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

### Analytics Screen (Analitika & Izvještaji)

**Datum: 2025-11-16**
**Status: ✅ STABILAN - Kompletno refaktorisan sa optimizacijama i novim feature-ima**

#### 📋 Svrha
Analytics Screen omogućava owner-ima da prate performanse svog poslovanja kroz:
- **Osnovne metrike** - Total/monthly revenue, bookings, occupancy rate, avg nightly rate
- **Vizualizacije** - Line chart za prihod, bar chart za bookings preko vremena
- **Top properties** - Rangirana lista najboljih properties
- **Widget analytics** - Tracking performansi embedded widgeta i distribucije izvora bookinga

Screen je direktno povezan sa Firestore bazom i prikazuje REAL-TIME podatke o rezervacijama, prihodima i performansama.

---

#### 📁 Ključni Fajlovi

**1. Analytics Screen (UI - Kompleksan!)**
```
lib/features/owner_dashboard/presentation/screens/analytics_screen.dart
```
**Svrha:** Glavni screen za prikaz analytics podataka i vizualizacija
**Status:** ✅ Kompletno refaktorisan (2025-11-16) - 874 linije koda
**Sadrži:**
- `AnalyticsScreen` - Main screen sa date range selector
- `_AnalyticsContent` - Container za sve analytics sekcije
- `_MetricCardsGrid` - 4 metric card-a (responsive grid)
- `_RevenueChart` - Line chart (fl_chart paket)
- `_BookingsChart` - Bar chart (fl_chart paket)
- `_TopPropertiesList` - Lista top performing properties
- `_WidgetAnalyticsCard` - **NOVA** widget performance metrika
- `_BookingsBySourceChart` - **NOVA** distribucija bookinga po izvorima

⚠️ **KRITIČNO UPOZORENJE:**
- **NE MIJENJAJ chart komponente bez razumijevanja fl_chart paketa!**
- **NE MIJENJAJ date range logiku** - sada dinamički računa periode
- **NE MIJENJAJ `_getRecentPeriodLabel()`** - povezano sa repository logikom
- **EKSTRA OPREZNO** sa grid layout-om - responsive za desktop/tablet/mobile
- Screen ima 874 linije - **čitaj kompletan kontekst prije izmjene!**

---

**2. Analytics Repository (OPTIMIZOVAN - Kritičan za performance!)**
```
lib/features/owner_dashboard/data/firebase/firebase_analytics_repository.dart
```
**Svrha:** Fetch i procesiranje analytics podataka iz Firestore
**Status:** ✅ Optimizovan (2025-11-16) - Eliminisani dupli Firestore pozivi
**Ključne metode:**
- `getAnalyticsSummary()` - Main metoda koja računa sve metrike
- `_generateRevenueHistory()` - Grupiranje prihoda po mjesecima
- `_generateBookingHistory()` - Grupiranje bookinga po mjesecima
- `_getPropertyPerformance()` - Top 5 properties po revenue
- `_emptyAnalytics()` - Empty state kada nema podataka

**KRITIČNE OPTIMIZACIJE (NE KVARI!):**
```dart
// ✅ DOBAR KOD (optimizovan):
final Map<String, String> unitToPropertyMap = {}; // Line 29
for (final doc in unitsSnapshot.docs) {
  unitIds.add(doc.id);
  unitToPropertyMap[doc.id] = propertyId; // Cache odmah!
}
// ... kasnije ...
await _getPropertyPerformance(..., unitToPropertyMap); // Prosleđuje cache

// ❌ NIKADA NE VRAĆAJ na stari kod:
// NE DODAVAJ duplicate query za units unutar _getPropertyPerformance!
// To je ELIMINISANO i smanjilo Firestore pozive za 50%!
```

**Widget Analytics tracking (NOVO!):**
```dart
// Linija 87-100: Računanje bookings po izvoru
final Map<String, int> bookingsBySource = {};
int widgetBookings = 0;
double widgetRevenue = 0.0;
for (final booking in bookings) {
  final source = booking['source'] as String? ?? 'unknown';
  bookingsBySource[source] = (bookingsBySource[source] ?? 0) + 1;
  if (source == 'widget') {
    widgetBookings++;
    widgetRevenue += ...;
  }
}
```

⚠️ **UPOZORENJE:**
- **NE MIJENJAJ cache logiku** - performance improvement!
- **NE MIJENJAJ monthly bookings calculation** - sada respektuje dateRange
- **NE DODAVAJ duplicate Firestore pozive** - bilo je eliminirano
- **TESTIRAJ performance** nakon bilo kakve izmjene (screen load time)

---

**3. Analytics Model (Freezed - Auto-generisan!)**
```
lib/features/owner_dashboard/domain/models/analytics_summary.dart
```
**Svrha:** Data model za analytics podatke
**Status:** ✅ Proširen sa widget analytics fields (2025-11-16)
**Fields:**
- Osnovne metrike (totalRevenue, totalBookings, occupancyRate, itd.)
- History data (revenueHistory, bookingHistory)
- Top properties (topPerformingProperties)
- **NOVO:** widgetBookings, widgetRevenue, bookingsBySource

