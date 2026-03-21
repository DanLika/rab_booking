// Mock scheduler and logger before importing the module
jest.mock("firebase-functions/v2/scheduler", () => ({
  onSchedule: jest.fn((options, handler) => handler),
}));

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logWarn: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
}));

const mockDelete = jest.fn();
const mockCommit = jest.fn().mockResolvedValue(undefined);
const mockBatchInstance = {
  delete: mockDelete,
  commit: mockCommit,
};
const mockBatch = jest.fn(() => mockBatchInstance);

const mockGet = jest.fn();
const mockLimit = jest.fn().mockReturnThis();
const mockWhere = jest.fn().mockReturnThis();

const mockCollectionGroup = jest.fn(() => ({
  where: mockWhere,
  limit: mockLimit,
  get: mockGet,
}));

const mockFirestore = jest.fn(() => ({
  collectionGroup: mockCollectionGroup,
  batch: mockBatch,
})) as any;

mockFirestore.Timestamp = {
  now: jest.fn(() => ({ toMillis: () => Date.now() })),
};

jest.mock("firebase-admin", () => ({
  firestore: mockFirestore,
  initializeApp: jest.fn(),
  apps: { length: 1 },
}));

jest.mock("../src/firebase", () => ({
  admin: { firestore: mockFirestore },
  db: mockFirestore(),
}));

// Import happens after mocks are set up
import { cleanupExpiredStripePendingBookings } from "../src/cleanupExpiredPendingBookings";
import * as admin from "firebase-admin";

describe("cleanupExpiredStripePendingBookings", () => {
  let db: any;

  beforeEach(() => {
    jest.clearAllMocks();
    db = admin.firestore();
  });

  it("should do nothing if no expired bookings found", async () => {
    const emptySnapshot = { empty: true, size: 0, docs: [] };
    db.collectionGroup().get.mockResolvedValueOnce(emptySnapshot);

    // Call the unwrapped handler
    await (cleanupExpiredStripePendingBookings as unknown as () => Promise<void>)();

    expect(db.collectionGroup).toHaveBeenCalledWith("bookings");
    expect(db.batch).not.toHaveBeenCalled();
  });

  it("should delete expired bookings using batches", async () => {
    const mockDocs = [
      { id: "booking-1", ref: { delete: jest.fn() }, data: () => ({ booking_reference: "BB-1" }) },
      { id: "booking-2", ref: { delete: jest.fn() }, data: () => ({ booking_reference: "BB-2" }) },
    ];
    const snapshot = { empty: false, size: 2, docs: mockDocs };

    mockGet.mockResolvedValueOnce(snapshot);

    await (cleanupExpiredStripePendingBookings as unknown as () => Promise<void>)();

    // The query should check for status == pending and stripe_pending_expires_at < now
    expect(mockWhere).toHaveBeenCalledWith("status", "==", "pending");
    expect(mockWhere).toHaveBeenCalledWith("stripe_pending_expires_at", "<", expect.anything());

    expect(mockBatch).toHaveBeenCalled();
    expect(mockDelete).toHaveBeenCalledTimes(2);
    expect(mockCommit).toHaveBeenCalledTimes(1);
  });

  it("should fallback to individual deletes if batch commit fails", async () => {
    const mockRef1 = { delete: jest.fn().mockResolvedValue(undefined) };
    const mockRef2 = { delete: jest.fn().mockRejectedValue(new Error("Individual delete failed")) };

    const mockDocs = [
      { id: "booking-1", ref: mockRef1, data: () => ({ booking_reference: "BB-1" }) },
      { id: "booking-2", ref: mockRef2, data: () => ({ booking_reference: "BB-2" }) },
    ];
    const snapshot = { empty: false, size: 2, docs: mockDocs };

    db.collectionGroup().get.mockResolvedValueOnce(snapshot);

    // Force batch commit to fail
    db.batch().commit.mockRejectedValueOnce(new Error("Batch failed"));

    await (cleanupExpiredStripePendingBookings as unknown as () => Promise<void>)();

    expect(mockRef1.delete).toHaveBeenCalled();
    expect(mockRef2.delete).toHaveBeenCalled();

    // Test logger was called for the failed individual delete
    const { logError } = require("../src/logger");
    expect(logError).toHaveBeenCalledWith(
      expect.stringContaining("Failed to delete document booking-2"),
      expect.any(Error),
      expect.any(Object)
    );
  });
});
