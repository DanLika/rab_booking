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

import { autoCompleteCheckedOutBookings } from "../src/completeCheckedOutBookings";
import { db } from "../src/firebase";

const { wrap } = test;

describe("Complete Checked Out Bookings", () => {
  const wrapped = wrap(autoCompleteCheckedOutBookings);
  const mockDb = db as any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb.collectionGroup.mockReturnThis();
    mockDb.where.mockReturnThis();
    mockDb.limit.mockReturnThis();

    // Default batch mock
    const mockBatch = {
      update: jest.fn(),
      commit: jest.fn().mockResolvedValue(true),
    };
    mockDb.batch.mockReturnValue(mockBatch);
  });

  it("should complete passed bookings", async () => {
    // Mock query result
    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: 2,
      docs: [
        { id: "bk-1", ref: { id: "bk-1" }, data: () => ({ status: "confirmed", check_out: "past" }) },
        { id: "bk-2", ref: { id: "bk-2" }, data: () => ({ status: "pending", check_out: "past" }) },
      ],
    });

    await wrapped({});

    expect(mockDb.batch).toHaveBeenCalled();
    const batch = mockDb.batch.mock.results[0].value;
    expect(batch.update).toHaveBeenCalledTimes(2);
    expect(batch.commit).toHaveBeenCalled();
  });

  it("should exclude iCal and external bookings", async () => {
    // Mock query result including external bookings
    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: 3,
      docs: [
        { id: "bk-1", ref: { id: "bk-1" }, data: () => ({ status: "confirmed" }) }, // Should update
        { id: "ical_123", ref: { id: "ical_123" }, data: () => ({ status: "confirmed", source: "airbnb" }) }, // Should skip (prefix + source)
        { id: "bk-3", ref: { id: "bk-3" }, data: () => ({ status: "confirmed", source: "booking_com" }) }, // Should skip (source)
      ],
    });

    await wrapped({});

    const batch = mockDb.batch.mock.results[0].value;
    expect(batch.update).toHaveBeenCalledTimes(1); // Only bk-1
  });

  it("should do nothing if no bookings found", async () => {
    mockDb.get.mockResolvedValueOnce({ empty: true });

    await wrapped({});

    expect(mockDb.batch).not.toHaveBeenCalled();
  });
});
