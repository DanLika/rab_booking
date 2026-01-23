import {onCall, HttpsError} from "firebase-functions/v2/https";
import {db} from "./firebase";
import {logInfo, logError, logSuccess, logWarn} from "./logger";
import {sendBookingConfirmationEmail} from "./emailService";
import {
  generateBookingAccessToken,
  calculateTokenExpiration,
} from "./bookingAccessToken";
import {setUser} from "./sentry";
import {checkRateLimit} from "./utils/rateLimit";

/**
 * Helper to convert Firestore Timestamp or Date to Date object
 */
function toDate(value: any): Date {
  if (!value) {
    throw new Error("Date value is null or undefined");
  }
  // If it's a Firestore Timestamp, convert it
  if (typeof value.toDate === "function") {
    return value.toDate();
  }
  // If it's already a Date, return it
  if (value instanceof Date) {
    return value;
  }
  // Try to parse as date string
  return new Date(value);
}

/**
 * Cloud Function: Resend Guest Booking Email
 *
 * Allows guests to resend their booking confirmation email from the widget.
 * Does NOT require authentication - verifies identity via booking_reference + email.
 * Uses platform's Resend API key (not owner's).
 *
 * Rate limited to prevent abuse: 3 requests per booking per hour.
 */
export const resendGuestBookingEmail = onCall(
  {secrets: ["RESEND_API_KEY"]},
  async (request) => {
    const {bookingReference, guestEmail} = request.data;

    // Set user context for Sentry (use email since guest is not authenticated)
    setUser(null, guestEmail);

    // Validate input
    if (!bookingReference || typeof bookingReference !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "Booking reference is required"
      );
    }

    if (!guestEmail || typeof guestEmail !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "Guest email is required"
      );
    }

    // Sanitize email
    const sanitizedEmail = guestEmail.trim().toLowerCase();

    // Rate limit: 3 requests per booking reference per hour
    // checkRateLimit returns true if allowed, false if rate limited
    const rateLimitKey = `resend_guest_email:${bookingReference}`;
    const isAllowed = checkRateLimit(rateLimitKey, 3, 3600); // 3600 seconds = 1 hour

    if (!isAllowed) {
      logWarn("[ResendGuestEmail] Rate limit exceeded", {
        bookingReference,
        email: sanitizedEmail,
      });
      throw new HttpsError(
        "resource-exhausted",
        "Too many resend attempts. Please try again later."
      );
    }

    try {
      logInfo("[ResendGuestEmail] Starting guest resend process", {
        bookingReference,
        email: sanitizedEmail,
      });

      // Find booking by reference (collection group query)
      const bookingsQuery = await db
        .collectionGroup("bookings")
        .where("booking_reference", "==", bookingReference)
        .limit(1)
        .get();

      if (bookingsQuery.empty) {
        logWarn("[ResendGuestEmail] Booking not found", {bookingReference});
        throw new HttpsError(
          "not-found",
          "Booking not found"
        );
      }

      const bookingDoc = bookingsQuery.docs[0];
      const booking = bookingDoc.data();

      // Verify guest email matches (case-insensitive)
      const bookingEmail = (booking.guest_email || "").trim().toLowerCase();
      if (bookingEmail !== sanitizedEmail) {
        logWarn("[ResendGuestEmail] Email mismatch", {
          bookingReference,
          providedEmail: sanitizedEmail,
          // Don't log actual booking email for privacy
        });
        throw new HttpsError(
          "permission-denied",
          "Email does not match booking records"
        );
      }

      // Validate required booking fields
      if (!booking.property_id) {
        throw new HttpsError("not-found", "Property ID not found in booking");
      }
      if (!booking.unit_id) {
        throw new HttpsError("not-found", "Unit ID not found in booking");
      }

      // Get unit data
      const unitDoc = await db
        .collection("properties")
        .doc(booking.property_id)
        .collection("units")
        .doc(booking.unit_id)
        .get();

      if (!unitDoc.exists) {
        throw new HttpsError("not-found", "Unit not found");
      }
      const unitData = unitDoc.data()!;

      // Get property data
      const propertyDoc = await db
        .collection("properties")
        .doc(booking.property_id)
        .get();
      const propertyData = propertyDoc.data();

      // Generate new access token
      const {token: accessToken, hashedToken} = generateBookingAccessToken();
      const checkOutDate = toDate(booking.check_out);
      const tokenExpiration = calculateTokenExpiration(checkOutDate);

      // Update booking with new access token
      await bookingDoc.ref.update({
        access_token: hashedToken,
        token_expires_at: tokenExpiration,
      });

      // Send confirmation email
      const depositAmount = booking.deposit_amount ||
        booking.advance_amount ||
        0;

      logInfo("[ResendGuestEmail] Sending confirmation email", {
        bookingReference,
        guestName: booking.guest_name,
        unitName: unitData.name || "Unit",
        propertyName: propertyData?.name || "Property",
      });

      await sendBookingConfirmationEmail(
        booking.guest_email,
        booking.guest_name,
        booking.booking_reference,
        toDate(booking.check_in),
        toDate(booking.check_out),
        booking.total_price,
        depositAmount,
        unitData.name || "Unit",
        propertyData?.name || "Property",
        accessToken,
        propertyData?.contact_email,
        booking.property_id
      );

      logSuccess("[ResendGuestEmail] Confirmation email resent to guest", {
        bookingReference,
        email: sanitizedEmail,
      });

      return {
        success: true,
        message: "Confirmation email sent successfully",
      };
    } catch (error: unknown) {
      // Re-throw HttpsError as-is
      if (error instanceof HttpsError) {
        throw error;
      }

      logError("[ResendGuestEmail] Unexpected error", error, {
        bookingReference,
        email: sanitizedEmail,
      });

      throw new HttpsError(
        "internal",
        "Failed to resend email. Please try again."
      );
    }
  }
);
