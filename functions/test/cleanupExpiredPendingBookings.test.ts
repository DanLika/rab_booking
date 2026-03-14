const test = require("firebase-functions-test")();

jest.mock("../src/firebase", () => {
  const mockFirestoreInstance = {
    collectionGroup: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    get: jest.fn(),
    batch: jest.fn(),
  };

  const firestoreFn = jest.fn(() => mockFirestoreInstance);
  Object.assign(firestoreFn, {
    Timestamp: {
      now: () => ({
        toDate: () => new Date(),
        toMillis: () => Date.now(),
      }),
    },
  });

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
  logSuccess: jest.fn(),
}));

import { cleanupExpiredStripePendingBookings } from "../src/cleanupExpiredPendingBookings";
import { db } from "../src/firebase";

const { wrap } = test;

describe("cleanupExpiredPendingBookings", () => {
  const mockDb = db as any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb.collectionGroup.mockReturnThis();
    mockDb.where.mockReturnThis();
    mockDb.limit.mockReturnThis();
  });

  it("should do nothing if no expired bookings found", async () => {
    mockDb.get.mockResolvedValueOnce({ empty: true });

    const wrapped = wrap(cleanupExpiredStripePendingBookings);
    await expect(wrapped({})).resolves.not.toThrow();
  });

  it("should delete expired bookings in batches", async () => {
    const mockBatch = {
      delete: jest.fn(),
      commit: jest.fn().mockResolvedValue(true),
    };
    mockDb.batch.mockReturnValue(mockBatch);

    const mockDocs = [
      { id: "doc1", ref: { delete: jest.fn() }, data: () => ({ booking_reference: "REF1" }) },
      { id: "doc2", ref: { delete: jest.fn() }, data: () => ({ booking_reference: "REF2" }) },
    ];
    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: 2,
      docs: mockDocs,
    });

    const wrapped = wrap(cleanupExpiredStripePendingBookings);
    await expect(wrapped({})).resolves.not.toThrow();

    expect(mockBatch.delete).toHaveBeenCalledTimes(2);
    expect(mockBatch.commit).toHaveBeenCalledTimes(1);
  });

  it("should fall back to individual deletes if batch commit fails", async () => {
    const mockBatch = {
      delete: jest.fn(),
      commit: jest.fn().mockRejectedValue(new Error("Batch failed")),
    };
    mockDb.batch.mockReturnValue(mockBatch);

    const doc1Ref = { delete: jest.fn().mockResolvedValue(true) };
    const doc2Ref = { delete: jest.fn().mockRejectedValue(new Error("Doc delete failed")) };
    const mockDocs = [
      { id: "doc1", ref: doc1Ref, data: () => ({ booking_reference: "REF1" }) },
      { id: "doc2", ref: doc2Ref, data: () => ({ booking_reference: "REF2" }) },
    ];
    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: 2,
      docs: mockDocs,
    });

    const wrapped = wrap(cleanupExpiredStripePendingBookings);
    await expect(wrapped({})).resolves.not.toThrow();

    expect(doc1Ref.delete).toHaveBeenCalled();
    expect(doc2Ref.delete).toHaveBeenCalled();
  });
});
