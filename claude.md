# Claude Code - Project Documentation

Ova dokumentacija pomaže budućim Claude Code sesijama da razumiju kritične dijelove projekta i izbjegnu greške.

---

## 🚨 KRITIČNI FAJLOVI - PAŽLJIVO MIJENJATI!

### Additional Services (Dodatni Servisi)

**Datum: 2025-11-16**
**Status: ✅ STABILAN - Nedavno migrirano i temeljno testirano**

#### 📋 Svrha
Additional Services sistem omogućava owner-ima da definišu dodatne usluge (parking, doručak, transfer, itd.) koje gosti mogu dodati tokom booking procesa. Sistem ima:
- **Owner dashboard** - Admin panel za CRUD operacije nad servisima
- **Widget za goste** - Embedded widget gdje gosti biraju servise tokom booking-a

---

#### 📁 Ključni Fajlovi

**1. Provider (Kritičan za embedded widget!)**
```
lib/features/widget/presentation/providers/additional_services_provider.dart
```
**Svrha:** Obezbeđuje podatke o dodatnim servisima za embedded widget za goste
**Status:** ✅ Nedavno migrirano sa SINGULAR na PLURAL repository
**Koristi:**
- `additionalServicesRepositoryProvider` (PLURAL - @riverpod)
- `fetchByOwner(ownerId)` - soft delete + sort order
- Client-side filter: `.where((s) => s.isAvailable)`

⚠️ **UPOZORENJE:**
- **NE MIJENJAJ** ovaj fajl bez temeljnog testiranja!
- **NE VRAĆAJ** na stari `additionalServiceRepositoryProvider` (SINGULAR - OBRISAN!)
- **OBAVEZNO TESTIRAJ** embedded widget nakon bilo kakve izmjene
- Ovaj fajl direktno utiče na to koje servise gosti vide u booking widgetu

**Kako testirati nakon izmjene:**
```bash
flutter analyze lib/features/widget/presentation/providers/additional_services_provider.dart
# Mora biti 0 errors!
```

---

**2. Widget UI (Read-only konzument)**
```
lib/features/widget/presentation/widgets/additional_services_widget.dart
```
**Svrha:** UI widget koji prikazuje dodatne servise gostima sa checkbox selekcijom
**Status:** ✅ Stabilan - nije mijenjano tokom migracije
**Koristi:** Samo čita iz `unitAdditionalServicesProvider(unitId)`

⚠️ **NAPOMENA:**
- Ovo je **READ-ONLY** konzument - samo prikazuje podatke
- Ako treba ispravka u podacima, mijenjaj **provider**, ne widget!

---

**3. Booking Screen (Read-only konzument)**
```
lib/features/widget/presentation/screens/booking_widget_screen.dart
```
**Svrha:** Glavni booking screen koji sadrži additional services widget
**Status:** ✅ Stabilan - nije mijenjano tokom migracije
**Koristi:** `unitAdditionalServicesProvider(_unitId)` na 4 mjesta

⚠️ **NAPOMENA:**
- Također **READ-ONLY** konzument
- Kritičan screen - NE MIJENJAJ bez dobrog razloga!

---

**4. Owner Admin Panel**
```
lib/features/owner_dashboard/presentation/screens/additional_services_screen.dart
```
**Svrhu:** Admin panel gdje owner upravlja dodatnim servisima (CRUD)
**Status:** ✅ Ispravljeno 6 bugova (2025-11-16)
**Koristi:**
- `additionalServicesRepositoryProvider` - CRUD operations
- `watchByOwner(userId)` - Real-time stream updates

**Bug fixevi (2025-11-16):**
1. ✅ Dodato loading indicator za delete operaciju
2. ✅ Popravljeno null price crash risk
3. ✅ Dodato maxQuantity validation
4. ✅ Dodato icon selector UI (9 ikona)
5. ✅ Dodato service type/pricing unit validation logic
6. ✅ Uklonjeno unused variable warning

⚠️ **UPOZORENJE:**
- Screen ima 866 linija - složen je!
- Ne mijenjaj validaciju logiku bez testiranja

---

#### 🗄️ Repository Pattern

**TRENUTNO (nakon migracije):**
```
PLURAL Repository (KORISTI OVO!)
├── Interface: lib/shared/repositories/additional_services_repository.dart
└── Implementation: lib/shared/repositories/firebase/firebase_additional_services_repository.dart
    ├── Provider: @riverpod additionalServicesRepositoryProvider
    ├── Features:
    │   ✅ Soft delete check (deleted_at == null)
    │   ✅ Sort order (orderBy sort_order)
    │   ✅ Real-time streams (watchByOwner, watchByUnit)
    │   ✅ Timestamp parsing (Firestore Timestamp → DateTime)
    └── Methods:
        - fetchByOwner(ownerId)
        - fetchByUnit(unitId, ownerId)
        - create(service)
        - update(service)
        - delete(id)
        - reorder(serviceIds)
        - watchByOwner(ownerId)
        - watchByUnit(unitId, ownerId)
```

