/**
 * Tests for src/bookingActions.ts — closes audit/67 F-67-01 class.
 *
 * Exercises approveBooking / rejectBooking / cancelBooking happy path
 * plus the auth + ownership + status + idempotency failure modes that
 * the pre-#549 direct-write flow silently swallowed.
 */

// eslint-disable-next-line @typescript-eslint/no-var-requires
const test = require("firebase-functions-test")();

jest.mock("firebase-functions/params", () => {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const real = jest.requireActual("firebase-functions/params");
  return {
    ...real,
    defineSecret: () => ({value: () => "mock-secret", name: "MOCK"}),
    defineString: () => ({value: () => ""}),
  };
});

jest.mock("../src/firebase", () => {
  const mockRef: any = {
    update: jest.fn().mockResolvedValue(true),
    path: "properties/prop-1/units/unit-1/bookings/booking-abc",
  };
  return {
    admin: {
      firestore: {
        FieldValue: {
          serverTimestamp: () => "mock-ts",
        },
      },
    },
    db: {
      collection: jest.fn(),
      runTransaction: jest.fn(),
      __mockRef: mockRef,
    },
  };
});

jest.mock("../src/stripe", () => ({
  stripeSecretKey: {name: "STRIPE_SECRET_KEY"},
}));

jest.mock("../src/utils/bookingLookup", () => ({
  findBookingById: jest.fn(),
}));

jest.mock("../src/utils/bookingRefund", () => ({
  processStripeRefund: jest.fn(),
}));

