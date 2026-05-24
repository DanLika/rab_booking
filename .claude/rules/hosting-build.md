---
paths:
  - "firebase.json"
  - ".firebaserc"
  - "web/**"
  - ".github/workflows/**"
  - "android/**"
  - "ios/**"
  - "pubspec.yaml"
---

# Hosting, Build & Deploy

## Domena struktura

**Domena**: `bookbed.io` (Porkbun) → DNS na Cloudflare

| Domena | Svrha | Firebase Site |
|--------|-------|---------------|
| `bookbed.io` | **Marketing/Landing page** (NE widget!) | - (buduće) |
| `app.bookbed.io` | Owner Dashboard | `bookbed-owner` |
| `view.bookbed.io` | **Booking Widget** (embed iframe) | `bookbed-widget` |
| `*.view.bookbed.io` | Klijent subdomene za widget | `bookbed-widget` |
| `bookbed-admin.web.app` | **Admin Dashboard** | `bookbed-admin` |

**⚠️ NE MIJEŠATI**: `bookbed.io` je REZERVISAN za marketing sajt. Widget UVIJEK ide na `view.bookbed.io`!

## Firebase Hosting targets (`.firebaserc`)

| Target | Site ID | Build folder | Custom domain |
|--------|---------|--------------|---------------|
| `owner` | `bookbed-owner` | `build/web_owner` | app.bookbed.io |
| `widget` | `bookbed-widget` | `build/web_widget` | view.bookbed.io, *.view.bookbed.io |
| `admin` | `bookbed-admin` | `build/web_admin` | bookbed-admin.web.app |

## Tri Firebase projekta (`.firebaserc` aliasi)

| Alias | Project ID | Notes |
|---|---|---|
| `default` / `production` | `rab-booking-248fc` | **PROD** — legacy naziv, sva produkcija (Stripe LIVE, Resend prod sender) |
| `development` | `bookbed-dev` | Konfigurisan, projekat postoji. Site IDs: `bookbed-{owner,widget,admin}-dev` |
| `staging` | `bookbed-staging` | Konfigurisan, projekat postoji. Site IDs: `bookbed-{owner,widget,admin}-staging` |

Site IDs za `-dev` i `-staging` MORAJU postojati u Firebase Console prije deploy-a (target mapping ne kreira ih).

Dart entrypoints po env:

| Surface | DEV | STAGING | PROD |
|---|---|---|---|
| Owner dashboard | `lib/owner_main_dev.dart` | `lib/main_staging.dart` | `lib/main_prod.dart` |
| Booking widget | `lib/widget_main_dev.dart` | `lib/widget_main_staging.dart` | `lib/widget_main.dart` |
| Admin dashboard | `lib/admin_main_dev.dart` | `lib/admin_main_staging.dart` | `lib/admin_main_production.dart` |

`firebase_options{,_dev,_staging}.dart` — auto-applied by entry point's `Firebase.initializeApp(options: ...)`. Each non-PROD entry point also calls `EnvironmentConfig.setEnvironment(Environment.X)` AND asserts the runtime project ID matches the expected env in `kDebugMode` (defense-in-depth against the contamination class documented in `audit/14` + `audit/15` + `audit/33`).

**⚠️ NIKADA NE BUILDAJ `--target lib/main.dart` ZA DEV/STAGING DEPLOY.** `lib/main.dart` uses PROD `DefaultFirebaseOptions` directly via its standalone `main()` (line 77+), bypassing all env asserts. It exposes `runMainApp()` for env-specific entry points to call after init — `lib/main_prod.dart`, `lib/owner_main_dev.dart`, `lib/main_staging.dart` are the canonical entries. Building `--target lib/main.dart` for dev/staging hosting silently bakes PROD options into the bundle.

### Footgun: hardcoded prod project ID
`lib/features/owner_dashboard/presentation/screens/ical/ical_export_list_screen.dart:211` hardkodira `const projectId = 'rab-booking-248fc'`. Dev build-ovi će generirati iCal export URL-ove koji pokazuju na PROD Cloud Functions. Zamijeniti s `EnvironmentConfig.firebaseProjectId` prije dev deploy-a.

### Footgun: GitHub Actions workflow
`.github/workflows/deploy-widget.yml:57` hardkodira `projectId: rab-booking-248fc`. Workflow trenutno radi samo na prod. Equivalent owner + admin dev/staging deploy workflows do NOT exist — all non-prod deploys are manual.

### Footgun (resolved 2026-05-24, audit/33 + audit/37): dev hosting served PROD-options build
`bookbed-owner-dev.web.app` was deployed with `--target lib/main.dart` (PROD options bundled). Firestore writes landed in `rab-booking-248fc` (PROD) instead of `bookbed-dev`. Fix: redeploy via `tool/deploy-dev.sh owner` (uses `--target lib/owner_main_dev.dart`). Verify post-redeploy: open `bookbed-owner-dev.web.app` → DevTools Network → Firestore requests should target `projects/bookbed-dev/databases/(default)`. Same wrapper now covers admin (`tool/deploy-dev.sh admin` → `lib/admin_main_dev.dart`) and widget.

