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

---
## Batch 3 — admin detail/list + auth (2026-07-18)

### user_detail_screen — 12/20  (admin)
- **[P1] BbAdminDarkTokens.textTertiary fails AA** — bb_redesign_tokens.dart:348 — Theming/A11y — 0x66FFFFFF on panelBg #2A2342 ≈3.95:1; #950 fixed owner surface, NOT admin. SYSTEMIC (any screen using palette.textTertiary).
- **[P2] copy button ~14px tap target** — user_detail_screen.dart:591-613 — A11y.
- **[P2] stale breakpoint _mobileBreakpoint=900** — :17,112 — Responsive.
- **[P2] _isLoading=false without setState/mounted in success paths** — :316,354,383,412 — Anti-Pattern.
- **[P2] 9 raw 16/24 spacing literals** — :134-199 — Theming.
- **[P2] AppColors.info/warning/success no dark-lift** — :658,671,744-748 — Theming.
- **[P3] sub-card providers no skeleton** — :632-675 — Perf.
- **[P3] date raw interpolation no zero-pad** — :534 — Anti-Pattern.
- **[P3] _ErrorState raw err.toString (has _sanitizeError)** — :217 — Anti-Pattern.

### users_list_screen — 14/20  (admin)
- **[P2] mobile card no semanticLabel** — users_list_screen.dart:666-668 — A11y.
- **[P2] SelectableText in DataCell blocks row onSelectChanged** — :826-843 — A11y/Anti-Pattern — name/email cell taps dead.
- **[P2] _pickDateRange hardcodes ThemeData.light** — :252-256 — Theming — light picker in dark console.
- **[P2] _filterAndSortOwners O(N) sort+filter every keystroke in build()** — :169-226,490 — Perf.
- **[P3] _AccountTypeBadge raw TextStyle/off-grid** — :1102-1109 — Theming.
- **[P3] _PageButton BorderRadius.circular(8) off-token** — :1051,1059 — Theming.
- **[P3] _formatDate locale-unaware, duplicated** — :723-726,902-905 — A11y.

### cookies_policy_screen — 16/20  (auth/legal, static)
- **[P1] FAB missing semanticLabel** — cookies_policy_screen.dart:156-164 — A11y.
- **[P2] ToC InkWell items no semantic role** — :431-456,492-507 — A11y.
- **[P2] BbSectionHeader emits no header semantics** — bb_section_header.dart:47-51 — A11y (affects all legal screens).
- **[P2] hardcoded eyebrow 'PRAVNO · KOLAČIĆI'** — :211,261 — A11y/Anti-Pattern.
- **[P3] Colors.white FAB icon** — :161 — Theming.
- **[P3] fontSize:13 ×2 sidebar** — :501,529 — Theming.
- **[P3] DateTime.now() in build (also wrong 'last updated')** — :95-97 — Perf.
- **[P3] textTertiaryLight #718096 3.56:1 on page bg** — :368,522 — A11y.

### email_verification_screen — 12/20  (auth)
- **[P2] unsandboxed BackdropFilter (no RepaintBoundary), re-composites each 1s tick** — email_verification_screen.dart:507-521 — Perf.
- **[P2] polling timer not cancelled on app pause** — :56-58,93-99 — Perf — 3s Auth RPC fires while backgrounded.
- **[P2] raw exception string to user** — :200 — Anti-Pattern.
- **[P2] AndroidKeyboardDismissFix mixin absent (screen has input dialogs)** — :42 — Anti-Pattern (keyboard-fix.md class).
- **[P3] mail disc + email chip no Semantics** — :549-564,586-601 — A11y.
- **[P3] cooldown countdown not liveRegion** — :656-665 — A11y.
- **[P3] BorderRadius.circular(18/20) off-token** — :555,591 — Theming.
- **[P3] no desktop-wide tier (campaign-level, all auth screens)** — :462,471-474 — Responsive.

### enhanced_login_screen — 11/20  (auth, LOWEST batch 3)
- **[P1] password toggle tap target 32×32 (<44)** — enhanced_login_screen.dart:613-614 — A11y.
- **[P1] no textInputAction chain (email→next→password→done→submit)** — :571-585,593-626 — A11y — check BbInput exposes param.
- **[P1] footer InkWell links no Semantics + tiny target** — :864-887 — A11y.
- **[P2] 4 raw TextStyle bypass BBType** — :797-801,819-824,913-917 — Theming.
- **[P2] pitch panel padding fromLTRB(80,64,80,64) collapses 1200-1400** — :786 — Responsive.
- **[P2] _PitchStat hero-metrics anti-pattern + hardcoded '45+'/'12k'/'99.9%'** — :840-844 — Anti-Pattern.
- **[P2] BackdropFilter no RepaintBoundary** — :475 — Perf (glassmorphism is documented intentional hero exception).
- **[P3] isCompactMobile uses stale Breakpoints.desktop=1024** — :348 + breakpoints.dart:32 — Responsive. SYSTEMIC.

