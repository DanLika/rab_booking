// Mock external dependencies
jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logWarn: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
}));

jest.mock("../src/sentry", () => ({
  setUser: jest.fn(),
}));

jest.mock("../src/utils/rateLimit", () => ({
  checkRateLimit: jest.fn().mockReturnValue(true),
}));

jest.mock("../src/utils/securityMonitoring", () => ({
  logRateLimitExceeded: jest.fn().mockResolvedValue(undefined),
}));

jest.mock("../src/emailService", () => ({
  sendBookingCancellationEmail: jest.fn().mockResolvedValue(true),
}));

jest.mock("../src/fcmService", () => ({
  sendGuestCancellationPushNotification: jest.fn().mockResolvedValue(true),
}));

jest.mock("../src/utils/bookingHelpers", () => ({
  fetchPropertyAndUnitDetails: jest.fn().mockResolvedValue({
    propertyName: "Test Property",
    unitName: "Test Unit",
  }),
}));

const mockRefundsCreate = jest.fn().mockResolvedValue({ id: "re_12345" });

// Mock Stripe
jest.mock("stripe", () => {
  return jest.fn().mockImplementation(() => ({
    refunds: {
      create: mockRefundsCreate,
    },
  }));
});

const mockBookingData = {
  booking_reference: "BB-123",
  guest_email: "guest@example.com",
  status: "confirmed",
  property_id: "prop-1",
  unit_id: "unit-1",
  check_in: { toDate: () => new Date(Date.now() + 86400000 * 5) }, // 5 days from now
  check_out: { toDate: () => new Date(Date.now() + 86400000 * 10) },
  payment_status: "paid",
  payment_method: "stripe",
  paid_amount: 100,
  stripe_payment_intent_id: "pi_123",
};

const mockWidgetSettings = {
  allow_guest_cancellation: true,
  cancellation_deadline_hours: 48,
  stripe_config: { secret_key: "sk_test_123" },
  email_config: {
    enabled: true,
    is_configured: true,
    from_email: "test@example.com",
  },
};

// We will explicitly control the mocked transaction object so we can assert on it
const mockTransactionGet = jest.fn();
const mockTransactionUpdate = jest.fn();

const mockUpdate = jest.fn();
const mockCollection = jest.fn();
const mockDoc = jest.fn(() => ({
  collection: mockCollection,
  update: mockUpdate,
}));
mockCollection.mockImplementation(() => ({
  doc: mockDoc,
}));

// The booking reference
const mockBookingRef = { update: mockUpdate, path: "mock/booking/ref" };

// Provide a mock for findBookingById BEFORE importing module
jest.mock("../src/utils/bookingLookup", () => ({
  findBookingById: jest.fn().mockResolvedValue({
    doc: {
      ref: mockBookingRef,
      exists: true,
    },
    data: mockBookingData,
  }),
}));

// Setup complete firebase-admin mock
jest.mock("firebase-admin", () => {
  const mockServerTimestamp = jest.fn(() => new Date());

  const mockRunTransaction = jest.fn(async (callback) => {
    const mockTransaction = {
      get: mockTransactionGet,
      update: mockTransactionUpdate,
    };
    return callback(mockTransaction);
  });

  const mockFirestore = jest.fn(() => ({
    collection: mockCollection,
    runTransaction: mockRunTransaction,
  })) as any;

  mockFirestore.FieldValue = {
    serverTimestamp: mockServerTimestamp,
  };

  return {
    firestore: mockFirestore,
    initializeApp: jest.fn(),
    apps: { length: 1 },
  };
});

// Setup exact same firebase module export
jest.mock("../src/firebase", () => {
  const admin = require("firebase-admin");
  return {
    admin,
    db: admin.firestore(),
  };
});

import { guestCancelBooking } from "../src/guestCancelBooking";
import { HttpsError } from "firebase-functions/v2/https";
import { findBookingById } from "../src/utils/bookingLookup";
import { checkRateLimit } from "../src/utils/rateLimit";

