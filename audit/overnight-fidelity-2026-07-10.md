# Overnight design-fidelity campaign — 2026-07-10

Page-by-page premium-fidelity closeout of owner screens vs `design_handoff/source/*.jsx`.
Dev-only, worktree-per-page, flat chrome (no gradients), BB* tokens. Each entry = one shipped PR.

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
