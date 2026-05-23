# BookBed TODO Items

Extracted from CLAUDE.md — inactive planning items.

---

## 🚨 TODO: Wave 3 deferred UI fixes (2026-05-22)

**Prioritet:** P2 (mobile UX papercuts; no regression introduced)
**Izvor:** `audit/19-wave3-cleanup.md` § Deferred + originally referenced (missing) `audit/07-chrome-smoke-test.md`

The 2026-05-22 Wave 3 responsive-cleanup session shipped 2 of 4 fixes (price row Flexible + admin footer year — CHANGELOG 6.75). 3 items deferred because the source audit doc `audit/07-chrome-smoke-test.md` is missing from the repo, so the bug descriptions + screenshots can't be cross-checked.

### Blocking prerequisite

**0. Recover or rebuild `audit/07-chrome-smoke-test.md`.** The follow-up `audit/08-null-tostring-fix.md` references it at lines 5, 23, 778 but the source itself is absent. Without primary screenshots/stack traces, the 3 items below are guesswork. Rebuild via a fresh Chrome smoke test on `bookbed-dev` widget + owner + admin, captured at 320/375/768/1440px breakpoints.

### Items

**1. Login CanvasKit text-input sync gap.** `lib/features/auth/presentation/screens/enhanced_login_screen.dart` + `lib/features/auth/presentation/widgets/premium_input_field.dart`. Claimed defect: text typed into email/password fields doesn't sync to `TextEditingController`, so `_handleLogin` reads empty fields. Known workaround in `memory/flutter-web-input-bypass.md`: bypass via direct `firebase_auth.signInWithEmailAndPassword` call. Code audit shows no obvious defect — controllers exist, listeners attached, `_handleLogin` snapshots into locals before async, `PremiumInputField` has `autocorrect:false`/`enableSuggestions:false`/`textCapitalization:none`. **Need browser console capture + screen recording** to triage.

**2. Owner mobile heading truncation.** Claimed: section headers on `/owner/overview` render as "Nedav…", "Rezer…", "Fi…" on iPhone X (375px) instead of "Nedavne", "Rezervacije", "Finansije". Code audit located no truncating widget — `RecentActivityWidget` already uses `AutoSizeText`/`minFontSize:14`, `_buildChartHeader` uses `Expanded`. Possible candidate: `CommonAppBar` title (not yet inspected) or the drawer items at narrow open widths. **Need screenshot at 375px Croatian locale (`?lang=hr`)** to pinpoint the offending widget.

**3. Admin "Em…" placeholder.** Claimed: a placeholder reads "Em…" instead of its full string. Low-confidence candidates: `admin_login_screen.dart:263-264` (`labelText:'Email Address'`, `hintText:'admin@bookbed.io'`) or `users_list_screen.dart:190` (`hintText:'Search users by name or email...'`) — the latter is the more plausible match if rendered in a narrow filter chip. **Need screenshot of the offending screen** to identify whether this is a `TextField.hint` (widen constraint), a `Text` ellipsis (drop `maxLines:1`), or a chip label (shorten copy).

### Done-when

- `audit/07-chrome-smoke-test.md` (or equivalent successor) committed with screenshots at 320/375/768/1440px.
- Each item above has either (a) a verified code fix landed via PR + closed against the rebuilt audit doc, or (b) a one-line "cannot reproduce" note attached to the audit item if the bug no longer surfaces on the current `main`.
- Follow-up bullets from `audit/19-wave3-cleanup.md` § "Out-of-scope follow-ups" actioned: `golden_test` for `PriceRowWidget` at 280/320/400px, plus a `grep -rn "mainAxisAlignment: MainAxisAlignment.spaceBetween" lib/features/widget/` sweep for sibling Row patterns missing `Flexible`.

---

## 🧹 TODO: Cleanup-session deferred execution (2026-05-22)

**Prioritet:** P2 hygiene
**Izvor:** `audit/18-stash-classification-2026-05-22.md` + `audit/18-dependabot-triage-2026-05-22.md`
**Why deferred:** mid-session multi-agent race (stash count 18 → 29, sibling stash storm, `.git/index.lock` contention) made destructive ops unsafe. Run when only one agent is active.

