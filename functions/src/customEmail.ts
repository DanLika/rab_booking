import {onCall, HttpsError} from "firebase-functions/v2/https";
import {sendCustomEmailToGuest} from "./emailService";
import {logError} from "./logger";

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

  // Basic email validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(guestEmail)) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid email address"
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
