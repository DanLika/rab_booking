# Claude Code - Project Documentation

**BookBed** - Booking management platforma za property owner-e.

**Dodatni dokumenti:**
- [CLAUDE_BUGS_ARCHIVE.md](./docs/bugs-archive/CLAUDE_BUGS_ARCHIVE.md) - Detaljni bug fix-evi sa code examples
- [CLAUDE_WIDGET_SYSTEM.md](./docs/cloud-widget-systems/CLAUDE_WIDGET_SYSTEM.md) - Widget modovi, payment logic, pricing
- [CLAUDE_MCP_TOOLS.md](./docs/cloud-mcp-tools/CLAUDE_MCP_TOOLS.md) - MCP serveri, slash commands
- [EMAIL_SYSTEM.md](./docs/features/email-templates/EMAIL_SYSTEM.md) - Email template-i, payment rok, reminders

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

**Booking Lookup** - `utils/bookingLookup.ts`:
```typescript
// ⚠️ NIKADA ne koristi FieldPath.documentId() sa collectionGroup()!
// Umjesto toga koristi helper funkcije:
import {findBookingById, findBookingByReference} from "./utils/bookingLookup";

// Primjer
const result = await findBookingById(bookingId, ownerId); // ownerId je optional
if (result) {
  const {doc, data, propertyId, unitId} = result;
}
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

## 🌐 HOSTING & DOMENE

**Domena**: `bookbed.io` (Porkbun) → DNS na Cloudflare

**⚠️ KRITIČNO - Domena struktura**:
| Domena | Svrha | Firebase Site |
|--------|-------|---------------|
| `bookbed.io` | **Marketing/Landing page** (NE widget!) | - (buduće) |
| `app.bookbed.io` | Owner Dashboard | `bookbed-owner` |
| `view.bookbed.io` | **Booking Widget** (embed iframe) | `bookbed-widget` |
| `*.view.bookbed.io` | Klijent subdomene za widget | `bookbed-widget` |

**Firebase Hosting targets** (`.firebaserc`):
| Target | Site ID | Build folder | Custom domain |
|--------|---------|--------------|---------------|
| `owner` | `bookbed-owner` | `build/web_owner` | app.bookbed.io |
| `widget` | `bookbed-widget` | `build/web_widget` | view.bookbed.io, *.view.bookbed.io |

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
- `jasko-rab.view.bookbed.io` → widget za Jasmina
- Format: `{subdomain}.view.bookbed.io`

**⚠️ NE MIJEŠATI**: `bookbed.io` je REZERVISAN za marketing sajt. Widget UVIJEK ide na `view.bookbed.io`!

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
      resizeToAvoidBottomInset: true, // NAMJERNO true - mixin radi ZAJEDNO sa Flutter native ponašanjem
      // ...
    ),
  );
}
```

**3. Meta tag u `web/index.html`**:
```html
<meta name="viewport" content="width=device-width, initial-scale=1.0, interactive-widget=resizes-content">
```

**NAPOMENA o `resizeToAvoidBottomInset: true`**: Koristimo `true` (ne `false`) jer mixin NE zamjenjuje Flutter-ovo native ponašanje, već ga DOPUNJUJE. Mixin detektuje kada keyboard dismiss nije pravilno obrađen i forsira rebuild. Flutter-ov `resizeToAvoidBottomInset: true` i dalje radi normalno za većinu slučajeva.

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
3. Postavi `resizeToAvoidBottomInset: true` na Scaffold (NAMJERNO true - mixin radi zajedno sa Flutter native ponašanjem)

---

## 🔗 SUBDOMAIN & URL SLUG SYSTEM

**URL formati** (widget na `view.bookbed.io`):
| Format | Primjer | Korištenje |
|--------|---------|------------|
| Query params | `jasko-rab.view.bookbed.io/?property=XXX&unit=YYY` | iframe embed |
| Clean slug | `jasko-rab.view.bookbed.io/apartman-6` | standalone, dijeljenje |

