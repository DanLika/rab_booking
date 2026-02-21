const test = require("firebase-functions-test")();

// Mock dependencies
const mockFirestoreInstance = {
  collectionGroup: jest.fn().mockReturnThis(),
  where: jest.fn().mockReturnThis(),
  limit: jest.fn().mockReturnThis(),
  get: jest.fn(),
  batch: jest.fn(),
};

jest.mock("../src/firebase", () => {
  const firestoreFn = jest.fn(() => mockFirestoreInstance);
  Object.assign(firestoreFn, {
    Timestamp: {
      now: jest.fn().mockReturnValue({ toMillis: () => 1000000000000 }),
      fromDate: jest.fn((d) => ({ toMillis: () => d.getTime(), toDate: () => d })),
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
  logSuccess: jest.fn(),
  logWarn: jest.fn(),
}));

import { cleanupExpiredStripePendingBookings } from "../src/cleanupExpiredPendingBookings";
import { db } from "../src/firebase";

const { wrap } = test;

describe("Cleanup Expired Pending Bookings", () => {
  const wrapped = wrap(cleanupExpiredStripePendingBookings);
  const mockDb = db as any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb.collectionGroup.mockReturnThis();
    mockDb.where.mockReturnThis();
    mockDb.limit.mockReturnThis();

    // Default batch mock
    const mockBatch = {
      delete: jest.fn(),
      commit: jest.fn().mockResolvedValue(true),
    };
    mockDb.batch.mockReturnValue(mockBatch);
  });

  it("should delete expired bookings", async () => {
    // Mock query result
    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: 2,
      docs: [
        { id: "bk-1", ref: { id: "bk-1", delete: jest.fn() }, data: () => ({ booking_reference: "REF-1" }) },
        { id: "bk-2", ref: { id: "bk-2", delete: jest.fn() }, data: () => ({ booking_reference: "REF-2" }) },
      ],
    });

    await wrapped({});

    // Verify batch deletion
    expect(mockDb.batch).toHaveBeenCalled();
    const batch = mockDb.batch.mock.results[0].value;
    expect(batch.delete).toHaveBeenCalledTimes(2);
    expect(batch.commit).toHaveBeenCalled();
  });

  it("should do nothing if no expired bookings", async () => {
    mockDb.get.mockResolvedValueOnce({ empty: true });

    await wrapped({});

    expect(mockDb.batch).not.toHaveBeenCalled();
  });

  it("should handle batch failure by falling back to individual deletes", async () => {
    // Mock query result
    const doc1 = { id: "bk-1", ref: { id: "bk-1", delete: jest.fn().mockResolvedValue(true) }, data: () => ({ booking_reference: "REF-1" }) };
    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: 1,
      docs: [doc1],
    });

    // Mock batch failure
    const mockBatch = {
      delete: jest.fn(),
      commit: jest.fn().mockRejectedValue(new Error("Batch failed")),
    };
    mockDb.batch.mockReturnValue(mockBatch);

    await wrapped({});

    // Verify fallback
    expect(doc1.ref.delete).toHaveBeenCalled();
  });
});
