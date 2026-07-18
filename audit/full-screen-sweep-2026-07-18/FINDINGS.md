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

---
## Batch 5 — owner edit-profile + AI + guides + iCal export (2026-07-18)

### edit_profile_screen — 13/20  (owner)
- **[P1] EN-only validator strings ×9** — profile_validators.dart:9-104 — A11y. SYSTEMIC validator.
- **[P2] no textInputAction chain (17+ fields)** — edit_profile_screen.dart:372-420 — A11y. SYSTEMIC (BbInput).
- **[P2] error.toString() to user** — :831 — A11y/Anti-Pattern.
- **[P2] BbAvatarUpload semanticLabel fallback EN** — bb_avatar_upload.dart:324 — A11y.
- **[P3] double setState in onImageSelected (_markDirty nested)** — :780-785 — Anti-Pattern.
- **[P3] pageBackground gradient wrapper redundant** — :693,696 — Theming.
- **[CLEAN] keyboard-fix mixin present; uses BbAvatarUpload NOT ProfileImagePicker (no gradient violation here); all 17 controllers disposed.**

### ai_assistant_screen — 14/20  (owner)
- **[P1] send button no tooltip/semantics** — ai_assistant_screen.dart:1222 — A11y.
- **[P1] hero Image.asset not excludeFromSemantics** — :1300 — A11y.
- **[P2] ref.read(aiChatNotifierProvider) in item builder (stale selection)** — :593 — Anti-Pattern.
- **[P2] hardcoded HR subtitle in header default params** — ai_assistant_premium_header.dart:65,111 — Theming/l10n.
- **[P2] _kOnPrimary=Colors.white/white70 raw** — :44-45 — Theming (BBColorSet.onPrimary token gap). SYSTEMIC.
- **[P2] Opacity+Container in typing dots forces compositing ×3 @60fps** — :1370 — Perf.
- **[P2] AndroidKeyboardDismissFix mixin absent (composer TextField)** — :72 — A11y/Platform.
- **[P2] no RepaintBoundary around MarkdownBody bubbles** — :797 — Perf.
- **[P3] Dismissible no semanticsLabel** — :597 — A11y.
- **[CLEAN] BBMotion.reduced respected; onTapLink http/https allowlist; error codes localized.**

### embed_help_screen — 16/20  (owner/guide)
- **[P1] copy button no tooltip** — embed_help_screen.dart:552-560 — A11y.
- **[P2] test-link InkWell no semantic label** — :304-342 — A11y.
- **[P2] breakpoint 1024 vs canonical 1200** — :78 — Responsive. SYSTEMIC.
- **[P2] fontSize:12 override BBType.mono** — :568 — Theming.
- **[P3] raw px literals 4/4/6/26** — :308,598,634,636 — Theming.

### embed_widget_guide_screen — 13/20  (owner/guide)
- **[P1] copy InkWell no semantic label** — embed_widget_guide_screen.dart:654,829 — A11y.
- **[P1] close IconButton constrained 28×28** — :617-621,785-791 — A11y (<44px).
- **[P2] raw $error to UI** — :1375,1382 — Anti-Pattern.
- **[P2] Colors.grey.shade50 hardcoded (light branch)** — :1114,1235 — Theming.
- **[P2] Colors.white for on-primary** — :224,1067 — Theming. SYSTEMIC.
- **[P2] desktop breakpoint 700 vs 1200** — :270 — Responsive. SYSTEMIC.
- **[P2] BBColor.surfaceVarDark/Light static bypasses theme extension** — :554,857,1425,1589 — Theming.
- **[P3] icon-in-tinted-circle repeated 8+ times, no hierarchy** — Anti-Pattern.

### faq_screen — 14/20  (owner/guide)
- **[P1] BbChip no Semantics(selected:)** — bb_chip.dart:58-136 — A11y — affects ALL BbChip consumers. SYSTEMIC widget.
- **[P2] _ClearSearchButton tap target ~26px** — faq_screen.dart:623-631 — A11y (InkResponse radius ≠ hit area).
- **[P2] hardcoded HR strings in _FaqPremiumHeader** — :308-311 — Theming/l10n. SYSTEMIC (premium headers).
- **[P2] Colors.white expanded icon** — :532 — Theming.
- **[P3] MediaQuery.sizeOf vs LayoutBuilder box width** — :580 — Responsive.
- **[P3] _getAllFAQs 24-item list rebuilt each build** — :64,232,269 — Perf.
- **[CLEAN] no ❓ emoji prefix (unlike owner_bookings FAQ); ExpansionTile native SR state.**

### ical_export_list_screen — 13/20  (owner)
- **[P1] desktop breakpoint >900 vs canonical 1200** — ical_export_list_screen.dart:638 — Responsive. SYSTEMIC.
- **[P2] eager .map().toList() Column not ListView.builder (unbounded units)** — :987-991 — Perf.
- **[P2] hardcoded HR strings IcalExportPremiumHeader** — ical_export_premium_header.dart:29,35,43,48 — Anti-Pattern/l10n. SYSTEMIC.
- **[P2] Colors.white on primary ×4** — :354,359,367,1144 — Theming. SYSTEMIC.
- **[P2] download tooltip/semanticLabel hardcoded EN 'Download'** — :1055,1059 — A11y.
- **[P2] decorative watermark BbIcon no ExcludeSemantics** — :755-761 — A11y.
- **[P3] dynamic unit/property untyped** — :50,72,171,998 — Anti-Pattern.
- **[P3] _loadUnits one-shot .future (stale on unit add/remove)** — :135-136 — Perf.

---
## Batch 6 — owner iCal-sync/notif/profile/property-form/stripe (2026-07-18)

