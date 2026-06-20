# Responsive / Overflow / A11y Recon — owner + widget + admin

**Date:** 2026-06-20 · **HEAD:** `54f0820a` (main) · **Mode:** READ-ONLY (no code changed)
**Scope:** `lib/**` owner (owner_dashboard + auth + subscription), widget (features/widget + widget_main*), admin (features/admin + admin_main*), shared (core + shared/widgets). Excludes `*.g.dart`, `test/`.
**Canonical breakpoints used for judging:** Desktop ≥1200 · Tablet 600–1199 · Mobile <600 (per prompt). Tablet grid → 2-col @ ≥720 (audit/128); mobile gap 12px via in-file `const _kMobileGap`.

## Existing house helpers (deviations are flagged against these)

There are **TWO** responsive helpers + **TWO** breakpoint-constant sources — and they disagree, which is itself the root of the breakpoint inconsistency below:

| Helper | File | mobile | tablet | desktop | wide |
|---|---|---|---|---|---|
| `BBResponsive` / `BBBreakpoint` (canonical, `responsive.dart`) | `lib/core/design/tokens.dart:643` + `lib/core/design/responsive.dart` | <600 | <1024 | <1440 | ≥1440 |
| `Breakpoints` (legacy) | `lib/core/constants/breakpoints.dart` | <600 | <1024 | ≥1024 | (1920 large) |

Both agree **mobile = 600**, but their tablet/desktop split is **1024** — which matches NEITHER the prompt's canonical desktop=1200 nor the recent `_kDesktopBp = 1200` convention in the AI-assistant/unit-hub screens. `responsive.dart` is the documented canonical (`BBResponsive.of` / `BBResponsiveBuilder` / `BBResponsiveValue`), yet almost no screen actually consumes it — most roll their own `MediaQuery...width < N` inline.

**A11y helpers** (`lib/core/accessibility/accessibility_helpers.dart`): `AccessibleIconButton`, `AccessibleInkWell`, `AccessibleGestureDetector`, `AccessibleCard`, `AccessibleImage`, `.withSemantics()` extension, and `A11yConstants` (**minTapTargetSize = 44**, touchTargetMedium = 48). These exist but are essentially **unused** outside the file — every flag in §3/§4 below is a raw `IconButton`/`InkWell` that bypassed these wrappers.

---

## Summary counts

| Category | Count | P0 | P1 | P2 |
|---|---|---|---|---|
| 1. Breakpoint consistency | 18 stray thresholds across 12 files | 1 | 4 | 13 |
| 2. RenderFlex overflow risk | 3 confirmed | 1 | 2 | 0 |
| 3. A11y — missing semantics | ~12 confirmed (of 33+18 scanned) | 0 | 4 | 8 |
| 4. Tap targets <48px | 5 confirmed | 0 | 1 | 4 |
| 5. Contrast-on-dark (heuristic, low conf) | ~8 risk sites | 0 | 0 | 8 |

**P0 (will visibly break):**
- **Admin users table** `users_list_screen.dart` DataTable (5 cols, no horizontal scroll, no cell ellipsis) → horizontal RenderFlex overflow on 800–1100px windows (it only renders ≥800px; below that it falls back to cards). See §2.
- **Breakpoint fragmentation** is P0-adjacent for *consistency* (not a crash): the same "is this mobile/desktop?" question is answered with 600/700/800/900/1024/1100/1200/1440 across the app; behaviour visibly differs screen-to-screen at e.g. 850px. See §1.

**P1/P2 (polish):** unguarded guest-name `Text` in the calendar booking-action menu (wraps, breaks compact header); icon-only nav chevrons / dialog-close X without tooltips; 32–40px tap targets on password toggle + app-bar back + calendar error actions; static `Colors.grey[600]` text on dark surfaces.

---

## 1. Breakpoint consistency

Threshold per site; "helper?" = uses a house helper vs rolls its own. Mobile=600 is consistent and correct everywhere; the **non-600 thresholds** are the inconsistency.

