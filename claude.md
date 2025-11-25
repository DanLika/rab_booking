# Claude Code - Project Documentation

Ova dokumentacija pomaže budućim Claude Code sesijama da razumiju kritične dijelove projekta i izbjegnu greške.

---

## 📘 PROJECT OVERVIEW

**RabBooking** je booking management platforma za property owner-e (apartmani, vile, kuće) na otoku Rabu, Hrvatska. Projekt se sastoji od:

1. **Owner Dashboard** (Flutter Web) - Admin panel za upravljanje nekretninama, jedinicama, rezervacijama, cijenama
2. **Booking Widget** (Flutter Web - Embeddable) - Javni widget koji vlasnici ugrađuju na svoje web stranice
3. **Backend** (Firebase) - Firestore database + Cloud Functions za business logiku

### Tehnologije
- **Frontend**: Flutter 3.35.7 (Web fokus - iOS/Android planned)
- **State Management**: Riverpod 2.x
- **Backend**: Firebase (Firestore, Cloud Functions, Storage, Auth)
- **Payments**: Stripe Connect
- **Architecture**: Feature-first structure, Repository pattern

### Trenutni Fokus
- ✅ Owner dashboard je **production-ready**
- ✅ Booking widget radi i embeduje se na web stranice
- 🚧 Mobile apps (iOS/Android) su **planirani** ali nisu prioritet
- ⚠️ **Hot reload i restart ne rade nikad** - to je normalno za Flutter Web dev

---

## 🎯 KRITIČNE SEKCIJE - NE MIJENJAJ BEZ RAZLOGA!

### 🏢 Unified Unit Hub - Centralni Management za Jedinice

**Status**: ✅ FINALIZED  
**File**: `lib/features/owner_dashboard/presentation/screens/unified_unit_hub_screen.dart`

#### Svrha
Master-Detail pattern za upravljanje smještajnim jedinicama. Owner može:
- Pregledati sve svoje jedinice (filter po property-u)
- Urediti osnovne podatke jedinice
- Upravljati cijenama kroz kalendar
- Konfigurisati booking widget
- Postaviti napredne opcije (email verification, tax, iCal)

#### Tabbed Interface
1. **Osnovni Podaci** - Pregled i editovanje informacija o jedinici (⚠️ needs work)
2. **Cjenovnik** - Upravljanje cijenama i sezonama (✅ **FINALIZED - USE AS REFERENCE!**)
3. **Widget** - Podešavanje izgleda widgeta (⚠️ needs work)
4. **Napredne** - Advanced settings (⚠️ needs work)

#### ⚠️ KRITIČNO - Cjenovnik Tab Je FROZEN!

**DO NOT:**
- ❌ Mijenjaj Cjenovnik tab kod bez eksplicitnog user zahtjeva
- ❌ Refaktorisaj postojeći kod
- ❌ Dodaj nove feature-e
- ❌ Mijenjaj layout logiku ili state management
- ❌ Mijenjaj error handling

**ONLY IF:**
- ✅ User **eksplicitno** traži bug fix
- ✅ User **eksplicitno** traži novu funkcionalnost
- ✅ User kaže "Nemoj reći da je finalizovano, želim ovo da se promijeni"

**KORISTI GA KAO REFERENTNU IMPLEMENTACIJU:**

Cjenovnik tab pokazuje kako treba implementirati responsive layout, loading/error states, i widget integration:
```dart
// Pattern za druge tabove:

// 1. Loading state
if (_isLoadingXXX) {
  return Center(
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
    ),
  );
}

// 2. Error state
if (_xxxError != null) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
        SizedBox(height: 16),
        Text('Greška: $_xxxError'),
        ElevatedButton(
          onPressed: _loadXXXData,
          child: Text('Pokušaj ponovo'),
        ),
      ],
    ),
  );
}

// 3. Responsive layout
final isDesktop = MediaQuery.of(context).size.width >= 1200;
final maxWidth = isDesktop ? 1000.0 : double.infinity;

return Container(
  constraints: BoxConstraints(maxWidth: maxWidth),
  padding: EdgeInsets.all(16),
  child: YourTabContentWidget(...),
);
```

**Responsive Breakpoints:**
- Desktop: `>= 1200px` → fixed 1000px width, centered
- Tablet: `600-1199px` → full width minus padding
- Mobile: `< 600px` → full width minus smaller padding

**Razlozi Zašto Je Frozen:**
1. Kompletno testiran - responsive layout radi na svim screen sizes ✅
2. User je zadovoljan - potvrdio da radi kako treba ✅
3. Referentna implementacija - pokazuje kako treba implementirati ostale tabove ✅

**AKO User Prijavi Problem:**
1. Prvo provjeri da li problem NIJE u Cjenovnik tabu
2. Možda je problem u drugom tabu, navigation-u, ili selectedUnit state-u?
3. Ako problem JE u Cjenovnik tabu → pitaj za screenshot/video i reproducible steps
4. Pitaj da li user želi da se izmijeni "finalizirani" tab
5. **NE MIJENJAJ** dok user ne potvrdi!

**Key Files:**
- `unified_unit_hub_screen.dart` - Main hub screen (~700-800 lines)
- `price_list_calendar_widget.dart` - Calendar component (~1500 lines, NE DIRAJ!)

**Commit**: `90d24f3` (2025-11-22)

---

### 🧙 Unit Creation Wizard - Multi-Step Form

**Status**: ✅ PRODUCTION READY  
**Folder**: `lib/features/owner_dashboard/presentation/screens/unit_wizard/`

#### Svrha
7-step wizard za kreiranje/editovanje smještajnih jedinica. Owner kreira novu jedinicu kroz guided flow sa validacijom na svakom koraku.

#### Structure
```
unit_wizard/
├── unit_wizard_screen.dart           # Main orchestrator
├── state/
│   ├── unit_wizard_state.dart        # Wizard state model (freezed)
│   ├── unit_wizard_provider.dart     # Riverpod state notifier
│   └── unit_wizard_provider.g.dart   # Generated
└── steps/
    ├── step_1_basic_info.dart        # Name, Description, Max Guests
    ├── step_2_capacity.dart          # Bedrooms, Bathrooms, etc.
    ├── step_3_pricing.dart           # Price per night, Cleaning fee, Tax
    ├── step_4_availability.dart      # Booking settings, Min/Max nights
    ├── step_5_photos.dart            # Photo upload
    ├── step_6_widget.dart            # Widget customization
    └── step_7_advanced.dart          # Review & Publish
```

#### Key Features
- ✅ **Progress Indicator** - Shows current step (1/7) sa visual progress bar
- ✅ **Form Validation** - Svaki step validira prije nego što dozvoli next
- ✅ **State Persistence** - Wizard state se čuva u provider, survives hot reload
- ✅ **Navigation** - Back/Next buttons, can jump to any completed step
- ✅ **Publish Logic** - Final step kreira unit + widget settings + initial pricing
- ✅ **Edit Mode** - Može editovati postojeće jedinice (loads current data)
- ✅ **Responsive** - Radi na mobile, tablet, desktop

#### ⚠️ KRITIČNO - Publish Flow

