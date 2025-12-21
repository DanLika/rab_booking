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

**Sentry Error Tracking** - `sentry.ts`:
```typescript
import {captureException, captureMessage, setUser} from "./sentry";

// User context - UVIJEK na početku callable funkcija:
setUser(request.auth.uid);              // Za authenticated usera
setUser(null, guestEmail);              // Za guest akcije (email verification, booking view)

// Error capture - NE KORISTITI DIREKTNO u većini slučajeva
// logError() iz logger.ts automatski šalje na Sentry
// Koristi captureMessage samo za security events:
captureMessage("Security: Price mismatch detected", "error", {unitId, clientPrice, serverPrice});
```

---

## =? STRIPE FLOW (LIVE MODE ✅)

**⚠️ KRITIČNO - PRODUKCIJA**: Stripe je u LIVE MODE. Ne mijenjaj bez testiranja!

**Ključni fajlovi - NE DIRATI bez razloga:**
| Fajl | Svrha |
|------|-------|
| `stripePayment.ts` | Checkout session kreiranje, minimum €0.50 validacija |
| `stripeConnect.ts` | Owner Stripe Connect onboarding |
| `handleStripeWebhook` | Webhook handler za `checkout.session.completed/expired` |

**Firebase Secrets (LIVE ključevi):**
- `STRIPE_SECRET_KEY` - Live secret key
- `STRIPE_WEBHOOK_SECRET` - Live webhook signing secret

**Stripe Connect Model:** Standard (Direct charges)
- Owner ima nezavisan Stripe račun
- Novac ide DIREKTNO owner-u
- Platforma trenutno NE uzima fee (application_fee_amount = 0)
- Owner je merchant of record (odgovoran za porez)

**Minimum iznos:** €0.50 (Stripe zahtjev) - validacija u `stripePayment.ts`

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

**Animation Widgets** (`lib/shared/widgets/animations/`):
```dart
import 'package:bookbed/shared/widgets/animations/animations.dart';

// Empty states - fade+scale entrance
AnimatedEmptyState(icon: Icons.inbox, title: 'No items', subtitle: 'Add your first item')

// Loading transitions - skeleton→content crossfade
AnimatedContentSwitcher(
  showContent: !isLoading,
  skeleton: MySkeleton(),
  content: MyContent(),
)

// Success feedback - animated checkmark with draw animation
AnimatedCheckmark(size: 64, color: Colors.green)

// Desktop hover effects
HoverScaleCard(child: MyCard(), onTap: () => {})
HoverListTile(title: Text('Item'), onTap: () => {})

// Staggered list entrances
AnimatedCardEntrance(delay: Duration(milliseconds: index * 100), child: MyCard())
```

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

**Last Updated**: 2025-12-21 | **Version**: 6.18

**Changelog 6.18**: Dashboard Rolling Window Periods & Chart Improvements:
- **Period Calculations Changed to Rolling Windows**:
  - **Problem**: Period računanja bila kalendarska (1. dec - 21. dec), što daje nekonzistentne rezultate
    - "Prošlo tromjesečje" pokazivalo MANJE podataka nego "Ovaj mjesec" (nelogično)
    - Periodi nisu bili dinamički - morali se ručno mijenjati svaki dan
  - **Fix**: Rolling windows sa `today minus X dana` logikom
    - `last7Days()`: zadnjih 7 dana (bilo: prošli tjedan)
    - `last30Days()`: zadnjih 30 dana (bilo: kalendarski mjesec)
    - `last90Days()`: zadnjih 90 dana (bilo: kalendarski tromjesečje)
    - `last365Days()`: zadnjih 365 dana (bilo: kalendarskih 12 mjeseci)
  - **Rezultat**: Period sa više dana UVIJEK ima više/jednako podataka
