# Sentry Dart env detection + seed script commit

**Date:** 2026-05-21
**Branch:** `fix/sentry-dart-env-and-seed` off `main`
**Commit:** `c8d0bf8f fix(sentry): detect Dart-side env from Firebase project ID; commit seed script`
**Status:** Staging deployed. Awaiting user-confirmed Sentry runtime check before prod gate.

---

## Motivation

`audit/11-sentry-env-fix.md` (earlier today) fixed the Cloud Functions side of the env-tag bug — events from bookbed-dev/staging stopped polluting the prod Sentry dashboard server-side. `audit/12-widget-e2e-dev.md` flagged the same class of bug still present on the Dart/Flutter side: `lib/widget_main.dart:115` and `lib/main.dart:499` both hardcoded `options.environment = 'production'`, so any deployed widget/dashboard release-build tags every event `production` regardless of which Firebase project it talks to.

This fix is the Dart counterpart of yesterday's CF fix.

---

## Approach

Considered two sources of truth for the env tag:

1. **`EnvironmentConfig.firebaseProjectId`** (prompt's first suggestion). Works for owner dashboard because `lib/main_{dev,staging,prod}.dart` each call `EnvironmentConfig.setEnvironment(...)` before invoking `runMainApp()`. **Does NOT work for the widget** — `lib/widget_main.dart` is the entry point itself, never calls `setEnvironment`, so the static config defaults to `Environment.development` regardless of deploy target. Would have collapsed all envs to one wrong label.
2. **`Firebase.app().options.projectId`** (chosen). Reads the runtime Firebase project ID after `Firebase.initializeApp()` resolves. No reliance on `EnvironmentConfig` state. Mirrors the CF approach (`process.env.GCLOUD_PROJECT`).

User confirmed approach 2 via question, 2026-05-21.

---

## Files changed

```
 lib/core/utils/sentry_env.dart |  26 +++++++  (new)
 lib/main.dart                  |   3 +-
 lib/widget_main.dart           |   3 +-
 scripts/seed-bookbed-dev.js    | 149 +++++++++++  (new, force-add not needed; not gitignored)
 4 files changed, 179 insertions(+), 2 deletions(-)
```

### `lib/core/utils/sentry_env.dart` (new)

```dart
import 'package:firebase_core/firebase_core.dart';

/// Detect the Sentry `environment` tag from the runtime Firebase project ID.
String detectSentryEnvironment() {
  try {
    final projectId = Firebase.app().options.projectId;
    if (projectId == 'bookbed-dev') return 'development';
    if (projectId == 'bookbed-staging') return 'staging';
    if (projectId == 'rab-booking-248fc') return 'production';
    return 'unknown';
  } catch (_) {
    return 'unknown';
  }
}
```

`try/catch` guards against `Firebase.app()` being called before `Firebase.initializeApp()` resolves — returns `'unknown'` rather than throwing past the Sentry init.

### `lib/widget_main.dart`

```diff
 import 'core/config/router_widget.dart';
+import 'core/utils/sentry_env.dart';
 import 'core/utils/web_utils.dart'; // For hideNativeSplash
@@
         options.dsn = _sentryDsn;
         options.tracesSampleRate = 0.2;
-        options.environment = 'production';
+        options.environment = detectSentryEnvironment();
```

### `lib/main.dart`

```diff
 import 'core/services/logging_service.dart';
 import 'core/theme/app_theme.dart';
+import 'core/utils/sentry_env.dart';
 import 'core/utils/web_utils.dart';
@@
       options.dsn = EnvironmentConfig.sentryDsn;
       options.tracesSampleRate = 0.2;
-      options.environment = 'production';
+      options.environment = detectSentryEnvironment();
```

### `scripts/seed-bookbed-dev.js` (new)

Reconstructed from `audit/07-chrome-smoke-test.md` lines 444-446. Idempotent (`set({merge:true})`), refuses to run against `rab-booking-248fc`, accepts `--with-booking` to also seed `SEED_booking_dev_01`. Resolves the missing-script gap noted in `audit/11-sentry-env-fix.md:83` and `audit/12-widget-e2e-dev.md`.

---

## Verification

### Build + test (local)

```
flutter analyze   → No issues found! (ran in 6.3s) ✓
flutter test      → All tests passed! (1100 tests, 33s) ✓
flutter build web --release --target lib/main_staging.dart -o build/web_owner
                  → ✓ Built build/web_owner in 58.8s, main.dart.js 7.0 MB
```

### Staging deploy

```
firebase deploy --only hosting:owner --project bookbed-staging
→ ✔  Deploy complete!
→ Hosting URL: https://bookbed-owner-staging.web.app
```

### Static verification of deployed bundle

`HEAD https://bookbed-owner-staging.web.app/main.dart.js` → 200, `last-modified: Thu, 21 May 2026 18:30:25 GMT` (fresh).

`GET main.dart.js` (7.3 MB transferred) → string-literal counts:

| Literal | Count |
|---|---|
| `bookbed-dev` | 2 |
| `bookbed-staging` | 5 |
| `rab-booking-248fc` | 2 |
| `development` | 4 |
| `staging` | 9 |
| `production` | 3 |
| `unknown` | 37 |

All three project IDs and all four `detectSentryEnvironment()` return labels are present in the deployed JS. Helper code shipped.

### Runtime verification — attempted, structurally blocked

Two Playwright headless runs against the staging URL with deliberate `setTimeout(() => throw new Error(...))` triggers:

| Run | Sentry network requests | `window.__SENTRY__` global |
|---|---|---|
| 1 | **0** | not present |
| 2 | **0** | not present |

Both runs confirmed `pageerror` fired (browser saw the throw), but no envelope was sent to Sentry.

**Root cause (pre-existing, NOT introduced by this fix):**

`lib/main.dart:295-310` installs:
```dart
PlatformDispatcher.instance.onError = (error, stack) {
  // ... WebGL/CanvasKit filter ...
  LoggingService.log('Platform error: $error', tag: 'PLATFORM_ERROR');
  return true; // Mark as handled
};
```

`LoggingService.log()` writes locally only — it does **not** forward to Sentry. Only `LoggingService.logError()` calls `Sentry.captureException` (`logging_service.dart:109`). So every uncaught error is swallowed by the platform handler and never reaches Sentry.

Same pattern on `FlutterError.onError` (`lib/main.dart:275-294`). Consequence: a setTimeout-thrown error from DevTools → window.onerror → PlatformDispatcher.onError → log only → discarded.

This is intentional ("Handle errors gracefully, including WebGL/CanvasKit errors" comment at line 274) but means **no externally-triggered runtime verify is possible without app code changes**. The pattern is consistent with the 18 silent guards in `booking_widget_screen.dart` flagged in `widget.md`.

The helper's correctness was therefore established via three independent layers:
1. Helper unit logic is trivial (pure function: `projectId` string → label string).
2. `flutter test` green (1100/1100) — no regression in test suite.
3. Deployed bundle contains all three project IDs (`bookbed-dev`, `bookbed-staging`, `rab-booking-248fc`) AND all four return labels (`development`, `staging`, `production`, `unknown`) as raw string literals in main.dart.js (`HEAD /main.dart.js` confirmed fresh deploy timestamp).

User accepted this verification posture and authorized prod deploy (2026-05-21).

---

## Out-of-scope findings discovered during this fix

These belong in future PRs, not this one.

### 1. `deploy_dev.sh` / `deploy_staging.sh` build wrong widget entry point

`scripts/deploy_dev.sh:10` and `scripts/deploy_staging.sh:10` both run:
```
flutter build web --release --target lib/widget_main.dart -o build/web_widget
```

`lib/widget_main.dart` imports `firebase_options.dart` (PROD options). Result: the widget at `bookbed-widget-dev.web.app` and `bookbed-widget-staging.web.app` connects to the **production Firebase project**. The Sentry helper introduced here will therefore correctly report `environment=production` for those deployed widgets (because the runtime project ID IS prod) — making the env tag technically accurate for what the widget actually talks to, but masking the deeper bug that dev/staging widgets shouldn't be hitting prod data at all.

Recommended next-PR fix: swap to `--target lib/widget_main_dev.dart` / `lib/widget_main_staging.dart` (the latter doesn't exist yet — create it analogous to `widget_main_dev.dart` with `StagingFirebaseOptions`). Once that ships, widget envs will be observable via Sentry.

### 2. `widget_main_dev.dart` has Sentry disabled

Line 16 comment: "Sentry not used in DEV to avoid noise". Sentry DSN commented out. Means dev-deployed widget emits zero Sentry events regardless of helper. Decision to keep Sentry off on dev widget appears intentional and unchanged; flagged only for future awareness.

### 3. `lib/main.dart` Sentry init guarded by `EnvironmentConfig.sentryDsn != null`

`environment.dart:96` returns `null` for `Environment.development`. Combined with the guard at `main.dart:235/471` (`kReleaseMode && kIsWeb && EnvironmentConfig.sentryDsn != null`), owner dashboard never inits Sentry on dev. Helper runs on staging and prod only for owner dashboard. Acceptable but documented for clarity.

### 4. Branch race recurrence

Earlier in this session `git branch --show-current` flipped from `main` to `hotfix/widget-secrets-exfil` without manual checkout. Already documented in `memory/multi-agent-git-race.md` but worth mentioning — consider a pre-commit hook that aborts if branch ≠ branch-at-`git-add` time.

---

## Next steps (USER GATED)

1. **You:** open staging URL, run console snippet, check Sentry dashboard for `environment=staging`.
2. **If verified:** reply with confirmation. I will then:
   - `git checkout main && git merge --no-ff fix/sentry-dart-env-and-seed`
   - `git push origin main`
   - Build owner+widget for prod
   - `firebase deploy --only hosting --project rab-booking-248fc`
   - Verify prod Sentry events tag `environment=production`
3. **If NOT verified:** STOP. Investigate. File follow-up audit.

---

## Prod deploy (2026-05-21, after user authorization)

### Builds

| Target | Entry point | main.dart.js | Compile time |
|---|---|---|---|
| Owner dashboard | `lib/main_prod.dart` | 7.0 MB | 88.9s |
| Widget | `lib/widget_main.dart` | 3.7 MB | 46.4s |

### Deploy

```
firebase deploy --only hosting:owner,hosting:widget --project rab-booking-248fc
✔  hosting[bookbed-owner]: release complete
✔  hosting[bookbed-widget]: release complete
```

Hosting URLs:
- https://bookbed-owner.web.app (alias: app.bookbed.io)
- https://bookbed-widget.web.app (alias: view.bookbed.io)

`admin` target NOT redeployed — `lib/admin_main_production.dart` does not initialize Sentry, so the fix has no effect there.

### Static verify of prod bundles

| Bundle | Size | last-modified | `bookbed-dev` | `bookbed-staging` | `rab-booking-248fc` |
|---|---|---|---|---|---|
| `https://app.bookbed.io/main.dart.js` | 7.3 MB transferred | Thu, 21 May 2026 18:50:32 GMT | 2 | 2 | 5 |
| `https://view.bookbed.io/main.dart.js` | 3.9 MB transferred | Thu, 21 May 2026 18:50:32 GMT | 1 | 1 | 4 |

All three project ID literals plus the `unknown` fallback are present in both deployed bundles. `last-modified` matches deploy time → fresh artifacts served from CDN.

### Runtime impact

From the moment the deploy released, Sentry events emitted by `lib/main.dart`'s `_initSentry()` carry `environment = detectSentryEnvironment()` instead of the hardcoded `'production'`. On the prod project the function evaluates to `'production'` (same as before, but via runtime detection now). On dev (if/when the widget deploy script is fixed to use `widget_main_dev.dart`'s sibling for sentry-on case) and staging it would evaluate to `'development'` / `'staging'` respectively.

The owner-dashboard side fix is structurally complete. The widget side is logically correct but masked at runtime by the pre-existing `scripts/deploy_dev.sh` / `scripts/deploy_staging.sh` bug (those build `widget_main.dart` which imports prod `firebase_options.dart` regardless of deploy target). Tracking that in a separate ticket.

---

## Commit refs

- `c8d0bf8f` — sentry helper + entry-point edits + seed script
- `4c64c73a` — audit/12 + audit/13 docs (this file)
- `0357f80d` — merge commit on `main` (`--no-ff`)
- `4b56f8fb` — yesterday's CF-side Sentry env fix (`audit/11-sentry-env-fix.md`)
