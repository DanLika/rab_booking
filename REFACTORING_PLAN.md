# 🔄 RAB BOOKING - REFACTORING PLAN

**Datum:** 24. Oktobar 2025
**Verzija:** 1.0
**Status:** Planning

---

## 📋 IZVRŠNI SAŽETAK

Transformacija postojeće AirBnb kopije u **multi-tenant SaaS booking platformu** koja omogućava vlasnicima apartmana da upravljaju objektima, smještajnim jedinicama i rezervacijama kroz jednostavan grid kalendar.

### Ključne razlike:

| Trenutno (AirBnb kopija) | Cilj (Booking SaaS) |
|--------------------------|---------------------|
| ❌ Property search & filtering | ✅ Owner manages own properties |
| ❌ Guest browsing properties | ✅ Direct booking via embed widget |
| ❌ Favorites, Reviews, Ratings | ✅ Simple calendar grid (zelena/crvena/siva) |
| ❌ Complex payment flow (Stripe) | ✅ Offline payment (IBAN, 20% advance) |
| ❌ Admin dashboard | ✅ Multi-tenant (svaki owner svoj dashboard) |
| ❌ Marketing content | ✅ iCal sync (Booking.com) |

---

## 🎯 GLAVNI CILJEVI

### 1. **Multi-Tenant SaaS**
- Više vlasnika (owners) se može registrovati
- Svaki owner kreira svoje objekte (properties)
- Svaki property ima N smještajnih jedinica (units)
- **Izolacija podataka** - owner vidi samo svoje podatke

### 2. **Grid Kalendar**
- Kvadratići predstavljaju dane
- **Boje:**
  - 🟢 **Zelena** = Slobodno (available)
  - 🔴 **Crvena** = Zauzeto (booked)
  - ⚫ **Siva** = Blokirano (blocked by owner)
- Cijene po danu
- Multi-select dana
- Real-time prikaz ukupne cijene

### 3. **Booking Flow (Bez Online Plaćanja)**
1. Guest odabere dane na kalendaru
2. Vidi ukupnu cijenu
3. Unese podatke (ime, email, telefon)
4. Dobije podatke za uplatu:
   - **20% avans** (IBAN, referenca)
   - Ostatak na licu mjesta
5. Owner dobije email notifikaciju

### 4. **iCal Sync**
- Import rezervacija sa Booking.com
- Parse iCal feed
- Automatski ili ručni sync
- Sprečava overbooking

### 5. **Embed Widget**
- Svaka unit ima svoj embeddable URL
- Prikazuje kalendar + booking forma
- Stavlja se u `<iframe>` na jasko-rab.com

---

## 🗂️ TRENUTNA STRUKTURA PROJEKTA

```
lib/
├── main.dart
├── core/
│   ├── animations/
│   ├── config/
│   ├── constants/
│   ├── errors/
│   ├── exceptions/
│   ├── providers/
│   ├── services/
│   ├── theme/
│   └── utils/
├── features/
│   ├── about/              ❌ DELETE
│   ├── admin/              ❌ DELETE
│   ├── auth/               ✅ KEEP & MODIFY
│   ├── booking/            ✅ KEEP & MODIFY
│   ├── calendar/           ✅ KEEP & MODIFY
│   ├── design_system_demo/ ❌ DELETE
│   ├── favorites/          ❌ DELETE
│   ├── home/               ❌ DELETE
│   ├── legal/              ✅ KEEP
│   ├── notifications/      ✅ KEEP
│   ├── owner/              ❌ DELETE (merge to owner_dashboard)
│   ├── owner_dashboard/    ✅ KEEP & MODIFY
│   ├── payment/            ❌ DELETE (replace with simple payment info)
│   ├── profile/            ✅ KEEP & MODIFY
│   ├── property/           ✅ KEEP & MODIFY
│   ├── search/             ❌ DELETE
│   └── support/            ❌ DELETE
├── shared/
│   ├── models/
│   ├── repositories/
│   └── widgets/
└── l10n/                   ✅ KEEP
```

---

## ❌ ŠTA BRISATI (Detaljno)

### 1. **Home/Marketing Feature**
📁 `lib/features/home/`

**Razlog:** Nema potrebe za marketing landing page. App je SaaS tool, ne marketplace.

**Fajlovi za brisanje:**
```
lib/features/home/
├── data/
│   └── marketing_content_repository.dart
├── presentation/
│   ├── screens/
│   │   └── home_screen.dart
│   └── widgets/
│       ├── cta_section_premium.dart
│       ├── featured_properties_section.dart
│       ├── home_hero_section_premium.dart
│       ├── how_it_works_section_premium.dart
│       ├── popular_destinations_section_premium.dart
│       ├── recently_viewed_section_premium.dart
│       └── testimonials_section_premium.dart
```

**Akcije:**
1. Obrisati cijeli folder `lib/features/home/`
2. Ukloniti iz `router.dart`: `GoRoute(path: '/', builder: ...)` → Replace sa dashboard
3. Ukloniti iz navigation bar-a

---

### 2. **Search & Filtering Feature**
📁 `lib/features/search/`

**Razlog:** Nema browsing properties. Guest dolazi direktno na embed widget.

**Fajlovi za brisanje:**
```
lib/features/search/
├── data/
│   └── repositories/
│       ├── property_search_repository.dart
│       ├── property_search_repository_optimized.dart
│       ├── recently_viewed_repository.dart
│       └── saved_searches_repository.dart
├── presentation/
│   ├── screens/
│   │   └── search_screen.dart (i drugi)
│   └── providers/
```

**Akcije:**
1. Obrisati cijeli folder
2. Ukloniti search bar iz app bar-a
3. Ukloniti search route iz router-a

---

### 3. **Favorites Feature**
📁 `lib/features/favorites/`

**Razlog:** Nema need za favoriting properties.

**Akcije:**
1. Obrisati cijeli folder
2. Ukloniti heart icon iz property cards
3. Drop `favorites` table iz Supabase-a

