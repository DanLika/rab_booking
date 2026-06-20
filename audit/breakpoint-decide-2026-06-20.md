# Breakpoint Canonicalization — Decision (`audit/breakpoint-decide`)

**Date:** 2026-06-20 · **Status:** DECISION RECORDED — migrates nothing. Each screen migration is a separate per-screen GO.
**Branch:** `audit/breakpoint-decide` (doc-only, off `origin/main`).

This doc **banks 1200 as the canonical desktop breakpoint** and **the device-class-vs-content-fit rule** that keeps it from rotting. No code changed.

---

## Context — why this exists

The owner app has **three competing breakpoint-definition systems** plus scattered raw literals, and they disagree on the single most-used question: *"at what width does the desktop layout appear?"*

- `Breakpoints` (`lib/core/constants/breakpoints.dart`, **38 refs** — dominant) → desktop = **1024**. Powers `context.isDesktop`.
- `BBBreakpoint` (`lib/core/design/tokens.dart:643`, 6 refs) → `desktop` class 1024–1440, `wide` = **1440**. Powers `BBResponsive`.
- `ResponsiveBreakpoints` (`lib/core/utils/responsive_spacing_helper.dart:34`, 6 refs) → desktop = **1200**. Powers page padding.

Two facts the raw "1024 vs 1440" framing missed, confirmed by reading source:

1. **1024 is the de-facto majority.** *Both* main device-class systems flip "desktop-or-larger" at 1024 (`Breakpoints.isDesktop` ≥1024 **and** `BBResponsive.isDesktopOrLarger` ≥1024). Only the padding helper + `BBContentMaxWidth=1200` clamp + the newest screens' private `_kDesktopBp=1200` + the CLAUDE.md convention use 1200. So promoting 1200 is a **deliberate target/migration**, not "adopt the existing majority."
2. **The docstrings lie.** `context_extensions.dart:18,21-22` claim desktop `>=1440`, but the code calls `Breakpoints.isDesktop` = `>=1024`. Actively misleading reviewers — must be fixed regardless of the decision.

The real risk is structural, not the constant: today `tablet == desktop == 1024`, so **no live tablet tier exists**. Moving desktop to 1200 makes the **1024–1199 band** hit each screen's tablet branch *for the first time* — every migration needs a ~1100 px eyeball.

---

## THE DECISION (operator-confirmed 2026-06-20)

| # | Decision | Value |
|---|----------|-------|
| 1 | Canonical **desktop** breakpoint | **1200 px** |
| 2 | Single source of truth | **`lib/core/constants/breakpoints.dart`** (dominant, powers `context.isDesktop`); `BBBreakpoint` + `ResponsiveBreakpoints` later delegate to it |
| 3 | Migration mode | **Additive** — introduce the canonical const + fix docstrings now (no behavior change); flip the shared `Breakpoints.desktop=1024` in a **separate final codemod PR** (CLAUDE.md: "bulk codemod = zaseban PR") |
| 4 | Content-fit reflows (LayoutBuilder, box-width driven) | **Keep** — just name them; migrate **only** device-class pivots |
| — | Mobile floor | **600 px** — already consistent everywhere; settled, no change |

**Why 1200:** aligns the device-class flip with `BBContentMaxWidth=1200` (multi-column appears exactly when content stops growing — one coherent threshold); matches the documented convention + every newest screen; keeps iPad-landscape (1024) on the tablet layout instead of a cramped desktop grid.

---

## Classification framework (the discriminator — the rule that keeps this from rotting)

For each width comparison, the *reliable signal* is **what it reads**, not the number:

