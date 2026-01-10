/**
 * User Account Deletion Service
 *
 * Provides complete account deletion functionality required for
 * Apple App Store compliance (mandatory since 2022).
 *
 * When account is deleted:
 * - All user profile data is permanently removed
 * - All owned properties, units, bookings are deleted
 * - Guest bookings made BY this user on OTHER owners' properties are anonymized
 * - Firebase Auth account is deleted
 * - User cannot recover account
 *
 * GDPR Compliance:
 * - Booking records are anonymized (not deleted) for financial/legal compliance
 * - Keeps booking dates, prices, status for owner reporting
 * - Removes guest PII: name, email, phone
 *
 * @module deleteUserAccount
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {logInfo, logError, logWarn} from "./logger";
import {setUser, captureMessage} from "./sentry";
import {enforceRateLimit} from "./utils/rateLimit";
import {maskEmail} from "./utils/inputSanitization";

const db = admin.firestore();
const BATCH_SIZE = 400; // Firestore limit is 500, keep margin for safety

/**
 * Delete user account and all associated data
 *
 * This is a destructive operation that cannot be undone.
 * The user must be authenticated to delete their own account.
 *
 * @returns {success: true} on success
 * @throws HttpsError if deletion fails
 *
 * @example
 * // Dart code:
 * final callable = FirebaseFunctions.instance.httpsCallable('deleteUserAccount');
 * await callable.call();
 * // Then sign out locally
 * await FirebaseAuth.instance.signOut();
 */
export const deleteUserAccount = onCall(
  {
    region: "europe-west1",
    // Allow longer timeout for large accounts
    timeoutSeconds: 540,
  },
  async (request) => {
    // Require authentication
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    // Rate limiting: 1 account deletion attempt per hour
    await enforceRateLimit(userId, "delete_account", {
      maxCalls: 1,
      windowMs: 3600000, // 1 hour
      errorMessage:
        "Account deletion already in progress or failed. Please try again later.",
    });

    // Set user context for Sentry error tracking
    setUser(userId);

    logInfo("[DeleteAccount] Account deletion requested", {userId});

    try {
      // Step 1: Log deletion event BEFORE deleting anything
      // This creates an audit trail even if deletion partially fails
      await logDeletionEvent(userId);

      // Step 2: Get user's email for logging (before deletion)
      let userEmail: string | undefined;
      try {
        const userRecord = await admin.auth().getUser(userId);
        userEmail = userRecord.email;
      } catch {
        // User might already be partially deleted
      }

      // Step 3: Anonymize guest bookings made BY this user on other owners' properties
      await anonymizeGuestBookings(userId, userEmail);

      // Step 4: Delete all owned properties (cascades to units, bookings, prices)
      await deleteOwnedProperties(userId);

      // Step 5: Delete platform connections (Booking.com, Airbnb OAuth)
      await deletePlatformConnections(userId);

      // Step 6: Delete iCal feeds
      await deleteIcalFeeds(userId);

      // Step 7: Delete user document and all subcollections
      await deleteUserDocument(userId);

      // Step 8: Delete legacy user_profiles document if exists
      await deleteLegacyProfile(userId);

      // Step 9: Finally, delete Firebase Auth account
      await admin.auth().deleteUser(userId);

      logInfo("[DeleteAccount] Account deleted successfully", {
        userId,
        email: maskEmail(userEmail),
      });

      // Send to Sentry for monitoring
      captureMessage("User account deleted", "info", {
        userId,
        email: maskEmail(userEmail),
      });

      return {
        success: true,
        message: "Account deleted successfully",
      };
    } catch (error) {
      logError("[DeleteAccount] Deletion failed", error as Error, {userId});

      throw new HttpsError(
        "internal",
        "Failed to delete account. Please contact support."
      );
    }
  }
);

/**
 * Log deletion event before deleting anything
 */
async function logDeletionEvent(userId: string): Promise<void> {
  try {
    await db.collection("security_events").add({
      type: "account_deleted",
      userId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      details: {
        reason: "user_requested",
        source: "app",
      },
    });
  } catch (error) {
    // Log but don't fail - deletion should continue
    logWarn("[DeleteAccount] Failed to log deletion event", {
      userId,
      error: String(error),
    });
  }
}

/**
 * Anonymize bookings made by this user as a GUEST on other owners' properties
 * GDPR compliant: keeps booking data for owner reporting, removes PII
 */