---

### 4. **Admin Dashboard**
📁 `lib/features/admin/`

**Razlog:** Multi-tenant sistem - svaki owner svoj admin, nema super-admin.

**Akcije:**
1. Obrisati cijeli folder
2. Ukloniti admin routes
3. Ukloniti role-based routing (admin check)

---

### 5. **Support/Contact Feature**
📁 `lib/features/support/`

**Razlog:** Za sada nije potreban support sistem.

**Akcije:**
1. Obrisati folder
2. Možda ostaviti samo simple contact email u settings

---

### 6. **Payment Processing (Stripe)**
📁 `lib/features/payment/`

**Razlog:** Nema online plaćanja. Samo prikaz podataka za uplatu.

**Fajlovi za brisanje:**
```
lib/features/payment/
├── data/
│   └── payment_service.dart  (Stripe integracija)
├── presentation/
│   ├── screens/
│   │   ├── payment_screen.dart
│   │   └── payment_success_screen.dart
```

**Akcije:**
1. Obrisati Stripe kod
2. Zadržati samo `payment_info` prikaz (IBAN, account holder)
3. Kreirati `PaymentInfoWidget` - prikazuje IBAN, iznos, referencu

---

### 7. **About & Design System Demo**
📁 `lib/features/about/`, `lib/features/design_system_demo/`

**Razlog:** Development/demo fajlovi, nisu za production.

**Akcije:**
1. Obrisati foldere
2. Ukloniti routes

---

### 8. **Nepotrebni Core Services**

**Fajlovi za brisanje:**
```
lib/core/services/
├── analytics_service.dart          ❌ (previše kompleksno)
├── supabase_analytics_service.dart ❌
├── performance_optimization_service.dart ❌
├── cache_service.dart              ❌ (možda kasnije)
```

**Razlog:** Over-engineering za MVP. Dodati kasnije po potrebi.

---

### 9. **Documentation Files**

**Fajlovi za brisanje:**
```
root/
├── DetailsPage.txt                 ❌
├── SearchMapPage.txt               ❌
├── SearchPage.txt                  ❌
├── flutterflow booking flow.txt    ❌
├── plan za implementaciju rab booking.txt ❌
```

**Razlog:** Stari dokumenti koji nisu relevantni za novi sistem.

---

## ✅ ŠTA ZADRŽATI I MODIFIKOVATI

### 1. **Auth Feature** ✅
📁 `lib/features/auth/`

**Zadržati:**
- ✅ Login screen
- ✅ Register screen
- ✅ Email/Password auth
- ✅ Password reset
- ✅ Auth state management

**Modifikovati:**
- ✅ Pojednostaviti registration flow (ukloniti property type, units count - to će biti u settingu)
- ✅ Ukloniti role-based auth (guest/owner/admin) → samo owner
- ✅ Nakon registracije → redirect na "Create Property" wizard

**Novi fajlovi:**
```
lib/features/auth/presentation/screens/
└── registration_wizard/
    ├── step1_account_info.dart     (email, password)
    ├── step2_personal_info.dart    (ime, prezime, phone)
    └── step3_complete.dart         (potvrda)
```

---

### 2. **Properties & Units Management** ✅
📁 `lib/features/property/`

**Zadržati:**
- ✅ Property model
- ✅ Property repository

**Modifikovati:**
- ✅ Promijeniti `PropertyDetailsScreen` → fokus na owner view, ne guest view
- ✅ Dodati `UnitManagementScreen` - lista jedinica po property-ju
- ✅ Dodati `AddEditUnitScreen`
- ✅ Ukloniti property search/filtering kod

**Nova struktura:**
```
lib/features/properties/
├── data/
│   ├── models/
│   │   ├── property.dart
│   │   └── unit.dart              🆕 NOVO
│   └── repositories/
│       ├── properties_repository.dart
│       └── units_repository.dart  🆕 NOVO
├── presentation/
│   ├── screens/
│   │   ├── properties_list_screen.dart
│   │   ├── add_edit_property_screen.dart
│   │   ├── property_details_screen.dart
│   │   ├── units_list_screen.dart          🆕 NOVO
│   │   └── add_edit_unit_screen.dart       🆕 NOVO
│   └── widgets/
│       ├── property_card.dart
│       └── unit_card.dart                  🆕 NOVO
```

---

### 3. **Calendar Feature** ✅
📁 `lib/features/calendar/`

**Zadržati:**
- ✅ Calendar models (CalendarDay, DayStatus)
- ✅ Calendar repository
- ✅ Real-time updates

**Modifikovati:**
- ❌ Ukloniti `table_calendar` dependency
- ✅ **Kreirati potpuno novi Grid Calendar Widget**
- ✅ Dodati multi-select functionality
- ✅ Prikazati cijene u svakom kvadratiću
- ✅ Real-time prikaz ukupne cijene

**Nova struktura:**
```
lib/features/calendar/
├── data/
│   ├── models/
│   │   ├── calendar_day.dart
│   │   ├── day_status.dart
│   │   └── price_summary.dart           🆕 NOVO
│   └── repositories/
│       ├── calendar_repository.dart
│       └── pricing_repository.dart      🆕 NOVO
├── presentation/
│   ├── screens/
│   │   ├── owner_calendar_screen.dart   (owner view - block dates, set prices)
│   │   └── guest_calendar_screen.dart   🆕 NOVO (guest view - select dates)
│   └── widgets/
│       ├── grid_calendar_widget.dart    🆕 NOVO (glavni widget!)
│       ├── calendar_day_cell.dart       🆕 NOVO
│       ├── calendar_header.dart         🆕 NOVO
│       ├── calendar_legend.dart         🆕 NOVO
│       ├── price_summary_card.dart      🆕 NOVO
│       └── date_range_selector.dart     🆕 NOVO
```

