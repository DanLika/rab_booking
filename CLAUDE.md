# Claude Code - Project Documentation

**BookBed** - Booking management platforma za property owner-e.

**Dodatni dokumenti:**
- [CLAUDE_BUGS_ARCHIVE.md](./CLAUDE_BUGS_ARCHIVE.md) - Detaljni bug fix-evi sa code examples
- [CLAUDE_WIDGET_SYSTEM.md](./CLAUDE_WIDGET_SYSTEM.md) - Widget modovi, payment logic, pricing
- [CLAUDE_MCP_TOOLS.md](./CLAUDE_MCP_TOOLS.md) - MCP serveri, slash commands

---

## <� NIKADA NE MIJENJAJ

| Komponenta | Razlog |
|------------|--------|
| Cjenovnik tab (`unified_unit_hub_screen.dart`) | FROZEN - referentna implementacija |
| Unit Wizard publish flow | 3 Firestore docs redoslijed kriti
an |
| Timeline Calendar z-index | Cancelled PRVI, confirmed ZADNJI |
| Calendar Repository (`firebase_booking_calendar_repository.dart`) | 989 linija, duplikacija NAMJERNA - bez unit testova NE DIRATI |
| Owner email u `atomicBooking.ts` | UVIJEK aalje - NE vraaj conditional check |
| Subdomain validation regex | `/^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$/` (3-30 chars) |
| `generateViewBookingUrl()` u `emailService.ts` | Email URL logika |
| Navigator.push za confirmation | NE vraaj state-based navigaciju |

---

## <� STANDARDI

```dart
// Gradients
final gradients = Theme.of(context).extension<AppGradients>()!;

// Input fields - UVIJEK 12px borderRadius
InputDecorationHelper.buildDecoration()

// Provider invalidation - POSLIJE save-a
await repository.updateData(...);
ref.invalidate(dataProvider);

// Nested config - UVIJEK copyWith
currentSettings.emailConfig.copyWith(requireEmailVerification: false)
// NE: EmailNotificationConfig(requireEmailVerification: false) - gubi polja!
```

---

## =� CALENDAR SYSTEM - KRITINO

**Repository**: `firebase_booking_calendar_repository.dart`
- Koristi `DateTime.utc()` za SVE map keys
- Stream errors: `onErrorReturnWith()` vraa prazan map
- Turnover detection MORA provjeriti: `partialCheckIn`, `partialCheckOut`, `booked`, `partialBoth`

**DateStatus enum**:
- `pending` � ~uta + dijagonalni uzorak (`#6B4C00` @ 60%)
- `partialBoth` � turnover day (oba bookinga)
- `isCheckOutPending` / `isCheckInPending` � prati koja polovica je pending

**� NE REFAKTORISATI** - duplikacija `_buildCalendarMap` vs `_buildYearCalendarMap` je NAMJERNA safety net. Prethodni refaktoring uveo 5+ bugova.

---

##  CLOUD FUNCTIONS (`functions/src/`)

**Logging** - UVIJEK koristi strukturirani logger:
```typescript
import {logInfo, logError, logWarn} from "./logger";
// NE: console.log() - nestrukturirano, teako za debug
```

**Timezone** - UVIJEK UTC za date comparison:
```typescript
const today = new Date();
today.setUTCHours(0, 0, 0, 0);  // CORRECT
// NE: today.setHours(0, 0, 0, 0) - koristi local timezone
```

**Rate Limiting** - dostupno u `utils/rateLimit.ts`:
- `checkRateLimit()` - in-memory, za hot paths
- `enforceRateLimit()` - Firestore-backed, za critical actions

**Input Sanitization** - `utils/inputSanitization.ts`:
```typescript
sanitizeText(name), sanitizeEmail(email), sanitizePhone(phone)
```

---

## =� STRIPE FLOW

```
1. User klikne "Pay with Stripe"
2. PLACEHOLDER booking kreira se sa status="stripe_pending" (blokira datume)
3. Same-tab redirect na Stripe Checkout
4. Webhook UPDATE-a placeholder na status="confirmed"
5. Return URL: ?stripe_status=success&session_id=cs_xxx
6. Widget poll-uje fetchBookingByStripeSessionId() (max 30s)
7. Confirmation screen
```

**KRITINO**: Placeholder booking sprje
ava race condition gdje 2 korisnika plate za iste datume.

---

## 🌐 HOSTING & DOMENE

**Domena**: `bookbed.io` (Porkbun) → DNS na Cloudflare

**Firebase Hosting targets** (`.firebaserc`):
| Target | Site ID | Build folder | Custom domain |
|--------|---------|--------------|---------------|
| `owner` | `bookbed-owner` | `build/web_owner` | app.bookbed.io |
| `widget` | `bookbed-widget` | `build/web_widget` | bookbed.io, *.bookbed.io |

**Build commands**:
```bash
# Owner dashboard
flutter build web --release --target lib/main.dart -o build/web_owner

# Booking widget
flutter build web --release --target lib/widget_main.dart -o build/web_widget

# Deploy
firebase deploy --only hosting
```

**Klijent subdomene** (dodaju se u Firebase Console → Hosting → Add custom domain):
- `jasko-rab.bookbed.io` → widget za Jasmina

---

## 📱 MULTI-PLATFORM BUILD SYSTEM

