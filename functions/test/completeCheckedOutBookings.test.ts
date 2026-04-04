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

const test = require("firebase-functions-test")();

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logWarn: jest.fn(),
}));

import { autoCompleteCheckedOutBookings } from "../src/completeCheckedOutBookings";
import { logError } from "../src/logger";
import { db } from "../src/firebase";

describe("autoCompleteCheckedOutBookings", () => {
  const wrapped = test.wrap(autoCompleteCheckedOutBookings);
  const mockDb = db as any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb.collectionGroup.mockReturnThis();
    mockDb.where.mockReturnThis();
    mockDb.limit.mockReturnThis();
  });

  it("should do nothing if no checked-out bookings found", async () => {
    mockDb.get.mockResolvedValueOnce({
      empty: true,
      size: 0,
      docs: [],
    });

    await wrapped({});

    expect(mockDb.collectionGroup).toHaveBeenCalledWith("bookings");
    expect(mockDb.where).toHaveBeenCalledWith("status", "in", ["confirmed", "pending"]);
    expect(mockDb.batch).not.toHaveBeenCalled();
  });

  it("should ignore iCal imported bookings", async () => {
    const mockIcalDoc = {
      id: "ical_ev-123", // iCal prefix
      data: () => ({ source: "ical" }),
      ref: { update: jest.fn() },
    };

    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: 1,
      docs: [mockIcalDoc],
    });

    await wrapped({});

    expect(mockDb.batch).not.toHaveBeenCalled();
    expect(mockIcalDoc.ref.update).not.toHaveBeenCalled();
  });

  it("should ignore external platform bookings", async () => {
    const mockExternalDoc = {
      id: "b-123",
      data: () => ({ source: "airbnb" }), // External
      ref: { update: jest.fn() },
    };

    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: 1,
      docs: [mockExternalDoc],
    });

    await wrapped({});

    expect(mockDb.batch).not.toHaveBeenCalled();
    expect(mockExternalDoc.ref.update).not.toHaveBeenCalled();
  });

  it("should update valid native bookings to completed", async () => {
    const mockNativeDoc = {
      id: "b-123",
      data: () => ({ source: "direct" }),
      ref: { update: jest.fn() },
    };

    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: 1,
      docs: [mockNativeDoc],
    });

    const mockBatch = {
      update: jest.fn(),
      commit: jest.fn().mockResolvedValue(true),
    };
    mockDb.batch.mockReturnValue(mockBatch);

    await wrapped({});

    expect(mockDb.batch).toHaveBeenCalled();
    expect(mockBatch.update).toHaveBeenCalled();
    // Verify first arg is ref, second contains status completed
    expect(mockBatch.update.mock.calls[0][0]).toBe(mockNativeDoc.ref);
    expect(mockBatch.update.mock.calls[0][1]).toHaveProperty("status", "completed");
    expect(mockBatch.commit).toHaveBeenCalled();
  });

  it("should fallback to individual updates if batch commit fails", async () => {
    const mockNativeDoc = {
      id: "b-123",
      data: () => ({ source: "direct", booking_reference: "REF-123" }),
      ref: { update: jest.fn().mockResolvedValue(true) },
    };

    mockDb.get.mockResolvedValueOnce({
      empty: false,
      size: 1,
      docs: [mockNativeDoc],
    });

    const mockBatch = {
      update: jest.fn(),
      commit: jest.fn().mockRejectedValue(new Error("Batch failed")),
    };
    mockDb.batch.mockReturnValue(mockBatch);

    await wrapped({});

    expect(mockBatch.commit).toHaveBeenCalled();
    expect(mockNativeDoc.ref.update).toHaveBeenCalled(); // Individual fallback called
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
      expect.stringContaining("Critical error during auto-complete"),
      expect.any(Error),
      expect.any(Object)
    );
  });
});
