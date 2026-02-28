import { findBookingById, findBookingByReference } from "../src/utils/bookingLookup";
import * as admin from "firebase-admin";

jest.mock("firebase-admin", () => {
  const mockFirestoreInstance = {
    collection: jest.fn().mockReturnThis(),
    collectionGroup: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    get: jest.fn(),
  };

  const firestoreFn = jest.fn(() => mockFirestoreInstance);

  return {
    firestore: firestoreFn,
  };
});

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logWarn: jest.fn(),
}));

describe("bookingLookup", () => {
  const db = admin.firestore();
  const mockDb = db as any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb.collection.mockReturnThis();
    mockDb.collectionGroup.mockReturnThis();
    mockDb.doc.mockReturnThis();
    mockDb.where.mockReturnThis();
    mockDb.limit.mockReturnThis();
  });

  describe("findBookingById", () => {
    it("should find booking via owner_id strategy (Strategy 1)", async () => {
      const mockDoc = {
        id: "booking-1",
        data: () => ({ property_id: "prop-1", unit_id: "unit-1" }),
        ref: { path: "properties/prop-1/units/unit-1/bookings/booking-1" },
      };

      mockDb.get.mockResolvedValueOnce({ docs: [mockDoc] });

      const result = await findBookingById("booking-1", "owner-1");

      expect(mockDb.collectionGroup).toHaveBeenCalledWith("bookings");
      expect(mockDb.where).toHaveBeenCalledWith("owner_id", "==", "owner-1");
      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1");
    });

    it("should fallback to strategy 2 (search all properties) if owner strategy fails", async () => {
      // 1. owner query (empty)
      mockDb.get.mockResolvedValueOnce({ docs: [] });

      // 2. properties query
      const mockPropDoc = { id: "prop-1" };
      mockDb.get.mockResolvedValueOnce({ empty: false, docs: [mockPropDoc] });

      // 3. units query (for prop-1)
      const mockUnitDoc = { id: "unit-1" };
      mockDb.get.mockResolvedValueOnce({ docs: [mockUnitDoc] });

      // 4. specific booking query
      const mockBookingDoc = {
        exists: true,
        data: () => ({ property_id: "prop-1", unit_id: "unit-1" }),
        ref: { path: "properties/prop-1/units/unit-1/bookings/booking-1" },
      };
      mockDb.get.mockResolvedValueOnce(mockBookingDoc);

      const result = await findBookingById("booking-1", "owner-1");

      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1");
    });

    it("should return null if booking not found by any strategy", async () => {
       // 1. properties query (empty)
       mockDb.get.mockResolvedValueOnce({ empty: true });

       // 2. legacy collection query (empty)
       mockDb.get.mockResolvedValueOnce({ exists: false });

       const result = await findBookingById("missing-booking");
       expect(result).toBeNull();
    });
  });

  describe("findBookingByReference", () => {
    it("should find booking via collectionGroup query", async () => {
      const mockDoc = {
        id: "booking-1",
        data: () => ({ property_id: "prop-1", unit_id: "unit-1" }),
        ref: { path: "some/path" },
      };

      mockDb.get.mockResolvedValueOnce({ empty: false, docs: [mockDoc] });

      const result = await findBookingByReference("REF-123");

      expect(mockDb.collectionGroup).toHaveBeenCalledWith("bookings");
      expect(mockDb.where).toHaveBeenCalledWith("booking_reference", "==", "REF-123");
      expect(result).toBeDefined();
    });

    it("should return null if not found", async () => {
      // 1. collectionGroup query (empty)
      mockDb.get.mockResolvedValueOnce({ empty: true });

      // 2. legacy collection query (empty)
      mockDb.get.mockResolvedValueOnce({ empty: true });

      const result = await findBookingByReference("REF-123");

      expect(result).toBeNull();
    });
  });
});
