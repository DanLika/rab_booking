# Bug Fix Archive

Ova dokumentacija sadrži arhivirane bug fix-eve sa detaljnim code examples. Za kratki pregled kritičnih pravila, vidi [CLAUDE.md](./CLAUDE.md).

---

## 2025-01-27 - Floating Point Comparison Fixes

### Bug #66: Floating Point Comparison u Payment Info Card
**File**: `lib/features/widget/presentation/widgets/details/payment_info_card.dart:99`

**Problem**: Direktna floating point comparison (`remainingAmount > 0`) može uzrokovati probleme s floating point precision. Vrlo mali pozitivni brojevi (npr. 0.0001) mogu biti prikazani kao error umjesto success.

```dart
// PRIJE (LOŠE) - Direktna floating point comparison
_buildPaymentRow(
  tr.remaining, 
  remainingAmount, 
  color: remainingAmount > 0 ? colors.error : colors.success
),

// POSLIJE (DOBRO) - Tolerance-based comparison
import 'package:bookbed/features/widget/domain/constants/widget_constants.dart';

_buildPaymentRow(
  tr.remaining,
  remainingAmount,
  color: remainingAmount.abs() > WidgetConstants.priceTolerance
      ? colors.error
      : colors.success,
),
```

**Razlog**: 
- `WidgetConstants.priceTolerance` (0.01 = 1 cent) se već koristi u drugim dijelovima kodebaze
- Tolerance-based comparison osigurava da se vrlo mali iznosi (manji od 1 centa) tretiraju kao 0
- Koristi se `.abs()` da se osigura da se negativni iznosi (zbog grešaka) također tretiraju ispravno

### Bug #68: Floating Point Precision u Cancellation Policy Card
**File**: `lib/features/widget/presentation/widgets/details/cancellation_policy_card.dart:113-119`

**Problem**: Floating point division (`hours / 24`) može uzrokovati precision issues pri konverziji sati u dane.

```dart
// PRIJE (LOŠE) - Floating point division
if (hours >= 24) {
  final days = (hours / 24).round();
  return tr.canCancelUpToDays(days);
}

// POSLIJE (DOBRO) - Integer division sa rounding logic
if (hours >= 24) {
  // Bug #68 Fix: Use integer division for better precision
  // Avoid floating point precision issues by using integer arithmetic
  final days = hours ~/ 24; // Integer division
  final remainingHours = hours % 24;
  // Round up if more than half a day (12 hours)
  final roundedDays = remainingHours >= 12 ? days + 1 : days;
  return tr.canCancelUpToDays(roundedDays);
}
```

**Razlog**:
- Integer division (`~/`) eliminira floating point precision issues
- Eksplicitna rounding logika (round up ako je > 12 sati) osigurava konzistentno ponašanje
- Bolje performanse i predvidljivost

---

## 2025-12-03 - Calendar Repository Bug Fixes

### 1. Stream Error Handlers
**File**: `firebase_booking_calendar_repository.dart`

```dart
// PRIJE (LOŠE) - Stream se zaglavi na loading forever
).handleError((error, stackTrace) {
  LoggingService.logError(...);
  // NE VRAĆA NIŠTA!
});

// POSLIJE (DOBRO) - Vraća prazan calendar
).onErrorReturnWith((error, stackTrace) {
  LoggingService.logError(...);
  return <DateTime, CalendarDateInfo>{};
});
```

### 2. Turnover Detection
```dart
// PRIJE (LOŠE) - Samo provjera parcijalnih statusa
if (existingInfo.status == DateStatus.partialCheckIn ||
    existingInfo.status == DateStatus.partialCheckOut)

// POSLIJE (DOBRO) - Svi booked statusi
if (existingInfo.status == DateStatus.partialCheckIn ||
    existingInfo.status == DateStatus.partialCheckOut ||
    existingInfo.status == DateStatus.booked ||
    existingInfo.status == DateStatus.partialBoth)
```

### 3. Orphan Gap Logic
**File**: `year_calendar_widget.dart:702, 732`
- Dodano `DateStatus.partialBoth` u provjeru za next/prev blocked date

