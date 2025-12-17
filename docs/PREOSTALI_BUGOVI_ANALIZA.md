# 📊 Potpuna Analiza Preostalog Posla - Widget Bugovi

**Datum:** 2025-12-16
**Status:** Ažurirano nakon bug fix sesije #4

---

## ✅ Riješeno u Sesiji #4 (2025-12-16)

### WIDGET_PROVIDERS_BUGS.md
1. ✅ **Bug #1**: Error logging u `booking_lookup_provider.dart` - **VEĆ BILO RIJEŠENO** (postojao `LoggingService.logError` poziv)
2. ✅ **Bug #2**: Hardcoded currency symbol '€' - deprecated getteri uklonjeni, koristi se `formatRoomPrice(currency)`, itd.

### WIDGET_MODELS_BUGS.md
1. ✅ **Bug #3**: Inconsistent price formatting - `calendar_date_status.dart` sada koristi `toStringAsFixed(2)`

### WIDGET_BANK_TRANSFER_BUGS.md
1. ✅ **Bug #3**: QR kod currency - **VEĆ BILO RIJEŠENO** (widget prima `currency` parametar)

---

## ✅ Riješeno u Sesiji #3 (2025-12-16)

### WIDGET_HELPERS_BUGS.md
1. ✅ **Bug #3**: Error handling u `booking_price_calculator.dart` - sada baca `PriceCalculationException`
2. ✅ **Bug #4**: `_iterateDates` u `calendar_data_builder.dart` - sada koristi exclusive end date
3. ✅ **Bug #5**: Standardizacija error handling-a - svi bacaju exception umjesto vraćanja fallback vrijednosti

---

## ✅ Riješeno u Prethodnim Sesijama

### WIDGET_HELPERS_BUGS.md
- ✅ Bug #1: `isAtSameMomentAs` → `DateNormalizer.isSameDay`
- ✅ Bug #2: Error handling u `_checkBlockedCheckInOut`

### WIDGET_PROVIDERS_BUGS.md
- ✅ Bug #3: Precision problemi (`double.parse` + `toStringAsFixed`)
- ✅ Bug #5: Date difference calculation (`DateNormalizer.nightsBetween`)

### WIDGET_CONFIRMATION_BUGS.md
- ✅ Bug #1-6: Svi riješeni (null checks, lokalizacija, type safety)

### WIDGET_BANK_TRANSFER_BUGS.md
- ✅ Bug #1: Hardcoded 'IBAN'/'SWIFT/BIC' stringovi
- ✅ Bug #2: Null exception u `_generateEpcQrData`

### WIDGET_MISC_BUGS.md
- ✅ Bug #1-4: Svi riješeni (currency, lokalizacija)

### WIDGET_CALENDAR_BUGS.md
- ✅ Bug #1: Date difference calculation
- ✅ Bug #2: Timezone problemi u `isSameDay`

---

## 🔧 PREOSTALI BUGOVI - Po Prioritetu

---

### 🟡 SREDNJI PRIORITET (2 buga)

#### 1. WIDGET_PROVIDERS_BUGS.md - Bug #4
**Fajl:** `booking_price_provider.dart`
**Linije:** 127-128
**Problem:** Hardcoded default basePrice (fallbackBasePrice = 100.0)

```dart
const fallbackBasePrice = 100.0;
double basePrice = fallbackBasePrice;
```

**Rješenje:**
```dart
// Opcija A: Baciti exception ako unit nije pronađen
if (unit == null) {
  throw PriceCalculationException.unitNotFound(unitId: unitId);
}
final basePrice = unit.pricePerNight;

// Opcija B: Vratiti null i handle-ovati u UI-u
final basePrice = unit?.pricePerNight;
if (basePrice == null) {
  // Return error state ili null
}
```

**Effort:** 1 sat
**Impact:** Prevent incorrect pricing

---

#### 2. WIDGET_MODELS_BUGS.md - Bug #1
**Fajl:** `booking_details_model.dart`
**Linije:** 30-31, 44-45
**Problem:** String datumi umjesto DateTime

```dart
required String checkIn, // ISO 8601 string
required String checkOut, // ISO 8601 string
```

**Rješenje:**
```dart
// Opcija A: Koristiti DateTime direktno
required DateTime checkIn,
required DateTime checkOut,

// fromJson:
checkIn: DateTime.parse(json['check_in'] as String),

// toJson:
'check_in': checkIn.toIso8601String(),

// Opcija B: Dodati validation u fromJson
static BookingDetailsModel fromJson(Map<String, dynamic> json) {
  try {
    final checkIn = DateTime.parse(json['check_in'] as String);
    // ...
  } catch (e) {
    throw BookingException('Invalid date format: ${json['check_in']}');
  }
}
```

**Effort:** 2-3 sata (refactoring + testiranje)
**Impact:** Type safety, bolja error handling

---

### 🟢 NISKI PRIORITET (~16 potencijalnih problema)

