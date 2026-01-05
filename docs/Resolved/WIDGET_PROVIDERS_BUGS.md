# Analiza Bugova - Widget Provider Files

**Datum analize:** 2024
**Zadnje ažurirano:** 2025-12-16
**Lokacija:** `lib/features/widget/presentation/providers/`

## 📋 Pregled

Ovaj dokument sadrži analizu potencijalnih bugova i grešaka pronađenih u provider klasama widget feature-a:
- `additional_services_provider.dart`
- `booking_lookup_provider.dart`
- `booking_price_provider.dart`
- `calendar_view_provider.dart`
- `ical_sync_status_provider.dart`
- `language_provider.dart`
- `owner_bank_details_provider.dart`

---

## 1. additional_services_provider.dart

### ✅ Problem #1: Nema error handling za repository pozive - **RIJEŠENO**
**Prioritet:** Srednji
**Status:** ✅ RIJEŠENO (2025-12-16) - **VEĆ BILO IMPLEMENTIRANO**
**Lokacija:** Linije 46-54

**Originalni problem:**
- Nema try-catch blokova za repository pozive
- Ako repository baci exception, provider će fail-ati

**Verifikacija (2025-12-16):**
Pri analizi ustanovljeno da je error handling **već bio implementiran**:
```dart
} catch (e, stackTrace) {
  // Log error and return empty list for graceful degradation
  await LoggingService.logError(
    'AdditionalServicesProvider: Failed to fetch services for unit $unitId',
    e,
    stackTrace,
  );
  return [];
}
```

**Utjecaj:** Bug je već bio riješen - postoji pravilno logiranje grešaka i graceful degradation.

---

### ⚠️ Potencijalni Problem #2: Exception throwing u provider calculation
**Prioritet:** Nizak  
**Lokacija:** Linija 63-66

**Problem:**
```dart
final service = services.firstWhere(
  (s) => s.id == serviceId,
  orElse: () => throw BookingException(
    'Additional service not found',
    code: 'booking/service-not-found',
  ),
);
```

**Objašnjenje:**
- Provider baca exception umjesto vraćanja error state-a
- Može uzrokovati probleme u UI-u ako se ne handle-uje pravilno
- Međutim, ovo je vjerojatno namjerno ponašanje

**Utjecaj:** Može uzrokovati probleme ako se exception ne handle-uje u UI-u.

---

## 2. booking_lookup_provider.dart

### ✅ Bug #1: Generic catch blok sakriva originalne greške - **RIJEŠENO**
**Prioritet:** Srednji
**Status:** ✅ RIJEŠENO (2025-12-16) - **VEĆ BILO IMPLEMENTIRANO**
**Lokacija:** Linija 75-83

**Problem:**
```dart
} catch (e) {
  throw BookingException.lookupFailed(e);
}
```

**Objašnjenje:**
- Generic catch blok hvata sve exception-e
- Wrap-uje ih u BookingException što može sakriti originalne greške
- Može otežati debugging

**Rješenje (PRIMIJENJENO):**
Pri analizi ustanovljeno da je error logging **već bio implementiran**:
```dart
} catch (e, stackTrace) {
  // Log the original error before wrapping it
  await LoggingService.logError(
    'BookingLookupService: Unexpected error during booking verification',
    e,
    stackTrace,
  );
  throw BookingException.lookupFailed(e);
}
```

**Utjecaj:** Bug je već bio riješen - postoji pravilno logiranje grešaka.

---

## 3. booking_price_provider.dart

### ✅ Bug #2: Hardcoded currency symbol - **RIJEŠENO**
**Prioritet:** Srednji
**Status:** ✅ RIJEŠENO (2025-12-16)
**Lokacija:** Linije 36-40