| file:line | threshold(s) | helper? | confidence | suggested fix |
|---|---|---|---|---|
| `lib/core/constants/breakpoints.dart` (whole file) | desktop=**1024** | defines `Breakpoints` | high | Reconcile with `BBBreakpoint` (1440) or the 1200 convention; pick ONE source of truth. |
| `lib/core/design/tokens.dart:650,653` (`BBBreakpoint`) | tablet=**1024**, desktop=**1440** | defines `BBBreakpoint` | high | Decide vs prompt-canonical 1200; doc says `BBContentMaxWidth` caps at 1200 yet desktop class starts at 1440 — mismatch. |
| `lib/features/admin/presentation/screens/user_detail_screen.dart:17` | `_mobileBreakpoint = **900**` | own const | med | Align admin mobile cutover (900 vs 800 vs 1100 below). |
| `lib/features/admin/presentation/screens/users_list_screen.dart:14` | `_mobileBreakpoint = **800**` | own const | med | Align with user_detail's 900 — same cluster, different number. |
| `lib/features/admin/presentation/screens/admin_dashboard_screen.dart:11,12` | mobile=**800**, tablet=**1100** | own consts | med | Standardise admin tier set. |
| `lib/features/admin/presentation/screens/admin_shell_screen.dart:16,17` | rail=**800**, sidebar=**1100** | own consts | low | Shell rail/sidebar tiers (intentional for nav, but document). |
| `lib/features/owner_dashboard/.../calendar/month_calendar_screen.dart:175,736,775,1633` | <**600** ×4 | inline MQ | low | Correct value; could use `Breakpoints.isMobile`/`context.isMobile`. |
| `lib/features/owner_dashboard/.../dashboard_overview_tab.dart:643` | >**900** | inline MQ | med | Stray 900 desktop cutover; should be 1200 (canonical) or `Breakpoints`. |
| `lib/features/owner_dashboard/.../ical/ical_sync_settings_screen.dart:111,112,255` | >**900**, >**600**, >**700** | inline | med | 700 + 900 mixed; consolidate to 600/1200. |
| `lib/features/owner_dashboard/.../ical/ical_export_list_screen.dart:636,637` | >**900**, >**600** | inline | med | Same stray-900 pattern. |
| `lib/features/owner_dashboard/.../stripe_connect_setup_screen.dart:288,289` | >**900**, >**600** | inline | med | Stray 900. |
| `lib/features/owner_dashboard/.../guides/embed_widget_guide_screen.dart:270` | >**700** | inline | med | Stray 700. |
| `lib/features/owner_dashboard/.../widget_settings_screen.dart:1221,1415` | ≥**600**, ≥**400** | inline | low | 400 = very-small tier (fine); 600 OK. |
| `lib/features/owner_dashboard/.../revenue_chart_widget.dart:130,132` | >**600**, >**400** | inline | low | Chart-height tiers; OK but magic. |
| `lib/features/owner_dashboard/.../unified_unit_hub_screen.dart:40,43,46` | desktop=**1200**, tablet=**800**, mobile=600 | own `_k*` consts | low | tablet=800 (not 720 audit/128); desktop=1200 correct. |
| `lib/features/owner_dashboard/.../owner_booking_detail_screen.dart:38` | `_kTabletGridMinWidth=**720**` | own const | low | ✅ matches audit/128 720 convention — reference. |
| `lib/features/owner_dashboard/.../guides/faq_screen.dart:273,275` + `guides/embed_help_screen.dart:78,80` | ≥**1024**, ≥**600** | inline | low | 1024 column tier; align to canonical desktop. |
| `lib/features/owner_dashboard/.../widgets/timeline/timeline_constants.dart:61,64` | mobile=600, tablet=**900** | own consts | low | Calendar uses tighter 900 tablet (documented intentional; `Breakpoints.calendarTablet=900` mirrors). |
| `lib/features/widget/.../calendar/calendar_compact_legend.dart:22` + `calendar_combined_header_widget.dart:42,43` | desktop=**1024**, small=**400** | own consts | low | Widget calendar 1024 desktop; OK internally consistent. |
| `lib/features/widget/.../calendar/calendar_view_switcher_widget.dart:16,17` | small=**450**, tiny=**360** | own consts | low | Device-specific (iPhone SE); intentional. |
| `lib/features/widget/.../booking/compact_pill_summary.dart:57` | `_columnLayoutBreakpoint=**280**` | own const | low | Intra-component column flip; fine. |
| `lib/core/utils/responsive_dialog_utils.dart:69,80` | <600, ≥**1024** | own util | low | Dialog sizing; 1024 desktop. |
| `lib/shared/widgets/redesign/bb_scaffold.dart:39,40` | mobile=600, desktop=**1024** | params | low | Defaults to 1024 desktop — differs from `BBBreakpoint` 1440. |
| `lib/features/auth/.../enhanced_login_screen.dart:406` + `enhanced_register_screen.dart:319` | ≥**1200** | inline | low | ✅ 1200 = canonical split panel. |
| `lib/features/subscription/screens/subscription_screen.dart:73` | ≥**720** | inline | low | ✅ 720 (audit/128 2-col). |

**Net:** mobile=600 is universal ✓. The desktop boundary is the mess — **1024 / 1100 / 1200 / 1440** all in play, plus stray **700/900** mid-tiers in iCal + Stripe + overview screens. Most screens ignore `BBResponsive`/`Breakpoints` and inline raw `MediaQuery`. Recommend a single codemod to `Breakpoints.*` / `context.isMobile` (separate PR per CLAUDE.md no-in-place-refactor rule).

---

