# PROD Contamination Deep Check — Wave 0 iOS Testing Fallout

**Date:** 2026-05-21
**Branch:** `main` @ `c72034c0`
**Status:** READ-ONLY audit. No data modified. No Stripe calls dissolved.
**Severity:** **HIGH** — confirmed LIVE Stripe Connect account in PROD tied to a test owner. Likely safe (account is `trial` state, no bookings, no transactions) but requires manual cleanup before audit/14 cleanup script can run.

---

## Headline finding

PROD Firestore user `qoN6aykKwqZI4n9REgqXfEFG8KM2` (Wave 0 test owner `wave0-smoke-202605181440@bookbed.test`) has:

```
stripe_account_id:    "acct_1TYSMdPWhhVc6lN0"
stripe_connected_at:  Timestamp(seconds=1779115314, nanos=807000000)
                       → 2026-05-18 16:01:54 UTC
```

This is a connected Stripe Express account ID associated with the BookBed PROD Stripe platform (rab-booking-248fc). Stripe Cloud Function `createStripeConnectAccount` reads its API key from GCP Secret Manager (`STRIPE_SECRET_KEY` v4), and per `.claude/rules/stripe.md` PROD uses LIVE mode. Therefore the Connect account is — to the best of available evidence without direct Secret Manager access — a **live Stripe Connect Express account**.

There are no bookings, payment intents, payouts, or transfers tied to it via Firestore (no `bookings`, `subscriptions`, or `audit_logs` reference the user). So if the Connect onboarding never finished, it's just an orphan KYC record. If it DID finish and link real banking details, it's a more serious cleanup item.

---

## Pre-flight + scope

```
git branch --show-current  → main
git status --short          → clean
git log -1                  → c72034c0
```

UID confirmed from `audit/14-deploy-scripts-mismatch.md:157` and `audit/07-ios-smoke-test.md:110`. No re-discovery needed.

ADC token works for PROD Firestore + Auth reads. Stripe Connect direct query via Stripe CLI blocked (local CLI auth = different platform, `acct_1T6Y41Q82cgbc9Mn` CallidusOS sandbox). GCP Secret Manager CLI access blocked, so the live-vs-test mode of `STRIPE_SECRET_KEY` cannot be verified programmatically from this session.

---

## TASK 1 — User doc + Stripe Connect fields

Queried `users/qoN6aykKwqZI4n9REgqXfEFG8KM2` in PROD.

### Stripe fields (key finding)

| Field | Value |
|---|---|
| `stripe_account_id` | **`acct_1TYSMdPWhhVc6lN0`** |
| `stripe_connected_at` | Timestamp 1779115314.807s = 2026-05-18 16:01:54 UTC |
| `stripe_customer_id` | not present |
| `stripe_connect_status` | not present (other code paths may store it on the account itself) |

### Other relevant fields

| Field | Value |
|---|---|
| `accountStatus` | `trial` |
| `accountType` | `trial` |
| `role` | `owner` |
| `email` | `wave0-smoke-202605181440@bookbed.test` |
| `displayName` | `Wave Zero Tester` |
| `createdAt` | 2026-05-18T12:49:40.845Z |
| `lastLoginAt` | present (timestamp not extracted) |
| `emailVerified` | `false` |
| `profileCompleted` | (boolean, value not surfaced — exists) |
| `onboardingCompleted` | (boolean, value not surfaced — exists) |
| `trialExpiresAt`, `trialStartDate`, `trialWarning{1,3,7}DaysSent`, `trialExpiredEmailSent` | trial-management fields populated by daily CF |
| `statusChangedAt`, `statusChangedBy` | likely admin trial-management trail |
| `recentSecurityEvents` | array exists (not dumped — likely login events) |

### Secondary stripe locations checked

- `stripe_accounts` top-level collection where `owner_id == TEST_UID` → **0 docs**
- `users/{TEST_UID}/stripe` subcollection → **0 docs**

So the Connect ID is stored ONLY on the user doc. Standard Cloud Functions pattern for this codebase.

---

## TASK 2 — Stripe CLI / Dashboard verify

Could **not** complete programmatically:

```
$ stripe accounts retrieve --stripe-account=acct_1TYSMdPWhhVc6lN0 --live
You provided the project name "sandbox" (either via the "--project-name" flag …),
but no config for that project was found.
```