**Problem:**
```dart
String get formattedRoomPrice => '€${roomPrice.toStringAsFixed(2)}';
String get formattedAdditionalServices => '€${additionalServicesTotal.toStringAsFixed(2)}';
String get formattedTotal => '€${totalPrice.toStringAsFixed(2)}';
String get formattedDeposit => '€${depositAmount.toStringAsFixed(2)}';
String get formattedRemaining => '€${remainingAmount.toStringAsFixed(2)}';
```

**Objašnjenje:**
- Hardcoded '€' symbol - isti problem kao u modelima
- Ne podržava multi-currency

**Rješenje (PRIMIJENJENO):**
1. Deprecated getteri su uklonjeni
2. Koriste se format metode koje primaju currency parametar:
```dart
/// Format price with currency symbol
/// Multi-currency support: use currencySymbol from WidgetTranslations
String formatRoomPrice(String currency) => '$currency${roomPrice.toStringAsFixed(2)}';
String formatAdditionalServices(String currency) => '$currency${additionalServicesTotal.toStringAsFixed(2)}';
String formatTotal(String currency) => '$currency${totalPrice.toStringAsFixed(2)}';
String formatDeposit(String currency) => '$currency${depositAmount.toStringAsFixed(2)}';
String formatRemaining(String currency) => '$currency${remainingAmount.toStringAsFixed(2)}';
```
3. U `booking_widget_screen.dart` zamijenjeni svi pozivi sa:
```dart
final currency = WidgetTranslations.of(context, ref).currencySymbol;
calculation.formatRoomPrice(currency)
// itd.
```

**Utjecaj:** Sada podržava multi-currency funkcionalnost.

---

### ✅ Bug #3: Precision problemi s double.parse i toStringAsFixed - **RIJEŠENO**
**Prioritet:** Visok
**Status:** ✅ RIJEŠENO (2025-12-15)
**Lokacija:** Linije 68, 71, 157, 160 (ranije 67, 70, 155, 158)

**Problem:**
```dart
final newDeposit = double.parse((newTotal * (depositPercentage / 100)).toStringAsFixed(2));
final newRemaining = double.parse((newTotal * ((100 - depositPercentage) / 100)).toStringAsFixed(2));
```

**Objašnjenje:**
- Korištenje `double.parse` i `toStringAsFixed` može uzrokovati precision probleme
- Floating point aritmetika može dati nepredvidive rezultate
- Bolje koristiti decimal aritmetiku ili round funkcije

**Rješenje:**
```dart
// Opcija 1: Koristiti round funkciju
final newDeposit = (newTotal * (depositPercentage / 100) * 100).round() / 100;

// Opcija 2: Koristiti decimal paket
import 'package:decimal/decimal.dart';
final newDeposit = (Decimal.fromDouble(newTotal) * Decimal.fromDouble(depositPercentage / 100)).toDouble();
```

**Utjecaj:** Može uzrokovati rounding greške u finansijskim kalkulacijama.

---

### ℹ️ Bug #4: Hardcoded default basePrice - **NAMJERNO PONAŠANJE**
**Prioritet:** Nizak (informativno)
**Status:** ℹ️ NAMJERNO - fallback sa warning logom
**Lokacija:** Linija 111, 132-134, 146-148

**Originalni problem:**
```dart
const fallbackBasePrice = 100.0;
double basePrice = fallbackBasePrice;
```

**Objašnjenje:**
- Hardcoded default vrijednost od 100.0 služi kao fallback
- Koristi se SAMO ako unit nije pronađen (što ne bi trebalo da se desi)
- Warning log se ispisuje kada se koristi fallback

**Trenutna implementacija (2025-12-16):**
```dart
const fallbackBasePrice = 100.0;
double basePrice = fallbackBasePrice;
// ...
if (unit?.pricePerNight != null) {
  basePrice = unit!.pricePerNight;
} else {
  LoggingService.logWarning(
    'BookingPrice: Unit $unitId has no pricePerNight, using fallback $fallbackBasePrice',
  );
}
```

**Zaključak:** Ovo je **defanzivno programiranje** - fallback omogućava graceful degradation umjesto crasha. Warning log pomaže u debugiranju ako se fallback ikad koristi u produkciji.

