# Bug Fix Master Plan - High & Medium Priority

**Kreirano:** 2025-12-16
**Zadnje ažurirano:** 2025-12-16
**Status:** U toku
**Procijenjeni scope:** 45+ bugova

---

## Pregled

Ovaj plan pokriva sve High i Medium priority bugove iz `OWNER_DASHBOARD_BUGS.md`. Bugovi su grupirani po kategorijama i prioritetu za efikasnije rješavanje.

### Već Riješeno (5 bugova):
- ✅ Bug #1: Memory leaks - Timer-i (VERIFIED OK)
- ✅ Bug #2: Race conditions (DEFENDED)
- ✅ Bug #3: Hardcoded debug log paths (FIXED)
- ✅ Bug #4: Error Boundaries (IMPLEMENTED - 2025-12-16)
- ✅ Bug #5: Async Timeout-ovi (IMPLEMENTED - 2025-12-16)

---

## FAZA 1: Kritični Infrastrukturni Bugovi

### 1.1 Error Boundaries (Bug #4) ✅ IMPLEMENTIRANO
**Prioritet:** HIGH | **Effort:** 2h | **Rizik:** Nizak
**Status:** ✅ IMPLEMENTIRANO (2025-12-16)

**Problem:** Nema globalnih error boundary-a - app crash ako exception u build metodi.

**Implementacija (verificirana):**
- ✅ `FlutterError.onError` handler u `lib/main.dart:69-93` (release mode)
- ✅ `ErrorWidget.builder` u `lib/main.dart:128-151` (debug i release)
- ✅ Firebase Crashlytics integracija za mobile
- ✅ Web-specific error handling (WebGL/CanvasKit errors)
- ✅ `GlobalErrorHandler.initialize()` za debug mode

**Lokacija:** `lib/main.dart` (linije 66-151)

---

### 1.2 Async Timeout-ovi (Bug #5) ✅ IMPLEMENTIRANO
**Prioritet:** HIGH | **Effort:** 3h | **Rizik:** Nizak
**Status:** ✅ IMPLEMENTIRANO (2025-12-16)

**Problem:** Neke async operacije nemaju timeout - beskonačno čekanje.

**Implementacija (verificirana):**
- ✅ `TimeoutConstants` klasa u `lib/core/constants/timeout_constants.dart`
  - `firestoreQuery: 30s`
  - `httpRequest: 15s`
  - `cloudFunction: 60s`
  - `realtimeInitial: 10s`
  - `fileUpload: 2min`
  - `shortOperation: 5s`
  - `bookingFetch: 10s`
  - `listFetch: 20s`
- ✅ `FutureTimeoutExtension` u `lib/core/utils/async_utils.dart`
  - `withFirestoreTimeout()`, `withHttpTimeout()`, `withCloudFunctionTimeout()`
  - `withBookingFetchTimeout()`, `withListFetchTimeout()`, `withShortTimeout()`
  - `withCustomTimeout(duration)`
- ✅ `StreamTimeoutExtension` za real-time listenere
  - `firstWithTimeout()`

**Lokacije:**
- `lib/core/constants/timeout_constants.dart`
- `lib/core/utils/async_utils.dart`

---

### 1.3 Provider AutoDispose (Bug #6)
**Prioritet:** MEDIUM | **Effort:** 2h | **Rizik:** Srednji

**Problem:** Neki provideri nemaju autoDispose - memory leak.