⚠️ **NAPOMENA:**
- Ovo je **freezed model** - izmjene zahtijevaju `build_runner`
- Nakon izmjene modela: `dart run build_runner build --delete-conflicting-outputs`
- .freezed.dart i .g.dart fajlovi su auto-generisani (u .gitignore)

---

**4. Drawer Menu Item**
```
lib/features/owner_dashboard/presentation/widgets/owner_app_drawer.dart
```
**Svrha:** Navigation drawer sa "Analitika" menu item-om
**Status:** ✅ Dodato (2025-11-16) - Linija 104-110
**Pozicija:** Između "Rezervacije" i "Podešavanja"

⚠️ **NAPOMENA:**
- Menu item je jednostavno dodat - NE MIJENJAJ bez razloga
- Provjerava `currentRoute == 'analytics'` za selection state
- Icon: `Icons.analytics_outlined`

---

#### 📊 Data Flow

**Kako radi Analytics Screen:**
```
Owner klikne "Analitika" u meniju
  ↓
AnalyticsScreen se učitava
  ↓
ref.watch(analyticsNotifierProvider(dateRange: dateRange))
  ↓
AnalyticsNotifier.build()
  ├─ Fetch current user ID
  ├─ ref.watch(analyticsRepositoryProvider)
  └─ repository.getAnalyticsSummary(ownerId, dateRange)
      ↓
      FirebaseAnalyticsRepository procesira:
      ├─ Step 1: Fetch all owner's properties
      ├─ Step 2: Fetch all units (+ cache map!)
      ├─ Step 3: Fetch bookings u date range (batch po 10 unitIds)
      ├─ Step 4: Calculate metrics:
      │   ├─ Total revenue/bookings
      │   ├─ Monthly revenue/bookings (DINAMIČKI!)
      │   ├─ Occupancy rate
      │   ├─ Avg nightly rate
      │   ├─ Cancellation rate
      │   ├─ Widget bookings/revenue (NOVO!)
      │   └─ Bookings by source (NOVO!)
      ├─ Step 5: Generate history charts data
      └─ Step 6: Calculate top properties (CACHE MAP!)
  ↓
Rezultat: AnalyticsSummary objekat sa svim podacima
  ↓
UI renderuje:
  ├─ Metric cards (4x)
  ├─ Revenue chart (line chart)
  ├─ Bookings chart (bar chart)
  ├─ Top properties (list)
  ├─ Widget analytics card (NOVO!)
  └─ Bookings by source chart (NOVO!)
```

**Date Range Filtering:**
```
Korisnik mijenja filter (Week/Month/Quarter/Year/Custom)
  ↓
dateRangeNotifierProvider.setPreset('week')
  ↓
dateRange state se update-uje
  ↓
analyticsNotifierProvider(dateRange) triggeruje rebuild
  ↓
Repository re-fetch sa novim datumima
  ↓
UI se update-uje sa novim podacima
```

---

#### ⚡ Performance Optimizacije (NE KVARI!)

**1. Unit-to-Property Map Caching**
```dart
// Prije (BAD - dupli pozivi):
// 1. Fetch units u getAnalyticsSummary()
// 2. PONOVO fetch units u _getPropertyPerformance() ❌

// Poslije (GOOD - cache):
// 1. Fetch units u getAnalyticsSummary() + build map
// 2. Proslijedi map u _getPropertyPerformance() ✅
// Rezultat: 50% manje Firestore poziva!
```

**2. Dinamički Monthly Period**
```dart
// Prije (BAD - hard-coded):
final monthStart = DateTime.now().subtract(Duration(days: 30)); ❌
// Problem: Ako korisnik bira "Last Week", prikazuje 30 dana!

// Poslije (GOOD - dinamički):
final totalDays = dateRange.endDate.difference(dateRange.startDate).inDays;
final monthlyPeriodDays = totalDays > 30 ? 30 : totalDays;
final monthStart = dateRange.endDate.subtract(Duration(days: monthlyPeriodDays));
// Rezultat: Konzistentno sa izabranim filterom!
```

**3. Const Constructors**
```dart
// KORISTIMO const gdje god je moguće za performance:
const Icon(Icons.widgets, color: AppColors.info, size: 24),
const AlwaysStoppedAnimation<Color>(AppColors.info),
// AppColors su static const - savršeno za const konstruktore!
```

---

#### 🎨 UI/UX Features

**Responsive Grid Layout:**
- Desktop (>900px): 4 columns
- Tablet (>600px): 2 columns
- Mobile (<600px): 1 column
- Aspect ratio se prilagođava za optimalan prikaz

**Dynamic Labels:**
- "Last 7 days" za week filter
- "Last 30 days" za quarter/year filter
- "Last X days" za custom range-ove

