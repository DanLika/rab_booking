import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();
const validStatuses = ["trial", "active", "trial_expired", "suspended"];

/**
 * A callable Cloud Function for an admin to update a user's account status.
 *
 * @remarks
 * - **Security:** Checks if the caller has an `isAdmin` custom claim.
 * - **Validation:** Ensures the provided `userId` exists and `newStatus` is a valid enum value.
 * - **Auditing:** Records the admin's UID in the `statusChangedBy` field.
 *
 * @param {object} data - The data passed to the function.
 * @param {string} data.userId - The ID of the user to update.
 * @param {string} data.newStatus - The new status to set for the user.
 * @param {string} [data.reason] - An optional reason for the status change.
 * @param {context} context - The context object for the callable function.
 *
 * @returns {Promise<object>} A result object indicating success.
 * @throws {functions.https.HttpsError} Throws an error if the user is not an admin,
 *   if the user is not found, or if the parameters are invalid.
 */
export const updateUserStatus = functions.https.onCall(async (data, context) => {
  // 1. Security Check: Ensure the caller is an admin
  if (!context.auth?.token.isAdmin) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "This function can only be called by an administrator.",
    );
  }

  const { userId, newStatus, reason } = data;
  const adminUid = context.auth.uid;

  // 2. Input Validation
  if (!userId || !newStatus) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with 'userId' and 'newStatus' arguments.",
    );
  }

  if (!validStatuses.includes(newStatus)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Invalid 'newStatus'. Must be one of: ${validStatuses.join(", ")}.`,
    );
  }

  const userRef = db.collection("users").doc(userId);

  try {
    // 3. Perform the update in a transaction for atomicity
    await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          `User with ID ${userId} not found.`,
        );
      }

      const updatePayload: { [key: string]: unknown } = {
        accountStatus: newStatus,
        statusChangedAt: admin.firestore.FieldValue.serverTimestamp(),
        statusChangedBy: adminUid,
      };

      if (reason) {
        updatePayload.statusChangeReason = reason;
      }

      transaction.update(userRef, updatePayload);
    });

    functions.logger.info(`Admin ${adminUid} successfully updated user ${userId} to status '${newStatus}'.`);
    return { success: true, message: `User ${userId} status updated to ${newStatus}.` };
  } catch (error) {
    functions.logger.error(`Error updating user ${userId} status by admin ${adminUid}:`, error);

    // Re-throw HttpsError to the client, or wrap other errors
    if (error instanceof functions.https.HttpsError) {
      throw error;
    } else {
      throw new functions.https.HttpsError("internal", "An unexpected error occurred.", error);
    }
  }
});
