# Findings

---
## Batch 1 — heavy user-facing screens (2026-07-18)

### owner_bookings_screen — 13/20
| Dim | Score | Key finding |
|---|---|---|
| A11y | 2/4 | Ledger rows no Semantics/MergeSemantics (7+ disjoint nodes/row); icon-only widgets no semanticLabel |
| Perf | 2/4 | ~200-line deep-link state machine runs in build(); MediaQuery read in nested leaf; provider watched whole ×3 |
| Theming | 3/4 | Color(0xFFFFD08A) amber rail; Colors.white ×3 in _RezAINudge |
| Responsive | 3/4 | pending-card width = (screenWidth/2)-80 ignores BBContentMaxWidth(1100); no tablet path |
| Anti-Patterns | 3/4 | dead nudge buttons (onPressed:(){}), ❓ emoji FAQ prefix, HR string leaks |

- **[P1] Dead AI nudge buttons** — bookings_premium_header.dart:602,622 — Anti-Pattern — "Odgovori"/"Kasnije" are onPressed:(){} no-ops → primary CTA silently fails. Wire or remove.
- **[P2] Pending-queue card width ignores content cap** — bookings_premium_header.dart:724 — Responsive — LayoutBuilder or clamp to min(maxWidth,1100)/2-gap.
- **[P2] Ledger rows silent to screen readers** — bookings_ledger.dart:384-396,575-588 — A11y — wrap rows in Semantics(button:true,label:...).
- **[P2] Icon-only widgets no semantic labels** — owner_bookings_sections.dart:418; bookings_ledger.dart:611,377 — A11y — overbooking warning icon silent.
- **[P2] Deep-link state machine in build()** — owner_bookings_screen.dart:210-422 — Perf — move to initState/ref.listen.
- **[P3] Color(0xFFFFD08A) hard-coded** — bookings_premium_header.dart:818 — Theming.
- **[P3] Ledger/conflict labels bypass l10n** — owner_bookings_sections.dart:202-203; dialogs.dart:181-182 — Anti-Pattern ('Unknown' fallback leaks EN).
- **[P3] ❓ emoji FAQ prefix** — owner_bookings_sections.dart:361 — Anti-Pattern (not SR-safe / not l10n).

### owner_booking_detail_screen — 13/20
| Dim | Score | Key finding |
|---|---|---|
| A11y | 2/4 | _RoundIconButton onPressed silently discarded — mail/call are dead taps |
| Perf | 3/4 | IntrinsicHeight per _TimelineRow; _relativeAgo(DateTime.now()) each build |
| Theming | 3/4 | _AmountTile eyebrow textTertiary on status tint ≈3.2:1 (fails AA) |
| Responsive | 2/4 | desktop bp hardcoded 1024 (canonical 1200); 36×36 tap targets; _kKvLabelWidth=124 fixed |
| Anti-Patterns | 3/4 | dead `sidebar` param; dead branch in _nightLabel; ~30 HR strings |

- **[P0] _RoundIconButton.onPressed silently discarded** — owner_booking_detail_screen.dart:682-697 — A11y/Anti-Pattern — declared+passed (mail :629, call :637) but never referenced in build(); renders Container+Tooltip, no InkWell → both buttons non-functional. Wrap in InkWell(onTap:onPressed). NOT FROZEN scope.
- **[P1] Desktop breakpoint 1024, canonical 1200** — :131,185 — Responsive — enters 2-col grid too early on 1024-1199.
- **[P2] _RoundIconButton tap target 36×36** — :688-689 — A11y — below 44/48px min.
- **[P2] _AmountTile eyebrow contrast fails AA** — :1278-1282 — A11y/Theming — use statusConfirmedDeep/statusPendingDeep.
- **[P2] IntrinsicHeight per _TimelineRow** — :1438 — Perf.
- **[P2] _relativeAgo(DateTime.now()) each build** — :966 — Perf — memoize.
- **[P3] dead `sidebar` param** — :832-833 (call sites 309,349,414) — Anti-Pattern.
- **[P3] dead branch _nightLabel** — :752-756 — Anti-Pattern.
- **[P3] ~30 hardcoded HR strings** — many lines — Anti-Pattern (l10n debt).

