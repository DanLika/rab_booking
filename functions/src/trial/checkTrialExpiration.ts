import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * A scheduled Cloud Function that runs daily to check for expired trials.
 *
 * @remarks
 * - **Schedule:** Runs every 24 hours. This can be configured in the Google Cloud Console.
 * - **Query:** Finds all users whose `accountStatus` is "trial" and whose
 *   `trialExpiresAt` timestamp is in the past.
 * - **Action:** Updates the `accountStatus` of each expired user to "trial_expired".
 * - **Efficiency:** Uses a batched write to update all expired users in a single operation
 *   per batch, minimizing Firestore write costs.
 */
export const checkTrialExpiration = functions.pubsub.schedule("every 24 hours").onRun(async (context) => {
  functions.logger.info("Running daily check for expired trials...");

  const now = admin.firestore.Timestamp.now();
  const batch = db.batch();
  let expiredUsersCount = 0;

  try {
    const expiredTrialsSnapshot = await db.collection("users")
      .where("accountStatus", "==", "trial")
      .where("trialExpiresAt", "<=", now)
      .get();

    if (expiredTrialsSnapshot.empty) {
      functions.logger.info("No expired trials found.");
      return null;
    }

    expiredUsersCount = expiredTrialsSnapshot.docs.length;
    functions.logger.info(`Found ${expiredUsersCount} users with expired trials.`);

    expiredTrialsSnapshot.forEach((doc) => {
      const userRef = doc.ref;
      batch.update(userRef, {
        accountStatus: "trial_expired",
        statusChangedAt: now,
        statusChangedBy: "system",
        statusChangeReason: "Trial period automatically expired.",
      });
    });

    await batch.commit();

    functions.logger.info(`Successfully updated ${expiredUsersCount} users to 'trial_expired'.`);

    // Optional: Trigger notifications or other follow-up actions here.

    return null;
  } catch (error) {
    functions.logger.error("Error checking for expired trials:", error);
    // Returning null to indicate completion, but the error is logged for monitoring.
    return null;
  }
});