### Footgun: owner dashboard has no env-overlay env var system
All per-env behavior is baked at build time. There's no way to ship one bundle that switches env via URL/cookie. Always rebuild on env change.

## Functions env layering po projektu

`functions/.env` (default) + `functions/.env.<projectId>` (per-project, ako postoji).

Trenutno postoji samo `.env.rab-booking-248fc`. Za `bookbed-dev` deploy: kreirati `functions/.env.bookbed-dev` sa minimum `FROM_EMAIL`, `FROM_NAME`, `WIDGET_URL` (dev), `BOOKING_DOMAIN`, `WEB_APP_URL`, `PASSWORD_RESET_REDIRECT_URL`. Bez toga dev fall-back-a na default `.env` koji ima prod URL-ove → guest emails iz dev pokazuju na prod.

## Build commands

**Prefer `tool/deploy-dev.sh` over manual builds for dev** — wraps the right `--target` + `--project` per surface and refuses to deploy with PROD options to dev hosting.

### PROD builds (manual or via deploy-widget.yml CI)

```bash
# Owner dashboard — PROD entry point, NOT lib/main.dart
flutter build web --release --target lib/main_prod.dart -o build/web_owner

# Booking widget — PROD
flutter build web --release --target lib/widget_main.dart -o build/web_widget

# Admin dashboard — PROD (the only env admin currently has)
flutter build web --release --target lib/admin_main_production.dart -o build/web_admin

# Deploy all PROD targets
firebase use production && firebase deploy --only hosting

# Deploy admin only
firebase use production && firebase deploy --only hosting:admin
```

### DEV builds (use `tool/deploy-dev.sh` wrapper instead)

```bash
# Owner dashboard — DEV (uses bookbed-dev Firebase project)
tool/deploy-dev.sh owner

# Equivalent manual incantation:
flutter build web --release --target lib/owner_main_dev.dart -o build/web_owner
firebase deploy --only hosting:owner --project bookbed-dev

# Booking widget — DEV
tool/deploy-dev.sh widget
# == flutter build web --release --target lib/widget_main_dev.dart -o build/web_widget
#  + firebase deploy --only hosting:widget --project bookbed-dev

# Admin dashboard — DEV
tool/deploy-dev.sh admin
# == flutter build web --release --target lib/admin_main_dev.dart -o build/web_admin
#  + firebase deploy --only hosting:admin --project bookbed-dev
```

### STAGING builds

```bash
# Owner dashboard — STAGING
flutter build web --release --target lib/main_staging.dart -o build/web_owner
firebase deploy --only hosting:owner --project bookbed-staging

# Booking widget — STAGING
flutter build web --release --target lib/widget_main_staging.dart -o build/web_widget
firebase deploy --only hosting:widget --project bookbed-staging

# Admin dashboard — STAGING
flutter build web --release --target lib/admin_main_staging.dart -o build/web_admin
firebase deploy --only hosting:admin --project bookbed-staging
```

### Post-deploy verification

After any non-PROD hosting deploy, open the URL → DevTools Network → confirm the first Firestore request targets the expected project:
- DEV → `projects/bookbed-dev/databases/(default)`
- STAGING → `projects/bookbed-staging/databases/(default)`
- PROD → `projects/rab-booking-248fc/databases/(default)`

If wrong, you bundled the wrong entry point — redeploy with correct `--target`.

## Klijent subdomene

Dodaju se u Firebase Console → Hosting → Add custom domain:
- `jasko-rab.view.bookbed.io` → widget za Jasmina
- Format: `{subdomain}.view.bookbed.io`

## Per-env URLs in Dart code — use `EnvironmentConfig`

`lib/core/config/environment.dart` is the single source of truth for hosts and base URLs. Never hardcode `view.bookbed.io` / `app.bookbed.io` / `bookbed.io` / project IDs in Dart code. T13 (`audit/08-environment-url-centralization.md`, commit `b0bad83c`) centralized all 6 prod-path callsites.

API:
```dart
EnvironmentConfig.firebaseProjectId   // 'rab-booking-248fc' / 'bookbed-staging' / 'bookbed-dev'
EnvironmentConfig.functionsBaseUrl    // https://us-central1-{project}.cloudfunctions.net
EnvironmentConfig.widgetHost          // view.bookbed.io / staging.view.bookbed.io / bookbed-widget-dev.web.app
EnvironmentConfig.dashboardHost       // app.bookbed.io / staging.app.bookbed.io / bookbed-owner-dev.web.app
EnvironmentConfig.marketingHost       // 'bookbed.io' (all envs — no marketing hosting target)
EnvironmentConfig.widgetBaseUrl       // https://{widgetHost}
EnvironmentConfig.dashboardBaseUrl    // https://{dashboardHost}
EnvironmentConfig.isWidgetHost(host)  // bare host OR client subdomain of widget
EnvironmentConfig.isMarketingHost(host) // bare marketing OR www.{marketing}
```

