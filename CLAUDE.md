# Claude Code - Project Documentation

**BookBed** - Booking management platforma za property owner-e.

**Dodatni dokumenti:**
- [CLAUDE_BUGS_ARCHIVE.md](./docs/bugs-archive/CLAUDE_BUGS_ARCHIVE.md) - Detaljni bug fix-evi sa code examples
- [CLAUDE_WIDGET_SYSTEM.md](./docs/cloud-widget-systems/CLAUDE_WIDGET_SYSTEM.md) - Widget modovi, payment logic, pricing
- [CLAUDE_MCP_TOOLS.md](./docs/cloud-mcp-tools/CLAUDE_MCP_TOOLS.md) - MCP serveri, slash commands
- [EMAIL_SYSTEM.md](./docs/features/email-templates/EMAIL_SYSTEM.md) - Email template-i, payment rok, reminders
- [SECURITY_FIXES.md](./docs/SECURITY_FIXES.md) - Sigurnosne ispravke (SF-001, SF-002, ...)

---

## <? NIKADA NE MIJENJAJ

| Komponenta | Razlog |
|------------|--------|
| Cjenovnik tab (`unified_unit_hub_screen.dart`) | FROZEN - referentna implementacija |
| Unit Wizard publish flow | 3 Firestore docs redoslijed kriti
an |
| Timeline Calendar z-index | Cancelled bookings at base level (drawn first), confirmed on top |
| Calendar Repository (`firebase_booking_calendar_repository.dart`) | 989 linija, duplikacija NAMJERNA - bez unit testova NE DIRATI |
| Owner email u `atomicBooking.ts` | UVIJEK aalje - NE vraaj conditional check |
| Subdomain validation regex | `/^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$/` (3-30 chars) |
| `generateViewBookingUrl()` u `emailService.ts` | Email URL logika |
| Navigator.push za confirmation | NE vraaj state-based navigaciju |

---

## <? STANDARDI

```dart
// Gradients (preferred method)
final gradients = context.gradients;

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

**Rate Limiting** - dostupno u `functions/src/utils/rateLimit.ts`:
- `checkRateLimit()` - in-memory, za hot paths
- `enforceRateLimit()` - Firestore-backed, za critical actions

**Input Sanitization** - `functions/src/utils/inputSanitization.ts`:
```typescript
sanitizeText(name), sanitizeEmail(email), sanitizePhone(phone)
```

**Booking Lookup** - `functions/src/utils/bookingLookup.ts`:
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
| `bookbed-admin.web.app` | **Admin Dashboard** | `bookbed-admin` |

**Firebase Hosting targets** (`.firebaserc`):
| Target | Site ID | Build folder | Custom domain |
|--------|---------|--------------|---------------|
| `owner` | `bookbed-owner` | `build/web_owner` | app.bookbed.io |
| `widget` | `bookbed-widget` | `build/web_widget` | view.bookbed.io, *.view.bookbed.io |
| `admin` | `bookbed-admin` | `build/web_admin` | bookbed-admin.web.app |

**Build commands**:
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

**Klijent subdomene** (dodaju se u Firebase Console → Hosting → Add custom domain):
- `jasko-rab.view.bookbed.io` → widget za Jasmina
- Format: `{subdomain}.view.bookbed.io`

**⚠️ NE MIJEŠATI**: `bookbed.io` je REZERVISAN za marketing sajt. Widget UVIJEK ide na `view.bookbed.io`!

---

## 🔐 ADMIN DASHBOARD

**URL**: `https://bookbed-admin.web.app`

**Entry point**: `lib/admin_main.dart`

**Screens**:
| Screen | Fajl | Svrha |
|--------|------|-------|
| Login | `admin_login_screen.dart` | Email/password auth za admine |
| Dashboard | `admin_dashboard_screen.dart` | Stats: total owners, trial, premium |
| Users List | `users_list_screen.dart` | Lista svih owner-a sa paginacijom |
| User Detail | `user_detail_screen.dart` | Detalji korisnika, properties count, bookings count |

**Shell navigacija** (`admin_shell_screen.dart`):
- Unified Drawer za mobile i desktop
- Dark/Light theme toggle u drawer-u
- Logout dugme u drawer-u

**Firestore Rules za Admin pristup**:
```javascript
// users collection - admin može čitati sve korisnike
allow read: if isOwner(userId) || isAdmin() || isAdminFromFirestore();

// bookings collection group - admin može čitati sve bookinge
match /{path=**}/bookings/{bookingId} {
  allow read: if
    isAdmin() || isAdminFromFirestore() ||
    // ... ostale rules
}
```

**Admin provjera** (dva načina):
1. `isAdmin()` - Firebase custom claims: `request.auth.token.isAdmin == true`
2. `isAdminFromFirestore()` - Firestore document: `users/{uid}.role == 'admin'`

**Providers** (`admin_providers.dart`):
- `adminNavIndexProvider` - trenutni tab index
- `adminDarkModeProvider` - dark/light mode state

**Repository** (`admin_users_repository.dart`):
- `getOwners()` - paginated lista owner-a
- `getUserById()` - pojedinačni korisnik
- `getDashboardStats()` - count agregacije
- `getUserPropertiesCount()` - broj property-ja korisnika
- `getUserBookingsCount()` - broj bookinga korisnika (collectionGroup query)

**⚠️ VAŽNO**: Admin bookings count koristi `collectionGroup('bookings').where('owner_id', isEqualTo: userId)` - zahtijeva admin pristup u Firestore rules!

---

## 📱 MULTI-PLATFORM BUILD SYSTEM

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

**Animation System** - koristi `flutter_animate` paket:
```dart
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bookbed/core/design_tokens/animation_tokens.dart';

// Empty states - fade+scale entrance (PREFERIRANO)
child.animate()
  .fadeIn(duration: AnimationTokens.normal, curve: AnimationTokens.easeOut)
  .scale(begin: Offset(0.8, 0.8), curve: AnimationTokens.fastOutSlowIn)

// Staggered list entrances
ListView.builder(
  itemBuilder: (context, index) => Card(...)
    .animate(delay: Duration(milliseconds: index * 100))
    .fadeIn(duration: AnimationTokens.fast)
    .slideY(begin: 20, end: 0),
)

// Button press feedback (state-driven)
child.animate(target: _isPressed ? 1 : 0)
  .scale(begin: Offset(1.0, 1.0), end: Offset(0.95, 0.95), duration: AnimationTokens.instant)

// Hover effects (desktop)
child.animate(target: _isHovered ? 1 : 0)
  .scale(end: Offset(1.02, 1.02), duration: AnimationTokens.fast)
```

