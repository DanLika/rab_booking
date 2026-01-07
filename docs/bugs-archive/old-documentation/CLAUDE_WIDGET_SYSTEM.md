# Widget System - Kompletna Dokumentacija

**Original Date**: 2025-11-27 | **Updated**: 2025-12-15
**Status**: DEFINITIVNA REFERENCA - Koristi za sve widget-related izmjene

Za glavni CLAUDE.md vidi: [CLAUDE.md](../../CLAUDE.md)

---

## VERIFICATION STATUS

| Item | Status | Last Verified |
|------|--------|---------------|
| WidgetMode enum (3 modes) | **VERIFIED** | 2025-12-15 |
| Payment methods logic | **VERIFIED** | 2025-12-15 |
| requireOwnerApproval logic | **VERIFIED** | 2025-12-15 |
| Deposit/Pricing hierarchy | **VERIFIED** | 2025-12-15 |
| Button text | **VERIFIED** | 2025-12-15 |

---

## Widget Modovi (WidgetMode enum)

**Location:** `lib/features/widget/domain/models/widget_mode.dart`

```dart
enum WidgetMode {
  calendarOnly,    // Samo kalendar - bez rezervacija
  bookingPending,  // Rezervacija bez placanja - ceka odobrenje
  bookingInstant,  // Puna rezervacija sa placanjem
}
```

### 1. `calendarOnly` - Samo Kalendar

| Aspekt | Vrijednost |
|--------|------------|
| Kalendar | View only (selekcija DISABLED) |
| Guest Form | NE prikazuje se |
| Payment Methods | NE prikazuje se |
| Contact Info | Pill card ispod kalendara |

### 2. `bookingPending` - Bez Placanja

| Aspekt | Vrijednost |
|--------|------------|
| Kalendar | Sa selekcijom datuma |
| Guest Form | Prikazuje se |
| Payment Methods | **NIKAD** se ne prikazuje |
| Button Text | "Send Booking Request - X nights" |

**KRITICNO:** `requireOwnerApproval` je **UVIJEK TRUE** za bookingPending (hardcoded u `submit_booking_use_case.dart:141`)!

### 3. `bookingInstant` - Sa Placanjem

| Aspekt | Vrijednost |
|--------|------------|
| Kalendar | Sa selekcijom datuma |
| Guest Form | Prikazuje se |
| Payment Methods | Stripe / Bank / Pay on Arrival |

---

## Payment Methods - Logika

**Location:** `lib/features/widget/presentation/screens/booking_widget_screen.dart:2262-2480`

### Validacija

- `bookingInstant` MORA imati barem JEDAN payment method (validira se u booking_widget_screen.dart:2264-2267)
- Ako nema nijednog payment method-a, prikazuje se NoPaymentInfo widget

### Bank Transfer - Bank Details Requirement

**VAZNO:** Bank details validacija se vrsi u **owner dashboard-u**, ne u widget-u:
- Widget prikazuje Bank Transfer ako je `bankTransferConfig.enabled == true`
- Owner dashboard validira da postoje bank details u CompanyDetails PRIJE nego dozvoli enable toggle
- Centralizirani bank details su u owner's **CompanyDetails** profilu

### Approval po Payment Metodi

| Payment Method | `requireOwnerApproval` |
|----------------|------------------------|
| **Stripe** | Konfigurabilan (moze FALSE) |
| **Bank Transfer** | Preporuceno TRUE |
| **Pay on Arrival** | Preporuceno TRUE |
| **bookingPending** | **UVIJEK TRUE** (hardcoded) |

**Code Location:** `lib/features/widget/domain/use_cases/submit_booking_use_case.dart:127-176`

```dart
// bookingPending - ALWAYS requires approval (line 141)
requireOwnerApproval: true,

// bookingInstant - configurable (line 174)
requireOwnerApproval: params.widgetSettings?.requireOwnerApproval ?? false,
```

### Button Text

**Location:** `lib/features/widget/presentation/screens/booking_widget_screen.dart:2718-2736`

