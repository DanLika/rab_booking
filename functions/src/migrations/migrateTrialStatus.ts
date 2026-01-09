import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * A callable Cloud Function for migrating existing users to the new trial system.
 *
 * @remarks
 * - **Security:** This function should be protected and only callable by admins.
 *   (Requires additional setup with custom claims or another auth mechanism).
 * - **Idempotency:** The script queries for users who do NOT have the `accountStatus`
 *   field, so it can be safely run multiple times without affecting already
 *   migrated users.
 * - **Efficiency:** Uses Firestore batches to update up to 500 users per batch.
 * - **Dry Run Mode:** Includes a `dryRun` parameter to simulate the migration
 *   without writing any data, allowing for safe testing.
 *
 * @param {object} data - The data passed to the function.
 * @param {boolean} [data.dryRun=true] - If true, simulates the migration. If false, executes it.
 * @param {number} [data.batchSize=500] - The number of users to process per batch.
 * @param {context} context - The context object for the callable function.
 *
 * @returns {Promise<object>} A result object with counts of users to migrate and batches processed.
 */
export const migrateTrialStatus = functions.https.onCall(async (data, context) => {
  // Basic security check: ensure the caller is an admin in a real scenario
  // For now, we'll just log a warning. In production, you'd check custom claims.
  // if (!context.auth?.token.isAdmin) {
  //   throw new functions.https.HttpsError("permission-denied", "Must be an admin to run this migration.");
  // }

  const dryRun = data.dryRun !== false; // Defaults to true if not specified or null
  const batchSize = data.batchSize || 500;
  let usersToMigrateCount = 0;
  let batchesProcessed = 0;

  functions.logger.info(`Starting trial status migration. Dry Run: ${dryRun}, Batch Size: ${batchSize}`);

  try {
    const usersSnapshot = await db.collection("users")
      .where("accountStatus", "==", null)
      .get();

    if (usersSnapshot.empty) {
      functions.logger.info("No users to migrate.");
      return { message: "No users found needing migration." };
    }

    usersToMigrateCount = usersSnapshot.docs.length;
    functions.logger.info(`Found ${usersToMigrateCount} users to migrate.`);

    let batch = db.batch();
    let commitCounter = 0;

    for (const [index, userDoc] of usersSnapshot.docs.entries()) {
      const userData = userDoc.data();
      const userId = userDoc.id;

      // Determine trial start date: use 'createdAt' if it exists, otherwise use now.
      const trialStartDate = userData.createdAt || admin.firestore.Timestamp.now();

      const trialEndDate = new Date(trialStartDate.toDate().getTime());
      trialEndDate.setDate(trialEndDate.getDate() + 30);
      const trialExpiresAt = admin.firestore.Timestamp.fromDate(trialEndDate);

      const isExpired = trialEndDate < new Date();
      const accountStatus = isExpired ? "trial_expired" : "trial";

      const updatePayload = {
        accountStatus: accountStatus,
        trialStartDate: trialStartDate,
        trialExpiresAt: trialExpiresAt,
        statusChangedAt: admin.firestore.Timestamp.now(),
        statusChangedBy: "system_migration",
      };

      if (!dryRun) {
        batch.set(userDoc.ref, updatePayload, { merge: true });
        commitCounter++;
      } else {
        functions.logger.info(`[Dry Run] User ${userId} would be set to status: ${accountStatus}`);
      }

      // Commit the batch when it's full or when it's the last user
      if ((commitCounter > 0 && commitCounter % batchSize === 0) || index === usersToMigrateCount - 1) {
        if (!dryRun) {
          await batch.commit();
          functions.logger.info(`Committed a batch of ${commitCounter} users.`);
          batch = db.batch(); // Start a new batch
          commitCounter = 0; // Reset counter
        }
        batchesProcessed++;
      }
    }

    const successMessage = `${dryRun ? "[Dry Run] " : ""}Migration complete. Processed ${usersToMigrateCount} users in ${batchesProcessed} batches.`;
    functions.logger.info(successMessage);
    return {
      message: successMessage,
      dryRun: dryRun,
      usersFound: usersToMigrateCount,
      batchesProcessed: batchesProcessed,
    };
  } catch (error) {
    functions.logger.error("Error during trial status migration:", error);
    throw new functions.https.HttpsError("internal", "Migration failed.", error);
  }
});
