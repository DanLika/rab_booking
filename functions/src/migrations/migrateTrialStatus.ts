import {onCall, HttpsError} from "firebase-functions/v2/https";
import {admin, db} from "../firebase";
import {logInfo, logError, logSuccess} from "../logger";

/**
 * Migration: Trial Status
 *
 * Callable Cloud Function for migrating existing users to the new trial system.
 *
 * @remarks
 * - **Security:** Only callable by admins (checks isAdmin custom claim)
 * - **Idempotency:** Queries for users without `accountStatus` field
 * - **Efficiency:** Uses Firestore batches (max 500 per batch)
 * - **Dry Run Mode:** Simulates migration without writing data
 */

const BATCH_SIZE = 500;
const TRIAL_DURATION_DAYS = 30;

interface MigrationRequest {
  dryRun?: boolean;
  batchSize?: number;
}

interface MigrationResult {
  message: string;
  dryRun: boolean;
  usersFound: number;
  usersInTrial: number;
  usersExpired: number;
  batchesProcessed: number;
}

export const migrateTrialStatus = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 540, // 9 minutes for large migrations
  },
  async (request): Promise<MigrationResult> => {
    // Security check: Only admins can run migrations
    if (!request.auth?.token.isAdmin) {
      throw new HttpsError(
        "permission-denied",
        "Must be an admin to run this migration."
      );
    }

    const adminUid = request.auth.uid;
    const {dryRun = true, batchSize = BATCH_SIZE} = request.data as MigrationRequest;

    logInfo("[Migration] Starting trial status migration", {
      dryRun,
      batchSize,
      adminUid,
    });

    try {
      // Query users without accountStatus field
      // Note: Firestore doesn't support "field doesn't exist" queries directly
      // So we query all users and filter in code
      const usersSnapshot = await db
        .collection("users")
        .limit(5000) // Safety limit
        .get();

      // Filter users that need migration (no accountStatus)
      const usersToMigrate = usersSnapshot.docs.filter((doc) => {
        const data = doc.data();
        return !data.accountStatus;
      });

      if (usersToMigrate.length === 0) {
        logInfo("[Migration] No users need migration");
        return {
          message: "No users found needing migration.",
          dryRun,
          usersFound: 0,
          usersInTrial: 0,
          usersExpired: 0,
          batchesProcessed: 0,
        };
      }

      logInfo("[Migration] Found users to migrate", {
        count: usersToMigrate.length,
      });

      let batch = db.batch();
      let batchCount = 0;
      let batchesProcessed = 0;
      let usersInTrial = 0;
      let usersExpired = 0;
      const now = new Date();

      for (const userDoc of usersToMigrate) {
        const userData = userDoc.data();
        const userId = userDoc.id;

        // Determine trial start date: use 'createdAt' if exists, otherwise now
        const createdAt = userData.createdAt?.toDate?.() || now;
        const trialStartDate = admin.firestore.Timestamp.fromDate(createdAt);

        // Calculate trial end date
        const trialEndDate = new Date(createdAt);
        trialEndDate.setDate(trialEndDate.getDate() + TRIAL_DURATION_DAYS);
        const trialExpiresAt = admin.firestore.Timestamp.fromDate(trialEndDate);

        // Determine if trial is already expired
        const isExpired = trialEndDate < now;
        const accountStatus = isExpired ? "trial_expired" : "trial";

        if (isExpired) {
          usersExpired++;
        } else {
          usersInTrial++;
        }

        const updatePayload = {
          accountStatus,
          trialStartDate,
          trialExpiresAt,
          statusChangedAt: admin.firestore.Timestamp.now(),
          statusChangedBy: "system_migration",
          // Initialize warning flags
          trialWarning7DaysSent: isExpired, // Mark as sent if already expired
          trialWarning3DaysSent: isExpired,
          trialWarning1DaySent: isExpired,
          trialExpiredEmailSent: false, // Don't auto-send expired email for migrated users
        };

        if (dryRun) {
          logInfo("[Migration] [Dry Run] Would migrate user", {
            userId,
            accountStatus,
            trialExpiresAt: trialExpiresAt.toDate().toISOString(),
          });
        } else {
          batch.set(userDoc.ref, updatePayload, {merge: true});
          batchCount++;

          // Commit batch when full
          if (batchCount >= batchSize) {
            await batch.commit();
            logInfo("[Migration] Committed batch", {batchCount});
            batch = db.batch();
            batchCount = 0;
            batchesProcessed++;
          }
        }
      }

      // Commit remaining batch
      if (!dryRun && batchCount > 0) {
        await batch.commit();
        batchesProcessed++;
      }

      const message = `${dryRun ? "[Dry Run] " : ""}Migration complete. ` +
        `Processed ${usersToMigrate.length} users (${usersInTrial} in trial, ${usersExpired} expired).`;

      logSuccess("[Migration] Completed", {
        dryRun,
        usersFound: usersToMigrate.length,
        usersInTrial,
        usersExpired,
        batchesProcessed,
      });

      return {
        message,
        dryRun,
        usersFound: usersToMigrate.length,
        usersInTrial,
        usersExpired,
        batchesProcessed,
      };
    } catch (error) {
      logError("[Migration] Error during migration", error);
      throw new HttpsError("internal", "Migration failed. Check logs for details.");
    }
  }
);