**Boje (update):**
```dart
enum DayStatus {
  available,   // 🟢 #4CAF50 (zelena)
  booked,      // 🔴 #EF5350 (crvena)
  blocked,     // ⚫ #9E9E9E (siva)
}
```

---

### 4. **Booking Feature** ✅
📁 `lib/features/booking/`

**Zadržati:**
- ✅ Booking model
- ✅ Booking repository
- ✅ Email notifications

**Modifikovati:**
- ❌ Ukloniti payment flow (Stripe)
- ✅ Dodati payment info display (IBAN, referenca)
- ✅ Dodati booking confirmation screen sa uputstvima za uplatu
- ✅ Jednostavan booking form (ime, email, telefon)

**Nova struktura:**
```
lib/features/bookings/
├── data/
│   ├── models/
│   │   ├── booking.dart
│   │   ├── booking_status.dart
│   │   └── payment_info.dart          🆕 NOVO
│   └── repositories/
│       └── bookings_repository.dart
├── presentation/
│   ├── screens/
│   │   ├── booking_form_screen.dart
│   │   ├── booking_confirmation_screen.dart  (sa payment info)
│   │   ├── bookings_list_screen.dart         (owner view)
│   │   └── booking_details_screen.dart
│   └── widgets/
│       ├── booking_form.dart
│       ├── payment_info_card.dart     🆕 NOVO
│       └── booking_status_chip.dart
```

**Booking Model Update:**
```dart
class Booking {
  final String id;
  final String unitId;
  final String guestName;
  final String guestEmail;
  final String? guestPhone;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final double totalPrice;
  final double advanceAmount;        // 20% od total
  final BookingStatus status;        // pending, confirmed, cancelled
  final PaymentStatus paymentStatus; // awaiting_advance, advance_paid, fully_paid
  final String source;               // 'direct' ili 'booking_com'
  final String? notes;
  final DateTime createdAt;
}
```

---

### 5. **Owner Dashboard** ✅
📁 `lib/features/owner_dashboard/`

**Zadržati:**
- ✅ Dashboard layout
- ✅ Stats widgets

**Modifikovati:**
- ✅ Pojednostaviti analytics (samo basic stats)
- ✅ Fokus na: Today's arrivals/departures, Current bookings, Quick actions
- ❌ Ukloniti advanced revenue analytics

**Nova struktura:**
```
lib/features/dashboard/
├── presentation/
│   ├── screens/
│   │   └── dashboard_screen.dart
│   └── widgets/
│       ├── today_overview_card.dart       (arrivals, departures)
│       ├── upcoming_bookings_card.dart
│       ├── quick_actions_card.dart        (new booking, block dates, set prices)
│       └── properties_summary_card.dart
```

---

### 6. **Profile/Settings** ✅
📁 `lib/features/profile/`

**Zadržati:**
- ✅ User profile
- ✅ Settings

**Modifikovati:**
- ✅ Dodati payment info setup (IBAN, bank name, account holder)
- ✅ Dodati iCal URL management
- ✅ Ukloniti guest-specific features

**Nova struktura:**
```
lib/features/profile/
├── presentation/
│   ├── screens/
│   │   ├── profile_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── payment_info_setup_screen.dart  🆕 NOVO
│   │   └── ical_sync_settings_screen.dart  🆕 NOVO
```

---

## 🆕 ŠTA DODATI (Nove Feature-e)

### 1. **iCal Sync Feature** 🆕
📁 `lib/features/ical_sync/`

**Opis:** Import rezervacija sa Booking.com putem iCal feed-a.

**Struktura:**
```
lib/features/ical_sync/
├── data/
│   ├── models/
│   │   └── ical_event.dart
│   ├── services/
│   │   ├── ical_parser_service.dart
│   │   └── ical_sync_service.dart
│   └── repositories/
│       └── ical_repository.dart
├── presentation/
│   ├── screens/
│   │   ├── ical_sync_setup_screen.dart
│   │   └── sync_history_screen.dart
│   └── widgets/
│       ├── ical_url_input.dart
│       └── sync_status_indicator.dart
```

**Dependencies:**
```yaml
icalendar_parser: ^2.0.0
http: ^1.1.0
```

**Funkcionalnost:**
1. Owner unese iCal URL za svaku jedinicu
2. Klikne "Sync Now" ili automatski sync (svakih 1h)
3. Parser ekstraktuje rezervacije iz iCal-a
4. Kreira `Booking` record sa `source: 'booking_com'`
5. Sprečava duplikate (check po datumima)
6. Prikazuje booking kao CRVENU na kalendaru

---

### 2. **Embed Widget Feature** 🆕
📁 `lib/features/embed/`

**Opis:** Standalone web widget koji se može embedovati u iframe.

**Struktura:**
```
lib/features/embed/
├── presentation/
│   ├── screens/
│   │   └── embed_calendar_screen.dart
│   └── widgets/
│       ├── embed_calendar_widget.dart
│       └── embed_booking_form.dart
```

**Route:**
```dart
GoRoute(
  path: '/embed/:unitId',
  builder: (context, state) {
    final unitId = state.pathParameters['unitId']!;
    return EmbedCalendarScreen(unitId: unitId);
  },
),
```

**Funkcionalnost:**
1. Prikazuje grid kalendar za odabranu jedinicu
2. Guest može da selektuje datume
3. Vidi ukupnu cijenu
4. Klikne "Rezerviši" → otvara booking form
5. Popuni podatke → Submit
6. Dobije confirmation sa payment info

**Styling:**
- Minimalan UI (bez navigation, bez header)
- Responsive (mobile + desktop)
- Light theme (match sa jasko-rab.com)

---

### 3. **Pricing Management Feature** 🆕
📁 `lib/features/pricing/`

**Opis:** Postavljanje cijena po danima ili sezonama.

