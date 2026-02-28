const test = require("firebase-functions-test")();

// Setup mocks inside the factory to avoid hoisting issues
jest.mock("../src/firebase", () => {
  const mockFirestoreInstance = {
    collectionGroup: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    get: jest.fn(),
    batch: jest.fn().mockReturnValue({
      update: jest.fn(),
      commit: jest.fn().mockResolvedValue(true),
    }),
  };

  const firestoreFn = jest.fn(() => mockFirestoreInstance);
  Object.assign(firestoreFn, {
    Timestamp: {
      fromDate: (date: Date) => ({
        toDate: () => date,
        toMillis: () => date.getTime(),
      }),
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

import { autoCompleteCheckedOutBookings } from "../src/completeCheckedOutBookings";
import { db } from "../src/firebase";

const { wrap } = test;

describe("completeCheckedOutBookings", () => {
  const mockDb = db as any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb.collectionGroup.mockReturnThis();
    mockDb.where.mockReturnThis();
    mockDb.limit.mockReturnThis();

    mockDb.batch.mockReturnValue({
      update: jest.fn(),
      commit: jest.fn().mockResolvedValue(true),
    });
  });

  it("should handle no bookings gracefully", async () => {
    mockDb.get.mockResolvedValueOnce({
      empty: true,
      size: 0,
      docs: []
    });

    const wrapped = wrap(autoCompleteCheckedOutBookings);
    await expect(wrapped({})).resolves.not.toThrow();

    expect(mockDb.collectionGroup).toHaveBeenCalledWith("bookings");
    expect(mockDb.where).toHaveBeenCalledWith("status", "in", ["confirmed", "pending"]);
    expect(mockDb.where).toHaveBeenCalledWith("check_out", "<", expect.any(Object));
  });

  it("should filter out iCal/external bookings and update others", async () => {
    // 1 Native booking, 1 Airbnb (source), 1 iCal (ID)
    const mockDocs = [
      {
        id: "native-123",
        ref: { update: jest.fn().mockResolvedValue(true) },
        data: () => ({ source: "direct" })
      },
      {
        id: "native-456",
        ref: { update: jest.fn().mockResolvedValue(true) },
        data: () => ({ source: "airbnb" }) // Should be filtered out
      },
      {
        id: "ical_event_123",
        ref: { update: jest.fn().mockResolvedValue(true) },
        data: () => ({ source: "ical" }) // Should be filtered out
      },
    ];

    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: 3,
      docs: mockDocs
    });

    const mockBatch = {
      update: jest.fn(),
      commit: jest.fn().mockResolvedValue(true),
    };
    mockDb.batch.mockReturnValue(mockBatch);

    const wrapped = wrap(autoCompleteCheckedOutBookings);
    await wrapped({});

    // Batch should only be called for the native booking
    expect(mockBatch.update).toHaveBeenCalledTimes(1);
    expect(mockBatch.update).toHaveBeenCalledWith(mockDocs[0].ref, expect.objectContaining({ status: "completed" }));
    expect(mockBatch.commit).toHaveBeenCalled();
  });

  it("should fallback to individual updates if batch commit fails", async () => {
    const mockDocs = [
      {
        id: "native-123",
        ref: { update: jest.fn().mockResolvedValue(true) },
        data: () => ({ source: "direct" })
      }
    ];

    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: 1,
      docs: mockDocs
    });

    const mockBatch = {
      update: jest.fn(),
      commit: jest.fn().mockRejectedValue(new Error("Batch failed")),
    };
    mockDb.batch.mockReturnValue(mockBatch);

    const wrapped = wrap(autoCompleteCheckedOutBookings);
    await wrapped({});

    expect(mockBatch.commit).toHaveBeenCalled();
    // Fallback: individual update should be called
    expect(mockDocs[0].ref.update).toHaveBeenCalled();
  });
});
