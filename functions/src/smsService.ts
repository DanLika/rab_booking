import {logInfo, logError, logSuccess} from "./logger";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {enforceRateLimit} from "./utils/rateLimit";

/**
 * SMS Service using Twilio
 *
 * Simple SMS sending for critical notifications
 *
 * Note: For MVP, this is a simplified version.
 * Full features (rate limiting, delivery tracking, webhooks)
 * can be added later if needed.
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
 * @param {SendSmsParams} params - The SMS parameters
 * @return {Promise<boolean>} Success status
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
    const response = await fetch(apiUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization":
          `Basic ${Buffer.from(
            `${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`
          ).toString("base64")}`,
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
 * Callable function to send SMS notifications
 * Incorporates authentication, input validation, and rate limiting
 */
export const sendSMSNotification = onCall(
  {
    region: "europe-west1",
    enforceAppCheck: false,
  },
  async (request) => {
    // 1. Authentication Check
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to send SMS notifications."
      );
    }
    const userId = request.auth.uid;

    const {to, message, category} = request.data as Partial<SendSmsParams>;

    // 2. Input Validation
    if (!to || typeof to !== "string" || !to.startsWith("+")) {
      throw new HttpsError(
        "invalid-argument",
        "A valid phone number with country code is required."
      );
    }

    if (!message || typeof message !== "string" || message.trim() === "") {
      throw new HttpsError(
        "invalid-argument",
        "A non-empty message is required."
      );
    }

    if (message.length > 1600) {
      throw new HttpsError(
        "invalid-argument",
        "Message exceeds the maximum length of 1600 characters."
      );
    }

    const validCategories = ["bookings", "payments", "calendar", "marketing"];
    if (!category || !validCategories.includes(category)) {
      throw new HttpsError(
        "invalid-argument",
        "A valid category is required."
      );
    }

    // 3. Rate Limiting
    // Limit to 10 SMS per user per day (24 hours)
    // to prevent abuse and manage costs
    await enforceRateLimit(userId, "send_sms_notification", {
      maxCalls: 10,
      windowMs: 24 * 60 * 60 * 1000,
      errorMessage: "Daily SMS notification limit exceeded.",
    });

    // 4. Send SMS
    const success = await sendSms({
      to,
      message,
      ownerId: userId,
      category: category as "bookings" | "payments" | "calendar" | "marketing",
    });

    if (!success) {
      throw new HttpsError(
        "internal",
        "Failed to send SMS notification. Please try again later."
      );
    }

    return {success: true};
  }
);
