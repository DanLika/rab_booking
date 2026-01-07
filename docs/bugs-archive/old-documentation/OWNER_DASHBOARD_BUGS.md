# Owner Dashboard - Analiza Problema i Preporuke

**Status:** ✅ VEĆINA RIJEŠENA (vidi tabelu ispod)
**Datum kreiranja:** 2024
**Zadnje ažurirano:** 2025-12-16

---

> **Napomena (2025-12-16):** Kritični bugovi (#1-3) su VERIFIED/FIXED.
> Bugovi #4 i #5 (Error Boundaries, Async Timeouts) su IMPLEMENTIRANI - vidi `BUG_FIX_MASTER_PLAN.md`.
> Preostali bugovi (#6-12) su srednji/nizak prioritet.

---

## 📋 Pregled

Ovaj dokument sadrži analizu potencijalnih problema u Owner Dashboard modulu, Core Services, Core Utils, Domain Models i Owner Dashboard Screens i preporuke za njihovo rešavanje. Analiza je bazirana na pregledu koda u:
- `lib/features/owner_dashboard/` - Owner Dashboard feature modul
  - `presentation/screens/` - Screen komponente (Bookings, Calendar, Profile, Property Form, Notifications, itd.)
  - `presentation/widgets/` - Reusable widget komponente (Dialogs, Drawer, Bottom Sheets, itd.)
  - `presentation/widgets/calendar/` - Calendar widget komponente (Booking Block, Drop Zone, Context Menu, Action Menu, itd.)
  - `presentation/widgets/timeline/` - Timeline widget komponente (Timeline Booking Block, Timeline Booking Stacker, itd.)
  - `presentation/state/` - Local state management (Price Calendar State, itd.)
  - `presentation/utils/` - Utility helper-i (Scroll Direction Tracker, itd.)
  - `presentation/providers/` - State management provider-i
  - `domain/models/` - Domain model-i (Analytics, Bookings, Calendar, iCal, Notifications, itd.)
- `lib/core/services/` - Core servisi (Currency, Email, iCal, Geolocation, itd.)
- `lib/core/utils/` - Core utility helper-i (Platform, Responsive, Validators, itd.)
- `lib/core/config/` - Router konfiguracija
- `lib/core/accessibility/` - Accessibility helper-i

---

## 🔴 Kritični Problemi

### 1. ~~Memory Leaks - Timer-i i Stream Subscription-ovi~~ ✅ VERIFIED OK

**Status:** VERIFIED (2025-12-15) - Svi Timer-ovi pravilno se dispose-uju

**Lokacija (verified):**
- `lib/features/owner_dashboard/presentation/screens/owner_bookings_screen.dart` - `_initialBookingCheckTimer?.cancel()` ✅
- `lib/features/owner_dashboard/presentation/widgets/timeline_calendar_widget.dart` - sve 3 Timer-a ✅
- `lib/features/owner_dashboard/presentation/screens/property_form_screen.dart` - `_subdomainDebounceTimer?.cancel()` ✅

**Verifikacija:**
- ✅ `owner_bookings_screen.dart`: Timer `_initialBookingCheckTimer` pravilno se cancela u `dispose()` (linija 199)
- ✅ `timeline_calendar_widget.dart`: Sva 3 timer-a (`_visibleRangeDebounceTimer`, `_verticalScrollThrottleTimer`, `_horizontalScrollThrottleTimer`) pravilno se dispose-uju (linije 500-502)
- ✅ `property_form_screen.dart`: Timer `_subdomainDebounceTimer` pravilno se cancela (linija 102)
- ⚠️ `owner_timeline_calendar_screen.dart`: Ne koristi Timer-e (lažna dojava u originalnom bug reportu)

**Napomena:** Originalni bug report spominjao `_scrollDebounceTimer` koji ne postoji u kodu.

---

### 2. ~~Race Conditions u Booking Dialog Logici~~ ⚠️ DEFENDED (Low Priority Refactor)

**Status:** DEFENDED (2025-12-15) - Race conditions su aktivno spriječene kroz multiple flag checks

**Lokacija:**
- `lib/features/owner_dashboard/presentation/screens/owner_bookings_screen.dart` (linije 280-420)

**Analiza:**
Kod koristi 5 flag-ova za zaštitu od race conditions:
- `_hasHandledInitialBooking` - primarni guard
- `_dialogShownForBooking` - sprječava višestruko prikazivanje dialoga
- `_bookingCheckScheduled` - sprječava višestruke addPostFrameCallback pozive
- `_isLoadingInitialBooking` - sprječava race condition tijekom loadinga
- `_handledBookingId` - prati koji booking je već obrađen

**Verifikacija zaštitnih mehanizama:**
- ✅ Linija 291-299: Kombinacija svih flag-ova sprječava višestruke trigger-e
- ✅ Linija 305: `mounted` + `context.mounted` + flag checks prije obrade
- ✅ Linija 316-318: Atomsko postavljanje flag-ova odmah po pronalasku bookinga
- ✅ Linija 348-350: Guard prije prikazivanja dialoga
- ✅ Linija 369-377: Reset svih flag-ova u success path
- ✅ Linija 405-415: Reset flag-ova u error path

**Zaključak:**
Race conditions su aktivno spriječene. Kod je kompleksan ali funkcionalan. Nema hitne potrebe za refaktoringom - koristiti originalni Completer pattern samo ako se pojave problemi u produkciji.

**Buduća preporuka (low priority):**
```dart
// Opcioni refaktoring za smanjenje broja flag-ova
Completer<void>? _bookingDialogCompleter;
```

---

### 3. ~~Hardcoded Debug Log Paths~~ ✅ RESOLVED

**Status:** FIXED (2025-12-15)

**Lokacija (fixed):**
- `lib/features/owner_dashboard/presentation/screens/owner_bookings_screen.dart`
- `lib/features/owner_dashboard/presentation/widgets/booking_details_dialog.dart`
- `lib/features/owner_dashboard/presentation/providers/owner_bookings_provider.dart`

**Problem (resolved):**
- ~~Hardcoded putanje do debug log fajlova (`/Users/duskolicanin/git/bookbed/.cursor/debug.log`)~~
- ~~Neće raditi na drugim sistemima ili u produkciji~~
- ~~Potencijalni security issue ako se koristi u produkciji~~

**Rješenje:**
- Uklonjeni svi `dart:io` i `dart:convert` importi vezani za debug logging
- Uklonjene sve `_log()` metode sa hardcoded putanjama
- Uklonjeni svi `#region agent log` blokovi koji su pisali u lokalne fajlove
- Aplikacija sada koristi isključivo `LoggingService` za logging

---

## 🟡 Srednji Problemi

### 4. ~~Nedostaju Error Boundary-i~~ ✅ IMPLEMENTIRANO

**Status:** ✅ IMPLEMENTIRANO (2025-12-16)

**Lokacija implementacije:** `lib/main.dart` (linije 66-151)

**Implementacija:**
- ✅ `FlutterError.onError` handler u release mode
- ✅ `ErrorWidget.builder` za graceful error display
- ✅ Firebase Crashlytics integracija za mobile
- ✅ `GlobalErrorHandler.initialize()` za debug mode

**Vidi:** [BUG_FIX_MASTER_PLAN.md](../plans/BUG_FIX_MASTER_PLAN.md#11-error-boundaries-bug-4--implementirano)

---

### 5. ~~Nedostaju Timeout-ovi na Async Operacijama~~ ✅ IMPLEMENTIRANO

**Status:** ✅ IMPLEMENTIRANO (2025-12-16)

**Lokacija implementacije:**
- `lib/core/constants/timeout_constants.dart` - Standardizirani timeout-ovi
- `lib/core/utils/async_utils.dart` - FutureTimeoutExtension, StreamTimeoutExtension

**Implementacija:**
- ✅ `TimeoutConstants` klasa sa svim standardnim timeout-ovima
- ✅ `FutureTimeoutExtension` sa metodama: `withFirestoreTimeout()`, `withHttpTimeout()`, `withCloudFunctionTimeout()`, itd.
- ✅ `StreamTimeoutExtension` za real-time listenere

**Vidi:** [BUG_FIX_MASTER_PLAN.md](../plans/BUG_FIX_MASTER_PLAN.md#12-async-timeout-ovi-bug-5--implementirano)

---

### 6. Provider State Management - Nedostaju autoDispose Flag-ovi

**Lokacija:**
- `lib/features/owner_dashboard/presentation/providers/`

**Problem:**
- Neki provider-i nemaju `autoDispose` flag, što može dovesti do memory leak-a
- State se zadržava i nakon što widget više nije u upotrebi

**Preporuka:**
- Proveriti sve provider-e i dodati `autoDispose: true` gde je to moguće
- Zadržati `keepAlive: true` samo za provider-e koji se često koriste (npr. cached data)

**Primer:**
```dart
// ❌ Loše - state se zadržava
@riverpod
class MyNotifier extends _$MyNotifier { ... }

// ✅ Dobro - state se automatski briše
@Riverpod(keepAlive: false)
class MyNotifier extends _$MyNotifier { ... }
```

---

### 7. Nedostaju Accessibility Labels

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/`
- `lib/features/owner_dashboard/presentation/screens/`

**Problem:**
- Mnogi widget-i nemaju `semanticLabel` ili `tooltip`
- Screen reader-i ne mogu pravilno da interpretiraju UI elemente
- Loša accessibility za korisnike sa invaliditetom

**Preporuka:**
- Koristiti `AccessibleIconButton`, `AccessibleInkWell` iz `core/accessibility/accessibility_helpers.dart`
- Dodati `Semantics` widget gde je potrebno
- Dodati `tooltip` na sve interaktivne elemente

**Primer:**
```dart
// ❌ Loše
IconButton(
  icon: Icon(Icons.delete),
  onPressed: () => delete(),
)

// ✅ Dobro
AccessibleIconButton(
  icon: Icons.delete,
  semanticLabel: 'Delete booking',
  tooltip: 'Delete booking',
  onPressed: () => delete(),
)
```

---

## 🟢 Manji Problemi / Code Quality

### 8. TODO Komentari Koji Treba Implementirati

**Lokacija:**
- `lib/features/owner_dashboard/presentation/providers/platform_connections_provider.dart` (linija 131)
- `lib/features/owner_dashboard/presentation/services/overbooking_notification_service.dart` (linije 28, 34, 40)

**Problem:**
- Postoje TODO komentari koji ukazuju na nedovršenu funkcionalnost
- Email i push notifikacije za overbooking nisu implementirane

**Preporuka:**
- Implementirati nedostajuću funkcionalnost ili dodati u backlog
- Ako je funkcionalnost namerno odložena, dodati `@Deprecated` ili `@Unimplemented` anotaciju

---

### 9. Nedostaju Lokalizacije

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/calendar/booking_action_menu.dart` (linije 316, 356, 391, 396)

**Problem:**
- Hardcoded string-ovi na srpskom/hrvatskom umesto lokalizovanih string-ova
- Komentari ukazuju na `// TODO: localize`

**Preporuka:**
- Dodati sve string-ove u `lib/l10n/app_en.arb` i `lib/l10n/app_hr.arb`
- Zameniti hardcoded string-ove sa `AppLocalizations.of(context).xxx`

---

### 10. Performance - Nedostaju RepaintBoundary Widget-i

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/`

**Problem:**
- Neki kompleksni widget-i nisu obavijeni sa `RepaintBoundary`
- To može dovesti do nepotrebnih repaint-ova i lošijih performansi

**Preporuka:**
- Dodati `RepaintBoundary` oko kompleksnih widget-a koji se često rebuild-uju
- Posebno važno za booking card-ove, calendar cell-ove, i stat card-ove

**Primer:**
```dart
RepaintBoundary(
  child: BookingCard(ownerBooking: booking),
)
```

---

### 11. Duplikacija Koda - Error Handling

**Lokacija:**
- Više fajlova u `lib/features/owner_dashboard/presentation/`

**Problem:**
- Isti error handling pattern se ponavlja na više mesta
- `if (mounted) { ErrorDisplayUtils.showErrorSnackBar(...) }` se ponavlja

**Preporuka:**
- Kreirati helper metodu ili extension za error handling
- Koristiti `AsyncValue.when()` za konzistentan error handling

**Primer:**
```dart
extension ErrorHandlingExtension on BuildContext {
  void showErrorIfMounted(dynamic error, {String? userMessage}) {
    if (mounted) {
      ErrorDisplayUtils.showErrorSnackBar(this, error, userMessage: userMessage);
    }
  }
}
```

---

### 12. Router - Kompleksna Redirect Logika

**Lokacija:**
- `lib/core/config/router_owner.dart` (linije 128-232)

**Problem:**
- Vrlo kompleksna `redirect` funkcija sa mnogo uslova
- Teško za održavanje i debug-ovanje
- Potencijalni edge case-ovi koji nisu pokriveni

**Preporuka:**
- Refaktorisati u manje, testabilne funkcije
- Dodati unit test-ove za redirect logiku
- Dodati detaljnije logging za svaki redirect scenario

**Primer:**
```dart
String? _handleRootRedirect(bool isAuthenticated, bool isLoading) {
  if (isAuthenticated) return OwnerRoutes.overview;
  if (!isLoading) return OwnerRoutes.login;
  return null; // Wait for auth to complete
}

String? _handlePublicRoute(String matchedLocation, bool hasWidgetParams) {
  if (matchedLocation.startsWith('/embed/')) return null;
  if (matchedLocation.startsWith('/booking')) return null;
  // ... etc
}
```

---

## 📊 Prioriteti za Rešavanje

### Visok Prioritet (Kritično)
1. ✅ Memory leaks - Timer-i i Stream subscription-ovi
2. ✅ Race conditions u booking dialog logici
3. ✅ Hardcoded debug log paths
13. ✅ Currency Service - Hardcoded exchange rates
14. ✅ Email Notification Service - Nedostaju retry i rate limiting
15. ✅ External Calendar Sync Service - Placeholder implementacije
27. ✅ Analytics Summary - Nedostaju validacije i edge case handling
28. ✅ Bookings View Mode - Hardcoded display names
31. ✅ iCal Feed - Hardcoded string-ovi i nedostaje lokalizacija
35. ✅ Notification Settings Screen - Nedostaju optimistic updates i error recovery
39. ✅ Property Form Screen - Kompleksna logika, performance problemi i potencijalni memory leaks
40. ✅ Stripe Connect Setup Screen - Nedostaju timeout-ovi i error recovery
41. ✅ Unified Unit Hub Screen - FROZEN, kompleksna logika i potencijalni performance problemi
42. ✅ Price Calendar State - Nedostaje memory management i cache size limit
45. ✅ Booking Details Dialog - Hardcoded debug log paths i potencijalni memory leaks
47. ✅ Edit Booking Dialog - Nedostaju timeout-ovi i potencijalni race conditions
48. ✅ Embed Code Generator Dialog - Hardcoded URL-ovi i nedostaju validacije
55. ✅ Booking Drop Zone - Hardcoded string-ovi i potencijalni performance problemi
57. ✅ Timeline Booking Stacker - Kompleksna logika i potencijalni edge cases

### Srednji Prioritet (Važno)
4. ✅ Error boundary-i
5. ✅ Timeout-ovi na async operacijama
6. ✅ Provider autoDispose flag-ovi
7. ✅ Accessibility labels
16. ✅ iCal Export Service - Nedostaje error handling i retry
17. ✅ iCal Generator - Hardcoded timezone i nedostaje validacija
18. ✅ IP Geolocation Service - Nedostaje caching i rate limiting
19. ✅ HTTP Client Resource Management
20. ✅ Platform Utils - Nedostaje error handling za platform detection
21. ✅ Profile Validators - Hardcoded error messages i nedostaje lokalizacija
22. ✅ Responsive Breakpoints - Duplikacija i konfuzija breakpoint vrednosti
23. ✅ Responsive Builder - Potencijalni performance problemi
24. ✅ Responsive Dialog Utils - Hardcoded vrednosti i nedostaje validacija
25. ✅ Responsive Spacing Helper - Kompleksna logika i potencijalni performance problemi
27. ✅ Analytics Summary - Nedostaju validacije i edge case handling
28. ✅ Bookings View Mode - Hardcoded display names
29. ✅ Calendar Filter Options - Nedostaju validacije i edge cases
30. ✅ Date Range Selection - Kompleksna logika i potencijalni edge cases
31. ✅ iCal Feed - Hardcoded string-ovi i nedostaje lokalizacija
32. ✅ Notification Model - Nedostaju validacije i error handling
33. ✅ Onboarding State - Nedostaju validacije i error handling
34. ✅ Windowed Bookings State - Kompleksna logika i potencijalni race conditions
36. ✅ Notifications Screen - Kompleksna selection mode logika i potencijalni memory leaks
38. ✅ Profile Screen - Nedostaju error handling-i i optimizacije
43. ✅ Scroll Direction Tracker - Nedostaju edge case handling-i
44. ✅ Booking Create Dialog - Kompleksna validacija i potencijalni race conditions
50. ✅ Onboarding Property Step - Nedostaju validacije i auto-save issues
51. ✅ Owner App Drawer - Nedostaju error handling-i i optimizacije
52. ✅ Booking Action Menu - Hardcoded string-ovi i nedostaju timeout-ovi
53. ✅ Booking Block Widget - Hardcoded string-ovi i hardcoded locale
54. ✅ Booking Context Menu - Hardcoded string-ovi i hardcoded menu dimensions
56. ✅ Timeline Booking Block - Nedostaju accessibility labels i hardcoded vrednosti

### Nizak Prioritet (Poboljšanja)
8. ✅ TODO komentari
9. ✅ Lokalizacije
37. ✅ Overview Screen - Wrapper screen (nema problema)
46. ✅ Dashboard Stats Skeleton - DEPRECATED widget (nema problema)
49. ✅ Language Selection Bottom Sheet - Hardcoded string-ovi
10. ✅ RepaintBoundary widget-i
11. ✅ Duplikacija koda
12. ✅ Router refactoring
26. ✅ Responsive Utils - Nedostaje dokumentacija i primeri

---

## 🛠️ Preporučeni Alati za Debug-ovanje

1. **Flutter DevTools** - Za memory leak detection
2. **Riverpod Inspector** - Za provider state debugging
3. **Sentry** - Za error tracking u produkciji
4. **Flutter Performance Overlay** - Za performance profiling

---

## 📝 Checklist za Code Review

Kada review-ujete kod u Owner Dashboard modulu i Core Services, proverite:

### Owner Dashboard
- [ ] Da li svi Timer-ovi imaju `cancel()` u dispose?
- [ ] Da li svi Stream subscription-ovi imaju `cancel()`?
- [ ] Da li postoje timeout-ovi na async operacijama?
- [ ] Da li su svi error-i pravilno handle-ovani?
- [ ] Da li postoje accessibility labels na interaktivnim elementima?
- [ ] Da li su svi string-ovi lokalizovani?
- [ ] Da li postoje `RepaintBoundary` widget-i gde je potrebno?
- [ ] Da li provider-i imaju `autoDispose` gde je to moguće?
- [ ] Da li postoje unit test-ovi za kritičnu logiku?
- [ ] Da li postoje optimistic updates za instant UI feedback?
- [ ] Da li postoje retry mehanizmi za failed operacije?
- [ ] Da li se svi AnimationController-i dispose-uju pravilno?
- [ ] Da li postoje optimizacije za velike liste (virtual scrolling)?
- [ ] Da li postoje timeout-ovi na Cloud Functions pozivima?
- [ ] Da li postoje hardcoded debug log paths koji treba ukloniti?
- [ ] Da li postoje hardcoded URL-ovi koji treba konfigurisati?
- [ ] Da li postoje DEPRECATED widget-i koji treba ukloniti?
- [ ] Da li postoje cache-ovi sa size limit-ima?
- [ ] Da li postoje debounce mehanizmi za auto-save operacije?
- [ ] Da li postoje hardcoded locale vrednosti umesto dinamičkog locale-a?
- [ ] Da li postoje optimizacije za drag & drop operacije (debounce, throttle)?
- [ ] Da li postoje RepaintBoundary widget-i za performance optimizacije?

### Core Services
- [ ] Da li HTTP client-i imaju proper dispose/close?
- [ ] Da li postoje retry mehanizmi za failed API pozive?
- [ ] Da li postoje timeout-ovi na svim HTTP pozivima?
- [ ] Da li postoje caching mehanizmi gde je to potrebno?
- [ ] Da li postoje rate limiting mehanizmi?
- [ ] Da li su hardcoded vrednosti (timezone, exchange rates) konfigurabilne?
- [ ] Da li postoje validacije input-a pre obrade?
- [ ] Da li postoje error handling za batch operations?

### Core Utils
- [ ] Da li platform detection ima error handling?
- [ ] Da li su svi error message-i lokalizovani?
- [ ] Da li postoje duplikacije breakpoint konstanti?
- [ ] Da li responsive widget-i imaju performance optimizacije?
- [ ] Da li postoje validacije za responsive helper parametre?
- [ ] Da li postoji dokumentacija za responsive utilities?

### Domain Models
- [ ] Da li svi model-i imaju validacije za required polja?
- [ ] Da li postoje error handling-i za Firestore parsing?
- [ ] Da li su svi display name-ovi lokalizovani?
- [ ] Da li postoje validacije za edge case-ove (negativne vrednosti, overflow, itd.)?
- [ ] Da li postoje unit test-ovi za kompleksnu logiku (date ranges, windowing)?
- [ ] Da li su hardcoded string-ovi zamenjeni sa lokalizacijama?

---

## 🔧 Core Services - Analiza Problema

### 13. Currency Service - Hardcoded Exchange Rates

**Lokacija:**
- `lib/core/services/currency_service.dart`

**Problem:**
- Exchange rates su hardcoded u enum-u (linije 27-30)
- Rates se ne ažuriraju automatski - mogu biti zastareli
- Nema mehanizma za ažuriranje kursa iz external API-ja
- Fallback logika za SharedPreferences može biti problematična (linije 70-78)

**Preporuka:**
- Implementirati servis za fetch-ovanje exchange rates iz external API-ja (npr. ExchangeRate-API, Fixer.io)
- Dodati cache mehanizam sa TTL (Time To Live)
- Dodati fallback na hardcoded rates ako API fail-uje
- Razmotriti korišćenje `package:exchange_rates` ili sličnog paketa

**Primer:**
```dart
@riverpod
Future<Map<Currency, double>> exchangeRates(Ref ref) async {
  try {
    // Fetch from API with cache
    final cached = await _getCachedRates();
    if (cached != null && !_isExpired(cached)) {
      return cached.rates;
    }
    
    final rates = await _fetchRatesFromAPI();
    await _cacheRates(rates);
    return rates;
  } catch (e) {
    // Fallback to hardcoded rates
    return _getDefaultRates();
  }
}
```

---

### 14. Email Notification Service - Nedostaju Retry i Rate Limiting

**Lokacija:**
- `lib/core/services/email_notification_service.dart`

**Problem:**
- Nema retry mehanizma za failed email-ove (linije 98-104, 160-166, 224-230)
- Nema rate limiting za Resend API pozive
- Hardcoded email subject-ovi na hrvatskom (linije 71, 138, 200)
- HTTP client se ne uvek dispose-uje pravilno
- Nema queue mehanizma za email-ove

**Preporuka:**
- Implementirati retry mehanizam sa exponential backoff
- Dodati rate limiting (Resend ima rate limits)
- Lokalizovati email subject-ove
- Implementirati email queue za batch sending
- Dodati timeout na HTTP pozive

**Primer:**
```dart
Future<void> _sendEmailWithRetry({...}) async {
  int attempts = 0;
  const maxAttempts = 3;
  
  while (attempts < maxAttempts) {
    try {
      await _sendEmail(...);
      return; // Success
    } catch (e) {
      attempts++;
      if (attempts >= maxAttempts) {
        await LoggingService.logError('Email send failed after $maxAttempts attempts', e);
        throw e;
      }
      // Exponential backoff
      await Future.delayed(Duration(seconds: pow(2, attempts).toInt()));
    }
  }
}
```

---

### 15. External Calendar Sync Service - Placeholder Implementacije

**Lokacija:**
- `lib/core/services/external_calendar_sync_service.dart`

**Problem:**
- Booking.com i Airbnb sync metode su placeholder-i (linije 124-199, 208-283)
- OAuth URL-ovi su placeholder-i i možda nisu tačni (linije 345-390)
- Nema error handling za batch operations (linija 292-325)
- Nema timeout-ova na HTTP pozivima
- Nema validacije za OAuth token exchange

**Preporuka:**
- Implementirati stvarne API integracije kada budu dostupne
- Dodati timeout-ove na sve HTTP pozive
- Implementirati proper error handling za batch operations
- Dodati validaciju za OAuth flow
- Razmotriti korišćenje Cloud Functions za periodic sync

**Primer:**
```dart
Future<List<BookingModel>> _syncBookingCom({...}) async {
  try {
    final response = await _httpClient.get(
      Uri.parse(url),
      headers: {...},
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Booking.com API request timed out');
      },
    );
    
    if (response.statusCode != 200) {
      throw IntegrationException('Booking.com API error: ${response.statusCode}');
    }
    
    // Parse and return bookings
  } catch (e) {
    await LoggingService.logError('Booking.com sync failed', e);
    return []; // Return empty list instead of throwing
  }
}
```

---

### 16. iCal Export Service - Nedostaje Error Handling i Retry

**Lokacija:**
- `lib/core/services/ical_export_service.dart`

**Problem:**
- Nema retry mehanizma za failed storage operations (linije 172-204)
- Potencijalni memory leak ako se generiše veoma veliki iCal fajl (svi booking-i u memoriji)
- Nema validacije za storage path
- Nema rate limiting za storage uploads

**Preporuka:**
- Implementirati retry mehanizam za storage operations
- Razmotriti streaming za velike iCal fajlove umesto buffering-a u memoriji
- Dodati validaciju za storage path
- Implementirati batch processing za velike brojeve booking-a

**Primer:**
```dart
Future<String> _uploadToStorageWithRetry({...}) async {
  int attempts = 0;
  const maxAttempts = 3;
  
  while (attempts < maxAttempts) {
    try {
      return await _uploadToStorage(...);
    } catch (e) {
      attempts++;
      if (attempts >= maxAttempts) {
        rethrow;
      }
      await Future.delayed(Duration(seconds: attempts));
    }
  }
  throw Exception('Upload failed after $maxAttempts attempts');
}
```

---

### 17. iCal Generator - Hardcoded Timezone i Nedostaje Validacija

**Lokacija:**
- `lib/core/services/ical_generator.dart`

**Problem:**
- Hardcoded timezone `Europe/Zagreb` (linija 29)
- Nema validacije input-a (booking, unit)
- Escape funkcija može imati probleme sa edge case-ovima (linija 199)
- Nema handling za null vrednosti u booking model-u

**Preporuka:**
- Dodati timezone kao parametar ili izvući iz unit/property settings
- Dodati validaciju input-a pre generisanja
- Poboljšati escape funkciju za sve edge case-ove
- Dodati null-safety checks

**Primer:**
```dart
static String generateUnitCalendar({
  required UnitModel unit,
  required List<BookingModel> bookings,
  String? timezone,
}) {
  // Validate inputs
  if (bookings.isEmpty) {
    throw ArgumentError('Bookings list cannot be empty');
  }
  
  final tz = timezone ?? unit.timezone ?? 'Europe/Zagreb';
  
  // ... rest of generation
}
```

---

### 18. IP Geolocation Service - Nedostaje Caching i Rate Limiting

**Lokacija:**
- `lib/core/services/ip_geolocation_service.dart`

**Problem:**
- Nema caching mehanizma - svaki poziv ide na API
- Nema rate limiting - može doći do prekoračenja free tier limita
- Može biti sporo ako svi provider-i fail-uju (linije 76-93)
- Nema timeout na provider level-u (samo na HTTP level-u)

**Preporuka:**
- Implementirati caching sa TTL (IP se ne menja često)
- Dodati rate limiting per provider
- Optimizovati fallback mehanizam
- Dodati circuit breaker pattern za failed provider-e

**Primer:**
```dart
class IpGeolocationService {
  final Map<String, CachedResult> _cache = {};
  static const cacheTTL = Duration(hours: 24);
  
  Future<GeoLocationResult?> getGeolocation(String? ipAddress) async {
    // Check cache first
    final cacheKey = ipAddress ?? 'current';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.result;
    }
    
    // Try providers with rate limiting
    final result = await _tryProviders(ipAddress);
    
    // Cache result
    if (result != null) {
      _cache[cacheKey] = CachedResult(result, DateTime.now());
    }
    
    return result;
  }
}
```

---

### 19. HTTP Client Resource Management

**Lokacija:**
- `lib/core/services/email_notification_service.dart`
- `lib/core/services/external_calendar_sync_service.dart`
- `lib/core/services/ip_geolocation_service.dart`

**Problem:**
- HTTP client-i se kreiraju ali se ne uvek dispose-uju pravilno
- Nema shared HTTP client instance (kreira se novi za svaki servis)
- Potencijalni connection leak ako se servis ne dispose-uje

**Preporuka:**
- Koristiti dependency injection za HTTP client
- Implementirati shared HTTP client sa connection pooling
- Osigurati da se svi client-i dispose-uju u `dispose()` metodi
- Razmotriti korišćenje `package:http` sa `IOClient` za bolje resource management

**Primer:**
```dart
// Shared HTTP client provider
@riverpod
http.Client httpClient(Ref ref) {
  final client = http.IOClient();
  ref.onDispose(() => client.close());
  return client;
}

// Use in services
class EmailNotificationService {
  final http.Client _httpClient;
  
  EmailNotificationService({required http.Client httpClient})
    : _httpClient = httpClient;
  
  // No need for dispose() - handled by provider
}
```

---

## 📊 Prioriteti za Rešavanje - Core Services

### Visok Prioritet (Kritično)
13. ✅ Currency Service - Hardcoded exchange rates
14. ✅ Email Notification Service - Nedostaju retry i rate limiting
15. ✅ External Calendar Sync Service - Placeholder implementacije

### Srednji Prioritet (Važno)
16. ✅ iCal Export Service - Nedostaje error handling i retry
17. ✅ iCal Generator - Hardcoded timezone i nedostaje validacija
18. ✅ IP Geolocation Service - Nedostaje caching i rate limiting
19. ✅ HTTP Client Resource Management

---

## 📊 Prioriteti za Rešavanje - Core Utils

### Visok Prioritet (Kritično)
20. ✅ Platform Utils - Nedostaje error handling za platform detection
21. ✅ Profile Validators - Hardcoded error messages i nedostaje lokalizacija

### Srednji Prioritet (Važno)
22. ✅ Responsive Breakpoints - Duplikacija i konfuzija breakpoint vrednosti
23. ✅ Responsive Builder - Potencijalni performance problemi
24. ✅ Responsive Dialog Utils - Hardcoded vrednosti i nedostaje validacija
25. ✅ Responsive Spacing Helper - Kompleksna logika i potencijalni performance problemi

### Nizak Prioritet (Poboljšanja)
26. ✅ Responsive Utils - Nedostaje dokumentacija i primeri

---

## 🛠️ Core Utils - Analiza Problema

### 20. Platform Utils - Nedostaje Error Handling za Platform Detection

**Lokacija:**
- `lib/core/utils/platform_utils.dart`

**Problem:**
- Platform detection može fail-ovati na web-u ako se `Platform` klasa pozove (linije 19-31)
- Nema try-catch blokova za platform detection
- Hardcoded string-ovi u dialog-ima (linije 136-186)
- Nema lokalizacije za dialog tekstove

**Preporuka:**
- Dodati try-catch blokove oko `Platform` poziva
- Koristiti `kIsWeb` check pre poziva `Platform` klasa
- Lokalizovati sve string-ove u dialog-ima
- Dodati fallback vrednosti ako platform detection fail-uje

**Primer:**
```dart
static bool get isIOS {
  if (kIsWeb) return false;
  try {
    return Platform.isIOS;
  } catch (e) {
    LoggingService.logWarning('Platform detection failed: $e');
    return false; // Safe fallback
  }
}
```

---

### 21. Profile Validators - Hardcoded Error Messages i Nedostaje Lokalizacija

**Lokacija:**
- `lib/core/utils/profile_validators.dart`

**Problem:**
- Svi error message-i su hardcoded na engleskom (linije 10, 15, 19, 30, 36, itd.)
- Nema lokalizacije - korisnici neće videti poruke na svom jeziku
- Validacija za IBAN i SWIFT je pojednostavljena - ne proverava checksum
- Email regex možda nije potpuno RFC 5322 compliant (linija 33)

**Preporuka:**
- Dodati lokalizaciju za sve error message-e
- Koristiti `AppLocalizations` umesto hardcoded string-ova
- Razmotriti korišćenje `package:email_validator` za bolju email validaciju
- Implementirati proper IBAN checksum validaciju (modulo 97)
- Dodati SWIFT format validaciju (4 letters, 2 letters, 2 alphanumeric, 3 optional)

**Primer:**
```dart
static String? validateEmail(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) {
    return l10n.validationEmailRequired;
  }
  
  // Use proper email validator package
  if (!EmailValidator.validate(value.trim())) {
    return l10n.validationEmailInvalid;
  }
  
  return null;
}
```

---

### 22. Responsive Breakpoints - Duplikacija i Konfuzija Breakpoint Vrednosti

**Lokacija:**
- `lib/core/utils/responsive_breakpoints.dart`
- `lib/core/utils/responsive_builder.dart`
- `lib/core/constants/breakpoints.dart`
- `lib/core/constants/app_dimensions.dart`

**Problem:**
- Postoji više fajlova sa breakpoint konstantama koje se možda razlikuju
- `ResponsiveBreakpoints` koristi različite vrednosti od `Breakpoints` klase
- Može doći do konfuzije koji breakpoint sistem koristiti
- Nema single source of truth za breakpoint vrednosti

**Preporuka:**
- Konsolidovati sve breakpoint vrednosti u jedan fajl
- Koristiti jedan sistem breakpoint-a kroz celu aplikaciju
- Dodati dokumentaciju koje breakpoint-e koristiti i kada
- Razmotriti kreiranje `BreakpointConstants` klase kao single source of truth

**Primer:**
```dart
// Single source of truth
class BreakpointConstants {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;
  
  // Use these everywhere instead of duplicating
}
```

---

### 23. Responsive Builder - Potencijalni Performance Problemi

**Lokacija:**
- `lib/core/utils/responsive_builder.dart`

**Problem:**
- `LayoutBuilder` se rebuild-uje na svaku promenu constraints (linija 33)
- Može dovesti do nepotrebnih rebuild-ova widget-a
- Nema memoization za calculated values
- `ResponsiveGrid` koristi `GridView.builder` ali nema `shrinkWrap` ili `physics` optimizacije

**Preporuka:**
- Dodati `const` konstruktore gde je moguće
- Razmotriti korišćenje `MediaQuery` umesto `LayoutBuilder` za jednostavnije slučajeve
- Dodati `RepaintBoundary` oko kompleksnih responsive widget-a
- Optimizovati `ResponsiveGrid` sa proper `shrinkWrap` i `physics` settings

**Primer:**
```dart
@override
Widget build(BuildContext context) {
  // Use MediaQuery for simple cases - more efficient
  final width = MediaQuery.of(context).size.width;
  
  if (width >= AppDimensions.desktop) {
    return largeDesktop ?? desktop ?? tablet ?? mobile ?? defaultWidget;
  }
  // ... rest
}
```

---

### 24. Responsive Dialog Utils - Hardcoded Vrednosti i Nedostaje Validacija

**Lokacija:**
- `lib/core/utils/responsive_dialog_utils.dart`

**Problem:**
- Hardcoded breakpoint vrednosti (400, 600, 1024) umesto korišćenja konstanti (linije 21-33)
- Nema validacije za min/max width parametre
- Nema dokumentacije za kada koristiti koje procente
- Može doći do nekonzistentnih dialog veličina ako se koriste različite helper metode

**Preporuka:**
- Koristiti breakpoint konstante umesto hardcoded vrednosti
- Dodati validaciju za min/max width (min mora biti < max)
- Dodati dokumentaciju sa primerima korišćenja
- Razmotriti kreiranje `DialogSizeConfig` klase za konzistentnost

**Primer:**
```dart
static double getDialogWidth(
  BuildContext context, {
  double verySmallMobilePercent = 0.9,
  double mobilePercent = 0.9,
  double tabletPercent = 0.8,
  double desktopPercent = 0.6,
  double minWidth = 500.0,
  double maxWidth = 600.0,
}) {
  // Validate parameters
  assert(minWidth < maxWidth, 'minWidth must be less than maxWidth');
  assert(verySmallMobilePercent > 0 && verySmallMobilePercent <= 1, 'Percent must be between 0 and 1');
  
  final screenWidth = MediaQuery.of(context).size.width;
  
  // Use constants instead of hardcoded values
  if (screenWidth < ResponsiveBreakpoints.verySmallWidth) {
    return screenWidth * verySmallMobilePercent;
  } else if (screenWidth < ResponsiveBreakpoints.mobileMaxWidth) {
    // ... rest
  }
}
```

---

### 25. Responsive Spacing Helper - Kompleksna Logika i Potencijalni Performance Problemi

**Lokacija:**
- `lib/core/utils/responsive_spacing_helper.dart`

**Problem:**
- `getScreenType` se poziva više puta u istom build ciklusu (linija 54)
- Kompleksna switch logika u svakoj metodi - može biti sporo
- Nema caching za calculated screen type
- Hardcoded vrednosti umesto korišćenja design tokens

**Preporuka:**
- Cache-ovati `screenType` rezultat u `BuildContext` extension-u
- Koristiti design tokens umesto hardcoded vrednosti
- Optimizovati switch expression-e
- Razmotriti kreiranje `SpacingConfig` klase za centralizovano upravljanje

**Primer:**
```dart
// Cache screen type in context
extension ResponsiveSpacingContext on BuildContext {
  ScreenType? _cachedScreenType;
  DateTime? _cacheTimestamp;
  
  ScreenType get screenType {
    final now = DateTime.now();
    if (_cachedScreenType != null && 
        _cacheTimestamp != null && 
        now.difference(_cacheTimestamp!) < Duration(milliseconds: 100)) {
      return _cachedScreenType!;
    }
    
    _cachedScreenType = ResponsiveSpacingHelper.getScreenType(this);
    _cacheTimestamp = now;
    return _cachedScreenType!;
  }
}
```

---

### 26. Responsive Utils - Nedostaje Dokumentacija i Primeri

**Lokacija:**
- `lib/core/utils/responsive.dart`

**Problem:**
- Fajl je samo export - nema dodatne dokumentacije
- Nema jasnih uputstava kada koristiti koji responsive helper
- Nema primer-a korišćenja u dokumentaciji
- Može doći do konfuzije koji fajl koristiti za šta

**Preporuka:**
- Dodati detaljnu dokumentaciju u export fajl
- Kreirati README sa primerima korišćenja svakog helper-a
- Dodati komentare koji helper koristiti u kojim situacijama
- Razmotriti kreiranje vodiča za responsive design u aplikaciji

**Primer:**
```dart
/// Responsive utilities for adaptive layouts
///
/// ## When to use which helper:
/// 
/// - **Breakpoints**: For simple breakpoint checks (mobile/tablet/desktop)
/// - **ResponsiveBuilder**: For building different widgets per breakpoint
/// - **ResponsiveSpacingHelper**: For spacing, padding, and sizing
/// - **ResponsiveDialogUtils**: For dialog sizing and layout
///
/// ## Examples:
/// 
/// ```dart
/// // Simple breakpoint check
/// if (context.isMobile) { ... }
///
/// // Responsive widget building
/// ResponsiveBuilder(
///   mobile: MobileLayout(),
///   desktop: DesktopLayout(),
/// )
///
/// // Responsive spacing
/// Padding(
///   padding: ResponsiveSpacingHelper.getPagePadding(context),
///   child: ...,
/// )
/// ```
library;
```

---

## 📊 Prioriteti za Rešavanje - Core Utils

### Visok Prioritet (Kritično)
20. ✅ Platform Utils - Nedostaje error handling za platform detection
21. ✅ Profile Validators - Hardcoded error messages i nedostaje lokalizacija

### Srednji Prioritet (Važno)
22. ✅ Responsive Breakpoints - Duplikacija i konfuzija breakpoint vrednosti
23. ✅ Responsive Builder - Potencijalni performance problemi
24. ✅ Responsive Dialog Utils - Hardcoded vrednosti i nedostaje validacija
25. ✅ Responsive Spacing Helper - Kompleksna logika i potencijalni performance problemi

### Nizak Prioritet (Poboljšanja)
26. ✅ Responsive Utils - Nedostaje dokumentacija i primeri

---

## 📦 Domain Models - Analiza Problema

### 27. Analytics Summary - Nedostaju Validacije i Edge Case Handling

**Lokacija:**
- `lib/features/owner_dashboard/domain/models/analytics_summary.dart`

**Problem:**
- Nema validacije za negativne vrednosti (revenue, bookings, occupancy rate)
- `occupancyRate` može biti > 100% što nije validno
- `cancellationRate` može biti > 100% što nije validno
- Nema validacije za prazne liste (revenueHistory, bookingHistory)
- `DateRangeFilter` factory metode mogu imati probleme sa month overflow (linije 94, 100, 103)

**Preporuka:**
- Dodati validacije u freezed model (custom assertions)
- Ograničiti occupancyRate i cancellationRate na 0-100%
- Validirati da revenue i booking vrednosti nisu negativne
- Dodati error handling za date range factory metode

**Primer:**
```dart
@freezed
class AnalyticsSummary with _$AnalyticsSummary {
  const AnalyticsSummary._();
  
  const factory AnalyticsSummary({
    required double totalRevenue,
    required double monthlyRevenue,
    // ... other fields
    required double occupancyRate,
    required double cancellationRate,
  }) = _AnalyticsSummary;
  
  // Custom validation
  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    final summary = _$AnalyticsSummaryFromJson(json);
    return summary.copyWith(
      occupancyRate: summary.occupancyRate.clamp(0.0, 100.0),
      cancellationRate: summary.cancellationRate.clamp(0.0, 100.0),
      totalRevenue: summary.totalRevenue < 0 ? 0.0 : summary.totalRevenue,
      monthlyRevenue: summary.monthlyRevenue < 0 ? 0.0 : summary.monthlyRevenue,
    );
  }
}
```

---

### 28. Bookings View Mode - Hardcoded Display Names

**Lokacija:**
- `lib/features/owner_dashboard/domain/models/bookings_view_mode.dart`

**Problem:**
- Hardcoded display name-ovi na engleskom (linije 11-12)
- Nema lokalizacije - korisnici neće videti tekst na svom jeziku
- `fromString` metoda ima default fallback ali nema logging za invalid vrednosti

**Preporuka:**
- Ukloniti `displayName` getter iz enum-a
- Koristiti `AppLocalizations` za display name-ove
- Dodati logging za invalid vrednosti u `fromString` metodi

**Primer:**
```dart
enum BookingsViewMode {
  card,
  table;
  
