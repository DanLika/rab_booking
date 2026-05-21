# BookBed TODO Items

Extracted from CLAUDE.md — inactive planning items.

---

## 🚨 TODO: Cloud Functions audit follow-ups (2026-05-21)

**Prioritet:** Mixed (P0 prod bugs, P1 cleanup, P2 hygiene, P3 long-term)
**Izvor:** `audit/11-cloudfunctions-inventory.md`

### P0 — production-affecting bugs

1. **Deploy `getBookingByStripeSession` to prod** (`rab-booking-248fc`). Source on `main` + dev; widget booking-confirmation Flutter path calls it on prod and currently 404s. _(Same item as Wave 0 cutover §1 below — kept in both places intentionally.)_
2. **Deploy `sendOwnerEmail` to prod**. Recent hotfix on `hotfix/widget-secrets-exfil` (commit `49af1625`) is dev-only; production owners do not currently receive widget inquiry emails.
3. **Fix dead Flutter callsite `sendSuspiciousActivityAlert`** (`lib/core/services/security_events_service.dart:356`). Backend `securityEmail.ts` deleted in commit `4cb5a391`; every suspicious-login attempt logs an unhandled cloud-functions error. Either restore the backend or remove the caller.

### P1 — source-state cleanup

4. **Decide Airbnb / Booking.com OAuth fate.** Source on dev only (`airbnbApi.ts`, `bookingComApi.ts`), 4 months stale, Flutter UI still calls `initiateAirbnbOAuth` / `initiateBookingComOAuth`. Either ship (deploy + complete) or cut (delete source + UI + undeploy from dev). Cross-reference `audit/06-platform-connections-check.md` if applicable.

### P2 — hygiene

5. **Track Firebase Extensions in `firebase.json`.** Run `firebase ext:export --project rab-booking-248fc` so `delete-user-data` + `storage-resize-images` are version-controlled.
6. **Add `functions/.env.bookbed-dev`** with dev-specific `WIDGET_URL`, `BOOKING_DOMAIN`, `FROM_EMAIL`, `FROM_NAME`. Per `.claude/rules/hosting-build.md` this is required to stop dev from sending emails with prod URLs.

### P3 — long-term

7. **Region consolidation roadmap.** Move Stripe + booking hot-path functions from `us-central1` → `europe-west1`. Needs dual-deploy phase + Stripe webhook URL update in Dashboard. ~+120ms latency win per call for EU/HR users.

---

## 🚨 TODO: Wave 0 prod cutover

**Prioritet:** HIGH (Wave 0 is dev-only until this lands)
**Izvor:** `audit/09-wave0-promote-report.md`

Wave 0 branches landed on `main` 2026-05-18 (`pre-wave0-promote` `eadec3cc` → `post-wave0-stable` `a480e5f3`). Production (`rab-booking-248fc`) is untouched — these changes only affect `bookbed-dev` (`createStripeCheckoutSession` deployed) and local dev workflow.

### Required for prod cutover

1. Deploy `getBookingByStripeSession` Cloud Function to `rab-booking-248fc` (currently only on `bookbed-dev`).
2. Build + deploy widget bundle to prod hosting (`view.bookbed.io` widget target).
3. Deploy widget overlay JS to `view.bookbed.io` (`web/bookbed-overlay.js` → `build/web_widget/`).
4. Deploy `firestore.rules` to prod **last** — so the live widget never makes a now-blocked direct read during the cutover window.
5. Deploy `createStripeCheckoutSession` to prod (the env-aware allowlist is harmless on prod — `getAllowedReturnDomains()` only appends extras when `GCP_PROJECT == 'bookbed-dev'`/`'bookbed-staging'`).
6. Run the manual smoke checklist from `audit/06-bookings-hotfix-partial.md` §6.3 against the prod widget origin.

### Wave 1 prerequisites (run BEFORE this prod cutover)

- Stash triage (9 stashes — full table in `audit/09-wave0-promote-report.md` §Outstanding).
- Branch archive-and-delete (12 branches awaiting Wave 1).
- T8 silent-catch coverage verification — confirm T10 captured all 18 sites originally in `stash@{8}` "T8-silent-catches-WIP-rescued-by-T10" before dropping that stash.

---

## ✅ DONE: Widget `null.toString()` hardening (2026-05-18)