**Pre-built Animation Widgets** (`lib/shared/widgets/animations/`):
```dart
// Empty states (uses flutter_animate internally)
AnimatedEmptyState(icon: Icons.inbox, title: 'No items', subtitle: 'Add your first item')
StaggeredEmptyState(icon: Icons.notifications_none, title: 'No notifications')

// Loading transitions
AnimatedContentSwitcher(showContent: !isLoading, skeleton: MySkeleton(), content: MyContent())

// Custom extensions (lib/core/utils/flutter_animate_extensions.dart)
child.animateWithTokens().emptyStateEntrance()  // Combined fade + scale
child.animateWithTokens().cardEntrance(staggerIndex: index)  // Staggered list
child.animateWithTokens().buttonPress()  // Press feedback
child.animateWithTokens().hoverScale()  // Desktop hover
```

**flutter_animate Parallel Animations** - KRITIČNO za ispravno ponašanje:
```dart
// ❌ POGREŠNO - efekti se izvršavaju sekvencijalno (scale PA ONDA rotate)
child.animate()
  .scale(duration: 3.seconds)
  .rotate(duration: 3.seconds)

// ✅ ISPRAVNO - efekti se izvršavaju paralelno (scale I rotate istovremeno)
child.animate()
  .scale(duration: 3.seconds)
  .rotate(delay: Duration.zero, duration: 3.seconds)  // delay: Duration.zero = počni odmah
```

**Migrirani widgeti** (Phase 1-5 complete):
- ✅ `AnimatedEmptyState`, `StaggeredEmptyState` - empty state entrance
- ✅ `auth_logo_icon.dart` - scale pulse + glow
- ✅ `booking_details_screen.dart`, `booking_confirmation_screen.dart` - fade-in
- ✅ `confirmation_header.dart` - scale entrance
- ✅ `error_boundary.dart` - float + rotate
- ✅ `year_calendar_skeleton.dart`, `month_calendar_skeleton.dart` - shimmer

**NE MIGRIRATI** (ostaju sa AnimationController):
- `owner_app_loader.dart`, `bookbed_loader.dart` - custom Alignment(-1→2) pattern
- `connectivity_banner.dart` - event-driven forward()/reverse()
- `enhanced_login_screen.dart` - programmatic shake

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

---

## 🔔 FCM PUSH NOTIFICATIONS (Web)

**Komponente:**
| Fajl | Svrha |
|------|-------|
| `lib/core/services/fcm_service.dart` | Flutter FCM service - token management, permission, message handling |
| `lib/core/widgets/fcm_navigation_handler.dart` | Foreground message UI (snackbar) + navigation on tap |
| `web/firebase-messaging-sw.js` | Service Worker za background notifications |
| `functions/src/fcmService.ts` | Cloud Functions - šalje push notifikacije |

**VAPID Key**: Hardcoded u `fcm_service.dart` (linija 18-19)
- Generirano u Firebase Console → Project Settings → Cloud Messaging → Web Push certificates

**Token Storage**: `users/{userId}/data/fcmTokens` (Map format)
```json
{
  "fcmToken123...": {
    "token": "fcmToken123...",
    "platform": "web",
    "createdAt": Timestamp,
    "lastSeen": Timestamp
  }
}
```

**Flow:**
1. User logs in → `fcmService.initialize()` called from `enhanced_auth_provider.dart`
2. Browser requests notification permission
3. FCM token saved to Firestore
4. Booking created → `atomicBooking.ts` calls `sendPendingBookingPushNotification()`
5. Cloud Function reads tokens from Firestore, sends via `messaging.sendEachForMulticast()`
6. **Foreground**: `FcmNavigationHandler` shows snackbar with "View" button
7. **Background**: Service Worker shows system notification

**Foreground vs Background:**
- **Foreground** (app open): `FirebaseMessaging.onMessage` → Flutter handles → snackbar
- **Background** (tab closed/minimized): Service Worker `onBackgroundMessage` → system notification

**Navigation from SnackBar:**
```dart
// ⚠️ VAŽNO: SnackBar action koristi drugačiji context - nema GoRouter
// Rješenje: koristi ref.read(ownerRouterProvider).go() umjesto context.go()
final router = ref.read(ownerRouterProvider);
router.go('/owner/bookings?booking=$bookingId');
```

**Kada se šalje push:**
- `sendPendingBookingPushNotification()` - novi pending booking (widget)
- `sendBookingPushNotification()` - booking confirmed/updated/cancelled
- `sendPaymentPushNotification()` - payment received

---

## 🔄 FORCE UPDATE SYSTEM (Android)

**Dokumentacija**: `docs/FORCE_UPDATE_SETUP.md`

**Komponente:**
| Fajl | Svrha |
|------|-------|
| `core/models/app_config.dart` | Freezed model za Firestore config (minRequiredVersion, latestVersion, forceUpdateEnabled) |
| `core/services/version_check_service.dart` | Fetch-uje config iz Firestore, poredi verzije, vraća UpdateStatus |
| `core/widgets/force_update_dialog.dart` | Non-dismissible dialog - blokira app dok korisnik ne update-uje |
| `core/widgets/optional_update_dialog.dart` | Dismissible dialog - podseća svakih 24h |
| `core/providers/version_check_provider.dart` | Provider + VersionCheckWrapper widget |
| `main.dart` | VersionCheckWrapper wrap-uje GlobalNavigationOverlay |

**Firestore Config** (`app_config/android`):
```json
{
  "minRequiredVersion": "1.0.2",
  "latestVersion": "1.0.3",
  "forceUpdateEnabled": true,
  "updateMessage": "Nova verzija sa sigurnosnim popravkama je dostupna.",
  "storeUrl": "https://play.google.com/store/apps/details?id=io.bookbed.app"
}
```

