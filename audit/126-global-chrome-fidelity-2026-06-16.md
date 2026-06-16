# audit/126 — Global Chrome Fidelity (page bg / AppBar / Drawer) vs handoff

**Date:** 2026-06-16 · **Type:** READ-ONLY audit (no code, no commit) · **Scope:** GLOBAL/SHARED owner chrome
**Method:** 3 Explore agents + direct greps. Every `file:line` below taken from live source this session.

## Why this exists

The premium-fidelity campaign (audit/124) polished screens one-by-one — Pregled (`07a9caf7`), Rezervacije (`420b48ed`), Timeline/Kalendar (`b9656008`). It never audited the **shared chrome layer** — page backgrounds/gradients, `CommonAppBar`, `OwnerAppDrawer` — as a thing in itself. This doc maps current state vs the design handoff ground-truth, surfaces the divergences (incl. a confirmed double-header), and hands the operator decision options with scope + blast-radius. Operator picks the fix scope; this doc changes no code.

**Blast-radius flag up front:** all three elements are GLOBAL/SHARED. A change to the *widget/token* hits every screen; a change to a *call site* is scoped. Even the cheapest pass below needs an **all-screen light+dark regression sweep**, not a single-screen eyeball.

---

## A. Page backgrounds / gradients

### Centralized token
`lib/core/theme/app_gradients.dart` + `lib/core/theme/gradient_extensions.dart` → `context.gradients.pageBackground` (TIP-1: simple 2-color, 2-stop diagonal).

| Theme | `pageBackground` | Direction | Stops |
|---|---|---|---|
| Light | `#ECEDF2` → `#FFFFFF` | topLeft → bottomRight | `[0.0, 0.3]` |
| Dark | `#1A1A1A` → `#2D2D2D` | topLeft → bottomRight | `[0.0, 0.3]` |

`sectionBackground` = same colors, topRight → bottomLeft. `#ECEDF2` already replaced the old flat `#F0F1F5` / spec `#F8F9FA` (comment app_gradients.dart:65); no `F8F9FA` remains in code.

