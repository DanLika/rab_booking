import {onCall, HttpsError} from "firebase-functions/v2/https";
import {db} from "./firebase";
import {logInfo, logError, logSuccess} from "./logger";
import {sendBookingConfirmationEmail} from "./emailService";
import {
  generateBookingAccessToken,
  calculateTokenExpiration,
} from "./bookingAccessToken";
import * as admin from "firebase-admin";

/**
 * Cloud Function: Resend Booking Email
 *
 * Allows property owners to resend booking confirmation emails to guests.
 * Generates a new access token for the booking lookup link.
 * Always sends the confirmation email template (which includes View My Booking link).
 *
 * Requirements:
 * - Caller must be authenticated
 * - Caller must be the owner of the property
 */
export const resendBookingEmail = onCall(async (request) => {
  // Verify authentication
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to resend emails"
    );
  }

  const {bookingId} = request.data;

  if (!bookingId) {
    throw new HttpsError(
      "invalid-argument",
      "Booking ID is required"
    );
  }

  try {
    logInfo("[ResendBookingEmail] Starting resend process", {
      bookingId,
      requesterId: request.auth.uid,
    });

    // Get the booking
    const bookingDoc = await db.collection("bookings").doc(bookingId).get();

    if (!bookingDoc.exists) {
      throw new HttpsError(
        "not-found",
        "Booking not found"
      );
    }

    const booking = bookingDoc.data()!;

    // Get unit to verify ownership
    // NOTE: Units are stored as subcollection: properties/{propertyId}/units/{unitId}
    if (!booking.property_id) {
      throw new HttpsError("not-found", "Property ID not found in booking");
    }

    const unitDoc = await db
      .collection("properties")
      .doc(booking.property_id)
      .collection("units")
      .doc(booking.unit_id)
      .get();
    if (!unitDoc.exists) {
      throw new HttpsError(
        "not-found",
        "Unit not found"
      );
    }
    const unitData = unitDoc.data()!;

    // Verify ownership - check owner_id from booking instead of unit
    if (booking.owner_id !== request.auth.uid) {
      logError("[ResendBookingEmail] Unauthorized - not the owner", {
        requesterId: request.auth.uid,
        ownerId: booking.owner_id,
      });
      throw new HttpsError(
        "permission-denied",
        "You are not authorized to resend emails for this booking"
      );
    }

    // Get property details
    const propertyDoc = await db.collection("properties")
      .doc(booking.property_id)
      .get();
    const propertyData = propertyDoc.data();

    // Generate new access token
    const {token: accessToken, hashedToken} = generateBookingAccessToken();
    const checkOutDate = booking.check_out.toDate();
    const tokenExpiration = calculateTokenExpiration(checkOutDate);

    // Update booking with new access token
    await bookingDoc.ref.update({
      access_token: hashedToken,
      token_expires_at: tokenExpiration,
    });

    // Always send the confirmation email (which includes View My Booking link)
    const depositAmount = booking.deposit_amount ||
      booking.advance_amount ||
      0;

    // Log email parameters for debugging
    logInfo("[ResendBookingEmail] Preparing to send email", {
      guestEmail: booking.guest_email,
      guestName: booking.guest_name,
      bookingReference: booking.booking_reference,
      checkIn: booking.check_in?.toDate?.() ? booking.check_in.toDate().toISOString() : String(booking.check_in),
      checkOut: booking.check_out?.toDate?.() ? booking.check_out.toDate().toISOString() : String(booking.check_out),
      totalPrice: booking.total_price,
      depositAmount,
      unitName: unitData.name || "Unit",
      propertyName: propertyData?.name || "Property",
      ownerEmail: propertyData?.contact_email,
      propertyId: booking.property_id,
    });

    await sendBookingConfirmationEmail(
      booking.guest_email,
      booking.guest_name,
      booking.booking_reference,
      booking.check_in.toDate(),
      booking.check_out.toDate(),
      booking.total_price,
      depositAmount,
      unitData.name || "Unit",
      propertyData?.name || "Property",
      accessToken,
      propertyData?.contact_email,
      booking.property_id // Pass propertyId for subdomain lookup
    );

    logSuccess("[ResendBookingEmail] Confirmation email resent", {
      bookingId,
      email: booking.guest_email,
      status: booking.status,
    });

    // Record the resend in booking history
    await bookingDoc.ref.update({
      last_email_resent: admin.firestore.FieldValue.serverTimestamp(),
      email_resent_count: admin.firestore.FieldValue.increment(1),
    });

    return {
      success: true,
      message: `Email successfully sent to ${booking.guest_email}`,
    };
  } catch (error: unknown) {
    // Re-throw HttpsError as-is
    if (error instanceof HttpsError) {
      throw error;
    }

    // Log unexpected errors - pass error as second param for proper serialization
    logError("[ResendBookingEmail] Unexpected error", error, {
      bookingId,
      requesterId: request.auth.uid,
    });

    throw new HttpsError(
      "internal",
      "Failed to resend email. Please try again."
    );
  }
});
