# Claude Code - Project Documentation

**BookBed** - Booking management platforma za property owner-e.

**Dodatni dokumenti:**
- [CLAUDE_BUGS_ARCHIVE.md](./docs/bugs-archive/CLAUDE_BUGS_ARCHIVE.md) - Detaljni bug fix-evi sa code examples
- [CLAUDE_WIDGET_SYSTEM.md](./docs/cloud-widget-systems/CLAUDE_WIDGET_SYSTEM.md) - Widget modovi, payment logic, pricing
- [CLAUDE_MCP_TOOLS.md](./docs/cloud-mcp-tools/CLAUDE_MCP_TOOLS.md) - MCP serveri, slash commands

---

## <? NIKADA NE MIJENJAJ

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

## <? STANDARDI

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

// Provider error handling - UVIJEK graceful degradation
try {
  return await repository.fetchData();
} catch (e, stackTrace) {
  await LoggingService.logError('Provider: Failed', e, stackTrace);
  return []; // ili null - NE throw
}
```

---

## =? CALENDAR SYSTEM - KRITINO

**Repository**: `firebase_booking_calendar_repository.dart`
- Koristi `DateTime.utc()` za SVE map keys
- Stream errors: `onErrorReturnWith()` vraa prazan map
- Turnover detection MORA provjeriti: `partialCheckIn`, `partialCheckOut`, `booked`, `partialBoth`

**DateStatus enum**:
- `pending` ? ~uta + dijagonalni uzorak (`#6B4C00` @ 60%)
- `partialBoth` ? turnover day (oba bookinga)
- `isCheckOutPending` / `isCheckInPending` ? prati koja polovica je pending

**? NE REFAKTORISATI** - duplikacija `_buildCalendarMap` vs `_buildYearCalendarMap` je NAMJERNA safety net. Prethodni refaktoring uveo 5+ bugova.

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

## =? STRIPE FLOW

```
1. User klikne "Pay with Stripe"
2. PLACEHOLDER booking kreira se sa status="pending" (blokira datume)
3. Same-tab redirect na Stripe Checkout
4. Webhook UPDATE-a placeholder na status="confirmed"
5. Return URL: ?stripe_status=success&session_id=cs_xxx
6. Widget poll-uje fetchBookingByStripeSessionId() (max 30s)
7. Confirmation screen
```

**KRITIČNO - Collection Group Query Bug**:
- NE KORISTITI `FieldPath.documentId` sa `collectionGroup()` query
- Firestore očekuje PUNI PUT dokumenta, ne samo ID
- Error: `Invalid query. When querying a collection group by documentId()...`
- **RJEŠENJE**: Koristi `stripe_session_id` field za lookup umjesto document ID
- Svi cross-tab messaging pathovi (BroadcastChannel, postMessage) MORAJU proslijediti `sessionId`
- `TabCommunicationService.sendPaymentComplete()` prima optional `sessionId` parametar

**KRITINO**: Placeholder booking sprje
ava race condition gdje 2 korisnika plate za iste datume.

---

## ?? HOSTING & DOMENE

**Domena**: `bookbed.io` (Porkbun) ? DNS na Cloudflare

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

**Klijent subdomene** (dodaju se u Firebase Console ? Hosting ? Add custom domain):
- `jasko-rab.bookbed.io` ? widget za Jasmina

---

## ?? MULTI-PLATFORM BUILD SYSTEM

### Podr�ane platforme
| Platforma | Build mod | Hot Reload | Napomena |
|-----------|-----------|------------|----------|
| **Web (Chrome)** | Debug | ? Da | Normalno radi |
| **iOS Simulator** | Debug | ? Da | Normalno radi |
| **Android fizi�ki** | **Release** | ? Ne | Debug ima bug |
| **Android Emulator** | **Release** | ? Ne | Debug ima bug |

### Verzije dependency-a (KRITI�NO)
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
**Workaround**: Koristi `--release` flag za Android ure�aje.

### Pokretanje na svim platformama
```bash
# 1. Web (debug, sa hot reload)
flutter run -d chrome --web-port 8080

# 2. iOS Simulator (debug, sa hot reload)
flutter run -d <iOS_DEVICE_ID>

# 3. Android fizi�ki ure�aj (MORA biti release)
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

// lib/core/utils/browser_detection.dart - barrel export
export 'browser_detection_stub.dart'
    if (dart.library.js_interop) 'browser_detection_web.dart';

// Korištenje:
import 'package:bookbed/core/utils/web_utils.dart';
import 'package:bookbed/core/utils/browser_detection.dart';

replaceUrlState('/new-path');  // No-op na mobile, radi na web
BrowserDetection.getBrowserName();  // 'unknown' na mobile, detektira browser na web
```