async function anonymizeGuestBookings(
  userId: string,
  userEmail?: string
): Promise<void> {
  if (!userEmail) return;

  try {
    // Find all bookings where this user was the guest (by email)
    const bookingsSnapshot = await db
      .collectionGroup("bookings")
      .where("guest_email", "==", userEmail)
      .get();

    if (bookingsSnapshot.empty) {
      logInfo("[DeleteAccount] No guest bookings to anonymize", {userId});
      return;
    }

    // Batch anonymize
    const batches: admin.firestore.WriteBatch[] = [];
    let currentBatch = db.batch();
    let operationCount = 0;

    for (const doc of bookingsSnapshot.docs) {
      // Don't anonymize if this user owns the property
      const data = doc.data();
      if (data.owner_id === userId) {
        continue; // Will be deleted with property
      }

      currentBatch.update(doc.ref, {
        guest_name: "[Deleted User]",
        guest_email: "[deleted]@anonymized.local",
        guest_phone: null,
        notes: data.notes ? "[Notes removed - user deleted account]" : null,
        anonymized_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      operationCount++;

      if (operationCount >= BATCH_SIZE) {
        batches.push(currentBatch);
        currentBatch = db.batch();
        operationCount = 0;
      }
    }

    if (operationCount > 0) {
      batches.push(currentBatch);
    }

    // Execute all batches
    for (const batch of batches) {
      await batch.commit();
    }

    logInfo("[DeleteAccount] Guest bookings anonymized", {
      userId,
      count: bookingsSnapshot.size,
    });
  } catch (error) {
    logWarn("[DeleteAccount] Guest booking anonymization failed", {
      userId,
      error: String(error),
    });
    // Don't fail deletion - this is best-effort GDPR compliance
  }
}

/**
 * Delete all properties owned by this user
 * This cascades to: units, bookings, daily_prices, widget_settings, ical_events
 */
async function deleteOwnedProperties(userId: string): Promise<void> {
  const propertiesSnapshot = await db
    .collection("properties")
    .where("owner_id", "==", userId)
    .get();

  if (propertiesSnapshot.empty) {
    logInfo("[DeleteAccount] No properties to delete", {userId});
    return;
  }

  for (const propertyDoc of propertiesSnapshot.docs) {
    await deletePropertyCascade(propertyDoc.ref);
  }

  logInfo("[DeleteAccount] Properties deleted", {
    userId,
    count: propertiesSnapshot.size,
  });
}

/**
 * Delete a property and all its subcollections
 */
async function deletePropertyCascade(
  propertyRef: admin.firestore.DocumentReference
): Promise<void> {
  // Delete units and their subcollections
  const unitsSnapshot = await propertyRef.collection("units").get();
  for (const unitDoc of unitsSnapshot.docs) {
    await deleteUnitCascade(unitDoc.ref);
  }

  // Delete widget_settings subcollection
  await deleteSubcollection(propertyRef, "widget_settings");

  // Delete ical_events subcollection
  await deleteSubcollection(propertyRef, "ical_events");

  // Delete the property document itself
  await propertyRef.delete();
}

/**
 * Delete a unit and all its subcollections
 */
async function deleteUnitCascade(
  unitRef: admin.firestore.DocumentReference
): Promise<void> {
  // Delete bookings
  await deleteSubcollection(unitRef, "bookings");

  // Delete daily_prices
  await deleteSubcollection(unitRef, "daily_prices");

  // Delete the unit document itself
  await unitRef.delete();
}

/**
 * Delete all documents in a subcollection
 */
async function deleteSubcollection(
  parentRef: admin.firestore.DocumentReference,
  subcollectionName: string
): Promise<void> {
  const snapshot = await parentRef.collection(subcollectionName).get();

  if (snapshot.empty) return;

  const batches: admin.firestore.WriteBatch[] = [];
  let currentBatch = db.batch();
  let operationCount = 0;

  for (const doc of snapshot.docs) {
    currentBatch.delete(doc.ref);
    operationCount++;

    if (operationCount >= BATCH_SIZE) {
      batches.push(currentBatch);
      currentBatch = db.batch();
      operationCount = 0;
    }
  }

  if (operationCount > 0) {
    batches.push(currentBatch);
  }

  for (const batch of batches) {
    await batch.commit();
  }
}

/**
 * Delete platform connections (Booking.com, Airbnb OAuth tokens)
 */
async function deletePlatformConnections(userId: string): Promise<void> {
  try {
    const connectionsSnapshot = await db
      .collection("platform_connections")
      .where("owner_id", "==", userId)
      .get();

    if (connectionsSnapshot.empty) return;

    const batch = db.batch();
    for (const doc of connectionsSnapshot.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();

    logInfo("[DeleteAccount] Platform connections deleted", {
      userId,
      count: connectionsSnapshot.size,
    });
  } catch (error) {
    logWarn("[DeleteAccount] Platform connections deletion failed", {
      userId,
      error: String(error),
    });
  }
}

/**
 * Delete iCal feed configurations
 */
async function deleteIcalFeeds(userId: string): Promise<void> {
  try {
    const feedsSnapshot = await db
      .collection("ical_feeds")
      .where("owner_id", "==", userId)
      .get();

    if (feedsSnapshot.empty) return;

    const batch = db.batch();
    for (const doc of feedsSnapshot.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();

    logInfo("[DeleteAccount] iCal feeds deleted", {
      userId,
      count: feedsSnapshot.size,
    });
  } catch (error) {
    logWarn("[DeleteAccount] iCal feeds deletion failed", {
      userId,
      error: String(error),
    });
  }
}

/**
 * Delete user document and all subcollections
 */
async function deleteUserDocument(userId: string): Promise<void> {
  const userRef = db.collection("users").doc(userId);

  // Delete subcollections first
  const subcollections = [
    "data",
    "securityEvents",
    "security_events",
    "notifications",
    "rate_limits",
    "devices",
  ];

  for (const subcollection of subcollections) {
    await deleteSubcollection(userRef, subcollection);
  }

  // Delete nested data subcollections (profile, company, preferences)
  const dataRef = userRef.collection("data");
  const dataSnapshot = await dataRef.get();
  for (const doc of dataSnapshot.docs) {
    await doc.ref.delete();
  }

  // Delete the user document itself
  await userRef.delete();

  logInfo("[DeleteAccount] User document deleted", {userId});
}

/**
 * Delete legacy user_profiles document if exists
 */
async function deleteLegacyProfile(userId: string): Promise<void> {
  try {
    const legacyRef = db.collection("user_profiles").doc(userId);
    const legacyDoc = await legacyRef.get();

    if (legacyDoc.exists) {
      await legacyRef.delete();
      logInfo("[DeleteAccount] Legacy profile deleted", {userId});
    }
  } catch (error) {
    // Don't fail if legacy profile doesn't exist
    logWarn("[DeleteAccount] Legacy profile deletion failed", {
      userId,
      error: String(error),
    });
  }
}