### ical_sync_settings_screen — 12/20  (owner)
- **[P1] stale desktop breakpoint >900** — ical_sync_settings_screen.dart:117 — Responsive. SYSTEMIC.
- **[P1] hardcoded HR status labels (Aktivan/Pauziran/Greška)** — :662-664 — A11y/Theming.
- **[P1] BBColor.success STATIC (misses dark mode)** — :1623 — Theming.
- **[P1] status conveyed by color-only 8px dot (WCAG 1.4.1)** — :535-542 — A11y.
- **[P2] platform InkWell no semantic role** — :758-795 — A11y.
- **[P2] IntrinsicHeight desktop 2-col row** — :218-227 — Perf.
- **[P2] mismatch-banner tone/color mismatch (error accent + warning icon)** — :1370-1386 — Anti-Pattern.
- **[P2] URL BbInput no textInputAction** — :1200-1218 — A11y. SYSTEMIC (BbInput).

### notification_settings_screen — 15/20  (owner)
- **[P2] _QuietTimeField tap target ~36px** — notification_settings_screen.dart:581-605 — A11y.
- **[P2] eyebrow color override breaks BBType.eyebrow AA ink (4.02:1 @10px)** — :388-390 — A11y/Theming.
- **[P2] textTertiaryLight #718096 on white BbCard fails AA ×3** — :370,538,578 — A11y — #951 fixed dark, light still fails on surface=#FFFFFF. SYSTEMIC.
- **[P2] BbSectionHeader no header semantics** — :329-332,423-426 — A11y.
- **[P2] showTimePicker no helpText (EN default all locales)** — :221 — A11y.
- **[P3] category key 'payments' leaks into snackbar** — :140 — A11y.
- **[P3] _currentPreferences ??= in build()** — :253-257 — Anti-Pattern.

### notifications_screen — 15/20  (owner)
- **[P2] unread dot no ExcludeSemantics** — notifications_screen.dart:965-974 — A11y.
- **[P2] title duplicated in semantic tree (BbCard.semanticLabel + Text) → read twice** — :908,941-950 — A11y.
- **[P2] getUnreadCount streams full docs not AggregateQuery** — notification_service.dart:91-98 — Perf (latent, PROD max 83).
- **[P2] hardcoded HR date-group keys in provider** — notifications_provider.dart:61-157 — A11y (provider has no context).
- **[P2] Colors.black scrim off-token** — :362 — Theming.
- **[P2] Colors.white FAB/AppBar ×2** — :388,409 — Theming. SYSTEMIC (onPrimary gap).
- **[P3] Dismissible no a11y delete alternative (WCAG 2.5.1)** — :498-564 — A11y.
- **[P3] FAB overlaps last row (no bottom pad)** — :384-393 — Responsive.

### profile_screen — 12/20  (owner)
- **[P1] rd.heroGradient on structural chrome ×4 (avatar halo/accent strip/radial gauge/Pro icon)** — profile_screen.dart:648,800,992,1113 — Theming — FLAT-CHROME VIOLATION #2. FLAG.
- **[P2] _VerifyChip/identity badges no semantic role** — :854-888,686-709 — A11y.
- **[P2] _RadialGaugePainter.shouldRepaint always true (gradient identity)** — :1056-1060 — Perf.
- **[P2] _ProfilStatStrip hardcoded HR strings ×5 (kDebugMode-gated fake metrics)** — :1432-1455 — Anti-Pattern.
- **[P2] Colors.white filled button fg + Pro icon** — :946,1121 — Theming. SYSTEMIC.
- **[P2] support email dusko@book-bed.com hardcoded in widget** — :391 — Anti-Pattern.
- **[P3] PremiumListTile dense+VisualDensity → ~40px tap target** — premium_list_tile.dart:64-65 — A11y.
- **[P3] EN-only snackbar 'Could not open email client'** — :399 — A11y.

### property_form_screen — 13/20  (owner)
- **[P1] no textInputAction chain (6 fields)** — property_form_screen.dart — A11y. SYSTEMIC (BbInput).
- **[P1] loading overlay blocks SR, no ExcludeSemantics/liveRegion** — :597-641 — A11y.
- **[P2] suggestion InkWell chip ~28px tap target** — :841-865 — A11y.
- **[P2] loading overlay raw Card(elevation:8) violates flat-chrome** — :600-641 — Theming/Anti-Pattern.
- **[P2] ZERO BB* token usage (uses old AppDimensions + raw radii/fontSize)** — file-wide — Theming. NOTABLE.
- **[P2] stale gradient comments (flat since 7.23)** — :277,682 — Anti-Pattern.
- **[P2] hardcoded EN Exception('Subdomain not available')** — :969 — Anti-Pattern.
- **[CLEAN] keyboard-fix mixin present; subdomain debounce+dispose clean.**

### stripe_connect_setup_screen — 10/20  (owner, BATCH LOW)
- **[P1] 3× identical EN-only timeout snackbar (fix-one-miss-two)** — stripe_connect_setup_screen.dart:87,154,242 — A11y/Anti-Pattern.
- **[P2] isDesktop=900 vs 1200 + two measurement sources (LayoutBuilder vs MediaQuery)** — :289,971 — Responsive. SYSTEMIC.
- **[P2] step accordion InkWell no semantic label** — :674 — A11y.
- **[P2] FAQ toggle InkWell no semantic label** — :758 — A11y.
- **[P2] step CircleAvatar visual 32px** — :684-685 — A11y.
- **[P3] raw BorderRadius.circular(16/12/8) off-token** — :423,438,486,594,760 — Theming.
- **[P3] 5 raw TextStyle bypass BBType + fontFamily:'monospace' literal** — :461-502,694,815,871 — Theming.
- **[P3] AppShadows.elevation3 not BBShadow** — :424 — Theming.
- **[P3] ❓ emoji FAQ not ExcludeSemantics** — :815 — A11y.
- **[P3] _StripePayoutsDashboard hardcoded HR labels (kDebugMode-gated)** — :1013-1260 — Anti-Pattern.

