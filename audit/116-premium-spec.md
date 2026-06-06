# audit/116 — Premium Spec (Owner)

**Date:** 2026-06-06
**Branch:** `feat/premium-redesign-2026-06-06` (worktree)
**Scope:** Owner app. Admin + Widget out of scope.
**Companion audit:** [114](114-owner-mobile-design-qa-2026-06-05.md) (R3 sweep, P-queue), [115](115-owner-mobile-full-fidelity-2026-06-06.md) (full-fidelity sweep, G-1/G-2/G-3).
**Intent:** Codify the Premium visual language as a TARGET reference so Phase B (shared chrome) and Phase C (page-by-page) implement against measured values, not vibes.

---

## §0 — Reading guide

This spec is a **target reference**, not an implementation plan. Phase B reads it and implements against §2–§5. Phase C composes pages against §3 + §App. Anything you cannot trace back to §2 or a sourced handoff file is out-of-spec drift — call it out, do not invent.

Sources (verbatim values quoted where used):

| Source | Role |
|---|---|
| `design_handoff/source/tokens.css` | Token spec (single source of truth for hex / shadow / radius / spacing / type) |
| `design_handoff/source/primitives.jsx` | Component-level reference (BBButton, BBInput, BBCard, BBAppBar, BBSidebar, …) |
| `design_handoff/source/pregled-premium.jsx` | Premium page reference — layered shell, north-star hero, dual-series chart, radial gauge, KPI sparkline cards, AI insight banner |
| `design_handoff/source/rezervacije-premium.jsx` | Premium page reference — segmented period pill, sparkline KPI cards, priority queue, premium ledger table |
| `design_handoff/source/profile-premium.jsx`, `calendar-premium.jsx` | Phase C composition signals (read in Phase C, not Phase A) |
| `lib/core/design/tokens.dart` | Flutter mirror (BBColor / BBSpace / BBRadius / BBShadow / BBType / BBMotion / BBGradient) — already maps 1:1 to tokens.css for most values |
| `lib/core/theme/app_shadows.dart` | `AppShadows.cardElevated` / `purpleSm` / `panelLight/Dark` already in place |
| `lib/shared/widgets/redesign/bb_scaffold.dart` | Console scaffold (shell → panel → card already implemented) |
| `lib/core/theme/app_theme.dart` | MaterialApp component themes (AppBarTheme/DialogTheme — these DO have premium gaps; see §3) |

---

## §1 — Premium identity (what it FEELS like)

Premium is **calm, layered, decelerated**. Hierarchy comes from depth (shell → panel → card → KPI tile), not from saturation. Numbers are tabular and oversized; surfaces are quiet. Motion is `cubic-bezier(.2,.8,.2,1)` — a 1.2 s ease-out that draws lines, not a bouncy spring.

In one paragraph: a north-star number dominates each page; supporting cards float on a calm panel that floats on a soft tinted shell; charts draw in under 1.5 s; status colors are semantic (purple completed, green confirmed, amber pending, slate cancelled — NEVER blue completed); the saturated brand purple is reserved for active nav tiles and primary CTAs; everything else borrows quiet neutral surfaces and a 3-layer cool-toned shadow ramp.

What this is NOT:
- Not Material 3 "saturated AppBar" — the AppBar dissolves into the panel
- Not single-line shadow — shadows are 3-layer cool-toned (RGB 16,24,40)
- Not 8 px radius cards — cards are 20 px (`BBRadius.md`); modals 24; hero 32
- Not "blue = completed" — completed = purple `#6B4CE6` (= `BBColor.primary`)

---

## §2 — Token reference (concrete values)

All values quoted verbatim from `tokens.css`. Flutter mirror class on the right where applicable. Where there is value drift, the Flutter side is canonical *for code* but `tokens.css` is canonical *for visual*; if they disagree, file an issue.

### §2.1 — Brand color

