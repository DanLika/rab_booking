# Overnight design-fidelity campaign — 2026-07-10

Page-by-page premium-fidelity closeout of owner screens vs `design_handoff/source/*.jsx`.
Dev-only, worktree-per-page, flat chrome (no gradients), BB* tokens. Each entry = one shipped PR.

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
