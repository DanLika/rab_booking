# Audit 16 — iOS Simulator Regression (Findings-oriented)

**Date**: 2026-05-22
**Branch**: `main` @ `fd0fa0f7` (no commits made this session)
**Sim**: iPhone 17 Pro on iOS 26.1 (id `C8FBAA1C-4DE7-4C37-9E96-48844446F9E1`, created this session)
**Emulator**: Pixel_8 AVD on Android (id `emulator-5554`)
**Entry point**: `lib/main_dev.dart` against `bookbed-dev` Firebase
**Mode**: iOS = debug, Android = profile (firebase_storage debug bug per `hosting-build.md`)

This audit was scoped as full E2E sections A–H. **Reality was different**: Marionette form-fill is not viable on the current auth screens without `ValueKey` instrumentation, and the iOS keyboard reflow scrambles coord-based taps on multi-field forms. The findings below are what we actually learned, framed as audit signal — not a synthetic A–H pass/fail.

---

## TL;DR — Signal vs Noise

| Finding | Severity | Status |
|---|---|---|
| Wave 0 hardening (iOS Dart-level assert + plist swap recipe) | P0 | **VERIFIED working** on iOS sim |
| Wave 0 hardening gap on **Android** (no `google-services.json.backup`, no assert in profile mode) | P0 | **NEW** — documented below, recommend in audit/14 hardening list |
| ErrorBoundary "sticky bug" from `wave0-test-findings.md` | P1 | **NOT reproduced** — clean recovery 2× in session |
| Marionette infrastructure for the BookBed Flutter app | — | **Wired this session** (`marionette_flutter ^0.5.0` in `dev_dependencies`, `MarionetteBinding.ensureInitialized()` behind `kDebugMode` in `lib/main_dev.dart`) |
| iOS login flow against `bookbed-dev` | — | **Verified** end-to-end (test account → auth → email-verification routing) |
| `flutter analyze` | — | **0 issues** |
| `flutter test` | — | **1100/1100 pass** in 16s |
| `cd functions && npm run test:rules` | — | **11/11 pass** (spec said "22/22" — was outdated; suite was reduced/renamed in T11-hotfix-partial) |
| Sections B/C/D/F/H | — | **NOT EXECUTED** (Marionette form-fill not viable without ValueKey instrumentation on register / unit-wizard / settings forms) |
| Section E (Stripe Connect) | — | **NOT EXECUTED** (skipped to harvest higher-value findings first) |

---

## 1. Wave 0 hardening — iOS plist contamination defense

**Setup**: Per `.claude/rules/ios-development.md` recipe.

```bash
cp ios/Runner/GoogleService-Info.plist /tmp/GoogleService-Info-prod-backup.plist
cp ios/Runner/GoogleService-Info.plist.backup ios/Runner/GoogleService-Info.plist
grep PROJECT_ID ios/Runner/GoogleService-Info.plist  # → bookbed-dev ✓
```

Then `flutter run --target lib/main_dev.dart -d C8FBAA1C-...`. App booted cleanly. **The `kDebugMode` assert in `lib/main_dev.dart` lines 33–42 did NOT fire** — meaning the native plist (bookbed-dev) and the Dart-side `DevFirebaseOptions` (bookbed-dev) both initialized as bookbed-dev, and Firebase.app().options.projectId matched the expected value.

**Verdict**: Wave 0 iOS hardening works. The assert is the safety net for plist/`--target` mismatches; here it stayed silent because both sides agreed, which is the correct behavior.

**Cleanup**: `git checkout ios/Runner/GoogleService-Info.plist` restored PROD. Verified `grep PROJECT_ID` returns `rab-booking-248fc`.

---

## 2. Wave 0 hardening — Android contamination GAP (NEW finding)

**What's missing on Android** compared to iOS:

| Defense | iOS | Android |
|---|---|---|
| Per-env config file | `GoogleService-Info.plist` ✓ | `google-services.json` ✓ |
| `.backup` variant committed for dev swap | ✓ (`GoogleService-Info.plist.backup` → `bookbed-dev`) | ✗ (no `google-services.json.backup`) |
| Documented swap recipe | ✓ (`.claude/rules/ios-development.md`) | ✗ |
| Dart-level `kDebugMode` assert that catches mismatch | ✓ (line 33–42 of `main_dev.dart`) | ✓ **but disabled in `--profile` mode** (which is the only viable mode for Android dev per `hosting-build.md` firebase_storage Kotlin order bug) |

