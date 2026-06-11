# Android Development — Firebase Project Wiring + Build Gotchas

## Why this exists

`android/app/google-services.json` is **hardcoded to PROD** (`rab-booking-248fc`). A `.backup` variant pointing at `bookbed-dev` exists alongside it. There is no Gradle product flavor; switching between PROD and DEV requires a manual file swap **plus** explicit `--target lib/main_dev.dart` (or widget equivalent) on every `flutter run`.

Forgetting either step results in **silent contamination of PROD** — the app connects to prod Firestore + Auth + Stripe Connect + FCM. This already happened on iOS during Wave 0 (2026-05-18); the cleanup is tracked in `audit/14` and `audit/15`. Same risk class on Android.

## Files

| File | Project | Purpose | Git-tracked? |
|---|---|---|---|
| `android/app/google-services.json` | `rab-booking-248fc` (PROD) | Active config used by every `flutter run` / `flutter build apk/appbundle` | ✓ tracked |
| `android/app/google-services.json.backup` | `bookbed-dev` (DEV) | Inactive — must be swapped in manually for dev testing | ✗ untracked (matched by `*.backup` in `.gitignore`) |

There is NO `.staging` variant. Staging Android testing requires creating one (analogous to `.backup`).

**Brittleness note:** Because `.backup` is gitignored, every developer must source the dev config independently (download from Firebase Console → bookbed-dev → Project settings → Your apps → Android (`io.bookbed.app`) → `google-services.json`). There is no single source of truth. The permanent fix (NOT yet implemented) is Gradle product flavors with per-env `google-services-{env}.json` files committed and a `productFlavors` block in `android/app/build.gradle.kts` that picks the right file at build time.

## To run Android against `bookbed-dev`

```bash
# 1. Backup current prod file (safety) — gitignored, won't leak
cp android/app/google-services.json android/app/google-services.json.prod-snapshot

# 2. Swap to the dev variant
cp android/app/google-services.json.backup android/app/google-services.json

# 3. Verify the swap landed
grep project_id android/app/google-services.json
# Should print:    "project_id": "bookbed-dev",

# 4. Run with explicit dev target (--debug for Marionette/adb smokes,
#    --release for plain runs — see "Debug vs release builds" below)
flutter run -d <android-device-id> --debug --target lib/main_dev.dart

# (or the widget entry, depending on what you're testing)
flutter run -d <android-device-id> --release --target lib/widget_main_dev.dart
```

## When you're done with the dev session — RESTORE the prod file

```bash
# Restore the prod file from git
git checkout android/app/google-services.json

# Verify
grep project_id android/app/google-services.json
# Should print:    "project_id": "rab-booking-248fc",

# Optionally delete the snapshot (or keep for next session)
rm android/app/google-services.json.prod-snapshot
```

The snapshot file is gitignored by `*.prod-snapshot` (committed 2026-05-22). Safe to leave on disk.

## Defense-in-depth — Dart-level assert (in code)

Every env-specific entry point (`main_dev.dart`, `main_staging.dart`, `main_prod.dart`, `widget_main.dart`, `widget_main_dev.dart`, `widget_main_staging.dart`) carries a `kDebugMode` assert immediately after `Firebase.initializeApp`. If the runtime project ID doesn't match what the entry point expects, the app crashes on boot with a message naming the mismatch.

This means: even if you forget the file swap, a `flutter run --target lib/main_dev.dart` against the prod `google-services.json` will crash visibly on debug builds instead of silently writing to prod.

Release builds (prod deploys) skip the check — the asserts ONLY fire in debug builds.

## Android-specific build gotchas

### Debug vs release builds — pick per task (rule updated 2026-06-11)

Historical: `firebase_storage` < 13 failed `assembleDebug` (Kotlin-before-Java
compile order), which made `--release` mandatory. On `firebase_storage: ^13`
+ Flutter 3.38.5 debug builds work again (verified audit/63, Pixel_8 —
`memory/android-debug-build-firebase-storage-13.md`).

- **UI-automation smokes (Marionette / adb taps): use `--debug`.** Release
  builds expose the UI as a single Surface to uiautomator — coord-taps fire
  but miss widgets (`memory/android-release-mode-adb-opacity.md`, F-T3-02).
- **Plain manual runs / perf checks: `--release` is still fine.** If a debug
  build fails after a dep bump, first retry with `--release` (per
  `.claude/rules/hosting-build.md`).

### AAB build blocker — use `tool/build_aab.sh` (both local + CI)

`flutter build appbundle --release --target lib/main.dart` fails on Flutter 3.38.5:

```
error: package net.jonhanson.flutter_native_splash does not exist
```

