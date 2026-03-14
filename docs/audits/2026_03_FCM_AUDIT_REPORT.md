# Monthly FCM & Notification System Audit Report

**Date:** March 2026

## 1. Push Notification Integrity (FCM)
- **`fcm_service.dart`**: Verified. The VAPID key is intentionally hardcoded on line ~18. FCM tokens are securely saved to the user's document path `users/{userId}/data/fcmTokens` in a Map structure. Token refresh logic is integrated and permission requests operate correctly.
- **`fcm_navigation_handler.dart`**: Verified. In-app notifications properly display a floating SnackBar containing a "View" action button. Safe routing is enforced via `ref.read(ownerRouterProvider).go()` rather than relying on `context.go`, circumventing `GoRouter` context discrepancies.
- **`firebase-messaging-sw.js`**: Verified. Background notifications are correctly managed by the Service Worker, which matches Firebase configuration. The click handler filters clients by checking URL validation effectively before sending `NOTIFICATION_CLICK` events.

## 2. Notification Trigger Points
- All critical notification events correctly invoke designated triggers (`sendPendingBookingPushNotification`, `sendPaymentPushNotification`).
- Notifications execute non-blockingly via `.catch()` inside atomic processes like `createBookingAtomic`.
- Push logic in `fcmService.ts` correctly validates token formats and relies on `admin.messaging().sendEachForMulticast()`. It correctly implements an cleanup cycle via `cleanupInvalidTokens` for non-deliverable tokens.

## 3. Email Delivery Reliability
- Robust retry architecture utilizing exponential backoff is validated in `emailRetry.ts` and actively utilized by notification processes to mitigate transient network errors.
- Output validation is applied on the Resend API SDK by `sendEmailWithValidation`, throwing explicit errors instead of failing silently.
- Verified email notification templates export correctly without dead paths.
- Failed communications effectively cascade `logError` with integrations reporting directly to Sentry tracking.
- Owner notification email enforces delivery uniformly by ignoring optional variables on critical channels (`atomicBooking.ts`).

## 4. Notification Preferences
- Checked `notificationPreferences.ts` logic — successfully determines whether to omit push/email notifications correctly by parsing the `masterEnabled` flag alongside subcategory values.

## 5. Sentry Error Monitoring
- Found standard execution for Sentry exception reporting configuration in `sentry.ts`.
- Captures critical faults in Payment flows, ICal operations, and core webhooks natively.
- Flutter utilizes custom error tracking via `LoggingService` that syncs events into Sentry.

## 6. Scheduled Function Health
- Cross-verified all CRON executions present within `index.ts`.
- Active CRONs run on correct cron schedules (e.g. `completeCheckedOutBookings`, `cleanupExpiredPendingBookings`, `cleanupPastDailyPrices`, `monthlyRevenueReport`).
- Time zones configured properly strictly target the `Europe/Zagreb` region.

## Verification Checklist
- [x] All Tests passed successfully via `npm test` within functions folder.
- [x] Service Worker correctly points matching Firebase options payload.
- [x] No orphaned notification templates were identified.

**Status:** ALL SYSTEMS NOMINAL AND WITHIN OPERATIONAL SPECIFICATIONS.
