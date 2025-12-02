# Claude Code - Project Documentation

Ova dokumentacija pomaže Claude Code sesijama da razumiju kritične dijelove projekta.

**Dodatni dokumenti:**
- [CLAUDE_MCP_TOOLS.md](./CLAUDE_MCP_TOOLS.md) - MCP serveri, slash commands, agenti
- [CLAUDE_WIDGET_SYSTEM.md](./CLAUDE_WIDGET_SYSTEM.md) - Widget modovi, payment logic, pricing
- [CLAUDE_BUGS_ARCHIVE.md](./CLAUDE_BUGS_ARCHIVE.md) - Arhivirani bug fix-evi (pre 2025-12-01)

---

## 📘 PROJECT OVERVIEW

**RabBooking** - Booking management platforma za property owner-e na otoku Rabu.

| Komponenta | Opis |
|------------|------|
| **Owner Dashboard** | Flutter Web admin panel |
| **Booking Widget** | Embeddable widget za web stranice |
| **Backend** | Firebase (Firestore, Cloud Functions, Auth) |

### Tehnologije
- Flutter 3.35.7, Riverpod 2.x, Firebase, Stripe Connect
- Feature-first structure, Repository pattern

### Status
- ✅ Owner dashboard - production-ready
- ✅ Booking widget - radi
- ⚠️ Hot reload/restart ne rade - normalno za Flutter Web

---

## 🎯 KRITIČNE SEKCIJE - NE MIJENJAJ!

### Unified Unit Hub
**File**: `unified_unit_hub_screen.dart`
**Status**: FINALIZED

- **Cjenovnik tab** je FROZEN - koristi kao referentnu implementaciju
- Responsive breakpoints: Desktop ≥1200px, Tablet 600-1199px, Mobile <600px
- NE MIJENJAJ bez eksplicitnog user zahtjeva

### Unit Wizard
**Folder**: `unit_wizard/`
**Status**: PRODUCTION READY

Publish flow kreira 3 Firestore dokumenta (redoslijed kritičan!):
1. Unit document
2. Widget settings
3. Initial pricing

### Timeline Calendar
**File**: `owner_timeline_calendar_screen.dart`

- Z-Index: Cancelled (0.6 opacity) renderuje PRVI, confirmed ZADNJI
- Gradient: DIJAGONALAN (`topLeft → bottomRight`), stops [0.0, 0.3]
- Headers: MORAJU biti transparent

### Owner Bookings Screen
**File**: `owner_bookings_screen.dart`

- Pending bookings: 2x2 button grid (Approve, Reject, Details, Cancel)
- Provider invalidation: POSLIJE repository poziva
- Skeleton loaders: RAZLIČITI za Card vs Table view

---

## 🎨 STANDARDI

### AppGradients ThemeExtension
```dart
final gradients = Theme.of(context).extension<AppGradients>()!;
gradients.pageBackground    // Screen body
gradients.sectionBackground // Cards, panels
gradients.brandPrimary      // AppBar, buttons
```

### Input Fields
- BorderRadius: **12px** (konzistentno!)
- Koristi `InputDecorationHelper.buildDecoration()`
- Theme defaults za border colors (ne hardcoded!)

### Responsive Pattern
```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 500) return Column(...);
    return Row(...);
  },
)
```

### Provider Invalidation
```dart
await repository.updateData(...);
ref.invalidate(dataProvider);  // POSLIJE save-a!
```

### Nested Config Update
```dart
// ✅ DOBRO
currentSettings.emailConfig.copyWith(requireEmailVerification: false)

// ❌ LOŠE - gubi ostala polja!
EmailNotificationConfig(requireEmailVerification: false)
```

---

## 🔧 ALATI (Summary)

Vidi [CLAUDE_MCP_TOOLS.md](./CLAUDE_MCP_TOOLS.md) za detalje.

**Aktivni MCP serveri**: dart-flutter, firebase, github, memory, context7, stripe, flutter-inspector, mobile-mcp

**Key slash commands**: `/ui`, `/firebase`, `/test`, `/stripe:*`, `/flutter:code-cleanup`

---

## 🔌 WIDGET SYSTEM (Summary)

Vidi [CLAUDE_WIDGET_SYSTEM.md](./CLAUDE_WIDGET_SYSTEM.md) za detalje.

