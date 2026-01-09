# Manual Testing Checklist: Free Trial & Access Control

This checklist provides a structured plan for manually testing the entire free trial user journey to ensure all components work as expected before deployment.

---

## Phase 1: Registration & Trial Initialization

-   [ ] **TRIAL-029.1:** Register a new user account.
-   [ ] **TRIAL-029.2:** Verify in Firestore that the user document is created with:
    -   `accountStatus` set to `"trial"`.
    -   `trialStartDate` set to the current timestamp.
    -   `trialExpiresAt` set to exactly 30 days from the start date.
    -   `warningSent_...` flags set to `false`.
-   [ ] **TRIAL-029.3:** Verify the user can log in and access all dashboard features without restriction.
-   [ ] **TRIAL-029.4:** (UI) Verify the "Trial Indicator" is visible and shows the correct number of days remaining.

## Phase 2: Trial Expiration & Warning System

-   [ ] **TRIAL-029.5:** Manually change a user's `trialExpiresAt` date in Firestore to be 8 days from now. Wait for the daily scheduled function to run. Verify **no** warning email is sent.
-   [ ] **TRIAL-029.6:** Change the `trialExpiresAt` date to be 7 days from now. Trigger or wait for the `sendTrialExpirationWarning` function.
    -   [ ] Verify a "7-day warning" email is sent.
    -   [ ] Verify the `warningSent_7_days` flag in Firestore is now `true`.
-   [ ] **TRIAL-029.7:** Repeat the process for the 3-day and 1-day warnings, verifying the correct email is sent and the corresponding flag is set.
-   [ ] **TRIAL-029.8:** Manually change a user's `trialExpiresAt` date to a timestamp in the past.
    -   [ ] Trigger or wait for the `checkTrialExpiration` function to run.
    -   [ ] Verify the user's `accountStatus` in Firestore is automatically changed to `"trial_expired"`.

## Phase 3: Blocked User Experience

-   [ ] **TRIAL-029.9:** Log in as the user whose trial has expired.
    -   [ ] Verify you are immediately redirected to the "Trial Expired" screen.
    -   [ ] Verify you cannot access any other dashboard routes (e.g., calendar, properties) by manually entering the URL.
-   [ ] **TRIAL-029.10:** Check the public-facing booking widget for this user.
    -   [ ] Verify the widget displays a "Booking Unavailable" message and not the calendar.
-   [ ] **TRIAL-029.11:** (Read-Only) Verify that the user can still view their existing bookings and properties (if this feature is implemented).
-   [ ] **TRIAL-029.12:** Verify the user can still access non-critical pages like "Data Export" and can successfully log out.

## Phase 4: Admin Reactivation

-   [ ] **TRIAL-029.13:** As an admin, manually change the `accountStatus` of the expired user to `"active"` in the Firestore console.
-   [ ] **TRIAL-029.14:** Log in again as the reactivated user.
    -   [ ] Verify you have full access to the dashboard and all features.
    -   [ ] Verify the "Trial Expired" screen is no longer shown.
    -   [ ] (UI) Verify the "Trial Indicator" is no longer visible.
-   [ ] **TRIAL-029.15:** Check the public-facing booking widget again.
    -   [ ] Verify it is now fully functional.

## Phase 5: Security Rules

-   [ ] **TRIAL-029.16:** As a non-admin user, attempt to modify your own `accountStatus` via the browser's developer console (simulating a malicious request). Verify the request is denied by Firestore security rules.
-   [ ] **TRIAL-029.17:** As a non-admin user, attempt to call the `migrateTrialStatus` callable function. Verify the call fails with a "permission-denied" error.
-   [ ] **TRIAL-029.18:** As an admin user, call the `updateUserStatus` callable function. Verify it successfully changes another user's status.
