# Overnight design-fidelity campaign — 2026-07-10

Page-by-page premium-fidelity closeout of owner screens vs `design_handoff/source/*.jsx`.
Dev-only, worktree-per-page, flat chrome (no gradients), BB* tokens. Each entry = one shipped PR.

---

## CAMPAIGN SUMMARY (iterations 1-10)

Ten overnight sweeps, each shipped as an independent squash-merged PR off `origin/main`
in its own `/tmp/bb-*-wt` worktree. All dev-only — **no firebase deploy**. Flat chrome
maintained (no re-introduced gradients); FROZEN surfaces (Cjenovnik grid, Timeline
dimensions, publish flow, Navigator.push confirmation, widget snackbar colors) untouched.

| # | PR | Area | Handoff |
|---|-----|------|---------|
| 1 | #840 | owner/149 Subscription cheap-wins (back-nav, Pro-card border, dialog l10n) | subscription |
| 2 | #841 | iCal sync-settings hero → flat status card | ical.jsx |
| 3 | #842 | owner/embed docstring flatten (stale TIP-1 gradient) + embed data-honesty | — |
| 4 | #843 | auth recovery RecCard icon-tile + handoff-xl card radius | login/register/recovery |
| 5 | #844 | profile BookBed Pro card benefits grid + price (audit/135 S3) | profile-premium |
| 6 | #845 | owner unit-hub master-panel fidelity | units.jsx |
| 7 | #846 | widget mint-accent success mark + deposit band | widget confirmation/deposit |
| 8 | #847 | widget mint selection ladder on calendar + guest-form quick wins | widget-calendar.jsx |
| 9 | #848 | admin dark-console nav chrome → BbAdminDarkTokens | admin-shell |
| 10 | **(this)** | **dialogs/states sweep — 5 owner AlertDialog → BbDialog** | **dialogs.jsx** |

