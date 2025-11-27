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

## 🔧 CLAUDE CODE ALATI & SLASH COMMANDS

### MCP Serveri

**Datum instalacije**: 2025-11-27 (Updated)

| Server | Svrha | Status |
|--------|-------|--------|
| **dart-flutter** | Live Dart analiza, Flutter widgets, pub.dev info | ✅ Aktivan |
| **firebase** | Firestore operacije, Auth, Cloud Functions direktno iz Claude | ✅ Aktivan |
| **github** | Issue/PR management, repo operacije | ✅ Aktivan |
| **memory** | Pamćenje konteksta između Claude Code sesija | ✅ Aktivan |
| **context7** | Up-to-date dokumentacija za bilo koju biblioteku | ✅ Aktivan |
| **playwright** | Browser automation (za React/Next.js projekte, NE Flutter) | ✅ Aktivan |
| **stripe** | Stripe API operacije - customers, payments, subscriptions, refunds | ✅ Aktivan |
| **flutter-inspector** | Screenshots, AI-optimized errors, Hot Restart, Dynamic Tools | ✅ Aktivan |
| **mobile-mcp** | Mobile testing - Android (ADB) i iOS (Simulator) automation | ✅ Aktivan |
| **supabase** | Supabase DB operacije (za buduće projekte) | ⏳ Čeka config |

**Napomena:** Puppeteer/Playwright NE rade sa Flutter Web jer Flutter renderuje na canvas. Zato koristimo **flutter-inspector** za visual debugging.

**Flutter Inspector MCP** - Visual debugging za Flutter (UNIQUE features):
```
"Napravi screenshot aplikacije"        → view_screenshot
"Pokaži greške u aplikaciji"           → get_app_errors (AI-optimized format)
"Hot restart aplikaciju"               → hot_restart_flutter
"Pokaži detalje view-a"                → get_view_details (screen size, pixel ratio)
```

**⚠️ VAŽNO:** Flutter Inspector zahtijeva da Flutter app radi u **debug mode** na portu 8181. Pokreni app sa:
```bash
flutter run -d chrome --web-port=8181
```

#### dart-flutter vs flutter-inspector - Komplementarni Sistem

| Zadatak | dart-flutter | flutter-inspector |
|---------|--------------|-------------------|
| Code analysis | ✅ `analyze_files` | ❌ |
| Hot Reload | ✅ `hot_reload` | ❌ |
| Hot Restart | ❌ | ✅ `hot_restart_flutter` |
| Screenshots | ❌ | ✅ `view_screenshot` |
| Runtime errors | ✅ `get_runtime_errors` | ✅ `get_app_errors` (AI-optimized) |
| Widget tree | ✅ `get_widget_tree` | ❌ |
| View details | ❌ | ✅ `get_view_details` |
| Tests | ✅ `run_tests` | ❌ |
| Pub.dev search | ✅ `pub_dev_search` | ❌ |
| Dynamic tools | ❌ | ✅ Runtime registration |

**Preporuka:** Koristi **oba** - dart-flutter za code/tooling, flutter-inspector za visual debugging.

**Stripe MCP** - Payment operacije:
```
"Pokaži mi sve kupce"
"Kreiraj payment link za proizvod"
"Vrati listu subscription-a"
"Napravi refund za payment pi_xxx"
```

#### Korištenje MCP Servera

**Firebase MCP** - Direktne Firestore operacije:
```
"Pokaži mi sve bookinge za unit abc123"
"Kreiraj novi property dokument"
```

**GitHub MCP** - Issue i PR management:
```
"Kreiraj issue za bug u calendar komponenti"
"Pokaži otvorene PR-ove"
```

**Memory MCP** - Perzistentna memorija:
```
"Zapamti da radimo na refaktoringu widget feature-a"
"Šta smo radili prošli put?"
```

**Context7 MCP** - Dokumentacija biblioteka:
```
"use context7 - Riverpod AsyncNotifier primjer"
"use context7 - go_router redirect guard"
"use context7 - Firebase Cloud Functions callable"
```

#### Environment Varijable

Potrebne za neke MCP servere (dodaj u `~/.zshrc`):
```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_xxx"  # Za GitHub MCP
```

### Custom Slash Commands

#### `/ui` - Flutter UI Generator

Generira Flutter UI komponente prema opisu. Automatski primjenjuje project standarde.

**Primjeri:**
```bash
/ui Kreiraj login formu sa email i password poljima
/ui Napravi card komponentu za prikaz property-ja sa slikom, nazivom i cijenom
/ui Bottom navigation bar sa 4 taba: Home, Search, Bookings, Profile
```

**Automatski primjenjuje:**
- Material 3 design
- Riverpod za state management
- LayoutBuilder responsive pattern (500px breakpoint)
- Theme-aware boje (`theme.colorScheme.*`)
- Dijagonalni gradient pattern (`topLeft → bottomRight`)
- BorderRadius 12 za input fields

#### `/firebase` - Firebase CRUD Generator

Generira Firebase repository, model i provider kod.

**Primjeri:**
```bash
/firebase CRUD za Reservation model sa fields: guestName, checkIn, checkOut, status, totalPrice
/firebase Repository za Property sa subcollection Units
/firebase Stream provider za real-time bookings updates
```

**Automatski primjenjuje:**
- Repository pattern (interface + Firebase implementation)
- Riverpod providers (`@riverpod`)
- Error handling sa `ErrorDisplayUtils`
- Optimistic UI + provider invalidation
- Freezed model sa `fromFirestore`/`toFirestore`
- Soft delete pattern (`deleted_at`)
- Nested config `.copyWith()` pattern

#### `/test` - Test Generator

Generira unit, widget i integration testove.

**Primjeri:**
```bash
/test Unit tests za BookingModel - serialization i validation
/test Widget tests za PropertyCard - rendering, tap actions, responsive layout
/test Integration tests za BookingRepository - full CRUD flow
/test Svi testovi za UnitWizardProvider - state transitions
```

**Generira:**
- **Unit tests**: mocktail mocks, model serialization, provider state
- **Widget tests**: ProviderScope, tester interactions, theme compliance, responsive
- **Integration tests**: fake_cloud_firestore, real CRUD flows, stream tests
- **Provider tests**: container setup, invalidation, async handling

**Test struktura:**
```
test/
├── unit/          # Business logic
├── widget/        # UI components
├── integration/   # Firebase flows
└── helpers/       # Shared mocks
```

#### `/stripe:*` - Stripe Operations

Slash komande za Stripe MCP operacije.

| Command | Svrha |
|---------|-------|
| `/stripe:customer-lookup` | Pronađi kupca po email-u i prikaži detalje |
| `/stripe:analyze-payments` | Analiziraj nedavna plaćanja i statistiku |
| `/stripe:create-link` | Kreiraj payment link za proizvod |
| `/stripe:subscriptions` | Lista i upravljanje subscription-ima |
| `/stripe:refund` | Procesiraj refund za plaćanje |
| `/stripe:account-info` | Prikaži info o Stripe računu i stanje |

**Primjeri:**
```bash
/stripe:customer-lookup john@example.com
/stripe:analyze-payments cus_xxx
/stripe:subscriptions active
/stripe:refund pi_xxx 50.00 requested_by_customer
/stripe:create-link "Premium Plan" 99.00 EUR
```

#### `/experiment:debug` - Experiment-Driven Debugging

Za kompleksne bugove koji zahtijevaju više pokušaja.

