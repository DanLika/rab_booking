# Cloud Functions Inventory & Cleanup Audit

**Date:** 2026-05-21
**Branch:** main (clean)
**Mode:** READ-ONLY — no deploys, no deletes, no source mutations.
**Projects audited:**
- `bookbed-dev` (development)
- `rab-booking-248fc` (production, legacy ID, alias `production` in `.firebaserc`)

`bookbed-staging` exists but was not in scope (no functions deployed AFAIK; not requested).

---

## 1. Headline numbers

| Metric | DEV (`bookbed-dev`) | PROD (`rab-booking-248fc`) |
|---|---|---|
| Live functions (1st-party) | 57 | 50 |
| Live functions (extensions, `ext-*`) | 0 | 5 |
| **Total live** | **57** | **55** |
| Source-defined deployable | 57 | 57 |
| Healthy (source ↔ live) | 57 | 50 |
| Orphans (live, no source) | 0 | 5 (all Firebase Extensions — see §3) |
| Source-but-not-live | 0 | 7 |

### Region split

| Region | DEV | PROD | Notes |
|---|---|---|---|
| `us-central1` | 35 | 32 | Older + Stripe-related |
| `europe-west1` | 22 | 21 | Newer (auth, trial, push, iCal, admin) |
| `europe-west3` | 0 | 2 | `ext-storage-resize-images-*` only (extension default) |

DEV mirrors PROD for first-party functions (-3 = the 3 funcs from §3 missing on PROD that affect users).

---

## 2. Orphans (LIVE but not in source) — recommended deletes

### `bookbed-dev`

**None.** Every live function on dev has a backing source definition. Healthy.

### `rab-booking-248fc` (prod)

All 5 prod orphans are **Firebase Extensions** (Console-managed, not in `functions/src/`):

| Function | Extension | Action |
|---|---|---|
| `ext-delete-user-data-clearData` | `firebase/delete-user-data@0.1.25` | KEEP — GDPR delete-on-uid trigger |
| `ext-delete-user-data-handleDeletion` | `firebase/delete-user-data@0.1.25` | KEEP |
| `ext-delete-user-data-handleSearch` | `firebase/delete-user-data@0.1.25` | KEEP |
| `ext-storage-resize-images-backfillResizedImages` | `firebase/storage-resize-images@0.2.10` | KEEP — image thumbnail pipeline (europe-west3) |
| `ext-storage-resize-images-generateResizedImage` | `firebase/storage-resize-images@0.2.10` | KEEP (europe-west3) |

Both confirmed via `firebase ext:list --project rab-booking-248fc` (ACTIVE, last updated 2025-10-26).

**`firebase.json` has empty `"extensions": {}`** — extensions are not tracked in repo. **Recommendation:** export to `firebase.json` so they survive a project rebuild and so dev can mirror prod for delete-user-data testing. Run:
```bash
firebase ext:export --project rab-booking-248fc
```

**Verdict:** none of the 5 are deletion candidates. They're not source-defined by design.

---

## 3. Source-but-not-live on PROD — 7 functions

Healthy on dev, missing from prod. Three buckets:

### 3.1 KILL FROM SOURCE — leftover after intentional prod-side delete

| Function | File | Last touched | Reason |
|---|---|---|---|
| `comebackReminder` | `functions/src/scheduledPushNotifications.ts:371-442` | 2026-01-28 | Deployment killed on prod via commit `4111acaf` ("kill comebackReminder cron"); source was never cleaned up. Still deployed on dev. |

**Recommended action:** delete `comebackReminder` block from `scheduledPushNotifications.ts` AND redeploy dev (or `firebase functions:delete comebackReminder --project bookbed-dev --region europe-west1`). Otherwise next prod deploy will resurrect a function the team already decided to kill.

### 3.2 PUSH TO PROD — recent feature, dev-only by oversight

| Function | File | Last touched | Risk |
|---|---|---|---|
| `getBookingByStripeSession` | `functions/src/getBookingByStripeSession.ts` | 2026-05-18 (`9f3d86b4` T11-hotfix-partial) | **HIGH** — Flutter widget calls this on prod (`booking_lookup_provider.dart:102`, `booking_widget_screen.dart:1326`); production call will throw `functions/not-found` and the booking confirmation flow breaks. |
| `sendOwnerEmail` | `functions/src/email/sendOwnerEmail.ts` | 2026-05-20 (`485ee112` widget_secrets split) | **HIGH** — called from `email_notification_service.dart:259` ("Inquiry from widget" path). Prod owners do not receive widget inquiry emails right now. |

