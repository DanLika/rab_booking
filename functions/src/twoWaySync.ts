import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {admin, db} from "./firebase";
import {logInfo, logError, logSuccess, logWarn} from "./logger";
import {
  blockDatesOnBookingCom,
  unblockDatesOnBookingCom,
} from "./bookingComApi";
import {
  blockDatesOnAirbnb,
  unblockDatesOnAirbnb,
} from "./airbnbApi";

/**
 * Two-Way Sync Engine
 * 
 * Automatically syncs bookings between BookBed and external platforms
 * (Booking.com, Airbnb) to prevent overbooking.
 * 
 * Features:
 * - Automatic date blocking when booking is created
 * - Automatic date unblocking when booking is cancelled
 * - Retry logic for failed syncs
 * - Conflict resolution
 */

/**
 * Get all platform connections for a unit
 */
async function getPlatformConnections(unitId: string): Promise<any[]> {
  const snapshot = await db
    .collection("platform_connections")
    .where("unit_id", "==", unitId)
    .where("status", "==", "active")
    .get();

  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
}

/**
 * Convert booking dates to date ranges for blocking
 */
function getDateRanges(checkIn: Date, checkOut: Date): Array<{start: Date; end: Date}> {
  // Block from check-in to check-out (exclusive of check-out date)
  return [
    {
      start: new Date(checkIn.getFullYear(), checkIn.getMonth(), checkIn.getDate()),
      end: new Date(checkOut.getFullYear(), checkOut.getMonth(), checkOut.getDate()),
    },
  ];
}

/**
 * Sync booking to external platforms
 * Called when booking is created, updated, or cancelled
 */
export const syncBookingToPlatforms = onDocumentWritten(
  "bookings/{bookingId}",
  async (event) => {
    const afterData = event.data?.after?.data();

    // Skip if document was deleted
    if (!afterData) {
      logInfo("[Two-Way Sync] Booking deleted, skipping sync", {
        bookingId: event.params.bookingId,
      });
      return;
    }

    const bookingId = event.params.bookingId;
    const unitId = afterData.unit_id;
    const status = afterData.status;
    const checkIn = afterData.check_in?.toDate();
    const checkOut = afterData.check_out?.toDate();

    // Only sync confirmed and pending bookings
    if (status !== "confirmed" && status !== "pending") {
      // LONG-TERM CONSIDERATION: Unblocking dates on cancel is risky
      // - If booking was cancelled, dates become available on external platforms
      // - This could lead to double-booking if not handled carefully
      // - Consider requiring manual confirmation before unblocking
      // 
      // For now, we only unblock on completion (not cancellation) to be safer
      // Cancellation unblocking should be a manual action with warnings
      if (status === "completed") {
        // Only unblock on completion, not cancellation
        // Cancellation unblocking requires manual action (see platform connections UI)
        await unblockBookingDates(unitId, checkIn, checkOut, bookingId);
      }
      // NOTE: Cancelled bookings do NOT automatically unblock dates
      // This prevents accidental double-booking if cancellation was a mistake
      return;
    }

    // Skip if dates are missing
    if (!checkIn || !checkOut) {
      logWarn("[Two-Way Sync] Missing dates, skipping sync", {
        bookingId,
        unitId,
      });
      return;
    }

    try {
      logInfo("[Two-Way Sync] Syncing booking to platforms", {
        bookingId,
        unitId,
        status,
        checkIn: checkIn.toISOString(),
        checkOut: checkOut.toISOString(),
      });

      // Get all platform connections for this unit
      const connections = await getPlatformConnections(unitId);

      if (connections.length === 0) {
        logInfo("[Two-Way Sync] No platform connections found", {
          bookingId,
          unitId,
        });
        return;
      }

      // Get date ranges to block
      const dateRanges = getDateRanges(checkIn, checkOut);

      // Block dates on all connected platforms
      for (const connection of connections) {
        try {
          if (connection.platform === "booking_com") {
            await blockDatesOnBookingCom(
              connection.id,
              connection.external_property_id,
              connection.external_unit_id,
              dateRanges
            );
          } else if (connection.platform === "airbnb") {
            await blockDatesOnAirbnb(
              connection.id,
              connection.external_property_id,
              dateRanges
            );
          }

          // Update last sync time
          await db.collection("platform_connections").doc(connection.id).update({
            last_synced_at: admin.firestore.Timestamp.now(),
            updated_at: admin.firestore.Timestamp.now(),
          });

          logSuccess("[Two-Way Sync] Dates blocked on platform", {
            bookingId,
            platform: connection.platform,
            connectionId: connection.id,
          });
        } catch (error) {
          logError("[Two-Way Sync] Failed to sync to platform", error, {
            bookingId,
            platform: connection.platform,
            connectionId: connection.id,
          });

          // Record sync failure
          await recordSyncFailure(
            connection.owner_id,
            unitId,
            connection.platform,
            bookingId,
            error instanceof Error ? error.message : "Unknown error"
          );
        }
      }
    } catch (error) {
      logError("[Two-Way Sync] Error syncing booking", error, {
        bookingId,
        unitId,
      });
    }
  }
);