Exceptions that stay hardcoded:
- iCal UID domain `@bookbed.io` (RFC 5545 stable identifier)
- Embed-snippet copy in `embed_help_screen.dart` / `embed_widget_guide_screen.dart` / `faq_screen.dart` (owner paste targets MUST be prod URL)

## Multi-Platform Build System

| Platforma | Build mod | Hot Reload | Napomena |
|-----------|-----------|------------|----------|
| **Web (Chrome)** | Debug | Da | Normalno radi |
| **iOS Simulator** | Debug | Da | Normalno radi |
| **Android fizički** | **Release** | Ne | Debug ima bug |
| **Android Emulator** | **Release** | Ne | Debug ima bug |

### Verzije dependency-a (KRITIČNO)

```yaml
# pubspec.yaml - NE UPGRADEATI bez testiranja!
flutter_riverpod: ^2.5.1      # NE 3.x - breaking changes
riverpod_annotation: ^2.3.5   # NE 3.x
freezed: ^2.5.7               # NE 3.x - zahtijeva sealed class
freezed_annotation: ^2.4.4    # NE 3.x
```

```gradle
// android/settings.gradle.kts
id("com.android.application") version "8.9.1"  // AGP
id("org.jetbrains.kotlin.android") version "2.1.0"  // Kotlin

// android/gradle/wrapper/gradle-wrapper.properties
distributionUrl=gradle-8.11.1-all.zip  // Gradle
```

### Android Debug Build Bug

**Problem**: `firebase_storage` plugin ne kompajlira Kotlin kod prije Java koda u debug modu.
**Workaround**: Koristi `--release` flag za Android uređaje.

### Android AAB Build (Play Store) — koristi `tool/build_aab.sh`

`flutter build appbundle` direktno PUCA jer Flutter 3.38.5 generira `GeneratedPluginRegistrant.java` koji importuje `flutter_native_splash` runtime klasu koju paket više ne ships (paket je dev-only CLI). `flutter build apk` ne pogađa tu putanju, samo `bundleRelease`.

**Fix** (committed 2026-05-22): wrapper script `tool/build_aab.sh` patcha `.flutter-plugins-dependencies` da postavi `native_build: false` za `flutter_native_splash` prije nego pokrene `flutter build appbundle`.

```bash
# Lokalno (Play Store upload)
tool/build_aab.sh                    # release + lib/main.dart
tool/build_aab.sh --release --target lib/widget_main.dart
```

**CI**: `.github/workflows/ci.yml` `build-android` job (Job 3) je ENABLED i koristi `./tool/build_aab.sh --release`. NE vraćaj na direktni `flutter build appbundle` — pukne. Reference: `audit/16-android-regression-full.md` Appendix B, `memory/aab-build-blocker.md`.

### Pokretanje

```bash
# Web (debug, sa hot reload)
flutter run -d chrome --web-port 8080

# iOS Simulator (debug, sa hot reload)
flutter run -d <iOS_DEVICE_ID>

# Android (MORA biti release)
flutter run -d <ANDROID_DEVICE_ID> --release
```

### Conditional imports za Web

```dart
// lib/core/utils/web_utils.dart - barrel export
export 'web_utils_stub.dart'
    if (dart.library.js_interop) 'web_utils_web.dart';
```

**⚠️ NIKADA direktno importovati `dart:js_interop` ili `dart:html`** - koristiti barrel exports!

### Prije build-a

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release          # Android APK (debug/sideload)
tool/build_aab.sh --release          # Android AAB (Play Store) — NE direktan `flutter build appbundle`
flutter build ios --release --no-codesign  # iOS
flutter build web --release          # Web
```

### NE RADITI

- NE pokreći više Android buildova paralelno (Gradle cache conflict)
- NE upgradeati Riverpod/Freezed na 3.x bez full refactora
- NE miješati debug i release buildove bez `flutter clean`

## Force Update System (Android)

**Dokumentacija**: `docs/FORCE_UPDATE_SETUP.md`

| Fajl | Svrha |
|------|-------|
| `core/models/app_config.dart` | Freezed model za Firestore config |
| `core/services/version_check_service.dart` | Fetch + compare verzija |
| `core/widgets/force_update_dialog.dart` | Non-dismissible dialog |
| `core/widgets/optional_update_dialog.dart` | Dismissible dialog (24h) |
| `core/providers/version_check_provider.dart` | Provider + VersionCheckWrapper |

Firestore Config: `app_config/android` — `minRequiredVersion`, `latestVersion`, `forceUpdateEnabled`

Force update radi SAMO na Android native app. Web se automatski ažurira pri deploy-u.
