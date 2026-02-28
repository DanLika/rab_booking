const test = require("firebase-functions-test")();
// Setup mocks inside the factory to avoid hoisting issues
jest.mock("../src/firebase", () => {
  const mockFirestoreInstance = {
    collectionGroup: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    get: jest.fn(),
    batch: jest.fn().mockReturnValue({
      delete: jest.fn(),
      commit: jest.fn().mockResolvedValue(true),
    }),
  };

  const firestoreFn = jest.fn(() => mockFirestoreInstance);
  Object.assign(firestoreFn, {
    Timestamp: {
      now: () => ({
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
  logSuccess: jest.fn(),
  logWarn: jest.fn(),
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

    mockDb.batch.mockReturnValue({
      delete: jest.fn(),
      commit: jest.fn().mockResolvedValue(true),
    });
  });

  it("should handle empty results gracefully", async () => {
    mockDb.get.mockResolvedValueOnce({
      empty: true,
      size: 0,
      docs: []
    });

    const wrapped = wrap(cleanupExpiredStripePendingBookings);
    await expect(wrapped({})).resolves.not.toThrow();

    expect(mockDb.collectionGroup).toHaveBeenCalledWith("bookings");
    expect(mockDb.where).toHaveBeenCalledWith("status", "==", "pending");
    expect(mockDb.where).toHaveBeenCalledWith("stripe_pending_expires_at", "<", expect.any(Object));
    expect(mockDb.batch).not.toHaveBeenCalled();
  });

  it("should process and delete expired bookings in batches", async () => {
    // Mock 3 documents (we'll pretend the batch size is large enough to handle them in one go)
    const mockDocs = Array(3).fill(null).map((_, i) => ({
      id: `booking-${i}`,
      ref: {
        path: `properties/prop1/units/unit1/bookings/booking-${i}`,
        delete: jest.fn().mockResolvedValue(true),
      },
      data: () => ({ booking_reference: `REF-${i}` })
    }));

    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: mockDocs.length,
      docs: mockDocs
    });

    const mockBatch = {
      delete: jest.fn(),
      commit: jest.fn().mockResolvedValue(true),
    };
    mockDb.batch.mockReturnValue(mockBatch);

    const wrapped = wrap(cleanupExpiredStripePendingBookings);
    await wrapped({});

    // Should create a batch
    expect(mockDb.batch).toHaveBeenCalled();
    // Should call delete on the batch for each document
    expect(mockBatch.delete).toHaveBeenCalledTimes(3);
    // Should commit the batch
    expect(mockBatch.commit).toHaveBeenCalledTimes(1);
  });

  it("should fallback to individual deletes if batch commit fails", async () => {
    const mockDocs = Array(2).fill(null).map((_, i) => ({
      id: `booking-${i}`,
      ref: {
        path: `properties/prop1/units/unit1/bookings/booking-${i}`,
        delete: jest.fn().mockResolvedValue(true),
      },
      data: () => ({ booking_reference: `REF-${i}` })
    }));

    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: mockDocs.length,
      docs: mockDocs
    });

    const mockBatch = {
      delete: jest.fn(),
      commit: jest.fn().mockRejectedValue(new Error("Batch failed")),
    };
    mockDb.batch.mockReturnValue(mockBatch);

    const wrapped = wrap(cleanupExpiredStripePendingBookings);
    await wrapped({});

    expect(mockBatch.commit).toHaveBeenCalled();
    // Fallback: individual deletes should be called
    expect(mockDocs[0].ref.delete).toHaveBeenCalled();
    expect(mockDocs[1].ref.delete).toHaveBeenCalled();
  });
});