**Rezolucija slug URL-a**:
1. Subdomain (`jasko-rab`) → `fetchPropertyBySubdomain()` → property
2. Path slug (`apartman-6`) → `fetchUnitBySlug(propertyId, slug)` → unit

**Ključni fajlovi**:
- `subdomain_service.dart` → `resolveFullContext(urlSlug)`
- `subdomain_provider.dart` → `fullSlugContextProvider(slug)`
- `router_widget.dart` → `/:slug` route

**Slug stabilnost**: Slug se NE regenerira automatski kad se promijeni naziv unita (`_isManualSlugEdit` flag u `unit_form_screen.dart`).

**Booking view URL**: `villa-marija.view.bookbed.io/view?ref=XXX&email=YYY`

**⚠️ VAŽNO**: Svi widget URL-ovi koriste `view.bookbed.io` domenu, NE `bookbed.io`!

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
| `bookings` | `unit_id` + `check_in` | Collection Group |
| `daily_prices` | `unit_id` + `date` | Collection Group |
| `daily_prices` | `unit_id` + `available` | Collection Group |
| `ical_events` | `unit_id` + `start_date` | Collection Group |
| `ical_events` | `unit_id` + `start_date` | Collection |

### Analytics Security Rules
Analytics koristi `collectionGroup('bookings')` sa `whereIn` na `unit_id` i range filter na `check_in`.
Firestore security rules MORAJU dozvoliti authenticated korisnicima pristup po ovim poljima:
```
// firestore.rules - Case 2 u bookings collection group
(isAuthenticated() && 'unit_id' in resource.data && 'check_in' in resource.data)
```
Bez ove rule, analytics query vraća `permission-denied` error.

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

## 📱 PWA (Progressive Web App)

**Konfiguracija**: `web/manifest.json`, `web/index.html` (linije 306-372)

**Widgeti**:
| Widget | Fajl | Svrha |
|--------|------|-------|
| `PwaInstallButton` | `widgets/pwa/pwa_install_button.dart` | Custom install dugme (prikazuje se samo kad je dostupno) |
| `ConnectivityBanner` | `widgets/pwa/connectivity_banner.dart` | Offline/online status banner |

**Dart API** (`core/utils/web_utils.dart`):
```dart
canInstallPwa()      // true ako je install prompt dostupan
isPwaInstalled()     // true ako je PWA već instalirana
promptPwaInstall()   // async - pokreće install prompt
listenToPwaInstallability(callback)  // listener za promjene
```

**JavaScript API** (`web/index.html`):
```javascript
window.pwaCanInstall    // bool
window.pwaIsInstalled   // bool
window.pwaPromptInstall()  // async function
// Eventi: 'pwa-installable', 'pwa-installed'
```

**TODO**: Web Push Notifications (Safari iOS 16.4+ only, zahtijeva VAPID ključeve)

---

**Last Updated**: 2025-12-17 | **Version**: 6.2

**Changelog 6.2**: Widget UI Polish & Form Component Alignment:
- **Form component heights ujednačene na 50px**:
  - Verify button: 49px → 50px
  - Verified badge: 51px → 50px
  - Country dropdown: 50px (već bilo OK)
  - TextFormField: ~50px (contentPadding 14px vertical)
- **Skraćeni tekstovi za bolji UX**:
  - "Verify Email" → "Verify" (svi jezici)
  - "Credit Card (Stripe)" → "Credit Card"
  - "Continue to Bank Transfer" → "Bank Transfer"
  - Calendar-only banner: uklonjena druga rečenica o kontaktiranju vlasnika
- **Padding/spacing poboljšanja**:
  - Booking pill bar: dodano 8px horizontalnog paddinga na mobile
  - Month calendar mobile: padding smanjen sa 16px na 8px (left/right)
  - Header content centriran sa jednakim left/right paddingom
  - Info banner: 8px top padding, Contact pill bar: 8px bottom padding (calendar-only mode)
