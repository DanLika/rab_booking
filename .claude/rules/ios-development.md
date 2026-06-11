# iOS Development — Firebase Project Wiring

## Why this exists

`ios/Runner/GoogleService-Info.plist` is **hardcoded to PROD** (`rab-booking-248fc`). A `.backup` variant pointing at `bookbed-dev` exists alongside it. There is no Xcode flavor scheme; switching between PROD and DEV requires a manual file swap **plus** explicit `--target lib/main_dev.dart` (or widget equivalent) on every `flutter run`.

Forgetting either step results in **silent contamination of PROD** — the app connects to prod Firestore + Auth + Stripe Connect + FCM. This already happened once during Wave 0 (2026-05-18); the cleanup is tracked in `audit/14` and `audit/15`.

## Files

| File | Project | Purpose |
|---|---|---|
| `ios/Runner/GoogleService-Info.plist` | `rab-booking-248fc` (PROD) | Active config used by every `flutter run` / `flutter build ios` |
| `ios/Runner/GoogleService-Info.plist.backup` | `bookbed-dev` (DEV) | Inactive — must be swapped in manually for dev testing |

There is NO `.staging` variant. Staging iOS testing requires creating one (analogous to `.backup`).

## To run iOS against `bookbed-dev`

```bash
# 1. Swap to the dev plist
cp ios/Runner/GoogleService-Info.plist.backup ios/Runner/GoogleService-Info.plist

# 2. Run with explicit dev target
flutter run -d <ios-device-id> --target lib/main_dev.dart

# (or the widget entry, depending on what you're testing)
flutter run -d <ios-device-id> --target lib/widget_main_dev.dart
```

## When you're done with the dev session — RESTORE the prod plist

```bash
# Save the dev plist for next time
cp ios/Runner/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist.dev-snapshot

# Restore the prod plist from git
git checkout ios/Runner/GoogleService-Info.plist

# Verify
grep PROJECT_ID ios/Runner/GoogleService-Info.plist
# Should print: rab-booking-248fc
```

## Defense-in-depth — Dart-level assert (in code)

Every env-specific entry point (`main_dev.dart`, `main_staging.dart`, `main_prod.dart`, `widget_main.dart`, `widget_main_dev.dart`, `widget_main_staging.dart`) carries a `kDebugMode` assert immediately after `Firebase.initializeApp`. If the runtime project ID doesn't match what the entry point expects, the app crashes on boot with a message naming the mismatch.

This means: even if you forget the plist swap, a `flutter run --target lib/main_dev.dart` against the prod plist will crash visibly instead of silently writing to prod.

Conversely: if you swap the plist but forget `--target`, the default `flutter run` (which uses `lib/main.dart`) will still hit prod options via its `firebase_options.dart` import, and the assert inside `lib/main.dart`'s `_initializeFirebaseSafely` will detect the prod-init landed on a non-prod project ID (when the plist override propagates to native services) — same crash signal.

The asserts ONLY fire in debug builds. Release builds (prod deploys) skip the check.

## Warning signs that you're in the wrong env

- App boots normally but auth signup creates user in prod (check `https://console.firebase.google.com/project/rab-booking-248fc/authentication/users`)
- Stripe Connect onboarding URL contains real LIVE-mode Express signup flow (instead of test-mode)
- Owner sees prod data they don't recognize (other owners' properties)
- Sentry events from your dev session tagged `environment=production`

If you see any of these, stop immediately and check:
1. `git status ios/Runner/GoogleService-Info.plist` — modified? You're on dev plist.
2. The `flutter run` command you used — does it include `--target lib/main_dev.dart`?
3. Cleanup any artifacts via `audit/15` recipe.

## Permanent fix (NOT yet implemented)

Tracked in audit/14 hardening recommendation #2 (doc deleted — git history): create Xcode `Debug-dev` and `Debug-staging` schemes, each with a Run Script Build Phase that copies the correct `GoogleService-Info-{env}.plist` into the bundle at build time. Eliminates the manual file-rename. Larger change; needs Xcode project edits + per-env plist files committed.

Until that lands, use the manual procedure above and rely on the Dart asserts as the safety net.

## See also

- audit/14 (deleted — git history) — initial discovery of the deploy-script branch; scripts since fixed
- `audit/15-prod-contamination-deep-check.md` — Stripe Connect contamination + iOS-specific root cause
- `memory/wave0-test-findings.md` — the original "drop --flavor dev" gotcha that led to Wave 0 contamination