// Audit 2026-06-12: booking actions share a Firestore-backed limiter; the
// suite covers handler logic, the limiter has its own tests.
jest.mock("../src/utils/rateLimit", () => ({
  enforceRateLimit: jest.fn().mockResolvedValue(undefined),
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

import {approveBooking, rejectBooking, cancelBooking} from "../src/bookingActions";

const {wrap} = test;

const OWNER_UID = "owner-uid-1";
const OTHER_UID = "intruder-uid";
const BOOKING_ID = "booking-abc";
const PROPERTY_ID = "prop-1";

function makeBookingRef(initialPath = "properties/prop-1/units/unit-1/bookings/booking-abc") {
  return {
    update: jest.fn().mockResolvedValue(true),
    path: initialPath,
  };
}

function primePropertyOwnedBy(uid: string) {
  // Mock db.collection("properties").doc(propertyId).get() chain.
  const mockDb = require("../src/firebase").db;
  const propGetMock = jest.fn().mockResolvedValue({
    exists: true,
    data: () => ({owner_id: uid}),
  });
  const docMock = jest.fn(() => ({get: propGetMock}));
  mockDb.collection.mockImplementation((name: string) => {
    if (name === "properties") return {doc: docMock};
    throw new Error(`unexpected collection ${name}`);
  });
}

describe("bookingActions (F-67-01)", () => {
  let bookingRef: ReturnType<typeof makeBookingRef>;

  beforeEach(() => {
    jest.clearAllMocks();
    bookingRef = makeBookingRef();
    primePropertyOwnedBy(OWNER_UID);
  });

  describe("approveBooking", () => {
    const wrapped = wrap(approveBooking);

    it("throws unauthenticated when no auth context", async () => {
      await expect(wrapped({data: {bookingId: BOOKING_ID}})).rejects.toThrow(/signed in/);
    });

    it("throws invalid-argument when bookingId missing", async () => {
      await expect(wrapped({data: {}, auth: {uid: OWNER_UID}})).rejects.toThrow(/bookingId/);
    });

    it("throws invalid-argument when bookingId is empty string", async () => {
      await expect(wrapped({data: {bookingId: "   "}, auth: {uid: OWNER_UID}})).rejects.toThrow(/required/);
    });

    it("throws not-found when bookingLookup returns null", async () => {
      const {findBookingById} = require("../src/utils/bookingLookup");
      findBookingById.mockResolvedValue(null);
      await expect(
        wrapped({data: {bookingId: BOOKING_ID}, auth: {uid: OWNER_UID}})
      ).rejects.toThrow(/Booking not found/);
    });

    it("throws failed-precondition when booking missing property_id", async () => {
      const {findBookingById} = require("../src/utils/bookingLookup");
      findBookingById.mockResolvedValue({
        doc: {ref: bookingRef},
        data: {status: "pending"},
        propertyId: undefined,
      });
      await expect(
        wrapped({data: {bookingId: BOOKING_ID}, auth: {uid: OWNER_UID}})
      ).rejects.toThrow(/missing property_id/);
    });

    it("throws permission-denied when caller is not property owner", async () => {
      primePropertyOwnedBy(OTHER_UID);
      const {findBookingById} = require("../src/utils/bookingLookup");
      findBookingById.mockResolvedValue({
        doc: {ref: bookingRef},
        data: {status: "pending"},
        propertyId: PROPERTY_ID,
      });
      await expect(
        wrapped({data: {bookingId: BOOKING_ID}, auth: {uid: OWNER_UID}})
      ).rejects.toThrow(/do not own/);
    });

    it("throws failed-precondition when status is not pending", async () => {
      const {findBookingById} = require("../src/utils/bookingLookup");
      findBookingById.mockResolvedValue({
        doc: {ref: bookingRef},
        data: {status: "confirmed"},
        propertyId: PROPERTY_ID,
      });
      await expect(
        wrapped({data: {bookingId: BOOKING_ID}, auth: {uid: OWNER_UID}})
      ).rejects.toThrow(/not eligible/);
    });

    it("transitions pending → confirmed and stamps approved_at on happy path", async () => {
      const {findBookingById} = require("../src/utils/bookingLookup");
      findBookingById.mockResolvedValue({
        doc: {ref: bookingRef},
        data: {status: "pending"},
        propertyId: PROPERTY_ID,
      });
      const out = await wrapped({data: {bookingId: BOOKING_ID}, auth: {uid: OWNER_UID}});
      expect(out).toEqual({success: true, bookingId: BOOKING_ID, status: "confirmed"});
      expect(bookingRef.update).toHaveBeenCalledTimes(1);
      const update = bookingRef.update.mock.calls[0][0];
      expect(update.status).toBe("confirmed");
      expect(update.approved_at).toBeDefined();
      expect(update.updated_at).toBeDefined();
    });

    it("consumes the shared booking_action rate limit for the caller", async () => {
      const {findBookingById} = require("../src/utils/bookingLookup");
      findBookingById.mockResolvedValue({
        doc: {ref: bookingRef},
        data: {status: "pending"},
        propertyId: PROPERTY_ID,
      });
      const {enforceRateLimit} = require("../src/utils/rateLimit");
      await wrapped({data: {bookingId: BOOKING_ID}, auth: {uid: OWNER_UID}});
      expect(enforceRateLimit).toHaveBeenCalledWith(
        OWNER_UID,
        "booking_action",
        expect.objectContaining({maxCalls: 30}),
      );
    });
  });

  describe("rejectBooking", () => {
    const wrapped = wrap(rejectBooking);

    beforeEach(() => {
      const {findBookingById} = require("../src/utils/bookingLookup");
      findBookingById.mockResolvedValue({
        doc: {ref: bookingRef},
        data: {status: "pending"},
        propertyId: PROPERTY_ID,
      });
    });

    it("uses default reason 'Rejected by owner' when none provided", async () => {
      const out = await wrapped({data: {bookingId: BOOKING_ID}, auth: {uid: OWNER_UID}});
      expect(out.status).toBe("cancelled");
      const u = bookingRef.update.mock.calls[0][0];
      expect(u.rejection_reason).toBe("Rejected by owner");
      expect(u.rejected_at).toBeDefined();
    });

    it("uses trimmed custom reason when provided", async () => {
      await wrapped({
        data: {bookingId: BOOKING_ID, reason: "  Dates conflict with hotel renovation  "},
        auth: {uid: OWNER_UID},
      });
      const u = bookingRef.update.mock.calls[0][0];
      expect(u.rejection_reason).toBe("Dates conflict with hotel renovation");
    });

    it("rejects non-string reason with invalid-argument", async () => {
      await expect(
        wrapped({data: {bookingId: BOOKING_ID, reason: 42}, auth: {uid: OWNER_UID}})
      ).rejects.toThrow(/reason must be a string/);
    });

    it("rejects reason > 500 chars with invalid-argument", async () => {
      const longReason = "x".repeat(501);
      await expect(
        wrapped({data: {bookingId: BOOKING_ID, reason: longReason}, auth: {uid: OWNER_UID}})
      ).rejects.toThrow(/exceeds 500/);
    });

    it("treats empty-trimmed reason as no reason (uses default)", async () => {
      await wrapped({data: {bookingId: BOOKING_ID, reason: "   "}, auth: {uid: OWNER_UID}});
      const u = bookingRef.update.mock.calls[0][0];
      expect(u.rejection_reason).toBe("Rejected by owner");
    });
  });

  describe("cancelBooking", () => {
    const wrapped = wrap(cancelBooking);

    function primeLoadOwned(initial: Record<string, unknown>) {
      const {findBookingById} = require("../src/utils/bookingLookup");
      findBookingById.mockResolvedValue({
        doc: {ref: bookingRef},
        data: initial,
        propertyId: PROPERTY_ID,
      });
    }

    function primeTransaction(initial: Record<string, unknown>) {
      const mockDb = require("../src/firebase").db;
      mockDb.runTransaction.mockImplementation(async (cb: any) => {
        const tx = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => initial,
          }),
          update: jest.fn(),
        };
        return await cb(tx);
      });
    }

    it("idempotent: already-cancelled returns short-circuit, NO update, NO refund", async () => {
      const initial = {
        status: "cancelled",
        refund_amount: 250,
        refund_status: "processed",
        stripe_payment_intent_id: "pi_abc",
      };
      primeLoadOwned(initial);
      primeTransaction(initial);
      const {processStripeRefund} = require("../src/utils/bookingRefund");

      const out = await wrapped({data: {bookingId: BOOKING_ID}, auth: {uid: OWNER_UID}});

      expect(out).toEqual({
        success: true,
        bookingId: BOOKING_ID,
        status: "cancelled",
        refundAmount: 250,
        refundStatus: "processed",
      });
      expect(processStripeRefund).not.toHaveBeenCalled();
    });

    it("transition: pending + paid via stripe → pending_stripe + refund issued", async () => {
      const initial = {
        status: "pending",
        payment_status: "paid",
        payment_method: "stripe",
        paid_amount: 250,
        stripe_payment_intent_id: "pi_test_1",
        booking_reference: "BB-XYZ-1",
      };
      primeLoadOwned(initial);
      const mockDb = require("../src/firebase").db;
      const txUpdate = jest.fn();
      mockDb.runTransaction.mockImplementation(async (cb: any) => {
        return await cb({
          get: jest.fn().mockResolvedValue({exists: true, data: () => initial}),
          update: txUpdate,
        });
      });
      const {processStripeRefund} = require("../src/utils/bookingRefund");
      processStripeRefund.mockResolvedValue({refundId: "re_123", status: "processed"});

      const out = await wrapped({data: {bookingId: BOOKING_ID, reason: "owner cancelled"}, auth: {uid: OWNER_UID}});

      expect(txUpdate).toHaveBeenCalledTimes(1);
      const txWrite = txUpdate.mock.calls[0][1];
      expect(txWrite.status).toBe("cancelled");
      expect(txWrite.cancelled_by).toBe("owner");
      expect(txWrite.cancellation_reason).toBe("owner cancelled");
      expect(txWrite.refund_amount).toBe(250);
      expect(txWrite.refund_status).toBe("pending_stripe");

      expect(processStripeRefund).toHaveBeenCalledTimes(1);
      const refundArg = processStripeRefund.mock.calls[0][0];
      expect(refundArg.bookingId).toBe(BOOKING_ID);
      expect(refundArg.cancelledBy).toBe("owner");
      expect(refundArg.refundAmount).toBe(250);
      expect(refundArg.stripePaymentIntentId).toBe("pi_test_1");
      expect(refundArg.bookingReference).toBe("BB-XYZ-1");
      expect(out.refundId).toBe("re_123");
      expect(out.refundStatus).toBe("pending_stripe");
    });

    it("transition: confirmed + bank_transfer paid → pending_manual + NO refund call", async () => {
      const initial = {
        status: "confirmed",
        payment_status: "paid",
        payment_method: "bank_transfer",
        paid_amount: 180,
      };
      primeLoadOwned(initial);
      primeTransaction(initial);
      const {processStripeRefund} = require("../src/utils/bookingRefund");

      const out = await wrapped({data: {bookingId: BOOKING_ID}, auth: {uid: OWNER_UID}});

      expect(out.refundStatus).toBe("pending_manual");
      expect(out.refundAmount).toBe(180);
      expect(processStripeRefund).not.toHaveBeenCalled();
    });

    it("transition: confirmed + unpaid → not_applicable + NO refund call", async () => {
      const initial = {
        status: "confirmed",
        payment_status: "pending",
        payment_method: "stripe",
        paid_amount: 0,
      };
      primeLoadOwned(initial);
      primeTransaction(initial);
      const {processStripeRefund} = require("../src/utils/bookingRefund");

      const out = await wrapped({data: {bookingId: BOOKING_ID}, auth: {uid: OWNER_UID}});

      expect(out.refundStatus).toBe("not_applicable");
      expect(out.refundAmount).toBe(0);
      expect(processStripeRefund).not.toHaveBeenCalled();
    });

    it("rejects cancel on completed booking via loadOwnedBookingForAction", async () => {
      const {findBookingById} = require("../src/utils/bookingLookup");
      findBookingById.mockResolvedValue({
        doc: {ref: bookingRef},
        data: {status: "completed"},
        propertyId: PROPERTY_ID,
      });
      await expect(
        wrapped({data: {bookingId: BOOKING_ID}, auth: {uid: OWNER_UID}})
      ).rejects.toThrow(/not eligible/);
    });

    it("rejects cancel from non-owner with permission-denied", async () => {
      primePropertyOwnedBy(OTHER_UID);
      const {findBookingById} = require("../src/utils/bookingLookup");
      findBookingById.mockResolvedValue({
        doc: {ref: bookingRef},
        data: {status: "confirmed"},
        propertyId: PROPERTY_ID,
      });
      await expect(
        wrapped({data: {bookingId: BOOKING_ID}, auth: {uid: OWNER_UID}})
      ).rejects.toThrow(/do not own/);
    });

    it("respects 500-char limit on cancellation reason", async () => {
      const initial = {status: "confirmed", payment_status: "pending", paid_amount: 0};
      primeLoadOwned(initial);
      primeTransaction(initial);
      await expect(
        wrapped({data: {bookingId: BOOKING_ID, reason: "x".repeat(501)}, auth: {uid: OWNER_UID}})
      ).rejects.toThrow(/exceeds 500/);
    });

    it("uses 'Cancelled by owner' default when reason omitted", async () => {
      const initial = {status: "pending", payment_status: "pending", paid_amount: 0};
      primeLoadOwned(initial);
      const mockDb = require("../src/firebase").db;
      const txUpdate = jest.fn();
      mockDb.runTransaction.mockImplementation(async (cb: any) => {
        return await cb({
          get: jest.fn().mockResolvedValue({exists: true, data: () => initial}),
          update: txUpdate,
        });
      });
      await wrapped({data: {bookingId: BOOKING_ID}, auth: {uid: OWNER_UID}});
      const write = txUpdate.mock.calls[0][1];
      expect(write.cancellation_reason).toBe("Cancelled by owner");
    });
  });
});
