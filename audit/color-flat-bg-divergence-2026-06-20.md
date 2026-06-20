# Color / FLAT-surface divergence sweep

**Date:** 2026-06-20 | **HEAD:** `54f0820a` | **Scope:** `lib/**` (owner / widget / admin / shared), excluding `*.g.dart` + `test/`. READ-ONLY (no source changed).

Ground truth: `lib/core/design/tokens.dart` (BB*), `lib/core/theme/{app_colors,app_gradients,app_shadows,app_theme}.dart`, `lib/core/design/bb_redesign_tokens.dart`, `lib/core/design_tokens/**`, `design_handoff/source/tokens.css`. FLAT-chrome contract (CHANGELOG 7.23 / audit/127): owner chrome (page / section / card backgrounds, app bars, drawers, sidebars) renders as **solid fills**, **no gradients**, **no box-shadow lift in light theme** (dark lifts via a lightness ladder, not shadow).

---

## 1. Summary — counts by category × surface

| Category | Total non-token sites | Genuine **chrome** divergences | Decorative / status / dialog / FAB / scrim / widget-surface / pre-theme (intentional, NOT flagged) |
|---|---|---|---|
| Raw hex `Color(0x…)` | 228 | 1 (+ ~9 hygiene, already-flat) | ~218 |
| `Colors.<named>` (non-trivial) | ~21 true (grep noise: most matches are `AppColors.*` substrings) | 0 | ~21 (all status/destructive/warning semantics; none are bg fills) |
| Gradient (Linear/Radial/Sweep) | 40 | **1** | 39 |
| Box-shadow / `elevation:` lift | ~235 | **5 candidates** | ~230 |
| Dead/deprecated token occurrences | — | — | see §3 |

**The real flat-chrome findings (6):** one gradient-on-a-card, five raw inline `BoxShadow`s on light-theme chrome surfaces. Everything else is decorative or token-backed. Detail in §2.

---

## 2. Divergence table — genuine + candidate findings

`file:line | category | current value | nearest BB* / flat-ladder value | confidence | note`

### 2a. CHROME divergences (the real ones)