## 2. RenderFlex overflow risks

(History: audit/124/126/128 already fixed Pregled hero / Rezervacije `_Fact` chips / booking-detail eyebrows / `bookings_premium_header` guest row — all now `Flexible`+ellipsis and **verified clean here**. These are the REMAINING ones.)

| file:line | issue | detail/value | confidence | suggested fix |
|---|---|---|---|---|
| `lib/features/admin/presentation/screens/users_list_screen.dart:453–519` | `DataTable` (Name/Email/Account/Created/Actions = 5 cols) wrapped only in a **vertical** `SingleChildScrollView`; no horizontal scroll, cells (`SelectableText(displayName)`@481, `SelectableText(user.email)`@493) have no ellipsis | renders only ≥800px (cards below via `_mobileBreakpoint=800`), so the squeeze hits the 800–1100px window where 5 cols + long emails exceed width → horizontal overflow | **high** | Wrap DataTable in `SingleChildScrollView(scrollDirection: Axis.horizontal)` OR raise the card-fallback cutover to ~1100. |
| `lib/features/owner_dashboard/.../calendar/booking_action_menu.dart:115` (and `:101` sourceDisplayName) | `Text(booking.guestName)` fontSize 18 bold + platform name, in `Expanded`→`Column`, **no maxLines / overflow** | Expanded bounds width so it won't throw, but a long guest/platform name **wraps to 2–3 lines** and breaks the compact action-menu header layout | med | Add `maxLines: 1, overflow: TextOverflow.ellipsis` to both `Text`s. |
| `lib/features/owner_dashboard/.../calendar/booking_action_menu.dart:~649` | secondary guest-name `Text` in a stacked title/subtitle Column, no ellipsis | same wrap-not-crash class | med | `maxLines`+ellipsis. |

**Verified-clean (do NOT re-flag):** `bookings_premium_header.dart` guest row (`Expanded`+`maxLines:1`+ellipsis @817–839) and `_Fact` chips (`Wrap`, audit/126); `bank_transfer_details_card` / `payment_info_card` (`Expanded flex` on values); `user_detail_screen` / `activity_log_screen` `_InfoRow` (Expanded); subscription plan rows.

---

## 3. A11y — missing semantics

Icon-only `IconButton`/`InkWell`/`GestureDetector` with no `tooltip` / `semanticLabel` / `Semantics` wrapper. (The `AccessibleIconButton`/`AccessibleInkWell` helpers exist but are unused — fix = route through them or add `tooltip:`.)

| file:line | issue | detail | confidence | suggested fix |
|---|---|---|---|---|
| `lib/shared/widgets/redesign/bb_app_bar.dart:205` | 40×40 `InkWell` icon-only nav/back button, no Semantics | shared app-bar → affects every screen using it; ALSO <48 tap target (§4) | **high** | `Tooltip`/`Semantics(button,label)` + bump to 48. |
| `lib/shared/widgets/redesign/bb_sidebar_rail.dart:82` | 48×48 logout `InkWell` icon-only, no Semantics | shared admin rail | **high** | wrap in `Semantics(button:true,label:'Odjava')` or `AccessibleInkWell`. |
| `lib/shared/widgets/custom_date_range_picker.dart:330,350` | prev/next month `IconButton(chevron_left/right)` no tooltip | shared date picker; non-obvious to screen readers | **high** | add `tooltip:` (prev/next month). |
| `lib/features/owner_dashboard/.../widgets/price_list_calendar_widget.dart:325,387,1532,1958` | month-nav + action `IconButton`s no tooltip | calendar chevrons | med-high | `tooltip:` per button. |
| `lib/features/owner_dashboard/.../widgets/edit_booking_dialog.dart:167,222,236,302,338` | dialog close-X + action `IconButton`s no tooltip | `Icons.close`/edit icons | med | `tooltip:` (Zatvori, etc.). |
| `lib/features/owner_dashboard/.../widgets/{language,theme}_selection_bottom_sheet.dart:66/67` | close-X `IconButton` no tooltip | sheet header | med | `tooltip: l10n.close`. |
| `lib/features/admin/presentation/screens/users_list_screen.dart:204` | clear-search `IconButton(Icons.clear)` no tooltip | search field trailing | med | `tooltip:'Clear'`. |
| `lib/features/widget/.../details/bank_transfer_details_card.dart:203` | copy-to-clipboard `InkWell(Icons.copy)` no Semantics | also ~24px tap target (§4) | med | `Semantics(button,label:'Kopiraj')` + pad to 48. |
| `lib/features/auth/.../enhanced_register_screen.dart:551,581` | password show/hide `IconButton` no tooltip | (login@610 HAS a `Tooltip` parent → not flagged) | med | `tooltip:` show/hide. |
| `lib/features/widget/.../pwa/pwa_install_button.dart:118` | icon `IconButton` no tooltip | install affordance | low | `tooltip:`. |
| `lib/features/owner_dashboard/.../widgets/timeline/timeline_split_day_cell.dart:107` | `GestureDetector(onTap)` icon-only cell, no Semantics | calendar day cell | low | `Semantics` label w/ date+status. |
| Legal screens `privacy_policy/cookies_policy/terms_conditions_screen.dart:446/414/426` | `InkWell` back/nav icon, no Semantics | 3 pre-login screens | low | `Semantics(button,label)`. |