**Recommended action:** deploy both to prod ASAP. Both are recent hotfixes / new features that landed on dev but never propagated. Cross-reference §3 of `audit/06-bookings-hotfix-partial.md` for `getBookingByStripeSession`'s migration story.

### 3.3 DECIDE — half-built integrations (Airbnb / Booking.com OAuth)

| Function | File | Last touched | Flutter caller |
|---|---|---|---|
| `initiateAirbnbOAuth` | `functions/src/airbnbApi.ts:42` | 2026-01-28 | `platform_connections_provider.dart:84` |
| `handleAirbnbOAuthCallback` | `functions/src/airbnbApi.ts:108` | 2026-01-28 | (HTTP redirect from Airbnb OAuth) |
| `initiateBookingComOAuth` | `functions/src/bookingComApi.ts:95` | 2026-01-28 | `platform_connections_provider.dart:67` |
| `handleBookingComOAuthCallback` | `functions/src/bookingComApi.ts:163` | 2026-01-28 | (HTTP redirect from Booking.com OAuth) |

Source on dev only, ~4 months stale. UI provider (`platform_connections_provider.dart`) still calls them — on prod the call will fail. Two paths:
- **Ship it:** finish the integration, deploy to prod.
- **Cut it:** delete `airbnbApi.ts` + `bookingComApi.ts`, remove the two `export *` lines from `index.ts:88-91`, remove or feature-flag the UI in `platform_connections_provider.dart`, undeploy from dev.

Cross-reference `audit/06-platform-connections-check.md` if it exists.

---

## 4. Per-function usage table (source-defined, 57 rows)

| Function | Region | Trigger | Usage | DEV | PROD | Verdict |
|---|---|---|---|:-:|:-:|---|
| autoCancelExpiredBookings | us-central1 | onSchedule | SCHEDULED | ✓ | ✓ | KEEP |
| autoCompleteCheckedOutBookings | us-central1 | onSchedule | SCHEDULED | ✓ | ✓ | KEEP |
| biweeklySummary | europe-west1 | onSchedule | SCHEDULED | ✓ | ✓ | KEEP |
| checkEmailVerificationStatus | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| checkInTomorrowReminder | europe-west1 | onSchedule | SCHEDULED | ✓ | ✓ | KEEP |
| checkLoginRateLimit | europe-west1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| checkOutTodayReminder | europe-west1 | onSchedule | SCHEDULED | ✓ | ✓ | KEEP |
| checkPasswordHistory | europe-west1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| checkRegistrationRateLimit | europe-west1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| checkSubdomainAvailability | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| checkTrialExpiration | europe-west1 | onSchedule | SCHEDULED | ✓ | ✓ | KEEP |
| cleanupExpiredStripePendingBookings | us-central1 | onSchedule | SCHEDULED | ✓ | ✓ | KEEP |
| cleanupPastDailyPrices | us-central1 | onSchedule | SCHEDULED | ✓ | ✓ | KEEP |
| **comebackReminder** | europe-west1 | onSchedule | SCHEDULED | ✓ | – | **KILL** (see §3.1) |
| createBookingAtomic | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| createCustomerPortalSession | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| createStripeCheckoutSession | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| createStripeConnectAccount | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| createSubscriptionCheckoutSession | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| deleteUserAccount | europe-west1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| disconnectStripeAccount | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| generateSubdomainFromName | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| **getBookingByStripeSession** | us-central1 | onCall | CLIENT_CALL | ✓ | – | **DEPLOY TO PROD** (see §3.2) |
| getStripeAccountStatus | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| getUnitIcalFeed | us-central1 | onRequest | WEBHOOK_HTTP (public iCal URL) | ✓ | ✓ | KEEP |
| guestCancelBooking | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| **handleAirbnbOAuthCallback** | us-central1 | onRequest | WEBHOOK_HTTP (Airbnb OAuth redirect) | ✓ | – | **DECIDE** (see §3.3) |
| **handleBookingComOAuthCallback** | us-central1 | onRequest | WEBHOOK_HTTP (Booking.com OAuth redirect) | ✓ | – | **DECIDE** (see §3.3) |
| handleStripeWebhook | us-central1 | onRequest | WEBHOOK_HTTP (Stripe → Functions) | ✓ | ✓ | KEEP |
| **initiateAirbnbOAuth** | us-central1 | onCall | CLIENT_CALL | ✓ | – | **DECIDE** (see §3.3) |
| **initiateBookingComOAuth** | us-central1 | onCall | CLIENT_CALL | ✓ | – | **DECIDE** (see §3.3) |
| migrateTrialStatus | europe-west1 | onCall | INTERNAL_HELPER | ✓ | ✓ | KEEP (one-shot migration; safe to leave) |
| monthlyRevenueReport | europe-west1 | onSchedule | SCHEDULED | ✓ | ✓ | KEEP |
| newAppUpdateNotification | europe-west1 | onDocumentUpdated | TRIGGER_FIRESTORE | ✓ | ✓ | KEEP |
| onBookingCreated | us-central1 | onDocumentCreated | TRIGGER_FIRESTORE | ✓ | ✓ | KEEP |
| onBookingStatusChange | us-central1 | onDocumentUpdated | TRIGGER_FIRESTORE | ✓ | ✓ | KEEP |
| onPropertyDeleted | europe-west1 | onDocumentDeleted | TRIGGER_FIRESTORE | ✓ | ✓ | KEEP |
| onUnitDeleted | europe-west1 | onDocumentDeleted | TRIGGER_FIRESTORE | ✓ | ✓ | KEEP |
| onUserCreate | europe-west1 | onDocumentCreated | TRIGGER_FIRESTORE | ✓ | ✓ | KEEP |
| pendingPaymentReminder | europe-west1 | onSchedule | SCHEDULED | ✓ | ✓ | KEEP |
| resendBookingEmail | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| resendGuestBookingEmail | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| revokeAllRefreshTokens | europe-west1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| savePasswordToHistory | europe-west1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| scheduledIcalSync | europe-west1 | onSchedule | SCHEDULED | ✓ | ✓ | KEEP |
| sendCustomEmailToGuest | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| sendEmailVerificationCode | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| **sendOwnerEmail** | us-central1 | onCall | CLIENT_CALL | ✓ | – | **DEPLOY TO PROD** (see §3.2) |
| sendPasswordResetEmail | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| sendTrialExpirationWarning | europe-west1 | onSchedule | SCHEDULED | ✓ | ✓ | KEEP |
| setLifetimeLicense | europe-west1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| setPropertySubdomain | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| syncIcalFeedNow | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| updateBookingTokenExpiration | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| updateUserStatus | europe-west1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| verifyBookingAccess | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |
| verifyEmailCode | us-central1 | onCall | CLIENT_CALL | ✓ | ✓ | KEEP |

