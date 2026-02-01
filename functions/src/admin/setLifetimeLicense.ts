import {onCall, HttpsError} from "firebase-functions/v2/https";
import {admin, db} from "../firebase";
import {logError, logSuccess, logWarn} from "../logger";

/**
 * Admin: Set Lifetime License
 *
 * Callable Cloud Function for admins to grant or revoke lifetime licenses.
 * Lifetime license gives users permanent premium access without Stripe subscription.
 *
 * @remarks
 * - **Security:** Checks if the caller has an `isAdmin` custom claim
 * - **Validation:** Ensures the provided `userId` exists
 * - **Auditing:** Records the admin's UID and timestamp when granting
 * - **Logging:** Logs action to security_events collection
 */

interface SetLifetimeLicenseRequest {
  userId: string;
  grant: boolean; // true = grant lifetime, false = revoke (revert to trial)
}

export const setLifetimeLicense = onCall(
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
      logWarn("[Admin] Non-admin attempted to set lifetime license", {
        callerUid: request.auth.uid,
      });
      throw new HttpsError(
        "permission-denied",
        "This function can only be called by an administrator."
      );
    }

    const {userId, grant} = request.data as SetLifetimeLicenseRequest;
    const adminUid = request.auth.uid;

    // 3. Input Validation
    if (!userId || typeof userId !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "The 'userId' argument is required and must be a string."
      );
    }

    if (typeof grant !== "boolean") {
      throw new HttpsError(
        "invalid-argument",
        "The 'grant' argument is required and must be a boolean."
      );
    }

    const userRef = db.collection("users").doc(userId);

    try {
      // 4. Perform the update in a transaction for atomicity
      const result = await db.runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw new HttpsError(
            "not-found",
            `User with ID ${userId} not found.`
          );
        }

        const userData = userDoc.data();
        const currentAccountType = userData?.accountType || "trial";
        const userEmail = userData?.email || "unknown";

        if (grant) {
          // Grant lifetime license
          const updatePayload = {
            accountType: "lifetime",
            lifetime_license_granted_at: admin.firestore.FieldValue.serverTimestamp(),
            lifetime_license_granted_by: adminUid,
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          };

          transaction.update(userRef, updatePayload);

          return {
            action: "granted",
            previousAccountType: currentAccountType,
            userEmail,
          };
        } else {
          // Revoke lifetime license - revert to trial
          const updatePayload = {
            accountType: "trial",
            lifetime_license_granted_at: admin.firestore.FieldValue.delete(),
            lifetime_license_granted_by: admin.firestore.FieldValue.delete(),
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          };

          transaction.update(userRef, updatePayload);

          return {
            action: "revoked",
            previousAccountType: currentAccountType,
            userEmail,
          };
        }
      });

      // 5. Log to security_events collection for audit trail
      await db.collection("security_events").add({
        type: "lifetime_license_change",
        action: result.action,
        target_user_id: userId,
        target_user_email: result.userEmail,
        admin_uid: adminUid,
        previous_account_type: result.previousAccountType,
        new_account_type: grant ? "lifetime" : "trial",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      logSuccess(`[Admin] Lifetime license ${result.action}`, {
        userId,
        userEmail: result.userEmail,
        action: result.action,
        adminUid,
        previousAccountType: result.previousAccountType,
      });

      return {
        success: true,
        message: grant ?
          `Lifetime license granted to user ${userId}.` :
          `Lifetime license revoked from user ${userId}.`,
        action: result.action,
      };
    } catch (error) {
      logError("[Admin] Error setting lifetime license", error, {
        userId,
        grant,
        adminUid,
      });

      // Re-throw HttpsError to the client
      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "An unexpected error occurred while setting lifetime license."
      );
    }
  }
);