**Branch**: `fix/null-tostring-hardening` — **merged to `main`** via `6f187d1a`.
**Audit**: `audit/08-null-tostring-fix.md`

Closed the Wave 0 smoke-test finding about `Uncaught TypeError: Cannot read properties of null (reading 'toString')` on the widget `/view` path. Root cause: `Uri.queryParameters` passes each value through `.toString()` during encoding, and dart2js compiles that into literal `null.toString()` when the value is nullable. Fixed 2 sites in `booking_view_screen.dart` with `?? ''` coercion. Full test suite green.

## 🟡 TODO: Login submit crash on Flutter web (separate bug class)

**Source**: `audit/07-chrome-smoke-test.md` line 524.

The same JS-error-type appears on the login form submit, but the underlying cause is **CanvasKit text-input sync** — `_passwordController.text` reads empty even when the DOM `<input>` is populated. Form validator fails before any auth call fires. This is NOT the same Dart `null.toString()` bug, and the hardening branch does NOT address it. Needs:

1. Repro on `bookbed-dev` with DevTools open, capture the actual stack trace (audit speculation was that it shares the null.toString class — proven wrong by the widget-side fix not affecting login).
2. Investigate `keyboard_dismiss_fix_web.dart` interaction with autofill events.
3. Workaround in production: direct JS `firebase_auth.signInWithEmailAndPassword` call (smoke test used this).

## 🔐 TODO: T11c — Drop `unit_id+status` clause from bookings rule (deferred from T11-hotfix-partial)

**Prioritet:** HIGH (largest remaining public-read surface on `bookings`)
**Status:** **DEFERRED** — clause 1 intentionally kept until availability CF ships
**Izvor:** `audit/03-backend.md` §3.4 flag #1, `audit/06-bookings-hotfix-partial.md`, `audit/06-availability-cf-design.md`

### Background

**T11-hotfix-partial** (branch `fix/bookings-hotfix-partial`, commit `9f3d86b4`, **merged to `main` 2026-05-18** via `04e742df`, **deployed to `bookbed-dev` only** — prod untouched, awaiting Wave 0 prod cutover) closed 2 of 3 public-read clauses on the `bookings` rule:

- ❌ `stripe_session_id` field-presence — REMOVED. Replaced by callable `getBookingByStripeSession(sessionId)`.
- ❌ `booking_reference` field-presence — REMOVED. Already had `verifyBookingAccess` as alternative.
- ✅ **`unit_id` + `status` field-presence — KEPT**. Widget calendar depends on it for availability rendering.

Clause 1 still makes every booking doc publicly readable to any Firebase API key holder. Closing it is **T11c**.

### Sequence (in order — out-of-order will break the widget calendar)

1. Ship `getUnitAvailability(unitId, dateRangeStart, dateRangeEnd)` Cloud Function (Admin SDK, returns sparse blocked-date array — zero PII).
2. Replace widget calendar's `collectionGroup('bookings').where('unit_id', '==', ...)` queries (in `firebase_booking_calendar_repository.dart` + `realtime_booking_calendar_provider.dart`) with the new CF.
3. Cut over deployment: deploy CF → deploy widget → only then drop clause 1.
4. Update the rules-unit-test guard `widget calendar (unit_id + status) clause STILL ALLOWS reads` in `functions/test/firestore_rules/bookings.test.ts` — flip the assertion or replace with a CF-mediated test.

### Production deploy of T11-hotfix-partial

Currently dev-only. Before prod cutover:
- Deploy `getBookingByStripeSession` CF to `rab-booking-248fc`.
- Build + deploy the widget bundle to prod hosting.
- Deploy `firestore.rules` to prod **last** (so the live widget never makes a now-blocked direct read).
- Run the manual smoke checklist (§6.3 of `audit/06-bookings-hotfix-partial.md`) on the prod widget origin.

---

## 🚨 TODO: Tech Debt Audit Findings (2026-05-18)

**Prioritet:** Mixed (C1 critical, rest medium)
**Izvor:** `audit/04-techdebt.md`, `audit/04b-flutter-analyze-summary.md`, `audit/04c-hardcoded-urls.md`