---
## Batch 7 — owner unit hub/form/pricing/wizard + widget settings (FROZEN cluster) (2026-07-18)

### unified_unit_hub_screen — 14/20  (owner; hosts FROZEN Cjenovnik)
- **[P2] sub-48dp tap targets unit duplicate/delete + PropertyTreeHeader (26/28px)** — unified_unit_hub_master_panel.dart:709-742,983-1020 — A11y.
- **[P3] hardcoded HR error string** — master_panel:153 — Anti-Pattern.
- **[P3] hardcoded HR KPI labels + _hrMonths** — units_premium_header.dart:55,87-108 — Theming/l10n. SYSTEMIC (premium header).
- **[P3] _kTabletBreakpoint=800 dead-zone 600-799** — unified_unit_hub_screen.dart:51 — Responsive. SYSTEMIC.
- **[P3] double sort per itemBuilder frame** — master_panel:301-324 — Perf.
- **[P3] MediaQuery.of(.size) not sizeOf ×2** — osnovno:14, screen:342 — Perf.

### unit_form_screen — 11/20  (owner, 3×P1)
- **[P1] area double.parse crash on empty optional field (no validator)** — unit_form_screen.dart:889,914 — Anti-Pattern — use tryParse ?? null. REAL BUG.
- **[P1] amenities never restored on edit → silent wipe on save** — :69-85 — Anti-Pattern. REAL BUG.
- **[P1] image delete buttons 24×24 (<48)** — :779-785,830-836 — A11y.
- **[P2] image delete no semantic label** — :774-836 — A11y.
- **[P2] no textInputAction chain (9 fields)** — :170-368 — A11y. SYSTEMIC (BbInput).
- **[P2] loading overlay off-token raw Card/TextStyle/Colors.black** — :491-536 — Theming.
- **[P2] stale "TIP-1 diagonal gradient" docstring** — :548-550 — Theming/doc. SYSTEMIC doc-rot.
- **[P2] image upload silently no-ops (TODO stub) → data loss on new images** — :867-870 — Anti-Pattern. REAL.
- **[P3] maxHeight uses kMaxUploadWidth (1920) not kMaxUploadHeight** — :845 — Anti-Pattern.
- **[P3] double ClipRRect nesting per image card** — :744-769 — Perf.

### unit_pricing_screen — 11/20  (owner; grid FROZEN)
- **[P1] no textInputAction on price fields ×3** — unit_pricing_screen.dart:659; price_list_calendar_widget.dart:1041,1554 — A11y.
- **[P1] CalendarDayCell no Semantics wrapper** — calendar_day_cell.dart:80-123 — A11y (additive wrapper OK around [FROZEN] grid).
- **[P2] day cell tap target <48dp small-mobile** — calendar_day_cell.dart:105 — A11y [FROZEN].
- **[P2] GradientTokens.brandPrimary on Save button** — unit_pricing_screen.dart:679 — Theming — FLAT-CHROME VIOLATION #3. FLAG.
- **[P2] Colors.white ×6 on button** — :701,710,718 — Theming. SYSTEMIC.
- **[P2] "base" label EN-only** — calendar_day_cell.dart:217 — A11y/l10n [FROZEN].
- **[P2] raw hex disabled-state colors** — price_list_calendar_widget.dart:511-512 — Theming.
- **[P3] _hasScheduledAutoSelect flag races** — :98-107 — Anti-Pattern.
- **[P3] _showPriceEditDialog 580 LOC inline** — price_list_calendar_widget.dart:870-1453 — Anti-Pattern [FROZEN-adjacent, GO only].

### unit_wizard_screen — 13/20  (owner; publish FROZEN)
- **[P1] step indicators no Semantics (label/state/role)** — wizard_progress_bar.dart:186-209 — A11y.
- **[P1] no progress announcement on step change** — unit_wizard_screen.dart:422-440 — A11y (SemanticsService.announce).
- **[P2] no textInputAction on numeric fields** — step_2_capacity.dart:726-815, step_3_pricing.dart:201-534 — A11y.
- **[P2] step4 breakpoint 900 vs 1200** — step_4_review.dart:24 — Responsive. SYSTEMIC.
- **[P2] _buildSummaryCard bypasses BbCard, raw shadow tokens** — step_4_review.dart:355-431 — Theming.
- **[P2] Colors.white step node icon** — wizard_progress_bar.dart:166,172,205 — Theming.
- **[P2] _buildServicesCard new Future every rebuild** — step_4_review.dart:321 — Perf.
- **[P2] stale "TIP-1 DIJAGONALNI GRADIENT" comment** — step_4_review.dart:381 — Anti-Pattern/doc. SYSTEMIC doc-rot.
- **[P2] AlertDialog not BbDialog (step 2)** — step_2_capacity.dart:196-211 — Anti-Pattern.
- **[P3] 5× duplicated card-header pattern** — steps 1-4 — Anti-Pattern.

### widget_advanced_settings_screen — 12/20  (owner)
- **[P1] ExpansionTile stays open after disable (initiallyExpanded one-shot)** — tax_legal_disclaimer_card.dart:65-66 — Anti-Pattern.
- **[P2] raw exception string to owner** — widget_advanced_settings_screen.dart:457 — Anti-Pattern.
- **[P2] both helper cards ZERO BB tokens** — email_verification_card.dart, tax_legal_disclaimer_card.dart — Theming. NOTABLE.
- **[P2] OutlinedButton.icon bypasses BbButton** — tax_legal_disclaimer_card.dart:172-179 — Theming.
- **[P2] Switch rows no Semantics/MergeSemantics** — email_verification_card.dart:68-103; tax_legal:120-155 — A11y.
- **[P2] no desktop content-width cap on ListView** — :314-375 — Responsive.
- **[P3] idle LayoutBuilder reads no constraints (dead)** — :424-429 — Perf.

