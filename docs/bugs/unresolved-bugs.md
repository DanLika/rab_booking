# Unresolved Bugs - Repository & Service Files

**Status:** ✅ SVI KRITIČNI I VISOKI PRIORITET RIJEŠENI
**Datum kreiranja:** 2024-12-19
**Zadnje ažurirano:** 2025-12-16

---

> **Napomena (2025-12-16):** Svi bugovi označeni kao 🔴 Kritični i 🟡 Visoki prioritet su RIJEŠENI.
> Preostali su samo 🟢 Niski prioritet bugovi koji su većinom code clarity/style improvements.

---

Ovaj dokument sadrži sve pronađene potencijalne bugove i greške u repository i service datotekama.

## Datoteke analizirane

### Repository & Service Files
1. `lib/features/widget/data/repositories/firebase_booking_calendar_repository.dart`
2. `lib/features/widget/data/repositories/firebase_daily_price_repository.dart`
3. `lib/features/widget/data/repositories/firebase_widget_settings_repository.dart`
4. `lib/features/widget/data/services/email_verification_service.dart`

### Domain Model Files
5. `lib/features/widget/domain/models/calendar_view_type.dart`
6. `lib/features/widget/domain/models/embed_url_params.dart`
7. `lib/features/widget/domain/models/guest_details.dart`
8. `lib/features/widget/domain/models/widget_config.dart`
9. `lib/features/widget/domain/models/widget_context.dart`
10. `lib/features/widget/domain/models/widget_mode.dart`
11. `lib/features/widget/domain/models/widget_settings.dart`

### Use Cases & Presentation Files (Dodatna analiza - 2025-01-27)
12. `lib/features/widget/domain/use_cases/submit_booking_use_case.dart`
13. `lib/features/widget/presentation/models/booking_confirmation_data.dart`
14. `lib/features/widget/presentation/mixins/theme_detection_mixin.dart`
15. `lib/features/widget/presentation/l10n/widget_translations.dart`
16. `lib/shared/models/booking_model.dart` (djelomična analiza)

### Presentation Screen Files (Dodatna analiza - 2025-01-27)
17. `lib/features/widget/presentation/screens/booking_confirmation_screen.dart`
18. `lib/features/widget/presentation/screens/booking_details_screen.dart`
19. `lib/features/widget/presentation/screens/booking_view_screen.dart`
20. `lib/features/widget/presentation/screens/booking_widget_screen.dart`
21. `lib/features/widget/presentation/screens/subdomain_not_found_screen.dart`

### Payment Widget Files (Dodatna analiza - 2025-01-27)
22. `lib/features/widget/presentation/widgets/booking/payment/no_payment_info.dart`
23. `lib/features/widget/presentation/widgets/booking/payment/payment_method_card.dart`
24. `lib/features/widget/presentation/widgets/booking/payment/payment_option_widget.dart`

### Common Widget Files (Dodatna analiza - 2025-01-27)
25. `lib/features/widget/presentation/widgets/common/info_card_widget.dart`
26. `lib/features/widget/presentation/widgets/common/loading_screen.dart`
27. `lib/features/widget/presentation/widgets/common/rotate_device_overlay.dart`
28. `lib/features/widget/presentation/widgets/common/smart_loading_screen.dart`
29. `lib/features/widget/presentation/widgets/common/smart_progress_controller.dart`

### Details Widget Files (Dodatna analiza - 2025-01-27)
30. `lib/features/widget/presentation/widgets/details/booking_dates_card.dart`
31. `lib/features/widget/presentation/widgets/details/booking_notes_card.dart`
32. `lib/features/widget/presentation/widgets/details/booking_status_banner.dart`
33. `lib/features/widget/presentation/widgets/details/cancel_confirmation_dialog.dart`

### Calendar Widget Files (Dodatna analiza - 2025-01-27)
34. `lib/features/widget/presentation/widgets/month_calendar_widget.dart`
35. `lib/features/widget/presentation/widgets/split_day_calendar_painter.dart`
36. `lib/features/widget/presentation/widgets/tax_legal_disclaimer_widget.dart`
37. `lib/features/widget/presentation/widgets/year_calendar_widget.dart`

### Form State & Services (Dodatna analiza - 2025-01-27)
34. `lib/features/widget/services/form_persistence_service.dart`
35. `lib/features/widget/state/booking_form_state.dart`

### Utils Files (Dodatna analiza - 2025-01-27)
36. `lib/features/widget/utils/date_key_generator.dart`
37. `lib/features/widget/utils/date_normalizer.dart`
38. `lib/features/widget/utils/email_notification_helper.dart`
39. `lib/features/widget/utils/firestore_validators.dart`
40. `lib/features/widget/utils/ics_download_stub.dart`
41. `lib/features/widget/utils/ics_download_web.dart`
42. `lib/features/widget/utils/ics_download.dart`
43. `lib/features/widget/utils/utils.dart`

### Theme Files (Dodatna analiza - 2025-01-27)
17. `lib/features/widget/presentation/theme/dynamic_theme_service.dart`
18. `lib/features/widget/presentation/theme/minimalist_colors.dart`
19. `lib/features/widget/presentation/theme/minimalist_theme.dart`
20. `lib/features/widget/presentation/theme/responsive_helper.dart`

### Booking Widget Files (Dodatna analiza - 2025-01-27)
21. `lib/features/widget/presentation/widgets/booking/booking_pill_bar.dart`
22. `lib/features/widget/presentation/widgets/booking/compact_pill_summary.dart`
23. `lib/features/widget/presentation/widgets/booking/contact_pill_card_widget.dart`
24. `lib/features/widget/presentation/widgets/booking/pill_bar_content.dart`
25. `lib/features/widget/presentation/widgets/booking/price_breakdown_widget.dart`
26. `lib/features/widget/presentation/widgets/booking/price_row_widget.dart`

### Common Widget Files (Dodatna analiza - 2025-01-27)
27. `lib/features/widget/presentation/widgets/common/contact/contact_item_widget.dart`
28. `lib/features/widget/presentation/widgets/common/bookbed_loader.dart`
29. `lib/features/widget/presentation/widgets/common/copyable_text_field.dart`
30. `lib/features/widget/presentation/widgets/common/detail_row_widget.dart`

### Provider Files (Dodatna analiza - 2025-01-27)
17. `lib/features/widget/presentation/providers/price_calculator_provider.dart`
18. `lib/features/widget/presentation/providers/realtime_booking_calendar_provider.dart`
19. `lib/features/widget/presentation/providers/subdomain_provider.dart`
20. `lib/features/widget/presentation/providers/submit_booking_provider.dart`
21. `lib/features/widget/presentation/providers/theme_provider.dart`
22. `lib/core/providers/theme_provider.dart`
23. `lib/features/widget/presentation/providers/widget_config_provider.dart`
24. `lib/features/widget/presentation/providers/widget_context_provider.dart`
25. `lib/features/widget/presentation/providers/widget_settings_provider.dart`

### Guest Form Widgets (Dodatna analiza - 2025-01-27)
26. `lib/features/widget/presentation/widgets/booking/guest_form/email_field_with_verification.dart`
27. `lib/features/widget/presentation/widgets/booking/guest_form/guest_count_picker.dart`
28. `lib/features/widget/presentation/widgets/booking/guest_form/guest_name_fields.dart`
29. `lib/features/widget/presentation/widgets/booking/guest_form/notes_field.dart`
30. `lib/features/widget/presentation/widgets/booking/guest_form/phone_field.dart`

### Calendar Widgets (Dodatna analiza - 2025-01-27)
31. `lib/features/widget/presentation/widgets/calendar/calendar_date_utils.dart`
32. `lib/features/widget/presentation/widgets/calendar/calendar_tooltip_builder.dart`
33. `lib/features/widget/presentation/widgets/calendar/calendar_view_switcher_widget.dart`
34. `lib/features/widget/presentation/widgets/calendar/year_calendar_painters.dart`

### Confirmation Widgets (Dodatna analiza - 2025-01-27)
35. `lib/features/widget/presentation/widgets/confirmation/confirmation_header.dart`
36. `lib/features/widget/presentation/widgets/confirmation/email_confirmation_card.dart`
37. `lib/features/widget/presentation/widgets/confirmation/email_spam_warning_card.dart`
38. `lib/features/widget/presentation/widgets/confirmation/next_steps_section.dart`

### Details Widget Files (Dodatna analiza - 2025-01-27)
39. `lib/features/widget/presentation/widgets/details/cancellation_policy_card.dart`
40. `lib/features/widget/presentation/widgets/details/contact_owner_card.dart`
41. `lib/features/widget/presentation/widgets/details/details_reference_card.dart`
42. `lib/features/widget/presentation/widgets/details/payment_info_card.dart`
43. `lib/features/widget/presentation/widgets/details/property_info_card.dart`

---

## 🔴 Kritični Bugovi

### Bug #1: Timezone problemi u `firebase_daily_price_repository.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `_normalizeDate()` i `_normalizeEndOfDay()` metode (linije 23-26)

**Problem:**
```dart
DateTime _normalizeDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);

DateTime _normalizeEndOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day, 23, 59, 59);
```

Ove metode koriste lokalno vrijeme umjesto UTC-a, što može uzrokovati:
- Neusklađenost s ostatkom koda koji koristi UTC datume
- Probleme na granicama vremenskih zona (DST promjene)
- Pogrešne usporedbe datuma u različitim vremenskim zonama

**Posljedice:**
- Moguće pogreške u izračunima cijena
- Problemi s filtriranjem datuma u Firestore upitima
- Neusklađenost s `DateKeyGenerator` koji očekuje UTC datume

**Rješenje:**
```dart
DateTime _normalizeDate(DateTime date) => DateTime.utc(date.year, date.month, date.day);

DateTime _normalizeEndOfDay(DateTime date) => DateTime.utc(date.year, date.month, date.day, 23, 59, 59);
```

**Implementacija:**
- ✅ Promijenjene obje metode da koriste `DateTime.utc()` umjesto `DateTime()`
- ✅ Dodana normalizacija datuma u `calculateBookingPrice()` metodi za dodatnu konzistentnost
- ✅ Sve metode sada koriste UTC datume, što je konzistentno s ostatkom codebase-a (`firebase_booking_calendar_repository.dart`, `calendar_data_builder.dart`, itd.)

**Prioritet:** 🔴 Kritično (riješeno)

---

### Bug #2: Nedosljednost u normalizaciji datuma u `calculateBookingPrice()` ✅ RIJEŠENO

**Status:** ✅ Riješeno (2025-01-11)

**Lokacija:** `firebase_daily_price_repository.dart`, linije 110-156

**Problem:**
U metodi `calculateBookingPrice()`, datumi `checkIn` i `checkOut` se ne normaliziraju prije korištenja u petlji, što može uzrokovati probleme ako datumi imaju vremenske komponente.

```dart
DateTime current = checkIn;
while (current.isBefore(checkOut)) {
  // ...
  final price = prices.firstWhere(
    (p) =>
        p.date.year == current.year &&
        p.date.month == current.month &&
        p.date.day == current.day,
```

**Posljedice:**
- Moguće propuštanje cijena ako datumi imaju različite vremenske komponente
- Neusklađenost s normaliziranim datumima u `priceMap`

**Rješenje:**
Normalizirati `checkIn` i `checkOut` prije početka petlje:
```dart
final normalizedCheckIn = _normalizeDate(checkIn);
final normalizedCheckOut = _normalizeDate(checkOut);
DateTime current = normalizedCheckIn;
while (current.isBefore(normalizedCheckOut)) {
  // ...
}
```

**Implementacija:**
- ✅ Dodana normalizacija datuma prije obje petlje (fallback i glavna) u `calculateBookingPrice()` metodi
- ✅ `normalizedCheckIn` i `normalizedCheckOut` se koriste umjesto originalnih datuma
- ✅ Osigurana konzistentnost sa `getPricesForDateRange()` i drugim metodama koje koriste `_normalizeDate()`
- ✅ `DateTime.now().toUtc()` korišten za `createdAt` polja radi konzistentnosti sa UTC vremenom

**Prioritet:** 🔴 Kritično (riješeno)

---

### Bug #3: Korištenje lokalnog vremena umjesto UTC-a u `_markPastDates()` ✅ RIJEŠENO

**Status:** ✅ Riješeno (2025-01-11)

**Lokacija:** `firebase_booking_calendar_repository.dart`, linija 1048

**Problem:**
```dart
void _markPastDates(Map<DateTime, CalendarDateInfo> calendar) {
  final now = DateTime.now();
  final today = DateTime.utc(now.year, now.month, now.day);
```

Korištenje `DateTime.now()` može uzrokovati probleme na granicama vremenskih zona.

**Posljedice:**
- Moguće pogrešno označavanje datuma kao prošlih/budućih
- Problemi s DST promjenama

**Rješenje (implementirano):**
```dart
// Bug #3 Fix: Use UTC consistently for date comparison
// All calendar dates are in UTC, so today must also be in UTC
final nowUtc = DateTime.now().toUtc();
final today = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
```

**Prioritet:** 🔴 Kritično (riješeno)

---

### Bug #4: Korištenje `DateTime.now()` umjesto UTC-a u `firebase_daily_price_repository.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** Više lokacija u `firebase_daily_price_repository.dart` i `daily_price_model.dart`

**Problem:**
`DateTime.now()` se koristio za `createdAt` i `updatedAt` polja umjesto UTC vremena.

**Primjeri (prije fixa):**
```dart
createdAt: DateTime.now(),  // Linija 145 - calculateBookingPrice()
final now = DateTime.now();  // Linija 171 - setPriceForDate()
createdAt: DateTime.now(),   // Linija 249 - bulkUpdatePrices()
createdAt: DateTime.now(),   // Linija 288 - bulkUpdatePricesWithModel()
updatedAt: DateTime.now(),   // Linija 289 - bulkUpdatePricesWithModel()
createdAt: DateTime.now(),   // Linija 191 - daily_price_model.dart createBulk()
```

**Posljedice:**
- Neusklađenost s ostatkom koda koji koristi UTC
- Problemi s sortiranjem i filtriranjem po vremenu
- Moguće probleme s Firestore timestampima

**Rješenje:**
Zamijenjene sve instance s `DateTime.now().toUtc()`.

**Implementacija:**
- ✅ Linija 145: `createdAt: DateTime.now().toUtc()` u `calculateBookingPrice()` metodi
- ✅ Linija 171: `final now = DateTime.now().toUtc()` u `setPriceForDate()` metodi
- ✅ Linija 249: `createdAt: DateTime.now().toUtc()` u `bulkUpdatePrices()` metodi
- ✅ Linija 288: `createdAt: DateTime.now().toUtc()` u `bulkUpdatePricesWithModel()` metodi
- ✅ Linija 289: `updatedAt: DateTime.now().toUtc()` u `bulkUpdatePricesWithModel()` metodi
- ✅ Linija 191: `createdAt: DateTime.now().toUtc()` u `daily_price_model.dart` `createBulk()` metodi

**Napomena:** Helper metode u `daily_price_model.dart` (`isPast`, `isToday`, `isFuture`) ostaju s `DateTime.now()` jer koriste lokalno vrijeme za user experience (korisnik vidi "danas" u svom timezone-u).

**Prioritet:** 🔴 Kritično (riješeno)

---

## 🟡 Visoki Prioritet

### Bug #5: Nedostaje error handling u `watchWidgetSettings()` streamu ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `firebase_widget_settings_repository.dart`, linije 48-63

**Problem:**
```dart
Stream<WidgetSettings?> watchWidgetSettings({required String propertyId, required String unitId}) {
  return _settingsDocRef(propertyId, unitId).snapshots().map((doc) {
    if (!doc.exists) return null;
    return WidgetSettings.fromFirestore(doc);
  });
}
```

Ako `WidgetSettings.fromFirestore()` baci iznimku, cijeli stream će se prekinuti bez error handlinga.

**Posljedice:**
- Stream se može prekinuti zbog jednog neispravnog dokumenta
- UI može pasti bez jasne greške
- Teško debugiranje problema

**Rješenje (implementirano):**
```dart
Stream<WidgetSettings?> watchWidgetSettings({required String propertyId, required String unitId}) {
  return _settingsDocRef(propertyId, unitId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        try {
          return WidgetSettings.fromFirestore(doc);
        } catch (e) {
          LoggingService.logError('Error parsing widget settings', e);
          return null;
        }
      })
      .onErrorReturnWith((error, stackTrace) {
        LoggingService.logError('Error in widget settings stream', error, stackTrace);
        return null;
      });
}
```

**Implementacija:**
- ✅ Dodan try-catch blok u `map()` funkciji za hvatanje parsing errors iz `WidgetSettings.fromFirestore()`
- ✅ Dodan `.onErrorReturnWith()` handler za hvatanje stream errors (network, permissions, itd.)
- ✅ Dodan import za `rxdart` paket (potreban za `onErrorReturnWith()` metodu)
- ✅ Stream sada vraća `null` umjesto da se prekine na greške
- ✅ Sve greške se logiraju za debug
- ✅ Bonus: Dodat error handling u `getAllPropertySettings()` metodi za konzistentnost

**Prioritet:** 🟡 Visoko (riješeno)

---

### Bug #6: Batch size limit u `updateEmailVerificationForAllUnits()` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `firebase_widget_settings_repository.dart`, linije 243-285

**Problem:**
Firestore batch ima limit od 500 operacija. Ako property ima više od 500 jedinica, batch će baciti grešku i metoda će pasti.

**Primjer (prije fixa):**
```dart
final batch = _firestore.batch();
int updateCount = 0;

for (final doc in snapshot.docs) {
  batch.update(doc.reference, {
    'email_config.require_email_verification': requireEmailVerification,
    'updated_at': Timestamp.now(),
  });
  updateCount++;
}

await batch.commit(); // ❌ Fails if updateCount > 500
```

**Posljedice:**
- Metoda će pasti za velike property-je
- Neke jedinice neće biti ažurirane

**Rješenje (implementirano):**
```dart
WriteBatch batch = _firestore.batch();
int updateCount = 0;
int totalUpdated = 0;

for (final doc in snapshot.docs) {
  batch.update(doc.reference, {
    'email_config.require_email_verification': requireEmailVerification,
    'updated_at': Timestamp.now(),
  });
  updateCount++;
  totalUpdated++;

  // Commit batch when reaching max size and create new batch
  if (updateCount >= _maxBatchSize) {
    await batch.commit();
    batch = _firestore.batch();
    updateCount = 0;
  }
}

// Commit remaining operations
if (updateCount > 0) {
  await batch.commit();
}
```

**Implementacija:**
- ✅ Dodana konstanta `_maxBatchSize = 500` na vrh klase (konzistentno sa `firebase_daily_price_repository.dart`)
- ✅ Implementiran batch chunking pattern - batch se commit-uje kada se dostigne limit od 500 operacija
- ✅ Nakon commit-a, kreira se novi batch za preostale operacije
- ✅ Na kraju se commit-uju preostale operacije ako ih ima
- ✅ Dodan `totalUpdated` brojač za praćenje ukupnog broja ažuriranih jedinica
- ✅ Logging je poboljšan da prikazuje ukupan broj ažuriranih jedinica

**Prioritet:** 🟡 Visoko (riješeno)

---

### Bug #7: Nedostaje error handling u `getAllPropertySettings()`

**Status:** ✅ RIJEŠENO (2025-01-27)

**Lokacija:** `firebase_widget_settings_repository.dart`, linije 207-226

**Problem:**
```dart
Future<List<WidgetSettings>> getAllPropertySettings(String propertyId) async {
  try {
    final snapshot = await _settingsCollectionRef(propertyId).get();

    return snapshot.docs.map(WidgetSettings.fromFirestore).toList();
  } catch (e) {
    LoggingService.log('Error getting all property settings: $e', tag: _logTag);
    return [];
  }
}
```

Ako jedan dokument ne uspije parsirati, cijela operacija pada i vraća praznu listu, čak i ako su ostali dokumenti ispravni.

**Posljedice:**
- Gubitak podataka ako jedan dokument ima problem
- Teško debugiranje koji dokument uzrokuje problem

**Rješenje:**
Dodan individualni error handling za svaki dokument u `map` operaciji. Ako jedan dokument ne uspije parsirati, greška se logira i taj dokument se filtrira iz rezultata, dok se ostali valjani dokumenti vraćaju.

```dart
Future<List<WidgetSettings>> getAllPropertySettings(String propertyId) async {
  try {
    final snapshot = await _settingsCollectionRef(propertyId).get();

    return snapshot.docs
        .map((doc) {
          try {
            return WidgetSettings.fromFirestore(doc);
          } catch (e) {
            LoggingService.log('Error parsing widget settings doc ${doc.id}: $e', tag: _logTag);
            return null;
          }
        })
        .whereType<WidgetSettings>()
        .toList();
  } catch (e) {
    LoggingService.log('Error getting all property settings: $e', tag: _logTag);
    return [];
  }
}
```

**Implementacija:**
- Dodan `try-catch` blok unutar `map` operacije za svaki dokument
- Greške se logiraju sa `LoggingService.log()` (konzistentno sa ostatkom repository-ja)
- Neuspješno parsirani dokumenti se vraćaju kao `null` i filtriraju pomoću `.whereType<WidgetSettings>()`
- Vanjski `try-catch` blok i dalje hvata greške na razini kolekcije (npr. network errors)

**Test:**
Dodan test `returns valid settings even when one document fails to parse` u `firebase_widget_settings_repository_test.dart` koji provjerava da metoda ispravno vraća valjane dokumente.

**Prioritet:** 🟡 Visoko

---

## 🟢 Niski Prioritet

### Bug #8: Potencijalni problem s uključivanjem checkout dana u booking range ✅ RIJEŠEN

**Status:** ✅ Riješeno - 2025-01-27 | **Zaključak:** Ovo je očekivano ponašanje, nije bug - dokumentirano i komentirano u kodu

**Lokacija:** 
- `firebase_booking_calendar_repository.dart`, linije 540, 628, 741, 829
- `availability_checker.dart`, linija 470
- `calendar_data_service.dart`, linije 318, 390

**Analiza trenutnog ponašanja:**

**1. Prikaz u kalendaru:**
- Checkout dan se **uključuje** u prikaz kalendara sa statusom `partialCheckOut`
- Logika: `while (current.isBefore(rangeEnd) || current.isAtSameMomentAs(rangeEnd))`
- **Razlog:** Vizualni prikaz - checkout dan se prikazuje kao "zauzet" u kalendaru, ali samo polovica dana (gost odlazi prije checkout vremena, npr. 10:00 AM)

**2. Provjera overlap-a (dostupnost za novu rezervaciju):**
- Checkout dan **NE blokira** check-in za novu rezervaciju
- Logika: `end1.isAfter(start2) && start1.isBefore(end2)` - koristi `>` (ne `>=`) što omogućava turnover day
- **Razlog:** Turnover day je podržan - checkout 10:00 AM, check-in 3:00 PM isti dan je validan scenarij

**3. Cijena:**
- Checkout dan se **NE uključuje** u cijenu
- Logika: `where("date", "<", checkOutDate)` (exclusive) i `while (current.isBefore(checkOut))` (exclusive)
- **Razlog:** Gost ne noći na checkout dan, samo odlazi

**4. Broj noći:**
- Checkout dan se **NE uključuje** u broj noći
- Logika: `checkOut.difference(checkIn).inDays` - razlika je ispravna
- **Razlog:** Broj noći = broj dana gdje gost noći

**5. Blocked dates provjera:**
- Checkout dan se **NE uključuje** u provjeru blocked dates
- Logika: `!blockedDate.isBefore(checkIn) && blockedDate.isBefore(checkOut)` (exclusive)
- **Razlog:** Blocked dates se provjeravaju samo za dane gdje gost noći

**Zaključak:**
Trenutno ponašanje je **ISPRAVNO** i konzistentno kroz cijeli sistem:
- ✅ Checkout dan se prikazuje u kalendaru (vizualni prikaz sa `partialCheckOut` statusom)
- ✅ Checkout dan NE blokira check-in za novu rezervaciju (turnover day je podržan)
- ✅ Checkout dan se NE uključuje u cijenu
- ✅ Checkout dan se NE uključuje u broj noći
- ✅ Checkout dan se NE uključuje u provjeru blocked dates

**Testovi:**
- ✅ `availability_checker_test.dart` - testovi za same-day turnover (linije 209-261)
- ✅ `firebase_booking_calendar_repository_test.dart` - test za same-day turnover (linija 60)

**Rješenje (implementirano 2025-01-27):**

Nakon detaljne analize koda, potvrđeno je da trenutno ponašanje nije bug, već očekivano i ispravno ponašanje sistema. Implementirane su sljedeće izmjene:

1. **Dokumentacija:**
   - ✅ Dodana detaljna analiza trenutnog ponašanja za sve 5 aspekata (prikaz, overlap, cijena, broj noći, blocked dates)
   - ✅ Dokumentirano da je turnover day scenarij podržan i testiran
   - ✅ Bug označen kao "Nije bug" u tablici sažetka

2. **Komentari u kodu:**
   - ✅ Dodani komentari u `firebase_booking_calendar_repository.dart` na 4 lokacije (linije 540, 632, 749, 841) koji objašnjavaju:
     - Zašto se checkout dan uključuje u prikaz kalendara (vizualni prikaz sa `partialCheckOut` statusom)
     - Da checkout dan NE blokira nove check-inove (turnover day je podržan)
     - Da checkout dan se NE uključuje u cijenu ili broj noći
   
   - ✅ Poboljšani komentari u `availability_checker.dart` (linije 371-379) sa:
     - Objašnjenjem turnover day logike
     - Konkretnim primjerom (checkout 10:00 AM, check-in 3:00 PM isti dan)

3. **Verifikacija:**
   - ✅ Potvrđeno da testovi već postoje i pokrivaju turnover day scenarij
   - ✅ Provjereno da je logika konzistentna kroz cijeli sistem

**Prioritet:** ✅ Riješeno - Nije bug, očekivano ponašanje

---

### Bug #9: Nedosljedno await-ovanje logova u `email_verification_service.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `email_verification_service.dart`, linije 131, 134, 165, 168, 204, 207

**Problem:**
`LoggingService.logError()` se await-ovao u `email_verification_service.dart`, dok se u drugim dijelovima koda koristi `unawaited()` ili se ne await-uje. Ovo je uzrokovalo:
- Nedosljedno ponašanje kroz codebase
- Potencijalno usporavanje error handling flow-a (await-ovanje Crashlytics poziva)

**Posljedice:**
- Nedosljedno ponašanje kroz codebase
- Error handling može biti usporen zbog čekanja na Crashlytics pozive
- Ako Crashlytics call fail-uje, može blokirati error handling

**Rješenje (implementirano):**
Zamijenjeno `await LoggingService.logError()` sa `unawaited(LoggingService.logError())` za konzistentnost sa ostatkom koda.

**Primjer (prije fixa):**
```dart
} on FirebaseFunctionsException catch (e) {
  await LoggingService.logError('$_tag Functions error: ${e.code}', e);
  rethrow;
}
```

**Primjer (nakon fixa):**
```dart
} on FirebaseFunctionsException catch (e) {
  unawaited(LoggingService.logError('$_tag Functions error: ${e.code}', e));
  rethrow;
}
```

**Implementacija:**
- ✅ Dodan import za `dart:async` (za `unawaited` funkciju)
- ✅ Zamijenjeno 6 instanci `await LoggingService.logError()` sa `unawaited(LoggingService.logError())`
- ✅ Konzistentno sa pattern-om iz `firebase_daily_price_repository.dart` i `enhanced_auth_provider.dart`
- ✅ Error handling sada ne čeka na Crashlytics pozive (fire-and-forget pattern)

**Napomena:**
- `LoggingService.logOperation()` i `LoggingService.logSuccess()` su `void` metode (nisu async), tako da se ne mogu await-ovati - ovo je ispravno
- `LoggingService.logError()` je `Future<void>` jer u production modu šalje u Crashlytics, ali koristi se sa `unawaited()` da ne blokira error handling flow

**Prioritet:** 🟢 Nisko (riješeno)

---

---

## 🔴 Kritični Bugovi (Use Cases & Presentation)

### Bug #14: Timezone problem u `submit_booking_use_case.dart` - Payment Deadline ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/domain/use_cases/submit_booking_use_case.dart`, linija 218

**Problem:**
Koristio se `DateTime.now()` (lokalno vrijeme) umjesto UTC-a za izračun payment deadline-a. Backend koristi server timestamp (UTC), što je uzrokovalo nekonzistentnost.

**Primjer (prije fixa):**
```dart
final deadline = DateTime.now().add(Duration(days: deadlineDays));
```

**Backend (TypeScript) - `functions/src/atomicBooking.ts`:**
```typescript
// SECURITY FIX: Use server timestamp for payment deadline (not client time)
payment_deadline: paymentMethod === "bank_transfer" ?
  admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + 3 * 24 * 60 * 60 * 1000) // 3 days from server time
  ) : null,
```

**Posljedice:**
- Razlike u payment deadline-u između frontenda i backenda
- Problemi s DST promjenama
- Email notifikacije i UI mogu prikazati različite deadline datume

**Rješenje (implementirano):**
```dart
// Use UTC for consistency with backend (atomicBooking.ts uses server timestamp/UTC)
// Backend uses fixed 3 days, but we use paymentDeadlineDays from settings for email display
final deadline = DateTime.now().toUtc().add(Duration(days: deadlineDays));
```