### Critical
- ✅ **C1 — DONE** (Wave 1, commit `c3465034` 2026-05-18): `bookingComApi.ts` deleted entirely as part of KILL Booking.com/Airbnb integration. MD5 IV concern moot.
- **C3 — 2 silent catches in confirmation screen** (`lib/features/widget/presentation/screens/booking_confirmation_screen.dart:171,192`). Wrap `tabService.dispose()` failures with `LoggingService.logWarning` (debug-mode only, no Sentry noise). Attempted in branch `fix/widget-silent-catches` (commit `6f7419147`) but file reverted locally — re-apply.

### High / Medium
- **H2 — Stripe Price IDs hardcoded** (`functions/src/stripeSubscription.ts:44`). Replace with env-sourced IDs.
- ✅ **M1 — DONE** (Wave 1, commit `c3465034` 2026-05-18): Booking.com (`bookingComApi.ts`, 514 lines) and Airbnb (`airbnbApi.ts`, 451 lines) integration files removed; OAuth dead code purged.
- ✅ **M2 — DONE** (Wave 1, commits `6a7bdc13` / `fab63189` 2026-05-18): Trial expiry email templates migrated to V2 (`generateEmailHtml` + `template-helpers`). See `audit/06-trial-v2-content-diff.md`.
- ✅ **M4 — DONE** (T12 merge `2fdec297`): `ical_export_list_screen.dart:212` now uses `EnvironmentConfig.firebaseProjectId`.
- **M5 — Cancellation policy logic stub** (`functions/src/guestCancelBooking.ts:250`).
- **M6 — 7 production `print()` calls** in widget config/helpers (`tax_legal_config.dart`, `booking_price_calculator.dart`, `ical_export_config.dart`, `embed_url_params.dart`, `email_verification_service.dart`, `availability_checker.dart`). Route through `LoggingService`.
- ✅ **M7 — DONE** (T13 merge `e162d5d1`): 6 callsites refactored via `EnvironmentConfig.widgetHost` / `dashboardHost` / `marketingHost` / `isMarketingHost()`. See CHANGELOG 6.69 for details.

### Code-health
- ✅ **DONE** (T13 merge `e162d5d1`): Brittle `host.startsWith('view.')` replaced with `host == EnvironmentConfig.widgetHost` in both `subdomain_service.dart:51` and `booking_view_screen.dart:107`. Staging widget host no longer mis-parses as client subdomain.
- ✅ **DONE** (T13 merge `e162d5d1`): Duplicate `_subdomainBaseDomain` consts in `embed_widget_guide_screen.dart` and `embed_code_generator_dialog.dart` removed; both now route via `EnvironmentConfig.widgetHost`.
- 2 discontinued + 133 outdated packages reported by `flutter pub outdated` — separate hygiene pass.

---

## ✅ DONE: V2 Trial Email Migration (Wave 1, 2026-05-18)

**Merged:** `fab63189` ("Merge: trial email V2 templates") via branch `chore/merge-trial-v2-winner` (`6a7bdc13`).
**Winner pick:** `refactor/trial-email-templates-v2-5763908700715533391` (per `audit/06-trial-v2-content-diff.md`).
**Result:** `trial-expired.ts` + `trial-expiring-soon.ts` now use `generateEmailHtml` + `template-helpers` (V2). The other 5 Jules candidate branches are awaiting Wave 1 archive-and-delete.
**Deploy:** Pending — Cloud Functions don't reflect git without `cd functions && npm run deploy` per MEMORY.md #3.

---

## 📝 TODO: Bookbed Website Documentation

**Prioritet:** High
**Rok:** 2-3 dana
**Lokacija:** Bookbed React website (docs sekcija)

### Potrebna dokumentacija:

**Za Owners (Property Managers):**
1. Getting Started - Kreiranje property-ja i unita
2. Pricing Setup - Postavljanje cijena i sezonskih pravila
3. Stripe Connect - Povezivanje Stripe računa
4. Widget Configuration - Embed kod i postavke
5. Managing Bookings - Pregled i upravljanje rezervacijama
6. iCal Sync - Sinkronizacija sa Booking.com/Airbnb
7. Notifications - Email postavke i obavijesti

**Za Guests:**
1. How to Book - Koraci za rezervaciju
2. Payment Options - Stripe, bank transfer, pay on arrival
3. Booking Lookup - Pregled postojeće rezervacije
4. Cancellation - Otkazivanje rezervacije

