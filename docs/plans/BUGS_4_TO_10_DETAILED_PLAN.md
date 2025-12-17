# Detaljan Plan - Bugovi #4 do #10

**Kreirano:** 2025-12-16
**Scope:** 7 bugova (4 Medium Priority, 3 Low Priority)
**Procijenjeno vrijeme:** ~12-15 sati

---

## Pregled Bugova

| Bug | Naziv | Prioritet | Status | Effort |
|-----|-------|-----------|--------|--------|
| #4 | Error Boundary-i | MEDIUM | ⚠️ Djelomično implementirano | 1h |
| #5 | Async Timeout-ovi | MEDIUM | ❌ Nije implementirano | 3h |
| #6 | Provider AutoDispose | MEDIUM | ⚠️ Djelomično implementirano | 2h |
| #7 | Accessibility Labels | MEDIUM | ⚠️ Helper postoji, nije korišten | 4h |
| #8 | TODO Komentari | LOW | ❌ Placeholder implementacije | 1h |
| #9 | Nedostaju Lokalizacije | LOW | ❌ Hardcoded stringovi | 1.5h |
| #10 | RepaintBoundary | LOW | ❌ Nije implementirano | 1h |

---

## Bug #4: Error Boundary-i

### Trenutno Stanje
**Status:** ⚠️ DJELOMIČNO IMPLEMENTIRANO

Postoji:
- `lib/core/error_handling/error_boundary.dart` - `ErrorBoundary` widget
- `GlobalErrorHandler` klasa sa `initialize()` metodom
- `main.dart` ima `FlutterError.onError` handler za Crashlytics/Sentry

Nedostaje:
- ErrorBoundary nije korišten oko screen widgeta
- Nema `ErrorWidget.builder` customizacije za graceful fallback

### Plan Implementacije

#### Korak 1: Verificirati GlobalErrorHandler
**Fajl:** `lib/main.dart`

```dart
// PROVJERA - Već postoji u main.dart (linije 66-90):
if (kReleaseMode) {
  if (!kIsWeb) {
    FlutterError.onError = (details) {
      if (AppInitState.isFirebaseReady) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };
    // ...
  } else {
    // Sentry za web
  }
}
```

**Akcija:** ✅ Već implementirano - SKIP

#### Korak 2: Dodati ErrorWidget.builder
**Fajl:** `lib/main.dart`

Dodati u `_runAppWithDeferredInit()` funkciju:

```dart
void _runAppWithDeferredInit() {
  // DODATI: Custom error widget za debug mode
  if (kDebugMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          color: Colors.red.shade50,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Debug Error',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                details.exception.toString(),
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                textAlign: TextAlign.center,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    };
  }

  // ... ostatak koda
}
```

#### Korak 3: Wrap kritične screens sa ErrorBoundary
**Fajlovi:**
- `lib/features/owner_dashboard/presentation/screens/owner_bookings_screen.dart`
- `lib/features/owner_dashboard/presentation/screens/owner_timeline_calendar_screen.dart`

```dart
// U router_owner.dart, wrap screens:
GoRoute(
  path: 'bookings',
  builder: (context, state) => ErrorBoundary(
    onError: (details) => LoggingService.logError('Bookings screen error', details.exception),
    child: OwnerBookingsScreen(
      initialBookingId: state.uri.queryParameters['bookingId'],
    ),
  ),
),
```

### Procjena: 1h
- 15min: Dodati ErrorWidget.builder
- 30min: Wrap 3-4 kritična screena
- 15min: Test

---

## Bug #5: Async Timeout-ovi

### Trenutno Stanje
**Status:** ❌ NIJE IMPLEMENTIRANO

Firestore query-ji i repository metode nemaju timeout. Može doći do beskonačnog čekanja.

### Plan Implementacije

#### Korak 1: Kreirati TimeoutConstants
**Fajl:** `lib/core/constants/timeout_constants.dart` (NOVI)