### widget_settings_screen — 11/20  (owner)
- **[P1] accent swatches no Semantics (32px GestureDetector)** — widget_appearance_section.dart:234-256 — A11y.
- **[P1] slider value no semanticFormatterCallback** — widget_settings_payment_sections.dart:321-329; behavior:114-127 — A11y.
- **[P1] isDesktop=600 vs canonical 1200** — widget_settings_behavior_sections.dart:24 — Responsive. SYSTEMIC.
- **[P2] part files ZERO BBType/BBSpace (26 font + 25 spacing literals)** — payment_sections + behavior_sections — Theming. NOTABLE (verbatim-split preserved pre-token style).
- **[P2] Colors.black raw shadow** — behavior_sections:366-367 — Theming.
- **[P2] whenData + addPostFrameCallback in build (double-build)** — widget_settings_screen.dart:376-385 — Perf.
- **[P2] twin switch-card methods (copy-paste)** — payment:575-638, behavior:278-348 — Anti-Pattern.
- **[P3] unused LayoutBuilder** — screen:524 — Perf.
- **[P3] stale "diagonal gradient" docstring** — widget_settings_section.dart:9-13 — doc. SYSTEMIC doc-rot.

---
## Batch 8 — subscription + widget guest screens + 404 (2026-07-18) — SCREENS COMPLETE (48/48)

### subscription_screen — 11/20  (owner)
- **[P1] dead "Usporedi sve značajke" link (TextSpan, no recognizer)** — subscription_screen.dart:992 — A11y/Anti-Pattern.
- **[P2] billing toggle no selected-state semantics** — :548-603 — A11y.
- **[P2] _TogglePill tap target ~32px** — :556 — A11y.
- **[P2] "Zadrži besplatno" no-op onPressed:(){} + 36px** — :952 — Anti-Pattern.
- **[P2] stale breakpoint 720 vs 600** — :75 — Responsive. SYSTEMIC.
- **[P2] _FeatureRow icon not ExcludeSemantics** — :884-889 — A11y.
- **[P3] ~30 hardcoded HR strings + 4 hardcoded prices (no NumberFormat)** — many — Anti-Pattern.
- **NOTE:** rd.heroGradient on _TrialHero is INTENTIONAL hero (not a flat-chrome regression).

### booking_confirmation_screen — 12/20  (guest widget)
- **[P1] copy button non-interactive (Material+SizedBox 28×28, no onTap/semantics)** — booking_confirmation_screen.dart:542-559 — A11y/Anti-Pattern — dead affordance on primary post-booking data.
- **[P1] 28×28 copy affordance <44px** — :547-549 — Responsive.
- **[P1] resend InkWell tap ~22px @320** — email_confirmation_card.dart:229-271 — Responsive.
- **[P2] duplicate Semantics label icon+heading (read twice)** — confirmation_header.dart:224-251 — A11y.
- **[P2] CalendarExportButton legacy SpacingTokens/BorderTokens** — calendar_export_button.dart:115,130 — Theming.
- **[P2] Colors.black dark-bg hardcode ×3** — :295; booking_summary_card.dart:100; email_confirmation_card.dart:143 — Theming.
- **[P2] Curves.elasticOut bounce on success mark** — confirmation_header.dart:229 — Anti-Pattern (ui-ux.md).
- **[P2] computeLuminance() each build ×3 (should thread isDarkMode)** — Perf.

### booking_details_screen — 13/20  (guest widget)
- **[P1] ref.watch inside async _handleCancelBooking (StateError risk)** — booking_details_screen.dart:172 — Anti-Pattern.
- **[P1] success #10B981 as TEXT = 2.54:1 fails AA** — booking_status_banner.dart:51-57; payment_info_card.dart:120 — A11y/Theming — use emerald600. SYSTEMIC widget palette.
- **[P1] warning #F59E0B as TEXT = 2.15:1 fails AA** — booking_status_banner.dart:51-57 — A11y/Theming — use amber700. SYSTEMIC.
- **[P2] textTertiary #999999 2.85:1 (help text)** — :341 — A11y. SYSTEMIC.
- **[P2] status banner icon no merged Semantics** — booking_status_banner.dart:38 — A11y.
- **[P2] cancelText Colors.black/white hardcoded** — :617-618 — Theming.
- **[P2] flag emoji → letters on Windows Chrome** — :484,501-513 — A11y.
- **[P2] Tooltip on disabled cancel = desktop-only** — :624-660 — A11y.
- **[P3] CancellationPolicyCard parseOrThrow no try-catch (crash risk)** — cancellation_policy_card.dart:32 — Anti-Pattern.

### booking_view_screen — 13/20  (guest widget)
- **[P1] status banner color-only semantics** — booking_status_banner.dart:38 — A11y.
- **[P1] header Row overflows @320 (no Flexible on title)** — booking_details_screen.dart:382-446 — Responsive.
- **[P2] language IconButton no semanticsLabel (icon is Row)** — :415-445 — A11y.
- **[P2] _buildStateMark icon no ExcludeSemantics** — booking_view_screen.dart:440 — A11y.
- **[P2] Colors.black/white cancel text** — booking_details_screen.dart:617 — Theming.
- **[P2] raw BoxShadow Color(0x1A141E32)** — booking_view_screen.dart:434 — Theming.
- **[P3] dynamic _loadedBooking/_loadedWidgetSettings** — :74-75 — Anti-Pattern.
- **[P3] _safeErrorToString duplicated in 2 files** — Anti-Pattern.
- **[P3] hardcoded EN 'Navigation error:' to guests** — :220,265 — A11y.