**Plan:**
1. Audit svih providera u `presentation/providers/`
2. Dodati `@Riverpod(keepAlive: false)` gdje treba
3. Zadržati `keepAlive: true` samo za cached data providere
4. Regenerirati `.g.dart` fajlove

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/providers/*.dart`

---

### 1.4 Accessibility Labels (Bug #7)
**Prioritet:** MEDIUM | **Effort:** 4h | **Rizik:** Nizak

**Problem:** Nedostaju semanticLabel/tooltip na interaktivnim elementima.

**Plan:**
1. Audit svih IconButton, InkWell, GestureDetector
2. Koristiti `AccessibleIconButton` iz `core/accessibility/`
3. Dodati `Semantics` widget gdje treba
4. Dodati `tooltip` na sve interaktivne elemente

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/widgets/*.dart`
- `lib/features/owner_dashboard/presentation/screens/*.dart`

---

## FAZA 2: Core Services Bugovi

### 2.1 Currency Service (Bug #13)
**Prioritet:** HIGH | **Effort:** 4h | **Rizik:** Srednji

**Problem:** Hardcoded exchange rates - mogu biti zastareli.

**Plan:**
1. Kreirati `ExchangeRateService` sa API fetch
2. Implementirati cache sa 24h TTL
3. Fallback na hardcoded rates ako API fail
4. Dodati provider za exchange rates

**Fajlovi:**
- `lib/core/services/exchange_rate_service.dart` (NOVI)
- `lib/core/services/currency_service.dart` (UPDATE)

**API opcije:**
- ExchangeRate-API (free tier: 1500 req/month)
- Fixer.io (free tier: 100 req/month)
- Open Exchange Rates

---

### 2.2 Email Notification Service (Bug #14)
**Prioritet:** HIGH | **Effort:** 3h | **Rizik:** Nizak

**Problem:** Nedostaje retry i rate limiting.

**Plan:**
1. Implementirati retry sa exponential backoff (max 3 attempts)
2. Dodati rate limiting (max 10 emails/minute)
3. Lokalizovati email subjects
4. Dodati timeout na HTTP pozive

**Fajlovi:**
- `lib/core/services/email_notification_service.dart`

**Kod:**
```dart
Future<void> _sendWithRetry(EmailRequest request) async {
  const maxAttempts = 3;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await _send(request).timeout(TimeoutConstants.httpRequest);
      return;
    } catch (e) {
      if (attempt == maxAttempts) rethrow;
      await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
    }
  }
}
```

---

### 2.3 External Calendar Sync (Bug #15)
**Prioritet:** HIGH | **Effort:** 2h | **Rizik:** Nizak

**Problem:** Placeholder implementacije bez timeout-ova.

**Plan:**
1. Dodati timeout na sve HTTP pozive
2. Implementirati proper error handling
3. Dodati logging za debug
4. Ostaviti placeholder za Booking.com/Airbnb (API nije dostupan)

**Fajlovi:**
- `lib/core/services/external_calendar_sync_service.dart`

---

### 2.4 iCal Export Service (Bug #16)
**Prioritet:** MEDIUM | **Effort:** 2h | **Rizik:** Nizak

**Problem:** Nedostaje retry i error handling za storage.

**Plan:**
1. Implementirati retry za storage upload (3 attempts)
2. Dodati streaming za velike fajlove
3. Validirati storage path
4. Dodati proper error messages

**Fajlovi:**
- `lib/core/services/ical_export_service.dart`

---

### 2.5 iCal Generator (Bug #17)
**Prioritet:** MEDIUM | **Effort:** 1h | **Rizik:** Nizak

**Problem:** Hardcoded timezone `Europe/Zagreb`.

**Plan:**
1. Dodati timezone kao parametar
2. Fallback na unit/property timezone
3. Dodati input validaciju
4. Poboljšati escape funkciju

**Fajlovi:**
- `lib/core/services/ical_generator.dart`

---

### 2.6 IP Geolocation Service (Bug #18)
**Prioritet:** MEDIUM | **Effort:** 2h | **Rizik:** Nizak

**Problem:** Nema caching - svaki poziv ide na API.

**Plan:**
1. Implementirati in-memory cache sa 24h TTL
2. Dodati rate limiting per provider
3. Implementirati circuit breaker za failed providere
4. Optimizovati fallback mehanizam

**Fajlovi:**
- `lib/core/services/ip_geolocation_service.dart`

---

### 2.7 HTTP Client Management (Bug #19)
**Prioritet:** MEDIUM | **Effort:** 2h | **Rizik:** Srednji

**Problem:** HTTP clienti se ne dispose-uju pravilno.

**Plan:**
1. Kreirati shared HTTP client provider
2. Koristiti DI za HTTP client
3. Osigurati proper dispose
4. Implementirati connection pooling

**Fajlovi:**
- `lib/core/providers/http_client_provider.dart` (NOVI)
- Svi servisi koji koriste HTTP

---

## FAZA 3: Core Utils Bugovi

### 3.1 Platform Utils (Bug #20)
**Prioritet:** HIGH | **Effort:** 1h | **Rizik:** Nizak

**Problem:** Platform detection može fail-ovati na webu.

**Plan:**
1. Dodati try-catch oko svih Platform poziva
2. Koristiti `kIsWeb` check prije Platform klase
3. Dodati fallback vrijednosti
4. Lokalizovati dialog tekstove

**Fajlovi:**
- `lib/core/utils/platform_utils.dart`

---

### 3.2 Profile Validators (Bug #21)
**Prioritet:** HIGH | **Effort:** 2h | **Rizik:** Nizak

**Problem:** Hardcoded error messages na engleskom.

**Plan:**
1. Dodati AppLocalizations parametar svim metodama
2. Kreirati lokalizacijske stringove
3. Implementirati proper IBAN checksum validaciju
4. Koristiti `package:email_validator`

**Fajlovi:**
- `lib/core/utils/profile_validators.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_hr.arb`

---

### 3.3 Responsive Breakpoints Consolidation (Bug #22)
**Prioritet:** MEDIUM | **Effort:** 2h | **Rizik:** Srednji

**Problem:** Više fajlova sa različitim breakpoint vrijednostima.

**Plan:**
1. Kreirati `BreakpointConstants` kao single source of truth
2. Migrirati sve fajlove na nove konstante
3. Ukloniti duplikate
4. Dodati dokumentaciju

**Fajlovi:**
- `lib/core/constants/breakpoint_constants.dart` (NOVI)
- `lib/core/utils/responsive_breakpoints.dart`
- `lib/core/utils/responsive_builder.dart`
- `lib/core/constants/breakpoints.dart`
- `lib/core/constants/app_dimensions.dart`

---

### 3.4 Responsive Builder Performance (Bug #23)
**Prioritet:** MEDIUM | **Effort:** 1h | **Rizik:** Nizak

**Problem:** LayoutBuilder rebuild na svaku promjenu constraints.

**Plan:**
1. Koristiti MediaQuery umjesto LayoutBuilder gdje moguće
2. Dodati const konstruktore
3. Dodati RepaintBoundary oko kompleksnih widgeta
4. Optimizovati ResponsiveGrid

**Fajlovi:**
- `lib/core/utils/responsive_builder.dart`

---

### 3.5 Responsive Dialog Utils (Bug #24)
**Prioritet:** MEDIUM | **Effort:** 1h | **Rizik:** Nizak

**Problem:** Hardcoded breakpoint vrijednosti.

**Plan:**
1. Koristiti BreakpointConstants
2. Dodati parameter validaciju
3. Dodati dokumentaciju
4. Kreirati DialogSizeConfig

**Fajlovi:**
- `lib/core/utils/responsive_dialog_utils.dart`

---

### 3.6 Responsive Spacing Helper (Bug #25)
**Prioritet:** MEDIUM | **Effort:** 1h | **Rizik:** Nizak

**Problem:** getScreenType se poziva više puta - performance.

**Plan:**
1. Kreirati cached screenType extension
2. Koristiti design tokens
3. Optimizovati switch expressione
4. Kreirati SpacingConfig

**Fajlovi:**
- `lib/core/utils/responsive_spacing_helper.dart`

---

## FAZA 4: Domain Models Bugovi

### 4.1 Analytics Summary (Bug #27)
**Prioritet:** HIGH | **Effort:** 1h | **Rizik:** Nizak

**Problem:** Nema validacija za negativne vrijednosti.

**Plan:**
1. Dodati validaciju u fromJson
2. Clamp occupancyRate na 0-100%
3. Clamp cancellationRate na 0-100%
4. Validirati revenue >= 0

**Fajlovi:**
- `lib/features/owner_dashboard/domain/models/analytics_summary.dart`

---

### 4.2 Bookings View Mode (Bug #28)
**Prioritet:** HIGH | **Effort:** 30min | **Rizik:** Nizak

**Problem:** Hardcoded display names.

**Plan:**
1. Ukloniti displayName getter iz enuma
2. Koristiti AppLocalizations u UI
3. Dodati logging za invalid values

**Fajlovi:**
- `lib/features/owner_dashboard/domain/models/bookings_view_mode.dart`

---

### 4.3 Calendar Filter Options (Bug #29)
**Prioritet:** MEDIUM | **Effort:** 1h | **Rizik:** Nizak

**Problem:** Nedostaju validacije.

**Plan:**
1. Dodati validate() extension metodu
2. Dodati normalize() za čišćenje praznih stringova
3. Limitirati broj filtera (max 50)
4. Validirati startDate <= endDate

**Fajlovi:**
- `lib/features/owner_dashboard/domain/models/calendar_filter_options.dart`

---

### 4.4 Date Range Selection (Bug #30)
**Prioritet:** MEDIUM | **Effort:** 2h | **Rizik:** Srednji

**Problem:** Kompleksna logika, hardcoded mjeseci.

**Plan:**
1. Koristiti `package:intl` za mjesece
2. Dodati startDate <= endDate validaciju
3. Implementirati lazy dates generator
4. Dodati unit testove za edge cases

**Fajlovi:**
- `lib/features/owner_dashboard/domain/models/date_range_selection.dart`

---

### 4.5 iCal Feed (Bug #31)
**Prioritet:** HIGH | **Effort:** 1h | **Rizik:** Nizak

**Problem:** Hardcoded stringovi, nedostaje validacija.

**Plan:**
1. Lokalizovati sve stringove
2. Dodati URL validaciju
3. Dodati error handling u fromFirestore
4. Koristiti AppLocalizations za time since sync

**Fajlovi:**
- `lib/features/owner_dashboard/domain/models/ical_feed.dart`

---

### 4.6 Notification Model (Bug #32)
**Prioritet:** MEDIUM | **Effort:** 1h | **Rizik:** Nizak

**Plan:**
1. Dodati validacije za required polja
2. Error handling za Firestore parsing
3. Lokalizovati display names
4. Validirati edge cases

**Fajlovi:**
- `lib/features/owner_dashboard/domain/models/notification_model.dart`

---

### 4.7 Onboarding State (Bug #33)
**Prioritet:** MEDIUM | **Effort:** 1h | **Rizik:** Nizak

**Plan:**
1. Dodati validacije
2. Error handling
3. Edge case handling

**Fajlovi:**
- `lib/features/owner_dashboard/domain/models/onboarding_state.dart`

---

### 4.8 Windowed Bookings State (Bug #34)
**Prioritet:** MEDIUM | **Effort:** 2h | **Rizik:** Srednji

**Problem:** Kompleksna logika, potencijalni race conditions.

**Plan:**
1. Dodati mutex za kritične sekcije
2. Validirati window boundaries
3. Dodati unit testove
4. Optimizovati performance

**Fajlovi:**
- `lib/features/owner_dashboard/domain/models/windowed_bookings_state.dart`

---

## FAZA 5: Screen & Widget Bugovi

### 5.1 Notification Settings Screen (Bug #35)
**Prioritet:** HIGH | **Effort:** 2h | **Rizik:** Nizak

**Plan:**
1. Implementirati optimistic updates
2. Dodati error recovery
3. Dodati loading states
4. Improve UX

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/screens/notification_settings_screen.dart`

---

### 5.2 Notifications Screen (Bug #36)
**Prioritet:** MEDIUM | **Effort:** 2h | **Rizik:** Srednji

**Plan:**
1. Simplificirati selection mode logiku
2. Fix memory leaks
3. Dodati proper dispose

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/screens/notifications_screen.dart`

---

### 5.3 Profile Screen (Bug #38)
**Prioritet:** MEDIUM | **Effort:** 1h | **Rizik:** Nizak

**Plan:**
1. Dodati error handling
2. Optimizacije
3. Loading states

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/screens/profile_screen.dart`

---

### 5.4 Property Form Screen (Bug #39)
**Prioritet:** HIGH | **Effort:** 3h | **Rizik:** Srednji

**Plan:**
1. Simplificirati logiku
2. Fix performance problemi
3. Fix memory leaks
4. Dodati proper validation

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/screens/property_form_screen.dart`

---

### 5.5 Stripe Connect Setup Screen (Bug #40)
**Prioritet:** HIGH | **Effort:** 2h | **Rizik:** Nizak

**Plan:**
1. Dodati timeout-ove
2. Error recovery
3. Loading states
4. Retry mechanism

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/screens/stripe_connect_setup_screen.dart`

---

### 5.6 Price Calendar State (Bug #42)
**Prioritet:** HIGH | **Effort:** 1h | **Rizik:** Nizak

**Plan:**
1. Dodati memory management
2. Cache size limit
3. Eviction policy

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/state/price_calendar_state.dart`

---

### 5.7 Scroll Direction Tracker (Bug #43)
**Prioritet:** MEDIUM | **Effort:** 30min | **Rizik:** Nizak

**Plan:**
1. Dodati edge case handling
2. Validacije

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/utils/scroll_direction_tracker.dart`

---

### 5.8 Booking Create Dialog (Bug #44)
**Prioritet:** MEDIUM | **Effort:** 2h | **Rizik:** Srednji

**Plan:**
1. Simplificirati validaciju
2. Fix race conditions
3. Dodati proper error handling

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/widgets/booking_create_dialog.dart`

---

### 5.9 Edit Booking Dialog (Bug #47)
**Prioritet:** HIGH | **Effort:** 2h | **Rizik:** Srednji

**Plan:**
1. Dodati timeout-ove
2. Fix race conditions
3. Error recovery

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/widgets/edit_booking_dialog.dart`

---

### 5.10 Embed Code Generator Dialog (Bug #48)
**Prioritet:** HIGH | **Effort:** 1h | **Rizik:** Nizak

**Plan:**
1. Konfigurabilni URL-ovi
2. Validacije
3. Error handling

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/widgets/embed_code_generator_dialog.dart`

---

### 5.11 Onboarding Property Step (Bug #50)
**Prioritet:** MEDIUM | **Effort:** 1h | **Rizik:** Nizak

**Plan:**
1. Dodati validacije
2. Fix auto-save issues
3. Error handling

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/widgets/onboarding/onboarding_property_step.dart`

---

### 5.12 Owner App Drawer (Bug #51)
**Prioritet:** MEDIUM | **Effort:** 1h | **Rizik:** Nizak

**Plan:**
1. Dodati error handling
2. Optimizacije

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/widgets/owner_app_drawer.dart`

---

### 5.13 Booking Action Menu (Bug #52)
**Prioritet:** MEDIUM | **Effort:** 1h | **Rizik:** Nizak

**Plan:**
1. Lokalizovati stringove
2. Dodati timeout-ove

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/widgets/calendar/booking_action_menu.dart`

---

### 5.14 Booking Block Widget (Bug #53)
**Prioritet:** MEDIUM | **Effort:** 1h | **Rizik:** Nizak

**Plan:**
1. Lokalizovati stringove
2. Dinamički locale

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/widgets/calendar/booking_block_widget.dart`

---

### 5.15 Booking Context Menu (Bug #54)
**Prioritet:** MEDIUM | **Effort:** 30min | **Rizik:** Nizak

**Plan:**
1. Lokalizovati stringove
2. Konfigurabilne dimenzije

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/widgets/calendar/booking_context_menu.dart`

---

### 5.16 Booking Drop Zone (Bug #55)
**Prioritet:** HIGH | **Effort:** 1h | **Rizik:** Nizak

**Plan:**
1. Lokalizovati stringove
2. Performance optimizacije

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/widgets/calendar/booking_drop_zone.dart`

---

### 5.17 Timeline Booking Block (Bug #56)
**Prioritet:** MEDIUM | **Effort:** 1h | **Rizik:** Nizak

**Plan:**
1. Dodati accessibility labels
2. Fix hardcoded vrijednosti

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/widgets/timeline/timeline_booking_block.dart`

---

### 5.18 Timeline Booking Stacker (Bug #57)
**Prioritet:** HIGH | **Effort:** 2h | **Rizik:** Srednji

**Plan:**
1. Simplificirati logiku
2. Fix edge cases
3. Dodati unit testove

**Fajlovi:**
- `lib/features/owner_dashboard/presentation/widgets/timeline/timeline_booking_stacker.dart`

---

## Raspored Implementacije

### Sprint 1 (Kritični infrastrukturni) - 50% ZAVRŠENO
| Bug | Opis | Effort | Status |
|-----|------|--------|--------|
| #4 | Error Boundaries | 2h | ✅ DONE |
| #5 | Async Timeouts | 3h | ✅ DONE |
| #20 | Platform Utils | 1h | ⏳ Pending |
| #21 | Profile Validators | 2h | ⏳ Pending |
| **Total** | | **8h** | **5h done** |

### Sprint 2 (Core Services)
| Bug | Opis | Effort |
|-----|------|--------|
| #13 | Currency Service | 4h |
| #14 | Email Notification | 3h |
| #15 | External Calendar Sync | 2h |
| #19 | HTTP Client Management | 2h |
| **Total** | | **11h** |

### Sprint 3 (Domain Models)
| Bug | Opis | Effort |
|-----|------|--------|
| #27 | Analytics Summary | 1h |
| #28 | Bookings View Mode | 30min |
| #29 | Calendar Filter Options | 1h |
| #30 | Date Range Selection | 2h |
| #31 | iCal Feed | 1h |
| #34 | Windowed Bookings State | 2h |
| **Total** | | **7.5h** |

### Sprint 4 (Screen Bugovi - High)
| Bug | Opis | Effort |
|-----|------|--------|
| #35 | Notification Settings | 2h |
| #39 | Property Form | 3h |
| #40 | Stripe Connect Setup | 2h |
| #42 | Price Calendar State | 1h |
| #47 | Edit Booking Dialog | 2h |
| #48 | Embed Code Generator | 1h |
| #55 | Booking Drop Zone | 1h |
| #57 | Timeline Booking Stacker | 2h |
| **Total** | | **14h** |

### Sprint 5 (Medium Priority)
| Bug | Opis | Effort |
|-----|------|--------|
| #6 | Provider AutoDispose | 2h |
| #7 | Accessibility Labels | 4h |
| #16-18 | iCal & Geolocation Services | 5h |
| #22-25 | Responsive Utils | 5h |
| #32-33 | Notification & Onboarding Models | 2h |
| #36, #38, #43-44, #50-56 | Remaining Screens/Widgets | 10h |
| **Total** | | **28h** |

---

## Ukupna Procjena

| Faza | Bugova | Effort |
|------|--------|--------|
| Sprint 1 | 4 | 8h |
| Sprint 2 | 4 | 11h |
| Sprint 3 | 6 | 7.5h |
| Sprint 4 | 8 | 14h |
| Sprint 5 | 20+ | 28h |
| **TOTAL** | **42+** | **~68.5h** |

---

## Napomene

1. **FROZEN fajlovi** - Bug #41 (Unified Unit Hub Screen) je FROZEN prema CLAUDE.md - NE DIRATI
2. **Testiranje** - Svaki fix treba testirati sa `flutter analyze` i ručno
3. **Dokumentacija** - Ažurirati OWNER_DASHBOARD_BUGS.md nakon svakog fixa
4. **Prioritet** - Započeti sa Sprint 1 jer su to infrastrukturni bugovi koji utječu na sve ostalo

---

## Checklist za Implementaciju

- [x] Sprint 1: Error Boundaries ✅, Timeouts ✅, Platform Utils ⏳, Validators ⏳
- [ ] Sprint 2: Core Services (Currency, Email, Calendar, HTTP)
- [ ] Sprint 3: Domain Models
- [ ] Sprint 4: High Priority Screens
- [ ] Sprint 5: Medium Priority Items
- [ ] Final: Ažurirati dokumentaciju

---

## Changelog

### 2025-12-16
- ✅ Bug #4 (Error Boundaries) verificiran kao IMPLEMENTIRAN - `FlutterError.onError` i `ErrorWidget.builder` postoje u `main.dart`
- ✅ Bug #5 (Async Timeouts) verificiran kao IMPLEMENTIRAN - `TimeoutConstants` i `async_utils.dart` postoje