```dart
/// Standardizirani timeout-ovi za async operacije
class TimeoutConstants {
  TimeoutConstants._(); // Prevent instantiation

  /// Firestore query timeout (30 sekundi)
  static const Duration firestoreQuery = Duration(seconds: 30);

  /// HTTP request timeout (15 sekundi)
  static const Duration httpRequest = Duration(seconds: 15);

  /// Cloud Function call timeout (60 sekundi)
  static const Duration cloudFunction = Duration(seconds: 60);

  /// Real-time listener initial data timeout (10 sekundi)
  static const Duration realtimeInitial = Duration(seconds: 10);

  /// File upload timeout (2 minute)
  static const Duration fileUpload = Duration(minutes: 2);

  /// Short operation timeout (5 sekundi)
  static const Duration shortOperation = Duration(seconds: 5);
}
```

#### Korak 2: Kreirati AsyncUtils extension
**Fajl:** `lib/core/utils/async_utils.dart` (NOVI)

```dart
import 'dart:async';
import '../constants/timeout_constants.dart';

/// Extension za dodavanje standardnih timeout-ova na Future
extension FutureTimeoutExtension<T> on Future<T> {
  /// Dodaje standardni Firestore timeout (30s)
  Future<T> withFirestoreTimeout([String? operationName]) {
    return timeout(
      TimeoutConstants.firestoreQuery,
      onTimeout: () => throw TimeoutException(
        operationName != null
          ? '$operationName timed out after ${TimeoutConstants.firestoreQuery.inSeconds}s'
          : 'Firestore query timed out after ${TimeoutConstants.firestoreQuery.inSeconds}s',
      ),
    );
  }

  /// Dodaje standardni HTTP timeout (15s)
  Future<T> withHttpTimeout([String? operationName]) {
    return timeout(
      TimeoutConstants.httpRequest,
      onTimeout: () => throw TimeoutException(
        operationName != null
          ? '$operationName timed out after ${TimeoutConstants.httpRequest.inSeconds}s'
          : 'HTTP request timed out after ${TimeoutConstants.httpRequest.inSeconds}s',
      ),
    );
  }

  /// Dodaje standardni Cloud Function timeout (60s)
  Future<T> withCloudFunctionTimeout([String? operationName]) {
    return timeout(
      TimeoutConstants.cloudFunction,
      onTimeout: () => throw TimeoutException(
        operationName != null
          ? '$operationName timed out after ${TimeoutConstants.cloudFunction.inSeconds}s'
          : 'Cloud Function timed out after ${TimeoutConstants.cloudFunction.inSeconds}s',
      ),
    );
  }

  /// Dodaje custom timeout
  Future<T> withCustomTimeout(Duration duration, [String? operationName]) {
    return timeout(
      duration,
      onTimeout: () => throw TimeoutException(
        operationName != null
          ? '$operationName timed out after ${duration.inSeconds}s'
          : 'Operation timed out after ${duration.inSeconds}s',
      ),
    );
  }
}
```

#### Korak 3: Primijeniti na kritične repository metode
**Fajlovi:**
- `lib/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart`
- `lib/shared/data/firebase/firebase_booking_calendar_repository.dart`

Primjer primjene:

```dart
// PRIJE:
Future<OwnerBooking?> getOwnerBookingById(String bookingId) async {
  final doc = await _bookingsRef.doc(bookingId).get();
  // ...
}

// POSLIJE:
import '../../../../core/utils/async_utils.dart';

Future<OwnerBooking?> getOwnerBookingById(String bookingId) async {
  final doc = await _bookingsRef
      .doc(bookingId)
      .get()
      .withFirestoreTimeout('getOwnerBookingById');
  // ...
}
```

#### Korak 4: Primijeniti na provider-e
**Fajl:** `lib/features/owner_dashboard/presentation/providers/owner_bookings_provider.dart`

