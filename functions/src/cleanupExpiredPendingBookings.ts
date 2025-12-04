/**
 * Scheduled Cloud Function: Cleanup Expired Stripe Pending Bookings
 *
 * Runs every 5 minutes to delete expired `stripe_pending` placeholder bookings.
 *
 * WHY THIS IS NEEDED:
 * - When user initiates Stripe checkout, we create placeholder booking with `stripe_pending` status
 * - Placeholder BLOCKS dates for 15 minutes (prevents race condition)
 * - If user abandons payment (closes Stripe tab), placeholder expires
 * - This cleanup job deletes expired placeholders to free up dates
 *
 * FLOW:
 * 1. Query all bookings with status = `stripe_pending`
 * 2. Filter where `stripe_pending_expires_at` < now
 * 3. Delete expired bookings in batch
 * 4. Log deletion count for monitoring
 */

import {onSchedule} from "firebase-functions/v2/scheduler";
import {db} from "./firebase";
import {admin} from "./firebase";

/**
 * Cleanup expired stripe_pending bookings (runs every 5 minutes)
 */
export const cleanupExpiredStripePendingBookings = onSchedule({
  schedule: "*/5 * * * *", // Every 5 minutes (cron format)
  timeZone: "Europe/Zagreb", // Croatia timezone
  retryCount: 3, // Retry up to 3 times on failure
}, async () => {
  console.log("[Cleanup] Starting expired stripe_pending bookings cleanup");

  const now = admin.firestore.Timestamp.now();

  try {
    // Query all stripe_pending bookings that have expired
    const expiredBookingsQuery = db
      .collection("bookings")
      .where("status", "==", "stripe_pending")
      .where("stripe_pending_expires_at", "<", now);

    const expiredBookingsSnapshot = await expiredBookingsQuery.get();

    if (expiredBookingsSnapshot.empty) {
      console.log("[Cleanup] No expired stripe_pending bookings found");
      return;
    }

    console.log(
      `[Cleanup] Found ${expiredBookingsSnapshot.size} expired stripe_pending bookings`
    );

    // Delete expired bookings in batch (max 500 per batch)
    const batch = db.batch();
    let deletionCount = 0;

    for (const doc of expiredBookingsSnapshot.docs) {
      const bookingData = doc.data();
      console.log(`[Cleanup] Deleting expired booking: ${doc.id} (${bookingData.booking_reference})`);
      batch.delete(doc.ref);
      deletionCount++;

      // Firestore batch limit is 500 operations
      if (deletionCount >= 500) {
        await batch.commit();
        console.log(`[Cleanup] Committed batch of ${deletionCount} deletions`);
        deletionCount = 0;
      }
    }

    // Commit remaining deletions
    if (deletionCount > 0) {
      await batch.commit();
      console.log(`[Cleanup] Committed final batch of ${deletionCount} deletions`);
    }

    console.log(
      `[Cleanup] Successfully deleted ${expiredBookingsSnapshot.size} expired stripe_pending bookings`
    );
  } catch (error) {
    console.error("[Cleanup] Error cleaning up expired bookings:", error);
    throw error; // Rethrow to trigger retry
  }
});
