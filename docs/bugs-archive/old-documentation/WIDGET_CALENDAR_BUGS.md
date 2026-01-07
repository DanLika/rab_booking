# Analiza Bugova - Widget Calendar Files

**Datum analize:** 2024
**Zadnje ažurirano:** 2025-12-15
**Lokacija:** `lib/features/widget/presentation/widgets/calendar/`

## 📋 Pregled

Ovaj dokument sadrži analizu potencijalnih bugova i grešaka pronađenih u calendar widget fajlovima:
- `calendar_combined_header_widget.dart`
- `calendar_compact_legend.dart`
- `calendar_date_selection_validator.dart`
- `calendar_date_utils.dart`
- `calendar_tooltip_builder.dart`
- `calendar_view_switcher_widget.dart`
- `month_calendar_skeleton.dart`
- `year_calendar_painters.dart`
- `year_calendar_skeleton.dart`

---

## 1. calendar_combined_header_widget.dart

### ⚠️ Potencijalni Problem #1: Default fallback za nepoznati language code
**Prioritet:** Nizak  
**Lokacija:** Linija 232-233

**Problem:**
```dart
String _getFlagEmoji(String languageCode) {
  switch (languageCode) {
    case 'hr':
      return '🇭🇷';
    case 'en':
      return '🇬🇧';
    case 'de':
      return '🇩🇪';
    case 'it':
      return '🇮🇹';
    default:
      return '🇭🇷';  // Default fallback
  }
}
```

**Objašnjenje:**
- Default fallback na '🇭🇷' može sakriti probleme
- Ako se proslijedi neispravan language code, neće se znati da je došlo do greške
- Možda bi bilo bolje logirati warning ili vratiti neutralni emoji

**Utjecaj:** Minimalan - samo visual, ali može sakriti probleme.

---

### ⚠️ Potencijalni Problem #2: Non-web platform handling
**Prioritet:** Nizak  
**Lokacija:** Linija 238

**Problem:**
```dart
void _changeLanguage(String languageCode, WidgetRef ref) {
  if (!kIsWeb) return;  // Silent return for non-web platforms
  // ...
}
```

**Objašnjenje:**
- Silent return za non-web platforme
- Language switcher neće raditi na mobile/desktop aplikacijama
- Možda bi trebalo handle-ovati non-web slučajeve drugačije

**Utjecaj:** Minimalan - widget je vjerojatno samo za web, ali vrijedi provjeriti.

---

## 2. calendar_compact_legend.dart

### ✅ Nema bugova
**Status:** Čist - widget bez problema.

---

## 3. calendar_date_selection_validator.dart

### ✅ Bug #1: Potencijalni problem s date difference calculation
**Prioritet:** Srednji
**Lokacija:** Linija 260
**Status:** ✅ **RIJEŠENO** (2025-12-15)

**Problem:**
```dart
ValidationResult validateRange({
  required DateTime start,
  required DateTime end,
  // ...
}) {
  final selectedNights = end.difference(start).inDays;
  // ...
}
```

**Objašnjenje:**
- Koristi `difference().inDays` umjesto `DateNormalizer.nightsBetween`
- Može dati pogrešan rezultat ako datumi nisu normalizirani
- Ako start ili end imaju vremenske komponente, razlika može biti pogrešna
- Postoji `DateNormalizer.nightsBetween` koji normalizira datume prije računanja

**Rješenje (PRIMIJENJENO):**
```dart
import '../../../utils/date_normalizer.dart';

// Bug #1 Fix: Use DateNormalizer for consistent date calculation
final selectedNights = DateNormalizer.nightsBetween(start, end);
```

**Utjecaj:** Sada koristi normalizirane datume za konzistentan izračun noći.

---

### ⚠️ Potencijalni Problem #3: Timezone problemi u validateAdvanceBooking
**Prioritet:** Nizak  
**Lokacija:** Linije 68-70

**Problem:**
```dart
final today = DateTime.now();
final todayNormalized = DateTime(today.year, today.month, today.day);
final daysInAdvance = date.difference(todayNormalized).inDays;
```

**Objašnjenje:**
- Koristi `DateTime.now()` što vraća lokalni DateTime
- Normalizacija koristi lokalni DateTime konstruktor
- Može biti problem s timezone-ovima
- Trebalo bi koristiti UTC ili `DateNormalizer.normalize`

**Rješenje:**
```dart
import '../../utils/date_normalizer.dart';

final today = DateTime.now();
final todayNormalized = DateNormalizer.normalize(today);
final dateNormalized = DateNormalizer.normalize(date);
final daysInAdvance = dateNormalized.difference(todayNormalized).inDays;
```

**Utjecaj:** Može dati pogrešan rezultat u edge case-ovima s timezone-ovima.

---

## 4. calendar_date_utils.dart