**Struktura:**
```
lib/features/pricing/
├── data/
│   ├── models/
│   │   ├── daily_price.dart
│   │   └── seasonal_price.dart
│   └── repositories/
│       └── pricing_repository.dart
├── presentation/
│   ├── screens/
│   │   ├── pricing_calendar_screen.dart
│   │   └── seasonal_pricing_screen.dart
│   └── widgets/
│       ├── price_editor_dialog.dart
│       └── bulk_price_setter.dart
```

**Funkcionalnost:**
1. Owner otvara jedinicu → "Set Prices"
2. Vidi kalendar gdje svaki dan ima cijenu
3. Može:
   - Kliknuti na dan → postavi cijenu
   - Selektovati range → bulk set cijenu
   - Kreirati "sezone" (ljeto, zima) sa default cijenama

**Priority sistema:**
```
Daily Price > Seasonal Price > Base Price
```

---

### 4. **Multi-Language Support** (Extended) 🆕

**Proširiti postojeće lokalizacije:**
```
lib/l10n/
├── app_en.arb    (English - za strane goste)
├── app_hr.arb    (Hrvatski)
├── app_de.arb    🆕 NOVO (Deutsch - mnogo Nijemaca na Rabu)
└── app_it.arb    🆕 NOVO (Italiano - talijani)
```

---

## 🗄️ SUPABASE SCHEMA IZMJENE

### **Nove Tabele**

#### 1. **units** (Nova!)
```sql
CREATE TABLE units (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  name TEXT NOT NULL,                    -- "Apartman 1"
  max_guests INT DEFAULT 2,
  base_price DECIMAL(10,2),              -- Default price per night
  description TEXT,
  images TEXT[],                         -- Array of image URLs
  is_active BOOLEAN DEFAULT TRUE,
  ical_url TEXT,                         -- Booking.com iCal URL
  last_ical_sync TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_units_property ON units(property_id);
```

#### 2. **daily_prices** (Nova!)
```sql
CREATE TABLE daily_prices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  unit_id UUID REFERENCES units(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(unit_id, date)
);

CREATE INDEX idx_daily_prices_unit_date ON daily_prices(unit_id, date);
```

#### 3. **blocked_dates** (Nova!)
```sql
CREATE TABLE blocked_dates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  unit_id UUID REFERENCES units(id) ON DELETE CASCADE,
  blocked_from DATE NOT NULL,
  blocked_to DATE NOT NULL,
  reason TEXT DEFAULT 'maintenance',
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_blocked_dates_unit ON blocked_dates(unit_id);
```

#### 4. **payment_info** (Nova!)
```sql
CREATE TABLE payment_info (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  bank_name TEXT,
  iban TEXT NOT NULL,
  swift TEXT,
  account_holder TEXT NOT NULL,
  default_advance_percentage DECIMAL(5,2) DEFAULT 20.00,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(owner_id)
);
```

---

### **Izmjena Postojećih Tabela**

#### **properties** (Update)
```sql
-- Dodati owner_id (multi-tenant!)
ALTER TABLE properties ADD COLUMN owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE properties ADD COLUMN is_active BOOLEAN DEFAULT TRUE;

-- Index za owner lookup
CREATE INDEX idx_properties_owner ON properties(owner_id);
```

#### **bookings** (Update)
```sql
-- Dodati unit_id reference
ALTER TABLE bookings DROP COLUMN property_id;  -- Više ne treba
ALTER TABLE bookings ADD COLUMN unit_id UUID REFERENCES units(id) ON DELETE CASCADE;

-- Dodati payment fields
ALTER TABLE bookings ADD COLUMN advance_amount DECIMAL(10,2);
ALTER TABLE bookings ADD COLUMN payment_status TEXT DEFAULT 'awaiting_advance';
  -- 'awaiting_advance', 'advance_paid', 'fully_paid'

-- Dodati source field
ALTER TABLE bookings ADD COLUMN source TEXT DEFAULT 'direct';
  -- 'direct', 'booking_com', 'airbnb'

-- Index
CREATE INDEX idx_bookings_unit ON bookings(unit_id);
CREATE INDEX idx_bookings_dates ON bookings(check_in, check_out);
```

---

### **Tabele za Brisanje**

```sql
-- Obrisati nepotrebne tabele
DROP TABLE IF EXISTS favorites CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS saved_searches CASCADE;
DROP TABLE IF EXISTS recently_viewed CASCADE;
DROP TABLE IF EXISTS marketing_content CASCADE;
DROP TABLE IF EXISTS support_tickets CASCADE;
```

---

### **Row Level Security (RLS) Policies**

```sql
-- Properties: Owner vidi samo svoje
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owners can view own properties"
ON properties FOR SELECT
USING (auth.uid() = owner_id);

CREATE POLICY "Owners can create own properties"
ON properties FOR INSERT
WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can update own properties"
ON properties FOR UPDATE
USING (auth.uid() = owner_id);

-- Units: Public može vidjeti active units (za embed)
ALTER TABLE units ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active units"
ON units FOR SELECT
USING (is_active = TRUE);

CREATE POLICY "Owners can manage units"
ON units FOR ALL
USING (
  property_id IN (
    SELECT id FROM properties WHERE owner_id = auth.uid()
  )
);

-- Bookings: Public može kreirati, Owner može vidjeti
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can create bookings"
ON bookings FOR INSERT
WITH CHECK (TRUE);

CREATE POLICY "Owners can view their bookings"
ON bookings FOR SELECT
USING (
  unit_id IN (
    SELECT u.id FROM units u
    JOIN properties p ON u.property_id = p.id
    WHERE p.owner_id = auth.uid()
  )
);

CREATE POLICY "Owners can update their bookings"
ON bookings FOR UPDATE
USING (
  unit_id IN (
    SELECT u.id FROM units u
    JOIN properties p ON u.property_id = p.id
    WHERE p.owner_id = auth.uid()
  )
);
```

---

## 📦 DEPENDENCIES UPDATE