### subdomain_not_found_screen — 16/20  (guest widget)
- **[P1] error icon disc 2.46:1 fails WCAG 1.4.11 (3:1 non-text)** — subdomain_not_found_screen.dart:64-73 — A11y — ExcludeSemantics or raise alpha. SYSTEMIC icon-disc pattern.
- **[P2] h1 no Semantics(header:true)** — :78-81 — A11y.
- **[P2] subdomain echo no maxLines/ellipsis (query-param bypasses slug cap)** — :105-111 — Responsive.
- **[P3] Colors.black not named const** — :41 — Theming.
- **[CLEAN] full BB* token discipline, l10n complete HR/DE/IT/EN, good test coverage.**

### not_found_screen — 14/20  (shared 404)
- **[P1] decorative icon no ExcludeSemantics** — not_found_screen.dart:22 — A11y.
- **[P1] '404'/heading no header role** — :24-30 — A11y.
- **[P2] Colors.grey[600] body text (~4.48:1)** — :44 — Theming/A11y.
- **[P2] Colors.grey[300] icon (invisible light)** — :22 — Theming.
- **[P2] raw AppBar not CommonAppBar** — :11-14 — Theming/Anti-Pattern.
- **[P2] Theme.of.primaryColor deprecated** — :28-29 — Anti-Pattern.
- **[P3] 5 hardcoded HR strings** — Anti-Pattern.

---
## COMPONENTS batch 1 — design-system primitives (bb_*) (2026-07-18) — ROOT-CAUSE layer

### bb_app_bar (PRIMITIVE) — 14/20
- **[P1] badge Colors.white on tertiary tone ~1.6:1 fails AA** — bb_app_bar.dart:236 — Theming.
- **[P1] breadcrumb tap targets ~2px padding** — :156-158 — A11y.
- **[P1] _RoundedIconBtn Semantics double-announce + no disabled state** — :193-196 — A11y — ROOT (every BbAppBar action).
- **[P2] preferredSize raw 56 not BBConstraint.appBarHeight** — :61,93 — Theming.
- **[P2] breadcrumb Row no overflow guard** — :172 — Responsive.
- **[P2] hamburger/back/notif labels hardcoded HR non-overridable** — :86,104,113 — A11y/l10n — ROOT.

### bb_avatar_slot (PRIMITIVE) — 14/20
- **[P1] InkWell no semantic label** — bb_avatar_slot.dart:65 — A11y.
- **[P1] placeholder textTertiary #718096 on #F5F5F5 = 3.68:1 fails AA** — :53-55 — A11y. SYSTEMIC contrast.
- **[P2] no ExcludeSemantics when decorative** — :45-58 — A11y.
- **[P2] ringColor default Color(0x40FFFFFF) hardcoded** — :18 — Theming.
- **[P2] NetworkImage no error/loading builder** — :37 — Perf/A11y.
- **[P3] id param stored but dead** — :13,22 — Anti-Pattern.

### bb_avatar_upload (PRIMITIVE) — 15/20
- **[P2] semanticLabel fallback hardcoded EN 'Change profile photo'** — bb_avatar_upload.dart:324 — A11y.
- **[P2] edit-button tap target 20/24px on xs/sm** — :128-129 — A11y/Responsive.
- **[P3] Color(0x33FFFFFF) ring + Colors.black 0.45 scrim raw** — :259,275 — Theming.
- **[P3] _diameter duplicates BbAvatar size table** — :110-122 — Anti-Pattern.
- **[CONFIRMED CLEAN] NO diagonal gradient (flat-chrome OK) — the violation is in profile_image_picker, NOT here.**

### bb_avatar (PRIMITIVE) — 15/20
- **[P1] no semantic label on identity widget (name never surfaced)** — bb_avatar.dart:72-118 — A11y.
- **[P2] Colors.white onGradient fg (no textOnGradient token)** — :56 — Theming. SYSTEMIC (onPrimary/onGradient gap).
- **[P2] ring BoxShadow Color(0x33FFFFFF) invisible light mode** — :113 — Theming.
- **[P2] Image.network no cacheWidth/Height (list of sm avatars)** — :98-105 — Perf.
- **[P3] _diameter switch could be const map** — :28-41 — Anti-Pattern.

### bb_bottom_sheet (PRIMITIVE) — 13/20
- **[P1] drag handle bare Container no semantics** — bb_bottom_sheet.dart:43-51 — A11y.
- **[P1] modal barrier no dismiss label (docstring omits barrierLabel)** — :6-8 — A11y — consider BbBottomSheet.show() factory.
- **[P2] no Semantics container role on sheet** — :28 — A11y.
- **[P2] no maxHeight guard (tall child overflows)** — :57-62 — Responsive.
- **[P2/P3] raw padding literals 10/4/12/8 + circular(999)** — :41,54,59,65,48 — Theming.

### bb_button (PRIMITIVE) — 15/20 — HIGH-VALUE ROOT
- **[P1] BbButtonSize.sm = 36px = ROOT of sub-48px systemic (35 call sites, 18 files)** — bb_button.dart:73 — A11y — raise to 40/44, one-line fixes all callers.
- **[P1] asIcon+sm = 36×36 icon button** — :191 — A11y — add minConstraints 44×44 on asIcon path.
- **[P2] loading state unannounced + BbSpinner no ExcludeSemantics** — :197-198,274-279 — A11y.
- **[P2] Semantics + InkWell double-announce risk (Material/Opacity between)** — :263-279 — A11y.
- **[P2] heights 36/44/52 raw literals (no named const)** — :72-79 — Theming.
- **[P3] onGradient Color(0x29FFFFFF)/0x38FFFFFF hardcoded** — :170-172 — Theming.
- **[P3] AnimatedContainer re-decorates + Matrix4 alloc on hover** — :236-255 — Perf.

