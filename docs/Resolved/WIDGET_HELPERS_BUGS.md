# Analiza Bugova - Widget Helper Files

**Datum analize:** 2024
**Zadnje ažurirano:** 2025-12-16
**Lokacija:** `lib/features/widget/data/helpers/`

## 📋 Pregled

Ovaj dokument sadrži analizu potencijalnih bugova i grešaka pronađenih u helper klasama widget feature-a:
- `availability_checker.dart`
- `booking_price_calculator.dart`
- `calendar_data_builder.dart`
- `helpers.dart` (barrel file - nema bugova)

---

## 1. availability_checker.dart

### ✅ Bug #1: Korištenje `isAtSameMomentAs` umjesto `DateNormalizer.isSameDay` - **RIJEŠENO**
**Prioritet:** Srednji
**Status:** ✅ RIJEŠENO (2025-12-15)
**Lokacija:** Linije 352 i 361 (ranije 421 i 436)

**Problem:**
```dart
// Linija 421
if (docDate.isAtSameMomentAs(checkIn)) {
  // ...
}

// Linija 436
if (docDate.isAtSameMomentAs(checkOut)) {
  // ...
}
```

**Objašnjenje:**
- `isAtSameMomentAs` uspoređuje točan trenutak uključujući vremenske komponente
- Iako su datumi normalizirani, ova metoda nije optimalna za usporedbu datuma
- Postoji rizik od problema s timezone-ovima ili preciznošću
- Kod već koristi `DateNormalizer.isSameDay` na drugim mjestima (npr. u `calendar_data_builder.dart` linija 243, 244, 324, 325)

**Rješenje:**
```dart
// Linija 421
if (DateNormalizer.isSameDay(docDate, checkIn)) {
  // ...
}

// Linija 436
if (DateNormalizer.isSameDay(docDate, checkOut)) {
  // ...
}
```

**Utjecaj:** Može uzrokovati probleme u edge case-ovima s timezone-ovima ili preciznošću datuma.

---

### ✅ Bug #2: Error handling vraća `available` umjesto error statusa - **RIJEŠENO**
**Prioritet:** Visok (sigurnosni problem)
**Status:** ✅ RIJEŠENO (2025-12-15)
**Lokacija:** Linija 373-375 (ranije 457)

**Problem:**
```dart
} catch (e) {
  unawaited(
    LoggingService.logError('Error checking blockCheckIn/blockCheckOut', e),
  );
  // Return available on error - don't block legitimate bookings
  return const AvailabilityCheckResult.available();
}
```

**Objašnjenje:**
- U slučaju greške, metoda vraća `available` umjesto error statusa
- Komentar kaže "don't block legitimate bookings", što je fail-open pristup
- Međutim, ovo može dozvoliti booking na datume koji su zapravo blokirani ako dođe do greške
- Fail-safe pristup bi bio vratiti error status

**Rješenje:**
```dart
} catch (e) {
  unawaited(
    LoggingService.logError('Error checking blockCheckIn/blockCheckOut', e),
  );
  // Fail-safe: return error status to prevent overbooking
  return AvailabilityCheckResult.error(ConflictType.blockedCheckIn);
}
```

**Utjecaj:** Sigurnosni problem - može dozvoliti preklapanje rezervacija ako dođe do greške u provjeri blokiranih check-in/check-out datuma.

---

### ⚠️ Potencijalni Problem #1: Timezone handling u `_checkBlockedCheckInOut`
**Prioritet:** Nizak  
**Lokacija:** Linije 402-403

**Problem:**
```dart
final checkInTimestamp = Timestamp.fromDate(checkIn);
final checkOutTimestamp = Timestamp.fromDate(checkOut);
```

**Objašnjenje:**
- `checkIn` i `checkOut` su normalizirani (UTC, 00:00:00)
- `Timestamp.fromDate` može imati problema ako se koriste lokalni datumi
- Međutim, pošto su datumi normalizirani, ovo bi trebalo biti OK
- Potrebno je provjeriti da li se datumi uvijek normaliziraju prije poziva

**Utjecaj:** Vjerojatno OK, ali vrijedi provjeriti u produkciji.

---

## 2. booking_price_calculator.dart

### ✅ Bug #3: Nedosljednost u error handling-u - **RIJEŠENO**
**Prioritet:** Srednji
**Status:** ✅ RIJEŠENO (2025-12-16)
**Lokacija:** Linija 153-167

**Problem:**
```dart
} catch (e) {
  if (e is DatesNotAvailableException) rethrow;

  unawaited(LoggingService.logError('Error calculating booking price', e));
  return const PriceCalculationResult.zero();
}
```

