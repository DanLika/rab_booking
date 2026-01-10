/**
 * Unit Management Cloud Functions
 *
 * Handles unit lifecycle events, including cascade deletion
 * of subcollections when a unit is deleted.
 *
 * Subcollections deleted:
 * - bookings
 * - daily_prices
 * - widget_settings (if exists)
 *
 * @module unitManagement
 */

import {onDocumentDeleted} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {logInfo, logError, logWarn} from "./logger";

const db = admin.firestore();
const BATCH_SIZE = 400; // Firestore limit is 500, keep margin for safety

/**
 * Triggered when a unit document is deleted.
 * Automatically deletes all subcollections to prevent orphaned data.
 *
 * This is a safety net - the Flutter app should also attempt to delete
 * subcollections, but this ensures cleanup happens even if the app
 * doesn't complete the operation.
 */
export const onUnitDeleted = onDocumentDeleted(
  {
    document: "properties/{propertyId}/units/{unitId}",
    region: "europe-west1",
  },
  async (event) => {
    const propertyId = event.params.propertyId;
    const unitId = event.params.unitId;

    logInfo("[UnitManagement] Unit deleted, cleaning up subcollections", {
      propertyId,
      unitId,
    });

    try {
      const unitRef = db
        .collection("properties")
        .doc(propertyId)
        .collection("units")
        .doc(unitId);

      // Delete all subcollections in parallel
      const results = await Promise.allSettled([
        deleteSubcollection(unitRef, "bookings", unitId),
        deleteSubcollection(unitRef, "daily_prices", unitId),
        deleteSubcollection(unitRef, "widget_settings", unitId),
      ]);

      // Log results
      const subcollections = ["bookings", "daily_prices", "widget_settings"];
      results.forEach((result, index) => {
        if (result.status === "rejected") {
          logWarn(
            `[UnitManagement] Failed to delete ${subcollections[index]}`,
            {
              unitId,
              error: String(result.reason),
            }
          );
        }
      });

      logInfo("[UnitManagement] Unit cleanup completed", {
        propertyId,
        unitId,
      });
    } catch (error) {
      logError(
        "[UnitManagement] Unit cleanup failed",
        error as Error,
        {propertyId, unitId}
      );
      // Don't throw - trigger should not retry on cleanup failure
    }
  }
);

/**
 * Delete all documents in a subcollection using batched writes
 */
async function deleteSubcollection(
  parentRef: admin.firestore.DocumentReference,
  subcollectionName: string,
  unitId: string
): Promise<void> {
  const collectionRef = parentRef.collection(subcollectionName);
  const snapshot = await collectionRef.limit(BATCH_SIZE).get();

  if (snapshot.empty) {
    logInfo(`[UnitManagement] No ${subcollectionName} to delete`, {unitId});
    return;
  }

  let totalDeleted = 0;

  // Process in batches
  while (true) {
    const batchSnapshot = await collectionRef.limit(BATCH_SIZE).get();

    if (batchSnapshot.empty) {
      break;
    }

    const batch = db.batch();
    batchSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    totalDeleted += batchSnapshot.size;

    // If we got less than BATCH_SIZE, we're done
    if (batchSnapshot.size < BATCH_SIZE) {
      break;
    }
  }

  if (totalDeleted > 0) {
    logInfo(`[UnitManagement] Deleted ${subcollectionName}`, {
      unitId,
      count: totalDeleted,
    });
  }
}