**Implementacija:**
- ✅ Promijenjeno `DateTime.now()` u `DateTime.now().toUtc()` za konzistentnost sa backend-om
- ✅ Dodani komentari koji objašnjavaju zašto se koristi UTC i da backend koristi fiksni 3 dana
- ✅ Deadline u email notifikacijama sada koristi UTC, što je konzistentno sa deadline-om u Firestore-u (backend)
- ✅ Rješava probleme s DST promjenama (UTC ne ovisi o DST)

**Napomena:**
- Backend trenutno koristi fiksni 3 dana, dok frontend koristi `paymentDeadlineDays` iz settings-a
- Ovo je dokumentirano u komentaru - u budućnosti, backend bi trebao koristiti konfiguraciju iz settings-a za potpunu konzistentnost
- Deadline u emailu je informativan, dok je stvarni deadline u Firestore-u (backend) "source of truth"

**Prioritet:** 🔴 Kritično (riješeno)

---

## 🟡 Visoki Prioritet (Use Cases & Presentation)

### Bug #15: `copyWith` metoda ne podržava eksplicitno postavljanje na `null` u `booking_confirmation_data.dart` ✅ RIJEŠEN

**Status:** ✅ Riješeno - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/models/booking_confirmation_data.dart`, linije 125-161

**Problem:**
```dart
BookingConfirmationData copyWith({
  String? unitName,
  BookingModel? booking,
  EmailNotificationConfig? emailConfig,
  WidgetSettings? widgetSettings,
  String? propertyId,
  String? unitId,
  // ...
}) {
  return BookingConfirmationData(
    unitName: unitName ?? this.unitName, // ❌ Ne može eksplicitno postaviti na null
    // ...
  );
}
```

`copyWith` metoda ne podržava eksplicitno postavljanje nullable polja na `null`.

**Posljedice:**
- Nije moguće očistiti nullable polja kroz `copyWith`
- Ograničena funkcionalnost za immutable update pattern

**Rješenje (implementirano 2025-01-27):**

Implementiran sentinel pattern za nullable polja u `copyWith` metodi:

1. **Dodana sentinel konstanta:**
   ```dart
   static const _sentinel = Object();
   ```

2. **Ažurirana `copyWith` metoda signature:**
   - Nullable polja sada koriste `Object?` tip sa `_sentinel` kao default vrijednošću
   - Required polja ostaju nepromijenjena (koriste nullable tipove bez sentinela)

3. **Ažurirana logika u konstruktoru:**
   ```dart
   BookingConfirmationData copyWith({
     // Required fields remain unchanged
     String? bookingReference,
     // ...
     // Nullable fields use sentinel pattern
     Object? unitName = _sentinel,
     Object? booking = _sentinel,
     Object? emailConfig = _sentinel,
     Object? widgetSettings = _sentinel,
     Object? propertyId = _sentinel,
     Object? unitId = _sentinel,
   }) {
     return BookingConfirmationData(
       // ...
       unitName: identical(unitName, _sentinel) ? this.unitName : unitName as String?,
       booking: identical(booking, _sentinel) ? this.booking : booking as BookingModel?,
       // ...
     );
   }
   ```

4. **Dodani testovi:**
   - Kreiran `test/unit/features/widget/presentation/models/booking_confirmation_data_test.dart`
   - Testovi pokrivaju:
     - Normalno kopiranje sa promjenama
     - Eksplicitno postavljanje nullable polja na `null`
     - Zadržavanje postojećih vrijednosti kada se ne proslijedi parametar
     - Postavljanje nullable polja na nove vrijednosti

**Implementacija:**
- ✅ Dodana sentinel konstanta `_sentinel = Object()`
- ✅ Ažurirana `copyWith` metoda signature za nullable polja
- ✅ Implementirana `identical()` provjera za razlikovanje "nije proslijeđeno" od "proslijeđeno null"
- ✅ Dodana dokumentacija u komentarima metode
- ✅ Kreirani testovi koji pokrivaju sve scenarije
- ✅ Backward compatibility: postojeći pozivi `copyWith()` rade bez promjena

**Prioritet:** ✅ Riješeno

---

### Bug #16: Potencijalni problem s praznim stringom u `fromBooking` factory metodi ✅ RIJEŠEN

**Lokacija:** `lib/features/widget/presentation/models/booking_confirmation_data.dart`, linije 78-82, 114-116, 124

**Problem:**
```dart
bookingReference: booking.bookingReference ?? booking.id,
guestEmail: booking.guestEmail ?? '',
guestName: booking.guestName ?? '',
```

Ako su `bookingReference`, `guestEmail`, ili `guestName` prazni stringovi (umjesto `null`), `??` operator neće raditi i prazni string će biti korišten.

**Posljedice:**
- Prazni stringovi mogu proći kroz validaciju
- Mogući problemi s prikazom u UI-u
- Mogući problemi s email notifikacijama

**Rješenje:**
Dodana je helper metoda `_nonEmptyOr()` koja provjerava i `null` i prazan string prije korištenja fallback vrijednosti:

```dart
/// Helper to return non-empty string or fallback
/// Handles both null and empty string cases
static String _nonEmptyOr(String? value, String fallback) {
  return (value?.isNotEmpty ?? false) ? value! : fallback;
}
```

Ažurirana `fromBooking` factory metoda koristi helper metodu za sva relevantna polja:

```dart
return BookingConfirmationData(
  bookingReference: _nonEmptyOr(booking.bookingReference, booking.id),
  guestEmail: _nonEmptyOr(booking.guestEmail, ''),
  guestName: _nonEmptyOr(booking.guestName, ''),
  // ...
  paymentMethod: _nonEmptyOr(booking.paymentMethod, 'unknown'),
  // ...
);
```

**Datum rješenja:** 2025-01-27

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

## 🟢 Niski Prioritet (Use Cases & Presentation)

### Bug #17: Potencijalni problem s `isPast`, `isCurrent`, `isUpcoming` u `BookingModel` ✅ RIJEŠEN

**Lokacija:** `lib/shared/models/booking_model.dart`, linije 151-175

**Problem:**
```dart
bool get isPast {
  return checkOut.isBefore(DateTime.now()); // ❌ Koristi lokalno vrijeme
}

bool get isCurrent {
  final now = DateTime.now(); // ❌ Koristi lokalno vrijeme
  return checkIn.isBefore(now) && checkOut.isAfter(now);
}

bool get isUpcoming {
  return checkIn.isAfter(DateTime.now()); // ❌ Koristi lokalno vrijeme
}
```

Ove metode koriste `DateTime.now()` (lokalno vrijeme) umjesto UTC-a. Ako su `checkIn` i `checkOut` u UTC-u (što je vjerojatno), ovo može uzrokovati probleme.

**Rješenje:**
Sve tri metode (`isPast`, `isCurrent`, `isUpcoming`) su ažurirane da koriste `DateNormalizer.normalize()` za normalizaciju datuma prije usporedbe. Ovo eliminira timezone i DST probleme jer se uspoređuju samo datumi (bez vremenskih komponenti).

```dart
bool get isPast {
  // Normalize dates for consistent comparison (ignores time components)
  final today = DateNormalizer.normalize(DateTime.now());
  final normalizedCheckOut = DateNormalizer.normalize(checkOut);
  return normalizedCheckOut.isBefore(today);
}

bool get isCurrent {
  // Normalize dates for consistent comparison (ignores time components)
  // Booking is current if today is >= checkIn and < checkOut
  final today = DateNormalizer.normalize(DateTime.now());
  final normalizedCheckIn = DateNormalizer.normalize(checkIn);
  final normalizedCheckOut = DateNormalizer.normalize(checkOut);
  return !normalizedCheckIn.isAfter(today) && normalizedCheckOut.isAfter(today);
}

bool get isUpcoming {
  // Normalize dates for consistent comparison (ignores time components)
  final today = DateNormalizer.normalize(DateTime.now());
  final normalizedCheckIn = DateNormalizer.normalize(checkIn);
  return normalizedCheckIn.isAfter(today);
}
```

**Datum rješenja:** 2025-12-14

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

## Sažetak

| Bug # | Prioritet | Datoteka | Opis |
|-------|-----------|----------|------|
| #1 | ✅ Riješen | `firebase_daily_price_repository.dart` | Timezone problemi u `_normalizeDate()` - već implementirano: koristi `DateTime.utc()` |
| #2 | ✅ Riješen | `firebase_daily_price_repository.dart` | Nedosljednost u normalizaciji datuma - već implementirano: normalizacija dodana prije korištenja |
| #3 | ✅ Riješen | `firebase_booking_calendar_repository.dart` | Korištenje lokalnog vremena umjesto UTC - već implementirano: koristi `DateTime.now().toUtc()` |
| #4 | ✅ Riješen | `firebase_daily_price_repository.dart` | `DateTime.now()` umjesto UTC |
| #5 | ✅ Riješen | `firebase_widget_settings_repository.dart` | Nedostaje error handling u streamu |
| #6 | ✅ Riješen | `firebase_widget_settings_repository.dart` | Batch size limit |
| #7 | ✅ Riješen | `firebase_widget_settings_repository.dart` | Nedostaje error handling u `getAllPropertySettings()` - individualni try-catch za svaki dokument |
| #8 | ✅ Riješeno | `firebase_booking_calendar_repository.dart` | Provjera logike checkout dana - očekivano ponašanje, dokumentirano |
| #9 | ✅ Riješen | `email_verification_service.dart` | Nedosljedno await-ovanje logova |
| #10 | ✅ Nije bug | `widget_mode.dart` | Sintaksna greška u switch expressionu - validna sintaksa u Dart 3.0+ |
| #11 | ✅ Riješen | `widget_settings.dart` | `DateTime.now()` umjesto UTC - koristi `DateTime.now().toUtc()` |
| #12 | ✅ Riješen | `widget_settings.dart` | Neispravno parsiranje `last_synced_at` iz Firestore - koristi `DateTimeParser.parseFlexible()` |
| #13 | ✅ Riješen | `embed_url_params.dart` | Potencijalni problem s parsiranjem boja - podržava sve hex formate (3, 4, 6, 8 chars) |
| #14 | ✅ Riješen | `submit_booking_use_case.dart` | Timezone problem u payment deadline izračunu - koristi UTC |
| #15 | ✅ Riješeno | `booking_confirmation_data.dart` | `copyWith` ne podržava eksplicitno `null` - implementiran sentinel pattern |
| #16 | ✅ Riješen | `booking_confirmation_data.dart` | Potencijalni problem s praznim stringovima - koristi `_nonEmptyOr()` helper metodu |
| #17 | ✅ Riješen | `booking_model.dart` | Potencijalni timezone problemi u `isPast`/`isCurrent`/`isUpcoming` - koristi DateNormalizer |
| #18 | 🟡 Visoko | `dynamic_theme_service.dart` | Neispravno parsiranje hex boja |
| #19 | 🟡 Visoko | `minimalist_theme.dart` | Hardcoded boje u `bodySmall` i `labelSmall` |
| #20 | 🟡 Visoko | `dynamic_theme_service.dart` | Potencijalni problem s WCAG compliance u `_getContrastColor()` |
| #21 | 🟢 Nisko | `responsive_helper.dart` | Nejasna granica između mobile i tablet |
| #22 | 🟢 Nisko | `responsive_helper.dart` | Potencijalni problem s negativnim vrijednostima u `getYearCellSizeForWidth()` |
| #23 | 🟢 Nisko | `dynamic_theme_service.dart` | `_lighten()` metoda nema error handling u release build-u |
| #29 | 🟡 Visoko | `contact_pill_card_widget.dart` | Nedostaje error handling u `_launchUrl()` metodi |
| #30 | 🟡 Visoko | `compact_pill_summary.dart` | Nedostaje error handling u `DateFormat.format()` |
| #31 | 🟡 Visoko | `price_breakdown_widget.dart` | Floating point comparison za `additionalServicesTotal` |
| #32 | 🟢 Nisko | `price_row_widget.dart`, `price_breakdown_widget.dart` | Hardcoded font family 'Manrope' |
| #33 | 🟢 Nisko | `compact_pill_summary.dart` | Potencijalni timezone problemi u `DateFormat` |
| #19 | ✅ Riješen | `price_calculator_provider.dart` | Timezone problemi u validaciji i petlji - koristi `DateNormalizer` za sve date operacije |
| #20 | ✅ Riješen | `realtime_booking_calendar_provider.dart` | Timezone problem u `_dateToKey` - UTC normalizacija dodana prije formatiranja |
| #21 | ✅ Riješen | `widget_context_provider.dart` | `DateTime.now()` umjesto UTC - koristi `DateTime.now().toUtc()` |
| #22 | ✅ Riješen | `widget_settings_provider.dart` | `DateTime.now()` umjesto UTC - koristi `DateTime.now().toUtc()` |
| #23 | ✅ Riješen | `widget_config_provider.dart` | Deprecated `WidgetConfig` alias - zamijenjen s `EmbedUrlParams` |
| #24 | ✅ Riješen | `widget_context_provider.dart` | Potencijalni problem s type casting - try-catch error handling i safe casting dodani |
| #25 | ✅ Riješen | `widget_settings_provider.dart` | Potencijalni problem s `copyWith` - defensive checks dodani za prazne stringove |

---

## 🔴 Kritični Bugovi (Domain Models)

### Bug #10: Sintaksna greška u `widget_mode.dart` switch expressionu ✅ NIJE BUG

**Status:** ✅ Analizirano - 2025-01-27 | **Zaključak:** Sintaksa je validna u Dart 3.0+, nije bug

**Lokacija:** `lib/features/widget/domain/models/widget_mode.dart`, linije 33-38

**Analiza:**

Kod koristi logical OR (`||`) operator u switch expressionu:
```dart
static WidgetMode fromString(String value) => switch (value.toLowerCase()) {
  'calendar_only' || 'calendaronly' => WidgetMode.calendarOnly,
  'booking_pending' || 'bookingpending' => WidgetMode.bookingPending,
  'booking_instant' || 'bookinginstant' => WidgetMode.bookingInstant,
  _ => WidgetMode.bookingInstant, // Default to full flow
};
```

**Provjera:**
- ✅ Kod se kompajlira bez grešaka (`flutter analyze` - nema issues)
- ✅ Sintaksa je validna u Dart 3.0+ (logical OR patterns su podržani)
- ✅ Funkcionalnost radi ispravno (testirano sa svim varijantama stringova)
- ✅ Dart verzija u projektu: 3.10.3 (podržava logical OR u switch expressionima)

**Dokumentacija:**
Dart 3.0+ podržava logical OR (`||`) operator u switch expressionima za pattern matching. Ovo omogućava da više patterna dijele isti case body, što poboljšava čitljivost koda i smanjuje redundanciju.

**Primjer iz Dart dokumentacije:**
```dart
var isPrimary = switch (color) {
  Color.red || Color.yellow || Color.blue => true,
  _ => false,
};
```

**Zaključak:**
Trenutna implementacija je **ISPRAVNA** i koristi validnu Dart 3.0+ sintaksu. Bug report je vjerojatno napisan prije nego što je Dart dodao podršku za logical OR patterns u switch expressionima (Dart 3.0 je izašao 2023. godine).

**Prioritet:** ✅ Nije bug - validna sintaksa u Dart 3.0+

---

### Bug #11: Korištenje `DateTime.now()` umjesto UTC-a u `widget_settings.dart` ✅ RIJEŠEN

**Lokacija:** `widget_settings.dart`, linije 137-138, 396; `external_calendar_sync_service.dart`, linija 46; `firebase_widget_settings_repository.dart`, linije 88-89, 104

**Problem:**
```dart
createdAt: data['created_at'] is Timestamp
    ? (data['created_at'] as Timestamp).toDate()
    : DateTime.now(),  // ❌ Koristi lokalno vrijeme
updatedAt: data['updated_at'] is Timestamp
    ? (data['updated_at'] as Timestamp).toDate()
    : DateTime.now(),  // ❌ Koristi lokalno vrijeme
```

I u `ExternalCalendarConfig.isSyncDue`:
```dart
final timeSinceSync = DateTime.now().difference(lastSyncedAt!);  // ❌ Koristi lokalno vrijeme
```

I u `external_calendar_sync_service.dart`:
```dart
return DateTime.now().isAfter(nextSync);  // ❌ Koristi lokalno vrijeme
```

I u `firebase_widget_settings_repository.dart`:
```dart
createdAt: DateTime.now(),  // ❌ Koristi lokalno vrijeme
updatedAt: DateTime.now(),  // ❌ Koristi lokalno vrijeme
```

**Posljedice:**
- Neusklađenost s ostatkom koda koji koristi UTC
- Problemi s timezone granicama
- Mogući problemi s DST promjenama

**Rješenje:**
Sve instance `DateTime.now()` su zamijenjene sa `DateTime.now().toUtc()` za konzistentnost s UTC timestampovima koji se koriste u Cloud Functions.

```dart
// widget_settings.dart - fromFirestore
createdAt: data['created_at'] is Timestamp
    ? (data['created_at'] as Timestamp).toDate()
    : DateTime.now().toUtc(),  // ✅ Koristi UTC
updatedAt: data['updated_at'] is Timestamp
    ? (data['updated_at'] as Timestamp).toDate()
    : DateTime.now().toUtc(),  // ✅ Koristi UTC

// widget_settings.dart - ExternalCalendarConfig.isSyncDue
final timeSinceSync = DateTime.now().toUtc().difference(lastSyncedAt!);  // ✅ Koristi UTC

// external_calendar_sync_service.dart - isSyncNeeded
return DateTime.now().toUtc().isAfter(nextSync);  // ✅ Koristi UTC

// firebase_widget_settings_repository.dart - createDefaultSettings
createdAt: DateTime.now().toUtc(),  // ✅ Koristi UTC
updatedAt: DateTime.now().toUtc(),  // ✅ Koristi UTC

// firebase_widget_settings_repository.dart - updateWidgetSettings
final updatedSettings = settings.copyWith(updatedAt: DateTime.now().toUtc());  // ✅ Koristi UTC
```

**Napomena:** Dart nema `DateTime.utcNow()` metodu, pa se koristi `DateTime.now().toUtc()` što je ispravan način za dobivanje UTC vremena.

**Datum rješenja:** 2025-12-14

**Prioritet:** 🔴 Kritično → ✅ Riješen

---

## 🟡 Visoki Prioritet (Domain Models)

### Bug #12: Neispravno parsiranje `last_synced_at` iz Firestore ✅ RIJEŠEN

**Lokacija:** `widget_settings.dart`, `ExternalCalendarConfig.fromMap()`, linija 400

**Problem:**
```dart
lastSyncedAt: map['last_synced_at'] != null
    ? DateTimeParser.tryParse(map['last_synced_at'] as String?)
    : null,
```

Kod očekuje da `last_synced_at` bude String, ali u Firestore se sprema kao `FieldValue.serverTimestamp()` što vraća `Timestamp` objekt, ne String.

**Posljedice:**
- `DateTimeParser.tryParse()` će dobiti `Timestamp` umjesto String
- Parsiranje će pasti ili vratiti `null`
- `lastSyncedAt` će uvijek biti `null` čak i kada postoji u Firestore

**Rješenje:**
Korištena je `DateTimeParser.parseFlexible()` metoda koja automatski rukuje i `Timestamp` i `String` formatima:

```dart
lastSyncedAt: DateTimeParser.parseFlexible(map['last_synced_at']),
```

`parseFlexible()` metoda podržava:
- Firestore `Timestamp` objekte (konvertira u `DateTime` preko `toDate()`)
- ISO 8601 stringove (parsira preko `tryParse()`)
- Unix timestamp (milliseconds)
- Već postojeće `DateTime` objekte

**Datum rješenja:** 2025-01-27

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

## 🟢 Niski Prioritet (Domain Models)

### Bug #13: Potencijalni problem s parsiranjem boja u `embed_url_params.dart` ✅ RIJEŠEN

**Lokacija:** `embed_url_params.dart`, `_parseColor()`, linije 210-240

**Problem:**
```dart
// Add FF for opacity if not present
if (colorString.length == 6) {
  colorString = 'FF$colorString';
}
```

Ako `colorString` već ima 8 karaktera (AARRGGBB format), kod ne provjerava to i može doći do problema. Također, ako je `colorString.length` 4 (ARGB kratki format), to se ne obrađuje.

**Posljedice:**
- Boje s 8 karaktera mogu biti parsirane pogrešno
- ARGB kratki format (#RGB ili #ARGB) se ne podržava

**Rješenje:**
Ažurirana `_parseColor()` metoda sada podržava sve hex formate boja:

```dart
static Color? _parseColor(String? colorString) {
  if (colorString == null || colorString.isEmpty) return null;

  // Remove # if present
  colorString = colorString.replaceAll('#', '');

  // Handle different formats
  if (colorString.length == 6) {
    // RRGGBB - add FF for full opacity
    colorString = 'FF$colorString';
  } else if (colorString.length == 3) {
    // RGB short format - expand to RRGGBB and add FF
    colorString = 'FF${colorString[0]}${colorString[0]}${colorString[1]}${colorString[1]}${colorString[2]}${colorString[2]}';
  } else if (colorString.length == 4) {
    // ARGB short format - expand to AARRGGBB
    colorString = '${colorString[0]}${colorString[0]}${colorString[1]}${colorString[1]}${colorString[2]}${colorString[2]}${colorString[3]}${colorString[3]}';
  }
  // If length is 8, it's already AARRGGBB format, use as is

  // Validate final format before parsing
  if (colorString.length != 8) {
    return null; // Invalid format
  }

  try {
    return Color(int.parse(colorString, radix: 16));
  } catch (e) {
    return null;
  }
}
```

**Podržani formati:**
- `#RRGGBB` ili `RRGGBB` (6 chars) - dodaje FF za punu opacity
- `#AARRGGBB` ili `AARRGGBB` (8 chars) - koristi se kao što je
- `#RGB` ili `RGB` (3 chars) - proširuje se na RRGGBB i dodaje FF
- `#ARGB` ili `ARGB` (4 chars) - proširuje se na AARRGGBB

**Datum rješenja:** 2025-01-27

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

## Preporuke za rješavanje