---

### ✅ Bug #5: Potencijalni problem s date difference calculation - **RIJEŠENO**
**Prioritet:** Srednji
**Status:** ✅ RIJEŠENO (2025-12-15)
**Lokacija:** Linija 149 (ranije 147)

**Problem:**
```dart
final nights = checkOut.difference(checkIn).inDays;
```

**Objašnjenje:**
- `difference().inDays` može dati pogrešan rezultat ako datumi nisu normalizirani
- Ako checkIn ima vremensku komponentu, razlika može biti pogrešna
- Trebalo bi koristiti `DateNormalizer.nightsBetween` ili normalizirati datume prije

**Rješenje:**
```dart
final nights = DateNormalizer.nightsBetween(checkIn, checkOut);
```

**Utjecaj:** Može dati pogrešan broj noći ako datumi nisu normalizirani.

---

### ⚠️ Potencijalni Problem #3: ref.read().future može uzrokovati probleme
**Prioritet:** Nizak  
**Lokacija:** Linija 113

**Problem:**
```dart
final context = await ref.read(widgetContextProvider((propertyId: propertyId, unitId: unitId)).future);
```

**Objašnjenje:**
- `ref.read().future` može uzrokovati probleme ako provider nije inicijaliziran
- Može dovesti do race condition-a
- Međutim, postoji try-catch blok koji to handle-uje

**Utjecaj:** Vjerojatno OK zbog try-catch bloka, ali vrijedi provjeriti.

---

## 4. calendar_view_provider.dart

### ✅ Nema bugova
**Status:** Čist - jednostavan StateProvider bez problema.

---

## 5. ical_sync_status_provider.dart

### ⚠️ Potencijalni Problem #4: Magic number za "never synced"
**Prioritet:** Nizak  
**Lokacija:** Linija 99

**Problem:**
```dart
minutesSinceSync: 999999, // Very high number to indicate "never synced"
```

**Objašnjenje:**
- Magic number 999999 umjesto konstante
- Može biti zbunjujuće za čitaoce koda

**Rješenje:**
```dart
static const int neverSyncedIndicator = 999999;
```

**Utjecaj:** Nema funkcionalnog utjecaja, samo code clarity.

---

### ⚠️ Potencijalni Problem #5: Display text formatiranje može biti problematično
**Prioritet:** Nizak  
**Lokacija:** Linija 47

**Problem:**
```dart
displayText = 'External calendars last synced: ${hours}h ${minutes % 60}min ago';
```

**Objašnjenje:**
- Formatiranje vremena može biti problematično za internacionalizaciju
- Hardcoded string umjesto lokalizacije

**Utjecaj:** Ne podržava internacionalizaciju.

---

## 6. language_provider.dart

### ⚠️ Potencijalni Problem #6: Nema validacije za invalid language codes
**Prioritet:** Nizak  
**Lokacija:** Linija 30

**Problem:**
```dart
final langParam = uri.queryParameters['lang']?.toLowerCase();
if (langParam != null && supportedLanguages.contains(langParam)) {
  return langParam;
}
```

**Objašnjenje:**
- Ako se proslijedi neispravan language code, defaulta na 'hr'
- Možda bi bilo bolje logirati warning ili vratiti error

**Utjecaj:** Nema značajnog utjecaja, ali može sakriti probleme.

---

## 7. owner_bank_details_provider.dart

### ✅ Problem #7: Nema error handling - **RIJEŠENO**
**Prioritet:** Srednji
**Status:** ✅ RIJEŠENO (2025-12-16) - **VEĆ BILO IMPLEMENTIRANO**
**Lokacija:** Linije 20-32

**Originalni problem:**
- Nema try-catch bloka
- Ako repository baci exception, provider će fail-ati