  // Remove displayName getter - use AppLocalizations instead
  // String get displayName => ... // REMOVE THIS
  
  static BookingsViewMode fromString(String? value) {
    final result = switch (value) {
      'card' => BookingsViewMode.card,
      'table' => BookingsViewMode.table,
      _ => BookingsViewMode.card,
    };
    
    if (value != null && result == BookingsViewMode.card && value != 'card') {
      LoggingService.logWarning('Invalid BookingsViewMode value: $value');
    }
    
    return result;
  }
}

// Use in UI:
// AppLocalizations.of(context).ownerBookingsCardView
// AppLocalizations.of(context).ownerBookingsTableView
```

---

### 29. Calendar Filter Options - Nedostaju Validacije i Edge Cases

**Lokacija:**
- `lib/features/owner_dashboard/domain/models/calendar_filter_options.dart`

**Problem:**
- Nema validacije da `startDate` nije posle `endDate`
- Nema validacije za prazne string-ove u listama (propertyIds, unitIds)
- `guestSearchQuery` i `bookingIdSearch` mogu biti prazni string-ovi umesto null
- Nema limit-a na broj filtera (može doći do performansi problema sa previše filtera)

**Preporuka:**
- Dodati validaciju da startDate <= endDate
- Filter-ovati prazne string-ove iz listi
- Normalizovati prazne string-ove u null vrednosti
- Dodati limit na broj filtera (npr. max 50 property IDs)

**Primer:**
```dart
extension CalendarFilterOptionsX on CalendarFilterOptions {
  /// Validate filter options
  String? validate() {
    if (startDate != null && endDate != null) {
      if (startDate!.isAfter(endDate!)) {
        return 'Start date must be before end date';
      }
    }
    
    if (propertyIds.length > 50) {
      return 'Too many properties selected (max 50)';
    }
    
    return null; // Valid
  }
  
