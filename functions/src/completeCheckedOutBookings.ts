/**
 * Scheduled Cloud Function: Auto-Complete Checked-Out Bookings
 *
 * Runs daily to update booking status from `confirmed` or `pending` to `completed`
 * after the checkout date has passed.
 *
 * WHY THIS IS NEEDED:
 * - Bookings remain in `confirmed` or `pending` status even after guests check out
 * - Owners need accurate historical data (completed bookings)
 * - Manual status updates are error-prone and time-consuming
 * - Automatic completion keeps booking records accurate and up-to-date
 *
 * FLOW:
 * 1. Query all bookings with status IN (`confirmed`, `pending`)
 * 2. Filter where `check_out` date < today (UTC)
 * 3. Update matching bookings to `completed` status in batches
 * 4. Log update count for monitoring
 *
 * ERROR RECOVERY:
 * - Individual document failures don't block other updates
 * - Failed updates are logged and will be retried on next run
 * - Batch commits are isolated to prevent partial failure cascades
 *
 * IMPORTANT:
 * - Only updates bookings where checkout date has PASSED
 * - Does NOT update cancelled bookings (they stay cancelled)
 * - Does NOT update external/iCal bookings (marked read-only)
 */

import {onSchedule} from "firebase-functions/v2/scheduler";
import {db, admin} from "./firebase";
import {logError, logSuccess, logInfo, logWarn} from "./logger";

// ==========================================
// CONFIGURATION
// ==========================================

/**
 * Auto-complete job configuration
 */
const CONFIG = {
  /**
   * Cron schedule for auto-complete job
   * Default: Every day at 2:00 AM (Zagreb time)
   * Override: AUTOCOMPLETE_SCHEDULE env var
   */
  schedule: process.env.AUTOCOMPLETE_SCHEDULE || "0 2 * * *",

  /**
   * Timezone for schedule
   * Default: Europe/Zagreb (Croatia)
   */
  timeZone: "Europe/Zagreb",

  /**
   * Number of retry attempts on failure
   * Default: 3
   */
  retryCount: parseInt(process.env.AUTOCOMPLETE_RETRY_COUNT || "3", 10),

  /**
   * Maximum documents per batch (Firestore limit: 500)
   * Default: 400 (leaving headroom for safety)
   */
  batchSize: Math.min(
    parseInt(process.env.AUTOCOMPLETE_BATCH_SIZE || "400", 10),
    500 // Firestore hard limit
  ),

  /**
   * Maximum total documents to process per run
   * Prevents runaway processing in case of data issues
   * Default: 5000 (typical property has < 1000 bookings/year)
   */
  maxDocsPerRun: parseInt(process.env.AUTOCOMPLETE_MAX_DOCS || "5000", 10),
} as const;

// ==========================================
// AUTO-COMPLETE FUNCTION
// ==========================================

/**
 * Auto-complete bookings where checkout date has passed
 *
 * Uses batched updates with error recovery to handle partial failures gracefully.
 */