**Verifikacija (2025-12-16):**
Pri analizi ustanovljeno da je error handling **već bio implementiran**:
```dart
try {
  final repository = UserProfileRepository();
  return await repository.getCompanyDetails(ownerId);
} catch (e, stackTrace) {
  // Log error and return null for graceful degradation
  // Bank details are optional - widget can still function without them
  await LoggingService.logError(
    'OwnerBankDetailsProvider: Failed to fetch bank details for owner $ownerId',
    e,
    stackTrace,
  );
  return null;
}
```

**Utjecaj:** Bug je već bio riješen - postoji pravilno logiranje grešaka i graceful degradation.

---

## 📊 Sažetak po prioritetima

### ✅ Riješeni bugovi:
1. ✅ **Bug #1**: Generic catch blok sakriva originalne greške - **VEĆ BILO RIJEŠENO** (2025-12-16)
2. ✅ **Bug #2**: Hardcoded currency symbol - **RIJEŠENO** (2025-12-16)
3. ✅ **Bug #3**: Precision problemi s double.parse i toStringAsFixed - **RIJEŠENO** (2025-12-15)
4. ✅ **Bug #5**: Potencijalni problem s date difference calculation - **RIJEŠENO** (2025-12-15)
5. ✅ **Problem #1**: Nema error handling u `additional_services_provider.dart` - **VEĆ BILO RIJEŠENO** (2025-12-16)
6. ✅ **Problem #7**: Nema error handling u `owner_bank_details_provider.dart` - **VEĆ BILO RIJEŠENO** (2025-12-16)

### ℹ️ Namjerno ponašanje (nije bug):
1. ℹ️ **Bug #4**: Hardcoded default basePrice - **NAMJERNO** (fallback sa warning logom)

### 🟢 Niski prioritet (code clarity - opciono):
1. Potencijalni Problem #2: Exception throwing u provider calculation (namjerno ponašanje)
2. Potencijalni Problem #3: ref.read().future (zaštićeno try-catch blokom)
3. Potencijalni Problem #4: Magic number za "never synced" (code clarity)
4. Potencijalni Problem #5: Display text formatiranje (internacionalizacija)
5. Potencijalni Problem #6: Nema validacije za invalid language codes (silent fallback na 'hr')

---

## 📝 Napomene

- Svi bugovi su identificirani kroz statičku analizu koda
- Preporučuje se testiranje svih popravki u development okruženju prije deploy-a
- Neki od "potencijalnih problema" mogu biti namjerno dizajnirano ponašanje
- Preporučuje se code review prije implementacije popravki

---

**Kreirano:** 2024
**Zadnje ažurirano:** 2025-12-16

## 📌 Changelog

### 2025-12-16 (Verifikacija)
- ✅ Problem #1 verificiran (VEĆ BILO IMPLEMENTIRANO): `additional_services_provider.dart` ima try-catch blok sa `LoggingService.logError` (linije 46-54)
- ✅ Problem #7 verificiran (VEĆ BILO IMPLEMENTIRANO): `owner_bank_details_provider.dart` ima try-catch blok sa `LoggingService.logError` (linije 20-32)
- ℹ️ Bug #4 preoznačen: Hardcoded basePrice je **namjerno ponašanje** - fallback sa warning logom za graceful degradation

### 2025-12-16
- ✅ Bug #1 riješen (VEĆ BILO IMPLEMENTIRANO): `booking_lookup_provider.dart` već ima `LoggingService.logError` poziv s stack trace-om
- ✅ Bug #2 riješen: Deprecated getteri uklonjeni, koriste se format metode (`formatRoomPrice(currency)`, itd.) koje primaju currency parametar iz `WidgetTranslations.currencySymbol`

### 2025-12-15
- ✅ Bug #3 riješen: Zamijenjeno `double.parse(...toStringAsFixed(2))` sa `(value * 100).roundToDouble() / 100` za preciznije zaokruživanje
- ✅ Bug #5 riješen: Zamijenjeno `checkOut.difference(checkIn).inDays` sa `DateNormalizer.nightsBetween(checkIn, checkOut)` za konzistentno računanje noći