**Objašnjenje:**
- Ako dođe do greške, vraćao se `zero()` rezultat
- To je skrivalo stvarne probleme (npr. Firestore greške, network greške)
- Otežavalo debugging i maskirao kritične greške

**Rješenje:**
Dodana nova `PriceCalculationException` klasa u `app_exceptions.dart` i promijenjen error handling:
```dart
} catch (e) {
  if (e is DatesNotAvailableException) rethrow;
  if (e is PriceCalculationException) rethrow;

  unawaited(LoggingService.logError('Error calculating booking price', e));
  // Bug Fix #3: Throw exception instead of returning zero to expose errors
  throw PriceCalculationException.failed(
    unitId: unitId,
    checkIn: checkIn,
    checkOut: checkOut,
    error: e,
  );
}
```

**Utjecaj:** Greške su sada vidljive i mogu se pravilno handle-ovati u UI layeru.

---

### ⚠️ Potencijalni Problem #2: Firestore query može propustiti datume na granicama
**Prioritet:** Nizak  
**Lokacija:** Linije 191-192

**Problem:**
```dart
.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(checkIn))
.where('date', isLessThan: Timestamp.fromDate(checkOut))
```

**Objašnjenje:**
- Query koristi `isLessThan` za `checkOut`, što je ispravno (exclusive end)
- Međutim, treba provjeriti da li su `checkIn` i `checkOut` normalizirani prije poziva
- Ako nisu normalizirani, mogu se pojaviti problemi s vremenskim komponentama

**Utjecaj:** Izgleda OK, ali vrijedi provjeriti da li su datumi uvijek normalizirani.

---

### ⚠️ Potencijalni Problem #3: Nedosljednost u `nights` izračunu
**Prioritet:** Nizak (nije bug, samo cleanup)  
**Lokacija:** Linija 257

**Problem:**
```dart
return PriceCalculationResult(
  totalPrice: total,
  nights: priceBreakdown.length,  // Ovo je OK
  priceBreakdown: priceBreakdown,
  usedFallback: usedFallback,
  weekendNights: weekendNights,
);
```

**Objašnjenje:**
- `nights: priceBreakdown.length` je ispravno jer se `priceBreakdown` popunjava za svaku noć
- Međutim, postoji varijabla `nights` izračunata ranije (linija 108) koja se ne koristi
- Ovo nije bug, ali može biti zbunjujuće

**Utjecaj:** Nema funkcionalnog utjecaja, samo code clarity.

---

## 3. calendar_data_builder.dart

### ✅ Bug #4: `_iterateDates` uključuje end date - **RIJEŠENO**
**Prioritet:** Srednji
**Status:** ✅ RIJEŠENO (2025-12-16)
**Lokacija:** Linija 218-237 (`_iterateDates`), Linija 239-280 (`_markDateRange`)

**Problem:**
```dart
void _iterateDates(
  DateTime start,
  DateTime end,
  void Function(DateTime date) action,
) {
  var current = start;
  while (!current.isAfter(end)) {  // Uključuje end date
    action(current);
    current = current.add(_oneDay);
  }
}
```

**Objašnjenje:**
- Metoda je uključivala `end` datum u iteraciju
- Za booking logiku, check-out dan se NE računa kao noć (standardna praksa)
- iCal eventi su pogrešno označavali checkout dan kao booked

**Rješenje:**
1. Promijenjen `_iterateDates` da koristi exclusive end date (`current.isBefore(end)`)
2. Ažuriran `_markDateRange` da eksplicitno označi checkout dan kao `partialCheckOut`

```dart
// _iterateDates - sada exclusive
void _iterateDates(DateTime start, DateTime end, void Function(DateTime date) action) {
  var current = start;
  while (current.isBefore(end)) {  // ✅ Exclusive end
    action(current);
    current = current.add(_oneDay);
  }
}

// _markDateRange - eksplicitno označava checkout dan
void _markDateRange({...}) {
  // Mark all nights (check-in through day before check-out)
  _iterateDates(start, end, (current) {
    final status = _determineStatus(
      isCheckInDay: DateNormalizer.isSameDay(current, checkIn),
      isCheckOutDay: false, // Never true in iteration
      isPending: isPending,
    );
    calendar[current] = CalendarDateInfo(...);
  });

  // Bug Fix #4: Explicitly mark checkout day
  if (!checkOut.isBefore(start) && !checkOut.isAfter(end)) {
    final checkoutStatus = isPending ? DateStatus.pending : DateStatus.partialCheckOut;
    calendar[checkOut] = CalendarDateInfo(date: checkOut, status: checkoutStatus, ...);
  }
}
```

