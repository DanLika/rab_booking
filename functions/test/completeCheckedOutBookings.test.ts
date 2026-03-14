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
      fromDate: (date: Date) => ({
        toDate: () => date,
        toMillis: () => date.getTime(),
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
  });

  it("should do nothing if no checked out bookings found", async () => {
    mockDb.get.mockResolvedValueOnce({ empty: true });

    const wrapped = wrap(autoCompleteCheckedOutBookings);
    await expect(wrapped({})).resolves.not.toThrow();
  });

  it("should update valid bookings in batches and exclude external sources", async () => {
    const mockBatch = {
      update: jest.fn(),
      commit: jest.fn().mockResolvedValue(true),
    };
    mockDb.batch.mockReturnValue(mockBatch);

    const mockDocs = [
      { id: "doc1", ref: { update: jest.fn() }, data: () => ({ booking_reference: "REF1", source: "direct" }) },
      { id: "doc2", ref: { update: jest.fn() }, data: () => ({ booking_reference: "REF2", source: "airbnb" }) }, // External, should be skipped
      { id: "ical_doc", ref: { update: jest.fn() }, data: () => ({ booking_reference: "REF3", source: "other" }) }, // iCal prefix, should be skipped
    ];
    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: 3,
      docs: mockDocs,
    });

    const wrapped = wrap(autoCompleteCheckedOutBookings);
    await expect(wrapped({})).resolves.not.toThrow();

    expect(mockBatch.update).toHaveBeenCalledTimes(1); // Only doc1 should be updated
    expect(mockBatch.commit).toHaveBeenCalledTimes(1);
  });

  it("should fall back to individual updates if batch commit fails", async () => {
    const mockBatch = {
      update: jest.fn(),
      commit: jest.fn().mockRejectedValue(new Error("Batch failed")),
    };
    mockDb.batch.mockReturnValue(mockBatch);

    const doc1Ref = { update: jest.fn().mockResolvedValue(true) };
    const doc2Ref = { update: jest.fn().mockRejectedValue(new Error("Doc update failed")) };
    const mockDocs = [
      { id: "doc1", ref: doc1Ref, data: () => ({ booking_reference: "REF1", source: "direct" }) },
      { id: "doc2", ref: doc2Ref, data: () => ({ booking_reference: "REF2", source: "direct" }) },
    ];
    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: 2,
      docs: mockDocs,
    });

    const wrapped = wrap(autoCompleteCheckedOutBookings);
    await expect(wrapped({})).resolves.not.toThrow();

    expect(doc1Ref.update).toHaveBeenCalled();
    expect(doc2Ref.update).toHaveBeenCalled();
  });
});