**Modovi**: `calendarOnly`, `bookingPending`, `bookingInstant`

**Kritično**:
- `bookingPending` → `requireOwnerApproval` UVIJEK true
- `bookingInstant` → MORA imati barem 1 payment method
- Pricing: daily_price > weekend_price > base_price

---

## 📦 WIDGET REFACTORING (2025-12-01)

| Fajl | Linije | Status |
|------|--------|--------|
| `booking_widget_screen.dart` | 2,154 | Refaktorisan (-49%) |
| `year_calendar_widget.dart` | 946 | Refaktorisan |
| `month_calendar_widget.dart` | 872 | Refaktorisan |

**Ekstraktovani komponenti:**
- `calendar/` - date_utils, view_switcher, legend
- `confirmation/` - 7 komponenti
- `details/` - 8 komponenti
- `shared/utils/` - validators, snackbar_helper

---

## 📚 DODATNE REFERENCE

### iCal Integration
**Folder**: `screens/ical/`
- Export Screen ZAHTIJEVA params: `context.push()` sa extra, NE `context.go()`!
- Provider invalidation nakon CRUD operacija

### Bank Account Screen
**Route**: `/owner/integrations/payments/bank-account`
- Odvojen od Edit Profile
- Koristi CompanyDetails model

### Router
**File**: `router_owner.dart`
- `isLoading` check KRITIČAN (sprječava flash nakon registracije)
- Widget params na `/login` route prikazuju `BookingWidgetScreen` (Stripe return fix)

### Same-Tab Stripe Checkout (2025-12-02, Updated)
**File**: `booking_widget_screen.dart`
**Svrha**: Stripe plaćanje se otvara u ISTOM tabu, booking se kreira webhook-om NAKON plaćanja.

**Implementacija:**
```dart
// Web: Use window.location.href for same-tab redirect
if (kIsWeb) {
  html.window.location.href = checkoutResult.checkoutUrl;
} else {
  // Mobile: Use url_launcher (will open in browser)
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
```

**Flow (NEW - Webhook Creates Booking):**
```
1. User klikne "Pay with Stripe"
2. Form data se BRIŠE (sprječava conflict na povratku)
3. Isti tab prelazi na Stripe Checkout
4. User plaća
5. Stripe webhook kreira booking u Firestore sa stripe_session_id
6. Stripe redirect-a natrag sa ?stripe_status=success&session_id=cs_xxx
7. Widget poll-uje za booking koristeći session_id (max 30s)
8. Kad nađe booking, prikaže confirmation screen
```

**KRITIČNO - session_id Lookup (BUG FIX 2025-12-02):**
```dart
// Problem: URL nema bookingId jer webhook kreira booking NAKON redirect-a
// Rješenje: Poll Firestore po stripe_session_id

Future<void> _handleStripeReturnWithSessionId(String sessionId) async {
  // Poll max 15 attempts × 2s = 30 seconds
  for (var i = 0; i < 15; i++) {
    booking = await bookingRepo.fetchBookingByStripeSessionId(sessionId);
    if (booking != null) break;
    await Future.delayed(Duration(seconds: 2));
  }
  // Navigate to confirmation
}
```

**Model Fields Added:**
- `BookingModel.stripeSessionId` - za webhook lookup
- `BookingModel.bookingReference` - human-readable referenca (BK-xxx)

**Prednosti:**
- Nema popup-ova ili novih tabova
- Booking se kreira tek nakon USPJEŠNOG plaćanja
- Cross-tab komunikacija zadržana kao fallback

### Cross-Tab Communication (Optional Fallback)
**Files**: `tab_communication_service.dart`, `tab_communication_service_web.dart`
**Svrha**: Fallback mehanizam - šalje broadcast drugim tabovima kada plaćanje završi.

- **BroadcastChannel API** sa localStorage fallback
- Channel: `rab-booking-stripe`
- Message types: `paymentComplete`, `bookingCancelled`, `calendarRefresh`
- Inicijalizacija u `booking_widget_screen.dart` → `_initTabCommunication()`
- `fromOtherTab` parametar sprječava circular broadcasting