**Utjecaj:**
- iCal eventi sada ispravno označavaju samo noći (checkout dan je dostupan)
- Regularni bookingi i dalje ispravno prikazuju checkout dan kao `partialCheckOut`
- Standardizirano ponašanje sa booking industrijom

---

### ⚠️ Potencijalni Problem #4: Nedosljednost u inicijalizaciji mjeseca
**Prioritet:** Nizak (code clarity)  
**Lokacija:** Linija 68

**Problem:**
```dart
final monthStart = DateTime.utc(year, month);
```

**Objašnjenje:**
- `DateTime.utc(year, month)` defaulta na dan 1, što je ispravno
- Međutim, eksplicitno navođenje dana bi bilo jasnije: `DateTime.utc(year, month, 1)`
- Ovo nije bug, ali je manje čitljivo

**Rješenje:**
```dart
final monthStart = DateTime.utc(year, month, 1);
```

**Utjecaj:** Nema funkcionalnog utjecaja, samo code clarity.

---

### ⚠️ Potencijalni Problem #5: Gap blocking logika može imati edge case
**Prioritet:** Nizak  
**Lokacija:** Linija 287

**Problem:**
```dart
final gapDays = gapEnd.difference(gapStart).inDays;

if (gapDays <= 0) continue;
```

**Objašnjenje:**
- `gapDays` se računa kao razlika između `gapEnd` i `gapStart`
- Ako su bookingi back-to-back (checkOut = checkIn), `gapDays` će biti 0
- Međutim, ako je `gapEnd` prije `gapStart`, `gapDays` će biti negativan
- Provjera `gapDays <= 0` pokriva oba slučaja, što je OK

**Utjecaj:** Izgleda OK, logika je ispravna.

---

### ⚠️ Potencijalni Problem #6: `_blockGapDates` može prebrisati postojeće statusove
**Prioritet:** Nizak  
**Lokacija:** Linija 310

**Problem:**
```dart
final existingInfo = calendar[current];
if (existingInfo?.status == DateStatus.available) {
  calendar[current] = existingInfo!.copyWith(status: DateStatus.blocked);
}
```

**Objašnjenje:**
- Metoda blokira samo datume koji su `available`
- Međutim, ako je datum već `booked` ili `pending`, neće ga blokirati
- Ovo može biti problem ako postoji booking u gap-u
- Međutim, ovo je vjerojatno namjerno - ne blokiraj već rezervirane datume

**Utjecaj:** Vjerojatno namjerno ponašanje, ali vrijedi provjeriti.

---

## 4. Opći problemi

### ✅ Bug #5: Nedosljednost u error handling-u između metoda - **RIJEŠENO**
**Prioritet:** Srednji
**Status:** ✅ RIJEŠENO (2025-12-16)

**Problem:**
- Neke metode vraćale error status (`AvailabilityCheckResult.error`)
- Druge metode vraćale `available` na grešku
- Treće metode vraćale `zero()` rezultat