- **Default Period**: Promijenjen sa `currentMonth()` na `last7Days()`
- **Choice Chip Labele Ažurirane**:
  - "Prošli tjedan" → "Zadnjih 7 dana" / "Last 7 days"
  - "Ovaj mjesec" → "Zadnjih 30 dana" / "Last 30 days"
  - "Prošlo tromjesečje" → "Zadnjih 90 dana" / "Last 90 days"
  - "Prošla godina" → "Zadnjih 365 dana" / "Last 365 days"
- **Chart Interakcije Pojednostavljene**:
  - Uklonjen zoom (scroll to zoom) - `horizontalRangeUpdater` removed iz `RectCoord`
  - Dodane vrijednosti na chartovima:
    - Revenue chart: €XXX prikazano iznad svake tačke
    - Bookings chart: broj rezervacija prikazano iznad svakog bara
  - Zadržani hover tooltips za detalje
- **Modified Files**:
  - `unified_dashboard_data.dart`: novi factory methods za rolling windows
  - `unified_dashboard_provider.dart`: `setPreset()` ažuriran za nove periode
  - `dashboard_overview_tab.dart`: chart labels sa vrijednostima, uklonjeni zoom eventi
  - `app_en.arb`, `app_hr.arb`: nove lokalizacije za choice chips

**Changelog 6.17**: Calendar Provider Cache Security Fix & Remember Me Feature:
- **CRITICAL SECURITY FIX - Calendar showing other owner's units**:
  - **Problem**: Owner A logs out, Owner B logs in → sees Owner A's units in Calendar Timeline
  - **Root Cause**: `keepAlive: true` providers cached previous user's data
    - `ownerPropertiesCalendarProvider` and `allOwnerUnitsProvider` used `FirebaseAuth.instance.currentUser`
    - Provider never invalidated on user change because `keepAlive: true` prevents disposal
  - **Fix** (`owner_calendar_provider.dart:20-24`):
    - Changed from `FirebaseAuth.instance.currentUser?.uid` to `ref.watch(enhancedAuthProvider)`
    - Now watches auth state changes → auto-invalidates on login/logout
    - New user gets fresh data, not cached data from previous user
  - **Key Learning**: `keepAlive: true` providers MUST watch auth state if they depend on current user
- **Remember Me / Auto-fill Feature** (AUTH_LOADING_STATES_PLAN.md):
  - Added `flutter_secure_storage: ^9.0.0` dependency
  - New `SecureStorageService` singleton (`lib/core/services/secure_storage_service.dart`)
  - New `SavedCredentials` freezed model (`lib/features/auth/models/saved_credentials.dart`)
  - Login screen auto-fills credentials if "Remember Me" was enabled
  - Credentials saved on successful login (if Remember Me checked)
  - Credentials cleared on logout
  - Platform-specific encryption: Android EncryptedSharedPreferences, iOS Keychain
- **Improved Auth Error Messages**:
  - New localization keys: `authErrorWrongPassword`, `authErrorUserNotFound`, `authErrorInvalidEmail`, etc.
  - Croatian and English translations
  - Generic fallback: `authErrorGeneric` for unmapped errors

**Changelog 6.16**: Stripe Live Payment Tested & Payment Method Display:
- **Stripe Live Payment Successfully Tested**:
  - First live transaction: €0.60 deposit payment
  - Webhook correctly updated booking status to `confirmed`
  - Email confirmation sent to guest
  - Stripe Connect Standard model working: money goes directly to owner
- **Payment Method Display in Booking Details** (`booking_details_dialog.dart`):
  - Added "Payment Method" row: Stripe, Bank Transfer, Cash, Other, Not specified
  - Added "Payment Option" row: Deposit, Full Payment
  - New localization strings in `app_en.arb`, `app_hr.arb`
  - Owners can now see how guests attempted to pay
- **Stripe Minimum Amount Fix** (`stripePayment.ts`):
  - Stripe requires minimum €0.50 for Checkout Sessions
  - Added validation: `Math.max(rawDepositCents, 50)`
  - Small deposits auto-adjusted to €0.50 minimum
