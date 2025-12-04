import {onCall, HttpsError} from "firebase-functions/v2/https";
import {sendSuspiciousActivityEmail} from "./emailService";
import {logError} from "./logger";
import {validateEmail} from "./utils/emailValidation";
import {sanitizeText} from "./utils/inputSanitization";
import {enforceRateLimit} from "./utils/rateLimit";

/**
 * Callable Cloud Function: Send suspicious activity alert email
 * Phase 3 security feature - alerts users of new device/location logins
 *
 * SECURITY:
 * - Authentication required
 * - Input sanitization for all text fields
 * - Rate limiting: 5 alerts per hour per user
 */
export const sendSuspiciousActivityAlert = onCall(async (request) => {
  // Verify authentication
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "User must be authenticated to trigger security alerts"
    );
  }

  const userId = request.auth.uid;

  // SECURITY: Rate limiting - 5 security alerts per hour
  await enforceRateLimit(userId, "security_alert", {
    maxCalls: 5,
    windowMs: 3600000, // 1 hour
    errorMessage:
      "Rate limit exceeded. Maximum 5 security alerts per hour. Please wait before sending more.",
  });

  // Extract parameters
  const {userEmail, userName, deviceId, location, reason} = request.data;

  // Validate required parameters
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

  // SECURITY: Sanitize all text inputs to prevent XSS and injection attacks
  const sanitizedUserName = sanitizeText(userName) || "Unknown User";
  const sanitizedDeviceId = deviceId ? sanitizeText(deviceId) : "Unknown Device";
  const sanitizedLocation = location ? sanitizeText(location) : "Unknown Location";
  const sanitizedReason = sanitizeText(reason) || "No reason provided";

  // Validate sanitized inputs
  if (sanitizedUserName.length < 2) {
    throw new HttpsError(
      "invalid-argument",
      "User name is too short or contains only invalid characters"
    );
  }

  if (sanitizedReason.length < 3) {
    throw new HttpsError(
      "invalid-argument",
      "Reason is too short or contains only invalid characters"
    );
  }

  try {
    // Send email - combine sanitized details into single string
    const details = `User: ${sanitizedUserName} (${userEmail})\nDevice: ${sanitizedDeviceId}\nLocation: ${sanitizedLocation}\nReason: ${sanitizedReason}`;

    await sendSuspiciousActivityEmail(
      userEmail,
      "Suspicious Login Activity",
      details
    );

    return {
      success: true,
      message: "Security alert sent successfully",
    };
  } catch (error) {
    logError("Error in sendSuspiciousActivityAlert", error);
    throw new HttpsError(
      "internal",
      "Failed to send security alert. Please try again."
    );
  }
});