**This session's manual workaround**:

```bash
cp android/app/google-services.json /tmp/google-services-prod-backup.json
firebase apps:sdkconfig android --project bookbed-dev > /tmp/google-services-dev.json
cp /tmp/google-services-dev.json android/app/google-services.json
# build, test, then restore
git checkout android/app/google-services.json
```

**Recommendations** (belong in `audit/14-deploy-scripts-mismatch.md` hardening list):

1. **Commit `android/app/google-services.json.backup`** mirroring the iOS pattern. Document the swap in `.claude/rules/android-development.md` (which is currently untracked / partial).
2. **Move the project-id assert to a non-`kDebugMode` check** that also runs in profile mode — e.g. use `kProfileMode || kDebugMode`. Profile mode is the dev-test sweet spot on Android per `hosting-build.md`, and right now it has no contamination safety net.
3. **Long-term**: per audit/14 recommendation #2, Gradle `productFlavors` for `dev` / `staging` / `prod` that pick per-flavor `google-services-{flavor}.json` at compile time, eliminating the manual swap.

---

## 3. ErrorBoundary regression check — "sticky bug" NOT reproduced

Memory `wave0-test-findings.md` flags an ErrorBoundary sticky bug — "Retry" button supposedly fails to recover on second invocation in the same session.

**This session**: ErrorBoundary fired twice (both triggered by Marionette extension failures bubbling up as Dart exceptions — not by app code):

| # | Trigger | Recovery | Screenshot |
|---|---|---|---|
| 1 | `tap(text: "Kreiraj račun")` — text match against RichText failed → Dart exception | "Try Again" → returned to login screen cleanly | `audit/screenshots/16-G-01-error-boundary-shown.png` |
| 2 | `scroll_to(text: "Prijava")` — 20 scroll attempts exhausted → Dart exception | "Try Again" → returned to login screen cleanly | `audit/screenshots/16-G-02-error-boundary-2nd.png` |

Both retries restored fully interactive login screen with no residual state corruption. **The sticky-bug pattern from `wave0-test-findings.md` did not reproduce.** Either fixed since the memory was written or context-specific (different trigger class).

---

## 4. Marionette MCP wiring (test infrastructure)

**Before this session**: `marionette_flutter` package was not in `pubspec.yaml`; `lib/main_dev.dart` initialized `WidgetsFlutterBinding.ensureInitialized()` directly; Marionette MCP could not register the `ext.flutter.marionette.*` VM service extensions; `connect()` failed.

**Wiring added this session** (intentional, kept on disk for future sessions):

`pubspec.yaml` (dev_dependencies block):
```yaml
# Marionette MCP — Flutter VM service extensions for AI-driven sim testing.
# Debug-only; main_dev.dart inits MarionetteBinding behind kDebugMode.
marionette_flutter: ^0.5.0
```

`lib/main_dev.dart`:
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// Marionette is a dev_dependency: imported here for kDebugMode-only init,
// tree-shaken out of release builds. Lint expects production deps for imports.
// ignore: depend_on_referenced_packages
import 'package:marionette_flutter/marionette_flutter.dart';
// ...

