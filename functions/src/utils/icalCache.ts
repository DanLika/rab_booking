import {admin, db} from "../firebase";
import {logInfo, logWarn} from "../logger";

/**
 * Flush iCal feed cache on properties/{propertyId}/widget_settings/{unitId}.
 * Non-fatal: NOT_FOUND on units without widget_settings is expected.
 *
 * @param {string} propertyId - Parent property document ID
 * @param {string} unitId - Unit document ID (= widget_settings doc ID)
 * @return {Promise<void>}
 */
export async function invalidateIcalCache(
  propertyId: string,
  unitId: string
): Promise<void> {
  try {
    await db
      .collection("properties").doc(propertyId)
      .collection("widget_settings").doc(unitId)
      .update({
        ical_cache_content: admin.firestore.FieldValue.delete(),
        ical_cache_generated_at: admin.firestore.FieldValue.delete(),
        ical_cache_etag: admin.firestore.FieldValue.delete(),
        ical_cache_unit_name: admin.firestore.FieldValue.delete(),
      });
    logInfo("[iCal Cache] Invalidated", {propertyId, unitId});
  } catch (e) {
    logWarn("[iCal Cache] Invalidation skipped or failed", {
      propertyId,
      unitId,
      error: e instanceof Error ? e.message : String(e),
    });
  }
}
