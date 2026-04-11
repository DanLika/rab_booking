// Setup mocks
jest.mock("firebase-admin", () => {
  const mockFirestoreInstance = {
    collection: jest.fn().mockReturnThis(),
    collectionGroup: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    get: jest.fn(),
    limit: jest.fn().mockReturnThis(),
  };

  const firestoreFn = jest.fn(() => mockFirestoreInstance);

  return {
    firestore: firestoreFn,
    initializeApp: jest.fn(),
    apps: { length: 1 },
  };
});

jest.mock("../../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logWarn: jest.fn(),
}));

import * as admin from "firebase-admin";
import { findBookingById, findBookingByReference } from "../../src/utils/bookingLookup";

describe("Booking Lookup Utility", () => {
  const mockDb = admin.firestore() as any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb.collection.mockReturnThis();
    mockDb.collectionGroup.mockReturnThis();
    mockDb.doc.mockReturnThis();
    mockDb.where.mockReturnThis();
    mockDb.limit.mockReturnThis();
  });

  describe("findBookingById", () => {
    it("should find booking via owner_id query (Strategy 1)", async () => {
      const mockDoc = {
        id: "booking-123",
        exists: true,
        data: () => ({ property_id: "prop-1", unit_id: "unit-1", owner_id: "owner-1" }),
        ref: { path: "properties/prop-1/units/unit-1/bookings/booking-123" }
      };

      mockDb.get.mockResolvedValueOnce({
        docs: [mockDoc]
      });

      const result = await findBookingById("booking-123", "owner-1");

      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1");
      expect(result?.unitId).toBe("unit-1");
      expect(mockDb.collectionGroup).toHaveBeenCalledWith("bookings");
      expect(mockDb.where).toHaveBeenCalledWith("owner_id", "==", "owner-1");
    });

    it("should find booking via parallel property search (Strategy 2)", async () => {
      // Mock failure for Strategy 1 if ownerId is passed, or just skip it

      const mockPropDoc = { id: "prop-1" };
      const mockUnitDoc = { id: "unit-1" };
      const mockBookingDoc = {
        exists: true,
        data: () => ({ property_id: "prop-1", unit_id: "unit-1" }),
        ref: { path: "properties/prop-1/units/unit-1/bookings/booking-123" }
      };

      mockDb.get
        // Strategy 2: properties
        .mockResolvedValueOnce({
          empty: false,
          docs: [mockPropDoc]
        })
        // Strategy 2: units for prop-1
        .mockResolvedValueOnce({
          docs: [mockUnitDoc]
        })
        // Strategy 2: booking get
        .mockResolvedValueOnce(mockBookingDoc);

      const result = await findBookingById("booking-123");

      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1");
      expect(result?.unitId).toBe("unit-1");
    });

    it("should find booking via legacy collection (Strategy 3)", async () => {
      const mockLegacyBookingDoc = {
        exists: true,
        data: () => ({ property_id: "prop-legacy", unit_id: "unit-legacy" }),
        ref: { path: "bookings/booking-123" }
      };

      mockDb.get
        // Strategy 2: properties (empty)
        .mockResolvedValueOnce({ empty: true })
        // Strategy 3: legacy collection
        .mockResolvedValueOnce(mockLegacyBookingDoc);

      const result = await findBookingById("booking-123");

      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-legacy");
      expect(result?.unitId).toBe("unit-legacy");
      expect(mockDb.collection).toHaveBeenCalledWith("bookings");
      expect(mockDb.doc).toHaveBeenCalledWith("booking-123");
    });

    it("should return null if booking is completely missing", async () => {
      mockDb.get
        // Strategy 2: properties (empty)
        .mockResolvedValueOnce({ empty: true })
        // Strategy 3: legacy collection (not exists)
        .mockResolvedValueOnce({ exists: false });

      const result = await findBookingById("missing-booking");

      expect(result).toBeNull();
    });
  });

  describe("findBookingByReference", () => {
    it("should find booking via collectionGroup", async () => {
      const mockDoc = {
        exists: true,
        data: () => ({ property_id: "prop-1", unit_id: "unit-1" }),
        ref: { path: "path" }
      };

      mockDb.get.mockResolvedValueOnce({
        empty: false,
        docs: [mockDoc]
      });

      const result = await findBookingByReference("REF-123");

      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1");
      expect(mockDb.where).toHaveBeenCalledWith("booking_reference", "==", "REF-123");
    });

    it("should fallback to legacy collection if collectionGroup is empty", async () => {
      const mockLegacyDoc = {
        exists: true,
        data: () => ({ property_id: "prop-legacy", unit_id: "unit-legacy" }),
        ref: { path: "legacy/path" }
      };

      mockDb.get
        .mockResolvedValueOnce({ empty: true })
        .mockResolvedValueOnce({
          empty: false,
          docs: [mockLegacyDoc]
        });

      const result = await findBookingByReference("REF-123");

      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-legacy");
    });

    it("should return null if not found anywhere", async () => {
      mockDb.get
        .mockResolvedValueOnce({ empty: true })
        .mockResolvedValueOnce({ empty: true });

      const result = await findBookingByReference("REF-123");

      expect(result).toBeNull();
    });
  });
});