**Firestore Rules**:
```javascript
match /app_config/{platform} {
  allow read: if isAuthenticated(); // Svaki authenticated user može check-ovati verziju
  allow write: if false; // Samo Cloud Functions (Admin SDK)
}
```

**Kada se poziva:**
1. **App start** - `VersionCheckWrapper.initState()` → `addPostFrameCallback`
2. **App resume** - `didChangeAppLifecycleState(resumed)` → check verziju

**Version comparison:**
- Semantic versioning: `MAJOR.MINOR.PATCH` (e.g., `1.0.2`)
- `1.0.2` < `1.0.3` → FORCE UPDATE ako `minRequiredVersion = 1.0.3`
- `1.0.2` < `1.0.3` → OPTIONAL UPDATE ako `latestVersion = 1.0.3` i `minRequiredVersion <= 1.0.2`

**UpdateStatus enum:**
- `forceUpdate` → Shows ForceUpdateDialog (cannot dismiss, must update)
- `optionalUpdate` → Shows OptionalUpdateDialog (dismissible, reminds every 24h)
- `upToDate` → No dialog

**Logging:**
```
VersionCheck: current=1.0.2, min=1.0.0, latest=1.0.3, status=optionalUpdate
```

**⚠️ VAŽNO**: Force update radi SAMO na Android native app. Web verzija se automatski ažurira pri deploy-u.

---

**Last Updated**: 2026-01-26 | **Version**: 6.38

**Changelog 6.38**: Timeline Calendar Visual Centering & Same-Day Turnover Support:
- **Visual Centering Fix** (`timeline_grid_widget.dart`):
  - **Problem**: Booking blocks appeared shifted right by ~half a day on timeline calendar
  - **Root Cause**: Parallelogram shape has `skewOffset ≈ dayWidth`, meaning top-left corner starts almost one full day right of container edge
  - **Fix**: Shift bookings left by `skewOffset / 2` so visual center aligns with day column boundaries
  - **Code**: `final left = (daysSinceFixedStart * dayWidth - skewOffset / 2).floorToDouble();`
- **Same-Day Turnover Support** (booking move operations):
  - **Problem**: Admin bookings couldn't be moved to turnover days (checkout == checkin), but Widget bookings could
  - **Root Cause**: Dates weren't normalized to midnight before overlap comparison, causing time component differences
  - **Fix** (`booking_model.dart`, `booking_action_menu.dart`, `timeline_booking_stacker.dart`):
    - `datesOverlap()` now normalizes all dates to midnight before comparison
    - Uses strict inequality (`isBefore`/`isAfter`) which allows checkout == checkin
    - `booking_action_menu` normalizes dates before calling `areDatesAvailable()`
    - `timeline_booking_stacker` uses normalized dates for stack level assignment
  - **Example**: Booking A (May 1-5) does NOT overlap with Booking B (May 5-10)
- **Repository Improvements** (`firebase_booking_repository.dart`):
  - `getOverlappingBookings()` now excludes completed bookings (only pending/confirmed block dates)
  - `deleteBooking()` accepts optional `booking` param to avoid permission issues with collectionGroup queries

**Changelog 6.37**: Timeline Calendar TELEPORT Bug Fixes:
- **Problem 1**: Clicking dates more than ~3 months away in date picker didn't work reliably
  - Sometimes jumped correctly, sometimes stayed in place or jumped to wrong date
- **Root Cause 1**: Timeline calendar uses 90-day "windowed" view for performance
  - When target date is outside visible window, animated scroll couldn't reach it
  - Recursive `_scrollToDate` calls caused race conditions
  - `_extendDateRangeIfNeeded` during scroll caused additional conflicts
- **Fix 1** (`timeline_calendar_widget.dart`):
  - **TELEPORT approach**: For far jumps (target outside visible window):
    1. Set `_isProgrammaticScroll = true` to block scroll listener updates
    2. Rebuild window around target date (set `_visibleStartIndex`, `_forceVisibleStartIndex = true`)
    3. Use `jumpTo()` (instant) instead of `animateTo()` (no race conditions)
    4. Reset flag after 500ms via Timer
  - Two TELEPORT blocks: one for range extension (past/future dates), one for far jumps within existing range
  - **Disabled `_extendDateRangeIfNeeded`**: No longer needed - TELEPORT handles range extension
- **Problem 2**: After TELEPORTing to distant dates and manually scrolling back, reservations disappeared
  - User reported: TELEPORT to May, scroll back towards January → reservations vanish
- **Root Cause 2**: TELEPORT scroll position calculation was missing `offsetWidth`
  - Content structure: `[SizedBox(offsetWidth)] + [day cells]`
  - TELEPORT calculated: `(newWindowTargetDay * dayWidth) - (viewport * 0.25)` ≈ 1550px
  - Should have been: `offsetWidth + (newWindowTargetDay * dayWidth) - (viewport * 0.25)` ≈ 19550px
  - Without `offsetWidth`, scroll landed in the spacer instead of the actual day cells
- **Fix 2** (`timeline_calendar_widget.dart` lines ~860 and ~970):
  ```dart
  // BUG FIX: Must include offsetWidth in scroll calculation!
  final offsetWidth = _visibleStartIndex * dimensions.dayWidth;
  final scrollInNewWindow =
      offsetWidth +
      (newWindowTargetDay * dimensions.dayWidth) -
      (dimensions.visibleContentWidth * 0.25);
  ```
- **Key insight**: Flag-based protection (`_isProgrammaticScroll`) must be set BEFORE `setState()` and reset AFTER scroll completes
- **Testing**: Confirmed working - TELEPORT + manual scroll back no longer causes reservations to disappear

**Changelog 6.36**: Calendar Timeline Booking Move Fixes:
- **UI Not Refreshing After Booking Move** (main fix):
  - **Problem**: After moving booking between units via drag-drop or menu, changes only visible after full app refresh
  - **Root Cause**: Only `calendarBookingsProvider` was invalidated, but UI watches `timelineCalendarBookingsProvider` (filtered provider)
  - **Fix** (`calendar_drag_drop_provider.dart`, `booking_action_menu.dart`):
    - Added `ref.invalidate(timelineCalendarBookingsProvider)` alongside `calendarBookingsProvider`
    - MUST invalidate BOTH: base provider AND filtered provider that UI watches