**Workflow:**
1. Kreira `EXPERIMENT_LOG.md` za tracking
2. Za svaki pokušaj: hipoteza → minimalne izmjene → rezultat → učenje
3. Max 5 pokušaja prije reassess-a

**Primjer:**
```bash
/experiment:debug Calendar ne prikazuje blokirane datume - iCal sync problem
```

#### `/pr:resolve-comments` - PR Comment Resolution

Sistematsko rješavanje review komentara na PR-u.

**Workflow:**
1. Fetch PR info i sve komentare
2. Kategorizacija: code changes, questions, suggestions, nitpicks
3. Process svaki komentar → implementiraj fix → reply

**Primjer:**
```bash
/pr:resolve-comments 123
```

#### `/misc:summary` - Conversation Summary

Generiše detaljan summary sesije za očuvanje konteksta.

**Kada koristiti:**
- Prije kraja duge sesije
- Kada treba nastaviti rad u novom terminalu
- Za dokumentovanje šta je urađeno

**Primjer:**
```bash
/misc:summary
```

### Edmund's Claude Code Plugin

**Datum instalacije**: 2025-11-27
**Marketplace**: `edmund-io/edmunds-claude-code`

#### Aktivne Slash Commands (za Flutter)

| Command | Svrha | Status |
|---------|-------|--------|
| `/new-task` | Analiza kompleksnih taskova i planiranje | ✅ Aktivno |
| `/misc:code-explain` | Detaljno objašnjenje koda sa dijagramima | ✅ Aktivno |
| `/misc:code-optimize` | Optimizacija performansi | ✅ Aktivno |
| `/misc:docs-generate` | Generisanje dokumentacije | ✅ Aktivno |
| `/misc:feature-plan` | Planiranje implementacije feature-a | ✅ Aktivno |
| `/flutter:code-cleanup` | Dart/Flutter refaktoring (PROJEKTNA) | ✅ Aktivno |

#### Backup Commands (za buduće React projekte)

Lokacija: `~/.claude/commands-react-backup/`

| Command | Svrha |
|---------|-------|
| `/api:api-new` | Next.js API routes |
| `/api:api-test` | API testiranje |
| `/api:api-protect` | API security |
| `/ui:component-new` | React komponente |
| `/ui:page-new` | Next.js stranice |
| `/supabase:*` | Supabase Edge Functions |
| `/misc:code-cleanup` | JS/TS cleanup (React) |
| `/misc:lint` | ESLint |

**Restore za React projekat:** `cp -r ~/.claude/commands-react-backup/* ~/.claude/commands/`

#### AI Agenti (18)

**Lokacija**: `~/.claude/agents/`

Agenti su specijalizirani knowledge provideri koji se aktiviraju automatski na osnovu konteksta pitanja. Za razliku od MCP servera (koji izvršavaju akcije), agenti pružaju **ekspertizu i smjernice**.

##### Kako Agenti Rade

1. **Automatska aktivacija** - Claude čita relevantne agente bazirano na kontekstu pitanja
2. **Task tool** - Za kompleksne zadatke koristi `Task` tool sa `subagent_type` parametrom
3. **Kombinacija** - Više agenata može biti aktivno istovremeno

##### Primjeri Invokacije

```
# Automatski (kontekstualno)
"Kako da optimizujem performanse ove Flutter liste?" → aktivira flutter-expert + performance-engineer

# Eksplicitno traženje
"Koristi stripe-expert da analiziraš moju payment integraciju"
"Pozovi security-engineer da pregleda autentifikaciju"

# Task tool (kompleksni zadaci)
Task(subagent_type: "flutter-expert", prompt: "Refaktoriši BookingCard widget")
```

---

**🚀 Specialist Experts (Tech Stack):**

| Agent | Aktivira se kada... | Fokus |
|-------|---------------------|-------|
| `flutter-expert` | Radiš na Flutter kodu, widget dizajnu | Flutter SDK, Riverpod, Material 3, responsive |
| `dart-expert` | Pišeš Dart kod, optimizacija | Idiomatic Dart, async/await, null safety |
| `stripe-expert` | Stripe integracija, plaćanja | Stripe API, Connect, webhooks, PCI compliance |
| `github-actions-expert` | CI/CD, automatizacija | GitHub Actions, workflows, matrix builds |
| `bash-expert` | Shell skripte, automatizacija | Defensive scripting, POSIX, ShellCheck |
| `docker-expert` | Kontejnerizacija, deployment | Dockerfile, Compose, networking, volumes |
| `websocket-expert` | Real-time komunikacija | RFC 6455, WSS, connection lifecycle |

---

**🏗️ Architecture & Planning:**

| Agent | Aktivira se kada... | Fokus |
|-------|---------------------|-------|
| `tech-stack-researcher` | Pitaš o izboru tehnologija | Evaluacija tehnologija, trade-offs |
| `system-architect` | Pitaš o arhitekturi sistema | Skalabilnost, maintainability |
| `backend-architect` | Pitaš o backend dizajnu | Data integrity, security, fault tolerance |
| `frontend-architect` | Pitaš o frontend/UI dizajnu | UX, accessibility, modern frameworks |
| `requirements-analyst` | Pitaš o specifikacijama | Requirements discovery, structured analysis |

---

**⚡ Code Quality & Performance:**

| Agent | Aktivira se kada... | Fokus |
|-------|---------------------|-------|
| `refactoring-expert` | Pitaš o refaktoringu | Clean code, technical debt reduction |
| `performance-engineer` | Pitaš o optimizaciji | Measurement-driven analysis, bottlenecks |
| `security-engineer` | Pitaš o sigurnosti | Vulnerabilities, compliance, best practices |

---

**📚 Documentation & Research:**

| Agent | Aktivira se kada... | Fokus |
|-------|---------------------|-------|
| `technical-writer` | Pitaš za dokumentaciju | Clear documentation, accessibility |
| `learning-guide` | Pitaš za objašnjenje koncepta | Progressive learning, practical examples |
| `deep-research-agent` | Pitaš za duboko istraživanje | Adaptive strategies, intelligent exploration |

---

##### Kada Koristiti Koji Agent

**Za RabBooking projekat najčešće koristimo:**

| Situacija | Agent(i) |
|-----------|----------|
| Widget styling/layout problemi | `flutter-expert` |
| Provider/state management | `flutter-expert` + `dart-expert` |
| Stripe Connect integracija | `stripe-expert` |
| Cloud Functions debugging | `dart-expert` (TypeScript) |
| CI/CD pipeline setup | `github-actions-expert` |
| Performance optimizacija | `performance-engineer` + `flutter-expert` |
| Security review | `security-engineer` |
| Real-time features (chat, notifications) | `websocket-expert` |

##### MCP vs Agenti - Komplementarni Sistem

| Aspekt | MCP Serveri | Agenti |
|--------|-------------|--------|
| **Svrha** | Izvršavanje akcija | Pružanje ekspertize |
| **Primjer** | `mcp__stripe__list_customers` | `stripe-expert` smjernice |
| **Kada** | Trebam URADITI nešto | Trebam ZNATI kako |
| **Output** | Konkretni podaci/rezultat | Smjernice/patterns/best practices |

**Primjer kombinacije:**
```
User: "Kreiraj payment link za novi proizvod"

1. stripe-expert aktivira se za best practices
2. mcp__stripe__create_product izvršava kreiranje
3. mcp__stripe__create_price postavlja cijenu
4. mcp__stripe__create_payment_link vraća URL
```

