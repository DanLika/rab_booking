import {onSchedule} from "firebase-functions/v2/scheduler";
import {admin, db} from "../firebase";
import {logInfo, logError, logSuccess} from "../logger";
import {sendTrialExpiringEmail} from "../emailService";
import {sendTrialExpiringPushNotification} from "../fcmService";
import {sendTrialExpiringSmsNotification} from "../smsService";
import {captureException, captureMessage, addBreadcrumb} from "../sentry";

/**
 * Send Trial Expiration Warnings
 *
 * Scheduled Cloud Function that runs daily to send trial expiration warnings.
 *
 * @remarks
 * - **Schedule:** Runs every day at 9:00 AM (good time for email open rates)
 * - **Query:** Finds users whose trial expires in exactly 7, 3, or 1 day(s)
 * - **Action:** Sends warning email and marks flag to prevent duplicates
 * - **Prevention:** Checks flags to avoid sending duplicate notifications
 */

// Warning intervals (days before expiration)
const WARNING_INTERVALS = [7, 3, 1];

export const sendTrialExpirationWarning = onSchedule(
  {
    schedule: "0 9 * * *", // Every day at 9:00 AM
    timeoutSeconds: 540,
    memory: "512MiB",
    region: "europe-west1",
    secrets: ["RESEND_API_KEY"],
  },
  async () => {
    logInfo("[Trial Warning] Starting daily trial expiration warning check");

    const now = new Date();

    for (const days of WARNING_INTERVALS) {
      await sendWarningsForInterval(now, days);
    }

    logSuccess("[Trial Warning] Completed all warning checks");
  }
);

/**
 * Send warnings for a specific interval (e.g., 7 days before expiration)
 */
async function sendWarningsForInterval(now: Date, days: number): Promise<void> {
  // Calculate the target date range
  const targetDate = new Date(now);
  targetDate.setDate(now.getDate() + days);

  // Create a range for the query (entire day)
  const startOfDay = new Date(targetDate);
  startOfDay.setHours(0, 0, 0, 0);

  const endOfDay = new Date(targetDate);
  endOfDay.setHours(23, 59, 59, 999);

  const startTimestamp = admin.firestore.Timestamp.fromDate(startOfDay);
  const endTimestamp = admin.firestore.Timestamp.fromDate(endOfDay);

  // Flag field name based on days
  const warningFlag = `trialWarning${days}Day${days === 1 ? "" : "s"}Sent`;

  try {
    const usersToWarnSnapshot = await db
      .collection("users")
      .where("accountStatus", "==", "trial")
      .where("trialExpiresAt", ">=", startTimestamp)
      .where("trialExpiresAt", "<=", endTimestamp)
      .where(warningFlag, "==", false)
      .limit(500)
      .get();

    if (usersToWarnSnapshot.empty) {
      logInfo(`[Trial Warning] No users expiring in ${days} day(s)`);
      return;
    }

    // Safety net: skip users whose accountType has been upgraded (e.g., premium, lifetime)
    // This handles the case where admin changed accountType but accountStatus wasn't synced
    const eligibleDocs = usersToWarnSnapshot.docs.filter((doc) => {
      const accountType = doc.data().accountType;
      return !accountType || accountType === "trial";
    });

    if (eligibleDocs.length === 0) {
      logInfo(`[Trial Warning] No eligible users expiring in ${days} day(s) (all upgraded)`);
      return;
    }

    if (eligibleDocs.length < usersToWarnSnapshot.docs.length) {
      logInfo("[Trial Warning] Skipped upgraded users", {
        days,
        total: usersToWarnSnapshot.docs.length,
        skipped: usersToWarnSnapshot.docs.length - eligibleDocs.length,
      });
    }

    logInfo("[Trial Warning] Found users to warn", {
      days,
      count: eligibleDocs.length,
    });

    const batch = db.batch();
    let emailsSent = 0;
    let pushSent = 0;

    for (const doc of eligibleDocs) {
      const userData = doc.data();
      const userRef = doc.ref;

      // Send warning email
      if (userData.email) {
        try {
          await sendTrialExpiringEmail(
            userData.email,
            userData.name || "User",
            days,
            doc.id
          );
          emailsSent++;
        } catch (emailError) {
          logError("[Trial Warning] Failed to send email", emailError, {
            userId: doc.id,
            days,
          });
          captureException(emailError, {
            userId: doc.id,
            days,
            context: "sendTrialExpiringEmail",
          });
        }
      }

      // Send push notification (non-blocking)
      try {
        const sent = await sendTrialExpiringPushNotification(doc.id, days);
        if (sent) pushSent++;
      } catch (pushError) {
        logError("[Trial Warning] Failed to send push notification", pushError, {
          userId: doc.id,
          days,
        });
        captureException(pushError, {
          userId: doc.id,
          days,
          context: "sendTrialExpiringPushNotification",
        });
      }

      // Send SMS notification (non-blocking)
      try {
        await sendTrialExpiringSmsNotification(doc.id, days);
      } catch (smsError) {
        logError("[Trial Warning] Failed to send SMS notification", smsError, {
          userId: doc.id,
          days,
        });
        captureException(smsError, {
          userId: doc.id,
          days,
          context: "sendTrialExpiringSmsNotification",
        });
      }

      // Mark warning as sent (even if email/push failed, to prevent spam)
      batch.update(userRef, {[warningFlag]: true});
    }

    await batch.commit();

    logSuccess(`[Trial Warning] Sent ${days}-day warnings`, {
      emailsSent,
      pushSent,
      totalUsers: eligibleDocs.length,
    });

    // Track successful batch in Sentry for monitoring
    addBreadcrumb(`Trial warning batch completed: ${days} days`, "trial", {
      emailsSent,
      pushSent,
      totalUsers: eligibleDocs.length,
    });

    // Alert if push delivery rate is low (< 50%)
    const pushDeliveryRate = eligibleDocs.length > 0 ?
      pushSent / eligibleDocs.length :
      1;
    if (pushDeliveryRate < 0.5 && eligibleDocs.length >= 5) {
      captureMessage("[Trial Warning] Low push notification delivery rate", "warning", {
        days,
        pushSent,
        totalUsers: usersToWarnSnapshot.docs.length,
        deliveryRate: `${(pushDeliveryRate * 100).toFixed(1)}%`,
      });
    }
  } catch (error) {
    logError(`[Trial Warning] Error sending ${days}-day warnings`, error);
    captureException(error, {
      days,
      context: "sendWarningsForInterval",
    });
  }
}