```dart
// U loadFirstPage() i loadMoreBottom():
Future<void> loadFirstPage() async {
  try {
    final bookings = await repository
        .getOwnerBookings(...)
        .withFirestoreTimeout('loadFirstPage');
    // ...
  } on TimeoutException catch (e) {
    state = state.copyWith(
      errorMessage: 'Request timed out. Please check your connection.',
      isLoadingTop: false,
    );
  }
}
```

### Procjena: 3h
- 30min: Kreirati TimeoutConstants i AsyncUtils
- 1.5h: Primijeniti na 5-6 kritičnih repository metoda
- 30min: Primijeniti na provider-e
- 30min: Test i error handling

---

## Bug #6: Provider AutoDispose

### Trenutno Stanje
**Status:** ⚠️ DJELOMIČNO IMPLEMENTIRANO

Analiza postojećih provider-a:
- `@Riverpod(keepAlive: true)` - 7 providera (ispravno za cached data)
- `@riverpod` (default, autoDispose: true) - ~30 providera (ispravno)

Provideri sa `keepAlive: true` (ISPRAVNO korištenje):
1. `analyticsProvider` - cache analytics data
2. `bookingsFiltersNotifierProvider` - persist filters
3. `ownerTotalBookingsProvider` - drawer stats
4. `ownerPendingBookingsCountProvider` - dashboard stats
5. `ownerPropertiesCalendarProvider` - calendar data
6. `ownerUnitIdsProvider` - unit IDs cache

### Plan Implementacije

#### Korak 1: Audit svih providera
Kreirati checklist:

```
[✅] analyticsProvider - keepAlive: true (CORRECT - expensive computation)
[✅] bookingsFiltersNotifierProvider - keepAlive: true (CORRECT - persist user filters)
[✅] ownerTotalBookingsProvider - keepAlive: true (CORRECT - drawer stats)
[✅] ownerPendingBookingsCountProvider - keepAlive: true (CORRECT - dashboard)
[✅] ownerPropertiesCalendarProvider - keepAlive: true (CORRECT - calendar data)
[✅] ownerUnitIdsProvider - keepAlive: true (CORRECT - used by 5+ providers)
[✅] ownerCalendarFiltersProvider - keepAlive: true (CORRECT - persist filters)
[⚠️] windowedBookingsNotifierProvider - @riverpod (CHECK - should it be keepAlive?)
```

#### Korak 2: Verificirati windowedBookingsNotifierProvider
**Fajl:** `lib/features/owner_dashboard/presentation/providers/owner_bookings_provider.dart`

```dart
// TRENUTNO:
@riverpod
class WindowedBookingsNotifier extends _$WindowedBookingsNotifier {
  // ...
}

// ANALIZA:
// - Koristi se samo na OwnerBookingsScreen
// - autoDispose je ispravno jer se state resetira kad user napusti screen
// - ZAKLJUČAK: ISPRAVNO - ne treba mijenjati
```

#### Korak 3: Dokumentirati odluke
Dodati komentare zašto je `keepAlive` korišten:

```dart
/// keepAlive: true - Cache analytics data to avoid expensive re-computation
/// Analytics include multiple Firestore queries and calculations
@Riverpod(keepAlive: true)
Future<AnalyticsSummary?> analytics(Ref ref) async {
  // ...
}
```

### Procjena: 2h
- 1h: Audit svih providera (17 fajlova)
- 30min: Verificirati i dokumentirati odluke
- 30min: Test memory usage

---

## Bug #7: Accessibility Labels

### Trenutno Stanje
**Status:** ⚠️ HELPER POSTOJI, NIJE KORIŠTEN

Postoji:
- `lib/core/accessibility/accessibility_helpers.dart`
  - `AccessibleIconButton`
  - `AccessibleInkWell`
  - `AccessibleGestureDetector`

Nedostaje:
- Nije korišteno u owner_dashboard widgetima
- Nedostaju tooltip-ovi na IconButton-ima

### Plan Implementacije

