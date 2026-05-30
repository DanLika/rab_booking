import {onCall, HttpsError} from "firebase-functions/v2/https";
import {admin, db} from "./firebase";
import {logInfo, logError, logSuccess, logWarn} from "./logger";

/**
 * Sentinel thrown inside the Firestore transaction to abort it cleanly when
 * the property has guest cancellation disabled. Caught by the outer handler
 * and converted to a structured `{success: false, reason}` response instead
 * of an HttpsError — keeps expected business rejections out of Sentry.
 */
class GuestCancellationDisabledError extends Error {
  constructor() {
    super("Guest cancellation disabled");
    this.name = "GuestCancellationDisabledError";
  }
}
import {sendBookingCancellationEmail} from "./emailService";
import {fetchPropertyAndUnitDetails} from "./utils/bookingHelpers";
import {sendGuestCancellationPushNotification} from "./fcmService";
import {findBookingById} from "./utils/bookingLookup";
import {setUser} from "./sentry";
import {safeToDate} from "./utils/dateValidation";
import {stripeSecretKey} from "./stripe";
import {checkRateLimit} from "./utils/rateLimit";
import {logRateLimitExceeded} from "./utils/securityMonitoring";
import {processStripeRefund} from "./utils/bookingRefund";
import {getCorsAllowlist} from "./utils/corsAllowlist";

/**
 * Validates email configuration to ensure all required fields are present
 * @param emailConfig - Email configuration from widget settings
 * @return Validation result with isValid flag and optional reason
 */
function validateEmailConfig(emailConfig: any): {
  isValid: boolean;
  reason?: string;
} {
  if (!emailConfig) {
    return {isValid: false, reason: "Email config missing"};
  }

  if (!emailConfig.enabled) {
    return {isValid: false, reason: "Email sending disabled"};
  }

  if (!emailConfig.is_configured) {
    return {isValid: false, reason: "Email not configured"};
  }

  // Validate from_email has proper format
  if (!emailConfig.from_email || !emailConfig.from_email.includes("@")) {
    return {isValid: false, reason: "Invalid from_email address"};
  }

  return {isValid: true};
}

/**
 * Cloud Function: Guest Cancel Booking
 *
 * Allows guests to cancel their own booking if:
 * 1. Booking is in 'confirmed' or 'pending' status
 * 2. Cancellation is within the allowed deadline (hours before check-in)
 * 3. Guest provides correct booking reference and email
 */
