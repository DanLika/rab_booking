# Admin Guide: Manual User Status Management

This guide outlines the process for administrators to manually manage user account statuses (`trial`, `active`, `suspended`) directly within the Firebase Firestore console.

---

## 1. Identifying an Admin

For security, the ability to modify a user's `accountStatus` is restricted. A user is considered an **Admin** if their Firebase Authentication token has a custom claim `isAdmin` set to `true`.

-   **Requirement:** An admin must have this custom claim. Without it, Firestore security rules will deny any attempt to change another user's status.
-   **Setting Claims:** Custom claims are typically set via a trusted server process (e.g., a dedicated Cloud Function) and not from the client.

---

## 2. How to Manually Change a User's Account Status

This process is used to activate a user after their trial expires or to suspend a user's account.

### Step 1: Navigate to the Firestore Console

1.  Open your project in the [Firebase Console](https://console.firebase.google.com/).
2.  From the left-hand menu, select **Build > Firestore Database**.

### Step 2: Locate the User's Document

1.  In the Firestore data explorer, you will see your collections. Find and click on the `users` collection.
2.  You need to find the specific user's document. You can usually identify it by the user's UID. If you only have their email address, you may need to look them up in the **Authentication** tab first to find their UID.
3.  Click on the document ID (the UID) to open its fields for editing.

### Step 3: Edit the `accountStatus` Field

1.  Once the document is open, you will see a list of fields. Find the `accountStatus` field.
2.  Click the **pencil icon** to edit its value.
3.  Change the value to one of the following:
    -   `active`: To grant a user full access after their trial has expired.
    -   `suspended`: To manually block a problematic user.
    -   `trial`: To revert a user to the trial state (use with caution).
4.  Click the **Update** button to save the change.

### Step 4: Update Audit Fields (Recommended)

For good record-keeping, it is crucial to update the audit trail fields at the same time.

1.  **`statusChangedAt`**:
    -   Click the pencil icon to edit.
    -   Change the type to `Timestamp`.
    -   Set it to the current date and time.
2.  **`statusChangedBy`**:
    -   Click the pencil icon to edit.
    -   Change the value to your own Admin UID. This creates a clear record of who made the change.

3.  Click **Update** to save all changes.

### Step 5: Verification

-   The user's access rights will change almost immediately. The next time their client application reads their user profile from Firestore, the new status will be applied.
-   If the user is currently online, they may need to refresh their app or log out and log back in for the change to take full effect, depending on how the client-side state management is configured.

---

## Common Scenarios & Actions

| Scenario                               | Action                                                                                             |
| :------------------------------------- | :------------------------------------------------------------------------------------------------- |
| A user's trial has expired.            | Change `accountStatus` from `trial_expired` to `active`.                                           |
| A user is violating terms of service.  | Change `accountStatus` to `suspended`.                                                             |
| A suspended user has resolved issues.  | Change `accountStatus` from `suspended` to `active`.                                               |
| A user was activated by mistake.       | Change `accountStatus` back to `trial_expired` or `trial` depending on the situation.              |