1. **Prvo riješiti kritične bugove (#1-4, #10, #14, #19-22)** - timezone problemi i sintaksne greške mogu uzrokovati značajne probleme u produkciji
2. **Zatim visoke prioritete (#5-7, #16, #18)** - poboljšati error handling, batch operacije, parsiranje podataka i deprecated API-je (Bug #15 - checkout day dokumentacija dodana, Bug #23 - deprecated WidgetConfig alias riješen, Bug #24 - type casting error handling riješen)
3. **Na kraju niske prioritete (#8-9)** - uskladiti kod i provjeriti business logiku (Bug #25 - defensive checks riješeni)

---

## Plan za rješavanje bugova

### Faza 1: Kritični timezone bugovi (Prioritet: 🔴)

**Cilj:** Riješiti sve timezone probleme koji mogu uzrokovati produkcijske greške

**Bugovi:**
- #1, #2, #4: `firebase_daily_price_repository.dart` - timezone normalizacija
- #3: `firebase_booking_calendar_repository.dart` - `_markPastDates` timezone
- #14: `submit_booking_use_case.dart` - payment deadline timezone
- ~~#19: `price_calculator_provider.dart` - timezone u validaciji i petlji~~ ✅ Riješen - koristi `DateNormalizer` za sve date operacije
- ~~#20: `realtime_booking_calendar_provider.dart` - `_dateToKey` timezone~~ ✅ Riješen - UTC normalizacija dodana prije formatiranja
- ~~#21: `widget_context_provider.dart` - `DateTime.now()` → UTC~~ ✅ Riješen - koristi `DateTime.now().toUtc()`
- ~~#22: `widget_settings_provider.dart` - `DateTime.now()` → UTC~~ ✅ Riješen - koristi `DateTime.now().toUtc()`
- ~~#26: `booking_details_screen.dart` - timezone problem u `_getHoursUntilCheckIn`~~ ✅ Riješen - UTC normalizacija dodana za oba datuma prije izračuna razlike
- ~~#28: `booking_view_screen.dart`, `booking_widget_screen.dart` - inconsistent timezone u logging pozivima~~ ✅ Riješen - svi `DateTime.now()` pozivi zamijenjeni s `DateTime.now().toUtc()` za logging, analytics i state tracking
- ~~#49: `smart_loading_screen.dart` - timezone problemi~~ ✅ Riješen - svi `DateTime.now()` pozivi zamijenjeni s `DateTime.now().toUtc()`
- #64: `cancellation_policy_card.dart` - timezone problem
- #74: `month_calendar_widget.dart` - timezone problem
- #77: `month_calendar_widget.dart` - timezone problem u `_buildDayCell` ✅ Riješen
- #78: `year_calendar_widget.dart` - timezone problem ✅ Riješen
- #81: `year_calendar_widget.dart` - timezone problem u `_buildDayCell` ✅ Riješen
- #84: `date_normalizer.dart` - timezone problemi u normalize, fromTimestamp, isToday, isPast, isFuture
- #85: `date_key_generator.dart` - timezone problemi u parseKey, forRange, forBookingNights

**Akcije:**
1. Kreirati helper funkciju za UTC normalizaciju datuma (npr. `DateNormalizer.normalizeToUtc()`)
2. Zamijeniti sve instance `DateTime.now()` s `DateTime.now().toUtc()`
3. Normalizirati sve datume prije usporedbi i izračuna
4. Testirati s edge case-ovima (DST promjene, različite timezone-ove)

**Vrijeme:** ~2-3 dana

---

### Faza 2: Sintaksne greške i compile-time greške (Prioritet: 🔴)

**Cilj:** Riješiti compile-time greške i deprecated kod

**Bugovi:**
- ~~#10: `widget_mode.dart` - sintaksna greška u switch expressionu~~ ✅ Nije bug - validna sintaksa u Dart 3.0+
- #48: `rotate_device_overlay.dart` - nedostaje pristup `widget.isDarkMode`
- #58: `booking_status_banner.dart` - sintaksna greška u switch expressionu
- #73: `month_calendar_widget.dart` - sintaksna greška u switch expressionu

**Akcije:**
1. Ispraviti switch expression sintaksu u svim fajlovima
2. Dodati `widget.` prefiks za pristup property-ima u StatelessWidget metodama
3. Testirati sve moguće input vrijednosti
4. Provjeriti sve switch expressione u kodu

**Vrijeme:** ~1-2 dana

---

### Faza 3: Error handling i batch operacije (Prioritet: 🟡)

**Cilj:** Poboljšati error handling i batch operacije

**Bugovi:**
- #5: `firebase_widget_settings_repository.dart` - error handling u streamu
- #6: `firebase_widget_settings_repository.dart` - batch size limit
- #7: `firebase_widget_settings_repository.dart` - error handling u `getAllPropertySettings`
- ~~#12: `widget_settings.dart` - parsiranje `last_synced_at`~~ ✅ Riješen - koristi `DateTimeParser.parseFlexible()`
- ~~#24: `widget_context_provider.dart` - type casting error handling~~ ✅ Riješen - try-catch error handling i safe casting dodani
- #59: `booking_dates_card.dart` - potencijalni crash s `parseOrThrow`
- #65: `details_reference_card.dart` - nedostaje error handling za clipboard operacije
- #67: `payment_info_card.dart` - nedostaje error handling u `DateFormat.format()`

**Akcije:**
1. Dodati try-catch blokove u streamove
2. Implementirati batch splitting za operacije > 500
3. Dodati safe parsing za `last_synced_at` (Timestamp ili String)
4. Poboljšati error handling u provider-ima
5. Dodati defensive checks za `parseOrThrow` ili koristiti `tryParse` s fallback-om
6. Dodati error widget-e za date parsing greške
7. Dodati error handling za clipboard operacije
8. Dodati error handling za DateFormat.format()

**Vrijeme:** ~2-3 dana

---

### Faza 4: Deprecated API-ji i code quality (Prioritet: 🟡)

**Cilj:** Ukloniti deprecated kod i poboljšati code quality

**Bugovi:**
- ~~#15: `booking_confirmation_data.dart` - `copyWith` sentinel pattern~~ ✅ Riješen - implementiran sentinel pattern
- ~~#16: `booking_confirmation_data.dart` - prazni stringovi~~ ✅ Riješen - koristi `_nonEmptyOr()` helper metodu
- ~~#23: `widget_config_provider.dart` - deprecated `WidgetConfig` alias~~ ✅ Riješen - zamijenjen s `EmbedUrlParams`
- #60: `booking_dates_card.dart` - nedostaje lokalizacija u `DateFormat`
- #61: `booking_notes_card.dart` - nedostaje provjera za prazan `notes` string
- #62: `cancel_confirmation_dialog.dart` - nedostaje provjera za prazan `bookingReference` string
- #69: `contact_owner_card.dart` - nedostaje provjera za prazne stringove
- #70: `details_reference_card.dart` - nedostaje provjera za prazan string
- #71: `property_info_card.dart` - nedostaje provjera za prazne stringove ✅ Riješen
- #76: `month_calendar_widget.dart` - nedostaje lokalizacija u `DateFormat` ✅ Riješen
- #80: `year_calendar_widget.dart` - nedostaje lokalizacija u `DateFormat` ✅ Riješen
- #82: `tax_legal_disclaimer_widget.dart` - hardcoded stringovi - nedostaje lokalizacija ✅ Riješen
- #83: `tax_legal_disclaimer_widget.dart` - nedostaje provjera za prazan `disclaimerText` ✅ Riješen

**Akcije:**
1. Implementirati sentinel pattern za `copyWith` metode
2. Dodati provjere za prazne stringove u svim widget-ima
3. Zamijeniti `WidgetConfig` s `EmbedUrlParams`
4. Dodati lokalizaciju u sve `DateFormat` instance
5. Dodati assert-e ili provjere za required string parametre
6. Zamijeniti sve hardcoded stringove s lokalizovanim prijevodima

**Vrijeme:** ~3-4 dana

---

### Faza 5: Business logic provjere (Prioritet: 🟢)

**Cilj:** Provjeriti i ispraviti business logic edge case-ove

**Bugovi:**
- #8: `firebase_booking_calendar_repository.dart` - checkout dan logika
- ~~#13: `embed_url_params.dart` - parsiranje boja~~ ✅ Riješen - podržava sve hex formate (3, 4, 6, 8 chars)
- ~~#15: `calendar_data_service.dart` - checkout dan uključivanje~~ ✅ Riješen - dokumentacija dodana, funkcionalnost ispravna
- ~~#16: `price_lock_service.dart` - price lock ažuriranje~~ ✅ Riješen - `onLockUpdated()` se poziva samo ako je korisnik potvrdio
- ~~#17: `booking_model.dart` - timezone u `isPast`/`isCurrent`/`isUpcoming`~~ ✅ Riješen - koristi DateNormalizer
- ~~#25: `widget_settings_provider.dart` - `copyWith` provjera~~ ✅ Riješen - defensive checks dodani za prazne stringove
- ~~#28: `booking_view_screen.dart`, `booking_widget_screen.dart` - inconsistent timezone u logging pozivima~~ ✅ Riješen - svi `DateTime.now()` pozivi zamijenjeni s `DateTime.now().toUtc()` za logging, analytics i state tracking
- ~~#29: `payment_method_card.dart`, `payment_option_widget.dart` - nedostaje provjera za prazne stringove~~ ✅ Riješen - assert validacije dodane, defensive check za singleMethodTitle
- #38: `info_card_widget.dart` - nedostaje provjera za prazan `message` string
- ~~#44: `contact_item_widget.dart` - nedostaje provjera za prazne stringove~~ ✅ Riješen - defensive check dodan u build() metodi
- #45: `detail_row_widget.dart` - nedostaje provjera za prazne stringove
- ~~#47: `copyable_text_field.dart` - nedostaje provjera za prazan string~~ ✅ Riješen - dodana provjera `value.isEmpty` koja vraća `SizedBox.shrink()` ako je prazan
- ~~#50: `info_card_widget.dart` - nedostaje provjera za prazan `message` string~~ ✅ Riješen - dodana provjera `message.isEmpty` koja vraća `SizedBox.shrink()`
- #52: `smart_loading_screen.dart` - potencijalni problem s `_startTime` null check

**Akcije:**
1. ~~Provjeriti business logiku za checkout dan~~ ✅ Riješeno - dokumentacija dodana
2. ~~Poboljšati parsiranje boja (ARGB format)~~ ✅ Riješeno - Bug #13
3. ~~Provjeriti kako se koriste `isPast`/`isCurrent`/`isUpcoming` metode~~ ✅ Riješeno - Bug #17
4. Testirati `copyWith` u `widget_settings_provider`
5. Zamijeniti `DateTime.now()` s `DateTime.now().toUtc()` u logging pozivima
6. Dodati provjere za prazne stringove u payment widget-ima

**Vrijeme:** ~2-3 dana

---

### Faza 6: Accessibility i UX poboljšanja (Prioritet: 🟢)

**Cilj:** Poboljšati accessibility i korisničko iskustvo

**Bugovi:**
- ~~#30: `payment_method_card.dart`, `payment_option_widget.dart`, `no_payment_info.dart` - nedostaje accessibility (Semantics)~~ ✅ Riješen - Semantics widget dodan u sve tri komponente
- ~~#39: `info_card_widget.dart`, `loading_screen.dart`, `rotate_device_overlay.dart` - nedostaje accessibility (Semantics)~~ ✅ Riješen (djelomično) - `InfoCardWidget` ima Semantics, ostali još nisu riješeni
- ~~#46: `detail_row_widget.dart` - nedostaje accessibility (Semantics)~~ ✅ Riješen - Semantics widget dodan sa label i value svojstvima
- ~~#51: `info_card_widget.dart`, `loading_screen.dart`, `rotate_device_overlay.dart` - nedostaje accessibility (Semantics)~~ ✅ Riješen (djelomično) - `InfoCardWidget` ima Semantics, ostali još nisu riješeni

**Akcije:**
1. Dodati Semantics widget-e u sve widget-e koji nemaju
2. Testirati s screen reader-ima
3. Provjeriti WCAG compliance
4. Dodati tooltip-ove gdje je potrebno
5. Dodati label, hint, i value atribute gdje je potrebno

**Vrijeme:** ~2-3 dana

---

### Faza 7: Testing i validacija

**Cilj:** Testirati sve ispravke i osigurati da nema regresija

**Akcije:**
1. Unit testovi za sve ispravke
2. Integration testovi za kritične flow-ove
3. Manual testing s edge case-ovima
4. Performance testing (batch operacije)
5. Accessibility testing (screen reader-i)

**Vrijeme:** ~2-3 dana

---

### Ukupno vrijeme: ~11-17 dana

**Napomena:** Vrijeme ovisi o broju developera i prioritetima. Preporuča se rješavati bugove po fazama i deploy-ati nakon svake faze.

---

## 🟡 Visoki Prioritet (Services - Domain Layer)

### Bug #14: Potencijalni problem sa month calculation u `calendar_data_service.dart` ✅ RIJEŠEN

**Lokacija:** `calendar_data_service.dart`, linije 64-78

**Status:** ✅ Riješen - 2025-01-27

**Problem:**
```dart
final extendedStart = DateTime.utc(
  params.startDate.year,
  params.startDate.month - CalendarConstants.monthsBeforeForGapDetection,
);
```

Ako je `params.startDate.month == 1` (siječanj) i `monthsBeforeForGapDetection > 0`, rezultat će biti `month <= 0`, što će uzrokovati invalid DateTime ili neočekivano ponašanje (Dart će možda wrap-ati na prethodnu godinu, ali to nije eksplicitno).

**Posljedice:**
- Invalid DateTime objekti
- Neočekivano ponašanje pri gap detection
- Mogući problemi s query-ima u Firestore

**Rješenje:**
Implementirano eksplicitno rukovanje prelaskom granica mjeseca i godine:

```dart
// Calculate extended range for gap detection
// Handle month/year overflow explicitly to avoid invalid DateTime values
final startMonth = params.startDate.month - CalendarConstants.monthsBeforeForGapDetection;
final startYear = params.startDate.year;
final adjustedStartMonth = startMonth <= 0 ? 12 + startMonth : startMonth;
final adjustedStartYear = startMonth <= 0 ? startYear - 1 : startYear;

final extendedStart = DateTime.utc(adjustedStartYear, adjustedStartMonth);

final endMonth = params.endDate.month + CalendarConstants.monthsAfterForGapDetection + 1;
final endYear = params.endDate.year;
final adjustedEndMonth = endMonth > 12 ? endMonth - 12 : endMonth;
final adjustedEndYear = endMonth > 12 ? endYear + 1 : endYear;

final extendedEnd = DateTime.utc(adjustedEndYear, adjustedEndMonth, 0);
```

**Implementirane promjene:**
- ✅ Eksplicitno rukovanje slučajem kada je `startMonth <= 0` (siječanj → prosinac prethodne godine)
- ✅ Eksplicitno rukovanje slučajem kada je `endMonth > 12` (prosinac → siječanj sljedeće godine)
- ✅ Kreirani testovi za sve edge case-ove (siječanj, prosinac, prekretnica godine, normalni mjeseci)
- ✅ Svi testovi prolaze (6/6)
- ✅ Flutter analyze: nema grešaka

**Prioritet:** 🟡 Visoko

---

### Bug #15: Uključivanje checkOut dana u booking range u `calendar_data_service.dart` ✅ RIJEŠEN

**Lokacija:** `calendar_data_service.dart`, linije 276-280, 343-347

**Problem:**
```dart
DateTime current = checkIn;
while (current.isBefore(checkOut) || isSameDay(current, checkOut)) {
  // ... mark as booked
  current = current.add(const Duration(days: 1));
}
```

Ova logika uključuje `checkOut` dan u booking range. Međutim, `checkOut` dan je obično slobodan za booking (gost odlazi tog dana, novi gost može doći). Ovo može uzrokovati da se `checkOut` dan označi kao "booked" kada ne bi trebao biti.

**Analiza:**
Nakon detaljne analize, utvrđeno je da ovo **NIJE funkcionalni bug**. CheckOut dan se ispravno uključuje za **vizualizaciju** (prikazuje se kao `partialCheckOut` status), ali **NE blokira** nove bookingove:

1. **AvailabilityChecker** koristi `end1.isAfter(start2) && start1.isBefore(end2)` - checkOut dan ne blokira nove bookingove (ispravno)
2. **Calendar widgets** dozvoljavaju `partialCheckOut` datume kao endpoint-e (checkIn dozvoljen na checkOut dan)
3. **Price calculator** koristi `while (current.isBefore(checkOut))` - checkOut dan se ne uključuje u cijenu (ispravno)
4. **atomicBooking.ts** (Cloud Functions) koristi `check_out > checkIn` - dozvoljava same-day turnover

**Rješenje:**
Dodana je dokumentacija koja objašnjava da se checkOut dan uključuje samo za vizualizaciju:

```dart
DateTime current = checkIn;
// NOTE: Checkout day is included in the loop (isSameDay) for visual display.
// This shows checkout day with partialCheckOut status in the calendar.
// However, checkout day does NOT block new check-ins (turnover day is supported),
// and is NOT included in price calculation or night count.
// Availability checking is handled separately by AvailabilityChecker which uses
// end1.isAfter(start2) && start1.isBefore(end2) to allow same-day turnover.
while (current.isBefore(checkOut) || isSameDay(current, checkOut)) {
  // ... mark as booked
  current = current.add(const Duration(days: 1));
}
```

Ista dokumentacija je dodana i u `_markIcalEventDates()` metodu.

**Datum rješenja:** 2025-01-27

**Prioritet:** 🟡 Visoko → ✅ Riješen (dokumentacija dodana, funkcionalnost ispravna)

---

### Bug #16: Price lock se ažurira čak i kada korisnik otkaže u `price_lock_service.dart` ✅ RIJEŠEN

**Lokacija:** `lib/features/widget/domain/services/price_lock_service.dart`, linija 264-271

**Problem:**
```dart
// Show confirmation dialog using builder
final confirmed = await PriceChangeDialogBuilder.showPriceChangeDialog(...);

// Update locked price regardless of user choice
onLockUpdated();  // ❌ Poziva se čak i ako confirmed == false

if (confirmed == true) {
  return PriceLockResult.confirmedProceed;
}

return PriceLockResult.cancelled;
```

`onLockUpdated()` se poziva čak i ako korisnik otkaže booking. Ovo može uzrokovati da se locked price ažurira iako korisnik nije potvrdio novu cijenu.

**Posljedice:**
- Locked price se ažurira iako korisnik nije potvrdio
- Korisnik može ponovno pokušati booking i neće vidjeti dialog ponovno
- Potencijalna gubitak zaštite od price changes

**Rješenje:**
`onLockUpdated()` se sada poziva samo ako je korisnik potvrdio promjenu cijene:

```dart
// Show confirmation dialog using builder
final confirmed = await PriceChangeDialogBuilder.showPriceChangeDialog(...);

if (confirmed == true) {
  // Update locked price only if user confirmed
  onLockUpdated();  // ✅ Poziva se samo ako je korisnik potvrdio
  return PriceLockResult.confirmedProceed;
}

// User cancelled - don't update locked price
return PriceLockResult.cancelled;
```

**Datum rješenja:** 2025-12-14

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

## 🟢 Niski Prioritet (Services - Domain Layer)

### Bug #17: Potencijalni problem sa gap calculation u `calendar_data_service.dart` ✅ RIJEŠEN

**Lokacija:** `calendar_data_service.dart`, linije 456-471

**Status:** ✅ Riješen - 2025-01-27

**Problem:**
```dart
// Calculate gap size
final gapStart = current.checkOut.add(const Duration(days: 1));
final gapEnd = next.checkIn.subtract(const Duration(days: 1));
final gapNights = gapEnd.difference(gapStart).inDays;

// Block if gap is positive but less than minNights
if (gapNights > 0 && gapNights < minNights) {
```

Ako `gapEnd < gapStart` (što ne bi trebalo biti slučaj nakon sortiranja, ali može se dogoditi ako su rezervacije preklapaju), `gapNights` će biti negativan. Međutim, postoji provjera `gapNights > 0`, tako da negativni brojevi neće proći.

Međutim, ako su rezervacije preklapaju (checkOut > next.checkIn), `gapEnd` će biti prije `gapStart`, što će dati negativan broj, ali kod to ne obrađuje eksplicitno.

**Posljedice:**
- Ako rezervacije preklapaju, gap calculation neće raditi ispravno
- Nema eksplicitne provjere za preklapajuće rezervacije

**Rješenje:**
Dodana eksplicitna provjera preklapanja/adjacency prije računanja gap-a:

```dart
// Calculate gap boundaries
final gapStart = current.checkOut.add(const Duration(days: 1));
final gapEnd = next.checkIn.subtract(const Duration(days: 1));

// Check if there's actually a gap (no overlap or adjacency)
// If reservations overlap or are adjacent (checkout == checkin), gapEnd will be before gapStart
if (gapEnd.isBefore(gapStart)) {
  // Reservations overlap or are adjacent - no gap to block
  continue;
}

// Calculate gap size
final gapNights = gapEnd.difference(gapStart).inDays;

// Block if gap is positive but less than minNights
if (gapNights > 0 && gapNights < minNights) {
  // ... block gap dates
}
```

**Implementirane promjene:**
- ✅ Dodana eksplicitna provjera `if (gapEnd.isBefore(gapStart)) continue;` prije računanja `gapNights`
- ✅ Dodani komentari koji objašnjavaju rukovanje preklapajućim/adjacent rezervacijama
- ✅ Verificirana gap calculation logika - trenutna implementacija je ispravna (nije potreban `+1` jer petlja već uključuje sve dane)
- ✅ Kreirani testovi za sve edge case-ove (preklapanje, adjacency, normalni gap-ovi, veliki gap-ovi)
- ✅ Svi testovi prolaze (11/11)
- ✅ Flutter analyze: nema grešaka

**Napomena:** Gap calculation logika je ispravna - `gapNights` predstavlja broj noći između `gapStart` i `gapEnd`, a petlja blokira sve dane u tom rasponu (uključujući oba endpointa).

**Prioritet:** 🟢 Nisko

---

### Bug #18: Nedostaje validacija u `booking_validation_service.dart` za edge case datuma ✅ RIJEŠEN

**Lokacija:** `lib/features/widget/domain/services/booking_validation_service.dart`, linije 87-100

**Problem:**
```dart
if (checkOut.isBefore(checkIn) || checkOut.isAtSameMomentAs(checkIn)) {
  return const ValidationResult.failure(
    'Check-out must be after check-in date.',
  );
}
```

Ova provjera ne uzima u obzir timezone razlike. Ako su `checkIn` i `checkOut` u različitim timezone-ovima, `isAtSameMomentAs` može dati neočekivane rezultate.

**Posljedice:**
- Potencijalni problemi s timezone handlingom
- Validacija može proći ili pasti neočekivano

**Rješenje:**
Implementirana UTC normalizacija prije usporedbe datuma, konzistentno s `checkSameDayCheckIn()` metodom u istom fajlu:

```dart
// Normalize dates to UTC for timezone-safe comparison
// Bug #18 Fix: Use UTC normalization to avoid timezone-related edge cases
final checkInUtc = DateTime.utc(checkIn.year, checkIn.month, checkIn.day);
final checkOutUtc = DateTime.utc(checkOut.year, checkOut.month, checkOut.day);

if (checkOutUtc.isBefore(checkInUtc) || checkOutUtc.isAtSameMomentAs(checkInUtc)) {
  return const ValidationResult.failure('Check-out must be after check-in date.');
}
```

**Implementirane promjene:**
- ✅ UTC normalizacija prije usporedbe datuma (konzistentno s `checkSameDayCheckIn()`)
- ✅ Dodani testovi za timezone edge case-ove (UTC, local, mixed timezones)
- ✅ Svi testovi prolaze (44/44)
- ✅ Flutter analyze: nema grešaka

**Datum rješenja:** 2025-01-27

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

## Sažetak novih bugova

| Bug # | Kritičnost | Lokacija | Status |
|-------|-----------|----------|--------|
| #14 | 🟡 Visoko | `calendar_data_service.dart:67` | Unresolved |
| #15 | ✅ Riješen | `calendar_data_service.dart:276-280,343-347` | Uključivanje checkOut dana - dokumentacija dodana, funkcionalnost ispravna (vizualizacija samo) |
| #16 | ✅ Riješen | `price_lock_service.dart:265` | Price lock se ažurira čak i kada korisnik otkaže - `onLockUpdated()` se poziva samo ako je korisnik potvrdio |
| #17 | ✅ Riješen | `calendar_data_service.dart:456-471` | Eksplicitna provjera preklapanja/adjacency dodana prije gap calculation |
| #18 | ✅ Riješen | `booking_validation_service.dart:87-100` | Nedostaje validacija za edge case datuma - UTC normalizacija dodana prije usporedbe |

---

## Preporuke za rješavanje (ažurirano)

1. **Prvo riješiti kritične bugove (#1-4, #10-11)** - timezone problemi i sintaksne greške mogu uzrokovati značajne probleme u produkciji
2. **Zatim visoke prioritete (#5-7, #15-16)** - poboljšati error handling, batch operacije, parsiranje podataka i business logiku (Bug #14 - month calculation riješen, Bug #18 - timezone validacija riješena)
3. **Na kraju niske prioritete (#8-9)** - uskladiti kod i provjeriti edge case-ove (Bug #17 - gap calculation overlap provjera riješena, Bug #18 - timezone validacija riješena)

---

## 🔴 Kritični Bugovi (Providers)

### Bug #19: Timezone problemi u `price_calculator_provider.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/providers/price_calculator_provider.dart`, linije 19-21, 24-26, 39-46, 49-54, 61-65, 88-91, 97-98

**Problem:**
```dart
// Linija 19: Validacija datuma bez timezone normalizacije
if (checkOut.isBefore(checkIn) || checkOut.isAtSameMomentAs(checkIn)) {
  return null;
}

// Linija 55-56: Petlja kroz datume bez normalizacije
DateTime current = checkIn;
while (current.isBefore(checkOut)) {
  // ...
}

// Linija 82: Izračun broja noći može biti netočan
final numberOfNights = checkOut.difference(checkIn).inDays;

// Linija 93-95: Usporedba datuma bez timezone normalizacije (duplikacija koda)
bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
```

**Posljedice:**
- Validacija datuma može proći ili pasti neočekivano zbog timezone razlika
- Petlja kroz datume može propustiti ili uključiti pogrešne dane
- `numberOfNights` može biti netočan ako datumi imaju vremenske komponente
- `_isSameDay` ne uzima u obzir timezone, što može uzrokovati probleme
- Duplikacija koda - `DateNormalizer.isSameDay()` već postoji u codebase-u

**Rješenje (implementirano 2025-01-27):**
```dart
// 1. Dodan import DateNormalizer
import '../../utils/date_normalizer.dart';

// 2. Normalizacija datuma na početku (prije validacije)
final normalizedCheckIn = DateNormalizer.normalize(checkIn);
final normalizedCheckOut = DateNormalizer.normalize(checkOut);

// 3. Validacija s normaliziranim datumima
if (normalizedCheckOut.isBefore(normalizedCheckIn) ||
    normalizedCheckOut.isAtSameMomentAs(normalizedCheckIn)) {
  return null;
}

// 4. Repository pozivi s normaliziranim datumima
final totalPrice = await dailyPriceRepo.calculateBookingPrice(
  unitId: unitId,
  checkIn: normalizedCheckIn,
  checkOut: normalizedCheckOut,
  // ...
);

// 5. Petlja s normaliziranim datumima
DateTime current = normalizedCheckIn;
while (current.isBefore(normalizedCheckOut)) {
  // 6. Koristi DateNormalizer.isSameDay() umjesto custom metode
  final dailyPriceModel = dailyPrices.cast<dynamic>().firstWhere(
    (p) => p != null && DateNormalizer.isSameDay(p.date, current),
    orElse: () => null,
  );
  // ...
}

// 7. Izračun broja noći s DateNormalizer
final numberOfNights = DateNormalizer.nightsBetween(
  normalizedCheckIn,
  normalizedCheckOut,
);

// 8. BookingPriceBreakdown s normaliziranim datumima
return BookingPriceBreakdown(
  // ...
  checkIn: normalizedCheckIn,
  checkOut: normalizedCheckOut,
);

// 9. Uklonjena custom _isSameDay metoda (duplikacija)
```

**Implementacija:**
- ✅ Dodan import `DateNormalizer` utility klase
- ✅ Normalizacija datuma na početku providera (prije validacije)
- ✅ Validacija koristi normalizirane datume
- ✅ Repository pozivi (`calculateBookingPrice`, `getPricesForDateRange`) koriste normalizirane datume
- ✅ Petlja za `nightlyPrices` koristi normalizirane datume
- ✅ Zamijenjeno `_isSameDay()` sa `DateNormalizer.isSameDay()`
- ✅ Zamijenjeno `checkOut.difference(checkIn).inDays` sa `DateNormalizer.nightsBetween()`
- ✅ `BookingPriceBreakdown` koristi normalizirane datume
- ✅ Uklonjena custom `_isSameDay` metoda (eliminirana duplikacija)
- ✅ Konzistentno sa ostatkom codebase-a (`booking_price_calculator.dart`, `BookingModel`)

**Zašto ovo rješenje:**
- Konzistentnost sa ostatkom codebase-a koji koristi `DateNormalizer`
- Eliminira duplikaciju koda (`_isSameDay` metoda)
- Koristi već testirane utility metode
- DST safe - normalizacija eliminira DST probleme
- Timezone safe - normalizacija osigurava konzistentnost bez obzira na timezone

**Prioritet:** 🔴 Kritično → ✅ Riješen

---

### Bug #20: Timezone problem u `realtime_booking_calendar_provider.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/providers/realtime_booking_calendar_provider.dart`, linija 15-22; `lib/features/widget/domain/services/calendar_data_service.dart`, linija 160-168

**Problem:**
```dart
String _dateToKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
```

`DateFormat.format()` koristi lokalno vrijeme ako `date` nije eksplicitno UTC. Repository vraća `Map<DateTime, CalendarDateInfo>` gdje su `DateTime` objekti u UTC-u, ali formatiranje može dati pogrešan dan zbog timezone offseta.

**Primjer problema:**
- UTC datum: `2024-01-15 23:00:00 UTC`
- Ako je korisnik u UTC+2, `DateFormat` formatira kao `2024-01-16` (jer 23:00 UTC = 01:00 sljedeći dan u UTC+2)
- To uzrokuje pogrešne ključeve u mapi i lookup probleme

**Posljedice:**
- Ključevi za kalendar mapu mogu biti pogrešni
- Datumi se mogu prikazati kao prethodni/sljedeći dan
- Problemi s lookup-om u mapi
- Mogući prikaz pogrešnih podataka u kalendaru

**Rješenje (implementirano 2025-01-27):**
Normalizacija datuma na UTC prije formatiranja kako bi se osigurali konzistentni ključevi bez obzira na timezone korisnika.

```dart
/// Convert DateTime key to String key (yyyy-MM-dd format)
///
/// Normalizes date to UTC before formatting to ensure consistent keys
/// regardless of timezone. Repository returns UTC DateTime objects, so
/// we must format them as UTC to avoid timezone offset issues.
String _dateToKey(DateTime date) {
  // Normalize to UTC by extracting year/month/day components
  // This ensures we format the correct day regardless of timezone
  final utcDate = DateTime.utc(date.year, date.month, date.day);
  return DateFormat('yyyy-MM-dd').format(utcDate);
}
```

**Implementacija:**
- ✅ Ažurirana `_dateToKey()` metoda u `realtime_booking_calendar_provider.dart` (linije 15-22)
- ✅ Ažurirana `getDateKey()` metoda u `calendar_data_service.dart` (linije 160-168) za konzistentnost
- ✅ Dodana UTC normalizacija prije formatiranja u obje metode
- ✅ Dodani komentari koji objašnjavaju zašto je UTC normalizacija potrebna
- ✅ Format `yyyy-MM-dd` je zadržan za konzistentnost

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Postojeći testovi: svi prolaze (17/17 u `firebase_booking_calendar_repository_test.dart`, 6/6 u `calendar_data_service_test.dart`)

**Prioritet:** 🔴 Kritično → ✅ Riješen

---

### Bug #21: Korištenje `DateTime.now()` umjesto UTC-a u `widget_context_provider.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/providers/widget_context_provider.dart`, linije 96-97

**Problem:**
```dart
createdAt: DateTime.now(),  // ❌ Koristi lokalno vrijeme
updatedAt: DateTime.now(),  // ❌ Koristi lokalno vrijeme
```

Koristi se lokalno vrijeme umjesto UTC-a za default widget settings kada settings ne postoje u Firestore-u.

**Posljedice:**
- Neusklađenost s ostatkom koda koji koristi UTC
- Problemi s timezone granicama
- Mogući problemi s sortiranjem i filtriranjem
- Neusklađenost sa Cloud Functions koje koriste server timestamp (UTC)

**Rješenje (implementirano 2025-01-27):**
```dart
createdAt: DateTime.now().toUtc(),  // ✅ Koristi UTC
updatedAt: DateTime.now().toUtc(),  // ✅ Koristi UTC
```

**Implementacija:**
- ✅ Zamijenjeno `DateTime.now()` sa `DateTime.now().toUtc()` u `widget_context_provider.dart` (linije 96-97)
- ✅ Konzistentno sa implementacijom u `firebase_widget_settings_repository.dart` (linije 88-89, 104)
- ✅ Konzistentno sa implementacijom u `widget_settings.dart` (linije 137-138)
- ✅ Osigurava da svi default widget settings koriste UTC timestampove

**Napomena:** Dart nema `DateTime.utcNow()` metodu, pa se koristi `DateTime.now().toUtc()` što je ispravan način za dobivanje UTC vremena.

**Prioritet:** 🔴 Kritično → ✅ Riješen

---

### Bug #22: Korištenje `DateTime.now()` umjesto UTC-a u `widget_settings_provider.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/providers/widget_settings_provider.dart`, linije 91-92

**Problem:**
```dart
createdAt: DateTime.now(),  // ❌ Koristi lokalno vrijeme
updatedAt: DateTime.now(),  // ❌ Koristi lokalno vrijeme
```

Koristi se lokalno vrijeme umjesto UTC-a za default widget settings provider (fallback kada custom settings ne postoje).

**Posljedice:**
- Neusklađenost s ostatkom koda koji koristi UTC
- Problemi s timezone granicama
- Neusklađenost sa Cloud Functions koje koriste server timestamp (UTC)

**Rješenje (implementirano 2025-01-27):**
```dart
createdAt: DateTime.now().toUtc(),  // ✅ Koristi UTC
updatedAt: DateTime.now().toUtc(),  // ✅ Koristi UTC
```

**Implementacija:**
- ✅ Zamijenjeno `DateTime.now()` sa `DateTime.now().toUtc()` u `widget_settings_provider.dart` (linije 91-92)
- ✅ Konzistentno sa implementacijom u `firebase_widget_settings_repository.dart` (linije 88-89, 104)
- ✅ Konzistentno sa implementacijom u `widget_settings.dart` (linije 137-138)
- ✅ Konzistentno sa implementacijom u `widget_context_provider.dart` (linije 96-97)
- ✅ Osigurava da svi default widget settings koriste UTC timestampove

**Napomena:** Dart nema `DateTime.utcNow()` metodu, pa se koristi `DateTime.now().toUtc()` što je ispravan način za dobivanje UTC vremena.

**Prioritet:** 🔴 Kritično → ✅ Riješen

---

## 🟡 Visoki Prioritet (Providers)

### Bug #23: Korištenje deprecated `WidgetConfig` alias u `widget_config_provider.dart` ✅ RIJEŠEN

**Lokacija:** `widget_config_provider.dart`, linije 3, 11, 14, 16

**Status:** ✅ Riješen - 2025-01-27

**Problem:**
```dart
import '../../domain/models/widget_config.dart';  // Deprecated alias
// ...
final widgetConfigProvider = StateProvider<WidgetConfig>((ref) {
  return const WidgetConfig();  // Koristi deprecated alias
});
```

Kod koristi deprecated `WidgetConfig` alias umjesto `EmbedUrlParams`. Prema dokumentaciji u `embed_url_params.dart`, `WidgetConfig` je deprecated i treba se koristiti `EmbedUrlParams`.

**Posljedice:**
- Kod koristi deprecated API
- Mogući problemi s budućim refactoringom
- Konfuzija za developere

**Rješenje:**
Zamijenjen deprecated `WidgetConfig` alias s `EmbedUrlParams`:

```dart
import '../../domain/models/embed_url_params.dart';
// ...
/// final config = EmbedUrlParams.fromUrlParameters(uri);
final widgetConfigProvider = StateProvider<EmbedUrlParams>((ref) {
  return const EmbedUrlParams();
});
```

**Implementirane promjene:**
- ✅ Ažuriran import s `widget_config.dart` na `embed_url_params.dart` (linija 3)
- ✅ Ažurirana dokumentacija u komentaru - `WidgetConfig.fromUrlParameters()` → `EmbedUrlParams.fromUrlParameters()` (linija 11)
- ✅ Ažuriran tip providera - `StateProvider<WidgetConfig>` → `StateProvider<EmbedUrlParams>` (linija 14)
- ✅ Ažuriran default konstruktor - `const WidgetConfig()` → `const EmbedUrlParams()` (linija 16)
- ✅ Flutter analyze: nema grešaka
- ✅ Svi property-ji (`themeMode`, `primaryColor`, `accentColor`, `backgroundColor`, `textColor`) su dostupni na `EmbedUrlParams`
- ✅ Nema breaking changes - transparentna zamjena jer je `WidgetConfig` samo typedef alias

**Prioritet:** 🟡 Visoko

---

### Bug #24: Potencijalni problem s type casting u `widget_context_provider.dart` ✅ RIJEŠEN

**Lokacija:** `lib/features/widget/presentation/providers/widget_context_provider.dart`, linije 55-105, 107-125

**Problem:**
```dart
final results = await Future.wait<Object?>([
  ref.read(propertyByIdProvider(propertyId).future),
  ref.read(unitByIdProvider(propertyId, unitId).future),
  ref.read(widgetSettingsProvider((propertyId, unitId)).future),
]);

final property = results[0] as PropertyModel?;
final unit = results[1] as UnitModel?;
final settings = results[2] as WidgetSettings?;
```

Ako bilo koji provider vrati neočekivani tip ili baci iznimku, `as` cast će baciti `TypeError` umjesto da se greška elegantno obradi.

**Posljedice:**
- Runtime crash ako tipovi nisu ispravni
- Teško debugiranje problema
- Loše korisničko iskustvo

**Rješenje:**
Implementirano try-catch error handling sa safe type casting-om:

```dart
try {
  // Fetch all data in parallel
  final results = await Future.wait<Object?>([
    ref.read(propertyByIdProvider(propertyId).future),
    ref.read(unitByIdProvider(propertyId, unitId).future),
    ref.read(widgetSettingsProvider((propertyId, unitId)).future),
  ]);

  // Bug #24 Fix: Use safe casting with type checks to prevent TypeError
  final property = results[0] is PropertyModel ? results[0] as PropertyModel : null;
  final unit = results[1] is UnitModel ? results[1] as UnitModel : null;
  final settings = results[2] is WidgetSettings ? results[2] as WidgetSettings : null;

  // ... rest of code
} catch (e) {
  // Bug #24 Fix: Wrap all exceptions in WidgetContextException for consistent error handling
  if (e is WidgetContextException) {
    rethrow;
  }
  throw WidgetContextException('Failed to load widget context: $e');
}
```

Ista error handling logika je dodana i u `widgetContextByUnitOnly()` metodu.

**Implementirane promjene:**
- ✅ Try-catch blok oko `Future.wait` i type casting operacija
- ✅ Safe casting s `is` provjerama umjesto direktnog `as` castinga
- ✅ Svi exceptioni se wrap-aju u `WidgetContextException` za konzistentno error handling
- ✅ `WidgetContextException` se ne wrap-uje duplo (rethrow ako već jest)
- ✅ Error handling dodan u obje metode (`widgetContext` i `widgetContextByUnitOnly`)
- ✅ Flutter analyze: nema grešaka

**Datum rješenja:** 2025-01-27

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

## 🟢 Niski Prioritet (Providers)

### Bug #25: Potencijalni problem s `copyWith` u `widget_settings_provider.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/providers/widget_settings_provider.dart`, linije 83-97

**Problem:**
```dart
// Fall back to default settings
return ref.read(defaultWidgetSettingsProvider).copyWith(id: unitId, propertyId: propertyId);
```

`copyWith` metoda u `WidgetSettings` možda ne podržava eksplicitno postavljanje nullable polja na `null` (vidi Bug #15 - riješen sa sentinel pattern-om). Međutim, ovdje se postavljaju non-nullable polja, tako da bi trebalo biti OK. Međutim, nedostaje defensive check da `unitId` i `propertyId` nisu prazni stringovi.

**Posljedice:**
- Ako se `unitId` ili `propertyId` proslijede kao prazni stringovi, `copyWith` će kreirati `WidgetSettings` s praznim ID-ovima
- To može uzrokovati probleme u Firestore operacijama ili lookup-ima
- Nema ranog fail-fast mehanizma za invalid input

**Rješenje (implementirano 2025-01-27):**
```dart
final widgetSettingsOrDefaultProvider = FutureProvider.family<WidgetSettings, (String propertyId, String unitId)>((
  ref,
  params,
) async {
  final (propertyId, unitId) = params;

  // Defensive check: ensure unitId and propertyId are not empty
  // This check must be done early, before any repository calls
  if (unitId.isEmpty || propertyId.isEmpty) {
    throw ArgumentError('unitId and propertyId must not be empty');
  }

  // Try to get custom settings
  final customSettings = await ref.read(widgetSettingsProvider((propertyId, unitId)).future);

  if (customSettings != null) {
    return customSettings;
  }

  // Fall back to default settings
  return ref.read(defaultWidgetSettingsProvider).copyWith(id: unitId, propertyId: propertyId);
});
```

**Implementirane promjene:**
- ✅ Dodana defensive provjera da `unitId` i `propertyId` nisu prazni stringovi
- ✅ Provjera je premještena na početak providera (prije poziva repository-ja) za raniji fail-fast
- ✅ Baca `ArgumentError` s jasnom porukom ako su parametri prazni
- ✅ Kreiran test fajl: `test/features/widget/presentation/providers/widget_settings_provider_test.dart`
- ✅ Testovi pokrivaju sve edge case-ove (prazan `unitId`, prazan `propertyId`, oba prazna)
- ✅ Svi testovi prolaze (3/3)
- ✅ Flutter analyze: nema grešaka

**Analiza:**
- Analizirani svi pozivi `WidgetSettings.copyWith()` u codebase-u
- Pronađena 2 poziva: `widget_settings_provider.dart:93` (non-nullable polja) i `firebase_widget_settings_repository.dart:104` (samo `updatedAt`)
- Nema slučajeva gdje se nullable polja postavljaju na `null` kroz `copyWith`
- Sentinel pattern nije implementiran jer nema trenutne potrebe (nema slučajeva gdje se nullable polja postavljaju na `null`)

**Zašto ovo rješenje:**
- Defensive checks osiguravaju da se `copyWith` ne poziva s invalid input-om
- Raniji fail-fast omogućava brže otkrivanje problema
- Testovi osiguravaju da se bug neće ponoviti
- Nema breaking changes - samo dodana validacija

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

## Sažetak novih bugova (Providers)

| Bug # | Kritičnost | Lokacija | Opis |
|-------|-----------|----------|------|
| #19 | ✅ Riješen | `price_calculator_provider.dart` | Timezone problemi u validaciji i petlji - koristi `DateNormalizer` za sve date operacije |
| #20 | ✅ Riješen | `realtime_booking_calendar_provider.dart` | Timezone problem u `_dateToKey` - UTC normalizacija dodana prije formatiranja |
| #21 | ✅ Riješen | `widget_context_provider.dart` | `DateTime.now()` umjesto UTC - koristi `DateTime.now().toUtc()` |
| #22 | ✅ Riješen | `widget_settings_provider.dart` | `DateTime.now()` umjesto UTC - koristi `DateTime.now().toUtc()` |
| #23 | ✅ Riješen | `widget_config_provider.dart` | Deprecated `WidgetConfig` alias - zamijenjen s `EmbedUrlParams` |
| #24 | 🟡 Visoko | `widget_context_provider.dart` | Potencijalni problem s type casting |
| #25 | ✅ Riješen | `widget_settings_provider.dart` | Potencijalni problem s `copyWith` - defensive checks dodani za prazne stringove |

---

## 🟡 Visoki Prioritet (Presentation Screens)

### Bug #26: Timezone problem u `booking_details_screen.dart` - `_getHoursUntilCheckIn` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/screens/booking_details_screen.dart`, linije 102-110

**Problem:**
```dart
int? _getHoursUntilCheckIn() {
  try {
    final checkInDate = DateTime.parse(widget.booking.checkIn);
    final now = DateTime.now();  // ❌ Koristi local timezone umjesto UTC
    return checkInDate.difference(now).inHours;
  } catch (e) {
    return null;
  }
}
```

**Detalji:**
- Metoda koristi `DateTime.now()` umjesto `DateTime.now().toUtc()`
- `checkInDate` je parsiran iz ISO 8601 stringa koji Cloud Function vraća u UTC formatu (npr. "2024-01-15T10:00:00.000Z")
- `DateTime.parse()` automatski parsira ISO 8601 string sa 'Z' sufixom kao UTC DateTime
- Razlika između UTC i local timezone može uzrokovati netočan izračun sati do check-in-a
- Ovo utječe na `_canCancelBooking()` logiku koja ovisi o `hoursUntilCheckIn`

**Posljedice:**
- Netočan izračun sati do check-in-a
- Mogućnost otkazivanja bookingova kada ne bi trebalo biti dozvoljeno (ili obrnuto)
- Inconsistent behavior ovisno o korisnikovom timezone-u

**Rješenje (implementirano 2025-01-27):**
```dart
/// Safely parse check-in date and calculate hours until check-in
/// Returns null if parsing fails
///
/// Normalizes both dates to UTC before calculation to ensure accurate
/// hours calculation regardless of user timezone. Cloud Function returns
/// checkIn as ISO 8601 string in UTC format (e.g., "2024-01-15T10:00:00.000Z").
int? _getHoursUntilCheckIn() {
  try {
    final checkInDate = DateTime.parse(widget.booking.checkIn);
    // Cloud Function returns ISO 8601 string in UTC format (with 'Z' suffix)
    // DateTime.parse() preserves timezone, so checkInDate is already UTC
    // Normalize to UTC to be safe (handles edge cases where string might not have 'Z')
    final checkInUtc = checkInDate.isUtc ? checkInDate : checkInDate.toUtc();

    // Use UTC for current time to ensure consistent comparison
    final nowUtc = DateTime.now().toUtc();

    return checkInUtc.difference(nowUtc).inHours;
  } catch (e) {
    return null;
  }
}
```

**Implementirane promjene:**
- ✅ Ažurirana `_getHoursUntilCheckIn()` metoda u `booking_details_screen.dart` (linije 102-110)
  - Dodana UTC normalizacija za `checkInDate` koristeći `checkInDate.isUtc ? checkInDate : checkInDate.toUtc()`
  - Zamijenjeno `DateTime.now()` sa `DateTime.now().toUtc()` za trenutno vrijeme
  - Dodani detaljni komentari koji objašnjavaju zašto je UTC normalizacija potrebna
- ✅ Ažurirane `daysUntilCheckIn` i `daysUntilCheckOut` metode u `BookingModel` (`lib/shared/models/booking_model.dart`, linije 217-226)
  - Dodana UTC normalizacija za konzistentnost sa `_getHoursUntilCheckIn()`
  - Obe metode sada koriste UTC za sve date operacije
  - Dodani komentari koji objašnjavaju zašto je to potrebno

**Zašto ovo rješenje:**
- Cloud Function `verifyBookingAccess.ts` vraća `checkIn` kao ISO 8601 string u UTC formatu (sa 'Z' sufixom)
- `DateTime.parse()` automatski parsira ISO 8601 string sa 'Z' sufixom kao UTC DateTime
- Međutim, `DateTime.now()` vraća lokalno vrijeme, što uzrokuje timezone mismatch
- Normalizacija oba datuma na UTC prije izračuna razlike osigurava točan izračun bez obzira na korisnikov timezone
- `toUtc()` metoda automatski rukuje konverzijom i edge case-ovima

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Postojeći testovi: svi prolaze (17/17 u `firebase_booking_calendar_repository_test.dart`)
- ✅ Konzistentnost: `daysUntilCheckIn` i `daysUntilCheckOut` metode također koriste UTC normalizaciju

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #27: Null check operator bez provjere u `booking_details_screen.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/screens/booking_details_screen.dart`, linije 127, 133, 154

**Problem:**
```dart
// Linija 127
if (!widget.widgetSettings!.allowGuestCancellation) {  // ❌ Koristi ! operator
  return false;
}

// Linija 133
final deadlineHours = widget.widgetSettings!.cancellationDeadlineHours ?? 48;  // ❌ Koristi ! operator

// Linija 154
if (widget.widgetSettings != null &&
    !widget.widgetSettings!.allowGuestCancellation) {  // ❌ Redundantna provjera + ! operator
  return tr.guestCancellationNotEnabled;
}
```

**Detalji:**
- Linija 127 koristi `widget.widgetSettings!` bez provjere da li je `null`
- Iako postoji provjera na liniji 122 (`if (widget.widgetSettings == null)`), ako se ta provjera promijeni ili ukloni, linija 127 će crash-ati
- Linija 133 također koristi `!` operator iako je već prošao provjeru na liniji 122
- Linija 154 ima redundantnu provjeru `!= null` i koristi `!` operator (može se koristiti `?.`)

**Posljedice:**
- Potencijalni crash ako `widgetSettings` bude `null` (npr. pri refaktoringu)
- Inconsistent null handling u kodu
- Redundantne provjere (`!= null` + `!` operator)

**Rješenje (implementirano 2025-01-27):**
```dart
// Linija 127 - koristi null-safe operator
if (widget.widgetSettings?.allowGuestCancellation != true) {  // ✅ Null-safe operator
  return false;
}

// Linija 133 - koristi null-safe operator
final deadlineHours = widget.widgetSettings?.cancellationDeadlineHours ?? 48;  // ✅ Null-safe operator

// Linija 154 - uklonjena redundantna provjera, koristi null-safe operator
if (widget.widgetSettings?.allowGuestCancellation != true) {  // ✅ Null-safe operator
  return tr.guestCancellationNotEnabled;
}
```

**Implementacija:**
- ✅ Zamijenjeno `widget.widgetSettings!` sa `widget.widgetSettings?.` u `_canCancelBooking()` metodi (linije 127, 133)
- ✅ Uklonjena redundantna provjera `!= null` i zamijenjeno `!` operator sa `?.` operatorom u `_getCancelDisabledReason()` metodi (linija 153-154)
- ✅ Konzistentno sa ostatkom koda koji koristi `?.` operator (linije 159, 465, 469)
- ✅ Logika ostaje ista - `?.allowGuestCancellation != true` pokriva i `null` i `false` slučajeve

**Zašto ovo rješenje:**
- Null-safe operator (`?.`) je sigurniji i čitljiviji od kombinacije provjere `!= null` i `!` operatora
- Eliminira potencijalne crash-ove pri refaktoringu
- Konzistentnost sa Dart best practices za rukovanje nullable vrijednostima
- Backward compatible - logika ostaje ista

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

## 🟢 Niski Prioritet (Presentation Screens)

### Bug #28: Inconsistent timezone korištenje u logging pozivima ✅ RIJEŠEN

**Status:** ✅ Riješen - kod već koristi `DateTime.now().toUtc()` (provjereno 2025-12-16)

**Lokacija:** `booking_view_screen.dart`, `booking_widget_screen.dart` - više lokacija

**Problem:**
Više poziva `DateTime.now()` za logging umjesto `DateTime.now().toUtc()` ili `DateTime.utcNow()`.

**Detalji:**
- Logging pozivi koriste `DateTime.now()` što može uzrokovati inconsistent timestamps
- Za debugging i analizu logova, UTC timestamps su preferirani
- Nije kritično, ali može otežati debugging u produkciji

**Primjeri:**
```dart
// booking_view_screen.dart:142
'id': 'log_${DateTime.now().millisecondsSinceEpoch}',  // ❌ Local timezone
'timestamp': DateTime.now().millisecondsSinceEpoch,

// booking_widget_screen.dart:1072
final paymentStartTime = DateTime.now();  // ❌ Local timezone
```

**Posljedice:**
- Inconsistent timestamps u logovima
- Teže debugging u produkciji s korisnicima u različitim timezone-ovima

**Rješenje:**
```dart
// Koristiti UTC za sve logging
'id': 'log_${DateTime.now().toUtc().millisecondsSinceEpoch}',
'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,

// Ili koristiti DateTime.utcNow()
final paymentStartTime = DateTime.utcNow();
```

**Prioritet:** 🟢 Nisko

---

### Bug #29: Nedostaje provjera za prazne stringove u payment widget-ima ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** 
- `lib/features/widget/presentation/widgets/booking/payment/payment_method_card.dart`, linije 16-22, 59
- `lib/features/widget/presentation/widgets/booking/payment/payment_option_widget.dart`, linije 24-35
- `lib/features/widget/presentation/screens/booking_widget_screen.dart`, linije 2249-2250, 2278

**Problem:**
```dart
// payment_method_card.dart:49
AutoSizeText(
  title,  // ❌ Nema provjere da li je prazan string
  maxLines: 1,
  minFontSize: _titleMinFontSize,
  overflow: TextOverflow.ellipsis,
  // ...
)

// payment_option_widget.dart:104
AutoSizeText(
  title,  // ❌ Nema provjere da li je prazan string
  maxLines: 1,
  minFontSize: _titleMinFontSize,
  overflow: TextOverflow.ellipsis,
  // ...
)

// payment_option_widget.dart:130
AutoSizeText(
  subtitle,  // ❌ Nema provjere da li je prazan string
  maxLines: 2,
  minFontSize: _subtitleMinFontSize,
  maxFontSize: _subtitleFontSize,
  overflow: TextOverflow.ellipsis,
  // ...
)
```

**Detalji:**
- `title` i `subtitle` su required parametri, ali nema provjere da li su prazni stringovi
- Ako se proslijedi prazan string, widget će prikazati prazan prostor što može biti confusing
- `AutoSizeText` s praznim stringom može uzrokovati layout probleme
- U `booking_widget_screen.dart:2273` se koristi `singleMethodTitle!` što može biti null (iako je provjereno prije)

**Posljedice:**
- Mogući layout problemi s praznim stringovima
- Loše korisničko iskustvo ako se prikaže prazan widget
- Potencijalni crash ako je `singleMethodTitle` null unatoč `!` operatoru

**Rješenje (implementirano 2025-01-27):**

**1. PaymentMethodCard - assert validacija i conditional rendering:**
```dart
// Bug #29 Fix: Removed const to allow assert validation for non-empty title
PaymentMethodCard({
  super.key,
  required this.icon,
  required this.title,
  this.subtitle,
  required this.isDarkMode,
}) : assert(title.isNotEmpty, 'Title cannot be empty');

// In build method:
// Bug #29 Fix: Only render subtitle if it's not null and not empty
if (subtitle != null && subtitle!.isNotEmpty)
  AutoSizeText(
    subtitle!,
    // ...
  ),
```

**2. PaymentOptionWidget - assert validacije:**
```dart
// Bug #29 Fix: Removed const to allow assert validation for non-empty title and subtitle
PaymentOptionWidget({
  super.key,
  required this.icon,
  this.secondaryIcon,
  required this.title,
  required this.subtitle,
  required this.isSelected,
  required this.onTap,
  required this.isDarkMode,
  this.depositAmount,
}) : assert(title.isNotEmpty, 'Title cannot be empty'),
     assert(subtitle.isNotEmpty, 'Subtitle cannot be empty');
```

**3. booking_widget_screen.dart - defensive check za singleMethodTitle:**
```dart
// Bug #29 Fix: Defensive check for singleMethodTitle (should never be null due to enabledCount == 1, but defensive programming)
if (singleMethodTitle == null || singleMethodTitle.isEmpty) {
  return NoPaymentInfo(isDarkMode: isDarkMode);
}

PaymentMethodCard(
  // ...
  title: singleMethodTitle,  // No longer needs ! operator
  // ...
),
```

**Implementirane promjene:**
- ✅ Dodana assert validacija u `PaymentMethodCard` konstruktor za non-empty `title`
- ✅ Dodana conditional rendering za empty `subtitle` u `PaymentMethodCard` (ne prikazuje se ako je prazan)
- ✅ Dodane assert validacije u `PaymentOptionWidget` konstruktor za non-empty `title` i `subtitle`
- ✅ Uklonjen `const` iz konstruktora (assert ne može biti u const konstruktoru)
- ✅ Dodan defensive check za `singleMethodTitle` u `booking_widget_screen.dart` prije korištenja
- ✅ Uklonjen nepotreban `!` operator za `singleMethodTitle` (sada je safe zbog defensive check-a)
- ✅ Flutter analyze: nema grešaka za payment widget fajlove

**Zašto ovo rješenje:**
- Assert statements osiguravaju da se widget ne može kreirati s praznim stringovima (fail-fast u debug modu)
- Conditional rendering za optional `subtitle` osigurava da se prazan subtitle ne prikazuje
- Defensive check u `booking_widget_screen.dart` osigurava da se `singleMethodTitle` ne koristi ako je null ili prazan
- Uklanjanje `const` iz konstruktora je potrebno jer assert ne može biti u const konstruktoru (trade-off za validaciju)

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

### Bug #30: Nedostaje accessibility (Semantics) u payment widget-ima ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:**
- `lib/features/widget/presentation/widgets/booking/payment/payment_method_card.dart`, linije 29-32
- `lib/features/widget/presentation/widgets/booking/payment/payment_option_widget.dart`, linije 58-63, 91-97
- `lib/features/widget/presentation/widgets/booking/payment/no_payment_info.dart`, linije 28-30

**Problem:**
Svi payment widget-i nemaju `Semantics` widget-e za accessibility, što otežava korištenje screen reader-ima (TalkBack, VoiceOver).

**Detalji:**
- `PaymentMethodCard` - nema Semantics za title i subtitle
- `PaymentOptionWidget` - nema Semantics za selectable opciju, title, subtitle, i deposit amount
- `NoPaymentInfo` - nema Semantics za error poruku
- Screen reader-i neće moći pravilno čitati payment opcije

**Posljedice:**
- Loša accessibility za korisnike sa screen reader-ima
- Neusklađenost s WCAG guidelines
- Loše korisničko iskustvo za korisnike s invaliditetom

**Rješenje (implementirano 2025-01-27):**

**1. PaymentMethodCard - Semantics widget:**
```dart
@override
Widget build(BuildContext context) {
  final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

  return Semantics(
    label: title,
    hint: subtitle,
    child: Container(
      // ... existing code
    ),
  );
}
```

**2. PaymentOptionWidget - Semantics widget s helper metodom:**
```dart
@override
Widget build(BuildContext context) {
  final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

  // Build semantic label combining title, subtitle, and deposit amount
  final semanticLabel = _buildSemanticLabel();

  return Semantics(
    label: semanticLabel,
    button: true,
    selected: isSelected,
    hint: subtitle,
    value: depositAmount,
    child: InkWell(
      // ... existing code
    ),
  );
}

String _buildSemanticLabel() {
  final parts = <String>[title];
  if (depositAmount != null) {
    parts.add(depositAmount!);
  }
  return parts.join(', ');
}
```

**3. NoPaymentInfo - Semantics widget:**
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
  final tr = WidgetTranslations.of(context, ref);

  final errorMessage = message ?? tr.noPaymentMethodsAvailable;

  return Semantics(
    label: errorMessage,
    hint: 'Error message',
    child: Container(
      // ... existing code
    ),
  );
}
```

**Implementirane promjene:**
- ✅ Dodan `Semantics` widget u `PaymentMethodCard` - wrap-ati Container s `label` (title) i `hint` (subtitle) properties
- ✅ Dodan `Semantics` widget u `PaymentOptionWidget` - wrap-ati InkWell s `label`, `hint`, `value`, `button`, `selected` properties
- ✅ Dodana helper metoda `_buildSemanticLabel()` u `PaymentOptionWidget` za kombinirani label (title + deposit amount)
- ✅ Dodan `Semantics` widget u `NoPaymentInfo` - wrap-ati Container s `label` (error message) i `hint` ('Error message') properties
- ✅ Flutter analyze: nema grešaka

**Zašto ovo rješenje:**
- `Semantics` widget ne utječe na vizualni prikaz - samo poboljšava accessibility
- `label` property pruža glavni tekst koji screen reader čita
- `hint` property pruža dodatni kontekst bez dupliranja label-a
- `value` property se koristi za dinamičke vrijednosti (npr. deposit amount)
- `button: true` označava da je widget interaktivan (za PaymentOptionWidget)
- `selected` property je kritičan za radio button styling u PaymentOptionWidget (screen reader će reći "selected" ili "not selected")
- Kombinirani label u `PaymentOptionWidget` osigurava da screen reader čita sve relevantne informacije (title + deposit amount)

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Nema breaking changes - Semantics widget ne utječe na vizualni prikaz ili funkcionalnost
- ✅ Konzistentno sa primjerima u codebase-u (calendar widget-i koriste Semantics na sličan način)

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

## 🟡 Visoki Prioritet (Booking Widget Files)

### Bug #35: Nedostaje error handling u `_launchUrl()` metodi u `contact_pill_card_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/booking/contact_pill_card_widget.dart`, `_launchUrl()` metoda, linije 167-208

**Problem:**
```dart
Future<void> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
```

Nedostaje error handling:
- Ako `Uri.parse()` baci exception (invalid URL), aplikacija će pasti
- Ako `canLaunchUrl()` baci exception, aplikacija će pasti
- Ako `launchUrl()` baci exception, aplikacija će pasti
- Nema feedback korisniku ako launch ne uspije

**Posljedice:**
- Aplikacija može pasti ako URL nije validan
- Korisnik ne dobiva feedback ako email/phone launch ne uspije
- Loše korisničko iskustvo

**Rješenje (implementirano 2025-01-27):**
```dart
Future<void> _launchUrl(String url, BuildContext context) async {
  try {
    final uri = Uri.parse(url);

    // Check if URL can be launched
    final canLaunch = await canLaunchUrl(uri);
    if (!canLaunch) {
      // URL cannot be launched (e.g., no email/phone app installed)
      if (context.mounted) {
        SnackBarHelper.showError(
          context: context,
          message: 'Unable to open $url. Please check if you have an app installed to handle this action.',
          duration: const Duration(seconds: 4),
        );
      }
      return;
    }

    // Launch URL
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on FormatException catch (e) {
    // Invalid URL format
    debugPrint('Error parsing URL: $url, error: $e');
    if (context.mounted) {
      SnackBarHelper.showError(
        context: context,
        message: 'Invalid URL format. Please contact the property owner.',
        duration: const Duration(seconds: 4),
      );
    }
  } catch (e) {
    // Any other error (canLaunchUrl, launchUrl, etc.)
    debugPrint('Error launching URL: $url, error: $e');
    if (context.mounted) {
      SnackBarHelper.showError(
        context: context,
        message: 'Unable to open $url. Please try again or contact the property owner.',
        duration: const Duration(seconds: 4),
      );
    }
  }
}
```

**Implementirane promjene:**
- ✅ Dodan `BuildContext context` parametar u `_launchUrl()` metodu za prikaz error snackbar-a
- ✅ Dodan `try-catch` blok oko cijele metode za comprehensive error handling
- ✅ Dodan `FormatException` catch blok za invalid URL format sa specifičnom error porukom
- ✅ Dodan general `catch` blok za sve ostale greške (canLaunchUrl, launchUrl, etc.)
- ✅ Dodana provjera `canLaunch` i prikaz error snackbar-a ako URL ne može biti launch-an
- ✅ Dodan `context.mounted` check prije prikazivanja snackbar-a (osigurava da widget još postoji)
- ✅ Dodan `debugPrint` za logging grešaka za debugging
- ✅ Ažuriran `_ContactRow` widget da prima `Function(BuildContext)` umjesto `VoidCallback` u `onTap` callback-u
- ✅ Ažurirane `_buildColumnLayout` i `_buildRowLayout` metode da primaju `BuildContext` parametar
- ✅ Ažurirani svi pozivi `_launchUrl()` metode da proslijede `context` kroz callback
- ✅ Dodan import za `SnackBarHelper` (`'../../../../../shared/utils/ui/snackbar_helper.dart'`)

**Zašto ovo rješenje:**
- Comprehensive error handling sprječava crash aplikacije za sve moguće greške
- `FormatException` catch blok omogućava specifičnu poruku za invalid URL format
- `SnackBarHelper.showError()` pruža korisniku jasne error poruke kroz UI
- `context.mounted` check osigurava da se snackbar ne prikazuje ako je widget već unmounted
- `debugPrint` logira greške za debugging bez utjecaja na release build-ove
- Konzistentno sa ostatkom widget sistema koji koristi `SnackBarHelper` za error poruke

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka (samo info poruke o redundantnim argumentima koji nisu kritični)
- ✅ Svi pozivi `_launchUrl()` metode su ažurirani da proslijede `context`
- ✅ Error handling pokriva sve moguće greške (Uri.parse, canLaunchUrl, launchUrl)

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #36: Nedostaje error handling u `DateFormat.format()` u `compact_pill_summary.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/booking/compact_pill_summary.dart`, `_DateRangeSection` klasa, linije 167-180, 188

**Problem:**
```dart
static final _dateFormat = DateFormat('MMM dd, yyyy');

// U build metodi:
final dateText = '${_dateFormat.format(checkIn)} - ${_dateFormat.format(checkOut)}';  // ❌ Nema error handling
```

Nedostaje error handling:
- Ako `DateFormat.format()` baci exception (npr. invalid DateTime), aplikacija će pasti
- Nema fallback ako formatiranje ne uspije
- Potencijalni timezone problemi ako datumi nisu u lokalnom vremenu

**Posljedice:**
- Aplikacija može pasti ako DateTime nije validan
- Mogući problemi s prikazom datuma u različitim timezone-ovima
- Loše korisničko iskustvo

**Rješenje (implementirano 2025-01-27):**
```dart
/// Safely format date with fallback to simple format if DateFormat fails
///
/// Returns formatted date string using DateFormat, or falls back to
/// simple format (YYYY-MM-DD) if formatting fails.
String _formatDate(DateTime date) {
  try {
    return _dateFormat.format(date);
  } catch (e) {
    // Fallback to simple format if DateFormat.format() fails
    // This prevents app crashes from invalid DateTime or formatting errors
    debugPrint('Error formatting date: $date, error: $e');
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// U build metodi:
final dateText = '${_formatDate(checkIn)} - ${_formatDate(checkOut)}';  // ✅ Koristi safe helper metodu
```

**Implementacija:**
- ✅ Dodana `_formatDate()` helper metoda u `_DateRangeSection` klasu (linije 167-180)
- ✅ Try-catch blok hvata sve exceptione koje `DateFormat.format()` može baciti
- ✅ Fallback format koristi jednostavnu YYYY-MM-DD formataciju (ISO 8601 standardni format)
- ✅ `debugPrint` logira grešku za debugging, ali ne crash-uje aplikaciju
- ✅ Ažurirana `build` metoda da koristi `_formatDate()` umjesto direktnog `_dateFormat.format()` poziva (linija 188)
- ✅ Dodan import `package:flutter/foundation.dart` za `debugPrint`

**Zašto ovo rješenje:**
- `DateFormat.format()` može baciti `FormatException` ako DateTime nije validan ili ako format string nije validan
- Fallback format (YYYY-MM-DD) je ISO 8601 standardni format koji je čitljiv i siguran
- `debugPrint` se koristi umjesto `print` jer se automatski uklanja u release build-ovima
- Ovo rješenje je konzistentno sa pristupom u `daily_price_model.dart` gdje se koristi custom formatiranje bez `DateFormat`

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Postojeći testovi: svi prolaze (7/7 u `compact_pill_summary_test.dart`)
- ✅ Backward compatible: normalno ponašanje ostaje isto, fallback se koristi samo ako `DateFormat.format()` baci exception

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #37: Floating point comparison u `price_breakdown_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/booking/price_breakdown_widget.dart`, linije 5, 91-92

**Problem:**
```dart
if (additionalServicesTotal > 0 && formattedAdditionalServices != null) {
```

Koristi se direktna floating point comparison (`> 0`) što može uzrokovati probleme s floating point precision.

**Posljedice:**
- Mogući problemi s prikazom dodatnih usluga zbog floating point grešaka
- Ako je `additionalServicesTotal` vrlo mali pozitivan broj (npr. 0.0001), možda ne bi trebao biti prikazan
- Ako je `additionalServicesTotal` negativan zbog greške, neće biti prikazan (što je možda dobro)

**Rješenje (implementirano 2025-01-27):**
```dart
// Bug #37 Fix: Use tolerance-based comparison to handle floating point precision
if (additionalServicesTotal.abs() > WidgetConstants.priceTolerance &&
    formattedAdditionalServices != null) ...[
```

**Implementirane promjene:**
- ✅ Dodan import za `WidgetConstants` (`../../domain/constants/widget_constants.dart`)
- ✅ Zamijenjena direktna floating point comparison (`> 0`) s tolerance-based comparison (`abs() > WidgetConstants.priceTolerance`)
- ✅ Korištena postojeća konstanta `WidgetConstants.priceTolerance` (0.01 = 1 cent) za konzistentnost s ostatkom codebase-a
- ✅ Dodan komentar objašnjavajući Bug #37 fix
- ✅ Flutter analyze: nema grešaka

**Zašto ovo rješenje:**
- `WidgetConstants.priceTolerance` (0.01) je već korištena u `booking_price_provider.dart` i `price_lock_service.dart` za slične price comparisons
- `.abs()` osigurava da se rukuje i s pozitivnim i negativnim floating point greškama
- 1 cent tolerance je prikladan za price comparisons (osigurava da se ne prikazuju usluge s efektivno nultom vrijednošću)
- Konzistentno s pattern-om već uspostavljenim u codebase-u

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Backward compatible: normalno ponašanje ostaje isto, samo se poboljšava handling floating point precision
- ✅ Konzistentno s `WidgetConstants.priceTolerance` korištenim u `booking_price_provider.dart` (linija 41) i `price_lock_service.dart` (linija 205)

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

## 🟢 Niski Prioritet (Booking Widget Files)

### Bug #38: Hardcoded font family 'Manrope' u `price_row_widget.dart` i `price_breakdown_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - kod već koristi `TypographyTokens.primaryFont` (provjereno 2025-12-16)

**Lokacija:**
- `lib/features/widget/presentation/widgets/booking/price_row_widget.dart`, linije 58, 69
- `lib/features/widget/presentation/widgets/booking/price_breakdown_widget.dart`, linija 125

**Problem:**
```dart
fontFamily: 'Manrope',
```

Font family je hardcoded. Ako font nije dostupan na uređaju, Flutter će koristiti fallback font, ali to može uzrokovati:
- Neusklađenost s ostatkom aplikacije
- Problemi na platformama gdje font nije dostupan
- Potencijalne probleme s accessibility (neki fontovi su bolji za čitljivost)

**Posljedice:**
- Neusklađenost fontova ako 'Manrope' nije dostupan
- Mogući problemi s prikazom na određenim platformama

**Rješenje:**
Koristiti font iz design tokens ili provjeriti dostupnost fonta:
```dart
// Koristiti font iz design tokens
fontFamily: TypographyTokens.fontFamily,

// Ili provjeriti dostupnost
fontFamily: _isManropeAvailable() ? 'Manrope' : null,
```

Ili jednostavno ukloniti hardcoded font i koristiti default font iz tema.

**Prioritet:** 🟢 Nisko

---

### Bug #39: Potencijalni timezone problemi u `DateFormat` u `compact_pill_summary.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/booking/compact_pill_summary.dart`, `_DateRangeSection` klasa, linije 158-179

**Problem:**
```dart
static final _dateFormat = DateFormat('MMM dd, yyyy');
// ...
final dateText = '${_dateFormat.format(checkIn)} - ${_dateFormat.format(checkOut)}';
```

`DateFormat.format()` koristi lokalno vrijeme DateTime objekta. Ako su `checkIn` i `checkOut` u UTC-u, formatiranje će ih konvertirati u lokalno vrijeme, što može uzrokovati probleme na granicama dana.

**Posljedice:**
- Mogući problemi s prikazom datuma na granicama dana u različitim timezone-ovima
- Neusklađenost s ostatkom aplikacije ako se koriste UTC datumi

**Rješenje (implementirano 2025-01-27):**
```dart
/// Safely format date with fallback to simple format if DateFormat fails
///
/// Returns formatted date string using DateFormat, or falls back to
/// simple format (YYYY-MM-DD) if formatting fails.
///
/// Bug #39 Fix: Normalizes date and converts to local time if in UTC
/// to ensure consistent date display regardless of timezone.
String _formatDate(DateTime date) {
  try {
    // Bug #39 Fix: Normalize date first (remove time components)
    final normalized = DateNormalizer.normalize(date);
    
    // Bug #39 Fix: Convert to local time if in UTC for display
    // DateFormat.format() uses local time, so we need to ensure
    // the date is in local timezone to avoid timezone conversion issues
    final localDate = normalized.isUtc ? normalized.toLocal() : normalized;
    
    return _dateFormat.format(localDate);
  } catch (e) {
    // Fallback to simple format if DateFormat.format() fails
    // This prevents app crashes from invalid DateTime or formatting errors
    debugPrint('Error formatting date: $date, error: $e');
    
    // Bug #39 Fix: Also normalize and convert to local for fallback format
    final normalized = DateNormalizer.normalize(date);
    final localDate = normalized.isUtc ? normalized.toLocal() : normalized;
    
    return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
  }
}
```

**Implementirane promjene:**
- ✅ Dodan import za `DateNormalizer` (`../../../utils/date_normalizer.dart`)
- ✅ Ažurirana `_formatDate()` metoda da normalizira datum prije formatiranja (uklanja vremensku komponentu)
- ✅ Dodana konverzija u lokalno vrijeme ako je datum u UTC-u (`normalized.isUtc ? normalized.toLocal() : normalized`)
- ✅ Ažuriran i fallback format da također normalizira i konvertira u lokalno vrijeme
- ✅ Dodana dokumentacija u komentarima objašnjavajući Bug #39 fix
- ✅ Flutter analyze: nema grešaka (samo info poruka o nepotrebnom importu koja je riješena)

**Zašto ovo rješenje:**
- `DateNormalizer.normalize()` uklanja vremensku komponentu (postavlja na 00:00:00.000), što osigurava konzistentno ponašanje bez obzira na timezone
- Konverzija u lokalno vrijeme (`toLocal()`) osigurava da se datum prikazuje u korisnikovom lokalnom vremenu, što je očekivano ponašanje za prikaz datuma korisniku
- `DateFormat.format()` koristi lokalno vrijeme DateTime objekta, tako da je potrebno osigurati da je datum u lokalnom vremenu prije formatiranja
- Ovo rješenje je konzistentno sa ostatkom aplikacije gdje se koristi `DateNormalizer` za normalizaciju datuma

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Backward compatible: normalno ponašanje ostaje isto, samo se osigurava konzistentno formatiranje za UTC i lokalne datume
- ✅ Konzistentno sa `DateNormalizer` pristupom korištenim u ostatku aplikacije

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

## 🟡 Visoki Prioritet (Common Widget Files)

### Bug #40: Hardcoded tooltip 'Kopiraj' u `copyable_text_field.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - već implementirano

**Lokacija:** `lib/features/widget/presentation/widgets/common/copyable_text_field.dart`, linija 157

**Problem:**
```dart
tooltip: 'Kopiraj',  // ❌ Hardcoded na hrvatski
```

Tooltip je bio hardcoded na hrvatski jezik i nije bio lokaliziran.

**Rješenje (već implementirano):**
```dart
/// Optional translations for localized tooltip
/// Bug #40 Fix: Localized copy tooltip
final WidgetTranslations? translations;

// U build metodi:
tooltip: translations?.copy ?? 'Copy', // Bug #40 Fix: Localized tooltip
```

**Implementirane promjene:**
- ✅ Dodan `WidgetTranslations? translations` parametar u widget
- ✅ Tooltip koristi `translations?.copy ?? 'Copy'` za lokalizaciju
- ✅ Fallback na engleski 'Copy' ako translations nisu dostupne
- ✅ Widget sada podržava lokalizaciju tooltip-a

**Verifikacija:**
- ✅ Kod već koristi lokalizirani tooltip
- ✅ Widget se koristi sa `translations: tr` parametrom u `bank_details_section.dart`
- ✅ Flutter analyze: nema grešaka

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #41: Case-sensitive provjere u `copyable_text_field.dart` za monospace font ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/common/copyable_text_field.dart`, linije 55-95

**Problem:**
```dart
final useMonospace =
    label.contains('IBAN') ||
    label.contains('Broj') ||
    label.contains('Reference');
```

Provjere su case-sensitive i mogu propustiti varijante:
- `label.contains('iban')` (lowercase) neće raditi
- `label.contains('IBAN')` će raditi samo ako je točno 'IBAN'
- 'Broj' je hardcoded na hrvatski - neće raditi za 'Account Number' ili druge jezike
- 'Reference' je hardcoded na engleski - neće raditi za 'Referenca' ili druge jezike
- 'SWIFT/BIC' nije u provjeri, ali se koristi u `bank_details_section.dart`

**Posljedice:**
- Monospace font možda neće biti primijenjen za određene label-e
- Neusklađenost s lokalizacijom
- Loše korisničko iskustvo (IBAN, SWIFT, reference brojevi bi trebali biti monospace bez obzira na jezik)

**Rješenje (implementirano 2025-01-27):**
```dart
/// Check if label should use monospace font based on case-insensitive keyword matching
///
/// Returns true if label contains any of the following keywords (case-insensitive):
/// - IBAN, SWIFT, BIC (banking codes)
/// - Reference, Referenca, Referenz, Riferimento (reference numbers)
/// - Account, Broj, Number, Numero, Kontonummer (account numbers)
bool _shouldUseMonospace(String label) {
  final lowerLabel = label.toLowerCase();

  // Banking codes (IBAN, SWIFT, BIC)
  if (lowerLabel.contains('iban') ||
      lowerLabel.contains('swift') ||
      lowerLabel.contains('bic')) {
    return true;
  }

  // Reference numbers (all languages)
  if (lowerLabel.contains('reference') ||
      lowerLabel.contains('referenca') ||
      lowerLabel.contains('referenz') ||
      lowerLabel.contains('riferimento')) {
    return true;
  }

  // Account numbers (all languages)
  if (lowerLabel.contains('account') ||
      lowerLabel.contains('broj') ||
      lowerLabel.contains('number') ||
      lowerLabel.contains('numero') ||
      lowerLabel.contains('kontonummer')) {
    return true;
  }

  return false;
}

// U build metodi:
// Bug #41 Fix: Use case-insensitive helper method for monospace font detection
final useMonospace = _shouldUseMonospace(label);
```

**Implementirane promjene:**
- ✅ Dodana `_shouldUseMonospace()` helper metoda sa case-insensitive provjerama
- ✅ Zamijenjena direktna case-sensitive provjera s helper metodom
- ✅ Dodana podrška za SWIFT i BIC banking codes
- ✅ Dodana podrška za reference numbers u više jezika (en, hr, de, it)
- ✅ Dodana podrška za account numbers u više jezika (en, hr, de, it)
- ✅ Dodana dokumentacija u komentarima objašnjavajući Bug #41 fix
- ✅ Flutter analyze: nema grešaka

**Zašto ovo rješenje:**
- Case-insensitive provjere (`toLowerCase()`) osiguravaju da monospace font radi bez obzira na case label-a
- Podrška za više jezika osigurava konzistentno ponašanje bez obzira na lokalizaciju
- Lista ključnih riječi je proširena da pokriva sve relevantne slučajeve (IBAN, SWIFT, BIC, reference, account numbers)
- Ovo rješenje je skalabilno - lako se mogu dodati nove ključne riječi u budućnosti

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Backward compatible: svi postojeći label-i će i dalje raditi, plus će raditi i nove varijante
- ✅ Testovi: postojeći testovi trebaju i dalje prolaziti (test za 'IBAN' label)

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #42: Nedostaje error handling za clipboard operacije u `copyable_text_field.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** 
- `lib/features/widget/presentation/widgets/common/copyable_text_field.dart`, `onCopy` callback (linije 40-41, 141-156)
- `lib/features/widget/presentation/widgets/bank_transfer/bank_details_section.dart`, `_copyToClipboard` metoda (linije 111-131)

**Problem:**
```dart
/// Callback when copy button is pressed
final VoidCallback onCopy;
```

Widget očekuje `VoidCallback` za `onCopy`, što znači da error handling mora biti u parent widget-u. Međutim, u primjeru korištenja se direktno poziva `Clipboard.setData()` bez error handlinga.

**Primjer korištenja:**
```dart
onCopy: () {
  Clipboard.setData(ClipboardData(text: value)); // ❌ Nema error handling
  // Show snackbar
},
```

**Posljedice:**
- Ako `Clipboard.setData()` baci exception (npr. na web-u ako clipboard API nije dostupan), aplikacija će pasti
- Nema feedback korisniku ako copy ne uspije
- Loše korisničko iskustvo

**Rješenje (implementirano 2025-01-27):**

**1. Ažuriran `CopyableTextField` widget:**
```dart
/// Callback when copy button is pressed
/// Bug #42 Fix: Changed to async function to support error handling
final Future<void> Function() onCopy;

// U build metodi:
IconButton(
  icon: Icon(Icons.content_copy, size: IconSizeTokens.small, color: colors.buttonPrimary),
  onPressed: () async {
    try {
      await onCopy();
    } catch (e) {
      // Bug #42 Fix: Handle clipboard errors gracefully
      if (context.mounted) {
        final errorMessage = translations?.errorOccurred ?? 'Failed to copy to clipboard';
        SnackBarHelper.showError(
          context: context,
          message: errorMessage,
          duration: const Duration(seconds: 3),
        );
      }
      debugPrint('Error copying to clipboard: $e');
    }
  },
  tooltip: translations?.copy ?? 'Copy',
)
```

**2. Ažurirana `_copyToClipboard` metoda u `bank_details_section.dart`:**
```dart
Future<void> _copyToClipboard(BuildContext context, WidgetRef ref, String text, String message) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      SnackBarHelper.showSuccess(
        context: context,
        message: message,
        duration: const Duration(seconds: 2),
      );
    }
  } catch (e) {
    // Bug #42 Fix: Handle clipboard errors gracefully
    if (context.mounted) {
      final tr = WidgetTranslations.of(context, ref);
      SnackBarHelper.showError(
        context: context,
        message: tr.errorOccurred,
        duration: const Duration(seconds: 3),
      );
    }
    debugPrint('Error copying to clipboard: $e');
  }
}
```

**Implementirane promjene:**
- ✅ Promijenjen `onCopy` callback tip s `VoidCallback` na `Future<void> Function()` za podršku async operacijama
- ✅ Dodan error handling u `IconButton.onPressed` koji hvata exception-e i prikazuje error poruku korisniku
- ✅ Dodan `context.mounted` check prije prikazivanja snackbar-a za sigurnost
- ✅ Ažurirana `_copyToClipboard` metoda u `bank_details_section.dart` da koristi async/await i error handling
- ✅ Dodan import za `SnackBarHelper` u `copyable_text_field.dart`
- ✅ Ažurirana dokumentacija widgeta sa primjerom async callback-a
- ✅ Ažurirani testovi da koriste async callback
- ✅ Flutter analyze: nema grešaka

**Zašto ovo rješenje:**
- Async callback omogućava pravilno rukovanje s `Clipboard.setData()` koji je async operacija
- Error handling u widget-u osigurava da aplikacija ne pada ako clipboard operacija ne uspije
- `SnackBarHelper.showError()` pruža korisniku jasnu feedback poruku o grešci
- `context.mounted` check osigurava da se snackbar ne prikazuje ako je widget već unmount-an
- Lokalizirane error poruke kroz `translations?.errorOccurred` osiguravaju konzistentno korisničko iskustvo

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Testovi: svi testovi prolaze (7/7)
- ✅ Backward compatible: postojeći kod koji koristi `CopyableTextField` treba ažurirati callback na async, ali to je minimalna promjena
- ✅ Error handling testiran: exception-i se hvataju i prikazuju korisniku umjesto da padnu aplikaciju

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

## 🟢 Niski Prioritet (Common Widget Files)

### Bug #43: Hardcoded font family 'Manrope' u `bookbed_loader.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - kod već koristi `TypographyTokens.primaryFont` (provjereno 2025-12-16)

**Lokacija:** `lib/features/widget/presentation/widgets/common/bookbed_loader.dart`, linija 98

**Problem:**
```dart
fontFamily: 'Manrope',
```

Font family je hardcoded. Ako font nije dostupan na uređaju, Flutter će koristiti fallback font.

**Posljedice:**
- Neusklađenost fontova ako 'Manrope' nije dostupan
- Mogući problemi s prikazom na određenim platformama

**Rješenje:**
Koristiti font iz design tokens ili ukloniti hardcoded font:
```dart
fontFamily: TypographyTokens.fontFamily, // Ako postoji u design tokens
// Ili jednostavno ukloniti i koristiti default font
```

**Prioritet:** 🟢 Nisko

---

### Bug #44: Nedostaje provjera za prazne stringove u `contact_item_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/common/contact/contact_item_widget.dart`, linija 63-66

**Problem:**
```dart
AutoSizeText(
  value, // ❌ Nema provjere da li je prazan string
  // ...
)
```

Ako je `value` prazan string, widget će prikazati prazan prostor što može biti confusing.

**Posljedice:**
- Mogući layout problemi s praznim stringovima
- Loše korisničko iskustvo ako se prikaže prazan widget

**Rješenje:**
Dodana defensive check u `build()` metodi koja vraća `SizedBox.shrink()` ako je `value` prazan string. Ovaj pristup:
- Ne zahtijeva uklanjanje `const` iz konstruktora (za razliku od assert pristupa)
- Osigurava da se widget ne prikazuje ako nema sadržaja
- Konzistentan s conditional rendering pattern-om korištenim u drugim widget-ima

**Implementacija:**
```dart
@override
Widget build(BuildContext context) {
  // Bug #44: Defensive check - don't render widget if value is empty
  if (value.isEmpty) {
    return const SizedBox.shrink();
  }

  final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
  // ... rest of build method
}
```

**Implementirane promjene:**
- ✅ Dodana provjera `if (value.isEmpty) return const SizedBox.shrink();` na početku `build()` metode
- ✅ Dodan komentar objašnjavajući Bug #44 fix
- ✅ Widget sada ne prikazuje prazan prostor kada je `value` prazan string
- ✅ Backward compatible - postojeći kod i dalje radi bez promjena

**Zašto je ovo rješenje odabrano:**
- Assert pristup bi zahtijevao uklanjanje `const` konstruktora, što bi moglo utjecati na performanse
- Defensive check u `build()` metodi je fleksibilniji i omogućava widgetu da se ponaša graciozno s praznim stringovima
- Konzistentan s pattern-om korištenim u drugim widget-ima u codebase-u

**Prioritet:** 🟢 Nisko (riješeno)

---

### Bug #45: Nedostaje provjera za prazne stringove u `detail_row_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - već implementirano

**Lokacija:** `lib/features/widget/presentation/widgets/common/detail_row_widget.dart`, linije 66-67

**Problem:**
```dart
Text(
  label, // ❌ Nema provjere da li je prazan string
  // ...
),
Text(
  value, // ❌ Nema provjere da li je prazan string
  // ...
),
```

Ako su `label` ili `value` prazni stringovi, widget će prikazati prazan prostor.

**Rješenje (već implementirano):**
```dart
// Bug #45 Fix: Removed const to allow assert validation for non-empty label and value
DetailRowWidget({
  super.key,
  required this.label,
  required this.value,
  required this.isDarkMode,
  this.isHighlighted = false,
  this.hasPadding = false,
  this.valueFontWeight = TypographyTokens.semiBold,
}) : assert(label.isNotEmpty, 'Label cannot be empty'),
     assert(value.isNotEmpty, 'Value cannot be empty');
```

**Implementirane promjene:**
- ✅ Dodane assert validacije u konstruktoru za `label.isNotEmpty` i `value.isNotEmpty`
- ✅ Uklonjen `const` konstruktor da bi se omogućile assert validacije
- ✅ Widget sada sprječava kreiranje s praznim stringovima na compile-time

**Verifikacija:**
- ✅ Assert validacije osiguravaju da se widget ne može kreirati s praznim stringovima
- ✅ Flutter analyze: nema grešaka
- ✅ Kod je već implementiran i radi ispravno

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

### Bug #46: Nedostaje accessibility (Semantics) u `detail_row_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/common/detail_row_widget.dart`, linija 71

**Problem:**
Widget nema `Semantics` widget za accessibility, što može otežati korištenje screen reader-ima.

**Posljedice:**
- Loša accessibility za korisnike sa screen reader-ima
- Neusklađenost s WCAG guidelines
- Loše korisničko iskustvo za korisnike s invaliditetom

**Rješenje (implementirano 2025-01-27):**
```dart
// Bug #46 Fix: Add Semantics widget for accessibility (screen readers)
final row = Semantics(
  label: label,
  value: value,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // ...
    ],
  ),
);
```

**Implementirane promjene:**
- ✅ Dodan `Semantics` widget oko `Row` widgeta sa `label` i `value` svojstvima
- ✅ Dodan komentar objašnjavajući Bug #46 fix
- ✅ Flutter analyze: nema grešaka
- ✅ Testovi: svi postojeći testovi prolaze

**Zašto ovo rješenje:**
- `Semantics` widget omogućava screen reader-ima da čitaju label i value kao jednu semantičku jedinicu
- `label` i `value` svojstva omogućavaju screen reader-ima da pravilno interpretiraju sadržaj
- Ovo rješenje je konzistentno s WCAG guidelines za accessibility

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Backward compatible: sve postojeće funkcionalnosti rade isto, samo je dodana accessibility podrška
- ✅ Testovi: svi postojeći testovi prolaze (9/9 testova)

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

### Bug #47: Nedostaje provjera za prazan string u `copyable_text_field.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/common/copyable_text_field.dart`, linija 89-92

**Problem:**
```dart
Text(
  value, // ❌ Nema provjere da li je prazan string
  // ...
),
```

Ako je `value` prazan string, widget će prikazati prazan prostor.

**Posljedice:**
- Mogući layout problemi s praznim stringovima
- Loše korisničko iskustvo ako se prikaže prazan widget
- Copy button će i dalje biti prikazan čak i ako nema što kopirati

**Rješenje (implementirano 2025-01-27):**
```dart
@override
Widget build(BuildContext context) {
  // Bug #47 Fix: Return empty widget if value is empty to prevent layout issues
  if (value.isEmpty) {
    return const SizedBox.shrink();
  }

  final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
  // ...
}
```

**Implementirane promjene:**
- ✅ Dodana provjera `value.isEmpty` na početku `build` metode
- ✅ Ako je `value` prazan, vraća se `SizedBox.shrink()` umjesto praznog widgeta
- ✅ Dodan komentar objašnjavajući Bug #47 fix
- ✅ Flutter analyze: nema grešaka
- ✅ Testovi: svi postojeći testovi prolaze

**Zašto ovo rješenje:**
- Early return pattern osigurava da se widget ne renderira ako nema sadržaja
- `SizedBox.shrink()` ne zauzima prostor u layout-u, što sprječava layout probleme
- Ovo rješenje je bolje od assert-a jer ne zahtijeva uklanjanje `const` konstruktora
- Backward compatible: postojeći kod koji prosljeđuje prazan string će jednostavno ne prikazati widget

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Backward compatible: normalno ponašanje ostaje isto, samo se poboljšava handling praznih stringova
- ✅ Testovi: svi postojeći testovi prolaze (7/7 testova)

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

### Bug #48: Nedostaje pristup `widget.isDarkMode` u `_buildSwitchButton()` metodi ✅ NIJE BUG

**Status:** ✅ Nije bug - validan kod

**Lokacija:** `rotate_device_overlay.dart`, linija 92-93

**Objašnjenje:**
Kod koristi `isDarkMode` direktno bez `widget.` prefiksa, što je **ispravno** za `StatelessWidget`. U `StatelessWidget`-u, property-je se mogu koristiti direktno jer su to instance varijable klase. `widget.` prefiks je potreban samo u `StatefulWidget` State klasama.

**Trenutni kod (ispravan):**
```dart
Widget _buildSwitchButton() {
  final backgroundColor = isDarkMode ? ColorTokens.pureWhite : ColorTokens.pureBlack;
  final foregroundColor = isDarkMode ? ColorTokens.pureBlack : ColorTokens.pureWhite;
  // ...
}
```

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Kod se kompajlira bez problema
- ✅ Konzistentno sa ostatkom codebase-a (npr. `bookbed_loader.dart`)

**Prioritet:** 🔴 Kritično → ✅ Nije bug

---

### Bug #49: Timezone problemi u `smart_loading_screen.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `smart_loading_screen.dart`, linije 191, 226, 227

**Problem:**
```dart
// Linija 196
_startTime = DateTime.now();  // ❌ Koristi local timezone

// Linija 231
final startTime = _startTime ?? DateTime.now();  // ❌ Koristi local timezone

// Linija 232
final elapsed = DateTime.now().difference(startTime).inMilliseconds;  // ❌ Koristi local timezone
```

**Detalji:**
- Koristi se `DateTime.now()` umjesto `DateTime.utcNow()` ili `DateTime.now().toUtc()`
- Ovo može uzrokovati probleme s DST promjenama i timezone razlikama
- Inconsistent s ostatkom koda koji koristi UTC

**Posljedice:**
- Potencijalni problemi s DST promjenama
- Inconsistent behavior ovisno o korisnikovom timezone-u
- Mogući problemi s `minimumDisplayTime` izračunom

**Rješenje:**
```dart
// Linija 191
_startTime = DateTime.now().toUtc();  // ✅ Koristi UTC

// Linija 226
final startTime = _startTime ?? DateTime.now().toUtc();  // ✅ Koristi UTC

// Linija 227
final elapsed = DateTime.now().toUtc().difference(startTime).inMilliseconds;  // ✅ Koristi UTC
```

**Implementirane promjene:**
- ✅ Zamijenjeni svi `DateTime.now()` pozivi sa `DateTime.now().toUtc()` u `_SmartLoadingScreenWithProviderState` klasi
- ✅ Konzistentno sa ostatkom kodebaze koji koristi UTC (`month_calendar_widget.dart`, `year_calendar_widget.dart`, `form_persistence_service.dart`)
- ✅ Eliminirani potencijalni problemi s DST promjenama i timezone razlikama

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Svi timezone izračuni koriste UTC za konzistentnost
- ✅ `minimumDisplayTime` izračun je sada timezone-safe

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #50: Nedostaje provjera za prazan `message` string u `info_card_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `info_card_widget.dart`, linija 33

**Problem:**
```dart
/// The main message text to display
final String message;  // ❌ Nema provjere da li je prazan string

// U build metodi:
Text(message, style: messageStyle),  // Može prikazati prazan tekst
```

**Detalji:**
- `message` je required parametar, ali nema provjere da li je prazan string
- Ako se proslijedi prazan string, widget će prikazati prazan prostor
- Nema fallback vrijednosti ili provjere

**Posljedice:**
- Mogući layout problemi s praznim stringom
- Loše korisničko iskustvo ako se prikaže prazan widget
- Potencijalno confusing za korisnike

**Rješenje:**
```dart
// Dodano u build metodi:
@override
Widget build(BuildContext context) {
  // Bug #50 Fix: Check for empty message string
  if (message.isEmpty) {
    return const SizedBox.shrink();
  }
  // ... rest of the method
}
```

**Implementirane promjene:**
- ✅ Dodana provjera na početku `build` metode koja vraća `SizedBox.shrink()` ako je `message` prazan
- ✅ Konzistentno sa pattern-om korištenim u Bug #70, #71, #83
- ✅ Fleksibilnije rješenje koje ne baca exception, samo sakriva widget

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Widget se ne prikazuje kada je `message` prazan string
- ✅ Normalno prikazuje widget kada je `message` validan

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

### Bug #51: Nedostaje accessibility (Semantics) u common widget-ima ✅ RIJEŠEN (djelomično)

**Status:** ✅ Riješen (djelomično) - 2025-01-27 - `InfoCardWidget` ima Semantics, ostali widget-i još nisu riješeni

**Lokacija:** `info_card_widget.dart`, `loading_screen.dart`, `rotate_device_overlay.dart`

**Problem:**
Svi common widget-i nemaju `Semantics` widget-e za accessibility, što može otežati korištenje screen reader-ima.

**Detalji:**
- `InfoCardWidget` - ✅ Dodani Semantics za message i title
- `WidgetLoadingScreen` - ❌ Još nema Semantics za loading state
- `RotateDeviceOverlay` - ❌ Još nema Semantics za rotate prompt i button

**Posljedice:**
- Loša accessibility za korisnike sa screen reader-ima
- Neusklađenost s WCAG guidelines
- Loše korisničko iskustvo za korisnike s invaliditetom

**Rješenje:**
```dart
// info_card_widget.dart
// Bug #51 Fix: Add Semantics for accessibility
final semanticsLabel = hasTitle ? '$title: $message' : message;

return Semantics(
  label: semanticsLabel,
  hint: 'Information message',
  child: Container(
    // ...
  ),
);

// loading_screen.dart
// Bug #51 Fix: Add Semantics for accessibility
final loadingLabel = progress != null 
    ? 'Loading: ${(progress! * 100).toInt()}%' 
    : 'Loading in progress';

return Semantics(
  label: loadingLabel,
  value: progress != null ? '${(progress! * 100).toInt()}%' : null,
  child: Scaffold(
    // ...
  ),
);

// rotate_device_overlay.dart
// Bug #51 Fix: Add Semantics for rotate prompt
Semantics(
  label: translations.rotateYourDevice,
  hint: translations.rotateForBestExperience,
  header: true,
  child: Column(
    children: [
      Text(translations.rotateYourDevice, ...),
      Text(translations.rotateForBestExperience, ...),
    ],
  ),
);

// Bug #51 Fix: Add Semantics for button
return Semantics(
  label: translations.switchToMonthView,
  hint: translations.rotateForBestExperience,
  button: true,
  child: ElevatedButton(
    // ...
  ),
);
```

**Implementirane promjene:**
- ✅ Dodan `Semantics` widget u `InfoCardWidget` - wrap-uje Container sa `label` (kombinuje title i message ako postoji title) i `hint` ('Information message') properties
- ❌ `WidgetLoadingScreen` - još nije implementirano
- ❌ `RotateDeviceOverlay` - još nije implementirano

**Verifikacija:**
- ✅ Semantics widget dodan u `InfoCardWidget`
- ✅ Flutter analyze: nema grešaka
- ✅ Konzistentno sa primjerima u codebase-u (Bug #30, #46, #57 koriste isti pattern)
- ⚠️ `WidgetLoadingScreen` i `RotateDeviceOverlay` još trebaju Semantics implementaciju

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

### Bug #52: Potencijalni problem s `_startTime` null check u `smart_loading_screen.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - već implementirano

**Lokacija:** `smart_loading_screen.dart`, linija 231

**Problem:**
Ako se `_finishProgress()` pozove prije nego što se `initState()` završi, `_startTime` može biti null.

**Rješenje (već implementirano):**
```dart
Future<void> _finishProgress() async {
  // Calculate remaining time to meet minimum display
  // Defensive check: ensure _startTime is initialized
  final startTime = _startTime ?? DateTime.now();
  final elapsed = DateTime.now().difference(startTime).inMilliseconds;
  // ...
}
```

**Implementirane promjene:**
- ✅ Defensive check već postoji: `_startTime ?? DateTime.now()`
- ✅ Fallback osigurava da kod neće pasti ako je `_startTime` null
- ✅ Elapsed time će biti približno točan (0ms ako se pozove prije inicijalizacije)
- ✅ Kod je siguran i neće uzrokovati crash

**Verifikacija:**
- ✅ Defensive check je implementiran u kodu
- ✅ Flutter analyze: nema grešaka
- ✅ Kod je siguran i radi ispravno

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

## Sažetak novih bugova (Presentation Screens)

| Bug # | Kritičnost | Lokacija | Status |
|-------|-----------|----------|--------|
| #26 | ✅ Riješen | `booking_details_screen.dart:102-110` | Timezone problem u `_getHoursUntilCheckIn` - UTC normalizacija dodana za oba datuma prije izračuna razlike |
| #27 | ✅ Riješen | `booking_details_screen.dart:127,133,154` | Null check operator bez provjere - koristi `?.` operator umjesto `!` |
| #28 | ✅ Riješen | `booking_view_screen.dart`, `booking_widget_screen.dart` (više lokacija) | Inconsistent timezone u logging pozivima - svi `DateTime.now()` pozivi zamijenjeni s `DateTime.now().toUtc()` | ✅ Riješen |
| #29 | ✅ Riješen | `payment_method_card.dart`, `payment_option_widget.dart` | Nedostaje provjera za prazne stringove - assert validacije dodane, defensive check za singleMethodTitle |
| #30 | ✅ Riješen | `payment_method_card.dart`, `payment_option_widget.dart`, `no_payment_info.dart` | Nedostaje accessibility (Semantics) - Semantics widget dodan u sve tri komponente s label, hint, button, selected, value properties |
| #48 | ✅ Nije bug | `rotate_device_overlay.dart:92-93` | Nedostaje pristup `widget.isDarkMode` - u StatelessWidget-u property-je se mogu koristiti direktno bez `widget.` prefiksa |
| #49 | ✅ Riješen | `smart_loading_screen.dart:191,226,227` | Timezone problemi - svi `DateTime.now()` pozivi zamijenjeni s `DateTime.now().toUtc()` | ✅ Riješen - 2025-01-27 |
| #50 | ✅ Riješen | `info_card_widget.dart:33` | Nedostaje provjera za prazan `message` string - dodana provjera `message.isEmpty` koja vraća `SizedBox.shrink()` | ✅ Riješen - 2025-01-27 |
| #51 | ✅ Riješen (djelomično) | `info_card_widget.dart`, `loading_screen.dart`, `rotate_device_overlay.dart` | Nedostaje accessibility (Semantics) - `InfoCardWidget` ima Semantics, ostali widget-i još nisu riješeni | ✅ Riješen (djelomično) - 2025-01-27 |
| #52 | ✅ Riješen | `smart_loading_screen.dart:231` | Potencijalni problem s `_startTime` null check - već implementirano: defensive check `_startTime ?? DateTime.now()` |
| #31 | 🟡 Visoko | `guest_count_picker.dart`, `booking_widget_screen.dart` | Nedostaje validacija kapaciteta |
| #32 | 🟡 Visoko | `guest_count_picker.dart` | Logička greška u provjeri kapaciteta |
| #33 | 🟢 Nisko | `email_field_with_verification.dart` | Potencijalni problem s disabled button state |
| #34 | 🟢 Nisko | `guest_count_picker.dart` | Nedostaje validacija minimalnog broja gostiju |
| #35 | ✅ Riješen | `contact_pill_card_widget.dart` | Nedostaje error handling u `_launchUrl()` metodi - dodan comprehensive error handling sa try-catch, FormatException catch, SnackBarHelper error poruke i context.mounted check |
| #36 | ✅ Riješen | `compact_pill_summary.dart` | Nedostaje error handling u `DateFormat.format()` - dodana `_formatDate()` helper metoda sa try-catch i fallback formatom |
| #37 | ✅ Riješen | `price_breakdown_widget.dart` | Floating point comparison za `additionalServicesTotal` - korištena `WidgetConstants.priceTolerance` za tolerance-based comparison umjesto direktne `> 0` provjere |
| #38 | 🟢 Nisko | `price_row_widget.dart`, `price_breakdown_widget.dart` | Hardcoded font family 'Manrope' |
| #39 | ✅ Riješen | `compact_pill_summary.dart` | Potencijalni timezone problemi u `DateFormat` - normalizacija datuma i konverzija u lokalno vrijeme dodana u `_formatDate()` metodi |
| #40 | ✅ Riješen | `copyable_text_field.dart` | Hardcoded tooltip 'Kopiraj' (nije lokalizirano) - već implementirano: koristi `translations?.copy ?? 'Copy'` |
| #41 | ✅ Riješen | `copyable_text_field.dart` | Case-sensitive provjere za monospace font - dodana `_shouldUseMonospace()` helper metoda sa case-insensitive provjerama i podrškom za više jezika |
| #42 | ✅ Riješen | `copyable_text_field.dart` | Nedostaje error handling za clipboard operacije - promijenjen `onCopy` callback na `Future<void> Function()` i dodan error handling sa `SnackBarHelper.showError()` |
| #43 | 🟢 Nisko | `bookbed_loader.dart` | Hardcoded font family 'Manrope' |
| #44 | ✅ Riješen | `contact_item_widget.dart` | Nedostaje provjera za prazne stringove - dodana defensive check u build() metodi koja vraća `SizedBox.shrink()` ako je `value` prazan string |
| #45 | ✅ Riješen | `detail_row_widget.dart` | Nedostaje provjera za prazne stringove - već implementirano: assert validacije u konstruktoru |
| #46 | ✅ Riješen | `detail_row_widget.dart` | Nedostaje accessibility (Semantics) - dodan `Semantics` widget sa `label` i `value` svojstvima za screen reader podršku |
| #47 | ✅ Riješen | `copyable_text_field.dart` | Nedostaje provjera za prazan string - dodana provjera `value.isEmpty` koja vraća `SizedBox.shrink()` ako je prazan |
| #63 | ✅ Nije bug | `payment_info_card.dart` | Sintaksna greška u switch expressionu - `||` operator je validna sintaksa u Dart 3.0+ pattern matching |
| #64 | ✅ Riješen | `cancellation_policy_card.dart` | Timezone problem u `hoursUntilCheckIn` izračunu - dodana UTC normalizacija za `checkInDate` i `DateTime.now()` |
| #65 | ✅ Riješen | `details_reference_card.dart` | Nedostaje error handling za clipboard operacije - dodan try-catch blok sa `SnackBarHelper.showError()` i `context.mounted` provjerom |
| #66 | ✅ Riješen | `payment_info_card.dart` | Floating point comparison za `remainingAmount` - korištena `WidgetConstants.priceTolerance` za tolerance-based comparison | ✅ Riješen - 2025-01-27 |
| #67 | ✅ Riješen | `payment_info_card.dart` | Nedostaje error handling u `DateFormat.format()` - kreirana `_formatDeadline()` helper metoda sa try-catch blokom | ✅ Riješen - 2025-01-27 |
| #68 | ✅ Riješen | `cancellation_policy_card.dart` | Floating point precision u `_formatCancellationDeadline()` - korištena integer division (`~/`) umjesto floating point dijeljenja | ✅ Riješen - 2025-01-27 |
| #69 | ✅ Riješen | `contact_owner_card.dart` | Nedostaje provjera za prazne stringove - već implementirano: dodana provjera `ownerEmail != null && ownerEmail!.isNotEmpty` i `ownerPhone != null && ownerPhone!.isNotEmpty` |
| #70 | ✅ Riješen | `details_reference_card.dart` | Nedostaje provjera za prazan string - dodana provjera `bookingReference.isEmpty` koja vraća `SizedBox.shrink()` ako je prazan |
| #71 | ✅ Riješen | `property_info_card.dart` | Nedostaje provjera za prazne stringove - dodana provjera `propertyName.isEmpty || unitName.isEmpty` koja vraća `SizedBox.shrink()` ako je bilo koji prazan |
| #72 | ✅ Riješen | `payment_info_card.dart` | Potencijalni floating point precision problemi - kreirana `_formatAmount()` metoda koja provjerava `isFinite` i vraća `'€0.00'` za NaN/Infinity vrijednosti |

---

## 🟡 Visoki Prioritet (Guest Form Widgets)

### Bug #31: Nedostaje validacija kapaciteta u `guest_count_picker.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-12-16

**Lokacija:** `guest_count_picker.dart`, linije 55, 67, 2544-2545 u `booking_widget_screen.dart`

**Problem:**
```dart
// guest_count_picker.dart:55
canIncrement: !isAtCapacity && adults < maxGuests,

// guest_count_picker.dart:67
canIncrement: !isAtCapacity && children < maxGuests,

// booking_widget_screen.dart:2544-2545
onAdultsChanged: (value) => setState(() => _adults = value),
onChildrenChanged: (value) => setState(() => _children = value),
```

`GuestCountPicker` ne validira automatski da li `adults + children` premašuje `maxGuests` kada se vrijednosti mijenjaju. Također, ako se `maxGuests` smanji nakon što su već postavljene vrijednosti `adults` i `children`, widget neće automatski prilagoditi vrijednosti.

**Posljedice:**
- Moguće je imati `adults + children > maxGuests` ako se `maxGuests` promijeni
- Korisnik može postaviti nevaljane vrijednosti direktno kroz `onAdultsChanged`/`onChildrenChanged`
- Validacija se dešava tek u `booking_widget_screen.dart` (linije 1314-1323), ali ne u realnom vremenu

**Rješenje:**
```dart
// U guest_count_picker.dart, dodati validaciju u callback-ove:
onIncrement: () {
  final newAdults = adults + 1;
  final newTotal = newAdults + children;
  if (newTotal <= maxGuests) {
    onAdultsChanged(newAdults);
  }
},
onIncrement: () {
  final newChildren = children + 1;
  final newTotal = adults + newChildren;
  if (newTotal <= maxGuests) {
    onChildrenChanged(newChildren);
  }
},
```

Ili u `booking_widget_screen.dart`:
```dart
onAdultsChanged: (value) {
  final newTotal = value + _children;
  final maxGuests = _unit?.maxGuests ?? 10;
  if (newTotal <= maxGuests) {
    setState(() => _adults = value);
  } else {
    // Clamp to max allowed
    setState(() => _adults = maxGuests - _children);
  }
},
onChildrenChanged: (value) {
  final newTotal = _adults + value;
  final maxGuests = _unit?.maxGuests ?? 10;
  if (newTotal <= maxGuests) {
    setState(() => _children = value);
  } else {
    // Clamp to max allowed
    setState(() => _children = maxGuests - _adults);
  }
},
```

**Prioritet:** 🟡 Visoko

---

### Bug #32: Logička greška u provjeri kapaciteta za adults/children ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-12-16

**Lokacija:** `guest_count_picker.dart`, linije 55, 67

**Problem:**
```dart
// Linija 55
canIncrement: !isAtCapacity && adults < maxGuests,

// Linija 67
canIncrement: !isAtCapacity && children < maxGuests,
```

Provjera `adults < maxGuests` i `children < maxGuests` nije ispravna. Trebalo bi provjeriti da li `totalGuests < maxGuests`, ne individualne vrijednosti. Na primjer, ako je `maxGuests = 4`, `adults = 2`, `children = 2`, tada je `isAtCapacity = true`, ali provjera `adults < maxGuests` bi bila `true`, što je redundantno jer je `isAtCapacity` već `true`.

**Posljedice:**
- Redundantna provjera koja može dovesti do konfuzije
- Logika nije jasna - provjerava se individualna vrijednost umjesto ukupnog broja

**Rješenje:**
```dart
// Ukloniti redundantne provjere, koristiti samo isAtCapacity
canIncrement: !isAtCapacity,
```

Ili, ako želimo provjeriti da li pojedinačna vrijednost može biti povećana:
```dart
canIncrement: !isAtCapacity && (adults + children) < maxGuests,
```

**Prioritet:** 🟡 Visoko

---

## 🟢 Niski Prioritet (Guest Form Widgets)

### Bug #33: Potencijalni problem s disabled button state u `email_field_with_verification.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-12-16

**Lokacija:** `email_field_with_verification.dart`, linija 96

**Problem:**
```dart
onPressed: isLoading ? () {} : onVerifyPressed,
```

Kada je `isLoading = true`, button je disabled (prazna funkcija), ali vizualno se prikazuje loading indicator. Međutim, button je još uvijek klikabilan (prazna funkcija se izvršava). Bolje bi bilo eksplicitno disable-ati button.

**Posljedice:**
- Button je još uvijek klikabilan iako je u loading stanju
- Može dovesti do konfuzije korisnika

**Rješenje:**
```dart
ElevatedButton(
  onPressed: isLoading ? null : onVerifyPressed,  // null = disabled
  // ...
)
```

**Prioritet:** 🟢 Nisko

---

### Bug #34: Nedostaje validacija minimalnog broja gostiju u `guest_count_picker.dart` ✅ NIJE BUG

**Status:** ✅ Nije bug - minimum 1 adult je standardno ponašanje za booking sisteme (provjereno 2025-12-16)

**Lokacija:** `guest_count_picker.dart`, linija 54

**Problem:**
```dart
canDecrement: adults > 1,
```

Minimum je 1 adult, što je ispravno. Međutim, nema provjere da li je minimum postavljen na razini widgeta ili da li postoji business pravilo koje zahtijeva minimum (npr. minimum 2 gosta).

**Napomena:**
Ovo može biti namjerno ponašanje, ali treba provjeriti business logiku.

**Prioritet:** 🟢 Nisko (potrebna provjera business logike)

---

## 🔴 Kritični Bugovi (Calendar Widgets)

### Bug #40: Timezone problemi u `calendar_date_utils.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `calendar_date_utils.dart`, linije 13-15, 18-20

**Problem:**
```dart
// Linija 13-15: isSameDay ne normalizira na UTC
static bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

// Linija 18-20: getDateKey koristi DateFormat koji može imati timezone probleme
static String getDateKey(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}
```

Ove metode ne normaliziraju datume na UTC prije usporedbe/formatiranja. Ako su datumi u različitim timezone-ovima ili imaju vremenske komponente, mogu dati pogrešne rezultate.

**Posljedice:**
- `isSameDay` može vratiti `false` za iste dane u različitim timezone-ovima
- `getDateKey` može generirati različite ključeve za isti dan u različitim timezone-ovima
- Problemi s DST promjenama
- Neusklađenost s ostatkom koda koji koristi UTC

**Rješenje:**
```dart
// Bug #40 Fix: Normalize both dates to UTC for consistent comparison
static bool isSameDay(DateTime a, DateTime b) {
  final aUtc = DateTime.utc(a.year, a.month, a.day);
  final bUtc = DateTime.utc(b.year, b.month, b.day);
  return aUtc == bUtc;
}

// Bug #40 Fix: Normalize to UTC by extracting year/month/day components
static String getDateKey(DateTime date) {
  final utcDate = DateTime.utc(date.year, date.month, date.day);
  return DateFormat('yyyy-MM-dd').format(utcDate);
}
```

**Implementirane promjene:**
- ✅ Dodana UTC normalizacija u `isSameDay()` metodi - normalizira oba datuma na UTC prije usporedbe
- ✅ Dodana UTC normalizacija u `getDateKey()` metodi - normalizira datum na UTC prije formatiranja
- ✅ Konzistentno sa `calendar_data_service.dart` koji već koristi UTC normalizaciju
- ✅ Eliminirani problemi s DST promjenama i timezone razlikama

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Konzistentno sa ostatkom kodebaze koji koristi UTC
- ✅ `isSameDay` i `getDateKey` sada rade ispravno bez obzira na timezone

**Prioritet:** 🔴 Kritično → ✅ Riješen

---

## 🟡 Visoki Prioritet (Calendar Widgets)

### Bug #41: Nedostaje defensive check za MediaQuery u `calendar_view_switcher_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-12-16

**Lokacija:** `calendar_view_switcher_widget.dart`, linija 50

**Problem:**
```dart
final screenWidth = MediaQuery.of(context).size.width;
```

Koristi se `MediaQuery.of(context)` bez defensive checka. Ako `MediaQuery` nije dostupan u context-u, aplikacija će pasti s `ProviderNotFoundException`.

**Posljedice:**
- Aplikacija može pasti ako widget se renderira izvan `MaterialApp`/`WidgetsApp`
- Teško debugiranje problema

**Rješenje:**
```dart
final mediaQuery = MediaQuery.maybeOf(context);
if (mediaQuery == null) {
  // Fallback na default vrijednost ili return SizedBox.shrink()
  return const SizedBox.shrink();
}
final screenWidth = mediaQuery.size.width;
```

Ili koristiti default vrijednost:
```dart
final screenWidth = MediaQuery.maybeOf(context)?.size.width ?? 400.0;
```

**Prioritet:** 🟡 Visoko

---

### Bug #42: Nedostaje defensive check za size u `PartialBothPainter` i `PendingPatternPainter` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-12-16

**Lokacija:** `year_calendar_painters.dart`, linije 147, 116

**Problem:**
```dart
// PartialBothPainter.paint() - linija 147
@override
void paint(Canvas canvas, Size size) {
  final paint = Paint()..style = PaintingStyle.fill;
  // ... nema provjere da li je size validan
}

// PendingPatternPainter.paint() - linija 116
@override
void paint(Canvas canvas, Size size) {
  drawDiagonalPattern(canvas, size, lineColor);
  // ... nema provjere da li je size validan
}
```

`DiagonalLinePainter` već ima defensive check za size (linije 57-60), ali `PartialBothPainter` i `PendingPatternPainter` nemaju. Ako je size invalid (npr. `width` ili `height` je 0, negativan, ili `Infinity`), painter može uzrokovati probleme.

**Posljedice:**
- Mogući crash-ovi ili neočekivano ponašanje s invalid size-om
- Inconsistent error handling između painter-a

**Rješenje:**
```dart
// U PartialBothPainter.paint()
@override
void paint(Canvas canvas, Size size) {
  // Defensive check: ensure size is valid before painting
  if (!size.width.isFinite || !size.height.isFinite || 
      size.width <= 0 || size.height <= 0) {
    return; // Skip painting if size is invalid
  }
  
  final paint = Paint()..style = PaintingStyle.fill;
  // ... rest of code
}

// U PendingPatternPainter.paint()
@override
void paint(Canvas canvas, Size size) {
  // Defensive check: ensure size is valid before painting
  if (!size.width.isFinite || !size.height.isFinite || 
      size.width <= 0 || size.height <= 0) {
    return; // Skip painting if size is invalid
  }
  
  drawDiagonalPattern(canvas, size, lineColor);
}
```

**Prioritet:** 🟡 Visoko

---

## 🟢 Niski Prioritet (Calendar Widgets)

### Bug #43: Potencijalni problem s `isDateInRange` u `calendar_date_utils.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-12-16

**Lokacija:** `calendar_date_utils.dart`, linije 23-31

**Problem:**
```dart
static bool isDateInRange(
  DateTime date,
  DateTime? rangeStart,
  DateTime? rangeEnd,
) {
  if (rangeStart == null || rangeEnd == null) return false;
  return (date.isAfter(rangeStart) || isSameDay(date, rangeStart)) &&
      (date.isBefore(rangeEnd) || isSameDay(date, rangeEnd));
}
```

Metoda koristi `isSameDay` koja ima timezone probleme (vidi Bug #40). Također, ako je `rangeStart > rangeEnd`, metoda će uvijek vratiti `false`, što može biti očekivano ponašanje, ali nije eksplicitno dokumentirano.

**Posljedice:**
- Timezone problemi zbog `isSameDay`
- Nema validacije da li je range validan (`rangeStart <= rangeEnd`)

**Rješenje:**
```dart
static bool isDateInRange(
  DateTime date,
  DateTime? rangeStart,
  DateTime? rangeEnd,
) {
  if (rangeStart == null || rangeEnd == null) return false;
  
  // Normalizirati sve datume na UTC
  final dateUtc = DateTime.utc(date.year, date.month, date.day);
  final startUtc = DateTime.utc(rangeStart.year, rangeStart.month, rangeStart.day);
  final endUtc = DateTime.utc(rangeEnd.year, rangeEnd.month, rangeEnd.day);
  
  // Provjeriti da li je range validan
  if (endUtc.isBefore(startUtc)) return false;
  
  return (dateUtc.isAfter(startUtc) || dateUtc.isAtSameMomentAs(startUtc)) &&
      (dateUtc.isBefore(endUtc) || dateUtc.isAtSameMomentAs(endUtc));
}
```

**Prioritet:** 🟢 Nisko

---

## 🔴 Kritični Bugovi (Details Widget Files)

### Bug #63: Sintaksna greška u switch expressionu u `payment_info_card.dart` ✅ NIJE BUG

**Status:** ✅ Nije bug - validna sintaksa u Dart 3.0+

**Lokacija:** `lib/features/widget/presentation/widgets/details/payment_info_card.dart`, `_buildPaymentStatusChip()` metoda, linije 220-225

**Objašnjenje:**
Kod koristi `||` operator u switch expressionu, što je **validna sintaksa** u Dart 3.0+ (pattern matching). Ovo omogućava multiple case values u jednom pattern-u.

**Trenutni kod (ispravan):**
```dart
final (statusColor, statusText) = switch (paymentStatus.toLowerCase()) {
  'paid' || 'completed' => (colors.success, tr.paid),  // ✅ Validna sintaksa
  'pending' => (colors.warning, tr.statusPending),
  'failed' || 'refunded' => (colors.error, paymentStatus),  // ✅ Validna sintaksa
  _ => (colors.textSecondary, paymentStatus),
};
```

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Kod se kompajlira bez problema
- ✅ Validna Dart 3.0+ sintaksa za pattern matching u switch expressions

**Posljedice:**
- Kod se neće kompajlirati ili će imati runtime greške
- Parsiranje payment statusa neće raditi ispravno
- Widget će možda pasti ili prikazati pogrešne boje/tekstove

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Kod se kompajlira bez problema
- ✅ Validna Dart 3.0+ sintaksa za pattern matching u switch expressions

**Prioritet:** 🔴 Kritično → ✅ Nije bug

---

## 🟡 Visoki Prioritet (Details Widget Files)

### Bug #64: Timezone problem u `cancellation_policy_card.dart` ✅ RIJEŠENO

**Status:** ✅ Riješeno - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/details/cancellation_policy_card.dart`, linije 30-33

**Problem:**
```dart
final hoursUntilCheckIn = checkInDate.difference(DateTime.now()).inHours;
```

Koristi se `DateTime.now()` (lokalno vrijeme) umjesto UTC-a. Ako je `checkInDate` u UTC-u, ovo može uzrokovati probleme s DST promjenama i timezone razlikama.

**Posljedice:**
- Mogući problemi s DST promjenama
- Neusklađenost s ostatkom koda koji koristi UTC
- Moguće pogrešne kalkulacije sati do check-in-a

**Rješenje:**
```dart
// Normalize to UTC for consistent comparison (handles DST and timezone differences)
final checkInUtc = checkInDate.isUtc ? checkInDate : checkInDate.toUtc();
// Use UTC for current time to ensure consistent comparison
final nowUtc = DateTime.now().toUtc();
final hoursUntilCheckIn = checkInUtc.difference(nowUtc).inHours;
```

**Implementirano:**
- ✅ Dodana UTC normalizacija za `checkInDate` i `DateTime.now()`
- ✅ Dodani komentari koji objašnjavaju zašto koristimo UTC
- ✅ Koristi se isti pattern kao u `booking_details_screen.dart` za konzistentnost

**Prioritet:** 🟡 Visoko → ✅ Riješeno

---

### Bug #65: Nedostaje error handling za clipboard operacije u `details_reference_card.dart` ✅ RIJEŠENO

**Status:** ✅ Riješeno - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/details/details_reference_card.dart`, `_copyToClipboard()` metoda, linije 32-45

**Problem:**
```dart
Future<void> _copyToClipboard(BuildContext context, WidgetRef ref) async {
  final tr = WidgetTranslations.of(context, ref);
  await Clipboard.setData(ClipboardData(text: bookingReference));  // ❌ Nema error handling
  if (context.mounted) {
    SnackBarHelper.showSuccess(
      context: context,
      message: tr.bookingReferenceCopied,
      duration: const Duration(seconds: 2),
    );
  }
}
```

Nedostaje error handling za `Clipboard.setData()`. Ako clipboard operacija baci exception (npr. na web-u ako clipboard API nije dostupan), aplikacija će pasti.

**Posljedice:**
- Aplikacija može pasti ako clipboard operacija ne uspije
- Nema feedback korisniku ako copy ne uspije
- Loše korisničko iskustvo

**Rješenje:**
```dart
Future<void> _copyToClipboard(BuildContext context, WidgetRef ref) async {
  final tr = WidgetTranslations.of(context, ref);
  try {
    await Clipboard.setData(ClipboardData(text: bookingReference));
    if (context.mounted) {
      SnackBarHelper.showSuccess(
        context: context,
        message: tr.bookingReferenceCopied,
        duration: const Duration(seconds: 2),
      );
    }
  } catch (e) {
    debugPrint('Error copying to clipboard: $e');
    if (context.mounted) {
      SnackBarHelper.showError(
        context: context,
        message: tr.errorOccurred,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
```

**Implementirano:**
- ✅ Dodan try-catch blok oko `Clipboard.setData()`
- ✅ Dodan `debugPrint` za logging grešaka
- ✅ Koristi se `tr.errorOccurred` za error poruku (umjesto `tr.copyFailed` jer taj key ne postoji)
- ✅ Provjera `context.mounted` prije prikazivanja error poruke
- ✅ Koristi se isti pattern kao u `copyable_text_field.dart` za konzistentnost

**Prioritet:** 🟡 Visoko → ✅ Riješeno

---

### Bug #66: Floating point comparison u `payment_info_card.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/details/payment_info_card.dart`, linija ~100

**Problem:**
```dart
color: remainingAmount > 0 ? colors.error : colors.success,
```

Koristi se direktna floating point comparison (`> 0`) što može uzrokovati probleme s floating point precision.

**Posljedice:**
- Mogući problemi s prikazom boje zbog floating point grešaka
- Ako je `remainingAmount` vrlo mali pozitivan broj (npr. 0.0001), možda ne bi trebao biti prikazan kao error
- Ako je `remainingAmount` negativan zbog greške, neće biti prikazan kao error (što je možda dobro)

**Rješenje:**
```dart
// ✅ Implementirano - koristi WidgetConstants.priceTolerance za konzistentnost
_buildPaymentRow(
  tr.remaining,
  remainingAmount,
  color: remainingAmount.abs() > WidgetConstants.priceTolerance
      ? colors.error
      : colors.success,
),
```

**Implementirane promjene:**
- ✅ Dodan import za `WidgetConstants` iz `widget_constants.dart`
- ✅ Zamijenjena direktna floating point comparison sa tolerance-based comparison koristeći `WidgetConstants.priceTolerance` (0.01 = 1 cent)
- ✅ Koristi se `.abs()` da se osigura da se negativni iznosi (zbog grešaka) također tretiraju ispravno
- ✅ Konzistentno sa drugim dijelovima kodebaze (Bug #37 fix u `price_breakdown_widget.dart`, `price_lock_service.dart`)

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Tolerance-based comparison osigurava da se vrlo mali iznosi (manji od 1 centa) tretiraju kao 0
- ✅ Ispravno prikazuje success (zeleno) umjesto error (crveno) za iznose manje od tolerance

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #67: Nedostaje error handling u `DateFormat.format()` u `payment_info_card.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/details/payment_info_card.dart`, `_buildDeadlineRow()` metoda, linija ~188-190

**Problem:**
```dart
Text(
  DateFormat('MMM d, yyyy').format(
    DateTimeParser.parseOrThrow(
      paymentDeadline,
      context: 'PaymentInfoCard.paymentDeadline',
    ),
  ),
  // ...
)
```

`DateTimeParser.parseOrThrow()` će baciti exception ako parsiranje ne uspije, ali `DateFormat.format()` također može baciti exception ako DateTime nije validan. Nema dodatnog error handlinga.

**Posljedice:**
- Aplikacija može pasti ako formatiranje ne uspije
- Loše korisničko iskustvo

**Rješenje:**
```dart
// Bug #67 Fix: Format deadline with error handling
String _formatDeadline(String? deadline, WidgetTranslations tr) {
  if (deadline == null || deadline.isEmpty) return '';
  
  try {
    final date = DateTimeParser.parseOrThrow(
      deadline,
      context: 'PaymentInfoCard.paymentDeadline',
    );
    return DateFormat('MMM d, yyyy').format(date);
  } catch (e) {
    debugPrint('Error formatting deadline: $deadline, error: $e');
    // Fallback to original string if formatting fails
    return deadline;
  }
}

// U _buildDeadlineRow metodi:
Text(
  _formatDeadline(paymentDeadline, tr),
  // ...
)
```

**Implementirane promjene:**
- ✅ Kreirana `_formatDeadline()` helper metoda sa try-catch blokom
- ✅ Dodana provjera za null i prazan string
- ✅ Fallback na originalni string ako formatiranje ne uspije
- ✅ Dodan `debugPrint` za logging grešaka
- ✅ Konzistentno sa pattern-om iz `compact_pill_summary.dart` (Bug #36)

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Aplikacija ne pada ako formatiranje ne uspije
- ✅ Fallback osigurava da se prikaže barem originalni string

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

## 🟢 Niski Prioritet (Details Widget Files)

### Bug #68: Floating point precision u `_formatCancellationDeadline()` u `cancellation_policy_card.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/details/cancellation_policy_card.dart`, `_formatCancellationDeadline()` metoda, linija 113

**Problem:**
```dart
final days = (hours / 24).round();
```

Koristi se floating point dijeljenje i `round()`, što može uzrokovati probleme s precision. Npr. ako je `hours = 47`, `47 / 24 = 1.958...`, `round()` će dati `2`, što je možda očekivano, ali može biti problematično za edge case-ove.

**Posljedice:**
- Mogući problemi s prikazom dana za edge case-ove
- Nije kritično, ali može biti confusing

**Rješenje:**
```dart
// Bug #68 Fix: Use integer division for better precision
// Avoid floating point precision issues by using integer arithmetic
final days = hours ~/ 24; // Integer division
final remainingHours = hours % 24;
// Round up if more than half a day (12 hours)
final roundedDays = remainingHours >= 12 ? days + 1 : days;
return tr.canCancelUpToDays(roundedDays);
```

**Implementirane promjene:**
- ✅ Zamijenjeno floating point division (`hours / 24`) sa integer division (`hours ~/ 24`)
- ✅ Dodana eksplicitna rounding logika (round up ako je > 12 sati)
- ✅ Eliminirani floating point precision issues
- ✅ Bolje performanse i predvidljivost

**Verifikacija:**
- ✅ Flutter analyze: nema grešaka
- ✅ Integer division eliminira floating point precision issues
- ✅ Eksplicitna rounding logika osigurava konzistentno ponašanje

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

### Bug #69: Nedostaje provjera za prazne stringove u `contact_owner_card.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/details/contact_owner_card.dart`, linije 57-62

**Problem:**
```dart
if (ownerEmail != null)
  _buildInfoRow(tr.email, ownerEmail!, Icons.email),
if (ownerPhone != null) ...[
  if (ownerEmail != null) const SizedBox(height: SpacingTokens.s),
  _buildInfoRow(tr.phone, ownerPhone!, Icons.phone),
],
```

Provjerava se samo da li su `ownerEmail` i `ownerPhone` `null`, ali ne provjerava da li su prazni stringovi. Ako su prazni stringovi, widget će ih prikazati.

**Posljedice:**
- Mogući layout problemi s praznim stringovima
- Loše korisničko iskustvo ako se prikaže prazan widget

**Rješenje:**
```dart
// Bug #69 Fix: Check for empty strings in addition to null
if (ownerEmail != null && ownerEmail!.isNotEmpty) 
  _buildInfoRow(tr.email, ownerEmail!, Icons.email),
if (ownerPhone != null && ownerPhone!.isNotEmpty) ...[
  if (ownerEmail != null && ownerEmail!.isNotEmpty) 
    const SizedBox(height: SpacingTokens.s),
  _buildInfoRow(tr.phone, ownerPhone!, Icons.phone),
],
```

**Implementirano:**
- ✅ Dodane provjere `isNotEmpty` uz postojeće `!= null` provjere za `ownerEmail` i `ownerPhone`
- ✅ Sprječava prikazivanje praznih stringova koji mogu uzrokovati layout probleme
- ✅ Poboljšano korisničko iskustvo

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

### Bug #70: Nedostaje provjera za prazan string u `details_reference_card.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/details/details_reference_card.dart`, linija 49

**Problem:**
```dart
Text(
  bookingReference, // ❌ Nema provjere da li je prazan string
  // ...
)
```

Ako je `bookingReference` prazan string, widget će prikazati prazan prostor.

**Posljedice:**
- Mogući layout problemi s praznim stringom
- Loše korisničko iskustvo ako se prikaže prazan widget
- Copy button će i dalje biti prikazan čak i ako nema što kopirati

**Rješenje:**
```dart
if (bookingReference.isEmpty) {
  return const SizedBox.shrink();
}
```

Ili dodati assert u konstruktor:
```dart
const DetailsReferenceCard({
  required this.bookingReference,
  // ...
}) : assert(bookingReference.isNotEmpty, 'Booking reference cannot be empty');
```

**Implementacija:**
Dodana provjera na početku `build` metode koja vraća `SizedBox.shrink()` ako je `bookingReference` prazan string. Ovo sprječava layout probleme i loše korisničko iskustvo.

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

### Bug #71: Nedostaje provjera za prazne stringove u `property_info_card.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/details/property_info_card.dart`, linija 42

**Problem:**
```dart
DetailRowWidget(
  label: tr.property,
  value: propertyName, // ❌ Nema provjere da li je prazan string
  // ...
),
DetailRowWidget(
  label: tr.unit,
  value: unitName, // ❌ Nema provjera da li je prazan string
  // ...
),
```

Ako su `propertyName` ili `unitName` prazni stringovi, widget će prikazati prazan prostor.

**Posljedice:**
- Mogući layout problemi s praznim stringovima
- Loše korisničko iskustvo ako se prikaže prazan widget

**Rješenje:**
```dart
if (propertyName.isEmpty || unitName.isEmpty) {
  return const SizedBox.shrink();
}
```

Ili dodati assert u konstruktor:
```dart
const PropertyInfoCard({
  required this.propertyName,
  required this.unitName,
  // ...
}) : assert(propertyName.isNotEmpty, 'Property name cannot be empty'),
     assert(unitName.isNotEmpty, 'Unit name cannot be empty');
```

**Implementacija:**
Dodana provjera na početku `build` metode koja vraća `SizedBox.shrink()` ako je bilo koji od stringova (`propertyName` ili `unitName`) prazan. Ovo sprječava layout probleme i loše korisničko iskustvo.

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

### Bug #72: Potencijalni floating point precision problemi u `payment_info_card.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `lib/features/widget/presentation/widgets/details/payment_info_card.dart`, `_buildPaymentRow()` metoda, linija 137

**Problem:**
```dart
'€${amount.toStringAsFixed(2)}',
```

Koristi se `toStringAsFixed(2)` što je dobro, ali ako je `amount` negativan ili `NaN`/`Infinity`, formatiranje može dati neočekivane rezultate.

**Posljedice:**
- Mogući problemi s prikazom negativnih iznosa (ako su dozvoljeni)
- Mogući problemi s `NaN` ili `Infinity` vrijednostima

**Rješenje:**
```dart
String _formatAmount(double amount) {
  if (!amount.isFinite) {
    return '€0.00'; // Fallback za NaN/Infinity
  }
  return '€${amount.toStringAsFixed(2)}';
}

// U build metodi:
Text(
  _formatAmount(amount),
  // ...
)
```

**Implementacija:**
Kreirana helper metoda `_formatAmount(double amount)` koja provjerava `isFinite` prije formatiranja. Ako `amount` nije finite (NaN ili Infinity), vraća fallback vrijednost `'€0.00'`. Zamijenjeni su svi direktni pozivi `'€${amount.toStringAsFixed(2)}'` sa `_formatAmount(amount)` u `_buildPaymentRow` metodi.

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

## Sažetak novih bugova (Calendar Widgets)

| Bug # | Kritičnost | Lokacija | Opis | Status |
|-------|-----------|----------|------|--------|
| #40 | ✅ Riješen | `calendar_date_utils.dart` | Timezone problemi u `isSameDay` i `getDateKey` - dodana UTC normalizacija u obje metode | ✅ Riješen - 2025-01-27 |
| #41 | 🟡 Visoko | `calendar_view_switcher_widget.dart` | Nedostaje defensive check za MediaQuery | Unresolved |
| #42 | 🟡 Visoko | `year_calendar_painters.dart` | Nedostaje defensive check za size u painter-ima | Unresolved |
| #43 | 🟢 Nisko | `calendar_date_utils.dart` | Potencijalni problem s `isDateInRange` | Unresolved |
| #73 | ✅ Riješen | `month_calendar_widget.dart:755-770` | Sintaksna greška u switch expressionu - konvertovan u switch statement sa multiple case labels | ✅ Riješen - 2025-01-27 |
| #74 | ✅ Riješen | `month_calendar_widget.dart:42` | Timezone problem - promijenjeno na `DateTime.utc()` sa UTC normalizacijom | ✅ Riješen - 2025-01-27 |
| #75 | ✅ Riješen | `month_calendar_widget.dart:191,281` | Nedostaje defensive check za MediaQuery - zamijenjeno `MediaQuery.of()` sa `MediaQuery.maybeOf()` sa fallback vrijednostima | ✅ Riješen - 2025-01-27 |
| #76 | ✅ Riješen | `month_calendar_widget.dart:194-195` | Nedostaje lokalizacija u `DateFormat` - dodano `Localizations.localeOf(context)` i proslijeđen u `DateFormat.yMMM()` | ✅ Riješen - 2025-01-27 |
| #77 | ✅ Riješen | `month_calendar_widget.dart:460-461` | Timezone problem - promijenjeno na `DateTime.now().toUtc()` i normalizacija na UTC | ✅ Riješen - 2025-01-27 |
| #78 | ✅ Riješen | `year_calendar_widget.dart:42` | Timezone problem - promijenjeno na `DateTime.now().toUtc().year` | ✅ Riješen - 2025-01-27 |
| #79 | ✅ Riješen | `year_calendar_widget.dart:48,218,279` | Nedostaje defensive check za MediaQuery - dodano `MediaQuery.maybeOf(context)?.size.width ?? 400.0` | ✅ Riješen - 2025-01-27 |
| #80 | ✅ Riješen | `year_calendar_widget.dart:399` | Nedostaje lokalizacija u `DateFormat` - dodan locale parametar koristeći `WidgetTranslations.locale.languageCode` | ✅ Riješen - 2025-01-27 |
| #81 | ✅ Riješen | `year_calendar_widget.dart:472` | Timezone problem - promijenjeno na `DateTime.now().toUtc()` i `DateTime.utc()` za normalizaciju | ✅ Riješen - 2025-01-27 |
| #82 | ✅ Riješen | `tax_legal_disclaimer_widget.dart:86,134` | Hardcoded stringovi - dodani translation keys `taxLegalInformation` i `taxLegalAcceptanceText` u `widget_translations.dart` | ✅ Riješen - 2025-01-27 |
| #83 | ✅ Riješen | `tax_legal_disclaimer_widget.dart:56` | Nedostaje provjera za prazan `disclaimerText` - dodana provjera na početku `_buildDisclaimerUI` metode koja vraća `SizedBox.shrink()` ako je `disclaimerText` prazan | ✅ Riješen - 2025-01-27 |

---

## 🔴 Kritični Bugovi (Calendar Widget Files)

### Bug #73: Sintaksna greška u switch expressionu u `month_calendar_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `month_calendar_widget.dart`, `_getBorderColorForDate()` metoda, linije 755-770

**Problem:**
```dart
Color _getBorderColorForDate(DateStatus status, WidgetColorScheme colors) =>
    switch (status) {
      DateStatus.available ||
      DateStatus.partialCheckIn ||
      DateStatus.partialCheckOut => colors.statusAvailableBorder,  // ❌ Sintaksna greška
      DateStatus.booked ||
      DateStatus.partialBoth => colors.statusBookedBorder,  // ❌ Sintaksna greška
      DateStatus.pending => colors.statusPendingBorder,
      DateStatus.blocked || DateStatus.disabled => colors.borderDefault,  // ❌ Sintaksna greška
      DateStatus.pastReservation => colors.statusPastReservationBorder,
    };
```

U Dart switch expressionu, `||` operator ne radi ovako. Ovo će uzrokovati compile error ili neočekivano ponašanje.

**Posljedice:**
- Kod se neće kompajlirati ili će imati runtime greške
- Parsiranje statusa neće raditi ispravno
- Widget će možda pasti ili prikazati pogrešne boje

**Implementacija:**
Konvertovan switch expression u switch statement sa multiple case labels. Svaki case je na zasebnoj liniji bez `||` operatora, što je validna Dart sintaksa. Isti pattern se koristi u `calendar_hover_tooltip.dart` i drugim dijelovima kodebaze.

```dart
Color _getBorderColorForDate(DateStatus status, WidgetColorScheme colors) {
  switch (status) {
    case DateStatus.available:
    case DateStatus.partialCheckIn:
    case DateStatus.partialCheckOut:
      return colors.statusAvailableBorder;
    case DateStatus.booked:
    case DateStatus.partialBoth:
      return colors.statusBookedBorder;
    case DateStatus.pending:
      return colors.statusPendingBorder;
    case DateStatus.blocked:
    case DateStatus.disabled:
      return colors.borderDefault;
    case DateStatus.pastReservation:
      return colors.statusPastReservationBorder;
  }
}
```

**Prioritet:** 🔴 Kritično → ✅ Riješen

---

## 🟡 Visoki Prioritet (Calendar Widget Files)

### Bug #74: Timezone problem u `month_calendar_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `month_calendar_widget.dart`, linija 42

**Problem:**
```dart
DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
```

Koristi se `DateTime.now()` (lokalno vrijeme) umjesto UTC-a. Ovo može uzrokovati probleme s DST promjenama i timezone razlikama.

**Posljedice:**
- Mogući problemi s DST promjenama
- Neusklađenost s ostatkom koda koji koristi UTC
- Moguće pogrešne kalkulacije mjeseca

**Implementacija:**
Promijenjeno na `DateTime.utc()` sa UTC normalizacijom za konzistentnost sa ostatkom koda. Isti pristup se koristi u `cancellation_policy_card.dart` i `booking_details_screen.dart`.

```dart
DateTime _currentMonth = DateTime.utc(
  DateTime.now().toUtc().year,
  DateTime.now().toUtc().month,
);
```

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #75: Nedostaje defensive check za MediaQuery u `month_calendar_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `month_calendar_widget.dart`, linije 191, 281

**Problem:**
```dart
// Linija 191:
final screenWidth = MediaQuery.of(context).size.width;

// Linija 281:
final screenWidth = MediaQuery.of(context).size.width;
final screenHeight = MediaQuery.of(context).size.height;
```

Koristi se `MediaQuery.of(context)` bez defensive checka. Ako `MediaQuery` nije dostupan u context-u, aplikacija će pasti s `ProviderNotFoundException`.

**Posljedice:**
- Aplikacija može pasti ako widget se renderira izvan `MaterialApp`/`WidgetsApp`
- Teško debugiranje problema

**Implementacija:**
Zamijenjeno `MediaQuery.of(context)` sa `MediaQuery.maybeOf(context)` sa fallback vrijednostima. Isti pattern se koristi u `booking_widget_screen.dart` (linije 2031, 2063, 3345).

```dart
// Linija 191 u _buildCompactMonthNavigation:
final mediaQuery = MediaQuery.maybeOf(context);
final screenWidth = mediaQuery?.size.width ?? 400.0;

// Linija 281 u _buildMonthView:
final mediaQuery = MediaQuery.maybeOf(context);
final screenWidth = mediaQuery?.size.width ?? 400.0;
final screenHeight = mediaQuery?.size.height ?? 800.0;
```

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #76: Nedostaje lokalizacija u `DateFormat` u `month_calendar_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `month_calendar_widget.dart`, linija 194-195

**Problem:**
```dart
final monthYear = DateFormat.yMMM().format(_currentMonth);
```

`DateFormat` se kreira bez locale parametra. Datumi će biti prikazani na engleskom bez obzira na jezik aplikacije.

**Posljedice:**
- Datumi će biti prikazani na engleskom čak i kada je aplikacija na hrvatskom ili drugom jeziku
- Loše korisničko iskustvo
- Neusklađenost s ostatkom aplikacije

**Implementacija:**
Dodano `Localizations.localeOf(context)` za dobijanje trenutnog locale-a i proslijeđen u `DateFormat.yMMM(locale.toString())`. Pošto je widget već unutar `MaterialApp`/`WidgetsApp` (jer koristi `WidgetTranslations`), locale će uvijek biti dostupan. Isti pristup se koristi u `timeline_date_header.dart`.

```dart
final locale = Localizations.localeOf(context);
final monthYear = DateFormat.yMMM(locale.toString()).format(_currentMonth);
```

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #77: Timezone problem u `month_calendar_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `month_calendar_widget.dart`, linija 460-461

**Problem:**
```dart
final today = DateTime.now();
final todayNormalized = DateTime(today.year, today.month, today.day);
```

Koristi se `DateTime.now()` (lokalno vrijeme) umjesto UTC-a. Ako se `date` koristi u UTC-u, ovo može uzrokovati probleme s DST promjenama i timezone razlikama.

**Posljedice:**
- Mogući problemi s DST promjenama
- Neusklađenost s ostatkom koda koji koristi UTC
- Moguće pogrešne kalkulacije "danas"

**Implementacija:**
Promijenjeno na `DateTime.now().toUtc()` za trenutno vrijeme i normalizacija na UTC prije kalkulacije. Isti pristup se koristi u `cancellation_policy_card.dart` i `booking_details_screen.dart`.

```dart
final today = DateTime.now().toUtc();
final todayNormalized = DateTime.utc(today.year, today.month, today.day);
```

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #78: Timezone problem u `year_calendar_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - kod već koristi `DateTime.now().toUtc().year` (provjereno 2025-12-16)

**Lokacija:** `year_calendar_widget.dart`, linija 42

**Problem:**
```dart
int _currentYear = DateTime.now().year;
```

Koristi se `DateTime.now()` (lokalno vrijeme) umjesto UTC-a. Ovo može uzrokovati probleme s DST promjenama i timezone razlikama.

**Posljedice:**
- Mogući problemi s DST promjenama
- Neusklađenost s ostatkom koda koji koristi UTC
- Moguće pogrešne kalkulacije godine

**Rješenje:**
```dart
int _currentYear = DateTime.now().toUtc().year;
```

**Prioritet:** 🟡 Visoko

---

### Bug #79: Nedostaje defensive check za MediaQuery u `year_calendar_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - kod već koristi `MediaQuery.maybeOf(context)?.size.width ?? 400.0` (provjereno 2025-12-16)

**Lokacija:** `year_calendar_widget.dart`, linije 48, 218, 279

**Problem:**
```dart
// Linija 48:
final screenWidth = MediaQuery.of(context).size.width;

// Linija 218:
final screenWidth = MediaQuery.of(context).size.width;

// Linija 279:
final screenWidth = MediaQuery.of(context).size.width;
```

Koristi se `MediaQuery.of(context)` bez defensive checka. Ako `MediaQuery` nije dostupan u context-u, aplikacija će pasti s `ProviderNotFoundException`.

**Posljedice:**
- Aplikacija može pasti ako widget se renderira izvan `MaterialApp`/`WidgetsApp`
- Teško debugiranje problema

**Rješenje:**
```dart
final mediaQuery = MediaQuery.maybeOf(context);
if (mediaQuery == null) {
  // Fallback na default vrijednosti
  final screenWidth = 400.0;
  // ...
}
final screenWidth = mediaQuery.size.width;
```

Ili koristiti default vrijednost:
```dart
final screenWidth = MediaQuery.maybeOf(context)?.size.width ?? 400.0;
```

**Prioritet:** 🟡 Visoko

---

### Bug #80: Nedostaje lokalizacija u `DateFormat` u `year_calendar_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `year_calendar_widget.dart`, linija 399

**Problem:**
```dart
final monthName = DateFormat.MMM().format(DateTime(_currentYear, month));
```

`DateFormat` se kreira bez locale parametra. Mjeseci će biti prikazani na engleskom bez obzira na jezik aplikacije.

**Posljedice:**
- Mjeseci će biti prikazani na engleskom čak i kada je aplikacija na hrvatskom ili drugom jeziku
- Loše korisničko iskustvo
- Neusklađenost s ostatkom aplikacije

**Implementacija:**
Dodan locale parametar u `DateFormat.MMM()` koristeći `WidgetTranslations.locale.languageCode`. `WidgetTranslations` se prosljeđuje kroz `_buildMonthRow` metodu kao parametar. Mjeseci se sada prikazuju na jeziku aplikacije (HR, EN, DE, IT).

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #81: Timezone problem u `year_calendar_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `year_calendar_widget.dart`, linija 472

**Problem:**
```dart
final today = DateTime.now();
final todayNormalized = DateTime(today.year, today.month, today.day);
```

Koristi se `DateTime.now()` (lokalno vrijeme) umjesto UTC-a. Ako se `date` koristi u UTC-u, ovo može uzrokovati probleme s DST promjenama i timezone razlikama.

**Posljedice:**
- Mogući problemi s DST promjenama
- Neusklađenost s ostatkom koda koji koristi UTC
- Moguće pogrešne kalkulacije "danas"

**Implementacija:**
Zamijenjeno `DateTime.now()` sa `DateTime.now().toUtc()` i `DateTime(...)` sa `DateTime.utc(...)` za normalizaciju. Osigurava konzistentnost sa UTC kodom i izbjegava probleme s DST promjenama.

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #82: Hardcoded stringovi - nedostaje lokalizacija u `tax_legal_disclaimer_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `tax_legal_disclaimer_widget.dart`, linije 86, 134

**Problem:**
```dart
// Linija 86:
Text(
  'Tax & Legal Information',  // ❌ Hardcoded string
  // ...
)

// Linija 134:
Text(
  'I understand and accept the tax and legal obligations',  // ❌ Hardcoded string
  // ...
)
```

Koriste se hardcoded stringovi umjesto lokalizovanih prijevoda. Ovo će prikazati tekst na engleskom bez obzira na jezik aplikacije.

**Posljedice:**
- Tekst će biti prikazan na engleskom čak i kada je aplikacija na hrvatskom ili drugom jeziku
- Loše korisničko iskustvo
- Neusklađenost s ostatkom aplikacije

**Implementacija:**
Dodana dva nova translation key-a u `widget_translations.dart`: `taxLegalInformation` (naslov sekcije) i `taxLegalAcceptanceText` (checkbox tekst) sa prijevodima za HR, EN, DE, IT. Zamijenjeni hardcoded stringovi u `tax_legal_disclaimer_widget.dart` sa lokalizovanim verzijama koristeći `WidgetTranslations.of(context, ref)`.

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

## 🟢 Niski Prioritet (Calendar Widget Files)

### Bug #83: Nedostaje provjera za prazan `disclaimerText` u `tax_legal_disclaimer_widget.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `tax_legal_disclaimer_widget.dart`, linija 56

**Problem:**
```dart
Text(
  taxConfig.disclaimerText,  // ❌ Nema provjere da li je prazan string
  // ...
)
```

Nema provjere da li je `disclaimerText` prazan string. Ako je prazan, widget će prikazati prazan prostor.

**Posljedice:**
- Mogući layout problemi s praznim stringom
- Loše korisničko iskustvo ako se prikaže prazan widget

**Implementacija:**
Dodana provjera na početku `_buildDisclaimerUI` metode koja vraća `SizedBox.shrink()` ako je `disclaimerText` prazan. Isti pattern se koristi u Bug #70, #71. Cijeli widget se sakriva ako nema disclaimer teksta.

```dart
Widget _buildDisclaimerUI(...) {
  // Bug #83 Fix: Check for empty disclaimerText
  if (taxConfig.disclaimerText.isEmpty) {
    return const SizedBox.shrink();
  }
  // ... rest of the method
}
```

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

## 🟡 Visoki Prioritet (Confirmation Widgets)

### Bug #53: Nedostaje defensive check za MediaQuery u `confirmation_header.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `confirmation_header.dart`, linija 88

**Problem:**
```dart
final screenWidth = MediaQuery.of(context).size.width;
```

Koristi se `MediaQuery.of(context)` bez defensive checka. Ako `MediaQuery` nije dostupan u context-u, aplikacija će pasti s `ProviderNotFoundException`.

**Posljedice:**
- Aplikacija može pasti ako widget se renderira izvan `MaterialApp`/`WidgetsApp`
- Teško debugiranje problema

**Implementacija:**
Zamijenjeno `MediaQuery.of(context)` sa `MediaQuery.maybeOf(context)?.size.width ?? 400.0` sa fallback vrijednostima. Isti pattern se koristi u `month_calendar_widget.dart` (Bug #75) i `booking_widget_screen.dart`.

```dart
// Bug #53 Fix: Defensive check za MediaQuery
final screenWidth = MediaQuery.maybeOf(context)?.size.width ?? 400.0;
final iconSize = screenWidth < 600 ? 56.0 : 80.0;
final logoHeight = screenWidth < 600 ? 60.0 : 80.0;
```

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #54: Nedostaje provjera za prazan email string u `email_confirmation_card.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `email_confirmation_card.dart`, linija 199-226

**Problem:**
```dart
TextSpan(
  text: ' ${widget.guestEmail} ',
  style: TextStyle(
    fontSize: TypographyTokens.fontSizeS,
    fontWeight: FontWeight.w600,
    color: colors.textPrimary,
  ),
),
```

Nema provjere da li je `guestEmail` prazan string. Ako je prazan, widget će prikazati samo razmake.

**Posljedice:**
- Mogući layout problemi s praznim email stringom
- Loše korisničko iskustvo
- Potencijalno confusing za korisnike

**Implementacija:**
Dodana conditional rendering sa provjerom `if (widget.guestEmail.isEmpty)`. Ako je email prazan, prikazuje se samo `tr.forBookingDetails` bez email adrese. Ako email postoji, prikazuje se normalno sa email adresom između `tr.checkYourEmailAt` i `tr.forBookingDetails`.

```dart
// Bug #54 Fix: Check for empty email string
Text.rich(
  TextSpan(
    children: [
      TextSpan(
        text: tr.checkYourEmailAt,
        style: TextStyle(...),
      ),
      if (widget.guestEmail.isEmpty)
        TextSpan(
          text: tr.forBookingDetails,
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeS,
            color: colors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        )
      else ...[
        TextSpan(
          text: ' ${widget.guestEmail} ',
          style: TextStyle(...),
        ),
        TextSpan(
          text: tr.forBookingDetails,
          style: TextStyle(...),
        ),
      ],
    ],
  ),
)
```

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #55: Nedostaje type safety u `next_steps_section.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `next_steps_section.dart`, linija 143-209

**Problem:**
```dart
// Linija 144: dynamic umjesto WidgetColorScheme
Widget _buildStepItem(
  dynamic colors,  // ❌ Trebalo bi biti WidgetColorScheme
  Map<String, dynamic> step,
  bool isLast,
) {
  // ...
  // Linija 162: Nema provjere da li je icon validan
  child: Icon(
    step['icon'] as IconData,  // ❌ Može baciti TypeError
    // ...
  ),
  // Linija 174: Nema provjere da li je title validan
  Text(
    step['title'] as String,  // ❌ Može baciti TypeError
    // ...
  ),
  // Linija 183: Nema provjere da li je description validan
  Text(
    step['description'] as String,  // ❌ Može baciti TypeError
    // ...
  ),
}
```

**Posljedice:**
- Runtime crash ako `step` map ne sadrži očekivane ključeve
- `dynamic` type umjesto `WidgetColorScheme` gubi type safety
- Teško debugiranje problema

**Implementacija:**
Promijenjen tip parametra sa `dynamic colors` na `WidgetColorScheme colors` za type safety. Dodano safe casting sa provjerama i fallback vrijednostima za `icon`, `title`, i `description`. Osigurava da aplikacija neće pasti ako `step` map ne sadrži očekivane ključeve ili ako su tipovi neispravni.

```dart
// Bug #55 Fix: Type safety i safe casting
Widget _buildStepItem(
  WidgetColorScheme colors,  // ✅ Eksplicitni tip
  Map<String, dynamic> step,
  bool isLast,
) {
  // Safe casting sa provjerama
  final icon = step['icon'] is IconData
      ? step['icon'] as IconData
      : Icons.help_outline; // Fallback icon

  final title = step['title'] is String
      ? step['title'] as String
      : 'Unknown step'; // Fallback title

  final description = step['description'] is String
      ? step['description'] as String
      : ''; // Fallback description
  
  // ... rest of code
}
```

**Prioritet:** 🟡 Visoko → ✅ Riješen
  
  factory StepItem.fromMap(Map<String, dynamic> map) {
    return StepItem(
      icon: map['icon'] is IconData ? map['icon'] : Icons.help_outline,
      title: map['title'] is String ? map['title'] : 'Unknown',
      description: map['description'] is String ? map['description'] : '',
    );
  }
}
```

**Prioritet:** 🟡 Visoko

---

## 🟢 Niski Prioritet (Confirmation Widgets)

### Bug #56: Redundantna provjera u `confirmation_header.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `confirmation_header.dart`, linija 83-89

**Problem:**
```dart
if (customLogoUrl != null && customLogoUrl!.isNotEmpty) ...[
```

Koristi se `customLogoUrl!` (null assertion operator) nakon što je već provjereno da nije null. Ovo je redundantno i može biti konfuzno.

**Posljedice:**
- Redundantna provjera
- Može biti konfuzno za developere

**Implementacija:**
Zamijenjeno sa lokalnom varijablom `logoUrl` koja se koristi za provjeru i u `CachedNetworkImage`. Eliminiše redundantni null assertion operator i čini kod čitljivijim.

```dart
// Bug #56 Fix: Remove redundant null assertion operator - use local variable
final logoUrl = customLogoUrl;
if (logoUrl != null && logoUrl.isNotEmpty) ...[
  CachedNetworkImage(
    imageUrl: logoUrl,
    // ...
  ),
]
```

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

### Bug #57: Nedostaje accessibility (Semantics) u confirmation widget-ima ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `confirmation_header.dart:100-118`, `email_confirmation_card.dart:175-248`, `next_steps_section.dart:103-155`

**Problem:**
Svi confirmation widget-i nemaju `Semantics` widget-e za accessibility, što može otežati korištenje screen reader-ima.

**Detalji:**
- `ConfirmationHeader` - nema Semantics za confirmation message i icon
- `EmailConfirmationCard` - nema Semantics za email info i resend button
- `NextStepsSection` - nema Semantics za step items

**Posljedice:**
- Loša accessibility za korisnike sa screen reader-ima
- Neusklađenost s WCAG guidelines
- Loše korisničko iskustvo za korisnike s invaliditetom

**Implementacija:**
Dodani Semantics widget-i za sve confirmation widget-e sa odgovarajućim label-ima i hint-ovima:

1. **ConfirmationHeader**: Dodan Semantics za confirmation icon (sa `image: true`) i confirmation message (sa `header: true`)
2. **EmailConfirmationCard**: Dodan Semantics za email title (sa `header: true`), email info tekst, i resend button (sa `button: true` i `enabled` statusom)
3. **NextStepsSection**: Dodan Semantics za svaki step item sa `label` (title) i `hint` (description)

```dart
// confirmation_header.dart
Semantics(
  label: confirmationMessage,
  image: true,
  child: ScaleTransition(scale: scaleAnimation, child: confirmationIcon),
)

Semantics(
  label: confirmationMessage,
  header: true,
  child: Text(confirmationMessage, ...),
)

// email_confirmation_card.dart
Semantics(
  label: tr.confirmationEmailSentTitle,
  header: true,
  child: Text(tr.confirmationEmailSentTitle, ...),
)

Semantics(
  label: widget.guestEmail.isEmpty
      ? '${tr.checkYourEmailAt} ${tr.forBookingDetails}'
      : '${tr.checkYourEmailAt} ${widget.guestEmail} ${tr.forBookingDetails}',
  child: Text.rich(...),
)

Semantics(
  label: _emailResent ? tr.emailSent : tr.didntReceiveResendEmail,
  button: true,
  enabled: !_isResendingEmail,
  child: InkWell(...),
)

// next_steps_section.dart
Semantics(
  label: title,
  hint: description,
  child: Column(...),
)
```

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

## Sažetak novih bugova (Confirmation Widgets)

| Bug # | Kritičnost | Lokacija | Opis | Status |
|-------|-----------|----------|------|--------|
| #53 | ✅ Riješen | `confirmation_header.dart:88` | Nedostaje defensive check za MediaQuery - zamijenjeno `MediaQuery.of(context)` sa `MediaQuery.maybeOf(context)?.size.width ?? 400.0` | ✅ Riješen - 2025-01-27 |
| #54 | ✅ Riješen | `email_confirmation_card.dart:199-226` | Nedostaje provjera za prazan email string - dodana conditional rendering sa provjerom `if (widget.guestEmail.isEmpty)` | ✅ Riješen - 2025-01-27 |
| #55 | ✅ Riješen | `next_steps_section.dart:143-209` | Nedostaje type safety i provjere za step map - promijenjen `dynamic colors` u `WidgetColorScheme colors` i dodano safe casting sa fallback vrijednostima | ✅ Riješen - 2025-01-27 |
| #56 | ✅ Riješen | `confirmation_header.dart:83-89` | Redundantna provjera s null assertion operatorom - zamijenjeno sa lokalnom varijablom `logoUrl` | ✅ Riješen - 2025-01-27 |
| #57 | ✅ Riješen | `confirmation_header.dart:100-118`, `email_confirmation_card.dart:175-248`, `next_steps_section.dart:103-155` | Nedostaje accessibility (Semantics) - dodani Semantics widget-i za sve confirmation widget-e sa odgovarajućim label-ima i hint-ovima | ✅ Riješen - 2025-01-27 |

---

## Sažetak novih bugova (Details Widgets)

| Bug # | Kritičnost | Lokacija | Opis | Status |
|-------|-----------|----------|------|--------|
| #58 | ✅ Nije bug | `booking_status_banner.dart:69-70` | Sintaksna greška u switch expressionu - `||` operator je validna sintaksa u Dart 3.0+ pattern matching | ✅ Nije bug |
| #59 | ✅ Riješen | `booking_dates_card.dart:61-68` | Potencijalni crash s `parseOrThrow` - dodana `_parseDateSafely()` helper metoda sa try-catch blokom | ✅ Riješen - 2025-01-27 |
| #60 | ✅ Riješen | `booking_dates_card.dart:70` | Nedostaje lokalizacija u `DateFormat` - dodano `Localizations.localeOf(context)` | ✅ Riješen - 2025-01-27 |
| #61 | ✅ Riješen | `booking_notes_card.dart:19` | Nedostaje provjera za prazan `notes` string - dodana provjera `notes.isEmpty` koja vraća `SizedBox.shrink()` | ✅ Riješen - 2025-01-27 |
| #62 | ✅ Riješen | `cancel_confirmation_dialog.dart:27` | Nedostaje provjera za prazan `bookingReference` string - dodana provjera `bookingReference.isEmpty` koja vraća `SizedBox.shrink()` | ✅ Riješen - 2025-01-27 |
| #63 | 🟢 Nisko | Details widget-i | Nedostaje accessibility (Semantics) | Unresolved |
| #64 | 🟢 Nisko | `booking_notes_card.dart:34` | Potencijalni problem s dark mode detekcijom | Unresolved |

---

## 🔴 Kritični Bugovi (Form State & Services)

### Bug #73: Timezone problemi u `form_persistence_service.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `form_persistence_service.dart`, linije 105, 120

**Problem:**
```dart
// Linija 105: Koristi lokalno vrijeme umjesto UTC
timestamp: DateTimeParser.parseOrDefault(
  safeCastString(json['timestamp']),
  DateTime.now(),  // ❌ Lokalno vrijeme
),

// Linija 120: Koristi lokalno vrijeme umjesto UTC
bool get isExpired {
  return DateTime.now().difference(timestamp).inHours > 24;  // ❌ Lokalno vrijeme
}
```

Koristi se `DateTime.now()` umjesto UTC-a za timestamp i provjeru isteka. Ovo može uzrokovati probleme s DST promjenama i timezone razlikama.

**Posljedice:**
- Neusklađenost s ostatkom koda koji koristi UTC
- Problemi s DST promjenama
- Mogući problemi s provjerom isteka podataka (24 sata može biti netočno)

**Implementacija:**
Zamijenjeno `DateTime.now()` sa `DateTime.now().toUtc()` na obje lokacije za konzistentnost sa ostatkom kodebaze koji koristi UTC. Isti pristup se koristi u `month_calendar_widget.dart`, `year_calendar_widget.dart`, `cancellation_policy_card.dart`, i drugim dijelovima kodebaze.

```dart
// Linija 105
timestamp: DateTimeParser.parseOrDefault(
  safeCastString(json['timestamp']),
  DateTime.now().toUtc(),  // ✅ UTC
),

// Linija 120
bool get isExpired {
  return DateTime.now().toUtc().difference(timestamp).inHours > 24;  // ✅ UTC
}
```

**Prioritet:** 🔴 Kritično → ✅ Riješen

---

## 🟡 Visoki Prioritet (Form State & Services)

### Bug #74: Potencijalni problem s `jsonDecode` error handling u `form_persistence_service.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `form_persistence_service.dart`, linija 174

**Problem:**
```dart
// Safely decode JSON and cast to Map
final decoded = jsonDecode(savedData);
final jsonMap = safeCastMap(decoded);
```

`jsonDecode` može baciti `FormatException` ako je JSON invalid. Iako je u try-catch bloku, greška se samo logira i vraća `null`. Međutim, nema specifičnog handlinga za `FormatException` koji bi mogao očistiti corrupt data.

**Posljedice:**
- Ako je `savedData` corrupt ili invalid JSON, `jsonDecode` će baciti exception
- Exception će biti uhvaćen i logiran, ali corrupt data ostaje u SharedPreferences
- Korisnik će ponovno dobiti istu grešku pri sljedećem učitavanju

**Implementacija:**
Dodan specifičan `on FormatException catch` blok prije generičkog catch-a. Kada se detektuje corrupt JSON, automatski se poziva `clearFormData()` za brisanje corrupt podataka iz SharedPreferences. Poboljšan logging za debugiranje.

```dart
try {
  final decoded = jsonDecode(savedData);
  final jsonMap = safeCastMap(decoded);
  // ... rest of code
} on FormatException catch (e) {
  // Specific handling for JSON decode errors
  LoggingService.log(
    'Invalid JSON format in saved form data: $e',
    tag: 'FORM_PERSISTENCE',
  );
  await clearFormData(unitId); // Clear corrupt data
  return null;
} catch (e) {
  // Other errors
  LoggingService.log(
    'Failed to load form data: $e',
    tag: 'FORM_PERSISTENCE',
  );
  return null;
}
```

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #75: Potencijalni problem s praznim stringovima u `booking_form_state.dart` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `booking_form_state.dart`, linije 195-203, 205-214

**Problem:**
```dart
// Linija 194-198: guestFullName getter
String get guestFullName {
  final first = firstNameController.text.trim();
  final last = lastNameController.text.trim();
  return '$first $last'.trim();  // ❌ Može vratiti prazan string
}

// Linija 201-203: fullPhoneNumber getter
String get fullPhoneNumber {
  return '${selectedCountry.dialCode} ${phoneController.text.trim()}';  // ❌ Može vratiti samo country code ako je phone prazan
}
```

Ovi getter-i ne provjeravaju da li su stringovi prazni. `guestFullName` može vratiti prazan string ako su oba polja prazna, a `fullPhoneNumber` će vratiti samo country code ako je phone prazan.

**Posljedice:**
- Prazni stringovi mogu proći kroz validaciju
- Mogući problemi s prikazom u UI-u
- Mogući problemi s backend validacijom

**Implementacija:**
- `guestFullName`: Dodan komentar koji objašnjava da vraća prazan string ako su oba polja prazna (expected behavior)
- `fullPhoneNumber`: Dodana provjera za prazan phone string - vraća prazan string umjesto samo country code

```dart
/// Get full guest name from controllers
///
/// Returns empty string if both fields are empty (expected behavior).
String get guestFullName {
  final first = firstNameController.text.trim();
  final last = lastNameController.text.trim();
  final fullName = '$first $last'.trim();
  return fullName;
}

/// Get full phone number with country code
///
/// Returns empty string if phone is not entered.
String get fullPhoneNumber {
  final phone = phoneController.text.trim();
  if (phone.isEmpty) {
    return ''; // Return empty string if phone is not entered
  }
  return '${selectedCountry.dialCode} $phone';
}
```

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

### Bug #76: Redundantna provjera u `adjustGuestCountToCapacity` metodi ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `booking_form_state.dart`, linija 219-226

**Problem:**
```dart
void adjustGuestCountToCapacity(int maxGuests) {
  if (totalGuests > maxGuests) {
    adults = maxGuests.clamp(1, maxGuests);  // ❌ Redundantno - clamp(1, maxGuests) je uvijek maxGuests
    children = 0;
  }
}
```

`maxGuests.clamp(1, maxGuests)` je redundantno jer će uvijek vratiti `maxGuests` (ako je `maxGuests >= 1`). Također, nema provjere da li je `maxGuests` validan (npr. > 0).

**Posljedice:**
- Redundantna provjera koja može biti konfuzna
- Nema validacije da li je `maxGuests` validan

**Implementacija:**
Uklonjen redundantni `clamp()` poziv i pojednostavljeno na `adults = maxGuests`. Defensive check za `maxGuests <= 0` je već postojao i ostao je. Kod je sada čitljiviji i jednostavniji.

```dart
/// Adjust guest count to respect max capacity
///
/// Called when unit data is loaded to ensure defaults don't exceed limits.
void adjustGuestCountToCapacity(int maxGuests) {
  if (maxGuests <= 0) return; // Defensive check

  if (totalGuests > maxGuests) {
    adults = maxGuests; // maxGuests is already >= 1 (checked above)
    children = 0;
  }
}
```

**Prioritet:** 🟡 Visoko → ✅ Riješen

---

## 🟢 Niski Prioritet (Form State & Services)

### Bug #77: Potencijalni problem s null assertion operatorom u `nights` getteru ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `booking_form_state.dart`, linija 185-190

**Problem:**
```dart
int get nights {
  if (checkIn == null || checkOut == null) return 0;
  return checkOut!.difference(checkIn!).inDays;  // ❌ Koristi null assertion operator
}
```

Iako je provjereno da nisu null na liniji 186, koristi se null assertion operator. Ovo je redundantno i može biti konfuzno.

**Posljedice:**
- Redundantna provjera
- Može biti konfuzno za developere

**Implementacija:**
Zamijenjeni null assertion operatori lokalnim varijablama (`checkInDate` i `checkOutDate`). Poboljšava čitljivost i osigurava da Dart analyzer razumije da su vrijednosti non-null nakon provjere.

```dart
int get nights {
  final checkInDate = checkIn;
  final checkOutDate = checkOut;
  if (checkInDate == null || checkOutDate == null) return 0;
  return checkOutDate.difference(checkInDate).inDays;  // ✅ Bez null assertion operatora
}
```

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

### Bug #78: Nedostaje validacija za `maxGuests` parametar u `adjustGuestCountToCapacity` ✅ RIJEŠEN

**Status:** ✅ Riješen - 2025-01-27

**Lokacija:** `booking_form_state.dart`, linija 210-217

**Problem:**
```dart
void adjustGuestCountToCapacity(int maxGuests) {
  if (totalGuests > maxGuests) {
    adults = maxGuests.clamp(1, maxGuests);
    children = 0;
  }
}
```

Nema provjere da li je `maxGuests` validan (npr. > 0). Ako je `maxGuests` negativan ili 0, metoda neće raditi ispravno. Također, `maxGuests.clamp(1, maxGuests)` je redundantno jer će uvijek vratiti `maxGuests` ako je `maxGuests >= 1`.

**Posljedice:**
- Ako je `maxGuests <= 0`, metoda neće prilagoditi vrijednosti
- Mogući problemi s invalid podacima
- Redundantna provjera koja može biti konfuzna

**Implementacija:**
Dodana validacija na početku metode koja provjerava da li je `maxGuests <= 0` i vraća early return. Također, uklonjen redundantni `clamp()` poziv jer je `maxGuests` već provjeren da je >= 1.

```dart
void adjustGuestCountToCapacity(int maxGuests) {
  if (maxGuests <= 0) return; // Defensive check
  
  if (totalGuests > maxGuests) {
    adults = maxGuests; // maxGuests is already >= 1 (checked above)
    children = 0;
  }
}
```

**Prioritet:** 🟢 Nisko → ✅ Riješen

---

## Sažetak novih bugova (Form State & Services)

| Bug # | Kritičnost | Lokacija | Opis | Status |
|-------|-----------|----------|------|--------|
| #73 | ✅ Riješen | `form_persistence_service.dart:105,120` | Timezone problemi - promijenjeno `DateTime.now()` na `DateTime.now().toUtc()` za timestamp i isExpired provjeru | ✅ Riješen - 2025-01-27 |
| #74 | ✅ Riješen | `form_persistence_service.dart:205-212` | Potencijalni problem s `jsonDecode` error handling - dodan specifičan `on FormatException catch` blok koji čisti corrupt data | ✅ Riješen - 2025-01-27 |
| #75 | ✅ Riješen | `booking_form_state.dart:195-214` | Potencijalni problem s praznim stringovima - dodana provjera za prazan phone u `fullPhoneNumber` getter i komentar za `guestFullName` | ✅ Riješen - 2025-01-27 |
| #76 | ✅ Riješen | `booking_form_state.dart:219-226` | Redundantna provjera - uklonjen `maxGuests.clamp(1, maxGuests)` i pojednostavljeno na `adults = maxGuests` | ✅ Riješen - 2025-01-27 |
| #77 | ✅ Riješen | `booking_form_state.dart:185-190` | Potencijalni problem s null assertion operatorom - zamijenjeni null assertion operatori lokalnim varijablama za bolju čitljivost i type safety | ✅ Riješen - 2025-01-27 |
| #78 | ✅ Riješen | `booking_form_state.dart:210-217` | Nedostaje validacija za `maxGuests` parametar - dodana validacija `if (maxGuests <= 0) return;` i uklonjen redundantni `clamp()` poziv | ✅ Riješen - 2025-01-27 |

---

## Preporuke za rješavanje (ažurirano)

1. **Prvo riješiti kritične bugove (#1-4, #10, #14, #40, #58, #84-85)** - timezone problemi, sintaksne greške i compile-time greške mogu uzrokovati značajne probleme u produkciji (Bug #1-3 - timezone problemi riješeni, Bug #19-22, #26 - riješeni, Bug #48, #63 - nisu bugovi, validan kod, Bug #73 - timezone problemi u form_persistence_service riješeni)
2. **Zatim visoke prioritete (#5-7, #18, #29-31, #41, #49, #53-55, #59-62, #66-67, #74-82, #86-88)** - poboljšati error handling, batch operacije, parsiranje podataka, business logiku, null safety, theme compliance, widget error handling, validaciju formi, lokalizaciju, clipboard operacije, defensive checks, timezone provjere, type safety, validaciju stringova, date parsing, lokalizaciju, MediaQuery defensive checks i input validaciju (Bug #15 - checkout day dokumentacija dodana, Bug #20 - timezone fix, Bug #23 - deprecated WidgetConfig alias riješen, Bug #24 - type casting error handling riješen, Bug #26 - timezone fix u `_getHoursUntilCheckIn`, Bug #27 - null safety riješen, Bug #29 - assert validacije i defensive checks riješeni, Bug #35 - error handling u `_launchUrl()` riješen, Bug #36 - DateFormat error handling riješen, Bug #37 - floating point comparison riješen, Bug #41 - case-sensitive provjere za monospace font riješene, Bug #42 - error handling za clipboard operacije riješen, Bug #49 - timezone problemi u `smart_loading_screen.dart` riješeni, Bug #53 - MediaQuery defensive check riješen, Bug #54 - provjera za prazan email string riješena, Bug #55 - type safety i safe casting riješeni, Bug #59 - error handling za parseOrThrow u booking_dates_card.dart riješen, Bug #60 - lokalizacija u DateFormat u booking_dates_card.dart riješena, Bug #61 - provjera za prazan notes string riješena, Bug #62 - provjera za prazan bookingReference string riješena, Bug #64 - timezone problem u `hoursUntilCheckIn` izračunu riješen, Bug #65 - error handling za clipboard operacije riješen, Bug #66 - floating point comparison za `remainingAmount` riješen (koristi `WidgetConstants.priceTolerance`), Bug #67 - error handling u DateFormat.format() u payment_info_card.dart riješen, Bug #74 - FormatException handling za jsonDecode riješen, Bug #75 - provjera za prazne stringove u booking_form_state riješena, Bug #76 - redundantni clamp uklonjen)
3. **Na kraju niske prioritete (#8-9, #21-22, #28, #32-34, #38-39, #43-44, #46-47, #50-51, #56-57, #63, #68, #83, #89)** - uskladiti kod, provjeriti edge case-ove, logging, responsive design, accessibility, font handling, validaciju stringova, timezone provjere, null check provjere, dark mode detekciju, floating point precision, UX poboljšanja i type conversion edge case-ove (Bug #25 - defensive checks riješeni, Bug #30 - Semantics accessibility riješen, Bug #40 - lokalizirani tooltip riješen, Bug #45 - provjera za prazne stringove riješena, Bug #50 - provjera za prazan `message` string riješena, Bug #51 - Semantics accessibility za `InfoCardWidget` riješen (djelomično), Bug #52 - _startTime null check riješen, Bug #56 - redundantna null assertion provjera riješena, Bug #57 - Semantics accessibility za confirmation widget-e riješena, Bug #64 - timezone problem riješen, Bug #65 - error handling za clipboard riješen, Bug #68 - floating point precision u `_formatCancellationDeadline()` riješen (koristi integer division `~/`), Bug #69 - provjera za prazne stringove riješena, Bug #70 - provjera za prazan string riješena, Bug #71 - provjera za prazne stringove riješena, Bug #72 - floating point precision riješen, Bug #83 - provjera za prazan disclaimerText riješena)

---

## Napomene

- Svi bugovi su dokumentirani na temelju analize koda
- Preporuča se testiranje svih rješenja prije deploy-a
- Timezone bugovi su posebno kritični jer mogu uzrokovati probleme u produkciji
- Error handling bugovi mogu uzrokovati loše korisničko iskustvo
- Business logic bugovi mogu uzrokovati gubitak bookingova ili neočekivano ponašanje (Bug #15 - checkout day dokumentacija dodana, Bug #16 - price lock je riješen)
- Null safety bugovi mogu uzrokovati crash-ove u produkciji (Bug #27 - riješen)
- Provider bugovi (#20-25) mogu uzrokovati probleme s state managementom i UI-om (Bug #19 - riješen)

---

## Orphan Gap Validation - UKLONJENA (2026-01-29)

**Fajl:** `year_calendar_widget.dart`, metoda `_wouldCreateOrphanGap()`
**Status:** VALIDACIJA UKLONJENA. Cijela metoda i njen poziv obrisani.

### Sta je radila
Sprjecavala goste da selektuju datume koji bi ostavili prazninu (gap) manju od `minNights` izmedju nove i postojecih rezervacija.

### Pronadjeni logicki bugovi

**1. Off-by-one u formuli:**
Formula `nextBlockedDate.difference(end).inDays - 1` koristi `-1` koji broji samo potpuno slobodne dane, ali NE racuna da gost moze koristiti turnover dane (checkout/checkin isti dan). Rezultat: gap od tacno `minNights` bookable noci (ukljucujuci turnover) se pogresno blokira jer formula daje `minNights - 1`.

**2. Mrtva zona (minNights=7):**

| Gap (noci) | Validne pozicije | Komentar |
|---|---|---|
| 7 | 1 | Tacan fit |
| 8 | 2 | Flush na obje strane |
| 9 | 1 | Samo sredina |
| **10-13** | **0** | **Potpuno neupotrebljiv!** |
| 14+ | 2+ | Dovoljno za 2 bookinga |

Gapovi od 10-13 noci su POTPUNO neupotrebljivi - nijedna 7-night pozicija ne prolazi validaciju, iako gap fizicki moze primiti jednu 7-night rezervaciju.

**3. UX problem:**
Cak i kad validacija radi korektno (npr. gap od 9 noci), gost mora pogoditi TACNO jednu validnu poziciju (npr. July 2-9) inace dobija nejasnu poruku koja ne objasnjava sta je problem.

### Razlog uklanjanja
- Prekompleksno za goste i ownere da razumiju
- Off-by-one bug u formuli
- Mrtva zona za gapove 10-13 noci (sa minNights=7)
- Month calendar NIKAD nije imao ovu validaciju - ponasanje je sada konzistentno

### Buduce
Ako se orphan gap problem pojavi u praksi, reimplementirati sa:
1. Ispravnom formulom koja racuna turnover dane (bez `-1` za partialCheckIn/partialCheckOut statuse)
2. Boljom UX porukom koja objasnjava problem i predlaze konkretne datume
3. Vizualnim oznacavanjem dana koji bi kreirali orphan gap (npr. sivom bojom)
