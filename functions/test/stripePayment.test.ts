/**
 * Unit tests for stripePayment.ts cloud functions.
 * Mocks Firebase and Stripe services.
 */

// Using require for firebase-functions-test to avoid ESM/CJS interop issues
// eslint-disable-next-line @typescript-eslint/no-var-requires
const test = require("firebase-functions-test")();
import { HttpsError } from "firebase-functions/v2/https";

// Import the functions to be tested
import { createStripeCheckoutSession, handleStripeWebhook } from "../src/stripePayment";

// Initialize the test environment
const { wrap } = test;

// Mock dependencies
jest.mock("firebase-functions/params", () => ({
  defineSecret: () => ({
    value: () => "mock-stripe-webhook-secret",
  }),
}));
jest.mock("../src/firebase", () => ({
  admin: {
    firestore: {
      FieldValue: {
        serverTimestamp: () => "mock-server-timestamp",
        delete: () => "mock-delete-timestamp",
      },
      Timestamp: {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        fromDate: (date: any) => ({
          toDate: () => date,
          toMillis: () => date.getTime(),
        }), // Mimic Timestamp object
        now: () => {
          const now = new Date();
          return {
            toDate: () => now,
            toMillis: () => now.getTime(),
          };
        }, // Mimic Timestamp object
      },
    },
  },
  db: {
    collection: jest.fn(),
    runTransaction: jest.fn(),
  },
}));

jest.mock("../src/stripe", () => ({
  getStripeClient: jest.fn(),
}));

jest.mock("../src/emailService", () => ({
  sendBookingApprovedEmail: jest.fn(),
  sendOwnerNotificationEmail: jest.fn(),
}));

jest.mock("../src/notificationService", () => ({
  createPaymentNotification: jest.fn(),
}));

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logWarn: jest.fn(),
}));

jest.mock("../src/utils/rateLimit", () => ({
  checkRateLimit: jest.fn().mockReturnValue(true), // Default to allow
}));