### 4. UTC Konzistencija
- Svi datumi koriste `DateTime.utc()` za map key lookup
- Gap blocking koristi UTC datume

---

## 2025-12-02/03 - Stripe Payment Flow Fixes

### Owner Email Always Sent (Bug #2)
**File**: `functions/src/atomicBooking.ts`

```typescript
// PRIJE (conditional - LOŠE)
const shouldSend = await shouldSendEmailNotification(ownerId, "bookings");
if (shouldSend) {
  await sendOwnerNotificationEmail(...);
}

// POSLIJE (always send - DOBRO)
await sendOwnerNotificationEmail(...);
```

### Calendar Pending Pattern Colors
**Files**: `split_day_calendar_painter.dart`, `calendar_date_status.dart`

```dart
// calendar_date_status.dart - getPatternLineColor()
case DateStatus.pending:
  return const Color(0xFF6B4C00).withValues(alpha: 0.6); // Dark gold/brown
```

### Booking Confirmation Navigation
```dart
// PRIJE (state-based - LOŠE)
setState(() => _viewState = WidgetViewState.confirmation);

// POSLIJE (Navigator.push - DOBRO)
await Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => BookingConfirmationScreen(...)),
);
_resetFormState();
_clearBookingUrlParams();
```

### Stripe Return - session_id Lookup
```dart
Future<void> _handleStripeReturnWithSessionId(String sessionId) async {
  // Poll max 15 attempts × 2s = 30 seconds
  for (var i = 0; i < 15; i++) {
    booking = await bookingRepo.fetchBookingByStripeSessionId(sessionId);
    if (booking != null) break;
    await Future.delayed(Duration(seconds: 2));
  }
}
```

---

## Pre 2025-12-01

---

## Stripe Connect - Return URL Fixes (2025-11-27)

**Problem 1**: `Uri.base.host` vraća hostname bez porta → Stripe vraćao na pogrešan URL
**Fix**: Koristi `Uri.base.authority` umjesto `Uri.base.host`

**Problem 2**: Widget slao returnUrl sa query params, Cloud Function dodavala `/booking-success`
**Fix**: Cloud Function sada pravilno appenda `&session_id=` ako URL već ima `?`

---

## Weekend Base Price (2025-11-26)

Price hijerarhija implementirana: `daily_price > weekendBasePrice > basePrice`

**Fajlovi**: `UnitModel`, `month_calendar_provider.dart`, `year_calendar_provider.dart`, `booking_price_provider.dart`

---

## minNights Bug Fix (2025-11-26)

**Problem**: Widget čitao minNights iz `widget_settings` umjesto `units`
**Fix**: `unit?.minStayNights ?? 1` u calendar widgetima

---

## Navigator Assertion Errors (2025-11-26)

