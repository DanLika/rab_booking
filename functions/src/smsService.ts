import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logInfo, logError, logSuccess} from "./logger";
import {enforceRateLimit} from "./utils/rateLimit";
import {setUser} from "./sentry";

/**
 * SMS Service using Twilio
 *
 * Simple SMS sending for critical notifications
 *
 * Note: For MVP, this is a simplified version.
 * Full features (rate limiting, delivery tracking, webhooks) can be added
 * later if needed.
 */

// Configuration
const TWILIO_ACCOUNT_SID = process.env.TWILIO_ACCOUNT_SID || "";
const TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN || "";
const TWILIO_PHONE_NUMBER = process.env.TWILIO_PHONE_NUMBER || "";

interface SendSmsParams {
  to: string;
  message: string;
  ownerId: string;
  category: "bookings" | "payments" | "calendar" | "marketing";
}

/**
 * Send SMS via Twilio
 *
 * Simplified version for MVP - just sends SMS without complex tracking
 *
 * @param {SendSmsParams} params - The SMS parameters
 * @return {Promise<boolean>} True if SMS was sent successfully
 */
export async function sendSms(params: SendSmsParams): Promise<boolean> {
  const {to, message, ownerId} = params;

  // Skip if Twilio is not configured
  if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN || !TWILIO_PHONE_NUMBER) {
    logInfo("[SMS Service] Twilio not configured, skipping SMS", {
      ownerId,
    });
    return false;
  }

  try {
    // Basic validation
    if (!to || !to.startsWith("+")) {
      logError("[SMS Service] Invalid phone number format", null, {
        to,
        ownerId,
      });
      return false;
    }

    if (message.length > 1600) {
      logError("[SMS Service] Message too long", null, {
        messageLength: message.length,
        ownerId,
      });
      return false;
    }

    logInfo("[SMS Service] Sending SMS", {
      to,
      ownerId,
      messageLength: message.length,
    });

    // Send SMS via Twilio API
    const apiUrl = `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`;
    const authString = `${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`;
    const base64Auth = Buffer.from(authString).toString("base64");
    const response = await fetch(apiUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": `Basic ${base64Auth}`,
      },
      body: new URLSearchParams({
        From: TWILIO_PHONE_NUMBER,
        To: to,
        Body: message,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      logError("[SMS Service] Twilio API error", null, {
        status: response.status,
        error: errorText,
      });
      return false;
    }

    logSuccess("[SMS Service] SMS sent successfully", {
      to,
      ownerId,
    });

    return true;
  } catch (error) {
    logError("[SMS Service] Error sending SMS", error, {
      to,
      ownerId,
    });
    return false;
  }
}

/**
 * Callable Cloud Function: Send SMS notification
 *
 * SECURITY:
 * - Authentication required
 * - Rate limiting: 5 SMS per minute per user
 * - Input validation
 */
export const sendSMSNotification = onCall(async (request) => {
  // Verify authentication
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "User must be authenticated to send SMS"
    );
  }

  const userId = request.auth.uid;

  // Set user context for Sentry error tracking
  setUser(userId);

  // SECURITY: Rate limiting - 5 SMS per minute
  await enforceRateLimit(userId, "send_sms", {
    maxCalls: 5,
    windowMs: 60000, // 1 minute
    errorMessage:
      "Rate limit exceeded. Maximum 5 SMS per minute. " +
      "Please wait before sending more.",
  });

  // Extract parameters
  const {to, message, category} = request.data;

  // Validate required parameters
  if (!to || !message) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required fields: to, message"
    );
  }

  try {
    const success = await sendSms({
      to,
      message,
      ownerId: userId,
      category: category || "marketing",
    });

    if (!success) {
      throw new HttpsError("internal", "Failed to send SMS");
    }

    return {
      success: true,
      message: "SMS sent successfully",
    };
  } catch (error) {
    logError("Error in sendSMSNotification", error);
    throw new HttpsError("internal", "Failed to send SMS. Please try again.");
  }
});