**Primjeri (prije popravke):**
- `_checkBookings` vraća `AvailabilityCheckResult.error(ConflictType.booking)` na grešku ✅
- `_checkIcalEvents` vraća `AvailabilityCheckResult.error(ConflictType.icalEvent)` na grešku ✅
- `_checkBlockedDates` vraća `AvailabilityCheckResult.error(ConflictType.blockedDate)` na grešku ✅
- `_checkBlockedCheckInOut` vraćao `AvailabilityCheckResult.available()` na grešku ⚠️ → **RIJEŠENO** (Bug #2)
- `calculate` vraćao `PriceCalculationResult.zero()` na grešku ⚠️ → **RIJEŠENO** (Bug #3)

**Rješenje:**
Svi error handleri sada konzistentno vraćaju error status ili bacaju exception:
- Availability checker metode: vraćaju `AvailabilityCheckResult.error()`
- Price calculator: baca `PriceCalculationException`

**Utjecaj:** Svi bugovi sada koriste fail-safe pristup koji sprječava tihe greške.

---

### ⚠️ Potencijalni Problem #7: Potencijalni memory leak s `unawaited`
**Prioritet:** Nizak  
**Lokacija:** Više mjesta

**Problem:**
```dart
unawaited(LoggingService.logError('Error parsing booking document', e));
```

**Objašnjenje:**
- `unawaited` se koristi za fire-and-forget async pozive
- Ako `LoggingService.logError` baci exception, neće biti uhvaćen
- Međutim, za logging, ovo je vjerojatno OK

**Utjecaj:** Nema značajnog utjecaja, logging greške ne bi trebale blokirati glavni flow.

---

## 📊 Sažetak po prioritetima

### 🔴 Visoki prioritet (treba popraviti odmah):
1. ✅ **Bug #2**: Error handling u `_checkBlockedCheckInOut` vraća `available` umjesto error statusa (sigurnosni problem) - **RIJEŠENO**

### 🟡 Srednji prioritet (treba popraviti uskoro):
1. ✅ **Bug #1**: Korištenje `isAtSameMomentAs` umjesto `DateNormalizer.isSameDay` - **RIJEŠENO**
2. ✅ **Bug #3**: Nedosljednost u error handling-u u `calculate` metodi - **RIJEŠENO**
3. ✅ **Bug #4**: `_iterateDates` uključuje end date - **RIJEŠENO**
4. ✅ **Bug #5**: Standardizirati error handling pristup kroz sve helper metode - **RIJEŠENO** (svi sada bacaju exception)

### 🟢 Niski prioritet (code clarity i edge case provjere) - **SVI ZATVORENI**:
1. ~~Potencijalni Problem #1~~: Timezone handling - **✅ OK** (datumi su normalizirani prije poziva)
2. ~~Potencijalni Problem #2~~: Firestore query granice - **✅ OK** (koristi `isLessThan` ispravno)
3. ~~Potencijalni Problem #3~~: `nights` izračun - **✅ OK** (koristi `priceBreakdown.length`)
4. ~~Potencijalni Problem #4~~: `DateTime.utc` dan - **✅ OK** (default je dan 1, Dart specifikacija)
5. ~~Potencijalni Problem #5~~: Gap blocking logika - **✅ OK** (logika ispravna)
6. ~~Potencijalni Problem #6~~: `_blockGapDates` - **✅ OK** (namjerno ponašanje)
7. ~~Potencijalni Problem #7~~: `unawaited` za logging - **✅ OK** (standard praksa)

---

## 🔧 Preporuke za popravke

### Faza 1 (Hitno):
1. ✅ Popraviti **Bug #2** - promijeniti error handling u `_checkBlockedCheckInOut` da vraća error status - **RIJEŠENO**

### Faza 2 (Kratkoročno):
1. ✅ Popraviti **Bug #1** - zamijeniti `isAtSameMomentAs` s `DateNormalizer.isSameDay` - **RIJEŠENO**
2. ✅ Popraviti **Bug #3** - poboljšati error handling u `calculate` metodi - **RIJEŠENO**
3. ✅ Popraviti **Bug #4** - `_iterateDates` sada koristi exclusive end date - **RIJEŠENO**

### Faza 3 (Dugoročno):
1. ✅ Standardizirati error handling pristup (**Bug #5**) - **RIJEŠENO**
2. Code clarity improvements (Potencijalni Problem #3, #4)
3. Edge case provjere (ostali potencijalni problemi)

---

## 📝 Napomene

- Svi bugovi su identificirani kroz statičku analizu koda
- Preporučuje se testiranje svih popravki u development okruženju prije deploy-a
- Neki od "potencijalnih problema" mogu biti namjerno dizajnirano ponašanje
- Preporučuje se code review prije implementacije popravki

---

**Kreirano:** 2024
**Zadnje ažurirano:** 2025-12-16 (Sesija #5 - verifikacija i zatvaranje svih potencijalnih problema)

## 📌 Changelog

### 2025-12-16 (Sesija #5)
- ✅ Svi potencijalni problemi (#1-#7) verificirani i zatvoreni kao "OK"
- Verifikacija potvrdila da je kod implementiran prema dokumentaciji

### 2025-12-16 (Sesija #3-#4)
- ✅ Bug #3 riješen: Promijenjen error handling u `calculate` metodi da baca `PriceCalculationException` umjesto vraćanja `zero()` rezultata
- ✅ Bug #4 riješen: Promijenjen `_iterateDates` da koristi exclusive end date (`isBefore` umjesto `!isAfter`)
- ✅ Bug #4 dodatak: Ažuriran `_markDateRange` da eksplicitno označi checkout dan kao `partialCheckOut`
- ✅ Bug #5 riješen: Svi error handleri sada konzistentno bacaju exception-e
- Dodana nova `PriceCalculationException` klasa u `app_exceptions.dart`
- Ažurirana dokumentacija interfejsa `IPriceCalculator`

### 2025-12-15
- ✅ Bug #1 riješen: Zamijenjeno `isAtSameMomentAs` sa `DateNormalizer.isSameDay` u `_checkBlockedCheckInOut`
- ✅ Bug #2 riješen: Promijenjen error handling u `_checkBlockedCheckInOut` da vraća `error` status umjesto `available` (fail-safe pristup)
