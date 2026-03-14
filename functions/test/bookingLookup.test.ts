jest.mock("firebase-admin", () => {
  const mockFirestoreInstance = {
    collection: jest.fn().mockReturnThis(),
    collectionGroup: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    get: jest.fn(),
  };

  const firestoreFn = jest.fn(() => mockFirestoreInstance);

  return {
    firestore: firestoreFn,
  };
});

jest.mock("../src/firebase", () => {
  const mockFirestoreInstance = {
    collection: jest.fn().mockReturnThis(),
    collectionGroup: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    get: jest.fn(),
  };

  const firestoreFn = jest.fn(() => mockFirestoreInstance);

  return {
    admin: {
      firestore: firestoreFn,
    },
    db: mockFirestoreInstance,
  };
});

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logWarn: jest.fn(),
}));

import { findBookingById } from "../src/utils/bookingLookup";
import * as admin from "firebase-admin";

describe("bookingLookup", () => {
  let mockDb: any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb = admin.firestore();
    mockDb.collection.mockReturnThis();
    mockDb.collectionGroup.mockReturnThis();
    mockDb.doc.mockReturnThis();
    mockDb.where.mockReturnThis();
  });

  describe("findBookingById", () => {
    it("should return null if booking not found by any strategy", async () => {
      mockDb.get.mockReset();
      let callIndex = 0;
      mockDb.get.mockImplementation(() => {
        callIndex++;
        if (callIndex === 1) return Promise.resolve({ docs: [] }); // Strategy 1
        if (callIndex === 2) return Promise.resolve({ empty: true }); // Strategy 2
        if (callIndex === 3) return Promise.resolve({ exists: false }); // Strategy 3
        return Promise.resolve({});
      });

      const result = await findBookingById("invalid-id", "owner-1");
      expect(result).toBeNull();
    });

    it("should find booking via Strategy 1 (owner_id lookup)", async () => {
      mockDb.get.mockReset();
      const mockBooking = {
        id: "bk-1",
        data: () => ({ property_id: "prop-1", unit_id: "unit-1" }),
        ref: { path: "some/path" }
      };

      mockDb.get.mockImplementationOnce(() => Promise.resolve({ docs: [mockBooking] }));

      const result = await findBookingById("bk-1", "owner-1");

      expect(result).not.toBeNull();
      expect(result?.propertyId).toBe("prop-1");
      expect(result?.unitId).toBe("unit-1");
    });

    it("should find booking via Strategy 2 (parallel search) if owner_id missing or fails", async () => {
      mockDb.get.mockReset();
      const mockProp = { id: "prop-1" };
      const mockUnit = { id: "unit-1" };

      let callIndex = 0;
      mockDb.get.mockImplementation(() => {
        callIndex++;
        if (callIndex === 1) return Promise.resolve({ empty: false, docs: [mockProp] }); // properties get
        if (callIndex === 2) return Promise.resolve({ docs: [mockUnit] }); // units get
        if (callIndex === 3) return Promise.resolve({ // booking get
          exists: true,
          data: () => ({ property_id: "prop-1", unit_id: "unit-1" }),
          ref: { path: "props/prop-1/units/unit-1/bookings/bk-1" }
        });
        return Promise.resolve({});
      });

      const result = await findBookingById("bk-1");

      expect(result).not.toBeNull();
      expect(result?.propertyId).toBe("prop-1");
    });

    it("should find booking via Strategy 3 (legacy collection) if 1 and 2 fail", async () => {
      mockDb.get.mockReset();

      let callIndex = 0;
      mockDb.get.mockImplementation(() => {
        callIndex++;
        if (callIndex === 1) return Promise.resolve({ empty: true }); // properties get
        if (callIndex === 2) return Promise.resolve({ // legacy booking get
          exists: true,
          data: () => ({ property_id: "prop-2", unit_id: "unit-2" }),
          ref: { path: "bookings/bk-1" }
        });
        return Promise.resolve({});
      });

      const result = await findBookingById("bk-1");

      expect(result).not.toBeNull();
      expect(result?.propertyId).toBe("prop-2");
    });
  });
});
