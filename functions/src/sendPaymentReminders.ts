/**
 * Scheduled Cloud Function: Send Payment Reminders
 *
 * Runs daily to send payment reminder emails to guests for bank transfer
 * bookings that are approaching their payment deadline (e.g., within 24 hours).
 *
 * This prevents unexpected cancellations and improves guest experience.
 *
 * FLOW:
 * 1. Scheduled to run once per day (e.g., at 9 AM).
 * 2. Queries all bookings with:
 *    - status: 'pending_payment'
 *    - paymentMethod: 'bank_transfer'
 *    - payment_reminder_sent: false (or does not exist)
 *    - payment_deadline: between now and 24 hours from now
 * 3. For each found booking, it triggers a payment reminder email.
 * 4. After sending the email, it updates the booking to set
 *    `payment_reminder_sent: true` to prevent duplicate reminders.
 * 5. Logs the number of reminders sent and any failures.
 */

import {onSchedule} from "firebase-functions/v2/scheduler";
import {db, admin} from "./firebase";
import {logError, logSuccess, logInfo} from "./logger";
import {sendPaymentReminderEmail} from "./emailService";

// Basic Booking model for type safety
interface Booking {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  propertyName: string;
  unitName?: string;
  checkIn: admin.firestore.Timestamp;
  depositAmount: number;
  accessToken?: string;
  propertyId?: string;
}

// ==========================================
// CONFIGURATION
// ==========================================

const CONFIG = {
  // Schedule to run every day at 9:00 AM
  schedule: "0 9 * * *",
  timeZone: "Europe/Zagreb",
  retryCount: 3,
  // Process up to 500 reminders per run to prevent timeouts
  maxDocsPerRun: 500,
} as const;

// ==========================================
// SCHEDULED FUNCTION
// ==========================================

export const sendPaymentReminders = onSchedule({
  schedule: CONFIG.schedule,
  timeZone: CONFIG.timeZone,
  retryCount: CONFIG.retryCount,
}, async () => {
  const startTime = Date.now();
  logInfo("[PaymentReminders] Starting scheduled payment reminder check.", {
    config: CONFIG,
  });

  const now = admin.firestore.Timestamp.now();
  const tomorrow = admin.firestore.Timestamp.fromMillis(
    now.toMillis() + 24 * 60 * 60 * 1000
  );

  try {
    // Query for pending bank transfer bookings with a deadline in the next 24 hours
    // that have not yet received a reminder.
    const remindersQuery = db
      .collectionGroup("bookings")
      .where("status", "==", "pending_payment")
      .where("paymentMethod", "==", "bank_transfer")
      .where("payment_reminder_sent", "!=", true)
      .where("payment_deadline", ">", now)
      .where("payment_deadline", "<=", tomorrow)
      .limit(CONFIG.maxDocsPerRun);

    const snapshot = await remindersQuery.get();

    if (snapshot.empty) {
      logInfo("[PaymentReminders] No bookings found requiring a payment reminder.");
      return;
    }

    logInfo(`[PaymentReminders] Found ${snapshot.size} bookings needing a reminder.`);

    let successCount = 0;
    const failedIds: string[] = [];

    // Process each reminder
    for (const doc of snapshot.docs) {
      const booking = doc.data() as Booking;
      const bookingId = doc.id;

      try {
        // 1. Send the payment reminder email with all required parameters
        await sendPaymentReminderEmail(
          booking.guestEmail,
          booking.guestName,
          booking.bookingReference,
          booking.propertyName,
          booking.unitName,
          booking.checkIn.toDate(),
          booking.depositAmount,
          booking.accessToken,
          booking.propertyId,
        );

        // 2. Mark the reminder as sent to prevent duplicates
        await doc.ref.update({
          payment_reminder_sent: true,
        });

        logInfo(`[PaymentReminders] Reminder sent successfully for booking ${bookingId}`);
        successCount++;
      } catch (error) {
        logError(`[PaymentReminders] Failed to process reminder for booking ${bookingId}`, error);
        failedIds.push(bookingId);
      }
    }

    const duration = Date.now() - startTime;
    if (failedIds.length > 0) {
      logError("[PaymentReminders] Reminder job completed with some failures.", {
        totalFound: snapshot.size,
        successfulReminders: successCount,
        failedReminders: failedIds.length,
        failedIds: failedIds,
        durationMs: duration,
      });
    } else {
      logSuccess("[PaymentReminders] Reminder job completed successfully.", {
        totalFound: snapshot.size,
        successfulReminders: successCount,
        durationMs: duration,
      });
    }
  } catch (error) {
    const duration = Date.now() - startTime;
    logError("[PaymentReminders] Critical error during reminder job.", error, {
      durationMs: duration,
    });
    throw error; // Rethrow to trigger retry
  }
});