### admin_dashboard_screen — 14/20
| Dim | Score | Key finding |
|---|---|---|
| A11y | 2/4 | KPI icons no Semantics; distribution progress bar invisible to SR; legend dot no label |
| Perf | 3/4 | _DashboardPalette.of watches provider redundantly; layout math each rebuild |
| Theming | 3/4 | Color(0xFF4A90D9) duplicates AppColors.info exactly |
| Responsive | 3/4 | _StatsLoading width:240 skeleton overflows narrow mobile; analytics width:280 cramped 800-900 |
| Anti-Patterns | 3/4 | _StatsError renders raw err.toString() to admin |

- **[P2] KPI tiles missing Semantics** — admin_dashboard_screen.dart:330-331 — A11y — Tooltip/Semantics per icon.
- **[P2] Distribution bar inaccessible** — :491-514 — A11y — Semantics(label: mix %s).
- **[P2] Color(0xFF4A90D9) duplicates AppColors.info** — :167 — Theming.
- **[P2] _StatsLoading width:240 overflow** — :601-605 — Responsive.
- **[P3] raw err.toString() in error card** — :209,634 — Anti-Pattern (note: overlaps flutter-patterns Klasa 2; kept because admin-visible not guest).
- **[P3] redundant adminDarkModeProvider watch** — :19-21,235-237 — Perf.
- **[P3] analytics cards width:280 tablet orphan** — :159-201 — Responsive.

### booking_widget_screen — 13/20
| Dim | Score | Key finding |
|---|---|---|
| A11y | 2/4 | #999999 tertiary text 2.85:1 (fails AA) — guest-facing; backdrop dismiss no Semantics |
| Perf | 3/4 | _heightReporter.send() in build() |
| Theming | 3/4 | raw hex in owner-gate banner; fontFamily:'Manrope' literal; Colors.black backdrop |
| Responsive | 2/4 | forceMonthView bp 1024 (canonical 1200); pill bar fixed 350 overflows 320 |
| Anti-Patterns | 3/4 | confirm button onPressed:(){} while processing → double-submit; confirm btn duplicated ~60 lines |

- **[P1] textTertiary #999999 contrast fail** — minimalist_colors.dart:35 — A11y — 2.85:1 on white; guest-facing. Bump to #767676.
- **[P1] forceMonthView bp off-canonical** — booking_widget_screen.dart:641 (also 654,746,841) — Responsive — align to 1200.
- **[P1] min-nights SnackBar bypasses SnackBarHelper** — :945-963 — A11y/Theming — raw showSnackBar, raw error color.
- **[P2] Backdrop dismiss no Semantics** — :1033-1044 — A11y.
- **[P2] inline hex in owner-gate banner** — :833-837 — Theming.
- **[P2] pill bar fixed 350 vs 320 mobile** — booking_widget_screen_form_ui.dart:205 — Responsive.
- **[P2] confirm button duplicated verbatim** — form_ui.dart:659-718 vs 862-917 — Anti-Pattern.
- **[P3] fontFamily:'Manrope' literal** — :724 — Theming.
- **[P3] _heightReporter.send() in build()** — :577 — Perf.

### month_calendar_screen — 10/20  (LOWEST so far)
| Dim | Score | Key finding |
|---|---|---|
| A11y | 1/4 | weekend date #FFB84D on white ≈1.7:1; status cells zero Semantics; FAB no label |
| Perf | 2/4 | unitNameMap/conflict/flatten rebuilt each build(); _selectedUnitId mutated bare in build(); 6× MediaQuery/frame |
| Theming | 3/4 | legend statusPending #B7791F on tint ≈3.6:1 fails AA |
| Responsive | 2/4 | portrait lock breaks tablet landscape; no tablet body layout |
| Anti-Patterns | 2/4 | header/switch = 4th in-file copy (comment admits); 14 HR strings; raw error text |

