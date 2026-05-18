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

Dart entrypoints po env: `lib/main.dart` (prod), `lib/main_dev.dart`, `lib/main_staging.dart` + matching `firebase_options{,_dev,_staging}.dart`. Admin nema dev entrypoint (samo prod + staging).

### Footgun: hardcoded prod project ID
`lib/features/owner_dashboard/presentation/screens/ical/ical_export_list_screen.dart:211` hardkodira `const projectId = 'rab-booking-248fc'`. Dev build-ovi će generirati iCal export URL-ove koji pokazuju na PROD Cloud Functions. Zamijeniti s `EnvironmentConfig.firebaseProjectId` prije dev deploy-a.

### Footgun: GitHub Actions workflow
`.github/workflows/deploy-widget.yml:57` hardkodira `projectId: rab-booking-248fc`. Workflow trenutno radi samo na prod.

## Functions env layering po projektu

`functions/.env` (default) + `functions/.env.<projectId>` (per-project, ako postoji).

Trenutno postoji samo `.env.rab-booking-248fc`. Za `bookbed-dev` deploy: kreirati `functions/.env.bookbed-dev` sa minimum `FROM_EMAIL`, `FROM_NAME`, `WIDGET_URL` (dev), `BOOKING_DOMAIN`, `WEB_APP_URL`, `PASSWORD_RESET_REDIRECT_URL`. Bez toga dev fall-back-a na default `.env` koji ima prod URL-ove → guest emails iz dev pokazuju na prod.

## Build commands

```bash
# Owner dashboard
flutter build web --release --target lib/main.dart -o build/web_owner

# Booking widget
flutter build web --release --target lib/widget_main.dart -o build/web_widget

# Admin dashboard
flutter build web --release --target lib/admin_main.dart -o build/web_admin

# Deploy all
firebase deploy --only hosting

# Deploy admin only
firebase deploy --only hosting:admin
```

## Klijent subdomene

Dodaju se u Firebase Console → Hosting → Add custom domain:
- `jasko-rab.view.bookbed.io` → widget za Jasmina
- Format: `{subdomain}.view.bookbed.io`

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
flutter build apk --release  # Android
flutter build ios --release --no-codesign  # iOS
flutter build web --release  # Web
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
