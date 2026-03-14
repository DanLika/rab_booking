const test = require("firebase-functions-test")();

// Setup mocks inside the factory to avoid hoisting issues
jest.mock("../src/firebase", () => {
  const mockFirestoreInstance = {
    collection: jest.fn().mockReturnThis(),
    collectionGroup: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    get: jest.fn(),
    update: jest.fn().mockResolvedValue(true),
    runTransaction: jest.fn(),
  };

  const firestoreFn = jest.fn(() => mockFirestoreInstance);

  Object.assign(firestoreFn, {
    FieldValue: {
      serverTimestamp: jest.fn().mockReturnValue("mocked-timestamp"),
    },
    Timestamp: {
      now: () => {
        const now = new Date();
        return {
          toDate: () => now,
          toMillis: () => now.getTime(),
        };
      },
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

jest.mock("../src/emailService", () => ({
  sendBookingCancellationEmail: jest.fn().mockResolvedValue(true),
}));

jest.mock("../src/utils/bookingHelpers", () => ({
  fetchPropertyAndUnitDetails: jest.fn().mockResolvedValue({
    propertyName: "Test Property",
    unitName: "Test Unit",
  }),
}));

jest.mock("../src/fcmService", () => ({
  sendGuestCancellationPushNotification: jest.fn().mockResolvedValue(true),
}));

jest.mock("../src/utils/bookingLookup", () => ({
  findBookingById: jest.fn(),
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

import { guestCancelBooking } from "../src/guestCancelBooking";
import { findBookingById } from "../src/utils/bookingLookup";
import { checkRateLimit } from "../src/utils/rateLimit";
import { db } from "../src/firebase";

const { wrap } = test;

describe("guestCancelBooking", () => {
  const mockDb = db as any;

  beforeEach(() => {
    jest.clearAllMocks();

    // Default rate limit to pass
    (checkRateLimit as jest.Mock).mockReturnValue(true);
  });

  it("should throw error if required fields are missing", async () => {
    const wrapped = wrap(guestCancelBooking);
    await expect(wrapped({ data: {} })).rejects.toThrow("Missing required fields");
  });

  it("should throw error if rate limit is exceeded", async () => {
    (checkRateLimit as jest.Mock).mockReturnValueOnce(false);
    const wrapped = wrap(guestCancelBooking);
    await expect(
      wrapped({
        data: {
          booking_id: "bk-1",
          booking_reference: "REF-1",
          guest_email: "test@example.com",
        },
      })
    ).rejects.toThrow("Too many cancellation attempts");
  });

  it("should throw error if booking is not found", async () => {
    (findBookingById as jest.Mock).mockResolvedValueOnce(null);

    const wrapped = wrap(guestCancelBooking);
    await expect(
      wrapped({
        data: {
          booking_id: "bk-1",
          booking_reference: "REF-1",
          guest_email: "test@example.com",
        },
      })
    ).rejects.toThrow("Booking not found");
  });

  it("should throw error if booking reference doesn't match", async () => {
    (findBookingById as jest.Mock).mockResolvedValueOnce({
      doc: { ref: {} },
      data: {
        booking_reference: "REAL-REF",
      },
    });

    const wrapped = wrap(guestCancelBooking);
    await expect(
      wrapped({
        data: {
          booking_id: "bk-1",
          booking_reference: "WRONG-REF",
          guest_email: "test@example.com",
        },
      })
    ).rejects.toThrow("Invalid booking reference");
  });

  it("should throw error if guest email doesn't match", async () => {
    (findBookingById as jest.Mock).mockResolvedValueOnce({
      doc: { ref: {} },
      data: {
        booking_reference: "REF-1",
        guest_email: "real@example.com",
      },
    });

    const wrapped = wrap(guestCancelBooking);
    await expect(
      wrapped({
        data: {
          booking_id: "bk-1",
          booking_reference: "REF-1",
          guest_email: "wrong@example.com",
        },
      })
    ).rejects.toThrow("Email does not match");
  });

  it("should throw error if booking status is not confirmed or pending", async () => {
    (findBookingById as jest.Mock).mockResolvedValueOnce({
      doc: { ref: {} },
      data: {
        booking_reference: "REF-1",
        guest_email: "test@example.com",
        status: "completed",
      },
    });

    const wrapped = wrap(guestCancelBooking);
    await expect(
      wrapped({
        data: {
          booking_id: "bk-1",
          booking_reference: "REF-1",
          guest_email: "test@example.com",
        },
      })
    ).rejects.toThrow("Cannot cancel booking with status: completed");
  });

  it("should successfully cancel booking", async () => {
    // Setup mock booking
    const mockBookingRef = { update: jest.fn().mockResolvedValue(true) };
    const mockBooking = {
      booking_reference: "REF-1",
      guest_email: "test@example.com",
      status: "confirmed",
      property_id: "prop-1",
      unit_id: "unit-1",
      check_in: { toDate: () => new Date(Date.now() + 100 * 60 * 60 * 1000) }, // Future date > 48hrs
      check_out: { toDate: () => new Date(Date.now() + 200 * 60 * 60 * 1000) },
      payment_status: "unpaid",
    };

    (findBookingById as jest.Mock).mockResolvedValueOnce({
      doc: { ref: mockBookingRef },
      data: mockBooking,
    });

    // Mock the transaction
    const mockTransaction = {
      get: jest.fn().mockImplementation((ref) => {
        // Mock widget settings
        if (ref === mockDb.collection().doc().collection().doc()) {
          return Promise.resolve({
            exists: true,
            data: () => ({
              allow_guest_cancellation: true,
              cancellation_deadline_hours: 48,
              email_config: { enabled: false }, // avoid sending email for this test
            }),
          });
        }
        // Mock booking re-fetch inside transaction
        return Promise.resolve({
          exists: true,
          data: () => mockBooking,
        });
      }),
      update: jest.fn(),
    };

    mockDb.runTransaction.mockImplementationOnce((cb: any) => cb(mockTransaction));

    const wrapped = wrap(guestCancelBooking);
    const result = await wrapped({
      data: {
        booking_id: "bk-1",
        booking_reference: "REF-1",
        guest_email: "test@example.com",
      },
    });

    expect(result.success).toBe(true);
    expect(result.bookingReference).toBe("REF-1");
    expect(mockTransaction.update).toHaveBeenCalled();
  });
});