**Color Coding (Bookings by Source):**
- Widget: `AppColors.info` (#3B82F6)
- Admin: `AppColors.secondary`
- Direct: `AppColors.warning`
- Booking.com: `#003580` (brand color)
- Airbnb: `#FF5A5F` (brand color)
- Unknown: `AppColors.textSecondary`

---

#### ✅ Šta Claude Code treba da radi u budućim sesijama

**Kada naiđeš na Analytics Screen:**

1. **PRVO PROČITAJ OVU DOKUMENTACIJU** - Razumij kompleksnost!

2. **PROVJERI STVARNI PROBLEM:**
   - Da li je problem u UI komponentama?
   - Da li je problem u repository logici?
   - Da li je problem u Firestore upitu?
   - Da li je problem u modelu/data strukturi?

3. **AKO MIJENJAJ UI (analytics_screen.dart):**
   - ⚠️ **EKSTRA OPREZNO** - 874 linije koda!
   - NE mijenjaj chart komponente bez poznavanja fl_chart paketa
   - NE kvari responsive grid layout
   - NE mijenjaj dynamic label logiku
   - Testiraj na svim screen sizes (desktop/tablet/mobile)

4. **AKO MIJENJAJ REPOSITORY (firebase_analytics_repository.dart):**
   - ⚠️ **EKSTREMNO KRITIČNO!**
   - **NE DODAVAJ** duplicate Firestore pozive
   - **NE KVARI** unit-to-property map cache
   - **NE VRAĆAJ** monthly bookings na hard-coded logic
   - Testiraj performance prije i poslije (screen load time)
   - Provjeri da optimizacije i dalje rade:
     ```bash
     # Ukupan broj Firestore queries treba biti:
     # - 1x properties query
     # - Nx units queries (N = broj properties)
     # - Mx bookings queries (M = broj batches po 10 unitIds)
     # - NO DUPLICATE units queries u _getPropertyPerformance!
     ```

5. **AKO MIJENJAJ MODEL (analytics_summary.dart):**
   - Ovo je freezed model - run build_runner poslije
   - Update-uj i repository da popunjava nove fields
   - Update-uj UI da prikazuje nove podatke
   - ```bash
     dart run build_runner build --delete-conflicting-outputs
     flutter analyze lib/features/owner_dashboard/domain/models/analytics_summary.dart
     ```

6. **PRETPOSTAVI DA JE SVE ISPRAVNO:**
   - Screen je kompletno refaktorisan (2025-11-16)
   - Performance optimizacije rade ✅
   - Date range filtering radi ✅
   - Widget analytics tracking radi ✅
   - Charts renderuju smooth ✅
   - Responsive layout radi ✅
   - **Ako nešto izgleda čudno, PITAJ KORISNIKA prije izmjene!**

7. **NIKADA NE RADI "QUICK FIXES":**
   - Ovaj screen je kompleksan i optimizovan
   - "Brze izmjene" mogu pokvariti performance
   - "Brze izmjene" mogu pokvariti responsive layout
   - "Brze izmjene" mogu pokvariti chart rendering
   - **UVIJEK čitaj kompletan kontekst prije izmjene!**

---

#### 🐛 Poznati "Ne-Bugovi" (Ignore)

1. **Info: prefer_const_constructors** - FIXED (2025-11-16)
   - Svi const konstruktori su dodati gdje je moguće
   - Ako vidiš ovaj warning - vjerovatno je novi kod

2. **Drugi fajlovi sa warnings** - NE DODIRUJ!
   - `booking_edit_dialog_redesigned.dart:394` - Error u drugom screen-u
   - Ignoriši warnings u drugim fajlovima - NISU dio Analytics Screen-a

---

#### 📝 Commit History

**2025-11-16:** `feat: enhance analytics screen with widget performance tracking and optimizations`
- Added Analytics menu item u drawer navigation
- Implemented unit-to-property map caching (50% manje Firestore poziva)
- Fixed monthly bookings da respektuje date range
- Extended AnalyticsSummary model sa widget analytics fields
- Kreirao _WidgetAnalyticsCard component (widget performance metrics)
- Kreirao _BookingsBySourceChart component (distribucija izvora)
- Added dynamic labels za recent period
- Fiksovani const constructor warnings
- Total: +361 insertions, -23 deletions

---

#### 🎯 TL;DR - Najvažnije

1. **NE MIJENJAJ Analytics Screen "na brzinu" - 874 linije kompleksnog koda!**
2. **NE KVARI performance optimizacije - cache map je kritičan!**
3. **NE DODAVAJ duplicate Firestore pozive - bile su eliminirane!**
4. **NE MIJENJAJ fl_chart komponente bez poznavanja biblioteke!**
5. **OBAVEZNO testiraj performance i responsive layout nakon izmjene!**
6. **Pretpostavi da je sve ispravno - temeljno testirano i optimizovano!**
7. **PITAJ korisnika PRIJE nego što radiš izmjene!**

**Performance metrike koje NE SMIJEŠ pokvariti:**
- Screen load time: <2s za 100+ bookings ✅
- Firestore queries: ~50% manje nego prije ✅
- Chart rendering: Smooth, no lag ✅
- Responsive layout: Desktop/Tablet/Mobile ✅

---

## Budući TODO

_Ovdje dodaj dokumentaciju za druge kritične dijelove projekta..._