### bb_card (PRIMITIVE) — 15/20 — ROOT
- **[P1] semanticLabel without excludeSemantics → double-read (ROOT of notifications_screen)** — bb_card.dart:130-132 — A11y — add excludeSemantics param.
- **[P2] non-interactive card semantically invisible (no container:true)** — :128 — A11y.
- **[P3] Matrix4.identity() alloc every build** — :123 — Perf.
- **[P3] accent bar width 4 raw literal** — :107 — Theming.

### bb_checkbox (PRIMITIVE) — 17/20 — ROOT (batch high)
- **[P1] naked-box variant 28px (no minWidth) = ROOT of register 22×22 finding** — bb_checkbox.dart:155-156 — A11y/Responsive — add minWidth:44.
- **[P2] Semantics wraps Opacity, label duplicated (no excludeSemantics)** — :226-245 — A11y.
- **[P2] semanticLabel ?? label drops subtitle (T&C subtitle never announced)** — :227 — A11y.
- **[P3] focus halo via spreadRadius only on 20px box not 44 target** — :176-179 — A11y.
- **[P3] InkWell ripple clips to box corner not full row** — :151-154 — Anti-Pattern.

---
## COMPONENTS batch 2 — primitives (bb_*) (2026-07-18) — ROOT-CAUSE layer (highest value)

### bb_chip (PRIMITIVE) — 11/20 — ROOT (A11y 0/4)
- **[P0] ZERO Semantics (no selected/button/label) = ROOT of chip-semantics systemic** — bb_chip.dart:58-136 — A11y — every consumer (faq, filters) inherits the hole. Wrap InkWell in Semantics(label,button:true,selected:).
- **[P1] tap target 32/40px <48** — :44 — A11y.
- **[P1] Colors.white ×4 (filterSelected)** — :51,108,116 — Theming. SYSTEMIC (onPrimary gap).
- **[P2] BorderRadius.circular(999) not BBRadius.fullAll** — :110 — Theming.
- **[P2] no focus ring** — :60 — A11y.

### bb_dialog (PRIMITIVE) — 14/20
- **[P1] no dialog Semantics (scopesRoute/namesRoute/header); Dialog.semanticsLabel unused** — bb_dialog.dart:36-44 — A11y.
- **[P1] barrier dismiss label absent** — :36 — A11y.
- **[P2] raw literal 20** — :58 — Theming.
- **[P2] no mobile inset-padding adjustment (ui-ux.md 12px)** — :38 — Responsive.
- **[P3] body String-only (no rich content) + no icon/severity slot → callers revert to raw AlertDialog** — :16-24 — Anti-Pattern.

### bb_dropdown (PRIMITIVE) — 15/20
- **[P1] no Semantics grouping (label detached from trigger)** — bb_dropdown.dart:225-229 — A11y.
- **[P1] disabled Opacity(0.45) no enabled:false + contrast fail** — :232-233 — A11y.
- **[P2] off-grid spacing 14/6/10** — :236,230,255,321 — Theming.
- **[P2] menu icon c.textTertiary on panelBg <3:1** — :294-296 — A11y.
- **[P3] FocusNode listener in field initializer not initState** — :128 — Anti-Pattern.