**NE MIJENJAJ** publish flow bez razumijevanja šta se dešava:
```dart
// unitWizardNotifier.publishUnit() kreira 3 Firestore dokumenta:

// 1. Unit document
await unitRepository.createUnit(unit);

// 2. Widget settings document
await widgetSettingsRepository.createWidgetSettings(settings);

// 3. Initial pricing document (base price za sve datume)
await pricingRepository.setInitialPricing(unitId, basePrice);

// 4. Navigate to unit hub
context.go('/owner/units/$unitId');
```

Ako izostane bilo koji od ova 3 koraka, jedinica neće raditi kako treba!

**DO NOT:**
- ❌ Mijenjaj wizard flow bez razumijevanja state transitions
- ❌ Uklanjaj state persistence logiku
- ❌ Mijenjaj publish redoslijed (mora biti unit → settings → pricing)
- ❌ Skip-uj bilo koji step u production modu

**ALWAYS:**
- ✅ Testiraj cijeli flow od step 1 do 7
- ✅ Provjeri Firestore nakon publish-a (3 dokumenta moraju postojati)
- ✅ Testiraj Edit mode (loadExistingUnit mora raditi)

**Routes:**
```dart
/owner/units/wizard        // New unit
/owner/units/wizard/:id    // Edit existing unit
```

**Key Files:**
- `unit_wizard_screen.dart` - Main orchestrator (lines 1-400)
- `unit_wizard_provider.dart` - State management (lines 1-300)
- All `step_*.dart` files - Individual step screens

**Commits:**
- `8f57efe` (2025-11-22) - Initial wizard structure
- `4a12bba` (2025-11-22) - Steps 5-7 implementation
- `c0b5ca5` (2025-11-22) - Complete publish logic
- `90d24f3` (2025-11-22) - Unit Hub wizard integration

---

### 📅 Timeline Calendar - Gantt Prikaz Rezervacija

**Status**: ✅ STABILAN  
**File**: `lib/features/owner_dashboard/presentation/screens/owner_timeline_calendar_screen.dart`

#### Svrha
Timeline (Gantt) prikaz svih rezervacija owner-a kroz vrijeme. Prikazuje:
- Sve jedinice vertikalno (jedne ispod drugih)
- Datume horizontalno (scroll left/right)
- Rezervacije kao blokove sa bojama po statusu
- Drag & drop za kreiranje/editovanje rezervacija

#### Key Features
- ✅ **Diagonal Gradient Background** - Teče od top-left prema bottom-right
- ✅ **Z-Index Layering** - Cancelled bookings (60% opacity) iza, confirmed (100%) ispred
- ✅ **Transparent Headers** - Date headers propuštaju parent gradient
- ✅ **Toolbar Layout** - Month selector centriran, navigation ikone desno
- ✅ **Responsive** - Radi na svim screen sizes

#### ⚠️ KRITIČNO - Z-Index Booking Layering

**Problem koji je riješen:**
Kada owner ima cancelled rezervaciju i novu confirmed rezervaciju za iste datume, kalendar ih prikazuje jednu preko druge. Trebalo je jasno prikazati confirmed (zelenu) rezervaciju ISPRED cancelled.

**Rješenje:**
Z-Index layering putem **sort + opacity**:
```dart
// 1. Sort bookings by status priority (kontroliše rendering order)
final sortedBookings = [...bookings]..sort((a, b) {
  // Priority: cancelled (0) < pending (1) < confirmed (2)
  final priorityA = a.status == BookingStatus.cancelled ? 0 : (a.status == BookingStatus.pending ? 1 : 2);
  final priorityB = b.status == BookingStatus.cancelled ? 0 : (b.status == BookingStatus.pending ? 1 : 2);
  return priorityA.compareTo(priorityB);
});

// 2. Render u sorted order (cancelled FIRST = bottom layer)
for (final booking in sortedBookings) {
  // Cancelled bookings dobijaju 60% opacity
  Opacity(
    opacity: booking.status == BookingStatus.cancelled ? 0.6 : 1.0,
    child: TimelineBookingBlock(booking: booking),
  );
}

// Rezultat:
// - Cancelled bookings render first (bottom layer, 60% opacity)
// - Confirmed bookings render last (top layer, 100% opacity)
// - Active bookings "izlaze" iznad cancelled bookings ✅
```

**DO NOT:**
- ❌ Mijenjaj sort order logiku - cancelled MORA render first!
- ❌ Mijenjaj opacity vrijednost (0.6 je user approved!)
- ❌ Vraćaj complex overlap detection (eliminisan je sa razlogom!)
- ❌ Pokušavaj selective opacity (samo overlapping dio) - previše kompleksno!

#### ⚠️ KRITIČNO - Diagonal Gradient & Transparent Headers

**Gradient Background:**
```dart
body: Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,          // ↘️ DIAGONAL (ne vertical!)
      end: Alignment.bottomRight,        // ↘️ DIAGONAL
      colors: isDark
        ? [veryDarkGray, mediumDarkGray]
        : [veryLightGray, Colors.white],
      stops: [0.0, 0.3],
    ),
  ),
  child: ...,
)
```

**Transparent Headers:**
```dart
// Date headers MORAJU biti transparent da se vidi gradient
TimelineMonthHeader:
  color: Colors.transparent,  // ✅

TimelineDayHeader:
  color: isToday 
    ? primary.withAlpha(0.2) 
    : Colors.transparent,  // ✅
```

**DO NOT:**
- ❌ Vraćaj header backgrounds na `theme.cardColor` - moraju biti transparent!
- ❌ Mijenjaj gradient direkciju na vertical (`topCenter → bottomCenter`)
- ❌ Mijenjaj stops vrijednosti `[0.0, 0.3]` - fade je na gornjih 30%

#### ⚠️ KRITIČNO - Toolbar Layout

**Month Selector MORA biti centriran:**
```dart
Row(
  children: [
    const Spacer(),                    // ← Push selector to center
    IconButton(chevron_left),          // ← Previous BEFORE selector
    InkWell(monthSelector),            // ← Centered
    IconButton(chevron_right),         // ← Next AFTER selector
    const Spacer(),                    // ← Balance centering
    // Action buttons (right-aligned)
  ],
)
```

**DO NOT:**
- ❌ Mijenjaj navigation arrow pozicije (mora biti oko month selektora!)
- ❌ Uklanjaj bilo koji Spacer (oba su potrebna za perfect centering)

**Key Files:**
- `owner_timeline_calendar_screen.dart` - Main screen
- `timeline_calendar_widget.dart` - Calendar grid component
- `timeline_booking_block.dart` - Individual booking block
- `timeline_date_header.dart` - Date header components

**Commits:**
- `ca59494` (2025-11-23) - Diagonal gradient
- `ce5e979` (2025-11-24) - UI improvements
- `c6af6ab` (2025-11-22) - Z-index layering

---

### 📖 Owner Bookings Screen - Rezervacije Management

**Status**: ✅ STABILAN  
**File**: `lib/features/owner_dashboard/presentation/screens/owner_bookings_screen.dart`

#### Svrha
Lista svih rezervacija owner-a sa filter i search opcijama. Owner može:
- Pregledati sve rezervacije (card ili table view)
- Filtrirati po statusu (pending/confirmed/cancelled/completed)
- Pretraživati po imenu gosta ili booking ID-u
- Approve/Reject/Cancel/Complete rezervacije
- Pregledati detalje rezervacije