- **"Cannot use ref after widget disposed" Error**:
  - **Problem**: Error appeared after clicking "Move to" menu item
  - **Root Cause**: `Navigator.pop(context)` called BEFORE `_moveBookingToUnit()`, so `ref.invalidate()` executed after widget disposal
  - **Fix** (`booking_action_menu.dart`):
    - Execute move operation FIRST (while dialog still open)
    - Close dialog AFTER operation completes with `if (mounted && context.mounted)` check
    - Changed `_moveBookingToUnit` return type from `void` to `bool` for proper flow control
- **Provider Invalidation Pattern** (Important for future reference):
  ```dart
  // CORRECT - invalidate both base AND filtered providers
  ref.invalidate(calendarBookingsProvider);        // base provider
  ref.invalidate(timelineCalendarBookingsProvider); // filtered provider UI watches
  ```

**Changelog 6.35**: Web Push Notifications (FCM):
- **NEW FEATURE**: Push notifications za Owner Dashboard (web)
- **Components Created**:
  - `fcm_service.dart` - Flutter FCM service sa VAPID key, token management
  - `fcm_navigation_handler.dart` - Foreground snackbar + navigation handling
  - `firebase-messaging-sw.js` - Service Worker za background notifications
  - `fcmService.ts` - Cloud Functions za slanje push notifikacija
- **Token Storage**: `users/{userId}/data/fcmTokens` (Map format, supports multiple devices)
- **Integration** (`atomicBooking.ts`):
  - `sendPendingBookingPushNotification()` za pending bookinge
  - `sendBookingPushNotification()` za confirmed/updated/cancelled
- **Bug Fix**: "No GoRouter found in context" - SnackBar action koristi `ref.read(ownerRouterProvider).go()` umjesto `context.go()`
- **Foreground**: Shows snackbar with "View" button → navigates to booking
- **Background**: Service Worker shows system notification with click-to-open

**Changelog 6.34**: Weekend Pricing Display & UX Improvements:
- **Weekend Pricing in Widget Calendar** (main feature):
  - **Problem**: Weekend pricing showed correctly in owner dashboard but NOT in embedded widget calendar
  - **Root Cause**: Widget calendar only showed prices in hover tooltips (desktop-only), mobile users couldn't see prices
  - **Fix** (`month_calendar_widget.dart`, `year_calendar_widget.dart`):
    - Added `_buildDayCellContent()` helper with price display directly in calendar cells
    - Price hierarchy: custom daily price → weekend base price → base price
    - Year calendar: price only shows when cellSize >= 24px (responsive)
- **Registration Form UX Fix** (`enhanced_register_screen.dart`):
  - **Problem**: Button disabled on any validation failure without showing why
  - **Fix**: Button only disabled when fields are EMPTY. Validation errors shown on submit click
  - Better UX: users see exactly what needs fixing
- **Unit Hub Race Condition Fix** (`unified_unit_hub_screen.dart`):
  - **Problem**: Auto-selection failed when units loaded before properties (empty properties list)
  - **Fix**: Added guard `if (properties.isEmpty) return;` in `_handleUnitsChanged()`
  - Added `ref.listen` for properties changes to re-trigger auto-selection
- **Booking Details Dialog** (`booking_details_dialog.dart`):
  - Responsive spacing improvements for small screens
  - Payment method and payment option display added
- **Unit Wizard Simplified**: Reduced from 5 steps to 4 steps (removed Photos step - photos added via Unit Hub)

**Changelog 6.33**: Force Update System (Android) - IMPLEMENTED:
- **NEW FEATURE**: App version control sa force/optional update dialogs
- **Components Created**:
  - `AppConfig` model (freezed) - Firestore config za verzije
  - `VersionCheckService` - Version comparison logic (semantic versioning)
  - `ForceUpdateDialog` - Non-dismissible dialog za kritične update-e
  - `OptionalUpdateDialog` - Dismissible dialog, podseća svakih 24h
  - `VersionCheckWrapper` - Widget za automatic version checking
- **Integration** (`main.dart`):
  - VersionCheckWrapper wrap-uje GlobalNavigationOverlay
  - Check-uje verziju na app start i app resume
- **Firestore**:
  - Collection: `app_config/{platform}` (android, ios)
  - Security rules: Read za authenticated usere, write samo Admin SDK
- **Localization**: 10 novih stringova (EN + HR) za update dialogs
- **Documentation**: `docs/FORCE_UPDATE_SETUP.md` - setup instrukcije
- **Testing Required**: Kreirati test `app_config/android` dokument u Firestore
- **Next Release**: Force update će biti aktivan tek u 1.0.3+ (trenutno 1.0.2+6)

**Changelog 6.32**: Email Verification Network Error Fix (v1.0.2+6):
- **CRASH FIX**: Network errors during email verification no longer crash the app
- **Problem**: When checking email verification status, network failures (timeout, no connection) caused app crash
- **Root Cause**: `User.reload()` in `refreshEmailVerificationStatus()` had no error handling
- **Fix** (`enhanced_auth_provider.dart:781-806`):
  - Added try-catch around `user.reload()` to catch and log network errors
  - Error is rethrown for caller to handle gracefully
- **Fix** (`email_verification_screen.dart:55-75`):
  - Added try-catch around `_checkVerificationStatus()` call
  - Shows user-friendly error message: "Network error. Please check your internet connection"
  - User can retry manually or when app resumes
- **Result**: Graceful degradation instead of crash, better UX for poor network conditions
- **Version**: Bumped to 1.0.2+6 for Google Play release

**Changelog 6.31**: Admin Dashboard Documentation & Fixes:
- **Admin Dashboard Section Added** to CLAUDE.md:
  - URL: `https://bookbed-admin.web.app`
  - Entry point, screens, shell navigation documented
  - Firestore rules for admin access documented
  - Admin providers and repository patterns documented
