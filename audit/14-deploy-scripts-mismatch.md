# Deploy Scripts ↔ Firebase Project Mismatch Audit

**Date:** 2026-05-21
**Branch:** `main` @ `c6fb7dea`
**Status:** READ-ONLY audit. No code changes. No deploys.
**Severity:** **HIGH** — confirmed prod data contamination from test activity (limited blast radius, see Data Impact).

---

## TL;DR

`scripts/deploy_dev.sh` and `scripts/deploy_staging.sh` both build `lib/widget_main.dart` for the widget hosting target. `widget_main.dart` imports `firebase_options.dart` (PROD). Result: widget deployed to `bookbed-widget-dev.web.app` and `bookbed-widget-staging.web.app` **connects to the production Firebase project `rab-booking-248fc`**, not to `bookbed-dev` / `bookbed-staging`.

Owner dashboard side is **correctly wired** (`main_dev.dart` / `main_staging.dart` exist and are used). Admin side has staging entry point but no deploy script of its own.

PROD project today contains one orphan test owner + property left over from Wave 0 testing on 2026-05-18. Zero bookings ever landed on the test property, so no Stripe transactions or guest emails were affected.

---

## TASK 1 — Inventory of deploy scripts

| Script | Path | Last modified |
|---|---|---|
| `deploy_dev.sh` | `scripts/deploy_dev.sh` | git: 2026-01-23 (`cbb4d375`) |
| `deploy_staging.sh` | `scripts/deploy_staging.sh` | git: same era |
| `deploy_prod.sh` | `scripts/deploy_prod.sh` | git: same era |
| `build_all_web.sh` | `scripts/build_all_web.sh` | build-only, no deploy |
| `.github/workflows/deploy-widget.yml` | CI workflow | prod-only widget deploy |

No `deploy/*.sh` directory, no root-level `deploy_*.sh`.

### Full content (verbatim)

**`scripts/deploy_dev.sh`**
```bash
#!/bin/bash
echo "🔧 Deploying to DEVELOPMENT..."
firebase use development
echo "📦 Building widget..."
flutter build web --release --target lib/widget_main.dart -o build/web_widget   # ← BUG
echo "📦 Building owner dashboard..."
flutter build web --release --target lib/main_dev.dart -o build/web_owner       # ← ok
./scripts/update_og_tags.sh
firebase deploy --only hosting,functions
```

**`scripts/deploy_staging.sh`**
```bash
#!/bin/bash
echo "🎭 Deploying to STAGING..."
firebase use staging
echo "📦 Building widget..."
flutter build web --release --target lib/widget_main.dart -o build/web_widget   # ← BUG
echo "📦 Building owner dashboard..."
flutter build web --release --target lib/main_staging.dart -o build/web_owner   # ← ok
./scripts/update_og_tags.sh
firebase deploy --only hosting,functions
```

**`scripts/deploy_prod.sh`**
```bash
#!/bin/bash
read -p "Type 'yes' to continue: " confirm
firebase use production
flutter build web --release --target lib/widget_main.dart -o build/web_widget   # ← ok (prod)
flutter build web --release --target lib/main_prod.dart -o build/web_owner      # ← ok (prod)
./scripts/update_og_tags.sh
firebase deploy --only hosting,functions
```

**`.github/workflows/deploy-widget.yml`** — prod-only, hardcoded `projectId: rab-booking-248fc`. Builds `widget_main.dart` → consistent with prod target.

**`scripts/build_all_web.sh`** — local build helper. Builds `lib/main.dart` for owner (not `main_prod.dart`), `lib/widget_main.dart` for widget, `lib/admin_main.dart` for admin. Does not deploy. Stale (predates env-aware entry points).

Admin: **no dedicated deploy script** despite `admin_main_production.dart` and `admin_main_staging.dart` both existing. Admin must be deployed manually via Firebase CLI today.

---

## TASK 2 — Per-script map: deploy target ↔ entry point ↔ firebase_options

