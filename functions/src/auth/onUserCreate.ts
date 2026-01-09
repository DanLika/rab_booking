import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Cloud Function trigger for new user creation.
 *
 * This function listens for the creation of a new document in the `users/{userId}`
 * collection and initializes the trial period and account status for the new user.
 *
 * @remarks
 * - **Security:** This logic runs on the server, preventing clients from manipulating
 *   their own trial start/end dates or account status.
 * - **Idempotency:** The `onCreate` trigger ensures this runs only once per user.
 */
export const onUserCreate = functions.firestore
  .document("users/{userId}")
  .onCreate(async (snap, context) => {
    const { userId } = context.params;
    const userRef = snap.ref;

    functions.logger.info(`New user created with ID: ${userId}. Initializing trial period.`);

    const now = new Date();
    const trialStartDate = admin.firestore.Timestamp.fromDate(now);

    // Calculate trial expiration date (30 days from now)
    const trialEndDate = new Date();
    trialEndDate.setDate(now.getDate() + 30);
    const trialExpiresAt = admin.firestore.Timestamp.fromDate(trialEndDate);

    try {
      await userRef.set({
        accountStatus: "trial",
        trialStartDate: trialStartDate,
        trialExpiresAt: trialExpiresAt,
        statusChangedAt: trialStartDate,
        statusChangedBy: "system",
        createdAt: trialStartDate, // Add createdAt for future reference/migrations
      }, { merge: true }); // Use merge:true to avoid overwriting other fields if any

      functions.logger.info(`Successfully initialized trial for user: ${userId}`);
    } catch (error) {
      functions.logger.error(`Error initializing trial for user ${userId}:`, error);
      // Optional: Add more robust error handling, like sending an alert
    }
  });
