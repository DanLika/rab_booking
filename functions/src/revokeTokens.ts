/**
 * Token Revocation Service
 *
 * Provides "Sign out from all devices" functionality by revoking
 * all Firebase Auth refresh tokens for a user.
 *
 * When tokens are revoked:
 * - All existing sessions become invalid
 * - User must re-authenticate on all devices
 * - Useful for compromised accounts or security concerns
 *
 * @module revokeTokens
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {logInfo, logWarn} from "./logger";
import {setUser} from "./sentry";

const db = admin.firestore();

/**
 * Revoke all refresh tokens for the current user
 *
 * This effectively signs out the user from all devices.
 * The user will need to re-authenticate on each device.
 *
 * @returns {success: true, message: string} on success
 * @throws HttpsError if user is not authenticated or revocation fails
 *
 * @example
 * // Dart code:
 * final callable = FirebaseFunctions.instance.httpsCallable('revokeAllRefreshTokens');
 * await callable.call();
 * // Then sign out locally
 * await FirebaseAuth.instance.signOut();
 */
export const revokeAllRefreshTokens = onCall(
  {
    region: "europe-west1",
  },
  async (request) => {
    // Require authentication
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    // Set user context for Sentry error tracking
    setUser(userId);

    try {
      // Revoke all refresh tokens
      // This invalidates all existing sessions across all devices
      await admin.auth().revokeRefreshTokens(userId);

      // Get user record to verify revocation time
      const userRecord = await admin.auth().getUser(userId);
      const revokeTime = userRecord.tokensValidAfterTime;

      logInfo("[RevokeTokens] All tokens revoked", {
        userId,
        revokeTime,
      });

      // Optional: Clear any stored device/session data
      try {
        const devicesRef = db
          .collection("users")
          .doc(userId)
          .collection("devices");

        const devices = await devicesRef.get();
        if (!devices.empty) {
          const batch = db.batch();
          devices.docs.forEach((doc) => {
            batch.delete(doc.ref);
          });
          await batch.commit();
          logInfo("[RevokeTokens] Device records cleared", {
            userId,
            deviceCount: devices.size,
          });
        }
      } catch (deviceError) {
        // Don't fail if device cleanup fails
        logWarn("[RevokeTokens] Device cleanup failed", {
          userId,
          error: String(deviceError),
        });
      }

      // Log security event to Cloud Logging
      logInfo("[RevokeTokens] Tokens revoked", {
        type: "tokens_revoked",
        userId,
        reason: "user_requested",
        revokeTime,
      });

      return {
        success: true,
        message: "All sessions have been invalidated. Please sign in again on each device.",
      };
    } catch (error) {
      logWarn("[RevokeTokens] Token revocation failed", {
        userId,
        error: String(error),
      });

      throw new HttpsError(
        "internal",
        "Failed to revoke tokens. Please try again."
      );
    }
  }
);
