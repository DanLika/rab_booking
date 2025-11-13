import {onSchedule} from "firebase-functions/v2/scheduler";
import {admin, db} from "./firebase";
import {logInfo, logError, logSuccess} from "./logger";

/**
 * Cleanup Abandoned Stripe Bookings
 *
 * This scheduled function runs every 30 minutes to cleanup abandoned Stripe checkout sessions.
 *
 * Problem:
 * - User starts booking process, booking created with paymentStatus: 'pending'
 * - User is redirected to Stripe checkout
 * - User closes browser or abandons checkout
 * - Booking remains in 'pending' status indefinitely, blocking availability
 *
 * Solution:
 * - Automatically cancel bookings with:
 *   - paymentMethod: 'stripe'
 *   - paymentStatus: 'pending'
 *   - createdAt: > 30 minutes ago
 *
 * Schedule: Runs every 30 minutes
 */
export const cleanupAbandonedStripeBookings = onSchedule(
  {
    schedule: "*/30 * * * *", // Every 30 minutes
    timeZone: "Europe/Zagreb",
    memory: "256MiB",
  },
  async (event) => {
    logInfo("[Cleanup] Starting cleanup of abandoned Stripe bookings...");

    try {
      // Calculate cutoff time (30 minutes ago)
      const cutoffTime = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 30 * 60 * 1000) // 30 minutes in milliseconds
      );

      // Query for abandoned Stripe bookings
      // Criteria:
      // 1. paymentMethod = 'stripe'
      // 2. paymentStatus = 'pending'
      // 3. createdAt < cutoffTime (older than 30 minutes)
      const abandonedBookingsQuery = await db
        .collection("bookings")
        .where("payment_method", "==", "stripe")
        .where("payment_status", "==", "pending")
        .where("created_at", "<", cutoffTime)
        .get();

      if (abandonedBookingsQuery.empty) {
        logInfo("[Cleanup] No abandoned bookings found.");
        return;
      }

      logInfo(
        `[Cleanup] Found ${abandonedBookingsQuery.size} abandoned booking(s) to cancel.`
      );

      // Cancel each abandoned booking
      const batch = db.batch();
      const cancelledBookings: string[] = [];

      abandonedBookingsQuery.forEach((doc) => {
        const bookingData = doc.data();
        const bookingId = doc.id;

        logInfo(`[Cleanup] Cancelling booking: ${bookingId}`);
        logInfo(`   Guest: ${bookingData.guest_name || "Unknown"}`);
        logInfo(`   Email: ${bookingData.guest_email || "Unknown"}`);
        logInfo(
          `   Created: ${bookingData.created_at?.toDate()?.toISOString() || "Unknown"}`
        );

        // Update booking status to 'cancelled'
        batch.update(doc.ref, {
          status: "cancelled",
          payment_status: "abandoned",
          cancelled_at: admin.firestore.FieldValue.serverTimestamp(),
          cancellation_reason: "Abandoned Stripe checkout after 30 minutes",
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        cancelledBookings.push(bookingId);
      });

      // Commit batch update
      await batch.commit();

      logSuccess(
        `[Cleanup] Successfully cancelled ${cancelledBookings.length} abandoned booking(s).`
      );
      logInfo(`[Cleanup] Cancelled booking IDs: ${cancelledBookings.join(", ")}`);
    } catch (error: unknown) {
      logError(`[Cleanup] Error cleaning up abandoned bookings: ${error}`);
      // Don't throw - we don't want to fail the scheduled function
      // Just log the error and continue
    }
  }
);

/**
 * Manual Cleanup Function (for testing/debugging)
 *
 * This callable function allows manual triggering of the cleanup process.
 * Useful for:
 * - Testing the cleanup logic
 * - Manual cleanup when needed
 * - Owner dashboard "Cleanup" button
 */
import {onCall, HttpsError} from "firebase-functions/v2/https";

export const manualCleanupAbandonedBookings = onCall(
  {
    memory: "256MiB",
  },
  async (request) => {
    // Only allow authenticated users (ideally owners/admins)
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be authenticated to trigger manual cleanup."
      );
    }

    logInfo(`[Cleanup] Manual cleanup triggered by user: ${request.auth.uid}`);

    try {
      // Calculate cutoff time (30 minutes ago or custom time from request)
      const customMinutes = request.data?.minutes || 30;
      const cutoffTime = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - customMinutes * 60 * 1000)
      );

      logInfo(`[Cleanup] Using cutoff time: ${customMinutes} minutes ago`);

      // Query for abandoned Stripe bookings
      const abandonedBookingsQuery = await db
        .collection("bookings")
        .where("payment_method", "==", "stripe")
        .where("payment_status", "==", "pending")
        .where("created_at", "<", cutoffTime)
        .get();

      if (abandonedBookingsQuery.empty) {
        logInfo("[Cleanup] No abandoned bookings found.");
        return {success: true, cancelledCount: 0, message: "No abandoned bookings found."};
      }

      logInfo(
        `[Cleanup] Found ${abandonedBookingsQuery.size} abandoned booking(s) to cancel.`
      );

      // Cancel each abandoned booking
      const batch = db.batch();
      const cancelledBookings: Array<{id: string; guestName: string; guestEmail: string}> = [];

      abandonedBookingsQuery.forEach((doc) => {
        const bookingData = doc.data();
        const bookingId = doc.id;

        // Update booking status to 'cancelled'
        batch.update(doc.ref, {
          status: "cancelled",
          payment_status: "abandoned",
          cancelled_at: admin.firestore.FieldValue.serverTimestamp(),
          cancellation_reason: `Manual cleanup: Abandoned Stripe checkout after ${customMinutes} minutes`,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        cancelledBookings.push({
          id: bookingId,
          guestName: bookingData.guest_name || "Unknown",
          guestEmail: bookingData.guest_email || "Unknown",
        });
      });

      // Commit batch update
      await batch.commit();

      logSuccess(
        `[Cleanup] Successfully cancelled ${cancelledBookings.length} abandoned booking(s).`
      );

      return {
        success: true,
        cancelledCount: cancelledBookings.length,
        cancelledBookings,
        message: `Successfully cancelled ${cancelledBookings.length} abandoned booking(s).`,
      };
    } catch (error: unknown) {
      logError(`[Cleanup] Error in manual cleanup: ${error}`);
      throw new HttpsError(
        "internal",
        `Failed to cleanup abandoned bookings: ${error}`
      );
    }
  }
);
