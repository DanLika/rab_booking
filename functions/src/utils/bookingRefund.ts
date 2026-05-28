// Booking refund helper — shared by guestCancelBooking + owner cancelBooking.
//
// Extracts the post-transaction Stripe refund flow so the two cancel paths
// stay byte-for-byte identical on the refund side. Both callers run their
// own transaction to flip booking status + write refund_amount /
// refund_status = "pending_stripe", then invoke this helper to issue the
// Stripe refund and stamp refund_status to processed / failed.

import * as admin from "firebase-admin";
import {db} from "../firebase";
import {logInfo, logError, logSuccess} from "../logger";
import {getStripeClient} from "../stripe";

export interface ProcessStripeRefundInput {
  bookingId: string;
  bookingReference: string;
  bookingRef: FirebaseFirestore.DocumentReference;
  ownerId: string | undefined;
  stripePaymentIntentId: string | undefined;
  refundAmount: number;
  cancelledBy: "guest" | "owner";
}

export interface ProcessStripeRefundResult {
  refundId?: string;
  status: "processed" | "failed";
  reason?: string;
}

/**
 * Process a Stripe destination refund for a booking that has already been
 * marked refund_status: "pending_stripe" inside a Firestore transaction.
 *
 * On success: writes refund_status: "processed" + stripe_refund_id.
 * On any failure: writes refund_status: "failed" (+ refund_error for
 * Stripe-side errors). Never throws — callers depend on cancellation
 * succeeding even if the refund leg later needs manual retry.
 *
 * @param {ProcessStripeRefundInput} input - booking + refund context.
 * @return {Promise<ProcessStripeRefundResult>} outcome for logging / response.
 */
export async function processStripeRefund(
  input: ProcessStripeRefundInput
): Promise<ProcessStripeRefundResult> {
  const {
    bookingId,
    bookingReference,
    bookingRef,
    ownerId,
    stripePaymentIntentId,
    refundAmount,
    cancelledBy,
  } = input;

  if (!(refundAmount > 0)) {
    return {status: "failed", reason: "refundAmount must be > 0"};
  }

  let ownerStripeAccountId: string | undefined;
  if (ownerId) {
    const ownerDoc = await db.collection("users").doc(ownerId).get();
    ownerStripeAccountId = ownerDoc.data()?.stripe_account_id as
      | string
      | undefined;
  }

  if (!ownerStripeAccountId) {
    logError("Stripe Connect account ID missing for refund", null, {
      bookingId,
      ownerId,
    });
    await bookingRef.update({refund_status: "failed"});
    return {status: "failed", reason: "owner missing stripe_account_id"};
  }

  if (!stripePaymentIntentId) {
    logError("Stripe payment intent ID missing", null, {bookingId});
    await bookingRef.update({refund_status: "failed"});
    return {status: "failed", reason: "missing stripe_payment_intent_id"};
  }

  try {
    const stripe = getStripeClient();
    const refund = await stripe.refunds.create(
      {
        payment_intent: stripePaymentIntentId,
        amount: Math.round(refundAmount * 100),
        reason: "requested_by_customer",
        reverse_transfer: true,
        metadata: {
          booking_id: bookingId,
          booking_reference: bookingReference,
          cancelled_by: cancelledBy,
          connected_account: ownerStripeAccountId,
        },
      },
      {idempotencyKey: `refund-${bookingId}`}
    );

    await bookingRef.update({
      refund_status: "processed",
      stripe_refund_id: refund.id,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    logSuccess(`Stripe refund processed: ${refund.id}`, {
      bookingId,
      refundAmount,
      cancelledBy,
    });
    logInfo("[processStripeRefund] refund issued", {
      bookingId,
      refundId: refund.id,
    });

    return {refundId: refund.id, status: "processed"};
  } catch (stripeError) {
    logError("Failed to process Stripe refund", stripeError, {
      bookingId,
      refundAmount,
      cancelledBy,
    });
    await bookingRef.update({
      refund_status: "failed",
      refund_error: String(stripeError),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    return {status: "failed", reason: String(stripeError)};
  }
}
