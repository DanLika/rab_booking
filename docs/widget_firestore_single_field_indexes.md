# Single-Field Indexi za Embedani Widget

## KRITIČNO: Razlika između Composite i Single-Field Indexa

**Composite Index** = više polja zajedno (npr. `unit_id` + `date`)
**Single-Field Index** = jedno polje (npr. `subdomain`, `slug`, `status`)

Firestore **AUTOMATSKI** kreira single-field indexe za sva polja **PO DEFAULT-u**, ALI postoje 2 izuzetka gde moraju biti **EKSPLICITNO** kreirani:

### Kada je Potreban Eksplicitni Single-Field Index:

1. **Array fields** sa `array-contains` operatorom
2. **Collection group queries** sa single field filter
3. **Range queries** (`<`, `<=`, `>`, `>=`) u collection group query-ima

---

## 🔍 Analiza Single-Field Query-ja u Widget-u

### 1. PROPERTIES Collection - `subdomain` Field

**Query u kodu:**
```dart
// subdomain_service.dart:81
collection('properties')
  .where('subdomain', isEqualTo: subdomain)
```

**Potreban Index:** ✅ **AUTOMATSKI** (equality u collection query)
**Tip:** Collection (ne collection group)
**Status:** ✅ Radi automatski - Firestore kreira ovaj index bez eksplicitne definicije

---

### 2. UNITS Subcollection - `slug` Field

**Query u kodu:**
```dart
// subdomain_service.dart:147
collection('properties/{propertyId}/units')
  .where('slug', isEqualTo: slug)
```

**Potreban Index:** ✅ **AUTOMATSKI** (equality u subcollection query)
**Tip:** Subcollection (ne collection group)
**Status:** ✅ Radi automatski

---

### 3. BOOKINGS Subcollection - `status` Field

**Query u kodu:**
```dart
// firebase_booking_calendar_repository.dart:439
collection('properties/{propertyId}/units/{unitId}/bookings')
  .where('status', whereIn: ['pending', 'confirmed'])
```

**Potreban Index:** ✅ **AUTOMATSKI** (whereIn u subcollection query)
**Tip:** Subcollection (ne collection group)
**Status:** ✅ Radi automatski

---

### 4. DAILY_PRICES Subcollection - `date` Field (Range Query)

**Query 1: Single range query**
```dart
// firebase_daily_price_repository.dart:122-123
collection('properties/{propertyId}/units/{unitId}/daily_prices')
  .where('date', isGreaterThanOrEqualTo: startDate)
  .where('date', isLessThanOrEqualTo: endDate)
```

**Potreban Index:** ✅ **AUTOMATSKI** (range query na istom polju)
**Napomena:** Range queries na **ISTOM POLJU** ne zahtevaju composite index
**Status:** ✅ Radi automatski

**Query 2: OrderBy date**
```dart
// firebase_daily_price_repository.dart:559
collection('properties/{propertyId}/units/{unitId}/daily_prices')
  .orderBy('date', descending: false)
```

**Potreban Index:** ✅ **AUTOMATSKI** (single field orderBy)
**Status:** ✅ Radi automatski

---

### 5. ICAL_EVENTS Subcollection - `unit_id` Field ⚠️

**Query 1: Single equality (collection query)**
```dart
// firebase_booking_calendar_repository.dart:76
collection('properties/{propertyId}/ical_events')
  .where('unit_id', isEqualTo: unitId)
```

**Potreban Index:** ✅ **AUTOMATSKI** (equality u collection query)
**Status:** ✅ Radi automatski

**Query 2: Composite sa date (collection query)**
```dart
// firebase_booking_calendar_repository.dart:208-209
collection('properties/{propertyId}/ical_events')
  .where('unit_id', isEqualTo: unitId)
  .where('start_date', isLessThanOrEqualTo: endDate)
```

**Potreban Index:** **COMPOSITE INDEX** (equality + range) sa COLLECTION scope
**Status:** ✅ DODATO u firestore.indexes.json (linija 185-192)

---

## 📊 Pregled Single-Field Indexa u Firebase Console

Prema tvoj listi indexa, postoje sledeći **single-field** indexi:

| Collection | Field | Scope | Status |
|------------|-------|-------|--------|
| properties | subdomain | Collection | ✅ Auto (default) |
| units | slug | Subcollection | ✅ Auto (default) |
| bookings | status | Subcollection | ✅ Auto (default) |
| daily_prices | date | Subcollection | ✅ Auto (default) |
| ical_events | unit_id | Subcollection | ✅ Auto (default) |
| ical_events | start_date | Subcollection | ✅ Auto (default) |

**Svi ovi indexi su automatski kreirani od strane Firestore-a!**

---

## ⚠️ VAŽNO: Kada Firestore NE Kreira Automatski Single-Field Index

### 1. Array Fields sa array-contains

Ako imaš query kao:
```dart
.where('tags', arrayContains: 'featured')
```

**Potreban je eksplicitni index** u Firebase Console:
- Field: `tags`
- Mode: `ARRAY_CONTAINS`

**Status za widget:** N/A - widget ne koristi array fields

---

### 2. Collection Group Queries sa Range

Ako imaš collection group query sa range:
```dart
collectionGroup('bookings')
  .where('created_at', isGreaterThan: timestamp)
```

**Potreban je eksplicitni single-field index** u Firebase Console:
- Collection Group: `bookings`
- Field: `created_at`
- Mode: `ASCENDING` ili `DESCENDING`

**Status za widget:** ✅ Collection group query-je u widget-u koriste composite indexe (unit_id + status)

---

## ✅ Zaključak za Widget Single-Field Indexe

### Odgovor na tvoje pitanje:

**Svi single-field indexi koje widget zahteva su AUTOMATSKI kreirani od strane Firestore-a.**

Ne postoji potreba za eksplicitnim single-field indexima jer:

1. ✅ Widget koristi **equality** i **whereIn** u collection/subcollection query-ima → automatski
2. ✅ Widget koristi **range queries na istom polju** (date) → automatski
3. ✅ Widget koristi **orderBy na jednom polju** → automatski
4. ✅ Widget NE koristi array fields sa array-contains
5. ✅ Widget koristi composite indexe za collection group queries

---

## 🔍 Provera u Firebase Console

U Firebase Console → Firestore → Indexes → Single field, trebalo bi da vidiš:

**AUTOMATSKI KREIRANE (exempt):**
- `properties.subdomain` - Collection (default behavior)
- `units.slug` - Collection group (default behavior)
- `bookings.status` - Collection group (default behavior)
- `daily_prices.date` - Collection group (default behavior)
- `ical_events.unit_id` - Collection group (default behavior)
- `ical_events.start_date` - Collection group (default behavior)

Ovi indexi su **uvek prisutni** (Firestore automatski kreira) i **ne moraju** biti u firestore.indexes.json fajlu.

---

## 📋 Preporuka

**NE TREBAŠ** dodavati single-field indexe u `firestore.indexes.json` jer:
1. Firestore ih automatski kreira
2. Dodavanje u JSON može stvoriti redundantne indexe
3. Jedini indexi koje trebaš eksplicitno definisati su **composite indexi** (više od jednog polja)

**Jedina akcija potrebna:**
- ✅ Deploy postojeći firestore.indexes.json (sa composite indexima)
- ✅ Sačekaj da se composite indexi kreiraju
- ✅ Widget će raditi bez grešaka