### Stash drops (29 stashes inventoried by SHA)

Full classification per stash in `audit/18-stash-classification-2026-05-22.md`. Recommended batches:

1. **DROP — race-debris from today** (10 stashes, SHAs `8526c348`, `b17e488e`, `d19775fb`, `c892e55a`, `7b1354c8`, `9621a95c`, `2d03f9b2`, `7863fbc1`, `883d897c`, `ece20c62`). Content is duplicated by what landed in `main` or other surviving stashes.
2. **INVESTIGATE before dropping** (4 stashes, `82818399`, `8aa2fd0f`, `b5bdf26b`, `4d989205`). Includes uncommitted prod code (`admin_login_screen.dart`, `price_row_widget.dart`) and substantial WIP (421 insertions). Verify scope is committed elsewhere first.
3. **VERIFY branch state** (9 stashes from `fix/error-boundary-and-chat-ux`, `fix/null-tostring-hardening`, `test/wave0-integration`, `fix/widget-silent-catches`). If branch landed in main, drop; else preserve.
4. **ANCIENT mvp/saas-booking-system stashes** (5 stashes: `faaedfff`, `457890b8`, `4151b352` (10585 lines), `d0e71b62`, `ea47ce17`). Audit doc has per-SHA verdict.
5. **KEEP**: my own `wip-security-fixes-doc-cleanup-session-2026-05-22` (`895abb60`, 333 lines on `fix/widget-price-row-and-admin-footer-year`).

Helper to drop by SHA (defeats index shift):
```bash
drop_by_sha() {
  local sha="$1"
  local ref=$(git stash list --format='%gd %H' | awk -v s="$sha" '$2==s {print $1; exit}')
  [ -n "$ref" ] && git stash drop "$ref" || echo "Stash $sha not found (already dropped?)"
}
```

### Dependabot triage (27 open branches)

Full classification per branch in `audit/18-dependabot-triage-2026-05-22.md`.

1. **REJECT — major bumps on locked/critical libs** (4 PRs): `pub/flutter_secure_storage-10.0.0`, `pub/package_info_plus-9.0.0`, `npm/functions/eslint-10.0.0`, `npm/functions/stripe-20.3.1`. Close + delete branches.
2. **INVESTIGATE — read diff per branch** (10 PRs): github_actions majors (download-artifact-8, upload-artifact-7, codecov-action-6), `pub/sentry_flutter-9.13.0`, `npm/functions/sentry/node-10.39.0`, `npm/functions/node-ical-0.25.2`, `npm/functions/firebase-*`, group updates (`pub/multi-*`, `npm/functions/multi-*`), `pub/flutter_launcher_icons-0.14.4`, `npm/functions/protobufjs-7.6.0`.
3. **AUTO-MERGE in small batches with CI watch** (12 PRs, transitive lockfile patches): ajv-6.15.0, brace-expansion-2.1.0, fast-xml-parser-4.5.6, flatted-3.4.2, handlebars-4.7.9, lodash-4.18.1, minimatch-3.1.5, minimatch-9.0.9, node-forge-1.4.0, path-to-regexp-0.1.13, picomatch-4.0.4, protobufjs/utf8-1.1.1.

### Branch + history hygiene

- Delete local cleanup branch: `git branch -d chore/cleanup-stash-dependabot-test-debt-2026-05-22`.
- Optional: squash duplicate cherry-pick (`cf1546a0` ↔ `70c91f8e`) via interactive rebase + force-push to `main`. Idempotent so leaving as cosmetic noise is also acceptable.

---

## 🚨 TODO: Cloud Functions audit follow-ups (2026-05-21)

**Prioritet:** Mixed (P0 prod bugs, P1 cleanup, P2 hygiene, P3 long-term)
**Izvor:** `audit/11-cloudfunctions-inventory.md`

### P0 — production-affecting bugs