Local Stripe CLI is logged into `CallidusOS™ Limited sandbox` (`acct_1T6Y41Q82cgbc9Mn`), a different Stripe platform. The connected-account `acct_1TYSMdPWhhVc6lN0` lives under the BookBed prod platform, accessible only with BookBed's live secret key.

### Mode determination (best-effort)

- `functions.config()` legacy output shows `stripe.secret_key = sk_test_51SIsGk...` — this is the **deprecated** functions.config() value. The 2026-03 Cloud Run shutdown deadline means this is no longer the source of truth.
- `gcloud functions describe createStripeConnectAccount --region=us-central1 --v2` shows `secretEnvironmentVariables: STRIPE_SECRET_KEY` from Secret Manager (`projectId=rab-booking-248fc, secret=STRIPE_SECRET_KEY, version=4`).
- Secret Manager value blocked from CLI in this session.
- `.claude/rules/stripe.md` (path-scoped on `functions/src/stripe*.ts`) explicitly says "**LIVE MODE**" for production.

**Conclusion:** with current evidence, assume `acct_1TYSMdPWhhVc6lN0` is a **LIVE Stripe Connect Express account**. If user later confirms PROD STRIPE_SECRET_KEY is in fact `sk_test_…`, severity drops to LOW.

### Manual verification (USER MUST RUN)

1. Open https://dashboard.stripe.com/connect/accounts (BookBed live mode, top-right account switcher).
2. Search for `acct_1TYSMdPWhhVc6lN0` OR `wave0-smoke-202605181440@bookbed.test` OR `Wave Zero Tester`.
3. If found, capture:
   - Status: pending verification / restricted / complete / rejected
   - Country, business type
   - External account (bank/debit card) attached? — critical
   - Capabilities enabled: card_payments, transfers
   - Created date (should match 2026-05-18 16:01 UTC if same Connect account)
4. If account is in `complete` state with banking attached → **dissolve via dashboard** before audit/14 user cleanup runs.
5. If pending verification with no banking → safe to dissolve via Connect API `accounts.delete` once `STRIPE_SECRET_KEY` is in hand.

---

## TASK 3 — FCM / device tokens

Queried three possible storage patterns in PROD:

| Location | Count |
|---|---|
| `users/{TEST_UID}/devices` subcollection | **0** |
| `fcm_tokens` collection where `user_id == TEST_UID` | **0** |
| FCM-shaped fields on user doc (`fcm`, `token` substring match) | **none** |

### Interpretation

The iOS app DID call `FirebaseMessaging.getToken()` during Wave 0 (per audit/07-ios-smoke-summary.md), which would have generated APNs token + FCM token tied to the iOS device's bundle ID `io.bookbed.app` AND PROD project `rab-booking-248fc`. But the app **did not persist** the token to Firestore on PROD — either because the persist path runs only under specific conditions, or because the session terminated before the FCM token write completed.

The actual FCM device token persists in:
- iOS local storage (UserDefaults / Keychain on test device) — outside our scope
- Firebase Cloud Messaging backend (token registry mapping device → project) — accessible only via Admin SDK's `messaging().send(token,...)` or via the FCM HTTP v1 API

There's no way to query FCM's backend for tokens by user UID. So if there is a stale prod-project FCM token attached to that simulator install, it would just produce 404s on the next push attempt and naturally expire. **No actionable artifact in Firestore.**

---

## TASK 4 — Google Sign-In OAuth / providerData

```json
{
  "providerData": [
    {
      "providerId": "password",
      "uid": "wave0-smoke-202605181440@bookbed.test",
      "email": "wave0-smoke-202605181440@bookbed.test",
      "displayName": "Wave Zero Tester"
    }
  ]
}
```

**Only password provider linked. No `google.com` or `apple.com` OAuth provider.**

So:
- No OAuth refresh token was issued against PROD `CLIENT_ID 592597958982-a38onq6ft57de2dprnsi3lg0rog27bvg.apps.googleusercontent.com`.
- No real Google account is linked to this PROD test user.
- Sign-out via Google account-revocation flow not required.

Auth metadata:
- `createdAt`: 2026-05-18 12:49:40 GMT (Wave 0)
- `lastSignIn`: 2026-05-18 12:49:40 GMT (= creation time, only signed in once during the test)
- `lastRefresh`: 2026-05-18 19:56:58 GMT (ID-token refresh during the same test session)
- `emailVerified`: false (the smoke test never sent an email-verification flow)
- `disabled`: false

---

