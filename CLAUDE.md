# Claude Code - Project Documentation

**BookBed** - Booking management platforma za property owner-e.

**Dodatni dokumenti:**
- [consolidated-bugs-archive.md](./docs/bugs/consolidated-bugs-archive.md) - Detaljni bug fix-evi sa code examples
- [EMAIL_SYSTEM.md](./docs/features/email-templates/EMAIL_SYSTEM.md) - Email template-i, payment rok, reminders
- [SECURITY_FIXES.md](./docs/SECURITY_FIXES.md) - Sigurnosne ispravke (SF-001..SF-073)
- [CHANGELOG.md](./docs/CHANGELOG.md) - Svi changelogi
- [TODO.md](./docs/TODO.md) - Planirani zadaci

**Audit log** (one-line index; detail in each audit/*.md file). *Pruned 2026-06-11: closed session audits + screenshot artifacts deleted (105MB→1.2MB) — recover any via git history (`git log --diff-filter=D -- audit/`). Kept: rules-referenced, OPEN/🚨 findings, runbooks, specs, recent design chain.*
- [cutover-dryrun-2026-05-30/runbook.md](./audit/cutover-dryrun-2026-05-30/runbook.md) — full ledger + 4a/4b/4c/4d phase logs + IAM re-grant script (2026-05-30)
- ✅ [overnight-fidelity](./audit/overnight-fidelity-2026-07-10.md) — **15-iteration** overnight design-fidelity campaign (owner + widget + admin), handoff as visual TARGET, fix-as-you-go across **#840–#854** (all squash-merged, dev-only, no deploy). **Owner:** Subscription cheap-wins `da0515e0` #840; auth-recovery RecCard icon-tile + xl radius `df9be9d5` #843; profile BookBed-Pro benefits grid + €19 + l10n `67fe8cd3` #844 / `912f1e96` #851; iCal hero → flat status card `d492a332` #841; embed/owner docstring flatten + embed **data-honesty** verdict `72a79fa2` #842; unit-hub master-panel fidelity `a5a663d1` #845 → PropertyTree **flat-row** rework (`ExpansionTile`→`Row [chevron][icon][name Expanded][count][edit][delete][add]`, closes long-name vertical-wrap band-aid) `40cad472` #854; 5 owner `AlertDialog`→`BbDialog` `c11c1a71` #849; deferred mop-up (units 1-line title / iCal Uvoz-Izvoz badge / admin env pill) `85301145` #850. **Widget:** mint success-mark + deposit band `ec71d98e` #846; mint calendar selection-ladder + guest-form quick-wins `e96bb8f7` #847; guest-form input radius **8→12px** `eef254f3` #853. **Admin:** dark-console nav chrome → `BbAdminDarkTokens` `8d4bed10` #848. **Decisions:** flat-chrome enforcement (no TIP-1 gradient re-add); data-honesty skips (no faked features); **CanvasKit login unlock** via `flt-semantics-placeholder` click enabled iter-13 live-verification sweep (`370d2e52` #852, doc-only attestation of #840–#851); 12px input radius standard. Full suite **1697 green**, golden **56/56** (no widget golden — 0 collateral), analyze 0 net-new, build web clean per PR. FROZEN (Cjenovnik/publish/timeline/widget-submit) untouched throughout. CHANGELOG 7.37. Deferred: owner PROD deploy batch. (2026-07-10)
- ✅ [breakpoint-decide](./audit/breakpoint-decide-2026-06-20.md) — canonical desktop-breakpoint **DECISION** (resolves the §1 "breakpoint-system unification" deferral from audit/responsive-overflow-a11y). Three competing helpers, none = the documented 1200: `Breakpoints` desktop=**1024** (38 refs, powers `context.isDesktop`), `BBBreakpoint` wide=**1440** (6), `ResponsiveBreakpoints` desktop=**1200** (6). **Decided 1200** (single source `lib/core/constants/breakpoints.dart`; other two delegate later), **additive** (legacy `Breakpoints.desktop=1024` flips in a separate Final codemod, NOT in place). Re-drift rule: classify by what a comparison READS — `MediaQuery` width pivot (padding/typography) → migrate to 1200; `LayoutBuilder constraints.maxWidth` reflow (column-count/wrap) → keep + name local const. **Decision doc SHIPPED main `ead8e25e` (#766)** (doc-only). **Foundation SHIPPED main `decb3be8` (#769)** — additive `Breakpoints.desktopWide=1200` + `isDesktopWide()` + fixed lying `context_extensions.dart` docstrings (claimed ≥1440; code is ≥1024); zero behavior, analyze 0 net-new, suite 1581 green, build web clean. CHANGELOG 7.32. Dev-only. Deferred: per-screen migrations (ride design passes — stripe/138, ical/140, embed/137) + Final codemod (flip legacy desktop / re-point `context.isDesktop` / eyeball 38 consumers @ ~1100px). (2026-06-20)
- ✅ [responsive-overflow-a11y](./audit/responsive-overflow-a11y-2026-06-20.md) — P5 read-only sweep (owner+widget+admin): breakpoint consistency (TWO disagreeing helpers, neither = canonical 1200), §2 RenderFlex overflow (3 confirmed), a11y missing-semantics + <48 tap-targets, dark-contrast. **2 §2 fixes shipped:** admin Users-list `DataTable` horizontal overflow → `LayoutBuilder`+horizontal-SCV+`ConstrainedBox(minWidth)` (**main `8828e620` #765**); `booking_action_menu` 6 bounded name Texts → `maxLines:1`+ellipsis (**this PR**). Each a RED→GREEN seam test (admin 780/900/1100/1440; menu BookingActionBottomSheet+MoveToUnit, both bite). analyze 0 net-new, suite +1583, build web clean. CHANGELOG 7.31. Dev-only. Deferred: breakpoint-system unification (§1), a11y tooltips/semantics batch, dark-contrast pass. (2026-06-20)
- ✅ [135-settings-fidelity-diff](./audit/135-settings-fidelity-diff-2026-06-19.md) — owner Settings fidelity diff (continuation of audit/129 §S3/S4-deferred). Code-first recon: cluster largely DONE; 2 agent-flagged "gaps" **false** (identity-chip + public-profile = no feature → data-honest omit; `change_password` SReqList already in `_PasswordStrengthMeter`). **SHIPPED main `54f0820a` (#762)** cheap-wins: `widget_advanced_settings` 4× raw `AppBar`→`CommonAppBar` (embed-safe behind `showAppBar` guards → no double-header in hub Napredno tab); `notification_settings` hardcoded HR banner → l10n `notificationSettingsBannerInfo`. DROPPED `edit_profile` 2-col name grid (single full-name field; split = data-model + migration = feature). analyze 0, suite +1535, build web clean. CHANGELOG 7.29. Dev-only. Deferred: S3 profile-hub Pro-card benefits grid (heavy, 1503 LOC). (2026-06-19)
- ✅ [134-unit-hub-fidelity](./audit/134-unit-hub-fidelity-recon-2026-06-19.md) — Unit Hub recon (**most FROZEN-saturated owner screen**: hosts FROZEN Cjenovnik grid + Wizard publish; §2 FROZEN-intersection map = #1 output). **B+A SHIPPED main `7301e77b` (#761)**: Osnovno tab → `units.jsx` (desktop gallery + header [Kopiraj/Uredi] + 2-col `BbCard` + emphasized PriceTile + tappable Cjenovnik banner), 3× `AlertDialog`→`BbDialog`; Vidljivost/Polog dropped (no backing field = data honesty); master panel deferred. **§F SHIPPED main `bbbcb9a3` (#763, 2026-06-20)** — Unit Wizard progress-bar polish (**= the work originally slated as `audit/142`; renumber didn't take → done under the 134 umbrella**): off-palette `#66BB6A`→`BBColor.of(context).success` (#2E7D5B/#4FAE7F) on completed nodes/labels/connectors + mobile bar; current node `BBShadow.purpleGlow` (handoff `--bb-shadow-purple-sm`, glow eyeball-confirmed = bloom not lift); 42-cell `wizard_progress_bar_test`; rejected handoff traps (FROZEN meta-badge / "Skica spremljena" no-persistence / step-1 Odustani / stepper re-layout). FROZEN `_publishUnit` 2-doc serial write untouched. analyze 0, build web `--no-tree-shake-icons` clean. CHANGELOG 7.28 + 7.30. Dev-only. (2026-06-19/20)
- ✅ [133-merged-screens-eyeball](./audit/133-merged-screens-eyeball-2026-06-19.md) — verification eyeball of the 3 last-merged owner screens @ main `ec9be53b` (2 merged UNVERIFIED); **no code changed**. Dev `:8095` (bookbed-dev, `seed-mcal-eyeball-dev.js` = 5 June bookings/Studio B) live-driven via chrome-devtools (CanvasKit) + 2 code-truth agents. **#1 AI Asistent:** user-bubble initials **`BT`** ✅ LIVE → closes the audit/132 [T1] eyeball-gate ([[seam-test-proves-fn-not-wiring]]); streaming UI code-correct (real `sendMessageStream`, dots→text flip) but did NOT run live — Gemini gated by `[app-check/recaptcha-error]` on a clean Chrome profile (no registered debug token; pipeline OK up to App Check, graceful banner) → refines [[firebase-ai-appcheck-sim-emulator-403]]; **dev-only, no PROD scope**. **#2 Mjesečni:** ✅ light+dark+mobile — 5 bookings/status colours/weekend tint/"DOLASCI·7D"/"Xn"/today circled; mobile = dots + `_buildDayAgenda` (code-confirmed); **ship-ready**. **#3 Timeline:** renders ✅ (turnover bars, premium chrome); **presuda** — page is FIXED, only the grid scrolls; vertical SCV nested in horizontal SCV = root cause; fix `Listener(onPointerSignal)`→`_verticalScrollController.jumpTo(pixels+dy)` (1×, column synced, horizontal passthrough) ⇒ **wheel-hook SUFFICIENT, NO parent-restructure** (would touch FROZEN grid). ⚠ OPEN: wheel sync/1× NOT live-automatable (synthetic wheel = no-op, [[flutter-web-scroll-not-automatable]]) → physical wheel eyeball; **touch-drag NOT covered by the fix** (gesture-arena path, still claimed by horizontal SCV) → device check + parallel fix if broken. (Timeline opens on July → `‹` to June.) (2026-06-19)
- ✅ [132-ai-assistant](./audit/132-ai-assistant-2026-06-18.md) — owner AI Assistant premium fidelity + subtle motion vs `ai-assistant.jsx` handoff (beyond audit/127 palette). **MERGED main `10d7a97c` (FF)** — S1: `_AiHeroIllustration` glow unified (empty/consent/quick-reply); bubble avatar 32→24; chips 5→**4/3/2** by width; composer minLines desktop 2; panel 320→300; bubble+header breakpoints aligned to `_kDesktopBp`(1200) so 768 folds coherently; 5 literals named. S2: user-bubble `BbAvatar` initials from `enhancedAuthProvider.userModel`. S3 (design-to-system, additive): typing dots replace static `'...'`, send cross-fade, chat-list skeleton, chip stagger — **streaming heartbeat untouched**. R1: tablet folds to mobile (no tier; `attach_file`/breadcrumb out of scope). **Hardening:** `buildAiMessageBubble` `typing`/`userName`/`userAvatarUrl` now **required** → compile-guards the call site (caught a live-unwired call site — static `'...'`/`"?"` avatar — that passed analyze+build+seam 14/14; full-screen pump blocked by `enhancedAuthProvider` so [T1] dispatch test deferred, wiring eyeball-gated; [[seam-test-proves-fn-not-wiring]]). analyze 0, seam 14/14, full suite +1535, build web clean. Live dev smoke: **iOS sim + Android Pixel_8 render ✓** (S2 'BT' avatar live) + **web `:8093` streaming ✓** (operator); native streaming blocked by `firebase_ai` App Check 403 on sim/emulator (env, not code). CHANGELOG 7.27. FROZEN: none. Not deployed (dev-only per operator) (2026-06-18)
- ✅ [129-owner-settings](./audit/129-owner-settings-2026-06-17.md) — recon: "owner Settings" = 9-screen CLUSTER (no single file; reached from `profile_screen` hub), ALL already Bb*-migrated (hex=0, mostly `context.gradients`) → not a campaign. Handoffs `settings.jsx` (3 forms) + `profile-premium.jsx` (hub). **SHIPPED main `3ec80302` (#760)** — S2: `bank_account` body `Container(color: rd.shellBg)`→`context.gradients.pageBackground` (**VISUALLY NEUTRAL**: rd.shellBg==pageBackground `#F0F1F5`/`#000` = hygiene not bug; audit/126 single-source). S1 DROPPED = recon **false positive** (widget_advanced flagged legacy by Bb=6/Mat=8, but non-comment grep=0; "hand-rolled gradient/Material/InkWell" = comments documenting past migrations→`BbButton`/audit/120; already flat+Bb). analyze 0, full suite green, build web clean; CHANGELOG 7.26. **Lesson:** low-Bb/high-Material fingerprint = candidate signal not proof — confirm code-not-comments; render only pixel-moving changes ([[skip-render-for-neutral-hygiene-changes]]). Deferred: owner PROD deploy (9 on main, 0 in PROD; hosting-only, pre-flighted green) (2026-06-17)
- ✅ [128-booking-detail-fidelity](./audit/128-booking-detail-fidelity-2026-06-17.md) — owner_booking_detail premium fidelity+hygiene vs its dedicated handoff (`booking-detail.jsx §201`; already premium-composed → light fidelity pass, sequenced behind 127). **MERGED main `77b8c3a6` (#759)** — F1 destructive→`destructiveSoft` ×3 (Odbij/Otkaži/mobile = soft-pink per handoff); §2 dead `shellBg` Container dropped → `pageBackground` (visually neutral: old shellBg == post-127 flat #F0F1F5/OLED #000; single-source per audit/126); §3 hygiene (named layout consts; off-grid `14`→`_kMobileGap`=12 since `BBSpace.xs2` **deprecated-on-use**; 2×`dynamic`→`BookingModel` + casts dropped); F6 `_TabletGrid` 2-col ≥720 (600–719 wide single; handoff tablet 768). Robustness (overflow-test-surfaced, 0 visual): cover eyebrow `Flexible`+ellipsis, `_TimelineRow` `Expanded`+ellipsis. New `owner_booking_detail_layout_test` (44 cells: 8 bp × light/dark × normal/long + 4 status); `detailActionVisibility` 5-case gate **preserved** (move-not-delete); Navigator.push FROZEN untouched. analyze 0, gate 5/5, overflow 44/44, live light render (desktop+tablet) F1+F6 confirmed; dark = 127 ladder. CHANGELOG 7.25. Deferred: PROD deploy batch, F3 bell, l10n debt (2026-06-17)
- ✅ [127-handoff-design-system](./audit/127-handoff-design-system-2026-06-16.md) — color/surface/bg **SYSTEM** audit (light+dark) vs handoff: extracted ground-truth ladder + 6 renders + mapped the **3-system Frankenstein** (`app_gradients` off-palette `#ECEDF2`/`#1A1A1A`/`#2D2D2D` vs `app_theme`/`rd.*` already aligned) + inverted dark elevation. **APPLIED on `design/127-handoff-palette-apply` (branch, unpushed, clean FF over origin/main)** — Part 1 handoff ladder (light `#F0F1F5`/`#FFFFFF`/cool borders `#E2E8F0`/`#2D3748`, dark `#000` OLED; VALUES-only, FLAT kept) + Part 2 **dark-depth widen** (flat chrome = no shadow → handoff Δ≈11 dark steps left panel dead → widened `#000`→`#141414` panel→`#1E1E1E` card→`#2A2A2A` variant→`#333333` elevated; divider/popup/elevation rippled; **LIGHT unchanged**). 5 files (`bb_redesign_tokens`/`tokens`/`app_colors`/`app_gradients`/`app_theme`) + `bb_card_test` re-point; analyze 0 net-new, suite green, live dev light+dark sweep (cards lift, panel floats, un-inverted). §7 doc addendum + memory [[flat-chrome-decision]] (shadowless-dark principle). CHANGELOG 7.24. Deferred: owner PROD deploy batch (2026-06-16)
- ✅ [126-global-chrome-fidelity](./audit/126-global-chrome-fidelity-2026-06-16.md) — read-only audit of shared owner chrome (page bg/gradients, `CommonAppBar`, `OwnerAppDrawer`) vs handoff: current-state map + handoff ground-truth ledger + decision options (1A/1B, 2A/2B/2C, 3A/3B/3C) + recommendation. **Fix SHIPPED main `696f004c` (2026-06-16)** — 1B (4 bg stragglers→`context.gradients.pageBackground`; `embed_widget_guide` skipped=already gradient), 2A (additive `CommonAppBar.showTitle` kills the 4-premium double-header, ~29 non-premium untouched), 3A (drawer `colorScheme.onSurface/primary`→`BBColor.textPrimary/primary` byte-identical cosmetic-neutral). 1461 tests, web build clean, live light+dark sweep; CHANGELOG 7.21 + audit/124 §global-chrome. Deferred: 2B breadcrumb appbar, 3B persistent desktop sidebar+rail. **§flatten REVERSAL SHIPPED (CHANGELOG 7.23)** — operator reversed TIP-1 → FLAT: `app_gradients` page/section gradients flattened (light shell `#ECEDF2`/raised `#FFF`, dark `#1A1A1A`/`#2D2D2D`, dark-card dissolve `#0B0B0D`→`#2D2D2D` fixed; 0 new hex), AI-card + Rezervacije-header hero washes → flat `surfaceVariant` (purple icons kept; mint-wash grep=0), trial banner flat + EN→HR (l10n debt flagged); usput `_Fact` RenderFlex fix (`Flexible`+ellipsis, +114px@≈1352) + 16-cell overflow test; 1495 tests, 0 FROZEN, live light Pregled+Rezervacije + dark golden harness. See [[flat-chrome-decision]] (2026-06-16)
- ✅ [125-security-audit](./audit/125-security-audit-2026-06-12.md) — delta /vibe-security pass (clean) + full 165+-check re-run (6 agenata, HUGE): 0 CRIT/HIGH/MED novih, 5 LOW; 2 agent false-positives ubijena firsthand verifikacijom. SF-084 fix wave (**PR #731**, merged `a5cd544f`): SF-080 extension — units + additional_services create/update trial-gated (kanonski + CG permissive-union mirror; delete = off-ramp), `widget_secrets.updated_at` request.time bind when-written, Firestore-backed RL na 4 booking-action + 2 admin callable-a. Rules emulator 196 pass (+14), jest 463/463; **PROD pickup ZAVRŠEN** (rules + 6 CF eu-west1, reachability verify svih 6). Usput: CI regresija paths-filter v3→v4 ("Resource not accessible by integration", ista klasa kao #728 "2s infra fail") → `permissions: pull-requests: read` fix; billing block se vratio → local-verified merge. Otvoreno dodano: F-125-04 Node 22 (Oct 2026 EOL), F-125-05 uuid moderates (ride firebase-admin@14, F-107-07/08) (2026-06-12)
- 🔄 [124-owner-page-fidelity](./audit/124-owner-page-fidelity-2026-06-11.md) — IN-FLIGHT page-by-page owner fidelity vs handoff (16 stranica + drawer + app bar, light+dark, fix-as-you-go na `design/124-owner-page-fidelity`): Pregled arrivals card + desktop grid + hero wash, Rezervacije Završene tab + channel tones, Timeline/Mjesečni weekday eyebrows + golden weekends + Uvezene legend, login desktop split; builds on audit/121 token layer (2026-06-11). **Rezervacije lean ledger (handoff RZPLedger) + gate-fix (complete/cancel → detail) SHIPPED main `420b48ed` (2026-06-15)** — novi pure `bookings_ledger.dart`, 10 orphan widgeta obrisana, `detailActionVisibility` `@visibleForTesting`, 2 testa, dev smoke 4/4 (Android Impeller); vidi CHANGELOG 7.19 + audit/124 §lean-ledger. **Timeline/Kalendar premium chrome (header + Timeline∣Mjesečni switch + grid card + legend pill badgevi + FAB krug + toolbar tokeni) SHIPPED main `b9656008` (2026-06-16)** — FROZEN grid (`timeline_dimensions`/repo/grid widgeti) bajt-identičan (samo wrap: DecoratedBox izvan ClipRRect), `buildChromeForTest` `@visibleForTesting` na widgetu, 8-ćelija overflow test, live web light+dark; CHANGELOG 7.20 + audit/124 §timeline-premium-chrome. Spawned [[listtile-asset-fail-robustness-gap]] (zaseban prod PR, NE bundlan). **Global chrome (page-bg gradient migration + double-header kill + drawer tokenize) SHIPPED main `696f004c` (2026-06-16)** — own audit/126 (1B+2A+3A); additive `CommonAppBar.showTitle` (4 premium stripped, ~29 non-premium untouched), 4 bg stragglers → `context.gradients.pageBackground`, drawer `colorScheme`→BB* byte-identical; 1461 tests, live light+dark sweep; CHANGELOG 7.21 + audit/124 §global-chrome. **AI Assistant premium fidelity (flat bubbles + `AiConversationHeader` copy/delete + composer pill + consent VIZUALNO-SAMO restyle + token sweep; `showTitle:false` ×3 → no double-header) SHIPPED main `ec78235b` (2026-06-16)** — LIVE Gemini shell-only (NE fabrikuje output), `_PregledAiInsight` placeholder NETAKNUT (data-honesty); consent grant/deny logika 0 linija; `@visibleForTesting buildAiMessageBubble` + 14-cell `ai_assistant_premium_test`; live bookbed-dev light+dark + consent grant end-to-end (logout→login→accept→chats) + logout robustnost real-tap clean (raniji "Oops" = Marionette `scroll_to` tooling, ne bug); CHANGELOG 7.22 + audit/124 §ai-assistant. **Owner PROD deploy sad 6-changes PREZREO** (Pregled+Rezervacije+Timeline+Mjesečni+global-chrome+AI, sve dev-only) → sljedeći potez = owner hosting-only PROD deploy + smoke. 2B breadcrumb + 3B persistent desktop sidebar deferred
- 🟢 [123-security-audit](./audit/123-security-audit-2026-06-11.md) — full 165+-check sweep (9 agents + gitleaks + semgrep + npm audit) + 2 /vibe-security passes: 0 CRIT/HIGH new. Fix wave 1: F-123-01/02/04/06/07 (payment bounds + iCal sanitize + 5MB cap + Connect rate limits; 462/462 jest green). Fix wave 2 (AI/LLM): F-123-AI server-authoritative Gemini daily quota (Firestore `users/{uid}/data/ai_usage` {day,count}, txn-consumed, rules pin day→request.time + monotonic increment so restart/tamper can't reset; replaces client-memory counter) + `ai_chats` messages.size()≤200; new `ai_usage.test.ts` 14 cells, full rules suite 173 pass green. Tier/subscription escalation verified CLOSED first-hand (rules 78-129). **§4 = kanonski open ledger** (99+107 apsorbovani 2026-06-11, izvorni docs obrisani). Same-day residual-closure wave (SF-083): F-86-01/02, F-99-03/10/16, F-107-10/13/16 CLOSED + F-107-17 killed false-positive + F-107-14 deferred-with-finding. Preostalo otvoreno: F-123-03 trial-gate product decision, F-86-03 Stripe-min-floor product decision, F-99-09/12-15 + F-107-05/12/15 deliberate deferrals, firebase-admin/functions major bumps (F-107-07/08), operator App-Check toggle + PROD curl verify (2026-06-11)

---

## NIKADA NE MIJENJAJ

| Komponenta | Razlog |
|------------|--------|
| Cjenovnik tab CONTENT (`unified_unit_hub_screen.dart` — pricing grid + Spremi) | FROZEN - referentna implementacija. Hub screen-shell chrome (premium header above existing layout, theme/AppBar) je additive-OK; FROZEN scope = tab content only. |
| Unit Wizard publish flow | 2-doc serial write (unit → widget_settings, Doc 2 id sourced from Doc 1) — redoslijed kritičan |
| Timeline Calendar z-index | Cancelled bookings at base (drawn first), confirmed on top |
| Calendar Repository (`firebase_booking_calendar_repository.dart`) | 989 linija, duplikacija NAMJERNA - bez unit testova NE DIRATI |
| Owner email u `atomicBooking.ts` | UVIJEK šalje - NE vraćaj conditional check |
| Subdomain validation regex | `/^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$/` (3-30 chars) |
| `generateViewBookingUrl()` u `emailService.ts` | Email URL logika |
| Navigator.push za confirmation | NE vraćaj state-based navigaciju |
| Timeline Calendar fixed dimensions (`timeline_dimensions.dart`) | FIXED 50/42/100/60px za SVE uređaje — NE vraćaj responsive breakpoints |
| `bookings` read rule — `unit_id+status` clause 1 | ✅ T11c CLOSED 2026-05-22 (commit `ab6bdb3d`). All 3 rule surfaces tightened. Widget calendar + booking-submit route through `getUnitAvailability` callable (eu-west1). Realtime → 30s polling. Privacy-driven: pending/confirmed visual distinction sacrificed. Vidi SF-019 (audit/06 obrisan — git history). |
| App Check na widget entry-ima (`widget_main*.dart`) | OFF NAMJERNO (eternal-shimmer P0, 2026-06-15, main `9cd2d2de`). `AppCheckInit.activate` → `ReCaptchaV3Provider` učitava CSP-blokiran `www.google.com/recaptcha/api.js` → token nikad ne iskuje → Firestore listeni + callables stalluju 10s → offline → vječni skeleton. App Check `enforceAppCheck:false` svuda gdje widget zalazi. NE re-enable bez Option B (`www.google.com` u `script-src` sva 3 surfacea + pravi `APP_CHECK_RECAPTCHA_KEY` + enforcement, ZAJEDNO). Detalji: `.claude/rules/widget.md`. |

---

## STANDARDI

```dart
// Gradients — FLAT since 2026-06-16 (CHANGELOG 7.23): pageBackground +
// sectionBackground render as SOLID fills (TIP-1 gray gradient retired per
// operator). API unchanged; do NOT re-add gradient stops. See app_gradients.dart.
final gradients = context.gradients;

// Input fields - UVIJEK 12px borderRadius
InputDecorationHelper.buildDecoration()

// Provider invalidation - POSLIJE save-a
await repository.updateData(...);
ref.invalidate(dataProvider);

// Nested config - UVIJEK copyWith
currentSettings.emailConfig.copyWith(requireEmailVerification: false)
// NE: EmailNotificationConfig(requireEmailVerification: false) - gubi polja!

// Provider error handling - UVIJEK graceful degradation
try {
  return await repository.fetchData();
} catch (e, stackTrace) {
  await LoggingService.logError('Provider: Failed', e, stackTrace);
  return []; // ili null - NE throw
}
```

**Design tokens (NEW code):**
- Koristi `BB*` iz `lib/core/design/tokens.dart` (`BBSpace`/`BBRadius`/`BBColor`/`BBType`/`BBShadow`) — canonical namespace
- `AppColors`/`AppDimensions`/`AppTypography`/`AppShadows` su source of truth (BB* delegira); **NE** refaktoriraj postojeće call sites in-place — bulk codemod je zaseban PR
- 3 off-scale TODO consts: `BBSpace.xs2=12`, `BBRadius.xs2=8`, svih 9 `BBType.*`
- Detalji: `design_handoff/source/tokens.css` (ground truth) + `audit/80b-token-mapping.md`

---

## QUICK CHECKLIST

**Prije commitanja:**
- [ ] `flutter analyze` = 0 issues
- [ ] Pročitaj CLAUDE.md ako diraš kritične sekcije
- [ ] `ref.invalidate()` POSLIJE repository poziva
- [ ] `mounted` check prije async setState/navigation
- [ ] **Seam-tested feature** (`@visibleForTesting` builder + a test that pumps it directly)? The seam test proves the **function**, NOT that the screen's call site wires it — green analyze/build/seam-test can hide a fully-unwired feature. Before merge: **live wiring check** (trigger the real path on the running app) OR a provider-overridden full-screen dispatch test. Memory: `seam-test-proves-fn-not-wiring` (audit/132 proof).

**Responsive breakpoints:**
- Desktop: ≥1200px
- Tablet: 600-1199px
- Mobile: <600px

---

## OBAVEZNO PRIJE COMMITA

**Dart formatiranje** - CI odbija PR ako kod nije formatiran:
```bash
dart format .
```

**Za AI agente:** UVIJEK pokreni `dart format .` prije commit-a.

**CI build-android job** (`.github/workflows/ci.yml` Job 3): koristi `./tool/build_aab.sh --release` wrapper — NE `flutter build appbundle` direktno (pukne na flutter_native_splash registry bug). Vidi `.claude/rules/hosting-build.md` + `memory/aab-build-blocker.md`.

---

## PARALELNI TERMINALI — NIKAD NE EDITUJ SHARED MAIN CHECKOUT

Više agent-terminala dijeli ovaj checkout. **SVAKI edit ide u VLASTITI worktree+branch — nikad u glavni repo dir** (`/Users/duskolicanin/git/bookbed`), čak ni jednolinijski `CLAUDE.md` / `docs/CHANGELOG.md` / audit-doc bump.

```bash
git worktree add /tmp/bb-<topic>-wt -b <type>/<topic> origin/main
cd /tmp/bb-<topic>-wt   # SAV rad ovdje: edit + verify + commit + push
# kraj: git worktree remove /tmp/bb-<topic>-wt
```

**Zašto:** uncommitted edit ostavljen u shared main stablu blokira sljedećem terminalu `git merge --ff-only origin/main`. Pregorjelo DVAPUT (2026-06-11 CLAUDE.md index race; 2026-06-21 — #768 changelog ostao uncommitted u mainu, ff abortao; bio je JEDINI zapis već-merge-anog code-only PR-a, umalo discardan na "vjerojatno housekeeping" pretpostavku).

**Ako nađeš prljav shared main tree — look-first, NIKAD blind-discard:** (1) `git diff <files>` da pročitaš; (2) odluči superseded-vs-jedina-kopija provjerom je li sadržaj već na origin/main (`git grep <marker> origin/main -- <file>` + je li PR merge-an code-only); (3) ako je substancijalno → PRESERVE prije čišćenja: patch na ZASEBAN fresh worktree + push, TEK onda `git checkout -- <files>` + ff; (4) NIKAD blind `stash→ff→pop` (pop konfliktira na istim version/changelog linijama koje sibling merge dira). Per-branch version bumpovi se beskonačno sudaraju pod paralelnim merge-om (7.32→7.33→7.34 race) → ostavi za JEDAN end-of-campaign CHANGELOG-reconcile prolaz, ne whack-a-mole. Detalji: `memory/parallel-session-shared-tree-protocol.md`.

---

## TOOLING GOTCHA: `flutter analyze` phantom errors

Ako `flutter analyze` izvijesti **tisuće** `uri_does_not_exist` / `undefined_identifier` / `undefined_method` errora — **NE TRETIRAJ ih kao bug u kodu**. Skoro sigurno je pub-cache desync.

**Quick check:** `ls -d ~/.pub-cache/hosted/pub.dev/firebase_core-* 2>/dev/null`

**Fix:** `flutter pub get`. (Historical proof: 6053 reported → 0 real, audit/04b — pruned, git history.)

---

## Path-Scoped Rules (`.claude/rules/`)

Učitavaju se SAMO kad radiš na matchujućim fajlovima:

| Fajl | Path scope | Sadržaj |
|------|-----------|---------|
| `cloud-functions.md` | `functions/src/**/*.ts` | Logger, UTC, rate limiting, Sentry, bookingLookup, FieldPath bug |
| `stripe.md` | `functions/src/stripe*.ts`, `lib/**/stripe*`, `lib/**/payment*` | LIVE MODE, checkout flow, webhook, min amount |
| `calendar.md` | `lib/**/calendar/**`, `lib/**/timeline/**` | DateStatus, turnover, fixed dimensions, repository rules |
| `widget.md` | `lib/features/widget/**`, `lib/widget_main*.dart`, `web/bookbed-overlay.js` | URL slugs, subdomene, snackbar boje, iframe overlay |
| `admin.md` | `lib/features/admin/**`, `lib/admin_main*.dart`, `functions/src/admin/**` | Admin panel, Firestore rules, providers |
| `ui-ux.md` | `lib/**/*.dart` | Design system, animacije, dialogs, skeleton loaders |
| `keyboard-fix.md` | `lib/**/presentation/screens/**`, `web/index.html`, `lib/core/utils/keyboard_dismiss*` | Android mixin, 3 koraka za nove forme |
| `hosting-build.md` | `firebase.json`, `.firebaserc`, `web/**`, `.github/workflows/**`, `android/**`, `ios/**`, `pubspec.yaml` | Domene, build commands, deploy targets |
| `firestore.md` | `firestore.rules`, `firestore.indexes.json` | Composite vs single-field, collection group, deploy |
| `fcm-pwa.md` | `lib/core/services/fcm_service*`, `web/firebase-messaging-sw.js`, `functions/src/fcmService.ts`, `lib/**/pwa/**` | Push notifikacije, PWA install, SW |
| `auth.md` | `lib/features/auth/**`, `lib/**/enhanced_auth_provider*`, `functions/src/auth*`, `functions/src/emailVerification*` | Sign-In flows, email verifikacija, Remember Me, provider cache security |
| `ios-development.md` | `ios/**`, `lib/main*.dart`, `lib/widget_main*.dart` | GoogleService-Info.plist swap, `--target` requirement, Dart project-ID asserts |
| `android-development.md` | `android/**`, `lib/main*.dart`, `lib/widget_main*.dart`, `tool/build_aab.sh` | google-services.json swap, debug-build `--release`, AAB blocker fix, 16KB page-size |
| `build-runner.md` | `pubspec.yaml`, `build.yaml`, `analysis_options.yaml`, `**/*.g.dart` | Fresh-clone `--delete-conflicting-outputs`, pub-cache desync distinction |

---

**Last Updated**: 2026-07-10 | **Version**: 7.37

# context-mode — MANDATORY routing rules

You have context-mode MCP tools available. These rules are NOT optional — they protect your context window from flooding. A single unrouted command can dump 56 KB into context and waste the entire session.

## BLOCKED commands — do NOT attempt these

### curl / wget — BLOCKED
Any Bash command containing `curl` or `wget` is intercepted and replaced with an error message. Do NOT retry.
Instead use:
- `ctx_fetch_and_index(url, source)` to fetch and index web pages
- `ctx_execute(language: "javascript", code: "const r = await fetch(...)")` to run HTTP calls in sandbox

### Inline HTTP — BLOCKED
Any Bash command containing `fetch('http`, `requests.get(`, `requests.post(`, `http.get(`, or `http.request(` is intercepted and replaced with an error message. Do NOT retry with Bash.
Instead use:
- `ctx_execute(language, code)` to run HTTP calls in sandbox — only stdout enters context

### WebFetch — BLOCKED
WebFetch calls are denied entirely. The URL is extracted and you are told to use `ctx_fetch_and_index` instead.
Instead use:
- `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` to query the indexed content

## REDIRECTED tools — use sandbox equivalents

### Bash (>20 lines output)
Bash is ONLY for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`, and other short-output commands.
For everything else, use:
- `ctx_batch_execute(commands, queries)` — run multiple commands + search in ONE call
- `ctx_execute(language: "shell", code: "...")` — run in sandbox, only stdout enters context

### Read (for analysis)
If you are reading a file to **Edit** it → Read is correct (Edit needs content in context).
If you are reading to **analyze, explore, or summarize** → use `ctx_execute_file(path, language, code)` instead. Only your printed summary enters context. The raw file content stays in the sandbox.

### Grep (large results)
Grep results can flood context. Use `ctx_execute(language: "shell", code: "grep ...")` to run searches in sandbox. Only your printed summary enters context.

## Tool selection hierarchy

1. **GATHER**: `ctx_batch_execute(commands, queries)` — Primary tool. Runs all commands, auto-indexes output, returns search results. ONE call replaces 30+ individual calls.
2. **FOLLOW-UP**: `ctx_search(queries: ["q1", "q2", ...])` — Query indexed content. Pass ALL questions as array in ONE call.
3. **PROCESSING**: `ctx_execute(language, code)` | `ctx_execute_file(path, language, code)` — Sandbox execution. Only stdout enters context.
4. **WEB**: `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` — Fetch, chunk, index, query. Raw HTML never enters context.
5. **INDEX**: `ctx_index(content, source)` — Store content in FTS5 knowledge base for later search.

## Subagent routing

When spawning subagents (Agent/Task tool), the routing block is automatically injected into their prompt. Bash-type subagents are upgraded to general-purpose so they have access to MCP tools. You do NOT need to manually instruct subagents about context-mode.

## Output constraints

- Keep responses under 500 words.
- Write artifacts (code, configs, PRDs) to FILES — never return them as inline text. Return only: file path + 1-line description.
- When indexing content, use descriptive source labels so others can `ctx_search(source: "label")` later.

## ctx commands

| Command | Action |
|---------|--------|
| `ctx stats` | Call the `ctx_stats` MCP tool and display the full output verbatim |
| `ctx doctor` | Call the `ctx_doctor` MCP tool, run the returned shell command, display as checklist |
| `ctx upgrade` | Call the `ctx_upgrade` MCP tool, run the returned shell command, display as checklist |