1. **Deploy `getBookingByStripeSession` to prod** (`rab-booking-248fc`). Source on `main` + dev; widget booking-confirmation Flutter path calls it on prod and currently 404s. _(Same item as Wave 0 cutover §1 below — kept in both places intentionally.)_
2. **Deploy `sendOwnerEmail` to prod**. Recent hotfix on `hotfix/widget-secrets-exfil` (commit `49af1625`) is dev-only; production owners do not currently receive widget inquiry emails.
3. ~~**Fix dead Flutter callsite `sendSuspiciousActivityAlert`** (`lib/core/services/security_events_service.dart:356`). Backend `securityEmail.ts` deleted in commit `4cb5a391`; every suspicious-login attempt logs an unhandled cloud-functions error. Either restore the backend or remove the caller.~~ **DONE 2026-05-22** — caller removed (decision: don't restore the backend, the `security_events` Firestore log is sufficient for the audit trail). `_sendSuspiciousActivityEmail` method + `cloud_functions` import deleted from `security_events_service.dart`. Suspicious-login detection still writes to the `security_events` collection unchanged. `flutter analyze` clean for this file.

### P1 — source-state cleanup

4. **Undeploy Airbnb / Booking.com OAuth orphans from `bookbed-dev`.** **Partially done.** Source + Flutter callers killed 2026-05-18 (`c3465034 feat(kill)`); PROD CFs deleted 2026-05-21 (CHANGELOG 6.71). **Gap discovered 2026-05-22 (audit/16 session):** CHANGELOG 6.71 claimed "Dev had already pruned these" but `firebase functions:list --project bookbed-dev` still shows 4 orphan CFs live:
   - `initiateAirbnbOAuth` (us-central1, callable)
   - `handleAirbnbOAuthCallback` (us-central1, https)
   - `initiateBookingComOAuth` (us-central1, callable)
   - `handleBookingComOAuthCallback` (us-central1, https)

   No Flutter caller, no source. Smoke probe confirms they respond OK_bad_request (`invalid-argument`) to empty calls — i.e. they're alive but useless. Cleanup commands:
   ```bash
   for fn in initiateAirbnbOAuth handleAirbnbOAuthCallback initiateBookingComOAuth handleBookingComOAuthCallback; do
     firebase functions:delete "$fn" --project bookbed-dev --force --region us-central1
   done
   ```
   Cross-reference `audit/06-platform-connections-check.md`, `audit/11-cloudfunctions-inventory.md` §3.3, CHANGELOG 6.71. Run when ready; closes TODO P1.4.

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

## 🟡 TODO: Guest counter (adults / children / pets) doesn't persist to form cache (2026-05-23)

**Prioritet:** P3 (UX papercut — counters reset to defaults on refresh while name/email/phone restore correctly)
**Izvor:** PR #447 smoke verification (CHANGELOG 6.81), `booking_widget_screen.dart:2765-2782`
**Status:** Pre-existing on `main` — `git diff main..HEAD` over the region is empty as of 2026-05-23. NOT introduced by PR #447's Phase 0+1 refactor.

**Defect:** The `onAdultsChanged` / `onChildrenChanged` / `onPetsChanged` callbacks passed to `GuestCountPicker` only call `setState(() => _adults = value)` etc. They never trigger `_saveFormData()` — unlike the text controllers, which register `_saveFormDataDebounced` listeners (lines 262-266). As a result:

- The user picks Adults=3 in the form.
- They refresh the page (or navigate away + back).
- `FormPersistenceService.loadFormData` restores name/email/phone/dates/notes correctly.
- Adults silently resets to whatever was last saved (most commonly the default `1`), because no save fired when the counter incremented.

Verified during PR #447 smoke flow: pre-reload localStorage `adults: 1`, post-reload `adults: 1`, while the in-memory `_adults` was `2` just before reload.

### Fix (one-line per handler)

```dart
onAdultsChanged: (value) {
  if (mounted) {
    setState(() => _adults = value);
    _saveFormDataDebounced();  // add
  }
},
// same for onChildrenChanged + onPetsChanged
```

Use `_saveFormDataDebounced` (the existing 500 ms debouncer at line 1299) rather than `_saveFormData()` directly — counters typically click rapidly during selection, no need for one disk write per tap.

### Done-when

- All 3 handlers call the debounced save.
- Manual smoke: pick Adults=3 → refresh → form reopens with Adults=3.
- New unit test for `BookingFormState.adults` setter triggers a `notifyListeners` (already true post-PR #447 ChangeNotifier promotion) — but the screen-level handler is what currently swallows the save, so the test target is the handler wiring, not the model.

## ✅ DONE: T11c — Drop `unit_id+status` clause from bookings rule

**Prioritet:** HIGH (was largest remaining public-read surface on `bookings`)
**Status:** ✅ **CLOSED 2026-05-22** via PR #446 (branch `fix/t11c-proper-bookings-migration`, merge commit `3b810b2d`). ✅ Dev cutover complete 2026-05-22 (rules + CF + widget bundle + `daily_prices` COLLECTION composite index `available + date`, commit `a1fe3633`). Final smoke green: anon CG bookings → 403, `getUnitAvailability` → 200 with `windows[]`. Prod cutover pending.
**Izvor:** `audit/03-backend.md` §3.4 flag #1, `audit/06-bookings-hotfix-partial.md`, `audit/06-availability-cf-design.md`, `audit/17-sf023-sf025-rules-fix.md`

### Outcome

Last anonymous read surface on the `bookings` collection-group is closed. Widget calendar + booking-submit gate now route through the `getUnitAvailability` Cloud Function. `firestore.rules` clause 1 (`unit_id`+`status` public read) removed from all 3 surfaces (subcollection, CG, deprecated top-level).

### Sequence — final state

1. ✅ **`getUnitAvailability` CF** (SF-023, 2026-05-22, merge `d481bf11`). `functions/src/availability.ts`, region `europe-west1`. Returns `AvailabilityWindow[]` with `source` discriminator covering bookings + manual blocks + ical.
2. ✅ **Widget bookings snapshot stream migrated.** `firebase_booking_calendar_repository.dart` — 4 sites collapsed into single `_streamBlockedEvents` that demultiplexes CF windows by source. `availability_checker._checkBookings` replaced with `_fetchAvailabilityWindows` + per-source overlap helpers. Bookings + iCal now share one CF round-trip.
3. ⏳ **Cut-over to prod** — pending. Sequence:
   - Deploy `getUnitAvailability` CF to `rab-booking-248fc` (region `europe-west1`).
   - Deploy `daily_prices` COLLECTION composite index (`available + date`) via `firebase deploy --only firestore:indexes --project rab-booking-248fc`. Wait `READY` **+ ~30 s propagation buffer** before the rules deploy (Firestore needs the gap after `READY` before queries actually use a new composite — first CF call still 500s "index currently building" without it; observed in dev cutover).
   - Build + deploy the widget bundle to prod hosting.
   - Deploy `firestore.rules` to prod **last** (so the live widget never makes a now-blocked direct read).
   - Run smoke verify (anon CG `runQuery` on `bookings` with `unit_id`+`status` filter must return 403; `getUnitAvailability` must return 200 with `windows[]`).
4. ✅ **Rules-unit-test guard flipped.** `functions/test/firestore_rules/bookings.test.ts` — 2 "STILL ALLOWS" / "ALLOWED" assertions now `assertFails`. Test suite renamed to `bookings rule (T11c closed)`. 24/24 pass.

### Trade-offs accepted

- **Realtime → 30s polling** for widget bookings. Same cadence already used for iCal blocks after SF-023. Acceptable for an anonymous booking-flow surface.
- **Pending/confirmed visual distinction lost** in widget calendar. CF strips `status` for privacy; synthesized `BookingModel.status = confirmed`. Privacy win for anonymous viewers.

### Production deploy of T11-hotfix-partial + SF-023 + T11c

Currently all three are dev-only. Combined prod cutover checklist:

- Deploy `getBookingByStripeSession` CF to `rab-booking-248fc`.
- Deploy `getUnitAvailability` CF to `rab-booking-248fc` (region `europe-west1`).
- Deploy `daily_prices` COLLECTION composite (`available + date`) to prod via `firebase deploy --only firestore:indexes --project rab-booking-248fc`. Wait `READY` **+ ~30 s propagation buffer** before the rules deploy.
- Build + deploy the widget bundle to prod hosting (must include both the SF-023 ical-stream migration AND the T11c bookings-stream migration).
- Deploy `firestore.rules` + `storage.rules` to prod **last**.
- Run the manual smoke checklists in `audit/06-bookings-hotfix-partial.md` §6.3 + `audit/17-sf023-sf025-rules-fix.md` § Smoke verify on the prod widget origin.

### Cross-link

`docs/SECURITY_FIXES.md` SF-019 → "T11c CLOSED 2026-05-22" subsection. `CLAUDE.md` NIKADA NE MIJENJAJ row for bookings clause 1 flipped to ✅ CLOSED.

---

## ✅ DONE: SF-026 — booking night/guest count Timestamp normalization (2026-05-22)

**Branch:** `fix/sf-026-booking-count-dst`
**Commits on `main`:** `5f747740` (core), `0a6a6570` (merge), `dc554396` (migration index fix), `ff39fa8d` (smoke script).
**Audit:** `audit/18-booking-count-audit.md` → `docs/SECURITY_FIXES.md` SF-026 entry.
**Deploy:** `bookbed-dev` deployed 2026-05-22. Prod cutover pending operator.

### What landed (Option B)

- **STEP 6 normalization** (`functions/src/utils/dateValidation.ts`): new `normalizeToZagrebCivilDayUTC()` helper extracts civil day via `Intl.DateTimeFormat('en-CA', {timeZone: 'Europe/Zagreb'})` then stores Timestamps at UTC midnight of that civil day. Preserves display (a Zagreb client picking June 1 still sees "June 1" everywhere) while making `.difference().inDays` (Dart floor) and `Math.ceil(/86_400_000)` (TS ceil) return the same integer N. Naive `getUTCDate()` extraction would have shifted Zagreb-originated bookings backwards 1 day — caught by advisor mid-implementation.
- **Standardized derivation**: TS `verifyBookingAccess` + `getBookingByStripeSession` now call canonical `calculateBookingNights()`; Dart email service uses `booking.numberOfNights`; widget + form-state use `DateNormalizer.nightsBetween()`.
- **Backfill script** (`functions/scripts/normalize-booking-nights.js`): dry-run default, `--force` opt-in. Scans `collectionGroup('bookings')` filtered client-side (no Firestore index dep) for `confirmed | pending_payment | awaiting_owner_decision`, rewrites Timestamps where they differ from normalized.
- **Smoke script** (`functions/scripts/smoke-sf026-dev.js`): read-only sanity check — observed expected drift on bookbed-dev's seed booking (status=cancelled, out of migration scope, floor=2 vs ceil=3).
- **Tests** (`functions/test/dateValidation.test.ts`, 13/13 green): DST spring-forward (Zagreb 2026-03-29) → 4 nights; DST fall-back (2026-10-25) → 2 nights; long booking across both transitions → 240 nights; idempotency; validation guards.

### Outstanding (operator)

1. `firebase deploy --only functions --project bookbed-prod` — same Cloud Function update on prod.
2. `GOOGLE_CLOUD_PROJECT=bookbed-prod node functions/scripts/normalize-booking-nights.js` — prod dry-run to count drift.
3. After review, `--force` migration on prod.
4. (Optional) `--force` migration on dev — only 1 cancelled booking on dev today, status not eligible, so nothing to do.

### Open behavior change (filed, not fixed)

Same-Zagreb-civil-day check-in + check-out (different clock times within one day) now throws "< 1 night" in `calculateBookingNights()` whereas pre-fix it returned 1 via `Math.ceil(0.x)`. Widget picker constrains to whole dates so unreachable today; admin/script paths could trip it later. Out of scope for this PR.

### Promote to Option A only if

- Audit needs an immutable "billed for N nights" field — store `nights: number` on the booking doc and migrate read sites.
- Partial-day stays (early check-in / late check-out) become a pricing feature — Timestamp time-component becomes meaningful again, normalization no longer safe.

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