#### Korak 1: Identificirati kritične widgete
**Prioritetni fajlovi:**
1. `lib/features/owner_dashboard/presentation/widgets/owner_app_drawer.dart`
2. `lib/features/owner_dashboard/presentation/widgets/bookings/booking_card/*.dart`
3. `lib/features/owner_dashboard/presentation/widgets/calendar/booking_action_menu.dart`
4. `lib/features/owner_dashboard/presentation/screens/owner_bookings_screen.dart`

#### Korak 2: Zamijeniti IconButton sa AccessibleIconButton
**Primjer transformacije:**

```dart
// PRIJE:
IconButton(
  icon: Icon(Icons.delete),
  onPressed: () => _deleteBooking(),
)

// POSLIJE:
import '../../../../core/accessibility/accessibility_helpers.dart';

AccessibleIconButton(
  icon: Icons.delete,
  onPressed: () => _deleteBooking(),
  semanticLabel: l10n.bookingActionDelete, // 'Delete booking'
  tooltip: l10n.bookingActionDelete,
)
```

#### Korak 3: Dodati lokalizacijske stringove za accessibility
**Fajlovi:**
- `lib/l10n/app_en.arb`
- `lib/l10n/app_hr.arb`

```json
// app_en.arb
{
  "accessibilityDeleteBooking": "Delete booking",
  "accessibilityEditBooking": "Edit booking",
  "accessibilityApproveBooking": "Approve booking",
  "accessibilityRejectBooking": "Reject booking",
  "accessibilityOpenMenu": "Open menu",
  "accessibilityCloseMenu": "Close menu",
  "accessibilityRefreshList": "Refresh list",
  "accessibilityFilterBookings": "Filter bookings",
  "accessibilityPreviousPeriod": "Go to previous period",
  "accessibilityNextPeriod": "Go to next period",
  "accessibilityToday": "Go to today"
}
```

#### Korak 4: Sistematska zamjena po fajlovima

**owner_app_drawer.dart:**
```dart
// Sve navigacijske ikone
AccessibleIconButton(
  icon: Icons.dashboard,
  onPressed: () => context.go('/owner/dashboard'),
  semanticLabel: l10n.ownerDashboard,
)
```

**booking_card_actions.dart:**
```dart
// Action buttons
AccessibleIconButton(
  icon: Icons.check_circle,
  onPressed: onApprove,
  semanticLabel: l10n.accessibilityApproveBooking,
  color: Colors.green,
)
```

### Procjena: 4h
- 30min: Dodati lokalizacijske stringove
- 2h: Zamijeniti IconButton-e u 10+ fajlova
- 1h: Dodati Semantics widget gdje treba
- 30min: Test sa TalkBack/VoiceOver

---

## Bug #8: TODO Komentari

### Trenutno Stanje
**Status:** ❌ PLACEHOLDER IMPLEMENTACIJE

Lokacije:
1. `platform_connections_provider.dart` (linija 131)
2. `overbooking_notification_service.dart` (linije 28, 34, 40)

### Plan Implementacije

#### Korak 1: Analizirati platform_connections_provider.dart
**Fajl:** `lib/features/owner_dashboard/presentation/providers/platform_connections_provider.dart`

```dart
// Linija 131 - TODO komentar
// Ovo je placeholder za buduću integraciju sa Booking.com/Airbnb
```

**Akcija:** Dodati `@Deprecated` anotaciju ili ostaviti TODO sa milestone

```dart
/// Platform connection provider
///
/// TODO(v2.0): Implement actual Booking.com/Airbnb API integration
/// Currently blocked by: Direct API access not available for small properties
/// Workaround: iCal sync is implemented and working
@riverpod
Future<void> connectPlatform(Ref ref, String platform) async {
  // Placeholder - API integration planned for v2.0
  throw UnimplementedError(
    'Direct $platform API integration is planned for v2.0. '
    'Currently use iCal sync instead.',
  );
}
```

#### Korak 2: Dokumentirati overbooking_notification_service.dart

