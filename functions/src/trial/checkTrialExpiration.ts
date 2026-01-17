import {onSchedule} from "firebase-functions/v2/scheduler";
import {admin, db} from "../firebase";
import {logInfo, logError, logSuccess} from "../logger";
import {sendTrialExpiredEmail} from "../emailService";

/**
 * Check Trial Expiration
 * 
 * Scheduled Cloud Function that runs daily to check for expired trials.
 *
 * @remarks
 * - **Schedule:** Runs every 24 hours at 2:00 AM
 * - **Query:** Finds all users whose `accountStatus` is "trial" and whose
 *   `trialExpiresAt` timestamp is in the past.
 * - **Action:** Updates the `accountStatus` to "trial_expired" and sends email
 * - **Efficiency:** Uses batched writes (max 500 per batch)
 */

const BATCH_SIZE = 500; // Firestore batch limit

export const checkTrialExpiration = onSchedule(
  {
    schedule: "0 2 * * *", // Every day at 2:00 AM
    timeoutSeconds: 540,
    memory: "512MiB",
    region: "europe-west1",
    secrets: ["RESEND_API_KEY"],
  },
  async () => {
    logInfo("[Trial Expiration] Starting daily check for expired trials");

    const now = admin.firestore.Timestamp.now();

    try {
      const expiredTrialsSnapshot = await db
        .collection("users")
        .where("accountStatus", "==", "trial")
        .where("trialExpiresAt", "<=", now)
        .limit(1000) // Process max 1000 at a time
        .get();

      if (expiredTrialsSnapshot.empty) {
        logInfo("[Trial Expiration] No expired trials found");
        return;
      }

      const expiredUsersCount = expiredTrialsSnapshot.docs.length;
      logInfo("[Trial Expiration] Found expired trials", {count: expiredUsersCount});

      // Process in batches
      let processedCount = 0;
      let batch = db.batch();
      let batchCount = 0;

      for (const doc of expiredTrialsSnapshot.docs) {
        const userData = doc.data();
        const userRef = doc.ref;

        // Update status
        batch.update(userRef, {
          accountStatus: "trial_expired",
          statusChangedAt: now,
          statusChangedBy: "system",
          statusChangeReason: "Trial period automatically expired.",
        });

        batchCount++;
        processedCount++;

        // Commit batch when full
        if (batchCount >= BATCH_SIZE) {
          await batch.commit();
          batch = db.batch();
          batchCount = 0;
        }

        // Send expiration email (if not already sent)
        if (!userData.trialExpiredEmailSent && userData.email) {
          try {
            await sendTrialExpiredEmail(
              userData.email,
              userData.name || "User",
              doc.id
            );

            // Mark email as sent
            await userRef.update({trialExpiredEmailSent: true});
          } catch (emailError) {
            logError("[Trial Expiration] Failed to send email", emailError, {
              userId: doc.id,
            });
          }
        }
      }

      // Commit remaining batch
      if (batchCount > 0) {
        await batch.commit();
      }

      logSuccess("[Trial Expiration] Completed", {
        processedCount,
        totalExpired: expiredUsersCount,
      });
    } catch (error) {
      logError("[Trial Expiration] Error checking expired trials", error);
    }
  }
);
