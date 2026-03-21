import { findBookingById, findBookingByReference } from "../src/utils/bookingLookup";
import * as admin from "firebase-admin";

// Mock firebase-admin completely before any imports
jest.mock("firebase-admin", () => {
  const mockGet = jest.fn();
  const mockWhere = jest.fn().mockReturnThis();
  const mockLimit = jest.fn().mockReturnThis();

  // Define mockCollection before mockDoc to fix scoping in TypeScript
  let mockCollection: any;

  // Break circular dependency using a getter approach
  const mockDoc: any = jest.fn(() => ({
    get: mockGet,
    collection: function() { return mockCollection.apply(this, arguments); },
  }));

  mockCollection = jest.fn(() => ({
    doc: mockDoc,
    where: mockWhere,
    get: mockGet,
    limit: mockLimit,
  }));

  const mockCollectionGroup = jest.fn(() => ({
    where: mockWhere,
    get: mockGet,
    limit: mockLimit,
  }));

  const mockFirestore = jest.fn(() => ({
    collection: mockCollection,
    collectionGroup: mockCollectionGroup,
  })) as any;

  // Needed by other modules that might be imported implicitly
  mockFirestore.FieldValue = {
    serverTimestamp: jest.fn(),
  };
  mockFirestore.Timestamp = {
    fromDate: jest.fn(),
    now: jest.fn(),
  };

  return {
    firestore: mockFirestore,
  };
});

// Mock logger to suppress console output during tests
jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logWarn: jest.fn(),
  logError: jest.fn(),
}));

