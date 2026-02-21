// Mock firebase-admin
const mockFirestoreInstance = {
  collection: jest.fn().mockReturnThis(),
  collectionGroup: jest.fn().mockReturnThis(),
  doc: jest.fn().mockReturnThis(),
  where: jest.fn().mockReturnThis(),
  limit: jest.fn().mockReturnThis(),
  get: jest.fn(),
};

jest.mock("firebase-admin", () => ({
  firestore: () => mockFirestoreInstance,
}));

// Mock ../src/firebase just in case
jest.mock("../src/firebase", () => ({
  db: mockFirestoreInstance,
  admin: {
    firestore: () => mockFirestoreInstance,
  },
}));

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logWarn: jest.fn(),
}));

import { findBookingById, findBookingByReference } from "../src/utils/bookingLookup";

describe("Booking Lookup Utility", () => {
  const mockDb = mockFirestoreInstance as any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb.collection.mockReturnThis();
    mockDb.collectionGroup.mockReturnThis();
    mockDb.doc.mockReturnThis();
    mockDb.where.mockReturnThis();
    mockDb.limit.mockReturnThis();
  });

  describe("findBookingById", () => {
    it("Strategy 1: should find booking by owner_id", async () => {
      // Mock collectionGroup('bookings').where('owner_id').get()
      mockDb.get.mockResolvedValueOnce({
        docs: [
          {
            id: "booking-1",
            ref: { path: "properties/p1/units/u1/bookings/booking-1" },
            data: () => ({ property_id: "p1", unit_id: "u1" }),
          },
        ],
      });

      const result = await findBookingById("booking-1", "owner-1");

      expect(result).not.toBeNull();
      expect(result?.propertyId).toBe("p1");
      expect(result?.unitId).toBe("u1");
      expect(mockDb.collectionGroup).toHaveBeenCalledWith("bookings");
    });

    it("Strategy 2: should find booking by parallel search", async () => {
      // Strategy 1 failed (owner_id not provided)

      // Mock properties list
      mockDb.get.mockResolvedValueOnce({
        empty: false,
        docs: [{ id: "p1" }, { id: "p2" }],
      });

      // Mock units fetch for each property
      // p1 units
      mockDb.get.mockResolvedValueOnce({
        docs: [{ id: "u1" }],
      });
      // p2 units
      mockDb.get.mockResolvedValueOnce({
        docs: [{ id: "u2" }],
      });

      // Mock booking checks (comprehensive search)
      // p1/u1 check - found!
      mockDb.get.mockResolvedValueOnce({
        exists: true,
        ref: { path: "properties/p1/units/u1/bookings/booking-1" },
        data: () => ({ property_id: "p1", unit_id: "u1" }),
      });
      // p2/u2 check - not found (if it gets called, Promise.all runs in parallel)
      mockDb.get.mockResolvedValueOnce({ exists: false });

      const result = await findBookingById("booking-1");

      expect(result).not.toBeNull();
      expect(result?.propertyId).toBe("p1");
      expect(mockDb.collection).toHaveBeenCalledWith("properties");
    });

    it("Strategy 3: should find booking in legacy collection", async () => {
      // Strategy 2 failed (mock properties empty or booking not found in deep search)
      mockDb.get.mockResolvedValueOnce({ empty: true }); // No properties

      // Strategy 3: Check legacy collection
      mockDb.get.mockResolvedValueOnce({
        exists: true,
        ref: { path: "bookings/booking-1" },
        data: () => ({ property_id: "p1", unit_id: "u1" }),
      });

      const result = await findBookingById("booking-1");

      expect(result).not.toBeNull();
      expect(mockDb.collection).toHaveBeenCalledWith("bookings");
    });

    it("should return null if not found anywhere", async () => {
      // Strategy 2: No properties
      mockDb.get.mockResolvedValueOnce({ empty: true });
      // Strategy 3: Not in legacy
      mockDb.get.mockResolvedValueOnce({ exists: false });

      const result = await findBookingById("missing-id");

      expect(result).toBeNull();
    });
  });

  describe("findBookingByReference", () => {
    it("should find booking by reference in collectionGroup", async () => {
      mockDb.get.mockResolvedValueOnce({
        empty: false,
        docs: [
          {
            id: "booking-1",
            ref: { path: "properties/p1/units/u1/bookings/booking-1" },
            data: () => ({ property_id: "p1", unit_id: "u1" }),
          },
        ],
      });

      const result = await findBookingByReference("REF-123");

      expect(result).not.toBeNull();
      expect(result?.propertyId).toBe("p1");
      expect(mockDb.collectionGroup).toHaveBeenCalledWith("bookings");
    });

    it("should fallback to legacy collection if not in collectionGroup", async () => {
      // collectionGroup empty
      mockDb.get.mockResolvedValueOnce({ empty: true });

      // legacy collection found
      mockDb.get.mockResolvedValueOnce({
        empty: false,
        docs: [
          {
            id: "booking-1",
            data: () => ({ property_id: "p1", unit_id: "u1" }),
          },
        ],
      });

      const result = await findBookingByReference("REF-123");

      expect(result).not.toBeNull();
      expect(mockDb.collection).toHaveBeenCalledWith("bookings");
    });

    it("should return null if not found", async () => {
      mockDb.get.mockResolvedValueOnce({ empty: true });
      mockDb.get.mockResolvedValueOnce({ empty: true });

      const result = await findBookingByReference("MISSING");

      expect(result).toBeNull();
    });
  });
});
