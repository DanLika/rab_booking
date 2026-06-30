import {admin} from "./firebase";
import {logInfo, logError, logSuccess} from "./logger";
import {shouldSendSmsNotification} from "./notificationPreferences";

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

/**
 * High-level SMS notifications (Localized)
 */

export interface SmsNotificationData {
  userId: string;
  body: string;
  category: "bookings" | "payments" | "calendar" | "marketing";
}

async function getUserPhoneNumber(userId: string): Promise<string | null> {
  try {
    const profileDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("data")
      .doc("profile")
      .get();

    if (!profileDoc.exists) return null;
    return profileDoc.data()?.phoneE164 || null;
  } catch (error) {
    logError("[SMS Service] Error fetching user phone number", error, {userId});
    return null;
  }
}

export async function sendNotificationSms(
  data: SmsNotificationData
): Promise<boolean> {
  const {userId, body, category} = data;

  try {
    const shouldSend = await shouldSendSmsNotification(userId, category);
    if (!shouldSend) {
      logInfo("[SMS Service] User opted out of SMS notifications", {userId, category});
      return false;
    }

    const phoneNumber = await getUserPhoneNumber(userId);
    if (!phoneNumber) {
      logInfo("[SMS Service] No phone number available for user", {userId});
      return false;
    }

    return await sendSms({
      to: phoneNumber,
      message: body,
      ownerId: userId,
      category,
    });
  } catch (error) {
    logError("[SMS Service] Error sending notification SMS", error, {userId, category});
    return false;
  }
}

function formatDateRange(checkInDate: Date, checkOutDate: Date): string {
  const formattedCheckIn = checkInDate.toLocaleDateString("hr-HR", {
    day: "2-digit",
    month: "short",
  });
  const formattedCheckOut = checkOutDate.toLocaleDateString("hr-HR", {
    day: "2-digit",
    month: "short",
  });
  return `${formattedCheckIn} - ${formattedCheckOut}`;
}

export async function sendPaymentSmsNotification(
  userId: string,
  guestName: string,
  amount: number,
  currency: string = "EUR"
): Promise<boolean> {
  const formattedAmount = new Intl.NumberFormat("hr-HR", {
    style: "currency",
    currency,
  }).format(amount);

  return sendNotificationSms({
    userId,
    body: `${guestName} je platio/la ${formattedAmount} za rezervaciju.`,
    category: "bookings",
  });
}

export async function sendPendingBookingSmsNotification(
  userId: string,
  guestName: string,
  checkInDate: Date,
  checkOutDate: Date
): Promise<boolean> {
  const dateRange = formatDateRange(checkInDate, checkOutDate);

  return sendNotificationSms({
    userId,
    body: `${guestName} je zatražio/la rezervaciju za ${dateRange}.`,
    category: "bookings",
  });
}

export async function sendGuestCancellationSmsNotification(
  userId: string,
  guestName: string,
  checkInDate: Date,
  checkOutDate: Date
): Promise<boolean> {
  const dateRange = formatDateRange(checkInDate, checkOutDate);

  return sendNotificationSms({
    userId,
    body: `${guestName} je otkazao/la rezervaciju za ${dateRange}.`,
    category: "bookings",
  });
}

export async function sendTrialExpiringSmsNotification(
  userId: string,
  daysRemaining: number
): Promise<boolean> {
  const dayText = daysRemaining === 1 ? "dan" : "dana";
  const urgency = daysRemaining === 1 ?
    "ističe sutra" :
    `ističe za ${daysRemaining} ${dayText}`;

  return sendNotificationSms({
    userId,
    body: `Vaš besplatni probni period ${urgency}. Nadogradite kako biste nastavili upravljati rezervacijama.`,
    category: "marketing",
  });
}

export async function sendOverbookingSmsNotification(
  userId: string,
  unitName: string,
  guestName1: string,
  guestName2: string
): Promise<boolean> {
  return sendNotificationSms({
    userId,
    body: `⚠️ UPOZORENJE: Preklapanje rezervacija za ${unitName}. Konflikt između ${guestName1} i ${guestName2}. Riješite odmah!`,
    category: "bookings",
  });
}