**Pattern za izbjegavanje**: Wrap `Navigator.pop()` u `addPostFrameCallback`:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) Navigator.pop(context);
});
```

---

## Calendar Legend Width Fix (2025-11-26)

**Fix**: Dodani `Center` wrapper sa `maxWidth` constraint

---

## Contact Info Pills Layout (2025-11-26)

**Fix**: Breakpoint promijenjen 600→350px, maxWidth 170→500px

---

## Cross-Month Date Selection (2025-11-26)

**Problem**: Selekcija se brisala pri navigaciji između mjeseci
**Fix**: Briši samo ako je selekcija KOMPLETNA (oba datuma)

---

## Blocked Dates Bypass (2025-11-26)

**Security Fix**: `checkAvailability()` sada provjerava i `daily_prices.available === false`

---

## Backend Daily Price Validation (2025-11-26)

**Security Fix u Cloud Function**: Validacija `available`, `block_checkin`, `min/max_nights_on_arrival`

---

## Edit Date Dialog Cleanup (2025-11-26)

Uklonjen `isImportant`, dodani section headers, ExpansionTile za napredne opcije

---

## Real-Time Sync - StreamProvider (2025-11-26)

Konverzija `ownerPropertiesProvider` i `ownerUnitsProvider` u StreamProvider za live updates

---

## TextEditingController Disposal (2025-11-26)

**Pattern**: Dispose controllere u `addPostFrameCallback` nakon dialog-a

---

## Unit Hub Delete Button (2025-11-26)

Dodana `_confirmDeleteUnit()` metoda

---

## Auth Error Handling (2025-11-26)

Security logging wrapped u try-catch, loading spinner za social sign-in

---

## Pill Bar Auto-Open (2025-11-18-19)

**Fix**: 2 state flags (`_pillBarDismissed`, `_hasInteractedWithBookingFlow`) sa localStorage

---

## Advanced Settings Save (2025-11-17)

**Key Lesson**: UVIJEK koristi `.copyWith()` za nested config objekte!

---

## Same-Day Turnover Bookings (2025-11-16)

**Fix u atomicBooking.ts**: `.where("check_out", ">", checkInDate)` umjesto `>=`

---

## Property Deletion (2025-11-16)

**Fix**: PRVO delete iz Firestore, PA ONDA invalidate provider

---

## 2025-12-16 - Overbooking Detection & Warning Dialogs

### Bug #69: TimelineBookingBlock Inconsistent Conflict Detection
**Files**:
- `lib/features/owner_dashboard/presentation/widgets/timeline/timeline_booking_block.dart`
- `lib/features/owner_dashboard/presentation/widgets/timeline/timeline_grid_widget.dart`

**Problem**: TimelineBookingBlock koristio statičku metodu `BookingOverlapDetector.hasConflict()` umjesto centraliziranog providera, dok Bookings stranica koristi `isBookingInConflictProvider`. Ovo je rezultiralo:
1. Nekonzistentnim rezultatima između Timeline i Bookings pogleda
2. Ponovnim računanjem konflikata za svaki booking umjesto korištenja centraliziranih providera

```dart
// PRIJE (LOŠE) - Statička metoda, nije sinkronizirana s ostatkom app-a
class TimelineBookingBlock extends StatefulWidget {
  final Map<String, List<BookingModel>>? allBookingsByUnit; // Proslijeđeno ručno
  // ...
}

// U build metodi:
final hasConflict = BookingOverlapDetector.hasConflict(
  booking: booking,
  allBookings: widget.allBookingsByUnit?[booking.unitId] ?? [],
);

// POSLIJE (DOBRO) - Centralizirani provider
class TimelineBookingBlock extends ConsumerStatefulWidget {
  // allBookingsByUnit UKLONJEN - koristi se provider
  // ...
}

class _TimelineBookingBlockState extends ConsumerState<TimelineBookingBlock> {
  @override
  Widget build(BuildContext context) {
    // Koristi isti provider kao Bookings stranica
    final hasConflict = ref.watch(isBookingInConflictProvider(widget.booking.id));

    // Za tooltip sa konfliktnim bookingom
    final conflictsAsync = ref.watch(overbookingConflictsProvider);
    final allConflicts = conflictsAsync.valueOrNull ?? [];
    final conflictingBookings = allConflicts
        .where((c) => c.booking1.id == widget.booking.id ||
                      c.booking2.id == widget.booking.id)
        .expand((c) => [c.booking1, c.booking2])
        .where((b) => b.id != widget.booking.id)
        .toList();
  }
}
```

**Razlog**: Centralizirani provider osigurava:
- Konzistentno ponašanje između svih pogleda (Timeline, Bookings, Calendar)
- Automatsko ažuriranje kada se bookings promijene
- Bolju performansu (rezultati se cache-iraju u provideru)

### Bug #70: SkewedBookingPainter Missing Red Border for Conflicts
**File**: `lib/features/owner_dashboard/presentation/widgets/calendar/skewed_booking_painter.dart`

**Problem**: Painter je imao `hasConflict` parametar ali nije crtao drugačiju boju za konfliktne bookinge.

```dart
// PRIJE (LOŠE) - hasConflict se ignorirao
@override
void paint(Canvas canvas, Size size) {
  final path = _createSkewedPath(size);

  // Fill
  final fillPaint = Paint()..color = backgroundColor..style = PaintingStyle.fill;
  canvas.drawPath(path, fillPaint);

  // Border - ISTI za sve
  final borderPaint = Paint()
    ..color = borderColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = borderWidth;
  canvas.drawPath(path, borderPaint);
}