**⚠️ NIKADA direktno importovati `dart:js_interop` ili `dart:html`** - koristiti barrel exports!

### Prije build-a
```bash
# 1. O�isti stare artefakte
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

### ?? NE RADITI
- NE pokre�i vi�e Android buildova paralelno (Gradle cache conflict)
- NE upgradeati Riverpod/Freezed na 3.x bez full refactora
- NE mije�ati debug i release buildove bez `flutter clean`

---

## ?? ANDROID CHROME KEYBOARD FIX (Flutter #175074)

**Problem**: Na Android Chrome, kada korisnik zatvori tastaturu BACK tipkom, Flutter Web (CanvasKit) ne recalculate-a layout i ostavlja bijeli prostor gdje je bila tastatura.

**Uzrok**: Flutter issue [#175074](https://github.com/flutter/flutter/issues/175074) - `resizeToAvoidBottomInset` ne radi korektno na Android Web.

### Rje�enje (3 komponente):

**1. JavaScript fix u `web/index.html`**:
```javascript
// "Jiggle" method - force Flutter to recalculate
function forceFlutterRecalc() {
  var glassPane = document.querySelector('flt-glass-pane');
  glassPane.style.width = 'calc(100% - 1px)';
  glassPane.style.height = 'calc(100% - 1px)';
  void glassPane.offsetHeight; // Force reflow
  window.dispatchEvent(new Event('resize'));
  requestAnimationFrame(function() {
    glassPane.style.width = '100%';
    glassPane.style.height = '100%';
    window.dispatchEvent(new Event('resize'));
  });
}
// Triggered on visualViewport resize when keyboard closes
```

**2. Dart mixin za svaki screen sa input poljima**:
```dart
// Dodaj import
import '../../../../core/utils/keyboard_dismiss_fix_mixin.dart';