### Ostali Plugini

**Marketplace**: `jeremylongshore/claude-code-plugins-plus`

| Plugin | Svrha |
|--------|-------|
| `project-health-auditor` | Analizira code quality, dependencies, security issues |
| `git-commit-smart` | Auto-generira pametne commit poruke |

### Hooks (Auto-akcije)

Konfigurisano u `~/.claude/settings.json`:

| Hook | Trigger | Akcija |
|------|---------|--------|
| `dart format` | Nakon svakog Edit | Auto-formatira Dart fajlove |
| `flutter analyze` | Nakon svakog Edit | Provjerava greške |

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
- **Obrisati jedinicu** (sa potvrdom i validacijom aktivnih rezervacija)

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
5-step wizard za kreiranje/editovanje smještajnih jedinica. Owner kreira novu jedinicu kroz guided flow sa validacijom na svakom koraku.

#### Structure
```
unit_wizard/
├── unit_wizard_screen.dart           # Main orchestrator
├── state/
│   ├── unit_wizard_state.dart        # Wizard state model (freezed)
│   ├── unit_wizard_provider.dart     # Riverpod state notifier
│   └── unit_wizard_provider.g.dart   # Generated
└── steps/
    ├── step_1_basic_info.dart        # Name, Slug, Description
    ├── step_2_capacity.dart          # Bedrooms, Bathrooms, Max Guests, Area
    ├── step_3_pricing.dart           # Price per night, Weekend price, Min/Max Stay
    ├── step_4_photos.dart            # Photo upload (OPTIONAL - can skip)
    └── step_5_review.dart            # Review & Publish
```

#### Key Features
- ✅ **Progress Indicator** - Shows current step (1/5) sa visual progress bar
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
- ✅ Testiraj cijeli flow od step 1 do 5
- ✅ Provjeri Firestore nakon publish-a (unit + widget_settings dokumenti moraju postojati)
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

## 🔌 WIDGET SYSTEM - KOMPLETNA DOKUMENTACIJA

**Datum dokumentacije**: 2025-11-27
**Status**: ✅ DEFINITIVNA REFERENCA - Koristi za sve widget-related izmjene

### Widget Modovi (WidgetMode enum)

```dart
enum WidgetMode {
  calendarOnly,    // Samo kalendar - bez rezervacija
  bookingPending,  // Rezervacija bez plaćanja - čeka odobrenje
  bookingInstant,  // Puna rezervacija sa plaćanjem
}
```

#### 1. `calendarOnly` - Samo Kalendar

**Svrha:** Gost vidi samo dostupnost, kontaktira vlasnika telefonom/emailom.

| Aspekt | Vrijednost |
|--------|------------|
| Kalendar | ✅ View only (selekcija DISABLED) |
| Date Selection | ❌ `onRangeSelected: null` |
| Guest Form | ❌ NE prikazuje se |
| Payment Methods | ❌ NE prikazuje se |
| Contact Info | ✅ Pill card ispod kalendara |
| Pill Bar | ❌ NE prikazuje se |

**Owner Settings Screen:**
- ✅ Widget Mode selector
- ✅ Contact Options section
- ❌ Payment Methods (sakriveno)
- ❌ Booking Behavior (sakriveno)

---

#### 2. `bookingPending` - Bez Plaćanja

**Svrha:** Gost kreira rezervaciju, owner odobrava, plaćanje se dogovara privatno.

| Aspekt | Vrijednost |
|--------|------------|
| Kalendar | ✅ Sa selekcijom datuma |
| Date Selection | ✅ Enabled |
| Guest Form | ✅ Prikazuje se |
| Payment Methods | ❌ **NIKAD** se ne prikazuje |
| Info Card | ✅ "Čeka odobrenje vlasnika" |
| Pill Bar | ✅ Floating, draggable |
| Button Text | "Send Booking Request - X nights" |

**Owner Settings Screen:**
- ✅ Widget Mode selector
- ✅ Info Card (zelena): "Rezervacija bez plaćanja"
- ✅ Booking Behavior section (ali `requireOwnerApproval` SAKRIVENO jer je uvijek TRUE)
- ✅ Contact Options section
- ❌ Payment Methods (sakriveno)

**Booking Creation:**
```dart
bookingService.createBooking(
  paymentOption: 'none',
  paymentMethod: 'none',
  requireOwnerApproval: true,  // UVIJEK true, hardcoded!
);
// Status: 'pending'
```

**⚠️ KRITIČNO:**
- `requireOwnerApproval` je **UVIJEK TRUE** za bookingPending
- Toggle za odobrenje treba biti **SAKRIVEN** u owner settings za ovaj mod
- Payment methods se **NIKAD** ne prikazuju gostu

---

#### 3. `bookingInstant` - Sa Plaćanjem

**Svrha:** Gost rezerviše i plaća online. Potvrda zavisi od payment metode.

| Aspekt | Vrijednost |
|--------|------------|
| Kalendar | ✅ Sa selekcijom datuma |
| Date Selection | ✅ Enabled |
| Guest Form | ✅ Prikazuje se |
| Payment Methods | ✅ Stripe / Bank / Pay on Arrival |
| Pill Bar | ✅ Floating, draggable |
| Button Text | Zavisi od payment metode |

**Owner Settings Screen:**
- ✅ Widget Mode selector
- ✅ Payment Methods section (SAMO ovdje!)
- ✅ Booking Behavior section (uključujući `requireOwnerApproval` toggle)
- ✅ Contact Options section

---

### Payment Methods - Detaljna Logika

#### Validacija u Owner Settings

```dart
// bookingInstant MORA imati barem JEDAN payment method
if (mode == WidgetMode.bookingInstant) {
  if (!stripeEnabled && !bankTransferEnabled && !payOnArrivalEnabled) {
    showError("Morate omogućiti barem jednu metodu plaćanja");
    return; // Ne dozvoli save
  }
}
```

#### Bank Transfer - Bank Details Validacija

```dart
// Bank Transfer može biti enabled SAMO ako owner ima unesene bank details
if (bankTransferEnabled && !ownerHasBankDetails) {
  showWarning("Prvo unesite bankovne podatke");
  // Link na: /owner/integrations/payments/bank-account
  return;
}
```

#### Payment Method Prioritet (Auto-Select)

```dart
// Ako je SAMO JEDAN payment method enabled:
// → Auto-select i prikaži simplified UI (nema radio buttons)

// Ako je VIŠE payment methods enabled:
// → Prikaži radio button selector
// → Default selection priority: Stripe > Bank Transfer > Pay on Arrival
```

#### Button Text po Payment Metodi

| Payment Method | Button Text |
|----------------|-------------|
| `stripe` | "Pay with Stripe - X nights" |
| `bank_transfer` | "Continue to Bank Transfer - X nights" |
| `pay_on_arrival` | "Rezervisi - X nights" |

---

### Approval Logic po Payment Metodi

| Payment Method | `requireOwnerApproval` | Preporuka |
|----------------|------------------------|-----------|
| **Stripe** | Konfigurabilan toggle | Može biti FALSE (auto-confirm nakon uplate) |
| **Bank Transfer** | Konfigurabilan toggle | Preporučeno TRUE (owner potvrđuje prije uplate) |
| **Pay on Arrival** | Konfigurabilan toggle | Preporučeno TRUE (owner potvrđuje) |
| **bookingPending** | **UVIJEK TRUE** | Hardcoded, toggle SAKRIVEN |