| file:line | category | current | correct token / flat value | conf | note |
|---|---|---|---|---|---|
| `lib/features/owner_dashboard/presentation/widgets/send_email_dialog.dart:273` | gradient + hex | `LinearGradient` sky100→sky50 (`0xFFE0F2FE`/`0xFFF0F9FF`) light, slate800→slate900 dark; border `0xFF0EA5E9`/`0xFF334155` | flat `c.surfaceVariant` (#F5F5F5 / #1E1E1E) + `c.border`; or `context.gradients.cardBackground` | **med** | Guest-Info **content card** painted with a gradient + 4 raw hex. Dialog surface, but it is a section card → flat-chrome candidate. |
| `lib/features/owner_dashboard/presentation/screens/owner_booking_detail_screen.dart:1144` | box-shadow | raw `BoxShadow(Colors.black α0.05, blur24, offset(0,-8))` on bottom action-bar (`color: c.surface`, top border) | `BBShadow.sm` / drop, or keep as sanctioned sticky-bar lift | **med** | Raw upward shadow on a **chrome strip** in light theme. Handoff may sanction a sticky-bar float; divergence is that it is raw, not a token. |
| `lib/features/owner_dashboard/presentation/screens/unit_form_screen.dart:565` | box-shadow | raw `BoxShadow` black α0.1 (light) on content card, radius 24 | `BBShadow.resting(context)` / `cardElevated` | med | Raw card shadow, light theme. |
| `lib/features/owner_dashboard/presentation/screens/property_form_screen.dart:669` | box-shadow | raw `BoxShadow` black α0.1 (light) on content card, radius 24 | `BBShadow.resting(context)` / `cardElevated` | med | Mirror of unit_form card. |
| `lib/features/owner_dashboard/presentation/screens/widget_settings_screen.dart:1561` | box-shadow | raw `BoxShadow` black α0.08 (light) on content card, radius 16 | `BBShadow.resting(context)` / `cardElevated` | med | Raw card shadow, light theme. |
| `lib/shared/widgets/redesign/bb_sidebar.dart:264` | box-shadow + hex | raw double `BoxShadow(0x0D101828 …)` + `BoxShadow(0x2914182D …)` on **active sidebar nav item** (`active ? c.surface`) | `BBShadow.cardElevated` / `AppShadows.panelLight` | med | Sidebar = chrome. This is the handoff `--bb-shadow-card` ramp **inlined raw** rather than the `BBShadow.cardElevated` token. Sanctioned for active nav tiles, but should reference the token. |

> Caveat on the 5 shadow rows: the handoff explicitly sanctions a premium card/sticky-bar float (`BBShadow.cardElevated` / `panelLight`). The divergence here is that the shadow is a **raw inline `BoxShadow`** rather than a BB token — and on a light-theme chrome surface where a pure-flat reading would have none. Human call needed on form cards (items 3–5) vs the flat ladder.

### 2b. Hygiene candidates (off-token but already FLAT — no gradient/lift, so NOT flat-violations)

| file:line | category | current | nearest token | conf | note |
|---|---|---|---|---|---|
| `lib/features/owner_dashboard/presentation/widgets/calendar/shared/calendar_summary_bar.dart:37,94,95,187` | hex | `0xFF1A1A24`/`0xFFFAFAFC`/`0xFF2A2A35`/`0xFFF5F5FA`/`0xFF1E1E28`/`0xFFF0F0F5` | `surface` / `surfaceVariant` / `cardBackground` | med | Hard-coded light+dark surface fills on the calendar summary bar. Flat already; token-hygiene only. |
| `lib/shared/widgets/offline_indicator.dart:60` | hex | `0xFF2E7D32` (green) | `AppColors.success` `#2E7D5B` | med | Offline banner green ≠ success token. |
| `lib/shared/widgets/offline_indicator.dart:42` | hex | `0xFF333333` | `BBColor.textPrimary` / dark elevated `#333333` | low | Banner bg. |
| `lib/features/admin/presentation/screens/admin_dashboard_screen.dart:167` | hex | `0xFF4A90D9` | `AppColors.info` (== same value) | low | Value matches info token; replace literal with token. |
| `lib/core/widgets/owner_splash_screen.dart:232,233,380,381` | hex | `0xFF000000` / `0xFFFAFAFA` | dark `#000` OK; light page `#F0F1F5` | med | Splash page bg uses legacy `#FAFAFA` not the `#F0F1F5` shell. Pre-app, low impact. |

### 2c. `Colors.<named>` — hygiene class (status/destructive/warning, NOT bg fills → no flat-chrome violation)

All ~21 true Material-named hits are semantic colors that should map to `AppColors.error/warning/success/info`. None paint a page/section/card background. Representative (grouped):

| file:line(s) | current | nearest token | note |
|---|---|---|---|
| `lib/core/utils/platform_utils.dart:246`; `lib/core/errors/error_handler.dart:69`; `…/notifications_screen.dart:346,350`; `…/bank_account_screen.dart:449`; `…/auth/.../edit_profile_screen.dart:680`; `…/multi_select_action_bar.dart:274` | `Colors.red` | `AppColors.error` (`destructiveSoft` for buttons) | destructive CTAs / error snackbars |
| `…/calendar/booking_context_menu.dart:63,104,109,120,127`; `…/multi_select_action_bar.dart:255` | `Colors.orange` | `AppColors.warning` / `statusImported` | import/iCal accent |
| `…/calendar/smart_booking_tooltip.dart` (×11); `…/booking_action_menu.dart` (×18); `…/calendar/calendar_error_state.dart` (×11) | `Colors.red.shadeN` / `orange.shadeN` | `error` / `warning` | tooltip + popup-menu + error-state (all elevate; low prio) |
| `…/widgets/owner_app_drawer.dart:590,897` | `amber.shade600/700`, `red.shade600` | `warning` / `error` | drawer = chrome, but these are a trial badge + logout tint, not surface fills |
| `…/subscription/trial_banner.dart:200-224` (×8) | `red.shadeN`/`amber.shadeN` | `error`/`warning` | trial banner (already flat per CL 7.23) |
| `…/guides/embed_widget_guide_screen.dart:1114,1235` | `Colors.grey.shade50` | `surfaceVariant` #F5F5F5 | code/example fill |
| `lib/shared/widgets/delete_account_dialog.dart:469-481`; `…/animations/animated_success.dart:262` | `Colors.green` | `AppColors.success` #2E7D5B | success confirm/animation |

### 2d. Gradient sites — confirmed DECORATIVE (intentional, NOT flagged)

39 of 40. All paint icon tiles, hero glows, charts, dividers, drag/drop feedback, status chips, progress bars, avatars, skeletons, FAB/CTA buttons, or pre-login auth/admin hero backgrounds. Notable, all OK:
- `dashboard_overview_tab.dart:333` chart fade overlay (scaffoldBg alpha); `:692` error-icon circle; `:1023` **dark-only** primary icon circle (light = flat fill); `:1819` radial wash behind headline; `:2090` gauge `SweepGradient`; `:2154` AI/primary icon tile; `:2547` progress bar. The AI hero card itself (`:2142`) is correctly **flat** `c.surfaceVariant` — gradient is on the icon tile only.
- `owner_booking_detail_screen.dart:484` cover-photo scrim (decorative).
- `bookings/bookings_premium_header.dart:776` amber priority rail (handoff-sanctioned; stop `0xFFFFD08A` is a raw hex but on a 4px decorative rail).
- `property_card_owner.dart:162,214,275,300,389,577` badge chips + transparent→divider hairlines + avatar.
- `guides/ai_assistant_screen.dart:1292` AI hero glow; `admin/admin_login_screen.dart:274,290,517,1002` admin auth hero; `auth/gradient_auth_button.dart`, `shared/gradient_button.dart` CTA buttons; `subscription_screen.dart:256,408` premium hero wash.

### 2e. Box-shadow sites — confirmed OK (token-backed / dialog / FAB / dark-only / decorative)

~230 sites. Cards/panels that use `BBShadow.cardElevated` / `panelLight` / `rd.panelShadow` / `AppShadows.getElevation(...)` are handoff-sanctioned premium float (e.g. `month_calendar_screen.dart:1593`, `owner_timeline_calendar_screen.dart:1252`, `profile_screen.dart:165`, `about_screen.dart:62`, `bank_account_screen.dart:540`, `ical_*`). FABs, dialogs, popup menus, tooltips, focus rings, skeletons, icon-tile glows, and `dark ? […] : null` shadows all legitimately elevate or are dark-only.

---

## 3. Dead / deprecated token occurrences

| Token | Status | Occurrences (consumers) | Action |
|---|---|---|---|
| `BBSpace.xs2` (=12) | deprecated-on-use | **0** | none — clean |
| `BBRadius.xs2` | n/a | **0** (symbol doesn't exist; `BBRadius` has no `xs2`) | none |
| `cream` | DEAD | **0 real consumers**. Only `lib/core/design_tokens/gradient_tokens.dart:26` (a `// Cream/beige` comment on a hex) + `custom_icons_tablericons.dart` (unrelated `kiceCream` icon glyphs) | drop the comment-only reference if tidying |
| `subtleBackground` (`subtleBackgroundLight/Dark`) | DEAD | **0 consumers**. Defined in `lib/core/design/tokens.dart:1119,1126` (`BBGradient`) + `lib/core/design_tokens/gradient_tokens.dart:22,32`; never read anywhere | safe to delete both definitions |
| `shellBg` / `shellBgLight` / `shellBgDark` / `rd.shellBg` | **CANONICAL, not dead** | ~20: `app_theme.dart` (scaffold/appbar/statusbar), `bb_scaffold.dart` (panel layer), `owner_app_drawer.dart:233`, 3 legal screens, `admin_shell_screen.dart`, `unit_wizard`/`booking_detail` (in comments) | KEEP. `AppColors.shellBgLight` (#F0F1F5) / `shellBgDark` (#000) **==** `context.gradients.pageBackground` first stop. The DEAD-token spec calls `shellBg` "redundant vs pageBackground"; in practice it's the legitimate scaffold/L1 source. Only "redundant" in that two names resolve to one value — usage is correct, not a divergence. |

Also clean: `BBSpace` off-grid bridge consts (`xxs2`, `xs6`, `sm20`, `lg40`, `xl56`, `xxxl96`) and `BBRadius` bridges (`tiny`, `subtle`, `medium`, `large`) are deprecated-annotated in `tokens.dart` but were not in scope to enumerate call-sites; the two named in the brief (`BBSpace.xs2`, `BBRadius.xs2`) are zero-use.

---

## 4. Token source-of-truth + app_colors ↔ tokens.css drift

**Source-of-truth files (legitimately hold hex; map other hits to these):**
- `lib/core/theme/app_colors.dart` — base palette (brand/semantic/surface/status/gradients/elevations/scrims).
- `lib/core/theme/app_gradients.dart` — `AppGradients` ThemeExtension (`context.gradients.*`); pageBackground/sectionBackground are FLAT (both stops equal one tone; `begin/end/stops` inert by design).
- `lib/core/theme/app_shadows.dart` — `AppShadows.elevation0-5` + colored/glow/neumorphic + handoff `cardElevated`/`purpleSm`/`panelLight`/`panelDark`.
- `lib/core/design/tokens.dart` — `BBColor`/`BBShadow`/`BBGradient` (delegates to AppColors/AppShadows; holds `BBColorPalette` Tailwind steps + `BBGradient.hero`).
- `lib/core/design/bb_redesign_tokens.dart` — `rd.*` (shellBg, panelShadow, purpleGlow, etc.).
- `lib/core/design_tokens/**` — 12 legacy token files (color/gradient/shadow/spacing/etc.); Phase-2 codemod targets, still imported by calendar + Cjenovnik (frozen).
- Widget-surface theme: `lib/features/widget/presentation/theme/minimalist_colors.dart` + `AppColors.mintWidget`/`mintWidgetTint` (#3DD9B0) — legitimate on `lib/features/widget/**` only.
- Skeleton palettes: `lib/shared/widgets/animations/skeleton_loader.dart`, `lib/core/widgets/bb_skeleton.dart`.

**Drift vs `design_handoff/source/tokens.css`:**

| Token | tokens.css | app_colors.dart | drift? |
|---|---|---|---|
| `--bb-primary` / `-dark` / `-light` (light) | #6B4CE6 / #5638C7 / #B5A4F0 | identical | ✅ none |
| `--bb-primary` dark | #8B6FFF | `primaryDarkMode` #8B6FFF | ✅ none |
| `--bb-bg` light | #FAFAFA | `backgroundLight` #FAFAFA | ✅ matches; **but** page shell is `--bb-shell-bg` #F0F1F5 = `shellBgLight` (scaffold uses shellBg, not bg — correct per audit/126/127) |
| `--bb-surface` / `-variant` / border (light) | #FFFFFF / #F5F5F5 / #E2E8F0 | identical | ✅ none |
| `--bb-shell-bg` light/dark | #F0F1F5 / #000 | `shellBgLight`/`shellBgDark` identical | ✅ none |
| `--bb-surface` **dark** | **#121212** | `surfaceDark` **#1E1E1E** | ⚠ **intentional** — audit/127 "dark-depth" WIDENED the dark ladder away from raw css (#000 page → #141414 panel → **#1E1E1E** card → **#2A2A2A** variant → #333333 elevated) because flat-dark has no shadow, so lightness must carry elevation. Documented in `app_colors.dart:104-113` + `app_gradients.dart:90-99`. NOT a bug. |
| `--bb-surface-variant` **dark** | **#1E1E1E** | `surfaceVarDark` **#2A2A2A** | ⚠ same intentional widen |
| `--bb-panel-bg` dark | #0B0B0D | `_darkStart` page = #000; panel layer in `bb_scaffold` resolves via `rd.shellBg` | ⚠ handoff #0B0B0D superseded by the #000-base ladder (the old #0B0B0D "card dissolve" trap was fixed in CHANGELOG 7.23). |
| `--bb-status-pending` | (handoff amber) | `statusPending` #B7791F (AA-safe darker) | minor deliberate (AA contrast) |

Net: **light values are byte-aligned to the handoff**; the only "drift" is the **deliberate post-handoff dark-depth widening** (audit/127) and the shellBg-vs-bg scaffold choice (audit/126) — both intentional, both documented. No accidental color drift found in `app_colors.dart`.
