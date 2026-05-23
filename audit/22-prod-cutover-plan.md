# audit/22 — PROD cutover plan: T11c + SF-023..026

**Target project**: `rab-booking-248fc` (PROD)
**Drafted**: 2026-05-23
**Status**: 🟡 DRAFT — no deploy authorized; awaiting answers in §8 before any execution
**Predecessors**: T11c CLOSED on `bookbed-dev` 2026-05-22 (PR #446, `ab6bdb3d`); SF-023/025 dev-deployed 2026-05-22; SF-026 dev-deployed 2026-05-22 (backfill NOT yet run); SF-022 code on `main` not deployed.
**Authoritative sources cited**: `docs/SECURITY_FIXES.md` SF-019 "Prod cutover prerequisites" + "T11c CLOSED" subsections; `audit/17-sf023-sf025-rules-fix.md`; `audit/21-sprint-summary-2026-05-22-23.md` Tier 2; CLAUDE.md "NIKADA NE MIJENJAJ" T11c row; `.claude/rules/firestore.md`; `.claude/rules/hosting-build.md`.

> **Note on `audit/06-availability-cf-design.md`**: the canonical deploy-order doc referenced by CLAUDE.md and SF-019 does not exist in `audit/` (only `06-bookings-hotfix-partial.md` + `06-indexes-drift.diff` are present). The canonical "CF → widget bundle → rules **last**" order is restated identically in `docs/SECURITY_FIXES.md` SF-019 (under "Prod cutover prerequisites" and "Dev deploy 2026-05-22") and is treated as authoritative for this plan. Backfill or recovery of the missing audit/06 design doc is a pre-deploy follow-up item (see §8 Q6).

> **Note on `audit/19-test-failures-diagnosis.md`**: the file referenced by `audit/21` does not exist as a separate doc; the diagnosis lives inline in `audit/21-sprint-summary-2026-05-22-23.md` §"Backend availability / fail-CLOSED — verification matrix" and confirms the fixes in §1 are safe to ship.

---

## 1. Scope & intent

Combined deploy to `rab-booking-248fc`:

| Change | Origin | Status on `main` |
|---|---|---|
| T11c — drop `unit_id + status` clause 1 from `bookings` (3 surfaces: subcollection + CG + deprecated top-level) | PR #446 (`ab6bdb3d`) merged → `main` | ✅ on main |
| `getUnitAvailability` CF (`functions/src/availability.ts`, region `europe-west1`) | SF-023 + T11c | ✅ on main |
| Widget bundle migrating 5 anonymous-context sites (`firebase_booking_calendar_repository.dart` 4 streams + `availability_checker.dart` 1 one-shot) onto the CF | T11c proper | ✅ on main |
| `daily_prices` COLLECTION composite (`available` + `date`) — `firestore.indexes.json` commit `a1fe3633` | T11c follow-on | ✅ on main |
| SF-023 — `ical_events` rules lockdown (subcollection + CG; deprecated top-level removed) | merge `d481bf11` | ✅ on main |
| SF-025 — `storage.rules` `/ical-exports/{p}/{u}/{...}` read tightened to owner + 5 MiB write cap | merge `d481bf11` | ✅ on main |
| SF-026 — `dateValidation.ts` STEP 6 Zagreb-civil-day normalize + Dart/TS derivation standardization | branch `fix/sf-026-booking-count-dst` | ✅ on main |
| Migration: `functions/scripts/normalize-booking-nights.js --force` | SF-026 backfill | NOT run on prod (or dev — only dry-run validated) |
| SF-022 — catch-promote-internal guards on 6 callables + dead `sendSuspiciousActivityAlert` callsite removal | `319f7d0f` | ✅ on main, NOT deployed anywhere |

**What ships in this cutover**: all rows above marked "on main" — i.e., this is essentially `main` → prod for everything between commits `a1fe3633` and `f4b19ad6` plus the SF-022 catch guards.

**What does NOT ship**:

- **SF-021 (widget_secrets split)** — Phase A code complete (`hotfix/widget-secrets-exfil`, commits `485ee112` + `3ed3c752`) but **deploy blocked on three operator prerequisites** that have not been completed: (1) `ICAL_TOKEN_PEPPER` Functions secret set on both `bookbed-dev` + `rab-booking-248fc` (same value); (2) per-owner Resend key rotation + `owner_id,new_resend_api_key` CSV for the migration script; (3) `ALLOWED_SUBSCRIPTION_PRICE_IDS` env param per project. Per SF-021 §Outstanding and `audit/21` Tier 2. SF-021 is its own cutover, separately gated; do not bundle it here.
- **Wave 5 Phase 1 (PR #447)** — refactor only, no security correctness payload. Wait for CI billing fix → merge → separate cutover or piggyback on a later non-security deploy.
- **Audit-only docs** (`audit/20`, `audit/21`, `audit/22`) — no deploy footprint.

---

## 2. Pre-flight checklist

All items must be ✅ before §3 begins. Defer any unchecked.

- [ ] **All 3 active PRs merged on `main`**: #449 (`chore/seed-test-owner-mode`) → #448 (`chore/test-debt-cleanup-audit-19`) → #447 (`refactor/booking-widget-phase1`). Merge order per `audit/21`. Blocker: GitHub Actions billing fix (Settings → Billing). Verify with `git log --oneline -20` shows all three merge commits on `main` before deploy starts.
- [ ] **`daily_prices` COLLECTION composite index present on `main`** (`available` ASC + `date` ASC). Confirmed in `firestore.indexes.json` (commit `a1fe3633`). Deploy this **before** rules deploy and **before** widget bundle so `getUnitAvailability` doesn't 500 on first prod call.
- [ ] **Widget bundle rebuilt + deployed to `bookbed-widget.web.app`** (PROD hosting target on `rab-booking-248fc`). Build: `flutter build web --release --target lib/widget_main.dart` then `firebase deploy --only hosting:widget --project rab-booking-248fc`. **Verify the deployed bundle is the post-T11c build**: HTTP HEAD `bookbed-widget.web.app/` returns `last-modified` ≥ 2026-05-22 17:37 GMT (dev parity). **Q2 resolved 2026-05-23** (`audit/24`): current PROD bundle `last-modified: Thu, 21 May 2026 18:50:32 GMT` (etag `153608da33...` on `flutter_bootstrap.js`) — confirmed **pre-T11c**, rebuild + redeploy in §3.3 is required.
- [ ] **`normalize-booking-nights.js` DRY-RUN against `rab-booking-248fc`**:
  ```bash
  GOOGLE_CLOUD_PROJECT=rab-booking-248fc node functions/scripts/normalize-booking-nights.js
  ```
  Expected output shape (dry-run default):
  ```
  SF-026 normalize-booking-nights — project=rab-booking-248fc
  Mode: DRY RUN (no writes)

  Found <N> total booking doc(s); filtering by status…
    <path>  status=<…>  in <iso>→<iso>  out <iso>→<iso>
    …
  Scanned: <N>
  Missing date (skipped): 0..few
  Drifting check_in: <K>
  Drifting check_out: <K>
  Bookings to update: <K>

  DRY RUN complete — no writes performed.
  ```
  - Save full dry-run stdout to `audit/migrations/2026-MM-DD-prod-sf026-normalize-DRYRUN.log`.
  - K should be the count of pre-fix DST-straddling bookings; many production bookings will already have midnight-Zagreb-civil-day timestamps and show no drift. If K = 0, the migration script execution in step 3.5 becomes a no-op (still run it for the audit-log artifact).
  - **NB**: script flag is `--force`, NOT `--execute` (script accepts only `--dry-run` (default) and `--force`).
- [ ] **Backup current PROD rules + storage rules** via Firebase Rules REST API (Q3 resolved 2026-05-23 — `audit/24`: `firebase` CLI has no `:rules:get` subcommand; REST is the working method):
  ```bash
  mkdir -p audit/migrations
  PROJECT=rab-booking-248fc
  TOKEN=$(gcloud auth print-access-token)

  # 1. Resolve the live ruleset name from the cloud.firestore release
  RULESET=$(curl -s \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-Goog-User-Project: $PROJECT" \
    "https://firebaserules.googleapis.com/v1/projects/$PROJECT/releases/cloud.firestore" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['rulesetName'])")

  # 2. Fetch the rules source and save snapshot
  curl -s \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-Goog-User-Project: $PROJECT" \
    "https://firebaserules.googleapis.com/v1/$RULESET" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['source']['files'][0]['content'])" \
    > audit/migrations/2026-MM-DD-prod-firestore-rules-pre-T11c.snapshot

  # 3. Storage rules — same flow, replace `cloud.firestore` with `cloud.storage/<bucket>`
  BUCKET="rab-booking-248fc.appspot.com"   # confirm exact bucket name in Firebase Console
  RULESET_STORAGE=$(curl -s \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-Goog-User-Project: $PROJECT" \
    "https://firebaserules.googleapis.com/v1/projects/$PROJECT/releases/firebase.storage%2F$BUCKET" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['rulesetName'])")
  curl -s \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-Goog-User-Project: $PROJECT" \
    "https://firebaserules.googleapis.com/v1/$RULESET_STORAGE" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['source']['files'][0]['content'])" \
    > audit/migrations/2026-MM-DD-prod-storage-rules-pre-T11c.snapshot
  ```
  Commit these snapshots to `main` BEFORE any deploy. Notes: (1) `X-Goog-User-Project: $PROJECT` is required — without it the API errors `403 SERVICE_DISABLED` even though the token is valid; (2) verified 2026-05-23 against `bookbed-dev` — returned full rules source (rulesetName `projects/bookbed-dev/rulesets/e319e00c-2d8b-4324-8e97-4cd5a7590c3c`, updateTime `2026-05-22T17:16:47Z`); (3) belt+suspenders alternative: tag the `main` commit immediately before §3.4 (`git tag pre-T11c-prod-rules <SHA>`) — the rules in repo IS what gets deployed, so the snapshot can also be recovered from git.
- [ ] **Sentry env detection verified PROD-tagged** for both widget and main app — per `audit/12` §2, `lib/core/utils/sentry_env.dart` derives env from `Firebase.app().options.projectId`. Smoke a deployed-widget error against `bookbed-widget.web.app` and confirm the Sentry event lands with `environment: production` (not `development`). Already validated for the dev path on `bookbed-widget-dev.web.app`.
- [ ] **iOS plist + Android google-services.json verified PROD**:
  ```bash
  grep PROJECT_ID ios/Runner/GoogleService-Info.plist        # → rab-booking-248fc
  grep project_id android/app/google-services.json            # → "project_id": "rab-booking-248fc",
  git status ios/Runner/GoogleService-Info.plist android/app/google-services.json  # both clean
  ```
  These don't affect the deploy itself (the cutover is server-side + widget hosting), but **operator must end the day on PROD configs** per `audit/21` "Active rules unchanged" sign-off + `.claude/rules/ios-development.md` + `.claude/rules/android-development.md`.
- [ ] **Test account isolation** — confirm `bookbed-test@bookbed.io` (per `memory/test-account.md`) has **NO PROD account**:
  ```bash
  # From a node session with prod Admin SDK creds
  admin.auth().getUserByEmail('bookbed-test@bookbed.io').catch(e => console.log('expected: not-found —', e.code))
  ```
  Should return `auth/user-not-found`. If a prod account exists, treat as a contamination repeat of Wave 0 (`audit/14`/`audit/15`) and abort the deploy until cleaned.
- [ ] **Rollback plan articulated** — see §5; operator acknowledges before starting.
- [ ] **Maintenance window scheduled** — see §7. Suggest 02:00–04:00 CET (lowest booking volume per dashboard analytics; user to confirm in §8 Q1).
- [ ] **Sentry alert channel active** — operator monitoring during the deploy window.
- [ ] **`audit/06-availability-cf-design.md` reconstructed** or this plan is annotated as standing in lieu of it (operator to choose in §8 Q6).

---

## 3. Deploy sequence (canonical order — DO NOT deviate)

Per `docs/SECURITY_FIXES.md` SF-019 "Prod cutover prerequisites" subsection + the dev-deploy sequence successfully validated 2026-05-22.

> **Why this exact order**: rules deploy is the lockout step. If rules go first, the live widget (still serving cached pre-T11c JS that issues direct `collectionGroup('bookings')` reads) starts getting `permission-denied` and the public booking flow breaks platform-wide. CF + widget bundle must be in place BEFORE the rules clamp down.

### Step 3.1 — Cloud Functions deploy

```bash
firebase deploy \
  --only functions:getUnitAvailability,functions:checkEmailVerificationStatus,functions:createSubscriptionCheckout,functions:syncIcal,functions:createConnectAccount,functions:createAccountLink,functions:processConnectPayment \
  --project rab-booking-248fc
```

Deploys (a) the `getUnitAvailability` callable (T11c + SF-023 backend), (b) the 6 callables touched by SF-022 catch-promote guards (`emailVerification.ts:466`, `stripeSubscription.ts:147`, `icalSync.ts:275`, 3 in `stripeConnect.ts`). Confirm exact CF names by running `firebase functions:list --project rab-booking-248fc` against current prod state — names above are derived from `functions/src/index.ts` exports and may need verbatim match.

**Expected duration**: 5–10 min per CF (cold deploy in `europe-west1`); ~30–45 min total for 7 functions.

**Success criteria**:
- `firebase functions:list --project rab-booking-248fc` shows updated `version` numbers post-deploy.
- Test invocation:
  ```bash
  curl -sS -X POST \
    "https://europe-west1-rab-booking-248fc.cloudfunctions.net/getUnitAvailability" \
    -H 'Content-Type: application/json' \
    -d '{"data":{"propertyId":"<PROD_property_id>","unitId":"<PROD_unit_id>","startDate":"2026-06-01","endDate":"2026-06-08"}}'
  ```
  Expect `200` with body `{"result":{"unitId":"…","windows":[…],"generatedAt":"…","cacheHint":30}}`. NOT `{"success":…,"blocks":…}` (that's the stale contract per `audit/21` Terminal C).
- SF-022 smoke: post-deploy `POST /checkEmailVerificationStatus -d '{"data":{}}'` returns **HTTP 400** + `status: INVALID_ARGUMENT` (was HTTP 500 + `INTERNAL` pre-fix).

### Step 3.2 — Firestore indexes deploy

```bash
firebase deploy --only firestore:indexes --project rab-booking-248fc
```

Adds the `daily_prices` COLLECTION composite (`available` + `date`). Without this, `getUnitAvailability` 500s on its first call against any unit with `daily_prices` docs (root cause of the dev's initial 500, per SF-019 "Dev deploy 2026-05-22" §1).

**Expected duration**: index build typically 30–120 s. **Wait an additional ~30 s after `READY`** — Firestore needs propagation time before queries actually use a new composite (observed on dev per SF-019 "Note: Firestore needs an additional ~30 s propagation after `READY` before queries actually use a new composite").

**Success criteria**: `firebase firestore:indexes --project rab-booking-248fc` shows the new index with `state: READY`.

### Step 3.3 — Widget bundle deploy

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs    # required after pub get on a fresh-state checkout per .claude/rules/build-runner.md
flutter build web --release --target lib/widget_main.dart
firebase deploy --only hosting:widget --project rab-booking-248fc
```

Ships the post-T11c widget that calls `getUnitAvailability` instead of issuing direct CG `bookings` / `ical_events` reads. Hosting deploy is global edge-cache flip; new clients pull the new bundle on next page load.

**Expected duration**: build ~3–5 min; hosting deploy ~1–2 min; edge propagation ≤ 5 min.

**Cache-bust check**:
```bash
curl -sI 'https://bookbed-widget.web.app/' | grep -i 'last-modified\|etag'
```
`last-modified` should match the deploy time (within minutes). Open an incognito tab against a known prod property `?property=<PROD_property_id>&unit=<PROD_unit_id>` — confirm calendar paints AND no `permission-denied` errors land in Sentry from the bundle.

> **Important — coexisting-contract window**: Between 3.1 (CF accepting the new `windows` contract) and 3.3 (bundle calling the new contract), browsers still holding the pre-T11c bundle from cache will (a) hit the old CF response shape (still works — server is backward-compatible) AND (b) attempt direct CG reads (still works — rules not yet locked). Between 3.3 and 3.4, both contracts coexist correctly. The only "broken" window is the moments after 3.4 when a stale-cache browser tries a direct CG read against the now-locked rules — see §6 risk row.

### Step 3.4 — Firestore rules deploy

```bash
firebase deploy --only firestore:rules --project rab-booking-248fc
```

**LAST.** Drops `unit_id+status` clause 1 from all 3 `bookings` rule surfaces; locks down `ical_events` per SF-023.

**Expected duration**: ≤ 1 min.

**Success criteria**:
- Anon read attempt against PROD CG bookings → `PERMISSION_DENIED`:
  ```bash
  # Standalone reproducer — should return 403
  curl -sS -X POST \
    "https://firestore.googleapis.com/v1/projects/rab-booking-248fc/databases/(default)/documents:runQuery" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" \
    -d '{"structuredQuery":{"from":[{"collectionId":"bookings","allDescendants":true}],"where":{"compositeFilter":{"op":"AND","filters":[{"fieldFilter":{"field":{"fieldPath":"unit_id"},"op":"EQUAL","value":{"stringValue":"<PROD_unit_id>"}}}]}}}}' \
    -o /dev/null -w "%{http_code}\n"
  ```
  Note: the `gcloud` auth token grants admin access; the realistic test is from an anonymous client (no auth at all) — confirm via incognito-browser network tab on the widget that no direct `runQuery` against CG bookings appears.
- Same anon read against CG `ical_events` → `PERMISSION_DENIED`.

### Step 3.5 — Storage rules deploy

```bash
firebase deploy --only storage --project rab-booking-248fc
```

**Concurrent with 3.4 OK** (separate file). Locks `/ical-exports/{p}/{u}/{...}` to owner read + 5 MiB write cap per SF-025.

**Expected duration**: ≤ 1 min.

**Success criteria**:
- Anonymous `GET https://firebasestorage.googleapis.com/v0/b/<bucket>/o/ical-exports%2F<p>%2F<u>%2Fcalendar.ics?alt=media` (no token) → 401.
- Owner-issued tokenized URL (via `getDownloadURL()`) still returns 200 + valid `.ics` body (download tokens bypass rules by design).

### Step 3.6 — SF-026 migration script execution

```bash
GOOGLE_CLOUD_PROJECT=rab-booking-248fc node functions/scripts/normalize-booking-nights.js --force \
  2>&1 | tee audit/migrations/2026-MM-DD-prod-sf026-normalize-FORCE.log
```

Backfills pre-fix bookings to UTC-midnight-Zagreb-civil-day. Idempotent — re-running yields zero updates.

**Expected duration**: depends on bookings count (~58 in PROD per `audit/15`); seconds to a minute.

**Idempotent verification**:
```bash
GOOGLE_CLOUD_PROJECT=rab-booking-248fc node functions/scripts/normalize-booking-nights.js
# Re-run in dry-run mode — should report:
#   Drifting check_in: 0
#   Drifting check_out: 0
#   Bookings to update: 0
```

> **Forward-only**: there is no inverse script. See §5 rollback for the failed-forward recovery posture.

---

## 4. Post-deploy validation

All checks must PASS before §7 declares the deploy successful. If any fail, follow §5 rollback for that surface.

| # | Check | Method | Pass = |
|---|---|---|---|
| 4.1 | `getUnitAvailability` live against PROD (anon caller allowed per CF design) | `curl` from §3.1 success-criteria invocation against a real PROD property/unit pair | HTTP 200 + valid `windows` array shape; cacheHint=30 |
| 4.2 | One real PROD booking dry-run through widget | Operator-owned test property OR coordinate with a real owner for one-off consent; cold incognito tab on `bookbed-widget.web.app/?property=…&unit=…`; select date, fill guest form, complete Stripe (test card okay if Stripe TEST mode is also live — otherwise abort at checkout step) | Calendar paints; no `permission-denied` in Sentry; if Stripe completes, booking lands in Firestore with normalized timestamps (date math agrees between Dart `numberOfNights` and TS `calculateBookingNights`) |
| 4.3 | Sentry dashboard 30-min watch | Tail `environment:production` events filtered by `service:functions` and `service:flutter-web` | No spike in `permission-denied` (Firestore), `INTERNAL` (CF), or `firebase_storage/unauthorized`; the SF-022 noise reduction should manifest as a noticeable DROP in CF `internal` events |
| 4.4 | iCal export sanity | Pick one PROD unit with a known existing iCal export token; subscribe via the dashboard-shared URL from an external consumer (e.g., `curl -sI`) | 200 + `text/calendar` body; tokenized URL still resolves (SF-025 download-token bypass) |
| 4.5 | Owner panel admin smoke | Log in as a known prod owner; load Timeline calendar; load Bookings list; load Settings | Calendar paints; bookings visible; no console errors |
| 4.6 | SF-022 metrics re-baseline | Re-run `POST /checkEmailVerificationStatus -d '{"data":{}}'` against prod | HTTP 400 + INVALID_ARGUMENT (was 500 + INTERNAL pre-fix) |
| 4.7 | Rules unit-test suite still passes locally against current prod-deployed rules | `cd functions && npm run test:rules` after pulling latest `main` | 24/24 green (`bookings.test.ts` + `ical_events.test.ts` + `widget_secrets.test.ts`) |

---

## 5. Rollback plan

**Trigger conditions** (any of, evaluated against the 30-min Sentry window):
- Net new `permission-denied` rate on `bookings` CG > 5 events/min OR > 50 over the window (suggests a widget-cache hold-out path or an unidentified call site).
- `getUnitAvailability` p50 latency > 2 s OR error rate > 2 % (CF + index issue).
- Any `INTERNAL` event class on `getUnitAvailability` more than 10×/min (catch-promote regression or unknown native-SDK failure).
- One or more owner reports of "calendar broken" / "blocked dates missing" / "cannot make booking" within 30 min of step 3.4.
- Any net new Stripe Connect error (SF-022 stripeConnect.ts changes regressed checkout).

**Per-surface rollback** (apply only the affected surface, not the whole stack — partial rollback minimizes blast radius):

| Surface | Rollback |
|---|---|
| Firestore rules | `firebase deploy --only firestore:rules --project rab-booking-248fc` from a temp branch that checks out `audit/migrations/2026-MM-DD-prod-firestore-rules-pre-T11c.snapshot` → `firestore.rules`. Restores public clause 1 on `bookings` + open read on `ical_events`. **Restores the pre-deploy security posture**, which was already understood-risky — but is recoverable, since dev parity exists. |
| Storage rules | Same procedure, swap in `…-storage-rules-pre-T11c.snapshot`. |
| Cloud Functions | Per-CF revert: `gcloud functions deploy <fn> --source=<previous-build-source>` is non-trivial since `firebase deploy` doesn't pin source archives. Realistic path: `git checkout <previous-main-commit> -- functions/src/` → `firebase deploy --only functions:<name1>,<name2>… --project rab-booking-248fc`. Document the previous commit SHA on `main` before deploy starts (`git log -1 main` → record). |
| Widget bundle | Re-deploy the previous build artifact from `firebase hosting:clone` or by checking out the previous main commit and rebuilding. Alternative: Firebase Console → Hosting → Releases → "Rollback" to last release. |
| `daily_prices` index | Cannot be deleted via `--only firestore:indexes` reliably. If keeping it causes harm (it shouldn't — it's additive), file via Firebase Console manual delete. No-op risk is much higher than removal risk. **Recommendation: leave the index in place even on rollback.** |
| SF-026 migration | **NONE — forward-only.** `normalize-booking-nights.js` does not save pre-images. If a backfill creates a regression (extremely unlikely — the operation is "snap to UTC midnight of the displayed Zagreb-civil-day"), recovery is **manual per-booking** using the dry-run log captured in step 3.6 (the script logs both old and new ISO strings per booking — sufficient to reverse by hand). Worst-case: bookings keep new (correct, displayable) dates and any night-count drift in pre-existing rows is recomputed once by the new derivation path. Document the data-shape change so failed-forward state is operator-recoverable. |

**Note**: Rolling back ONLY the rules step (3.4) restores the public-read state but leaves the new CF + widget bundle running — both are backward-compatible. This is the cleanest single-step recovery if the failure mode is "rules-deploy blocked something".

---

## 6. Risk register

| # | Risk | Severity | Mitigation | Abort trigger |
|---|---|---|---|---|
| R1 | Widget direct-CG reads from cached old bundle hit locked rules after step 3.4, browsers throw `permission-denied`, owners report broken widget | High | (a) Deploy 3.3 fully propagated (≤ 5 min) BEFORE 3.4. (b) Maintenance window at low-traffic hour (02:00–04:00 CET). (c) Sentry watch in 30-min validation window. (d) §5 rules rollback is single-command + minutes to recover. | Permission-denied rate > 5/min sustained 5 min |
| R2 | `atomicBooking` transaction race during SF-026 migration: a booking is being written (STEP 6 of new normalize path) at the same instant the migration tries to update its `check_in`/`check_out` | Medium | Migration runs in §3.6 AFTER all writes go through the new normalize path (per §3.1 functions deploy); no booking pre-step-3.6 can land with non-normalized timestamps. Migration runs in 400-batch transactions; Firestore guarantees `update` on existing doc is atomic. **Practical**: schedule §3.6 outside peak booking-write hours; window suggestion 02:00–04:00 CET also satisfies this. | Migration script reports `FATAL` or any batch commit fails |
| R3 | Sentry alert flood masks a real new issue | Medium | (a) Pre-deploy: ensure Sentry rate-limit/sampling isn't suppressing the surface. (b) During: filter to `service:functions environment:production created:>=<deploy_start>` only; don't try to read live noise. (c) Post: 30-min watch deliberately small; re-evaluate at 6h + 24h marks before declaring done. | A specific signal can't be distinguished from noise within 15 min — escalate to manual SQL query against Firestore + Cloud Logging directly |
| R4 | Rules-deploy timing window: CF must accept new contract BEFORE rules lock down direct reads | Critical | Step order in §3 enforces 3.1 → 3.2 → 3.3 → 3.4. Operator does NOT advance to 3.4 until 3.3 cache-bust check passes AND 3.1 CF smoke from §3.1 success-criteria passes. The intentional design is "CF and widget both green, then rules". | Skipping any of 3.1/3.2/3.3 — abort cutover, do not proceed |
| R5 | `daily_prices` COLLECTION index not built in time, `getUnitAvailability` 500s | Medium | Step 3.2 explicitly inserts a 30-s post-`READY` propagation wait per the SF-019 dev observation. Re-test §3.1's smoke `curl` after the wait before advancing. | First post-`READY` `getUnitAvailability` call returns 500 with "index currently building" — wait, retry; if still failing after 5 min, abort and investigate |
| R6 | Stripe Connect callable regression from SF-022 catch-promote guard breaks live owner onboarding/payouts | High | `stripeConnect.ts` 3 callables touched. Smoke: trigger one Stripe Connect onboarding link generation against a known prod owner; expect 200 + valid URL. Pre-existing client-fault errors (`not-found` for missing user docs) now correctly return as 404 (not 500). | Owner reports "cannot create Stripe Connect account" / payouts dashboard error |
| R7 | iCal subscribers break (Booking.com / Airbnb / Adriagate polling the export URLs) | Medium | SF-025 preserves download-token bypass — tokenized URLs continue working. Only tokenless path-guess GETs are now denied. Owners who shared raw paths (rare; only via direct dashboard tokenized URL flow) would re-share. Communicate to support inbox. | Owners report "external calendar stopped syncing" — verify their subscription URL has the token query-param |
| R8 | Audit/06 design doc missing → operator unaware of subtle constraint | Low | This plan restates the canonical CF→widget→rules ordering from SF-019 verbatim; SF-019 is the operational source of truth. If audit/06 has additional constraints (e.g., specific pacing between steps), they're recoverable from `audit/06-bookings-hotfix-partial.md` + commit messages on PR #446. Operator should re-read those before kickoff. | (Not abortable — investigative gap; addressable in §8 Q6) |

---

## 7. Authorization checklist

Per CLAUDE.md sign-off rule: **"No PROD deploy without explicit per-deploy user authorization"** (`audit/21` §"Active rules unchanged"). All four items signed before §3 starts.

- [ ] **User explicitly authorizes this deploy on date YYYY-MM-DD**: __________________
- [ ] **User confirms maintenance window (02:00–04:00 CET suggested, lowest booking volume per analytics; alternate proposals welcome)**: __________________
- [ ] **User confirms rollback path acknowledged** (§5 read end-to-end, no surprises): __________________
- [ ] **User confirms Sentry alert channel monitored during deploy** (acknowledges responsibility for first response in the 30-min validation window): __________________

---

## 8. Open questions for user (block deploy until answered)

**Q1.** Confirm preferred deploy date + maintenance window. Suggestion: 02:00–04:00 CET on a midweek night (Tue/Wed/Thu) outside school-holiday peaks. Lowest booking volume per dashboard. Does this match what you see in BookBed analytics?

**Q2.** ~~Confirm widget bundle on `bookbed-widget.web.app` is currently the **pre-T11c** build…~~ **RESOLVED 2026-05-23** (`audit/24`). Probed `bookbed-widget.web.app/` + `bookbed-widget.web.app/flutter_bootstrap.js`: both return `last-modified: Thu, 21 May 2026 18:50:32 GMT`. T11c merged 2026-05-22 (`ab6bdb3d`), so PROD is **pre-T11c** and §3.3 rebuild + redeploy IS required. Bootstrap ETags also differ between PROD (`153608da33...`) and DEV (`e71fa54a52...`) — corroborates different bundles.

**Q3.** ~~What is the correct `firebase` CLI subcommand for fetching the deployed rules ruleset…~~ **RESOLVED 2026-05-23** (`audit/24`). Firebase CLI exposes no `:rules:get` subcommand (verified against `firebase --help` for both top-level and `firebase firestore` namespaces; only deploy-side `firebase deploy --only firestore:rules` exists). **Working method**: Firebase Rules REST API (`firebaserules.googleapis.com/v1`) with `Authorization: Bearer $(gcloud auth print-access-token)` + `X-Goog-User-Project: <project-id>`. Two-call flow: (1) `GET /v1/projects/<project>/releases/cloud.firestore` returns `rulesetName`; (2) `GET /v1/<rulesetName>` returns full source content. Without `X-Goog-User-Project` header the API errors `403 SERVICE_DISABLED`. Full commands now embedded in §2 pre-flight "Backup current PROD rules" item. Belt+suspenders option (b) remains valid: tag `main` immediately before §3.4 and recover rules from git.

**Q4.** Has SF-026's migration script been tested against any prod-shape data in dev (e.g., copying a few real PROD booking docs to dev, running dry-run, verifying expected drift output)? If not, the §3.6 prod `--force` run is the first real-data validation — acceptable since the operation is idempotent and recoverable manually, but worth knowing.

**Q5.** Acknowledge the **coexisting-contract transient window**: during the 5–10 min between §3.1 CF deploy and §3.4 rules deploy, the widget can be hit by clients on both pre-T11c and post-T11c bundles. Both contracts work correctly during this window (CF accepts both shapes; rules still allow direct reads). Between §3.4 and the moment the last stale-cache browser refreshes, a small minority of requests may hit `permission-denied`. Acceptable per the SF-019 maintenance-window protocol — confirm acknowledged.

**Q6.** **`audit/06-availability-cf-design.md` is missing** (referenced by CLAUDE.md "NIKADA NE MIJENJAJ" T11c row + SF-019 §Outstanding deferral). Do you want me to (a) reconstruct it from PR #446 commit log + this plan, OR (b) leave it as an open documentation gap and treat audit/22 + SF-019 as the canonical deploy reference? Either way, the cutover can proceed; this is documentation hygiene, not a blocker.

---

## 9. Estimated total deploy time

| Phase | Duration |
|---|---|
| §3.1 Cloud Functions deploy (7 callables, EU west) | 30–45 min |
| §3.2 Firestore indexes deploy + propagation wait | 2–5 min |
| §3.3 Widget bundle build + hosting deploy + cache-bust verify | 8–12 min |
| §3.4 Firestore rules deploy + anon-read smoke verify | 2–3 min |
| §3.5 Storage rules deploy + anon-GET smoke | 2 min |
| §3.6 SF-026 migration --force + idempotent re-verify | 2 min |
| §4 Post-deploy validation (7 checks; Sentry watch is parallel) | 30–40 min |
| **End-to-end** (best case, no rollbacks) | **75–110 min** |
| **End-to-end** (with one partial rollback + retry) | **+30–45 min** |

Total realistic budget: **90–120 min**. Block out a 2-hour maintenance window with operator availability for the full duration.

---

## Sign-off (post-deploy, appended after execution)

To be filled in after successful cutover:

- Deploy date/time (UTC): __________________
- Pre-deploy `main` SHA: __________________
- Post-deploy `main` SHA: __________________
- Pre-deploy rules snapshot path: __________________
- Post-deploy dry-run idempotency log path: __________________
- Sentry 30-min summary: __________________
- 6h follow-up summary: __________________
- 24h follow-up summary: __________________
- Outstanding items for next session: __________________
