import {shouldSendEmailNotification} from "./notificationPreferences";
import {logInfo, logWarn} from "./logger";

/**
 * Email Notification Helper - Respects Owner Preferences
 *
 * Wrapper za slanje emaila sa provjerom notification preferences.
 * Respektuje owner-ove postavke iz Notification Settings screen-a.
 *
 * @module emailNotificationHelper
 */

/**
 * Send email if owner's notification preferences allow it
 *
 * This function checks the owner's notification preferences before sending an email.
 * It respects the owner's choice to opt-out of specific notification categories.
 *
 * @param ownerId - Owner user ID (from Firestore users collection)
 * @param category - Notification category (bookings, payments, calendar, marketing)
 * @param sendEmailFn - Async function that sends the email
 * @param forceIfCritical - If true, sends email even if owner opted out
 *                          (use for critical events that require immediate attention)
 * @returns Promise<boolean> - true if email was sent, false if skipped due to preferences
 *
 * @example
 * // Respect preferences for instant bookings
 * await sendEmailIfAllowed(
 *   ownerId,
 *   'bookings',
 *   async () => await sendBookingConfirmationOwnerEmail(...),
 *   false // Owner can opt-out
 * );
 *
 * @example
 * // Force send for pending bookings (requires owner approval)
 * await sendEmailIfAllowed(
 *   ownerId,
 *   'bookings',
 *   async () => await sendPendingBookingOwnerNotification(...),
 *   true // Critical - owner MUST be notified
 * );
 */
export async function sendEmailIfAllowed(
  ownerId: string,
  category: "bookings" | "payments" | "calendar" | "marketing",
  sendEmailFn: () => Promise<void>,
  forceIfCritical = false
): Promise<boolean> {
  try {
    // CRITICAL EVENTS: Override preferences
    // Pending bookings require owner approval, so we MUST notify them
    if (forceIfCritical) {
      logInfo(
        `[EmailHelper] Sending critical ${category} email (bypassing preferences)`,
        {ownerId, category}
      );
      await sendEmailFn();
      return true;
    }

    // CHECK PREFERENCES: Does owner want to receive this category?
    const shouldSend = await shouldSendEmailNotification(ownerId, category);

    if (!shouldSend) {
      logInfo(
        `[EmailHelper] Owner opted out of ${category} emails (not sending)`,
        {ownerId, category}
      );
      return false;
    }

    // SEND EMAIL: Owner wants to receive this notification
    logInfo(
      `[EmailHelper] Owner preferences allow ${category} email (sending)`,
      {ownerId, category}
    );
    await sendEmailFn();
    return true;
  } catch (error: any) {
    // FALLBACK: If preference check fails, SEND email anyway (safer)
    // Better to send an email owner doesn't want than miss a critical notification
    logWarn(
      `[EmailHelper] Failed to check preferences for ${category} email, sending anyway (safe fallback)`,
      {ownerId, category, error: error.message}
    );

    try {
      await sendEmailFn();
      return true;
    } catch (sendError: any) {
      // Email send also failed - log and re-throw
      logWarn(
        `[EmailHelper] Failed to send ${category} email after preference check failure`,
        {ownerId, category, error: sendError.message}
      );
      throw sendError;
    }
  }
}
