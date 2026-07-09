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