- **Header ikone**: responsive sizing za tiny screens (<360px) - ikone 18px umjesto 20px
- **Contact pill bar**: uklonjen text underline iz kontakt linka

**Changelog 6.1**: Cloud Functions FieldPath.documentId Bug Fix:
- **CRITICAL BUG FIX**: `FieldPath.documentId()` NE RADI sa `collectionGroup()` queries
  - Error: `When querying a collection group and ordering by FieldPath.documentId(), the corresponding value must result in a valid document path`
  - Firestore očekuje PUNI PUT dokumenta (npr. `properties/xxx/units/yyy/bookings/zzz`), ne samo ID (`zzz`)
- **Nova helper funkcija**: `functions/src/utils/bookingLookup.ts`
  - `findBookingById(bookingId, ownerId?)` - tri strategije:
    1. Query po `owner_id` polju (brzo ako je owner poznat)
    2. Comprehensive search kroz sve properties/units (sporije ali uvijek radi)
    3. Fallback na legacy `bookings` collection
  - `findBookingByReference(bookingReference)` - query po `booking_reference` polju
- **Popravljene Cloud Functions**:
  - `resendBookingEmail.ts` - koristi `findBookingById`
  - `customEmail.ts` - koristi `findBookingById`
  - `guestCancelBooking.ts` - koristi `findBookingById`
  - `twoWaySync.ts` - koristi `findBookingById`
  - `updateBookingTokenExpiration.ts` - koristi `findBookingById`
- **Dodan Firestore index**: `owner_id` single-field index za `bookings` collection group
- **PRAVILO**: Nikada ne koristi `FieldPath.documentId()` sa `collectionGroup()` - uvijek query po custom polju

**Changelog 6.0**: Widget Hybrid Loading & Native Splash Update:
- **Hybrid Progressive Loading**: Widget UI prikazuje se ODMAH sa skeleton kalendarom
  - Uklonjeno: BookBed Loader iz `booking_widget_screen.dart`
  - `LazyCalendarContainer` prikazuje skeleton dok se podaci učitavaju
  - `hideNativeSplash()` poziva se u `widget_main.dart` initState
  - Loading vrijeme smanjeno sa ~10-14s na ~4s
- **Native Splash minimalistički dizajn**: Crno-bijela shema umjesto ljubičaste
  - Light mode: `#000000` progress bar, `rgba(0,0,0,0.2)` track
  - Dark mode: `#FFFFFF` progress bar, `rgba(255,255,255,0.2)` track
  - Usklađeno sa BookBed Loader bojama
- **Obrisani fajlovi** (više se ne koriste):
  - `loading_screen.dart`, `smart_loading_screen.dart`, `smart_progress_controller.dart`
  - `loading_screen_test.dart`
- **InteractiveViewer (zoom) testiran i UKLONJEN**:
  - Zoom na kalendaru (1x-2x) testirano ali odlučeno da nije potrebno
  - Responsive dizajn + OS-level zoom već zadovoljavaju accessibility potrebe

**Changelog 5.9**: Booking Dialog Race Condition Fix:
- **Problem**: Booking details dialog otvarao se 2-3 puta kada korisnik navigira sa notifications page na bookings page
- **Uzrok**: Async race condition između `setState()`, `router.go()` i `addPostFrameCallback()`
- **Fix** (`owner_bookings_screen.dart`):
  1. Uklonjen `!_isLoadingInitialBooking` check koji je blokirao dialog opening
  2. URL query params čiste se PRIJE resetovanja state flags-a (ne poslije)
  3. Dodani `!_dialogShownForBooking` checks na SVE putanje koje setuju `_pendingBookingToShow`
  4. `_pendingBookingToShow = null` postavlja se odmah nakon što se `_dialogShownForBooking = true` setuje
  5. Dodatni guard za `pendingBookingIdProvider` setting iz URL-a