describe("Stripe Payment Functions", () => {
  // Mock Firestore and Stripe clients with explicit 'any' types for testing
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let mockDb: any, mockStripe: any;

  // Shared mock documents
  const mockPropertyDoc = {
    exists: true,
    data: () => ({ name: "Test Property", images: ["image-url"] }),
  };
  const mockUnitDoc = {
    exists: true,
    data: () => ({ name: "Test Unit" }),
  };
  const mockOwnerDoc = {
    exists: true,
    data: () => ({ stripe_account_id: "acct_12345" }),
  };

  beforeEach(() => {
    // Reset mocks before each test
    jest.clearAllMocks();

    // Setup mock Firestore
    mockDb = require("../src/firebase").db;
    const firestoreMock = {
      collection: jest.fn().mockReturnThis(),
      doc: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get: jest.fn().mockResolvedValue({ docs: [], empty: true }),
      update: jest.fn().mockResolvedValue(true),
      set: jest.fn().mockResolvedValue(true),
      id: "mock-generated-id", // Add ID for placeholder booking generation
    };
    mockDb.collection.mockReturnValue(firestoreMock);


    // Setup mock Stripe
    mockStripe = {
      accounts: {
        retrieve: jest.fn(),
      },
      checkout: {
        sessions: {
          create: jest.fn(),
        },
      },
    };
    const { getStripeClient } = require("../src/stripe");
    getStripeClient.mockReturnValue(mockStripe);

    // Explicitly reset mocks that have their behavior changed in tests
    const { checkRateLimit } = require("../src/utils/rateLimit");
    checkRateLimit.mockReturnValue(true);
  });

  describe("createStripeCheckoutSession", () => {
    // Dynamically generate future dates to avoid "date in the past" errors
    const getFutureDate = (days: number) => {
      const date = new Date();
      date.setDate(date.getDate() + days);
      return date.toISOString().split("T")[0]; // YYYY-MM-DD format
    };

    const validBookingData = {
      unitId: "unit-123",
      propertyId: "property-123",
      ownerId: "owner-123",
      checkIn: getFutureDate(10),
      checkOut: getFutureDate(15),
      guestName: "John Doe",
      guestEmail: "john.doe@example.com",
      guestPhone: "123456789",
      guestCount: 2,
      totalPrice: 500,
      depositAmount: 100,
      paymentOption: "deposit",
      notes: "Test notes",
      taxLegalAccepted: true,
    };

    const validReturnUrl = "https://jasko-rab.view.bookbed.io/calendar";

    const mockStripeAccount = {
      charges_enabled: true,
      capabilities: {
        card_payments: "active",
        transfers: "active",
      },
    };

    it("should create a checkout session successfully on the happy path", async () => {
      // Arrange
      // Mock Firestore document gets
      mockDb.collection().doc().get
        .mockResolvedValueOnce(mockPropertyDoc) // property
        .mockResolvedValueOnce(mockUnitDoc)     // unit
        .mockResolvedValueOnce(mockOwnerDoc);    // owner

      // Mock Stripe account verification
      mockStripe.accounts.retrieve.mockResolvedValue(mockStripeAccount);

      // Mock transaction to show no date conflicts
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      mockDb.runTransaction.mockImplementation(async (callback: any) => {
        const transaction = {
          get: jest.fn().mockResolvedValue({ docs: [] }), // No conflicting bookings
          set: jest.fn(),
        };
        return await callback(transaction);
      });

      // Mock Stripe session creation
      mockStripe.checkout.sessions.create.mockResolvedValue({
        id: "sess_123",
        url: "https://checkout.stripe.com/pay/sess_123",
      });

      const wrapped = wrap(createStripeCheckoutSession);

      // Act
      const result = await wrapped({
        data: { bookingData: validBookingData, returnUrl: validReturnUrl },
        auth: { uid: "test-user" },
      });

      // Assert
      expect(result.success).toBe(true);
      expect(result.sessionId).toBe("sess_123");
      expect(result.checkoutUrl).toContain("sess_123");
      expect(mockStripe.checkout.sessions.create).toHaveBeenCalled();
      expect(mockDb.runTransaction).toHaveBeenCalled();
    });

    it("should throw an error if bookingData is missing", async () => {
      const wrapped = wrap(createStripeCheckoutSession);
      await expect(wrapped({ data: { returnUrl: validReturnUrl } })).rejects.toThrow(
        new HttpsError("invalid-argument", "Booking data is required")
      );
    });

    it("should throw an error for a non-whitelisted return URL", async () => {
      const wrapped = wrap(createStripeCheckoutSession);
      await expect(
        wrapped({
          data: { bookingData: validBookingData, returnUrl: "https://evil-site.com" },
        })
      ).rejects.toThrow(
        new HttpsError("invalid-argument", "Invalid return URL. Please try again from the booking page.")
      );
    });

    it("should throw an error if rate limit is exceeded", async () => {
      const { checkRateLimit } = require("../src/utils/rateLimit");
      checkRateLimit.mockReturnValue(false);

      const wrapped = wrap(createStripeCheckoutSession);
      await expect(
        wrapped({
          data: { bookingData: validBookingData, returnUrl: validReturnUrl },
        })
      ).rejects.toThrow(
        new HttpsError("resource-exhausted", "Too many checkout attempts. Please wait a few minutes before trying again.")
      );
    });

    it("should throw an error if owner has no Stripe account", async () => {
      mockDb.collection().doc().get
        .mockResolvedValueOnce(mockPropertyDoc)
        .mockResolvedValueOnce(mockUnitDoc)
        .mockResolvedValueOnce({ exists: true, data: () => ({}) }); // Owner without stripe_account_id

      const wrapped = wrap(createStripeCheckoutSession);
      await expect(
        wrapped({
          data: { bookingData: validBookingData, returnUrl: validReturnUrl },
        })
      ).rejects.toThrow(
        new HttpsError("failed-precondition", "Owner has not connected their Stripe account. Please contact the property owner.")
      );
    });

     it("should throw an error if owner's Stripe account is not enabled for charges", async () => {
        mockDb.collection().doc().get
            .mockResolvedValueOnce(mockPropertyDoc)
            .mockResolvedValueOnce(mockUnitDoc)
            .mockResolvedValueOnce(mockOwnerDoc);
        mockStripe.accounts.retrieve.mockResolvedValue({ ...mockStripeAccount, charges_enabled: false });

        const wrapped = wrap(createStripeCheckoutSession);
        await expect(
            wrapped({
                data: { bookingData: validBookingData, returnUrl: validReturnUrl },
            })
        ).rejects.toThrow(
            new HttpsError("failed-precondition", "Property owner's payment account is not fully set up. Please contact the property owner.")
        );
    });

    it("should throw an error if there is a date conflict", async () => {
      mockDb.collection().doc().get
        .mockResolvedValueOnce(mockPropertyDoc)
        .mockResolvedValueOnce(mockUnitDoc)
        .mockResolvedValueOnce(mockOwnerDoc);
      mockStripe.accounts.retrieve.mockResolvedValue(mockStripeAccount);

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      mockDb.runTransaction.mockImplementation(async (callback: any) => {
        const transaction = {
          // Mock a conflicting booking with a valid document snapshot structure
          get: jest.fn().mockResolvedValue({
            docs: [
              {
                id: "conflict-booking",
                data: () => ({
                  status: "confirmed",
                  check_in: new Date(),
                  check_out: new Date(),
                }),
              },
            ],
          }),
          set: jest.fn(),
        };
        // This will cause the callback to throw the "already-exists" error
        return await callback(transaction);
      });

      const wrapped = wrap(createStripeCheckoutSession);
      await expect(
        wrapped({
          data: { bookingData: validBookingData, returnUrl: validReturnUrl },
        })
      ).rejects.toThrow(
        new HttpsError("already-exists", "Dates no longer available. Another booking is in progress or confirmed.")
      );
    });
  });

  describe("handleStripeWebhook", () => {
    // A mock Stripe event for checkout.session.completed
    const mockStripeEvent = {
      id: "evt_123",
      type: "checkout.session.completed",
      data: {
        object: {
          id: "sess_123",
          metadata: {
            placeholder_booking_id: "placeholder-123",
            property_id: "property-123",
            unit_id: "unit-123",
            owner_id: "owner-123",
            access_token_plaintext: "plain-text-token",
          },
          payment_intent: "pi_123",
        },
      },
    };

    // A mock placeholder booking document
    const mockPlaceholderBooking = {
      exists: true,
      data: () => ({
        status: "pending",
        deposit_amount: 100,
        unit_id: "unit-123",
        property_id: "property-123",
        owner_id: "owner-123",
        guest_name: "John Doe",
        guest_email: "john.doe@example.com",
        booking_reference: "REF-123",
        check_in: new Date(),
        check_out: new Date(),
        total_price: 500,
      }),
    };

    beforeEach(() => {
      // Mock the constructEvent to return our test event
      mockStripe.webhooks = {
        constructEvent: jest.fn().mockReturnValue(mockStripeEvent),
      };
    });

    it("should confirm the booking on a valid checkout.session.completed event", async () => {
      // Arrange
      // Mock Firestore reads for the placeholder and other details
      mockDb.collection().doc().get
        .mockResolvedValueOnce(mockPlaceholderBooking) // placeholder booking
        .mockResolvedValueOnce(mockPropertyDoc)        // property doc for email
        .mockResolvedValueOnce(mockUnitDoc)            // unit doc for email
        .mockResolvedValueOnce(mockOwnerDoc);          // owner doc for email

      const req = {
        headers: { "stripe-signature": "valid-sig" },
        rawBody: "raw-body",
      };
      const res = {
        status: jest.fn().mockReturnThis(),
        send: jest.fn(),
        json: jest.fn(),
      };

      // Act
      await handleStripeWebhook(req as any, res as any);

      // Assert
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          status: "confirmed",
          booking_id: "placeholder-123",
        })
      );
      // Verify that the booking status was updated in Firestore
      expect(mockDb.collection().doc().update).toHaveBeenCalledWith(
        expect.objectContaining({
          status: "confirmed",
          payment_status: "paid",
        })
      );
      // Verify that emails and notifications were sent
      const { sendBookingApprovedEmail } = require("../src/emailService");
      expect(sendBookingApprovedEmail).toHaveBeenCalled();
      const { createPaymentNotification } = require("../src/notificationService");
      expect(createPaymentNotification).toHaveBeenCalled();
    });

    it("should not process the event if the placeholder booking is already confirmed (idempotency)", async () => {
      const alreadyConfirmedBooking = {
        exists: true,
        data: () => ({
          ...mockPlaceholderBooking.data(),
          status: "confirmed", // ALREADY CONFIRMED
          stripe_session_id: "sess_123",
        }),
      };
      mockDb.collection().doc().get.mockResolvedValue(alreadyConfirmedBooking);

       const req = {
        headers: { "stripe-signature": "valid-sig" },
        rawBody: "raw-body",
      };
      const res = {
        status: jest.fn().mockReturnThis(),
        send: jest.fn(),
        json: jest.fn(),
      };

      // Act
      await handleStripeWebhook(req as any, res as any);

      // Assert
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          status: "already_processed",
        })
      );
      // Crucially, ensure no update or notification functions were called again
      expect(mockDb.collection().doc().update).not.toHaveBeenCalled();
       const { sendBookingApprovedEmail } = require("../src/emailService");
      expect(sendBookingApprovedEmail).not.toHaveBeenCalled();
    });

     it("should return a 400 error if the webhook signature is invalid", async () => {
      mockStripe.webhooks.constructEvent.mockImplementation(() => {
        throw new Error("Invalid signature");
      });

      const req = {
        headers: { "stripe-signature": "invalid-sig" },
        rawBody: "raw-body",
      };
      const res = {
        status: jest.fn().mockReturnThis(),
        send: jest.fn(),
      };

      await handleStripeWebhook(req as any, res as any);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.send).toHaveBeenCalledWith("Webhook signature verification failed");
    });

  });
});