### **Ukloniti:**
```yaml
# pubspec.yaml - REMOVE
dependencies:
  flutter_stripe: ^10.1.1        ❌ Više ne treba
  table_calendar: ^3.0.9         ❌ Pravimo custom grid
```

### **Dodati:**
```yaml
# pubspec.yaml - ADD
dependencies:
  icalendar_parser: ^2.0.0       🆕 Za iCal sync
  http: ^1.1.0                   🆕 HTTP requests
  url_launcher: ^6.2.1           🆕 Open IBAN u banking app
  share_plus: ^7.2.1             🆕 Share booking confirmation
  syncfusion_flutter_calendar: ^24.1.41  🆕 (opciono - za grid, ili custom)
```

---

## 🔀 ROUTING IZMJENE

### **Stari Router:**
```dart
routes: [
  GoRoute(path: '/', builder: (_, __) => HomeScreen()),        ❌ DELETE
  GoRoute(path: '/search', builder: (_, __) => SearchScreen()), ❌ DELETE
  GoRoute(path: '/favorites', ...),                            ❌ DELETE
  GoRoute(path: '/admin', ...),                                ❌ DELETE
  // ...
]
```

### **Novi Router:**
```dart
final router = GoRouter(
  initialLocation: '/dashboard',  // Owner dashboard kao default
  routes: [
    // Auth
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => RegisterScreen()),

    // Owner Dashboard
    GoRoute(path: '/dashboard', builder: (_, __) => DashboardScreen()),

    // Properties & Units
    GoRoute(path: '/properties', builder: (_, __) => PropertiesListScreen()),
    GoRoute(path: '/properties/add', builder: (_, __) => AddPropertyScreen()),
    GoRoute(
      path: '/properties/:propertyId/units',
      builder: (context, state) {
        final propertyId = state.pathParameters['propertyId']!;
        return UnitsListScreen(propertyId: propertyId);
      },
    ),
    GoRoute(
      path: '/units/:unitId/calendar',
      builder: (context, state) {
        final unitId = state.pathParameters['unitId']!;
        return OwnerCalendarScreen(unitId: unitId);
      },
    ),

    // Bookings
    GoRoute(path: '/bookings', builder: (_, __) => BookingsListScreen()),
    GoRoute(
      path: '/bookings/:bookingId',
      builder: (context, state) {
        final bookingId = state.pathParameters['bookingId']!;
        return BookingDetailsScreen(bookingId: bookingId);
      },
    ),

    // Settings
    GoRoute(path: '/settings', builder: (_, __) => SettingsScreen()),
    GoRoute(path: '/settings/payment', builder: (_, __) => PaymentInfoSetupScreen()),
    GoRoute(path: '/settings/ical', builder: (_, __) => ICalSyncSettingsScreen()),

    // PUBLIC EMBED ROUTE (no auth required!)
    GoRoute(
      path: '/embed/:unitId',
      builder: (context, state) {
        final unitId = state.pathParameters['unitId']!;
        return EmbedCalendarScreen(unitId: unitId);
      },
    ),
  ],
);
```

---

## 🎨 GRID CALENDAR WIDGET - Detaljni Plan

### **Layout Struktura:**

```
+------------------------------------------+
|  < October 2025 >          [Month View] |  <- Header
+------------------------------------------+
| Legend: 🟢 Available  🔴 Booked  ⚫ Blocked |
+------------------------------------------+
|  Mon  Tue  Wed  Thu  Fri  Sat  Sun      |  <- Week days
+---+---+---+---+---+---+---+---+---+-----+
|   | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | ... |
|   |60€|60€|60€|60€|80€|80€|   |   |     |
|   |🟢 |🟢 |🔴 |🔴 |🔴 |🟢 |🟢 |🟢 |     |
+---+---+---+---+---+---+---+---+---+-----+
|  9|10 |11 |12 |13 |14 |15 |16 |...      |
|80€|60€|60€|60€|60€|60€|80€|80€|         |
|🟢 |🟢 |⚫ |⚫ |🟢 |🟢 |🟢 |🟢 |         |
+---+---+---+---+---+---+---+---+---+-----+
| Selected: 5.10 - 8.10 (3 nights)        |
| Total Price: 220€                       |
| Advance (20%): 44€                      |
| [Reserve Now]                           |
+------------------------------------------+
```

### **Features:**

1. **Multi-select:**
   - Klikneš start date → highlight
   - Držiš i povučeš → range select
   - Ili klikneš start, pa end date