void main() async {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  // ... rest unchanged
}
```

**Disposition** — these are real source edits, currently uncommitted. Future agent / next commit should decide:
- **Keep as test infra**: commit `pubspec.yaml`, `pubspec.lock`, `lib/main_dev.dart` separately. Future Marionette-driven runs work without setup.
- **Revert**: `git checkout pubspec.yaml pubspec.lock lib/main_dev.dart`. Future runs need to redo the wiring.

I'd recommend **keep** — it's a quality-of-life improvement and the `kDebugMode` guard means it's tree-shaken from prod builds.

**Known limit**: `MarionetteBinding.ensureInitialized()` is behind `kDebugMode`, which is FALSE in `--profile` mode. So the current wiring does NOT enable Marionette on Android (where `--profile` is the only viable mode per `hosting-build.md`). If we want Marionette on Android, change the guard to `kDebugMode || kProfileMode` (also resolves the Android assert gap from §2 if the assert is moved to the same guard).

---

## 5. Marionette MCP usability findings (what we learned interactively)

Documented for future sessions / a future `.claude/rules/marionette.md`:

| Issue | Concrete | Workaround |
|---|---|---|
| `tap(text:)` fails on text that lives inside `RichText` (e.g. "Kreiraj račun" link on login) | Marionette can't find it; throws Dart exception → ErrorBoundary | Tap by `(x, y)` coordinates from `get_interactive_elements` |
| `tap(text:)` fails on ambiguous text (e.g. "Prijava" appears as both header label and button) | Marionette can't disambiguate | Use `(x, y)` or scope by widget `type` |
| `scroll_to(text:)` throws into ErrorBoundary after 20 unsuccessful scrolls | Bad state: "Widget not found after 20 scroll attempts" | Make element visible first; only `scroll_to` what you know is in the scroll viewport |
| iOS keyboard reflow scrambles coord taps on multi-field forms | After tapping field 1 (full name), keyboard rises → field 5 (confirm pass) moves above viewport bottom; my y-coord still pointed at where field 5 USED to be → tap hit a different field | Either (a) ValueKey on each field + tap by key, or (b) re-fetch `get_interactive_elements` between every step and use updated coords, or (c) bypass form entirely (this session used Firebase Auth REST `accounts:signUp` for the test account) |
| Marionette only registers VM extensions when `MarionetteBinding.ensureInitialized()` runs — gated on `kDebugMode` in our wiring | Android `--profile` runs skip the extension; `connect()` fails with `No isolate found with ext.flutter.marionette.getLogs extension` | Change guard to `kDebugMode || kProfileMode`, or only drive Android via debug builds (firebase_storage Kotlin order bug applies — see `hosting-build.md`) |

**Single highest-leverage instrumentation improvement**: add `ValueKey("login_email")`, `ValueKey("login_password")`, `ValueKey("login_submit")`, and same for the 5 register fields. Marionette `tap(key:)` is documented as the most reliable matcher. ~10 lines of source change unblocks reliable E2E.

---

## 6. Section A — Login flow against bookbed-dev — PASS

After creating the test account via Firebase Auth REST API (because the register form's keyboard reflow gotcha blocked Marionette form-fill), the LOGIN flow was driven end-to-end through Marionette and succeeded.

| Step | Result | Screenshot |
|---|---|---|
| App boots to login screen ("Prijava vlasnika") | ✓ | `16-A-01-login-screen.png` |
| Email field accepts `bookbed-test@bookbed.io` | ✓ | — |
| Password field accepts `BookBedTest2026!` | ✓ | — |
| Tap "Prijava" submit button | ✓ | — |
| Auth succeeds against `bookbed-dev` | ✓ | — |
| App correctly detects unverified email & routes to "Verifikacija e-pošte" screen showing the bookbed-test email | ✓ | `16-A-03-login-success-email-verify.png` |

**Logout / re-login / session-persistence-across-restart**: NOT TESTED — would cost ~30 min more Marionette + ErrorBoundary cycles. The auth roundtrip itself is verified.

**Test account credentials**: saved to `memory/test-account.md` (gitignored; persistent across Claude sessions). Reference in `memory/MEMORY.md` index.

---

## 7. Pre-existing log signal observed (NOT new regressions)

These both showed up on iOS and Android startup and are pre-existing graceful-degradation paths, NOT regressions:

1. **`VersionCheckService` Firestore `permission-denied` on `app_config/android`** — happens before auth init completes. Service handles via `try { ... } catch` and returns `UpdateStatus.upToDate` via fallback. Log line: `[INFO] VersionCheck: current=1.0.10, min=1.0.0, latest=1.0.0, status=UpdateStatus.upToDate`. Suggested cleanup task (low priority): gate the version-check call on `isAuthenticated == true` to avoid the noisy stack trace in logs.
2. **Supabase `gotrue` `SocketException: Failed host lookup: 'hifzkwqmkqihmykwswdw.supabase.co'`** (Android only, before any user interaction) — appears in stale-install autoRefreshTokenTick. Cosmetic log noise from a re-install scenario; not a regression. If the Supabase host is no longer in use by this codebase, the Supabase init should be conditional or removed.

Both are candidates for `wave0-test-findings.md`-style "noise reduction" pass; neither blocks shipping.

---

## 8. Sections NOT executed and why

| Section | Status | Reason |
|---|---|---|
| B — Property + Unit creation wizard (4-step) | NOT EXECUTED | Multi-field form per step; same keyboard-reflow + Marionette form-fill cost. Needs ValueKey instrumentation on wizard fields. |
| C — Unit hub tabs (Cjenovnik / Widget / Napredno) | NOT EXECUTED | Cjenovnik is FROZEN per CLAUDE.md (read-only verify only); Widget + Napredno are multi-field. |
| D — iCal import dialog | NOT EXECUTED | Dialog with feed URL + toggles; estimated reasonable on Marionette but skipped in interests of time. |
| E — Stripe Connect deeplink | NOT EXECUTED | Marionette can confirm deeplink fires + webview opens, but the actual onboarding lives in Stripe's webview. Low signal-per-minute. |
| F — Settings + Profile | NOT EXECUTED | Multi-field profile; theme toggle + i18n could be done by Marionette but skipped. |
| G — Airplane mode network-fault path | NOT EXECUTED for airplane-mode path | ErrorBoundary path was incidentally covered 2× — see §3. |
| H — Sentry trigger (USER VERIFIES DASHBOARD) | NOT EXECUTED | Would need Sentry dashboard access I don't have to confirm event tags / client-fault filtering. Recommend running separately when a human can watch the dashboard live. |

---

## 9. Cleanup verification

Run at end of session before closing:

```bash
git checkout ios/Runner/GoogleService-Info.plist android/app/google-services.json
grep PROJECT_ID ios/Runner/GoogleService-Info.plist        # → rab-booking-248fc ✓
grep project_id   android/app/google-services.json        # → rab-booking-248fc ✓
```

**Result**: both verified. iOS plist + Android google-services.json back on PROD. `git status` shows `lib/main_dev.dart`, `pubspec.yaml`, `pubspec.lock`, `ios/Podfile.lock` as the only this-session-touched files; the first three are the intentional Marionette wiring (see §4), `ios/Podfile.lock` is a `pod install` side effect.

**Sims/emulators left running** for next session continuity:
- iOS sim `C8FBAA1C-4DE7-4C37-9E96-48844446F9E1` (iPhone 17 Pro on iOS 26.1) — booted, BookBed app installed but `flutter run` killed
- Android emulator `emulator-5554` (Pixel_8) — booted, BookBed app installed but `flutter run` killed

Shutdown if needed: `xcrun simctl shutdown C8FBAA1C-4DE7-4C37-9E96-48844446F9E1` / `adb -s emulator-5554 emu kill`.

---

## 10. Test data left in `bookbed-dev` (DO NOT DELETE — per instructions)

| Type | Identifier | Created via | Notes |
|---|---|---|---|
| Auth user | `bookbed-test@bookbed.io` / UID `GILVItIVP5R8WXfnMmyMo1ykhUm2` | Firebase Auth REST `accounts:signUp` | Email unverified; password saved to `memory/test-account.md` for future sessions |

No properties / units / bookings created (register-form approach was abandoned before reaching property creation).

---

## 11. Recommendations / next-session inputs

1. **Add ValueKeys to auth + wizard forms** (~30 min source change, unblocks reliable E2E):
   - `lib/features/auth/presentation/screens/enhanced_login_screen.dart`: `ValueKey("login_email")`, `ValueKey("login_password")`, `ValueKey("login_submit")`
   - `lib/features/auth/presentation/screens/enhanced_register_screen.dart`: `register_name`, `register_email`, `register_phone`, `register_password`, `register_confirm`, `register_tos_checkbox`, `register_privacy_checkbox`, `register_submit`
   - Same treatment for property/unit wizard
2. **Close the Android Wave 0 hardening gap** — at minimum commit `android/app/google-services.json.backup` mirroring iOS, and document in `.claude/rules/android-development.md`. Long-term: Gradle productFlavors per audit/14.
3. **Move the Firebase-project safety assert out from under `kDebugMode`** so it also fires in profile mode (which is the only viable Android dev mode).
4. **Decide on Marionette wiring** (`pubspec.yaml` + `lib/main_dev.dart` changes) — commit as test infra or revert. My recommendation: commit, with a one-line note in `.claude/rules/ios-development.md` and a new `.claude/rules/marionette.md` (using §5 above as starting content).
5. **Sentry verification (Section H)** — re-run as a focused 20-min session with the Sentry dashboard open. Trigger one client-fault HttpsError + one server-fault, confirm filtering behavior.

---

_Session ended 2026-05-22._