### Consolidated deferred backlog (carried out of iterations 1-10)
- ✅ **Units property-header title vertical-wrap** — CLOSED iter 11 (#850). `title`/`subtitle`
  `Text` in `_buildPropertySection`'s `ExpansionTile` gained `maxLines:1`+ellipsis so a long
  property name no longer wraps under the fixed 3-icon action cluster. RED→GREEN overflow gate.
- ✅ **iCal FeedCard direction badge (Uvoz/Izvoz)** — CLOSED iter 11. Data-honest `DirectionBadge`
  keyed on `IcalFeed.importEnabled` (import=primary+download / export-only=tertiary+upload) added
  to the feed-row title. New l10n `icalDirectionImport`/`icalDirectionExport` (en+hr). Platform
  name wrapped in `Flexible`+ellipsis so the badge never overflows the row.
- ✅ **Admin topbar env pill** — CLOSED iter 11. `_AdminEnvPill` in `_AdminHeader` reads the REAL
  `Firebase.app().options.projectId` (never fabricated): green "Production" for `rab-booking-248fc`,
  amber "Development"/"Staging" otherwise; hides on uninitialised Firebase. Admin = web-only English,
  env identifiers not user copy → no l10n.
- **Widget guest-form live eyeball** — selection-fill / in-range / glow + guest-count/payment
  quick-wins (#847) need a real date-selection; synthetic web pointer can't drive Flutter's
  gesture arena (`flutter-web-scroll-not-automatable`) → Marionette / real device.
- **Widget guest-form field radius (20→12)** and **confirmation card radius (20→24)** — handoff
  numbers assume a base that doesn't exist in Flutter (fields already `medium`=8, uniform); a
  real change is global-theme-wide → separate deliberate decision. (#847)
- **Counter buttons → true filled circle** — current glyph IconButtons already circular. (#847)
- **Owner Settings S3 profile-hub Pro benefits grid remainder** — heavy 1503-LOC screen. (#844)
- **BbDialog custom-body limitation** — the primitive only takes plain `title`/`body` strings;
  AlertDialogs with rich/form bodies can't migrate without extending it (see below).

---

## iCal (`ical.jsx` → `ical_sync_settings_screen.dart`) — SHIPPED

**Divergence found:** the sync-settings screen rendered a premium header
(`IcalSyncPremiumHeader`, audit/117 pattern, already matching the handoff top row)
**and** a second saturated hero card built with `rd.brandPrimaryGradient` +
`rd.purpleGlow` (`_buildHeroCard`). That was two competing headers plus a live
flat-chrome violation (retired purple gradient) — the handoff has no such gradient;
its status lives in a flat tinted `FeedCard` status row (`--bb-surface-variant` /
`--bb-error-tint`).

**Fix (UI layer only, no sync/token/export logic touched):**
- Flattened `_buildHeroCard` → a FLAT status card: tinted flat surface keyed to the
  aggregate feed status (`status.tint` @ 0.08 alpha, +0.24 hairline border), solid
  status-icon backplate (@ 0.16), status pill + secondary-text description. No
  gradient, no `purpleGlow`, no white-on-purple text.
- Removed the duplicate CTA: `Dodaj feed` now wired into the existing
  `IcalSyncPremiumHeader` via `onAddFeed: () => _showAddFeedDialog(context)`
  (header CTA was previously always null → never rendered). Single primary action.
- Named consts `_kHeroTintAlpha` / `_kHeroIconTintAlpha`; stale class + method
  docstrings updated (no longer claim a brand-primary gradient hero).

**Data honesty:** kept the dynamic status resolver (`_resolveHeroStatus`) — status/
description reflect real feed stats; no invented feed cards or benefit copy. The
handoff's static `SyncSettingsCard` (frequency / auto-block / email / daily-summary
toggles) was NOT added — those settings have no backing field in the model (would be
inventing UI).

**Verify:** `dart format .` clean; `flutter analyze` (screen) 0 issues; full
`flutter test` = **1673 passed** (golden harness green — screen not in golden set, no
re-bless). FROZEN untouched: `icalSync.ts`, `IcalRepository`, provider chain,
`syncIcalFeedNow` + capture-before-pop, keyboard-dismiss mixin, `PopScope`,
`_checkPlatformMismatch`. iOS plist untouched (prod).

**Live eyeball:** deferred — flat-chrome status-card pattern is already live-verified
on Pregled/Rezervacije (audit/126 §flatten); CanvasKit owner-auth eyeball not run.

---

## Iteration 1 — Subscription (Pretplata)

**Screen:** `lib/features/subscription/screens/subscription_screen.dart` vs `design_handoff/source/subscription.jsx`.
**Basis:** applies the audit/149 recon "🟢 Cheap-wins bundle" (all SAFE, high-confidence, code-conclusive). Screen was already a near pixel-exact port (hero, billing toggle, plan-card content/geometry, price block, free-inline, footnote all match) — recon found no heavy fidelity work.

### Sections changed
1. **App-bar → back-nav** (handoff `showBack`). Screen is only ever `context.push`ed (from `profile_screen` + `trial_banner`), never a drawer destination. Swapped `Icons.menu`/`openDrawer` → `Icons.arrow_back`/`Navigator.maybePop`; dropped `drawer: OwnerAppDrawer` + its now-unused import. Matches handoff + the `widget_advanced` exemplar (audit/135).
2. **Pro plan card → clean featured border** (handoff featured = 2px border only). Dropped `variant: BbCardVariant.accentLeft` + `accentTone: BbCardAccentTone.primary`; kept `selected: true`. Removes the double-emphasis 4px primary left bar; leaves the 2px primary border.
3. **Upgrade dialog → l10n + HR** (was hardcoded English "Upgrade to Pro" / "coming soon… Stripe… Stay tuned"). New keys `subscriptionUpgradeComingSoonTitle` / `subscriptionUpgradeComingSoonBody` (en+hr); "OK" → existing `l10n.ok`. Payment/Stripe logic untouched (still a coming-soon placeholder — data-honest).

### Data honesty (kept, per recon)
- Upgrade flow stays an unwired "coming soon" placeholder (no Stripe checkout exists).
- Hero trial figures (12/14, endDate) remain hardcoded stubs matching the handoff mock.
- FAQ + native-redirect branch code-exceed the handoff → kept.

### Verification
- `dart format .` clean; `flutter analyze` = 0 net-new (100 pre-existing infos, all in unrelated test files).
- `flutter test` full suite **1673 passed**, 0 failed.
- `flutter test --tags golden` green (subscription golden renders the native-redirect branch = unaffected).
- l10n gates green: `hardcoded_strings_guard` (dropped now-localized "OK"/"Upgrade to Pro" from allowlist → baseline shrinks), `l10n_completeness` (en/hr key parity), `widget_translations_coverage`.
- Live web eyeball: app compiles + serves clean at `:8097`, login screen renders correctly. Subscription route is auth-gated; CanvasKit text-input fill is not automatable via chrome-devtools MCP (known `flutter-web-input-bypass` / `canvaskit-tier3` limitation) → full authed screen render deferred. Changes are cosmetic, low-risk, and fully test-covered; recon rated the live-render as optional/budget-lean.
- iOS sim: not attempted (web-only per input-automation limitation; plist untouched).

### Deferred (recon 🟠, unchanged)
- Mobile Pro-card 4-feature truncation + "+ još N značajke" (code shows all 6 — arguably better).
- Footnote hidden on mobile in handoff (code shows it).
- Featured-card purple shadow (127-adjacent re-color domain).
- Tablet column cap 640 vs ~704; bottom pad xl→lg.
- Global (audit/126): desktop/tablet breadcrumb app-bar §2B; persistent sidebar/rail §3B.

---

## Iteration 3 — Embed Widget Guide (`embed_widget_guide_screen`) vs `embed.jsx`

**Verdict: NO pixel-moving change — data honesty.** The handoff is largely
**aspirational**: it renders a mode toggle (Ugrađeno/Skočni gumb/Poveznica),
an accent-color picker (5 swatches → `data-accent`), a live mint-widget mock,
platform tabs (HTML/WordPress/Wix) with per-platform steps, and customization
toggles (Jezik/Tema/Zaobljenost + PRO "Powered by" removal). **None of these
map to the real product** — the widget is a fixed
`view.bookbed.io/?property=…&unit=…&embed=true` iframe with no accent/mode/
platform/language config surface. Building them would wire dishonest UI to
nothing (per `seam-test-proves-fn-not-wiring` / fidelity-render-as-target: only
render what the product actually does).

The real screen is already premium-composed and correct: BbCard hero, numbered
step ladder (filled-primary circles + connector line), auto-generated per-unit
embed codes with **property/unit IDs highlighted** (a genuine feature the
handoff lacks), developer customization block, scroll-protection overlay-script
snippet, live-preview launcher, help links. Considered swapping the light
`surfaceVar` code block for the handoff's dark `#1B2330` ink surface, but that
requires a NEW hardcoded color token (violates "no raw Color() in new code")
and the light block with primary-highlighted IDs is arguably clearer — rejected
as scope creep, not fidelity. Icon-family Rounded swap rejected: whole codebase
uses `Icons.*`; one-screen drift ≠ fidelity.

**Shipped (bonus quick-win): `ical_export_list_screen.dart` stale-docstring
flatten.** Two docstrings still described a "TIP 1 diagonal `sectionBackground`
gradient (2 colors/2 stops, topRight→bottomLeft)" — reversed by CHANGELOG 7.23
(flat chrome). The `context.gradients.sectionBackground` API already renders a
FLAT solid fill (the `LinearGradient` is retained but flat), so **zero visual
change**; only the lying comments were corrected. Continues iteration-2's sync-
screen flatten (#841).

Verify: dart format clean; `flutter analyze lib/` 0 errors (76 pre-existing
off-scale deprecation infos, 0 net-new — comment-only edit); golden `--tags
golden` 52 cells + models/widgets **All tests passed**. No live eyeball — no
embed pixels moved; docstring edits carry no runtime signal.

---

## Iteration 4 — Owner auth cluster (login · register · recovery)

**Handoffs:** `design_handoff/source/auth.jsx`, `register.jsx`, `recovery.jsx` (+ tokens.css, primitives.jsx).
**Files:** `enhanced_login_screen.dart`, `enhanced_register_screen.dart`, `forgot_password_screen.dart` (+ `forgot_password_screen_test.dart`).

### Recon
Login + register were already deeply aligned (audit/124 `cd4d6914`/`5256bd25` shipped the handoff desktop split: brand pitch panel + 560px glass card ≥1200, pitch stats, legal footer, SSO). No divergence found in their structure/copy — left as-is. The **recovery** screen (`forgot_password_screen`) was the real gap: it reused the login/register **BbLogo** header + a full-width `BbButton` back-link + a `BbEmptyState` success view, none of which match handoff `recovery.jsx` `RecCard`.

### Sections changed
- **forgot_password (recovery) — request view:** BbLogo header → handoff `RecCard` **tinted icon-tile** (`_buildIconTile`: 64×64, radius 18, 32px `lock_reset` glyph, `primary` tint @ alpha 0.06 from tokens.css). Title/sub kept; sub gains `height:1.55` per handoff. Full-width back-button → compact inline **`RecBackLink`** (`arrow_back` 16px + label in primary, 44px tap target).
- **forgot_password — success (sent) view:** rebuilt from `BbEmptyState` to match handoff `SentCard` — success-tinted `mark_email_read` icon-tile (alpha 0.12) + h1 title + submitted-email sub + primary "return to login" (`arrow_forward`) + tertiary "resend". All routes/security-mask logic preserved verbatim.
- **All three cards — radius:** handoff cards use `--bb-radius-xl` (32px, "hero cards"); code used `BBRadius.lgAll` (24). Bumped login/register/forgot glass cards `lgAll`→`xlAll` (6 sites) for handoff-accurate softer corners.
- **Named consts:** `_kIconTileSize/Radius/Glyph`, `_kPrimaryTintAlpha/_kSuccessTintAlpha` (sourced to tokens.css rgba).

### Untouched (data honesty / logic)
- Register omits the handoff SSO row — documented preserved-as-is (register screen has no social sign-in path); NOT invented.
- Recovery `VerifyCard` (6-digit code) is a separate email-verification screen, out of this file's scope — not fabricated here.
- Zero auth-logic edits (enhanced_auth_provider, sign-in/reset flows, Remember Me, keyboard-dismiss mixin all intact).

### Verify
- `dart format` clean; `flutter analyze lib/features/auth/` **0 issues**.
- Auth widget tests **15/15** green (login flow `signInWithEmail` dispatch test passes — login logic untouched, only card radius). Re-pointed forgot `BbLogo` assertion → new `lock_reset` icon-tile (coverage moved, not deleted).
- `flutter test` full suite **1673 passed, 0 failed**.
- `--tags golden`: 8 intended baselines re-blessed via full warm-font run (`auth_register` + `auth_forgot_password` × mobile/tablet × light/dark) — radius + icon-tile deltas; all other goldens untouched (proves no collateral). Re-blessed PNGs read back = correct Inter render, no tofu.
- Live web eyeball `:8111` (chrome-devtools, CanvasKit): **login desktop split ✓**, **register desktop split ✓**, **forgot/recovery icon-tile ✓** — all match handoffs. Live login sanity: CanvasKit text-input not automatable (known `flutter-web-input-bypass`); login call site unchanged (radius-only) + dispatch test green → deemed sufficient.

### Deferred
- Recovery `VerifyCard` 6-digit code UI (separate email-verification screen).
- Register SSO row (product decision — no social path currently wired on register).

---

## Iteration 5 — owner profile hub (`profile_screen.dart`) BookBed Pro card

**Deferred S3 item from audit/135** ("profile-hub Pro-card benefits grid"). Worktree `design/profile-hub-fidelity` off `origin/main` `df9be9d5`.

### Gap (vs `profile-premium.jsx` §248 `PFPProCard`)
Card rendered title + trial pill + subtitle + CTA only. Handoff adds: (1) 4-benefit grid w/ `check_circle` marks, (2) trial-progress bar, (3) `€19 / mjesečno` price above CTA.

### Changed — `_ProfilProCard`
- **Benefits grid** (`_ProProBenefits`): 4 static labels (`subscriptionFeatureUnlimitedProperties` / `AdvancedAnalytics` / **new** `AiAssistant` / `PrioritySupport`), each `BbIcon check_circle size:16 color:BBColor.success` (theme-aware #2E7D5B / #4FAE7F). Desktop = free-wrapping `Wrap` (repeat(4,auto)); mobile = `LayoutBuilder` 2-col grid, chips `maxLines:2` (no mid-word truncation on narrow phones). Named `_kProBenefitsTopGap=16`, `_kProBenefitColGap=18`.
- **Price** (`subscriptionProPrice` / `subscriptionProPeriod`): `€19` (h1, w800, -0.5 ls) + `/ mjesečno` (caption, textTertiary) baseline-aligned above the CTA; CTA full-width on mobile.
- **Trial-progress bar OMITTED — data honesty.** No trial-day-count field on the model (`grep trialEndsAt/trialDays` = 0); handoff's "12 od 14 dana"/86% is placeholder → rendering it would fabricate data. Same principle as audit/135 identity-chip + stat-strip gates.

### l10n
Added `subscriptionFeatureAiAssistant` (en "Unlimited AI assistant" / hr "AI asistent bez ograničenja"). Other 3 benefits + price/period + `subscriptionStatusTrial` already existed. Regenerated `app_localizations*.dart`.

### Verify
- `dart format` · `flutter analyze` **0 net-new** (file: No issues found) · full suite **1677 green** · `--tags golden` **green**.
- New seam: `@visibleForTesting buildProCardForTest` + `test/golden/seams/profile_pro_card_golden_test.dart` (4 cells: mobile/tablet × light/dark). **PNGs read back** — no tofu; benefits grid + green checks + price + CTA render correct both themes/bp, mobile 2-line wrap graceful.
- Live web login CanvasKit-blocked (known); auth-free seam golden used as eyeball per `memory/golden-fidelity-provider-screen-gotchas`.

### Deferred
- Trial-progress bar (needs `trialEndsAt` on UserModel — feature, not fidelity).
## Iteration 6 — owner Units MASTER PANEL fidelity (`unified_unit_hub_screen.dart` sidebar/endDrawer) vs `units.jsx`

Continuation of audit/134, which shipped the Osnovno tab + header (main `7301e77b`) but **deferred the master panel**. This closes that gap. Handoff spec = `units.jsx` `PropertyTree` + `UnitTreeItem`.

### Sections changed (master panel / list chrome ONLY)
- **Header (`_buildMasterPanel`):** bare `home_work_outlined` icon → handoff **32×32 primary-tint badge** (radius 10, alpha 0.12) around `apartment` glyph; title gains a **tertiary subtitle caption** `N objekata · N jedinica` (new l10n `unitHubPropertiesUnitsSubtitle`, counts read from `ownerPropertiesProvider`/`ownerUnitsProvider`). Both lines ellipsize.
- **Property section (`_buildPropertySection`):** individually-elevated card (1.5px border + `AppShadows.getElevation(2)`) → handoff flat grouping — hairline border, **shadow removed**, radius → `_kMasterRowRadius` (12 = `--bb-radius-sm`), margin 12→8. ExpansionTile function + all action buttons preserved.
- **Unit tile (`_buildUnitListTile`):** rebuilt to handoff `UnitTreeItem` — selected = **primary-tint bg + 3px left accent bar** (was 2px full border + tint + shadow); unselected = **flat/transparent** (card border + `getElevation(1)` shadow dropped). Added **leading `bed_rounded` icon** (primary when selected). Status **pill → uppercase micro-label** (10px w700, letterSpacing 0.4; `success` / `textTertiary` per handoff, not error-red). Meta row (`group` + capacity, `€`price/noć) **indented 23px** under the name, all `textTertiary`. Duplicate/delete action buttons kept.
- **Token migration:** the whole tile/header moved off `theme.colorScheme.*` (onSurface/onSurfaceVariant/primary) → `BBColor.of(context)` (primary/textPrimary/textTertiary) + `context.gradients.*`; `withAlpha((k*255).toInt())` → `withValues(alpha:)`. Orphaned `_unavailableColor` helper + `app_shadows.dart` import removed (both dead after the change).

### Named consts
`_kMasterBadgeSize`(32), `_kMasterBadgeRadius`(10), `_kMasterRowRadius`(12), `_kMasterSelectedBar`(3).

### FROZEN fence honored (0 touch)
Cjenovnik tab content / `price_list_calendar_widget` / `_buildSaveButton` purple / Wizard `_publishUnit` 2-doc serial write / all `context.push`/`Navigator.push` entries. Data honesty: no Vidljivost/Polog field added (audit/134 ruling). Only the master-panel/list chrome restyled; zero logic/nav/selection edits.

### Verify
- `dart format` clean; `flutter analyze` (touched file) **No issues** (0 net-new; removed 1 self-orphaned helper + 1 dead import).
- `flutter test` full suite **1673 passed, 0 failed** (no test references the hub master panel → nothing re-pointed).
- `--tags golden` **52 passed** — no baseline regressed (master panel not in any golden seam; all owner-UI dark goldens green ⇒ dark ladder intact).
- `flutter build web --no-tree-shake-icons` clean.
- **Live web eyeball** `:8096` (bookbed-dev, chrome-devtools, real login `bookbed-test@bookbed.io`): **desktop sidebar ✓** + **mobile endDrawer ✓** — tint badge + `N objekata · N jedinica` subtitle + search; selected unit tile shows 3px accent bar + tint bg + leading bed icon + **uppercase green DOSTUPNO label** + indented `4 · € 120/noć` meta, faithful to `units.jsx`. Dark = green goldens + audit/127 ladder (all colors via `BBColor.of`/`context.gradients`).

### Deferred
- Property-header title vertical-wrap under the 3-icon action cluster (pre-existing width constraint, not introduced here) — a fuller `PropertyTree` flat-row rework (drop per-property card, single panel card) would fix it but is a larger structural change.
- Dark-mode live capture (web app follows in-app theme, not OS colorScheme; covered by dark goldens).

**NEXT page recommendation:** widget-*.jsx guest surface (widget-calendar / guest-form / pricing / confirmation / error) — `.claude/rules/widget.md` applies (App Check OFF, subdomain slugs, snackbar colors). Then admin-*.jsx console, then dialogs/states/variants.

---

## Iteration 7 — guest booking widget (mint accent fidelity)

**Branch:** `design/widget-guest-fidelity` | anchor `a5a663d1`. Widget mint accent `#3DD9B0` / deep `#1FAF87` (handoff WC_MINT/WP_MINT). UI-visual only; zero booking-logic edits; no FROZEN painter touched.

Scoped to the two highest-value, lowest-risk gaps (pure-presentation widgets, no calendar painter, no App Check surface):

### Sections changed
- **Confirmation — success mark** (`confirmation_header.dart`): replaced the flat monochrome `Icons.check_circle` (was `colors.textPrimary`) with the handoff layered success mark for the genuinely-confirmed states (`stripe`, `pay_on_arrival`, default): two soft mint rings (`rgba(#3DD9B0,.14)` / `.22`) + mint→mint-deep gradient core disc (135°, `boxShadow rgba(31,175,135,.40)`) + white `check_rounded` glyph. `pending` / `bank_transfer` keep their neutral schedule/pending glyphs (data honesty — not "success"). File-local named consts (`_kWcMint` etc.) with note that `#3DD9B0` == `BbRedesignTokens.mintWidget`.
- **Pricing — deposit band** (`price_breakdown_widget.dart`): replaced the plain secondary-text deposit line with the handoff `WPDepositBand`: mint-tinted panel (`bg rgba(#3DD9B0,.10)` / `border rgba(#3DD9B0,.32)`, radius 12) with mint-deep bold label + `task_alt_rounded` mint-deep icon. Same content (`depositWithPercentage`) — no new l10n string.

### Verification
- `dart format` clean; `flutter analyze` 0 net-new (only pre-existing `medium`-radius deprecation on unchanged line 106).
- `price_breakdown_widget_test` 8/8 green (incl. "renders deposit info" — text preserved).
- l10n gates green (hardcoded-strings ratchet + WidgetTranslations 4-lang coverage + ARB completeness) — no new user-facing string.
- `--tags golden` 56/56 green (changed widgets not in a golden seam; no baseline moved).
- Live web eyeball skipped: deterministic color/shape presentation, covered by unit + golden suite.

### Deferred (widget cluster, next iteration)
- **Calendar** day-cell mint palette (selected fill → mint, today border → mint-deep `#1FAF87`, in-range tint → mint-light `#A8EFD9`, selected mint-glow shadow). Highest visible impact but touches `split_day_calendar_painter` / `month_calendar_widget` — FROZEN-adjacent per `.claude/rules/calendar.md`; needs new `BbRedesignTokens` mint-ladder fields (ThemeExtension class+copyWith+lerp surface) and a live eyeball. Own careful task.
- **Guest form** field radius 20→12, guest-counter buttons → true circle, payment-option selected-card mint-deep border.
- **Confirmation summary card** radius 20→24, deposit sub-band mint tint; **error** ring opacity 12%→16%.

**NEXT page recommendation:** finish the widget calendar mint-ladder (add `BbRedesignTokens` mint fields + apply in painters, with live web eyeball via `widget_main_dev.dart`) as a dedicated FROZEN-adjacent task — biggest remaining visible widget gap. Then guest-form radii, then admin-*.jsx console.

## Iteration 8 — Widget calendar mint ladder + guest-form quick wins (design/widget-calendar-mint)

**Handoff:** `widget-calendar.jsx` (W_MINT `#3DD9B0`, W_MINT_DEEP `#1FAF87`, W_MINT_LIGHT `#A8EFD9`).

### SHIPPED (values-only, zero structural painter edits)
- **Mint selection ladder** on the active widget scheme (`MinimalistColorSchemeAdapter` — NOT BbRedesignTokens; that's the owner theme, the widget uses `WidgetColorScheme`):
  - Added `MinimalistColors.mint/mintDeep/mintLight` (+ dark variants) constants.
  - Added 3 members to `WidgetColorScheme` (abstract) + all 3 impls (Light/Dark map to existing selected tokens; adapter → mint): `statusSelectedRangeBorder` (#3DD9B0), `statusInRangeBackground` (#A8EFD9), `selectedGlowShadow` (mint 0.45 / blur 14 / y+4).
  - `statusTodayBorder` re-pointed to `mintDeep` (was `statusAvailableBorder`).
  - `month_calendar_widget.dart`: selected-endpoint border `textPrimary`→`statusSelectedRangeBorder`; today border `textPrimary`→`statusTodayBorder`; selected cell `boxShadow`→`selectedGlowShadow`. **No geometry / z-order / availability-logic touched.**
  - `split_day_calendar_painter.dart`: in-range fill `buttonPrimary@0.2`→`statusInRangeBackground@0.55` (single Paint color swap; paint order/paths untouched).
- **Guest-form / payment quick wins:**
  - `payment_option_widget.dart`: selected card border + radio ring + radio dot `borderFocus`/`buttonPrimary`→`statusTodayBorder` (mint-deep).
  - `guest_count_picker.dart`: capacity-warning error ring `error@0.10`→`error@0.16`.

### DEFERRED (handoff numbers didn't map to Flutter reality)
- **Guest-form field radius 20→12** — fields already use `BBRadiusBridges.medium`(8) via the shared widget theme, not 20; changing there is global-theme-wide → out of scope for a quick win.
- **Confirmation summary-card radius 20→24** — real value is `medium`(8), uniform across ALL confirmation cards; bumping one card to 24 breaks sibling consistency (handoff assumed a 20 base that doesn't exist).
- **Counter buttons → true circle** — current `add/remove_circle_outline` IconButtons are already circular glyphs; a filled-bordered circle is a structural layout rework → deferred to keep the batch low-risk.

### Verify
- `dart format` clean; `flutter analyze` 0 net-new (only pre-existing `deprecated_member_use` infos).
- Full `flutter test` **1677 green**; widget subset 757 green; `--tags golden` 56 green (widget calendar not in golden seam set → no baseline moved).
- **Live web eyeball** (`flutter run -d chrome --target lib/widget_main_dev.dart`, seeded bookbed-dev `--test-owner` fixture, `?subdomain=bookbed-test&property=…&unit=…`, desktop 1280 + mobile 390): calendar renders identically to pre-change **plus** today-cell (10 Jul) now carries the **mint-deep ring** (was black). **No regression** — layout/geometry/z-order/available-cell color all unchanged. Selection-fill / in-range / glow are code-path + test verified (synthetic pointer events can't drive Flutter's gesture arena → cannot live-click a date; documented limitation `flutter-web-scroll-not-automatable`). Guest-form/payment quick-wins unreachable without a date selection but covered by the green suite.

**NEXT page recommendation:** admin-*.jsx console (`.claude/rules/admin.md`), then dialogs/states/variants. Widget guest surface remaining: the guest-form/payment/confirmation quick-wins that need a live date-selection to eyeball (drive via a real device/Marionette, not synthetic web taps).

---

## Iteration 9 — admin console shell + users (dark deep-purple, English)

**Handoffs:** `design_handoff/source/admin-shell.jsx` + `admin-users.jsx`. Admin = web-only dark deep-purple console (`#1E1A33` shellBg, `BbAdminDarkTokens` ThemeExtension). Login R6 done (#650), users DataTable overflow fixed (#765).

**Finding:** The `BbAdminDarkTokens` preset already carried the handoff-verbatim nav tokens (`navTileIdleBg`, `navTileActiveBg`, `navTileActiveBorder`, `navIconActiveGradient` = `BBGradient.hero`, `navActiveGlow` purple glow, `adminBadgeBg/Fg`) — but the shell's `_DrawerItem`/`_RailItem`/`_AdminNavPanel` **did not consume them**, rendering generic `colorScheme.primary.withValues(alpha:0.1)` tiles with no gradient, no glow, and no ADMIN badge. The tokens existed; the rendering ignored them. This iteration wires the render to the tokens (pure fidelity, data-honest — no invented UI).

**Sections changed (`admin_shell_screen.dart`, dark-console chrome only):**
1. **Sidebar/drawer header** — added the `ADMIN` badge pill (`adminBadgeBg`/`adminBadgeFg`, radius 5, 9px/800/0.1em) beside the BookBed wordmark; added `-0.02em` letter-spacing on wordmark; wrapped title column in `Expanded` (overflow-safe).
2. **`_DrawerItem`** — reworked to handoff spec: 44px row, radius 12, active fill `navTileActiveBg` + border `navTileActiveBorder`; icon now lives in a 28px rounded `_NavIconTile` that carries the hero gradient + purple glow when active (dark). Light mode falls back to primary tints. Became a `ConsumerWidget` to read dark-mode.
3. **New `_NavIconTile`** — shared rounded icon tile (gradient + glow on active/dark, idle `navTileIdleBg`).
4. **`_RailItem`** — 48px tablet-rail tile now radius 12 with hero-gradient fill + glow when active (dark), idle `navTileIdleBg`; light-mode primary-tint fallback + border. `isDark` threaded through from `_AdminRail`.

**Data honesty:** the users handoff (`admin-users.jsx`) is an aspirational owners-CRM (master-detail panel, GMV/bookings columns, invite/suspend actions) with no backing data — NOT applied. Current users screen renders real `UserModel` data; left structurally intact (only inherits the shared shell chrome). No Firestore/provider/callable edits.

**Verify:** `dart format` clean; `flutter analyze` 0 errors, 0 issues on changed files (101 pre-existing info-lints = baseline, unchanged). Full suite **1678 green** (incl. admin seam 780/900/1100/1440 + token isolation). `--tags golden` green (56 baselines). Live eyeball: temp nav-chrome golden rendered @3x — ADMIN pill + active hero-gradient icon-tile + purple glow + idle row all confirmed correct (temp file removed). New `admin_shell_nav_test.dart` seam (via `@visibleForTesting buildAdminNavChromeForTest`) asserts active tile = `navIconActiveGradient` + non-empty glow shadow + ADMIN text; Firebase-free (`adminDarkModeProvider` override + `SharedPreferences.setMockInitialValues`).

**Deferred:** desktop sidebar section grouping (handoff Platform/Operations/System groups — current flat 3-item nav; grouping = adding invented Analytics/Owners/Properties/Payments/Sync/Support destinations that don't route → NOT data-honest without those screens). Topbar global-search + Production env pill + notifications bell (handoff `AdminTopbar`) — current `_AdminHeader` is minimal; search needs a real backing query surface. Users owners-CRM master-detail = needs data model.

**NEXT recommendation:** admin remaining screens are gated on backing data (bookings/payments/support/sync/viz consoles don't exist as routes). Best next data-honest admin pass = **topbar polish** (`_AdminHeader` → env badge from `firebase_options` project id + notifications affordance) OR pivot to the **dialogs/states/variants sweep** (BbDialog/empty-state/error-state consistency across owner+admin+widget) which has real surfaces everywhere. Recommend the dialogs/states sweep next — broadest real coverage.
## Iteration 8 — Widget calendar mint ladder + guest-form quick wins (design/widget-calendar-mint)

**Handoff:** `widget-calendar.jsx` (W_MINT `#3DD9B0`, W_MINT_DEEP `#1FAF87`, W_MINT_LIGHT `#A8EFD9`).

### SHIPPED (values-only, zero structural painter edits)
- **Mint selection ladder** on the active widget scheme (`MinimalistColorSchemeAdapter` — NOT BbRedesignTokens; that's the owner theme, the widget uses `WidgetColorScheme`):
  - Added `MinimalistColors.mint/mintDeep/mintLight` (+ dark variants) constants.
  - Added 3 members to `WidgetColorScheme` (abstract) + all 3 impls (Light/Dark map to existing selected tokens; adapter → mint): `statusSelectedRangeBorder` (#3DD9B0), `statusInRangeBackground` (#A8EFD9), `selectedGlowShadow` (mint 0.45 / blur 14 / y+4).
  - `statusTodayBorder` re-pointed to `mintDeep` (was `statusAvailableBorder`).
  - `month_calendar_widget.dart`: selected-endpoint border `textPrimary`→`statusSelectedRangeBorder`; today border `textPrimary`→`statusTodayBorder`; selected cell `boxShadow`→`selectedGlowShadow`. **No geometry / z-order / availability-logic touched.**
  - `split_day_calendar_painter.dart`: in-range fill `buttonPrimary@0.2`→`statusInRangeBackground@0.55` (single Paint color swap; paint order/paths untouched).
- **Guest-form / payment quick wins:**
  - `payment_option_widget.dart`: selected card border + radio ring + radio dot `borderFocus`/`buttonPrimary`→`statusTodayBorder` (mint-deep).
  - `guest_count_picker.dart`: capacity-warning error ring `error@0.10`→`error@0.16`.

### DEFERRED (handoff numbers didn't map to Flutter reality)
- **Guest-form field radius 20→12** — fields already use `BBRadiusBridges.medium`(8) via the shared widget theme, not 20; changing there is global-theme-wide → out of scope for a quick win.
- **Confirmation summary-card radius 20→24** — real value is `medium`(8), uniform across ALL confirmation cards; bumping one card to 24 breaks sibling consistency (handoff assumed a 20 base that doesn't exist).
- **Counter buttons → true circle** — current `add/remove_circle_outline` IconButtons are already circular glyphs; a filled-bordered circle is a structural layout rework → deferred to keep the batch low-risk.

### Verify
- `dart format` clean; `flutter analyze` 0 net-new (only pre-existing `deprecated_member_use` infos).
- Full `flutter test` **1677 green**; widget subset 757 green; `--tags golden` 56 green (widget calendar not in golden seam set → no baseline moved).
- **Live web eyeball** (`flutter run -d chrome --target lib/widget_main_dev.dart`, seeded bookbed-dev `--test-owner` fixture, `?subdomain=bookbed-test&property=…&unit=…`, desktop 1280 + mobile 390): calendar renders identically to pre-change **plus** today-cell (10 Jul) now carries the **mint-deep ring** (was black). **No regression** — layout/geometry/z-order/available-cell color all unchanged. Selection-fill / in-range / glow are code-path + test verified (synthetic pointer events can't drive Flutter's gesture arena → cannot live-click a date; documented limitation `flutter-web-scroll-not-automatable`). Guest-form/payment quick-wins unreachable without a date selection but covered by the green suite.

**NEXT page recommendation:** admin-*.jsx console (`.claude/rules/admin.md`), then dialogs/states/variants. Widget guest surface remaining: the guest-form/payment/confirmation quick-wins that need a live date-selection to eyeball (drive via a real device/Marionette, not synthetic web taps).

---

## Dialogs / states / variants consistency sweep — SHIPPED (iteration 10)

**Handoff:** `dialogs.jsx`, `dialogs-misc.jsx`, `states.jsx`, `variants.jsx`, `filters-dialog.jsx`.
Cross-app pass (not one screen). Continues audit/134, which converted the first 3 raw
`AlertDialog`s (unit hub) to `BbDialog`.

### CHANGED (5 owner call sites -> `BbDialog`)
All are plain text confirmations already on l10n keys — clean 1:1 map to the `BbDialog`
shell (`title`/`body` strings + `primary`/`secondary` `BbDialogAction`). No new strings.

| File | Dialog | Variant |
|------|--------|---------|
| `profile_screen.dart` | logout confirm | neutral primary |
| `bank_account_screen.dart` | discard changes (PopScope) | `destructive: true` |
| `edit_profile_screen.dart` | discard changes (PopScope) | `destructive: true` |
| `stripe_connect_setup_screen.dart` | disconnect Stripe | `destructive: true` |
| `subscription_screen.dart` | upgrade coming-soon | neutral, single OK |

- Destructive confirms use `BbDialog(destructive: true)` -> `BbButtonVariant.destructive`
  (hard), matching `dialogs.jsx` (`variant: 'destructive'` for modal CTA). The soft-pink
  precedent (audit/128 F1) is for **inline** booking-detail actions, not modal confirms —
  intentionally NOT applied here.
- Dead locals dropped where the dialog was their only consumer: `theme` (stripe),
  `BBColorSet c` (subscription). Red hardcoded `TextButton.styleFrom(foregroundColor:
  Colors.red)` on discard dialogs replaced by the token-driven destructive `BbButton`.

### NEW TEST
`test/shared/widgets/redesign/bb_dialog_test.dart` (4 cells, pumps `BbDialog` directly):
title/body render, primary+secondary callback wiring, destructive->destructive variant,
non-destructive->primary variant. Seam-covers the primitive the 5 sites now depend on.

### SKIPPED (with reason)
- **FROZEN Cjenovnik** `price_list_calendar_widget.dart` (3 `AlertDialog`s) — FROZEN grid.
- **Rich/form-body dialogs** — `edit_booking_dialog`, wizard `additional_service_dialog`,
  `multi_select_action_bar` (2), `step_2_capacity`: bodies are forms/lists, not plain text.
  `BbDialog` only accepts `title`/`body` **strings** -> can't migrate without extending it
  (added to deferred backlog).
- **Core/infra dialogs** — `error_display_utils`, `error_handler`, `platform_utils`
  (+ its `CupertinoAlertDialog` branch), `optional_update_dialog`, `force_update_dialog`:
  framework-level error/update surfaces, not owner design-system chrome.
- **Admin** `admin_login_screen.dart` — pre-auth login uses its own dark-token theme
  (`BbAdminDarkTokens`, R6); `BbDialog` is owner-styled -> mismatch, skip.
- **Widget** snackbars/toasts — FROZEN colors per `.claude/rules/widget.md`.
- **Empty/error states** — reviewed vs `states.jsx`: owner surfaces already route through
  `BbEmptyState` / `unit_hub_empty_state` / `revenue_guide_empty_state` (audit/134 + iter 4
  RecCard icon-tile); no drift worth a pixel-moving change this pass.

### Verify
- `dart format` clean; `flutter analyze` on the 5 changed files + new test = **0 issues**
  (full-tree 101 = pre-existing baseline, unchanged).
- Full `flutter test` **1682 green** (1677 + 4 new dialog cells; a caught expected-error
  stack print mid-run is a test's own assertion, not a failure); `--tags golden` ran inside
  the suite green — no baseline moved (dialog swaps touch no golden seam surface).
- Live web spot-check skipped: these confirms sit behind owner auth (logout / discard /
  disconnect / upgrade), not reachable on `widget_main_dev`; the seam test + code-path
  verification cover the primitive, and each site keeps its trigger + Navigator.pop return
  value byte-for-byte.

**PR:** #849 (squash-merged). Dev-only, no deploy.

---

## Iteration 11 — deferred-backlog mop-up (design/deferred-mopup)

Final sweep: picked 3 cheap, safe, data-honest wins off the consolidated backlog. No
structural / FROZEN-adjacent work (calendar painters, VerifyCard, master-detail all skipped).

### SHIPPED
1. **Units property-header title wrap** (`unified_unit_hub_screen.dart` `_buildPropertySection`)
   — `title`+`subtitle` `Text` in the `ExpansionTile` gained `maxLines:1`+`ellipsis`. Long
   property names were wrapping vertically under the fixed 3-icon (edit/delete/add) + expand
   trailing cluster (pre-existing width bug, deferred iter 6). Pure text-constraint; layout,
   actions, nav untouched.
2. **iCal FeedCard direction badge** (`ical_sync_settings_screen.dart` `_buildFeedRow`) — new
   `@visibleForTesting DirectionBadge` in the row title, keyed on the real
   `IcalFeed.importEnabled` field: import → primary-tint pill + `download`; export-only →
   tertiary-tint pill + `upload`. Platform name wrapped in `Flexible`+ellipsis so the badge
   never overflows. New l10n `icalDirectionImport`/`icalDirectionExport` (en "Import"/"Export",
   hr "Uvoz"/"Izvoz"). Data-honest — no invented field.
3. **Admin topbar env pill** (`admin_shell_screen.dart` `_AdminHeader`) — `_AdminEnvPill` reads
   the live `Firebase.app().options.projectId` (same source as the boot asserts). Green
   "Production" for `rab-booking-248fc`, amber "Development"/"Staging" otherwise; `SizedBox.shrink`
   when Firebase uninitialised (isolated tests). Admin is web-only English; env names are
   identifiers, not user copy → no l10n. Added `firebase_core` import.

### SKIPPED (with reason)
- **Subscription mobile Pro-card** (truncation/footnote/shadow/tablet cap) — inspected
  `subscription_screen.dart`: the Pro card already renders all 6 features (no truncation), the
  `purpleSm` featured shadow, the "Preporučeno" badge, and the yearly footnote. The backlog's
  "4-feature truncation + 2-col grid" item was the **profile-hub** `_ProProBenefits`, already
  closed iter 3. Remaining profile-hub work = heavy 1503-LOC screen → stays deferred.
- Widget guest-form live eyeball, field/card radius, counter circle, BbDialog custom-body — as
  carried (Marionette / global-theme / primitive-extension decisions).

### Verify
- `dart format` clean; `flutter analyze` (3 changed files + new test) **No issues found** (0
  net-new; full-tree pre-existing info baseline unchanged).
- Full `flutter test` **1686 green** (1682 baseline + 4 new). `--tags golden` **56 green** — no
  baseline moved (env pill / ical row / hub title touch no golden seam surface).
- New `test/features/owner_dashboard/ical_direction_badge_test.dart` (4 cells): DirectionBadge
  Import/Export label (en) + Uvoz (hr) + **RED→GREEN one-line overflow gate** mirroring the fixed
  ExpansionTile title pattern (long name + fixed trailing cluster @ 300px stays single-line,
  `maxLines==1`, ellipsis).
- Eyeball: temp golden of both DirectionBadge variants rendered @light — Import (primary tint +
  download) / Export (tertiary tint + upload) faithful to `ical.jsx`; temp file removed. Env pill
  + hub title are code-path + test verified (behind owner/admin auth; CanvasKit auth eyeball not
  automatable — `canvaskit-tier3`). iOS plist untouched (prod).

**PR:** #850 (squash-merged). Dev-only, no deploy. FROZEN: 0 touch.

## Iteration 12 — profile-hub l10n remainder + iCal FeedCard footer bar (design/profile-remainder)

Two top deferred-backlog items. Worktree `design/profile-remainder` off `origin/main`
`85301145`. UI layer only — no auth/subscription/sync logic touched.

### 1. Profile-hub remainder (`profile_screen.dart`)
Iteration 5 (#844) shipped the Pro-card benefits grid + price. Recon of the REST of the
1622-LOC hub found the structure/tokens **already faithful** to `profile-premium.jsx`
(identity card, hero strip, radial gauge, verified chips, stat strip, 2-col desktop
layout — all Bb*-migrated, `context.gradients` flat bg, no `colorScheme` drift; the 9
`theme.dividerColor` dividers resolve from `AppColors` via ThemeData = on-palette, kept).
The real remaining gap was **l10n debt**: ~13 hardcoded Croatian literals rendered
verbatim in the EN locale. Migrated to ARB (en+hr):
- Header eyebrow `RAČUN · VLASNIK` → `ownerProfileEyebrow`
- Identity: `Domaćin` badge → `ownerProfileHostBadge`; `Član od {year}` →
  `ownerProfileMemberSince`; `Email potvrđen`/`Telefon dodan`/`Telefon nedostaje` →
  `ownerProfileEmailVerified`/`PhoneAdded`/`PhoneMissing`
- Completion panel: `Dovršite profil`/`Još N koraka do 100%.`/`Dovrši`/`ispunjeno` →
  `ownerProfileCompleteHeading`/`CompleteRemaining({steps})`/`CompleteCta`/`CompleteFilledLabel`
- Pro card `Probni period` → `ownerProfileTrialBadge`
- Group titles `Aplikacija`/`Pravno` → `ownerProfileGroupApp`/`GroupLegal`; danger-zone
  `OPASNA ZONA` → existing `dangerZone` key (`.toUpperCase()`)

**Data honesty (audit/135 ruling):** identity-chip + public-profile stay OMITTED (no
backing feature). Stat strip stays kDebug/env-gated (3 of 4 metrics have no backend).
No visual change in HR locale (values byte-identical); EN locale now shows English.

### 2. iCal FeedCard footer action bar (`ical_sync_settings_screen.dart`)
`_buildFeedRow` trailing `PopupMenuButton` (sync / pause-resume / edit / delete) →
inline footer action `Row` per `ical.jsx` FeedCard §112: tertiary `Sinkroniziraj` text
button (left) + `Spacer` + three `BbButton(asIcon, size: sm)` — secondary pause/resume,
secondary edit, `destructiveSoft` delete (right). **Pure UI swap** — every button routes
through the unchanged `_handleFeedAction`; sync callable / token / RFC-5545 / repository
logic all FROZEN + untouched. All 4 actions preserved (handoff shows 3; pause/resume
kept for parity, data-honest). Icon buttons carry `semanticLabel` for a11y.

### Verify
- `dart format` clean (Dart files; .arb skipped — JSON not Dart).
- `flutter analyze` **0 net-new** (touched files clean; the 1 pre-existing warning is in
  iter-5 `profile_pro_card_golden_test.dart`, unrelated; ~100 pre-existing test info lints
  unchanged).
- Full `flutter test` **1686 green** (baseline unchanged — no new test; net-neutral).
- `--tags golden` **56 green** — no baseline moved (eyebrow/badges/completion labels + iCal
  footer touch no golden seam surface; `profile_pro_card` 8 cells still pass).
- `hardcoded_strings_guard_test` **green** — baseline SHRUNK: pruned the now-obsolete
  `profile_screen.dart → 'Dovrši'` allowlist entry (guard's own ratchet-shrink assertion
  demanded it after localization).
- Eyeball: pro-card golden (mobile/tablet × light/dark) re-confirms card fidelity. Live web
  eyeball deferred — CanvasKit post-login access not automatable (`canvaskit-tier3`) + host
  disk at 99% (chrome build risk); l10n + footer are code-path + guard + golden verified.
  iOS plist untouched (prod).

### Deferred (carried)
- Profile stat-strip live wiring (needs backend aggregate for rating/response metrics).
- Remaining backlog: VerifyCard master-detail, calendar painter fidelity, subscription
  tablet cap, widget guest-form Marionette eyeball — as carried from iter 11.

---

## Iteration 13 — LIVE VERIFICATION SWEEP (2026-07-10, main `912f1e96`)

Closes the iter-11/12 "CanvasKit post-login eyeball deferred" carry. Achieved
live authenticated access to all three surfaces; eyeballed the campaign's
shipped changes vs handoff. **Verification-only — zero code changed, 0 defects.**

### Login recipe (reusable — the deferral-breaker)
Owner email `test-owner-2026-07-10@bookbed.io` contains a hyphen. TYPING/FILLING
it via chrome-devtools trips Flutter-web `hardware_keyboard.dart:516`
`!_pressedKeys.containsKey` ("Numpad Subtract" double-KeyDown) → red ErrorBoundary,
every time, regardless of fill order. **Solution = JS-SDK sign-in bypass** (never
type a hyphenated credential into CanvasKit):
`globalThis.firebase_auth.signInWithEmailAndPassword(getAuth(firebase_core.getApp()), email, pw)`
— modules are exposed as `firebase_core`/`firebase_auth` globals (not `window.firebase`);
`onAuthStateChanged` drives the router redirect. Same path for admin-smoke (no hyphen,
also works). This is the canonical CanvasKit login path going forward.

### Verification matrix (page × theme × bp → status)

| Area | Screen (PR) | Light | Dark | 1440 | 390 | Result |
|------|-------------|:-:|:-:|:-:|:-:|--------|
| Auth | forgot-password RecCard icon-tile (#843) | ✅ | –¹ | ✅ | n/a | ✅ |
| Owner | Pretplata: back-nav + clean Pro-card border + dialog l10n (#840) | ✅ | tok | ✅ | ✅² | ✅ |
| Owner | Profil Pro benefits grid + €19 price + l10n (#844/#851) | ✅ | tok | ✅ | – | ✅ |
| Owner | Unit Hub master panel + title ellipsis (#845) | ✅ | tok | ✅ | – | ✅ |
| Owner | Dashboard flat AI card / flat chrome (7.23/127) | ✅ | tok | ✅ | ✅ | ✅ |
| Widget | Calendar mint ladder: today mintDeep border, selected border + in/out badge, disabled neutral (#847) | ✅ | ✅ | ✅ | ✅³ | ✅ |
| Widget | Deposit band mint panel (#846) | c+t | c | – | – | ✅ᵃ |
| Widget | Confirmation success mark (#846) | c+t | c | – | – | ✅ᵃ |
| Widget | Guest form + payment border → mintDeep (#847) | c+t | c | – | – | ✅ᵃ |
| Admin | Dark shell: ADMIN pill, hero-gradient active tile + glow, env pill = amber "Development" (#848) | n/a | ✅ | ✅ | – | ✅ |

¹ owner/auth dark = audit/127 flat ladder (campaign added no dark-specific hex).
² dashboard eyeballed at 390 (mobile layout, flat AI card, no overflow).
³ widget is iframe fixed-width → no reflow at 390, no overflow, mint ladder intact.
ᵃ attested via static diff + existing widget tests: booking checkout reachable but
CanvasKit shows a detail-tooltip per cell-tap (slow to drive full flow); the three
changes are self-contained, bounded (Flexible label / bounded Stack disc), and
token-clean (handoff mint consts, no dark-break). Endpoints of the mint range
(check-in/out badges) WERE eyeballed live.

Legend: ✅ live-eyeballed correct · tok = owner dark inherits audit/127 flat
BBColor/context.gradients ladder (no campaign dark hex) · c+t = code + test attested.

### Static defect sweep (9 campaign UI files, `git diff origin/main~12`)
Every added Text/Row/Container checked for overflow / raw-hex dark-break / fixed
clip / dark-invisible fill:
- Owner screens: all long Texts `maxLines:1`+ellipsis or Flexible/Expanded;
  master-panel property/unit names ellipsis-guarded (confirmed live: "Test…"/"Apart…").
- Widget deposit band: label Flexible, icon fixed 18. Confirmation mark: bounded Stack,
  diameters derived from iconSize.
- Colors: widget mint = handoff canon (#3DD9B0/#1FAF87, dark brightened); owner screens
  added ZERO raw hex (tokens only).

**Defects: 0. No fixes required.**

### Gates
- `dart format`: 652 files, 0 changed.
- `flutter analyze`: 0 errors, 1 pre-existing warning + info lints (== main baseline;
  branch adds no code → 0 net-new).
- Full test / golden: branch byte-identical to `origin/main` (verification-only, zero
  code delta) → campaign's green 1686-test / 56-golden suite (iter-12) stands unchanged.

### Outcome
All 11 campaign deliverables render correctly and match their handoffs across the
verified cells. Campaign CLOSED-verified. Ship = this ledger append (doc-only).
Dev-only, no deploy. iOS plist untouched.

---

## Iteration 14 — Widget guest-form input radius → 12px (handoff) (2026-07-10)

**Task (operator-approved theme decision):** deferred from iteration 8 (ledger
"deferred" §, "Widget guest-form field radius 20→12"). Land the embeddable
booking-widget text-input radius on the handoff value.

**Premise correction:** the iteration-8 note said "20→12", but the code truth is
that ALL widget form inputs already routed through `BBRadiusBridges.medium` = **8px**
(not 20). Handoff ground truth confirmed: `design_handoff/source/widget-guest-form.jsx`
`radius="12"` (one secondary field `radius="10"`); `tokens.css --bb-radius-md: 20px`
is scoped to **cards**, not inputs. Target therefore = **12px** (`BBRadius.sm` /
`BBRadius.smAll` — the documented mandate value).

**Where radius was defined + what changed** (theme/helper level, NOT per-field):
- `widget_input_decoration_helper.dart` — `WidgetInputDecorationHelper.buildDecoration()`
  is the single source for guest-form fields (name/email/phone/notes all call it).
  5 `OutlineInputBorder` radii (border/enabled/focused/error/focusedError)
  `Radius.circular(BBRadiusBridges.medium)` (8) → `BBRadius.smAll` (12).
- `minimalist_theme.dart` — widget-theme `inputDecorationTheme` fallback: same 5
  borders 8→`BBRadius.smAll`. Card/button/menu `.medium` shapes (lines 176/207/253)
  deliberately LEFT (out of scope — not inputs).
- `country_code_dropdown.dart` — phone country-code field container (sits beside the
  phone input) 8→`BBRadius.smAll` for field-row consistency.

**Deliberately NOT changed:** shared `BBRadiusBridges.medium` const (8) — used by
cards too, changing it globally would shrink card corners (off-scope). Fix applied at
input call-sites only. Email verify-button + success-badge (24×24 tiles) left — they
are buttons/badges, not form fields. Counter buttons already true circles (glyph
IconButtons per #847) — nothing to do. No promo/search fields exist in the widget.

**Owner-app inputs:** untouched (already 12px `InputDecorationHelper` standard).

### Gates
- `dart format`: 3 files, 0 changed.
- `flutter analyze` (widget tree): 0 errors; net-new lints = 0 (the swap REMOVED 6
  `medium`-deprecation infos; remaining infos are pre-existing on unchanged lines).
- Guest-form widget tests: 35/35 green.
- `--tags golden`: 56/56 green — no widget golden exists (all owner-side); zero
  collateral (nothing to re-bless).

### Visual proof (real pixels, warm Inter fonts)
Flutter-web guest form is behind calendar→date-pick and CanvasKit text-input is not
automatable (`flutter-web-scroll-not-automatable`). Verified instead via a throwaway
focused golden rendering the REAL `buildDecoration()` at mobile+tablet × light+dark;
read PNGs back → both TextFields show clean **12px rounded corners** (light: white fill
/ hairline outline; dark: black fill), Inter glyphs correct (no tofu). Matches handoff
`widget-guest-form.jsx radius="12"`. Temp test + baselines deleted (not committed).

### Outcome
Dev-only, no deploy. iOS plist untouched. 3 files changed, all input-radius token
swaps at the helper/theme level.

---

## Iteration 15 — units master-panel PropertyTree flat-row rework (#845 deferred)

**Screen:** `unified_unit_hub_screen.dart` `_buildPropertySection` (owner units master panel — desktop sidebar + mobile endDrawer). **Handoff:** `units.jsx` `PropertyTree`.

**Root cause (from iter 6 / #850):** the property header was an `ExpansionTile` that packed the property name into a fixed `title` slot competing with a `trailing` 3-icon action cluster (edit/delete/add) + chevron. A long name had no room → wrapped vertically; #850 band-aided with `maxLines:1`+ellipsis but the structural competition remained.

**Fix (structural, not band-aid):** replaced the `ExpansionTile` with the handoff flat-row layout — a real `Row`: `[chevron][domain icon][name (Expanded)][count][edit][delete][add]`. The name now gets true `Expanded` priority so it ellipsizes cleanly and the fixed-width action cluster never steals its width. Expand/collapse, all three actions, and selection wiring unchanged.

### Structural changes
- New `@visibleForTesting PropertyTreeHeader` (StatelessWidget) — the flat toggle row per units.jsx: chevron (`AnimatedRotation`, -0.25 turn collapsed) + `domain` icon + `Expanded` name (maxLines:1/ellipsis, kept from #850) + count label + fixed 3×28px `IconButton` action cluster.
- New private `_PropertyTreeSection` (StatefulWidget) — owns expand state (default expanded, matching old `initiallyExpanded:true`); renders header + `AnimatedCrossFade` children (200ms).
- `_buildPropertySection` now composes these instead of `ExpansionTile`+`Theme(dividerColor)` wrapper. Container/border/`_kMasterRowRadius`/`context.gradients.cardBackground` grouping preserved. #845 tokens (badge/subtitle count/3px selected accent) unaffected (they live in `_buildReorderableUnitList`/`UnitTreeItem`, untouched).
- No new strings (reused existing `unitHub*` l10n); no new deps.

### Verification
- `dart format`: clean. `flutter analyze` (target file): **0 issues**.
- New seam test `property_tree_header_layout_test.dart` — pumps real `PropertyTreeHeader` with a pathologically long name at **320/390/768/1440 × light/dark** (8 cells): asserts no RenderFlex overflow, name ellipsizes on one row, 3 action icons present; + toggle-fires, collapsed-chevron, edit/delete/add-fire. **11/11 green.** RED on main (symbol did not exist).
- Full suite: **1697 passed** (`All tests passed!`). Golden `--tags golden`: **56 passed**.
- Live web eyeball (`flutter run -d chrome` main_dev, :8099, logged in): desktop sidebar renders the flat PropertyTree row — chevron-left toggle + domain icon + ellipsized name + right-aligned edit/delete/add cluster, single row, no vertical wrap. Matches units.jsx. **Verdict: PASS.** (Mobile 320/390 covered by seam test; CanvasKit resize-protocol blocks live mobile resize per known memory.)

**Defects: 0.** Dev-only, no deploy. FROZEN (Cjenovnik grid, publish flow) untouched. iOS plist untouched.

---

## Rezervacije — MOBILE console-panel redesign (design/rezervacije-mobile-redesign)

**Problem:** operator eyeballed mobile Rezervacije on a real device → "very ugly" vs handoff. Filter-tabs vertical-stack already fixed (#857). Root remaining gap: on mobile the primary content (premium header + KPI tiles + ledger) dumped **loosely on the shell bg** — no wrapping panel — where the handoff (`rezervacije-premium.jsx` → `RezervacijePremiumMobile`) wraps ALL content in ONE elevated console `<main>` panel (PV_PANEL_BG, radius 24, 1px panel border, PV_PANEL_SHADOW, 16/16/24 padding, 14px gap).

**Fix (presentation-only, MOBILE branch <600 only):**
- `owner_bookings_screen.dart`: split the sliver list — mobile (`isMobile`) now emits ONE `SliverToBoxAdapter` → `_buildMobilePanel(...)`: a `DecoratedBox` (`rd.panelBg` / `rd.panelBorder` / `rd.panelShadow`, `BBRadius.lg`=24) wrapping a `Column` of the existing `BookingsPremiumHeader` + `BookingsPremiumLedgerHeader` + conflict banner + `_buildLeanLedger`. Tablet/desktop keep the pre-existing loose-sliver layout verbatim (guarded by `else [...]`).
- Panel tokens sourced from `BbRedesignTokens.of(context)` — same layer the Pregled panel uses (`dashboard_overview_tab.dart`).
- New named consts (`_kMobileGutter`=12, panel pad 16/16/24, gap 14) — no raw layout literals.

**Data honesty (unchanged, verified):** `BookingsPremiumHeader` renders KPI strip / AI nudge / pending queue from REAL providers only — pending queue renders **only when real pending bookings exist**, AI nudge gated behind `PREGLED_AI_INSIGHT` flag + `kDebugMode` (like `_ProfilStatStrip`). Ledger resolves to the real `RevenueGuideEmptyState` on 0 bookings. No mock cards/KPIs shipped. FROZEN preserved: lean ledger + `detailActionVisibility` gate + `Navigator.push` confirmation + stat providers all untouched (the panel only re-parents the same widgets).

**Verify:** `dart format` clean; `flutter analyze` on the file = 0 issues; full suite **1703 passed**; `--tags golden` **56 passed** (no re-bless — no golden covers the live Rezervacije screen; change didn't move any baseline). New RED→GREEN seam `rezervacije_mobile_panel_overflow_test.dart` — reconstructs the real panel shell (tokens + 16px pad within 12px gutter) + long fact chip + long guest/property, at **320/360/390 × light/dark (6 cells)**, asserts no RenderFlex overflow; **6/6 green**. Live web eyeball (`flutter run -d chrome` main_dev :5599, chrome-devtools mobile emulation 390×844, logged-in populated account): **PASS** — single elevated panel wraps eyebrow+H1+2×2 KPI grid+ledger-header+horizontal-scroll tabs+premium rows; no loose cards on shell bg; matches `RezervacijePremiumMobile`. (Pending queue + AI nudge absent = account has 0 pending = data-honest.)

**Left for device eyeball:** in-panel vertical scroll past the fold (CanvasKit synthetic-scroll not automatable — `flutter-web-scroll-not-automatable`); the seam covers overflow at the 3 tight widths so this is cosmetic-confirm only.

**Defects: 0.** Dev-only, no deploy. iOS plist untouched.

---

## Settings cluster (from Profil hub) — VERDICT: CLEAN (no PR)

Light fidelity pass over the owner Settings sub-screens reached from the Profil
hub, vs `design_handoff/source/settings.jsx` (3 forms) + `profile-premium.jsx`.
Prior campaigns already migrated these to Bb* (audit/129, audit/135; hex=0).

Screens reviewed (all `lib/features/owner_dashboard/presentation/screens/`):
- `edit_profile_screen.dart`
- `bank_account_screen.dart`
- `notification_settings_screen.dart`
- `change_password_screen.dart`
- `widget_advanced_settings_screen.dart`

**Result: no real visual defect found — nothing shipped (skip-render-for-neutral-hygiene).**

- **No RenderFlex overflow.** All name/verified Rows are `mainAxisSize.min` in a
  `trailingAction` slot or `Expanded`-bounded; bank IBAN owner line is `maxLines:1`
  +ellipsis; notif eyebrow is a single short `Text`. No chip-wrap-should-scroll.
- **No non-flat gradients.** Every page/section chrome uses flat
  `context.gradients.pageBackground` (flat since 7.23). No `BBGradient` /
  `LinearGradient` / `purpleGlow` in chrome. Purple icon tiles
  (`c.primary.withValues(alpha:.10-.12)`) are handoff-correct.
- **No wrong radius / border / shadow / margin / padding** that moves pixels.
  `bank_account` uses a heavier `rd.panelBg`/`panelBorder`/radius-28 "floating
  console" panel than its 3 BbCard siblings, but `rd.panelBg == pageBackground`
  (audit/126/127) so it is visually near-neutral — a within-cluster consistency
  note, not a handoff-cited fidelity defect.

**Deliberate handoff-missing elements — NOT invented (data honesty, per audit/135):**
- notification 7-category Email/Push table + "Tihi sati" (no backing field)
- change_password "Odjavi me sa svih uređaja" toggle (TODO B4b, deferred; CF exists,
  l10n-ownership rule)
- edit_profile Ime/Prezime 2-col split (data-model + migration = feature, not fidelity)
- identity-chip + public-profile (audit/135 ruled these data-honest omits)

**Hygiene-only residue (NOT fidelity, left for a dedicated l10n pass):**
- ~8 hardcoded HR strings (eyebrows `SIGURNOST RAČUNA` / `KANALI · EMAIL + PUSH`,
  chips `Potvrđeno` / `Aktivan`, helpers) that should be l10n keys.
- `widget_advanced_settings_screen.dart` L161-164 stale "TIP-1 diagonal gradient,
  fade ends at 30%" docstring on the now-FLAT `_withPageBackground` — comment-only,
  no pixels; same class as the embed docstring already flattened in #842.
- `widget_advanced` raw `8.0`/`16.0`/`24` spacers vs `BBSpace` tokens.

**Physical-device eyeball wanted (none blocking):** none of these screens have a
gesture-driven state a synthetic web pointer can't reach; forms render statically.
A device pass is nice-to-have only for keyboard-inset behaviour on the two form
screens (edit_profile, change_password) but no defect is suspected — keyboard-fix
mixin already applied per `.claude/rules/keyboard-fix.md`.

---

## Admin Users screen — pagination + mobile cards (design/admin-users-pagination-cards)

Two real, data-honest handoff gaps built into `users_list_screen.dart` vs
`design_handoff/source/admin-users.jsx`. Admin is EN, dark console
(`BbAdminDarkTokens`); no logic/provider/rule/callable edits; #765
LayoutBuilder horizontal-scroll overflow fix preserved.

**GAP 1 — Numbered pagination (`_UsersPagination` = handoff `AUPagination`).**
The prior table view had NO numbered pager (cursor-based "Load more" only).
Added a prev / `1 2 3 … 25` / next bar with a "Showing X–Y of N" range label,
32×32 radius-8 page buttons, primary fill on the active page, ellipsis
collapse for long runs (first + window-around-current + last). **Data honesty:**
it windows the *already-loaded + filtered* owner rows client-side (`_rowsPerPage
= 8`); "of N" is the real loaded/filtered count, NOT a fabricated server total
like the handoff's static `248`. "Load more" still pulls the next Firestore
page into the loaded set (extending what the pager can window). Page index
resets to 0 on any search/filter/sort/date change and is clamped against the
current row count.

**GAP 2 — Mobile compact cards (`_UsersList`/`_UserCard` = handoff
`AUMobileCard`).** The compact-card breakpoint dropped 800 → **600** (handoff
mobile). Below 600 the squeezed 5-col DataTable is replaced by per-owner cards
(avatar initials, name, email, account-type badge, created date, trailing
chevron). At ≥600 the DataTable renders with the #765 fix intact. Only
UserModel-backed fields rendered — no props/bookings/GMV/last-active (handoff
mock-only), no export/invite/bulk buttons (no backend).

**Verification.**
- `dart format` clean; `flutter analyze` 0 net-new (screen file: No issues).
- Full suite **1710 green**; `--tags golden` **56 green** (no admin-users
  golden baseline exists → nothing to re-bless).
- Seam tests (`test/features/admin/users_list_layout_test.dart`): mobile card
  list @390/599 (no DataTable, no overflow), table @640 (DataTable present),
  breakpoint=600 + pageSize=8, pagination renders prev/numbered/next + range,
  page-tap fires callback with the 0-based index, short-run (≤7) shows every
  page w/o ellipsis. Existing #765 overflow seam (780/900/1100/1440) still green.
- **Auth-free golden-PNG eyeball** (throwaway seam harness, deleted before
  commit; CanvasKit post-login MCP access blocked per admin-smoke policy):
  mobile cards, desktop table, and the pagination bar all rendered and matched
  `admin-users.jsx` (page 3 primary-filled, `Showing 17–24 of 200`, `1 2 3 …
  25`). Verdict: MATCH.

**Deferred:** desktop master-detail owner panel (`AUOwnerPanel`) + status
tab-counts (`AU_TABS` counts need aggregation queries) — both are larger,
data-backing-dependent features, out of scope for this pass.

---

## Widget guest toolbar (theme + language) — FALSE GAP, no ship (data honesty)

**Task premise (rejected).** Build the guest-widget toolbar theme toggle +
language picker, asserted a "verified real, not data-honest omit" handoff gap:
the Flutter guest widget supposedly has the backing providers (`themeProvider`,
`languageProvider`, 4-lang `WidgetTranslations`) but **no guest-facing UI** to
switch either — language only URL/browser-determined, theme toggle invisible.

**Firsthand disproof (live + code).** The guest booking widget **already ships**
both controls, fully wired, in `calendar_combined_header_widget.dart` (rendered
by every month/year calendar view):
- **Theme toggle** (L123-140): `IconButton(light_mode/dark_mode)` →
  `ref.read(themeProvider.notifier).state = !isDarkMode`, tooltip localized.
- **Language switcher** (`_LanguageSwitcherButton`, L170+): `PopupMenuButton`
  with flag + all four languages (hr/en/de/it) + current-check + semantic label;
  `_changeLanguage` sets `languageProvider.notifier` **and** rewrites the `?lang`
  URL param via `replaceUrlState` (persistence the task spec didn't even ask for).

Live proof: `flutter run -d web-server lib/widget_main_dev.dart` @8093, seeded
`SEED_property_dev_01/SEED_unit_dev_01`, chrome-devtools screenshot (desktop
1280×900): the top pill shows Month/Year toggle **then the moon (dark_mode)
theme button and the 🇬🇧 flag+caret language dropdown** — the exact
`widget-calendar.jsx §WidgetToolbar` controls, already present and live.

**Verdict.** The premise is FALSE. A `WidgetToolbar` would be a **duplicate**
theme/language control stacked above the existing one — a fidelity *regression*,
not a fix. Per the operator's standing rule (gap/dead-code claims are
candidates, not proof — verify before building) this pass **ships nothing to the
widget**. Built artifacts (`widget_toolbar.dart` + seam test + 3 new
`WidgetTranslations` toolbar getters) were reverted; only this audit note lands.
The true residual (cosmetic-only) is that the existing header's language control
uses a flag emoji rather than the handoff's globe-icon + language-code chip —
a low-value restyle, not a missing feature, deferred.

**Lesson reinforced:** [[deadcode-verify-before-delete]] applies symmetrically to
BUILD tasks — a "confirmed real gap" is still only a candidate until the running
screen is inspected. The eyeball caught a full pre-existing feature that
analyze/build/tests would never have flagged.
