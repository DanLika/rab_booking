import * as admin from "firebase-admin";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {logInfo, logError} from "./logger";

/**
 * Scheduled function to cleanup old daily_prices documents.
 *
 * Runs monthly (1st day at 2 AM UTC).
 * Deletes daily_prices documents where:
 * - date < (today - 365 days)
 *
 * This implicitly only affects past dates since cutoff is always in the past.
 *
 * IMPORTANT: The `date` field in daily_prices is a Firestore Timestamp,
 * NOT a string. We must use Timestamp for comparison.
 *
 * Safety features:
 * - Never deletes future dates
 * - Max 5000 docs per run (10 batches × 500 docs)
 * - Error recovery: continues with next batch if one fails
 * - Structured logging for monitoring
 */
export const cleanupPastDailyPrices = onSchedule(
  {
    schedule: "0 2 1 * *", // Monthly: 1st day at 2 AM UTC
    timeZone: "UTC",
    memory: "512MiB",
    timeoutSeconds: 540, // 9 minutes
  },
  async () => {
    const startTime = Date.now();
    const db = admin.firestore();

    // Calculate cutoff date (365 days ago) at midnight UTC
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);

    const cutoffDate = new Date(today);
    cutoffDate.setDate(cutoffDate.getDate() - 365);

    // Convert to Firestore Timestamp for comparison
    // IMPORTANT: daily_prices.date is stored as Timestamp, not string
    const cutoffTimestamp = admin.firestore.Timestamp.fromDate(cutoffDate);

    logInfo("DailyPrices Cleanup: Started", {
      todayDate: formatDate(today),
      cutoffDate: formatDate(cutoffDate),
      cutoffTimestamp: cutoffTimestamp.toDate().toISOString(),
      retentionDays: 365,
    });

    try {
      // Collection group query: all daily_prices across all units
      // Single range filter: date < cutoffTimestamp
      // Since cutoff = today - 365, this only matches past dates
      const query = db
        .collectionGroup("daily_prices")
        .where("date", "<", cutoffTimestamp)
        .limit(5000); // Safety limit

      const snapshot = await query.get();

      if (snapshot.empty) {
        logInfo("DailyPrices Cleanup: No documents to delete", {
          cutoffDate: formatDate(cutoffDate),
        });
        return;
      }

      // Batch delete
      const BATCH_SIZE = 500;
      const MAX_BATCHES = 10; // Safety: max 5000 docs per run

      let batch = db.batch();
      let batchCount = 0;
      let deletedCount = 0;
      let errorCount = 0;

      for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
        deletedCount++;

        // Commit batch when full
        if (deletedCount % BATCH_SIZE === 0) {
          try {
            await batch.commit();
            logInfo(`DailyPrices Cleanup: Batch ${batchCount + 1} committed`, {
              docsInBatch: BATCH_SIZE,
            });
            batch = db.batch();
            batchCount++;

            // Safety: stop after MAX_BATCHES
            if (batchCount >= MAX_BATCHES) {
              logInfo("DailyPrices Cleanup: Reached max batches limit", {
                maxBatches: MAX_BATCHES,
                totalDocsProcessed: deletedCount,
              });
              break;
            }
          } catch (error) {
            logError(
              "DailyPrices Cleanup: Batch commit failed",
              error as Error
            );
            errorCount++;
            batch = db.batch(); // Start fresh batch
          }
        }
      }

      // Commit remaining docs
      const remainingDocs = deletedCount % BATCH_SIZE;
      if (remainingDocs !== 0) {
        try {
          await batch.commit();
          logInfo("DailyPrices Cleanup: Final batch committed", {
            docsInBatch: remainingDocs,
          });
        } catch (error) {
          logError(
            "DailyPrices Cleanup: Final batch commit failed",
            error as Error
          );
          errorCount++;
        }
      }

      const duration = Date.now() - startTime;
      logInfo("DailyPrices Cleanup: Completed", {
        totalDocsFound: snapshot.size,
        deletedCount,
        batchCount: batchCount + (remainingDocs > 0 ? 1 : 0),
        errorCount,
        durationMs: duration,
      });
    } catch (error) {
      logError("DailyPrices Cleanup: Fatal error", error as Error);
      throw error; // Propagate to trigger Cloud Scheduler retry
    }
  }
);

/**
 * Format Date to "YYYY-MM-DD" string (matches Firestore daily_prices format)
 */
function formatDate(date: Date): string {
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, "0");
  const day = String(date.getUTCDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}