  /// Normalize filter options (remove empty strings, normalize dates)
  CalendarFilterOptions normalize() {
    return copyWith(
      propertyIds: propertyIds.where((id) => id.isNotEmpty).toList(),
      unitIds: unitIds.where((id) => id.isNotEmpty).toList(),
      statuses: statuses.where((s) => s.isNotEmpty).toList(),
      sources: sources.where((s) => s.isNotEmpty).toList(),
      guestSearchQuery: guestSearchQuery?.isEmpty ?? true ? null : guestSearchQuery?.trim(),
      bookingIdSearch: bookingIdSearch?.isEmpty ?? true ? null : bookingIdSearch?.trim(),
    );
  }
}
```

---

### 30. Date Range Selection - Kompleksna Logika i Potencijalni Edge Cases

**Lokacija:**
- `lib/features/owner_dashboard/domain/models/date_range_selection.dart`

**Problem:**
- `next()` i `previous()` metode imaju kompleksnu logiku za month overflow/underflow (linije 89-143)
- `_getMonday` metoda ne uzima u obzir timezone (linija 55)
- `dates` getter može generisati veliku listu za dugačke range-ove (linije 67-75)
- `toDisplayString` koristi hardcoded month name-ove na engleskom (linije 165-180)
- Nema validacije da startDate <= endDate

**Preporuka:**
- Koristiti `package:intl` za month name-ove umesto hardcoded array-a
- Dodati validaciju da startDate <= endDate
- Optimizovati `dates` getter za velike range-ove (lazy generation)
- Razmotriti korišćenje `package:timezone` za timezone-aware date operations
- Dodati unit test-ove za edge case-ove (month boundaries, leap years)

**Primer:**
```dart
import 'package:intl/intl.dart';

