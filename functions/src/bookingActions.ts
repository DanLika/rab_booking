// Owner booking actions (approve / reject / cancel / complete) — F-67-01 + sibling.
//
// Background: prior to these CFs the owner dashboard called
// `bookingDoc.reference.update({status: ...})` directly via the Firestore SDK.
// That produced a silent no-op for the user (see audit/67 §G) and gave no
// server-side audit point. We move the state transitions behind these
// callables so the UI gets a clear success/error contract and the rules
// surface can deny client status writes in a follow-up.
//
// `cancelBooking` additionally handles the Stripe refund leg via the shared
// `processStripeRefund` helper so guest + owner cancellation paths cannot
// drift on refund behaviour.
//
// `completeBooking` finishes the migration class: was the last booking-status
// transition still writing direct from the Flutter SDK
// (`firebase_owner_bookings_repository.ts completeBooking()` → `.reference.update`).
// Eligible source statuses are `confirmed` (typical) or `pending` (edge case
// where owner skips approve and goes straight to complete after guest-stay).

import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {db} from "./firebase";
import {logInfo, logSuccess, logWarn} from "./logger";
import {setUser} from "./sentry";
import {findBookingById} from "./utils/bookingLookup";
import {processStripeRefund} from "./utils/bookingRefund";
import {stripeSecretKey} from "./stripe";

const REGION = "europe-west1";

interface BookingActionInput {
  bookingId?: unknown;
  reason?: unknown;
}

interface BookingActionOutput {
  success: boolean;
  bookingId: string;
  status: string;
}

interface CancelBookingOutput extends BookingActionOutput {
  refundAmount: number;
  refundStatus: string;
  refundId?: string;
}

/**
 * Validate that `value` is a non-empty trimmed string or throw HttpsError.
 *
 * @param {unknown} value - raw input from the callable request.
 * @param {string} field - field name, used in the error message.
 * @return {string} the trimmed string.
 */
