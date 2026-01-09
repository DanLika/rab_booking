import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * A scheduled Cloud Function that runs daily to send trial expiration warnings.
 *
 * @remarks
 * - **Schedule:** Runs every 24 hours.
 * - **Query:** Finds users whose trial expires in exactly 7, 3, or 1 day(s).
 * - **Action:** Logs a message and, in the future, will trigger an email and/or
 *   in-app notification to the user.
 * - **Prevention:** It should check a flag (e.g., `warningSent_7_days`) to avoid
 *   sending duplicate notifications.
 */
export const sendTrialExpirationWarning = functions.pubsub.schedule("every 24 hours").onRun(async (context) => {
  functions.logger.info("Running daily check to send trial expiration warnings...");

  const now = new Date();
  const intervals = [1, 3, 7]; // Days before expiration to send a warning

  for (const days of intervals) {
    const warningDate = new Date();
    warningDate.setDate(now.getDate() + days);

    // We create a range for the query to be more robust against function execution time variations.
    const startOfDay = new Date(warningDate.setHours(0, 0, 0, 0));
    const endOfDay = new Date(warningDate.setHours(23, 59, 59, 999));

    const startTimestamp = admin.firestore.Timestamp.fromDate(startOfDay);
    const endTimestamp = admin.firestore.Timestamp.fromDate(endOfDay);
    const warningFlag = `warningSent_${days}_days`;

    try {
      const usersToWarnSnapshot = await db.collection("users")
        .where("accountStatus", "==", "trial")
        .where("trialExpiresAt", ">=", startTimestamp)
        .where("trialExpiresAt", "<=", endTimestamp)
        .where(warningFlag, "==", false) // Check if warning was already sent
        .get();

      if (usersToWarnSnapshot.empty) {
        functions.logger.info(`No users found whose trial expires in ${days} day(s).`);
        continue;
      }

      const batch = db.batch();
      functions.logger.info(`Found ${usersToWarnSnapshot.docs.length} users to warn (${days} day(s) remaining).`);

      usersToWarnSnapshot.forEach((doc) => {
        // --- TODO: Implement actual email/notification sending logic here ---
        // For now, we just log it.
        functions.logger.info(`Sending ${days}-day expiration warning to user ${doc.id}.`);

        // Set a flag to prevent re-sending this specific warning
        const userRef = doc.ref;
        batch.update(userRef, { [warningFlag]: true });
      });

      await batch.commit();

    } catch (error) {
      functions.logger.error(`Error sending ${days}-day expiration warnings:`, error);
    }
  }

  return null;
});
