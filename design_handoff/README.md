# Handoff: BookBed — Premium 2026 Redesign → Flutter

> **Hrvatski (kratko):** Ovo je paket za predaju dizajna Claude Code-u. HTML datoteke u `source/` su **vizualna specifikacija** (ne kod za kopiranje). Cilj je **rekreirati ove ekrane u tvojoj postojećoj Flutter aplikaciji**, redoslijedom odozdo prema gore: **tokeni → primitive → shell → jedan ekran → ostali ekrani**. Svaki ekran ima screenshot u `screens/` (mapiran niže). Ne prevodi HTML doslovno u Dart — koristi ga kao referencu i refaktoriraj postojeći Flutter UI sloj.

---

## Overview

BookBed is a property-booking SaaS with **three product surfaces**:

1. **Owner app** — mobile-first + responsive web. Croatian (HR). Full BookBed purple brand. The main surface.
2. **Admin console** — web-only, responsive. English. A distinct **dark deep-purple** console (its own identity — not the owner lavender shell).
3. **Booking widget** — embeddable, web-only, guest-facing. Minimalist, distinct **mint** accent (`#3DD9B0`), near-black ink. Self-contained theme so it embeds on any third-party site.

This package documents a **premium 2026 redesign** of all three. The design system is token-driven and dark-theme-ready.

## About the design files

The files in `source/` are **design references created in HTML/React (JSX) prototypes** — they show the intended look, layout, spacing, color, and behavior. **They are not production code to copy directly.** Your task is to **recreate these designs in the existing Flutter codebase**, using its established patterns (widgets, theming, state management, routing, localization). Where the Flutter app already implements a screen, **refactor its UI layer** to match the design — do not rewrite business logic.

> The project's `tokens.css` header notes it "Matches `lib/core/design/tokens.dart` spec" — so a Dart token layer is the intended foundation. Build/così align that first.

## Fidelity

**High-fidelity (hifi).** Final colors, typography, spacing, radii, shadows, and interaction states are all specified here and in `source/tokens.css`. Recreate pixel-faithfully using Flutter equivalents. The screenshots in `screens/` are scaled-to-fit reference captures (see note on icons below).

> **Note on screenshot icons:** the capture renders Material Symbols icons as their **text token names** (e.g. `group`, `payments`, `event`) instead of glyphs. This is a capture artifact — in the real design every such label is a **Material Symbols Rounded** icon, and the text shown *is the exact icon name to use*. Layout, color, and hierarchy in the screenshots are accurate.

---

## Recommended implementation ORDER (do not go screen-by-screen first)

The system is ~80% tokens + shared components. Build those once, and screens become fast composition. Going screen-first causes drift.

```
1. TOKENS        source/tokens.css  →  AppTheme / design tokens in Dart
                 (colors, spacing 8px grid, radii, shadows, typography, dark variant)
2. PRIMITIVES    source/primitives.jsx  →  Bb* widget library
                 (BbCard, BbButton, BbChip, BbInput, BbStatusBadge, BbAvatar,
                  BbIcon, BbSidebar, BbAppBar, BbAvatarSlot, Spinner, …)
3. SHELL         BbSidebar + BbAppBar + .bb-shell + floating panel
                 →  BbConsoleScaffold (dissolved sidebar, breadcrumb app bar,
                    floating content panel)  +  AdminScaffold (dark variant)
4. ONE SCREEN    Build "Pregled" (owner dashboard) end-to-end to validate the pipeline.
5. ALL SCREENS   The rest, page-by-page — now fast because they just compose primitives.
```

### Per-screen workflow in Claude Code
For each screen, give Claude Code: **(1)** this README, **(2)** the specific `source/*.jsx` module, **(3)** the matching `screens/*.png`, **(4)** the path to the existing `lib/...` file. Prompt:
> "Refactor this screen's UI to match the design, using our AppTheme tokens and Bb* widgets. Keep existing logic/state; only rebuild the presentation layer."

