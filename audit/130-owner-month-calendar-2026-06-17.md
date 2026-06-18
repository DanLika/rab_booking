# audit/130 — Owner Month Calendar (Mjesečni) — Handoff Fidelity Recon

**READ-ONLY recon. No code shipped. Wait for operator review before any edit.**
Branch `design/130-owner-month-calendar` @ `3ec80302` (clean off origin/main). 2026-06-17.
`build_runner` regenerated in worktree (exit 0) → branch implementation-ready.

---

## TL;DR (read this first)

1. **Owner month view = `month_calendar_screen.dart` (1517 LOC), LIVE, built on Syncfusion `SfCalendar`.**
2. **ZERO FROZEN-grid intersection.** The month view imports **none** of the 5 FROZEN concerns (timeline geometry, widget repo, price grid, timeline widget, Navigator.push). The entire fidelity pass is **SAFE chrome** — no per-edit sign-off needed *for the month view itself*.
3. **Palette already converged (audit/127).** Page bg = flat `context.gradients.pageBackground`. What's LEFT is **beyond-color visual fidelity** vs `calendar-month.jsx` — tuning the custom `SfCalendar` builders (cell + appointment-bar styling, legend, KPI, FAB).
4. **Two watch-outs (NOT FROZEN, but real):**
   - **Shared surface:** `month_calendar_kpi_strip.dart` is shared with the Timeline screen → KPI edits ripple to both (eyeball both).
   - **Mixed-bag TRAP:** `widgets/calendar/` holds widgets that belong to the **Timeline** *and the FROZEN Cjenovnik price grid* — a blind "restyle everything in widgets/calendar/" pass would hit FROZEN-adjacent code. See §3.2.

---

## 1. Base-verify (audit/127 confirmed in base)

`lib/core/theme/app_gradients.dart` (grep-verified, stored **flat** start==end):
- Light shell `_lightStart/_lightEnd = #F0F1F5` (:66–67)
- Dark page `_darkStart/_darkEnd = #000000` (:73–74)
- Dark card `_darkCard = #1E1E1E` (:94); dark section `#1E1E1E` (:106–107)

→ 127 handoff ladder + flat-chrome present. Color work for the month view is **done**; this recon is about everything *else*.

---

## 2. Location & scope (distinguished from the 3 confusables)

| Surface | File | LOC | This recon? |
|---|---|---|---|
| **OWNER month view** ← target | `lib/features/owner_dashboard/presentation/screens/calendar/month_calendar_screen.dart` | 1517 | ✅ |
| Shared KPI strip (month + timeline) | `…/presentation/widgets/calendar/month_calendar_kpi_strip.dart` | 195 | ✅ (shared) |
| Owner **Timeline** screen (hosts Timeline∣Mjesečni toggle) | `…/screens/owner_timeline_calendar_screen.dart` | 1257 | ⚠️ bridge only |
| Owner **Timeline** widget (custom grid) | `…/widgets/timeline_calendar_widget.dart` | 1839 | ❌ separate |
| **Cjenovnik** price grid (FROZEN) | `…/widgets/price_list_calendar_widget.dart` | 2572 | ❌ FROZEN |
| **Guest** booking-widget calendar | `lib/features/widget/data/repositories/firebase_booking_calendar_repository.dart` (+ `features/widget/presentation/widgets/month_calendar_widget.dart`) | 989 | ❌ guest |

**Navigation / entry (grep-proven):**
- Standalone route `OwnerRoutes.calendarMonth` → `const MonthCalendarScreen()` (`lib/core/config/router_owner.dart:157–161`). `MonthCalendarScreen` is instantiated **only** there → LIVE, not orphaned.
- Reached from the Timeline screen via an inline `_CalendarViewSwitch` segmented control that calls `context.go(OwnerRoutes.calendarMonth)`. The two screens **bridge by route**, neither embeds the other. (Same switch is duplicated inline in both screens — see §4 dup note.)

**Data source (grep-proven):** `month_calendar_screen.dart:19` imports `owner_calendar_provider.dart` → `calendarBookingsProvider` → `ownerBookingsRepositoryProvider`. **Owner-specific. NOT the FROZEN `firebase_booking_calendar_repository` (guest/widget).**

