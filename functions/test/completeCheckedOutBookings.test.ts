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

const mockUpdate = jest.fn();
const mockCommit = jest.fn().mockResolvedValue(undefined);
const mockBatchInstance = {
  update: mockUpdate,
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
  fromDate: jest.fn((date) => ({ toMillis: () => date.getTime() })),
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
import { autoCompleteCheckedOutBookings } from "../src/completeCheckedOutBookings";

describe("completeCheckedOutBookings", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("should do nothing if no checked-out bookings found", async () => {
    const emptySnapshot = { empty: true, size: 0, docs: [] };
    mockGet.mockResolvedValueOnce(emptySnapshot);

    await (autoCompleteCheckedOutBookings as unknown as () => Promise<void>)();

    expect(mockWhere).toHaveBeenCalledWith("status", "in", ["confirmed", "pending"]);
    expect(mockWhere).toHaveBeenCalledWith("check_out", "<", expect.anything());
    expect(mockBatch).not.toHaveBeenCalled();
  });

  it("should filter out iCal/external bookings and update the rest", async () => {
    const mockRef1 = { update: jest.fn() };
    const mockRef2 = { update: jest.fn() };
    const mockRef3 = { update: jest.fn() };

    const mockDocs = [
      { id: "booking-1", ref: mockRef1, data: () => ({ source: "direct" }) }, // Valid
      { id: "booking-2", ref: mockRef2, data: () => ({ source: "airbnb" }) }, // Excluded by source
      { id: "ical_123", ref: mockRef3, data: () => ({ source: "direct" }) },  // Excluded by ID prefix
    ];
    const snapshot = { empty: false, size: 3, docs: mockDocs };

    mockGet.mockResolvedValueOnce(snapshot);

    await (autoCompleteCheckedOutBookings as unknown as () => Promise<void>)();

    expect(mockBatch).toHaveBeenCalled();
    // Only the first booking is valid, so batch.update is called 1 time
    expect(mockUpdate).toHaveBeenCalledTimes(1);
    expect(mockUpdate).toHaveBeenCalledWith(mockRef1, expect.objectContaining({
      status: "completed",
    }));
    expect(mockCommit).toHaveBeenCalledTimes(1);
  });

  it("should do nothing if all found bookings are filtered out", async () => {
    const mockRef1 = { update: jest.fn() };

    const mockDocs = [
      { id: "booking-1", ref: mockRef1, data: () => ({ source: "airbnb" }) }, // Excluded
    ];
    const snapshot = { empty: false, size: 1, docs: mockDocs };

    mockGet.mockResolvedValueOnce(snapshot);

    await (autoCompleteCheckedOutBookings as unknown as () => Promise<void>)();

    expect(mockBatch).not.toHaveBeenCalled();
  });

  it("should fallback to individual updates if batch commit fails", async () => {
    const mockRef1 = { update: jest.fn().mockResolvedValue(undefined) };
    const mockRef2 = { update: jest.fn().mockRejectedValue(new Error("Individual update failed")) };

    const mockDocs = [
      { id: "booking-1", ref: mockRef1, data: () => ({ source: "direct" }) },
      { id: "booking-2", ref: mockRef2, data: () => ({ source: "direct" }) },
    ];
    const snapshot = { empty: false, size: 2, docs: mockDocs };

    mockGet.mockResolvedValueOnce(snapshot);

    // Force batch commit to fail
    mockCommit.mockRejectedValueOnce(new Error("Batch failed"));

    await (autoCompleteCheckedOutBookings as unknown as () => Promise<void>)();

    expect(mockRef1.update).toHaveBeenCalledWith(expect.objectContaining({ status: "completed" }));
    expect(mockRef2.update).toHaveBeenCalledWith(expect.objectContaining({ status: "completed" }));

    const { logError } = require("../src/logger");
    expect(logError).toHaveBeenCalledWith(
      expect.stringContaining("Failed to update booking booking-2"),
      expect.any(Error),
      expect.any(Object)
    );
  });
});