| Payment Method | Button Text |
|----------------|-------------|
| `stripe` | "Pay with Stripe - X nights" |
| `bank_transfer` | "Continue to Bank Transfer - X nights" |
| `pay_on_arrival` | "Reserve - X nights" |
| `bookingPending` | "Send Booking Request - X nights" |
| Fallback | "Confirm Booking - X nights" |

---

## Deposit (Avans)

**Location:** `lib/features/widget/domain/models/widget_settings.dart:36`

```dart
globalDepositPercentage: int  // 0-100%, default 20%
```

**KRITICNO:** Koristi `globalDepositPercentage`, NE `stripeConfig.depositPercentage`!

Deposit se primjenjuje na SVE payment metode uniformno.

---

## Pricing Hijerarhija (Airbnb-style) - **VERIFIED**

**Location:** `lib/features/widget/data/helpers/booking_price_calculator.dart:249-298`

```
1. daily_prices[X].weekendPrice  <- Ako je vikend I weekendPrice postoji za taj datum
2. daily_prices[X].price         <- Custom cijena za datum
3. unit.weekendBasePrice         <- Za Sub/Ned ako nema daily_price
4. unit.pricePerNight            <- BASE FALLBACK
```

**Code:**
```dart
if (dailyPrice != null) {
  // Use daily_price with its getEffectivePrice logic
  priceForNight = dailyPrice.getEffectivePrice(weekendDays: weekendDays);
} else {
  // No daily_price -> use fallback from unit
  usedFallback = true;
  priceForNight = isWeekend && weekendBasePrice != null
      ? weekendBasePrice
      : basePrice;
}
```

---

## Widget Screen - Mode Handling

**Location:** `lib/features/widget/presentation/screens/booking_widget_screen.dart`

```dart
// Kalendar - disabled za calendarOnly
CalendarViewSwitcher(
  onRangeSelected: widgetMode == WidgetMode.calendarOnly ? null : (start, end) { ... },
)

// Pill Bar - NIKAD za calendarOnly
if (widgetMode != WidgetMode.calendarOnly && ...)

// Payment Section - SAMO za bookingInstant (starts at line 2304)
if (_widgetSettings?.widgetMode == WidgetMode.bookingInstant) ...[
  // Payment methods rendering (lines 2304-2480)
]

// bookingPending shows info message instead (line 2482)
if (_widgetSettings?.widgetMode == WidgetMode.bookingPending) ...[
  InfoCardWidget(message: tr.bookingPendingUntilConfirmed...)
]
```

---

## DO NOT

- NE PRIKAZUJ payment methods u `bookingPending` modu
- NE DOZVOLI `requireOwnerApproval = false` za `bookingPending`
- NE KORISTI `stripeConfig.depositPercentage` - koristi `globalDepositPercentage`
- NE DOZVOLI save `bookingInstant` bez barem jednog payment method-a
- NE DOZVOLI date selection u `calendarOnly` modu

## ALWAYS

- UVIJEK provjeri `widgetMode` prije prikaza sekcija
- UVIJEK koristi `globalDepositPercentage` za deposit kalkulacije
- UVIJEK validiraj payment methods pri save-u za `bookingInstant`
- UVIJEK hardcode `requireOwnerApproval: true` za `bookingPending` bookings
- UVIJEK koristi pricing hijerarhiju: daily_price > weekend_price > base_price

---

## KEY FILES REFERENCE

| File | Purpose |
|------|---------|
| `lib/features/widget/domain/models/widget_mode.dart` | WidgetMode enum definition |
| `lib/features/widget/domain/models/widget_settings.dart` | Widget settings including globalDepositPercentage |
| `lib/features/widget/domain/use_cases/submit_booking_use_case.dart` | Booking submission with approval logic |
| `lib/features/widget/presentation/screens/booking_widget_screen.dart` | Main widget UI with mode handling |
| `lib/features/widget/data/helpers/booking_price_calculator.dart` | Pricing hierarchy implementation |

---

## CHANGELOG

| Date | Change |
|------|--------|
| 2025-11-27 | Original documentation created |
| 2025-12-15 | Full verification against codebase |
| 2025-12-15 | Added code locations and line numbers |
| 2025-12-15 | Clarified bank details validation (owner dashboard, not widget) |
| 2025-12-15 | Added KEY FILES REFERENCE section |