```dart
/// Overbooking notification service - PLACEHOLDER
///
/// Status: NOT IMPLEMENTED (MVP scope)
///
/// Planned features for v2.0:
/// - [ ] Email notifications to owners
/// - [ ] Push notifications via FCM
/// - [ ] Firestore notification documents
///
/// Current workaround: Manual conflict resolution via calendar UI
class OverbookingNotificationServiceImpl implements OverbookingNotificationService {
  @override
  Future<void> sendEmailNotification(OverbookingConflict conflict) async {
    // TODO(v2.0): Implement email notification
    // Requires: Email template, Resend API integration
    debugPrint('[OverbookingNotification] Email notification not implemented');
  }

  // ... similar for other methods
}
```

### Procjena: 1h
- 30min: Dokumentirati placeholder-e
- 30min: Dodati UnimplementedError gdje je potrebno

---

## Bug #9: Nedostaju Lokalizacije

### Trenutno Stanje
**Status:** ❌ HARDCODED STRINGOVI

Lokacija: `booking_action_menu.dart` (linije 316, 356, 391, 396)

Hardcoded stringovi:
- `'Konflikt sa:'` (linija 316)
- `'+${count} više...'` (linija 356)
- `'Uvezena rezervacija'` (linija 391)
- `'Upravljajte na ${platform}'` (linija 396)

### Plan Implementacije

#### Korak 1: Dodati stringove u app_en.arb
**Fajl:** `lib/l10n/app_en.arb`

```json
{
  "bookingActionConflictWith": "Conflict with:",
  "bookingActionMoreConflicts": "+{count} more...",
  "@bookingActionMoreConflicts": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "bookingActionImportedBooking": "Imported booking",
  "bookingActionManageOn": "Manage on {platform}",
  "@bookingActionManageOn": {
    "placeholders": {
      "platform": {
        "type": "String"
      }
    }
  }
}
```

#### Korak 2: Dodati stringove u app_hr.arb
**Fajl:** `lib/l10n/app_hr.arb`

```json
{
  "bookingActionConflictWith": "Konflikt sa:",
  "bookingActionMoreConflicts": "+{count} više...",
  "bookingActionImportedBooking": "Uvezena rezervacija",
  "bookingActionManageOn": "Upravljajte na {platform}"
}
```

#### Korak 3: Zamijeniti hardcoded stringove
**Fajl:** `lib/features/owner_dashboard/presentation/widgets/calendar/booking_action_menu.dart`

```dart
// PRIJE (linija 316):
Text('Konflikt sa:', ...)

// POSLIJE:
Text(l10n.bookingActionConflictWith, ...)

// PRIJE (linija 356):
Text('+${conflictingBookings!.length - 3} više...', ...)

// POSLIJE:
Text(l10n.bookingActionMoreConflicts(conflictingBookings!.length - 3), ...)

// PRIJE (linija 391):
Text('Uvezena rezervacija', ...)

// POSLIJE:
Text(l10n.bookingActionImportedBooking, ...)

// PRIJE (linija 396):
Text('Upravljajte na ${booking.sourceDisplayName}', ...)

// POSLIJE:
Text(l10n.bookingActionManageOn(booking.sourceDisplayName), ...)
```

#### Korak 4: Regenerirati lokalizacije

```bash
flutter gen-l10n
```

### Procjena: 1.5h
- 30min: Dodati stringove u ARB fajlove
- 30min: Zamijeniti hardcoded stringove
- 15min: Regenerirati lokalizacije
- 15min: Test

---

## Bug #10: RepaintBoundary Widget-i

### Trenutno Stanje
**Status:** ❌ NIJE IMPLEMENTIRANO

Kompleksni widgeti bez RepaintBoundary:
- Booking card-ovi u listi
- Calendar cell-ovi
- Stat card-ovi na dashboard-u

### Plan Implementacije

#### Korak 1: Identificirati kandidate za RepaintBoundary
**Kriteriji:**
- Widget se često rebuild-uje
- Widget ima kompleksan rendering (shadows, gradients)
- Widget je dio liste

