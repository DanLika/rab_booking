/**
 * Scheduled Cloud Function: Cleanup Expired Stripe Pending Bookings
 *
 * Runs periodically to delete expired placeholder bookings from abandoned Stripe checkout.
 *
 * WHY THIS IS NEEDED:
 * - When user initiates Stripe checkout, we create placeholder booking with `pending` status
 * - Placeholder BLOCKS dates for 15 minutes (prevents race condition)
 * - If user abandons payment (closes Stripe tab), placeholder expires
 * - This cleanup job deletes expired placeholders to free up dates
 *
 * FLOW:
 * 1. Query all bookings with status = `pending` AND `stripe_pending_expires_at` field exists
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
import {
  sendBookingCancellationEmail,
} from "./emailService";
import {sendEmailWithRetry} from "./utils/emailRetry";
import {
  fetchPropertyAndUnitDetails,
} from "./utils/bookingHelpers";
import {safeToDate} from "./utils/dateValidation";

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
   * Schedule for 7-day expiration (Daily)
   */
  dailySchedule: "every 24 hours",

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

  /**
   * Maximum total documents for daily cleanup (larger limit)
   */
  maxDocsPerDailyRun: 5000,
} as const;

// ==========================================
// EMAIL ERROR TRACKING
// ==========================================

/**
 * Track email sending failure for monitoring/alerting
 *
 * Logs to Cloud Logging for:
 * - Monitoring via Cloud Monitoring dashboards
 * - Alerting via Log-based metrics
 * - Querying via Logs Explorer
 *
 * @param bookingId - Booking ID
 * @param emailType - Type of email that failed
 * @param recipient - Email recipient
 * @param error - Error that occurred
 */
function trackEmailFailure(
  bookingId: string,
  emailType: string,
  recipient: string,
  error: unknown
): void {
  // Log to Cloud Logging with structured data for monitoring/alerting
  // Can create Log-based metrics in GCP Console to trigger alerts
  logWarn("[EmailFailure] Failed to send email", {
    bookingId,
    emailType,
    recipient,
    errorMessage: error instanceof Error ? error.message : String(error),
    errorStack: error instanceof Error ? error.stack : undefined,
    // Structured labels for Cloud Monitoring queries
    severity: "WARNING",
    component: "email",
    action: "send_failure",
  });
}

// ==========================================
// CLEANUP FUNCTIONS
// ==========================================

/**
 * Cleanup expired Stripe pending bookings (placeholders from abandoned checkout)
 *
 * Uses batched deletes with error recovery to handle partial failures gracefully.
 */
