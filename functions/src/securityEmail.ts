import {onCall, HttpsError} from "firebase-functions/v2/https";
import {sendSuspiciousActivityEmail} from "./emailService";
import {logError} from "./logger";
import {validateEmail} from "./utils/emailValidation";

/**
 * Callable Cloud Function: Send suspicious activity alert email
 * Phase 3 security feature - alerts users of new device/location logins
 */
export const sendSuspiciousActivityAlert = onCall(async (request) => {
  // Verify authentication
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "User must be authenticated to trigger security alerts"
    );
  }

  // Extract parameters
  const {userEmail, userName, deviceId, location, reason} = request.data;

  // Validate parameters
  if (!userEmail || !userName || !reason) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required fields: userEmail, userName, reason"
    );
  }

  // RFC-compliant email validation
  if (!validateEmail(userEmail)) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid email address. Please provide a valid email with a proper domain (e.g., example@domain.com)."
    );
  }

  try {
    // Send email - combine details into single string
    const details = `User: ${userName} (${userEmail})\nDevice: ${deviceId}\nLocation: ${location}\nReason: ${reason}`;
    await sendSuspiciousActivityEmail(
      userEmail,
      "Suspicious Login Activity",
      details
    );

    return {
      success: true,
      message: `Security alert sent to ${userEmail}`,
    };
  } catch (error) {
    logError("Error in sendSuspiciousActivityAlert", error);
    throw new HttpsError(
      "internal",
      "Failed to send security alert. Please try again."
    );
  }
});