### ✅ Bug #2: Timezone problemi u isSameDay
**Prioritet:** Srednji
**Lokacija:** Linija 14-18
**Status:** ✅ **RIJEŠENO** (Bug #40 - prethodno)

**Problem:**
```dart
static bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
```

**Objašnjenje:**
- Ne normalizira datume prije usporedbe
- Ne uzima u obzir timezone
- Postoji `DateNormalizer.isSameDay` koji je bolji pristup
- Duplikacija funkcionalnosti - postoje dvije `isSameDay` metode

**Rješenje (PRIMIJENJENO u Bug #40):**
```dart
// Bug #40 Fix: Normalize both dates to UTC for consistent comparison
static bool isSameDay(DateTime a, DateTime b) {
  final aUtc = DateTime.utc(a.year, a.month, a.day);
  final bUtc = DateTime.utc(b.year, b.month, b.day);
  return aUtc == bUtc;
}
```

**Utjecaj:** Sada koristi UTC normalizaciju za konzistentnu usporedbu datuma.

---

### ⚠️ Potencijalni Problem #4: Timezone problemi u isDateInRange
**Prioritet:** Nizak  
**Lokacija:** Linija 29-30

**Problem:**
```dart
return (date.isAfter(rangeStart) || isSameDay(date, rangeStart)) &&
    (date.isBefore(rangeEnd) || isSameDay(date, rangeEnd));
```

**Objašnjenje:**
- Koristi `isAfter` i `isBefore` što može biti problematično s timezone-ovima
- Zavisi od `isSameDay` metode koja također ima probleme
- Trebalo bi normalizirati datume prije usporedbe

**Utjecaj:** Može dati pogrešne rezultate u edge case-ovima s timezone-ovima.

---

## 5. calendar_tooltip_builder.dart

### ✅ Nema bugova
**Status:** Čist - ima dobre defensive provjere (linije 61, 69-70).

---

## 6. calendar_view_switcher_widget.dart

### ✅ Nema bugova
**Status:** Čist - widget bez problema.

---

## 7. month_calendar_skeleton.dart

### ⚠️ Potencijalni Problem #5: Hardcoded vrijednosti za empty cells
**Prioritet:** Nizak  
**Lokacija:** Linija 144

**Problem:**
```dart
final isEmpty = index < 3 || index > 31;
```

**Objašnjenje:**
- Hardcoded vrijednosti 3 i 31
- Ne uzima u obzir stvarni broj dana u mjesecu
- Može biti problematično za različite mjesece

**Utjecaj:** Minimalan - samo visual za skeleton loader, ali može biti zbunjujuće.

---

## 8. year_calendar_painters.dart

### ⚠️ Potencijalni Problem #6: Nema size validacije u PartialBothPainter
**Prioritet:** Nizak  
**Lokacija:** Linija 147

**Problem:**
```dart
@override
void paint(Canvas canvas, Size size) {
  final paint = Paint()..style = PaintingStyle.fill;
  // Nema provjere za size validity
  // ...
}
```

**Objašnjenje:**
- `DiagonalLinePainter` ima defensive provjere za size (linije 57-59)
- `PartialBothPainter` nema iste provjere
- Može uzrokovati probleme ako size nije validan

**Rješenje:**
```dart
@override
void paint(Canvas canvas, Size size) {
  // Defensive check: ensure size is valid before painting
  if (!size.width.isFinite || !size.height.isFinite || 
      size.width <= 0 || size.height <= 0) {
    return; // Skip painting if size is invalid
  }
  // ... rest of code
}
```

**Utjecaj:** Može uzrokovati probleme u edge case-ovima s invalid size-om.

---

### ⚠️ Potencijalni Problem #7: Nema size validacije u PendingPatternPainter
**Prioritet:** Nizak  
**Lokacija:** Linija 116

**Problem:**
```dart
@override
void paint(Canvas canvas, Size size) {
  drawDiagonalPattern(canvas, size, lineColor);
  // Nema provjere za size validity
}
```

**Objašnjenje:**
- Isti problem kao `PartialBothPainter`
- Nema defensive provjere za size

**Utjecaj:** Može uzrokovati probleme u edge case-ovima.

---

## 9. year_calendar_skeleton.dart

### ⚠️ Potencijalni Problem #8: Leap year handling u _isEmptyDay
**Prioritet:** Nizak  
**Lokacija:** Linija 247-250

**Problem:**
```dart
bool _isEmptyDay(int monthIndex, int dayIndex) {
  final month = monthIndex + 1; // 1-indexed month
  final day = dayIndex + 1; // 1-indexed day

  // Days that don't exist in shorter months
  if (month == 2 && day > 28) {
    return true; // Feb (ignore leap years for skeleton)
  }
  // ...
}
```

**Objašnjenje:**
- Komentar kaže "ignore leap years for skeleton"
- To je OK za skeleton loader, ali može biti zbunjujuće
- Nije bug, samo code clarity

**Utjecaj:** Nema funkcionalnog utjecaja - skeleton loader ne treba biti 100% tačan.

---

## 📊 Sažetak po prioritetima

### ✅ Riješeno (2025-12-15):
1. **Bug #1**: ✅ Potencijalni problem s date difference calculation u `validateRange` - sada koristi `DateNormalizer.nightsBetween()`
2. **Bug #2**: ✅ Timezone problemi u `CalendarDateUtils.isSameDay` - riješeno u Bug #40, koristi UTC normalizaciju

### 🟢 Niski prioritet (code clarity i edge case provjere):
1. Potencijalni Problem #1: Default fallback za nepoznati language code
2. Potencijalni Problem #2: Non-web platform handling
3. Potencijalni Problem #3: Timezone problemi u `validateAdvanceBooking`
4. Potencijalni Problem #4: Timezone problemi u `isDateInRange`
5. Potencijalni Problem #5: Hardcoded vrijednosti za empty cells
6. Potencijalni Problem #6: Nema size validacije u `PartialBothPainter`
7. Potencijalni Problem #7: Nema size validacije u `PendingPatternPainter`
8. Potencijalni Problem #8: Leap year handling (OK za skeleton)

---

## 📝 Napomene

- Svi bugovi su identificirani kroz statičku analizu koda
- Preporučuje se testiranje svih popravki u development okruženju prije deploy-a
- Bug #1 i #2 su povezani s nedosljednošću u korištenju `DateNormalizer` vs lokalnih metoda
- Preporučuje se code review prije implementacije popravki

---

**Kreirano:** 2024
**Zadnje ažurirano:** 2025-12-15

### Changelog:
- **2025-12-15**: Bug #1 riješen (DateNormalizer u validateRange), Bug #2 već bio riješen (Bug #40)