**Kandidati:**
1. `BookingCard` - koristi se u ListView
2. `TimelineBookingBlock` - koristi se u calendar
3. `StatCard` - koristi se na dashboard

#### Korak 2: Wrap BookingCard
**Fajl:** `lib/features/owner_dashboard/presentation/screens/owner_bookings_screen.dart`

```dart
// U _buildBookingCard ili ListView.builder:
// PRIJE:
return _buildBookingCard(context, booking);

// POSLIJE:
return RepaintBoundary(
  child: _buildBookingCard(context, booking),
);
```

#### Korak 3: Wrap TimelineBookingBlock
**Fajl:** `lib/features/owner_dashboard/presentation/widgets/timeline/timeline_booking_block.dart`

```dart
// U build metodi:
@override
Widget build(BuildContext context) {
  return RepaintBoundary(
    child: GestureDetector(
      // ... postojeći kod
    ),
  );
}
```

#### Korak 4: Wrap StatCard
**Fajl:** Gdje god se koristi StatCard widget

```dart
RepaintBoundary(
  child: StatCard(
    title: 'Total Revenue',
    value: '\$12,345',
    // ...
  ),
)
```

#### Korak 5: Verificirati performance
```dart
// U debug mode, možeš koristiti:
debugRepaintRainbowEnabled = true;
// Ovo će pokazati rainbow boje kad se widget repaint-a
```

### Procjena: 1h
- 30min: Identificirati i wrap-ati 5-6 widgeta
- 30min: Test performance sa DevTools

---

## Redoslijed Implementacije

### Dan 1 (4h)
1. ✅ Bug #4: Error Boundaries (1h)
2. ✅ Bug #5: Async Timeouts - TimeoutConstants i AsyncUtils (1h)
3. ✅ Bug #5: Async Timeouts - Primjena na repository (2h)

### Dan 2 (4h)
1. ✅ Bug #6: Provider AutoDispose audit (2h)
2. ✅ Bug #9: Lokalizacije (1.5h)
3. ✅ Bug #10: RepaintBoundary (30min)

### Dan 3 (4-6h)
1. ✅ Bug #7: Accessibility Labels (4h)
2. ✅ Bug #8: TODO Komentari (1h)

---

## Checklist za Svaki Bug

### Prije implementacije:
- [ ] Pročitati relevantne fajlove
- [ ] Razumjeti postojeći kod
- [ ] Identificirati sve lokacije koje treba promijeniti

### Tijekom implementacije:
- [ ] Pratiti code style projekta
- [ ] Koristiti postojeće utility funkcije
- [ ] Dodati dokumentaciju gdje treba

### Nakon implementacije:
- [ ] `flutter analyze` - 0 issues
- [ ] Ručno testirati promjene
- [ ] Ažurirati OWNER_DASHBOARD_BUGS.md sa statusom

---

## Napomene

1. **Error Boundaries** - Već djelomično implementirano, samo treba dodati ErrorWidget.builder i wrap screens
2. **Provider AutoDispose** - Većina providera već koristi ispravne postavke, samo dokumentacija
3. **Accessibility** - AccessibleIconButton helper postoji, samo ga treba koristiti
4. **Lokalizacije** - Samo 4 stringa za dodati u booking_action_menu.dart
5. **RepaintBoundary** - Jednostavno wrap-anje, ali treba verificirati da ne uzrokuje probleme

---

## Git Commit Poruke

```
fix(error-handling): Add ErrorWidget.builder and wrap critical screens with ErrorBoundary

fix(async): Add TimeoutConstants and async timeout utilities

refactor(providers): Audit and document keepAlive decisions for all providers

feat(a11y): Replace IconButton with AccessibleIconButton across owner dashboard

docs(todo): Document placeholder implementations with milestone targets

fix(l10n): Add missing localizations for booking_action_menu.dart

perf(ui): Add RepaintBoundary to frequently rebuilt widgets
```