- **[P1] Weekend date text fails AA** — month_calendar_screen.dart:638-641 — A11y — ≈1.7:1.
- **[P1] FAB no accessibility label** — :1761-1823 — A11y.
- **[P2] legend statusPending text fails AA** — :1699-1727 — A11y/Theming.
- **[P2] state mutation inside build()** — :221-225 — Anti-Pattern/Perf — _selectedUnitId set bare.
- **[P2] portrait-only lock breaks tablet landscape** — :100 — Responsive.
- **[P2] status-dot cells zero Semantics** — :663-722 — A11y.
- **[P3] 14 HR strings** — :820-842,912,946-947 — Anti-Pattern.
- **[P3] raw error string in error state** — :209 — Anti-Pattern.
- **[P3] header/switch 4th in-file copy** — :1341 — Anti-Pattern.
- **[P3] 6× MediaQuery/frame** — multiple — Perf.

### owner_timeline_calendar_screen — 12/20
| Dim | Score | Key finding |
|---|---|---|
| A11y | 2/4 | FAB zero Semantics; unit-name InkWell no label; date-header cells no Semantics |
| Perf | 2/4 | double setState via addPostFrameCallback on toggle; ref.listen in build() |
| Theming | 3/4 | Colors.red.shade700 conflict indicator; Colors.white snackbar action |
| Responsive | 3/4 | _kBadgeDot 7.0 sub-min; FAB itself 56×56 OK |
| Anti-Patterns | 2/4 | (state as dynamic).scrollToConflict cast; _hrMonths/_hrDays bypass l10n; double empty setState |

- **[P1] ref.listen inside build()** — owner_timeline_calendar_screen.dart:246 — Perf.
- **[P1] double setState on summary toggle** — :410-423 — Perf — remove addPostFrameCallback block.
- **[P2] FAB missing Semantics** — :853-916 — A11y.
- **[P2] unit-name InkWell no label** — timeline_unit_name_cell.dart:40 — A11y.
- **[P2] date-header cells no Semantics** — timeline_date_header.dart:95-206 — A11y.
- **[P2] Colors.red.shade700 conflict indicator** — timeline_booking_block.dart:228 — Theming.
- **[P2] Colors.white snackbar action** — :646 — Theming.
- **[P2] _hrMonths/_hrDays bypass l10n** — :1040-1053; timeline_date_header.dart:113-121 — Anti-Pattern.
- **[P3] (state as dynamic).scrollToConflict cast** — :617 — Anti-Pattern.
- **[P3] try/catch around AppLocalizations in build()** — :305-309 — Anti-Pattern.

---
## Batch 2 — dev-tooling + admin shell/login/log + splash (2026-07-18)

### gallery_screen (DEV-ONLY) — 16/20
- **[P2] ThemeData rebuilt every frame** — gallery_screen.dart:38 — Perf — cache light/dark themes.
- **[P2] BBResponsive read but unused for layout** — :47 — Responsive — reference gallery doesn't demo adaptation.
- **[P3] text-color tokens missing from palette** — :140-160 — Theming.
- **[P3] _DialogTriggers missing key/const** — :533-586 — Anti-Pattern.
- **[P3] SizedBox(width:240) hard-coded cards** — :410-443 — Responsive.