---

## Design Tokens

All values are the single source of truth from `source/tokens.css`. Define them once in Dart (e.g. `AppColors`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppText`) and a dark override.

### Brand & accent (light)
| Token | Hex / value | Use |
|---|---|---|
| `--bb-primary` | `#6B4CE6` | primary brand, CTAs, active states |
| `--bb-primary-dark` | `#5638C7` | pressed primary |
| `--bb-primary-light` | `#B5A4F0` | subtle primary |
| `--bb-primary-tint-bg` | `rgba(107,76,230,0.06)` | faint primary fill (icon tiles, hover) |
| `--bb-secondary` | `#FF6B6B` | destructive / error |
| `--bb-tertiary` | `#FFB84D` | accent / warning highlight |
| gradient `--bb-gradient-primary` | `linear-gradient(135deg,#6B4CE6,#8B6FFF)` | sidebar active tiles, primary CTAs |
| gradient `--bb-gradient-hero` | `linear-gradient(135deg,#6B4CE6 0%,#8B6FFF 60%,#A78BFF 100%)` | hero cards, highlighted date chips |
| widget mint | `#3DD9B0` | **widget only** — selected dates, success, CTA |

### Semantic
`--bb-success #2E7D5B` · `--bb-warning #FFB84D` · `--bb-error #FF6B6B` · `--bb-info #4A90D9` — each with a matching `…-tint` rgba.

### Booking status (calendar + cards)
| Status | Color | BG |
|---|---|---|
| confirmed | `#2E7D5B` | `rgba(46,125,91,0.12)` |
| pending | `#B7791F` (AA-safe) | `rgba(255,184,77,0.18)` |
| cancelled | `#4A5568` | `rgba(113,128,150,0.14)` |
| completed | `#6B4CE6` | `rgba(107,76,230,0.10)` |
| imported | `#4A90D9` | `rgba(74,144,217,0.12)` |

### Surfaces & text (light)
`--bb-bg #FAFAFA` · `--bb-surface #FFFFFF` · `--bb-surface-variant #F5F5F5` · `--bb-border #E2E8F0` · `--bb-border-subtle #EDF2F7`
text: `--bb-text-primary #2D3748` · `secondary #4A5568` · `tertiary #718096` · `disabled #A0AEC0`

### Premium console shell (the redesign's signature layering)
Three depth layers: **shell → floating panel → cards**.
| Token | Light | Dark |
|---|---|---|
| `--bb-shell-bg` | `#F0F1F5` | `#000000` |
| `--bb-panel-bg` | `#FBFBFD` | `#0B0B0D` |
| `--bb-panel-border` | `rgba(20,24,45,0.05)` | `rgba(255,255,255,0.06)` |
| `--bb-panel-shadow` | soft 3-layer (see below) | deeper 3-layer |

### Spacing — **8px grid (NEVER 12)**
`xxs 4 · xs 8 · sm 16 · md 24 · lg 32 · xl 48 · xxl 64`

### Radii
`xs 6 · sm 12 (buttons/inputs/chips) · md 20 (cards) · lg 24 (modals/sheets) · xl 32 (hero) · full 999`

### Shadows — premium soft multi-layer ramp
```
--bb-shadow-sm:   0 1px 2px rgba(16,24,40,.04), 0 2px 6px -1px rgba(16,24,40,.06)
--bb-shadow-md:   0 1px 2px rgba(16,24,40,.04), 0 6px 16px -4px rgba(16,24,40,.08), 0 20px 40px -12px rgba(16,24,40,.12)
--bb-shadow-lg:   0 2px 4px rgba(16,24,40,.05), 0 12px 28px -6px rgba(16,24,40,.14), 0 32px 64px -20px rgba(16,24,40,.18)
--bb-shadow-card: 0 1px 2px rgba(16,24,40,.04), 0 4px 10px -2px rgba(16,24,40,.05), 0 18px 40px -16px rgba(16,24,40,.10)   ← default card float
--bb-shadow-purple-sm: 0 4px 12px rgba(107,76,230,.20)   ← glow on active nav tiles / primary CTAs ONLY
```
Flutter: each comma-segment = one `BoxShadow` in a `boxShadow: [...]` list.

### Typography — Inter (+ JetBrains Mono for code/IBAN)
Tabular figures on **all numerics** → Flutter `fontFeatures: [FontFeature.tabularFigures()]`.
| Class | Size / line / weight / tracking |
|---|---|
| `bb-display-lg` | 48 / 1.05 / 800 / -0.03em |
| `bb-display` | 32 / 1.15 / 700 / -0.02em |
| `bb-h1` | 24 / 1.2 / 700 / -0.015em |
| `bb-h2` | 20 / 1.25 / 600 / -0.01em |
| `bb-h3` | 18 / 1.3 / 600 |
| `bb-body-lg` | 16 / 1.5 / 400 |
| `bb-body` | 14 / 1.5 / 400 |
| `bb-label` | 13 / 1.4 / 500 / 0.01em |
| `bb-caption` | 12 / 1.5 / 400 |
| `bb-eyebrow` | 11 / 1.4 / 600 / 0.08em / UPPERCASE |
| `bb-mono` | JetBrains Mono 13 / 500 |

### Icons
**Material Symbols Rounded**, filled by default (`FILL 1, wght 500, opsz 24`). Flutter: `material_symbols_icons` package (or bundle the variable font). Icon names appear verbatim throughout the JSX (`<BBIcon name="…">`) and in the screenshots.

### Motion
- `bb-lift` — card hover: translateY(-3px) + shadow-lg (180ms `cubic-bezier(.2,.8,.2,1)`)
- `bb-press` — scale(0.98) on active
- `bb-row-hover` — bg → primary-tint
- Chart entrance: `pv-draw` (stroke-dashoffset line draw, 1.2s) + `pv-fade-in` (area fade) + count-up on KPI numbers
- **All gated by `prefers-reduced-motion`** → respect `MediaQuery.disableAnimations` in Flutter.

---

## Shared chrome & the premium "console" language

These define the redesign — implement as reusable Flutter widgets:

- **Dissolved sidebar (`BbSidebar`, desktop 260px)** — no hard border; sits on the same `shell-bg` as the page gutter. Top: brand + collapse + a **⌘K search field**. Nav **grouped under muted uppercase labels** (owner: *Glavno / Upravljanje / Pomoć*; admin: *Platform / Operations / System*). Each item = an **icon tile** (neutral when idle; **brand-gradient + purple glow when active**) inside a **raised white pill**. Bottom: clean **profile row** (avatar · name · email · chevron). Tablet → **rail 72px** (icon tiles only). Mobile → **hamburger + drawer**.
- **App bar (`BbAppBar`, 56px)** — transparent on the shell. Left: **breadcrumb** on desktop/tablet (e.g. *Početna › Pregled*), plain title + hamburger on mobile. Right: **rounded-square bordered icon buttons** (search/theme/notifications with badge).
- **Floating content panel** — dashboard-style screens (Pregled/Rezervacije/Profil) float an off-white rounded panel (`panel-bg`, radius 28, `panel-shadow`) inset on the shell. Other screens place cards directly on the shell. The `.bb-shell` class encapsulates this (paints shell + dissolves sidebar/app bar — color/border only, layout-safe).
- **KPI cards** — per-metric colored icon tile (purple/blue/green/amber via tints), big tabular value (count-up on load), delta pill, optional sparkline.
- **AdminScaffold** — the dark console equivalent (`#1E1A33` sidebar, English, Production badge). Same craft, its own palette. Fixed canvas sizes: desktop 1440×1100, tablet 768×1024, mobile-web 390×880.

---

## Primitive → Flutter widget map (`source/primitives.jsx`)

| JSX primitive | Purpose | Flutter notes |
|---|---|---|
| `Icon` / `BBIcon` | Material Symbol | `Icon(SymbolsRounded.x, fill: 1)` |
| `BBButton` | variants (primary/secondary/tertiary/destructive) × sizes × icon-only/loading | `FilledButton`/`OutlinedButton`/`TextButton` + custom |
| `BBChip` | filter/selectable chip | `ChoiceChip` / custom |
| `BBInput` | text field + iconLeft + sizes | `TextField` + `InputDecoration` |
| `BBCard` | container; floats on `shadow-card` by default | `Container` + `BoxDecoration` (radius md, shadow-card) |
| `BBStatusBadge` | booking status pill (dot + label) | maps to status token table above |
| `BBAvatar` | initials/photo avatar, sizes + tone | `CircleAvatar` |
| `BBAvatarSlot` | user-fillable circular photo (`image-slot`) | real image picker target |
| `BBSidebar` / `BBSidebarRail` | desktop/tablet nav | see chrome section |
| `BBAppBar` | breadcrumb/title app bar | `AppBar` custom |
| `Spinner`, skeletons | loading states | `states.jsx` has canonical patterns |

> **Scope/naming note for devs reading the JSX:** each Premium module uses locally-prefixed helpers (`PV*` Pregled, `RZP*` Rezervacije, `PFP*` Profil, `CALP*` Kalendar, `APY*` Payments, `ASY*` Sync, `SUP*` Support, `ANL*`/`Adm*` Analytics) to avoid global collisions. These are screen-local compositions of the shared primitives — fold them into your widgets per screen.

---

## Screens index (→ screenshot mapping)

> Each owner/dashboard screen exists at 3 breakpoints (Desktop 1440 / Tablet 768 / Mobile 390). Screenshots below are the **Desktop** reference; consult the matching `source/*.jsx` for tablet/mobile layouts. Owner Pregled/Rezervacije/Profil/Kalendar have a Classic↔Premium toggle — **the redesign target is the Premium variant** (what's captured).

### Owner app — `screens/NN-owner.png`
| # | Screen | Source module | Notes |
|---|---|---|---|
| 01 | Pregled (Dashboard) | `pregled-premium.jsx` | north-star revenue (count-up), AI insight, dual-series chart, occupancy radial, colored KPI sparklines, channel mix, arrivals (next guest chip highlighted) |
| 02 | Rezervacije (Bookings) | `rezervacije-premium.jsx` | KPI strip, AI nudge, pending priority queue (approve/reject + payment progress), bookings ledger table |
| 03 | Kalendar — Timeline | `calendar-premium.jsx` (+ FROZEN `calendar-timeline.jsx`) | premium chrome; **grid geometry is FROZEN** (see below) |
| 04 | Kalendar — Mjesečni | `calendar-month.jsx` | month grid + occupancy KPI strip; Google-Calendar-style spanning bars |
| 05 | Profil | `profile-premium.jsx` | identity card + completion radial + verified chips, host-trust KPIs, Pro card |
| 06 | Smještajne Jedinice (Units) | `units.jsx` | property tree + unit detail; **Cjenovnik price tab FROZEN** |
| 07 | Rezervacija — Detalji | `booking-detail.jsx` | full record, activity timeline, status+actions, cover image-slot |
| 08 | Pretplata (Subscription) | `subscription.jsx` | trial hero, billing toggle, Besplatno vs Pro |
| 09 | Isplate (Payouts) | `payouts.jsx` | Stripe Connect status, balance tiles, IBAN, schedule |
| 10 | iCal Sinkronizacija | `ical.jsx` | feed list, real OTA logos, status + error states |
| 11 | AI Asistent | `ai-assistant.jsx` | consent onboarding + chat surface |
| 12 | Obavještenja | `notifications.jsx` | typed category icons, inline actions, mark-all-read |
| 13 | FAQ (Pomoć) | `faq.jsx` | search + category chips + accordion + contact card |
| 14 | Widget (Embed guide) | `embed.jsx` | copyable snippet, live mint preview, install steps |
| 15 | Prijava (Login) | `auth.jsx` | **glass card on gradient — intentional** (glass only on hero/auth) |
| 16 | Postavke — Uredi profil | `settings.jsx` | photo block, details, public bio (sub-screen pattern) |

Other owner screens (in `source/`, not separately screenshotted): **Promijeni lozinku** & **Obavijesti settings** (`settings.jsx`), **Registracija** (`register.jsx`), **Oporavak računa** (`recovery.jsx`), **Legal** (`legal.jsx`), **Unit Wizard** (`wizard.jsx` — Step 4 publish FROZEN), **Booking create/edit** + **dialogs** (`dialogs.jsx`, `dialogs-misc.jsx`, `filters-dialog.jsx`).

### Admin console — `screens/NN-admin.png` (English, dark)
| # | Screen | Source module |
|---|---|---|
| 01 | Login | `admin-auth.jsx` |
| 02 | Overview (shell + dashboard) | `admin-shell.jsx` |
| 03 | Analytics (trends/donut/cohort) | `admin-viz.jsx` |
| 04 | Owners (users) | `admin-users.jsx` |
| 05 | Bookings | `admin-bookings.jsx` |
| 06 | Payments | `admin-payments.jsx` |
| 07 | Sync health | `admin-sync.jsx` |
| 08 | Support (master-detail inbox) | `admin-support.jsx` |

### Booking widget — `screens/NN-widget.png` (mint, guest-facing)
| # | Screen | Source module |
|---|---|---|
| 01 | Calendar | `widget-calendar.jsx` |
| 02 | Guest form | `widget-guest-form.jsx` (⚠ **no localStorage persistence of fields** — F-67-03) |
| 03 | Confirmation (success) | `widget-confirmation.jsx` |
| 04 | Pricing (panel + breakdown) | `widget-pricing.jsx` |
| 05 | Error / not-found states | `widget-error.jsx` |

---

## FROZEN regions — replicate geometry exactly, do not redesign
These were locked during the redesign (chrome may be restyled, structure must not change):
- **Timeline calendar grid** — parallelogram booking blocks, cell dims **50 / 42 / 100 / 60 px**, z-order (`calendar-timeline.jsx`).
- **Cjenovnik (price) tab** in Units.
- **Unit Wizard publish step (Step 4)** (`wizard.jsx`).
- **Navigator.push confirm flow** for booking create.

## Localization & conventions
- Owner app + widget: **Croatian (HR)** with full diacritics (č ć ž š đ). Admin chrome: **English** (the admin Support *thread* is intentionally HR — a real owner↔agent conversation).
- **Monday-start** weeks. Currency `€` with `.`/`,` per HR formatting. Tabular figures everywhere.
- Light + dark via theme token swap. Min 44px touch targets. Safe-area aware. Respect reduced-motion.

## Assets (`source/assets/`)
`logo.png`, `assistant.png`, `google.png`, `apple.png`, `booking.png`, `airbnb.png`, `other-sync.png`. User-fillable photo zones use the `<image-slot>` web component (`source/image-slot.js`) — in Flutter these become real image-picker/upload targets.

## Files in this package
- `README.md` — this document (self-sufficient).
- `screens/` — reference screenshots (29 desktop screens; see index above).
- `source/` — all design source: `tokens.css`, `primitives.jsx`, every screen module (`*.jsx`), `image-slot.js`, `BookBed Design.html` (the full canvas — open in a browser to see every screen live, including tablet/mobile and the Classic↔Premium toggles), and `assets/`.

> **Tip:** open `source/BookBed Design.html` in a browser for the highest-fidelity reference — it renders every screen at all breakpoints with real icons, live charts, and interactions. The screenshots are for quick reference; the live canvas + source are ground truth.