String toDisplayString({required bool isWeek, required Locale locale}) {
  final dateFormat = DateFormat('MMM yyyy', locale.toString());
  
  if (isWeek) {
    // Use intl for formatting
    final startFormatted = DateFormat('d MMM', locale.toString()).format(startDate);
    final endFormatted = DateFormat('d MMM yyyy', locale.toString()).format(endDate);
    return '$startFormatted - $endFormatted';
  } else {
    return dateFormat.format(startDate);
  }
}

/// Lazy date generator for large ranges
Iterable<DateTime> get datesLazy sync* {
  DateTime current = startDate;
  while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
    yield DateTime(current.year, current.month, current.day);
    current = current.add(const Duration(days: 1));
  }
}
```

---

### 31. iCal Feed - Hardcoded String-ovi i Nedostaje Lokalizacija

**Lokacija:**
- `lib/features/owner_dashboard/domain/models/ical_feed.dart`

**Problem:**
- Hardcoded display name-ovi na hrvatskom (linija 19: 'Druga platforma')
- Hardcoded string-ovi u `getTimeSinceLastSync()` metodi (linije 142-155)
- Nema validacije za `icalUrl` format
- `fromFirestore` može fail-ovati ako su required polja null (linije 94-112)
- Nema error handling za invalid Firestore data

**Preporuka:**
- Lokalizovati sve string-ove
- Dodati URL validaciju za `icalUrl`
- Dodati error handling u `fromFirestore` metodi
- Koristiti `AppLocalizations` za time since last sync poruke

**Primer:**
```dart
String getTimeSinceLastSync(AppLocalizations l10n) {
  if (lastSynced == null) return l10n.icalNeverSynced;

  final now = DateTime.now();
  final difference = now.difference(lastSynced!);

  if (difference.inMinutes < 1) {
    return l10n.icalJustNow;
  } else if (difference.inMinutes < 60) {
    return l10n.icalMinutesAgo(difference.inMinutes);
  } else if (difference.inHours < 24) {
    return l10n.icalHoursAgo(difference.inHours);
  } else {
    return l10n.icalDaysAgo(difference.inDays);
  }
}

