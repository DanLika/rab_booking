import {onCall, HttpsError} from "firebase-functions/v2/https";
import {admin} from "./firebase";
import {logInfo, logError, logSuccess} from "./logger";
import * as crypto from "crypto";

/**
 * Generate iCal export URL and token for a unit
 * 
 * Called when owner enables iCal export in widget settings.
 * Generates a secure token and public URL for the iCal feed.
 */
export const generateIcalExportUrl = onCall(async (request) => {
  // Check authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const {propertyId, unitId} = request.data;

  if (!propertyId || !unitId) {
    throw new HttpsError("invalid-argument", "propertyId and unitId are required");
  }

  const db = admin.firestore();

  try {
    logInfo("[iCal Export] Generating URL", {propertyId, unitId});

    // Verify user owns this property
    const propertyDoc = await db.collection("properties").doc(propertyId).get();

    if (!propertyDoc.exists || propertyDoc.data()?.owner_id !== request.auth.uid) {
      throw new HttpsError("permission-denied", "You do not own this property");
    }

    // Generate secure random token
    const token = crypto.randomBytes(32).toString("hex");

    // Get Firebase project ID for URL
    const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
    const region = process.env.FUNCTION_REGION || "us-central1";

    // Generate public iCal feed URL
    // Format: https://{region}-{project}.cloudfunctions.net/getUnitIcalFeed/{propertyId}/{unitId}/{token}
    const icalUrl = `https://${region}-${projectId}.cloudfunctions.net/getUnitIcalFeed/${propertyId}/${unitId}/${token}`;

    // Update widget_settings with token and URL
    await db
      .collection("properties")
      .doc(propertyId)
      .collection("widget_settings")
      .doc(unitId)
      .update({
        ical_export_token: token,
        ical_export_url: icalUrl,
        ical_export_last_generated: admin.firestore.Timestamp.now(),
      });

    logSuccess("[iCal Export] URL generated successfully", {
      propertyId,
      unitId,
      url: icalUrl,
    });

    return {
      success: true,
      icalUrl,
      message: "iCal export URL generated successfully",
    };
  } catch (error) {
    logError("[iCal Export] Error generating URL", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    throw new HttpsError("internal", "Failed to generate URL: " + errorMessage);
  }
});

/**
 * Revoke iCal export URL and token
 * 
 * Called when owner disables iCal export in widget settings.
 */
export const revokeIcalExportUrl = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const {propertyId, unitId} = request.data;

  if (!propertyId || !unitId) {
    throw new HttpsError("invalid-argument", "propertyId and unitId are required");
  }

  const db = admin.firestore();

  try {
    logInfo("[iCal Export] Revoking URL", {propertyId, unitId});

    // Verify user owns this property
    const propertyDoc = await db.collection("properties").doc(propertyId).get();

    if (!propertyDoc.exists || propertyDoc.data()?.owner_id !== request.auth.uid) {
      throw new HttpsError("permission-denied", "You do not own this property");
    }

    // Remove token and URL from widget_settings
    await db
      .collection("properties")
      .doc(propertyId)
      .collection("widget_settings")
      .doc(unitId)
      .update({
        ical_export_token: admin.firestore.FieldValue.delete(),
        ical_export_url: admin.firestore.FieldValue.delete(),
      });

    logSuccess("[iCal Export] URL revoked successfully", {propertyId, unitId});

    return {
      success: true,
      message: "iCal export URL revoked successfully",
    };
  } catch (error) {
    logError("[iCal Export] Error revoking URL", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    throw new HttpsError("internal", "Failed to revoke URL: " + errorMessage);
  }
});
