// Mock Firebase Admin correctly
jest.mock("firebase-admin", () => {
  const mockFirestoreInstance = {
    collection: jest.fn().mockReturnThis(),
    collectionGroup: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    get: jest.fn().mockResolvedValue({ docs: [], empty: true }), // default mock
  };

  const firestoreFn = jest.fn(() => mockFirestoreInstance);

  return {
    firestore: firestoreFn,
    initializeApp: jest.fn(),
  };
});

jest.mock("../src/firebase", () => {
  const adminMock = require("firebase-admin");
  return {
    admin: adminMock,
    db: adminMock.firestore(),
  };
});

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logWarn: jest.fn(),
}));

import { findBookingById, findBookingByReference } from "../src/utils/bookingLookup";
import { db } from "../src/firebase";

describe("bookingLookup", () => {
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
    it("should find booking by ownerId (Strategy 1)", async () => {
      const mockBooking = {
        id: "booking-123",
        data: () => ({ property_id: "prop-1", unit_id: "unit-1" }),
        ref: { path: "some/path" }
      };

      mockDb.get.mockResolvedValueOnce({ docs: [mockBooking] });

      const result = await findBookingById("booking-123", "owner-1");

      expect(mockDb.collectionGroup).toHaveBeenCalledWith("bookings");
      expect(mockDb.where).toHaveBeenCalledWith("owner_id", "==", "owner-1");
      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1");
    });

    it("should fall back to Strategy 2 if ownerId is provided but not found", async () => {
      // Mock Strategy 1 (not found)
      mockDb.get.mockResolvedValueOnce({ docs: [] });

      // Mock Strategy 2
      const propDoc = { id: "prop-1" };
      mockDb.get.mockResolvedValueOnce({ empty: false, docs: [propDoc] }); // Properties
      const unitDoc = { id: "unit-1" };
      mockDb.get.mockResolvedValueOnce({ docs: [unitDoc] }); // Units

      const mockBooking = {
        exists: true,
        data: () => ({ property_id: "prop-1", unit_id: "unit-1" }),
        ref: { path: "some/path" }
      };
      mockDb.get.mockResolvedValueOnce(mockBooking); // Booking check

      const result = await findBookingById("booking-123", "owner-1");

      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1");
    });

    it("should use Strategy 2 if no ownerId is provided", async () => {
      // Mock Strategy 2
      const propDoc = { id: "prop-1" };
      mockDb.get.mockResolvedValueOnce({ empty: false, docs: [propDoc] }); // Properties
      const unitDoc = { id: "unit-1" };
      mockDb.get.mockResolvedValueOnce({ docs: [unitDoc] }); // Units

      const mockBooking = {
        exists: true,
        data: () => ({ property_id: "prop-1", unit_id: "unit-1" }),
        ref: { path: "some/path" }
      };
      mockDb.get.mockResolvedValueOnce(mockBooking); // Booking check

      const result = await findBookingById("booking-123");

      expect(mockDb.collectionGroup).not.toHaveBeenCalled();
      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1");
    });

    it("should fall back to Strategy 3 (legacy) if not found in Strategy 2", async () => {
      // Mock Strategy 2 (not found)
      mockDb.get.mockResolvedValueOnce({ empty: true }); // No properties

      // Mock Strategy 3
      const mockLegacyBooking = {
        exists: true,
        data: () => ({ property_id: "prop-1", unit_id: "unit-1" }),
        ref: { path: "legacy/path" }
      };
      mockDb.get.mockResolvedValueOnce(mockLegacyBooking); // Legacy check

      const result = await findBookingById("booking-123");

      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1");
    });

    it("should return null if not found in any strategy", async () => {
      // Mock Strategy 2
      mockDb.get.mockResolvedValueOnce({ empty: true }); // No properties

      // Mock Strategy 3
      mockDb.get.mockResolvedValueOnce({ exists: false }); // Legacy check not found

      const result = await findBookingById("booking-123");

      expect(result).toBeNull();
    });
  });

  describe("findBookingByReference", () => {
    it("should find booking by reference in collectionGroup", async () => {
      const mockBooking = {
        data: () => ({ property_id: "prop-1", unit_id: "unit-1" }),
        ref: { path: "some/path" }
      };

      mockDb.get.mockResolvedValueOnce({ empty: false, docs: [mockBooking] });

      const result = await findBookingByReference("REF-123");

      expect(mockDb.collectionGroup).toHaveBeenCalledWith("bookings");
      expect(mockDb.where).toHaveBeenCalledWith("booking_reference", "==", "REF-123");
      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1");
    });

    it("should fall back to legacy collection if not found in collectionGroup", async () => {
      // Not found in collectionGroup
      mockDb.get.mockResolvedValueOnce({ empty: true });

      // Found in legacy collection
      const mockLegacyBooking = {
        data: () => ({ property_id: "prop-1", unit_id: "unit-1" }),
        ref: { path: "legacy/path" }
      };
      mockDb.get.mockResolvedValueOnce({ empty: false, docs: [mockLegacyBooking] });

      const result = await findBookingByReference("REF-123");

      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop-1");
    });

    it("should return null if not found anywhere", async () => {
      // Not found in collectionGroup
      mockDb.get.mockResolvedValueOnce({ empty: true });

      // Not found in legacy collection
      mockDb.get.mockResolvedValueOnce({ empty: true });

      const result = await findBookingByReference("REF-123");

      expect(result).toBeNull();
    });
  });
});