### Podržane platforme
| Platforma | Build mod | Hot Reload | Napomena |
|-----------|-----------|------------|----------|
| **Web (Chrome)** | Debug | ✅ Da | Normalno radi |
| **iOS Simulator** | Debug | ✅ Da | Normalno radi |
| **Android fizički** | **Release** | ❌ Ne | Debug ima bug |
| **Android Emulator** | **Release** | ❌ Ne | Debug ima bug |

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

### Poznati bug: Android Debug Build
**Problem**: `firebase_storage` plugin ne kompajlira Kotlin kod prije Java koda u debug modu.
**Error**: `cannot find symbol: FlutterFirebaseStoragePlugin`
**Workaround**: Koristi `--release` flag za Android uređaje.

### Pokretanje na svim platformama
```bash
# 1. Web (debug, sa hot reload)
flutter run -d chrome --web-port 8080

# 2. iOS Simulator (debug, sa hot reload)
flutter run -d <iOS_DEVICE_ID>

# 3. Android fizički uređaj (MORA biti release)
flutter run -d <ANDROID_DEVICE_ID> --release

# 4. Android Emulator (MORA biti release)
flutter run -d emulator-5554 --release
```

### Conditional imports za Web
Web-specifični kod (npr. `package:web`) koristi conditional imports:
```dart
// lib/core/utils/web_utils.dart - barrel export
export 'web_utils_stub.dart'
    if (dart.library.js_interop) 'web_utils_web.dart';

// Korištenje:
import 'package:rab_booking/core/utils/web_utils.dart';
replaceUrlState('/new-path');  // No-op na mobile, radi na web
createTabCommunicationService();  // Vraća Stub ili Web implementaciju
```

### Prije build-a
```bash
# 1. Očisti stare artefakte
flutter clean

# 2. Regeneriraj dependencies
flutter pub get

# 3. Regeneriraj freezed/riverpod kod
dart run build_runner build --delete-conflicting-outputs

# 4. Test build
flutter build apk --release  # Android
flutter build ios --release --no-codesign  # iOS
flutter build web --release  # Web
```

### ⚠️ NE RADITI
- NE pokreći više Android buildova paralelno (Gradle cache conflict)
- NE upgradeati Riverpod/Freezed na 3.x bez full refactora
- NE miješati debug i release buildove bez `flutter clean`

---

## 🔗 SUBDOMAIN & URL SLUG SYSTEM

**URL formati** (widget):
| Format | Primjer | Korištenje |
|--------|---------|------------|
| Query params | `jasko-rab.bookbed.io/?property=XXX&unit=YYY` | iframe embed |
| Clean slug | `jasko-rab.bookbed.io/apartman-6` | standalone, dijeljenje |

**Rezolucija slug URL-a**:
1. Subdomain (`jasko-rab`) → `fetchPropertyBySubdomain()` → property
2. Path slug (`apartman-6`) → `fetchUnitBySlug(propertyId, slug)` → unit

**Ključni fajlovi**:
- `subdomain_service.dart` → `resolveFullContext(urlSlug)`
- `subdomain_provider.dart` → `fullSlugContextProvider(slug)`
- `router_widget.dart` → `/:slug` route

**Slug stabilnost**: Slug se NE regenerira automatski kad se promijeni naziv unita (`_isManualSlugEdit` flag u `unit_form_screen.dart`).

**Booking view URL**: `villa-marija.bookbed.io/view?ref=XXX&email=YYY`

---

##  QUICK CHECKLIST

**Prije commitanja:**
- [ ] `flutter analyze` = 0 issues
- [ ] Pro
itaj CLAUDE.md ako diraa kriti
ne sekcije
- [ ] `ref.invalidate()` POSLIJE repository poziva
- [ ] `mounted` check prije async setState/navigation

**Responsive breakpoints:**
- Desktop: e1200px
- Tablet: 600-1199px
- Mobile: <600px

---

---

## 🎨 UI/UX STANDARDI

**Filozofija**: Less colorful, more professional - neutralne pozadine sa jednom accent bojom na ikonama.

**Dialogs**:
- Footer: `AppColors.dialogFooterDark/Light`, border: `AppColors.sectionDividerDark/Light`
- Padding: 12px mobile (<400px), 16-20px desktop
- Border radius: 11-12px

**Cards/Tiles**:
- Ikone: jedna boja (primary) sa 10-12% opacity pozadinom
- Shadows: `AppShadows.elevation1` za većinu, `elevation2` za istaknute
- Border radius: 12px standard

**Skeleton loaders**: `SkeletonColors.baseColor/highlightColor` iz `skeleton_loader.dart`

**Snackbars (Widget)**: `SnackBarHelper` u `shared/utils/ui/snackbar_helper.dart`
- Boje prate calendar status: Success=Available(zelena), Error=Booked(crvena), Warning=Pending(amber), Info=plava
- Light: `#10B981`, `#EF4444`, `#F59E0B`, `#3B82F6`
- Dark: `#34D399`, `#F87171`, `#FBBF24`, `#60A5FA`
- Auto-hide prethodnog, centrirani tekst, sve poruke koriste `WidgetTranslations`

---

**Last Updated**: 2025-12-10 | **Version**: 4.8

**Changelog 4.8**: Widget snackbar boje usklađene sa calendar statusima.

**Changelog 4.7**: Multi-platform build dokumentacija - Android release mode, conditional imports, dependency verzije.

**Changelog 4.6**: URL slug sistem za clean URLs (`/apartman-6` umjesto query params).