2. **Color Coding:**
   - 🟢 Zelena (#4CAF50) - Available
   - 🔴 Crvena (#EF5350) - Booked (ne može se kliknuti)
   - ⚫ Siva (#9E9E9E) - Blocked (ne može se kliknuti)

3. **Price Display:**
   - Prikazuje cijenu u svakom dostupnom kvadratiću
   - Ako nema daily price → koristi base price

4. **Real-time Calculation:**
   - Dok selektuješ dane → live update total cijene
   - Prikazuje broj noći
   - Prikazuje 20% avans

5. **Responsive:**
   - Mobile: Swipe horizontally između mjeseci
   - Desktop: Grid view sa scroll

---

## 📧 EMAIL NOTIFICATIONS - Plan

### **1. Nova Rezervacija (Owner)**
**Trigger:** Guest kreira booking
**Template:**
```
Subject: Nova rezervacija - [Unit Name]

Poštovani,

Primili ste novu rezervaciju:

Guest: [Guest Name]
Email: [Guest Email]
Telefon: [Guest Phone]

Check-in: [Date]
Check-out: [Date]
Broj noći: [Nights]

Ukupna cijena: [Total]€
Avans (20%): [Advance]€

Status: Čeka uplatu avansa

[View Booking Details]

---
Rab Booking System
```

### **2. Potvrda Rezervacije (Guest)**
**Trigger:** Guest kreira booking
**Template:**
```
Subject: Potvrda rezervacije - [Unit Name]

Poštovani [Guest Name],

Hvala što ste odabrali naš smještaj!

DETALJI REZERVACIJE:
Objekat: [Property Name]
Smještaj: [Unit Name]
Check-in: [Date] od 15:00h
Check-out: [Date] do 10:00h
Broj noći: [Nights]

PLAĆANJE:
Ukupna cijena: [Total]€
Avans (20%): [Advance]€
Ostatak (na licu mjesta): [Remaining]€

PODACI ZA UPLATU AVANSA:
Primatelj: [Account Holder]
IBAN: [IBAN]
Poziv na broj: [Reference]
Iznos: [Advance]€

Molimo uplatite avans u roku od 3 dana kako biste potvrdili rezervaciju.

Dokaz o uplati pošaljite na: [Owner Email]

Vidimo se uskoro!
```

---

## 📋 IMPLEMENTACIONI PLAN - Korak po Korak

### **FAZA 1: Priprema i Čišćenje** (1 dan)

#### **Korak 1.1: Backup projekta**
```bash
# Već urađeno - imaš backup
cd C:\Users\W10\dusko1
# rab_booking je vec backup
```

#### **Korak 1.2: Kreirati novi branch**
```bash
cd rab_booking
git checkout -b refactor/saas-booking-system
git add .
git commit -m "feat: Start refactoring to SaaS booking system"
```

#### **Korak 1.3: Brisanje feature foldera**
```bash
# Obrisati nepotrebne feature-e
rm -rf lib/features/home
rm -rf lib/features/search
rm -rf lib/features/favorites
rm -rf lib/features/admin
rm -rf lib/features/support
rm -rf lib/features/about
rm -rf lib/features/design_system_demo

# Obrisati nepotrebne txt fajlove
rm DetailsPage.txt
rm SearchMapPage.txt
rm SearchPage.txt
rm "flutterflow booking flow.txt"
rm "flutterflow booking flow sa calendarom.txt"
rm "plan za implementaciju rab booking.txt"
```

#### **Korak 1.4: Očistiti dependencies**
```yaml
# pubspec.yaml - ukloniti:
# flutter_stripe
# table_calendar (ako koristimo custom grid)
```

#### **Korak 1.5: Git commit**
```bash
git add .
git commit -m "chore: Remove unused features (home, search, favorites, admin, support)"
```

---

### **FAZA 2: Supabase Schema Update** (pola dana)

#### **Korak 2.1: Kreirati migration file**
```bash
# U Supabase Dashboard → SQL Editor
# Ili lokalno: supabase/migrations/20251024_saas_schema.sql
```

#### **Korak 2.2: Execute SQL**
1. Otvori Supabase Dashboard
2. SQL Editor → New Query
3. Copy-paste SQL iz "SUPABASE SCHEMA IZMJENE" sekcije
4. Execute

#### **Korak 2.3: Verifikacija**
- Provjeri da li su nove tabele kreirane: `units`, `daily_prices`, `blocked_dates`, `payment_info`
- Provjeri da li su RLS policies aktivne
- Testiraj policy: pokušaj da insert property sa drugim owner_id (treba da failuje)

---

### **FAZA 3: Refaktorisanje Auth** (1 dan)

#### **Korak 3.1: Pojednostaviti registration**
Već ima `register_screen.dart`, samo ukloniti nepotrebna polja.

#### **Korak 3.2: Update router**
```dart
// lib/core/config/router.dart
// Promijeniti initialLocation sa '/' na '/dashboard'
final router = GoRouter(
  initialLocation: '/dashboard',
  redirect: (context, state) {
    final isLoggedIn = supabase.auth.currentUser != null;

    if (!isLoggedIn && state.location != '/login' && state.location != '/register') {
      return '/login';
    }

    // Ako je logged in i ide na /login → redirect to /dashboard
    if (isLoggedIn && (state.location == '/login' || state.location == '/register')) {
      return '/dashboard';
    }

    return null;
  },
  routes: [
    // Auth routes
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => RegisterScreen()),

    // Dashboard (default)
    GoRoute(path: '/dashboard', builder: (_, __) => DashboardScreen()),

    // ... ostale routes
  ],
);
```

#### **Korak 3.3: Git commit**
```bash
git add .
git commit -m "refactor: Simplify auth and update router"
```

---

### **FAZA 4: Properties & Units Management** (2 dana)

#### **Korak 4.1: Kreirati Unit model**
```dart
// lib/features/properties/data/models/unit.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'unit.freezed.dart';
part 'unit.g.dart';

@freezed
class Unit with _$Unit {
  const factory Unit({
    required String id,
    required String propertyId,
    required String name,
    @Default(2) int maxGuests,
    required double basePrice,
    String? description,
    @Default([]) List<String> images,
    @Default(true) bool isActive,
    String? icalUrl,
    DateTime? lastIcalSync,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Unit;

  factory Unit.fromJson(Map<String, dynamic> json) => _$UnitFromJson(json);
}
```

#### **Korak 4.2: Units Repository**
```dart
// lib/features/properties/data/repositories/units_repository.dart
class UnitsRepository {
  final SupabaseClient _supabase;

  Future<List<Unit>> getUnitsByProperty(String propertyId) async {
    final response = await _supabase
        .from('units')
        .select()
        .eq('property_id', propertyId)
        .order('name');

    return (response as List).map((json) => Unit.fromJson(json)).toList();
  }

  Future<Unit> createUnit(Unit unit) async {
    final response = await _supabase
        .from('units')
        .insert(unit.toJson())
        .select()
        .single();

    return Unit.fromJson(response);
  }

  Future<void> updateUnit(String id, Map<String, dynamic> updates) async {
    await _supabase
        .from('units')
        .update(updates)
        .eq('id', id);
  }

  Future<void> deleteUnit(String id) async {
    await _supabase
        .from('units')
        .delete()
        .eq('id', id);
  }
}
```

#### **Korak 4.3: Units List Screen**
Kreirati UI za prikaz i upravljanje jedinicama.

#### **Korak 4.4: Git commit**
```bash
git add .
git commit -m "feat: Add units management (model, repository, screens)"
```

---

### **FAZA 5: Grid Calendar Widget** (3 dana) ⭐ **PRIORITET**

Ovo je NAJVAŽNIJI DIO aplikacije!

#### **Korak 5.1: Kreirati CalendarDay model**
```dart
// lib/features/calendar/data/models/calendar_day.dart
@freezed
class CalendarDay with _$CalendarDay {
  const factory CalendarDay({
    required DateTime date,
    required DayStatus status,
    double? price,
    String? bookingId,
  }) = _CalendarDay;

  factory CalendarDay.fromJson(Map<String, dynamic> json) =>
      _$CalendarDayFromJson(json);
}

enum DayStatus {
  available,   // 🟢
  booked,      // 🔴
  blocked,     // ⚫
}
```

#### **Korak 5.2: Calendar Repository**
```dart
// lib/features/calendar/data/repositories/calendar_repository.dart
class CalendarRepository {
  Future<List<CalendarDay>> getCalendarData(String unitId, DateTime month) async {
    // 1. Get all days in month
    final days = _generateMonthDays(month);

    // 2. Fetch bookings for this month
    final bookings = await _supabase
        .from('bookings')
        .select()
        .eq('unit_id', unitId)
        .gte('check_in', month.toIso8601String().split('T')[0])
        .lte('check_out', DateTime(month.year, month.month + 1, 0).toIso8601String().split('T')[0]);

    // 3. Fetch blocked dates
    final blocked = await _supabase
        .from('blocked_dates')
        .select()
        .eq('unit_id', unitId)
        .gte('blocked_from', month.toIso8601String().split('T')[0])
        .lte('blocked_to', DateTime(month.year, month.month + 1, 0).toIso8601String().split('T')[0]);

    // 4. Fetch daily prices
    final prices = await _supabase
        .from('daily_prices')
        .select()
        .eq('unit_id', unitId)
        .gte('date', month.toIso8601String().split('T')[0])
        .lte('date', DateTime(month.year, month.month + 1, 0).toIso8601String().split('T')[0]);

    // 5. Map status for each day
    return days.map((date) {
      // Check if booked
      final isBooked = bookings.any((b) =>
        date.isAfter(b['check_in']) && date.isBefore(b['check_out'])
      );

      // Check if blocked
      final isBlocked = blocked.any((b) =>
        date.isAfter(b['blocked_from']) && date.isBefore(b['blocked_to'])
      );

      // Get price
      final priceData = prices.firstWhere(
        (p) => p['date'] == date.toIso8601String().split('T')[0],
        orElse: () => null,
      );

      return CalendarDay(
        date: date,
        status: isBooked ? DayStatus.booked :
                isBlocked ? DayStatus.blocked :
                DayStatus.available,
        price: priceData?['price'] ?? unit.basePrice,
      );
    }).toList();
  }
}
```

#### **Korak 5.3: Grid Calendar Widget**
```dart
// lib/features/calendar/presentation/widgets/grid_calendar_widget.dart
class GridCalendarWidget extends ConsumerStatefulWidget {
  final String unitId;
  final Function(List<DateTime> selectedDates, double totalPrice)? onDatesSelected;

  @override
  ConsumerState<GridCalendarWidget> createState() => _GridCalendarWidgetState();
}

class _GridCalendarWidgetState extends ConsumerState<GridCalendarWidget> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  Set<DateTime> _selectedDates = {};

  @override
  Widget build(BuildContext context) {
    final calendarData = ref.watch(calendarDataProvider(widget.unitId, _focusedMonth));

    return calendarData.when(
      data: (days) => Column(
        children: [
          // Header
          _buildHeader(),

          // Legend
          _buildLegend(),

          // Calendar Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, // 7 days per week
                childAspectRatio: 1,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                return CalendarDayCell(
                  day: day,
                  isSelected: _selectedDates.contains(day.date),
                  onTap: () => _handleDayTap(day),
                );
              },
            ),
          ),

          // Price Summary
          if (_selectedDates.isNotEmpty)
            _buildPriceSummary(days),
        ],
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  void _handleDayTap(CalendarDay day) {
    if (day.status != DayStatus.available) return;

    setState(() {
      if (_rangeStart == null) {
        // Prvi klik - start date
        _rangeStart = day.date;
        _selectedDates = {day.date};
      } else if (_rangeEnd == null) {
        // Drugi klik - end date
        _rangeEnd = day.date;

        // Populate all dates between start and end
        _selectedDates = _generateDateRange(_rangeStart!, _rangeEnd!);

        // Notify parent
        final totalPrice = _calculateTotalPrice();
        widget.onDatesSelected?.call(_selectedDates.toList(), totalPrice);
      } else {
        // Treći klik - reset
        _rangeStart = day.date;
        _rangeEnd = null;
        _selectedDates = {day.date};
      }
    });
  }

  double _calculateTotalPrice() {
    // Calculate total price for selected dates
    // ...
  }
}
```

#### **Korak 5.4: Calendar Day Cell**
```dart
// lib/features/calendar/presentation/widgets/calendar_day_cell.dart
class CalendarDayCell extends StatelessWidget {
  final CalendarDay day;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (day.status) {
      case DayStatus.available:
        backgroundColor = isSelected
          ? Colors.green[300]!
          : Colors.green[100]!;
        textColor = Colors.green[900]!;
        break;
      case DayStatus.booked:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[900]!;
        break;
      case DayStatus.blocked:
        backgroundColor = Colors.grey[300]!;
        textColor = Colors.grey[700]!;
        break;
    }

    return GestureDetector(
      onTap: day.status == DayStatus.available ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: isSelected ? Colors.green[700]! : Colors.grey[400]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.date.day}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            if (day.price != null && day.status == DayStatus.available)
              Text(
                '${day.price!.toStringAsFixed(0)}€',
                style: TextStyle(
                  fontSize: 11,
                  color: textColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

#### **Korak 5.5: Git commit**
```bash
git add .
git commit -m "feat: Implement grid calendar widget with multi-select"
```

---

### **FAZA 6: Booking Flow** (2 dana)

#### **Korak 6.1: Update Booking Model**
Dodati `advanceAmount`, `paymentStatus`, `source` fields.

#### **Korak 6.2: Booking Form Screen**
UI za unos guest info (ime, email, telefon).

#### **Korak 6.3: Booking Confirmation Screen**
Prikazuje payment info (IBAN, iznos, referencu).

#### **Korak 6.4: Email Notifications**
Supabase Edge Function za slanje email-ova.

#### **Korak 6.5: Git commit**
```bash
git add .
git commit -m "feat: Implement booking flow with payment instructions"
```

---

### **FAZA 7: iCal Sync** (2 dana)

#### **Korak 7.1: iCal Parser Service**
Koristi `icalendar_parser` package.

#### **Korak 7.2: Sync Service**
Fetch iCal → Parse → Create bookings.

#### **Korak 7.3: UI za iCal Setup**
Owner unosi iCal URL, klikne "Sync Now".

#### **Korak 7.4: Git commit**
```bash
git add .
git commit -m "feat: Add iCal sync for Booking.com integration"
```

---

### **FAZA 8: Embed Widget** (1 dan)

#### **Korak 8.1: Embed Calendar Screen**
Standalone screen bez navigation, minimal UI.

#### **Korak 8.2: Routing**
Public route `/embed/:unitId` (bez auth check).

#### **Korak 8.3: Testing**
Deploy na Vercel, testiraj u iframe-u.

#### **Korak 8.4: Git commit**
```bash
git add .
git commit -m "feat: Create embeddable calendar widget"
```

---

### **FAZA 9: Dashboard & Pricing** (1-2 dana)

#### **Korak 9.1: Dashboard Screen**
Today's overview, upcoming bookings, quick actions.

#### **Korak 9.2: Pricing Management**
UI za postavljanje cijena po danima.

#### **Korak 9.3: Git commit**
```bash
git add .
git commit -m "feat: Add dashboard and pricing management"
```

---

### **FAZA 10: Testing & Deployment** (1 dan)

#### **Korak 10.1: Manual Testing**
- Test auth flow
- Test property & unit creation
- Test calendar (zelena/crvena/siva boje)
- Test booking flow
- Test iCal sync
- Test embed widget

#### **Korak 10.2: Web Build**
```bash
flutter build web --release
```

#### **Korak 10.3: Deploy to Vercel**
```bash
git add .
git commit -m "build: Production build for web"
git push origin refactor/saas-booking-system
```
Vercel će automatski deployovati.

#### **Korak 10.4: Embed na jasko-rab.com**
```html
<!-- apartman2.php -->
<iframe
  src="https://rab-booking.vercel.app/embed/unit-id-123"
  width="100%"
  height="700px"
  frameborder="0">
</iframe>
```

---

## ✅ SUCCESS CRITERIA

Projekat je uspješan kada:

1. ✅ Owner može da se registruje i uloguje
2. ✅ Owner može da kreira properties i units
3. ✅ Owner vidi grid kalendar sa bojama (zelena/crvena/siva)
4. ✅ Owner može da blokira datume (siva boja)
5. ✅ Owner može da postavi cijene po danima
6. ✅ Guest otvara embed widget i vidi kalendar
7. ✅ Guest može da selektuje dane i vidi ukupnu cijenu
8. ✅ Guest može da rezerviše i dobije payment info
9. ✅ Owner dobije email sa novom rezervacijom
10. ✅ Owner može da sync-uje iCal sa Booking.com
11. ✅ iCal rezervacije se prikazuju kao crvene na kalendaru

---

## 📊 ESTIMACIJA VREMENA

| Faza | Opis | Trajanje |
|------|------|----------|
| 1 | Čišćenje projekta | 1 dan |
| 2 | Supabase schema | 0.5 dana |
| 3 | Auth refactor | 1 dan |
| 4 | Properties & Units | 2 dana |
| 5 | Grid Calendar Widget | 3 dana |
| 6 | Booking Flow | 2 dana |
| 7 | iCal Sync | 2 dana |
| 8 | Embed Widget | 1 dan |
| 9 | Dashboard & Pricing | 2 dana |
| 10 | Testing & Deployment | 1 dan |
| **UKUPNO** | | **15.5 dana** |

**Realno vrijeme (sa bugfixing):** 18-20 dana (3-4 sedmice)

---

## 📝 NAPOMENE

### **Faza po faza pristup:**
Ne treba odmah sve implementirati. Možemo ići inkrementalno:

1. **MVP (Week 1):** Auth + Properties + Units + Basic Calendar
2. **Week 2:** Grid Calendar + Booking Flow
3. **Week 3:** iCal Sync + Embed Widget
4. **Week 4:** Dashboard + Pricing + Polish

### **Git Strategy:**
- Svaka faza = novi commit
- Veliki feature = novi branch
- Nakon svakog commit-a → push to GitHub
- Vercel automatski deploya svaki push

### **Testiranje:**
- Manual testing nakon svake faze
- Test na različitim devices (mobile, tablet, desktop)
- Test embed widget u iframe-u na jasko-rab.com

---

## 🚀 SLEDEĆI KORACI

1. **Pregledaj ovaj dokument** i reci da li se slažeš sa planom
2. **Odaberi prioritet:**
   - MVP prvo (samo najvažnije feature-e)?
   - Ili full implementation odjednom?
3. **Potvrdimo tech stack:**
   - Supabase (preporuka) ili Firebase?
4. **Krećemo sa implementacijom!**

---

**Dokument kreirao:** Claude Code AI
**Datum:** 24. Oktobar 2025
**Verzija:** 1.0