- **Firestore Rules Fix** (`firestore.rules`):
  - Added `isAdmin() || isAdminFromFirestore() ||` to bookings collection group rules
  - Fixes: Admin couldn't see user's bookings count (permission-denied)
- **UI Fixes** (`admin_shell_screen.dart`, `users_list_screen.dart`):
  - Removed theme toggle from AppBar (kept only in drawer)
  - Fixed refresh button on Users page (moved to content row)
- **Hosting Targets Updated**: Added `admin` target for `bookbed-admin.web.app`

**Changelog 6.30**: Safari Web Compatibility Fixes:
- **Flutter Loader TypeError Fix** (`web/index.html`):
  - **Problem**: `TypeError: _flutter.loader.load is not a function` on Chrome & Safari
  - **Root Cause**: `flutter_bootstrap.js` adds `loader` as nested property on `_flutter` object
  - **Original Approach**: `Object.defineProperty` only intercepted initial `_flutter` assignment, not nested `loader`
  - **Fix**: JavaScript `Proxy` with `set` trap to intercept all property assignments including `loader`
  - **Renderer Fallback**: Check `buildConfig.builds` before injecting renderer config
  - Prevents "FlutterLoader could not find a build compatible" error
- **Safari Firebase Init Error Fix** (`main.dart`, `widget_main.dart`, `widget_main_dev.dart`):
  - **Problem**: `Null check operator used on a null value` during Firebase initialization on Safari
  - **Root Cause**: `Firebase.apps` getter throws on Safari when SDK hasn't fully initialized
  - **Fix**: Wrapped `Firebase.apps.isEmpty` in nested try-catch:
    ```dart
    bool needsInit = true;
    try {
      needsInit = Firebase.apps.isEmpty;
    } catch (_) {
      // Safari throws - assume needs init
      needsInit = true;
    }
    if (needsInit) await Firebase.initializeApp(...);
    ```
  - Applied to: Owner app (`main.dart`), Widget production (`widget_main.dart`), Widget dev (`widget_main_dev.dart`)
- **Removed Firebase Compat SDK Pre-initialization**:
  - Commented out `firebase-app-compat.js` and related SDK scripts in `index.html`
  - Was causing conflicts with Flutter's modular Firebase SDK
- **Files Modified**:
  - `web/index.html`: Proxy-based loader interception, renderer fallback, removed compat SDK
  - `lib/main.dart`: Safari-safe Firebase init with detailed logging
  - `lib/widget_main.dart`: Added `_initializeFirebaseSafely()` helper
  - `lib/widget_main_dev.dart`: Added `_initializeFirebaseSafelyDev()` helper
- **Result**: Both Owner Dashboard and Widget now work on Safari (tested on macOS Safari)

**Changelog 6.29**: App Store Submission Preparation & UI Fixes:
- **iOS Deployment Target Fix**:
  - Problem: Runner.xcodeproj targetao iOS 13.0, Podfile zahtijevao iOS 15.0
  - Fix: Ažurirane sve 3 instance `IPHONEOS_DEPLOYMENT_TARGET` na 15.0
  - Rezultat: `flutter build ios --release` sada prolazi
- **Subscription Screen Simplification**:
  - Problem: `trialStatusProvider` uzrokovao Firestore permission error
  - Fix: Uklonjena Firestore zavisnost, screen sada samo pokazuje web redirect button
  - Novi l10n: `subscriptionWebOnlyTitle`, `subscriptionWebOnlyMessage`, `subscriptionContinueToWeb`
  - App Store compliance: Subscription management na webu, ne u app-u
- **Stripe Loading Animation Fix**:
  - Problem: Currency simboli (€, $, £) se pomjerali ~640px umjesto 20px
  - Uzrok: `slideY(end: -20)` koristi widget height multiplier, ne pixele
  - Fix: Promijenjeno na `moveY(end: -20)` koji koristi apsolutne pixele
- **Unit Hub Menu Button Styling**:
  - Zamijenjen plain `IconButton` sa styled button (container, border, SmartTooltip)
  - Konzistentno sa calendar toolbar button stilom
- **App Store Audit**: Verified Sign in with Apple, ATT compliance, ATS, FCM config

**Changelog 6.28**: Dashboard Metrics Fix - Exclude Pending Bookings:
- **Problem**: Dashboard Revenue, Bookings Count, i Occupancy Rate uključivali pending bookinge
- **Izvor**: `fix/dashboard-metrics-6709532682132730445` branch (Jules AI)
- **Fix** (`unified_dashboard_provider.dart`):
  - Kreiran `confirmedAndCompletedBookings` filter
  - Revenue, bookingsCount, occupancyRate koriste samo confirmed/completed
  - **POBOLJŠANJE**: Charts (revenueHistory, bookingHistory) također filtrirani
- **Rezultat**: Summary metrike i chart totali sada konzistentni
- **Napomena**: Upcoming Check-ins i dalje uključuje pending (očekivano ponašanje)

**Changelog 6.27**: Logo Asset Implementation & FCM Push Notifications:
- **Logo Asset System**:
  - Nova `logo-light.avif` slika u `assets/images/`
  - Kreiran `BookBedLogo` widget (`lib/shared/widgets/bookbed_logo.dart`)
  - **Dark Mode Support**: Automatska inverzija boja putem `ColorFilter.matrix`
  - `AuthLogoIcon` ažuriran da koristi `Image.asset` umjesto `CustomPaint`
  - Uklonjena stara `_LogoPainter` klasa
  - Fallback na `Icons.home_work_outlined` ako asset ne učita
- **FCM Push Notifications** (Phase 2):
  - Integrirano u `atomicBooking.ts` za pending i confirmed bookinge
  - `sendBookingPushNotification()` sada prima opcionalne `checkInDate`/`checkOutDate` parametre
  - `sendPendingBookingPushNotification()` za pending bookinge
  - In-app notifikacije putem `createBookingNotification()`
  - Non-blocking izvršenje sa `.catch()` error handling