Root cause: `flutter_native_splash 2.4.7`'s own pubspec declares `flutter.plugin.platforms.android`, and Flutter 3.38.5 takes that declaration at face value when generating `GeneratedPluginRegistrant.java`, even though it's a dev_dependency. The package's runtime plugin class has been removed in recent versions, so the import is broken at Javac time.

`flutter build apk --release` works fine — only `bundleRelease` fails.

**Fix:** Use the wrapper script `tool/build_aab.sh` which patches `.flutter-plugins-dependencies` to skip native registration for that one plugin before invoking `flutter build appbundle`.

```bash
# Default: --release --target lib/main.dart
tool/build_aab.sh

# Or with custom flags
tool/build_aab.sh --release --target lib/widget_main.dart
```

Verified produces a working AAB. Full reproduction + fix derivation: `memory/aab-build-blocker.md` + `tool/build_aab.sh` header (audit/16 pruned — git history).

**CI parity** (enabled 2026-05-22, commit `739655b4`, merged via `21d57f49`):
`.github/workflows/ci.yml` `build-android` job runs `./tool/build_aab.sh --release`
and uploads `build/app/outputs/bundle/release/app-release.aab` as artifact
`android-aab` (retention 7 days). Do NOT replace with direct `flutter build
appbundle` — the registrant bug applies on the GitHub runner too.

### Deep links — cover both warm-start and cold-start

`bookbed://` custom scheme + `https://bookbed.io / app.bookbed.io / view.bookbed.io` App Links (autoVerify) are registered in `android/app/src/main/AndroidManifest.xml`. When regression-testing deep links via `adb`, exercise BOTH the warm-start path (`uni_links` / `app_links` stream) AND cold-start (`getInitialLink()` / `getInitialAppLink()`) — they are separate code paths.

Recipe + auth-race gotcha (cold-start Pigeon trace): see `.claude/rules/deep-links.md`.

### 16KB page size — static + runtime

All bundled `lib/arm64-v8a/*.so` files must have `PT_LOAD` `p_align >= 16384` to pass Play Store 2025-11-01 `targetSdkVersion >= 35` upload check. Verified passing on 2026-05-22 (libflutter + libVkLayer at 64KB; libsentry + libdatastore at 16KB).

Runtime 16KB verification requires a 16KB-page-kernel device — the default Pixel_8 AVD runs a 4KB kernel and cannot test the runtime path. Either use a Pixel 8a+ on Android 15+, or boot the emulator with `-feature 16K-paging`.

## Warning signs that you're in the wrong env

- App boots normally but auth signup creates user in prod (check `https://console.firebase.google.com/project/rab-booking-248fc/authentication/users`)
- Stripe Connect onboarding URL contains real LIVE-mode Express signup flow (instead of test-mode)
- Owner sees prod data they don't recognize (other owners' properties)
- Sentry events from your dev session tagged `environment=production`
- FCM push tokens registering against the PROD bookbed Firebase project

If you see any of these, stop immediately and check:
1. `git status android/app/google-services.json` — modified? You're on the dev variant.
2. The `flutter run` command you used — does it include `--target lib/main_dev.dart`?
3. Cleanup any artifacts via `audit/15` recipe (Stripe Connect orphans + Auth user removal).

## Permanent fix (NOT yet implemented)

Tracked as F-Android-011 (audit/16, pruned) + `.claude/rules/ios-development.md` analog: add `productFlavors { dev { applicationIdSuffix ".dev" }; staging { ... }; prod { ... } }` to `android/app/build.gradle.kts`, with per-env `src/dev/google-services.json` / `src/staging/google-services.json` / `src/prod/google-services.json` files committed. Gradle picks the right file based on the flavor.

Together with iOS Xcode `Debug-dev` / `Debug-staging` schemes, this eliminates the entire manual swap class of bugs. Larger change; needs Gradle + Xcode edits + 3 per-env config files committed.

Until that lands, use the manual procedure above and rely on the Dart asserts as the safety net.

## See also

- `.claude/rules/ios-development.md` — iOS plist swap (analogous procedure)
- `.claude/rules/hosting-build.md` — debug build bug, dependency versions, CI AAB wiring
- `.claude/rules/deep-links.md` — warm + cold start coverage matrix
- `audit/14-deploy-scripts-mismatch.md` — origin of the swap-based contamination class
- `audit/15-prod-contamination-deep-check.md` — Stripe Connect contamination cleanup recipe
- `memory/wave0-test-findings.md` — Wave 0 "drop --flavor dev" gotcha that triggered the contamination
- `memory/aab-build-blocker.md` — AAB blocker resolution history (+ CI status)