// Dodaj mixin
class _MyScreenState extends State<MyScreen> with AndroidKeyboardDismissFix {

// Wrap Scaffold u KeyedSubtree
@override
Widget build(BuildContext context) {
  return KeyedSubtree(
    key: ValueKey('my_screen_$keyboardFixRebuildKey'),
    child: Scaffold(
      resizeToAvoidBottomInset: false, // KRITI�NO!
      // ...
    ),
  );
}
```

**3. Meta tag u `web/index.html`**:
```html
<meta name="viewport" content="width=device-width, initial-scale=1.0, interactive-widget=resizes-content">
```

### Fajlovi:
| Fajl | Svrha |
|------|-------|
| `web/index.html` | JavaScript "jiggle" fix + visualViewport listener |
| `keyboard_dismiss_fix_mixin.dart` | Dart mixin sa `keyboardFixRebuildKey` |
| `keyboard_dismiss_fix_web.dart` | Web implementacija (JS interop) |
| `keyboard_dismiss_fix_stub.dart` | Stub za non-web platforme |

### Screens sa mixinom (OBAVEZNO za nove forme):
- `enhanced_login_screen.dart`
- `enhanced_register_screen.dart`
- `forgot_password_screen.dart`
- `change_password_screen.dart`
- `edit_profile_screen.dart`
- `bank_account_screen.dart`
- `property_form_screen.dart`
- `unit_form_screen.dart`
- `step_1_basic_info.dart`, `step_2_capacity.dart`, `step_3_pricing.dart`

### ?? KADA KREIRA� NOVI SCREEN SA INPUT POLJIMA:
1. Dodaj `with AndroidKeyboardDismissFix` mixinu
2. Wrap `Scaffold` u `KeyedSubtree(key: ValueKey('screen_name_$keyboardFixRebuildKey'), ...)`
3. Postavi `resizeToAvoidBottomInset: false` na Scaffold

---

## ?? SUBDOMAIN & URL SLUG SYSTEM

**URL formati** (widget):
| Format | Primjer | Kori�tenje |
|--------|---------|------------|
| Query params | `jasko-rab.bookbed.io/?property=XXX&unit=YYY` | iframe embed |
| Clean slug | `jasko-rab.bookbed.io/apartman-6` | standalone, dijeljenje |

**Rezolucija slug URL-a**:
1. Subdomain (`jasko-rab`) ? `fetchPropertyBySubdomain()` ? property
2. Path slug (`apartman-6`) ? `fetchUnitBySlug(propertyId, slug)` ? unit

**Klju�ni fajlovi**:
- `subdomain_service.dart` ? `resolveFullContext(urlSlug)`
- `subdomain_provider.dart` ? `fullSlugContextProvider(slug)`
- `router_widget.dart` ? `/:slug` route

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

## 🔥 FIRESTORE INDEXI

### Composite vs Single-Field Indexi
- **Single-field indexi** = Firestore automatski kreira za SVA polja (equality, whereIn, orderBy)
- **Composite indexi** = MORAJU biti eksplicitno definirani u `firestore.indexes.json`

### Kada Treba Composite Index:
```dart
// ✅ NE treba composite (single field equality)
.where('subdomain', isEqualTo: subdomain)

// ✅ NE treba composite (range na ISTOM polju)
.where('date', isGreaterThanOrEqualTo: start)
.where('date', isLessThanOrEqualTo: end)

// ❌ TREBA composite (equality + range na RAZLIČITIM poljima)
.where('unit_id', isEqualTo: unitId)
.where('start_date', isLessThanOrEqualTo: endDate)
```

### Collection vs Collection Group
- **Collection index** = query na subcollection (`collection('properties/{id}/units')`)
- **Collection group index** = query preko SVIH subcollections (`collectionGroup('bookings')`)
- ⚠️ **Collection group index NE pokriva collection query i obrnuto!**

### Widget Potrebni Indexi (svi postoje):
| Collection | Fields | Scope |
|------------|--------|-------|
| `bookings` | `unit_id` + `status` | Collection Group |
| `daily_prices` | `unit_id` + `date` | Collection Group |
| `daily_prices` | `unit_id` + `available` | Collection Group |
| `ical_events` | `unit_id` + `start_date` | Collection Group |
| `ical_events` | `unit_id` + `start_date` | Collection |

### Deploy Indexa:
```bash
firebase deploy --only firestore:indexes
```

---

## 🎨 UI/UX STANDARDI

**Filozofija**: Less colorful, more professional - neutralne pozadine sa jednom accent bojom na ikonama.

**Dialogs**:
- Footer: `AppColors.dialogFooterDark/Light`, border: `AppColors.sectionDividerDark/Light`
- Padding: 12px mobile (<400px), 16-20px desktop
- Border radius: 11-12px

**Cards/Tiles**:
- Ikone: jedna boja (primary) sa 10-12% opacity pozadinom
- Shadows: `AppShadows.elevation1` za ve�inu, `elevation2` za istaknute
- Border radius: 12px standard

**Skeleton loaders**: `SkeletonColors.baseColor/highlightColor` iz `skeleton_loader.dart`

**Snackbars (Widget)**: `SnackBarHelper` u `shared/utils/ui/snackbar_helper.dart`
- Boje prate calendar status: Success=Available(zelena), Error=Booked(crvena), Warning=Pending(amber), Info=plava
- Light: `#10B981`, `#EF4444`, `#F59E0B`, `#3B82F6`
- Dark: `#34D399`, `#F87171`, `#FBBF24`, `#60A5FA`
- Auto-hide prethodnog, centrirani tekst, sve poruke koriste `WidgetTranslations`

---

**Last Updated**: 2025-12-15 | **Version**: 5.1

**Changelog 5.1**: Dodana Firestore indexi sekcija, browser_detection conditional imports, upozorenje o dart:js_interop.

**Changelog 5.0**: Firestore collection group query bug fix - NE koristiti FieldPath.documentId sa collectionGroup(), dodano sessionId u cross-tab messaging.

**Changelog 4.9**: Android Chrome keyboard dismiss fix (Flutter #175074) - JavaScript "jiggle" method + Dart mixin za sve forme.

**Changelog 4.8**: Widget snackbar boje usklađene sa calendar statusima.

**Changelog 4.7**: Multi-platform build dokumentacija - Android release mode, conditional imports, dependency verzije.

**Changelog 4.6**: URL slug sistem za clean URLs (`/apartman-6` umjesto query params).
