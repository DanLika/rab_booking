const test = require("firebase-functions-test")();
// Setup mocks inside the factory to avoid hoisting issues
jest.mock("../src/firebase", () => {
  const mockFirestoreInstance = {
    runTransaction: jest.fn(),
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    get: jest.fn(),
    update: jest.fn(),
  };

  const firestoreFn = jest.fn(() => mockFirestoreInstance);
  Object.assign(firestoreFn, {
    FieldValue: {
      serverTimestamp: jest.fn().mockReturnValue("mock-timestamp"),
    },
  });

  return {
    admin: {
      firestore: firestoreFn,
    },
    db: mockFirestoreInstance,
  };
});

jest.mock("../src/utils/bookingLookup", () => ({
  findBookingById: jest.fn(),
}));

jest.mock("../src/utils/rateLimit", () => ({
  checkRateLimit: jest.fn(),
}));

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logWarn: jest.fn(),
}));

jest.mock("../src/sentry", () => ({
  setUser: jest.fn(),
}));

jest.mock("../src/utils/securityMonitoring", () => ({
  logRateLimitExceeded: jest.fn().mockResolvedValue(true),
}));

jest.mock("../src/emailService", () => ({
  sendBookingCancellationEmail: jest.fn().mockResolvedValue(true),
}));

jest.mock("../src/fcmService", () => ({
  sendGuestCancellationPushNotification: jest.fn().mockResolvedValue(true),
}));

jest.mock("../src/utils/bookingHelpers", () => ({
  fetchPropertyAndUnitDetails: jest.fn().mockResolvedValue({
    propertyName: "Test Prop",
    unitName: "Test Unit",
  }),
}));

import { guestCancelBooking } from "../src/guestCancelBooking";
import { findBookingById } from "../src/utils/bookingLookup";
import { checkRateLimit } from "../src/utils/rateLimit";
import { db } from "../src/firebase";
import { HttpsError } from "firebase-functions/v2/https";

const { wrap } = test;

describe("guestCancelBooking", () => {
  const mockDb = db as any;

  beforeEach(() => {
    jest.clearAllMocks();
    (checkRateLimit as jest.Mock).mockReturnValue(true);
  });

  const validRequest = {
    data: {
      bookingId: "booking-123",
      bookingReference: "REF-123",
      guestEmail: "guest@example.com",
    },
    rawRequest: { ip: "127.0.0.1" }
  };

  it("should throw rate limit error if exceeded", async () => {
    (checkRateLimit as jest.Mock).mockReturnValueOnce(false);

    const wrapped = wrap(guestCancelBooking);
    await expect(wrapped(validRequest as any)).rejects.toThrow(
      new HttpsError("resource-exhausted", "Too many cancellation attempts. Please wait a minute and try again.")
    );
  });

  it("should throw invalid-argument if missing fields", async () => {
    const wrapped = wrap(guestCancelBooking);
    await expect(wrapped({ data: {}, rawRequest: {} } as any)).rejects.toThrow(
      new HttpsError("invalid-argument", "Missing required fields: booking_id, booking_reference, guest_email")
    );
  });

  it("should throw not-found if booking not found", async () => {
    (findBookingById as jest.Mock).mockResolvedValueOnce(null);

    const wrapped = wrap(guestCancelBooking);
    await expect(wrapped(validRequest as any)).rejects.toThrow(
      new HttpsError("not-found", "Booking not found")
    );
  });

  it("should throw permission-denied if reference doesn't match", async () => {
    (findBookingById as jest.Mock).mockResolvedValueOnce({
      doc: { ref: {} },
      data: { booking_reference: "WRONG-REF" }
    });

    const wrapped = wrap(guestCancelBooking);
    await expect(wrapped(validRequest as any)).rejects.toThrow(
      new HttpsError("permission-denied", "Invalid booking reference")
    );
  });

  it("should throw permission-denied if email doesn't match", async () => {
    (findBookingById as jest.Mock).mockResolvedValueOnce({
      doc: { ref: {} },
      data: {
        booking_reference: "REF-123",
        guest_email: "wrong@example.com"
      }
    });

    const wrapped = wrap(guestCancelBooking);
    await expect(wrapped(validRequest as any)).rejects.toThrow(
      new HttpsError("permission-denied", "Email does not match booking records")
    );
  });

  it("should throw failed-precondition if status is not confirm/pending", async () => {
    (findBookingById as jest.Mock).mockResolvedValueOnce({
      doc: { ref: {} },
      data: {
        booking_reference: "REF-123",
        guest_email: "guest@example.com",
        status: "completed"
      }
    });

    const wrapped = wrap(guestCancelBooking);
    await expect(wrapped(validRequest as any)).rejects.toThrow(
      new HttpsError("failed-precondition", "Cannot cancel booking with status: completed")
    );
  });

  it("should process cancellation successfully in transaction", async () => {
    (findBookingById as jest.Mock).mockResolvedValueOnce({
      doc: { ref: { update: jest.fn() } },
      data: {
        booking_reference: "REF-123",
        guest_email: "guest@example.com",
        status: "confirmed",
        property_id: "prop-1",
        unit_id: "unit-1"
      }
    });

    // Mock successful transaction result to skip the internal transaction logic
    // which is hard to mock perfectly without refactoring
    mockDb.runTransaction.mockImplementationOnce(async () => {
      return {
        alreadyCancelled: false,
        refundAmount: 0,
        refundStatus: "not_applicable",
        paymentMethod: "none",
        widgetSettings: { email_config: { enabled: false } }
      };
    });

    const wrapped = wrap(guestCancelBooking);
    const result = await wrapped(validRequest as any);

    expect(result.success).toBe(true);
    expect(result.bookingReference).toBe("REF-123");
    expect(mockDb.runTransaction).toHaveBeenCalled();
  });
});
