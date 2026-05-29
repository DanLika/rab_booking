# App Check Client Init — 2026-05-29

Closes the App Check client-init prereq carried over from audit/84 STEP 4.

## Done autonomously (this PR — #560)

- `firebase_app_check: ^0.4.4+1` pinned in `pubspec.yaml`
- `lib/core/init/app_check_init.dart` — `AppCheckInit.activate({required bool isProd})`
  - Reads `APP_CHECK_RECAPTCHA_KEY` from `String.fromEnvironment(...)` (set via `--dart-define`)
  - Idempotent `_activated` flag — chained entries (`main_dev.dart → app.runMainApp() → main.dart's _initializeInBackground`) never double-activate
  - Android: Play Integrity (prod) / Debug (dev+staging)
  - iOS: DeviceCheck (prod) / Debug (dev+staging)
  - Web: `ReCaptchaV3Provider(_recaptchaKey)` if key supplied, else placeholder
  - `debugPrint` warning when running PROD-on-web without a real key
- All 12 entrypoints wired (PROD = 5, dev = 4, staging = 3):
  - PROD: `main.dart`, `main_prod.dart`, `widget_main.dart`, `admin_main.dart`, `admin_main_production.dart`
  - dev: `main_dev.dart`, `owner_main_dev.dart`, `widget_main_dev.dart`, `admin_main_dev.dart`
  - staging: `main_staging.dart`, `widget_main_staging.dart`, `admin_main_staging.dart`
- `flutter analyze` 95 (3 lint infos delta from 92 baseline, no errors)
- `flutter test` 1216 / 1216 GREEN
- 3 web bundles built clean (`build/web_{owner,widget,admin}`)
- Dev hosting redeployed via `tool/deploy-dev.sh {owner,widget,admin}` — DEV entries (audit/33 contamination guard)
- PROD hosting redeployed via `firebase deploy --only hosting:owner,hosting:widget,hosting:admin --project rab-booking-248fc`

## Why no behavior change for end users

Every callable still has `enforceAppCheck: false`. Placeholder tokens fail validation, but the gate isn't enforced anywhere → no requests are rejected. This PR only starts producing telemetry against the App Check pipeline.

## Manual follow-ups (REQUIRED before enforcement flip)

### 1. Register reCAPTCHA v3 site (Firebase Console, 5 min)

- Firebase Console → bookbed PROD project (`rab-booking-248fc`) → App Check → Apps
- For each Web app — bookbed-owner, bookbed-widget, bookbed-admin — click "reCAPTCHA v3" → Register
- A single site key across all three is simpler (the `--dart-define` only takes one value)
- Repeat for bookbed-dev project

### 2. Register Android Play Integrity

- Firebase Console → App Check → Apps → Android app → Play Integrity → Register
- Requires Play Console linkage; PROD AAB build is already on Play Store, so this should be one click

### 3. Register iOS DeviceCheck

- Firebase Console → App Check → Apps → iOS app → DeviceCheck → Register
- Automatic — Firebase provisions the DeviceCheck key from the linked Apple Developer account

### 4. Pass site key to PROD builds

Wherever PROD builds happen (`.github/workflows/deploy-*.yml`, `tool/deploy-prod.sh`, etc.):

```bash
flutter build web --release --target lib/main_prod.dart \
  --dart-define=APP_CHECK_RECAPTCHA_KEY=<paste-key-here> \
  -o build/web_owner
```

Repeat for `widget_main.dart` + `admin_main_production.dart`. Store the key as a GitHub Actions secret (`APP_CHECK_RECAPTCHA_KEY`), expose as env var, inject via `--dart-define`.

### 5. Wait 24-48h, verify Firebase Console metrics

- Firebase Console → App Check → Metrics → "Verified requests" %
- Target: ≥95% on PROD across owner/widget/admin web + Android + iOS
- Investigate any "Unverified" spike before flipping enforcement

### 6. Flip `enforceAppCheck: true` (separate PR — audit/86 candidate)

After ≥95% verified for 7 days on PROD:

- `functions/src/stripeSubscription.ts` — `createSubscriptionCheckoutSession`
- `functions/src/stripePayment.ts` — `createStripeCheckoutSession`
- `functions/src/availability.ts` — `getUnitAvailability`
- Consider expanding to: `createStripeConnectAccount`, `createBookingAtomic`, `guestCancelBooking`, `verifyBookingAccess`, `getBookingByStripeSession`
- Deploy, monitor for legit-traffic rejection spike, roll back per-CF if necessary

## Defense-in-depth implication

Once enforcement is on, the residual risk noted in `[[pr517-f-50-02-closed-2026-05-27]]` ("distributed botnet can still bump victim's loginAttempts counter via many IPs") is closed for the anonymous attack surface — bots without a valid App Check token can no longer reach `recordLoginFailure`. The same applies to `getUnitAvailability` widget enumeration and Stripe checkout abuse.

## Region notes

The Stripe + booking + availability hot path runs in `us-central1`; the auth-security + admin family in `europe-west1`. Both regions get App Check uniformly (it's a per-token check, not region-gated). No region-specific config needed.

## Architecture notes

- `lib/main.dart` calls `AppCheckInit.activate(isProd: true)` inside `_initializeInBackground()` AFTER the Firebase init try/catch block, BEFORE Firestore persistence config. The idempotency guard means dedicated entries (`main_dev.dart` etc.) that already activated AppCheck before delegating to `runMainApp()` aren't penalized.
- Widget + admin entry points use `core/init/app_check_init.dart` relative imports (Dart lint `prefer_relative_imports` flagged the absolute `package:bookbed/` form on 3 main entries during analyze).
- The placeholder key strategy is borrowed from the audit/85 brief — chose it over making `webProvider` nullable so we don't have to thread an `if (kIsWeb && _recaptchaKey.isEmpty)` branch through the SDK call.

## Cross-links

- Predecessor: [audit/84 STEP 4](./84-security-sweep-2026-05-29.md) (App Check noted as deferred)
- Follow-up: audit/86 (enforcement flip after metric burn-in)
- Related memory: `[[pr517-f-50-02-closed-2026-05-27]]` (botnet residual risk), `[[oncall-default-cors-reflective]]` (Firebase Functions v2 default behavior — now mitigated by F-58-07 allowlist), `[[dev-hosting-prod-bundling-class]]` (audit/33 contamination guard used by `tool/deploy-dev.sh`)