**UI Preporuka za Owner:**
Prikazati info text: "Za Stripe plaćanje možete isključiti odobravanje jer je plaćeno unaprijed. Za Bank Transfer i Pay on Arrival preporučujemo da ostavite uključeno."

---

### Cancellation Policy

#### Bank Transfer / Pay on Arrival
```
Gost šalje Cancellation REQUEST
    → Owner odobrava ili odbija
    → Refund se dogovara privatno
```

#### Stripe (plaćeno online)
```
Gost šalje Cancellation REQUEST
    → Owner odobrava ili odbija
    → Manual refund (za sada)
    → [FUTURE] Automatski refund opcija
```

**⚠️ NAPOMENA:** Za sada SVE cancellation ide kroz REQUEST → Owner approval. Automatski self-service cancellation može se dodati kasnije.

---

### Deposit (Avans) - Jedinstvena Opcija

```dart
// JEDAN slider za deposit percentage
// Primjenjuje se na SVE payment methods (Stripe + Bank Transfer)
globalDepositPercentage: int  // 0-100%, default 20%
```

**⚠️ KRITIČNO:**
- Koristi `globalDepositPercentage`, NE `stripeConfig.depositPercentage`
- Legacy polja (`depositPercentage` u config-ima) postoje za backward compatibility
- Pri save-u kopiraj globalnu vrijednost u oba config-a

---

### Pricing Hijerarhija (Airbnb-style)

```
KAKO WIDGET RAČUNA CIJENU ZA DATUM X:

1. Da li postoji daily_prices[X].price?
   └─ DA → Koristi tu cijenu (HIGHEST PRIORITY)
   └─ NE → Idi na korak 2

2. Da li je datum X vikend (prema unit.weekendDays)?
   └─ DA → Da li postoji unit.weekendBasePrice?
           └─ DA → Koristi vikend cijenu
           └─ NE → Idi na korak 3
   └─ NE → Idi na korak 3

3. Koristi unit.pricePerNight (BASE FALLBACK)
```

**Primjer:**
- Owner postavi base price: 50€, weekend price: 70€
- U Cjenovnik tabu postavi za 25-31 Dec: 100€
- Rezultat:
  - 1-24 Dec (radni dan): 50€
  - 1-24 Dec (vikend): 70€
  - 25-31 Dec (svi dani): 100€ (override)
  - 1 Jan+: Vraća se na base/weekend logiku

---

### Weekend Days - Konfiguracija

**Trenutno stanje:**
- Default: `[6, 7]` (Subota, Nedjelja) - ISO weekday format
- **NEMA UI** za owner da odabere dane

**Buduća implementacija (OPCIJA B - sve u Cjenovnik tab):**
```
☐ Petak
☑ Subota  (default selected)
☑ Nedjelja
```

**Napomena za vikend:**
- Gledamo NOĆENJA, ne dnevni status
- Petak + Subota ima više smisla za vikend cijenu jer:
  - Petak = check-in u 15h
  - Nedjelja = check-out u 10h
  - Ponedjeljak = radni dan

---

### Step 3 Wizard vs Cjenovnik Tab (OPCIJA B)

**Step 3 Wizard - GLOBALNE postavke:**
| Polje | Status | Napomena |
|-------|--------|----------|
| Base Price | ✅ Required | `pricePerNight` |
| Weekend Price | ❌ PREMJESTITI u Cjenovnik | Kompleksnije jer treba weekend days selector |
| Min Stay | ✅ Required | `minStayNights` |
| Max Stay | ✅ DODATI | `maxStayNights` sa objašnjenjem |

**Cjenovnik Tab - PER-DAY postavke i BULK edit:**
| Polje | Status | Napomena |
|-------|--------|----------|
| Daily Price | ✅ Postoji | Override za specifične dane |
| Weekend Days Selector | ✅ DODATI | Multi-select za vikend dane |
| Weekend Price | ✅ DODATI | Globalna vikend cijena (premjestiti iz wizard-a) |
| Min Nights on Arrival | ✅ Postoji | Per-day override |
| Max Nights on Arrival | ✅ Postoji | Per-day override |
| Bulk Edit | ✅ Postoji | Za range datuma |

---

### Sekcije u Owner Widget Settings Screen

```dart
Widget build(BuildContext context) {
  return ListView(
    children: [
      // UVIJEK PRIKAŽI
      _buildWidgetModeSection(),

      // SAMO ZA bookingInstant
      if (_selectedMode == WidgetMode.bookingInstant) ...[
        _buildPaymentMethodsSection(),
        _buildBookingBehaviorSection(),  // Sa requireOwnerApproval toggle
      ],

      // SAMO ZA bookingPending
      if (_selectedMode == WidgetMode.bookingPending) ...[
        _buildInfoCard("Rezervacija bez plaćanja..."),
        _buildBookingBehaviorSection(),  // BEZ requireOwnerApproval (sakriven)
      ],

      // UVIJEK PRIKAŽI (ali se koristi samo u calendarOnly)
      _buildContactOptionsSection(),
    ],
  );
}
```

---

### Booking Widget Screen - Mode Handling

```dart
// Kalendar - date selection disabled za calendarOnly
CalendarViewSwitcher(
  onRangeSelected: widgetMode == WidgetMode.calendarOnly
      ? null  // DISABLED
      : (start, end) { ... },
)

// Pill Bar - NIKAD za calendarOnly
if (widgetMode != WidgetMode.calendarOnly &&
    _checkIn != null && _checkOut != null &&
    _hasInteractedWithBookingFlow && !_pillBarDismissed)
  _buildFloatingDraggablePillBar(...)

// Contact Pill Card - SAMO za calendarOnly
if (widgetMode == WidgetMode.calendarOnly)
  _buildContactPillCard(...)

// Payment Section - SAMO za bookingInstant
if (widgetMode == WidgetMode.bookingInstant)
  _buildPaymentMethodsInForm(...)

// Info "čeka odobrenje" - SAMO za bookingPending
if (widgetMode == WidgetMode.bookingPending)
  InfoCardWidget(message: "Čeka odobrenje vlasnika")
```

---

### DO NOT (Widget System)

- ❌ **NE PRIKAZUJ** payment methods u `bookingPending` modu
- ❌ **NE DOZVOLI** `requireOwnerApproval = false` za `bookingPending`
- ❌ **NE KORISTI** `stripeConfig.depositPercentage` - koristi `globalDepositPercentage`
- ❌ **NE DOZVOLI** save `bookingInstant` bez barem jednog payment method-a
- ❌ **NE ENABLE** Bank Transfer ako owner nema bank details
- ❌ **NE DOZVOLI** date selection u `calendarOnly` modu

### ALWAYS (Widget System)

- ✅ **UVIJEK** provjeri `widgetMode` prije prikaza sekcija
- ✅ **UVIJEK** koristi `globalDepositPercentage` za deposit kalkulacije
- ✅ **UVIJEK** validiraj payment methods pri save-u za `bookingInstant`
- ✅ **UVIJEK** hardcode `requireOwnerApproval: true` za `bookingPending` bookings
- ✅ **UVIJEK** prikaži Contact Info za `calendarOnly` mod
- ✅ **UVIJEK** koristi pricing hijerarhiju: daily_price > weekend_price > base_price

---

### Lokalizacija (FUTURE)