#### Key Features
- ✅ **2x2 Button Grid** za pending bookings (Approve, Reject, Details, Cancel)
- ✅ **Responsive Row Layout** za ostale statuse (Details, Cancel/Complete)
- ✅ **Button Colors Match Badges** - Approve=green, Reject=red
- ✅ **Separate Skeleton Loaders** - Card view i Table view imaju RAZLIČITE skeletone
- ✅ **Instant UI Refresh** - Provider invalidation za real-time updates

#### ⚠️ KRITIČNO - Button Layouts

**Pending bookings MORAJU imati 2x2 grid:**
```dart
if (booking.status == BookingStatus.pending) {
  return Column(
    children: [
      Row(
        children: [
          Expanded(child: approveButton),   // Green
          SizedBox(width: 8),
          Expanded(child: rejectButton),    // Red
        ],
      ),
      SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: detailsButton),   // Grey
          SizedBox(width: 8),
          Expanded(child: cancelButton),    // Grey
        ],
      ),
    ],
  );
}
```

**Other statuses koriste responsive row:**
```dart
// Confirmed/Cancelled/Completed bookings
return Row(
  children: [
    Expanded(child: detailsButton),
    SizedBox(width: 8),
    Expanded(child: cancelOrCompleteButton),
  ],
);
```