- **Ključni princip**: Redoslijed cleanup-a je kritičan - URL mora biti očišćen PRIJE nego što se resetuju flags-ovi

**Changelog 5.8**: Analytics Security Rules Fix:
- **Problem**: Analytics page vraćala `permission-denied` error za `collectionGroup('bookings')` query
- **Uzrok**: Firestore security rules nisu dozvoljavale authenticated korisnicima query po `unit_id` + `check_in`
- **Fix**: Dodana nova rule u `firestore.rules` za analytics queries (Case 2)
- Dodano `print()` logging u analytics provider/repository za debug u release mode
- Index `bookings: unit_id + check_in` (Collection Group) već postojao - problem bio samo u rules

**Changelog 5.7**: Bug Fixes & Error Boundaries:
- ErrorBoundary wrapperi dodani na Loader widgete u `router_owner.dart` (PropertyEditLoader, UnitEditLoader, UnitPricingLoader, WidgetSettingsLoader)
- Warning dialogs integrirani: `UpdateBookingWarningDialog` u edit_booking_dialog, `UnblockWarningDialog` u price_list_calendar
- Timezone fix: `DateNormalizer.normalize()` u validateAdvanceBooking umjesto lokalnog DateTime
- Language fallback: `🌐` globe emoji za nepoznate jezike umjesto hardcoded `🇭🇷`
- Skeleton loader: named constants umjesto magic numbers u month_calendar_skeleton
- Async timeouts utility već postoji (`async_utils.dart`, `timeout_constants.dart`) - dokumentirano

**Changelog 5.6**: PWA install button i connectivity banner widgeti, JS/Dart interop za PWA install prompt.

**Changelog 5.5**: Email System Reorganization:
- Payment deadline: 3 dana → **7 dana** (atomicBooking.ts:870)
- Check-in reminder: 1 dan → **7 dana** prije
- Payment reminder: **Dan 6** (1 dan prije isteka)
- Uklonjeni `-v2` suffix iz template imena
- Premješteni template-i iz `version-2/` u `templates/`
- Uklonjen `suspicious-activity.ts` (TODO za budućnost)
- Nova dokumentacija: `EMAIL_SYSTEM.md`

**Changelog 5.4**: Stripe Security Improvements implementirane:
- Rate limiting na `createStripeCheckoutSession` (10 req/5min per IP)
- Stripe Connect account verification (`charges_enabled`, `card_payments`, `transfers`)
- Security monitoring (`securityMonitoring.ts`) - logira kritične security evente
- Firestore rules za bookings: selektivni pristup (owner, widget calendar, Stripe polling, booking view)
- Error message cleanup - generičke poruke za klijente, detalji samo u logovima

**Changelog 5.3**: Owner email UVIJEK se šalje za svaki booking (Bug Archive #2) - `forceIfCritical=true` u atomicBooking.ts. Dok nema push notifications, owner ne smije propustiti rezervaciju.

**Changelog 5.2**: Keyboard fix threshold usklađivanje (JS/Dart 12%/15%), window.resize fallback, EPC QR validacija sa currency parametrom.

**Changelog 5.1**: Dodana Firestore indexi sekcija, browser_detection conditional imports, upozorenje o dart:js_interop.

**Changelog 5.0**: Firestore collection group query bug fix - NE koristiti FieldPath.documentId sa collectionGroup(), dodano sessionId u cross-tab messaging.

**Changelog 4.9**: Android Chrome keyboard dismiss fix (Flutter #175074) - JavaScript "jiggle" method + Dart mixin za sve forme.

**Changelog 4.8**: Widget snackbar boje usklađene sa calendar statusima.

**Changelog 4.7**: Multi-platform build dokumentacija - Android release mode, conditional imports, dependency verzije.

**Changelog 4.6**: URL slug sistem za clean URLs (`/apartman-6` umjesto query params).