**Napomena:** U budućnosti će se aplikacija lokalizovati na hrvatski i engleski. Za sada:
- Piši novi tekst na **hrvatskom**
- Lokalizacija će biti zadnji korak prije produkcije
- Ne dodavaj hardcoded engleski tekst u nove feature-e

---

## 🎨 VAŽNI STANDARDI & PATTERNS

### Gradient Standardization - AppGradients ThemeExtension

**Datum**: 2025-11-26 (Updated)
**Status**: ✅ COMPLETED - Centralized gradient system
**Commits**: `f524445`, `7d075d8`, `83fc4f5`, `7d90499`

#### Centralizovani Gradient System

**File**: `lib/core/theme/app_gradients.dart`

Svi gradijenti su centralizovani u `AppGradients` ThemeExtension klasi:

```dart
final gradients = Theme.of(context).extension<AppGradients>()!;

// Page background (screen body)
Container(
  decoration: BoxDecoration(
    gradient: gradients.pageBackground,
  ),
)

// Section background (cards, panels)
Container(
  decoration: BoxDecoration(
    gradient: gradients.sectionBackground,
    border: Border.all(color: gradients.sectionBorder),
  ),
)

// Brand gradient (AppBar, buttons, headers)
Container(
  decoration: BoxDecoration(
    gradient: gradients.brandPrimary,
  ),
)
```

#### Dostupni Gradijenti