**API Reference:**
1. Cloud Functions API - createBookingAtomic, verifyBookingAccess, etc.
2. Widget Embed Options - URL parametri, customization
3. Webhook Events - Stripe webhooks, booking events

**Izvor sadržaja:** Ovaj projekt (CLAUDE.md, SECURITY_FIXES.md, kod)

---

## 📝 TODO: Admin Controls Feature

**Prioritet:** Low (nice-to-have)
**Kompleksnost:** ~20-30 minuta
**Izvor:** Ekstrahirano iz branch `sentinel-firestore-audit-15445911159531971809`

### Opis
Admin kontrole za upravljanje korisničkim računima iz Admin panela bez potrebe za direktnim Firestore editiranjem.

### Nova polja u UserModel (`lib/shared/models/user_model.dart`):
```dart
/// Hide subscription page from this user (e.g., for special deals)
final bool hideSubscription;

/// Admin override of account type (bypasses subscription logic)
final AccountType? adminOverrideAccountType;
```

### Potrebne izmjene:

**1. UserModel** (`lib/shared/models/user_model.dart`):
- Dodati `hideSubscription` (bool, default: false)
- Dodati `adminOverrideAccountType` (AccountType?, nullable)
- Ažurirati `fromJson()` i `toJson()`
- Ažurirati `copyWith()`

**2. AdminUsersRepository** (`lib/features/admin/data/repositories/`):
```dart
Future<void> updateAdminFlags({
  required String userId,
  bool? hideSubscription,
  AccountType? adminOverrideAccountType,
  bool clearOverride = false,  // Set to true to remove override
}) async {
  final updates = <String, dynamic>{
    'updated_at': FieldValue.serverTimestamp(),
  };
  if (hideSubscription != null) {
    updates['hide_subscription'] = hideSubscription;
  }
  if (clearOverride) {
    updates['admin_override_account_type'] = FieldValue.delete();
  } else if (adminOverrideAccountType != null) {
    updates['admin_override_account_type'] = adminOverrideAccountType.name;
  }
  await _firestore.collection('users').doc(userId).update(updates);
}
```

**3. UserDetailScreen** (`lib/features/admin/presentation/screens/user_detail_screen.dart`):
- Dodati "Admin Controls" card sa:
  - Switch za `hideSubscription`
  - Dropdown za `adminOverrideAccountType` (None, Free, Premium, Enterprise)
  - Save button

**4. SubscriptionScreen** provjera:
```dart
// U subscription_screen.dart
if (user.hideSubscription) {
  // Redirect away or show "Contact admin" message
}

// Za account type provjeru
AccountType get effectiveAccountType =>
    user.adminOverrideAccountType ?? user.accountType;
```

### Korištenje
- Admin može sakriti subscription stranicu za korisnika koji ima special deal
- Admin može override-ati account type bez potrebe za Stripe subscription

---

## 📝 TODO: Security Branch Fixes (Za Kasnije)

**Prioritet:** Medium
**Branchevi:** Pregledani 2026-02-01, sadrže korisne security fixeve za budući deploy.

### Branch 1: `security-audit-2026-01-29-9611837304482000277`
**Šta radi**: Premješta `loginAttempts` Firestore write sa klijenta na Cloud Functions.
- `firestore.rules`: `loginAttempts` write → `allow write: if false`
- `authRateLimit.ts`: Nove CF `recordFailedLoginAttempt` + `resetLoginAttempts`
- `rate_limit_service.dart`: Poziva CF umjesto direktnog Firestore write-a
- `stripeSubscription.ts`: Generičke error poruke (ne leaka `error.message`)

**⚠️ Zahtijeva koordiniran deploy** (ovim redoslijedom):
1. Deploy Cloud Functions prvo
2. Deploy Flutter app
3. Deploy Firestore rules zadnje

### Branch 2: `security-audit-2025-05-22-13396931281884778762`
**Šta radi**: XSS fix u email template-ima + Stripe error sanitizacija.
- `trial-expired.ts`: `${userName}` → `${escapeHtml(userName)}`
- `trial-expiring-soon.ts`: isto `escapeHtml`
- `stripePayment.ts`: `error.message` → generička poruka
- `stripeSubscription.ts`: `error.message` → generička poruka

**Jednostavan za cherry-pick** - samo 4 fajla, mali fixevi.