/// Validate iCal URL
String? validateIcalUrl(String url) {
  try {
    final uri = Uri.parse(url);
    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Invalid URL scheme';
    }
    return null;
  } catch (e) {
    return 'Invalid URL format';
  }
}
```

---

### 32. Notification Model - Nedostaju Validacije i Error Handling

**Lokacija:**
- `lib/features/owner_dashboard/domain/models/notification_model.dart`

**Problem:**
- `fromFirestore` može fail-ovati ako su required polja null (linije 72-88)
- Nema validacije za `title` i `message` (mogu biti prazni)
- `metadata` može sadržati bilo koji JSON - nema validacije strukture
- Nema error handling za invalid Firestore data
- `titleKey` i `messageKey` se ne koriste konzistentno (linije 64-65)

**Preporuka:**
- Dodati validacije za required polja
- Dodati error handling u `fromFirestore` metodi
- Validirati da title i message nisu prazni
- Dokumentovati strukturu metadata objekta
- Implementirati konzistentno korišćenje localization keys

**Primer:**
```dart
factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
  try {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw ArgumentError('Document data is null');
    }
    
    final title = data['title'] as String? ?? '';
    final message = data['message'] as String? ?? '';
    
    if (title.isEmpty && data['titleKey'] == null) {
      throw ArgumentError('Notification must have title or titleKey');
    }
    
    if (message.isEmpty && data['messageKey'] == null) {
      throw ArgumentError('Notification must have message or messageKey');
    }
    
    return NotificationModel(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      type: NotificationType.fromString(data['type'] as String?),
      title: title,
      message: message,
      // ... rest
    );
  } catch (e) {
    LoggingService.logError('Error parsing NotificationModel from Firestore', e);
    rethrow;
  }
}
```

---

### 33. Onboarding State - Nedostaju Validacije i Error Handling

**Lokacija:**
- `lib/features/owner_dashboard/domain/models/onboarding_state.dart`

**Problem:**
- Nema validacije da `currentStep` nije negativan ili veći od maksimalnog broja koraka
- Nema validacije da `completedSteps` ne sadrži duplikate
- Nema validacije da `completedSteps` ne sadrži step-ove veće od maksimalnog broja
- `PropertyFormData`, `UnitFormData`, `PricingFormData` nemaju validacije

**Preporuka:**
- Dodati validacije za step brojeve
- Validirati da completedSteps ne sadrži duplikate
- Dodati validacije za form data (email format, phone format, itd.)
- Implementirati `validate()` metode za sve form data klase

**Primer:**
```dart
extension OnboardingStateX on OnboardingState {
  static const int maxSteps = 3;
  
  String? validate() {
    if (currentStep < 0 || currentStep > maxSteps) {
      return 'Invalid current step: $currentStep';
    }
    
    if (completedSteps.any((step) => step < 0 || step > maxSteps)) {
      return 'Invalid step in completedSteps';
    }
    
    if (completedSteps.length != completedSteps.toSet().length) {
      return 'completedSteps contains duplicates';
    }
    
    // Validate form data if present
    if (propertyData != null) {
      final error = propertyData!.validate();
      if (error != null) return error;
    }
    
    return null; // Valid
  }
}

extension PropertyFormDataX on PropertyFormData {
  String? validate() {
    if (name.trim().isEmpty) return 'Property name is required';
    if (email != null && !ProfileValidators.validateEmail(email) == null) {
      return 'Invalid email format';
    }
    // ... more validations
    return null;
  }
}
```

---

### 34. Windowed Bookings State - Kompleksna Logika i Potencijalni Race Conditions

**Lokacija:**
- `lib/features/owner_dashboard/domain/models/windowed_bookings_state.dart`

**Problem:**
- Kompleksna logika za windowing sa više flag-ova koji mogu biti u nekonzistentnom stanju
- `canLoadTop` i `canLoadBottom` imaju kompleksne uslove (linije 46-51)
- `shouldTrim` logika može dovesti do previše čestog trim-ovanja
- `canTrimNow()` koristi hardcoded 500ms debounce (linija 79)
- Nema validacije da windowSize i pageSize nisu negativni ili preveliki
- Potencijalni race condition između loading flag-ova

**Preporuka:**
- Dodati validacije za windowSize i pageSize
- Razmotriti korišćenje state machine pattern za windowing logiku
- Dodati dokumentaciju za windowing algoritam
- Razmotriti korišćenje `Duration` konstante umesto hardcoded vrednosti
- Dodati unit test-ove za edge case-ove

**Primer:**
```dart
class WindowedBookingsState {
  // Constants
  static const Duration trimDebounceDuration = Duration(milliseconds: 500);
  static const int maxWindowSize = 1000;
  static const int minWindowSize = 5;
  
  const WindowedBookingsState({
    // ... fields
    this.windowSize = 20,
    this.pageSize = 20,
  }) : assert(windowSize >= minWindowSize && windowSize <= maxWindowSize,
         'windowSize must be between $minWindowSize and $maxWindowSize'),
       assert(pageSize >= minWindowSize && pageSize <= maxWindowSize,
         'pageSize must be between $minWindowSize and $maxWindowSize');
  
  /// Can perform trim now (uses constant instead of hardcoded value)
  bool canTrimNow() {
    if (lastTrimTime == null) return true;
    return DateTime.now().difference(lastTrimTime!) > trimDebounceDuration;
  }
}
```

---

## 📊 Prioriteti za Rešavanje - Domain Models

### Visok Prioritet (Kritično)
27. ✅ Analytics Summary - Nedostaju validacije i edge case handling
28. ✅ Bookings View Mode - Hardcoded display names
31. ✅ iCal Feed - Hardcoded string-ovi i nedostaje lokalizacija

### Srednji Prioritet (Važno)
29. ✅ Calendar Filter Options - Nedostaju validacije i edge cases
30. ✅ Date Range Selection - Kompleksna logika i potencijalni edge cases
32. ✅ Notification Model - Nedostaju validacije i error handling
33. ✅ Onboarding State - Nedostaju validacije i error handling
34. ✅ Windowed Bookings State - Kompleksna logika i potencijalni race conditions
36. ✅ Notifications Screen - Kompleksna selection mode logika i potencijalni memory leaks
38. ✅ Profile Screen - Nedostaju error handling-i i optimizacije

---

## 📱 Owner Dashboard Screens - Analiza Problema

### 35. Notification Settings Screen - Nedostaju Optimistic Updates i Error Recovery

**Lokacija:**
- `lib/features/owner_dashboard/presentation/screens/notification_settings_screen.dart`

**Problem:**
- Nema optimistic updates - UI se ne ažurira odmah, korisnik mora čekati na server response (linije 26-68, 70-134)
- `_currentPreferences` se inicijalizuje u build metodi što može dovesti do nekonzistentnog stanja (linija 158)
- Nema retry mehanizma ako save fail-uje
- Nema debounce-a za brze toggle promene

**Preporuka:**
- Implementirati optimistic updates za instant UI feedback
- Inicijalizovati `_currentPreferences` u `initState` ili koristiti provider state
- Dodati retry mehanizam sa exponential backoff
- Dodati debounce za toggle switch-e

**Primer:**
```dart
Future<void> _toggleMasterSwitch(bool value) async {
  if (_currentPreferences == null) return;
  
  // Optimistic update
  final previousValue = _currentPreferences!.masterEnabled;
  setState(() {
    _currentPreferences = _currentPreferences!.copyWith(masterEnabled: value);
  });
  
  try {
    // ... save logic
  } catch (e) {
    // Rollback on error
    setState(() {
      _currentPreferences = _currentPreferences!.copyWith(masterEnabled: previousValue);
    });
    // Show error
  }
}
```

---

### 36. Notifications Screen - Kompleksna Selection Mode Logika i Potencijalni Memory Leaks

**Lokacija:**
- `lib/features/owner_dashboard/presentation/screens/notifications_screen.dart`

**Problem:**
- `_selectedIds` Set se ne čisti pravilno u svim slučajevima (linije 29, 36, 44, 53, 58)
- Nema debounce-a za `_deleteSelected` i `_deleteAll` operacije
- `Dismissible` widget može dovesti do problema sa state-om ako se notification obriše dok je u dismiss animaciji (linije 409-464)
- Nema optimizacije za velike liste notifikacija (nema virtual scrolling)

**Preporuka:**
- Dodati debounce za delete operacije
- Dodati proper cleanup za `_selectedIds` u dispose metodi
- Razmotriti korišćenje `ListView.builder` sa `itemExtent` za bolje performanse
- Dodati confirmation dialog pre brisanja više notifikacija

**Primer:**
```dart
@override
void dispose() {
  _selectedIds.clear();
  super.dispose();
}