// POSLIJE (DOBRO) - Crveni border za konflikte
@override
void paint(Canvas canvas, Size size) {
  if (!size.width.isFinite || !size.height.isFinite ||
      size.width <= 0 || size.height <= 0) {
    return; // Skip invalid sizes
  }

  final path = _createSkewedPath(size);

  // Fill
  final fillPaint = Paint()..color = backgroundColor..style = PaintingStyle.fill;
  canvas.drawPath(path, fillPaint);

  // Border - CRVENI (2.5px) za konflikte, normalni inače
  final effectiveBorderColor = hasConflict ? Colors.red : borderColor;
  final effectiveBorderWidth = hasConflict ? 2.5 : borderWidth;

  final borderPaint = Paint()
    ..color = effectiveBorderColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = effectiveBorderWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.miter;
  canvas.drawPath(path, borderPaint);
}
```

### New Feature: UnblockWarningDialog
**File**: `lib/features/owner_dashboard/presentation/widgets/dialogs/unblock_warning_dialog.dart`

**Namjena**: Upozorenje prije ručnog otključavanja datuma kada unit ima aktivne platformske integracije.

```dart
// Korištenje:
final confirmed = await UnblockWarningDialog.show(
  context: context,
  platformName: 'Booking.com, Airbnb',
  startDate: DateTime(2025, 1, 15),
  endDate: DateTime(2025, 1, 20),
);

if (confirmed) {
  // Nastavi sa otključavanjem
}
```

**Značajke**:
- Prikazuje raspon datuma koji će biti otključani
- Lista rizika (greškom otkazano, gost planira reaktivirati, dupla rezervacija)
- Crveni "Da, Otključaj" button za jasnu potvrdu opasne akcije

### New Feature: UpdateBookingWarningDialog
**File**: `lib/features/owner_dashboard/presentation/widgets/dialogs/update_booking_warning_dialog.dart`

**Namjena**: Upozorenje prije promjene datuma rezervacije kada unit ima aktivne platformske integracije.

```dart
// Korištenje:
final confirmed = await UpdateBookingWarningDialog.show(
  context: context,
  oldCheckIn: DateTime(2025, 1, 15),
  oldCheckOut: DateTime(2025, 1, 20),
  newCheckIn: DateTime(2025, 1, 18),
  newCheckOut: DateTime(2025, 1, 23),
  platformNames: ['Booking.com', 'Airbnb'],
);

if (confirmed) {
  // Nastavi sa ažuriranjem
}
```

**Značajke**:
- Vizualno prikazuje stare vs nove datume
- Stari datumi (crveno) - bit će otključani
- Novi datumi (zeleno) - bit će zaključani
- Info sekcija pokazuje koje platforme će biti sinkronizirane

### Localization Keys Added
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_hr.arb`

```json
// UnblockWarningDialog
"warningUnblockDatesTitle": "Warning: Unblock Dates",
"warningUnblockDatesMessage": "Unblocking dates {dateRange} will make them available on {platform}.",
"warningUnblockDatesRisks": "This could lead to double-booking if:",
"riskCancelledByMistake": "The booking was cancelled by mistake",
"riskPlanToReactivate": "You plan to reactivate the booking",
"riskAnotherBookingExists": "Another booking already exists for these dates",
"yesUnblock": "Yes, Unblock",

// UpdateBookingWarningDialog
"warningUpdateBookingTitle": "Update Booking Dates",
"warningUpdateBookingMessage": "Updating booking dates will sync changes to external platforms:",
"oldDatesWillBeUnblocked": "Old dates (will be unblocked)",
"newDatesWillBeBlocked": "New dates (will be blocked)",
"platformSyncInfo": "Changes will be synced to: {platforms}",
"updateBooking": "Update Booking"
```