### bb_empty_state (PRIMITIVE) — 15/20
- **[P1] decorative BbIcon not ExcludeSemantics (reads numeric codepoint)** — bb_empty_state.dart:74,176 — A11y.
- **[P1] title no header:true** — :79-84 — A11y.
- **[P2] icon-disc c.primary@0.06 <3:1 (class #951)** — :70 — A11y.
- **[P2] raw BorderRadius.circular(12) not BBRadius.smAll + off-grid spacing** — :173,180,68 — Theming.
- **[P3] CTA Row no wrap fallback @360px** — :98-116 — Responsive.

### bb_icon (PRIMITIVE) — 13/20 — ROOT
- **[P1] no semanticLabel/ExcludeSemantics API = ROOT of "decorative icons not excluded" systemic** — bb_icon.dart:20-58 — A11y — all icons flow through here; Icon.semanticLabel:null does NOT suppress, need ExcludeSemantics wrapper.
- **[P2] _resolve() map lookup + IconData alloc every build (no cache)** — :36-45 — Perf.
- **[P2] missing-glyph fallback silent (no debug assert)** — :38-39 — Anti-Pattern.
- **[P3] fill/weight typed int (Icon wants double)** — :26-27 — Anti-Pattern.
- **[P3] no IconTheme.of inheritance** — :48-58 — Theming.

### bb_input (PRIMITIVE) — 12/20 — ROOT (biggest systemic, 3×P0)
- **[P0] missing textInputAction param = ROOT keyboard-chain gap (every multi-field form)** — bb_input.dart:35-58 — A11y — add `TextInputAction? textInputAction` → TextField.
- **[P0] missing focusNode param** — :108 — A11y — add `FocusNode? focusNode`, dispose only if internally created.
- **[P0] missing autofillHints param (+ no AutofillGroup)** — :35-58 — A11y — password managers disabled on login/register/change-password.
- **[P1] custom label not wired to InputDecoration.labelText (SR label detached)** — :210-216 — A11y.
- **[P1] no required-field indicator param** — :35-58 — A11y.
- **[P2] trailingAction (password toggle) tap target unenforced <48** — :282-285 — A11y.
- **[P2] missing textCapitalization param** — :35-58 — A11y/UX.
- **EXACT MISSING PARAMS:** textInputAction, focusNode, autofillHints, required, textCapitalization + trailingAction min-size.

### bb_logo (PRIMITIVE) — 11/20
- **[P1] useGradient=true DEFAULT = BBGradient.brandPrimary diagonal = FLAT-CHROME VIOLATION #4** — bb_logo.dart:9,20 — Theming — flip default false. FLAG (appears in nav/auth/admin chrome).
- **[P1] docstring claims assets/images/logo.png fallback — never implemented (glyph only)** — :5-6 — Anti-Pattern.
- **[P2] Text('b') no Semantics('BookBed')/ExcludeSemantics** — :8,25 — A11y.
- **[P3] Colors.white hardcoded** — :28 — Theming.

### bb_radio (PRIMITIVE) — sibling of bb_checkbox
- **[P1] missing radio contract (no inMutuallyExclusiveGroup:true/checked:) — announces generic 'selected'** — bb_radio.dart:152-157 — A11y.
- **[P2] Semantics wraps Opacity (same class as bb_checkbox)** — :152-157 — A11y/Anti-Pattern.
- **[P2] no-label dot ~24px width <48 (no minWidth)** — :108-149 — Responsive.
- **[P2] FormField validator reads outer value not state.value** — :241 — Anti-Pattern.
- **[P3] focus-ring raw BoxShadow spreadRadius:3** — :87 — Theming.

---
## COMPONENTS batch 3 — primitives (bb_*) (2026-07-18)

### bb_scaffold (PRIMITIVE) — 17/20
- **[P2] double BbRedesignTokens.of in _panel** — bb_scaffold.dart:100,105 — Perf.
- **[P2] desktopBreakpoint default 1024 vs canonical 1200** — :40 — Responsive. SYSTEMIC.
- **[P2] tablet/desktop branch bare Container not Scaffold (IME/overlay insets unhandled)** — :179-201 — Anti-Pattern.
- **[P3] mobile Drawer no semanticLabel** — :136-149 — A11y.

### bb_section_header (PRIMITIVE) — 13/20 — ROOT (A11y 0/4)
- **[P0] title emits NO Semantics(header:true) = ROOT of missing-header systemic** — bb_section_header.dart:47-51 — A11y — legal cluster/notification_settings/about all inherit; `level` enum never forwarded. One wrap fixes all.
- **[P1] action InkWell no Semantics(button/label) + icon not excluded** — :72-94 — A11y.
- **[P2] raw literals 2/4** — :56,77,89 — Theming.
- **[P3] action icon fixed 16px unscaled vs textScaler** — :85-90 — Responsive.

### bb_sidebar_rail (PRIMITIVE) — 14/20
- **[P1] _RailButton no selected: state** — bb_sidebar_rail.dart:114-116 — A11y.
- **[P1] logout InkWell no label/tooltip** — :80-94 — A11y.
- **[P2] no tooltips on collapsed rail items** — :68-74 — A11y/Responsive.
- **[P2] badge Colors.white + raw type + circular(999)** — :156,161-169 — Theming.
- **[P3] rail width 72 magic literal** — :48 — Responsive.

### bb_sidebar (PRIMITIVE) — 12/20 — ROOT
- **[P0] nav items zero Semantics(button/selected)** — bb_sidebar.dart:317-324 — A11y.
- **[P0] sub-items height 36px <48** — :403 — A11y.
- **[P1] section group labels no header semantics** — :200-213 — A11y.
- **[P1] collapse chevron 28×28** — :530-543 — A11y.
- **[P1] sidebar width hard-pinned 260 no breakpoint** — :77 — Responsive.
- **[P2] 3 raw TextStyle + hardcoded shadow Color literals** — :204-291,265-274 — Theming.
- **[P3] InkWell ink clipped by non-Material Container** — :317-324 — Anti-Pattern.

### bb_skeleton (PRIMITIVE) — 17/20
- **[P1] no ExcludeSemantics (10 placeholders = 10 empty SR focus stops)** — bb_skeleton.dart:52-77 — A11y.
- **[P2] no RepaintBoundary (siblings repaint together)** — :52-77 — Perf.
- **[P3] gradient-alignment shimmer re-allocs BoxDecoration/frame (vs ShaderMask)** — :61-65 — Perf.
- **[CLEAN] AnimationController lifecycle correct + BBMotion.reduced guard present.**

### bb_sparkline (PRIMITIVE) — 10/20 — BATCH LOW (A11y 0/4)
- **[P0] no Semantics label (chart invisible to SR, WCAG 1.1.1)** — bb_sparkline.dart:35-49 — A11y.
- **[P1] shouldRepaint list IDENTITY not equality (stale/over-repaint)** — :119-124 — Perf.
- **[P1] 5 Paint() allocs inside paint() every frame** — :95-113 — Perf.
- **[P2] no RepaintBoundary** — :35-48 — Perf.
- **[P2] docstring 'smooth path' but lineTo straight segments** — :5-7,87-89 — Anti-Pattern.
- **[P3] dotBg omitted from shouldRepaint** — :119-124 — Anti-Pattern.

### bb_spinner (PRIMITIVE) — 15/20
- **[P1] no Semantics/ExcludeSemantics (button spinner independently announced) = root of bb_button loading finding** — bb_spinner.dart:38-43 — A11y — add ExcludeSemantics default + opt-in semanticsLabel liveRegion.
- **[P3] AlwaysStoppedAnimation misleading name** — :40 — Anti-Pattern.
- **[CLEAN] CircularProgressIndicator framework-managed controller, token color.**

### bb_status_badge (PRIMITIVE) — 15/20 — status-color AA (3rd instance)
- **[P1] statusImported #4A90D9 = 3.3:1 fails AA = 3rd member of status-color-AA class** — bb_status_badge.dart:63-68 — A11y — add statusImportedDeep token (pattern already exists for confirmed/pending Deep).
- **[P2] no Semantics role wrapper** — :80-108 — A11y.
- **[P3] TextStyle raw literals not BBType** — :97-103 — Theming.
- **[P3] hardcoded HR fallback strings ×5 (22 call sites, non-HR falls through)** — :41-68 — Anti-Pattern.
- **[P3] cancelled dot uses c.textTertiary (text token) not status token** — :53 — Theming.

---
## COMPONENTS batch 4 — bb_switch + shared/legacy widgets (2026-07-18) — DEAD-CODE discoveries

### bb_switch (PRIMITIVE) — 16/20
- **[P1] excludeSemantics missing → label double-announced (same class as checkbox/radio)** — bb_switch.dart:134-139 — A11y.
- **[P2] raw BoxShadow Color(0x29000000) not BBShadow** — :76-80 — Theming.
- **[P2] no keyboard focus (Space/Enter toggle)** — :88 — A11y.
- **[P3] minHeight 44 not 48** — :92 — A11y.

### adaptive_layout (shared) — 11/20
- **[P1] AppDimensions.tablet=1024 breakpoint (canonical 1200); AdaptiveSplitView minWidthForSplit=800; 3 diff thresholds in one file** — adaptive_layout.dart:40,124,382,255 — Responsive. SYSTEMIC.
- **[P2] AdaptiveAppBarActions nested interactive in PopupMenuItem (double-tap/announce)** — :402-407 — A11y.
- **[P3] AppDimensions.spaceS/M/L not BBSpace** — Theming.
- **[P3] per-build list alloc + .reversed.toList()** — :45-61 — Perf.

### app_filter_chip (shared, legacy) — 8/20 — MIGRATE→BbChip
- **[P1] no Semantics(selected:) — AT label empty when icon present** — app_filter_chip.dart:73-111 — A11y.
- **[P2] AnimatedContainer animates nothing (dead 200ms; colors live in FilterChip)** — :66-67 — Anti-Pattern/Perf.
- **[P2] tap target <48 (no materialTapTargetSize:padded)** — :105 — A11y.
- **[P2] ZERO BB tokens (Colors.white, circular(10), elevation:2, fontSize:14)** — :47-110 — Theming.
- **[P2] BbChip is canonical successor; 4 live call sites (unit_form:647, property_form:914, calendar_filters_panel:317,383) — straight swap.**

### bookbed_branded_loader (shared) — 11/20
- **[P1] no Semantics/liveRegion on progress** — bookbed_branded_loader.dart:47-64 — A11y.
- **[P2] indeterminate FractionallySizedBox alignment = layout pass/frame (use Transform.translate)** — :152-163 — Perf.
- **[P2] fixed 200px bar (62% of 320dp)** — :22,53-54 — Responsive.
- **[P2] isDarkMode bool param duplicates Theme + raw AppColors** — :39-98 — Theming/Anti-Pattern.

### bookbed_logo (shared, legacy) — 9/20 — DEAD CODE
- **[P0] DEAD CODE — zero callers, superseded by BbLogo (11+ sites). Safe to `rm`.** — bookbed_logo.dart — Anti-Pattern.
- **[P1] (live, on BbLogo) useGradient=true default = flat-chrome trap** — bb_logo.dart:9 — Theming (already logged batch 2).
- **[P2] Image.asset no semanticLabel** — :47 — A11y (moot, dead).

### button (shared, legacy / PremiumButton) — 7/20 — DEAD CODE
- **[P0] DEAD CODE — zero call sites, superseded by BbButton (288 sites). Delete file + widgets.dart:16 export.** — button.dart — Anti-Pattern.
- **[P1] authPrimaryGradient/ctaGradient diagonal = flat-chrome violation (in dead code = trap if export stays)** — :410,419 — Theming.
- **[P1] no Semantics on any path** — :183-237 — A11y (moot, dead).
- **[P2] GestureDetector+InkWell gesture-arena contention** — :186-213 — Anti-Pattern.

### card (shared, legacy / PremiumCard) — 7/20 — NEARLY DEAD (2 callers, glass API dead)
- **[P1] CardVariant.glass = live GLASSMORPHISM API (banned anti-pattern as named symbol) + gradient fills** — card.dart:319-342,170-196 — Anti-Pattern/Theming.
- **[P1] no semantics on tappable card** — :255-261 — A11y.
- **[P1] outlined/filled variants use non-dark-aware AppShadows.elevation1** — :307,315 — Theming.
- **[P2] SingleChildScrollView(NeverScrollable) on every card (dead layer)** — :259-267 — Perf.
- **[P2] enableHover=true default rebuilds non-interactive cards on hover** — :60,234-243 — Perf.
- **[P3] glass/outlined/filled factories = 0 live consumers (2 sites use .elevated only: unit_hub_empty_state:155, revenue_chart_widget:40) → migrate to BbCard + delete.**

### common_app_bar (shared, ~40 consumers) — 15/20 — ROOT
- **[P2] hardcoded EN tooltip 'Menu' on ALL leading icons (drawer/back/close) = ROOT across ~40 screens** — common_app_bar.dart:57 — A11y — make nullable leadingTooltip param w/ l10n.
- **[P2] title required String even when showTitle:false (dummy strings at 4 premium sites)** — :11,22-28 — Anti-Pattern.
- **[P3] magic breakpoint 600 + MediaQuery.of every build** — :38 — Responsive.
- **[P3] actions get no enforced tooltip/semantics contract (root of missing action tooltips)** — :60 — A11y.
