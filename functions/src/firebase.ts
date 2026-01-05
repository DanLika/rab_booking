/**
 * Firebase Admin SDK Initialization
 *
 * CRITICAL: This module initializes Firebase Admin SDK for all Cloud Functions.
 * If initialization fails, ALL Cloud Functions will fail.
 *
 * ERROR HANDLING:
 * - Validates successful initialization
 * - Logs initialization status for debugging
 * - Throws descriptive errors if initialization fails
 *
 * USAGE:
 * ```typescript
 * import {db, admin} from "./firebase";
 * const doc = await db.collection("bookings").doc(bookingId).get();
 * ```
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

/**
 * Initialize Firebase Admin SDK with error handling
 *
 * Cloud Functions automatically provides credentials via environment variables:
 * - GOOGLE_APPLICATION_CREDENTIALS (service account)
 * - FIREBASE_CONFIG (project config)
 */
try {
  // Check if already initialized (prevents multiple initializations)
  if (admin.apps.length === 0) {
    functions.logger.info("[Firebase] Initializing Firebase Admin SDK...");

    // Initialize with default credentials (auto-detected by Cloud Functions)
    admin.initializeApp();

    // Validate initialization - defensive check
    const app = admin.app();
    if (!app) {
      throw new Error("Firebase Admin initialization returned null/undefined");
    }

    // Validate Firestore is accessible
    const firestoreInstance = admin.firestore();
    if (!firestoreInstance) {
      throw new Error("Firestore instance is null/undefined after initialization");
    }

    // Safely get project ID with defensive check
    const projectId = app.options?.projectId ?? "unknown";

    functions.logger.info("[Firebase] Successfully initialized Firebase Admin SDK", {
      projectId,
    });
  } else {
    functions.logger.info("[Firebase] Already initialized, using existing app");
  }
} catch (error) {
  functions.logger.error("[Firebase] CRITICAL: Failed to initialize Firebase Admin SDK", {
    error: error instanceof Error ? error.message : String(error),
  });
  functions.logger.error("[Firebase] All Cloud Functions will fail until this is resolved");
  throw new Error(
    `Firebase Admin initialization failed: ${error instanceof Error ? error.message : String(error)}`
  );
}

/**
 * Firestore database instance
 * @throws Error if Firestore is not accessible
 */
export const db = admin.firestore();

// Validate exports
if (!db) {
  throw new Error("CRITICAL: Firestore database instance is null/undefined");
}

// Re-export admin namespace for use in other modules
export {admin};

functions.logger.info("[Firebase] Module exports validated successfully");