- **iCal Import Testing**:
  - Created test iCal files for Booking.com and Airbnb formats
  - Overbooking detection confirmed working (33 conflicts displayed)
- **Timeline Calendar Position Fix**:
  - Fixed UTC vs LOCAL timezone mismatch in booking position calculation
  - `timeline_grid_widget.dart`, `timeline_booking_block.dart` now use `DateTime.utc()`
- **Booking Move Feature Fix** (`firebase_booking_repository.dart`):
  - Fixed `updateBooking()` to handle unit changes with atomic Firestore batch
  - Delete from old path + create at new path in single transaction

**Changelog 6.15**: Stripe Live Mode Setup & Mobile URL Fix:
- **Stripe Live Mode Activated**:
  - Firebase secrets updated: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` (Live keys)
  - Webhook endpoint: `https://us-central1-rab-booking-248fc.cloudfunctions.net/handleStripeWebhook`
  - Events: `checkout.session.completed`, `checkout.session.expired`
  - Platform profile completed in Stripe Dashboard
- **Mobile App URL Fix** (`stripe_connect_setup_screen.dart`):
  - **Problem**: `Uri.base` returns empty string on native Android/iOS apps
  - **Error**: "Not a valid URL" when connecting Stripe account from mobile app
  - **Fix**: Added fallback to `https://app.bookbed.io` for Stripe Connect return/refresh URLs
  - Mobile apps now correctly redirect back to owner dashboard after Stripe onboarding

**Changelog 6.14**: Smart Price Mismatch Alerting - completed above

**Changelog 6.13**: Widget Embed Code & Month Display Fix:
- **Iframe Embed Code Improvement**:
  - Embed kod sada koristi `view.bookbed.io` domenu (ne `bookbed.io`)
  - Direktan iframe umjesto script-based embed.js
  - Responsive visina sa `aspect-ratio: 1/1.4; min-height: 500px; max-height: 850px;`
  - Owner samo kopira i zalijepi - radi na bilo kojem sajtu
  - Fajlovi: `embed_code_generator_dialog.dart`, `embed_widget_guide_screen.dart`
- **Month/Year Display Always Visible**:
  - **Problem**: U embedded widgetu, mjesec/godina ("Dec 2025") se nije prikazivalo na uskim iframe-ovima
  - **Uzrok**: `isTinyScreen < 360px` check sakrivao tekst, ali iframe može biti uži od device-a
  - **Fix** (`month_calendar_widget.dart:217-230`):
    - Mjesec/godina se UVIJEK prikazuje (uklonjen `if (!isTinyScreen)` check)
    - Na malim ekranima koristi manji font (`fontSizeXS`) umjesto skrivanja
    - Korisnik uvijek zna koji mjesec gleda

**Changelog 6.12**: Timeline Calendar Scroll Fixes & Turnover Visibility:
- **Scroll Bounce-Back Fix** (Android weak swipe issue):
  - **Problem**: Weak swipes on Timeline Calendar would bounce back instead of scrolling
  - **Root Cause**: `ClampingScrollPhysics.createBallisticSimulation()` returns `null` for low-velocity gestures
  - **Fix**: New `TimelineSnapScrollPhysics` class (`timeline_snap_scroll_physics.dart`):
    - Custom `createBallisticSimulation()` that ALWAYS returns a snap simulation
    - Critically damped spring (no oscillation) for smooth stop at day boundary
    - Low `minFlingVelocity` (10.0) to capture weak Android swipes
- **Feedback Loop Fix** (auto-scroll backwards/forwards):
  - **Problem**: Calendar auto-scrolled continuously after user swipe
  - **Root Cause**: `_updateVisibleRange` → parent updates → `didUpdateWidget` → scroll → loop
  - **Fix** (`timeline_calendar_widget.dart`):
    - Report CENTER of visible range instead of START (prevents position drift)
    - `didUpdateWidget` only scrolls when `forceScrollKey` changes (explicit user action)
    - Increased skip threshold from `visibleWidth/4` to `visibleWidth/2`
