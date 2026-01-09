# Jules Branch Audit: iCal Overbooking Integration

**Branch:** `feature/overbooking-ical-integration-363307911286820607`
**Commit:** `2391409` - feat(overbooking): Integrate iCal events into detection
**Author:** google-labs-jules[bot]
**Audit Date:** 2026-01-09

---

## 📋 SAŽETAK

Jules predlaže integraciju iCal događaja (Booking.com, Airbnb) u overbooking detekciju. Trenutno `calendarBookingsProvider` vraća samo native bookings, dok iCal eventi nisu uključeni u overbooking provjeru.

**Problem koji rješava:** Vlasnik može imati rezervaciju na Airbnb-u koja nije vidljiva u overbooking detekciji, što može dovesti do dvostrukih rezervacija.

---

## ✅ ŠTO JE ISPRAVNO (Za implementaciju)

### 1. Koncept unifikacije podataka
Jules ispravno identificira da `calendarBookingsProvider` treba biti "single source of truth" za sve kalendarske podatke - i native bookings i iCal events.

### 2. Query chunking za Firestore limit
```dart
// Jules koristi chunking za >30 unit-a (Firestore whereIn limit)
for (var i = 0; i < unitIds.length; i += 30) {
  final chunk = unitIds.sublist(i, i + 30 > unitIds.length ? unitIds.length : i + 30);
  // query...
}
```
**Status:** ✅ Ispravno - Firestore ima limit od 30 za `whereIn`

### 3. Graceful error handling za iCal
```dart
} catch (e) {
  LoggingService.log('Non-critical error fetching iCal events: $e', tag: 'iCal');
}
```
**Status:** ✅ Ispravno - iCal sync failure ne smije srušiti kalendar

### 4. Merge strategija
```dart
mergedBookings.update(
  unitId,
  (existing) => [...existing, ...bookings],
  ifAbsent: () => bookings,
);
```
**Status:** ✅ Ispravno - pravilno spaja native i iCal bookings

---

## ❌ ŠTO JE POGREŠNO (Preskačemo)

### 1. Pogrešan model import
```dart
// Jules koristi:
import '../../../../shared/models/ical_event_model.dart';

// Ispravno je:
import '../../domain/models/ical_feed.dart'; // IcalEvent je ovdje
```

### 2. Pogrešna polja u IcalEvent
```dart
// Jules koristi:
event.uid        // ❌ Ne postoji
event.dtstart    // ❌ Ne postoji  
event.dtend      // ❌ Ne postoji

// Ispravna polja:
event.id         // ✅
event.startDate  // ✅
event.endDate    // ✅
```

### 3. Pogrešan fromMap constructor
```dart
// Jules koristi:
ICalEvent.fromMap(doc.data())  // ❌ Ne postoji

// Ispravno:
IcalEvent.fromFirestore(doc)   // ✅
```

### 4. Direktan Firestore pristup u provider
Jules dodaje direktan `FirebaseFirestore.instance` pristup u provider umjesto korištenja postojećeg repository patterna.

---

## 🔧 PLAN IMPLEMENTACIJE

### Faza 1: Dodati iCal events u calendarBookingsProvider

**Datoteka:** `lib/features/owner_dashboard/presentation/providers/owner_calendar_provider.dart`

**Promjene:**
1. Importati `IcalEvent` model
2. Koristiti postojeći `FirebaseIcalRepository` umjesto direktnog Firestore pristupa
3. Dohvatiti iCal events za sve unit-e
4. Konvertirati `IcalEvent` u `BookingModel` za unified prikaz
5. Merge-ati s regular bookings

**Pseudo-kod:**
```dart
// 1. Dohvati regular bookings (postojeći kod)
final regularBookingsMap = await repository.getCalendarBookingsWithUnitIds(...);

// 2. Dohvati iCal events
final icalRepository = ref.watch(icalRepositoryProvider);
final iCalBookingsMap = <String, List<BookingModel>>{};

for (final unitId in unitIds) {
  try {
    final events = await icalRepository.getEventsForUnit(unitId);
    final bookings = events.map((e) => _icalEventToBookingModel(e)).toList();
    if (bookings.isNotEmpty) {
      iCalBookingsMap[unitId] = bookings;
    }
  } catch (e) {
    LoggingService.log('Non-critical iCal error: $e', tag: 'iCal');
  }
}

// 3. Merge
final mergedBookings = <String, List<BookingModel>>{...regularBookingsMap};
iCalBookingsMap.forEach((unitId, bookings) {
  mergedBookings.update(
    unitId,
    (existing) => [...existing, ...bookings],
    ifAbsent: () => bookings,
  );
});
```

### Faza 2: Helper funkcija za konverziju

```dart
BookingModel _icalEventToBookingModel(IcalEvent event) {
  return BookingModel(
    id: 'ical_${event.id}',  // Prefix za razlikovanje
    unitId: event.unitId,
    checkIn: event.startDate,
    checkOut: event.endDate,
    status: BookingStatus.confirmed,
    guestName: event.guestName,
    totalPrice: 0,
    bookingDate: event.createdAt,
    source: event.source,
  );
}
```

---

## ⚠️ RIZICI I MITIGACIJA

| Rizik | Mitigacija |
|-------|------------|
| Performance - dodatni query | Koristiti batch query s chunking |
| iCal sync failure | Graceful error handling, ne blokira kalendar |
| Duplicate conflicts | Prefix `ical_` na ID-u razlikuje izvore |

---

## 📊 TESTIRANJE

1. **Unit test:** Provjeri da merge ispravno kombinira bookings
2. **Integration test:** Provjeri overbooking detekciju s iCal eventima
3. **Manual test:** Dodaj Airbnb iCal feed, provjeri da se konflikti detektiraju

---

## ✔️ CHECKLIST ZA ODOBRENJE

- [ ] Koncept je ispravan
- [ ] Implementacija koristi postojeće repository-je
- [ ] Error handling je graceful
- [ ] Nema breaking changes za postojeći kod
- [ ] Performance je prihvatljiv

---

**Status:** ✅ IMPLEMENTIRANO

**Datum implementacije:** 2026-01-09

## Promjene:
- `lib/features/owner_dashboard/presentation/providers/owner_calendar_provider.dart`
  - Dodan import za `icalRepositoryProvider` i `IcalEvent`
  - `calendarBookings` provider sada dohvaća i iCal events
  - Nova helper funkcija `_icalEventToBookingModel()` za konverziju
  - Graceful error handling - ako iCal fetch ne uspije, kalendar radi s regular bookings
