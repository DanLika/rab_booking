# Claude Code - Project Documentation

Ova dokumentacija pomaže Claude Code sesijama da razumiju kritične dijelove projekta.

**Dodatni dokumenti:**
- [CLAUDE_MCP_TOOLS.md](./CLAUDE_MCP_TOOLS.md) - MCP serveri, slash commands, agenti
- [CLAUDE_WIDGET_SYSTEM.md](./CLAUDE_WIDGET_SYSTEM.md) - Widget modovi, payment logic, pricing
- [CLAUDE_BUGS_ARCHIVE.md](./CLAUDE_BUGS_ARCHIVE.md) - Arhivirani bug fix-evi (pre 2025-12-01)

---

## 📘 PROJECT OVERVIEW

**RabBooking** - Booking management platforma za property owner-e na otoku Rabu.

| Komponenta | Opis |
|------------|------|
| **Owner Dashboard** | Flutter Web admin panel |
| **Booking Widget** | Embeddable widget za web stranice |
| **Backend** | Firebase (Firestore, Cloud Functions, Auth) |

### Tehnologije
- Flutter 3.35.7, Riverpod 2.x, Firebase, Stripe Connect
- Feature-first structure, Repository pattern

### Status
- ✅ Owner dashboard - production-ready
- ✅ Booking widget - radi
- ⚠️ Hot reload/restart ne rade - normalno za Flutter Web

---

## 🎯 KRITIČNE SEKCIJE - NE MIJENJAJ!

### Unified Unit Hub
**File**: `unified_unit_hub_screen.dart`
**Status**: FINALIZED

- **Cjenovnik tab** je FROZEN - koristi kao referentnu implementaciju
- Responsive breakpoints: Desktop ≥1200px, Tablet 600-1199px, Mobile <600px
- NE MIJENJAJ bez eksplicitnog user zahtjeva

### Unit Wizard
**Folder**: `unit_wizard/`
**Status**: PRODUCTION READY

Publish flow kreira 3 Firestore dokumenta (redoslijed kritičan!):
1. Unit document
2. Widget settings
3. Initial pricing

### Timeline Calendar
**File**: `owner_timeline_calendar_screen.dart`

- Z-Index: Cancelled (0.6 opacity) renderuje PRVI, confirmed ZADNJI
- Gradient: DIJAGONALAN (`topLeft → bottomRight`), stops [0.0, 0.3]
- Headers: MORAJU biti transparent

### Owner Bookings Screen
**File**: `owner_bookings_screen.dart`

- Pending bookings: 2x2 button grid (Approve, Reject, Details, Cancel)
- Provider invalidation: POSLIJE repository poziva
- Skeleton loaders: RAZLIČITI za Card vs Table view

---

## 🎨 STANDARDI

### AppGradients ThemeExtension
```dart
final gradients = Theme.of(context).extension<AppGradients>()!;
gradients.pageBackground    // Screen body
gradients.sectionBackground // Cards, panels
gradients.brandPrimary      // AppBar, buttons
```

### Input Fields
- BorderRadius: **12px** (konzistentno!)
- Koristi `InputDecorationHelper.buildDecoration()`
- Theme defaults za border colors (ne hardcoded!)

### Responsive Pattern
```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 500) return Column(...);
    return Row(...);
  },
)
```

### Provider Invalidation
```dart
await repository.updateData(...);
ref.invalidate(dataProvider);  // POSLIJE save-a!
```

### Nested Config Update
```dart
// ✅ DOBRO
currentSettings.emailConfig.copyWith(requireEmailVerification: false)

// ❌ LOŠE - gubi ostala polja!
EmailNotificationConfig(requireEmailVerification: false)
```

---

## 🔧 ALATI (Summary)

Vidi [CLAUDE_MCP_TOOLS.md](./CLAUDE_MCP_TOOLS.md) za detalje.

**Aktivni MCP serveri**: dart-flutter, firebase, github, memory, context7, stripe, flutter-inspector, mobile-mcp

**Key slash commands**: `/ui`, `/firebase`, `/test`, `/stripe:*`, `/flutter:code-cleanup`

---

## 🔌 WIDGET SYSTEM (Summary)

Vidi [CLAUDE_WIDGET_SYSTEM.md](./CLAUDE_WIDGET_SYSTEM.md) za detalje.

**Modovi**: `calendarOnly`, `bookingPending`, `bookingInstant`

**Kritično**:
- `bookingPending` → `requireOwnerApproval` UVIJEK true
- `bookingInstant` → MORA imati barem 1 payment method
- Pricing: daily_price > weekend_price > base_price

---

## 📦 WIDGET REFACTORING (2025-12-01)

| Fajl | Linije | Status |
|------|--------|--------|
| `booking_widget_screen.dart` | 2,154 | Refaktorisan (-49%) |
| `year_calendar_widget.dart` | 946 | Refaktorisan |
| `month_calendar_widget.dart` | 872 | Refaktorisan |

**Ekstraktovani komponenti:**
- `calendar/` - date_utils, view_switcher, legend
- `confirmation/` - 7 komponenti
- `details/` - 8 komponenti
- `shared/utils/` - validators, snackbar_helper

---

## 📚 DODATNE REFERENCE

### iCal Integration
**Folder**: `screens/ical/`
- Export Screen ZAHTIJEVA params: `context.push()` sa extra, NE `context.go()`!
- Provider invalidation nakon CRUD operacija

### Bank Account Screen
**Route**: `/owner/integrations/payments/bank-account`
- Odvojen od Edit Profile
- Koristi CompanyDetails model

### Router
**File**: `router_owner.dart`
- `isLoading` check KRITIČAN (sprječava flash nakon registracije)
- Widget params na `/login` route prikazuju `BookingWidgetScreen` (Stripe return fix)

### Cross-Tab Communication (2025-12-02)
**Files**: `tab_communication_service.dart`, `tab_communication_service_web.dart`
**Svrha**: Kada Stripe plaćanje završi u Tab B, Tab A (originalni widget) automatski prikaže confirmation screen.

- **BroadcastChannel API** sa localStorage fallback
- Channel: `rab-booking-stripe`
- Message types: `paymentComplete`, `bookingCancelled`, `calendarRefresh`
- Inicijalizacija u `booking_widget_screen.dart` → `_initTabCommunication()`
- `fromOtherTab` parametar sprječava circular broadcasting

**Flow:**
```
Tab A (form) ← BroadcastChannel ← Tab B (Stripe return broadcasts paymentComplete)
```

---

## 🎯 QUICK REFERENCE

### NIKADA NE MIJENJAJ:
1. Cjenovnik tab - frozen
2. Z-index sorting u Timeline Calendar
3. Wizard publish flow (3 docs redoslijed)
4. Input field borderRadius 12px
5. Gradient direkcija topLeft → bottomRight
6. Provider invalidation POSLIJE save-a

### UVIJEK KORISTI:
1. `theme.colorScheme.*` (ne AppColors)
2. `InputDecorationHelper.buildDecoration()`
3. `.copyWith()` za nested config
4. `ref.invalidate()` POSLIJE repository poziva
5. `mounted` check prije async navigation

### PRIJE MIJENJANJA:
1. Pročitaj ovu dokumentaciju
2. Provjeri commit history
3. `flutter analyze` = 0 issues
4. PITAJ korisnika ako nešto čudno

---

**Last Updated**: 2025-12-02
**Version**: 3.0 (Refaktorisan)