### enhanced_register_screen — 12/20  (auth)
- **[P1] password field error EN-only (wrong validator overload)** — enhanced_register_screen.dart:564 — Anti-Pattern/A11y — use minimumLengthError + l10n.passwordErrorText (class #943).
- **[P1] both legal checkboxes pass identical l10n.authAcceptTerms prefix** — :624,639 — Anti-Pattern — likely copy-paste; SR reads both identically.
- **[P2] checkbox tap target 22×22 + shrinkWrap, label not tappable** — :709-712,720 — A11y.
- **[P2] ProfileImagePicker DIAGONAL GRADIENT violates flat-chrome rule + raw colorScheme** — profile_image_picker.dart:119-126,232-239 — Theming — retired 2026-06-16 (flat-chrome-decision). FLAG.
- **[P2] ProfileImagePicker edit button no Semantics/tooltip** — :221-265 — A11y.
- **[P2] hardcoded EN loader 'Creating your account...'** — :363 — Theming/A11y.
- **[P3] RichText legal link not keyboard/switch focusable** — :676-695 — A11y.
- **[P3] _RegisterPitchPanel hardcoded HR copy** — :755-815 — Anti-Pattern.

---
## Batch 4 — auth forgot/legal + owner about/bank/password (2026-07-18)

### forgot_password_screen — 13/20  (auth)
- **[P1] glassmorphism BackdropFilter blur** — forgot_password_screen.dart:203-204 — Anti-Pattern — GPU layer, contradicts flat direction.
- **[P2] validateEmail EN-only strings** — profile_validators.dart:30,37 — A11y/Theming — inline field error always EN (screen has l10n). SYSTEMIC validator class.
- **[P2] no textInputAction/onFieldSubmitted** — :257-267 — A11y. SYSTEMIC (BbInput param gap).
- **[P2] double error feedback (snackbar + inline)** — :74-76 — Anti-Pattern.
- **[P3] raw literal 36 card padding** — :199 — Theming.

### privacy_policy_screen — 16/20  (auth/legal)
- **[P1] FAB missing semanticLabel** — privacy_policy_screen.dart:169-177 — A11y (legal-cluster class).
- **[P1] textTertiary #718096 fails AA (3.56:1 shellBg / 4.02:1 white)** — :400,552 — A11y — lastUpdated stamp is normal-weight body. SYSTEMIC light-mode contrast.
- **[P2] ToC InkWell no mouseCursor + no button semantics** — :463-488,524-539 — A11y.
- **[P2] lastUpdated = DateTime.now().year (dynamic, semantically wrong)** — :108-110 — Anti-Pattern.
- **[P3] Colors.white FAB icon** — :173 — Theming.
- **[P3] BbSectionHeader no header:true** — :427,461 — A11y (KNOWN systemic).

### terms_conditions_screen — 15/20  (auth/legal)
- **[P2] FAB missing tooltip/semantics** — terms_conditions_screen.dart:161-169 — A11y.
- **[P2] ToC InkWell tap targets <44px (24-30px)** — :447-448,510 — A11y/Responsive.
- **[P2] heading hierarchy skips h2 (h1→h3)** — :371,406 — A11y.
- **[P3] Colors.white FAB icon** — :166 — Theming.
- **[P3] mixed token namespace (rd.shellBg vs BBColor)** — :84,106 — Theming.
- **[P3] DateTime.now().year in build** — :101 — Perf.
- **[P3] fontSize:13 inline ×2** — :515-516,542-543 — Theming.

### about_screen — 15/20  (owner)
- **[P2] hardcoded eyebrow 'INFO · APLIKACIJA'** — about_screen.dart:124 — A11y/Theming.
- **[P2] wrong desktop breakpoint >=1024** — :35 — Responsive. SYSTEMIC.
- **[P2] _ContactRow not tappable as whole row (only tiny icon-btn)** — :433-465 — A11y/UX.
- **[P3] no heading semantics** — :234,292,388 — A11y.
- **[P3] decorative BbIcon not ExcludeSemantics** — :337,435 — A11y (BbIcon widget-level).
- **[P3] panel radius 28 off-token** — :59 — Theming.
- **[P3] fontSize:12 override vs BBType.caption** — :533 — Theming.

### bank_account_screen — 13/20  (owner)
- **[P2] wrong desktop breakpoint >=1024** — bank_account_screen.dart:489 — Responsive. SYSTEMIC.
- **[P2] no textInputAction/focus chain on 4 fields** — :333-371 — A11y/Anti-Pattern. SYSTEMIC (BbInput).
- **[P3] validateIban/validateSwift EN-only** — profile_validators.dart:181,187,204,210 — A11y. SYSTEMIC validator.
- **[P3] fontSize:13 override BBType.mono** — :254 — Theming.
- **[P3] panel radius 28 off-token** — :535 — Theming.
- **[P3] icon container no Semantics** — :220-232 — A11y.
- **[P3] _loadData called every build** — :485 — Perf.
- **[P3] error state raw $error to UI** — :590 — Anti-Pattern.
- **[P4] redundant autovalidateMode Form+fields** — :341,352,549 — Anti-Pattern.

### change_password_screen — 14/20  (owner)
- **[P1] no textInputAction chain (3 password fields)** — change_password_screen.dart:350,388,449 — A11y. SYSTEMIC (BbInput).
- **[P2] strength meter no liveRegion** — :431-445,578-647 — A11y — Weak→Strong not announced.
- **[P2] missing autofillHints on all 3 password fields** — :350-484 — A11y. SYSTEMIC (BbInput no autofillHints + no AutofillGroup).
- **[P2] withAlpha((0.1*255).toInt()) truncates not rounds** — :615 — Theming (memory withalpha-toint-vs-withvalues; line 293 same file does it right).
- **[P2] visibility toggle 18px — verify BbInput trailing ink ≥48px** — :364,401,462 — A11y.
- **[P3] hardcoded 4/6 radii strength meter** — :602,616 — Theming.
- **[P3] maxWidth:680 raw literal** — :260 — Responsive.