Future<void> _deleteSelected() async {
  if (_selectedIds.isEmpty) return;
  
  // Debounce multiple rapid clicks
  if (_isDeleting) return;
  
  // ... rest of delete logic
}
```

---

### 37. Overview Screen - Wrapper Screen (Nema Problema)

**Lokacija:**
- `lib/features/owner_dashboard/presentation/screens/overview_screen.dart`

**Problem:**
- Nema problema - ovo je samo wrapper screen koji renderuje `DashboardOverviewTab`

**Preporuka:**
- Nema preporuka - screen je jednostavan i ispravan

---

### 38. Profile Screen - Nedostaju Error Handling-i i Optimizacije

**Lokacija:**
- `lib/features/owner_dashboard/presentation/screens/profile_screen.dart`

**Problem:**
- `Image.network` za avatar nema error handling za network failures (linije 128-185)
- Nema caching za avatar slike
- Kompleksna logika za fallback display name i email (linije 64-75)
- Nema loading state za avatar image

**Preporuka:**
- Dodati `CachedNetworkImage` umesto `Image.network` za avatar
- Dodati proper error handling za image loading
- Simplifikovati fallback logiku za display name i email
- Dodati placeholder dok se avatar učitava

**Primer:**
```dart
// Use cached network image
CachedNetworkImage(
  imageUrl: authState.userModel!.avatarUrl!,
  width: isMobile ? 72 : 88,
  height: isMobile ? 72 : 88,
  fit: BoxFit.cover,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => CircleAvatar(
    // Fallback avatar
  ),
)
```

---

### 39. Property Form Screen - Kompleksna Logika, Performance Problemi i Potencijalni Memory Leaks

**Lokacija:**
- `lib/features/owner_dashboard/presentation/screens/property_form_screen.dart`

**Problem:**
- `_subdomainDebounceTimer` se ne uvek otkazuje pravilno (linija 102)
- `_selectedImages` lista može biti veoma velika - nema optimizacije za memory (linija 49)
- `FutureBuilder` za image reading može dovesti do memory leak-a (linije 1089-1122)
- Nema timeout-ova na Cloud Functions pozivima (linije 132, 195)
- Kompleksna logika za subdomain checking sa više state flag-ova
- Nema retry mehanizma za failed image uploads

**Preporuka:**
- Dodati proper cleanup za sve Timer-ove i Future-ove
- Optimizovati image handling - koristiti thumbnails umesto full-size slika
- Dodati timeout-ove na sve Cloud Functions pozive
- Implementirati retry mehanizam za image uploads
- Razmotriti korišćenje `ImagePicker` sa compression opcijama

**Primer:**
```dart
@override
void dispose() {
  _subdomainDebounceTimer?.cancel();
  // Cancel all image reading futures
  for (final image in _selectedImages) {
    // Cancel any pending operations
  }
  // ... dispose controllers
  super.dispose();
}

Future<void> _pickImages() async {
  final ImagePicker picker = ImagePicker();
  final List<XFile> images = await picker.pickMultiImage(
    imageQuality: 85, // Compress images
    maxWidth: 1920, // Limit size
  );
  // ... rest
}
```

---

### 40. Stripe Connect Setup Screen - Nedostaju Timeout-ovi i Error Recovery

**Lokacija:**
- `lib/features/owner_dashboard/presentation/screens/stripe_connect_setup_screen.dart`

**Problem:**
- Nema timeout-ova na Cloud Functions pozivima (linije 45, 78, 176)
- `launchUrl` može fail-ovati bez proper error handling-a (linije 95-106)
- Nema retry mehanizma za failed account status checks
- `_MoneyLoadingAnimation` koristi više AnimationController-a koji se možda ne dispose-uju pravilno (linije 904-957)

**Preporuka:**
- Dodati timeout-ove na sve Cloud Functions pozive
- Dodati proper error handling za `launchUrl`
- Implementirati retry mehanizam sa exponential backoff
- Osigurati da se svi AnimationController-i dispose-uju

**Primer:**
```dart
Future<void> _loadStripeAccountInfo() async {
  setState(() => _isLoading = true);
  
  try {
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('getStripeAccountStatus');
    final result = await callable.call().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Stripe account status check timed out');
      },
    );
    // ... rest
  } catch (e) {
    // Retry logic
    if (e is TimeoutException && _retryCount < 3) {
      await Future.delayed(Duration(seconds: pow(2, _retryCount).toInt()));
      return _loadStripeAccountInfo();
    }
    // ... error handling
  }
}
```

---

### 41. Unified Unit Hub Screen - FROZEN, Kompleksna Logika i Potencijalni Performance Problemi

**Lokacija:**
- `lib/features/owner_dashboard/presentation/screens/unified_unit_hub_screen.dart`

**Problem:**
- Screen je označen kao FROZEN - možda ima poznate probleme
- Kompleksna master-detail logika sa više state varijabli
- `ref.listen` može dovesti do nepotrebnih rebuild-ova (linija 158)
- Nema optimizacije za velike liste units (nema virtual scrolling u master panel-u)
- `TabController` se ne dispose-uje pravilno u svim slučajevima (linija 115)
- Kompleksna logika za responsive layout sa više breakpoint-a

**Preporuka:**
- Dokumentovati zašto je screen FROZEN i koje su poznate probleme
- Optimizovati `ref.listen` - koristiti `ref.listenManual` ili optimizovati uslove
- Dodati virtual scrolling za master panel sa velikim brojem units
- Osigurati da se `TabController` uvek dispose-uje
- Razmotriti refactoring kompleksne layout logike

**Primer:**
```dart
// Document FROZEN status
/// FROZEN: This screen has known performance issues with large unit lists.
/// TODO: Implement virtual scrolling for master panel
/// TODO: Optimize ref.listen to prevent unnecessary rebuilds
class UnifiedUnitHubScreen extends ConsumerStatefulWidget {
  // ...
}

// Optimize ref.listen
ref.listenManual<AsyncValue<List<UnitModel>>>(
  ownerUnitsProvider,
  (previous, next) {
    // Only handle data changes, not loading/error states
    if (next.hasValue && previous?.value != next.value) {
      next.whenData((units) => _handleUnitsChanged(units, properties));
    }
  },
);
```

---

## 📊 Prioriteti za Rešavanje - Owner Dashboard Screens

### Visok Prioritet (Kritično)
35. ✅ Notification Settings Screen - Nedostaju optimistic updates i error recovery
39. ✅ Property Form Screen - Kompleksna logika, performance problemi i potencijalni memory leaks
40. ✅ Stripe Connect Setup Screen - Nedostaju timeout-ovi i error recovery
41. ✅ Unified Unit Hub Screen - FROZEN, kompleksna logika i potencijalni performance problemi

### Srednji Prioritet (Važno)
36. ✅ Notifications Screen - Kompleksna selection mode logika i potencijalni memory leaks
38. ✅ Profile Screen - Nedostaju error handling-i i optimizacije

### Nizak Prioritet (Poboljšanja)
37. ✅ Overview Screen - Wrapper screen (nema problema)
46. ✅ Dashboard Stats Skeleton - DEPRECATED widget (nema problema)
49. ✅ Language Selection Bottom Sheet - Hardcoded string-ovi

---

## 🧩 Owner Dashboard State, Utils & Widgets - Analiza Problema

### 42. Price Calendar State - Nedostaje Memory Management i Cache Size Limit

**Lokacija:**
- `lib/features/owner_dashboard/presentation/state/price_calendar_state.dart`

**Problem:**
- `_priceCache` Map može rasti neograničeno - nema LRU eviction ili size limit-a (linija 7)
- Nema cleanup mehanizma za stare mesece
- `ChangeNotifier` se ne dispose-uje - potencijalni memory leak
- Nema validacije za month key format

**Preporuka:**
- Implementirati LRU cache sa maksimalnim brojem meseci (npr. 12 meseci)
- Dodati `dispose()` metodu za cleanup
- Dodati validaciju za month keys
- Razmotriti korišćenje `package:collection` LRU cache implementacije

**Primer:**
```dart
class PriceCalendarState extends ChangeNotifier {
  static const int _maxCachedMonths = 12;
  final Map<DateTime, Map<DateTime, DailyPriceModel>> _priceCache = {};
  final List<DateTime> _accessOrder = []; // For LRU tracking

  void setMonthPrices(DateTime month, Map<DateTime, DailyPriceModel> prices) {
    final monthKey = DateTime(month.year, month.month);
    
    // LRU eviction
    if (_priceCache.length >= _maxCachedMonths && !_priceCache.containsKey(monthKey)) {
      final oldest = _accessOrder.removeAt(0);
      _priceCache.remove(oldest);
    }
    
    _priceCache[monthKey] = Map.from(prices);
    _accessOrder.remove(monthKey);
    _accessOrder.add(monthKey);
    notifyListeners();
  }

  @override
  void dispose() {
    _priceCache.clear();
    _accessOrder.clear();
    super.dispose();
  }
}
```

---

### 43. Scroll Direction Tracker - Nedostaju Edge Case Handling-i

**Lokacija:**
- `lib/features/owner_dashboard/presentation/utils/scroll_direction_tracker.dart`

**Problem:**
- `update()` metoda može dovesti do problema ako `controller` nema clients (linija 33)
- Nema handling-a za scroll position jumps (npr. programmatic scroll)
- Hardcoded threshold vrednosti (linije 20, 23, 26)
- Nema reset mehanizma za edge cases (npr. content size changes)

**Preporuka:**
- Dodati validaciju za controller state pre pristupa
- Implementirati detection za programmatic scroll jumps
- Konfigurisati threshold vrednosti kroz konstruktor
- Dodati reset mehanizam za content size changes

**Primer:**
```dart
void update(ScrollController controller) {
  if (!controller.hasClients) {
    reset(); // Reset state if controller is detached
    return;
  }

  final currentPixels = controller.offset;
  final delta = currentPixels - _lastPixels;
  
  // Detect large jumps (programmatic scroll)
  if (delta.abs() > 1000) {
    reset();
    return;
  }
  
  // ... rest of logic
}
```

---

### 44. Booking Create Dialog - Kompleksna Validacija i Potencijalni Race Conditions

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/booking_create_dialog.dart`

**Problem:**
- Email validacija koristi jednostavan regex koji možda ne pokriva sve edge cases (linija 622)
- Nema debounce-a za overlap checking - može dovesti do višestrukih provjera
- `_createBooking` metoda može biti pozvana više puta ako korisnik brzo klikne (linija 453)
- Nema timeout-a na `calendarBookingsProvider.future` poziv (linija 555)

**Preporuka:**
- Koristiti `email_validator` package za robustniju email validaciju
- Dodati debounce za overlap checking
- Dodati loading state guard da spreči multiple submissions
- Dodati timeout na provider future pozive

**Primer:**
```dart
bool _isSubmitting = false;

Future<void> _createBooking() async {
  if (_isSubmitting) return; // Prevent double submission
  
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isSaving = true;
    _isSubmitting = true;
  });

  try {
    // Add timeout
    final bookingsMap = await ref.read(calendarBookingsProvider.future)
      .timeout(const Duration(seconds: 10));
    
    // ... rest of logic
  } finally {
    if (mounted) {
      setState(() {
        _isSaving = false;
        _isSubmitting = false;
      });
    }
  }
}
```

---