| Gradient | Svrha | Light Theme | Dark Theme |
|----------|-------|-------------|------------|
| `pageBackground` | Screen body | Off-white → White | Very dark → Medium dark |
| `sectionBackground` | Cards, panels | Warm cream tones | Warm dark tones |
| `brandPrimary` | AppBar, buttons | Purple fade | Purple fade |
| `sectionBorder` | Card borders | Warm beige (#E8E5DC) | Warm gray (#3D3733) |

#### Karakteristike
- **Direction**: Dijagonalni (topLeft → bottomRight), NE vertikalni!
- **Theme-Aware**: Automatska adaptacija za light/dark mode
- **Centralized**: Promijeni boju na jednom mjestu = update svuda

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
- ❌ **NE KORISTI** hardcoded boje - koristi `AppGradients`
- ❌ **NE KREIRAJ** nove LinearGradient ručno - koristi centralizovane
- ❌ **NE MIJENJAJ** boje u `app_gradients.dart` bez razloga
- ❌ **NE KORISTI** `.withOpacity()` - uvijek koristi `.withValues(alpha: X)`

#### ALWAYS:
- ✅ **UVIJEK KORISTI** `Theme.of(context).extension<AppGradients>()!`
- ✅ **KORISTI** `gradients.pageBackground` za screen body
- ✅ **KORISTI** `gradients.sectionBackground` za cards/panels
- ✅ **KORISTI** `gradients.brandPrimary` za AppBar/buttons
- ✅ **KORISTI** `gradients.sectionBorder` za card borders

#### IF USER REPORTS:
- "Gradijent ne izgleda dobro" → Provjeri da koristi `AppGradients` extension
- "Border boja ne odgovara" → Koristi `gradients.sectionBorder`
- "Compile error: extension null" → Provjeri da je `AppGradients` registrovan u theme

#### IF YOU NEED TO ADD NEW GRADIENT:
1. Dodaj novi gradient u `lib/core/theme/app_gradients.dart`
2. Definiši light i dark varijantu
3. Dodaj u `copyWith()` i `lerp()` metode
4. Koristi kroz `Theme.of(context).extension<AppGradients>()!.noviGradient`

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

### Widget Mode Behavior - bookingPending Approval Toggle

**Datum**: 2025-11-27
**Status**: ✅ COMPLETED - Hidden approval toggle for bookingPending mode

#### Problem

`bookingPending` mod (rezervacija bez plaćanja) prikazivao je toggle za "Zahtijeva Odobrenje" iako je odobrenje u tom modu UVIJEK obavezno. Ovo je zbunjivalo owner-e.

#### Rješenje

1. **Hidden toggle**: U `bookingPending` modu, approval toggle je sakriven
2. **Info banner**: Prikazan info banner koji objašnjava da je odobrenje uvijek potrebno
3. **Hardcoded save**: Pri spremanju, `requireOwnerApproval` je UVIJEK `true` za `bookingPending`

#### UI Logic
```dart
// widget_settings_screen.dart - Behavior switches section
final isBookingPending = _selectedMode == WidgetMode.bookingPending;

// For bookingPending: only show cancellation (approval is always true)
if (isBookingPending) {
  return Column(
    children: [
      // Info banner explaining approval is automatic
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(...),
        child: Row(
          children: [
            Icon(Icons.info_outline, ...),
            Expanded(
              child: Text(
                'U "Rezervacija bez plaćanja" modu sve rezervacije uvijek zahtijevaju vaše odobrenje.',
                ...
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      cancellationCard,  // Only cancellation toggle shown
    ],
  );
}

// For bookingInstant: show both approval + cancellation
// ...
```

#### Save Logic
```dart
// Hardcoded approval for bookingPending mode
requireOwnerApproval: _selectedMode == WidgetMode.bookingPending
    ? true  // ALWAYS true for bookingPending
    : _requireApproval,  // User's choice for bookingInstant
```

#### Widget Mode Summary

| Mode | Approval Toggle | Approval Value |
|------|-----------------|----------------|
| `calendarOnly` | N/A | N/A (no bookings) |
| `bookingPending` | **HIDDEN** | **ALWAYS true** |
| `bookingInstant` | Visible | User's choice |

#### DO NOT:
- ❌ **NE PRIKAZUJ** approval toggle za `bookingPending` mod
- ❌ **NE DOZVOLI** `requireOwnerApproval: false` za `bookingPending`

#### ALWAYS:
- ✅ Info banner za `bookingPending` koji objašnjava behavior
- ✅ Hardcode `true` pri save-u za `bookingPending`
- ✅ Samo `bookingInstant` ima configurable approval

**Key Files:**
- `lib/features/owner_dashboard/presentation/screens/widget_settings_screen.dart` - Lines 1360-1422

---

### Unit Wizard - Max Stay Nights Field

**Datum**: 2025-11-27
**Status**: ✅ COMPLETED - Added maxStayNights to Step 3 Pricing

#### Svrha

Dodano polje za maksimalan broj noći po rezervaciji u Step 3 (Cijena) Unit Wizard-a. Ovo omogućava owner-ima da ograniče dužinu boravka na nivou jedinice.

#### Implementation

**State Model** (`unit_wizard_state.dart`):
```dart
int? maxStayNights, // Maximum nights per booking (null = no limit)
```

**Provider Handler** (`unit_wizard_provider.dart`):
```dart
case 'maxStayNights':
  return draft.copyWith(maxStayNights: value);
```

**UI Field** (`step_3_pricing.dart`):
```dart
TextFormField(
  controller: _maxStayController,
  decoration: InputDecorationHelper.buildDecoration(
    labelText: 'Maksimalan Boravak (noći)',
    hintText: '30',
    helperText: 'Najviše noći (opcionalno)',
    prefixIcon: const Icon(Icons.date_range),
    ...
  ),
  validator: (value) {
    if (value == null || value.isEmpty) return null; // Optional
    final number = int.tryParse(value);
    if (number == null || number < 1) return 'Unesite ispravan broj';
    // Check that max >= min
    final minStay = int.tryParse(_minStayController.text) ?? 1;
    if (number < minStay) return 'Max mora biti >= min ($minStay)';
    return null;
  },
)
```

**Publish** (`unit_wizard_screen.dart`):
```dart
final unit = UnitModel(
  ...
  maxStayNights: draft.maxStayNights, // null = no limit
);
```

#### Validation Rules
- ✅ **Optional field** - null = no maximum limit
- ✅ **Must be ≥ 1** if provided
- ✅ **Must be ≥ minStay** - cannot be less than minimum stay

#### Info Banner

Dodan info banner u Step 3 koji objašnjava napredne opcije dostupne u Cjenovnik tab-u nakon kreiranja jedinice:
- Min/max noći po datumu
- Blokiranje check-in/check-out dana
- Vikend dani
- Sezonske cijene

**Key Files:**
- `lib/features/owner_dashboard/presentation/screens/unit_wizard/state/unit_wizard_state.dart`
- `lib/features/owner_dashboard/presentation/screens/unit_wizard/state/unit_wizard_provider.dart`
- `lib/features/owner_dashboard/presentation/screens/unit_wizard/steps/step_3_pricing.dart`
- `lib/features/owner_dashboard/presentation/screens/unit_wizard/unit_wizard_screen.dart`

---

## 🐛 NEDAVNI BUG FIX-EVI (Post 20.11.2025)

### Weekend Base Price - Airbnb-Style Pricing

**Datum**: 2025-11-26

#### Implementacija
Dodata podrška za vikend cijene na nivou jedinice (UnitModel). Price hijerarhija:
1. **custom daily_price** (iz `daily_prices` kolekcije) - najviši prioritet
2. **weekendBasePrice** (iz `units` kolekcije) - za Sub/Ned ako nema daily_price
3. **basePrice** (pricePerNight iz `units`) - fallback za sve ostale dane

#### Izmijenjeni Fajlovi
- `UnitModel` - nova polja: `weekendBasePrice`, `weekendDays`
- `step_3_pricing.dart` - UI za vikend cijenu u Unit Wizard
- `month_calendar_provider.dart` - `_getEffectivePrice()` helper
- `year_calendar_provider.dart` - isto
- `booking_price_provider.dart` - proslijeđuje unit pricing
- `firebase_booking_calendar_repository.dart` - `calculateBookingPrice()` sa fallback
- `firebase_daily_price_repository.dart` - isto

#### Korištenje
```dart
// Provider automatski uzima vikend cijenu iz UnitModel
final unit = await unitRepo.fetchUnitById(unitId);
final basePrice = unit?.pricePerNight ?? 100.0;
final weekendBasePrice = unit?.weekendBasePrice; // null = koristi basePrice
final weekendDays = unit?.weekendDays ?? [6, 7]; // Default: Sub=6, Ned=7
```

---

### minNights Bug Fix - Widget Čita Iz UnitModel

**Datum**: 2025-11-26

#### Problem
Min nights postavljen u Unit Hub-u se nije primjenjivao na embedded widget kalendar. Widget je čitao `minNights` iz `widget_settings` kolekcije umjesto `minStayNights` iz `units` kolekcije.

#### Rješenje
Ažurirani `month_calendar_widget.dart` i `year_calendar_widget.dart`:
```dart
// PRIJE (bug):
final minNights = widgetSettings.value?.minNights ?? 1;

// POSLIJE (fix):
final unitAsync = ref.watch(unitByIdProvider(widget.propertyId, widget.unitId));
final unit = unitAsync.valueOrNull;
final minNights = unit?.minStayNights ?? 1;
```

---

### Navigator Assertion Error Fix

**Datum**: 2025-11-26
**File**: `widget_settings_screen.dart`

#### Problem
`!_debugLocked is not true` error kada se promijeni widget mode i sačuva. `ref.invalidate()` triggeruje rebuild dok `Navigator.pop()` pokušava navigirati.

#### Rješenje
Wrap `Navigator.pop()` u `addPostFrameCallback`:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) {
    Navigator.pop(context);
  }
});
```

---

### Widget Settings Embedded Mode - Navigator.pop Fix

**Datum**: 2025-11-26
**File**: `widget_settings_screen.dart`

#### Problem
"You have popped the last page off of the stack" error kada se sačuva widget settings unutar Unit Hub tab-a. Screen se koristi u dva režima:
- **Standalone** (`showAppBar: true`) - otvoren kao zasebna stranica
- **Embedded** (`showAppBar: false`) - ugrađen u Unit Hub tab

#### Rješenje
Dodaj uslov da `Navigator.pop()` se poziva SAMO u standalone modu:
```dart
if (widget.showAppBar) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      Navigator.pop(context);
    }
  });
}
```

---

### Calendar Legend/Footer Width Fix

**Datum**: 2025-11-26
**Files**: `month_calendar_widget.dart`, `year_calendar_widget.dart`, `year_grid_calendar_widget.dart`

#### Problem
Min. stay info i legenda bili su preširoki - nisu pratili širinu kalendara.

#### Rješenje
Dodani `Center` wrapper sa `maxWidth` constraint koji prati kalendar:
```dart
Center(
  child: Container(
    constraints: BoxConstraints(maxWidth: isDesktop ? 650.0 : 600.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      // ...
    ),
  ),
)
```

---

### Contact Info Pills Row Layout Fix

**Datum**: 2025-11-26
**File**: `booking_widget_screen.dart`

#### Problem
Email i telefon pills su bili u column na mobilnim uređajima, zauzimali previše vertikalnog prostora.

#### Rješenje
- Breakpoint promijenjen sa 600px na 350px za row/column switch
- maxWidth promijenjen sa 170px na 500px za row layout
- Spacing reduciran sa 12px na 8px
- Divider smanjen (height 40→24px, margin 16→12px)

```dart
final useRowLayout = screenWidth >= 350; // Bilo 600
final maxWidth = useRowLayout ? 500.0 : 200.0; // Bilo 170
```

---

### Cross-Month Date Selection Fix

**Datum**: 2025-11-26
**File**: `month_calendar_widget.dart`

#### Problem
Kada korisnik odabere checkIn (npr. Nov 29) i prebaci na drugi mjesec da odabere checkOut, selekcija se brisala. Stari "Bug #70 Fix" je brisao `_rangeStart` i `_rangeEnd` uvijek pri navigaciji.

#### Rješenje
Briši selekciju samo ako je KOMPLETNA (oba datuma odabrana):
```dart
// Samo briši ako je kompletna selekcija
if (_rangeStart != null && _rangeEnd != null) {
  _rangeStart = null;
  _rangeEnd = null;
  widget.onRangeSelected?.call(null, null);
}
```

---

### Blocked Dates Bypass Fix

**Datum**: 2025-11-26
**File**: `firebase_booking_calendar_repository.dart`

#### Problem
`checkAvailability()` je provjeravala samo bookings i iCal events, ali NE i blokirane datume iz `daily_prices` (`available: false`). Korisnik je mogao odabrati range preko blokiranog datuma.

#### Rješenje
Dodana treća provjera u `checkAvailability()`:
```dart
// Check blocked dates from daily_prices (available: false)
final blockedDatesSnapshot = await _firestore
    .collection('daily_prices')
    .where('unit_id', isEqualTo: unitId)
    .where('available', isEqualTo: false)
    .get();

