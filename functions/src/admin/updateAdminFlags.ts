import {onCall, HttpsError} from "firebase-functions/v2/https";
import {admin, db} from "../firebase";
import {logError, logSuccess, logWarn} from "../logger";

/**
 * Admin: Update Admin Flags
 *
 * Callable Cloud Function for admins to update admin-controlled flags on a user profile.
 *
 * @remarks
 * - **Security:** Checks if the caller has an `isAdmin` custom claim
 * - **Validation:** Ensures the provided `userId` exists
 * - **Auditing:** Records the update timestamp
 * - **Logging:** Logs action to security_events collection
 */

// Valid account types for override
const VALID_ACCOUNT_TYPES = ["trial", "premium", "enterprise", "lifetime"] as const;
type AccountType = typeof VALID_ACCOUNT_TYPES[number];

interface UpdateAdminFlagsRequest {
  userId: string;
  hideSubscription?: boolean;
  adminOverrideAccountType?: AccountType | null;
  clearOverride?: boolean; // If true, deletes the override field
}

export const updateAdminFlags = onCall(
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
      logWarn("[Admin] Non-admin attempted to update admin flags", {
        callerUid: request.auth.uid,
      });
      throw new HttpsError(
        "permission-denied",
        "This function can only be called by an administrator."
      );
    }

    const {
      userId,
      hideSubscription,
      adminOverrideAccountType,
      clearOverride,
    } = request.data as UpdateAdminFlagsRequest;
    const adminUid = request.auth.uid;

    // 3. Input Validation
    if (!userId || typeof userId !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "The 'userId' argument is required and must be a string."
      );
    }

    if (adminOverrideAccountType && !VALID_ACCOUNT_TYPES.includes(adminOverrideAccountType)) {
      throw new HttpsError(
        "invalid-argument",
        `Invalid 'adminOverrideAccountType'. Must be one of: ${VALID_ACCOUNT_TYPES.join(", ")}.`
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

        const updatePayload: Record<string, any> = {
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        };

        if (typeof hideSubscription === "boolean") {
          updatePayload.hide_subscription = hideSubscription;
        }

        if (clearOverride === true) {
          updatePayload.admin_override_account_type = admin.firestore.FieldValue.delete();
        } else if (adminOverrideAccountType) {
          updatePayload.admin_override_account_type = adminOverrideAccountType;
        }

        // Only update if there are changes
        if (Object.keys(updatePayload).length > 1) { // >1 because updated_at is always present
          transaction.update(userRef, updatePayload);
        }
      });

      // 5. Log to security_events collection for audit trail
      const userDoc = await userRef.get();
      const userEmail = userDoc.data()?.email || "";

      await db.collection("security_events").add({
        type: "admin_flags_update",
        action: "update",
        target_user_id: userId,
        target_user_email: userEmail,
        admin_uid: adminUid,
        changes: {
          hide_subscription: hideSubscription,
          admin_override_account_type: clearOverride ? "deleted" : adminOverrideAccountType,
        },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      logSuccess("[Admin] User admin flags updated", {
        userId,
        adminUid,
        hideSubscription,
        adminOverrideAccountType,
        clearOverride,
      });

      return {
        success: true,
        message: "User admin flags updated successfully.",
      };
    } catch (error) {
      logError("[Admin] Error updating admin flags", error, {
        userId,
        adminUid,
      });

      // Re-throw HttpsError to the client
      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "An unexpected error occurred while updating admin flags."
      );
    }
  }
);