## TASK 5 — Other artifacts tied to TEST_UID

| Query | PROD result |
|---|---|
| `properties.where('owner_id', '==', TEST_UID)` | 1 — `6VCCLt8rnSokrIani9oU` "Wave Test Vila" (already known) |
| `subscriptions.where('user_id', '==', TEST_UID)` | 0 |
| `subscriptions.where('userId', '==', TEST_UID)` | 0 |
| `subscriptions.where('ownerId', '==', TEST_UID)` | 0 |
| `subscriptions.where('customer_id', '==', TEST_UID)` | 0 |
| `audit_logs.where('user_id', '==', TEST_UID)` | 0 |
| `collectionGroup('bookings').where('guest_email', '==', TEST_EMAIL)` | (index-blocked, but TASK 1 of audit/14 already scanned all 14 prod properties → 0 hits) |

### PROD top-level collections (sanity check, no contamination found beyond above)

```
additional_services, email_verifications, loginAttempts, properties,
security_events, system_rate_limits, tenants, users
```

`loginAttempts` and `security_events` may contain entries for this UID but were not deep-scanned in this audit (low priority — they're transient audit data, not load-bearing artifacts).

---

## Severity assessment per vector

| Vector | Severity | Rationale |
|---|---|---|
| **Stripe Connect Express account** in PROD platform | **HIGH (assumed LIVE)** | `acct_1TYSMdPWhhVc6lN0` exists, connected 2026-05-18. Could carry real KYC + banking if onboarding completed. Cannot verify state without manual dashboard check. |
| FCM device tokens | LOW | Not persisted to Firestore. Will fail-and-expire naturally. |
| Google/Apple OAuth | NONE | Only password provider; no third-party OAuth tokens issued. |
| Firestore user doc | LOW | 1 user doc, easy DELETE — but DO NOT delete until Stripe Connect cleared (CF `disconnectStripeAccount` requires user doc to look up `stripe_account_id`). |
| Firestore property + unit | LOW | 1 property `Wave Test Vila` + 1 unit `Apartman A`. No bookings. Safe DELETE. |
| Firestore booking artifacts | NONE | Audit/14 confirmed 0 bookings tied to user. |
| Trial emails sent from PROD | LOW (sent to `@bookbed.test` which bounces) | Resend trial-warning CFs would have sent emails to `wave0-smoke-202605181440@bookbed.test`. That domain doesn't accept mail → bounced via Resend. No real user inbox affected, but it did consume Resend send budget. |

---

## Cleanup recipe (NOT EXECUTED — flags only)

**Order matters because of Stripe dependency.**

### Step 1 — Disconnect Stripe (HIGHEST priority, BLOCKING)

Option A (preferred): use CF `disconnectStripeAccount`
- Sign in to PROD as the test owner (impersonation via Admin SDK token mint), OR run the CF callable with admin override
- CF deletes the Stripe account via Stripe API + clears Firestore `stripe_account_id` field
- Logs in PROD CF logs

Option B: manual Stripe Dashboard
- Login to BookBed live Stripe dashboard
- Connect → Accounts → search `acct_1TYSMdPWhhVc6lN0`
- Reject / Reject application / Delete (UI varies by account state)
- Then manually clear `stripe_account_id` + `stripe_connected_at` from Firestore user doc

Option C: Stripe API direct (script)
```javascript
// scripts/cleanup-prod-wave0-stripe.js — NOT YET WRITTEN
const Stripe = require('stripe');
const stripe = new Stripe(process.env.STRIPE_LIVE_SECRET_KEY);
const r = await stripe.accounts.del('acct_1TYSMdPWhhVc6lN0');
console.log(r);
```
Needs LIVE secret key in env. Gated behind `--confirm-prod` flag.

### Step 2 — Delete Firestore property/unit/user (after Stripe step)

Same as `audit/14-deploy-scripts-mismatch.md` migration plan:
```
db.doc('properties/6VCCLt8rnSokrIani9oU/units/seg85UhyMQM8hw7ZpLhq').delete()
db.doc('properties/6VCCLt8rnSokrIani9oU').delete()
db.doc('users/qoN6aykKwqZI4n9REgqXfEFG8KM2').delete()
admin.auth().deleteUser('qoN6aykKwqZI4n9REgqXfEFG8KM2')
```
Wrap in `scripts/cleanup-prod-wave0-artifacts.js` with `--confirm-prod` gate, idempotent existence checks, and audit log.

### Step 3 — Verify post-cleanup

Re-run audit/14 TASK 5 queries + audit/15 TASK 1 queries. Expect:
- `auth().getUserByEmail('wave0-smoke-202605181440@bookbed.test')` → not found
- `users/qoN6aykKwqZI4n9REgqXfEFG8KM2` → doesn't exist
- `properties/6VCCLt8rnSokrIani9oU` → doesn't exist
- `stripe.accounts.retrieve('acct_1TYSMdPWhhVc6lN0')` → 404

---

## Root-cause crystallization (vs audit/14)

`audit/14-deploy-scripts-mismatch.md` listed three candidate causes for the PROD contamination. This deeper check confirms **#5 (new) = the actual cause**:

**#5 — iOS app default-`flutter run` entry + manually-swapped GoogleService-Info.plist**

Evidence:
- `ios/Runner/GoogleService-Info.plist` PROJECT_ID = `rab-booking-248fc` (PROD) — current state.
- `ios/Runner/GoogleService-Info.plist.backup` PROJECT_ID = `bookbed-dev` — manual file-swap pattern. Last `.backup` mtime Jan 18, .plist mtime Jan 24 → at some point swapped to prod and never swapped back.
- `lib/main.dart` is the default `flutter run` entry when `--target` is not specified. It imports `firebase_options.dart` (PROD), and does NOT call `EnvironmentConfig.setEnvironment(...)`.
- `lib/main_dev.dart` is correct, but only used if invoked via `--target lib/main_dev.dart`. Per `memory/wave0-test-findings.md`: "Drop --flavor dev from flutter run: iOS Runner.xcodeproj has no flavor schemes". The flavor was dropped; the `--target` flag was likely also forgotten OR the dev plist swap wasn't done.
- AppDelegate.swift contains no `FirebaseApp.configure()` — relies entirely on Dart-side `Firebase.initializeApp(options:…)`. So whichever options the Dart layer passes is the source of truth for Firestore/Auth. With `lib/main.dart` as entry → PROD options.
- Stripe Connect onboarding from iOS calls `createStripeConnectAccount` CF on whichever Firebase project the app is connected to. If connected to PROD → calls PROD CF → creates account on PROD Stripe platform.

This explains the entire chain end-to-end:
1. Tester runs `flutter run -d "iPhone Simulator"` without `--target lib/main_dev.dart`
2. Default `lib/main.dart` builds → app initializes Firebase with PROD options
3. Tester registers `wave0-smoke-202605181440@bookbed.test` → lands in PROD Auth
4. Tester completes profile, creates property → PROD Firestore
5. Tester taps "Connect Stripe" → CF invocation against PROD → live Stripe Express account `acct_1TYSMdPWhhVc6lN0` created
6. Tester returns from Stripe onboarding → `stripe_account_id` written to user doc in PROD Firestore

No deploy-script bug needed for *this specific* contamination event. But the deploy-script bug audited in `audit/14` is still real and still needs fixing — it's a separate exposure surface (web dev/staging widget hosts pointing at prod).

---

## Hardening recommendations (out of scope for cleanup; PR-level fixes)

1. **`scripts/run_dev.sh`** (if it exists) or alternative: enforce `--target lib/main_dev.dart` always. Make `flutter run` without explicit target fail at the engineering-script layer. (Check `scripts/run_dev.sh` content.)
2. **iOS Xcode schemes**: create `Debug-dev` / `Debug-staging` schemes that auto-swap GoogleService-Info.plist via Run Script Build Phase. Eliminates manual file-rename pattern.
3. **`lib/main.dart` direct entry**: add `assert(EnvironmentConfig.isProduction == false || isReleaseMode, 'Use main_prod.dart or main_dev.dart')` at the top of main(). Debug-mode runs that bypass env entries crash visibly.
4. **`AppDelegate.swift`**: add `FirebaseApp.configure()` explicitly in `didFinishLaunchingWithOptions` AFTER reading a per-flavor plist file path. Removes Dart-layer race.
5. **Functions config migration**: move legacy `functions.config().stripe.secret_key` → Secret Manager only. Delete the legacy `functions.config()` entries entirely so the `sk_test_…` value isn't sitting there confusing future audits. (Deprecation deadline March 2026 forces this anyway.)
6. **GitHub Actions parity**: create `deploy-owner-dev.yml`, `deploy-widget-dev.yml`, equivalents for staging. Shell scripts in `scripts/deploy_*.sh` become legacy/reference-only.

---

## Cleanup execution log (2026-05-21 20:23 UTC)

User authorized Firestore + Auth cleanup with `--skip-stripe-check` flag (Stripe Connect dissolution deferred to manual dashboard action). Run via:

```
node scripts/cleanup-prod-wave0-orphans.js --skip-stripe-check --execute
```

Operations completed (full log: `audit/migrations/2026-05-21-prod-wave0-cleanup.log`):

| Op | Result |
|---|---|
| Delete `properties/6VCCLt8rnSokrIani9oU/units/seg85UhyMQM8hw7ZpLhq` | ✓ deleted |
| Delete `properties/6VCCLt8rnSokrIani9oU/units/seg85UhyMQM8hw7ZpLhq` (idempotent retry) | ✓ no-op |
| Delete `properties/6VCCLt8rnSokrIani9oU/widget_settings/seg85UhyMQM8hw7ZpLhq` | ✓ deleted (NEW: subcollection walk found this — not flagged in earlier audit/14/15 checks) |
| Delete `properties/6VCCLt8rnSokrIani9oU` | ✓ deleted |
| Delete `users/qoN6aykKwqZI4n9REgqXfEFG8KM2` | ✓ deleted |
| Delete auth user `qoN6aykKwqZI4n9REgqXfEFG8KM2` | ✓ deleted |

### Post-cleanup verification

Re-ran TASK 1 + TASK 5 queries against PROD:

| Check | Before | After |
|---|---|---|
| `users/qoN6aykKwqZI4n9REgqXfEFG8KM2` doc | exists | **absent** ✓ |
| `auth.getUserByEmail('wave0-smoke-202605181440@bookbed.test')` | UID qoN6... | `auth/user-not-found` ✓ |
| `auth.getUser(qoN6...)` | UID qoN6... | `auth/user-not-found` ✓ |
| `properties/6VCCLt8rnSokrIani9oU` | "Wave Test Vila" | **absent** ✓ |
| Unit, widget_settings under it | 2 docs | **absent** ✓ |
| Remaining subcollections on deleted property | — | none ✓ |
| `properties.where('subdomain', '==', 'wave-test-vila')` | 1 | **0** ✓ |
| Total PROD properties | 14 | **13** ✓ |

### Outstanding — NOT addressed by this run

- **Stripe Connect `acct_1TYSMdPWhhVc6lN0`** remains in BookBed live mode. Now orphaned (no linked Firestore user). User must dissolve manually via https://dashboard.stripe.com/connect/accounts (LIVE mode). The account had `details_submitted` unknown / `external_account` unknown at audit time — recommend verifying state before dissolution to capture for audit trail.

---

## Open questions for next session

1. **Is `STRIPE_SECRET_KEY` (Secret Manager v4) live or test?** If live → confirm dashboard cleanup. If test → severity drops to LOW.
2. **Was the Stripe Connect onboarding completed?** Dashboard look-up determines whether external_account (banking) was attached.
3. **Were any trial-warning emails actually sent from PROD Resend to the test address?** Check Resend logs for 2026-05-18..2026-05-25 → filter to recipient `wave0-smoke-202605181440@bookbed.test`. Confirms whether the test acct is currently active in Resend's bounce list.
4. **Does PROD Resend have other `@bookbed.test` bounces?** If yes → other test users / Wave 0 fallout exists beyond the one this audit found.

---

## Files referenced

- `audit/07-ios-smoke-test.md`, `audit/07-ios-smoke-summary.md` (Wave 0 iOS test trail)
- `audit/14-deploy-scripts-mismatch.md` (deploy-script bug + initial contamination discovery)
- `lib/main.dart`, `lib/main_dev.dart` (entry points)
- `lib/firebase_options.dart`, `lib/firebase_options_dev.dart` (Firebase configs)
- `ios/Runner/GoogleService-Info.plist` (PROD), `ios/Runner/GoogleService-Info.plist.backup` (DEV)
- `ios/Runner/AppDelegate.swift` (no native FirebaseApp.configure())
- `functions/src/stripeConnect.ts:14` (`createStripeConnectAccount`)
- `functions/src/stripe.ts:12` (`stripeSecretKey = defineSecret("STRIPE_SECRET_KEY")`)
- `.claude/rules/stripe.md` ("LIVE MODE" rule)
- `memory/wave0-test-findings.md` (the --flavor / --target gotcha)