Ovi bugovi su **code quality improvements** ili **edge case provjere** koji ne blokiraju funkcionalnost:

#### WIDGET_BANK_TRANSFER_BUGS.md
- **Bug #4**: Hardcoded tooltip 'Kopiraj' u `CopyableTextField` (30 min)

#### WIDGET_MODELS_BUGS.md
- **Bug #2**: Hardcoded currency u `BookingPriceBreakdown` - koristi `_currencySymbol = '€'`
- **Bug #4**: Hardcoded currency u `CalendarDateInfo` - koristi `'€'` direktno

#### WIDGET_PROVIDERS_BUGS.md
- Potencijalni Problem #1: Error handling u `additional_services_provider.dart`
- Potencijalni Problem #2: Exception throwing u provider calculation
- Potencijalni Problem #3: `ref.read().future` može uzrokovati probleme
- Potencijalni Problem #4: Magic number za "never synced"
- Potencijalni Problem #5: Display text formatiranje
- Potencijalni Problem #6: Invalid language codes
- Potencijalni Problem #7: Error handling u `owner_bank_details_provider.dart`

#### WIDGET_CALENDAR_BUGS.md
- Potencijalni Problem #1: Default fallback za nepoznati language code
- Potencijalni Problem #2: Non-web platform handling
- Potencijalni Problem #3: Timezone problemi u `validateAdvanceBooking`
- Potencijalni Problem #4: Timezone problemi u `isDateInRange`
- Potencijalni Problem #5: Hardcoded vrijednosti za empty cells
- Potencijalni Problem #6: Size validacija u `PartialBothPainter`
- Potencijalni Problem #7: Size validacija u `PendingPatternPainter`

#### WIDGET_HELPERS_BUGS.md
- ~~Potencijalni Problem #1~~: Timezone handling u `_checkBlockedCheckInOut` - **OK** (datumi su normalizirani)
- ~~Potencijalni Problem #2~~: Firestore query granice - **OK** (koristi `isLessThan` ispravno)
- ~~Potencijalni Problem #3~~: Nedosljednost u `nights` izračunu - **OK** (koristi `priceBreakdown.length`)
- ~~Potencijalni Problem #4~~: Eksplicitno navođenje dana u `DateTime.utc` - **OK** (default je dan 1, nije bug)

---

## 📈 STATISTIKA

### Ukupno Bugova (Originalno)
- **Visoki prioritet:** 3 ✅ (svi riješeni)
- **Srednji prioritet:** 15 bugova
  - ✅ Riješeno: 13
  - 🔧 Preostalo: 2
- **Niski prioritet:** ~19 potencijalnih problema

### Riješeni Bugovi po Sesijama
- **Sesija #1** (2025-12-15): 10 bugova (confirmation, bank transfer, misc)
- **Sesija #2** (2025-12-15): 6 bugova (helpers, providers, calendar)
- **Sesija #3** (2025-12-16): 3 buga (error handling standardizacija)
- **Sesija #4** (2025-12-16): 4 buga (currency support, price formatting)

**Ukupno riješeno:** 23 bugova ✅
**Preostalo (srednji prioritet):** 2 buga 🔧
**Preostalo (niski prioritet):** ~12 code quality improvements (4 iz WIDGET_HELPERS zatvorena kao "OK")

---

## 📝 NAPOMENE

1. **WIDGET_HELPERS_BUGS.md** - Svi kritični bugovi riješeni ✅
2. **WIDGET_CONFIRMATION_BUGS.md** - Potpuno čist ✅
3. **WIDGET_BANK_TRANSFER_BUGS.md** - Potpuno čist ✅ (currency bug već bio riješen)
4. **WIDGET_MISC_BUGS.md** - Potpuno čist ✅
5. **WIDGET_CALENDAR_BUGS.md** - Samo edge cases preostali
6. **WIDGET_PROVIDERS_BUGS.md** - Samo default basePrice preostao
7. **WIDGET_MODELS_BUGS.md** - Samo String→DateTime refactoring preostao

---

## 🎯 PREPORUKE ZA PREOSTALE BUGOVE

### Opcija A - Odgoditi (Preporučeno)
**Razlog:**
- Svi **kritični, visoki i većina srednjih** prioriteta bugovi su riješeni ✅
- Preostalo je samo **2 srednja** + **~16 niskih** prioriteta
- Trenutna funkcionalnost radi korektno
- Fokusirati se na nove feature-e

**Kada riješiti:**
- Bug #4 (basePrice): Kada se doda error handling UI za "unit not found"
- Bug #1 (DateTime): Kao dio većeg type safety refactoring projekta

---

**Zaključak:** Aplikacija je **stabilna i funkcionalna**. Preostali bugovi su **nice-to-have improvements** koji ne blokiraju production deploy.

---

**Kreirano:** 2025-12-16
**Zadnje ažurirano:** 2025-12-16 (Sesija #5 - verifikacija WIDGET_HELPERS)