**Grid engine (grep-proven):** `month_calendar_screen.dart:7` imports `package:syncfusion_flutter_calendar/calendar.dart`. It is the **only** file in `lib/` using SfCalendar. Config: `CalendarView.month` (:84) toggling to `.schedule` (:132–134); `firstDayOfWeek: DateTime.monday` (:463); `MonthViewSettings(showAgenda: true, appointmentDisplayMode: MonthAppointmentDisplayMode.appointment)` (:474–478); **custom `monthCellBuilder` (:516)** + **custom `appointmentBuilder` (:583)** + `ScheduleViewSettings` (:520). → geometry is Syncfusion-managed + custom-builder-styled, **not** a hand-rolled fixed-pixel grid.

---

## 3. ★ FROZEN INTERSECTION MAP ★ (the #1 output)

### 3.1 — Does the month view touch each FROZEN concern?

CLAUDE.md "NIKADA NE MIJENJAJ" concerns, checked against `month_calendar_screen.dart` imports (grep: only `syncfusion` + `owner_calendar_provider`) and its whole widget tree:

| # | FROZEN concern | Touched by month view? | Evidence | Classification |
|---|---|---|---|---|
| 1 | **Calendar grid geometry** (fixed dims) | **NO** | Month grid = SfCalendar + custom builders (:474–516–583). Defines its **own** geometry. | none — own geometry |
| 2 | **`firebase_booking_calendar_repository.dart`** (989 LOC, guest/widget, "duplikacija NAMJERNA") | **NO** | Not imported. Uses `owner_calendar_provider` instead (:19). | none |
| 3 | **Timeline cell dimensions `timeline_dimensions.dart`** (50/42/100/60px) | **NO** | Not imported (grep clean). Timeline-only file. | none |
| 4 | **`price_list_calendar_widget.dart`** (2572 LOC, Cjenovnik) | **NO** (direct) | Not imported. ⚠️ but see §3.2 trap (`calendar_day_cell`). | none direct |
| 5 | **Navigator.push confirmation pattern** ("NE vraćaj state-based navigaciju") | **NO** | No `Navigator.push`/`context.push` in file (grep clean). Booking edit/create via `showDialog` (`BookingInlineEditDialog` :769–773, `BookingCreateDialog` :785–788); view switch via `context.go`. | none |

**Result: the month-view fidelity pass touches NONE of the 5 FROZEN concerns. It is 100% (a) value-consumption / pure SAFE chrome.** No (b) FROZEN code-line edits are required to do the handoff pass.

### 3.2 — The `widgets/calendar/` mixed-bag TRAP (must read before editing)

`widgets/calendar/` looks like "the month calendar's widgets" but is **shared/legacy** — importer greps prove most files belong to **Timeline** or the **FROZEN price grid**, NOT the month view:

| Widget in `widgets/calendar/` | Actually imported by | Month view uses it? | FROZEN risk if edited |
|---|---|---|---|
| `month_calendar_kpi_strip.dart` | month screen **+ Timeline screen** | ✅ YES (shared) | none, but ripples to Timeline |
| `calendar_top_toolbar.dart` | Timeline screen | ❌ | Timeline regression |
| `calendar_day_cell.dart` | **`price_list_calendar_widget`** | ❌ | **FROZEN-adjacent (Cjenovnik price grid)** → needs sign-off |
| `calendar_error_state.dart` | `timeline_calendar_widget` | ❌ | Timeline regression |
| `booking_drop_zone.dart` | `timeline_calendar_widget` | ❌ | Timeline regression |
| `skewed_booking_painter.dart` | `booking_block_widget` + `timeline/timeline_booking_block` | ❌ | Timeline regression |
| `room_row_header.dart` | (no importers found — orphan) | ❌ | — |

→ **Rule for the implementation phase:** restyle **inside `month_calendar_screen.dart`** (its inline classes + SfCalendar builders) and **`month_calendar_kpi_strip.dart`** ONLY. Do **not** touch other `widgets/calendar/*` files thinking they're month-view — `calendar_day_cell.dart` in particular feeds the FROZEN price grid.

---

## 4. Design-system + flatten audit (month-view scope only, beyond color)