### Current state per screen (owner_dashboard)
- **TIP-1 gradient — 19 screens:** Pregled (dashboard_overview_tab.dart:58), Rezervacije (owner_bookings_screen.dart:569), Timeline (owner_timeline_calendar_screen.dart:344), Mjesečni (month_calendar_screen.dart:202), unified_unit_hub:275 + notifications, notification_settings, change_password, edit_profile, property_form, unit_form, unit_pricing, stripe_connect_setup, widget_settings, ai_assistant, embed_help, faq, ical_export_list.
- **Legacy flat `rd.shellBg` (#F0F1F5 light / #000 dark) — 4 stragglers:** profile_screen.dart:146, about_screen.dart:42, owner_booking_detail_screen.dart:49, ical_sync_settings_screen.dart:99.
- **Transparent outlier — 1:** embed_widget_guide_screen.dart:64.

### Handoff ground-truth
`design_handoff/source/tokens.css`: page bg is **FLAT** — `--bb-bg` = `#FAFAFA` (light) / `#000000` (dark), applied `body { background: var(--bb-bg); }` (tokens.css:54, 141, 220). **No page-level gradient anywhere in the handoff.**

### Ledger — "gradient vs flat", resolved
- Handoff = **flat**. The TIP-1 page gradient is **not in the handoff**; it is an intentional **user-driven override** (standing global preference explicitly mandates TIP-1 2-color/2-stop diagonal for backgrounds & sections). → *Deliberate divergence, not a bug.*
- Dark nuance: handoff dark page = pure `#000`. The 4 legacy-flat screens' dark (`#000`) match handoff *better* than the gradient (`#1A1A1A→#2D2D2D`). Migrating them to gradient moves dark *away* from handoff but *toward* internal consistency.
- **Real defect = inconsistency:** 5 screens bypass the centralized token (4 flat + 1 transparent).

---

## B. AppBar — `CommonAppBar`

### Definition
`lib/shared/widgets/common_app_bar.dart` — pure pass-through over Material `AppBarTheme` (theme-driven, no BB* used directly). Tokens resolve from `lib/core/theme/app_theme.dart`:

| | Light | Dark |
|---|---|---|
| background | `shellBgLight` #F0F1F5 | `shellBgDark` #000000 |
| elevation / scrolledUnder | 0 / 1 (hairline) | 0 / 1 |
| toolbar height | 56px | 56px |
| title | titleLarge w600 20px, `#2D3748` | … `#E2E8F0` |

**Blast radius: ~33 files** reference `CommonAppBar` (28 owner + 3 auth-legal + subscription + the def). Touching the **widget/theme** = all-surface regression. Touching a **call-site title** = scoped.

### Double-header (key finding)
Premium screens render the title **twice** — top AppBar **and** an in-body premium header:

| Screen | AppBar title | In-body premium header | Verdict |
|---|---|---|---|
| Mjesečni | "Month Calendar" (month_calendar_screen.dart:176) | eyebrow + **"KALENDAR"** (`_PremiumCalendarHeader` :1107/1166) | **literal duplicate** |
| Timeline | "Calendar" (owner_timeline_calendar_screen.dart:336) | eyebrow + **"KALENDAR"** (:1024/1083) | **literal duplicate** |
| Rezervacije | "Bookings" (owner_bookings_screen.dart:560) | eyebrow "PREGLED SVIH REZERVACIJA" (`BookingsPremiumLedgerHeader`) | redundant chrome |
| Pregled | "Overview" (dashboard_overview_tab.dart:52) | eyebrow + greeting "Dobro jutro, {name}" | redundant chrome (no literal dup) |

### Handoff ground-truth
`primitives.jsx` `BBAppBar` (:587) + `pregled-premium.jsx`: handoff **HAS** a top bar (56px, `var(--bb-surface)` bg, 1px bottom border) — but its content is **not a bare repeated title**:
- Desktop = **breadcrumb** (`['Početna','Pregled']`, pregled-premium.jsx:450).
- Mobile = **title + hamburger** + actions (pregled-premium.jsx:555).
- Plus a **separate** in-body header (eyebrow + greeting) → no redundancy in the handoff.

### Ledger
Handoff expects a top bar → **don't strip it entirely**. Divergence = live puts a **bare repeated title** in the bar (duplicating the in-body title on the calendar screens); handoff puts breadcrumb (desktop) / title+hamburger (mobile). Secondary: live bar bg = `shellBg`, handoff = `--bb-surface` (confirm surface value before any retheme). **Non-premium screens (~29) have no in-body header → their AppBar title is their only title and must stay.**

---

## C. Drawer — `OwnerAppDrawer`

### Definition
`lib/features/owner_dashboard/presentation/widgets/owner_app_drawer.dart` — "dissolved sidebar" intent (no purple banner; comment :223). Token sources are **mixed**:
- Background: `context.gradients.pageBackground`.
- Header: `rd.shellBg` + `rd.panelBorder` (BbRedesignTokens).
- Items: `BBColor.primary` tints (selected .12/.15, hover .06/.08), icons #6B4CE6 / #8B6FFF.
- Unselected text/icon: `theme.colorScheme.onSurface`.
- Badges: `colorScheme.danger` (pending) + raw `Colors.amber.shade700/600` (notifications).
- Light + dark both handled.

### Attachment / breakpoints
Slide-out `drawer:` (hamburger) on **every** owner screen, **all breakpoints** (≈19 call sites). **No persistent desktop sidebar / tablet rail exists.**

> Clarification on the user's "desktop component instead of endDrawer" note: that refers to the **unit-hub master-detail panel** — unified_unit_hub_screen.dart `endDrawer: !isDesktop` (:248) with desktop replacement `_buildDesktopLayout` Row (:292). That is a **units-list master panel**, NOT global nav. It already uses `context.gradients.sectionBackground` on both the desktop panel and its endDrawer twin → already consistent. It is *not* the global `OwnerAppDrawer`.

### Handoff ground-truth
`primitives.jsx`: persistent **`BBSidebar` 260px** (desktop — `var(--bb-surface)` + right border, logo + search + nav groups Glavno/Upravljanje/Pomoć + profile) + **`BBSidebarRail` 72px** (tablet, icon-only) + **hamburger** (mobile, no sidebar). Premium screens dissolve chrome via `PV_TRANSPARENT_CHROME`.

### Ledger
Styling already matches handoff's "dissolved" intent; tokens are *partially* BB* (mixed with `colorScheme` / BbRedesignTokens / raw amber). Big structural gap = **no persistent desktop sidebar / tablet rail** — live is slide-out everywhere.

---

## D. Centralization summary
Three single sources exist (good): `app_gradients`/`context.gradients`, `AppTheme.appBarTheme` + `CommonAppBar`, `OwnerAppDrawer`. Divergence lives almost entirely at **call sites**: 5 screens bypass the gradient token, 4 screens double-title, drawer token sources are mixed.

---

## Decision options (per element — operator picks)

### 1. Page background
- **A. Handoff-strict** — drop gradient, flat surface everywhere. *Contradicts the standing TIP-1 preference; not recommended unless the user reverses.* Blast: 19 screens + token.
- **B. Keep gradient + finish migration** ✅ — migrate the 5 stragglers (profile, about, owner_booking_detail, ical_sync_settings → gradient; decide on embed_widget_guide). Honors the preference, fixes the real inconsistency. Blast: **5 call sites**, one-line decoration swap each, light+dark eyeball.
- *(Optional token tweak: light start `#ECEDF2` → bluer/grayer to taste — 1 constant, but a 19-screen visual shift → full sweep.)*

### 2. AppBar (double-header)
- **A. Strip the bare title on the 4 premium screens** ✅ — keep hamburger + actions; the in-body header owns the title. Kills the literal duplicate, matches handoff-mobile intent. Blast: **4 call sites** (scoped — `CommonAppBar` unchanged, other ~29 surfaces safe). Needs a title-less path in `CommonAppBar`.
- **B. Breadcrumb mode** — desktop breadcrumb + mobile title+hamburger (full handoff fidelity). Blast: touches shared `CommonAppBar` (~33 surfaces, additive) + responsive logic. Larger follow-up.
- **C. Keep AppBar title, drop in-body header** — ✗ contradicts the recent premium-header investment (now canonical). Reject.
- *(Micro: retheme bar bg `shellBg` → `--bb-surface` once the handoff surface value is confirmed.)*

### 3. Drawer
- **A. Tokenize to BB*** ✅ — normalize mixed sources (`colorScheme` / `rd.shellBg` / raw amber) to BB* where tokens exist. Cosmetic-neutral hygiene. Blast: **1 file**, drawer light+dark eyeball.
- **B. Persistent desktop sidebar + tablet rail** — full handoff nav layout. Blast: **VERY HIGH** — every owner Scaffold (~20) restructured to Row[rail, content] + a new responsive shell. Separate epic; do NOT bundle.
- **C. Leave as-is** — accept slide-out-everywhere as a deliberate simplification; document the desktop-sidebar gap as deferred.

---

## Recommendation

**1B + 2A + 3A** as one contained chrome-consistency pass: ≈10 call-site edits + 1 drawer file, with no shared-widget behavior change beyond adding a title-less `CommonAppBar` path. **Defer 2B (breadcrumb) and 3B (persistent desktop sidebar) as separate larger fidelity epics.** Because all three are GLOBAL/SHARED, even this contained pass requires an **all-screen light+dark regression sweep** before ship.

---

## Verification of this audit
- Doc-only; correctness = citation accuracy. Spot-check examples: month_calendar_screen.dart:176 (AppBar "Month Calendar") vs :1166 (in-body "KALENDAR"); app_gradients.dart light/dark stops; tokens.css:54/141 (`--bb-bg` flat).
- No `.dart` touched → no build/test impact; `flutter analyze` unaffected.
