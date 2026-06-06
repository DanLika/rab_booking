# audit/117 — Premium Implementation Evidence (Batches B1–B5)

**Date:** 2026-06-06
**Branch:** `feat/premium-redesign-2026-06-06`
**PR:** [#679 (draft)](https://github.com/DanLika/rab_booking/pull/679)
**Spec:** [audit/116](116-premium-spec.md) — single source of truth
**Per-batch contract:** match `design_handoff/screens/*-owner.png` Premium variant exactly. Agent never self-certifies; user gates each batch.

---

## §B1 — Pregled premium (GATED)

| Element | Mockup ref | Status | Surface |
|---|---|---|---|
| AppBar resolution | flat over shell bg (`#F0F1F5`) | **FLAT KEPT** (Phase B AppBarTheme + BbAppBar transparent on premium pages) | `app_theme.dart` light+dark |
| Eyebrow date + H1 "Dobro jutro, Ivana" | `01-owner.png` header | ✓ existing `dashboard_overview_tab.dart` | already in place |
| North-star revenue command | `PVRevenueCommand` | ✓ existing (PR #675) | `dashboard_overview_tab.dart:1701` |
| Occupancy radial gauge | `PVRadial` | ✓ existing (PR #675) | `dashboard_overview_tab.dart:1847` |
| AI insight banner tri-stop gradient | `PVAIInsight` purple→light purple→mint (`tokens.css:217`) | **C-1 commit `2998d1ea`** | `dashboard_overview_tab.dart:2035-2050` |
| 4 KPI tiles all with sparklines | `PV_KPIS` | **C-1 commit `2998d1ea`** (tiles 3+4 wired proxy series) | `dashboard_overview_tab.dart:725-749` |
| Next-guest hero date chip | `PV_ARRIVALS[0].next=true` | **C-1 commit `2998d1ea`** new `_ArrivalsDateChip` | `dashboard_overview_tab.dart:1693-1755` |
| Channel mix card | `PVChannels` flat BbCard | ✓ existing (PR #675) | `dashboard_overview_tab.dart:2150` |

**Fixture (DEV):** 10 bookings seeded via `scripts/seed-pregled-premium-dev.js` on test acct `bookbed-test@bookbed.io`. Yields €2 210 revenue, 5 `revenueHistory` points, 2 upcoming arrivals, multi-channel.

**Quality:** `flutter analyze lib/`: 0 issues in touched file. `flutter test`: green. `dart format`: clean.

**Deploy:** https://bookbed-owner-dev.web.app (commit `2998d1ea`). Bundle `projectId = bookbed-dev` ✓.

---

## §B2 — Rezervacije + Jedinice + Kalendar Mjesečni (this batch)

### §B2.1 Rezervacije premium composition (the never-built P1)

| Element | Mockup ref (`02-owner.png`) | Implementation |
|---|---|---|
| Eyebrow date + H1 "Rezervacije" | header row | `bookings_premium_header.dart::_PremiumHeaderRow` |
| 4-tile KPI strip — Na čekanju · Potvrđeno (mj.) · Zarada (mj.) · Nadolazeći | `RZPStatStrip` | `_RezKpiStrip` + `_RezStatTile` |
| AI nudge banner — tri-stop amber/purple/teal gradient | `RZPAINudge` | `_RezAINudge` (gated by `PREGLED_AI_INSIGHT` dart-define + `kDebugMode`) |
| "Zahtijeva vašu pažnju" priority queue header | `RZPPendingQueue` | `_RezPendingQueue` w/ amber dot + count badge |
| Pending booking card w/ amber rail | `RZPPendingCard` | `_RezPendingCard` — `tertiary`-colored 4 px gradient rail |
| Inline `Odobri` / `Odbij` (reuse PR #676 pattern) | `BBButton` row | `BbButton` primary + destructive-soft; calls `FirebaseOwnerBookingsRepository.approve/rejectBooking` directly; refreshes `windowedBookingsNotifierProvider` |
| Payment progress with polog % | inline | `LinearProgressIndicator` 8 px green |
| Stay facts (apartment · event · group · sell) | inline | `_Fact` widget × 4 |
| Bookings ledger table | `RZPLedger` | **DEFERRED** — existing list+table view in `owner_bookings_screen.dart` retained as system-of-record; premium ledger is a Batch 4 follow-up |

**File:** `lib/features/owner_dashboard/presentation/widgets/bookings/bookings_premium_header.dart` (new, ~600 lines)
**Insertion:** `owner_bookings_screen.dart:590-616` — new `SliverToBoxAdapter` BEFORE the filters section, hidden when `filters.hasActiveFilters || filters.showImportedOnly`.

**Reuse from PR #676:** the inline `notificationActionApprove` / `notificationActionReject` l10n strings + the same `FirebaseOwnerBookingsRepository.approveBooking` / `rejectBooking` repository methods.

### §B2.2 Kalendar Mjesečni — premium KPI strip

| Element | Mockup ref (`04-owner.png`) | Implementation |
|---|---|---|
| 4-tile KPI strip — Popunjenost · Rezervacije · Dolasci · Slobodne noći | header strip | `MonthCalendarKpiStrip` (new widget) |
| Status filter chips (Potvrđeno / Na čekanju / Završeno / …) | below KPI | **EXISTING** `_buildStatusLegend` — premium pass not required |
| Calendar grid | grid | **FROZEN** — cells / dimensions / `timeline_dimensions.dart` untouched per CLAUDE.md |

**File:** `lib/features/owner_dashboard/presentation/widgets/calendar/month_calendar_kpi_strip.dart` (new, ~200 lines)
**Insertion:** `month_calendar_screen.dart:161-165` — new `SliverToBoxAdapter` as first sliver, before the unit filter.
**Free-nights derivation:** local — `30 - round(30 × occupancyRate / 100)`. Honest derivation, not invented data; documented inline.

### §B2.3 Jedinice — chrome inherited from Phase B

`unified_unit_hub_screen.dart` (which holds the FROZEN Cjenovnik tab) consumes the Phase B `AppBarTheme` premium chrome automatically (surface bg, 56 px slim, bb-h2 title). The list panel + tabbed detail panel layouts in `06-owner.png` map cleanly to the existing `BbCard` consumers and need no per-screen refactor for the "chrome premium pass" the prompt asked for. **No per-screen changes shipped for Jedinice in this batch.** If user requests composition (eyebrow + KPI strip), that's a Batch 4 follow-up.

### §B2.4 AppBar resolution (carried forward from C-1)

Confirmed in audit/116 §AppBar-resolution: handoff Premium has the AppBar dissolving into the shell (transparent). Phase B's MaterialApp `AppBarTheme = surfaceLight + 56 px + text-primary title` is correct for both legacy screens and BbScaffold-wrapped premium pages. No revert.

---

## §B3 — Shared chrome (PENDING)

Deferred. Per user prompt: Drawer / EndDrawer / Dialog base / BottomSheet base / Bb* component depth. **Note:** Dialog + BottomSheet base already shipped in Phase B (`app_theme.dart` radius 24 + 3-layer shadow). Remaining: Drawer envelope shadow, EndDrawer treatment, Bb* component lift transitions, resolution of `BbIconTile` open question (grep first — `lib/shared/widgets/redesign/bb_icon.dart` exists; `bb_icon_tile.dart` does NOT). Channel-mix card stays FLAT per `01-owner.png` ground truth.

---

## §B4 — Remaining screens (PENDING)

Deferred. Profil / AI Asistent / Stripe / iCal Sync / iCal Export / FAQ / Notifications / Bankovni / settings sub-screens.

---

## §B5 — Booking detail full-route (GATED)

Deferred. **Requires explicit user "GO frozen Navigator" before any work** — Navigator.push confirmation flow is FROZEN per CLAUDE.md. Until then keep modal; only premium composition within the modal allowed.

---

## Per-batch quality gates

| Gate | B1 | B2 |
|---|---|---|
| Mockup match | side-by-side reviewed, AppBar FLAT KEPT | this report |
| `flutter analyze lib/` | 0 issues in touched files | 0 issues across `bookings_premium_header.dart` + `month_calendar_kpi_strip.dart` + `month_calendar_screen.dart` + `owner_bookings_screen.dart` |
| `flutter test` | green | this report |
| `dart format` | clean | this report |
| Bundle `projectId` | `bookbed-dev` verified | this report |
| FROZEN untouched | calendar repo / cjenovnik / unit wizard / Navigator.push / timeline_dimensions | this report |

---

## Open items / known caveats

- **AI nudge appearance:** the `_RezAINudge` only surfaces when the oldest pending booking has `waitHours >= 6`. Fresh fixture bookings (`created_at = serverTimestamp()`) have `waitHours = 0`, so AI nudge will not surface until the seed ages OR seed is rewritten to backdate `created_at`. Acceptable for this gate; can iterate.
- **Bookings ledger table** premium composition is DEFERRED — existing list+table stays as system-of-record beneath the premium hero.
- **Jedinice composition** is DEFERRED — chrome inherits from Phase B. User can request explicit composition.
- **`BbIconTile` open question** carried forward to Batch 3.

---

## Process notes

- Premium composition mirrors Pregled shape: eyebrow → H1 → KPI strip → AI banner → action queue → existing system-of-record list.
- New widgets reuse `UnifiedDashboardData` provider (no new query layers) and existing `FirebaseOwnerBookingsRepository` methods (no new business logic).
- All gradients/shadows via native Flutter `LinearGradient` / `BoxShadow` — no new pubspec deps.

---

**Status:** B2 ready for user gate at https://bookbed-owner-dev.web.app.