### responsive_probe_screen (DEV-ONLY) — 14/20
- **[P2] breakpoints stale 1024/1440 ladder** — responsive_probe_screen.dart:193-195 + tokens.dart:701-707 — Responsive — BBBreakpoint.tablet=1024/desktop=1440 disagree with canonical desktop≥1200 (#766/#769); the probe TEACHES the wrong boundary. SYSTEMIC.
- **[P2] ThemeData.dark()/light() not project BbTheme** — :37-39 — Theming.
- **[P3] Colors.white active pill** — :179 — Theming.
- **[P3] raw TextStyle(fontSize:12) ignores textScaler** — :403 — A11y/Theming.
- **[P3] raw Material palette slot colors** — :264-277 — Anti-Pattern.

### owner_splash_screen — 13/20
- **[P2] hardcoded bg hex 0xFF000000/0xFFFAFAFA** — owner_splash_screen.dart:231-232,379-381 — Theming.
- **[P2] silent try/catch around Theme.of** — :371-377 — Anti-Pattern.
- **[P2] no Semantics/liveRegion on splash** — :237-243,388-398 — A11y.
- **[P3] complete() animates via Future.delayed loop not vsync** — :69-75 — Perf.
- **[P3] fixed 200px progress bar** — bookbed_branded_loader.dart:22 — Responsive.
- **[P3] Material+Scaffold double-wrap in overlay** — :386-397 — Anti-Pattern.

### activity_log_screen — 10/20  (admin)
- **[P1] no-pagination provider hardcaps 50 rows** — admin_users_repository.dart:441 getActivityLog limit:50 — Perf/A11y — admin investigating incident never sees past row 50; no load-more/cursor. Add paginated notifier.
- **[P2] raw $err in error widget** — activity_log_screen.dart:124 — Anti-Pattern (admin-visible).
- **[P2] event card zero Semantics** — :167-247 — A11y.
- **[P2] AppColors.primary/warning/info on dark surface w/o dark-lift** — :257,263,269 — Theming.
- **[P2] Colors.white FilledButton fg** — :66 — Theming.
- **[P3] off-token radius/padding 10** — :173,176 — Theming.
- **[P3] fontSize:11 ×3 off-token** — :219,230,242 — Theming.
- **[P3] maxWidth:1000 magic literal** — :106 — Responsive.
- **[P3] double BbAdminDarkTokens.of lookup** — :148,275 — Anti-Pattern.
- **[P3] Map<String,dynamic> event untyped into widget** — :142 — Anti-Pattern.
- **[P3] timestamp no toLocal()** — :163-164 — A11y (UTC shown to admin).

### admin_login_screen — 14/20
- **[P2] _AdminCheck missing isCheckbox:true** — admin_login_screen.dart:656 — A11y.
- **[P2] "Forgot password?" tap target 36px** — :619-620 — A11y.
- **[P2] password toggle tooltip = "Password" not show/hide** — :898 — A11y.
- **[P3] emailCtrl never disposed** — :163 — Anti-Pattern (KNOWN, confirmed).
- **[P3] bg CustomPaint/ShaderMask no RepaintBoundary** — :999-1014,822 — Perf.
- **[P3] DateTime.now().year in build()** — :975 — Perf.
- **[P3] AlertDialog not BbDialog** — :197 — Theming.
- **[P3] splashRadius deprecated** — :897 — Anti-Pattern.
- **[P3] 3.14159265 literal not dart:math pi** — :849-850 — Anti-Pattern.
- **[P3] _AdminPill raw 6 not BBRadius.xs** — :572 — Theming.

### admin_shell_screen — 14/20
- **[P1] nav items no Semantics role/selected** — admin_shell_screen.dart:237-246,463-476 — A11y — one fix (_DrawerItem+_RailItem) covers all surfaces.
- **[P1] "Sign Out" text InkWell ~14px tap target** — :538-554 — A11y/Responsive.
- **[P2] ThemeData rebuilt every build** — :107-136 — Perf.
- **[P2] BBColor.success/warning no dark variant in env pill** — :853 — Theming.
- **[P2] admin breakpoints 800/1100 diverge from canonical 600/1200** — :19-20 — Responsive. SYSTEMIC.
- **[P2] rail avatar sign-out no Semantics label** — :262-286 — A11y.
- **[P2] const TextStyle(color:Colors.white) ×2** — :277-281,517-521 — Theming.
- **[P3] MAIN MENU letterSpacing:1.2 literal** — :455-460 — Theming.
- **[P3] _DrawerItem height exactly 44px** — :637-638 — Responsive.