export const autoCompleteCheckedOutBookings = onSchedule({
  schedule: CONFIG.schedule,
  timeZone: CONFIG.timeZone,
  retryCount: CONFIG.retryCount,
}, async () => {
  const startTime = Date.now();
  logInfo("[AutoComplete] Starting auto-complete for checked-out bookings", {
    config: {
      schedule: CONFIG.schedule,
      batchSize: CONFIG.batchSize,
      maxDocsPerRun: CONFIG.maxDocsPerRun,
    },
  });

  // Get today's date at midnight UTC (for consistent date comparison)
  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);
  const todayTimestamp = admin.firestore.Timestamp.fromDate(today);

  try {
    // Query all confirmed/pending bookings where checkout date < today
    // Use collection group query to find across all units
    // Excludes cancelled and already completed bookings
    const checkedOutBookingsQuery = db
      .collectionGroup("bookings")
      .where("status", "in", ["confirmed", "pending"])
      .where("check_out", "<", todayTimestamp)
      .limit(CONFIG.maxDocsPerRun);

    const checkedOutBookingsSnapshot = await checkedOutBookingsQuery.get();

    if (checkedOutBookingsSnapshot.empty) {
      logInfo("[AutoComplete] No checked-out bookings found to complete");
      return;
    }

    const totalToUpdate = checkedOutBookingsSnapshot.size;
    logInfo(`[AutoComplete] Found ${totalToUpdate} checked-out bookings to complete`);

    // Filter out external/iCal bookings (read-only)
    const bookingsToUpdate = checkedOutBookingsSnapshot.docs.filter((doc) => {
      const data = doc.data();
      // Skip external bookings (they shouldn't be auto-updated)
      if (data.source && ["booking_com", "airbnb", "ical", "external"].includes(data.source.toLowerCase())) {
        logInfo(`[AutoComplete] Skipping external booking: ${doc.id} (source: ${data.source})`);
        return false;
      }
      // Skip bookings with ID prefix 'ical_' (imported bookings)
      if (doc.id.startsWith("ical_")) {
        logInfo(`[AutoComplete] Skipping iCal imported booking: ${doc.id}`);
        return false;
      }
      return true;
    });

    if (bookingsToUpdate.length === 0) {
      logInfo("[AutoComplete] All checked-out bookings are external/iCal imports - skipping");
      return;
    }

    logInfo(`[AutoComplete] After filtering external bookings: ${bookingsToUpdate.length} to update`);

    // Process updates in batches with error recovery
    const results = await updateInBatches(bookingsToUpdate);

    // Log results
    const duration = Date.now() - startTime;
    logSuccess("[AutoComplete] Auto-complete job finished", {
      totalFound: totalToUpdate,
      filteredOut: totalToUpdate - bookingsToUpdate.length,
      successfulUpdates: results.successCount,
      failedUpdates: results.failedCount,
      failedIds: results.failedIds,
      durationMs: duration,
    });

    // If some updates failed, log warning but don't throw
    // (they'll be picked up on next run)
    if (results.failedCount > 0) {
      logError("[AutoComplete] Some updates failed - will retry on next run", null, {
        failedCount: results.failedCount,
        failedIds: results.failedIds,
      });
    }
  } catch (error) {
    const duration = Date.now() - startTime;
    logError("[AutoComplete] Critical error during auto-complete", error, {
      durationMs: duration,
    });
    throw error; // Rethrow to trigger retry
  }
});

// ==========================================
// BATCH UPDATE HELPER
// ==========================================

interface BatchUpdateResult {
  successCount: number;
  failedCount: number;
  failedIds: string[];
}

/**
 * Update documents in batches with error recovery
 *
 * Creates a new batch after each commit to avoid the bug where
 * a committed batch can't accept new operations.
 *
 * @param docs - Array of document snapshots to update
 * @returns Results with success/failure counts
 */
async function updateInBatches(
  docs: FirebaseFirestore.QueryDocumentSnapshot[]
): Promise<BatchUpdateResult> {
  const results: BatchUpdateResult = {
    successCount: 0,
    failedCount: 0,
    failedIds: [],
  };

  const now = admin.firestore.Timestamp.now();

  // Process in chunks of batchSize
  for (let i = 0; i < docs.length; i += CONFIG.batchSize) {
    const chunk = docs.slice(i, i + CONFIG.batchSize);

    // Create NEW batch for each chunk (fixes the batch reuse bug)
    const batch = db.batch();

    // Add all updates to batch
    for (const doc of chunk) {
      batch.update(doc.ref, {
        status: "completed",
        updated_at: now,
      });
    }

    // Log batch processing (concise - one log per batch instead of per document)
    logInfo(`[AutoComplete] Processing batch: ${chunk.length} documents`);

    // Commit batch with error handling
    try {
      await batch.commit();
      results.successCount += chunk.length;
      logInfo(`[AutoComplete] Batch committed successfully (total: ${results.successCount})`);
    } catch (batchError) {
      // Batch failed - fall back to individual updates
      logWarn(`[AutoComplete] Batch commit failed, trying individual updates`, {
        error: batchError instanceof Error ? batchError.message : String(batchError),
      });

      for (const doc of chunk) {
        try {
          await doc.ref.update({
            status: "completed",
            updated_at: now,
          });
          results.successCount++;
        } catch (docError) {
          results.failedCount++;
          results.failedIds.push(doc.id);
          logError(`[AutoComplete] Failed to update booking ${doc.id}`, docError, {
            bookingId: doc.id,
            bookingReference: doc.data().booking_reference,
          });
        }
      }
    }
  }

  return results;
}