### 45. Booking Details Dialog - Hardcoded Debug Log Paths i Potencijalni Memory Leaks

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/booking_details_dialog.dart`

**Problem:**
- Hardcoded debug log path `/Users/duskolicanin/git/bookbed/.cursor/debug.log` (linije 31-42, 509-522, 527-540)
- File write operacije u build metodi - može dovesti do performance problema
- Nema error handling za file write operacije
- `_resendConfirmationEmail` nema timeout na Cloud Function poziv (linija 543)

**Preporuka:**
- Ukloniti hardcoded debug log paths ili koristiti `LoggingService`
- Premestiti file write operacije iz build metode
- Dodati proper error handling za file operacije
- Dodati timeout na Cloud Function pozive

**Primer:**
```dart
// Remove debug logging or use LoggingService
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Remove file write operations from build method
  // Use LoggingService.log() instead if needed
  
  // ... rest of build logic
}

Future<void> _resendConfirmationEmail(...) async {
  try {
    final callable = functions.httpsCallable('resendBookingEmail');
    await callable.call({'bookingId': ownerBooking.booking.id})
      .timeout(const Duration(seconds: 30));
    // ... rest
  } catch (e) {
    // ... error handling
  }
}
```

---

### 46. Dashboard Stats Skeleton - DEPRECATED Widget (Nema Problema)

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/dashboard_stats_skeleton.dart`

**Problem:**
- Widget je označen kao DEPRECATED (linija 6-8)
- Još uvek postoji u kodu - treba ukloniti ili dokumentovati zašto je zadržan

**Preporuka:**
- Ukloniti widget ako nije više korišćen
- Ili dodati `@Deprecated` anotaciju sa objašnjenjem
- Dokumentovati migration path ka `SkeletonLoader.analyticsMetricCards()`

---