function requireString(value: unknown, field: string): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${field} must be a string.`);
  }
  const trimmed = value.trim();
  if (!trimmed) {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  return trimmed;
}

/**
 * Resolve a booking owned by `uid` and ensure its current status is one of
 * `allowedStatuses`. Throws the appropriate HttpsError on missing booking,
 * ownership mismatch, or disallowed status so callable handlers can stay
 * focused on the state transition itself.
 *
 * @param {string} uid - authenticated owner UID.
 * @param {string} bookingId - booking document ID.
 * @param {readonly string[]} allowedStatuses - eligible source statuses.
 * @return {Promise} reference + data of the located booking.
 */
async function loadOwnedBookingForAction(
  uid: string,
  bookingId: string,
  allowedStatuses: readonly string[]
): Promise<{
  ref: FirebaseFirestore.DocumentReference;
  data: FirebaseFirestore.DocumentData;
}> {
  const lookup = await findBookingById(bookingId, uid);
  if (!lookup) {
    throw new HttpsError("not-found", "Booking not found.");
  }
  const {doc, data, propertyId} = lookup;
  if (!propertyId || typeof propertyId !== "string") {
    logWarn("[bookingActions] booking missing property_id", {
      bookingId,
      path: doc.ref.path,
    });
    throw new HttpsError(
      "failed-precondition",
      "Booking is missing property_id."
    );
  }
  const propDoc = await db.collection("properties").doc(propertyId).get();
  const ownerId = propDoc.data()?.owner_id;
  if (!propDoc.exists || ownerId !== uid) {
    logWarn("[bookingActions] ownership mismatch", {
      bookingId,
      propertyId,
      uid,
      ownerId,
    });
    throw new HttpsError(
      "permission-denied",
      "You do not own this booking."
    );
  }
  if (!allowedStatuses.includes(data.status)) {
    throw new HttpsError(
      "failed-precondition",
      `Booking status "${data.status}" is not eligible for this action.`
    );
  }
  return {ref: doc.ref, data};
}

/**
 * Require an authenticated caller. Sets the Sentry user context as a side
 * effect so downstream errors carry the owner UID.
 *
 * @param {CallableRequest<BookingActionInput>} request - callable request.
 * @return {string} authenticated UID.
 */
function requireAuth(request: CallableRequest<BookingActionInput>): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  setUser(uid);
  return uid;
}

/**
 * approveBooking — transitions a pending booking to `confirmed` and stamps
 * `approved_at`. Guests receive the confirmation email via the existing
 * `onBookingStatusChange` Firestore trigger (bookingManagement.ts).
 */
export const approveBooking = onCall<
  BookingActionInput,
  Promise<BookingActionOutput>
>(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 30,
    maxInstances: 50,
    cors: true,
  },
  async (request) => {
    const uid = requireAuth(request);
    const bookingId = requireString(request.data?.bookingId, "bookingId");

    logInfo("[approveBooking] start", {bookingId, uid});
    const {ref} = await loadOwnedBookingForAction(uid, bookingId, ["pending"]);
    await ref.update({
      status: "confirmed",
      approved_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    logSuccess("[approveBooking] booking confirmed", {
      bookingId,
      uid,
      path: ref.path,
    });
    return {success: true, bookingId, status: "confirmed"};
  }
);

/**
 * rejectBooking — transitions a pending booking to `cancelled` with a
 * rejection_reason. Email + iCal/availability fan-out runs in the existing
 * onBookingStatusChange trigger.
 */
export const rejectBooking = onCall<
  BookingActionInput,
  Promise<BookingActionOutput>
>(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 30,
    maxInstances: 50,
    cors: true,
  },
  async (request) => {
    const uid = requireAuth(request);
    const bookingId = requireString(request.data?.bookingId, "bookingId");

    const rawReason = request.data?.reason;
    let reason = "Rejected by owner";
    if (rawReason !== undefined && rawReason !== null) {
      if (typeof rawReason !== "string") {
        throw new HttpsError("invalid-argument", "reason must be a string.");
      }
      const trimmed = rawReason.trim();
      if (trimmed.length > 500) {
        throw new HttpsError(
          "invalid-argument",
          "reason exceeds 500 characters."
        );
      }
      if (trimmed.length > 0) {
        reason = trimmed;
      }
    }

    logInfo("[rejectBooking] start", {bookingId, uid});
    const {ref} = await loadOwnedBookingForAction(uid, bookingId, ["pending"]);
    await ref.update({
      status: "cancelled",
      rejection_reason: reason,
      rejected_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    logSuccess("[rejectBooking] booking rejected", {
      bookingId,
      uid,
      path: ref.path,
    });
    return {success: true, bookingId, status: "cancelled"};
  }
);

/**
 * cancelBooking — owner-initiated cancellation of a `pending` or
 * `confirmed` booking. Transitions status → cancelled inside a transaction
 * that also computes the refund_amount / refund_status. After the
 * transaction completes, if the booking was paid via Stripe the shared
 * `processStripeRefund` helper issues the destination refund.
 *
 * Email + iCal cache invalidation fan out via the existing
 * `onBookingStatusChange` Firestore trigger (bookingManagement.ts) — same
 * path the guest cancellation flow already uses.
 */
export const cancelBooking = onCall<
  BookingActionInput,
  Promise<CancelBookingOutput>
>(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 60,
    maxInstances: 50,
    cors: true,
    secrets: [stripeSecretKey],
  },
  async (request) => {
    const uid = requireAuth(request);
    const bookingId = requireString(request.data?.bookingId, "bookingId");

    const rawReason = request.data?.reason;
    let reason = "Cancelled by owner";
    if (rawReason !== undefined && rawReason !== null) {
      if (typeof rawReason !== "string") {
        throw new HttpsError("invalid-argument", "reason must be a string.");
      }
      const trimmed = rawReason.trim();
      if (trimmed.length > 500) {
        throw new HttpsError(
          "invalid-argument",
          "reason exceeds 500 characters."
        );
      }
      if (trimmed.length > 0) {
        reason = trimmed;
      }
    }

    logInfo("[cancelBooking] start", {bookingId, uid});

    // Ownership check + allow already-cancelled to fall through to the
    // transaction's idempotent short-circuit. The transaction itself
    // rejects truly ineligible states (completed / refunded).
    const {ref: bookingRef, data: initial} = await loadOwnedBookingForAction(
      uid,
      bookingId,
      ["pending", "confirmed", "cancelled"]
    );
    const bookingReference: string =
      typeof initial.booking_reference === "string" ?
        initial.booking_reference :
        bookingId;

    // Transactional state transition + refund-status preparation.
    // Mirrors guestCancelBooking's atomic update so the two paths land
    // the same set of fields.
    const txResult = await db.runTransaction(async (transaction) => {
      const fresh = await transaction.get(bookingRef);
      if (!fresh.exists) {
        throw new HttpsError("not-found", "Booking not found.");
      }
      const data = fresh.data()!;
      if (data.status === "cancelled") {
        return {
          alreadyCancelled: true as const,
          refundAmount: (data.refund_amount as number) || 0,
          refundStatus: (data.refund_status as string) || "not_applicable",
          stripePaymentIntentId: data.stripe_payment_intent_id as
            | string
            | undefined,
        };
      }
      if (data.status !== "pending" && data.status !== "confirmed") {
        throw new HttpsError(
          "failed-precondition",
          `Booking status "${data.status}" is not eligible for cancellation.`
        );
      }

      const paymentStatus = data.payment_status;
      const paymentMethod = data.payment_method;
      const paidAmount = (data.paid_amount as number) || 0;
      let refundAmount = 0;
      let refundStatus = "not_applicable";
      if (paymentStatus === "paid" && paidAmount > 0) {
        refundAmount = paidAmount;
        refundStatus =
          paymentMethod === "stripe" ? "pending_stripe" : "pending_manual";
      }

      transaction.update(bookingRef, {
        status: "cancelled",
        cancelled_at: admin.firestore.FieldValue.serverTimestamp(),
        cancelled_by: "owner",
        cancellation_reason: reason,
        refund_amount: refundAmount,
        refund_status: refundStatus,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        alreadyCancelled: false as const,
        refundAmount,
        refundStatus,
        stripePaymentIntentId: data.stripe_payment_intent_id as
          | string
          | undefined,
      };
    });

    if (txResult.alreadyCancelled) {
      logInfo("[cancelBooking] idempotent — already cancelled", {bookingId});
      return {
        success: true,
        bookingId,
        status: "cancelled",
        refundAmount: txResult.refundAmount,
        refundStatus: txResult.refundStatus,
      };
    }

    // Step 2: Stripe refund AFTER transaction (no external API inside Tx).
    let refundId: string | undefined;
    if (
      txResult.refundStatus === "pending_stripe" &&
      txResult.refundAmount > 0
    ) {
      const result = await processStripeRefund({
        bookingId,
        bookingReference,
        bookingRef,
        ownerId: uid,
        stripePaymentIntentId: txResult.stripePaymentIntentId,
        refundAmount: txResult.refundAmount,
        cancelledBy: "owner",
      });
      refundId = result.refundId;
    }

    logSuccess("[cancelBooking] booking cancelled", {
      bookingId,
      uid,
      path: bookingRef.path,
      refundAmount: txResult.refundAmount,
      refundStatus: txResult.refundStatus,
      refundId,
    });

    return {
      success: true,
      bookingId,
      status: "cancelled",
      refundAmount: txResult.refundAmount,
      refundStatus: txResult.refundStatus,
      refundId,
    };
  }
);

/**
 * completeBooking — transitions a `confirmed` booking to `completed`.
 * Stamps `completed_at` + `updated_at`. Closes the F-67-01 migration
 * class: the previous Flutter callsite
 * (`firebase_owner_bookings_repository.completeBooking()`) wrote
 * `status='completed'` directly via the client SDK, which audit/67 §G
 * showed as a silent no-op for owners on PROD (rules deny was already
 * present but client never surfaced the error).
 *
 * Source status restricted to `confirmed` only: both UI entrypoints
 * (`owner_bookings_screen.dart:1819` card action, `bookings_table_view
 * .dart:484` popup menu) gate the button to
 * `status == confirmed && booking.isPast`, so `pending` → `completed`
 * is not a legitimate transition — accepting it server-side would only
 * enlarge the attack surface. To complete a booking that is still
 * pending the owner must approve first.
 *
 * Email + iCal fan-out happens via the existing `onBookingStatusChange`
 * Firestore trigger — same path the other three actions rely on.
 */
export const completeBooking = onCall<
  BookingActionInput,
  Promise<BookingActionOutput>
>(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 30,
    maxInstances: 50,
    cors: true,
  },
  async (request) => {
    const uid = requireAuth(request);
    const bookingId = requireString(request.data?.bookingId, "bookingId");

    logInfo("[completeBooking] start", {bookingId, uid});
    const {ref} = await loadOwnedBookingForAction(uid, bookingId, [
      "confirmed",
    ]);
    await ref.update({
      status: "completed",
      completed_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    logSuccess("[completeBooking] booking completed", {
      bookingId,
      uid,
      path: ref.path,
    });
    return {success: true, bookingId, status: "completed"};
  }
);