- **Modified Files**:
  - `pubspec.yaml`: Dodana `assets/images/` folder
  - `lib/shared/widgets/bookbed_logo.dart`: Novi widget
  - `lib/features/auth/presentation/widgets/auth_logo_icon.dart`: Image.asset + dark mode
  - `lib/core/widgets/owner_app_loader.dart`: Koristi `AuthLogoIcon`
  - `lib/features/widget/presentation/widgets/common/bookbed_loader.dart`: Koristi `AuthLogoIcon`
  - `functions/src/atomicBooking.ts`: FCM integracija
  - `functions/src/fcmService.ts`: Ažurirani parametri funkcije

**Changelog 6.26**: Security Audit Complete (SF-001 through SF-017):
- **Analizirani branchevi**: 12 AI agent brancheva (Google Jules, Sentinel, Bolt, Palette)
- **Implementirano**: 17 sigurnosnih ispravki (2 CRITICAL, 1 HIGH, ostalo Low/Medium)
- **Odbijeno**: 1 (SF-003 - mikro-optimizacija bez koristi)
- **Duplikati preskočeni**: 1 (sentinel/fix-pii-leak-calendar - već riješeno u SF-014)

**CRITICAL fixes:**
- **SF-007**: Uklonjena mogućnost spremanja lozinke u SecureStorage ("Remember Me" sada sprema samo email)
- **SF-011**: Dodan `service-account-key.json` u `.gitignore` (sprječava slučajno commitanje Firebase admin credentials)

**HIGH fix:**
- **SF-014**: Spriječeno izlaganje PII podataka (ime, email, telefon gosta) u public booking widget kalendaru

**Ostale ispravke:**
- SF-001: Owner ID validacija u booking creation (server-side)
- SF-002: SSRF prevencija u iCal sync (whitelist enabled)
- SF-004: IconButton hover/splash feedback
- SF-005: Phone number validacija
- SF-006: Sequential character password check (slova + brojevi)
- SF-008: Booking notes length limit (1000 chars)
- SF-009: Error handling info leakage prevention
- SF-010: Year calendar race condition fix
- SF-012: Secure error handling & email sanitization
- SF-013: Haptic feedback on password toggle
- SF-015: DebouncedSearchField ValueNotifier optimization
- SF-016: AnimatedGradientFAB ValueNotifier optimization
- SF-017: Password visibility toggle tooltips (accessibility)

**Dokumentacija**: Sve ispravke detaljno dokumentirane u `docs/SECURITY_FIXES.md`

**Changelog 6.25**: Security Fixes (SF-001, SF-002):
- **SF-001: Owner ID Validation in Booking Creation** (`atomicBooking.ts`):
  - **Problem**: `ownerId` parametar dolazio direktno iz klijentskog zahtjeva bez validacije
  - **Fix**: Sada se `owner_id` dohvaća iz property dokumenta u Firestore-u (server-side validacija)
  - **Benefit**: Sprječava maliciozne korisnike da postave pogrešan `owner_id`
- **SF-002: SSRF Prevention in iCal Sync** (`icalSync.ts`):
  - **Problem**: Whitelist validacija za iCal URL-ove bila zakomentirana - server dopuštao bilo koji URL
  - **Fix**: Omogućena whitelist validacija - samo poznate booking platforme (Booking.com, Airbnb, Google Calendar, etc.)
  - **Breaking Change**: URL-ovi koji nisu na whitelisti sada se blokiraju
  - **Otkrio**: Google Sentinel (automated security scan)
- **Nova dokumentacija**: `docs/SECURITY_FIXES.md` - prati sve sigurnosne ispravke s detaljima

**Changelog 6.24**: Embed Code URL Fix - Remove Subdomain Prefix:
- **Problem**: Embed kod generirao URL sa property subdomain prefiksom (npr. `jasko-apartments.view.bookbed.io`)
  - Subdomene nisu uvijek konfigurirane u Firebase Hosting
  - Property name se koristio kao subdomain, što ne odgovara stvarnoj konfiguraciji
- **Fix**: Embed kod sada uvijek koristi `view.bookbed.io` bez prefiksa
  - Property i Unit ID parametri su dovoljni za identifikaciju
  - Subdomene su opcionalne i koriste se samo za slug URL-ove (shareable links)
- **Izmijenjeni fajlovi**:
  - `embed_code_generator_dialog.dart`: `_iframeEmbedCode` sada koristi `_defaultWidgetBaseUrl`
  - `embed_widget_guide_screen.dart`: `_generateEmbedCode` sada koristi fiksni `view.bookbed.io`
- **Rezultat**: Embed kod radi na svim sajtovima bez potrebe za konfiguracijom subdomene

**Changelog 6.23**: flutter_animate Migration Phase 2-5 Complete:
- **Migrated Files** (AnimationController → flutter_animate):
  - `auth_logo_icon.dart`: Scale pulse + glow opacity animation
  - `booking_details_screen.dart`: Fade-in entrance animation
  - `booking_confirmation_screen.dart`: Fade-in entrance animation
  - `confirmation_header.dart`: Scale animation for success icon
  - `error_boundary.dart`: Float + rotate animation for error illustration
  - `year_calendar_skeleton.dart`: Shimmer effect
  - `month_calendar_skeleton.dart`: Shimmer effect
- **Critical Bug Fix - Parallel Animations**:
  - **Problem**: flutter_animate chains `.effect1().effect2()` run sequentially by default
  - **Original behavior**: Single AnimationController = simultaneous animations
  - **Fix**: Added `delay: Duration.zero` to second effect for parallel execution
  - Affected: `auth_logo_icon.dart` (scale + glow), `error_boundary.dart` (moveY + rotate)
- **Radians to Turns Conversion**:
  - flutter_animate `.rotate()` uses turns (1 turn = 360°), not radians
  - Formula: `radians / (2 * pi)` → turns (e.g., `0.05 rad / 6.283 ≈ 0.008 turns`)
- **Files NOT Migrated** (patterns incompatible with flutter_animate):
  - `owner_app_loader.dart`, `bookbed_loader.dart`, `bookbed_branded_loader.dart`: Custom `Alignment(-1 → 2)` animation
  - `connectivity_banner.dart`: Event-driven `forward()`/`reverse()` control
  - `enhanced_login_screen.dart`: Programmatic shake animation
  - `animated_success.dart`: Complex programmatic control with external trigger
