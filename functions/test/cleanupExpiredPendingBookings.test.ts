const mockFirestoreInstance = {
  collectionGroup: jest.fn().mockReturnThis(),
  where: jest.fn().mockReturnThis(),
  limit: jest.fn().mockReturnThis(),
  get: jest.fn(),
  batch: jest.fn(),
};

const mockFirestoreFn = jest.fn(() => mockFirestoreInstance);
Object.assign(mockFirestoreFn, {
  FieldValue: { serverTimestamp: jest.fn() },
  Timestamp: {
    now: jest.fn().mockReturnValue({
      toDate: () => new Date(),
      toMillis: () => Date.now(),
    }),
    fromDate: (date: Date) => ({
      toDate: () => date,
      toMillis: () => date.getTime(),
    }),
  }
});

jest.mock("firebase-admin", () => {
  return {
    initializeApp: jest.fn(),
    apps: [{ length: 1 }],
    firestore: mockFirestoreFn,
  };
});

jest.mock("../src/firebase", () => {
  const fAdmin = require("firebase-admin");
  return {
    admin: fAdmin,
    db: fAdmin.firestore(),
  };
});

// require test after mock
const test = require("firebase-functions-test")();

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logWarn: jest.fn(),
}));

import { cleanupExpiredStripePendingBookings } from "../src/cleanupExpiredPendingBookings";
import { logError } from "../src/logger";
import { db } from "../src/firebase";

describe("cleanupExpiredPendingBookings", () => {
  const wrapped = test.wrap(cleanupExpiredStripePendingBookings);
  const mockDb = db as any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb.collectionGroup.mockReturnThis();
    mockDb.where.mockReturnThis();
    mockDb.limit.mockReturnThis();
  });

  it("should do nothing if no expired bookings found", async () => {
    mockDb.get.mockResolvedValueOnce({
      empty: true,
      size: 0,
      docs: [],
    });

    await wrapped({});

    expect(mockDb.collectionGroup).toHaveBeenCalledWith("bookings");
    expect(mockDb.where).toHaveBeenCalledWith("status", "==", "pending");
    expect(mockDb.batch).not.toHaveBeenCalled();
  });

  it("should delete expired bookings in a batch", async () => {
    const mockDoc1 = { ref: { delete: jest.fn() } };
    const mockDoc2 = { ref: { delete: jest.fn() } };

    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: 2,
      docs: [mockDoc1, mockDoc2],
    });

    const mockBatch = {
      delete: jest.fn(),
      commit: jest.fn().mockResolvedValue(true),
    };
    mockDb.batch.mockReturnValue(mockBatch);

    await wrapped({});

    expect(mockDb.batch).toHaveBeenCalled();
    expect(mockBatch.delete).toHaveBeenCalledTimes(2);
    expect(mockBatch.commit).toHaveBeenCalled();
  });

  it("should fall back to individual deletes if batch fails", async () => {
    const mockDoc = {
      id: "b-123",
      data: () => ({ booking_reference: "REF-123" }),
      ref: { delete: jest.fn().mockResolvedValue(true) },
    };

    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: 1,
      docs: [mockDoc],
    });

    const mockBatch = {
      delete: jest.fn(),
      commit: jest.fn().mockRejectedValue(new Error("Batch failed")),
    };
    mockDb.batch.mockReturnValue(mockBatch);

    await wrapped({});

    expect(mockBatch.commit).toHaveBeenCalled();
    expect(mockDoc.ref.delete).toHaveBeenCalled(); // Individual delete called as fallback
  });

  it("should log error and rethrow if critical failure occurs", async () => {
    mockDb.get.mockRejectedValueOnce(new Error("Database error"));

    try {
      await wrapped({});
      fail("Should have thrown");
    } catch (e: any) {
      expect(e.message).toBe("Database error");
    }

    expect(logError).toHaveBeenCalledWith(
      expect.stringContaining("Critical error during cleanup"),
      expect.any(Error),
      expect.any(Object)
    );
  });
});