describe("bookingLookup", () => {
  let db: any;

  beforeEach(() => {
    jest.clearAllMocks();
    db = admin.firestore();
  });

  describe("findBookingById", () => {
    const mockBookingId = "booking-123";
    const mockOwnerId = "owner-123";
    const mockBookingData = {
      property_id: "prop-1",
      unit_id: "unit-1",
      status: "confirmed",
    };

    it("should find booking via Strategy 1 (owner_id)", async () => {
      // Mock collectionGroup('bookings').where('owner_id', '==', ownerId).get()
      const mockSnapshot = {
        docs: [
          {
            id: mockBookingId,
            data: () => mockBookingData,
            ref: { path: "properties/prop-1/units/unit-1/bookings/booking-123" },
          },
        ],
      };
      db.collectionGroup().get.mockResolvedValueOnce(mockSnapshot);

      const result = await findBookingById(mockBookingId, mockOwnerId);

      expect(db.collectionGroup).toHaveBeenCalledWith("bookings");
      expect(db.collectionGroup().where).toHaveBeenCalledWith("owner_id", "==", mockOwnerId);
      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1");
      expect(result?.unitId).toBe("unit-1");
      expect(result?.data).toEqual(mockBookingData);
    });

    it("should fall back to Strategy 2 if owner_id lookup fails", async () => {
      // Strategy 1 fails (returns empty or different booking)
      const emptySnapshot = { docs: [] };
      db.collectionGroup().get.mockResolvedValueOnce(emptySnapshot);

      // Strategy 2 mock
      // Mock properties query
      const mockPropertiesSnapshot = {
        empty: false,
        docs: [{ id: "prop-1" }, { id: "prop-2" }],
      };
      // Properties get
      db.collection().get.mockResolvedValueOnce(mockPropertiesSnapshot);

      // Mock units query for each property
      const mockUnitsSnapshotProp1 = { docs: [{ id: "unit-1" }] };
      const mockUnitsSnapshotProp2 = { docs: [{ id: "unit-2" }] };
      // First db.collection('properties').doc(id).collection('units').get()
      db.collection().doc().collection().get
        .mockResolvedValueOnce(mockUnitsSnapshotProp1)
        .mockResolvedValueOnce(mockUnitsSnapshotProp2);

      // Mock booking check for each path
      // bookingRef.get() checks
      const mockBookingDocExist = {
        exists: true,
        data: () => mockBookingData,
        ref: { path: "properties/prop-1/units/unit-1/bookings/booking-123" },
      };
      const mockBookingDocNotExist = { exists: false };

      db.collection().doc().collection().doc().collection().doc().get
        .mockResolvedValueOnce(mockBookingDocExist)
        .mockResolvedValueOnce(mockBookingDocNotExist);

      const result = await findBookingById(mockBookingId, mockOwnerId);

      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1"); // Matches first found
      expect(result?.data).toEqual(mockBookingData);
    });

    it("should use Strategy 2 directly if no ownerId provided", async () => {
      // Strategy 2 mock
      const mockPropertiesSnapshot = {
        empty: false,
        docs: [{ id: "prop-1" }],
      };
      db.collection().get.mockResolvedValueOnce(mockPropertiesSnapshot);

      const mockUnitsSnapshot = { docs: [{ id: "unit-1" }] };
      db.collection().doc().collection().get.mockResolvedValueOnce(mockUnitsSnapshot);

      const mockBookingDocExist = {
        exists: true,
        data: () => mockBookingData,
        ref: { path: "properties/prop-1/units/unit-1/bookings/booking-123" },
      };
      db.collection().doc().collection().doc().collection().doc().get.mockResolvedValueOnce(mockBookingDocExist);

      const result = await findBookingById(mockBookingId);

      expect(db.collectionGroup).not.toHaveBeenCalled(); // Strategy 1 skipped
      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1");
    });

    it("should fall back to Strategy 3 (legacy) if Strategy 2 fails", async () => {
      // Strategy 2 fails (no properties)
      const mockPropertiesSnapshot = { empty: true, docs: [] };
      db.collection().get.mockResolvedValueOnce(mockPropertiesSnapshot);

      // Strategy 3 (legacy bookings collection)
      const mockLegacyDoc = {
        exists: true,
        data: () => mockBookingData,
        ref: { path: "bookings/booking-123" },
      };
      db.collection().doc().get.mockResolvedValueOnce(mockLegacyDoc);

      const result = await findBookingById(mockBookingId);

      expect(db.collection).toHaveBeenCalledWith("bookings");
      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1");
    });

    it("should return null if all strategies fail", async () => {
      // Strategy 2 fails (no properties)
      const mockPropertiesSnapshot = { empty: true, docs: [] };
      db.collection().get.mockResolvedValueOnce(mockPropertiesSnapshot);

      // Strategy 3 fails
      const mockLegacyDoc = { exists: false };
      db.collection().doc().get.mockResolvedValueOnce(mockLegacyDoc);

      const result = await findBookingById(mockBookingId);

      expect(result).toBeNull();
    });
  });

  describe("findBookingByReference", () => {
    const mockReference = "BB-12345";
    const mockBookingData = {
      property_id: "prop-1",
      unit_id: "unit-1",
      booking_reference: mockReference,
    };

    it("should find booking via collectionGroup query", async () => {
      const mockSnapshot = {
        empty: false,
        docs: [
          {
            data: () => mockBookingData,
            ref: { path: "properties/prop-1/units/unit-1/bookings/booking-123" },
          },
        ],
      };
      db.collectionGroup().limit().get.mockResolvedValueOnce(mockSnapshot);

      const result = await findBookingByReference(mockReference);

      expect(db.collectionGroup).toHaveBeenCalledWith("bookings");
      expect(db.collectionGroup().where).toHaveBeenCalledWith("booking_reference", "==", mockReference);
      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1");
      expect(result?.data).toEqual(mockBookingData);
    });

    it("should fall back to legacy collection if collectionGroup query is empty", async () => {
      const emptySnapshot = { empty: true };
      db.collectionGroup().limit().get.mockResolvedValueOnce(emptySnapshot);

      const mockLegacySnapshot = {
        empty: false,
        docs: [
          {
            data: () => mockBookingData,
            ref: { path: "bookings/booking-123" },
          },
        ],
      };
      db.collection().limit().get.mockResolvedValueOnce(mockLegacySnapshot);

      const result = await findBookingByReference(mockReference);

      expect(db.collection).toHaveBeenCalledWith("bookings");
      expect(db.collection().where).toHaveBeenCalledWith("booking_reference", "==", mockReference);
      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1");
    });

    it("should return null if booking not found anywhere", async () => {
      const emptySnapshot = { empty: true };
      db.collectionGroup().limit().get.mockResolvedValueOnce(emptySnapshot);
      db.collection().limit().get.mockResolvedValueOnce(emptySnapshot);

      const result = await findBookingByReference(mockReference);

      expect(result).toBeNull();
    });
  });
});
