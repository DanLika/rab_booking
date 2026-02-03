import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {admin} from "../firebase";
import {logInfo, logError, logSuccess} from "../logger";

/**
 * Free Trial Initialization & Profile Creation
 *
 * Cloud Function trigger for new user creation.
 * Initializes the trial period, account status, and profile subdocument for new users.
 *
 * @remarks
 * - **Security:** This logic runs on the server, preventing clients from manipulating
 *   their own trial start/end dates or account status.
 * - **Idempotency:** The `onCreate` trigger ensures this runs only once per user.
 * - **Trial Duration:** 30 days from account creation
 * - **Profile:** Creates users/{userId}/data/profile with initial user data
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
      // Use batch write for atomic updates
      const batch = admin.firestore().batch();

      // 1. Update main user document with trial status
      batch.set(userRef, {
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
      }, {merge: true});

      // 2. Create profile subdocument with initial user data
      // This ensures profile completion percentage is calculated correctly
      const profileRef = userRef.collection("data").doc("profile");
      const firstName = userData?.first_name || "";
      const lastName = userData?.last_name || "";
      const displayName = firstName && lastName ?
        `${firstName} ${lastName}`.trim() :
        (userData?.displayName || "");

      batch.set(profileRef, {
        displayName: displayName,
        emailContact: userData?.email || "",
        phoneE164: userData?.phone || "",
        address: {
          country: "",
          city: "",
          street: "",
          postalCode: "",
        },
        social: {
          website: "",
          facebook: "",
        },
        propertyType: "",
        logoUrl: "",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      await batch.commit();

      logSuccess("[Trial Init] Trial and profile initialized successfully", {
        userId,
        trialExpiresAt: trialExpiresAt.toDate().toISOString(),
        displayName: displayName,
        hasEmail: !!userData?.email,
        hasPhone: !!userData?.phone,
      });
    } catch (error) {
      logError("[Trial Init] Failed to initialize trial/profile", error, {userId});
    }
  }
);