**Button Styling:**
- **Approve**: Green (#66BB6A) - matches Confirmed badge color
- **Reject**: Red (#EF5350) - matches Cancelled badge color
- **Details/Cancel**: Minimalist grey (light: grey[50], dark: grey[850])

**DO NOT:**
- ❌ Vraćaj vertikalni button layout (jedan ispod drugog)
- ❌ Mijenjaj button boje (moraju match-ovati badge colors!)
- ❌ Uklanjaj `Expanded` wrappers (potrebni za ravnomjerno raspoređivanje)

#### ⚠️ KRITIČNO - Skeleton Loaders

**Card View i Table View imaju RAZLIČITE skeletone:**
```dart
loading: () {
  if (viewMode == BookingsViewMode.table) {
    return BookingTableSkeleton();  // Imitira DataTable (header + 5 rows)
  } else {
    return Column(
      children: List.generate(
        5,
        (index) => BookingCardSkeleton(),  // Imitira booking card layout
      ),
    );
  }
}
```

**DO NOT:**
- ❌ Koristi isti skeleton za oba view-a
- ❌ Prikazuj običan CircularProgressIndicator (loš UX)
- ✅ `BookingTableSkeleton` imitira stvarnu table strukturu
- ✅ `BookingCardSkeleton` imitira stvarni card layout (header, guest info, dates, payment, buttons)

#### ⚠️ KRITIČNO - Provider Invalidation

**Instant UI refresh zahtijeva invalidaciju PRIJE update-a:**
```dart
// Primjer: Confirm booking
Future<void> _confirmBooking(String bookingId) async {
  await repository.confirmBooking(bookingId);
  
  // Instant UI refresh (MORA biti ovim redoslijedom!)
  ref.invalidate(allOwnerBookingsProvider);  // 1. Invalidate all
  ref.invalidate(ownerBookingsProvider);     // 2. Invalidate filtered
  
  // UI se automatski update-uje sa novim podacima ✅
}
```

**DO NOT:**
- ❌ Invalidiraj samo `ownerBookingsProvider` (incomplete refresh)
- ❌ Pozivaj `setState()` umjesto provider invalidation (ne radi!)
- ✅ Primjeni isti pattern na SVE akcije (approve, reject, cancel, complete)

#### Status Filter

**Prikazuj SAMO aktivne statuse:**
```dart
items: BookingStatus.values.where((s) {
  return s == BookingStatus.pending ||
         s == BookingStatus.confirmed ||
         s == BookingStatus.cancelled ||
         s == BookingStatus.completed;
}).map((status) => DropdownMenuItem(...))
```

**DO NOT:**
- ❌ Prikazuj sve statuse (uključujući checkedIn, checkedOut, inProgress, blocked)
- ✅ Samo 4 statusa se aktivno koriste u aplikaciji

**Key Files:**
- `owner_bookings_screen.dart` - Main screen (~1300 lines)
- `bookings_table_view.dart` - Table view component
- `booking_card_owner.dart` - Card view component
- `skeleton_loader.dart` - BookingCardSkeleton i BookingTableSkeleton

**Commit**: `31938c9` (2025-11-19)

---

## 🎨 VAŽNI STANDARDI & PATTERNS

### Gradient Standardization - Purple-Fade Pattern (THEME-AWARE)

**Datum**: 2025-11-24  
**Status**: ✅ COMPLETD - All gradients standardized  
**Commits**: `f524445`, `7d075d8`

#### Novi Standard (OBAVEZAN!)

**Svi gradijenti u aplikaciji MORAJU koristiti ovaj pattern:**
```dart
final theme = Theme.of(context);
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.colorScheme.primary,
        theme.colorScheme.primary.withValues(alpha: 0.7),
      ],
    ),
  ),
)
```

**Karakteristike:**
- **Direction**: Dijagonalni (topLeft → bottomRight), NE vertikalni!
- **Colors**: Start = full opacity primary, End = 70% opacity primary fade
- **Theme-Aware**: Uses `Theme.of(context)` za automatic light/dark mode adaptation

#### Impacted Files (20+)

**Phase 1 - Main Screens & Components (14 files):**
- `common_app_bar.dart` - App bar gradient
- `owner_app_drawer.dart` - Drawer header gradient
- `booking_details_dialog.dart` - Dialog gradient
- All iCal screens (4) - Body gradients
- `unit_wizard/unit_form_screen.dart` - Form gradient
- `property_form_screen.dart`, `unit_pricing_screen.dart` - Form gradients
- `calendar_top_toolbar.dart`, `price_list_calendar_widget.dart` - Calendar gradients
- `unified_unit_hub_screen.dart` - AppBar + info card (2 locations)
- `stripe_connect_setup_screen.dart` - Body gradient

**Phase 2 - Calendar Dialogs & Buttons (6 files):**
- `owner_timeline_calendar_screen.dart` - FAB gradient wrapper
- `edit_booking_dialog.dart` - Save button gradient
- `booking_create_dialog.dart` - Create button gradient
- `calendar_filters_panel.dart` - Dialog header gradient
- `unit_future_bookings_dialog.dart` - Dialog header gradient
- `calendar_search_dialog.dart` - Dialog header gradient

#### Button Gradient Pattern

**Kada koristiš gradient unutar button-a:**
```dart
Builder(
  builder: (context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      child: ElevatedButton(
        onPressed: _handleAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
        ),
        child: Text('Action'),
      ),
    );
  },
)
```

**Zašto Builder?** Ako widget nema direktan pristup BuildContext-u za theme (npr. u `actions` listi dialog-a), wrap-uj u Builder.

#### DO NOT:
- ❌ **NE VRAĆAJ** stare gradijente sa `AppColors.primary + AppColors.authSecondary`
- ❌ **NE KORISTI** hardcoded boje kao `Color(0xFF6B4CE6)` ili `Color(0xFF4A90E2)`
- ❌ **NE KORISTI** vertikalne gradijente (`topCenter → bottomCenter`)
- ❌ **NE KORISTI** `.withOpacity()` - uvijek koristi `.withValues(alpha: X)`
- ❌ **NE PRESKAČI** `begin` i `end` parametre - mora biti dijagonalno!

#### ALWAYS:
- ✅ **UVIJEK KORISTI** `theme.colorScheme.primary` za boje
- ✅ **UVIJEK KORISTI** dijagonalni pravac: `topLeft → bottomRight`
- ✅ **UVIJEK KORISTI** alpha fade: `primary.withValues(alpha: 0.7)` za kraj
- ✅ **UVIJEK DOBIJ** theme sa `Theme.of(context)` na početku build metode
- ✅ **KORISTI Builder** widget ako nemaš pristup BuildContext-u za theme

#### IF USER REPORTS:
- "Gradijent ne izgleda dobro" → Provjeri da koristi theme-aware pattern
- "Boje ne odgovaraju dizajnu" → Provjeri da je dijagonalni pravac (topLeft→bottomRight)
- "Gradijent je preteško tamno/svetlo" → Provjeri alpha vrednost (mora biti 0.7)
- "Compile error: undefined 'theme'" → Dodaj `final theme = Theme.of(context);` ili koristi Builder

#### IF YOU NEED TO ADD NEW GRADIENT:
1. Kopiraj pattern gore (sa `theme.colorScheme.primary` + `alpha: 0.7`)
2. Koristi dijagonalni pravac (`topLeft → bottomRight`)
3. Dodaj `final theme = Theme.of(context);` na početku build metode ili koristi Builder

---

### Input Field Styling Standardization

**Datum**: 2025-11-24  
**Status**: ✅ COMPLETED - All wizard inputs standardized  
**Commit**: `b8ed9fd`

#### Problem Koji Je Riješen

Wizard input fields nisu bili konzistentni sa Cjenovnik tab styling-om. `InputDecorationHelper` je koristio custom colored borders umjesto theme defaults.

#### Novi Standard

**Svi input text fields u wizard-u koriste isti pattern:**
```dart
InputDecoration(
  labelText: 'Label',
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  filled: true,
  fillColor: theme.cardColor,
)
```

**Key Changes u `InputDecorationHelper`:**
1. ✅ Removed `enabledBorder` - bilo je custom outline color sa 30% alpha
2. ✅ Removed `focusedBorder` - bilo je custom primary color sa width 2
3. ✅ Removed `errorBorder` - bilo je custom error color
4. ✅ Removed `focusedErrorBorder` - bilo je custom error color sa width 2
5. ✅ Kept only base `border` sa `borderRadius: 12`

**Rezultat:**
- Flutter theme system sada upravlja svim border state-ima automatski
- Enabled state: Uses theme's default enabled border color
- Focused state: Uses theme's default primary color
- Error state: Uses theme's default error color
- Sve border boje adaptiraju se na light/dark theme automatski

#### DO NOT:
- ❌ **NE VRAĆAJ** custom colored borders (enabledBorder, focusedBorder, etc.)
- ❌ **NE MIJENJAJ** borderRadius bez konzultacije - mora biti 12!
- ❌ **NE DODAVAJ** custom border colors - theme defaults rade perfektno!

#### ALWAYS:
- ✅ **UVIJEK KORISTI** `InputDecorationHelper.buildDecoration()` za wizard fields
- ✅ **UVIJEK ČUVAJ** borderRadius 12 (matching Cjenovnik tab)
- ✅ **UVIJEK DOZVOLI** theme-u da upravlja border bojama

#### IF USER REPORTS:
- "Input borders izgledaju drugačije" → Provjeri da koristi `InputDecorationHelper`
- "Borders nisu vidljivi u dark mode" → Provjeri da NEMA custom colors
- "Focus state ne radi" → Provjeri da theme default focusedBorder nije overridden

**Impacted Files:**
- `lib/core/utils/input_decoration_helper.dart` - Helper class
- All unit wizard step files (`step_1_basic_info.dart`, etc.) - Use helper

---

### Responsive Form Layout Pattern (LayoutBuilder)

**Datum**: 2025-11-25
**Status**: ✅ STANDARD - Koristi na svim form screen-ima

#### Pattern

Koristi `LayoutBuilder` sa 500px breakpoint za responsive Row/Column layout:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 500) {
      // Mobile: vertikalni layout
      return Column(children: [field1, SizedBox(height: 16), field2]);
    }
    // Desktop: horizontalni layout
    return Row(children: [
      Expanded(child: field1),
      SizedBox(width: 16),
      Expanded(child: field2),
    ]);
  },
)
```

#### Gdje se koristi
- `property_form_screen.dart` - Name+Slug, Location+Address
- `step_1_basic_info.dart` - Name+Slug
- `step_2_capacity.dart` - Bedrooms+Bathrooms, MaxGuests+AreaSqm

#### Pravila
- ✅ Breakpoint: **500px** (konzistentno)
- ✅ Spacing: **16px** (width za Row, height za Column)
- ✅ Koristi `Expanded` u Row-u (ne fixed width)
- ✅ `crossAxisAlignment: CrossAxisAlignment.start` za Row

---

### Widget Advanced Settings - Cjenovnik Styling Applied

**Datum**: 2025-11-24
**Status**: ✅ COMPLETED - Advanced Settings kartice imaju identičan styling kao Cjenovnik tab
**Commit**: `a88fd99`

#### Svrha

Primenjen **IDENTIČAN styling** iz Cjenovnik tab-a na sve tri kartice u Advanced Settings screen-u:
1. **Email Verification Card**
2. **Tax & Legal Disclaimer Card**
3. **iCal Export Card**

#### Design Elements

**1. 5-Color Diagonal Gradient (topRight → bottomLeft)**
```dart
gradient: LinearGradient(
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
  colors: isDark
    ? [Color(0xFF1A1A1A), Color(0xFF1F1F1F), Color(0xFF242424), Color(0xFF292929), Color(0xFF2D2D2D)]
    : [Color(0xFFF0F0F0), Color(0xFFF2F2F2), Color(0xFFF5F5F5), Color(0xFFF8F8F8), Color(0xFFFAFAFA)],
  stops: [0.0, 0.125, 0.25, 0.375, 0.5],
)
```

**2. Container Structure**
- BorderRadius 24
- Border width 1.5
- AppShadows elevation 1
- ClipRRect za gradient

**3. Minimalist Icons**
- Padding 8
- Primary color 12% alpha background
- Size 18
- BorderRadius 8

**4. ExpansionTile Styling**
- `initiallyExpanded: enabled` (otvoren ako je enabled)
- Title: `theme.textTheme.titleMedium` sa `fontWeight.bold`
- Subtitle: `theme.textTheme.bodySmall` sa conditional color

**5. Responsive Padding**
- Mobile: 16px
- Desktop: 20px

#### DO NOT:
- ❌ **NE MIJENJAJ** styling bez eksplicitnog user zahtjeva - mora biti IDENTIČNO kao Cjenovnik!
- ❌ **NE POVEĆAVAJ** icon size ili padding
- ❌ **NE KORISTI** hardcoded padding bez isMobile check-a

#### ALWAYS:
- ✅ Gradient: 5-color, stops [0.0, 0.125, 0.25, 0.375, 0.5]
- ✅ BorderRadius 24, border width 1.5, AppShadows elevation 1
- ✅ Minimalist icons: padding 8, size 18, borderRadius 8
- ✅ Responsive padding: `isMobile ? 16 : 20`

**Modified Files:**
1. `email_verification_card.dart` - Email verification settings card
2. `tax_legal_disclaimer_card.dart` - Tax/legal disclaimer settings card
3. `ical_export_card.dart` - iCal export settings card
4. `widget_advanced_settings_screen.dart` - Main advanced settings screen

---

### Booking Widget - Deposit Slider & Payment Methods

**Datum**: 2025-11-17  
**Status**: ✅ COMPLETED - Unified deposit + hidden payment methods  
**Commit**: `1bc0122`

#### Problem 1 - Deposit Slider Konfuzija

**Prije:** Stripe i Bank Transfer imali odvojene slidere za deposit percentage.  
**Problem:** Widget **UVIJEK** koristio 20% deposit, ignorisao settings.

**Rješenje:** Zajednički global deposit slider za SVE payment metode.

#### Model Changes

**Dodano novo top-level polje:**
```dart
class WidgetSettings {
  final int globalDepositPercentage; // Global deposit % (applies to all payment methods)
  
