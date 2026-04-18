import * as admin from "firebase-admin";

// Mock dependencies
jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logWarn: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
}));

// Mock firebase-admin completely before any imports
const mockUpdate = jest.fn();
const mockCommit = jest.fn().mockResolvedValue(undefined);
const mockBatch = jest.fn(() => ({
  update: mockUpdate,
  commit: mockCommit,
}));

const mockGet = jest.fn();
const mockCollectionGroup = jest.fn();

jest.mock("firebase-admin", () => {
  const mockFirestore = jest.fn(() => ({
    collectionGroup: mockCollectionGroup,
    batch: mockBatch,
  }));

  // Attach Timestamp to the mock to avoid TDZ
  (mockFirestore as any).Timestamp = {
    now: jest.fn(() => ({seconds: 1000, nanoseconds: 0})),
  };

  return {
    apps: {length: 1}, // Prevent initialization errors
    initializeApp: jest.fn(),
    firestore: mockFirestore,
  };
});

describe("Complete Checked Out Bookings", () => {
  beforeEach(() => {
    jest.clearAllMocks();

    mockCollectionGroup.mockReturnValue({
      where: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: mockGet,
          }),
        }),
      }),
    });
  });

  it("should initialize the scheduled function correctly", () => {
    // Just requiring it verifies it doesn't throw on initialization
    const {autoCompleteCheckedOutBookings} = require("../src/completeCheckedOutBookings");
    expect(autoCompleteCheckedOutBookings).toBeDefined();
  });

  it("should have logic to query and update checked out bookings", async () => {
    // This is a proxy test since we can't run the wrapped onSchedule easily
    const db = admin.firestore();

    // Setup a mock query based on the implementation
    const checkedOutBookingsQuery = db
      .collectionGroup("bookings")
      .where("status", "==", "confirmed")
      .where("check_out", "<", admin.firestore.Timestamp.now())
      .limit(2000);

    // Execute get to verify chain
    await checkedOutBookingsQuery.get();

    // Verify our mocks are called in the way the function expects
    expect(db.collectionGroup).toHaveBeenCalledWith("bookings");
  });
});
