import {onDocumentDeleted} from "firebase-functions/v2/firestore";
import {db} from "./firebase";
import {logError, logInfo} from "./logger";

/**
 * Cloud Function: Cascade delete unit subcollections
 *
 * Triggered when a unit is deleted. Deletes all associated documents in
 * subcollections to ensure data integrity.
 */
export const onUnitDeleted = onDocumentDeleted(
  "properties/{propertyId}/units/{unitId}",
  async (event) => {
    const {propertyId, unitId} = event.params;
    logInfo(`Unit deleted, starting cascade delete for unit ${unitId} in property ${propertyId}`);

    try {
      // 1. Delete daily_prices subcollection
      const dailyPricesRef = db.collection(`properties/${propertyId}/units/${unitId}/daily_prices`);
      const dailyPricesSnapshot = await dailyPricesRef.get();
      if (!dailyPricesSnapshot.empty) {
        const batch = db.batch();
        dailyPricesSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        logInfo(`Deleted ${dailyPricesSnapshot.size} documents from daily_prices subcollection`);
      }

      // 2. Delete widget_settings subcollection
      const widgetSettingsRef = db.collection(`properties/${propertyId}/units/${unitId}/widget_settings`);
      const widgetSettingsSnapshot = await widgetSettingsRef.get();
      if (!widgetSettingsSnapshot.empty) {
        const batch = db.batch();
        widgetSettingsSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        logInfo(`Deleted ${widgetSettingsSnapshot.size} documents from widget_settings subcollection`);
      }

      logInfo(`Cascade delete completed for unit ${unitId}`);
    } catch (error) {
      logError(`Error during cascade delete for unit ${unitId}:`, error);
    }
  }
);
