# audit/33 — TIER 4 Owner Dashboard web smoke (chrome-devtools MCP) — **HALTED ON P1 CONTAMINATION FINDING**

**Date:** 2026-05-24 (07:48 UTC)
**Scope:** Six-checkpoint pure-observation smoke of Owner Dashboard dev hosting (`bookbed-owner-dev.web.app`). **Halted after A1 due to P1 finding: dev hosting URL serves PROD-connected build.**
**Predecessors:** `audit/32-tier4-widget-ui-smoke-2026-05-23.md` (sister surface, widget side — passed clean), `audit/14-deploy-scripts-mismatch.md` (origin of the deploy-mismatch contamination class on iOS/Android), `audit/15-prod-contamination-deep-check.md` (cleanup recipe for prior contamination), `.claude/rules/hosting-build.md` (Footgun + Build-commands sections).

> **Run discipline:** task explicitly observation-only. After A1 first network probe showed Firestore writes targeting `rab-booking-248fc` (PROD project per `.claude/rules/hosting-build.md`), all interactive testing was halted to prevent further accidental writes to PROD. The login attempt itself triggered 2 `POST /Write/channel` requests against the PROD database — these are unintentional writes documented in §3.1.

---

## 1. Result matrix

| # | Checkpoint | Status | Reason |
|---|---|---|---|
| A1 | Login flow | 🛑 **BLOCKED — P1 finding** | `bookbed-owner-dev.web.app` build connects to **PROD Firebase project `rab-booking-248fc`**, NOT dev. Test account `bookbed-test@bookbed.io` lives on `bookbed-dev` per `memory/test-account.md` → password rejected on PROD auth. Login failed cleanly; but the AUTH ATTEMPT ITSELF caused 2 unintended Firestore writes to PROD (`POST /Write/channel` against `projects/rab-booking-248fc/databases/(default)`). |
| A2 | Bookings list | ⛔ NOT EXECUTED | Cannot proceed — env contamination violates task `SAFETY` clause "Dev env only". Login also blocked. |
| A3 | Calendar Timeline | ⛔ NOT EXECUTED | Same. |
| A4 | Calendar Month | ⛔ NOT EXECUTED | Same. |
| A5 | Unit Hub | ⛔ NOT EXECUTED | Same. |
| A6 | Logout | ⛔ NOT EXECUTED | Cannot logout if never logged in. |

**Verdict:** 1/6 🛑 BLOCKED (with P1 finding), 5/6 ⛔ NOT EXECUTED. **Highest-priority output of this run = the P1 finding below.**

---

## 2. P1 finding — `bookbed-owner-dev.web.app` serves PROD-connected build (F-OwnerDashboard-001)

### 2.1 Observation

After navigating to `https://bookbed-owner-dev.web.app` and submitting the login form with `bookbed-test@bookbed.io` / `BookBedTest2026!`:

**Network panel (chrome-devtools `list_network_requests`, fetch/xhr filter):**

```
reqid=44  POST  https://firestore.googleapis.com/google.firestore.v1.Firestore/Write/channel
                ?VER=8&database=projects%2Frab-booking-248fc%2Fdatabases%2F(default)... [200]
reqid=45  GET   https://firestore.googleapis.com/google.firestore.v1.Firestore/Write/channel
                ?gsessionid=...&database=projects%2Frab-booking-248fc%2Fdatabases%2F(default)... [200]
reqid=46  POST  https://firestore.googleapis.com/google.firestore.v1.Firestore/Write/channel
                ?VER=8&database=projects%2Frab-booking-248fc%2Fdatabases%2F(default)... [200]
reqid=47  POST  https://firestore.googleapis.com/google.firestore.v1.Firestore/Listen/channel
                ?VER=8&database=projects%2Frab-booking-248fc%2Fdatabases%2F(default)... [200]
reqid=48  POST  https://firestore.googleapis.com/google.firestore.v1.Firestore/Listen/channel
                ?VER=8&database=projects%2Frab-booking-248fc%2Fdatabases%2F(default)... [200]
```

