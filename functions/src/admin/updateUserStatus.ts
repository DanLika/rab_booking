import {onCall, HttpsError} from "firebase-functions/v2/https";
import {admin, db} from "../firebase";
import {logError, logSuccess} from "../logger";

/**
 * Admin: Update User Status
 *
 * Callable Cloud Function for admins to update a user's account status.
 *
 * @remarks
 * - **Security:** Checks if the caller has an `isAdmin` custom claim
 * - **Validation:** Ensures the provided `userId` exists and `newStatus` is valid
 * - **Auditing:** Records the admin's UID in the `statusChangedBy` field
 */

// Valid account statuses
const VALID_STATUSES = ["trial", "active", "trial_expired", "suspended"] as const;
type AccountStatus = typeof VALID_STATUSES[number];

interface UpdateUserStatusRequest {
  userId: string;
  newStatus: AccountStatus;
  reason?: string;
}

export const updateUserStatus = onCall(
  {
    region: "europe-west1",
  },
  async (request) => {
    // 1. Security Check: Ensure the caller is authenticated
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to perform this action."
      );
    }

    // 2. Security Check: Ensure the caller is an admin
    const isAdmin = request.auth.token.isAdmin === true;
    if (!isAdmin) {
      logError("[Admin] Non-admin attempted to update user status", null, {
        callerUid: request.auth.uid,
      });
      throw new HttpsError(
        "permission-denied",
        "This function can only be called by an administrator."
      );
    }

    const {userId, newStatus, reason} = request.data as UpdateUserStatusRequest;
    const adminUid = request.auth.uid;

    // 3. Input Validation
    if (!userId || typeof userId !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "The 'userId' argument is required and must be a string."
      );
    }

    if (!newStatus || !VALID_STATUSES.includes(newStatus)) {
      throw new HttpsError(
        "invalid-argument",
        `Invalid 'newStatus'. Must be one of: ${VALID_STATUSES.join(", ")}.`
      );
    }

    const userRef = db.collection("users").doc(userId);

    try {
      // 4. Perform the update in a transaction for atomicity
      await db.runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw new HttpsError(
            "not-found",
            `User with ID ${userId} not found.`
          );
        }

        const currentStatus = userDoc.data()?.accountStatus;

        const updatePayload: Record<string, admin.firestore.FieldValue | string | boolean | null> = {
          accountStatus: newStatus,
          statusChangedAt: admin.firestore.FieldValue.serverTimestamp(),
          statusChangedBy: adminUid,
          previousStatus: currentStatus || null,
        };

        if (reason) {
          updatePayload.statusChangeReason = reason;
        }

        // If activating from trial_expired, clear the expired flag
        if (newStatus === "active" && currentStatus === "trial_expired") {
          updatePayload.trialExpiredEmailSent = false;
        }

        // If setting to trial, reset warning flags
        if (newStatus === "trial") {
          updatePayload.trialWarning7DaysSent = false;
          updatePayload.trialWarning3DaysSent = false;
          updatePayload.trialWarning1DaySent = false;
          updatePayload.trialExpiredEmailSent = false;
        }

        transaction.update(userRef, updatePayload);
      });

      logSuccess("[Admin] User status updated", {
        userId,
        newStatus,
        adminUid,
        reason: reason || "No reason provided",
      });

      return {
        success: true,
        message: `User ${userId} status updated to ${newStatus}.`,
      };
    } catch (error) {
      logError("[Admin] Error updating user status", error, {
        userId,
        adminUid,
      });

      // Re-throw HttpsError to the client
      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "An unexpected error occurred while updating user status."
      );
    }
  }
);
