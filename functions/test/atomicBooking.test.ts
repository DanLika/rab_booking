/**
 * Unit tests for atomicBooking.ts cloud functions.
 * Mocks Firebase, email services, and other utilities.
 */

// eslint-disable-next-line @typescript-eslint/no-var-requires
const test = require("firebase-functions-test")();

// Mock dependencies
jest.mock("../src/firebase", () => {
  const mockFirestore = {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    get: jest.fn(),
    set: jest.fn().mockResolvedValue(true),
    update: jest.fn().mockResolvedValue(true),
    runTransaction: jest.fn(),
    id: "mock-booking-id",
  };
  return {
    admin: {
      firestore: {
        FieldValue: {
          serverTimestamp: () => "mock-timestamp",
        },
        Timestamp: {
          fromDate: (date: Date) => ({
            toDate: () => date,
            toMillis: () => date.getTime(),
          }),
          now: () => {
            const now = new Date();
            return {
              toDate: () => now,
              toMillis: () => now.getTime(),
            };
          },
        },
      },
    },
    db: mockFirestore,
  };
});

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logWarn: jest.fn(),
}));

jest.mock("../src/emailService", () => ({
  sendBookingConfirmationEmail: jest.fn(),
  sendPendingBookingRequestEmail: jest.fn(),
  sendOwnerNotificationEmail: jest.fn(),
  sendPendingBookingOwnerNotification: jest.fn(),
}));

jest.mock("../src/fcmService", () => ({
  sendPendingBookingPushNotification: jest.fn().mockResolvedValue(undefined),
}));

jest.mock("../src/notificationService", () => ({
  createBookingNotification: jest.fn().mockResolvedValue(undefined),
}));

jest.mock("../src/utils/rateLimit", () => ({
  enforceRateLimit: jest.fn().mockResolvedValue(undefined),
  checkRateLimit: jest.fn().mockReturnValue(true),
}));

jest.mock("../src/utils/priceValidation", () => ({
  validateBookingPrice: jest.fn().mockResolvedValue(undefined),
  calculateBookingPrice: jest.fn().mockResolvedValue({ totalPrice: 500 }),
}));

jest.mock("../src/sentry", () => ({
  setUser: jest.fn(),
  captureMessage: jest.fn(),
}));

// Import the function to be tested
import { createBookingAtomic } from "../src/atomicBooking";

const { wrap } = test;

describe("Atomic Booking Functions", () => {
  // Dynamically generate future dates to avoid "date in the past" errors
  const getFutureDate = (days: number) => {
    const date = new Date();
    date.setDate(date.getDate() + days);
    return date.toISOString().split("T")[0]; // YYYY-MM-DD format
  };

  const validData = {
    unitId: "unit-123",
    propertyId: "property-123",
    checkIn: getFutureDate(10),
    checkOut: getFutureDate(15),
    guestName: "John Doe",
    guestEmail: "john@example.com",
    guestCount: 2,
    totalPrice: 500,
    paymentMethod: "bank_transfer",
    requireOwnerApproval: true,
  };

  const mockPropertyDoc = {
    exists: true,
    data: () => ({ owner_id: "owner-123", name: "Test Property" }),
  };

  const mockWidgetSettingsDoc = {
    exists: true,
    data: () => ({
      widget_mode: "booking_instant",
      stripe_config: { enabled: true, deposit_percentage: 20 },
      bank_transfer_config: { enabled: true, deposit_percentage: 20 },
    }),
  };

  const mockUnitDoc = {
    exists: true,
    data: () => ({
      name: "Test Unit",
      min_stay_nights: 1,
      max_guests: 4,
      max_total_capacity: 6,
      pet_fee: 10,
    }),
  };

  const mockOwnerUserDoc = {
    exists: true,
    data: () => ({ email: "owner@example.com" }),
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("createBookingAtomic", () => {
    it("should return isStripeValidation: true if paymentMethod is stripe", async () => {
      // Arrange
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get
        .mockResolvedValueOnce(mockPropertyDoc)        // propertyDocForOwner
        .mockResolvedValueOnce(mockWidgetSettingsDoc); // widgetSettingsDoc

      const wrapped = wrap(createBookingAtomic);
      const stripeData = { ...validData, paymentMethod: "stripe" };

      // Act
      const result = await wrapped({ data: stripeData });

      // Assert
      expect(result.success).toBe(true);
      expect(result.isStripeValidation).toBe(true);
    });

    it("should create a bank transfer booking successfully (happy path)", async () => {
      // Arrange
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get
        .mockResolvedValueOnce(mockPropertyDoc)        // propertyDocForOwner
        .mockResolvedValueOnce(mockWidgetSettingsDoc) // widgetSettingsDoc
        .mockResolvedValueOnce(mockUnitDoc)           // unitDocForFees
        .mockResolvedValueOnce(mockPropertyDoc)       // propertyDoc (for email)
        .mockResolvedValueOnce(mockOwnerUserDoc)      // ownerDoc (for owner email)
        .mockResolvedValueOnce({ exists: false });    // bank details

      mockDb.runTransaction.mockImplementation(async (callback: any) => {
        const transaction = {
          get: jest.fn()
            .mockResolvedValueOnce({ empty: true })   // conflicts
            .mockResolvedValueOnce({ docs: [] })      // daily prices
            .mockResolvedValueOnce({ exists: false }) // checkout prices
            .mockResolvedValueOnce(mockUnitDoc),      // unitDoc
          set: jest.fn(),
        };
        return await callback(transaction);
      });

      const wrapped = wrap(createBookingAtomic);

      // Act
      const result = await wrapped({ data: validData });

      // Assert
      expect(result.success).toBe(true);
      expect(mockDb.runTransaction).toHaveBeenCalled();
    });

    it("should throw error if required fields are missing", async () => {
      const wrapped = wrap(createBookingAtomic);
      const invalidData = { unitId: "unit-123" };

      await expect(wrapped({ data: invalidData })).rejects.toThrow();
    });

    it("should throw error if property is not found", async () => {
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get.mockResolvedValueOnce({ exists: false });

      const wrapped = wrap(createBookingAtomic);
      await expect(wrapped({ data: validData })).rejects.toThrow();
    });

    it("should throw error if ownerId is missing from property", async () => {
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get.mockResolvedValueOnce({ exists: true, data: () => ({}) });

      const wrapped = wrap(createBookingAtomic);
      await expect(wrapped({ data: validData })).rejects.toThrow();
    });

    it("should throw error if date conflict is detected in transaction", async () => {
       // Arrange
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get
        .mockResolvedValueOnce(mockPropertyDoc)
        .mockResolvedValueOnce(mockWidgetSettingsDoc)
        .mockResolvedValueOnce(mockUnitDoc);

      mockDb.runTransaction.mockImplementation(async (callback: any) => {
        const transaction = {
          get: jest.fn().mockResolvedValueOnce({
            empty: false,
            docs: [{ id: "conflict-1", data: () => ({ status: "confirmed" }) }]
          }),
        };
        return await callback(transaction);
      });

      const wrapped = wrap(createBookingAtomic);
      await expect(wrapped({ data: validData })).rejects.toThrow();
    });
  });
});