export const cleanupExpiredStripePendingBookings = onSchedule({
  schedule: CONFIG.schedule,
  timeZone: CONFIG.timeZone,
  retryCount: CONFIG.retryCount,
}, async () => {
  const startTime = Date.now();
  logInfo("[Cleanup] Starting expired Stripe pending bookings cleanup", {
    config: {
      schedule: CONFIG.schedule,
      batchSize: CONFIG.batchSize,
      maxDocsPerRun: CONFIG.maxDocsPerRun,
    },
  });

  const now = admin.firestore.Timestamp.now();

  try {
    // Query all pending bookings with stripe_pending_expires_at field that have expired
    // This identifies Stripe checkout placeholders (not regular pending bookings)
    // Limit query to prevent memory issues with large datasets
    // NEW STRUCTURE: Use collection group query to find expired bookings across all units
    const expiredBookingsQuery = db
      .collectionGroup("bookings")
      .where("status", "==", "pending")
      .where("stripe_pending_expires_at", "<", now)
      .limit(CONFIG.maxDocsPerRun);

    const expiredBookingsSnapshot = await expiredBookingsQuery.get();

    if (expiredBookingsSnapshot.empty) {
      logInfo("[Cleanup] No expired Stripe pending bookings found");
      return;
    }

    const totalToDelete = expiredBookingsSnapshot.size;
    logInfo(`[Cleanup] Found ${totalToDelete} expired Stripe pending bookings`);

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

/**
 * Cloud Function: Auto-cancel expired pending bookings (7-day payment deadline)
 *
 * Runs daily to check for bookings that exceeded payment deadline.
 * Replaces `autoCancelExpiredBookings` in bookingManagement.ts
 *
 * IMPROVEMENTS:
 * - Batch processing (400 docs/batch)
 * - Query limits (5000 docs)
 * - Error recovery
 */
export const cleanupExpiredPendingBookings = onSchedule(
  {
    schedule: CONFIG.dailySchedule,
    timeZone: CONFIG.timeZone,
    retryCount: CONFIG.retryCount,
    secrets: ["RESEND_API_KEY"],
  },
  async () => {
    const startTime = Date.now();
    logInfo("[Cleanup] Starting expired pending bookings cleanup (7-day)", {
      config: {
        schedule: CONFIG.dailySchedule,
        batchSize: CONFIG.batchSize,
        maxDocsPerRun: CONFIG.maxDocsPerDailyRun,
      },
    });

    const now = admin.firestore.Timestamp.now();

    try {
      // Only cancel PENDING bookings (awaiting owner approval or payment)
      // Confirmed bookings are NOT auto-cancelled - owner confirmation = payment received
      // This is intentional: bank_transfer and pay_on_arrival always require owner approval,
      // so they stay pending until owner confirms (which means payment was received)
      const expiredBookingsQuery = db
        .collectionGroup("bookings")
        .where("status", "==", "pending")
        .where("payment_deadline", "<", now)
        .limit(CONFIG.maxDocsPerDailyRun);

      const expiredBookingsSnapshot = await expiredBookingsQuery.get();

      if (expiredBookingsSnapshot.empty) {
        logInfo("[Cleanup] No expired pending bookings found");
        return;
      }

      const totalToCancel = expiredBookingsSnapshot.size;
      logInfo(`[Cleanup] Found ${totalToCancel} expired pending bookings`);

      // Filter out external bookings just in case (though they shouldn't be pending with payment_deadline)
      const validDocs = expiredBookingsSnapshot.docs.filter((doc) => {
        const data = doc.data();
        if (data.source && ["booking_com", "airbnb", "ical", "external"].includes(data.source.toLowerCase())) {
          return false;
        }
        if (doc.id.startsWith("ical_")) {
          return false;
        }
        return true;
      });

      if (validDocs.length < totalToCancel) {
        logInfo(`[Cleanup] Filtered out ${totalToCancel - validDocs.length} external/invalid bookings`);
      }

      // Process cancellations in batches
      const results = await cancelInBatches(validDocs);

      // Log results
      const duration = Date.now() - startTime;
      logSuccess("[Cleanup] Expired pending bookings cleanup completed", {
        totalFound: totalToCancel,
        processed: validDocs.length,
        successful: results.successCount,
        failed: results.failedCount,
        failedIds: results.failedIds,
        durationMs: duration,
      });

      // If some failed, log warning
      if (results.failedCount > 0) {
        logError("[Cleanup] Some cancellations failed - will retry on next run", null, {
          failedCount: results.failedCount,
          failedIds: results.failedIds,
        });
      }
    } catch (error) {
      const duration = Date.now() - startTime;
      logError("[Cleanup] Critical error during cleanup", error, {
        durationMs: duration,
      });
      throw error;
    }
  }
);

// ==========================================
// BATCH HELPERS
// ==========================================

interface BatchResult {
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
 * @return Results with success/failure counts
 */
async function deleteInBatches(
  docs: FirebaseFirestore.QueryDocumentSnapshot[]
): Promise<BatchResult> {
  const results: BatchResult = {
    successCount: 0,
    failedCount: 0,
    failedIds: [],
  };

  // Process in chunks of batchSize
  for (let i = 0; i < docs.length; i += CONFIG.batchSize) {
    const chunk = docs.slice(i, i + CONFIG.batchSize);

    // Create NEW batch for each chunk (fixes the batch reuse bug)
    const batch = db.batch();

    // Add all deletes to batch (no per-document logging to reduce log volume)
    for (const doc of chunk) {
      batch.delete(doc.ref);
    }

    // Log batch processing (concise - one log per batch instead of per document)
    logInfo(`[Cleanup] Processing batch: ${chunk.length} documents`);

    // Commit batch with error handling
    try {
      await batch.commit();
      results.successCount += chunk.length;
      logInfo(`[Cleanup] Batch committed successfully (total: ${results.successCount})`);
    } catch (batchError) {
      // Batch failed - fall back to individual deletes
      logWarn("[Cleanup] Batch commit failed, trying individual deletes", {
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

/**
 * Cancel bookings in batches with error recovery
 */
async function cancelInBatches(
  docs: FirebaseFirestore.QueryDocumentSnapshot[]
): Promise<BatchResult> {
  const results: BatchResult = {
    successCount: 0,
    failedCount: 0,
    failedIds: [],
  };

  const now = admin.firestore.Timestamp.now();

  // Process in chunks of batchSize
  for (let i = 0; i < docs.length; i += CONFIG.batchSize) {
    const chunk = docs.slice(i, i + CONFIG.batchSize);

    // Create NEW batch for each chunk
    const batch = db.batch();

    // Add updates to batch
    for (const doc of chunk) {
      batch.update(doc.ref, {
        status: "cancelled",
        cancellation_reason: "Payment not received within deadline",
        cancelled_at: now,
        updated_at: now,
      });
    }

    logInfo(`[Cleanup] Processing cancellation batch: ${chunk.length} documents`);

    try {
      await batch.commit();
      results.successCount += chunk.length;
      logInfo(`[Cleanup] Batch committed successfully (total: ${results.successCount})`);

      // Send emails individually (batch commit succeeded)
      // We do this AFTER commit to ensure we don't email if update fails
      // Note: This makes email sending non-atomic with DB update, but that's acceptable for notifications
      await Promise.all(chunk.map(async (doc) => {
        try {
          const booking = doc.data();
          if (booking.guest_email) {
            // Fetch property and unit names
            const {propertyName, unitName} = await fetchPropertyAndUnitDetails(
              booking.property_id,
              booking.unit_id,
              "cleanupExpiredPending"
            );

            await sendEmailWithRetry(
              async () => {
                await sendBookingCancellationEmail(
                  booking.guest_email,
                  booking.guest_name || "Guest",
                  booking.booking_reference,
                  propertyName,
                  unitName,
                  safeToDate(booking.check_in, "check_in"),
                  safeToDate(booking.check_out, "check_out"),
                  undefined,
                  booking.property_id,
                  "Payment not received within deadline",
                  true
                );
              },
              "Auto-Cancel Notification",
              booking.guest_email
            );
          }
        } catch (emailError) {
          logError("Failed to send cancellation email", emailError, {bookingId: doc.id});
          trackEmailFailure(doc.id, "auto_cancel_notification", doc.data().guest_email, emailError);
        }
      }));

    } catch (batchError) {
      logWarn("[Cleanup] Batch commit failed, trying individual cancellations", {
        error: batchError instanceof Error ? batchError.message : String(batchError),
      });

      // Fallback to individual processing
      for (const doc of chunk) {
        try {
          await doc.ref.update({
            status: "cancelled",
            cancellation_reason: "Payment not received within deadline",
            cancelled_at: now,
            updated_at: now,
          });

          // Send email
          const booking = doc.data();
          if (booking.guest_email) {
            try {
              const {propertyName, unitName} = await fetchPropertyAndUnitDetails(
                booking.property_id,
                booking.unit_id,
                "cleanupExpiredPending"
              );
              await sendEmailWithRetry(
                async () => {
                  await sendBookingCancellationEmail(
                    booking.guest_email,
                    booking.guest_name || "Guest",
                    booking.booking_reference,
                    propertyName,
                    unitName,
                    safeToDate(booking.check_in, "check_in"),
                    safeToDate(booking.check_out, "check_out"),
                    undefined,
                    booking.property_id,
                    "Payment not received within deadline",
                    true
                  );
                },
                "Auto-Cancel Notification",
                booking.guest_email
              );
            } catch (e) {
              logError("Failed to send email during fallback", e);
            }
          }

          results.successCount++;
        } catch (docError) {
          results.failedCount++;
          results.failedIds.push(doc.id);
          logError(`[Cleanup] Failed to cancel booking ${doc.id}`, docError);
        }
      }
    }
  }

  return results;
}