/**
 * Unblock booking dates on external platforms
 */
async function unblockBookingDates(
  unitId: string,
  checkIn: Date | undefined,
  checkOut: Date | undefined,
  bookingId: string
): Promise<void> {
  if (!checkIn || !checkOut) {
    return;
  }

  try {
    logInfo("[Two-Way Sync] Unblocking booking dates", {
      bookingId,
      unitId,
      checkIn: checkIn.toISOString(),
      checkOut: checkOut.toISOString(),
    });

    const connections = await getPlatformConnections(unitId);
    const dateRanges = getDateRanges(checkIn, checkOut);

    for (const connection of connections) {
      try {
        if (connection.platform === "booking_com") {
          await unblockDatesOnBookingCom(
            connection.id,
            connection.external_property_id,
            connection.external_unit_id,
            dateRanges
          );
        } else if (connection.platform === "airbnb") {
          await unblockDatesOnAirbnb(
            connection.id,
            connection.external_property_id,
            dateRanges
          );
        }

        logSuccess("[Two-Way Sync] Dates unblocked on platform", {
          bookingId,
          platform: connection.platform,
        });
      } catch (error) {
        logError("[Two-Way Sync] Failed to unblock dates", error, {
          bookingId,
          platform: connection.platform,
        });
      }
    }
  } catch (error) {
    logError("[Two-Way Sync] Error unblocking dates", error, {
      bookingId,
      unitId,
    });
  }
}

/**
 * Record sync failure for retry
 */
async function recordSyncFailure(
  ownerId: string,
  unitId: string,
  platform: string,
  bookingId: string,
  error: string
): Promise<void> {
  try {
    await db.collection("sync_failures").add({
      owner_id: ownerId,
      unit_id: unitId,
      platform,
      booking_id: bookingId,
      error,
      retry_count: 0,
      next_retry_at: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 60 * 1000) // Retry in 1 minute
      ),
      created_at: admin.firestore.Timestamp.now(),
      updated_at: admin.firestore.Timestamp.now(),
    });
  } catch (error) {
    logError("[Two-Way Sync] Failed to record sync failure", error);
  }
}

/**
 * Scheduled function to retry failed syncs
 * Runs every 5 minutes
 */