  // Migration u fromFirestore():
  globalDepositPercentage: data['global_deposit_percentage'] ??
      (data['stripe_config'] != null
          ? (data['stripe_config']['deposit_percentage'] ?? 20)
          : 20),
}
```

**Migracija:** Ako `global_deposit_percentage` ne postoji → uzima iz `stripe_config.deposit_percentage` → fallback 20%.

#### Widget Usage
```dart
// booking_widget_screen.dart
final depositPercentage = _widgetSettings?.globalDepositPercentage ?? 20;
```

**Rezultat:**
- ✅ Widget koristi `globalDepositPercentage` za SVE payment metode
- ✅ Stripe, Bank Transfer, Pay on Arrival - svi koriste isti deposit
- ✅ Automatska migracija postojećih settings-a

#### Problem 2 - Payment Methods u "No Payment" Modu

**Prije:** `bookingPending` mod prikazivao payment metode koje ne rade.  
**Rješenje:** Sakrivene payment metode, prikazan info card umjesto.

#### UI Logic
```dart
// Payment Methods - SAMO za bookingInstant mode
if (_selectedMode == WidgetMode.bookingInstant) {
  _buildPaymentMethodsSection(),
}

// Info card - SAMO za bookingPending mode
if (_selectedMode == WidgetMode.bookingPending) {
  _buildInfoCard(
    title: 'Rezervacija bez plaćanja',
    message: 'U ovom modu gosti mogu kreirati rezervaciju, ali NE mogu platiti online...',
    color: theme.colorScheme.tertiary, // Green
  ),
}
```

**Rezultat:**
- ✅ `bookingPending` mod: Info card (zeleni) umjesto payment metoda
- ✅ Validacija radi SAMO za `bookingInstant` mod
- ✅ Nema konfuzije - owner zna šta se dešava

#### DO NOT:
- ❌ **NE KORISTI** `stripeConfig.depositPercentage` u widgetu
- ❌ **NE PRIKAZUJ** payment metode u `bookingPending` modu
- ❌ **NE MIJENJAJ** migraciju logiku (fallback je kritičan!)

#### ALWAYS:
- ✅ Widget koristi `globalDepositPercentage`, ne config-specific deposit
- ✅ Payment methods conditional: `if (_selectedMode == WidgetMode.bookingInstant)`
- ✅ Global deposit se kopira u oba config-a pri save-u (backward compatibility)

**Key Files:**
- `lib/features/widget/domain/models/widget_settings.dart` - Model
- `lib/features/owner_dashboard/presentation/screens/widget_settings_screen.dart` - UI
- `lib/features/widget/presentation/screens/booking_widget_screen.dart` - Widget logic

---

## 🐛 NEDAVNI BUG FIX-EVI (Post 20.11.2025)

### Timeline Calendar - Pill Bar Auto-Open Fix

**Datum**: 2025-11-18-19  
**Commit**: `925accb`

#### Problem (Dva Povezana Bug-a)

**Bug #1 - Auto-Open Nakon Refresh:**
- Pill bar se automatski otvarao nakon refresh-a, čak i kada ga je user zatvorio
- Root cause: `if (_checkIn != null && _checkOut != null)` → pokazuje pill bar čim datumi postoje
- Missing: Flag da tracka da li je user zatvorio pill bar

**Bug #2 - Chicken-and-Egg:**
- Prvi fix je uveo novi bug: Pill bar se NIJE prikazivao nakon selekcije datuma
- Root cause: `_hasInteractedWithBookingFlow` se postavljao samo na Reserve button klik
- Problem: Reserve button je UNUTAR pill bar-a → pill bar nije vidljiv → ne može kliknuti Reserve!

#### Rješenje

**Implementirana 2 State Flags sa localStorage persistence:**
```dart
bool _pillBarDismissed = false;              // Track if user clicked X
bool _hasInteractedWithBookingFlow = false;   // Track if user showed interest
```

**Display Logic:**
```dart
if (_checkIn != null &&
    _checkOut != null &&
    _hasInteractedWithBookingFlow &&  // User showed interest
    !_pillBarDismissed)                // User didn't dismiss
  _buildFloatingDraggablePillBar(...);
```

**Ključna Izmjena - Date Selection = Interaction:**
```dart
setState(() {
  _checkIn = start;
  _checkOut = end;
  _hasInteractedWithBookingFlow = true;  // ← Date selection IS interaction
  _pillBarDismissed = false;             // Reset dismissed flag
});
```

**Rezultat:**
- ✅ Selektuj datume → Pill bar se PRIKAŽE
- ✅ Klikni X → Pill bar se SAKRIJE (datumi ostaju)
- ✅ Refresh → Pill bar OSTAJE sakriven
- ✅ Selektuj NOVE datume → Pill bar se PONOVO prikaže

---

### Advanced Settings - Save & Switch Toggle Fix

**Datum**: 2025-11-17  
**Commits**: `22a485d`, `4ed5aa5`

#### Problem 1 - Settings Se Nisu Čuvali

**Root Cause A - Novi Config Gubi Postojeće Podatke:**
```dart
// ❌ LOŠE - Kreira NOVI config sa samo jednim poljem
final updatedSettings = currentSettings.copyWith(
  emailConfig: EmailNotificationConfig(
    requireEmailVerification: _requireEmailVerification, // Samo ovo!
    // enabled, sendBookingConfirmation, sendPaymentReceipt → DEFAULTI!
  ),
);
```

**Rješenje:** Koristi `.copyWith()` za nested config-e:
```dart
// ✅ DOBRO - Koristi copyWith() da SAČUVA postojeće podatke
final updatedSettings = currentSettings.copyWith(
  emailConfig: currentSettings.emailConfig.copyWith(
    requireEmailVerification: _requireEmailVerification,
    // enabled, sendBookingConfirmation → OSTAJU NEPROMENJENI ✅
  ),
);
```

**Root Cause B - Cached State u Parent Screen:**
```dart
// Widget Settings screen koristi CACHED podatke iz memorije
final settings = WidgetSettings(
  emailConfig: _existingSettings?.emailConfig ?? ...,  // ← CACHE!
);
```

**Rješenje:** Invaliduj provider nakon povratka iz Advanced Settings:
```dart
onTap: () async {
  await Navigator.push(context, MaterialPageRoute(...));
  
  if (mounted) {
    ref.invalidate(widgetSettingsProvider);  // ← Force refresh
    _loadSettings();
  }
}
```

#### Problem 2 - Switch Toggles Se Vraćali Natrag

**Root Cause - Smart Reload Loop:**
```dart
// ❌ LOŠE - Reload se triggeruje NAKON SVAKOG klika!
if (!_isSaving) {
  final needsReload = firestoreValue != localStateValue;
  if (needsReload) {
    _loadSettings(settings); // ← Poziva se NAKON klika, vrati switch!
  }
}
```

**Rješenje:** Zamijenjen smart reload sa single initialization:
```dart
bool _isInitialized = false;