| Script | `firebase use` | Widget target | Widget imports | Owner target | Owner imports | Admin target | Admin imports |
|---|---|---|---|---|---|---|---|
| `deploy_dev.sh` | `development` (bookbed-dev) | `widget_main.dart` | **`firebase_options.dart` (PROD)** ❌ | `main_dev.dart` | `firebase_options_dev.dart` ✓ | none | — |
| `deploy_staging.sh` | `staging` (bookbed-staging) | `widget_main.dart` | **`firebase_options.dart` (PROD)** ❌ | `main_staging.dart` | `firebase_options_staging.dart` ✓ | none | — |
| `deploy_prod.sh` | `production` (rab-booking-248fc) | `widget_main.dart` | `firebase_options.dart` (PROD) ✓ | `main_prod.dart` | `firebase_options.dart` (PROD) ✓ | none | — |
| `build_all_web.sh` | — | `widget_main.dart` | PROD imports | `main.dart` | PROD imports (no setEnvironment) | `admin_main.dart` | PROD imports |
| `deploy-widget.yml` | hardcoded `rab-booking-248fc` | `widget_main.dart` | PROD ✓ | — | — | — | — |

---

## TASK 3 — `firebase_options*.dart` inventory

| File | `projectId` |
|---|---|
| `lib/firebase_options.dart` | `rab-booking-248fc` (PROD) |
| `lib/firebase_options_dev.dart` | `bookbed-dev` |
| `lib/firebase_options_staging.dart` | `bookbed-staging` |

All three populate `projectId`, `appId`, `apiKey`, etc. for their respective Firebase projects. There is no admin-specific options file.

### Entry-point ↔ options matrix

| Entry point | Imports | Init project | `setEnvironment` called |
|---|---|---|---|
| `lib/main.dart` (shared) | `firebase_options.dart` | — (called by main_*) | — |
| `lib/main_dev.dart` | `firebase_options_dev.dart` | bookbed-dev | `development` ✓ |
| `lib/main_staging.dart` | `firebase_options_staging.dart` | bookbed-staging | `staging` ✓ |
| `lib/main_prod.dart` | `firebase_options.dart` | rab-booking-248fc | `production` ✓ |
| `lib/widget_main.dart` | `firebase_options.dart` | rab-booking-248fc | **none** |
| `lib/widget_main_dev.dart` | `firebase_options_dev.dart` | bookbed-dev | **none** |
| `lib/widget_main_staging.dart` | **FILE DOES NOT EXIST** | — | — |
| `lib/admin_main.dart` | `firebase_options.dart` | rab-booking-248fc | none |
| `lib/admin_main_staging.dart` | `firebase_options_staging.dart` | bookbed-staging | none |
| `lib/admin_main_production.dart` | `firebase_options.dart` | rab-booking-248fc | none |

**Missing files:** `lib/widget_main_staging.dart`, `lib/admin_main_development.dart` (if dev admin is needed). Per `.claude/rules/hosting-build.md` — "Admin nema dev entrypoint (samo prod + staging)" — admin dev is intentionally absent.

---

## TASK 4 — Cross-reference + mismatches

Three confirmed mismatches:

### Mismatch 1: `deploy_dev.sh` widget (HIGH)
- Target: `bookbed-widget-dev.web.app`
- Builds: `lib/widget_main.dart` which imports `firebase_options.dart` → init project = `rab-booking-248fc` (PROD)
- Effective behavior: widget at the dev hosting URL talks to **PROD Firestore + Auth + Functions + Stripe (LIVE!)**
- Existed since `lib/widget_main_dev.dart` was first added (2026-01-10 `a85a33f5`). 4+ months in this state.

### Mismatch 2: `deploy_staging.sh` widget (HIGH)
- Target: `bookbed-widget-staging.web.app`
- Same root cause as Mismatch 1.
- Compounded: `lib/widget_main_staging.dart` doesn't exist, so there's no easy fix — must be created.

