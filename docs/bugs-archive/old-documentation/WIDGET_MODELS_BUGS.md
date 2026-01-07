# Analiza Bugova - Widget Model Files

**Datum analize:** 2024
**Lokacija:** `lib/features/widget/domain/models/`

## 📋 Pregled

Ovaj dokument sadrži analizu potencijalnih bugova i grešaka pronađenih u model klasama widget feature-a:
- `booking_details_model.dart`
- `booking_price_breakdown.dart`
- `booking_submission_result.dart`
- `calendar_date_status.dart`

---

## ⚠️ VAŽNA NAPOMENA O CURRENCY I DATUMIMA

### Multi-Currency Arhitektura

Aplikacija koristi **EUR kao storage currency** - sve cijene u Firestore-u su uvijek u EUR. Multi-currency podrška postoji kroz:

- `CurrencyService` (`lib/core/services/currency_service.dart`) - konverzija i formatiranje
- `PriceText` widget (`lib/shared/widgets/price_text.dart`) - automatska konverzija za prikaz
- `selectedCurrencyProvider` - korisnikov odabir valute (EUR, USD, GBP, HRK)

**Zašto modeli koriste hardcoded `€`:**
- Model klase (`BookingPriceBreakdown`, `CalendarDateInfo`) su za **internal data representation**
- `formattedPrice` getteri u modelima se koriste samo za **debug/logging**, ne za UI prikaz
- UI komponente koriste `PriceText` widget ili `CurrencyService` za prikaz korisnicima
- Promjena modela bi zahtijevala propagiranje `Currency` parametra kroz cijeli stack bez stvarne koristi

**Ovo NIJE bug** - to je svjesna arhitekturna odluka. Cijene se uvijek pohranjuju u EUR, a konverzija se radi samo na display layeru.

### String Datumi vs DateTime

`BookingDetailsModel` koristi `String` za datume jer:
- Backend (Cloud Function `verifyBookingAccess`) vraća ISO 8601 stringove
- Freezed model matchuje API response 1:1 za type safety
- Promjena bi zahtijevala update Cloud Function-a i sve klijente

**Ovo NIJE bug** - to je API contract između frontend-a i backend-a.

---

## 1. booking_details_model.dart

### ℹ️ Design Decision #1: String datumi umjesto DateTime
**Status:** ✅ NAMJERNO - API Contract
**Lokacija:** Linije 30-31, 44-45

**Kod:**
```dart
required String checkIn, // ISO 8601 string
required String checkOut, // ISO 8601 string
String? createdAt, // ISO 8601 string
String? paymentDeadline, // ISO 8601 string
```

**Objašnjenje:**
- Backend Cloud Function (`verifyBookingAccess`) vraća datume kao ISO 8601 stringove
- Freezed model matchuje API response 1:1
- Parsing se radi u UI layeru gdje je potreban (`DateTime.parse()`)
- Try-catch postoji u `booking_details_screen.dart` za graceful error handling

**Zašto se NE mijenja:**
- Promjena bi zahtijevala update Cloud Function-a
- Nema stvarnog benefita - parsing je trivijalan
- API contract je stabilan i testiran

---

### ℹ️ Design Decision #2: Nema validacije za ISO 8601 format
**Status:** ✅ NAMJERNO - Backend Controlled
**Lokacija:** Cijeli model

**Objašnjenje:**
- Backend kontrolira format datuma
- Freezed generirani `fromJson` kod radi 1:1 mapping
- Validacija na klijentu bi bila redundantna

---

## 2. booking_price_breakdown.dart

### ℹ️ Design Decision #3: Hardcoded currency symbol
**Status:** ✅ NAMJERNO - Storage Currency
**Lokacija:** Linija 2

**Kod:**
```dart
/// Currency symbol used throughout the app
const String _currencySymbol = '€';
```

**Objašnjenje:**
- EUR je storage currency - sve cijene u Firestore-u su u EUR
- `formattedPrice` getteri u modelu se koriste za logging/debug, ne za UI
- UI koristi `PriceText` widget ili `CurrencyService.formatPrice()` za multi-currency prikaz
- Vidi sekciju "Multi-Currency Arhitektura" iznad

**Zašto se NE mijenja:**
- Model je za internal representation, ne za UI display
- Dodavanje currency parametra bi kompliciralo API bez koristi
- `CurrencyService` već pokriva sve UI use case-ove

---

### ✅ Bug #3: Inconsistent price formatting - **RIJEŠENO**
**Prioritet:** Srednji
**Status:** ✅ RIJEŠENO (2025-12-16)
**Lokacija:** `calendar_date_status.dart` linija 154-156

**Problem:**
```dart
// booking_price_breakdown.dart
String _formatPrice(double amount) =>
    '$_currencySymbol${amount.toStringAsFixed(2)}';  // 2 decimale

// calendar_date_status.dart (PRIJE)
String? get formattedPrice {
  if (price == null) return null;
  return '€${price!.toStringAsFixed(0)}';  // 0 decimala
}
```

**Rješenje (PRIMIJENJENO):**
Standardizirano na 2 decimale u `calendar_date_status.dart`:
```dart
/// Get formatted price (e.g., "€50.00")
/// Bug #3 Fix: Standardized to 2 decimal places for consistency
String? get formattedPrice {
  if (price == null) return null;
  return '€${price!.toStringAsFixed(2)}';
}
```

---

