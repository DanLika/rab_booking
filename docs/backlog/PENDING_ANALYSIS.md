# Pending Analysis - Bugovi i Poboljšanja

Ovaj dokument sadrži bugove i poboljšanja koja zahtijevaju dodatnu analizu i istraživanje prije implementacije.

**Pravila:**
- Svaki item mora imati jasno definiran problem
- Mora biti navedeno zašto zahtijeva dodatnu analizu
- Mora biti navedeno što treba istražiti prije implementacije
- Status: `PENDING` | `IN_ANALYSIS` | `READY_FOR_IMPLEMENTATION` | `REJECTED`

---

## PENDING-001: PremiumInputField - autovalidateMode parametar

**Status:** `PENDING`

**Datum dodavanja:** 2026-01-08

**Izvor:** Branch `REG-001-name-validation-4891515535746336586`

**Problem:**
Registration screen i drugi auth screenovi trebaju `autovalidateMode` za real-time validaciju polja, ali `PremiumInputField` widget ne podržava ovaj parametar.

**Trenutno stanje:**
```dart
// PremiumInputField NE podržava autovalidateMode
PremiumInputField(
  controller: _controller,
  labelText: 'Email',
  validator: (value) => validateEmail(value),
  // autovalidateMode: AutovalidateMode.onUserInteraction, // NE POSTOJI
)
```

**Željeno stanje:**
```dart
PremiumInputField(
  controller: _controller,
  labelText: 'Email',
  validator: (value) => validateEmail(value),
  autovalidateMode: AutovalidateMode.onUserInteraction, // RADI
)
```

**Što treba istražiti:**
1. Koliko mjesta u aplikaciji koristi `PremiumInputField`?
2. Da li će dodavanje novog parametra utjecati na postojeće upotrebe?
3. Da li treba default vrijednost (`AutovalidateMode.disabled`)?
4. Da li postoje drugi widgeti koji trebaju istu promjenu?

**Fajlovi za analizu:**
- `lib/features/auth/presentation/widgets/premium_input_field.dart`
- Svi screenovi koji koriste `PremiumInputField`

**Procjena kompleksnosti:** Niska (dodavanje parametra i proslijeđivanje)

---

## PENDING-002: PremiumInputField - autofillHints parametar

**Status:** `DONE` ✅

**Datum dodavanja:** 2026-01-08
**Datum rješavanja:** 2026-01-08

**Izvor:** Branch `REG-001-name-validation-4891515535746336586`, `safari-compatibility-fixes-16853240208209773061`

**Rješenje:**
Implementirano u sklopu analize `safari-compatibility-fixes` brancha:
- Dodan `autofillHints` parametar u `PremiumInputField` widget
- Dodani autofillHints u Login screen (email, password)
- Dodani autofillHints u Register screen (firstName, lastName, email, phone, password)

**Izmijenjeni fajlovi:**
- `lib/features/auth/presentation/widgets/premium_input_field.dart`
- `lib/features/auth/presentation/screens/enhanced_login_screen.dart`
- `lib/features/auth/presentation/screens/enhanced_register_screen.dart`

---

## PENDING-003: ErrorDisplayUtils - error parametar za logging

**Status:** `PENDING`

**Datum dodavanja:** 2026-01-08

**Izvor:** Branch `REG-001-name-validation-4891515535746336586`

**Problem:**
Kada prikazujemo error korisniku, ponekad želimo i logirati originalni error za debugging, ali `ErrorDisplayUtils.showErrorSnackBar` ne podržava `error` parametar.

**Trenutno stanje:**
```dart
// Moramo odvojeno logirati i prikazati
try {
  await uploadImage();
} catch (e, stackTrace) {
  LoggingService.logError('Upload failed', e, stackTrace);
  ErrorDisplayUtils.showErrorSnackBar(context, l10n.uploadFailed);
}
```

**Željeno stanje (opcija A):**
```dart
// Sve u jednom pozivu
try {
  await uploadImage();
} catch (e, stackTrace) {
  ErrorDisplayUtils.showErrorSnackBar(
    context, 
    l10n.uploadFailed,
    error: e,
    stackTrace: stackTrace,
  );
}
```

**Što treba istražiti:**
1. Da li je bolje držati logging odvojeno od UI prikaza?
2. Koliko mjesta u aplikaciji bi koristilo ovu funkcionalnost?
3. Da li bi ovo kompliciralo `ErrorDisplayUtils` API?
4. Alternativa: Helper metoda `showErrorAndLog()`?

**Fajlovi za analizu:**
- `lib/shared/utils/error_display_utils.dart`
- Sva mjesta gdje se koristi `showErrorSnackBar`

**Procjena kompleksnosti:** Niska

**Preporuka:** Možda je bolje zadržati trenutni pristup (odvojeno logiranje) jer je eksplicitniji i jasniji.

---

## TEMPLATE ZA NOVE ITEME

```markdown
## PENDING-XXX: [Kratak naziv]

**Status:** `PENDING`

**Datum dodavanja:** YYYY-MM-DD

**Izvor:** [Odakle dolazi - branch, issue, review, etc.]

**Problem:**
[Opis problema]

**Trenutno stanje:**
[Kod ili opis trenutnog stanja]

**Željeno stanje:**
[Kod ili opis željenog stanja]

**Što treba istražiti:**
1. [Pitanje 1]
2. [Pitanje 2]
3. ...

**Fajlovi za analizu:**
- [fajl1.dart]
- [fajl2.dart]

**Procjena kompleksnosti:** Niska | Srednja | Visoka

**Napomena:** [Dodatne napomene ako ih ima]
```

---

**Zadnje ažurirano:** 2026-01-08

---

## Changelog

- **2026-01-08:** PENDING-002 riješen - autofillHints dodan u PremiumInputField


---

## PENDING-004: Timeline Calendar Scroll Jank na Mobile Web

**Status:** `PENDING`

**Datum dodavanja:** 2026-01-08

**Izvor:** Branch `feat/timeline-scroll-performance-562950073032721043`

**Problem:**
Timeline kalendar ima scroll jank (trzanje) na mobile web-u zbog sinkronog `jumpTo` poziva u scroll sync logici.

**Trenutno stanje:**
```dart
// Sinkroni jumpTo - može uzrokovati jank
void _performHorizontalScrollSync(double mainOffset) {
  if (_isSyncingScroll || !_horizontalScrollController.hasClients) return;
  // ...
  _headerScrollController.jumpTo(mainOffset);  // SINKRONO
}
```

**Predloženo rješenje (iz Jules brancha):**
```dart
// Deferirano na post-frame callback
void _performHorizontalScrollSync(double mainOffset) {
  if (_isSyncingScroll || _isSyncScheduled) return;
  
  _isSyncScheduled = true;
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    _headerScrollController.jumpTo(mainOffset);  // DEFERIRANO
    _isSyncScheduled = false;
  });
}
```

**Što treba istražiti:**
1. Testirati na stvarnom mobile uređaju (iOS Safari, Android Chrome)
2. Da li deferiranje uzrokuje vidljiv lag između header-a i grid-a?
3. Trenutni komentar kaže "CRITICAL: This must be instant" - zašto?
4. Možda hybrid pristup: instant za male pomake, deferirano za velike?

**Fajlovi za analizu:**
- `lib/features/owner_dashboard/presentation/widgets/timeline_calendar_widget.dart`

**Procjena kompleksnosti:** Srednja

**Napomena:** 
- Potrebno testiranje na stvarnim uređajima prije implementacije
- Branch: `feat/timeline-scroll-performance-562950073032721043`
- Commit: `29a4491`

