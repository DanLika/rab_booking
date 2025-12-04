import {onCall, HttpsError} from "firebase-functions/v2/https";
import {sendCustomEmailToGuest} from "./emailService";
import {logError} from "./logger";
import {validateEmail} from "./utils/emailValidation";

/**
 * Callable Cloud Function: Send custom email to guest
 * Phase 2 feature for property owners
 */
export const sendCustomEmailToGuestFunction = onCall(async (request) => {
  // Verify authentication
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "User must be authenticated to send emails"
    );
  }

  // Extract parameters
  const {guestEmail, guestName, subject, message} = request.data;

  // Validate parameters
  if (!guestEmail || !guestName || !subject || !message) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required fields: guestEmail, guestName, subject, message"
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
    // Send email
    await sendCustomEmailToGuest(
      guestEmail,
      guestName,
      subject,
      message
    );

    return {
      success: true,
      message: `Email sent to ${guestEmail}`,
    };
  } catch (error) {
    logError("Error in sendCustomEmailToGuestFunction", error);
    throw new HttpsError(
      "internal",
      "Failed to send email. Please try again."
    );
  }
});