### 47. Edit Booking Dialog - Nedostaju Timeout-ovi i Potencijalni Race Conditions

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/edit_booking_dialog.dart`

**Problem:**
- `_saveChanges` metoda nema timeout na Firestore transaction (linija 409)
- Nema timeout na Cloud Function poziv za token expiration update (linija 430)
- `PopScope` sa `canPop: !_isLoading` može dovesti do problema ako loading nikad ne završi (linija 77)
- Nema retry mehanizma za failed transactions

**Preporuka:**
- Dodati timeout-ove na sve async operacije
- Dodati timeout guard za `_isLoading` state
- Implementirati retry mehanizam sa exponential backoff
- Dodati proper error recovery

**Primer:**
```dart
Future<void> _saveChanges() async {
  setState(() => _isLoading = true);
  
  // Add timeout guard
  Timer? timeoutTimer;
  timeoutTimer = Timer(const Duration(seconds: 30), () {
    if (mounted && _isLoading) {
      setState(() => _isLoading = false);
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        'Operation timed out. Please try again.',
      );
    }
  });

  try {
    await firestore.runTransaction((transaction) async {
      // ... transaction logic
    }).timeout(const Duration(seconds: 15));
    
    // ... rest of logic
  } finally {
    timeoutTimer?.cancel();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

---

### 48. Embed Code Generator Dialog - Hardcoded URL-ovi i Nedostaju Validacije

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/embed_code_generator_dialog.dart`

**Problem:**
- Hardcoded base URL-ovi `https://bookbed.io` i `bookbed.io` (linije 38-39)
- Nema validacije za subdomain format
- Nema error handling za invalid URL generation
- Hardcoded embed.js script URL (linija 79)

**Preporuka:**
- Koristiti environment variables ili config za base URL-ove
- Dodati validaciju za subdomain format (alphanumeric + hyphens)
- Dodati error handling za URL generation
- Konfigurisati embed.js URL kroz config

**Primer:**
```dart
class _EmbedCodeGeneratorDialogState extends State<EmbedCodeGeneratorDialog> {
  // Use config instead of hardcoded values
  static String get _defaultWidgetBaseUrl => 
    AppConfig.widgetBaseUrl ?? 'https://bookbed.io';
  
  String get _widgetBaseUrl {
    if (widget.propertySubdomain != null && 
        widget.propertySubdomain!.isNotEmpty) {
      // Validate subdomain format
      if (!_isValidSubdomain(widget.propertySubdomain!)) {
        return _defaultWidgetBaseUrl; // Fallback
      }
      return 'https://${widget.propertySubdomain}.$_subdomainBaseDomain';
    }
    return _defaultWidgetBaseUrl;
  }
  
  bool _isValidSubdomain(String subdomain) {
    return RegExp(r'^[a-z0-9-]+$').hasMatch(subdomain) &&
           subdomain.length >= 3 &&
           subdomain.length <= 63;
  }
}
```

---

### 49. Language Selection Bottom Sheet - Hardcoded String-ovi

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/language_selection_bottom_sheet.dart`

**Problem:**
- Hardcoded language names 'Hrvatski' i 'English' (linije 81, 94)
- Nema lokalizacije za language display names
- Nema error handling ako language provider fail-uje

**Preporuka:**
- Koristiti `AppLocalizations` za language display names
- Dodati error handling za language provider failures
- Razmotriti korišćenje `LocaleDisplayNames` package-a

**Primer:**
```dart
_LanguageOption(
  locale: const Locale('hr'),
  title: l10n.languageCroatian, // Use localization
  subtitle: l10n.languageCroatianNative,
  isSelected: currentLocale.languageCode == 'hr',
  onTap: () {
    try {
      ref.read(languageNotifierProvider.notifier).setLanguage('hr');
      Navigator.of(context).pop();
    } catch (e) {
      ErrorDisplayUtils.showErrorSnackBar(context, e);
    }
  },
),
```

---

### 50. Onboarding Property Step - Nedostaju Validacije i Auto-save Issues

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/onboarding_property_step.dart`

**Problem:**
- `_saveData()` se poziva na svaku promenu teksta - može dovesti do previše provider update-ova (linije 53-57)
- Nema debounce-a za auto-save
- Email i website validacija nisu implementirane (linije 248-272)
- Hardcoded default country 'Hrvatska' (linija 49)
- Nema error handling za provider save operacije

**Preporuka:**
- Dodati debounce za auto-save operacije
- Implementirati email i website validaciju
- Koristiti lokalizaciju za default country
- Dodati error handling za save operacije

**Primer:**
```dart
Timer? _saveDebounceTimer;

void _saveData() {
  _saveDebounceTimer?.cancel();
  _saveDebounceTimer = Timer(const Duration(milliseconds: 500), () {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final data = PropertyFormData(/* ... */);
        ref.read(onboardingNotifierProvider.notifier).savePropertyData(data);
      } catch (e) {
        // Log error but don't block UI
        LoggingService.logError('Failed to save property data: $e');
      }
    }
  });
}

@override
void dispose() {
  _saveDebounceTimer?.cancel();
  // ... dispose controllers
  super.dispose();
}
```

---

### 51. Owner App Drawer - Nedostaju Error Handling-i i Optimizacije

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/owner_app_drawer.dart`

**Problem:**
- `Image.network` za avatar nema error handling za network failures (linija 243)
- Nema caching za avatar slike
- `pendingBookingsCountProvider` može dovesti do nepotrebnih rebuild-ova (linija 424)
- Nema loading state za avatar image

**Preporuka:**
- Koristiti `CachedNetworkImage` umesto `Image.network`
- Optimizovati `pendingBookingsCountProvider` watch - koristiti `select` za selective rebuilds
- Dodati placeholder dok se avatar učitava
- Dodati error handling za provider failures

**Primer:**
```dart
// Optimize provider watch
final pendingCount = ref.watch(
  pendingBookingsCountProvider.select((value) => value.valueOrNull ?? 0),
);

// Use CachedNetworkImage
CachedNetworkImage(
  imageUrl: authState.userModel!.avatarUrl!,
  width: 56,
  height: 56,
  fit: BoxFit.cover,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Center(
    child: Text(initial, /* ... */),
  ),
)
```

---

## 📊 Prioriteti za Rešavanje - State, Utils & Widgets

### Visok Prioritet (Kritično)
42. ✅ Price Calendar State - Nedostaje memory management i cache size limit
45. ✅ Booking Details Dialog - Hardcoded debug log paths i potencijalni memory leaks
47. ✅ Edit Booking Dialog - Nedostaju timeout-ovi i potencijalni race conditions
48. ✅ Embed Code Generator Dialog - Hardcoded URL-ovi i nedostaju validacije

### Srednji Prioritet (Važno)
43. ✅ Scroll Direction Tracker - Nedostaju edge case handling-i
44. ✅ Booking Create Dialog - Kompleksna validacija i potencijalni race conditions
50. ✅ Onboarding Property Step - Nedostaju validacije i auto-save issues
51. ✅ Owner App Drawer - Nedostaju error handling-i i optimizacije

### Nizak Prioritet (Poboljšanja)
46. ✅ Dashboard Stats Skeleton - DEPRECATED widget (nema problema)
49. ✅ Language Selection Bottom Sheet - Hardcoded string-ovi

---

## 📅 Owner Dashboard Calendar Widgets - Analiza Problema

### 52. Booking Action Menu - Hardcoded String-ovi i Nedostaju Timeout-ovi

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/calendar/booking_action_menu.dart`

**Problem:**
- Hardcoded string-ovi za noći i goste (linije 127, 130) - 'noć', 'noći', 'gost', 'gosta'
- Hardcoded string-ovi u conflict warning banner-u (linije 307, 316, 356)
- Hardcoded string-ovi u external booking banner-u (linije 391, 396)
- Nema timeout-ova na repository pozivima za move booking (linija 615)
- Nema error handling za failed move operations
- `_moveBookingToUnit` nema retry mehanizam

**Preporuka:**
- Koristiti `AppLocalizations` za sve string-ove
- Dodati timeout-ove na repository pozive
- Implementirati retry mehanizam sa exponential backoff
- Dodati proper error handling sa user-friendly porukama

**Primer:**
```dart
// Use localization
_buildInfoChip(
  Icons.nights_stay, 
  l10n.bookingActionNights(nights), // Use pluralization
),
_buildInfoChip(
  Icons.people_outline,
  l10n.bookingActionGuests(booking.guestCount), // Use pluralization
),

// Add timeout
Future<void> _moveBookingToUnit(...) async {
  try {
    final updatedBooking = widget.booking.copyWith(unitId: targetUnit.id);
    final bookingRepo = ref.read(bookingRepositoryProvider);
    await bookingRepo.updateBooking(updatedBooking)
      .timeout(const Duration(seconds: 30));
    // ... rest
  } catch (e) {
    // ... error handling
  }
}
```

---

### 53. Booking Block Widget - Hardcoded String-ovi i Hardcoded Locale

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/calendar/booking_block_widget.dart`

**Problem:**
- Hardcoded string-ovi u tooltip-ovima i semantic label-u (linije 240, 268, 362, 385, 476, 479)
- Hardcoded locale 'hr_HR' u DateFormat pozivima (linije 449, 473, 474)
- Nema error handling za drag operations
- `_buildSemanticLabel` koristi hardcoded string-ove umesto lokalizacije

**Preporuka:**
- Koristiti `AppLocalizations` za sve string-ove
- Koristiti `Localizations.localeOf(context)` umesto hardcoded locale
- Dodati error handling za drag operations
- Implementirati lokalizovane semantic labels

**Primer:**
```dart
String _buildSemanticLabel() {
  final l10n = AppLocalizations.of(context);
  final checkInStr = DateFormat('d. MMM', Localizations.localeOf(context).languageCode)
    .format(booking.checkIn);
  final checkOutStr = DateFormat('d. MMM', Localizations.localeOf(context).languageCode)
    .format(booking.checkOut);
  final statusStr = booking.status.displayName; // Use localized display name
  final guestName = booking.guestName ?? l10n.bookingActionUnknownGuest;
  final nights = booking.checkOut.difference(booking.checkIn).inDays;

  return l10n.bookingBlockSemanticLabel(
    guestName,
    checkInStr,
    checkOutStr,
    nights,
    booking.guestCount,
    statusStr,
  );
}

String _getDateRangeString(DateTime checkIn, DateTime checkOut) {
  final locale = Localizations.localeOf(context);
  final dateFormat = DateFormat('d MMM', locale.languageCode);
  return '${dateFormat.format(checkIn)} - ${dateFormat.format(checkOut)}';
}
```

---

### 54. Booking Context Menu - Hardcoded String-ovi i Hardcoded Menu Dimensions

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/calendar/booking_context_menu.dart`

**Problem:**
- Hardcoded string-ovi 'N/A' i 'Imported booking - manage on...' (linije 83, 151)
- Hardcoded menu dimensions 220.0 i 400.0 (linije 357-358)
- Nema error handling za context menu actions
- Nema validacije za position bounds checking

**Preporuka:**
- Koristiti `AppLocalizations` za sve string-ove
- Konfigurisati menu dimensions kroz constants ili responsive helpers
- Dodati error handling za sve menu actions
- Poboljšati position bounds checking sa padding constants

**Primer:**
```dart
// Use constants
class _MenuConstants {
  static const double menuWidth = 220.0;
  static const double menuHeight = 400.0;
  static const double edgePadding = 16.0;
}

// Use localization
Text(
  booking.guestName ?? l10n.bookingContextUnknownGuest,
  // ...
),

Text(
  l10n.bookingContextImportedBooking(booking.sourceDisplayName),
  // ...
),

// Improve bounds checking
Future<void> showBookingContextMenu(...) {
  final screenSize = MediaQuery.of(context).size;
  final menuWidth = _MenuConstants.menuWidth;
  final menuHeight = _MenuConstants.menuHeight;
  final padding = _MenuConstants.edgePadding;

  double left = position.dx;
  double top = position.dy;

  // Keep menu within bounds with proper padding
  left = left.clamp(padding, screenSize.width - menuWidth - padding);
  top = top.clamp(padding, screenSize.height - menuHeight - padding);
  
  // ... rest
}
```

---

### 55. Booking Drop Zone - Hardcoded String-ovi i Potencijalni Performance Problemi

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/calendar/booking_drop_zone.dart`

**Problem:**
- Hardcoded string-ovi 'Pusti ovdje' i 'Nije moguće' (linija 219)
- `onWillAcceptWithDetails` se poziva na svaki drag update - može dovesti do previše provider update-ova (linija 66)
- Nema debounce-a za validation calls
- Nema timeout-ova na validation operacijama
- Potencijalni performance problemi sa čestim rebuild-ovima tokom drag-a

**Preporuka:**
- Koristiti `AppLocalizations` za sve string-ove
- Optimizovati validation calls - dodati debounce ili throttle
- Dodati timeout-ove na validation operacije
- Razmotriti korišćenje `RepaintBoundary` za drop zone widget-e
- Implementirati selective rebuilds umesto full rebuilds

**Primer:**
```dart
// Use localization
Text(
  isValid 
    ? l10n.bookingDropZoneDropHere 
    : (errorMessage ?? l10n.bookingDropZoneCannotDrop),
  // ...
),

// Optimize validation with debounce
Timer? _validationDebounceTimer;

onWillAcceptWithDetails: (details) {
  _validationDebounceTimer?.cancel();
  _validationDebounceTimer = Timer(const Duration(milliseconds: 100), () {
    ref.read(dragDropProvider.notifier).validateDrop(
      dropDate: date,
      targetUnitId: unit.id,
      allBookings: allBookings,
    ).timeout(const Duration(seconds: 5));
  });
  return true;
},

// Use RepaintBoundary for performance
@override
Widget build(BuildContext context, WidgetRef ref) {
  return RepaintBoundary(
    child: GestureDetector(
      // ... rest
    ),
  );
}
```

---

## 📊 Prioriteti za Rešavanje - Calendar Widgets

### Visok Prioritet (Kritično)
55. ✅ Booking Drop Zone - Hardcoded string-ovi i potencijalni performance problemi

### Srednji Prioritet (Važno)
52. ✅ Booking Action Menu - Hardcoded string-ovi i nedostaju timeout-ovi
53. ✅ Booking Block Widget - Hardcoded string-ovi i hardcoded locale
54. ✅ Booking Context Menu - Hardcoded string-ovi i hardcoded menu dimensions
56. ✅ Timeline Booking Block - Nedostaju accessibility labels i hardcoded vrednosti

---

## ⏱️ Owner Dashboard Timeline Widgets - Analiza Problema

### 56. Timeline Booking Block - Nedostaju Accessibility Labels i Hardcoded Vrednosti

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/timeline/timeline_booking_block.dart`

**Problem:**
- Nema `Semantics` widget-a za accessibility (linije 138-218)
- Hardcoded vrednosti za block height calculation (linija 132: `unitRowHeight - 8`)
- Hardcoded margin vrednosti (linija 166: `EdgeInsets.symmetric(horizontal: 2)`)
- Hardcoded transform vrednosti (linija 167: `Matrix4.diagonal3Values(1.02, 1.02, 1.0)`)
- Nema error handling za conflict detection failures
- Potencijalni performance problemi sa čestim rebuild-ovima tokom hover-a

**Preporuka:**
- Dodati `Semantics` widget sa proper labels za screen readers
- Konfigurisati hardcoded vrednosti kroz constants ili theme
- Dodati error handling za conflict detection
- Razmotriti korišćenje `RepaintBoundary` za performance optimizacije
- Optimizovati hover state management

**Primer:**
```dart
// Add constants
class _TimelineBookingBlockConstants {
  static const double blockHeightPadding = 8.0;
  static const double horizontalMargin = 2.0;
  static const double hoverScale = 1.02;
  static const double hoverOpacity = 1.0;
  static const double normalOpacity = 0.92;
}

// Add Semantics
return Semantics(
  label: _buildSemanticLabel(booking, hasConflict),
  button: true,
  enabled: true,
  child: MouseRegion(
    // ... rest
  ),
);

String _buildSemanticLabel(BookingModel booking, bool hasConflict) {
  final l10n = AppLocalizations.of(context);
  final conflictText = hasConflict ? l10n.bookingBlockHasConflict : '';
  return l10n.bookingBlockSemanticLabel(
    booking.guestName ?? l10n.bookingActionUnknownGuest,
    booking.checkIn,
    booking.checkOut,
    booking.numberOfNights,
    conflictText,
  );
}
```

---

### 57. Timeline Booking Stacker - Kompleksna Logika i Potencijalni Edge Cases

**Lokacija:**
- `lib/features/owner_dashboard/presentation/widgets/timeline/timeline_booking_stacker.dart`

**Problem:**
- `assignStackLevels` metoda ima kompleksnu logiku sa potencijalnim edge cases (linije 16-56)
- `detectSameDayTurnovers` može biti neefikasna za velike liste (O(n²) kompleksnost) (linije 62-91)
- Nema validacije za input parametre (null checks, empty lists)
- Deprecated metoda `hasOverlap` još uvek postoji u kodu (linija 114)
- Nema dokumentacije za stack level algoritam
- Potencijalni bug: `stackEndDates[assignedLevel] = booking.checkOut` može overwrite-ovati postojeći end date ako nije pravilno proveren (linija 49)

**Preporuka:**
- Optimizovati `detectSameDayTurnovers` - koristiti hash map za O(n) kompleksnost
- Dodati validacije za input parametre
- Ukloniti deprecated metodu ili dodati `@Deprecated` anotaciju sa migration path-om
- Dodati dokumentaciju za stack level algoritam
- Popraviti potencijalni bug u `assignStackLevels` logici
- Razmotriti unit test-ove za edge cases

**Primer:**
```dart
/// Assign stack levels to bookings within a unit
///
/// Algorithm: Greedy assignment - assigns each booking to the first available level
/// where the previous booking has ended before this one starts.
///
/// Time complexity: O(n²) where n is number of bookings
/// Space complexity: O(n) for stack levels map
static Map<String, int> assignStackLevels(List<BookingModel> bookings) {
  // Validate input
  if (bookings.isEmpty) return {};
  
  // Sort bookings by check-in date
  final sorted = List<BookingModel>.from(bookings)
    ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

  final Map<String, int> stackLevels = {};
  final List<DateTime?> stackEndDates = [];

  for (final booking in sorted) {
    int assignedLevel = stackEndDates.length; // Default: new level
    
    // Find first available level
    for (int level = 0; level < stackEndDates.length; level++) {
      final endDate = stackEndDates[level];
      if (endDate == null || !booking.checkIn.isBefore(endDate)) {
        assignedLevel = level;
        break;
      }
    }

    // Create new level if needed
    if (assignedLevel >= stackEndDates.length) {
      stackEndDates.add(booking.checkOut);
    } else {
      // FIXED: Only update if this booking ends later
      final currentEnd = stackEndDates[assignedLevel];
      if (currentEnd == null || booking.checkOut.isAfter(currentEnd)) {
        stackEndDates[assignedLevel] = booking.checkOut;
      }
    }

    stackLevels[booking.id] = assignedLevel;
  }

  return stackLevels;
}

/// Optimized same-day turnover detection (O(n) instead of O(n²))
static Map<DateTime, List<List<BookingModel>>> detectSameDayTurnovers(
  List<BookingModel> bookings,
) {
  final Map<DateTime, List<List<BookingModel>>> turnovers = {};
  
  if (bookings.length < 2) return turnovers;

  // Build check-out date index for O(1) lookup
  final Map<DateTime, List<BookingModel>> checkOutIndex = {};
  for (final booking in bookings) {
    final checkOutDate = _normalizeDate(booking.checkOut);
    checkOutIndex.putIfAbsent(checkOutDate, () => []).add(booking);
  }

  // Find matching check-ins
  for (final booking in bookings) {
    final checkInDate = _normalizeDate(booking.checkIn);
    final matchingCheckOuts = checkOutIndex[checkInDate];
    
    if (matchingCheckOuts != null) {
      for (final checkOutBooking in matchingCheckOuts) {
        if (checkOutBooking.id != booking.id) {
          turnovers.putIfAbsent(checkInDate, () => []).add([
            checkOutBooking,
            booking,
          ]);
        }
      }
    }
  }

  return turnovers;
}

@Deprecated('Use BookingOverlapDetector.doBookingsOverlap directly')
static bool hasOverlap(BookingModel booking1, BookingModel booking2) {
  // ... existing implementation
}
```

---

## 📊 Prioriteti za Rešavanje - Timeline Widgets

### Visok Prioritet (Kritično)
57. ✅ Timeline Booking Stacker - Kompleksna logika i potencijalni edge cases

### Srednji Prioritet (Važno)
56. ✅ Timeline Booking Block - Nedostaju accessibility labels i hardcoded vrednosti

---

## 🔗 Povezani Dokumenti

- [Flutter Best Practices](https://docs.flutter.dev/development/best-practices)
- [Riverpod Documentation](https://riverpod.dev/docs/introduction/getting_started)
- [Accessibility Guidelines](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)

---

**Datum kreiranja:** 2024-12-19  
**Poslednja izmena:** 2024-12-19 (dodata analiza Core Services, Core Utils, Domain Models, Owner Dashboard Screens, State, Utils & Widgets, Calendar Widgets, Timeline Widgets)  
**Autor:** AI Code Analysis
