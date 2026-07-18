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