Total **KEEP:** 50. Plus 5 ext-* on prod = 55 healthy.
**KILL** (source-only): 1 (`comebackReminder`).
**DEPLOY TO PROD** urgently: 2 (`getBookingByStripeSession`, `sendOwnerEmail`).
**DECIDE** ship-or-cut: 4 (Airbnb + Booking.com OAuth pair).

---

## 5. Flutter callers without backend — dead callsites

| Flutter call | Caller | Status |
|---|---|---|
| `sendSuspiciousActivityAlert` | `lib/core/services/security_events_service.dart:356` | **DEAD** — backing file `functions/src/securityEmail.ts` was deleted in commit `4cb5a391` ("Remove unused securityEmail.ts placeholder"). Flutter call will throw `functions/not-found` on both projects whenever a suspicious-login is detected. Either re-implement the function or remove the Flutter caller. |

Verified: zero source references, zero deploys on either project.

---

## 6. Secrets audit

Defined secrets (via `defineSecret(...)`):

| Secret | Defined in | Used by | Status |
|---|---|---|---|
| `RESEND_API_KEY` | `email/sendOwnerEmail.ts:27` | 10+ functions (atomicBooking, bookingManagement, emailVerification, guestCancelBooking, resendBookingEmail, resendGuestBookingEmail, trial/*, …) | ACTIVE |
| `ICAL_TOKEN_PEPPER` | `icalExport.ts:14` | `getUnitIcalFeed` | ACTIVE — required by `widget-secrets-exfil` branch (see `memory/widget-secrets-exfil-deploy-prereqs.md`); per-env setup before deploy |
| `STRIPE_SECRET_KEY` | `stripe.ts:12` | `handleStripeWebhook`, `createStripeCheckoutSession`, `createCustomerPortalSession`, Connect / Subscription flow | ACTIVE |
| `STRIPE_WEBHOOK_SECRET` | `stripePayment.ts:35` | `handleStripeWebhook` only | ACTIVE |

**No orphaned secrets in source.** `.env` and `.env.rab-booking-248fc` contain only `FROM_EMAIL`, `FROM_NAME`, `WIDGET_URL`, `BOOKING_DOMAIN` (+ default's `ALLOWED_SUBSCRIPTION_PRICE_IDS`); all are referenced in source.

**Note (env layering):** `ALLOWED_SUBSCRIPTION_PRICE_IDS` only in default `.env`, not in `.env.rab-booking-248fc` — by Firebase's per-project layering rules, prod still inherits the default. Verify the values in `.env` are the prod price IDs (currently invisible without reading them). If dev needs different price IDs, add `.env.bookbed-dev`. (Out of scope of this audit, flagged in `memory/widget-secrets-exfil-deploy-prereqs.md`.)

---

## 7. Region consolidation observations

**Split today:** Stripe + booking + iCal export + email in `us-central1`; auth + trial + push + admin + iCal sync in `europe-west1`.

**Latency cost:** EU/HR end-users → us-central1 ≈ +120ms RTT vs europe-west1 for every onCall. Most painful on the booking widget hot path (`createBookingAtomic`, `createStripeCheckoutSession`, `handleStripeWebhook` is server-to-server so doesn't matter).

**Migration cost:** Cloud Functions can't change region in place. You deploy the new region, switch the Flutter client (`FirebaseFunctions.instanceFor(region: ...)`), then delete the old region's function. During transition both exist. Stripe webhook URL would need to be updated in Stripe Dashboard.

**Recommendation:** NOT a quick win. Open a separate workstream for region migration. For now, document the split and don't deploy new functions to `us-central1`.

---

## 8. Recommended actions — prioritized

### P0 — production-affecting bugs (do this week)

1. **Deploy `getBookingByStripeSession` to prod.** Widget booking-confirmation path is broken on prod. (`firebase deploy --only functions:getBookingByStripeSession --project rab-booking-248fc`)
2. **Deploy `sendOwnerEmail` to prod.** Widget inquiry emails are not landing for production owners.
3. **Either remove `sendSuspiciousActivityAlert` caller** from `lib/core/services/security_events_service.dart:356` or restore the backend function. Currently every suspicious-login attempt logs an unhandled cloud-functions error.

### P1 — source-state cleanup

4. **Delete `comebackReminder`** from `functions/src/scheduledPushNotifications.ts:371-442` and undeploy from dev (`firebase functions:delete comebackReminder --project bookbed-dev --region europe-west1`). It was killed on prod 2026-05-18 but never removed from source.
5. **Decide Airbnb / Booking.com OAuth fate.** 4 functions, 4 months stale, Flutter UI still calls `initiate*`. Either finish + deploy to prod, or delete `airbnbApi.ts` + `bookingComApi.ts`, drop the two `export *` from `index.ts:88-91`, remove caller from `platform_connections_provider.dart`, undeploy from dev.

### P2 — hygiene

6. **Track Firebase Extensions in `firebase.json`.** Run `firebase ext:export --project rab-booking-248fc` so `delete-user-data` + `storage-resize-images` are version-controlled. Currently they exist only in the Firebase Console.
7. **Add `.env.bookbed-dev`** with dev-specific `WIDGET_URL`, `BOOKING_DOMAIN`, `FROM_EMAIL`, `FROM_NAME`. Per `.claude/rules/hosting-build.md` this is required to stop dev from sending emails with prod URLs.

### P3 — long-term

8. **Region consolidation roadmap.** Move Stripe / booking hot-path functions from `us-central1` → `europe-west1`. Not a one-shot — needs Stripe webhook URL update and dual-deploy phase.

---

## 9. Risk per recommended delete

| Action | Risk | Mitigation |
|---|---|---|
| Remove `comebackReminder` from source | LOW — already killed on prod | Verify dev deploy doesn't break any pending cron expectations |
| Undeploy `comebackReminder` from dev | LOW — function does nothing user-facing on dev | Just delete via CLI |
| Delete Airbnb / Booking.com OAuth (if cut path chosen) | MEDIUM — Flutter UI references them; need coordinated removal in `platform_connections_provider.dart` | Feature-flag in UI first, deploy, then delete backend, then remove flag |
| Remove `sendSuspiciousActivityAlert` Flutter caller | LOW — function never resolves anyway | Confirm `security_events_service.dart` callers expect best-effort (catch + log) |

No prod webhook removal proposed — `handleStripeWebhook` and `getUnitIcalFeed` are healthy.

---

## 10. Methodology

- Live state: `firebase functions:list --project <p>` for both projects (saved to `/tmp/cf-{dev,prod}-clean.txt`).
- Source state: parsed all 39 `export * from` re-exports in `functions/src/index.ts`, matched against `export const NAME = (onCall|onRequest|onSchedule|onDocument*|onUserCreated)(...)` regex.
- Flutter callers: grep `lib/` for `httpsCallable('<name>')` (multiline-aware).
- Internal helper detection: name referenced in a different source file from its definition.
- Firebase Extensions: `firebase ext:list --project rab-booking-248fc`.
- Secrets: `defineSecret(...)` grep, cross-referenced with `secrets: [...]` usage.
- Recency: `git log -- <file>` for unused candidates.

All raw artifacts under `/tmp/cf-*.{txt,json}` from the audit session.