URL-decoded path: `projects/rab-booking-248fc/databases/(default)`.

### 2.2 Why this is PROD

Per `.claude/rules/hosting-build.md` §"Tri Firebase projekta":

| Alias | Project ID |
|---|---|
| `default` / `production` | **`rab-booking-248fc`** — PROD (Stripe LIVE, Resend prod sender) |
| `development` | `bookbed-dev` |
| `staging` | `bookbed-staging` |

Per `.claude/rules/ios-development.md` + `android-development.md`: `rab-booking-248fc` is the PROD project that contaminated Wave 0 (`audit/14`, `audit/15`).

→ The dev hosting URL serves a build whose `firebase_options.dart` resolves to PROD config.

### 2.3 Root cause analysis

`.firebaserc` correctly maps `bookbed-owner-dev` SITE → `bookbed-dev` PROJECT (lines 22-33):

```json
"bookbed-dev": {
  "hosting": {
    "owner": ["bookbed-owner-dev"]
  }
}
```

So the **hosting is on dev project** — that part is correct.

But the **BUILD that was deployed bundles PROD `firebase_options.dart`**. Reason:

1. `EnvironmentConfig._current` defaults to `Environment.development` (line 5 of `lib/core/config/environment.dart`) BUT each entry point overrides via `setEnvironment()`.
2. `lib/main.dart` calls `setEnvironment(Environment.production)` (canonical PROD entry).
3. `lib/main_dev.dart` calls `setEnvironment(Environment.development)`.
4. Per `.claude/rules/hosting-build.md` §"Build commands", the ONLY documented owner build is:
   ```bash
   flutter build web --release --target lib/main.dart -o build/web_owner
   ```
   → uses `lib/main.dart` (PROD entry) regardless of where the build will be deployed.
5. There is **NO automated workflow** for owner dashboard deploy (`.github/workflows/` contains only `deploy-widget.yml` which is PROD-only at line 41 `--target lib/widget_main.dart`, line 57 `projectId: rab-booking-248fc`).
6. Therefore the manual `bookbed-owner-dev.web.app` deploy was almost certainly done by running the documented build command + `firebase deploy --only hosting:owner --project bookbed-dev`. The build step compiled with PROD options; the deploy step put the PROD-options-bundled build onto the dev hosting site.
7. The runtime then reads bundled `firebase_options.dart` → connects to `rab-booking-248fc` (PROD) regardless of which hosting site serves the JS.

### 2.4 Why login failed

