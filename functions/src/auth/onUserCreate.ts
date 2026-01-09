import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {admin} from "../firebase";
import {logInfo, logError, logSuccess} from "../logger";

/**
 * Free Trial Initialization
 * 
 * Cloud Function trigger for new user creation.
 * Initializes the trial period and account status for new users.
 *
 * @remarks
 * - **Security:** This logic runs on the server, preventing clients from manipulating
 *   their own trial start/end dates or account status.
 * - **Idempotency:** The `onCreate` trigger ensures this runs only once per user.
 * - **Trial Duration:** 30 days from account creation
 */

// Trial duration in days (configurable)
const TRIAL_DURATION_DAYS = 30;

export const onUserCreate = onDocumentCreated(
  {
    document: "users/{userId}",
    region: "europe-west1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logError("[Trial Init] No data in snapshot", null);
      return;
    }

    const userId = event.params.userId;
    const userRef = snapshot.ref;
    const userData = snapshot.data();

    // Skip if trial already initialized (idempotency check)
    if (userData?.accountStatus) {
      logInfo("[Trial Init] User already has accountStatus, skipping", {userId});
      return;
    }

    logInfo("[Trial Init] Initializing trial for new user", {userId});

    const now = new Date();
    const trialStartDate = admin.firestore.Timestamp.fromDate(now);

    // Calculate trial expiration date
    const trialEndDate = new Date();
    trialEndDate.setDate(now.getDate() + TRIAL_DURATION_DAYS);
    const trialExpiresAt = admin.firestore.Timestamp.fromDate(trialEndDate);

    try {
      await userRef.set({
        // Account status
        accountStatus: "trial",
        trialStartDate: trialStartDate,
        trialExpiresAt: trialExpiresAt,
        statusChangedAt: trialStartDate,
        statusChangedBy: "system",
        
        // Warning flags (to prevent duplicate emails)
        trialWarning7DaysSent: false,
        trialWarning3DaysSent: false,
        trialWarning1DaySent: false,
        trialExpiredEmailSent: false,
      }, {merge: true}); // Use merge:true to avoid overwriting other fields

      logSuccess("[Trial Init] Trial initialized successfully", {
        userId,
        trialExpiresAt: trialExpiresAt.toDate().toISOString(),
      });
    } catch (error) {
      logError("[Trial Init] Failed to initialize trial", error, {userId});
    }
  }
);