export const guestCancelBooking = onCall({secrets: ["RESEND_API_KEY", stripeSecretKey], cors: getCorsAllowlist()}, async (request) => {
  const data = request.data;

  // Support both camelCase and snake_case for backward compatibility
  const bookingId = data.bookingId || data.booking_id;
  const bookingReference = data.bookingReference || data.booking_reference;
  const guestEmail = data.guestEmail || data.guest_email;

  // Set user context for Sentry error tracking (guest action - use email)
  setUser(null, guestEmail || null);

  // ========================================================================
  // SECURITY: Rate limiting to prevent brute-force attacks
  // ========================================================================
  const clientIp = (request as any).rawRequest?.ip ||
    (request as any).rawRequest?.headers?.["x-forwarded-for"]?.split(",")[0]?.trim() ||
    "unknown";

  // In-memory rate limiting (fast, per-instance)
  // Sufficient for abuse prevention - no Firestore cost
  const ipHash = Buffer.from(clientIp).toString("base64").substring(0, 16);
  if (!checkRateLimit(`guest_cancel:${clientIp}`, 10, 60)) { // 10 attempts per minute
    logRateLimitExceeded(ipHash, "guest_cancel").catch(() => {});

    throw new HttpsError(
      "resource-exhausted",
      "Too many cancellation attempts. Please wait a minute and try again."
    );
  }


  // Validate required fields
  if (!bookingId || !bookingReference || !guestEmail) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required fields: booking_id, booking_reference, guest_email"
    );
  }

  try {
    logInfo(`Guest cancel booking request: ${bookingReference}`, {
      bookingId,
      guestEmail,
    });

    // Find booking using helper (avoids FieldPath.documentId bug with collectionGroup)
    // Note: Guest doesn't have owner_id, so we search comprehensively
    const bookingResult = await findBookingById(bookingId);

    if (!bookingResult) {
      throw new HttpsError("not-found", "Booking not found");
    }

    const bookingDoc = bookingResult.doc;
    const bookingRef = bookingDoc.ref;
    const booking = bookingResult.data;

    // Verify booking reference matches
    if (booking.booking_reference !== bookingReference) {
      throw new HttpsError(
        "permission-denied",
        "Invalid booking reference"
      );
    }

    // Verify guest email matches
    const bookingEmail = booking.guest_email || booking.guest_details?.email;
    if (bookingEmail?.toLowerCase() !== guestEmail.toLowerCase()) {
      throw new HttpsError(
        "permission-denied",
        "Email does not match booking records"
      );
    }

    // Check if booking can be cancelled (status)
    if (booking.status !== "confirmed" && booking.status !== "pending") {
      throw new HttpsError(
        "failed-precondition",
        `Cannot cancel booking with status: ${booking.status}`
      );
    }

    // Extract property and unit IDs for transaction
    const propertyId = booking.property_id;
    const unitId = booking.unit_id;

    if (!propertyId || !unitId) {
      throw new HttpsError(
        "internal",
        "Booking is missing property_id or unit_id"
      );
    }

    // ====================================================================
    // CRITICAL: Use Firestore transaction for atomic cancellation
    // Prevents race conditions and ensures idempotency
    // FIX: Widget settings now fetched INSIDE transaction (prevents race condition)
    // ====================================================================
    const cancellationResult = await db.runTransaction(async (transaction) => {
      // Step 1: Fetch widget settings INSIDE transaction (atomic read)
      // Widget settings are stored as subcollection: properties/{propertyId}/widget_settings/{unitId}
      const widgetSettingsRef = db
        .collection("properties")
        .doc(propertyId)
        .collection("widget_settings")
        .doc(unitId);
      const widgetSettingsDoc = await transaction.get(widgetSettingsRef);

      if (!widgetSettingsDoc.exists) {
        throw new HttpsError(
          "not-found",
          "Widget settings not found for this booking"
        );
      }

      const widgetSettings = widgetSettingsDoc.data()!;

      // Step 2: Validate cancellation policy (atomic validation)
      // Check if guest cancellation is allowed
      if (!widgetSettings.allow_guest_cancellation) {
        // Sentinel — caught by outer handler, converted to structured response.
        // Avoid HttpsError here so Sentry doesn't capture an expected business
        // rejection as an unhandled error.
        throw new GuestCancellationDisabledError();
      }

      // Check cancellation deadline
      const cancellationDeadlineHours =
        widgetSettings.cancellation_deadline_hours || 48;
      const now = new Date();

      // Step 3: Re-read booking INSIDE transaction (fresh data)
      const freshBookingDoc = await transaction.get(bookingRef);

      if (!freshBookingDoc.exists) {
        throw new HttpsError("not-found", "Booking not found");
      }

      const freshBooking = freshBookingDoc.data()!;

      // Step 4: IDEMPOTENCY CHECK - if already cancelled, return success
      if (freshBooking.status === "cancelled") {
        logInfo(`Booking already cancelled: ${bookingReference}`, {
          bookingId,
          cancelledBy: freshBooking.cancelled_by,
          cancelledAt: freshBooking.cancelled_at,
        });

        return {
          alreadyCancelled: true,
          cancelledBy: freshBooking.cancelled_by || "unknown",
          cancelledAt: freshBooking.cancelled_at,
          refundAmount: freshBooking.refund_amount || 0,
          refundStatus: freshBooking.refund_status || "not_applicable",
          widgetSettings, // Return for use outside transaction
        };
      }

      // Step 5: Re-validate status (ensure still cancellable)
      if (freshBooking.status !== "confirmed" &&
          freshBooking.status !== "pending") {
        throw new HttpsError(
          "failed-precondition",
          `Cannot cancel booking with status: ${freshBooking.status}`
        );
      }

      // Step 6: Re-check cancellation deadline using fresh booking data
      const freshCheckInDate = safeToDate(freshBooking.check_in, "check_in");
      const hoursUntilCheckIn =
        (freshCheckInDate.getTime() - now.getTime()) / (1000 * 60 * 60);

      if (hoursUntilCheckIn < cancellationDeadlineHours) {
        throw new HttpsError(
          "failed-precondition",
          "Cancellation deadline has passed during processing."
        );
      }

      // Step 7: Calculate refund amount based on payment status
      let refundAmount = 0;
      let refundStatus = "not_applicable";
      const paymentStatus = freshBooking.payment_status;
      const paymentMethod = freshBooking.payment_method;
      const paidAmount = freshBooking.paid_amount || 0;

      if (paymentStatus === "paid" && paidAmount > 0) {
        // User has paid - eligible for refund
        // TODO: Add cancellation policy logic (full_refund/50_percent/no_refund)
        refundAmount = paidAmount; // Full refund for now
        refundStatus = paymentMethod === "stripe" ?
          "pending_stripe" :
          "pending_manual";
      }

      // Step 8: Update booking atomically
      transaction.update(bookingRef, {
        status: "cancelled",
        cancelled_at: admin.firestore.FieldValue.serverTimestamp(),
        cancelled_by: "guest",
        cancellation_reason: "Guest cancellation via widget",
        refund_amount: refundAmount,
        refund_status: refundStatus,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      logSuccess(`Booking cancelled atomically: ${bookingReference}`, {
        bookingId,
        guestEmail,
        refundAmount,
        refundStatus,
      });

      return {
        alreadyCancelled: false,
        refundAmount,
        refundStatus,
        paymentMethod,
        stripePaymentIntentId: freshBooking.stripe_payment_intent_id,
        widgetSettings, // Return for use outside transaction
      };
    });

    // Handle idempotency - if already cancelled, return early
    if (cancellationResult.alreadyCancelled) {
      logInfo(`Idempotent cancellation request: ${bookingReference}`);
      // Continue to send email confirmation (user may not have received it)
    }

    // ====================================================================
    // Step 7: Process Stripe refund AFTER transaction completes
    // (Outside transaction to avoid blocking on external API)
    // Shared helper used by both guest + owner cancellation flows so the
    // refund leg cannot drift between callers. See audit/52 F-52-01 for the
    // destination refund / reverse_transfer rationale.
    // ====================================================================
    if (cancellationResult.refundStatus === "pending_stripe" &&
        cancellationResult.refundAmount > 0) {
      await processStripeRefund({
        bookingId,
        bookingReference,
        bookingRef,
        ownerId: booking.owner_id,
        stripePaymentIntentId: cancellationResult.stripePaymentIntentId,
        refundAmount: cancellationResult.refundAmount,
        cancelledBy: "guest",
      });
    }

    // Send cancellation confirmation email to guest
    try {
      // Get email config from widget settings (returned from transaction)
      const emailConfig = cancellationResult.widgetSettings.email_config || {};
      const emailValidation = validateEmailConfig(emailConfig);

      if (emailValidation.isValid) {
        const guestName = booking.guest_details?.name || booking.guest_name || "Guest";

        // Fetch property and unit names using shared utility
        const {propertyName, unitName} = await fetchPropertyAndUnitDetails(
          propertyId,
          unitId,
          "guestCancelBooking"
        );

        await sendBookingCancellationEmail(
          guestEmail,
          guestName,
          bookingReference,
          propertyName,
          unitName,
          safeToDate(booking.check_in, "check_in"),
          safeToDate(booking.check_out, "check_out"),
          cancellationResult.refundAmount, // Actual refund amount
          propertyId
        );
        logSuccess(`Cancellation email sent to guest: ${guestEmail}`);
      } else {
        logInfo(`Email not sent: ${emailValidation.reason}`, {
          bookingId,
          guestEmail,
        });
      }
    } catch (emailError) {
      logError("Failed to send cancellation email", emailError, {
        bookingId,
        guestEmail,
      });
      // Don't fail the whole cancellation if email fails
    }

    // Send push notification to owner about guest cancellation (non-blocking)
    try {
      const ownerId = booking.owner_id;
      if (ownerId) {
        const guestName = booking.guest_details?.name || booking.guest_name || "Guest";
        sendGuestCancellationPushNotification(
          ownerId,
          bookingId,
          guestName,
          safeToDate(booking.check_in, "check_in"),
          safeToDate(booking.check_out, "check_out")
        ).catch((e) => logError("Failed to send guest cancellation push notification", e));

        logInfo("Owner push notification sent for guest cancellation", {
          ownerId,
          bookingId,
        });
      }
    } catch (notificationError) {
      logError("Failed to send owner notification", notificationError);
    }

    return {
      success: true,
      message:
        "Booking cancelled successfully. " +
        "You will receive a confirmation email shortly.",
      bookingReference,
      cancelledAt: new Date().toISOString(),
    };
  } catch (error) {
    // Expected business rejection — return structured response (not an error).
    if (error instanceof GuestCancellationDisabledError) {
      logWarn("Guest cancellation rejected by property policy", {
        bookingId,
        bookingReference,
        guestEmail,
      });
      return {
        success: false,
        reason: "guest_cancel_disabled",
        message: "Guest cancellation is not allowed for this property. " +
          "Please contact the property owner.",
      };
    }

    // Log full error details for debugging (server-side only)
    logError("Error cancelling booking", error, {
      bookingId,
      bookingReference,
      guestEmail,
    });

    // Re-throw HttpsErrors (these have safe, user-facing messages)
    if (error instanceof HttpsError) {
      throw error;
    }

    // SECURITY: Don't expose internal error details to client
    // Log the actual error but return generic message
    throw new HttpsError(
      "internal",
      "Failed to cancel booking. Please try again or contact support."
    );
  }
});