if (!_isInitialized && !_isSaving) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      _loadSettings(settings);
      setState(() => _isInitialized = true);
    }
  });
}
```

**Rezultat:**
- ✅ Settings se učitavaju SAMO JEDNOM kada se screen otvori
- ✅ NE reload-uju se tokom user edit-a (switch klikovi sada rade!)
- ✅ Save invalidira provider kako treba

#### Key Lessons

1. **UVIJEK koristi `.copyWith()` za nested config objekte** - konstruktor postavlja DEFAULT vrednosti!
2. **Provider invalidation je KRITIČNA** - kada saveš podatke → invaliduj provider!
3. **Cached state u StatefulWidget-ima** mora biti re-fetched nakon child screen izmjena
4. **Smart reload pattern je opasan** - može se triggerovati TOKOM user edit-a, ne samo nakon povratka

---

### Same-Day Turnover Bookings (Bug #77)

**Datum**: 2025-11-16  
**Commit**: `0c056e3`

#### Problem

Korisnici nisu mogli da selektuju dan koji je checkOut postojeće rezervacije za checkIn nove rezervacije. Ovo sprečava standardnu hotel praksu "turnover day".

**Primjer:**
- Postojeća rezervacija: checkIn = 10.01, checkOut = 15.01
- Nova rezervacija: checkIn = 15.01 ← **BLOKIRANO** ❌

#### Rješenje

**File:** `functions/src/atomicBooking.ts`  
**Line 194:** Promijenjen operator u conflict detection query
```typescript
// PRIJE (❌):
.where("check_out", ">=", checkInDate);
// Problem: checkOut = 15 blokira checkIn = 15

// POSLIJE (✅):
.where("check_out", ">", checkInDate);
// Rješenje: checkOut = 15 DOZVOLJAVA checkIn = 15
```

**Rezultat:**
- ✅ checkOut = 15.01 sada dozvoljava checkIn = 15.01
- ✅ Samo PRAVA preklapanja se odbijaju (checkOut > checkIn)
- ✅ Industry standard - same-day turnover je moguć

**Conflict Logic:**
```typescript
// Konflikt postoji kada:
existing.check_in < new.check_out  AND  existing.check_out > new.check_in
```

---

### Property Deletion & Card UI Improvements

**Datum**: 2025-11-16  
**Commit**: `1723600`

#### Problem 1 - Property Deletion Nije Radio

**Root Cause:** `ref.invalidate()` SAMO osvježava listu iz Firestore-a, NE briše podatke!
```dart
// ❌ PRIJE (broken):
if (confirmed == true && context.mounted) {
  try {
    ref.invalidate(ownerPropertiesProvider);  // Invalidacija BEZ brisanja!
    // ... snackbar
  }
}