describe("guestCancelBooking", () => {
  beforeEach(() => {
    jest.clearAllMocks();

    // Setup default successful transaction mocks
    mockTransactionGet.mockImplementation((ref) => {
      // Mock widget settings ref vs booking ref
      if (ref === mockBookingRef) {
        return Promise.resolve({
          exists: true,
          data: () => mockBookingData,
        });
      }
      // Widget settings
      return Promise.resolve({
        exists: true,
        data: () => mockWidgetSettings,
      });
    });

    // Default findBookingById success
    (findBookingById as jest.Mock).mockResolvedValue({
      doc: {
        ref: mockBookingRef,
        exists: true,
      },
      data: mockBookingData,
    });
  });

  // Wrapper for v2 callable functions
  const wrapFunction = (fn: any) => {
    return async (data: any, context?: any) => {
      const req = {
        data: data.data || data,
        rawRequest: data.rawRequest || { ip: "127.0.0.1", headers: {} },
      };

      if (fn.run) {
        return fn.run(req);
      }
      try {
        return await fn(req);
      } catch (err) {
        throw err;
      }
    };
  };

  const validRequest = {
    data: {
      bookingId: "booking-123",
      bookingReference: "BB-123",
      guestEmail: "guest@example.com",
    }
  };

  it("should throw if rate limited", async () => {
    (checkRateLimit as jest.Mock).mockReturnValueOnce(false);

    await expect(wrapFunction(guestCancelBooking)(validRequest)).rejects.toThrow(
      new HttpsError("resource-exhausted", "Too many cancellation attempts. Please wait a minute and try again.")
    );
  });

  it("should throw if required fields are missing", async () => {
    const invalidReq = { data: { bookingId: "b-1" } }; // missing reference and email

    await expect(wrapFunction(guestCancelBooking)(invalidReq)).rejects.toThrow(
      new HttpsError("invalid-argument", "Missing required fields: booking_id, booking_reference, guest_email")
    );
  });

  it("should throw if booking not found", async () => {
    (findBookingById as jest.Mock).mockResolvedValueOnce(null);

    await expect(wrapFunction(guestCancelBooking)(validRequest)).rejects.toThrow(
      new HttpsError("not-found", "Booking not found")
    );
  });

  it("should throw if booking reference doesn't match", async () => {
    const req = {
      data: {
        ...validRequest.data,
        bookingReference: "WRONG-REF",
      }
    };

    await expect(wrapFunction(guestCancelBooking)(req)).rejects.toThrow(
      new HttpsError("permission-denied", "Invalid booking reference")
    );
  });

  it("should throw if guest email doesn't match", async () => {
    const req = {
      data: {
        ...validRequest.data,
        guestEmail: "wrong@email.com",
      }
    };

    await expect(wrapFunction(guestCancelBooking)(req)).rejects.toThrow(
      new HttpsError("permission-denied", "Email does not match booking records")
    );
  });

  it("should throw if booking status is not confirmed/pending", async () => {
    (findBookingById as jest.Mock).mockResolvedValueOnce({
      doc: { ref: mockBookingRef },
      data: { ...mockBookingData, status: "completed" },
    });

    await expect(wrapFunction(guestCancelBooking)(validRequest)).rejects.toThrow(
      new HttpsError("failed-precondition", "Cannot cancel booking with status: completed")
    );
  });

  it("should throw if guest cancellation is disabled in widget settings", async () => {
    mockTransactionGet.mockImplementation((ref) => {
      if (ref === mockBookingRef) {
        return Promise.resolve({ exists: true, data: () => mockBookingData });
      }
      return Promise.resolve({
        exists: true,
        data: () => ({ ...mockWidgetSettings, allow_guest_cancellation: false }),
      });
    });

    await expect(wrapFunction(guestCancelBooking)(validRequest)).rejects.toThrow(
      new HttpsError("permission-denied", "Guest cancellation is not allowed for this property. Please contact the property owner.")
    );
  });

  it("should throw if cancellation deadline has passed", async () => {
    // Make check-in date within 24 hours, but deadline is 48 hours
    const closeCheckIn = new Date(Date.now() + 86400000 * 1); // 1 day

    mockTransactionGet.mockImplementation((ref) => {
      if (ref === mockBookingRef) {
        return Promise.resolve({
          exists: true,
          data: () => ({ ...mockBookingData, check_in: { toDate: () => closeCheckIn } })
        });
      }
      return Promise.resolve({ exists: true, data: () => mockWidgetSettings });
    });

    await expect(wrapFunction(guestCancelBooking)(validRequest)).rejects.toThrow(
      new HttpsError("failed-precondition", "Cancellation deadline has passed during processing.")
    );
  });

  it("should process cancellation and stripe refund correctly", async () => {
    const result = await wrapFunction(guestCancelBooking)(validRequest);

    // Assert transaction update was called with correct data
    expect(mockTransactionUpdate).toHaveBeenCalledWith(mockBookingRef, expect.objectContaining({
      status: "cancelled",
      cancelled_by: "guest",
      refund_amount: 100, // From mockBookingData.paid_amount
      refund_status: "pending_stripe",
    }));

    // Assert Stripe refund was processed
    const Stripe = require("stripe");
    expect(Stripe).toHaveBeenCalled();
    expect(mockRefundsCreate).toHaveBeenCalledWith(expect.objectContaining({
      amount: 10000, // 100 * 100
    }));

    // Assert emails and notifications sent
    const { sendBookingCancellationEmail } = require("../src/emailService");
    expect(sendBookingCancellationEmail).toHaveBeenCalled();

    expect(result.success).toBe(true);
    expect(result.message).toContain("Booking cancelled successfully");
  });

  it("should handle already cancelled idempotency check gracefully", async () => {
    mockTransactionGet.mockImplementation((ref) => {
      if (ref === mockBookingRef) {
        return Promise.resolve({
          exists: true,
          data: () => ({ ...mockBookingData, status: "cancelled" })
        });
      }
      return Promise.resolve({ exists: true, data: () => mockWidgetSettings });
    });

    const result = await wrapFunction(guestCancelBooking)(validRequest);

    // Assert transaction update was NOT called again
    expect(mockTransactionUpdate).not.toHaveBeenCalled();

    // Should still return success
    expect(result.success).toBe(true);
  });
});