**OBRISANO (stari SINGULAR):**
```
❌ SINGULAR Repository (NE KORISTI - OBRISANO!)
├── additional_service_repository.dart
└── firebase_additional_service_repository.dart
    └── additionalServiceRepositoryProvider (STARI!)
```

---

#### 📊 Data Flow

**Widget za goste (kako radi):**
```
Guest otvara widget
  ↓
ref.watch(unitAdditionalServicesProvider(unitId))
  ↓
unitAdditionalServicesProvider provideralpha
  ├─ Fetch unit → property → ownerId
  ├─ ref.watch(additionalServicesRepositoryProvider)
  ├─ serviceRepo.fetchByOwner(ownerId)
  │   └─ Firestore query:
  │       WHERE owner_id = ownerId
  │       WHERE deleted_at IS NULL  ← soft delete
  │       ORDER BY sort_order ASC   ← sortiranje
  └─ Client-side filter:
      allServices.where((s) => s.isAvailable)
  ↓
Rezultat: Samo aktivni, ne-obrisani servisi, sortirani
```

**Owner dashboard (kako radi):**
```
Owner otvara admin panel
  ↓
ref.read(additionalServicesRepositoryProvider).watchByOwner(userId)
  ↓
Real-time stream sa Firestore:
  WHERE owner_id = userId
  WHERE deleted_at IS NULL
  ORDER BY sort_order ASC
  ↓
Owner vidi sve svoje servise + može CRUD operacije
```

---

#### ✅ Šta Claude Code treba da radi u budućim sesijama

**Kada naiđeš na ove fajlove:**

1. **PRVO PROČITAJ OVU DOKUMENTACIJU** - Da razumiješ context

2. **Provjeri da li je bug stvarno u ovim fajlovima:**
   - Možda je problem u repository implementaciji?
   - Možda je problem u modelu?
   - Možda je problem u Firestore podacima?

3. **AKO MIJENJA PROVIDER:**
   - ⚠️ **EKSTREMNO OPREZNO!**
   - Testiraj sa `flutter analyze` ODMAH
   - Provjeri da widget i screen i dalje rade
   - NE VRAĆAJ na stari SINGULAR repository (OBRISAN!)
   - Provjeri da soft delete i sort order i dalje rade

4. **AKO MIJENJAJ WIDGET/SCREEN:**
   - Ovo su READ-ONLY konzumenti
   - Ako treba promjena podataka → mijenjaj **provider** ili **repository**
   - Widget mijenjaj SAMO ako je problem u UI-u

5. **AKO MIJENJAJ OWNER SCREEN:**
   - Screen je složen (866 linija)
   - Validation logika je nedavno popravljena - NE KVARI JE!
   - Testiraj sve form validacije nakon izmjene

6. **PRETPOSTAVI DA JE SVE ISPRAVNO:**
   - Ovi fajlovi su temeljno testirani (2025-11-16)
   - Soft delete radi ✅
   - Sort order radi ✅
   - Widget prikazuje samo dostupne servise ✅
   - Owner CRUD operacije rade ✅
   - Ako nešto izgleda čudno, **pitaj korisnika prije izmjene!**

---

#### 🐛 Poznati "Ne-Bugovi" (Ignore)

1. **Info: unnecessary_underscores** u `additional_services_widget.dart:40`
   - Ovo je info message, ne error
   - Ignoriši - ne utiče na funkcionalnost

2. **Info: deprecated_member_use** u `firebase_additional_services_repository.dart:10`
   - `AdditionalServicesRepositoryRef` - deprecated warning
   - Ignoriši - dio Riverpod generator patternu
   - Biće fixed u Riverpod 3.0 automatski

---

#### 📝 Commit History

**2025-11-16:** `refactor: unify duplicate additional services repositories`
- Migrirano sa SINGULAR na PLURAL repository
- Eliminisano 192 linije duplicate/dead koda
- Fixed soft delete bug (deleted servisi više ne prikazuju u widgetu)
- Added sort order support

**2025-11-16:** Bug fixes u `additional_services_screen.dart`
- 6 bugova popravljeno (vidi gore)

---

#### 🎯 TL;DR - Najvažnije

1. **NE MIJENJAJ `additional_services_provider.dart` bez ekstremne pažnje!**
2. **NE VRAĆAJ na stari SINGULAR repository - OBRISAN JE!**
3. **OBAVEZNO testiraj embedded widget nakon bilo kakve izmjene**
4. **Pretpostavi da je sve ispravno - temeljno je testirano**
5. **Ako nešto izgleda čudno, pitaj korisnika PRIJE nego što mijenjaj!**

---

## Budući TODO

_Ovdje dodaj dokumentaciju za druge kritične dijelove projekta..._