// ✅ POSLIJE (fixed):
if (confirmed == true && context.mounted) {
  try {
    // 1. PRVO obriši iz Firestore
    await ref.read(ownerPropertiesRepositoryProvider).deleteProperty(propertyId);
    
    // 2. PA ONDA invaliduj provider
    ref.invalidate(ownerPropertiesProvider);
    
    // 3. Prikaži success
    ErrorDisplayUtils.showSuccessSnackBar(...);
  }
}
```

**Rezultat:** Property se sada stvarno briše iz Firestore-a! ✅

#### Problem 2 - Property Card UI

**Redesignirane komponente:**

**Publish Toggle:**
- Published: zeleni gradient + zelena border + bold tekst ✅
- Hidden: crveni gradient + crvena border + bold tekst ✅
- Container sa padding, borderRadius 12px

**Action Buttons:**
- Edit button: purple gradient + purple border + purple ikona ✅
- Delete button: red gradient + red border + red ikona ✅
- `_StyledIconButton` widget sa InkWell ripple effect

**Image Corners:**
- ClipRRect sa borderRadius samo na gornjim ivicama (16px)

**Rezultat:** Profesionalniji i konzistentniji izgled property card-ova! ✅

---

## 📚 DODATNE REFERENCE SEKCIJE

### Additional Services (Dodatni Servisi)

**Status**: ✅ STABILAN - Nedavno migrirano (2025-11-16)

#### Osnovne Informacije
- **Provider**: `additionalServicesRepositoryProvider` (PLURAL!)
- **Svrha**: Owner-i definišu dodatne usluge (parking, doručak, transfer)
- **Guest Widget**: `additional_services_widget.dart` prikazuje servise u booking flow-u

#### Ključni Constraint-ovi
- ❌ **NE VRAĆAJ** na stari SINGULAR repository (`additionalServiceRepositoryProvider` - OBRISAN!)
- ✅ **KORISTI** `unitAdditionalServicesProvider(unitId)` za fetch
- ✅ **Client-side filter**: `.where((s) => s.isAvailable)` za guest widget
- ✅ **Soft delete**: Query provjerava `deleted_at == null`

**Key Files:**
- `lib/shared/repositories/additional_services_repository.dart` - Interface
- `lib/shared/repositories/firebase/firebase_additional_services_repository.dart` - Implementation
- `lib/features/widget/presentation/providers/additional_services_provider.dart` - Guest widget provider

---

### Analytics Screen (Analitika & Izvještaji)

**Status**: ✅ STABILAN - Optimizovan (2025-11-16)

#### Osnovne Informacije
- **File**: `analytics_screen.dart` (~1114 lines)
- **Svrha**: Performance tracking za owner-e (revenue, bookings, occupancy)
- **Components**: Metric cards, Revenue chart, Bookings chart, Top properties, Widget analytics

#### Ključni Constraint-ovi
- ❌ **NE DODAVAJ** duplicate Firestore pozive (eliminirani su!)
- ❌ **NE MIJENJAJ** chart komponente bez poznavanja fl_chart paketa
- ✅ **Performance optimizacija**: Unit-to-property map caching (50% manje poziva)
- ✅ **Widget analytics**: Tracking bookings po source (widget/admin/direct/booking.com/airbnb)

**Key Files:**
- `lib/features/owner_dashboard/presentation/screens/analytics_screen.dart` - Main screen
- `lib/features/owner_dashboard/data/firebase/firebase_analytics_repository.dart` - Data fetching
- `lib/features/owner_dashboard/domain/models/analytics_summary.dart` - Data model

---

### Notification Settings

**Status**: ✅ STABILAN - Theme support (2025-11-16)

#### Osnovne Informacije
- **File**: `notification_settings_screen.dart` (~675 lines)
- **Svrha**: Owner postavke za email/push/SMS notifikacije
- **Categories**: Bookings, Payments, Calendar, Marketing

#### Ključni Constraint-ovi
- ❌ **NE HARDCODUJ** boje - koristi `theme.colorScheme.*`
- ✅ **Custom Switch Theme**: White/Black thumbs (user request)
- ✅ **Theme Support**: 40+ AppColors zamenjeno sa theme-aware bojama
- ✅ Master switch + 4 kategorije sa 3 kanala svaka (email, push, sms)

**Key Files:**
- `lib/features/owner_dashboard/presentation/screens/notification_settings_screen.dart` - Main screen
- `lib/shared/models/notification_preferences_model.dart` - Data model

---

### iCal Integration (Import/Export)

**Status**: ✅ STABILAN - Master-Detail pattern (2025-11-16)

#### Osnovne Informacije
- **Folder**: `lib/features/owner_dashboard/presentation/screens/ical/`
- **Svrha**: Import rezervacija sa Booking.com/Airbnb, Export iCal URL-ova

#### Screen-ovi
1. **Import** - `ical_sync_settings_screen.dart` - Dodaj/uredi iCal feed-ove
2. **Export List** - `ical_export_list_screen.dart` - Master screen sa listom jedinica
3. **Export Detail** - `ical_export_screen.dart` - iCal URL za konkretnu jedinicu (REQUIRES params!)
4. **Guide** - `ical_guide_screen.dart` - Uputstvo za setup

#### Ključni Constraint-ovi
- ❌ **NE OTVORI** Export Screen sa `context.go()` (mora `context.push()` sa extra params!)
- ❌ **NE MIJENJAJ** null-safety validation u route builder-u
- ✅ **Master-Detail pattern**: Export List (no params) → Export Screen (requires unit + propertyId)
- ✅ **Horizontal gradient**: Svi 4 screen-a koriste left→right gradient

**Route Builder (KRITIČNO!):**
```dart
GoRoute(
  path: OwnerRoutes.icalExport,
  builder: (context, state) {
    if (state.extra == null) return const NotFoundScreen();
    
    final extra = state.extra as Map<String, dynamic>;
    final unit = extra['unit'] as UnitModel?;
    final propertyId = extra['propertyId'] as String?;
    
    if (unit == null || propertyId == null) return const NotFoundScreen();
    
    return IcalExportScreen(unit: unit, propertyId: propertyId);
  },
)
```

---

### Change Password Screen

**Status**: ✅ STABILAN - Refaktorisan (2025-11-16)

#### Osnovne Informacije
- **File**: `change_password_screen.dart` (~675 lines)
- **Svrha**: Owner-i mijenjaju lozinku (zahtijeva trenutnu lozinku)
- **Features**: Re-autentikacija, password strength indicator, stay logged in

#### Ključni Constraint-ovi
- ❌ **NE HARDCODUJ** boje - koristi `theme.colorScheme.*`
- ❌ **NE MIJENJAJ** validation logiku bez testiranja
- ✅ **Full dark/light theme support** - 12+ l10n stringova
- ✅ **Premium UI**: AuthBackground, GlassCard, PremiumInputField, GradientAuthButton

---

### Dashboard Overview Tab

**Status**: ✅ STABILAN - Theme-aware (2025-11-16)

#### Osnovne Informacije
- **File**: `dashboard_overview_tab.dart` (~509 lines)
- **Svrha**: Landing page nakon login-a - statistike i recent aktivnosti
- **Components**: 6 stat cards, recent activity list, refresh indicator

#### Ključni Constraint-ovi
- ❌ **NE KVARI** `_createThemeGradient()` helper - automatski prilagođava boje za dark mode!
- ❌ **NE MIJENJAJ** responsive logic - Mobile/Tablet/Desktop breakpoints su ispravni
- ❌ **NE MIJENJAJ** animation delays - Stagger je namjerno (0-500ms)
- ✅ **Theme-aware gradients**: `_createThemeGradient()` automatski zatamnjuje 30% u dark mode
- ✅ **Performance**: Future.wait za paralelno učitavanje providers

**Responsive Design:**
- Mobile (<600px): 2 cards per row
- Tablet (600-899px): 3 cards per row
- Desktop (≥900px): Fixed 280px width

---

### Edit Profile Screen

**Status**: ✅ STABILAN - Refaktorisan (2025-11-16)

#### Osnovne Informacije
- **File**: `edit_profile_screen.dart` (~708 lines)
- **Svrha**: Owner profil + company details (za fakture i komunikaciju)
- **Features**: 13 controllers, profile image upload, dual save (profile + company)

#### Ključni Constraint-ovi
- ❌ **NE DODAVAJ** instagram/linkedin u SocialLinks (model ima SAMO website + facebook!)
- ❌ **NE MIJENJAJ** controllers lifecycle - svi moraju biti disposed!
- ✅ **Dual save**: UserProfile + CompanyDetails se čuvaju odvojeno
- ✅ **SocialLinks**: SAMO website i facebook (2 fields)
- ✅ **Company Details**: ExpansionTile sa 9 fields (name, tax, vat, iban, swift, address)

---

### CommonAppBar

**Status**: ✅ STABILAN - Blur/sliver efekti uklonjeni (2025-11-16)

#### Osnovne Informacije
- **File**: `common_app_bar.dart` (~92 lines)
- **Svrha**: Jedini app bar komponent u aplikaciji
- **Features**: Gradient background, no blur, no scroll effects

#### Ključni Constraint-ovi
- ❌ **NE KREIRAJ** nove sliver/blur/premium app bar komponente
- ❌ **NE VRAĆAJ** `CommonGradientAppBar` ili `PremiumAppBar` (OBRISANI!)
- ❌ **NE DODAVAJ** blur/scroll efekte
- ✅ **Simple non-sliver AppBar** wrapper sa gradient pozadinom
- ✅ **Koristi se u 20+ screen-ova** - mijenjaj EKSTRA oprezno!

**Why No Blur?**
```dart
scrolledUnderElevation: 0,           // Blokira blur
surfaceTintColor: Colors.transparent, // Blokira tint
```

---

## ⚙️ KONFIGURACIONI FAJLOVI & ROUTING

### Router Configuration

**File**: `lib/core/config/router_owner.dart`

#### Key Routes
```dart
/owner/overview              // Dashboard overview tab
/owner/units                 // Unit Hub (redirects to hub)
/owner/units/hub             // Unified Unit Hub
/owner/units/wizard          // Create new unit
/owner/units/wizard/:id      // Edit existing unit
/owner/calendar/timeline     // Timeline calendar
/owner/bookings              // Bookings list
/owner/analytics             // Analytics screen
/owner/integrations/ical/import        // iCal import
/owner/integrations/ical/export-list   // iCal export list
/owner/integrations/ical/export        // iCal export detail (REQUIRES params!)
/owner/profile/edit                     // Edit profile
/owner/profile/notifications           // Notification settings
```

#### isLoading Check (KRITIČNO!)

**Line 186-196:**
```dart
if (isLoading) {
  return null; // Stay on current route until auth completes
}
```

**Razlog:** Sprječava "Register → Login → Dashboard" flash nakon registracije. Router mora čekati da auth state se stabilizuje prije redirect-a.

**DO NOT:**
- ❌ Uklanjaj `isLoading` null check
- ❌ Redirect-uj prije nego što je auth operacija završena

---

### Repository Providers

**File**: `lib/shared/providers/repository_providers.dart`

#### Pattern
```dart
@riverpod
RepositoryType repositoryName(RepositoryNameRef ref) {
  return RepositoryImplementation();
}
```

**DO NOT:**
- ❌ Koristi singleton pattern
- ✅ Mora biti provider (Riverpod će handle-ovati lifecycle)

---

## 🎯 QUICK REFERENCE GUIDE

### NIKADA NE MIJENJAJ (bez user zahtjeva):

1. ❌ **Cjenovnik tab u Unit Hub** - frozen, koristi ga kao referencu!
2. ❌ **Z-index sorting logiku** u Timeline Calendar - cancelled mora render first!
3. ❌ **Wizard publish flow** - 3 Firestore docs (unit, settings, pricing)
4. ❌ **Input field borderRadius** - mora biti 12px!
5. ❌ **Gradient direkciju** - mora biti `topLeft → bottomRight`!
6. ❌ **Provider invalidation pattern** - cache-first, invalidate POSLIJE save-a!
7. ❌ **Button layouts u Bookings screen** - pending mora biti 2x2 grid!
8. ❌ **Skeleton loading logic** - Card vs Table view imaju različite skeletone!
9. ❌ **iCal Export route builder** - null-safety validation je kritična!
10. ❌ **isLoading check u router-u** - sprječava flash nakon registracije!

### UVIJEK KORISTI:

1. ✅ `theme.colorScheme.*` umjesto AppColors
2. ✅ `InputDecorationHelper.buildDecoration()` za input fields
3. ✅ `.copyWith()` za nested config update-e (NIKADA konstruktor!)
4. ✅ `ref.invalidate()` POSLIJE repository poziva (ne prije!)
5. ✅ `Builder` widget ako nemaš pristup BuildContext-u za theme
6. ✅ `mounted` check prije async navigation
7. ✅ Dijagonalni gradient: `topLeft → bottomRight` sa alpha fade 0.7
8. ✅ BorderRadius 12px za input fields, 24px za advanced settings kartice
9. ✅ `context.push()` sa extra params za iCal Export Screen
10. ✅ Provider invalidation za SVE booking akcije (approve, reject, cancel)

### PRIJE NEGO ŠTO MIJENJAJ:

1. 🔍 **Pročitaj ovu dokumentaciju** - možda je već dokumentovano!
2. 🔍 **Provjeri commit history** - od 20.11.2025 naovamo
3. 🔍 **Testiraj sa `flutter analyze`** - mora biti 0 issues
4. 🔍 **Pitaj korisnika** - ako nešto izgleda čudno, PITAJ prije nego što mijenjaj!
5. 🔍 **Provjeri da li je "frozen"** - Cjenovnik tab, Unit Hub, itd.
6. 🔍 **Razumiješ li constraint-ove?** - DO NOT / ALWAYS sekcije su kritične!

---

## 🚨 COMMON PITFALLS (Česte Greške)

### 1. "Hot reload ne radi"

**Ovo je normalno za Flutter Web!** Hot reload ima ograničen support:
- ✅ Radi za: Promjene u `build()` metodama, styling promjene
- ❌ NE radi za: `initState` promjene, Provider/state promjene, nove importove

**Rješenje:** Koristi Hot Restart (Shift+R ili R u terminalu), ili potpuno restart-uj app.

### 2. "Provider ne refresh-uje podatke"

**Problem:** FutureProvider NE re-fetch-uje automatski bez invalidacije!

**Rješenje:**
```dart
// ✅ DOBRO - Invaliduj provider nakon izmjene
await repository.updateData(...);
ref.invalidate(dataProvider);