for (final doc in blockedDatesSnapshot.docs) {
  final blockedDate = (data['date'] as Timestamp).toDate();
  if (blockedDate >= checkIn && blockedDate < checkOut) {
    return false; // Conflict with blocked date
  }
}
```

**Sada provjerava:**
- ✅ Bookings (rezervacije)
- ✅ iCal events (Booking.com, Airbnb)
- ✅ Blocked dates (`available: false` u daily_prices)

---

### Backend Daily Price Validation (Security Fix)

**Datum**: 2025-11-26
**File**: `functions/src/atomicBooking.ts`

#### Problem
Cloud Function `createBookingAtomic` nije validirala `daily_prices` kolekciju. Gost je mogao zaobići UI restrikcije direktnim API pozivom.

#### Rješenje
Dodana validacija unutar `db.runTransaction()` bloka (nakon conflict check-a, linija ~220):

```typescript
// STEP 2.5: Validate daily_prices restrictions
const dailyPricesQuery = db.collection("daily_prices")
  .where("unit_id", "==", unitId)
  .where("date", ">=", checkInDate)
  .where("date", "<", checkOutDate);

const dailyPricesSnapshot = await transaction.get(dailyPricesQuery);

for (const doc of dailyPricesSnapshot.docs) {
  const priceData = doc.data();

  // Check 1: available flag
  if (priceData.available === false) {
    throw new HttpsError("failed-precondition", "Date not available");
  }

  // Check 2: blockCheckIn on check-in date
  if (isCheckInDate && priceData.block_checkin === true) {
    throw new HttpsError("failed-precondition", "Check-in not allowed");
  }

  // Check 3: minNightsOnArrival
  if (isCheckInDate && priceData.min_nights_on_arrival > bookingNights) {
    throw new HttpsError("failed-precondition", "Minimum nights required");
  }

  // Check 4: maxNightsOnArrival
  if (isCheckInDate && priceData.max_nights_on_arrival < bookingNights) {
    throw new HttpsError("failed-precondition", "Maximum nights exceeded");
  }
}

// Check 5: blockCheckOut on check-out date (separate query)
```

**Validira:**
- ✅ `available` - Ako `false`, odbij booking
- ✅ `block_checkin` - Ako `true` na check-in datumu, odbij
- ✅ `block_checkout` - Ako `true` na check-out datumu, odbij
- ✅ `min_nights_on_arrival` - Ako booking noći < min, odbij
- ✅ `max_nights_on_arrival` - Ako booking noći > max, odbij

**Backward Compatible:** Datumi bez daily_prices zapisa = default dostupni.

---

### Edit Date Dialog - UI/UX Cleanup

**Datum**: 2025-11-26
**File**: `lib/features/owner_dashboard/presentation/widgets/price_list_calendar_widget.dart`

#### Promjene
1. **Uklonjen `isImportant`** - Polje nije imalo nikakvu funkciju
2. **InputDecorationHelper** - Svi input fieldi sada koriste standardni helper sa borderRadius 12px
3. **Section headers sa ikonama** - CIJENA, DOSTUPNOST, NAPOMENA sekcije imaju ikone
4. **ExpansionTile za napredne opcije** - weekendPrice, minNights, maxNights premješteni u collapsible sekciju
5. **Warning banner** - Upozorenje da napredne opcije nisu aktivne u widgetu

#### Nova Struktura Dialoga
```
┌─────────────────────────────────────┐
│ € CIJENA                            │
│ [Osnovna cijena po noći]            │
├─────────────────────────────────────┤
│ 📅 DOSTUPNOST                        │
│ [x] Dostupno                        │
│ [ ] Blokiraj prijavu (check-in)    │
│ [ ] Blokiraj odjavu (check-out)    │
├─────────────────────────────────────┤
│ 📝 NAPOMENA                          │
│ [Napomena za ovaj datum]            │
├─────────────────────────────────────┤
│ ⚙️ Napredne opcije (collapsed)       │
│   ⚠️ Ove opcije se čuvaju, ali...   │
│   [Vikend cijena]                   │
│   [Min. noći] [Max. noći]           │
└─────────────────────────────────────┘
```

---

### Real-Time Sync - StreamProvider Conversion

**Datum**: 2025-11-26
**Commit**: `999ba80`

#### Problem
- UI se nije automatski osvježavao kada se podaci promijene u drugom browser tabu
- FutureProvider samo jednom učita podatke, nema live updates

#### Rješenje
Konverzija `ownerPropertiesProvider` i `ownerUnitsProvider` iz FutureProvider u StreamProvider:

```dart
// PRIJE (FutureProvider - no live updates)
@riverpod
Future<List<PropertyModel>> ownerProperties(Ref ref) async {
  return await repository.getOwnerProperties(ownerId);
}

// POSLIJE (StreamProvider - real-time sync)
@riverpod
Stream<List<PropertyModel>> ownerProperties(Ref ref) {
  return repository.watchOwnerProperties(ownerId);
}
```

**Nove Repository Metode:**
- `watchOwnerProperties(ownerId)` - Real-time stream za properties
- `watchAllOwnerUnits(ownerId)` - Real-time stream za sve jedinice

**Rezultat:**
- ✅ Promjene u jednom tabu automatski vidljive u drugom
- ✅ Nema potrebe za manual refresh

---

### Price Calendar - TextEditingController Disposal Fix

**Datum**: 2025-11-26
**Commit**: `999ba80`

#### Problem
Red screen greška: "TextEditingController was used after being disposed" kada se sprema cijena u kalendaru.

**Root Cause:** Controllers se dispose-aju u `.then()` callback dok dialog još animira zatvaranje:
```dart
// ❌ LOŠE - dispose dok widget još postoji
showDialog(...).then((_) {
  priceController.dispose();  // Widget možda još koristi controller!
});
```

#### Rješenje
Wrap dispose u `addPostFrameCallback` da se izvrši u sljedećem frame-u:
```dart
// ✅ DOBRO - dispose u sljedećem frame-u
showDialog(...).then((_) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    priceController.dispose();
  });
});
```

**Primijenjeno na:**
- Single date edit dialog (~line 1321)
- Bulk price edit dialog (~line 1549)

---

### Unit Hub - Delete Unit Button

**Datum**: 2025-11-26
**Commit**: `999ba80`

#### Problem
Nije postojalo dugme za brisanje jedinica u Unit Hub-u.

#### Rješenje
Dodana `_confirmDeleteUnit()` metoda i delete dugme u unit list tile:
- AlertDialog za potvrdu brisanja
- Validacija aktivnih rezervacija (u repository-u)
- Provider invalidation za instant UI refresh
- Reset selekcije ako je obrisana odabrana jedinica

---

### Auth System - Error Handling & Loading State

**Datum**: 2025-11-26
**Commit**: `bd4c9d3`

#### Riješeni Problemi
- Security logging i `sendEmailVerification()` wrapped u try-catch (non-blocking)
- Social sign-in (Google/Apple/Anonymous) sada ima loading spinner
- UI koristi `state.error` umjesto raw exception poruka
- Error check prije success navigacije

#### Ključni Pattern
```dart
// Provider: Non-blocking async operacije
try {
  await _security.logLogin(user, location: location);
} catch (e) {
  LoggingService.log('Security logging failed: $e', tag: 'AUTH_WARNING');
}