(33 `IconButton` + 18 `InkWell/GD` scanned; many close-X are semantically guessable → P2. `enhanced_login_screen.dart:610`, `calendar_top_toolbar.dart:629`, and several copy buttons DO have a `Tooltip`/`Semantics` parent → **not** flagged.)

---

## 4. Tap targets <48px

| file:line | issue | size found | confidence | suggested fix |
|---|---|---|---|---|
| `lib/shared/widgets/redesign/bb_app_bar.dart:205` | `SizedBox(width:40,height:40)` around InkWell icon | **40×40** | high | bump to 48×48 (shared, high traffic). |
| `lib/features/auth/.../enhanced_login_screen.dart:612` | password-toggle `IconButton` `padding:zero` + `BoxConstraints(minWidth:32,minHeight:32)` | **32×32** | high | use 48 min constraints. |
| `lib/features/owner_dashboard/.../calendar/calendar_error_state.dart:227,238` | retry + dismiss `IconButton` `padding:zero` + 32×32 constraints | **32×32** | med | 48 min (has tooltip already). |
| `lib/features/widget/.../details/bank_transfer_details_card.dart:203` | copy `InkWell` = `Padding(4)` around 16px icon | **~24×24** | med | wrap `withMinTapTarget`/`SizedBox(48)`. |
| `lib/features/owner_dashboard/.../calendar/calendar_top_toolbar.dart:629` | clear-filter `InkWell` `width:40`, height unconstrained | **40 wide** | low | width→48 (height ok via Container). |

(Note: `IconButton(padding: EdgeInsets.zero)` alone does NOT shrink the target — IconButton keeps its 48 min `constraints` default unless `constraints:` is ALSO overridden. Only the sites above override BOTH.)

---

## 5. Contrast on dark (heuristic, confidence = LOW — no rendering done)

Static greys with **no `isDark` branch**, likely rendering on dark surfaces (#000/#141414/#1E1E1E). Theme is FLAT so contrast carries surface separation. (Sites already using `isDark ? a : b` ternaries are NOT flagged.)

| file:line | issue | detail | confidence | suggested fix |
|---|---|---|---|---|
| `lib/features/owner_dashboard/.../calendar/smart_booking_tooltip.dart:336,504,514` | `Colors.grey[600]` body text, no dark branch | mid-grey on dark tooltip | low | `BBColor.of(context).textSecondary`. |
| `lib/features/owner_dashboard/.../calendar/booking_context_menu.dart:148,156` | `Colors.grey[600]` text | menu subtitle on dark | low | token `textSecondary`. |
| `lib/features/owner_dashboard/.../embed_code_generator_dialog.dart:268,351,424` | `Colors.grey.shade600/700` text | small captions on dark dialog | low | token. |
| `lib/features/owner_dashboard/.../calendar/booking_block_widget.dart:279,314` | `Colors.grey.shade700/400` | block label on dark | low | token. |
| `lib/shared/presentation/screens/not_found_screen.dart:22,44` | `Colors.grey[300]/[600]` icon+text | 404 on dark | low | token. |
| `lib/features/owner_dashboard/.../calendar/smart_booking_tooltip.dart:140` | `Colors.grey[300]` divider/border | borderline | low | token border. |
| `lib/features/owner_dashboard/.../{edit_booking_dialog:470, booking_create_dialog:1002, timeline_booking_block:232}` | `Colors.black54/black38` text | dark-on-dark if surface is dark | low | verify branch; use token. |

(92 total `Colors.grey/black/whiteNN` direct refs in `features/`; the ~8 above are the ones without an obvious dark branch. Most others are inside `isDark ? ... : ...` ternaries or on known-light surfaces → not flagged. Needs a real dark-theme render pass to confirm WCAG AA.)

---

## Notes / method

- Greps run in sandbox; every flagged site (except §5 heuristic) was **read to confirm** before listing. Two parallel read-only Explore agents confirmed the overflow set; their false positive on `bookings_premium_header` guest row was dropped after first-hand read (it IS guarded).
- No code changed. No `flutter analyze`/`build`/`pub get`/`build_runner` run (3 sibling agents share the tree).
- Biggest single fix-value: reconcile the breakpoint sources (§1) + horizontal-scroll the admin users table (§2 P0).
