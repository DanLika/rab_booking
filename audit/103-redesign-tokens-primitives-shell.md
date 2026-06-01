# audit/103 — Redesign Phase 1: tokens + primitives + shell foundation

**Date:** 2026-05-31
**Branch:** `redesign/tokens-primitives-shell`
**Scope:** UI-only, additive. No screen refactors, no logic changes, no dev/PROD deploy.
**Predecessor:** none (foundation for Phase 2 screen-refactor PRs).

## 0 · TL;DR

- 19 new `Bb*` primitives in `lib/shared/widgets/redesign/` + parent-level barrel `redesign.dart`.
- `BbRedesignTokens` `ThemeExtension` wired into both `AppTheme.lightTheme` and `darkTheme` so handoff surfaces (`shellBg #F0F1F5`, `panelBg #FBFBFD`, mint widget, glass, focus ring, status tints) are available without recoloring any unmigrated screen.
- `BBType.mono` switched to JetBrains Mono (handoff `--bb-font-mono`). New `BBType.eyebrow()`, `BBType.displayLg()`, `BBGradient.hero/heroDark`, `BBShadow.purpleSm/cardElevated/panelLight/panelDark` added; legacy `BBColor` / `BBRadius` / `BBSpace` values left untouched.
- `material_symbols_icons: ^4.2928.1` added to `pubspec.yaml`.
- `flutter analyze` worktree = `95 issues` matches `main` baseline = `95 issues` (zero net-new).
- All 19 widgets self-style via `BbRedesignTokens.of(context)` + existing BB tokens; no hard-coded hex/px.

## 1 · Why this PR

The handoff at `design_handoff/` is a token-driven system: ~80% reused primitives + token swap, ~20% screen composition. Without a stable foundation layer (tokens + primitives + shell), each Phase 2 screen PR would (a) re-derive the same handoff hex values, (b) couple visual churn with structural churn, and (c) drift in API surface. This PR lands ONLY the foundation so Phase 2 PRs (29 screens) are pure composition.

Two strict guardrails shape the choices below:

- **Existing screens still render correctly after this PR merges** → no rewrite of `AppTheme.lightTheme/darkTheme` component themes (e.g., `AppBarTheme` is currently a 64px filled-purple bar; the handoff specifies a 56px transparent breadcrumb bar — that's a Phase 2 visual change, not Phase 1 foundation).
- **`lib/core/widgets/bb_*.dart` (`BB*` double-cap legacy) is untouched** → new redesign primitives live at `lib/shared/widgets/redesign/bb_*.dart` (`Bb*` single-cap). Both can be imported in the same file via simple path qualifier.

## 2 · Token mapping

Handoff source: `design_handoff/source/tokens.css` (read verbatim during execution; not paraphrased from agent summary).

### 2.1 Surfaces — new in `BbRedesignTokens`

| Handoff CSS var | Light | Dark | Dart accessor |
|---|---|---|---|
| `--bb-shell-bg` | `#F0F1F5` | `#000000` | `BbRedesignTokens.of(ctx).shellBg` |
| `--bb-panel-bg` | `#FBFBFD` | `#0B0B0D` | `…panelBg` |
| `--bb-panel-border` | `rgba(20,24,45,.05)` | `rgba(255,255,255,.06)` | `…panelBorder` |
| `--bb-panel-shadow` | 3-layer soft | 3-layer dark | `…panelShadow` (= `AppShadows.panelLight/Dark`) |
| `--bb-shadow-card` | 3-layer | n/a | `BBShadow.cardElevated` (= `AppShadows.cardElevated`) |
| `--bb-shadow-purple-sm` | `0 4px 12px rgba(107,76,230,.20)` | lighter `(139,111,255,.30)` | `BBShadow.purpleGlow(ctx)` or `…purpleGlow` field |
| `--bb-focus-ring` | `rgba(107,76,230,.22)` | `rgba(139,111,255,.32)` | `…focusRingColor` |
| `--bb-glass-bg` / `--bb-glass-border` | `rgba(255,255,255,.72)` / `.50` | `rgba(30,30,30,.60)` / `.08` | `…glassBg` / `…glassBorder` |
| widget mint `#3DD9B0` (widget only) | static | static | `AppColors.mintWidget`, `…mintWidget` |
| soft auth/hero backdrop (Phase 1.2) | `LinearGradient(#FAFAFA → #F4F1FF)` 135° | `LinearGradient(#0B0813 → #14101F)` 135° | `…softBg` |

### 2.2 Status — handoff "deep" hexes via redesign tokens

Existing `BBColor.statusPending = 0xFFFFB84D` and `statusCancelled = 0xFF718096` are kept for compat with the calendar (it relies on these values for visual identity). Handoff's AA-safe deeper values are exposed *additively* via `BbRedesignTokens`:

| Status | Existing `BBColor.*` (light) | Handoff deep (light) | Handoff tint |
|---|---|---|---|
| confirmed | `#2E7D5B` ✅ match | `#2E7D5B` | `rgba(46,125,91,.12)` |
| pending | `#FFB84D` (bright) | `#B7791F` (AA-safe darker) | `rgba(255,184,77,.18)` |
| cancelled | `#718096` (mid grey) | `#4A5568` (darker grey) | `rgba(113,128,150,.14)` |
| completed | `#6B4CE6` ✅ match | `#6B4CE6` | `rgba(107,76,230,.10)` |
| imported | `#4A90D9` ✅ match | `#4A90D9` | `rgba(74,144,217,.12)` |

`BbStatusBadge` (redesign) consumes the deep + tint hexes from the extension; the legacy `BBStatusBadge` keeps its `BBColor.*` lookup. Phase 2 can revisit whether to migrate the calendar to the deep values once all screens use redesign widgets.

### 2.3 Type — new + 1 swap

| Handoff class | Dart accessor | Notes |
|---|---|---|
| `bb-display-lg` 48/800/1.05/-0.03em | `BBType.displayLg(ctx)` | **new** — hero pages only |
| `bb-display` 32/700/1.2 | `BBType.display(ctx)` | unchanged |
| `bb-h1` 24/700/1.2 | `BBType.h1(ctx)` | unchanged |
| `bb-h2` 20/600/1.2 | `BBType.h2(ctx)` | unchanged |
| `bb-h3` 18/600/1.2 | `BBType.h3(ctx)` | unchanged |
| `bb-body-lg` 16/400/1.5 | `BBType.bodyLg(ctx)` | unchanged |
| `bb-body` 14/400/1.5 | `BBType.body(ctx)` | unchanged |
| `bb-label` 13/500/1.5 | `BBType.label(ctx)` | unchanged |
| `bb-caption` 12/400/1.5 | `BBType.caption(ctx)` | unchanged |
| `bb-eyebrow` 11/600/1.4 +0.08em UPPER | `BBType.eyebrow(ctx)` | **new** — pair with `.toUpperCase()` on the displayed string |
| `bb-mono` JetBrains Mono 13/500 | `BBType.mono(ctx)` | **changed** — was `GoogleFonts.inter(... tabular figures)`, now `GoogleFonts.jetBrainsMono(...)`; network-loaded on first use |

### 2.4 Gradients

| Handoff var | Dart accessor | Notes |
|---|---|---|
| `--bb-gradient-primary` (135° `#6B4CE6 → #8B6FFF`) | `BBGradient.brandPrimary` (existing) | end stop ~5% off (legacy is `#7E5FEE`) — kept to avoid drift; redesign can use `BbRedesignTokens.of(ctx).brandPrimaryGradient` if/when exact match needed |
| `--bb-gradient-hero` (135° 3-stop `#6B4CE6 0% → #8B6FFF 60% → #A78BFF 100%`) | `BBGradient.hero` + dark `BBGradient.heroDark` | **new** |

### 2.5 Spacing, radii — `BBSpace` / `BBRadius` already correct

Verified by reading `design_handoff/source/tokens.css` lines 184-204:
- spacing `xxs/xs/sm/md/lg/xl/xxl = 4/8/16/24/32/48/64` ✅ matches `BBSpace`
- radii `xs/sm/md/lg/xl/full = 6/12/20/24/32/999` ✅ matches `BBRadius`

No changes needed.

## 3 · Widget inventory

20 files (19 widgets + barrel) under `lib/shared/widgets/redesign/`:

| File | Class | Source jsx | Strategy |
|---|---|---|---|
| `bb_icon.dart` | `BbIcon` | `Icon`/`BBIcon` | NEW — wraps `material_symbols_icons`, name-keyed lookup via `materialSymbolsIconNameToUnicodeMap` (forces `--no-tree-shake-icons` via side-effect import of `symbols_map.dart`) |
| `bb_logo.dart` | `BbLogo` | `Logo` | NEW — gradient brand "b" tile (no asset dependency yet) |
| `bb_spinner.dart` | `BbSpinner` | `Spinner` | NEW — 2px CircularProgressIndicator wrapper |
| `bb_avatar.dart` | `BbAvatar` + `BbAvatarSize` + `BbAvatarTone` | `BBAvatar` | NEW — full handoff tone palette (primary/success/info/tertiary/neutral/on-gradient), 5 sizes (xs/sm/md/lg/xl) |
| `bb_avatar_slot.dart` | `BbAvatarSlot` | `BBAvatarSlot` | NEW — onTap callback for `image_picker` wiring |
| `bb_avatar_upload.dart` | `BbAvatarUpload` + `BbAvatarUploadCallback` | `BBAvatarSlot` (handoff) + `ProfileImagePicker` (image-pick logic) | **NEW Phase 1.4** — mirrors `ProfileImagePicker`'s `image_picker` invocation (gallery, 512×512, q=85) + error/log path; redesign chrome only (circular surface matching `BbAvatar`, edit-pill overlay, placeholder w/ initials or `person` icon, busy overlay w/ `BbSpinner`). API: `onImageSelected: (Uint8List? bytes, String? name)` aligned to existing `ProfileImagePicker` callers for mechanical drop-in. Caller-controlled `isUploading` covers backend upload window; internal `_isPicking` covers plugin invocation — both show the same spinner. |
| `bb_button.dart` | `BbButton` + 8 variants | `BBButton` | NEW — all handoff variants (incl. `destructiveSoft`, `success`, `onGradient`, `onGradientSolid`), `asIcon`, `active`, `loading` |
| `bb_checkbox.dart` | `BbCheckbox` | `dialogs.jsx:90` Checkbox helper | **NEW Phase 1.3** — 20×20 box, optional label + subtitle, focus halo. Form integration via conditional `FormField<bool>` wrap when validator present (matches BbInput #616 pattern). `error` parameter wins over validator output (explicit override). |
| `bb_input.dart` | `BbInput` | `BBInput` | NEW — icon left/right, error/helper, charLimit counter (tabular), 3 sizes (40/48/56), focus ring. Phase 1.1 (PR #616): added `validator` + `autovalidateMode` + `onFieldSubmitted` parameters; wraps in `FormField<String>` when `validator` is supplied (zero overhead otherwise; internal `TextField` retained). |
| `bb_radio.dart` | `BbRadio<T>` + `BbRadioGroup<T>` + `BbRadioOption<T>` typedef | (no direct JSX — single-choice convention) | **NEW Phase 1.3** — 20×20 outer circle + 8px inner dot, focus halo. `BbRadioGroup` is the ergonomic wrapper; supports `validator: FormFieldValidator<T>?` via internal conditional `FormField<T>` wrap. |
| `bb_card.dart` | `BbCard` + 3 variants + 5 accent tones | `BBCard` | NEW — `defaultStyle`/`flat`/`accentLeft`, hoverable lift on web only |
| `bb_chip.dart` | `BbChip` + 2 variants | `BBChip` | NEW — `filter`/`tab`, count badge, dot, leading/trailing icon |
| `bb_status_badge.dart` | `BbStatusBadge` + `BbBookingStatus` | `BBStatusBadge` | NEW — pulls deep + tint hexes from `BbRedesignTokens` |
| `bb_switch.dart` | `BbSwitch` | `ical.jsx:194` ToggleSwitch | **NEW Phase 1.3** — 36×20 track + 16px circular thumb (deliberately tightened from handoff 40×24/18; documented in dart-doc). Visual-only: toggles don't typically Form-validate. `AnimatedAlign` thumb slide via `BBMotion.adapt`. |
| `bb_skeleton.dart` | `BbSkeleton` | `BBSkeleton` | NEW — minimal w/h/radius API (handoff), reduced-motion fallback |
| `bb_section_header.dart` | `BbSectionHeader` + level enum | `BBSectionHeader` | NEW — title + count + trailing action link with `arrow_forward` icon |
| `bb_dialog.dart` | `BbDialog` + `BbDialogAction` | `BBDialog` | NEW — `showDialog` shell, destructive flag |
| `bb_dropdown.dart` | `BbDropdown<T>` + `BbDropdownItem<T>` | `DropdownButtonFormField` call-sites (no direct JSX) | **NEW Phase 1.6** — wraps `DropdownButton<T>` inside [BbInput]-parity chrome (label / helper / error / iconLeft / size sm 40 / md 48 / lg 56). Per-item `icon` (Material Symbol name) renders inside menu rows; widget-level `iconLeft` decorates the trigger row. Form integration via conditional `FormField<T>` wrap when `validator` present (mirrors BbInput #616 + BbCheckbox / BbRadioGroup #625 pattern). `error` parameter wins over validator output (explicit override). Menu surface uses `BbRedesignTokens.panelBg`; menu corner radius is theme-level (Flutter limitation — documented in dart-doc). `tabular: true` opt-in for numeric content (years, codes). |
| `bb_bottom_sheet.dart` | `BbBottomSheet` | `BBBottomSheet` | NEW — drag-handle + title + footer slots |
| `bb_empty_state.dart` | `BbEmptyState` + benefit/action types | `BBEmptyState` | NEW — illustration override + 3-col benefits grid (collapses to 1 col <480px) |
| `bb_sparkline.dart` | `BbSparkline` | `BBSparkline` | NEW — `CustomPainter` line + area fill + final-point dot |
| `bb_app_bar.dart` | `BbAppBar` + breadcrumb/action types + `PreferredSizeWidget` | `BBAppBar` | NEW — 56px, breadcrumb desktop / title mobile, rounded-square 40×40 action buttons with badge support |
| `bb_sidebar.dart` | `BbSidebar` + 6 helper types | `BBSidebar` | NEW — 260px desktop, brand row + ⌘K search + grouped nav (gradient active tiles + purple glow) + bottom user row |
| `bb_sidebar_rail.dart` | `BbSidebarRail` + item type | `BBSidebarRail` | NEW — 72px tablet, logo + icon-only items + bottom logout |
| `bb_scaffold.dart` | `BbScaffold` | composes shell | NEW — dissolved sidebar + floating panel; responsive desktop/tablet/mobile |
| `redesign.dart` (parent) | barrel | — | re-exports all `redesign/bb_*.dart` for one-line Phase 2 import |

**WRAP strategy:** none used. Every widget is a NEW standalone implementation that mirrors the handoff JSX surface 1-to-1. The legacy `BB*` (double-cap) widgets at `lib/core/widgets/bb_*.dart` are not imported by any redesign file — Phase 2 callers will switch over to `Bb*` (single-cap) via the barrel. The exec plan called for `as legacy` wraps, but those would have inherited legacy parameter shapes (e.g., legacy `BBAvatar` has 3 sizes + `color`; handoff has 5 sizes + tone palette) and forced extra mapping logic per call. Reimplementing was cleaner and only ~40 LOC heavier overall.

**BbInput Form integration (Phase 1.1):** `BbInput` exposes a `validator` parameter that wires it into a `Form` ancestor. Without `validator` it behaves exactly like a plain `TextField` (backward compat with PR #611 callers — zero new widgets in the tree). With `validator`, the chrome wraps in a `FormField<String>` whose `state.errorText` feeds the existing custom helper-text + border-color path; `_formKey.currentState!.validate()` triggers per-input validation correctly and a successful re-validate clears the error in one rebuild. The validator runs against the live `controller.text` rather than the cached `state.value`, so programmatic `controller.text = …` writes (server-side error clear, password fill, etc.) are validated correctly. Explicit `widget.error` always wins over validator output (server-side errors override client-side validation) — only one `Text` widget is ever in the tree for the error, so there's no double-render. `iconRight` is a static icon-name only; `trailingAction` accepts a stateful Widget (password toggle, clipboard, etc.).

**Phase 1.3 form controls (this PR):** `BbCheckbox` + `BbSwitch` + `BbRadio` (with `BbRadioGroup<T>` wrapper) join `BbInput` as the form primitive family. Checkbox and Radio (via `BbRadioGroup`) follow the same conditional `FormField<T>` wrap convention introduced by Phase 1.1 #616 — pass `validator` to opt into Form integration, omit it for plain controlled widgets. Switch is visual-only (toggles don't typically Form-validate; use `Form.didChange` callback if you need cross-field coordination). All three honor reduced-motion via `BBMotion.adapt()` on transitions, gate disabled state from `onChanged: null` (45% opacity + no ripple, no internal state), expose `semanticLabel` for screen-reader override, and use `BbRedesignTokens.focusRingColor` for the focus halo. Error display for `BbCheckbox` / `BbRadioGroup` renders as a helper line below the row (mirrors `BbInput`); a `Tooltip`-on-icon variant was considered but rejected — it's invisible to touch users. Two gaps surfaced during Phase 2 motivated the foundation patch: Register #623 had 3 plain `Checkbox`es recolored with `c.primary` (same gap projected for Edit Profile, Bank Account, terms agreement flows); Notification Settings + iCal Sync screens have many toggle switches needing R2C.

**Phase 1.4 avatar upload:** `BbAvatarUpload` closes the image-picker gap surfaced by Register #623 (which preserved `ProfileImagePicker` as-is, flagged) and the parked Edit Profile R2C. It is the third "WRAP" attempt across the foundation layer and the second time the existing widget could **not** be cleanly wrapped by composition — `ProfileImagePicker` is a single `StatefulWidget` that owns `_pickImage`, `_imageBytes`, `_isUploading` and bakes the visual chrome into the same widget; there is no static method, no service layer, no callback hook to inject from outside. The honest finding is **mirror, not wrap**: the new primitive replicates the 3-line `ImagePicker().pickImage(source: gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85)` invocation and `LoggingService.logError` + `ScaffoldMessenger` SnackBar error path verbatim, while the redesign chrome (circular surface matching `BbAvatar`, edit-pill overlay using `c.primary`, busy overlay with `BbSpinner`, placeholder via initials or `person` icon) is fresh code. The `onImageSelected: (Uint8List? bytes, String? name)` callback API is deliberately aligned with the existing `ProfileImagePicker` signature — the task spec drafted `(XFile file)` from inference, but reading the source showed both call sites (`enhanced_register_screen.dart:419` + `edit_profile_screen.dart:730`) consume `bytes` + `name` from `_pickImage`'s post-`readAsBytes()` call, so a `XFile` API would have forced re-coupling at every migration site. Two upload-state surfaces are kept distinct: internal `_isPicking` covers the ~100ms `pickImage` → `readAsBytes` window the caller has no visibility into; the public `isUploading` prop covers the seconds-long backend upload (Firebase Storage etc.). Both show the same dimmed-overlay `BbSpinner` and disable tap. `ProfileImagePicker` stays in `lib/features/auth/presentation/widgets/` unmodified so Register #623 + the parked Edit Profile R2C can swap onto `BbAvatarUpload` in mechanical follow-up PRs without coupling the migration to a delete.

## 4 · Shell architecture

`BbScaffold` (`lib/shared/widgets/redesign/bb_scaffold.dart`) composes the redesign chrome and gates by viewport.

```
Desktop (≥1024)                      Tablet (600–1023)            Mobile (<600)
┌─────────────────────────────┐      ┌───────────────────┐        ┌────────────────┐
│ shell-bg                    │      │ shell-bg          │        │ shell-bg       │
│ ┌─────┐ ┌─────────────────┐ │      │ ┌──┐ ┌──────────┐ │        │ ┌────────────┐ │
│ │BbS  │ │ BbAppBar 56     │ │      │ │BS│ │BbAppBar  │ │        │ │BbAppBar    │ │
│ │260  │ ├─────────────────┤ │      │ │R │ ├──────────┤ │        │ │  ☰  title  │ │
│ │     │ │ panel-bg        │ │      │ │72│ │ panel-bg │ │        │ ├────────────┤ │
│ │ nav │ │ radius 20       │ │      │ │  │ │ floating │ │        │ │ body       │ │
│ │     │ │ cardElevated    │ │      │ │  │ │          │ │        │ │ edge-edge  │ │
│ │user │ │   body          │ │      │ │  │ │  body    │ │        │ │            │ │
│ └─────┘ └─────────────────┘ │      │ └──┘ └──────────┘ │        │ └────────────┘ │
└─────────────────────────────┘      └───────────────────┘        └────────────────┘
                                                                  Drawer slides
                                                                  from left (BbSidebar)
```

Breakpoints are `BbScaffold.mobileBreakpoint = 600` / `desktopBreakpoint = 1024` (override via constructor). `overrideShellBg` lets the widget surface paint mint (or any other base) without forking the whole scaffold.

**Not changed in this PR:**

- `lib/core/design/responsive.dart:229 BBScaffold` (thin wrapper) — unchanged
- `lib/features/owner_dashboard/presentation/widgets/owner_app_drawer.dart` `OwnerAppDrawer` — unchanged (still used)
- `lib/shared/widgets/common_app_bar.dart` `CommonAppBar` — unchanged
- All routers (`router_owner.dart`, `router_widget.dart`, `router_admin.dart`) — unchanged
- `AppTheme.lightTheme` / `darkTheme` component themes — only the `extensions:` list grew (added `BbRedesignTokens.light` / `.dark` alongside the existing `AppGradients.*`)

## 5 · Screen reference (Phase 2 deferred)

29 reference screenshots are in `design_handoff/screens/` (committed in this PR for reviewer convenience). Each maps to a JSX module in `design_handoff/source/`. Each Phase 2 PR refactors ONE screen onto these foundation widgets.

| # | Surface | Screen | Source module | Suggested first slice |
|---|---|---|---|---|
| 01–16 | Owner | Pregled / Rezervacije / Kalendar (timeline + month) / Profil / Smještajne Jedinice / Rezervacija detalji / Pretplata / Isplate / iCal / AI Asistent / Obavještenja / FAQ / Embed / Login / Settings | `pregled-premium.jsx` etc. (see `design_handoff/README.md` §"Screens index") | **Pregled** (smallest visible win; biggest validation of `BbScaffold` + `BbCard` + `BbSparkline` together) |
| 01–08 | Admin | Login / Overview / Analytics / Owners / Bookings / Payments / Sync health / Support | `admin-*.jsx` | After 2 owner screens land — admin needs an `AdminScaffold` dark variant, not in this PR |
| 01–05 | Widget | Calendar / Guest form / Confirmation / Pricing / Errors | `widget-*.jsx` | Independent — can land any time, uses `BbScaffold(overrideShellBg: BbRedesignTokens.mintWidget)` |

**FROZEN** (replicate geometry only, do not redesign): timeline calendar grid (50/42/100/60 px), Cjenovnik price tab, Unit Wizard publish step (Step 4), Navigator.push booking-create confirm flow. Phase 2 PRs touching those surfaces must call out the frozen carve-outs.

## 6 · Verification results

Worktree: `/tmp/bb-rd1-wt`, branch `redesign/tokens-primitives-shell`.

| Step | Command | Result |
|---|---|---|
| Dep add | `flutter pub add material_symbols_icons` | added `^4.2928.1` |
| Codegen | `dart run build_runner build --delete-conflicting-outputs` | 99 outputs in 30s, no errors |
| Format | `dart format lib/core/design lib/core/theme lib/shared/widgets/redesign{,.dart}` | 15 of 38 reformatted |
| Analyze baseline (main) | `flutter analyze --no-fatal-infos` | **95 issues** (all info-level deprecated-token warnings; pre-existing) |
| Analyze worktree | same | **95 issues** (identical — 0 net-new from this PR) |
| Web build (widget) | `flutter build web --release --target lib/widget_main_dev.dart` | ✅ `Built build/web` — `main.dart.js` 3.8 MiB |
| Web build (owner) | `flutter build web --release --target lib/main_dev.dart` | ✅ `Built build/web` — `main.dart.js` 7.1 MiB, compile 44 s |
| Tests | `flutter test` (1216 tests, 30 s) | ✅ `All tests passed` |

## 7 · Drift / no-drift decisions

Recorded so Phase 2 reviewers don't re-litigate:

- **Status pending light hex** kept at bright `#FFB84D` (`BBColor.statusPending`); handoff AA-safe `#B7791F` exposed *additively* as `BbRedesignTokens.statusPendingDeep`. Decision: changing the live token would shift calendar visual identity on every unmigrated screen. Phase 2 calendar refactor revisits.
- **Status cancelled light hex** kept at `#718096`; handoff `#4A5568` available as `BbRedesignTokens.statusCancelledDeep`. Same reason.
- **`AppColors.backgroundLight`** kept at warm white `#FFFAFAFA`; handoff shell-bg `#F0F1F5` exposed via `BbRedesignTokens.shellBg`. Decision: `Scaffold.backgroundColor` inherits the legacy value on every unmigrated screen; flipping it Phase 1 would change every screen at once.
- **`AppBarTheme.backgroundColor`** kept as filled `AppColors.primary` (dark purple, 64px); handoff transparent 56px breadcrumb pattern lives in the new `BbAppBar` widget. Decision: same — flipping the global AppBarTheme would mass-rerender screens before Phase 2 refactors them.
- **`BBGradient.brandPrimary` end stop** kept at `#7E5FEE`; handoff exact end stop `#8B6FFF`. Difference visually negligible; redesign widgets pull `BbRedesignTokens.brandPrimaryGradient` if they need the handoff-exact 2-stop. Future codemod can collapse.

## 8 · Phase 2 hand-off

Each Phase 2 PR is independent (no inter-PR dependencies). Recommended sequencing:

1. **PR-A: Pregled (Owner Dashboard, screen 01-owner)** — validates `BbScaffold` + `BbCard` + `BbSparkline` + `BbSectionHeader` end-to-end. Smallest visible win.
2. **PR-B: Login (Owner, screen 15-owner)** — exercises `BbButton` + `BbInput` + glass surface. Touches auth flow; FROZEN logic unchanged.
3. **PR-C: Rezervacije (Owner, screen 02-owner)** — validates `BbStatusBadge` + `BbChip` + table layout.
4. **PR-D: Widget Calendar (Widget, screen 01-widget)** — exercises mint shell override + calendar layout.
5. PR-E…N: remaining screens, parallelizable.

Each PR should:
- `import 'package:bookbed/shared/widgets/redesign.dart'`
- preserve all existing FROZEN regions (CLAUDE.md NIKADA NE MIJENJAJ table)
- use `BbScaffold` where the screen currently wraps in Scaffold/BBScaffold/CommonAppBar
- keep state/repository/logic layer untouched

## 9 · Files committed

```
pubspec.yaml + pubspec.lock                                      (material_symbols_icons)
lib/core/design/tokens.dart                                      (eyebrow + displayLg + hero gradient + purple shadows + JetBrains Mono mono)
lib/core/design/bb_redesign_tokens.dart                          (NEW — ThemeExtension)
lib/core/theme/app_colors.dart                                   (mintWidget + mintWidgetTint)
lib/core/theme/app_shadows.dart                                  (cardElevated + purpleSm + panelLight/Dark)
lib/core/theme/app_theme.dart                                    (wire BbRedesignTokens into extensions list)
lib/shared/widgets/redesign/  (20 files)                         (NEW — 19 widgets + bb_scaffold)
lib/shared/widgets/redesign.dart                                 (NEW — barrel)
design_handoff/                                                  (NEW — reference package, ~700KB)
audit/103-redesign-tokens-primitives-shell.md                    (this file)
```

## 10 · Hard guardrails honored

- No PROD deploy, no dev deploy
- UI-only, FROZEN logic untouched
- No legacy `Bb*` widget modified
- No router modified
- No `AppTheme` component theme rewritten (only `extensions:` grew by one)
- `dart format` clean
- Branch-guard verified before commit (per memory [[multi-agent-git-race]])

---

## Amendment — Phase 1.7 · adminDark token foundation (2026-06-01)

**Branch:** `foundation/phase-1.7-admin-dark`
**Scope:** Additive token layer only. Zero screen migrations, zero existing-theme mutations.

### Why this amendment

Phase 1 (this audit, §1) deliberately deferred the admin console's dark deep-purple identity (`#1E1A33` per `design_handoff/README.md` §148) so the foundation PR stayed scoped to owner-app surfaces. Phase 2 admin-screen refactors cannot proceed until the dark token surface exists — otherwise each admin screen PR would re-derive the same `ADM_SB_*` hex constants from `design_handoff/source/admin-shell.jsx`, exactly the drift Phase 1 was designed to prevent (§1).

### What landed

- New `BbAdminDarkTokens extends ThemeExtension<BbAdminDarkTokens>` appended to `lib/core/design/bb_redesign_tokens.dart` (same file — keeps all redesign tokens centrally addressable).
- 14 fields, all hex transcribed verbatim from `design_handoff/source/admin-shell.jsx`:
  - `shellBg` `#1E1A33` (`ADM_SB_BG`)
  - `panelBg` `#2A2342` (shellBg lifted ~+5% white — elevated panel layer for future fully-dark admin subscreens)
  - `divider` `rgba(255,255,255,0.08)` (`ADM_SB_BORDER`)
  - `textPrimary` `#FFFFFF` / `textSecondary` `rgba(255,255,255,0.72)` (`ADM_SB_TXT`) / `textTertiary` `rgba(255,255,255,0.40)` (nav-group eyebrow)
  - `navTileIdleBg` / `navTileActiveBg` / `navTileActiveBorder` (`rgba(255,255,255,0.06|0.08|0.10)`)
  - `navIconActiveGradient` = `BBGradient.hero` (reuses owner purple hero on dark surface)
  - `navActiveGlow` `[BoxShadow(rgba(139,111,255,0.40), blur 12, dy 4)]`
  - `adminBadgeBg` `rgba(139,111,255,0.28)` / `adminBadgeFg` `#C9BBFF`
  - `profileSecondaryText` `rgba(255,255,255,0.5)`
- Static const `BbAdminDarkTokens.preset` — canonical instance for admin shells to consume.
- `BbAdminDarkTokens.of(BuildContext)` — Theme-extension resolver with fallback to `preset` (matches `BbRedesignTokens.of` pattern).

### Strictly additive — what was NOT touched

- `AppTheme.lightTheme` extensions list — unchanged.
- `AppTheme.darkTheme` extensions list — unchanged. Owner dark mode continues to resolve `BbRedesignTokens.dark` (OLED `#000000` shellBg). Admin's deep-purple `#1E1A33` is **not** wired into owner dark — proven by a regression test (`bb_admin_dark_tokens_test.dart` → "AppTheme.darkTheme (owner) does NOT register BbAdminDarkTokens — isolation guard").
- `BbRedesignTokens` light/dark presets — unchanged. No field added, no field renamed, no value changed.
- All migrated owner / widget screens — unchanged (full test suite must remain green).
- No admin shell refactor in this PR. Admin chrome refactor is a separate Phase 2 PR that imports `BbAdminDarkTokens.preset` directly.

### Wiring contract (consumer side)

Admin shell, when built, wraps its dark sidebar / rail subtree in a `Theme(data: ..., extensions: [BbAdminDarkTokens.preset, ...])` so `BbAdminDarkTokens.of(context)` resolves in that subtree. The light topbar + body continue to resolve the outer light theme + `BbRedesignTokens.light`. This mirrors the `theme-light bb-screen` + dark sidebar hybrid shipped in `design_handoff/source/admin-shell.jsx` line 145.

### Test coverage

`test/core/design/bb_admin_dark_tokens_test.dart` covers:

1. `preset.shellBg == #1E1A33` (handoff-verbatim hex)
2. on-dark contrast tokens (`textPrimary` / `textSecondary` / `textTertiary` / `divider` / `adminBadgeFg`)
3. `navActiveGlow` is non-empty + carries the purple color
4. `of(context)` fallback returns `preset` when no admin theme is wired (the default case)
5. `of(context)` returns the wired instance when a `Theme.extensions` registers one
6. `copyWith` overrides only the named field; sibling fields unchanged
7. `lerp` at `t=0` / `t=1` / `t=0.5` — no null deref; non-`BbAdminDarkTokens` other returns `this`
8. Isolation guard: `AppTheme.darkTheme` MUST NOT register `BbAdminDarkTokens` (would recolor owner dark)

### Verification

- `dart format` on the two touched files — clean
- `flutter analyze --no-fatal-infos` — 0 errors
- `flutter test` — full suite green; owner / widget screens MUST NOT recolor (regression-checked by the isolation guard test above)

### Out of scope (deferred to later phases)

- Admin shell composition (`AdminScaffold` / `AdminSidebar` / `AdminRail` / `AdminTopbar`) — Phase 2 admin-shell PR
- Admin dashboard / users / bookings / payments / sync / support screen refactors — Phase 2 per-screen PRs
- Admin login (`admin-auth.jsx`) — Phase 2 admin-auth PR
- Migrating the existing admin chrome (`lib/admin*`) onto these tokens — Phase 2 lift-and-shift PR