- **Code Reduction**: ~55% average across migrated files (removed dispose, initState, AnimationController boilerplate)

**Changelog 6.22**: flutter_animate Migration & Dependency Cleanup:
- **Removed 12 Unused Packages** from pubspec.yaml:
  - `easy_localization` - projekt koristi `intl` umjesto toga
  - `photo_view` - nikad implementirano
  - `visibility_detector`, `step_progress_indicator` - nekorišteno
  - `flutter_map`, `flutter_map_marker_cluster`, `geolocator`, `geocoding`, `latlong2` - mape neće biti
  - `scrollable_positioned_list`, `flutter_dotenv`, `universal_io`, `vector_math` - nekorišteno
- **Moved `fake_cloud_firestore`** iz dependencies u dev_dependencies (test-only paket)
- **Kept for future use**: `pdf`, `printing` (fakture/izvještaji), `flutter_animate` (animacije)
- **flutter_animate Migration Phase 1 Complete**:
  - Created `flutter_animate_extensions.dart` - helper methods za AnimationTokens integraciju
  - Migrated `AnimatedEmptyState`: StatefulWidget (135 lines) → StatelessWidget (50 lines) = 63% reduction
  - Migrated `StaggeredEmptyState`: StatefulWidget (164 lines) → StatelessWidget (70 lines) = 57% reduction
  - Total: 299 → 120 lines = **60% code reduction**
  - Zero breaking changes - API remains identical
  - Benefits: No AnimationController disposal needed, no memory leak risk, simpler code

**Changelog 6.21**: Stripe Connect Return URL Routing Fix:
- **Sentry Error Fix**: `permission-denied` errors on `/owner/stripe-return` route
  - **Problem**: After completing Stripe Connect onboarding, Stripe redirects to `/owner/stripe-return`
  - **Root Cause**: Route was never defined in GoRouter, causing 404 fallback and race conditions with auth state
  - **Fix** (`router_owner.dart`):
    - Added `stripeReturn = '/owner/stripe-return'` and `stripeRefresh = '/owner/stripe-refresh'` route constants
    - Added GoRoute handlers that redirect to `OwnerRoutes.stripeIntegration` (`/owner/integrations/stripe`)
  - **Result**: Owner returns to Stripe Integration page after onboarding, where `_loadStripeAccountInfo()` fetches updated status
- **Note**: This fix only affects owner Stripe Connect flow (account linking), NOT widget Stripe payments

**Changelog 6.20**: Bank Account Routing Fix & Bottom Sheet Standardization:
- **Bank Account 404 Routing Fix** (`bank_account_screen.dart`):
  - **Problem**: Navigating Unit Hub → Widget Settings → Bank Transfer → Bank Account → Save caused 404 error
  - **Root Cause**: Hardcoded route string `/owner/integrations/payments` instead of route constant
  - **Fix**: Added `router_owner.dart` import and changed all 3 navigation points to use `OwnerRoutes.unitHub`
  - Lines affected: 121 (after save), 271 (cancel button), 319 (discard dialog)
  - Uses `context.canPop() ? context.pop() : context.go(OwnerRoutes.unitHub)` pattern
- **Bottom Sheet Height Standardization** (`notification_settings_bottom_sheet.dart`):
  - **Problem**: Notification Settings used fixed 600px height while Language/Theme used dynamic percentage
  - **Fix**: Changed to use `ResponsiveSpacingHelper.getBottomSheetMaxHeightPercent(context)`
  - All bottom sheets now use consistent responsive heights:
    - Landscape Mobile: 80% of screen
    - Portrait Mobile: 70% of screen
    - Tablet/Desktop: 60% of screen
- **Serbian to Croatian Localization Fixes** (`app_hr.arb`):
  - Fixed remaining Ekavian (Serbian) words to Ijekavian (Croatian)
  - Examples: "Ocene"→"Ocjene", "Sinhronizuj"→"Sinkroniziraj", "nalog"→"račun", etc.
- **SelectableText for Booking Details**:
  - Booking ID, guest email, and phone number now copyable via long-press
  - Added to `booking_card_header.dart` and `booking_card_guest_info.dart`

**Changelog 6.19**: Bookings Page UX Improvements & Automatic Status Updates:
- **Booking ID Display Fix** (`booking_card_header.dart`, `booking_details_dialog.dart`):
  - Changed from truncated document ID (`#abc123xy`) to user-friendly `booking_reference` (e.g., `BK-2024-001234`)
  - Fallback to document ID if `booking_reference` is null
  - Booking ID now copyable via SelectableText (from previous changelog)
- **iCal Bookings Already Displayed**:
  - Confirmed: NO source filter in repository - iCal bookings automatically shown
  - Table View already has "Source" column with platform badges (Widget, Booking.com, Airbnb, iCal)
  - Timeline Calendar already has platform icon in top-right corner
  - No changes needed - feature already works correctly
- **Email Template Duplicate Greeting Fixed** (`send_email_dialog.dart`):
  - **Problem**: "Poštovani {name}," appeared TWICE - once in Flutter template, once in Cloud Functions
  - **Fix**: Removed greeting from Flutter `getMessage()` method (lines 50-95)
  - Cloud Functions `generateGreeting()` already adds "Poštovani/a {name}," automatically
  - Affects all email templates: confirmation, reminder, cancellation, custom
- **Automatic Booking Status Updates** - NEW scheduled Cloud Function:
  - **Created**: `completeCheckedOutBookings.ts` - auto-completes bookings after checkout
  - **Schedule**: Daily at 2:00 AM (Zagreb timezone) - configurable via `AUTOCOMPLETE_SCHEDULE` env var
  - **Query**: `.where("status", "in", ["confirmed", "pending"]).where("check_out", "<", today)`
  - **Filters OUT**: External/iCal bookings (source: booking_com, airbnb, ical, external) and ID prefix `ical_`
  - **Batch Processing**: 400 docs/batch, max 5000 docs/run, error recovery with individual fallback
  - **Updates**: Sets `status: "completed"` and `updated_at: now()`
  - **Export**: Added to `index.ts` for deployment
  - **Firestore Index**: Added composite index `status` (ASC) + `check_out` (ASC) for collection group query
  - **Logging**: Structured logs with success/failure counts, duration tracking
  - **Benefits**: Owners get accurate historical data without manual status updates

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

