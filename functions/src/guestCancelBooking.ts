import {onCall, HttpsError} from "firebase-functions/v2/https";
import {admin, db} from "./firebase";
import {logInfo, logError, logSuccess} from "./logger";
import {sendBookingCancellationEmail} from "./emailService";

/**
 * Cloud Function: Guest Cancel Booking
 *
 * Allows guests to cancel their own booking if:
 * 1. Booking is in 'confirmed' or 'pending' status
 * 2. Cancellation is within the allowed deadline (hours before check-in)
 * 3. Guest provides correct booking reference and email
 */
export const guestCancelBooking = onCall(async (request) => {
  const data = request.data;
  const {bookingId, bookingReference, guestEmail} = data;

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

    // Get booking document
    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw new HttpsError("not-found", "Booking not found");
    }

    const booking = bookingDoc.data()!;

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

    // Get widget settings to check cancellation policy
    // Widget settings are stored as subcollection: properties/{propertyId}/widget_settings/{unitId}
    const propertyId = booking.property_id;
    const unitId = booking.unit_id;

    if (!propertyId || !unitId) {
      throw new HttpsError(
        "internal",
        "Booking is missing property_id or unit_id"
      );
    }

    const widgetSettingsRef = db
      .collection("properties")
      .doc(propertyId)
      .collection("widget_settings")
      .doc(unitId);
    const widgetSettingsDoc = await widgetSettingsRef.get();

    if (!widgetSettingsDoc.exists) {
      throw new HttpsError(
        "not-found",
        "Widget settings not found for this booking"
      );
    }

    const widgetSettings = widgetSettingsDoc.data()!;

    // Check if guest cancellation is allowed
    if (!widgetSettings.allow_guest_cancellation) {
      throw new HttpsError(
        "permission-denied",
        "Guest cancellation is not allowed for this property. " +
        "Please contact the property owner."
      );
    }

    // Check cancellation deadline
    const cancellationDeadlineHours =
      widgetSettings.cancellation_deadline_hours || 48;
    const checkInDate = booking.check_in.toDate();
    const now = new Date();
    const hoursUntilCheckIn =
      (checkInDate.getTime() - now.getTime()) / (1000 * 60 * 60);

    if (hoursUntilCheckIn < cancellationDeadlineHours) {
      throw new HttpsError(
        "failed-precondition",
        `Cancellation deadline has passed. ` +
        `You must cancel at least ${cancellationDeadlineHours} hours before check-in. ` +
        `Please contact the property owner.`
      );
    }

    // Update booking status to 'cancelled'
    await bookingRef.update({
      status: "cancelled",
      cancelled_at: admin.firestore.FieldValue.serverTimestamp(),
      cancelled_by: "guest",
      cancellation_reason: "Guest cancellation via widget",
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    logSuccess(`Booking cancelled by guest: ${bookingReference}`, {
      bookingId,
      guestEmail,
    });

    // Send cancellation confirmation email to guest
    try {
      // Get email config from widget settings
      const emailConfig = widgetSettings.email_config || {};

      if (emailConfig.enabled && emailConfig.is_configured) {
        const guestName = booking.guest_details?.name || booking.guest_name || "Guest";
        await sendBookingCancellationEmail(
          guestEmail,
          guestName,
          bookingReference,
          "Guest cancellation"
        );
        logSuccess(`Cancellation email sent to guest: ${guestEmail}`);
      }
    } catch (emailError) {
      logError("Failed to send cancellation email", emailError);
      // Don't fail the whole cancellation if email fails
    }

    // Send notification email to owner (if contact email exists)
    try {
      const ownerEmail = widgetSettings.contact_options?.email_address;
      if (ownerEmail) {
        // You can implement owner notification here if needed
        logInfo(`Owner notification would be sent to: ${ownerEmail}`);
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
    logError("Error cancelling booking", error);

    // Re-throw HttpsErrors
    if (error instanceof HttpsError) {
      throw error;
    }

    // Wrap other errors
    throw new HttpsError(
      "internal",
      `Failed to cancel booking: ${error}`
    );
  }
});
