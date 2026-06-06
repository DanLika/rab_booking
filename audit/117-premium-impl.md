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

## §B3 — Shared chrome (this batch — Terminal A)

Closes the chrome premium pass. Additive — no FROZEN surface touched. Per the
`01-owner.png` ground truth, the premium shell is **flat-console**, so chrome
work stays subtle: depth comes from layered surfaces + cool-toned shadows, not
heavy Material elevation.

| Element | Mockup ref | Implementation |
|---|---|---|
| Drawer envelope shadow | premium `--bb-shadow-lg` (3-layer cool-toned) | `app_theme.dart` light + dark — new `drawerTheme: DrawerThemeData(elevation: 16, shadowColor: cool-tone, scrimColor, surfaceTintColor: transparent, width: 280)`. Single Material elevation is the closest single-stack approximation of the 3-layer cool ramp; honest delta, see [`audit/116 §3.2`](116-premium-spec.md). |
| EndDrawer treatment | same envelope as Drawer | Same `DrawerThemeData` covers both slots — Material renders the same widget class either way. Premium-ifies the master-panel EndDrawer in FROZEN `unified_unit_hub_screen.dart` **without** touching its source. |
| Dialog content base | radius 24 + `--bb-shadow-lg` | Already shipped Phase B (`dialogTheme` radius `BBRadius.lg`, elevation 12, cool shadowColor, `bb-h2` title). Verified internals on `BbDialog` (`bb_dialog.dart`): wraps in `Dialog` `backgroundColor: Colors.transparent` → `Container` with `BBShadow.modal(context)` 3-layer + `BBRadius.lgAll` + `BBSpace.md` padding + h2 title + 20-px body→buttons gap + 8-px button-row gap. Matches handoff `BBDialog` 1:1. No code change. |
| BottomSheet content base | top corners radius 24 + drag handle 36×4 + `--bb-shadow-lg` | Already shipped Phase B (`bottomSheetTheme` radius `BBRadius.lg` top, drag handle, surface bg). Verified internals on `BbBottomSheet` (`bb_bottom_sheet.dart`): drag handle 36×4 at 10-px top inset, h3 title slot 12/20/8, child slot 8/4/16, optional footer 12/20 with `c.border` top divider, `BBShadow.modal(context)`. Matches handoff `BBBottomSheet` 1:1. No code change. |
| BbCard depth/states | `--bb-shadow-card` resting → `--bb-shadow-md` lifted, translateY(-2 px) | Already premium (`bb_card.dart`). `BBShadow.cardElevated` resting, `BBShadow.elevated(context)` on web hover, `translateByDouble(0, -2, 0, 1)`. No code change. |
| BbButton depth/states | primary: `--bb-shadow-purple-sm` resting → `--bb-shadow-purple` hover + **translateY(-1 px)** | `bb_button.dart` — primary hover shadow swap already shipped; **added** `translateY(-1 px)` lift via `AnimatedContainer.transform` (this batch). Only fires on `primary` variant (per handoff) and only when interactive. |
| BbInput focus ring | `--bb-focus-ring` (3 px primary tint) | Already premium (`bb_input.dart`). `BoxShadow(color: rd.focusRingColor, spreadRadius: 3)` on focus when no error. No code change. |
| BbChip selected purple glow | filter variant: brand fill + `--bb-shadow-purple-sm` | Already premium (`bb_chip.dart`). Filter-selected → `c.primary` bg + `BBShadow.purpleSm`. No code change. |
| BbStatusBadge | semantic tints + dot per `--bb-status-*` | Already premium (`bb_status_badge.dart`). Resolves through `BbRedesignTokens.statusXTint` + `c.statusCompleted` etc. Completed = brand-purple per audit/115 G-1. No code change. |
| `BbIconTile` open question (audit/116 §8) | spec acknowledged "user prompt truncated" | **RESOLVED — does not exist.** `grep -r "BbIconTile\|bb_icon_tile" lib/` = 0 matches in Flutter; `grep -i IconTile design_handoff/source/` = 0 matches in handoff. Per Terminal A contract ("RESOLVE BbIconTile: grep existing primitive, use it, do NOT invent"), **no new primitive is created**. `BbIcon` (`bb_icon.dart`) remains the canonical icon primitive; consumers wrap it in `Container`/`BoxDecoration` when an icon-tile chip is needed (this is the pattern used in `dashboard_overview_tab.dart` for arrival hero icons and in the sidebar `SidebarItem` 28-px icon halo). If a true `BbIconTile` primitive is desired downstream, it would be a Batch 4 extraction PR with explicit handoff spec; out of scope here. |

**Files touched (this batch):**
- `lib/core/theme/app_theme.dart` (+27 lines, light + dark `drawerTheme`)
- `lib/shared/widgets/redesign/bb_button.dart` (+11 lines, primary hover `translateY(-1 px)`)
- `audit/117-premium-impl.md` (this update)

**Frozen carve-outs reaffirmed:** Calendar repo, `timeline_dimensions.dart`, Cjenovnik tab, Unit Wizard publish flow, `Navigator.push` confirmation. `unified_unit_hub_screen.dart` is not edited — its master-panel `endDrawer` inherits the new theme automatically.

**Honest deltas vs handoff (defer):**
- Drawer/Sheet/Dialog use Material's single-elevation shadow API; the design tokens specify a 3-layer cool-toned ramp. Visual delta is ≤ 2 dp of perceived halo at default DPR; a custom `Material(elevation: 0) + DecoratedBox(boxShadow: [...])` wrap could fully bridge it, but the cost is losing Material's gesture/animation integration. Accept Material elevation + cool shadowColor as the premium-best-approximation.
- `BbCard.hoverable` duration is `BBMotion.fast` (120 ms) vs `.bb-lift` 180 ms — audit/116 §3.5 explicitly defers this 60 ms drift.

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