export const scheduledTwoWaySync = onSchedule(
  {
    schedule: "every 5 minutes",
    timeoutSeconds: 540,
    memory: "512MiB",
    region: "europe-west1",
  },
  async () => {
    try {
      logInfo("[Two-Way Sync] Starting scheduled retry of failed syncs");

      // Get all sync failures that are ready for retry
      const now = admin.firestore.Timestamp.now();
      const failuresSnapshot = await db
        .collection("sync_failures")
        .where("next_retry_at", "<=", now)
        .where("retry_count", "<", 5) // Max 5 retries
        .limit(50) // Process max 50 at a time
        .get();

      if (failuresSnapshot.empty) {
        logInfo("[Two-Way Sync] No failed syncs to retry");
        return;
      }

      logInfo("[Two-Way Sync] Retrying failed syncs", {
        count: failuresSnapshot.size,
      });

      let successCount = 0;
      let failureCount = 0;

      for (const failureDoc of failuresSnapshot.docs) {
        const failure = failureDoc.data();
        const failureId = failureDoc.id;

        try {
          // NEW STRUCTURE: Get booking data using collection group query
          const bookingQuery = await db
            .collectionGroup("bookings")
            .where(admin.firestore.FieldPath.documentId(), "==", failure.booking_id)
            .limit(1)
            .get();

          if (bookingQuery.empty) {
            // Booking no longer exists, delete failure record
            await failureDoc.ref.delete();
            continue;
          }

          const bookingDoc = bookingQuery.docs[0];
          const bookingData = bookingDoc.data()!;
          const checkIn = bookingData.check_in?.toDate();
          const checkOut = bookingData.check_out?.toDate();
          const status = bookingData.status;

          // Skip if booking is cancelled or completed
          if (status === "cancelled" || status === "completed") {
            await failureDoc.ref.delete();
            continue;
          }

          if (!checkIn || !checkOut) {
            await failureDoc.ref.delete();
            continue;
          }

          // Get connection
          const connectionSnapshot = await db
            .collection("platform_connections")
            .where("unit_id", "==", failure.unit_id)
            .where("platform", "==", failure.platform)
            .where("status", "==", "active")
            .limit(1)
            .get();

          if (connectionSnapshot.empty) {
            // Connection no longer exists, delete failure record
            await failureDoc.ref.delete();
            continue;
          }

          const connection = connectionSnapshot.docs[0];
          const connectionData = connection.data();
          const dateRanges = getDateRanges(checkIn, checkOut);

          // Retry blocking dates
          if (failure.platform === "booking_com") {
            await blockDatesOnBookingCom(
              connection.id,
              connectionData.external_property_id,
              connectionData.external_unit_id,
              dateRanges
            );
          } else if (failure.platform === "airbnb") {
            await blockDatesOnAirbnb(
              connection.id,
              connectionData.external_property_id,
              dateRanges
            );
          }

          // Success - delete failure record
          await failureDoc.ref.delete();
          successCount++;

          logSuccess("[Two-Way Sync] Retry successful", {
            failureId,
            bookingId: failure.booking_id,
          });
        } catch (error) {
          // Increment retry count
          const retryCount = (failure.retry_count || 0) + 1;
          const backoffMinutes = Math.min(Math.pow(2, retryCount), 60); // Exponential backoff, max 60 min
          const nextRetryAt = new Date(Date.now() + backoffMinutes * 60 * 1000);

          await failureDoc.ref.update({
            retry_count: retryCount,
            next_retry_at: admin.firestore.Timestamp.fromDate(nextRetryAt),
            updated_at: admin.firestore.Timestamp.now(),
            last_error: error instanceof Error ? error.message : "Unknown error",
          });

          failureCount++;

          logWarn("[Two-Way Sync] Retry failed", {
            failureId,
            retryCount,
            nextRetryAt: nextRetryAt.toISOString(),
          });

          // If max retries reached, notify owner
          if (retryCount >= 5) {
            await notifyOwnerOfSyncFailure(failure.owner_id, failure);
          }
        }
      }

      logSuccess("[Two-Way Sync] Scheduled retry completed", {
        successCount,
        failureCount,
        total: failuresSnapshot.size,
      });
    } catch (error) {
      logError("[Two-Way Sync] Error in scheduled retry", error);
    }
  }
);

/**
 * Notify owner of persistent sync failure
 */
async function notifyOwnerOfSyncFailure(ownerId: string, failure: any): Promise<void> {
  try {
    // Create notification in Firestore
    // NEW STRUCTURE: Write to users/{ownerId}/notifications subcollection
    await db
      .collection("users")
      .doc(ownerId)
      .collection("notifications")
      .add({
        ownerId,
        type: "sync_failure",
        title: "Sync Failure - Manual Action Required",
        message: `Failed to sync booking to ${failure.platform} after multiple retries. Please block dates manually.`,
        metadata: {
          platform: failure.platform,
          bookingId: failure.booking_id,
          unitId: failure.unit_id,
        },
        timestamp: admin.firestore.Timestamp.now(),
        isRead: false,
      });

    logInfo("[Two-Way Sync] Owner notified of sync failure", {
      ownerId,
      bookingId: failure.booking_id,
    });
  } catch (error) {
    logError("[Two-Way Sync] Failed to notify owner", error);
  }
}

