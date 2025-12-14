import {logInfo, logError, logSuccess} from "./logger";

/**
 * SMS Service using Twilio
 * 
 * Simple SMS sending for critical notifications
 * 
 * Note: For MVP, this is a simplified version.
 * Full features (rate limiting, delivery tracking, webhooks) can be added later if needed.
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
        "Authorization": `Basic ${Buffer.from(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`).toString("base64")}`,
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

