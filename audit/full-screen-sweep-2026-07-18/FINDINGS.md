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