`bookbed-test@bookbed.io / BookBedTest2026!` (per `memory/test-account.md`, UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`) exists on `bookbed-dev`, NOT on PROD `rab-booking-248fc`. PROD Firebase Auth returned `auth/invalid-credential` or similar → UI shows "Pogrešna lozinka. Molimo pokušajte ponovo." (the error message generic-izes "user not found" + "wrong password" for security per Firebase Auth defaults).

**Silver lining:** because the account doesn't exist on PROD, no owner-doc was created on PROD as a side-effect of the auth attempt. The 2 Firestore writes that DID happen (reqid 44, 46) are most likely App Check token writes or similar bootstrap state — not owner-data writes. Owner-data contamination only happens if a REAL prod account is used to login against this URL.

### 2.5 Severity: **P1 / HIGH**

| Vector | Risk |
|---|---|
| Someone with PROD owner credentials uses `bookbed-owner-dev.web.app` for dev testing | Real PROD owner data mutated — bookings created/edited/cancelled, properties touched, Stripe Connect actions on LIVE keys |
| Wave 0 contamination class precedent (`audit/14`, `audit/15`) | Already happened on iOS/Android — cleanup required Stripe Connect orphan deletion + Auth user removal. Web version of same risk class. |
| The URL is **labelled "-dev"** in the subdomain | Operators trust the label; this is exactly how Wave 0 fired — `flutter run -d <device>` against the prod plist with dev-named target. |
| Smoke testing audits would all hit PROD if account were valid on PROD | This audit caught it before doing damage; future audits won't get the same luck. |

### 2.6 Recommended fix

Three layers (defense in depth, low cost):

**(a) Create per-env owner build commands in `.claude/rules/hosting-build.md`** (~10 min):
```bash
# DEV
flutter build web --release --target lib/main_dev.dart -o build/web_owner_dev
firebase deploy --only hosting:owner --project bookbed-dev

# STAGING
flutter build web --release --target lib/main_staging.dart -o build/web_owner_staging
firebase deploy --only hosting:owner --project bookbed-staging

# PROD (current docs)
flutter build web --release --target lib/main.dart -o build/web_owner
firebase deploy --only hosting:owner --project rab-booking-248fc
```

**(b) Add `deploy-owner-dev.yml` GitHub Action** (~30 min):
- Trigger on push to `main` paths `lib/**` + `pubspec.yaml`
- Build with `--target lib/main_dev.dart`
- Deploy to `bookbed-dev` project, target `owner`
- Mirror the same pattern for `deploy-admin-dev.yml` and `deploy-widget-dev.yml`

**(c) Runtime assert in entry points** (analog to `.claude/rules/ios-development.md` "Defense-in-depth — Dart-level assert"): the existing entry points already SHOULD assert that `Firebase.app().options.projectId == EnvironmentConfig.firebaseProjectId` in `kDebugMode`. **Verify** — if not present in `main.dart`/`main_dev.dart`/`main_staging.dart`, add it. Then dev-built-with-prod-options will crash visibly on debug instead of silently sending writes to PROD.

**(d) Re-deploy `bookbed-owner-dev.web.app` IMMEDIATELY** with `--target lib/main_dev.dart` to stop the live contamination. Same for `bookbed-admin-dev.web.app` (likely same bug, untested here). Same for `bookbed-widget-dev.web.app` — but `audit/32` confirmed widget dev hits the correct `bookbed-dev` Cloud Functions (CF region `europe-west1-bookbed-dev.cloudfunctions.net`), so widget side is probably built correctly OR widget paths happen to not hit Firestore from the bundle directly. **Verify widget separately**; don't assume.

### 2.7 What was actually written to PROD during this run

Two Firestore POST writes to PROD `projects/rab-booking-248fc/databases/(default)/(default)` during the login attempt. The exact docs/collections are not visible from chrome-devtools Network panel (Firestore uses gRPC-Web `Write/channel` opaque protocol). Best-guess candidates from app initialization sequence:

| Candidate write | Source |
|---|---|
| App Check token | `firebase_app_check` init writes attestation record |
| Analytics event (login_attempt or screen_view) | `firebase_analytics` writes to `analytics_events` if configured |
| Login rate-limit / failedAttempts counter | per `memory/future-todos.md` — may be writing a counter doc for the email even on failed login |
| Default `users/{uid}` doc — UNLIKELY because auth never succeeded; no uid was minted |

**Recommended PROD cleanup** (operator action, not in scope here):
- Query PROD Firestore for any docs created in the window 2026-05-24 07:48:00 to 07:49:30 UTC.
- Cross-reference with `analytics_events`, `app_check_tokens`, `login_attempts`/`rate_limits`, or other ephemeral collections.
- Delete any debris (likely 0–5 docs; non-critical data — App Check + analytics regenerate harmlessly).
- This audit's evidence: 2 `POST /Write/channel` calls captured; both returned `200`.

---

## 3. Setup + execution log

### 3.1 Pre-flight ✅

- `git branch --show-current` → `main`
- `git status --short` → `?? .mcp.json`, `?? jest_dx/` (pre-existing untracked, not from this run)
- chrome-devtools MCP available (verified by `new_page` returning page 5 with isolated context `owner-smoke-a1`)

### 3.2 A1 execution

1. `new_page` `https://bookbed-owner-dev.web.app` in isolated context `owner-smoke-a1`.
2. Initial probe via JS — Flutter CanvasKit, no a11y placeholder visible. Took `take_snapshot` → semantic tree already enabled (Owner dashboard's login flow seems to ship a11y on by default, unlike widget which needs the focus+Enter dance per audit/32 §1.1). 23 uids returned including:
   - uid 22_4 "Prijava vlasnika" (Owner Sign-in)
   - uid 22_7 email textbox
   - uid 22_9 password textbox
   - uid 22_11 "Zapamti me" checkbox (Remember Me, checked)
   - uid 22_13 "Prijava" submit button
3. `fill` uid 22_7 = `bookbed-test@bookbed.io` ✓
4. `fill` uid 22_9 = `BookBedTest2026!` ✓
5. `click` uid 22_13 submit ✓
6. `wait_for ["Pregled", "Rezervacije", "Kalendar", "Bookings", "Dashboard", "BookBed"]` → matched on "BookBed" (page title unchanged — wait_for matched the static title, not a navigation).
7. Take snapshot: NEW elements `uid 23_0 / 23_3 "Pogrešna lozinka. Molimo pokušajte ponovo."` + password field marked `invalid="true"`. **Login failed.**
8. `list_console_messages` (error filter):
   - `Uncaught TypeError: Cannot read properties of null (reading 'toString')` (msgid 47) — unrelated to login, likely a Flutter null-safe gap
   - `Failed to load resource: the server responded with a status of 400` (msgid 50) — the failed login response from Firebase Auth REST
9. `list_network_requests` (fetch/xhr filter, page 2 of 2):
   - **5 Firestore requests targeting `projects/rab-booking-248fc/databases/(default)`** — see §2.1
10. JS probe `EnvironmentConfig.firebaseProjectId`: not directly accessible (Flutter web obfuscates), but bundle scripts confirmed:
    - `https://bookbed-owner-dev.web.app/main.dart.js` (full bundle, would need source map to extract baked project ID; runtime behavior is the authoritative signal via Network panel)
    - `https://bookbed-owner-dev.web.app/payment_bridge.js`
    - `https://bookbed-owner-dev.web.app/flutter_bootstrap.js`

### 3.3 A2–A6 NOT EXECUTED

Halted per safety constraint after A1's PROD-contamination discovery. No further interactive tests run.

### 3.4 Screenshots

- `a1-login-page.jpeg` — login form before submit (Croatian UI, all fields visible)
- `a1-CRITICAL-prod-contamination.jpeg` — error state "Pogrešna lozinka" after PROD auth rejection

Both at `$TMPDIR/bb-smoke-h-shots/`.

---

## 4. Net new findings

### 4.1 N1 — Owner Dashboard dev hosting serves PROD-connected build (F-OwnerDashboard-001, P1)

Detailed in §2. Recommended fix in §2.6.

### 4.2 N2 — `.claude/rules/hosting-build.md` Build commands section is missing per-env owner/admin variants

Per §2.3 step 4, the canonical doc only shows the PROD `--target lib/main.dart` build line. This is the documentation root cause of the per-env build mistake. Adding the dev/staging variants (per §2.6 fix (a)) is ~10 min of doc work but prevents future operator error.

### 4.3 N3 — No automated dev/staging deploy workflows exist

`.github/workflows/` has only `deploy-widget.yml` (PROD only). No `deploy-{widget,owner,admin}-{dev,staging}.yml`. All non-prod deploys are manual. This compounds N2 — without an automated workflow that uses the right entry point, every manual deploy is a chance to bundle the wrong env.

### 4.4 N4 — Console error on login page: `Cannot read properties of null (reading 'toString')`

Captured during initial load BEFORE any login attempt. Unrelated to PROD contamination — likely a Flutter null-safe gap in the login screen. Not investigated further (out of scope; flag for backlog). Possibly the same class as `memory/flutter-web-uri-null-tostring.md` (Uri null-toString crash). Reproduction: load `https://bookbed-owner-dev.web.app` in fresh incognito + DevTools console open.

---

## 5. Cross-refs

- `audit/14-deploy-scripts-mismatch.md` — origin of the deploy-mismatch contamination class (iOS/Android)
- `audit/15-prod-contamination-deep-check.md` — Stripe Connect cleanup recipe; applicable if real owner login on this URL happened in the past
- `audit/32-tier4-widget-ui-smoke-2026-05-23.md` — sister-surface smoke; widget side was clean (`europe-west1-bookbed-dev.cloudfunctions.net` confirmed in CP1 network panel)
- `.claude/rules/hosting-build.md` §"Footgun: GitHub Actions workflow" — already documents one footgun (workflow hardcodes PROD); this audit adds N2 + N3 in the same class
- `.claude/rules/ios-development.md` §"Defense-in-depth — Dart-level assert" — recommended for web too (§2.6 (c))
- `memory/test-account.md` — `bookbed-test@bookbed.io / BookBedTest2026!` on `bookbed-dev` (not PROD, hence A1 login failure)
- `memory/firebase-projects.md` — three-project topology
- `memory/wave0-test-findings.md` — original Wave 0 contamination context

---

## 6. Open items + handoff

### 6.1 Immediate operator actions (P1)

1. **Re-deploy `bookbed-owner-dev.web.app`** with `--target lib/main_dev.dart` to stop ongoing contamination.
2. **Verify `bookbed-admin-dev.web.app`** — almost certainly has the same bug. Check Network panel after navigating to login.
3. **Audit recent PROD Firestore writes** from any IP/UA that looks like dev testing — see §2.7 cleanup recommendation.
4. **Stripe Connect dev test accounts** — verify no real Stripe Connect onboarding was triggered via this URL in the past 30 days.

### 6.2 Doc/process actions (~1 hour total)

1. Add per-env build commands to `.claude/rules/hosting-build.md` §Build commands (per §2.6 (a)).
2. Create `deploy-owner-dev.yml` + `deploy-admin-dev.yml` + `deploy-widget-dev.yml` workflows (per §2.6 (b)).
3. Verify Dart-level entry-point asserts exist in `main.dart`/`main_dev.dart`/`main_staging.dart` (per §2.6 (c)).
4. Update `audit/14-deploy-scripts-mismatch.md` cross-ref — web is now in the same contamination class as iOS/Android.

### 6.3 Smoke re-run plan

After §6.1 fix (1) lands:
- Re-run this audit as `audit/33-owner-dashboard-web-smoke-RERUN-<date>.md` with same A1–A6 sequence.
- Confirm Network panel shows `projects/bookbed-dev/databases/(default)`.
- Then proceed with full A1–A6 execution.

---

## 7. Worktree deviation (consistent with audit/32 §6.1)

- Path: `$TMPDIR/bb-smoke-owner-wt` (not `/tmp/bb-smoke-owner-wt` — workspace-root restriction)
- Branch: `doc/audit-33-owner-smoke` (not `main` — git refuses two worktrees on same branch)

---

## 8. Sign-off

| Section | State |
|---|---|
| §1 result matrix (1 BLOCKED, 5 NOT EXECUTED) | ✅ |
| §2 P1 finding F-OwnerDashboard-001 + root cause + fix | ✅ |
| §3 execution log A1 + halt rationale | ✅ |
| §4 net new findings (N1 P1 / N2-N4 LOW) | ✅ |
| §5 cross-refs | ✅ |
| §6 operator handoff | ✅ |

**Status:** Smoke halted on P1 contamination finding. Highest-priority output = §2 + §6.1 immediate operator actions. Awaiting user authorization to push `doc/audit-33-owner-smoke` → main and trigger §6.1 actions.

**No code mutations made.** Two unintended Firestore writes hit PROD during the (failed) login attempt — opaque protocol, low-impact best-guess (App Check / analytics / rate-limit counter). Documented in §2.7.
