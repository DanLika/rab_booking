/**
 * Property Management Cloud Functions
 *
 * Handles property lifecycle events, including cascade deletion
 * of all subcollections when a property is deleted.
 *
 * Cascade delete structure:
 * - properties/{propertyId}/units/{unitId} -> triggers onUnitDeleted (unitManagement.ts)
 *   - bookings (handled by onUnitDeleted)
 *   - daily_prices (handled by onUnitDeleted)
 *   - widget_settings (handled by onUnitDeleted)
 * - properties/{propertyId}/ical_feeds (deleted here)
 * - properties/{propertyId}/ical_events (deleted here)
 * - properties/{propertyId}/widget_settings (deleted here, if exists at property level)
 *
 * @module propertyManagement
 */

import {onDocumentDeleted} from "firebase-functions/v2/firestore";
import {db} from "./firebase";
import {logInfo, logError, logWarn, logSuccess} from "./logger";

const BATCH_SIZE = 400; // Firestore limit is 500, keep margin for safety

/**
 * Triggered when a property document is deleted.
 * Automatically deletes all subcollections to prevent orphaned data.
 *
 * The onUnitDeleted trigger (unitManagement.ts) handles unit subcollections,
 * so we only need to delete:
 * 1. Unit documents (triggers cascade via onUnitDeleted)
 * 2. Property-level subcollections: ical_feeds, ical_events, widget_settings
 */
export const onPropertyDeleted = onDocumentDeleted(
  {
    document: "properties/{propertyId}",
    region: "europe-west1",
  },
  async (event) => {
    const propertyId = event.params.propertyId;

    logInfo("[PropertyManagement] Property deleted, cleaning up subcollections", {
      propertyId,
    });

    const stats = {
      unitsDeleted: 0,
      icalFeedsDeleted: 0,
      icalEventsDeleted: 0,
      widgetSettingsDeleted: 0,
      errors: [] as string[],
    };

    try {
      const propertyRef = db.collection("properties").doc(propertyId);

      // Step 1: Delete all unit documents
      // This triggers onUnitDeleted for each unit, which handles:
      // - bookings subcollection
      // - daily_prices subcollection
      // - widget_settings subcollection (unit level)
      try {
        stats.unitsDeleted = await deleteUnitsWithTrigger(propertyRef, propertyId);
      } catch (error) {
        stats.errors.push(`units: ${String(error)}`);
        logWarn("[PropertyManagement] Failed to delete units", {
          propertyId,
          error: String(error),
        });
      }

      // Step 2: Delete property-level subcollections in parallel
      const results = await Promise.allSettled([
        deleteSubcollection(propertyRef, "ical_feeds", propertyId),
        deleteSubcollection(propertyRef, "ical_events", propertyId),
        deleteSubcollection(propertyRef, "widget_settings", propertyId),
      ]);

      // Process results
      const subcollections = ["ical_feeds", "ical_events", "widget_settings"];
      results.forEach((result, index) => {
        const name = subcollections[index];
        if (result.status === "fulfilled") {
          if (name === "ical_feeds") stats.icalFeedsDeleted = result.value;
          if (name === "ical_events") stats.icalEventsDeleted = result.value;
          if (name === "widget_settings") stats.widgetSettingsDeleted = result.value;
        } else {
          stats.errors.push(`${name}: ${String(result.reason)}`);
          logWarn(`[PropertyManagement] Failed to delete ${name}`, {
            propertyId,
            error: String(result.reason),
          });
        }
      });

      // Log summary
      if (stats.errors.length === 0) {
        logSuccess("[PropertyManagement] Property cleanup completed successfully", {
          propertyId,
          unitsDeleted: stats.unitsDeleted,
          icalFeedsDeleted: stats.icalFeedsDeleted,
          icalEventsDeleted: stats.icalEventsDeleted,
          widgetSettingsDeleted: stats.widgetSettingsDeleted,
        });
      } else {
        logWarn("[PropertyManagement] Property cleanup completed with errors", {
          propertyId,
          stats,
        });
      }
    } catch (error) {
      logError(
        "[PropertyManagement] Property cleanup failed",
        error as Error,
        {propertyId}
      );
      // Don't throw - trigger should not retry on cleanup failure
      // Orphaned data is better than infinite retry loops
    }
  }
);

/**
 * Delete all unit documents (triggers onUnitDeleted for each)
 *
 * By deleting unit documents, the onUnitDeleted trigger in unitManagement.ts
 * will automatically clean up each unit's subcollections:
 * - bookings
 * - daily_prices
 * - widget_settings
 *
 * @return Number of units deleted
 */
async function deleteUnitsWithTrigger(
  propertyRef: FirebaseFirestore.DocumentReference,
  propertyId: string
): Promise<number> {
  const unitsRef = propertyRef.collection("units");
  let totalDeleted = 0;

  // Process in batches to handle large properties
  while (true) {
    const snapshot = await unitsRef.limit(BATCH_SIZE).get();

    if (snapshot.empty) {
      break;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    totalDeleted += snapshot.size;

    logInfo("[PropertyManagement] Deleted batch of units", {
      propertyId,
      batchSize: snapshot.size,
      totalSoFar: totalDeleted,
    });

    // Small delay to allow onUnitDeleted triggers to process
    // This prevents overwhelming the system with concurrent triggers
    if (snapshot.size === BATCH_SIZE) {
      await new Promise((resolve) => setTimeout(resolve, 500));
    } else {
      // Less than batch size means we're done
      break;
    }
  }

  if (totalDeleted > 0) {
    logInfo("[PropertyManagement] All units deleted (triggers will clean subcollections)", {
      propertyId,
      count: totalDeleted,
    });
  }

  return totalDeleted;
}

/**
 * Delete all documents in a subcollection using batched writes
 *
 * @return Number of documents deleted
 */
async function deleteSubcollection(
  parentRef: FirebaseFirestore.DocumentReference,
  subcollectionName: string,
  propertyId: string
): Promise<number> {
  const collectionRef = parentRef.collection(subcollectionName);
  let totalDeleted = 0;

  // Process in batches
  while (true) {
    const snapshot = await collectionRef.limit(BATCH_SIZE).get();

    if (snapshot.empty) {
      break;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    totalDeleted += snapshot.size;

    // If we got less than BATCH_SIZE, we're done
    if (snapshot.size < BATCH_SIZE) {
      break;
    }
  }

  if (totalDeleted > 0) {
    logInfo(`[PropertyManagement] Deleted ${subcollectionName}`, {
      propertyId,
      count: totalDeleted,
    });
  }

  return totalDeleted;
}
