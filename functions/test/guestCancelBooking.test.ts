const test = require("firebase-functions-test")();

// Mock all internal dependencies
jest.mock("../src/firebase", () => {
  const mockFirestoreInstance = {
    collection: jest.fn().mockReturnThis(),
    collectionGroup: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    get: jest.fn(),
    update: jest.fn().mockResolvedValue(true),
    runTransaction: jest.fn(),
  };

  const firestoreFn = jest.fn(() => mockFirestoreInstance);
  Object.assign(firestoreFn, {
    FieldValue: {
      serverTimestamp: jest.fn().mockReturnValue("mock-server-timestamp"),
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

jest.mock("../src/utils/bookingLookup", () => ({
  findBookingById: jest.fn(),
}));

jest.mock("../src/utils/bookingHelpers", () => ({
  fetchPropertyAndUnitDetails: jest.fn().mockResolvedValue({
    propertyName: "Test Property",
    unitName: "Test Unit",
  }),
}));

jest.mock("../src/emailService", () => ({
  sendBookingCancellationEmail: jest.fn().mockResolvedValue(true),
}));

jest.mock("../src/fcmService", () => ({
  sendGuestCancellationPushNotification: jest.fn().mockResolvedValue(true),
}));

// Mock Stripe
const mockRefundsCreate = jest.fn().mockResolvedValue({ id: "re_test123" });
jest.mock("stripe", () => {
  return jest.fn().mockImplementation(() => ({
    refunds: {
      create: mockRefundsCreate,
    },
  }));
});

import { guestCancelBooking } from "../src/guestCancelBooking";
import { db } from "../src/firebase";
import { findBookingById } from "../src/utils/bookingLookup";
import { checkRateLimit } from "../src/utils/rateLimit";

const { wrap } = test;

describe("guestCancelBooking", () => {
  const wrapped = wrap(guestCancelBooking);
  const mockDb = db as any;
  const mockFindBookingById = findBookingById as jest.Mock;
  const mockCheckRateLimit = checkRateLimit as jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();

    mockCheckRateLimit.mockReturnValue(true);

    mockDb.runTransaction.mockImplementation(async (callback: any) => {
      const transaction = {
        get: jest.fn(),
        update: jest.fn(),
      };

      // Mock transaction get for widget settings
      transaction.get.mockResolvedValueOnce({
        exists: true,
        data: () => ({
          allow_guest_cancellation: true,
          cancellation_deadline_hours: 48,
          stripe_config: { secret_key: "sk_test_123" },
          email_config: {
            enabled: true,
            is_configured: true,
            from_email: "test@example.com"
          }
        }),
      });

      // Mock transaction get for fresh booking
      transaction.get.mockResolvedValueOnce({
        exists: true,
        data: () => ({
          status: "confirmed",
          check_in: new Date(Date.now() + 72 * 60 * 60 * 1000), // 72 hours from now
          payment_status: "paid",
          payment_method: "stripe",
          paid_amount: 100,
          stripe_payment_intent_id: "pi_test123",
          property_id: "prop-1",
          unit_id: "unit-1",
        }),
      });

      return callback(transaction);
    });
  });

  const validRequest = {
    bookingId: "book-123",
    bookingReference: "REF-123",
    guestEmail: "guest@example.com",
  };

  it("should throw rate limit error if exceeded", async () => {
    mockCheckRateLimit.mockReturnValueOnce(false);
    await expect(wrapped({ data: validRequest, rawRequest: { ip: "1.2.3.4" } }))
      .rejects.toThrow("Too many cancellation attempts");
  });

  it("should throw error if required fields are missing", async () => {
    await expect(wrapped({ data: {} }))
      .rejects.toThrow("Missing required fields");
  });

  it("should throw error if booking not found", async () => {
    mockFindBookingById.mockResolvedValueOnce(null);
    await expect(wrapped({ data: validRequest }))
      .rejects.toThrow("Booking not found");
  });

  it("should throw error if booking reference is invalid", async () => {
    mockFindBookingById.mockResolvedValueOnce({
      doc: { ref: { update: jest.fn() } },
      data: {
        booking_reference: "WRONG-REF",
      },
    });

    await expect(wrapped({ data: validRequest }))
      .rejects.toThrow("Invalid booking reference");
  });

  it("should throw error if guest email does not match", async () => {
    mockFindBookingById.mockResolvedValueOnce({
      doc: { ref: { update: jest.fn() } },
      data: {
        booking_reference: "REF-123",
        guest_email: "wrong@example.com",
      },
    });

    await expect(wrapped({ data: validRequest }))
      .rejects.toThrow("Email does not match booking records");
  });

  it("should throw error if booking is not cancellable (wrong status)", async () => {
    mockFindBookingById.mockResolvedValueOnce({
      doc: { ref: { update: jest.fn() } },
      data: {
        booking_reference: "REF-123",
        guest_email: "guest@example.com",
        status: "cancelled",
      },
    });

    await expect(wrapped({ data: validRequest }))
      .rejects.toThrow("Cannot cancel booking with status: cancelled");
  });

  it("should successfully cancel a booking and process refund", async () => {
    mockFindBookingById.mockResolvedValueOnce({
      doc: { ref: { update: jest.fn() } },
      data: {
        booking_reference: "REF-123",
        guest_email: "guest@example.com",
        status: "confirmed",
        property_id: "prop-1",
        unit_id: "unit-1",
      },
    });

    const result = await wrapped({ data: validRequest });

    expect(result.success).toBe(true);
    expect(mockDb.runTransaction).toHaveBeenCalled();
    expect(mockRefundsCreate).toHaveBeenCalledWith(expect.objectContaining({
      payment_intent: "pi_test123",
      amount: 10000,
    }));
  });

  it("should handle idempotency if already cancelled inside transaction", async () => {
    mockFindBookingById.mockResolvedValueOnce({
      doc: { ref: { update: jest.fn() } },
      data: {
        booking_reference: "REF-123",
        guest_email: "guest@example.com",
        status: "confirmed", // Outer check passes
        property_id: "prop-1",
        unit_id: "unit-1",
      },
    });

    mockDb.runTransaction.mockImplementationOnce(async (callback: any) => {
      const transaction = {
        get: jest.fn(),
        update: jest.fn(),
      };
      // Widget settings
      transaction.get.mockResolvedValueOnce({ exists: true, data: () => ({ allow_guest_cancellation: true }) });
      // Fresh booking inside transaction is ALREADY CANCELLED
      transaction.get.mockResolvedValueOnce({
        exists: true,
        data: () => ({
          status: "cancelled",
          cancelled_by: "guest",
        }),
      });
      return callback(transaction);
    });

    const result = await wrapped({ data: validRequest });

    expect(result.success).toBe(true); // Still returns success to user
    expect(mockRefundsCreate).not.toHaveBeenCalled(); // No double refund
  });
});