### Mismatch 3: `build_all_web.sh` (LOW)
- Builds `lib/main.dart` for owner. `main.dart` is the shared core, expected to be called via `main_dev/staging/prod.dart` which set `EnvironmentConfig.setEnvironment(...)` first.
- When invoked directly, `EnvironmentConfig._current` defaults to `Environment.development` (per `environment.dart:5`).
- Side effects in app code that branch on `EnvironmentConfig.firebaseProjectId`, `EnvironmentConfig.sentryDsn`, `EnvironmentConfig.widgetHost`, `EnvironmentConfig.functionsBaseUrl` would all use dev values, while Firebase itself is initialized against PROD (because `main.dart` imports `firebase_options.dart`).
- Net result: split-brain state — Firebase calls go to prod, but URL builders / log levels / Sentry DSN treat the app as dev.
- This is a build-only helper; not used in CI/deploy. Lower severity. Recommend either delete or fix to call the env-aware entry points.

### CI workflow assessment
`deploy-widget.yml` hardcodes `projectId: rab-booking-248fc` and builds `widget_main.dart`. Internally consistent — this is the prod widget deploy path on `git push origin main`. Not a mismatch; it's intentional.

But: per `.claude/rules/hosting-build.md` "Footgun: GitHub Actions workflow" — there's no equivalent workflow for dev/staging. CI deploys only prod, manual scripts deploy dev/staging. Adds friction; not a correctness bug.

---

## TASK 5 — Data impact (PROD Firestore + Auth)

Queried `rab-booking-248fc` (PROD) via Admin SDK:

### Confirmed contamination

| Artifact | ID | Created | Source |
|---|---|---|---|
| Auth user `wave0-smoke-202605181440@bookbed.test` | `qoN6aykKwqZI4n9REgqXfEFG8KM2` | 2026-05-18 12:49:40 GMT | Wave 0 testing |
| Property `Wave Test Vila` | `6VCCLt8rnSokrIani9oU` (subdomain `wave-test-vila`) | 2026-05-18 14:16:51 GMT | owned by the test user above |
| Unit `Apartman A` | `seg85UhyMQM8hw7ZpLhq` | (under Wave Test Vila), base €50 | — |

### What was NOT contaminated

| Check | PROD count | Notes |
|---|---|---|
| `properties/SEED_property_dev_01` | absent | wave0 SEED fixtures stayed in dev |
| Properties with `subdomain == 'seed-dev'` | 0 | — |
| Bookings with `booking_reference == 'BB-SEED01'` | 0 | — |
| Bookings on `Wave Test Vila` property | **0** | no Stripe / no guest data |
| Bookings with `@example.com`, `@bookbed.test`, `seed-guest` email | 0 (scanned all 14 PROD properties) | — |
| Total PROD bookings | 58 | all appear legitimate |
| Total PROD properties | 14 | 1 of 14 is the test artifact |

### Risk envelope

- **Stripe LIVE exposure:** zero bookings on the test property, therefore zero Stripe sessions reachable from these artifacts. The narrower claim "no Stripe transaction tied to test data" is verified directly; the broader claim "prod Stripe keys never exercised by dev/staging widget traffic" is not directly testable without crawling Stripe LIVE for sessions tagged with dev-source metadata — out of scope, low likelihood.
- **Guest data exposure:** zero. No real guest emails or PII landed in PROD via dev/staging widget.
- **Owner data exposure:** one test owner account exists in PROD Auth + Firestore. Email format makes it obvious (`@bookbed.test` is not a real domain). Trial status, no payment methods.

### Could damage have been worse?

Yes. The mismatch was live for 4 months. Any of these would have produced real prod artifacts:
1. A QA tester opening `bookbed-widget-dev.web.app` with a real prod `property_id` + `unit_id` and clicking "Book Now" → real Stripe LIVE charge.
2. An owner pasting `bookbed-widget-dev.web.app/?property=…` instead of `view.bookbed.io/?property=…` into a real iframe → all customer bookings from that iframe landing in prod (which is technically the intended outcome, so harmless in *that* specific case — but the env separation is still broken).
3. An owner registering on `bookbed-owner-dev.web.app` (which IS correctly wired to dev Firebase) and then their widget activity referring to dev units, but the widget would 404 because the widget is reading from prod. Confusing failure mode.

The fact that the Wave 0 tester created `Wave Test Vila` in PROD via a workflow that they thought was dev is evidence that path #3 (or similar confusion) already played out at least once.

---

## TASK 6 — Fix plan

Three files need creation/edit. Plus migration of the 3 PROD test artifacts.

### Fix A: create `lib/widget_main_staging.dart`