| Token | Light | Dark | Flutter |
|---|---|---|---|
| primary | `#6B4CE6` | `#8B6FFF` | `BBColor.primary` (light), `BBColor.primaryDark` (light's dark stop) |
| primary-dark | `#5638C7` | `#6B4CE6` | `BBColor.primaryDark` (slight drift: Flutter is `#5B3DD6`) |
| primary-light | `#B5A4F0` | `#B5A4F0` | `BBColor.primaryLight` (`#9B86F3`) |
| primary-tint-hover | `rgba(107,76,230,0.08)` | `rgba(139,111,255,0.12)` | derive via `withOpacity(0.08)` |
| primary-tint-pressed | `rgba(107,76,230,0.12)` | `rgba(139,111,255,0.20)` | derive |
| primary-tint-bg | `rgba(107,76,230,0.06)` | `rgba(139,111,255,0.08)` | derive — used for nav-active background, chip backgrounds |

Drift note: `primary-dark` differs by 2 hex units across the two sources. Visually equivalent. Pick `tokens.css` for new Premium surfaces; do not refactor `BBColor.primaryDark` (would diff every consumer).

### §2.2 — Semantic + status

| Token | Light | Dark | Notes |
|---|---|---|---|
| success | `#2E7D5B` | `#4FAE7F` | confirmed bookings, deposit progress bar |
| warning / tertiary | `#FFB84D` | `#FFC872` | pending status, accent badges |
| error / secondary | `#FF6B6B` | `#FF8080` | destructive, error tints |
| info | `#4A90D9` | `#6BA8E8` | imported bookings (Booking.com / Airbnb) |
| status-confirmed | `#2E7D5B` | `#4FAE7F` | green |
| status-pending | `#B7791F` (AA-darker than warning) | `#FFC872` | amber-on-tint |
| status-cancelled | `#4A5568` | `#A0AEC0` | slate |
| **status-completed** | **`#6B4CE6`** | **`#8B6FFF`** | **purple — this is the G-1 fix target** |
| status-imported | `#4A90D9` | `#6BA8E8` | blue |

### §2.3 — Shell surfaces (layered console)

| Token | Light | Dark | Flutter consumer |
|---|---|---|---|
| shell-bg | `#F0F1F5` | `#000000` | `BbRedesignTokens.shellBg` — BbScaffold outer fill |
| panel-bg | `#FBFBFD` | `#0B0B0D` | `BbRedesignTokens.panelBg` — BbScaffold inner floating panel |
| panel-border | `rgba(20,24,45,0.05)` | `rgba(255,255,255,0.06)` | `BbRedesignTokens.panelBorder` |
| surface | `#FFFFFF` | `#121212` | `BBColor.of(context).surface` — cards on the panel |
| surface-variant | `#F5F5F5` | `#1E1E1E` | `BBColor.of(context).surfaceVariant` — segmented pill bg, skeleton |
| border-subtle | `#EDF2F7` | `#1F2937` | dividers, KPI tile borders |

### §2.4 — Shadow ramp (3-layer, cool-toned)

| Token | Stack | Use |
|---|---|---|
| shadow-sm | `0 1px 2px rgba(16,24,40,.04), 0 2px 6px -1px rgba(16,24,40,.06)` | Sidebar items, AppBar action buttons |
| shadow-md (premium) | `0 1px 2px rgba(16,24,40,.04), 0 6px 16px -4px rgba(16,24,40,.08), 0 20px 40px -12px rgba(16,24,40,.12)` | Lifted/hovered cards, popovers |
| shadow-lg (premium) | `0 2px 4px rgba(16,24,40,.05), 0 12px 28px -6px rgba(16,24,40,.14), 0 32px 64px -20px rgba(16,24,40,.18)` | Modals, hero, lifted dialog |
| shadow-card | `0 1px 2px rgba(16,24,40,.04), 0 4px 10px -2px rgba(16,24,40,.05), 0 18px 40px -16px rgba(16,24,40,.10)` | Default resting card — already wired as `BBShadow.cardElevated` and consumed by `BbCard` |
| shadow-purple-sm | `0 4px 12px rgba(107,76,230,.20)` (dark: `…(139,111,255,.30)`) | Primary CTA resting, active sidebar tile only |
| shadow-purple | `0 8px 24px rgba(107,76,230,.25)` | Primary CTA hover |
| panel-shadow | `0 1px 3px rgba(16,24,40,.03), 0 2px 8px -2px rgba(16,24,40,.04), 0 16px 36px -16px rgba(16,24,40,.10)` | Outer floating panel that holds the page body |

**Flutter status:** all 7 stacks are present in `lib/core/theme/app_shadows.dart` (lines 128–208) as `cardElevated` / `purpleSm` / `purpleSmDark` / `panelLight` / `panelDark`. `BbCard` already consumes `cardElevated`. **No new shadow tokens needed.**

### §2.5 — Radii

| Token | Value | Use |
|---|---|---|
| BBRadius.xs | 6 | Tiny chips, indicator pills |
| BBRadius.sm | 12 | **Buttons, inputs, chips (CLAUDE.md mandate)** |
| BBRadius.md | 20 | Cards |
| BBRadius.lg | 24 | Modals, sheets |
| BBRadius.xl | 32 | Hero cards |
| BBRadius.full | 999 | Avatars, pills, FABs, segmented period buttons |

### §2.6 — Spacing (8 px grid, NO 12)

`BBSpace.xxs=4 / xs=8 / sm=16 / md=24 / lg=32 / xl=48 / xxl=64`. The 12 px legacy is `@Deprecated` and only retained for codemod safety.

### §2.7 — Type scale (Inter)

| Token | Size | Weight | LH | Letter-spacing | Use |
|---|---|---|---|---|---|
| `BBType.displayLg` | 48 | 800 | 1.05 | −0.03em (−1.44) | Premium page hero only (Pregled north-star) |
| `BBType.display` | 32 | 700 | 1.15 | −0.02em | Hero numbers (KPI tile value, occupancy %) |
| `BBType.h1` / `h1Num` | 24 | 700 | 1.2 | −0.015em | Page H1 |
| `BBType.h2` / `h2Num` | 20 | 600 | 1.25 | −0.01em | Section H2, dialog title |
| `BBType.h3` | 18 | 600 | 1.3 | −0.005em | Card title, breadcrumb leaf |
| `BBType.bodyLg` | 16 | 400 | 1.5 | 0 | Large body, list item primary |
| `BBType.body` | 14 | 400 | 1.5 | 0 | Default body, button text |
| `BBType.label` | 13 | 500 | 1.4 | +0.01em (+0.13) | Form labels |
| `BBType.caption` | 12 | 400 | 1.5 | 0 | Helper, count, sublabel |
| `BBType.eyebrow` | 11 | 600 | 1.4 | +0.08em (+0.88) UPPER | Section eyebrow, KPI label |
| `BBType.mono` | 13 | 500 (JetBrains Mono) | 1.5 | 0 | IBAN, codes, tokens |

All numeric strings (€, dates, counts) MUST set `fontFeatures: [FontFeature.tabularFigures()]` — use `*Num` variants where they exist, or `copyWith(fontFeatures: ...)`.

### §2.8 — Hero gradients

| Token | Stops | Use |
|---|---|---|
| `BBGradient.hero` (light) | `#6B4CE6 0% → #8B6FFF 60% → #A78BFF 100%`, 135° | Sidebar active tile icon halo, hero CTA on dark-on-bg, KPI tile arrival "next" highlight |
| `BBGradient.heroDark` | `#4A2BD1 → #6B4CE6 → #8B6FFF`, 135° | Dark-mode hero variant |
| `BbRedesignTokens.softBg` (light, PR #615) | `#FAFAFA → #F4F1FF` 135° lavender wash | **Auth screens, soft hero backdrops** (glass cards on calm surface) |
| `BbRedesignTokens.softBg` (dark) | `#0B0813 → #14101F` 135° | Dark auth |

### §2.8.1 — heroGradient vs softBg policy (clarifies user prompt FLAG)

The user prompt asked whether PR #615's "swap `rd.heroGradient → rd.softBg`" should be reverted. **It should not.** PR #615 *added* `softBg` as an additive token (not a swap); the actual swap of login PR #613's misuse of `heroGradient` was a follow-up fixup. The two gradients are **distinct intentional surfaces**:

- `heroGradient` = saturated brand purple. Use: sidebar active tile icon halo, primary CTA on dark backgrounds, KPI tile "next arrival" highlight (per `PV_ARRIVALS[0].next`).
- `softBg` = pale lavender wash. Use: auth screens, soft hero backdrops where a glass card sits on a calm surface.

Premium dashboards (Pregled hero) use **neither** — they use `panelBg` as the floating panel and the `radial-gradient` wash inside `PVRevenueCommand` (see §3.7).

---

## §3 — Component-level premium values

For each shared chrome primitive: TARGET values + current Flutter state + gap.

### §3.1 — AppBar

| Property | Premium target | Current MaterialApp default (`app_theme.dart:67-91`) | Current `BbAppBar` |
|---|---|---|---|
| Height | 56 | 64 | 56 ✓ |
| Background | `var(--bb-surface)` (on standalone screens) OR `transparent` (when inside `BbScaffold` panel) | `AppColors.primary` (saturated purple) | `surfaceColor` arg (panel-shell: `transparent`; mobile: `shellBg`) ✓ |
| Border-bottom | `1 px solid var(--bb-border-subtle)` (`#EDF2F7`) | none (elevation 0 + shadow on scroll) | optional border ✓ |
| Title style | `bb-h2` (20/600, text-primary) | `titleLarge` w/ `Colors.white` 600 | `BBType.h2` ✓ |
| Action button | 40×40, `radius BBRadius.sm`, border `border-subtle`, surface bg, badge top-right −5,−5 | `iconTheme.color = white` (overflows on light surfaces) | `AppBarIconBtn` ✓ |
| Breadcrumb | Optional — gray segments with `chevron_right` separators, last segment text-primary 600 | n/a | ✓ |

**Gap:** MaterialApp default `appBarTheme` is the saturated-purple legacy Material 3 pattern. Any screen NOT wrapped in `BbScaffold`/`BbAppBar` inherits this. Phase B switches the default to the premium pattern (surface bg, text-primary title, 56 px). Screens already on `BbAppBar` are unaffected.

### §AppBar-resolution (Phase C-1, 2026-06-06)

User prompt for Phase C-1 asked the agent to compare `design_handoff/screens/01-owner.png` against `source/pregled-premium.jsx` and decide whether the AppBar/top region is **gradient/purple** or **flat surface**, then either restore a premium gradient AppBar (if mockup is gradient) or keep Phase B's flat (if mockup is flat).

**Decision: FLAT KEPT.** `01-owner.png` ground truth shows the AppBar dissolves into the shell — transparent over `--bb-shell-bg` (`#F0F1F5`). The handoff JSX (`pregled-premium.jsx`) confirms this: every premium page wraps `BBAppBar style={PV_TRANSPARENT_CHROME}` where `PV_TRANSPARENT_CHROME = { background: 'transparent', borderRight: 'none', borderBottom: 'none' }`. `tokens.css §Premium console shell` (line 287–298) also dissolves the AppBar: `.bb-shell > div > header { background: transparent !important; border-bottom: none !important; }`.

Phase B is therefore correct for both consumers:
- **Premium pages** (inside `BbScaffold`) — `BbAppBar` already passes `surfaceColor: Colors.transparent` (tablet/desktop) or `surfaceColor: shellBg` (mobile). MaterialApp default is unused on these.
- **Legacy screens** (still on stock `AppBar`) — Phase B's surface bg + 56 px + bb-h2 title is the closest Material-default approximation of premium. Migrating these to `BbAppBar` is a Phase D concern, not C.

There is one subtle drift worth flagging: Phase B set `shadowColor: AppColors.sectionDividerLight` + `scrolledUnderElevation: 1` on the default AppBarTheme — premium shell has `border-bottom: none`. On scroll, legacy screens will draw a 1-pt divider; premium-shell screens will not (BbAppBar handles its own border). Acceptable — the divider on legacy screens is a sensible visual fallback during the transitional period.

**No code change** from this resolution.

### §3.2 — Drawer (mobile slide-in)

Used in `BbScaffold` mobile branch (`bb_scaffold.dart:136-149`). Wraps `BbSidebar` inside a Material `Drawer(backgroundColor: surface, width: 280)`.

| Property | Premium target | Current |
|---|---|---|
| Background | `surface` (`#FFFFFF`) | `BBColor.of(context).surface` ✓ |
| Width | 280 | 280 ✓ |
| Shadow | `shadow-lg` (3-layer) — Material default is ~elevation 16 which renders as a single dark shadow | Material default |
| Header | BookBed logo + "BookBed" wordmark + collapse chevron (already in `BbSidebar`) | ✓ via BbSidebar |
| Search row | 42 px ⌘K pill at top (in `BbSidebar`) | ✓ |
| Active nav item | `surface` bg, `border-subtle` border, `purpleSm` shadow, gradient-hero icon halo (28×28) | check BbSidebar — out of scope for this audit |
| User tile (bottom) | Avatar + name + email + `unfold_more` chevron, lift on hover | ✓ via BbSidebar |

**Gap:** Drawer envelope uses Material default shadow. Premium target = `shadow-lg`. Small visual delta; Phase B reviews `BbScaffold._panel` mobile branch and the Drawer wrap.

### §3.3 — Dialog (modal)

| Property | Premium target (handoff `BBDialog`) | Current MaterialApp default (`app_theme.dart:244-258`) |
|---|---|---|
| Width | 420 (default) | uncapped; relies on `ResponsiveDialogUtils` per call site |
| Background | `surface` | `surfaceLight` ✓ |
| Radius | **24 (`BBRadius.lg`)** | **20 (`AppDimensions.radiusM`)** ← drift |
| Shadow | `shadow-lg` (3-layer) | `elevation: 8` (single Material elevation, single dark shadow) ← drift |
| Padding (body) | 24 (`BBSpace.md`) | n/a (per-Dialog) |
| Title style | `bb-h2` (20/600, text-primary) | `headlineSmall.copyWith(textPrimaryLight)` — `headlineSmall` is 24/400 by default — drift |
| Body style | `bb-body` (14/400, text-secondary) | `bodyMedium.copyWith(textSecondaryLight)` ≈ 14/400 ✓ |
| Button bar | right-aligned, gap 8, tertiary then primary (or destructive) | per call site |

**Gap:** radius 20→24, elevation → 3-layer shadow, title size 24→20 (font weight: 400→600). Phase B updates `DialogThemeData` light + dark blocks.

### §3.4 — BottomSheet

Handoff `BBBottomSheet`: width 360 (mobile native), top corners radius 24, drag handle 36×4 at top in `border` color, `shadow-lg`, title `bb-h3` (18/600), body padded 8/4/16, optional footer with top border. Current Flutter side — `BbBottomSheet` exists at `lib/shared/widgets/redesign/bb_bottom_sheet.dart`; review in Phase B. MaterialApp `bottomSheetTheme` is NOT set (Material default applies for non-`BbBottomSheet` call sites). Phase B should at minimum add a `bottomSheetTheme` entry mirroring the BbBottomSheet defaults (radius `BBRadius.lg`, shadow `shadow-lg`).

### §3.5 — Card (BbCard)

| Property | Target | Current `BbCard` (`bb_card.dart`) |
|---|---|---|
| Background | `surface` (or `panelBg` via admin extension) | ✓ |
| Border | 1 px `border-subtle`; 2 px `primary` if selected | ✓ |
| Radius | 20 (`BBRadius.md`) | ✓ |
| Padding | 20 default; toggle off via `padded: false` | ✓ |
| Resting shadow | `shadow-card` (3-layer) | ✓ `BBShadow.cardElevated` |
| Hover shadow | `shadow-md` (3-layer, deeper) | ✓ `BBShadow.elevated(context)` |
| Hover transform | `translateY(-2px)` | ✓ `Matrix4..translateByDouble(0,-2,0,1)` |
| Hover transition | 160 ms ease-out | `BBMotion.fast` = 120 ms (premium handoff: `.bb-lift` = 180 ms cubic-bezier(.2,.8,.2,1)) — minor drift, defer |
| Variant: accent-left | 4 px colored left bar, accentTone enum | ✓ |

**Gap:** None at the visual level — `BbCard` is already premium. Hover duration off by 60 ms; defer.

### §3.6 — Button (BbButton)

Per handoff `BBButton` — six variants (primary / secondary / tertiary / destructive / destructive-soft / on-gradient / on-gradient-solid), three sizes (sm=36 / md=44 / lg=52), radius 12 (`BBRadius.sm`), primary has `shadow-purple-sm` resting + `shadow-purple` on hover + `translateY(-1 px)` on hover, 120 ms transition. Loading spinner. Verify in Phase B against `lib/shared/widgets/redesign/bb_button.dart`.

### §3.7 — Page-specific premium signals (Phase C reference; not Phase B)

These are documented here so Phase B doesn't accidentally over-build (they belong to per-page composition):

- **`PVRevenueCommand`** — north-star number `BBType.displayLg` (56 sp on mobile, 56 → 40 compact), counts up over 1.2 s, behind it a radial-gradient wash `radial-gradient(60% 60% at 30% 35%, rgba(107,76,230,.13) 0%, rgba(139,111,255,.05) 45%, transparent 72%)`. Delta chip `+12,4%` in success-tint pill.
- **`PVDualChart`** — current period filled area (purple linear gradient) + previous period dashed ghost. `pv-draw` stroke animation 1.2 s `cubic-bezier(.2,.8,.2,1)`.
- **`PVRadial`** — animated stroke-dashoffset gauge, 168 px outer, 16 px stroke. Linear gradient stops `#6B4CE6 → #8B6FFF` rotated `-90°`.
- **`PVKpiCard`** — count-up number, 96-width sparkline at right, icon tile 36 px `color-mix 14% transparent` of accent color.
- **`PVAIInsight`** — banner gradient `linear-gradient(105deg, rgba(107,76,230,.10) 0%, rgba(139,111,255,.05) 45%, rgba(61,217,176,.07) 100%)` (purple → teal hint), 46 px hero icon tile with `BBGradient.hero` + `shadow-purple-sm`, "BookBed AI" eyebrow chip in primary-tint-bg.
- **`PVPeriod`** — segmented pill, 4 px outer padding, inner buttons radius 999, active = surface + `shadow-sm`.
- **`RZP_PENDING`** — priority queue: pending bookings rendered as a distinct "north-star action" card above the ledger.

---

## §4 — Motion + interaction

| Token | Value | Use |
|---|---|---|
| `BBMotion.fast` | 120 ms | Chip select, button press, hover micro-feedback |
| `BBMotion.base` | 200 ms | Default transitions |
| `BBMotion.slow` | 320 ms | Route transitions, sheet open/close |
| `BBMotion.curve` | `Curves.easeOutCubic` | Default curve |
| **Handoff `.bb-lift`** | 180 ms `cubic-bezier(.2,.8,.2,1)` | Card lift on hover (current = 120 ms; minor drift, defer) |
| **Handoff `.pv-draw`** | 1.2 s `cubic-bezier(.2,.8,.2,1)` | SVG stroke-dashoffset chart entrance |
| **Handoff `.pv-fade-in`** | 1.1 s ease | Chart fill area entrance |
| **Handoff count-up** | 1.0–1.2 s cubic ease-out | KPI number rollup |

Reduced-motion (`MediaQuery.disableAnimations` OR platform reduceMotion) → all durations collapse to `Duration.zero` via `BBMotion.adapt(context, d)`.

Premium hover interactions (web only):
- Card: `translateY(-2 px)` + `shadow-md`, 160 ms
- Primary button: `translateY(-1 px)` + `shadow-purple`, 120 ms
- Nav item (row): bg fade to `primary-tint-bg`, 140 ms
- Button press: `scale(0.98)`, 100 ms

---

## §5 — Additive mechanism

**Decision:** Phase B uses `BbRedesignTokens` (already exists at `lib/core/design/bb_redesign_tokens.dart`) as the token bag. Wherever a Premium variant of a component is needed, use the audit/103 §Amendment Phase 1.7 precedent — a route-scoped `Theme.of(context).extension<BbRedesignTokens>()` lookup with a graceful fallback to base values when the extension is absent.

Why not a separate `BbPremiumTokens` extension:
- All Premium primitives (shellBg / panelBg / panelShadow / heroGradient / softBg) already live in `BbRedesignTokens`
- All shadow stacks (cardElevated / panelLight / panelDark / purpleSm) live in `AppShadows`
- All type / radius / motion live in `BBType` / `BBRadius` / `BBMotion`
- Adding a parallel extension would split the source of truth and force every consumer to read two extensions

Phase B additions to `BbRedesignTokens` (if any are needed) are pure additions (lerp + copyWith updated, no breaking change). Anticipated additions:
- `aiInsightGradient: LinearGradient` (purple → teal banner)
- `radialWashGradient: RadialGradient` (north-star backdrop)
- These are TBD pending Phase C — Phase B may not need them.

**MaterialApp default theme changes (Phase B):** these are not additive — they replace the saturated-purple legacy AppBarTheme with a premium-surface theme. Risk: screens NOT wrapped in `BbScaffold` and NOT yet refactored to `BbAppBar` will lose the saturated purple AppBar visual. This is the desired effect (it's drift, not a feature), but listing screens still on stock `AppBar` is part of Phase B due diligence.

---

## §6 — G-1 root fix (referenced, not re-analyzed)

Per audit/115 G-1 (grep-verified): `lib/core/constants/enums.dart:369` hardcodes `BookingStatus.completed → const Color(0xFF42A5F5)` (blue), which propagates to ~17 consumers via the `BookingStatus.color` extension. Premium spec requires `#6B4CE6` (purple) per §2.2 status-completed. Phase B fix is a single-line swap: `BookingStatus.completed => BBColor.statusCompleted`. Effort: trivial. Blast radius: positive — every consumer flips to correct color in one change.

---

## §7 — Phase B implementation scope (TARGET vs SCOPED)

Phase B implements the shared chrome — primitives shared by every page. Phase C composes pages against those primitives. The split:

**In scope for Phase B:**
1. **G-1 fix** at `enums.dart:369` (purple completed status)
2. **`AppBarTheme` light + dark** — switch to surface bg + 56 px + bb-h2 title + text-primary, replacing the saturated-purple default
3. **`DialogTheme` light + dark** — radius 20 → 24 (`BBRadius.lg`), elevation 8 → `BBShadow.elevated(context)`, titleTextStyle to `BBType.h2`
4. **`BottomSheetTheme`** (currently unset) — add minimal entry with radius `BBRadius.lg` top corners + `BBShadow.elevated(context)`
5. **Drawer shadow** — confirm `BbScaffold` mobile Drawer uses `BBShadow.modal(context)` envelope or document why Material default suffices
6. **Audit pass on Bb\* primitives** — verify BbButton purple-glow stack, BbInput focus ring, BbChip selected purple-shadow; no rewrites unless gap is observable on screen
7. **`flutter analyze` = 0**, **`flutter test`** green

**Out of scope for Phase B (deferred to Phase C):**
- North-star number on Pregled, dual-series chart, radial gauge, KPI sparkline cards, AI insight banner — these are PAGE composition (Phase C order: Pregled → Rezervacije → Jedinice → Kalendar chrome → rest)
- Rezervacije premium ledger + priority queue
- Profile premium chrome
- Calendar chrome upgrades (FROZEN repository + dimensions remain untouched)

**Frozen carve-outs reaffirmed:**
- Calendar Repository (`firebase_booking_calendar_repository.dart`)
- Calendar fixed dimensions (`timeline_dimensions.dart`)
- Cjenovnik tab (`unified_unit_hub_screen.dart`)
- Unit Wizard publish flow (3-doc atomicity)
- Navigator.push confirmation flow
- `BookingStatus` cancelled z-index order (drawn first, confirmed on top)

---

## §8 — Open questions for C1 user gate

User prompt's "Bb* core components (BbCard, BbButton, BbInput, **BbIconTi**" appears truncated. The grep shows `bb_icon.dart` exists; no `bb_icon_tile.dart`. Two plausible reads:

| Read | Action | Effort |
|---|---|---|
| `BbIconTile` (intended new primitive) | Phase B creates it; spec §3 needs an addendum | M — new primitive |
| `BbIconTi…` = typo for `BbIcon` or `BbIconButton` | Phase B verifies BbIcon premium weight + opsz settings | XS |

**C1 gate:** confirm with user which one.

Other items to gate at C1:
1. Did Phase B switch the MaterialApp default `AppBarTheme` correctly (any legacy screen that still expects the saturated purple visual)?
2. `BbCard` hover duration is 120 ms but `.bb-lift` is 180 ms — acceptable drift or align?
3. Drawer envelope shadow upgrade — accept Material default, or add explicit `shadow-lg` Box wrap?
4. After C1 approval, Phase C order is Pregled → Rezervacije → Jedinice → Kalendar chrome → rest. Confirm.

---

## §App — Cross-screen premium signals (Phase C reference)

Read these when planning Phase C pages, not during Phase B. Summarized for quick lookup:

| File | North-star pattern | Distinctive primitive |
|---|---|---|
| `pregled-premium.jsx` | `€3.840` 56 sp displayLg + dual chart + radial 78 % | `PVAIInsight` purple→teal banner, `PV_KPIS` sparkline tiles |
| `rezervacije-premium.jsx` | KPI summary row + `RZP_PENDING` priority queue + premium ledger w/ inline payment progress | `RZPStatCard` icon tile color-mixed; segmented period pill |
| `profile-premium.jsx` | TBD — read in Phase C | TBD |
| `calendar-premium.jsx` | TBD — read in Phase C (chrome only; cells stay FROZEN) | TBD |

---

## §Revert/Cleanup

This spec is doc-only. No production touched. Phase B will gate on user approval at C1.

**Phase 0 worktree (already created):** `/tmp/bb-premium-wt` on branch `feat/premium-redesign-2026-06-06`. Cleanup: `git worktree remove /tmp/bb-premium-wt` after PR merge.

---

**Status:** Phase A complete. Ready for Phase B (shared chrome + G-1) followed by Checkpoint 1 deploy + user gate.
