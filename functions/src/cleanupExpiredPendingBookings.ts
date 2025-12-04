/**
 * Scheduled Cloud Function: Cleanup Expired Stripe Pending Bookings
 *
 * Runs periodically to delete expired `stripe_pending` placeholder bookings.
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
 * 3. Delete expired bookings in batches with error recovery
 * 4. Log deletion count for monitoring
 *
 * ERROR RECOVERY:
 * - Individual document failures don't block other deletions
 * - Failed deletions are logged and will be retried on next run
 * - Batch commits are isolated to prevent partial failure cascades
 */

import {onSchedule} from "firebase-functions/v2/scheduler";
import {db, admin} from "./firebase";
import {logError, logSuccess, logInfo, logWarn} from "./logger";

// ==========================================
// CONFIGURATION (Environment-based)
// ==========================================

/**
 * Cleanup job configuration
 *
 * These can be overridden via environment variables for different environments:
 * - Development: More frequent runs, smaller batches for testing
 * - Production: Standard intervals, full batch sizes
 */
const CONFIG = {
  /**
   * Cron schedule for cleanup job
   * Default: Every 5 minutes
   * Override: CLEANUP_SCHEDULE env var
   */
  schedule: process.env.CLEANUP_SCHEDULE || "*/5 * * * *",

  /**
   * Timezone for schedule
   * Default: Europe/Zagreb (Croatia)
   */
  timeZone: "Europe/Zagreb",

  /**
   * Number of retry attempts on failure
   * Default: 3
   * Override: CLEANUP_RETRY_COUNT env var
   */
  retryCount: parseInt(process.env.CLEANUP_RETRY_COUNT || "3", 10),

  /**
   * Maximum documents per batch (Firestore limit: 500)
   * Default: 400 (leaving headroom for safety)
   * Override: CLEANUP_BATCH_SIZE env var
   */
  batchSize: Math.min(
    parseInt(process.env.CLEANUP_BATCH_SIZE || "400", 10),
    500 // Firestore hard limit
  ),

  /**
   * Maximum total documents to process per run
   * Prevents runaway processing in case of data issues
   * Default: 2000
   * Override: CLEANUP_MAX_DOCS env var
   */
  maxDocsPerRun: parseInt(process.env.CLEANUP_MAX_DOCS || "2000", 10),
} as const;

// ==========================================
// CLEANUP FUNCTION
// ==========================================

/**
 * Cleanup expired stripe_pending bookings
 *
 * Uses batched deletes with error recovery to handle partial failures gracefully.
 */
export const cleanupExpiredStripePendingBookings = onSchedule({
  schedule: CONFIG.schedule,
  timeZone: CONFIG.timeZone,
  retryCount: CONFIG.retryCount,
}, async () => {
  const startTime = Date.now();
  logInfo("[Cleanup] Starting expired stripe_pending bookings cleanup", {
    config: {
      schedule: CONFIG.schedule,
      batchSize: CONFIG.batchSize,
      maxDocsPerRun: CONFIG.maxDocsPerRun,
    },
  });

  const now = admin.firestore.Timestamp.now();

  try {
    // Query all stripe_pending bookings that have expired
    // Limit query to prevent memory issues with large datasets
    const expiredBookingsQuery = db
      .collection("bookings")
      .where("status", "==", "stripe_pending")
      .where("stripe_pending_expires_at", "<", now)
      .limit(CONFIG.maxDocsPerRun);

    const expiredBookingsSnapshot = await expiredBookingsQuery.get();

    if (expiredBookingsSnapshot.empty) {
      logInfo("[Cleanup] No expired stripe_pending bookings found");
      return;
    }

    const totalToDelete = expiredBookingsSnapshot.size;
    logInfo(`[Cleanup] Found ${totalToDelete} expired stripe_pending bookings`);

    // Process deletions in batches with error recovery
    const results = await deleteInBatches(expiredBookingsSnapshot.docs);

    // Log results
    const duration = Date.now() - startTime;
    logSuccess("[Cleanup] Cleanup completed", {
      totalFound: totalToDelete,
      successfulDeletions: results.successCount,
      failedDeletions: results.failedCount,
      failedIds: results.failedIds,
      durationMs: duration,
    });

    // If some deletions failed, log warning but don't throw
    // (they'll be picked up on next run)
    if (results.failedCount > 0) {
      logError("[Cleanup] Some deletions failed - will retry on next run", null, {
        failedCount: results.failedCount,
        failedIds: results.failedIds,
      });
    }
  } catch (error) {
    const duration = Date.now() - startTime;
    logError("[Cleanup] Critical error during cleanup", error, {
      durationMs: duration,
    });
    throw error; // Rethrow to trigger retry
  }
});

// ==========================================
// BATCH DELETION HELPER
// ==========================================

interface BatchDeleteResult {
  successCount: number;
  failedCount: number;
  failedIds: string[];
}

/**
 * Delete documents in batches with error recovery
 *
 * KEY FIX: Creates a new batch after each commit to avoid the bug where
 * a committed batch can't accept new operations.
 *
 * @param docs - Array of document snapshots to delete
 * @returns Results with success/failure counts
 */
async function deleteInBatches(
  docs: FirebaseFirestore.QueryDocumentSnapshot[]
): Promise<BatchDeleteResult> {
  const results: BatchDeleteResult = {
    successCount: 0,
    failedCount: 0,
    failedIds: [],
  };

  // Process in chunks of batchSize
  for (let i = 0; i < docs.length; i += CONFIG.batchSize) {
    const chunk = docs.slice(i, i + CONFIG.batchSize);

    // Create NEW batch for each chunk (fixes the batch reuse bug)
    const batch = db.batch();

    // Add all deletes to batch
    for (const doc of chunk) {
      const bookingData = doc.data();
      logInfo(`[Cleanup] Queuing deletion: ${doc.id} (ref: ${bookingData.booking_reference})`);
      batch.delete(doc.ref);
    }

    // Commit batch with error handling
    try {
      await batch.commit();
      results.successCount += chunk.length;
      logInfo(`[Cleanup] Batch committed: ${chunk.length} deletions (total: ${results.successCount})`);
    } catch (batchError) {
      // Batch failed - fall back to individual deletes
      logWarn(`[Cleanup] Batch commit failed, trying individual deletes`, {
        error: batchError instanceof Error ? batchError.message : String(batchError),
      });

      for (const doc of chunk) {
        try {
          await doc.ref.delete();
          results.successCount++;
        } catch (docError) {
          results.failedCount++;
          results.failedIds.push(doc.id);
          logError(`[Cleanup] Failed to delete document ${doc.id}`, docError, {
            bookingId: doc.id,
            bookingReference: doc.data().booking_reference,
          });
        }
      }
    }
  }

  return results;
}