Mirror `lib/widget_main_dev.dart` — same body, swap `firebase_options_dev.dart` → `firebase_options_staging.dart` and `DevFirebaseOptions` → `StagingFirebaseOptions`. Estimated 40 LOC. Decide whether staging widget gets Sentry — recommend yes (DSN gated on env), but out of scope for this audit.

### Fix B: edit `scripts/deploy_dev.sh` line 10

```diff
-flutter build web --release --target lib/widget_main.dart -o build/web_widget
+flutter build web --release --target lib/widget_main_dev.dart -o build/web_widget
```

### Fix C: edit `scripts/deploy_staging.sh` line 10

```diff
-flutter build web --release --target lib/widget_main.dart -o build/web_widget
+flutter build web --release --target lib/widget_main_staging.dart -o build/web_widget
```

(Requires Fix A to land first.)

### Fix D (optional, lower priority): `scripts/build_all_web.sh`

Either delete (use deploy scripts instead) or replace `lib/main.dart` / `lib/widget_main.dart` / `lib/admin_main.dart` with the env-aware entry points and add a `--env=dev|staging|prod` flag.

### Fix E (out of scope; tracked separately): widget entry-point firebase_options selection

Even simpler structural fix: refactor `widget_main.dart` to take an env via `--dart-define=BB_ENV=dev|staging|prod` and choose `firebase_options*.dart` at runtime via a thin selector. Removes the need for three near-identical `widget_main_*.dart` files. Larger refactor; not blocking the audit fixes.

### Verification gates

After Fix A–C land:
1. `flutter analyze` → 0 issues
2. `flutter test` → green
3. `flutter build web --release --target lib/widget_main_dev.dart -o build/web_widget` → succeeds
4. `flutter build web --release --target lib/widget_main_staging.dart -o build/web_widget` → succeeds
5. Deploy dev widget: `firebase deploy --only hosting:widget --project bookbed-dev`
6. Open `https://bookbed-widget-dev.web.app/?property=SEED_property_dev_01&unit=SEED_unit_dev_01` → should render (uses dev Firebase project where seed exists). Before fix, this URL would 404 because widget reads prod where SEED doesn't exist.
7. Same for staging once staging fixtures seeded.

---

## TASK 7 — Migration plan for PROD contamination

Three orphan records to clean up. None have child bookings, so deletion is safe.

### Delete order (matters for Firestore subcollections)

```javascript
// 1) Delete Wave Test Vila unit
db.doc('properties/6VCCLt8rnSokrIani9oU/units/seg85UhyMQM8hw7ZpLhq').delete()

// 2) Delete Wave Test Vila property
db.doc('properties/6VCCLt8rnSokrIani9oU').delete()

// 3) Delete test owner user doc + Auth record
db.doc('users/qoN6aykKwqZI4n9REgqXfEFG8KM2').delete()
admin.auth().deleteUser('qoN6aykKwqZI4n9REgqXfEFG8KM2')

// 4) Recheck no orphan subdocs (widget_settings, widget_secrets, pricing_calendar, etc.)
//    Use Firestore listCollections on the property doc + recursiveDelete if any remain.
```

Recommend wrapping in an idempotent script `scripts/cleanup-prod-wave0-artifacts.js` that:
- Validates each doc exists before delete (avoid silent no-ops masking real issues)
- Logs each delete with timestamp + caller identity
- Refuses to run unless `--confirm-prod` flag is passed
- Is committed to repo so future audit trail exists

Out of scope for this READ-ONLY audit. Recommend as next ticket.

### Verification after cleanup

Re-run TASK 5 queries; expect:
- `auth().getUserByEmail('wave0-smoke-202605181440@bookbed.test')` → not found
- `properties.where('subdomain', '==', 'wave-test-vila')` → 0 docs
- `users/qoN6aykKwqZI4n9REgqXfEFG8KM2` → doesn't exist
- Total PROD properties: 14 → 13
- Total PROD bookings: 58 (unchanged, no orphan bookings to clean)

---

## Open follow-ups

