# Technical Architecture: Free Trial & Access Control

This document details the technical implementation plan for the free trial feature.

## 1. Firestore Schema Changes

-   **TRIAL-003.1: User Document Extension**
    -   The `users/{userId}` document will be updated to include the following fields:

| Field Name | Type | Description |
| :--- | :--- | :--- |
| `accountStatus` | `string` | Manages user access. Enum: `trial`, `trial_expired`, `active`, `suspended`. |
| `trialStartDate` | `timestamp` | Set once at registration. Marks the beginning of the trial. |
| `trialExpiresAt` | `timestamp` | Calculated at registration (`startDate` + 30 days). |
| `statusChangedAt` | `timestamp` | Records when the `accountStatus` was last modified. |
| `statusChangedBy` | `string` | Audits who changed the status. Values: `system` (automated) or an admin's UID. |

```json
// Example users/{userId} document
{
  "email": "test@example.com",
  "displayName": "John Doe",
  // ... existing fields
  "accountStatus": "trial",
  "trialStartDate": "2023-10-27T10:00:00Z",
  "trialExpiresAt": "2023-11-26T10:00:00Z",
  "statusChangedAt": "2023-10-27T10:00:00Z",
  "statusChangedBy": "system"
}
```

## 2. Cloud Functions

-   **TRIAL-003.2: Backend Logic**
    -   **`onUserCreate` Trigger:** A new Cloud Function will trigger on the creation of any new user document in Firestore. This function is responsible for securely initializing the trial fields (`accountStatus`, `trialStartDate`, `trialExpiresAt`, etc.), ensuring the client cannot manipulate these values.
    -   **`checkTrialExpiration` (Scheduled):** A scheduled function (e.g., Pub/Sub cron) will run daily. It will query for all users whose `accountStatus` is `trial` and whose `trialExpiresAt` date has passed. For each user found, it will update their `accountStatus` to `trial_expired`.
    -   **`sendTrialExpirationWarning` (Scheduled):** A second scheduled function will run daily to query for users with trials ending soon (e.g., in 7, 3, or 1 days) and trigger reminder emails and in-app notifications.

## 3. Flutter Client (Owner Dashboard)

-   **TRIAL-003.3: Client-Side Access Control**
    -   **`UserProfileModel`:** The `UserProfileModel` in `lib/shared/models/user_profile_model.dart` will be updated to include the new schema fields.
    -   **`EnhancedAuthProvider`:** This provider will be the central point for managing and checking the user's status. It will fetch the full user profile on login and listen for real-time updates.
    -   **Router Guards:** The `go_router` configuration (`lib/core/config/router_owner.dart`) will be updated with a redirect/guard logic. Before navigating to any protected route, it will check the `accountStatus` from the `EnhancedAuthProvider`. If the status is `trial_expired` or `suspended`, it will redirect the user to a new `TrialExpiredScreen`.
    -   **`TrialIndicatorWidget`:** A new widget will be created to display the remaining trial days, conditionally rendered based on the `accountStatus`.
    -   **UI State:** The UI will be updated to disable editing capabilities if the user is in a read-only state.

## 4. Firestore Security Rules

-   **TRIAL-003.4: Securing Account Status**
    -   The `firestore.rules` file will be updated to enforce strict access control on the new fields.
    -   **User Rules:**
        -   A user can **read** their own `accountStatus` and trial dates.
        -   A user can **NEVER write** to `accountStatus`, `trialStartDate`, `trialExpiresAt`, `statusChangedAt`, or `statusChangedBy`.
    -   **Admin Rules:**
        -   An admin (identified via custom claims, `request.auth.token.isAdmin == true`) can write to any user's `accountStatus` and related fields. This allows for manual activation or suspension.
    -   **System Access:** Cloud Functions will use the Admin SDK, which bypasses security rules, allowing them to perform automated status updates.

```
// firestore.rules example snippet
match /users/{userId} {
  allow read: if request.auth.uid == userId;
  allow write: if request.auth.uid == userId
               // Deny writing to protected fields
               && !("accountStatus" in request.resource.data)
               && !("trialStartDate" in request.resource.data)
               && !("trialExpiresAt" in request.resource.data);

  // Allow admin to update status
  allow update: if request.auth.token.isAdmin == true;
}
```

## 5. Booking Widget Behavior

-   **TRIAL-003.5: Widget Access Control**
    -   To prevent the widget from functioning for expired accounts, the owner's `accountStatus` must be checked.
    -   **Denormalization:** The `ownerAccountStatus` will be denormalized and stored within the `widget_settings/{unitId}` document. A simple Cloud Function will trigger on updates to a user's `accountStatus` and sync the new value to all of that user's `widget_settings` documents.
    -   **Client Logic:** The widget's initial data provider (`WidgetSettingsProvider`) will read this field. If the status is not `trial` or `active`, it will prevent the calendar from loading and instead show a `WidgetUnavailableScreen`.