---

## 📝 TODO: Bookbed Website Documentation

**Prioritet:** High  
**Rok:** 2-3 dana  
**Lokacija:** Bookbed React website (docs sekcija)

### Potrebna dokumentacija:

**Za Owners (Property Managers):**
1. Getting Started - Kreiranje property-ja i unita
2. Pricing Setup - Postavljanje cijena i sezonskih pravila
3. Stripe Connect - Povezivanje Stripe računa
4. Widget Configuration - Embed kod i postavke
5. Managing Bookings - Pregled i upravljanje rezervacijama
6. iCal Sync - Sinkronizacija sa Booking.com/Airbnb
7. Notifications - Email postavke i obavijesti

**Za Guests:**
1. How to Book - Koraci za rezervaciju
2. Payment Options - Stripe, bank transfer, pay on arrival
3. Booking Lookup - Pregled postojeće rezervacije
4. Cancellation - Otkazivanje rezervacije

**API Reference:**
1. Cloud Functions API - createBookingAtomic, verifyBookingAccess, etc.
2. Widget Embed Options - URL parametri, customization
3. Webhook Events - Stripe webhooks, booking events

**Izvor sadržaja:** Ovaj projekt (CLAUDE.md, SECURITY_FIXES.md, kod)

---

## 📝 TODO: Admin Controls Feature

**Prioritet:** Low (nice-to-have)
**Kompleksnost:** ~20-30 minuta
**Izvor:** Ekstrahirano iz branch `sentinel-firestore-audit-15445911159531971809`

### Opis
Admin kontrole za upravljanje korisničkim računima iz Admin panela bez potrebe za direktnim Firestore editiranjem.

### Nova polja u UserModel (`lib/shared/models/user_model.dart`):
```dart
/// Hide subscription page from this user (e.g., for special deals)
final bool hideSubscription;

/// Admin override of account type (bypasses subscription logic)
final AccountType? adminOverrideAccountType;
```

### Potrebne izmjene:

**1. UserModel** (`lib/shared/models/user_model.dart`):
- Dodati `hideSubscription` (bool, default: false)
- Dodati `adminOverrideAccountType` (AccountType?, nullable)
- Ažurirati `fromJson()` i `toJson()`
- Ažurirati `copyWith()`

**2. AdminUsersRepository** (`lib/features/admin/data/repositories/`):
```dart
Future<void> updateAdminFlags({
  required String userId,
  bool? hideSubscription,
  AccountType? adminOverrideAccountType,
  bool clearOverride = false,  // Set to true to remove override
}) async {
  final updates = <String, dynamic>{
    'updated_at': FieldValue.serverTimestamp(),
  };
  if (hideSubscription != null) {
    updates['hide_subscription'] = hideSubscription;
  }
  if (clearOverride) {
    updates['admin_override_account_type'] = FieldValue.delete();
  } else if (adminOverrideAccountType != null) {
    updates['admin_override_account_type'] = adminOverrideAccountType.name;
  }
  await _firestore.collection('users').doc(userId).update(updates);
}
```

**3. UserDetailScreen** (`lib/features/admin/presentation/screens/user_detail_screen.dart`):
- Dodati "Admin Controls" card sa:
  - Switch za `hideSubscription`
  - Dropdown za `adminOverrideAccountType` (None, Free, Premium, Enterprise)
  - Save button

**4. SubscriptionScreen** provjera:
```dart
// U subscription_screen.dart
if (user.hideSubscription) {
  // Redirect away or show "Contact admin" message
}

// Za account type provjeru
AccountType get effectiveAccountType =>
    user.adminOverrideAccountType ?? user.accountType;
```

### Korištenje
- Admin može sakriti subscription stranicu za korisnika koji ima special deal
- Admin može override-ati account type bez potrebe za Stripe subscription

---

## ⚠️ OBAVEZNO PRIJE COMMITA

**Dart formatiranje** - CI će odbiti PR ako kod nije formatiran:
```bash
dart format .
```

**Za AI agente (Jules, Sentinel, Bolt):** UVIJEK pokreni `dart format .` prije kreiranja commita. CI workflow provjerava formatiranje i odbija neformatirani kod.

---

## 🚀 Changelog 5.9: Performance & Security Optimizations (2026-01-13)

**Portirane optimizacije iz feature brancheva:**

### Performance
| Optimizacija | Datoteke | Korist |
|--------------|----------|--------|
| `keepAlive: true` calendar provider | `owner_calendar_provider.dart` | Nema re-fetch pri navigaciji |
| 3m/9m date range (umjesto 12m/12m) | `owner_calendar_provider.dart` | ~75% manje Firestore reads |
| `unitToPropertyMap` passthrough | `firebase_owner_bookings_repository.dart` | Eliminira N+1 queries za iCal |
| `aggregate(sum())` za revenue | `firebase_revenue_analytics_repository.dart` | 1 query umjesto 100+ reads |
| `collectionGroup.count()` | `admin_users_repository.dart` | N+1 → 1 query |
| Skip redundant profile fetch | `enhanced_auth_provider.dart` | Nema double-fetch na login |
| Memory cache za rate limit | `rate_limit_service.dart` | Manje Firestore reads za locked accounts |

### Security
| Fix | Datoteke | Opis |
|-----|----------|------|
| owner_id integrity check | `firestore.rules` | Sprječava fake owner_id injection |
| Log redaction (GDPR) | `logging_service.dart` | Redaktira passworde, tokene, API keys |
| Token masking | `ical_export_service.dart` | Maskira Firebase Storage tokene |

**Preskočene grane:** `bolt-optimize-booking-retrieval` (pagination rizik), `bolt-property-global-store` (veliko refaktoriranje), `jules/security-audit-fixes` (XSS već riješen), `chore/weekly-dependency-updates` (ručno updatati).