1. **Cleanup PROD artifacts** (Fix migration above) — next session.
2. **Land Fix A–C** — small PR, low risk, gated by dev re-deploy + widget render check.
3. **Audit dev/staging Firebase projects for other split-brain symptoms.** Were any test bookings created in dev via prod widget? Inverse direction — less likely because dev widget hosting is itself the misconfigured one, but worth a spot check.
4. **Consider Fix E** (single `widget_main.dart` with `--dart-define` env selector) as Wave 2 refactor.
5. **Per `.claude/rules/hosting-build.md` footgun #2:** `ical_export_list_screen.dart:211` hardcodes prod projectId. Separate fix.
6. **CI parity:** add `deploy-widget-dev.yml` / `deploy-widget-staging.yml` workflows so dev/staging widgets aren't dependent on someone running a shell script.

---

## How did the test owner + property reach PROD if owner-dev is wired correctly?

The owner side of `deploy_dev.sh` has imported `lib/main_dev.dart` (which sets `setEnvironment(development)` + `firebase_options_dev.dart`) since the script's first commit (`4503279e`, 2026-01-05). Verified via `git log -p --follow scripts/deploy_dev.sh | grep -- "--target.*main"` → exactly one historic state, the current one. So a deploy-script bug on the owner side is **ruled out**.

Three remaining candidate paths for the contamination:

1. **Human error on prod URL.** Tester opened `https://bookbed-owner.web.app` (prod) thinking it was `bookbed-owner-dev.web.app`, signed up with `wave0-smoke-202605181440@bookbed.test`, created `Wave Test Vila`. No code defect; just confusion between near-identical hostnames. Most plausible given the Wave 0 day was busy with multiple test windows.
2. **Manual deploy mixing.** Someone ran `scripts/build_all_web.sh` (which builds `lib/main.dart` with no `setEnvironment` call + prod `firebase_options.dart`) and then `firebase deploy --only hosting:owner --project bookbed-dev`. The dev owner site would temporarily point at prod Firebase. No git evidence; would need Firebase Hosting deploy log to confirm.
3. **Auth signup form bug.** Some past version of the owner signup form may have not respected `EnvironmentConfig` (e.g. hardcoded Firebase Auth call). Less likely given `firebase_options_dev.dart` is selected at `Firebase.initializeApp`, but possible if signup uses a separate auth-only client.

**This audit cannot disambiguate without Firebase Hosting deploy history.** Recommend before running the cleanup migration: query Firebase Hosting release history for `bookbed-owner-dev` to see if a release between 2026-05-17 and 2026-05-19 used a non-dev bundle. If yes → possibility #2; if no → possibility #1 (human error). Either way, the script fixes A–C in TASK 6 are still correct and necessary, just for a different mismatch than the one that produced *this specific* contamination.

---

## Why this slipped past previous audits

`audit/07-chrome-smoke-test.md` and `audit/12-widget-e2e-dev.md` both observed widget behavior on `localhost:8080` builds using `--target lib/widget_main_dev.dart` directly. That bypasses the deploy script bug entirely — the local build was correctly wired, so the dev project showed the expected seed data and Wave 0 testing "worked." The mismatch is only visible when the deploy SCRIPTS run (and produce artifacts pointing at prod).

`audit/12` did flag the issue structurally ("widget_main.dart imports firebase_options.dart (PROD) but deploy_dev.sh:10 builds it for DEV hosting"), but didn't follow through with a PROD Firestore scan for evidence. This audit closes that loop.

---

## Files referenced

- `scripts/deploy_dev.sh`, `scripts/deploy_staging.sh`, `scripts/deploy_prod.sh`, `scripts/build_all_web.sh`
- `.github/workflows/deploy-widget.yml`
- `lib/widget_main.dart`, `lib/widget_main_dev.dart`
- `lib/main.dart`, `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`
- `lib/admin_main.dart`, `lib/admin_main_staging.dart`, `lib/admin_main_production.dart`
- `lib/firebase_options.dart`, `lib/firebase_options_dev.dart`, `lib/firebase_options_staging.dart`
- `lib/core/config/environment.dart`
- `.claude/rules/hosting-build.md` (already documents footgun #1 + #2)
- `audit/07-chrome-smoke-test.md`, `audit/12-widget-e2e-dev.md`, `audit/13-sentry-dart-fix.md`
