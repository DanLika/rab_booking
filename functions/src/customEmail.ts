import {onCall, HttpsError} from "firebase-functions/v2/https";
import {sendCustomEmailToGuest} from "./emailService";
import {logError} from "./logger";
import {validateEmail} from "./utils/emailValidation";
import {enforceRateLimit} from "./utils/rateLimit";
import {db} from "./firebase";

/**
 * Callable Cloud Function: Send custom email to guest
 * Phase 2 feature for property owners
 *
 * SECURITY:
 * - Authentication required (must be logged in)
 * - Authorization required (must be owner of the booking)
 * - Rate limiting: 10 emails per minute per user
 * - Input validation and length limits
 */
export const sendCustomEmailToGuestFunction = onCall(async (request) => {
  // Verify authentication
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "User must be authenticated to send emails"
    );
  }

  const userId = request.auth.uid;

  // SECURITY: Rate limiting - 10 emails per minute
  await enforceRateLimit(userId, "send_custom_email", {
    maxCalls: 10,
    windowMs: 60000, // 1 minute
    errorMessage:
      "Rate limit exceeded. Maximum 10 custom emails per minute. Please wait before sending more.",
  });

  // Extract parameters
  const {bookingId, guestEmail, guestName, subject, message} = request.data;

  // Validate required parameters
  if (!bookingId || !guestEmail || !guestName || !subject || !message) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required fields: bookingId, guestEmail, guestName, subject, message"
    );
  }

  // SECURITY: Authorization - verify user owns the booking
  const bookingDoc = await db.collection("bookings").doc(bookingId).get();

  if (!bookingDoc.exists) {
    throw new HttpsError("not-found", "Booking not found");
  }

  const bookingData = bookingDoc.data()!;

  // Check: Is this user the owner of the booking?
  if (bookingData.owner_id !== userId) {
    throw new HttpsError(
      "permission-denied",
      "You can only send emails to guests of your own bookings"
    );
  }

  // Check: Does the guest email match the booking?
  if (bookingData.guest_email !== guestEmail) {
    throw new HttpsError(
      "permission-denied",
      "Guest email does not match the booking record"
    );
  }

  // Input length limits (RFC 5321 compliant + practical limits)
  const MAX_EMAIL_LENGTH = 254;
  const MAX_NAME_LENGTH = 100;
  const MAX_SUBJECT_LENGTH = 998; // RFC 5321
  const MAX_MESSAGE_LENGTH = 50000; // ~50KB message body

  if (typeof guestEmail !== "string" || guestEmail.length > MAX_EMAIL_LENGTH) {
    throw new HttpsError("invalid-argument", "Email address too long");
  }
  if (typeof guestName !== "string" || guestName.length > MAX_NAME_LENGTH) {
    throw new HttpsError("invalid-argument", "Guest name too long");
  }
  if (typeof subject !== "string" || subject.length > MAX_SUBJECT_LENGTH) {
    throw new HttpsError("invalid-argument", "Subject too long");
  }
  if (typeof message !== "string" || message.length > MAX_MESSAGE_LENGTH) {
    throw new HttpsError("invalid-argument", "Message too long (max 50KB)");
  }

  // RFC-compliant email validation
  if (!validateEmail(guestEmail)) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid email address. Please provide a valid email with a proper domain (e.g., example@domain.com)."
    );
  }

  try {
    // Fetch property data for email context
    const propertyDoc = await db
      .collection("properties")
      .doc(bookingData.property_id)
      .get();
    const propertyData = propertyDoc.data();

    // Send email with property context
    await sendCustomEmailToGuest(
      guestEmail,
      guestName,
      subject,
      message,
      bookingData.owner_id, // Pass owner email if needed
      propertyData?.name // Pass property name for email signature
    );

    return {
      success: true,
      message: "Custom email sent successfully",
      bookingId,
    };
  } catch (error) {
    logError("Error in sendCustomEmailToGuestFunction", error);
    throw new HttpsError(
      "internal",
      "Failed to send email. Please try again."
    );
  }
});