Scope corrected to what the month view *actually* renders (a parallel agent's P2/P3 hits on `calendar_top_toolbar`/`calendar_day_cell`/`calendar_error_state` were **out of scope** — those are Timeline/price-grid files, §3.2).

**Code hygiene of the in-scope files = GOOD:**
- `month_calendar_screen.dart`: HIGH `BB*` adoption (BBColor.status*, BBType.h1/.eyebrow/.caption, BBSpace, BBRadius, BBShadow, BBMotion). Page bg = `context.gradients.pageBackground` (:203) — the **only** gradient in the file, and it's the correct flat token. No raw `LinearGradient`. CommonAppBar wired `showTitle:false` (no double-header — per audit/126 §2A). Premium chrome present: inline `_PremiumCalendarHeader` (eyebrow + "Kalendar" h1 + Timeline∣Mjesečni switch), `_CalendarGridCard`, `_MonthStatusLegend` (Bb*-clean), `_AnimatedGradientFAB` (despite the name, **no** literal gradient code — flat-compliant).
- `month_calendar_kpi_strip.dart`: EXCELLENT `BB*` adoption (`BBColor.of(context)`, BBType). Minor magic spacing (`SizedBox(10/12)`, `height:2`) — cosmetic, not fidelity-critical.

**Minor in-scope nits (P3/P4, optional):** a few magic pixel literals (KPI gaps 10/12px; skeleton `EdgeInsets.fromLTRB(16,12,16,4)`). Note `BBSpace.xs2(=12)` is **deprecated-on-use** — for any 12px need use an in-file `const` (per audit/128 / memory `bbspace-xs2-deprecated-use-named-const`).

→ **The month view is already token-clean and flat.** This is NOT a token-hygiene campaign. The real work is §5.

---

## 5. Handoff target & beyond-color fidelity gaps

**Dedicated owner handoff EXISTS & CONFIRMED owner-facing:** `design_handoff/source/calendar-month.jsx` (full file ~1–442), wired in `BookBed Design.html:49`, section **"Kalendar — Mjesečni"** (HTML :153–167) with Desktop/Tablet/Mobile artboards (1440/768/390). Owner evidence: sidebar+AppBar chrome, owner toolbar ("Idi na…/Danas/Filteri/Nova rezervacija"), all-units month grid ("4 jedinice"), per-booking guest/unit/status metadata, owner KPI strip. The **guest** widget calendar is a separate render (`widget-calendar.jsx`) — not this.

**Target spec (the fidelity bar):**
- **Shared chrome:** eyebrow ("Lipanj · 4 jedinice") + "Kalendar" h1 (28px bold) + segmented Timeline∣**Mjesečni** (active = soft shadow); KPI strip 4-col (Popunjenost/Rezervacije/Dolasci·7d/Slobodne noći; tinted 36×36 icon circles, radius-md); legend row ("Status:" + 5 status badges + right-aligned "N rezervacija · M jedinice"); month-grid **card** (1px border, radius-md, shadow-card, internal legend header); month nav (chevrons + month-picker w/ shadow-sm).
- **Desktop/Tablet grid:** Monday-start 7-col; weekday header (weekends in secondary color); cells with "today" ring (primary, 24px) + subtle weekend tint `rgba(255,184,77,0.05)`; out-of-month dimmed. **Google-Calendar-style multi-day spanning booking bars** (22px desktop / 20px tablet), greedy lane-packing, guest name + "Xn" night count (if span ≥3d) + continuation chevrons, 6px radius, inset highlight.
- **Mobile:** compact 52px cells = day number + up to 3 status **dots** (5×5px); selected-day ring (22px); **day agenda panel** below (kind icon login/logout/hotel, guest+unit+kind, status badge).

**Structural alignment (Flutter vs handoff) — already largely in place:**
- ✅ Monday-start (:463), appointment-mode spanning bars (:478), agenda/schedule view (:475/:520), custom cell + appointment builders (:516/:583), 5px status dots, premium header + KPI strip + legend card all exist.

**Beyond-color GAP CANDIDATES (require live side-by-side render to confirm — implementation phase, NOT confirmed here):**
1. **Appointment-bar fidelity:** do the custom `appointmentBuilder` (:583) bars match the handoff's lane-packed bars with night-count + continuation chevrons + inset highlight + 6px corners? (Syncfusion's default packing vs handoff's greedy lanes.)
2. **Month cell fidelity:** `monthCellBuilder` (:516) "today" ring (24px primary), weekend tint, out-of-month dimming vs handoff.
3. **Mobile dots+agenda:** confirm ≤3 dots + agenda item layout (kind icon / status badge) match.
4. **KPI labels/tints:** "Dolasci·7d" + "Slobodne noći" copy & tone tints match handoff 4-col.
5. **Legend & month-nav chrome:** legend row format + month-picker shadow-sm.
6. **Premium-header dedup:** the Timeline∣Mjesečni switch + header is duplicated inline in both screens (flagged in-file ~:1079–1087 for extraction to a shared `BbSegmentedControl`/`BbPremiumHeader`). Optional refactor; cosmetic-neutral.

All of the above live in `month_calendar_screen.dart` builders/inline classes + `month_calendar_kpi_strip.dart` → **SAFE**.

---

## 6. Proposed scope split (for operator GO)

### ✅ SAFE — chrome/token, NO sign-off (the whole month-view pass)
- `month_calendar_screen.dart`: SfCalendar `monthCellBuilder`/`appointmentBuilder`/`MonthViewSettings`/`ScheduleViewSettings` styling; inline `_PremiumCalendarHeader`, `_CalendarGridCard`, `_MonthStatusLegend`, `_AnimatedGradientFAB`, `_CalendarViewSwitch`.
- `month_calendar_kpi_strip.dart` — **with shared-surface caveat:** also rendered on the Timeline screen → verify both screens after any KPI edit.

### 🔒 FROZEN — needs explicit per-edit GO
- **None invoked by the month-view fidelity pass.** The month view consumes no FROZEN file (§3.1).
- **Watch-outs (do NOT edit as "month-view"):** `calendar_day_cell.dart` (→ FROZEN Cjenovnik price grid), `calendar_top_toolbar.dart` / `calendar_error_state.dart` / `booking_drop_zone.dart` / `skewed_booking_painter.dart` (→ Timeline). Editing any of these = a Timeline/price-grid change requiring its own review, NOT part of this pass.

### Next step (gated on operator review)
1. Live-render `calendar-month.jsx` (Babel harness) as the visual TARGET; launch `flutter run` (main_dev) and diff the month view section-by-section across Desktop/Tablet/Mobile + light/dark. Seed: `scripts/seed-mcal-eyeball-dev.js` (already present, untracked).
2. Ledger each divergence (§5 candidates), fix SAFE-scope only, add overflow/golden coverage, attest with per-breakpoint side-by-side.
3. **STOP here. No code until GO.**

---

## 7. PHASE 1 — Render + Live Diff (confirmed-gap ledger)

**Method.** Target = `calendar-month.jsx` artboards (`cal-mo-desktop/tablet/mobile`) served over HTTP, isolated onto a clean stage, class-swapped `theme-light`↔`theme-dark`, screenshot at 1440×1100 / 768×1024 / 390×880. Live = `flutter run -d web-server :8091` (main_dev), bookbed-test owner (auth persisted), seeded 5 clean June bookings on "Studio B" (`SEED_rez_smoke_unit_b`), captured at the same 3 widths × light/dark via chrome-devtools (`emulate` colorScheme = the app follows `ThemeMode.system`). Shots in `audit-shots/cal-{target,live}-{w}-{theme}.png` (12).

**⚠ Capture caveat (CanvasKit paint timing).** SfCalendar paints day-cells first, then the appointment layer ~1–2 s later; **resizing** a mounted calendar does NOT re-trigger the appointment paint. Reliable recipe per width: set viewport → **re-navigate `overview`→`month` (fresh mount)** → wait ~2.5 s (rAF flush) → screenshot. Theme toggle (`emulate`) re-paints live without remount. (Early "empty grid" screenshots were this artifact, not real — a11y tree confirmed all 5 guests bound.)

**Live month cell anatomy** (from `_buildMonthCell` :597 + `appointmentDisplayMode.appointment`): date number (top-left) + **count-badge "1"** (top-right) + **status dots** + a **thin spanning appointment bar** that shows the guest name only when its height >40 px (`:816` gate) — so desktop/tablet bars are thin & unlabeled, mobile single-booking bars show the name. This is a hybrid (badges+dots+thin-bars), NOT the handoff's chunky labeled bars.

### ✅ Already matches (honest — several do)
Eyebrow `LIPANJ 2026 · 4 JEDINICE` + `Kalendar` H1 + Timeline∣Mjesečni segmented toggle · KPI strip (4 tinted-icon tiles + values, card style; 2×2 wrap on mobile) · today-ring (17) · Monday-start weekday header (PON–NED) · status colors (green/amber/purple) · month-nav `‹ lipanj 2026 ›` present (w/ date-picker) · out-of-month dimming · flat surfaces + **127 light/dark palette (OLED-black dark correct)**.

### Confirmed gaps (scope = `month_calendar_screen.dart` + `month_calendar_kpi_strip.dart`)

| # | Gap (live → handoff) | Bp | Theme | Cost | Proposed fix |
|---|---|---|---|---|---|
| **G1** | Booking bars: **thin unlabeled lines + "1" badge + dots** → handoff **chunky ~22 px bars w/ guest name + night-count + continuation chevrons (‹ ›), lane-packed** | desktop+tablet | both | **FRAMEWORK** ⚠ | SfCalendar month + `monthCellBuilder` can't natively render tall labeled lane-packed bars. Options: drop `monthCellBuilder`, force taller appointments + rich `appointmentBuilder` (fights SfCalendar month packing/overflow), **or** custom month-grid painter. High-risk → **feasibility spike before committing.** |
| **G2** | Mobile = shrunk desktop grid w/ bars → handoff **dots grid + day-agenda panel** (tap day → booking list w/ kind-icon/guest/unit/status) | mobile | both | **FRAMEWORK (partial)** | `monthCellBuilder` already draws dots → at <600 px suppress bars, keep dots, add day-agenda `ListView` bound to selected day (or reuse SfCalendar `schedule` view, already wired via `_currentView`). Medium-high. |
| **G3** | Legend: live **4 chips, missing "Uvezeno"** (imported); no trailing `N rezervacija · M jedinice` stat | all | both | **CHEAP** | add Uvezeno chip + trailing stat in `_MonthStatusLegend` (:1345) |
| **G4** | Weekend emphasis: handoff tints SUB/NED columns + amber weekend dates; live tints **current-weekday** header instead, no weekend tint | all | both | **CHEAP** | weekend bg tint + amber date color in `_buildMonthCell` decoration |
| **G5** | KPI label `DOLASCI` → handoff `DOLASCI · 7D` | all | both | **CHEAP** | label string in `month_calendar_kpi_strip.dart` |
| **G6** | Toolbar composition: handoff **labeled row** (`‹ month › · Idi na… · Danas · Filteri · + Nova`); live = appbar icons + in-card month-nav + **FAB** + unit dropdown (actions PRESENT, arranged differently) | desktop+tablet | both | **MEDIUM** | optional recompose to labeled toolbar; or accept FAB pattern (functional parity). Low priority. |
| **G7** | Live surfaces a full-width **"Smještajni objekt" unit dropdown**; handoff hides unit filter behind **Filteri** | all | both | **MEDIUM** | optional: move into Filteri dialog to match; or keep (extra utility). Low priority. |

### 🔻 Out-of-scope (GLOBAL chrome — NOT month-view; already tracked in audit/126)
- **Persistent left sidebar / icon-rail** (handoff) vs **hamburger drawer** (live) — audit/126 **§3B deferred**.
- **Top app bar**: breadcrumb `Kalendar › Mjesečni` + search + theme + bell + avatar (handoff) vs hamburger + 2 icons (live) — audit/126 **§2B deferred**.
- These appear in every diff shot but must NOT be "fixed" inside the month view.

### Recommendation (operator picks the fix subset)
- **Do now (clear wins, low risk):** G3 + G4 + G5 — pure styling in the two in-scope files.
- **Decide after a spike:** G1 (bars) and G2 (mobile) are the high-value, high-risk items that define "tune vs rebuild". Recommend a short SfCalendar **feasibility spike** for G1 (can we get handoff-fidelity bars without abandoning SfCalendar month / without touching FROZEN?) before committing. Month view is NOT FROZEN, but a bespoke month grid is a large lift.
- **Optional / defer:** G6, G7 (functional parity already; arrangement-only).

**STOP — Phase 1 complete. No fixes applied. Awaiting operator selection of the fix subset.**

---

## 8. Phase 2 — G1 + G2 spike (READ-ONLY) + G3/G4/G5 applied

### Applied (A): G3 (honest half) + G4 + G5
- **G5** — `month_calendar_kpi_strip.dart`: `Dolasci` → `Dolasci · 7d` (→ "DOLASCI · 7D"). HONEST: `upcomingCheckIns` IS a 7-day window (`firebase_owner_bookings_repository` `next7Days = now + Duration(days:7)`, "next 7 days").
- **G4** — `_buildMonthCell`: weekend (SUB/NED) cell tint `BBColor.tertiary`@5% + amber weekend date number (`tertiary`/`tertiaryDarkMode` = handoff "Golden Sand" #FFB84D/#FFC872; token, no hex). In-month only (out-of-month dim wins; today-ring unchanged).
- **G3** — `_MonthStatusLegend`: added trailing `N rezervacija · M jedinice` stat (desktop/tablet only; Croatian count-agreement; reuses `_PremiumCalendarHeader._unitsWord`; counts = `filteredBookings.length` + `units.length`). **"Uvezeno" chip REJECTED** — the legend's own comment already documents it's omitted because the month grid renders no imported tone (`_getBookingColor` = 4 statuses; provider fetches `bookings`, not `ical_events`); adding a chip for an un-rendered status would mislead (data-honesty, audit/129 lesson). Surfacing imported events on the calendar = a feature (data-layer), not styling → deferred.
- Attest: `dart format` (1 file changed) · `flutter analyze` 2 files = **No issues found (0 net-new)** (project's 98 `info` lints all pre-existing in unrelated widget/test files) · **full suite "All tests passed!" +1535** (incl. `calendar_chrome_responsive_test`, which renders the modified legend) · **`flutter build web --target lib/main_dev.dart --no-tree-shake-icons` clean** ("✓ Built build/web", 38s). C render (served the built app on :8091, auth-preserving origin): `audit-shots/cal-applied-{1440,768,390}-{light,dark}.png` (6) — all three changes confirmed both themes, bar/badge/dot rendering un-regressed, legend stat correctly dropped on mobile (no overflow).

### Spike (B) — G1 + G2 (no code written)

**G1 — chunky labeled spanning bars (desktop/tablet).**
Current: SfCalendar month + custom `monthCellBuilder` (date + count-badge + dots) + `appointmentDisplayMode.appointment` + `appointmentBuilder`; bars overlay cells. The rich `_buildScheduleAppointment` (name + unit·Xn + status badge) ALREADY exists but is gated to `bounds.height > 40` (`:816`); month bars (≤40px) use name-only `_buildMonthAppointment`.
- **Closest achievable in SfCalendar (TUNE ≈85%):** de-clutter cell (drop badge+dots from `_buildMonthCell`, keep number) → number+bars like handoff [CHEAP]; add "Xn" to `_buildMonthAppointment` → labeled ~22px bars [CHEAP]; lane-packing is NATIVE; inset-highlight + rounded corners [CHEAP].
- **Residual gap (tune-only ≈15%):** (1) **bar height** — SfCalendar month has NO direct appointment-height knob (height = cell ÷ stacked-appt count), so consistent ~22px isn't fully controllable; bars shrink as a day stacks. (2) **continuation chevrons (‹ ›) + square-corner-at-week-wrap** — SfCalendar splits multi-week spans into per-week segments but passes NO start/end/continues flag to `appointmentBuilder`; must infer by comparing booking dates to the segment week → fiddly, mild framework-fight; exact chevron + per-end radius is the cosmetic residual.
- **Lift IF rebuilt bespoke (NOT default):** hand-rolled 7-col grid + per-week lane-packing spanning-bar engine + hit-testing + today/weekend/out-of-month + agenda = ~400–600 LOC new widget replacing the SfCalendar month path, re-implementing calendar correctness SfCalendar gives for free. Est. ~2–4 focused days + tests; risk = re-introducing calendar bugs. (Month view is NOT FROZEN, so permitted — but large.)
- **Recommendation: TUNE + accept residual.** Cheap wins land most of it; accept imperfect bar-height/chevron fidelity. **Rebuild only on an explicit operator pixel-fidelity case.**

**G2 — mobile dots + day-agenda.**
Current: mobile = same month grid + thin bars; `_buildMonthCell` ALREADY draws status dots (≤4, `:682`).
- **Closest achievable in SfCalendar (TUNE ≈90%, NO framework fight):** suppress thin bars at mobile (`appointmentBuilder` → `SizedBox.shrink()` when mobile+month) → dots-only grid [CHEAP]; selected-day ring is NATIVE (`selectionDecoration` already set); add `_selectedDay` state (from `onTap` `details.date`) + a ListView below the grid of that day's bookings (kind-icon + guest + unit + status badge) bound to `filteredBookings` — NEW in-scope widget (~80–120 LOC), standard Flutter. (SfCalendar's `schedule` view exists but is a separate full view, not grid-on-top + agenda-below.)
- **Residual:** only exact agenda-card styling (cosmetic).
- **Recommendation: TUNE / DO.** Achievable in-scope without fighting SfCalendar; medium lift; bigger mobile-fidelity win than G1.

### Spike bottom line
- **G1:** tune to ~85%, accept residual; bespoke rebuild = large lift + correctness risk → explicit case only.
- **G2:** tune/do — achievable, no framework fight, ~100 LOC.
- Neither needs FROZEN (month view consumes none, §3) nor the two out-of-scope files.

---

## 9. G1 + G2 APPLIED (on top of G3/G4/G5; scope = the 2 files)

**G1 (tune):**
- De-cluttered month cell — count-badge dropped; status dots now **mobile-only** (`_buildMonthCell` gains `isMobile`). Desktop/tablet cells = date number + bars (handoff).
- Appointment bars: trailing night-count **"Xn"** (`_buildMonthAppointment`, width ≥ 80) + **inset highlight** (white 18% border ≈ handoff `inset 0 0 0 1px rgba(255,255,255,.18)`).
- Native lane-packing kept. Per instruction: did **NOT** pursue fixed bar-height or continuation chevrons.

**⚠ ACCEPTED RESIDUAL (SfCalendar month framework limit):** appointment bar height = (cell appointment area ÷ stacked-appt count); SfCalendar exposes **no direct month-appointment-height knob**, so bars stay thin and shrink as a day stacks more bookings — "Xn"/name only render when a bar is tall/wide enough. Multi-week spans split into per-week segments with **no continuation flag**, so continuation chevrons (‹ ›) + square-corner-at-week-wrap are **not implemented**. Both accepted as framework limits (bespoke grid = deferred, §8 spike).

**G2 (do):**
- Mobile = **dots grid + day-agenda**. Bars suppressed on mobile+month (`_buildAppointmentWidget` early return); dots kept via the `_buildMonthCell` mobile gate; native selected-day ring (`selectionDecoration`).
- `_handleCalendarTap` mobile: tapping a day sets `_selectedDay` (no dialog) → drives the agenda; agenda items → edit dialog; FAB → create.
- New `_buildDayAgenda` + `_agendaItem`: bookings covering the selected day (default today), kind icon (Dolazak/Odlazak/Boravak = login/logout/hotel) + guest + unit + status badge; header "`<Pon>, DD. <genitiv>`" + "N rezervacija".
- **⚠ Double-agenda avoided** (operator flag): `MonthViewSettings.showAgenda` → `!isMobile` so SfCalendar's built-in month agenda is OFF on mobile and does not render alongside the custom one.
- **l10n debt:** agenda HR strings (weekday short, genitive months, kind labels, empty state) inlined — l10n keys are outside this 2-file scope; tracked with the screen's pre-existing l10n debt.

**Attest:** `dart format` · `flutter analyze` 2 files **No issues (0 net-new)** · full suite + web build (see below) · render `audit-shots/cal-final-{1440,768,390}-{light,dark}.png`. Mobile day-agenda interactivity (tap a day → agenda updates) is verified live on :8091 — golden/widget tests don't cover it.