// UI: Prefer state.error
final authState = ref.read(enhancedAuthProvider);
final errorMessage = authState.error ?? e.toString();
```

---

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

**Status**: ✅ STABILAN - Master-Detail pattern (2025-11-25)

#### Osnovne Informacije
- **Folder**: `lib/features/owner_dashboard/presentation/screens/ical/`
- **Svrha**: Import rezervacija sa Booking.com/Airbnb, Export iCal URL-ova
- **Platform Options**: Booking.com, Airbnb, Druga platforma (iCal)

#### Screen-ovi
1. **Import** - `ical_sync_settings_screen.dart` - Dodaj/uredi iCal feed-ove
2. **Export List** - `ical_export_list_screen.dart` - Master screen sa listom jedinica
3. **Export Detail** - `ical_export_screen.dart` - iCal URL za konkretnu jedinicu (REQUIRES params!)
4. **Guide** - `ical_guide_screen.dart` - Uputstvo za setup

#### ⚠️ KRITIČNO - Provider Invalidation za UI Refresh

**Problem riješen (2025-11-25):** UI se nije osvježavao nakon CRUD operacija na feed-ovima.

**Rješenje:** Dodano `ref.invalidate()` nakon svake operacije:
```dart
// Nakon delete/create/update feed-a:
ref.invalidate(icalFeedsStreamProvider);
ref.invalidate(icalStatisticsProvider);
```

**Lokacije u kodu:**
- `_confirmDeleteFeed()` - linije 808-810
- `_saveFeed()` (create) - linije 1204-1206
- `_saveFeed()` (update) - linije 1221-1223

#### ⚠️ KRITIČNO - Cloud Function HTTP Redirect Handling

**File:** `functions/src/icalSync.ts`

**Problem riješen:** Booking.com koristi HTTP redirecte (301, 302, 303, 307, 308) za iCal URL-ove.

**Rješenje:** `fetchIcalData()` funkcija sada:
- Prati do 5 redirecta rekurzivno
- Podržava relative URL redirecte (`/path` → `https://host/path`)
- Logira svaki redirect za debugging

#### Ključni Constraint-ovi
- ❌ **NE OTVORI** Export Screen sa `context.go()` (mora `context.push()` sa extra params!)
- ❌ **NE MIJENJAJ** null-safety validation u route builder-u
- ❌ **NE UKLANJAJ** provider invalidation iz CRUD operacija!
- ✅ **Master-Detail pattern**: Export List (no params) → Export Screen (requires unit + propertyId)
- ✅ **Horizontal gradient**: Svi 4 screen-a koriste left→right gradient
- ✅ **Instant UI refresh**: Provider invalidation nakon svake CRUD operacije

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

**Commit:** `4fff528` (2025-11-25)

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

**Status**: ✅ STABILAN - Refaktorisan (2025-11-25)

#### Osnovne Informacije
- **File**: `edit_profile_screen.dart` (~830 lines)
- **Svrha**: Owner profil + company details (za fakture i komunikaciju)
- **Features**: Profile image upload, dual save (profile + company)
- **Kartice**: 3 collapsible cards (Lični Podaci, Adresa, Kompanija)

#### Ključni Constraint-ovi
- ❌ **NE DODAVAJ** instagram/linkedin u SocialLinks (model ima SAMO website + facebook!)
- ❌ **NE MIJENJAJ** controllers lifecycle - svi moraju biti disposed!
- ❌ **NE DODAVAJ** bank fields ovdje - premješteni u Bank Account Screen!
- ✅ **Dual save**: UserProfile + CompanyDetails se čuvaju odvojeno
- ✅ **SocialLinks**: SAMO website i facebook (2 fields)
- ✅ **Bank details**: Premješteni u `Integracije → Plaćanja → Bankovni Račun`
- ✅ Pri save-u ČUVAJ postojeće bank podatke: `existingCompany?.bankAccountIban ?? ''`

---

### Bank Account Screen & Drawer Reorganization

**Status**: ✅ COMPLETED (2025-11-25)
**Commit**: `bc65be1`

#### Svrha
Dedicated screen za upravljanje bankovnim podacima (IBAN, SWIFT, Bank Name, Account Holder).
Podaci se koriste u Booking Widget-u kada gost odabere "Bankovni prijenos" kao način plaćanja.

#### Nova Drawer Struktura
```
[Expandable] Integracije
├── [Section Header] iCal
│   ├── Import Rezervacija
│   └── Export Kalendara
└── [Section Header] Plaćanja
    ├── Stripe Plaćanja
    └── Bankovni Račun  ← NOVA stranica
```

#### Key Files
- **NEW**: `lib/features/owner_dashboard/presentation/screens/bank_account_screen.dart`
- **EDIT**: `lib/features/owner_dashboard/presentation/widgets/owner_app_drawer.dart`
- **EDIT**: `lib/core/config/router_owner.dart`

#### Ruta
```dart
static const String bankAccount = '/owner/integrations/payments/bank-account';
```

#### Data Storage
- **Firestore lokacija**: `users/{userId}/profile/company` (ISTA kao prije!)
- **Model**: `CompanyDetails` (bankAccountIban, swift, bankName, accountHolder)
- **Zero migration**: Postojeći podaci ostaju netaknuti

#### Ključni Constraint-ovi
- ❌ **NE VRAĆAJ** bank fields u Edit Profile - premješteni su namjerno!
- ❌ **NE MIJENJAJ** Firestore lokaciju - widget čita iz istog mjesta
- ✅ Pri save-u **ČUVAJ** ostale CompanyDetails fields (companyName, taxId, etc.)
- ✅ Widget Settings navigacija vodi na Bank Account (ne Edit Profile)

#### _DrawerSectionHeader Widget
Nova helper komponenta za section headers unutar ExpansionTile:
```dart
class _DrawerSectionHeader extends StatelessWidget {
  final String title;
  // Renders: vertical accent bar + section title text
}
```

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
// Integrations
/owner/integrations/stripe                    // Stripe setup
/owner/integrations/payments/bank-account     // Bank account (NEW)
/owner/integrations/ical/import               // iCal import
/owner/integrations/ical/export-list          // iCal export list
/owner/integrations/ical/export               // iCal export detail (REQUIRES params!)
// Profile
/owner/profile/edit                           // Edit profile
/owner/profile/notifications                  // Notification settings
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

## 🎯 FUTURE IMPROVEMENTS / NICE TO HAVE

Ova sekcija sadrži pakete i alate koji nisu prioritet za MVP, ali bi mogli poboljšati UX/UI u budućnosti.

### UI Packages

| Package | Svrha | Link | Prioritet |
|---------|-------|------|-----------|
| **awesome_snackbar_content** | Fancy SnackBar notifikacije (Success/Error/Warning/Info sa ikonama i animacijama) | [GitHub](https://github.com/mhmzdev/awesome_snackbar_content) | ⭐ Low - Za UI polish |

**awesome_snackbar_content** detalji:
- 4 tipa: Success (zelena), Failure (crvena), Warning (žuta), Help (plava)
- Custom ikone i animacije
- Zamjena za trenutni `ErrorDisplayUtils`
- **Kada dodati:** Nakon MVP-a, za "production polish" fazu

### MCP Serveri (Za Buduće Projekte)

| MCP Server | Svrha | Kada dodati |
|------------|-------|-------------|
| **figma-flutter-mcp** | Figma design tokens → Flutter kod | Kada koristimo Figma za dizajn |

---

**Last Updated**: 2025-11-27
**Version**: 2.5
**Focus**: MCP Serveri (10), Slash Commands (16), Agents dokumentacija

---

**REMEMBER**: Ova dokumentacija je živi dokument. Kada radiš važne izmjene, update-uj relevantu sekciju!