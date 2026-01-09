# Free Trial Feature Implementation Guide

This document describes the free trial feature implementation and what needs to be done to fully integrate it.

## Overview

The free trial system provides:
- 30-day free trial for new users
- Automatic trial expiration with email notifications
- Warning emails at 7, 3, and 1 day before expiration
- Admin tools for managing user status
- Migration script for existing users

## Components

### Cloud Functions (Firebase Functions v2)

| Function | File | Description |
|----------|------|-------------|
| `onUserCreate` | `functions/src/auth/onUserCreate.ts` | Firestore trigger - initializes trial for new users |
| `checkTrialExpiration` | `functions/src/trial/checkTrialExpiration.ts` | Daily scheduled job - marks expired trials |
| `sendTrialExpirationWarning` | `functions/src/trial/sendTrialExpirationWarning.ts` | Daily scheduled job - sends warning emails |
| `updateUserStatus` | `functions/src/admin/updateUserStatus.ts` | Admin callable function - change user status |
| `migrateTrialStatus` | `functions/src/migrations/migrateTrialStatus.ts` | One-time migration for existing users |

### Email Templates

| Email | Function | Description |
|-------|----------|-------------|
| Trial Expiring | `sendTrialExpiringEmail()` | Warning email (7, 3, 1 days before) |
| Trial Expired | `sendTrialExpiredEmail()` | Notification when trial ends |

### Flutter Components

| Component | File | Description |
|-----------|------|-------------|
| `TrialStatus` model | `lib/features/subscription/models/trial_status.dart` | Data model for trial status |
| `trialStatusProvider` | `lib/features/subscription/providers/trial_status_provider.dart` | Riverpod provider |
| `TrialBanner` | `lib/features/subscription/widgets/trial_banner.dart` | Warning banner widget |
| `TrialIndicator` | `lib/features/subscription/widgets/trial_banner.dart` | Compact status indicator |
| `SubscriptionScreen` | `lib/features/subscription/screens/subscription_screen.dart` | Subscription management UI |

## Firestore Schema

### User Document Fields

Add these fields to `users/{userId}` documents:

```javascript
{
  // Account status
  accountStatus: "trial" | "active" | "trial_expired" | "suspended",
  trialStartDate: Timestamp,
  trialExpiresAt: Timestamp,
  statusChangedAt: Timestamp,
  statusChangedBy: string, // "system" or admin UID
  statusChangeReason: string | null,
  previousStatus: string | null,
  
  // Warning flags (prevent duplicate emails)
  trialWarning7DaysSent: boolean,
  trialWarning3DaysSent: boolean,
  trialWarning1DaySent: boolean,
  trialExpiredEmailSent: boolean,
}
```

## Firestore Security Rules

Add these rules to `firestore.rules`:

```javascript
// In users/{userId} rules:
match /users/{userId} {
  // Allow read for authenticated user (their own document)
  allow read: if request.auth != null && request.auth.uid == userId;
  
  // Allow write for authenticated user, but protect trial fields
  allow write: if request.auth != null && request.auth.uid == userId
    && !request.resource.data.diff(resource.data).affectedKeys()
        .hasAny(['accountStatus', 'trialStartDate', 'trialExpiresAt', 
                 'statusChangedAt', 'statusChangedBy', 'statusChangeReason',
                 'trialWarning7DaysSent', 'trialWarning3DaysSent', 
                 'trialWarning1DaySent', 'trialExpiredEmailSent']);
  
  // Admin can update any field
  allow write: if request.auth != null && request.auth.token.isAdmin == true;
}
```

## Firestore Indexes

Add these composite indexes:

```json
{
  "collectionGroup": "users",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "accountStatus", "order": "ASCENDING" },
    { "fieldPath": "trialExpiresAt", "order": "ASCENDING" }
  ]
}
```

## Integration Steps

### 1. Deploy Cloud Functions

```bash
cd functions
npm run build
firebase deploy --only functions:onUserCreate,functions:checkTrialExpiration,functions:sendTrialExpirationWarning,functions:updateUserStatus,functions:migrateTrialStatus
```

### 2. Update Firestore Rules

Add the security rules above to `firestore.rules` and deploy:

```bash
firebase deploy --only firestore:rules
```

### 3. Create Firestore Indexes

Add the indexes to `firestore.indexes.json` and deploy:

```bash
firebase deploy --only firestore:indexes
```

### 4. Run Migration (One-time)

Call the migration function from admin panel or Firebase console:

```javascript
// First do a dry run
const result = await firebase.functions().httpsCallable('migrateTrialStatus')({
  dryRun: true
});
console.log(result.data);

// Then run for real
const result = await firebase.functions().httpsCallable('migrateTrialStatus')({
  dryRun: false
});
```

### 5. Integrate Flutter Components

#### Add TrialBanner to main layout

```dart
// In your main scaffold or app shell:
Column(
  children: [
    const TrialBanner(), // Add at top
    Expanded(child: yourContent),
  ],
)
```

#### Add TrialIndicator to drawer/app bar

```dart
// In drawer header or app bar:
Row(
  children: [
    Text('Welcome, $userName'),
    const Spacer(),
    const TrialIndicator(),
  ],
)
```

#### Add route for subscription screen

```dart
// In your router:
GoRoute(
  path: '/subscription',
  builder: (context, state) => const SubscriptionScreen(),
),
```

### 6. Implement Access Control

Use `hasFullAccessProvider` to restrict features:

```dart
// In a widget:
final hasAccess = ref.watch(hasFullAccessProvider);

if (!hasAccess) {
  return const TrialExpiredOverlay();
}

return YourFeatureWidget();
```

## TODO: Payment Integration

When ready to implement payments:

1. Set up Stripe subscription products
2. Implement Stripe checkout in `SubscriptionScreen`
3. Create webhook handler for subscription events
4. Update `accountStatus` to "active" on successful payment
5. Handle subscription cancellation/expiration

## Testing

### Test Trial Initialization

1. Create a new user account
2. Verify `accountStatus` is "trial"
3. Verify `trialExpiresAt` is 30 days from now

### Test Expiration Check

1. Manually set a user's `trialExpiresAt` to past date
2. Trigger `checkTrialExpiration` function
3. Verify `accountStatus` changed to "trial_expired"

### Test Warning Emails

1. Set a user's `trialExpiresAt` to 7 days from now
2. Trigger `sendTrialExpirationWarning` function
3. Verify email was sent and flag was set

### Test Admin Status Update

1. Call `updateUserStatus` with admin credentials
2. Verify status was updated
3. Verify audit fields were set