- **Device-class pivot** → reads `MediaQuery…width` / top-level `screenWidth`, gates **padding / typography / "desktop look"**. → **MIGRATE to canonical 1200.**
- **Content-fit reflow** → reads `LayoutBuilder` `constraints.maxWidth` (the box, not the screen), gates **column count / Row-vs-Column wrap**. → **KEEP value, name it a local const** (same class as `booking_detail`'s deliberate `_kTabletGridMinWidth=720`).
- **Different axis (out of scope):** content-max-width clamps (`maxWidth:1000/1100` → unify to `BBContentMaxWidth=1200` as hygiene), dialog sizing (`ResponsiveDialogUtils`), very-small/form-field guards (340/350/360/375/400/480/500), browser UA sniff (768), font-scaling (600/1024, moves with the final codemod).

---

## (2) STRAYS to migrate → 1200 (device-class pivots, raw literals)

| Screen | File:line | Current | Gates | Action |
|--------|-----------|---------|-------|--------|
| iCal Export | `ical_export_list_screen.dart:636,637` | `>900`, `>600` | horizontal padding tier | → `isDesktopWide`(1200) / mobile 600 |
| iCal Sync | `ical_sync_settings_screen.dart:111,112` | `>900`, `>600` | horizontal padding tier | → 1200 / 600 |
| iCal Sync | `…:255` | `>700` | icon backplate size (cosmetic) | evaluate in-eyeball → 1200 or keep |
| Stripe Connect | `stripe_connect_setup_screen.dart:288,289,997` | `>900`, `>600`, `<600` | padding tier + mobile flag | → 1200 / 600 |
| Dashboard Overview | `dashboard_overview_tab.dart:390,643` | `>900` | gutter padding + panel radius | → 1200 |
| Dashboard Overview | `…:42,737,1493` | `<600` | mobile flags | keep 600 (already canonical) |

**Content clamps to unify (same PRs, low-risk):** `ical_export:651`=1000, `stripe_connect:306`=1000, `dashboard_overview:62`=1100 → `BBContentMaxWidth` (1200).

### Wave 2 — raw-900 strays beyond the 5 named screens (exhaustive sweep)
`profile_screen.dart:1322`, `unit_wizard/steps/step_4_review.dart:24`, legal pages `privacy_policy_screen.dart:85` / `terms_conditions_screen.dart:81` / `cookies_policy_screen.dart:79` — all raw `900`. Classify each per the framework (legal-page 900 ≈ device-class reading-width → 1200; others eyeball).
**Already-1200-but-raw (hygiene only, value unchanged):** `unit_pricing_screen.dart:84`, `month_calendar_screen.dart:451` → adopt the named const.
**Skeletons (MUST migrate in lockstep with their screen):** `dashboard_stats_skeleton.dart:19`, `skeleton_loader.dart:845,939,1170` (600/900) — a skeleton breaking at a different width than its loaded content is a visible glitch.

## (3) KEEP — intentional, do NOT migrate

| Screen | File:line | Value | Why keep |
|--------|-----------|-------|----------|
| Calendar | `breakpoints.dart:160` `calendarTablet` | 900 | Named, domain-specific day-cell sizing; timeline grid is FROZEN |
| Widget | `widget/.../theme/responsive_helper.dart:10` | 1024 | Separate embeddable iframe surface, own responsive system |
| Auth split | `enhanced_login_screen.dart:406`, `enhanced_register_screen.dart:319` | 1200 | Pitch-panel split; **already canonical-valued** (adopt const in final codemod) |
| Subscription | `subscription_screen.dart:73` | 720 | Side-by-side plans need less width (content-driven) |
| Booking Detail | `owner_booking_detail_screen.dart:38` `_kTabletGridMinWidth` | 720 | Named, audit/128 deliberate 2-col |

## (3b) KEEP-as-content-fit — value stays, just name it (decision #4)

| Screen | File:line | Current | Gates | Action |
|--------|-----------|---------|-------|--------|
| Dashboard Overview | `dashboard_overview_tab.dart:830` | `constraints.maxWidth >= 900` | 4-col vs 2-col stat grid | **keep 900**, name `_kStatGridMin` (forcing 1200 = only 2 cards across 900–1199, wasted whitespace) |
| Embed Guide | `embed_widget_guide_screen.dart:270` | `constraints.maxWidth > 700` | side-by-side steps+test vs stacked | **keep 700**, name `_kEmbedSideBySideMin` |

---

## (4) Migration packaging & order

**Rider strategy (operator pref):** a screen with an imminent design-apply pass gets its breakpoint migration **folded into that pass** — one touch, one shared ~1100 px eyeball — never a standalone breakpoint-only PR. Standalone breakpoint PRs only for already-shipped or indefinitely-deferred screens. The two bookends (Foundation + Final codemod) are standalone and screen-agnostic.

**Bookends — standalone, single-concern:**

| Step | Scope | Risk |
|------|-------|------|
| **Foundation (land FIRST)** | Fix the wrong `context_extensions.dart` docstrings; add canonical `desktop`=1200 const + `isDesktopWide()` helper to `breakpoints.dart` as the single source (legacy `desktop=1024` untouched). **Prereq for every folded pass** — they reference the shared helper; if a pass ships before Foundation it uses a local `_kDesktopBp=1200`, re-pointed in the codemod. | none (no behavior change) |
| **Final codemod (land LAST)** | Flip legacy `Breakpoints.desktop` 1024→1200; re-point `BBBreakpoint`/`ResponsiveBreakpoints` to delegate; replace remaining local `_kDesktopBp` consts with `context.isDesktop`; **eyeball all 38 `context.isDesktop` consumers @ ~1100 px**. The "bulk codemod = zaseban PR" step; only after the band is proven. | highest |

**Folded into an imminent design-apply pass — NO standalone bp PR, shares that pass's eyeball:**

| Screen(s) | Rides | Bp work folded in |
|-----------|-------|-------------------|
| Stripe Connect | **audit/138** | `>900/>600` padding → 1200 / 600; clamp 1000 → `BBContentMaxWidth` |
| iCal sync + export | **audit/140** | `>900/>600` padding → 1200 / 600; `>700` icon-size eval; clamps 1000 → 1200 |
| Embed guide | **audit/137** | name-only (`>700` content-fit kept) — trivial |

**Standalone — already-shipped or indefinitely-deferred (no pass to ride):**

| Screen(s) | Why standalone | Bp work | Risk |
|-----------|----------------|---------|------|
| `dashboard_overview_tab` + `dashboard_stats_skeleton` (lockstep) | audit/124 fidelity **already SHIPPED** | `:390/:643` → 1200; **keep** `:830` grid (name `_kStatGridMin`); clamp 1100 → 1200; skeleton in same PR | high (premium Pregled — careful light+dark) |
| Wave-2 misc: `profile_screen:1322`, `step_4_review:24`, legal pages (privacy/terms/cookies) raw 900 | no imminent pass | classify each → 1200 or keep+name; bundle as one small PR | med |
| Hygiene: `unit_pricing:84`, `month_calendar:451` (already 1200, raw→const) | value unchanged, near-zero risk | adopt const | low; ⚠ `unit_pricing` FROZEN-check vs Cjenovnik first |

**Eyeball:** folded screens share their design pass's single matrix; standalone screens get their own — 600 / 900 / **1100 (critical — newly-reachable tablet band)** / 1300 px, light + dark, plus the screen's own content breaks.

---

## FROZEN no-go (per-edit GO required)

- **Cjenovnik pricing-grid CONTENT** (`unified_unit_hub_screen.dart`) — hub-shell breakpoint consts are additive-OK, but the pricing grid's responsive layout is FROZEN. Confirm `unit_pricing_screen` scope against this before any edit.
- **`timeline_dimensions.dart`** — FIXED 50/42/100/60 px, "NE vraćaj responsive breakpoints." Untouched.
- **Calendar `calendarTablet=900`** — KEEP (intentional; timeline grid FROZEN).

---

## Migration gates (per future PR)

`dart format .` · `flutter analyze` (0 net-new) · `flutter test` · `flutter build web --no-tree-shake-icons` · the eyeball matrix above. CF: n/a.

**This doc decides the number (1200) and the discriminator rule. It migrates nothing.** Every row in (4) is a separate GO.