// ❌ LOŠE - Samo setState() bez invalidacije
await repository.updateData(...);
setState(() {}); // Provider i dalje ima stare podatke!
```

### 3. "Nested config se ne čuva"

**Problem:** Konstruktor postavlja DEFAULT vrijednosti za sva polja!

**Rješenje:**
```dart
// ✅ DOBRO - Koristi .copyWith() za nested objekte
final updated = currentSettings.copyWith(
  emailConfig: currentSettings.emailConfig.copyWith(
    requireEmailVerification: false,
  ),
);

// ❌ LOŠE - Gubi sve ostale fields u emailConfig-u!
final updated = currentSettings.copyWith(
  emailConfig: EmailNotificationConfig(
    requireEmailVerification: false,
  ),
);
```

### 4. "Gradient ne izgleda dobro u dark mode"

**Problem:** Hardcoded boje ne adaptiraju se na theme!

**Rješenje:**
```dart
// ✅ DOBRO - Theme-aware gradient
final theme = Theme.of(context);
gradient: LinearGradient(
  colors: [
    theme.colorScheme.primary,
    theme.colorScheme.primary.withValues(alpha: 0.7),
  ],
)

// ❌ LOŠE - Hardcoded boje
gradient: LinearGradient(
  colors: [Color(0xFF6B4CE6), Color(0xFF4A90E2)],
)
```

### 5. "Routing sa params ne radi"

**Problem:** `context.go()` ne može slati complex params!

**Rješenje:**
```dart
// ✅ DOBRO - context.push() sa extra
context.push(
  OwnerRoutes.icalExport,
  extra: {
    'unit': unit,
    'propertyId': propertyId,
  },
);

// ❌ LOŠE - context.go() bez params (NotFoundScreen!)
context.go(OwnerRoutes.icalExport);
```

---

## 📞 KADA TREBAŠ POMOĆ

### Ako naiđeš na bug:

1. ✅ Provjeri ovu dokumentaciju - možda je već dokumentovan fix
2. ✅ Provjeri commit history - možda je nedavno riješen
3. ✅ Provjeri `flutter analyze` - možda je očigledan error
4. ✅ Reproducaj bug - tačni steps za reprodukciju
5. ✅ **PITAJ korisnika** - ne pokušavaj da "pogađaš" šta je problem!

### Ako user traži novu funkcionalnost:

1. ✅ Provjeri da li mijenja "frozen" section (Cjenovnik, Unit Hub)
2. ✅ Provjeri constraint-ove - možda postoje arhitekturne odluke
3. ✅ Predloži alternativu ako postoji bolji način
4. ✅ **OBJASNI rizike** ako feature zahtijeva breaking changes

### Ako nešto izgleda čudno:

1. ✅ **PITAJ prije nego što mijenjaj!**
2. ✅ Možda je namjerno tako urađeno (vidi dokumentaciju)
3. ✅ Možda je user request (npr. white/black switch thumbs)
4. ✅ Možda je arhitekturna odluka (npr. no blur u CommonAppBar)

---

**Last Updated**: 2025-11-25  
**Version**: 2.0 (Optimizovana verzija)  
**Original Size**: 278.3k chars  
**Current Size**: ~50k chars (82% reduction)  
**Focus**: Unit Hub, Wizard, Calendar, Bookings + Standards & Bug Fixes

---

**REMEMBER**: Ova dokumentacija je živi dokument. Kada radiš važne izmjene, update-uj relevantu sekciju!