**Napomena:** Od 2025-12-02, same-tab redirect je primarni flow. Cross-tab komunikacija je zadržana samo kao fallback za slučaj da user ima više tabova otvorenih.

---

## 🐛 BUG FIX-EVI (2025-12-02)

### Calendar Pending Status - Diagonal Pattern & Colors
**Files**: `split_day_calendar_painter.dart`, `calendar_date_status.dart`

**Problem**: Dijagonalne linije na turnover days (pending bookings) bile teško vidljive, pogotovo u light theme.

**Rješenje**:
1. **Povećana debljina linije**: `strokeWidth` 1.5 → 2.0
2. **Nova boja**: Tamno zlatna/smeđa `#6B4C00` sa 60% opacity (umjesto `backgroundPrimary @ 40%`)

```dart
// calendar_date_status.dart - getPatternLineColor()
case DateStatus.pending:
  return const Color(0xFF6B4C00).withValues(alpha: 0.6); // Dark gold/brown
```

**Pending Status u Kalendaru - NE MIJENJAJ:**
- `DateStatus.pending` - žuta pozadina sa dijagonalnim uzorkom
- `needsDiagonalPattern` - vraća `true` samo za `pending`
- Split day (turnover) koristi `SplitDayCalendarPainter` za dijagonale
- `isCheckOutPending` / `isCheckInPending` - prati koja polovica je pending

### Booking Confirmation Navigation Fix
**File**: `booking_widget_screen.dart`, `booking_confirmation_screen.dart`

**Problem**: Back/Close dugmad na confirmation screen nisu radili za Pay on Arrival/Bank Transfer jer:
- State-based navigacija (`WidgetViewState`) držala isti URL
- Klik na Back/Close nije imao vizualni feedback

**Rješenje**: Refaktorisano na `Navigator.push()` za SVE payment flowove:

```dart
// PRIJE (state-based - LOŠE)
setState(() => _viewState = WidgetViewState.confirmation);

// POSLIJE (Navigator.push - DOBRO)
await Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => BookingConfirmationScreen(...)),
);
// Nakon pop-a, reset form state
_resetFormState();
_clearBookingUrlParams();
```

**Uklonjeno:**
- `WidgetViewState` enum
- `_viewState`, `_completedBooking`, `_completedPaymentMethod` state
- `_resetToCalendarView()` metoda

### Stripe Return - Calendar Instead of Confirmation
**Root Cause**: Stripe webhook kreira booking NAKON redirect-a, URL nema `bookingId`.

**Simptomi**:
- URL: `?stripe_status=success&session_id=cs_xxx` (bez `bookingId`)
- Cached form data se učita sa datumima koji su sada rezervisani
- Widget prikaže "conflict" umjesto confirmation

**Rješenje**:
1. **Clear form data PRIJE redirect-a na Stripe** (u `_handleStripePayment`)
2. **Nova metoda `fetchBookingByStripeSessionId()`** u repository
3. **Nova metoda `_handleStripeReturnWithSessionId()`** - poll-uje za booking
4. **Nova polja u `BookingModel`**: `stripeSessionId`, `bookingReference`

---

## 🎯 QUICK REFERENCE

### NIKADA NE MIJENJAJ:
1. Cjenovnik tab - frozen
2. Z-index sorting u Timeline Calendar
3. Wizard publish flow (3 docs redoslijed)
4. Input field borderRadius 12px
5. Gradient direkcija topLeft → bottomRight
6. Provider invalidation POSLIJE save-a
7. **Calendar Pending Status** - diagonal pattern, boje, `DateStatus.pending` logika
8. **Navigator.push za confirmation** - NE vraćaj state-based navigaciju!

### UVIJEK KORISTI:
1. `theme.colorScheme.*` (ne AppColors)
2. `InputDecorationHelper.buildDecoration()`
3. `.copyWith()` za nested config
4. `ref.invalidate()` POSLIJE repository poziva
5. `mounted` check prije async navigation

### PRIJE MIJENJANJA:
1. Pročitaj ovu dokumentaciju
2. Provjeri commit history
3. `flutter analyze` = 0 issues
4. PITAJ korisnika ako nešto čudno

---

**Last Updated**: 2025-12-02
**Version**: 3.1 (Bug fixes: Stripe session_id, Navigator.push, pending pattern)