### ℹ️ Design Decision #4: Default fallback u fromString
**Status:** ✅ NAMJERNO - Defensive Coding
**Lokacija:** Linija 120-125

**Kod:**
```dart
static ServicePricingType fromString(String value) => switch (value) {
  'per_stay' => ServicePricingType.perStay,
  'per_night' => ServicePricingType.perNight,
  'per_person' => ServicePricingType.perPerson,
  _ => ServicePricingType.perStay,  // Safe default
};
```

**Objašnjenje:**
- Default fallback na `perStay` je safe choice
- Baci exception bi crashao app za edge case
- `perStay` je najčešći pricing type, pa je logičan default
- Logging se može dodati za unknown values ako treba debugging

---

### ℹ️ Design Decision #7: Hardcoded fallbackBasePrice
**Status:** ✅ NAMJERNO - Defensive Coding
**Lokacija:** `booking_price_provider.dart` linije 111-112

**Kod:**
```dart
const fallbackBasePrice = 100.0;
double basePrice = fallbackBasePrice;
// ... later overwritten if unit.pricePerNight exists
```

**Objašnjenje:**
- Fallback se koristi SAMO kada se cijena ne može dohvatiti iz cache-a ili baze
- Logira warning kada se koristi: `logWarning('Using fallback base price...')`
- Prepisuje se stvarnom cijenom čim je dostupna (`basePrice = unit.pricePerNight`)
- Sprječava crash ako pricing podaci nisu dostupni

**Zašto se NE mijenja:**
- Ovo je defensive coding pattern - app ne smije crashati zbog missing data
- Warning log omogućava debugging ako se ikad dogodi
- Vrijednost 100.0 EUR je razumna default za booking preview

---

## 3. booking_submission_result.dart

### ✅ Nema bugova
**Status:** Čist

**Objašnjenje:**
- Koristi sealed class pattern što je dobar pristup
- Jasna separacija između Stripe i non-Stripe flow-a
- Nema pronađenih bugova

---

## 4. calendar_date_status.dart

### ℹ️ Design Decision #5: Hardcoded currency symbol
**Status:** ✅ NAMJERNO - Storage Currency
**Lokacija:** Linija 156

**Kod:**
```dart
String? get formattedPrice {
  if (price == null) return null;
  return '€${price!.toStringAsFixed(2)}';
}
```

**Objašnjenje:**
- Isto kao Design Decision #3
- Ovaj getter se koristi interno, UI koristi `PriceText` widget

---

### ℹ️ Design Decision #6: Hardcoded pattern line color
**Status:** ✅ NAMJERNO - Unique Visual Element
**Lokacija:** Linija 73

**Kod:**
```dart
Color getPatternLineColor(WidgetColorScheme colors) => switch (this) {
  DateStatus.pending => const Color(0xFF6B4C00).withValues(alpha: 0.6),
  _ => Colors.transparent,
};
```

**Objašnjenje:**
- Ova boja je specifična za pending diagonal pattern
- Koristi se samo na jednom mjestu (pending status overlay)
- Darker amber (`#6B4C00`) na lighter amber pozadini za kontrast
- Nije dio standardnog theme-a jer je jedinstvena za ovaj visual pattern
- Dark mode koristi istu boju jer pattern treba biti vidljiv na oba theme-a

---

## 📊 Sažetak

### ✅ Riješeni bugovi:
1. ✅ **Bug #3**: Inconsistent price formatting - **RIJEŠENO** (2025-12-16)

### ℹ️ Svjesne Design Decisions (NE bugovi):
1. **DD #1**: String datumi - API contract sa backend-om
2. **DD #2**: Nema ISO 8601 validacije - backend controlled
3. **DD #3**: Hardcoded € u BookingPriceBreakdown - storage currency
4. **DD #4**: Default fallback u fromString - defensive coding
5. **DD #5**: Hardcoded € u CalendarDateInfo - storage currency
6. **DD #6**: Hardcoded pattern color - unique visual element
7. **DD #7**: fallbackBasePrice = 100.0 - defensive coding sa logging

---

## 🔧 Ako Treba Multi-Currency u Modelima (Future)

Ako se u budućnosti odluči da modeli trebaju podržavati multi-currency:

```dart
// Opcija 1: Dodati currency u model
class BookingPriceBreakdown {
  final Currency currency;
  // ...
  String get formattedTotal => total.toCurrency(currency);
}

// Opcija 2: Ukloniti formatted* gettere iz modela
// i koristiti samo CurrencyService/PriceText u UI
```

**Preporuka:** Opcija 2 - modeli ne trebaju znati za formatiranje.

---

## 📝 Reference

- `CurrencyService`: [lib/core/services/currency_service.dart](../../lib/core/services/currency_service.dart)
- `PriceText` widget: [lib/shared/widgets/price_text.dart](../../lib/shared/widgets/price_text.dart)
- `verifyBookingAccess` CF: [functions/src/verifyBookingAccess.ts](../../functions/src/verifyBookingAccess.ts)

---

**Kreirano:** 2024
**Zadnje ažurirano:** 2025-12-16

## 📌 Changelog

### 2025-12-16
- ✅ Bug #3 riješen: Standardizirano price formatting na 2 decimale
- 📝 Dokumentacija ažurirana: Objašnjene design decisions vs bugovi
- 📝 Dodana sekcija "Multi-Currency Arhitektura"
- 📝 Preimenovani "bugovi" u "design decisions" gdje je primjenjivo
- 📝 Dodana DD #7: fallbackBasePrice defensive coding pattern
