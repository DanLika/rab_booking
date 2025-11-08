import {onCall, HttpsError} from "firebase-functions/v2/https";
import {sendSuspiciousActivityEmail} from "./emailService";
import {logError} from "./logger";

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

  // Basic email validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(userEmail)) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid email address"
    );
  }

  try {
    // Send email
    await sendSuspiciousActivityEmail(
      userEmail,
      userName,
      deviceId,
      location,
      reason
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
