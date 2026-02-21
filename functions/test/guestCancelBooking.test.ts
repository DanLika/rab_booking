const test = require("firebase-functions-test")();

// Mock dependencies
const mockFirestoreInstance = {
  collection: jest.fn().mockReturnThis(),
  doc: jest.fn().mockReturnThis(),
  runTransaction: jest.fn(),
  update: jest.fn(),
};

jest.mock("../src/firebase", () => {
  const firestoreFn = jest.fn(() => mockFirestoreInstance);
  Object.assign(firestoreFn, {
    FieldValue: {
      serverTimestamp: jest.fn().mockReturnValue("MOCK_TIMESTAMP"),
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

jest.mock("../src/sentry", () => ({
  setUser: jest.fn(),
}));

jest.mock("../src/utils/rateLimit", () => ({
  checkRateLimit: jest.fn().mockReturnValue(true),
}));

jest.mock("../src/utils/securityMonitoring", () => ({
  logRateLimitExceeded: jest.fn().mockResolvedValue(true),
}));

jest.mock("../src/emailService", () => ({
  sendBookingCancellationEmail: jest.fn(),
}));

jest.mock("../src/fcmService", () => ({
  sendGuestCancellationPushNotification: jest.fn().mockResolvedValue(true),
}));

// Mock findBookingById
jest.mock("../src/utils/bookingLookup", () => ({
  findBookingById: jest.fn(),
}));

// Mock dateValidation
jest.mock("../src/utils/dateValidation", () => ({
  safeToDate: jest.fn((d) => new Date(d)),
}));

import { guestCancelBooking } from "../src/guestCancelBooking";
import { checkRateLimit } from "../src/utils/rateLimit";
import { findBookingById } from "../src/utils/bookingLookup";
import { sendBookingCancellationEmail } from "../src/emailService";

const { wrap } = test;

describe("guestCancelBooking", () => {
  const wrapped = wrap(guestCancelBooking);

  const validData = {
    bookingId: "bk-123",
    bookingReference: "REF-123",
    guestEmail: "guest@example.com",
  };

  const mockBooking = {
    booking_reference: "REF-123",
    guest_email: "guest@example.com",
    status: "confirmed",
    property_id: "prop-1",
    unit_id: "unit-1",
    check_in: "2026-06-01",
    check_out: "2026-06-05",
    owner_id: "owner-1",
  };

  const mockWidgetSettings = {
    allow_guest_cancellation: true,
    cancellation_deadline_hours: 48,
    email_config: {
      enabled: true,
      is_configured: true,
      from_email: "noreply@bookbed.io",
    },
  };

  beforeEach(() => {
    jest.clearAllMocks();
    (checkRateLimit as jest.Mock).mockReturnValue(true);
    (findBookingById as jest.Mock).mockResolvedValue({
      doc: { ref: { id: "bk-123", update: jest.fn() } },
      data: mockBooking,
    });
    mockFirestoreInstance.runTransaction.mockImplementation(async (callback) => {
      // Create a mock transaction object
      const mockTransaction = {
        get: jest.fn().mockImplementation((ref) => {
          // Identify request by checking if it's the widget settings ref
          // Since ref.path might not be set in our simplistic mock chain,
          // we can check if we are getting the booking ref or widget settings ref.

          // In the code:
          // 1. widgetSettingsRef = db...doc(unitId)
          // 2. bookingRef = bookingDoc.ref

          // We can use a simple toggle or verify calls sequence, but a safer way
          // in this test setup is to check if it matches the booking reference.

          // Let's assume the FIRST call is widget settings (based on code flow)
          // and SECOND call is booking.
          // BUT transaction.get() calls order matters.
          // Code: 1. widgetSettingsRef, 3. bookingRef.

          // A more robust way: Mock the refs differently in `findBookingById` vs `db.collection...`
          // But here `db` is mocked globally.

          // Let's rely on the fact that `mockBooking` has `booking_reference` and `mockWidgetSettings` does not.
          // Wait, we are returning data based on the ref.

          // Let's modify the return value based on call count for this specific test case,
          // OR try to infer from the context.

          // Ideally, we'd check the collection path.
          // In our mock chain: db.collection().doc().collection().doc().
          // We haven't implemented path tracking in the chain.

          // Let's try to detect if it's the booking ref.
          // `findBookingById` returns `{ doc: { ref: ... } }`.
          // We can tag that ref.

          if (ref.id === "bk-123") {
             return { exists: true, data: () => mockBooking };
          }

          // Otherwise assume widget settings
          return { exists: true, data: () => mockWidgetSettings };
        }),
        update: jest.fn(),
      };
      return callback(mockTransaction);
    });
  });

  it("should throw error if rate limit exceeded", async () => {
    (checkRateLimit as jest.Mock).mockReturnValue(false);
    await expect(wrapped({ data: validData })).rejects.toThrow("Too many cancellation attempts");
  });

  it("should throw error if arguments missing", async () => {
    await expect(wrapped({ data: {} })).rejects.toThrow("Missing required fields");
  });

  it("should throw error if booking not found", async () => {
    (findBookingById as jest.Mock).mockResolvedValue(null);
    await expect(wrapped({ data: validData })).rejects.toThrow("Booking not found");
  });

  it("should throw error if reference mismatch", async () => {
    (findBookingById as jest.Mock).mockResolvedValue({
      doc: { ref: {} },
      data: { ...mockBooking, booking_reference: "WRONG" },
    });
    await expect(wrapped({ data: validData })).rejects.toThrow("Invalid booking reference");
  });

  it("should throw error if email mismatch", async () => {
    (findBookingById as jest.Mock).mockResolvedValue({
      doc: { ref: {} },
      data: { ...mockBooking, guest_email: "other@example.com" },
    });
    await expect(wrapped({ data: validData })).rejects.toThrow("Email does not match");
  });

  it("should successfully cancel booking", async () => {
    const result = await wrapped({ data: validData });

    expect(result.success).toBe(true);
    expect(result.message).toContain("Booking cancelled successfully");
    expect(mockFirestoreInstance.runTransaction).toHaveBeenCalled();
    expect(sendBookingCancellationEmail).toHaveBeenCalled();
  });

  it("should handle idempotent cancellation (already cancelled)", async () => {
    mockFirestoreInstance.runTransaction.mockImplementation(async (callback) => {
        const mockTransaction = {
          get: jest.fn().mockImplementation((ref) => {
            if (ref.id === "bk-123") {
                // Return already cancelled booking
                return { exists: true, data: () => ({ ...mockBooking, status: "cancelled" }) };
            }
            return { exists: true, data: () => mockWidgetSettings };
          }),
          update: jest.fn(),
        };
        return callback(mockTransaction);
      });

    const result = await wrapped({ data: validData });

    // Should return success but not re-update
    expect(result.success).toBe(true);
  });
});
