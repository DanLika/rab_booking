/**
 * Scheduled Cloud Function: Cancel Expired Bank Transfer Bookings
 *
 * Runs daily to automatically cancel bank transfer bookings that have passed
 * their payment deadline without receiving payment.
 *
 * This keeps the calendar accurate and frees up availability.
 *
 * FLOW:
 * 1. Scheduled to run once per day (e.g., at 1 AM).
 * 2. Queries all bookings with:
 *    - status: 'pending_payment'
 *    - paymentMethod: 'bank_transfer'
 *    - payment_deadline: in the past
 * 3. For each expired booking, it updates the status to 'cancelled'.
 * 4. Sends a cancellation notification email to the guest and the owner.
 * 5. Logs the number of cancellations and any failures.
 */

import {onSchedule} from "firebase-functions/v2/scheduler";
import {db, admin} from "./firebase";
import {logError, logSuccess, logInfo} from "./logger";
import {sendGuestCancellationEmail, sendOwnerCancellationNotificationEmail} from "./emailService";

// Basic Booking model for type safety
interface Booking {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  propertyName: string;
  unitName?: string;
  checkIn: admin.firestore.Timestamp;
  checkOut: admin.firestore.Timestamp;
  totalAmount: number;
  ownerId: string;
}

// ==========================================
// CONFIGURATION
// ==========================================

const CONFIG = {
  // Schedule to run every day at 1:00 AM
  schedule: "0 1 * * *",
  timeZone: "Europe/Zagreb",
  retryCount: 3,
  // Process up to 500 cancellations per run
  maxDocsPerRun: 500,
} as const;

// ==========================================
// SCHEDULED FUNCTION
// ==========================================

export const cancelExpiredBankBookings = onSchedule({
  schedule: CONFIG.schedule,
  timeZone: CONFIG.timeZone,
  retryCount: CONFIG.retryCount,
}, async () => {
  const startTime = Date.now();
  logInfo("[AutoCancel] Starting expired bank transfer booking cleanup.", {
    config: CONFIG,
  });

  const now = admin.firestore.Timestamp.now();

  try {
    // Query for expired pending bank transfer bookings
    const expiredBookingsQuery = db
      .collectionGroup("bookings")
      .where("status", "==", "pending_payment")
      .where("paymentMethod", "==", "bank_transfer")
      .where("payment_deadline", "<", now)
      .limit(CONFIG.maxDocsPerRun);

    const snapshot = await expiredBookingsQuery.get();

    if (snapshot.empty) {
      logInfo("[AutoCancel] No expired bank transfer bookings found.");
      return;
    }

    logInfo(`[AutoCancel] Found ${snapshot.size} expired bank transfer bookings to cancel.`);

    let successCount = 0;
    const failedIds: string[] = [];

    // Process each cancellation
    for (const doc of snapshot.docs) {
      const booking = doc.data() as Booking;
      const bookingId = doc.id;

      try {
        // 1. Update booking status to 'cancelled'
        await doc.ref.update({
          status: "cancelled",
          cancellation_reason: "Payment not received within deadline.",
        });

        // 2. Send cancellation email to guest
        await sendGuestCancellationEmail(
          booking.guestEmail,
          booking.guestName,
          booking.bookingReference,
          booking.propertyName,
          booking.unitName,
          booking.checkIn.toDate(),
          booking.checkOut.toDate(),
        );

        // 3. Send cancellation notification to owner
        // First, fetch the owner's email from the 'users' collection
        const ownerDoc = await db.collection("users").doc(booking.ownerId).get();
        const ownerEmail = ownerDoc.data()?.email;

        if (ownerEmail) {
          await sendOwnerCancellationNotificationEmail(
            ownerEmail,
            booking.bookingReference,
            booking.guestName,
            booking.guestEmail,
            booking.propertyName,
            booking.unitName,
            booking.checkIn.toDate(),
            booking.checkOut.toDate(),
            booking.totalAmount,
          );
        } else {
            logError(`[AutoCancel] Owner email not found for ownerId ${booking.ownerId}`);
        }

        logInfo(`[AutoCancel] Successfully cancelled booking ${bookingId}`);
        successCount++;
      } catch (error) {
        logError(`[AutoCancel] Failed to cancel booking ${bookingId}`, error);
        failedIds.push(bookingId);
      }
    }

    const duration = Date.now() - startTime;
    if (failedIds.length > 0) {
      logError("[AutoCancel] Job completed with some failures.", {
        totalFound: snapshot.size,
        successfulCancellations: successCount,
        failedCancellations: failedIds.length,
        failedIds: failedIds,
        durationMs: duration,
      });
    } else {
      logSuccess("[AutoCancel] Job completed successfully.", {
        totalFound: snapshot.size,
        successfulCancellations: successCount,
        durationMs: duration,
      });
    }
  } catch (error) {
    const duration = Date.now() - startTime;
    logError("[AutoCancel] Critical error during auto-cancellation job.", error, {
      durationMs: duration,
    });
    throw error; // Rethrow to trigger retry
  }
});