- **Toolbar Navigation Fix**:
  - Previous/Next/DatePicker buttons now increment `forceScrollKey++`
  - Required after feedback loop fix to trigger scroll in `didUpdateWidget`
- **Turnover Day Visibility** (`skewed_booking_painter.dart`):
  - Increased `turnoverGap` from 2px to 4px
  - Added 50% opacity diagonal separator lines on check-in/check-out edges
  - Turnover days now clearly visible in Timeline Calendar

**Changelog 6.11**: Flutter Animation Widget Library:
- **New animation widgets** (`lib/shared/widgets/animations/`):
  - `AnimatedEmptyState`: Fade+scale entrance for empty state screens
  - `AnimatedContentSwitcher`: Smooth skeleton→content crossfade transitions
  - `AnimatedCheckmark`: Custom painted checkmark with draw animation
  - `SuccessOverlay`: Full-screen success celebration overlay
  - `HoverScaleCard`, `HoverListTile`: Desktop hover effects with scale+shadow
  - `AnimatedCardEntrance`: Staggered fade+slide entrance for lists
  - `AnimatedDialog`: Scale/slide-up dialog entrance helpers
  - `AnimatedButton`: Press feedback micro-interactions
- **Applied animations**:
  - `owner_bookings_screen.dart`: AnimatedEmptyState for no bookings
  - `notifications_screen.dart`: Staggered empty state with 3 animation controllers
  - `unified_unit_hub_screen.dart`: AnimatedEmptyState for no units
  - `dashboard_overview_tab.dart`: AnimatedEmptyState for chart empty states
  - `lazy_calendar_container.dart`: AnimatedContentSwitcher for skeleton→calendar fade
- **Removed unused packages**: `lottie: ^3.1.0`, `confetti: ^0.8.0` from pubspec.yaml
- **Implementation plan**: `docs/research/ANIMATION_IMPLEMENTATION_PLAN.md`

**Changelog 6.10**: iCal Export Permission-Denied Bug Fix + Missing Index:
- **iCal Export Bug**:
  - **Problem**: iCal export failed with `permission-denied` error when generating .ics files
  - **Root Cause**: `fetchUnitBookings()` query used only `unit_id` filter, but Firestore security rules (Case 3) require `unit_id` + `status` for collection group queries
  - **Fix** (`firebase_booking_repository.dart:13-35`):
    - Added `status` whereIn filter to `fetchUnitBookings()` query
    - Now fetches only `pending`, `confirmed`, `completed` bookings (excludes `cancelled`)
    - Matches security rule Case 3: `('unit_id' in resource.data && 'status' in resource.data)`
  - **Cleanup** (`ical_export_service.dart`):
    - Removed redundant client-side status filtering (now done at query level)
    - Removed unused `enums.dart` import
- **Missing Firestore Index**:
  - **Problem**: `syncReminders.ts` Cloud Function failed with `FAILED_PRECONDITION: The query requires an index`
  - **Query**: `.where("created_at", ">=", ...).where("status", "in", [...])`
  - **Fix**: Added composite index `status` ASC + `created_at` ASC to `firestore.indexes.json` (lines 154-160)
  - **Note**: When combining range (`>=`) and equality/whereIn filters, equality fields must come FIRST in the index

