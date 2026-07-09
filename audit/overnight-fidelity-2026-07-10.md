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
