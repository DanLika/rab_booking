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

// Import the functions to be tested
import {
  createBookingAtomic,
  createOwnerBookingAtomic,
  updateBookingAtomic,
} from "../src/atomicBooking";

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

  // ==========================================================================
  // audit/26 PR-A — owner-side callables
  // ==========================================================================
  describe("createOwnerBookingAtomic", () => {
    const ownerData = {
      unitId: "unit-123",
      propertyId: "property-123",
      checkIn: getFutureDate(10),
      checkOut: getFutureDate(15),
      guestName: "Jane Smith",
      guestEmail: "jane@example.com",
      guestPhone: "+385991234567",
      guestCount: 2,
      totalPrice: 350,
      paymentMethod: "cash",
      notes: "Late check-in",
    };
    const authCtx = { auth: { uid: "owner-123" } } as any;

    it("rejects unauthenticated callers", async () => {
      const wrapped = wrap(createOwnerBookingAtomic);
      await expect(wrapped({ data: ownerData, auth: undefined })).rejects.toThrow();
    });

    it("rejects when caller is not the property owner", async () => {
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get
        .mockResolvedValueOnce({
          exists: true,
          data: () => ({ owner_id: "different-owner" }),
        });

      const wrapped = wrap(createOwnerBookingAtomic);
      await expect(wrapped({ data: ownerData, ...authCtx })).rejects.toThrow();
    });

    it("rejects when target unit is missing", async () => {
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get
        .mockResolvedValueOnce({
          exists: true,
          data: () => ({ owner_id: "owner-123" }),
        })
        .mockResolvedValueOnce({ exists: false });

      const wrapped = wrap(createOwnerBookingAtomic);
      await expect(wrapped({ data: ownerData, ...authCtx })).rejects.toThrow();
    });

    it("rejects overlap by default and surfaces already-exists", async () => {
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get
        .mockResolvedValueOnce({
          exists: true,
          data: () => ({ owner_id: "owner-123" }),
        })
        .mockResolvedValueOnce({ exists: true, data: () => ({ name: "Test" }) });

      mockDb.runTransaction.mockImplementation(async (callback: any) => {
        const transaction = {
          get: jest.fn().mockResolvedValueOnce({
            docs: [
              { id: "other", data: () => ({ status: "confirmed" }) },
            ],
          }),
          set: jest.fn(),
        };
        return await callback(transaction);
      });

      const wrapped = wrap(createOwnerBookingAtomic);
      await expect(wrapped({ data: ownerData, ...authCtx })).rejects.toThrow();
    });

    it("creates booking on happy path with no conflicts", async () => {
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get
        .mockResolvedValueOnce({
          exists: true,
          data: () => ({ owner_id: "owner-123" }),
        })
        .mockResolvedValueOnce({ exists: true, data: () => ({ name: "Test" }) });

      mockDb.runTransaction.mockImplementation(async (callback: any) => {
        const transaction = {
          get: jest.fn().mockResolvedValueOnce({ docs: [] }),
          set: jest.fn(),
        };
        return await callback(transaction);
      });

      const wrapped = wrap(createOwnerBookingAtomic);
      const result = await wrapped({ data: ownerData, ...authCtx });
      expect(result.success).toBe(true);
      expect(result.bookingId).toBeDefined();
      expect(result.bookingReference).toMatch(/^BK-/);
      expect(result.nights).toBe(5);
    });

    it("skips overlap check when allowOverlap=true", async () => {
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get
        .mockResolvedValueOnce({
          exists: true,
          data: () => ({ owner_id: "owner-123" }),
        })
        .mockResolvedValueOnce({ exists: true, data: () => ({ name: "Test" }) });

      const txnGet = jest.fn();
      mockDb.runTransaction.mockImplementation(async (callback: any) => {
        const transaction = { get: txnGet, set: jest.fn() };
        return await callback(transaction);
      });

      const wrapped = wrap(createOwnerBookingAtomic);
      const result = await wrapped({
        data: { ...ownerData, allowOverlap: true },
        ...authCtx,
      });
      expect(result.success).toBe(true);
      // Overlap query should NOT run when allowOverlap=true
      expect(txnGet).not.toHaveBeenCalled();
    });

    it("rejects invalid payment method", async () => {
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get
        .mockResolvedValueOnce({
          exists: true,
          data: () => ({ owner_id: "owner-123" }),
        });

      const wrapped = wrap(createOwnerBookingAtomic);
      await expect(
        wrapped({
          data: { ...ownerData, paymentMethod: "stripe" }, // widget-only
          ...authCtx,
        })
      ).rejects.toThrow();
    });

    it("rejects guestCount out of bounds", async () => {
      const wrapped = wrap(createOwnerBookingAtomic);
      await expect(
        wrapped({ data: { ...ownerData, guestCount: 999 }, ...authCtx })
      ).rejects.toThrow();
    });

    it("accepts historical check-in date (past)", async () => {
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get
        .mockResolvedValueOnce({
          exists: true,
          data: () => ({ owner_id: "owner-123" }),
        })
        .mockResolvedValueOnce({ exists: true, data: () => ({ name: "Test" }) });

      mockDb.runTransaction.mockImplementation(async (callback: any) => {
        const transaction = {
          get: jest.fn().mockResolvedValueOnce({ docs: [] }),
          set: jest.fn(),
        };
        return await callback(transaction);
      });

      // 30 days in the past — owner recording a historical stay
      const past = new Date();
      past.setDate(past.getDate() - 30);
      const pastIso = past.toISOString().split("T")[0];
      const past2 = new Date();
      past2.setDate(past2.getDate() - 25);
      const past2Iso = past2.toISOString().split("T")[0];

      const wrapped = wrap(createOwnerBookingAtomic);
      const result = await wrapped({
        data: { ...ownerData, checkIn: pastIso, checkOut: past2Iso },
        ...authCtx,
      });
      expect(result.success).toBe(true);
    });
  });

  describe("updateBookingAtomic", () => {
    const baseUpdate = {
      bookingId: "booking-abc",
      propertyId: "property-123",
      unitId: "unit-123",
    };
    const authCtx = { auth: { uid: "owner-123" } } as any;
    const currentBookingDoc = {
      exists: true,
      data: () => ({
        owner_id: "owner-123",
        check_in: { toMillis: () => Date.now() },
        check_out: { toMillis: () => Date.now() + 86_400_000 },
      }),
    };

    beforeEach(() => {
      // jest.clearAllMocks() above does NOT drop mockResolvedValueOnce queue.
      // Reset the chainable mock's get queue between tests so residue from an
      // earlier suite's setup doesn't leak into this one.
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get.mockReset();
      mockDb.runTransaction.mockReset();
    });

    it("rejects unauthenticated callers", async () => {
      const wrapped = wrap(updateBookingAtomic);
      await expect(
        wrapped({ data: { ...baseUpdate, guestCount: 3 }, auth: undefined })
      ).rejects.toThrow();
    });

    it("rejects when caller is not booking owner", async () => {
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get
        .mockResolvedValueOnce({
          exists: true,
          data: () => ({ owner_id: "someone-else" }),
        });

      const wrapped = wrap(updateBookingAtomic);
      await expect(
        wrapped({ data: { ...baseUpdate, guestCount: 3 }, ...authCtx })
      ).rejects.toThrow();
    });

    it("rejects when booking doc no longer exists", async () => {
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get
        .mockResolvedValueOnce({ exists: false });

      const wrapped = wrap(updateBookingAtomic);
      await expect(
        wrapped({ data: { ...baseUpdate, guestCount: 3 }, ...authCtx })
      ).rejects.toThrow();
    });

    it("same-unit update without dates skips overlap check", async () => {
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get.mockResolvedValueOnce(currentBookingDoc);

      const txnGet = jest.fn()
        .mockResolvedValueOnce(currentBookingDoc); // inner re-read
      const txnUpdate = jest.fn();
      mockDb.runTransaction.mockImplementation(async (callback: any) => {
        return await callback({
          get: txnGet,
          update: txnUpdate,
          set: jest.fn(),
          delete: jest.fn(),
        });
      });

      const wrapped = wrap(updateBookingAtomic);
      const result = await wrapped({
        data: { ...baseUpdate, guestCount: 4, notes: "Updated" },
        ...authCtx,
      });
      expect(result.success).toBe(true);
      // Only the inner re-read should run — no overlap query.
      expect(txnGet).toHaveBeenCalledTimes(1);
      expect(txnUpdate).toHaveBeenCalledTimes(1);
    });

    it("rejects move when target property is not owned by caller", async () => {
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get
        .mockResolvedValueOnce(currentBookingDoc)
        .mockResolvedValueOnce({
          exists: true,
          data: () => ({ owner_id: "different-owner" }),
        });

      const wrapped = wrap(updateBookingAtomic);
      await expect(
        wrapped({
          data: {
            ...baseUpdate,
            targetPropertyId: "property-xyz",
            targetUnitId: "unit-xyz",
          },
          ...authCtx,
        })
      ).rejects.toThrow();
    });

    it("date change triggers overlap check and rejects on conflict", async () => {
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get.mockResolvedValueOnce(currentBookingDoc);

      const txnGet = jest.fn()
        .mockResolvedValueOnce(currentBookingDoc) // inner re-read
        .mockResolvedValueOnce({ // overlap query
          docs: [
            { id: "other-booking", data: () => ({ status: "confirmed" }) },
          ],
        });
      mockDb.runTransaction.mockImplementation(async (callback: any) => {
        return await callback({
          get: txnGet,
          update: jest.fn(),
          set: jest.fn(),
          delete: jest.fn(),
        });
      });

      const wrapped = wrap(updateBookingAtomic);
      await expect(
        wrapped({
          data: {
            ...baseUpdate,
            checkIn: getFutureDate(10),
            checkOut: getFutureDate(15),
          },
          ...authCtx,
        })
      ).rejects.toThrow();
    });

    it("rejects invalid status enum", async () => {
      const mockDb = require("../src/firebase").db;
      mockDb.collection().doc().get.mockResolvedValueOnce(currentBookingDoc);

      const wrapped = wrap(updateBookingAtomic);
      await expect(
        wrapped({
          data: { ...baseUpdate, status: "not-a-status" },
          ...authCtx,
        })
      ).rejects.toThrow();
    });
  });
});