**Changelog 6.9**: Platform Source Display for External Bookings:
- **PlatformIcon Widget** (`lib/shared/widgets/platform_icon.dart`):
  - Reusable widget za prikaz platforme bookinga
  - Ikone: **B** (plava #003580) = Booking.com, **A** (crvena #FF5A5F) = Airbnb, **W** (ljubičasta #7C3AED) = Direct, **🔗** (narandžasta) = iCal/External
  - Static helpers: `getDisplayName(source)`, `shouldShowIcon(source)`
- **Timeline Booking Blocks** (`timeline_booking_block.dart`):
  - Platform ikona u gornjem desnom uglu za external bookinge
  - Automatski offset (28px) ako postoji conflict warning ikona
- **Booking Details Dialog** (`booking_details_dialog.dart`):
  - Dodano "Izvor/Source" polje u Guest Information sekciju
  - Prikazuje se samo za `isExternalBooking` bookinge
  - Nova `_DetailRowWithWidget` klasa za custom child widgets
- **Conflict Messages**:
  - Snackbar u `owner_timeline_calendar_screen.dart` sada prikazuje platformu: "Guest (Booking.com)"
  - `_ConflictWarningBanner` u tooltipima već prikazuje platformu za svaki konflikt
- **Lokalizacija**: `ownerDetailsSource` - "Source" (EN) / "Izvor" (HR)

**Changelog 6.8**: Comprehensive Sentry Integration:
- **Flutter LoggingService** (`logging_service.dart`):
  - `logError()` sada šalje na Sentry via `captureException()` (fire-and-forget, non-blocking)
  - Novi `logNavigation()` method za breadcrumbs
  - `setUser()` za user identification (owner uid + email)
  - `clearUser()` poziva se na logout
- **Flutter NavigatorObserver** (`sentry_navigator_observer.dart`):
  - Automatski logira sve navigacije kao Sentry breadcrumbs
  - Dodano u `router_owner.dart` i `router_widget.dart`
  - Prati: push, pop, replace, remove akcije
- **Cloud Functions logger.ts**:
  - `logError()` automatski šalje na Sentry via `captureException()`
  - Svi errori sada imaju user context ako je `setUser()` pozvan
- **Cloud Functions setUser()** dodano na 17 funkcija:
  - `atomicBooking.ts`, `stripePayment.ts`, `stripeConnect.ts`
  - `icalSync.ts`, `guestCancelBooking.ts`, `verifyBookingAccess.ts`
  - `customEmail.ts`, `resendBookingEmail.ts`, `updateBookingTokenExpiration.ts`
  - `subdomainService.ts`, `emailVerification.ts` (sve 3 funkcije)
  - `airbnbApi.ts`, `bookingComApi.ts`, `passwordHistory.ts` (2 funkcije)
  - `passwordReset.ts`, `revokeTokens.ts`
- Guest/unauthenticated actions koriste: `setUser(null, email)` pattern
- **SKIP**: `authRateLimit.ts` - poziva se PRIJE autentikacije (nema user ID)

**Changelog 6.7**: Clipboard API Error Handling:
- **Problem**: Clipboard.setData() može baciti exception na nekim browserima (Safari u iframe-u)
- **Fix**: Dodano try-catch na sve Clipboard operacije u widget fajlovima:
  - `popup_blocked_dialog.dart`: Pokazuje error snackbar ako kopiranje ne uspije
  - `booking_reference_card.dart`: Tihi fail (referenca je vidljiva na ekranu)
  - `bank_transfer_instructions_card.dart`: Tihi fail (podaci su vidljivi na ekranu)
- **Pattern za buduće Clipboard operacije**:
  ```dart
  try {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      // Show success
    }
  } catch (e) {
    // Clipboard API can fail on some browsers (e.g., Safari in iframe)
    // Handle gracefully
  }
  ```

**Changelog 6.14**: Smart Price Mismatch Alerting (False Positive Fix):
- **Problem**: Sentry dobivao HIGH severity alert za SVAKI price mismatch, čak i za benigne scenarije:
  - Cached prices na klijentu (€2-5 razlika je normalna)
  - Floating-point rounding (< €0.10 je bezopasno)
  - Owner promijenio cijenu dok je korisnik bio na stranici
- **Rješenje**: Smart threshold u `priceValidation.ts` (line 287-325):
  - Sentry alert SAMO za sumnjive mismatche: `difference > €10` ILI `percentageDifference > 5%`
  - Male razlike (€0.01-10) se loguju u Cloud Logs, ali NE šalju na Sentry
  - Booking i dalje USPIJEVA sa server-calculated cijenom u oba slučaja
- **Stripe Fee clarification**:
  - Stripe fee (1.4% + €0.25) se **SKIDA SA OWNER-A**, ne dodaje se na cijenu
  - Korisnik plaća: `totalPrice = roomPrice + servicesTotal`
  - Owner dobija: `totalPrice - stripeFee` (npr. 170€ → 167.73€)
  - `servicesTotal` parametar se UVIJEK šalje sa klijenta na server za validaciju

**Changelog 6.6**: Security Helper Integration - All Helpers Now Active:
- **logRateLimitExceeded() integration**:
  - `authRateLimit.ts`: Login and registration rate limit events (severity: medium)
  - `atomicBooking.ts`: Widget booking rate limit events
  - `bookingAccessToken.ts`: Token verification rate limit events
  - All rate limit blocks now logged to Firestore + Cloud Logging
- **logPriceMismatch() integration**:
  - `priceValidation.ts`: Price manipulation detection (severity: high → Sentry alert)
  - Logs: unitId, clientPrice, serverPrice, difference, propertyId, dates
- **Security monitoring coverage complete**:
  - All helper functions from `securityMonitoring.ts` now actively used
  - Events flow: Firestore `security_events` + Cloud Logging + Sentry (critical/high)

**Changelog 6.5**: Cloud Functions Performance & Security Monitoring:
- **bookingLookup.ts Strategy 2 optimization**:
  - Problem: O(N×M) sequential queries (~5s for 100 properties × 10 units)
  - Solution: Parallel queries using `Promise.all()` (~500ms for same data)
  - Step 1: Fetch all units for all properties in parallel
  - Step 2: Build list of all booking paths to check
  - Step 3: Check all booking paths in parallel
  - Performance improvement: ~10x faster for comprehensive search fallback
- **Sentry integration for security monitoring**:
  - Critical events (`severity: "critical"`) now sent to Sentry as `fatal` level
  - High severity events (`severity: "high"`) sent as `error` level
  - Enables real-time alerting via Sentry dashboard/email for security incidents
  - Events tracked: webhook signature failures, price mismatch, suspicious bookings
  - Import: `import {captureMessage} from "../sentry";`

**Changelog 6.4**: Timeline Calendar Performance & Navigation Fixes:
- **Month navigation buttons requiring 2 clicks**: Fixed by canceling animation instead of skipping
- **FAB shadow invisible on hover**: `0.5.toInt() = 0` → `(0.5 * 255).toInt()`
- **Excessive rebuilds during scroll**: Dynamic threshold (30 days during animation vs 10 days normally)
- **_getDateRange() optimization**: Added `_cachedFullDateRange` caching (1460 objects generated once)
- **Scroll retry logging**: Simplified to reduce console spam

**Changelog 6.3**: Platform Connections Security Rules & Price Calendar Validation:
- **Permission-denied bug fix za "Označi kao dostupno" bulk akciju**:
  - Problem: Bulk update uspije ("Batch commit successful"), ali permission-denied error se pojavi
  - Uzrok: `platformConnectionsForUnitProvider` query na `platform_connections` kolekciju PRIJE bulk update-a
  - `platform_connections` kolekcija NIJE IMALA Firestore security rules definirana
  - Fix: Dodana nova sekcija u `firestore.rules`:
    ```javascript
    match /platform_connections/{connectionId} {
      allow read: if isResourceOwner();
      allow create: if canCreateAsOwner();
      allow update, delete: if isResourceOwner();
    }
    ```
- **Cross-validacija za min/max polja u price calendar edit dialogu**:
  - Min noći ne može biti veće od max noći
  - Min dana unaprijed ne može biti veće od max dana unaprijed
  - Pokazuje warning snackbar ako korisnik unese nelogičnu kombinaciju
  - Nove lokalizacije: `priceCalendarMinNightsCannotExceedMax`, `priceCalendarMinAdvanceCannotExceedMax`

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
