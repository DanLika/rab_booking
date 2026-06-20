# audit/149 — Owner Subscription (Pretplata) fidelity diff

**DRAFT — READ-ONLY — NOT committed. No apply, no commit, no live-render this pass** (deferred to apply-time, per audit/135). Recon off clean `origin/main` `54f0820a` (worktree `/tmp/bb-recon-subscription-wt`, branch `recon/subscription`). Base palette ✓ `#F0F1F5` / `#000` / `#1E1E1E` (`app_gradients.dart`). Color = audit/127 (excluded — flagging layout/component/spacing/chrome only).

**Target:** `lib/features/subscription/screens/subscription_screen.dart` (1006) vs `design_handoff/source/subscription.jsx` (257).
**Method:** code-first diff, both sides read in full + ground-truth on `BbCard`, `BBSpace`, and the screen's routing (`router_owner.dart` + all `context.push` call sites).

---

## Verdict

**The screen is already a high-fidelity port of the handoff.** Hero, billing toggle, plan-card content (names/descs/prices €15·€19·€180·€48·€0/feature lists+ok-flags/CTAs/"Preporučeno" badge), price block (40·w800·ls−1.2), footnote, and free-inline all match **near pixel-exact** (opacities, radii, sizes 1:1). Spacing uses `BBSpace.md`(24) = the 8px-grid snap of the handoff's 20/24 values → **intentional token discipline, not drift.**

**2 real, cheap gaps** (app-bar nav + Pro-card extra accent bar) + a handful of minor/optional deltas. **No heavy fidelity work** (the one "heavy" candidate — persistent sidebar/breadcrumb — is already-known global-chrome deferral, audit/126 §2B/§3B, not subscription-specific).

---

## Per-section ledger

### Scaffold / chrome — `SubScaffold` (jsx:34) vs `build`+`_buildWebContent` (:43, :66)

| Item | code vs handoff | Class | Cost |
|---|---|---|---|
| **App-bar leading: `menu`→`openDrawer` + `drawer:OwnerAppDrawer`** (:45-50) vs handoff `showBack` (jsx:40/53/63) | **REAL gap.** Screen is **only ever `context.push`ed** (`profile_screen` :331/:1057/:1156 + `trial_banner` :53) — NOT a drawer destination (absent from `owner_app_drawer`). A pushed sub-page offering a hamburger to the root drawer is wrong; handoff + sibling exemplar (audit/135 `widget_advanced`: `arrow_back`/pop) want **back→pop**. | SAFE | **cheap** |
| Page bg `context.gradients.pageBackground` (:52) | **already matches** (flat #F0F1F5/#000, 127 ✓) | — | — |
| Centered column `maxWidth:860` (:85) | **already matches** desktop (860 ✓). Tablet caps 860 vs handoff 640 (jsx:55) → ~704 effective on 768; trivial. | SAFE | trivial (skip) |
| Main padding `fromLTRB(32,24,32,48)` (:77) vs handoff desktop `24/32/32` | top+horiz ✓; bottom `xl`(48) vs `lg`(32) = +16 scroll tail. harmless. | SAFE | trivial (skip) |
| Persistent **sidebar** (jsx:38) + tablet **rail** (jsx:51) | **already-deferred** — audit/126 **§3B** (global). Not subscription-specific. | — | deferred |
| Desktop/tablet **breadcrumb** `['Profil','Pretplata']` (jsx:40/53) vs `title` | **already-deferred** — audit/126 **§2B** breadcrumb appbar (global). Mobile `title="Pretplata"` ✓ already matches. | — | deferred |

### Trial-status hero — `SubStatusHero` (jsx:72) vs `_TrialHero` (:214)
**Verdict: matches near pixel-exact.** gradient(`rd.heroGradient`)+`xlAll`+`purpleGlow`+pad(20/28) ✓; radial halo −80/−60·280·`0x2EFFFFFF`→`0x00`·stops[0,.7] ✓; eyebrow "VAŠ PLAN"(`0xD1`=.82) ✓; title "Probni period"(22/28·w800·ls−0.56·Wrap) + "Pro značajke" pill(`0x2E`·12·w700) ✓; non-compact paragraph + bold endDate ✓; progress "12 od 14"(tnum·`0xE6`) + compact "do 10.06."(`0xC7`) + bar(h6·`0x38`·fill white→`0xC7`·maxW420) ✓; CTA onGradientSolid·workspace_premium·md/lg·fullWidth-compact ✓.
- On-gradient white-alpha hexes (`0xD1/0x2E/0xE6/0xC7/0x38 FFFFFF`) = legitimate scrims on the purple hero (theme-independent) → **NOT** a 127 hex-hygiene issue.

| Item | Class | Cost |
|---|---|---|
| **Upgrade CTA → `_showUpgradeDialog` is hardcoded ENGLISH** ("Upgrade to Pro" / "coming soon… Stripe… Stay tuned", :430-433; called :234 + Pro-card :753) | SAFE | **cheap** (l10n) |
| Hero→toggle gap `BBSpace.md`(24) vs handoff marginBottom 24 desktop | already matches | — |

### Billing toggle — `SubBillingToggle` (jsx:115) vs `_BillingToggle` (:452)
**Verdict: matches** (+ bonus). Center·pad4·`surfaceVariant`·r999·border ✓; pills Mjesečno/Godišnje, selected→`surface`+`BBShadow.sm`, label 14·w600 ✓; "−20%" badge `success@.12`·11·w700·tnum ✓. **Code adds `AnimatedContainer` (BBMotion.fast)** = design-to-system enhancement over the static handoff. ✓ already matches.

### Plan cards — `SubPlanCard` (jsx:151) vs `_FreePlanCard`(:616)/`_ProPlanCard`(:674)

| Item | code vs handoff | Class | Cost |
|---|---|---|---|
| **Pro card = `BbCard(accentLeft, accentTone:primary, selected:true)`** (:697-699) | **REAL gap.** `selected:true`→2px primary border ✓ matches handoff featured (jsx:161). But `accentLeft` **also** Stack-overlays a **4px primary left bar** (`bb_card.dart` :95-116) — handoff featured has **no** left bar (border only). Double-emphasis. Fix = **drop `variant`/`accentTone`, keep `selected:true`** → clean 2px-border card. | SAFE | **cheap** |
| Free card `BbCard()` default = pad20·radius-md(20)·1px border (:633) vs handoff free 1px border-subtle·r-md·pad20 | **already matches** (geometry). | — | — |
| Card content: names/descs/`_PriceBlock`(40·w800·ls−1.2)/`€15·€19·€180·€48·€0`/6-feature lists+ok-flags/dividers/CTAs(primary·secondary-disabled) | **already matches** (verbatim incl. `_FeatureRow` check_circle/cancel·18·body-13·strikethrough) | — | — |
| Featured shadow: code `cardElevated` (neutral) vs handoff `shadow-purple-sm` (purple-tinted, jsx:163) | **127-adjacent** (shadow tint) — premium-emphasis nuance; badge already uses `purpleSm` (:767). | SAFE | optional (skip — re-color domain) |
| **Mobile Pro card shows ALL 6 features** (`_PlansStacked`→`_ProPlanCard`, :605/:680) vs handoff mobile `maxFeatures={4}` + "+ još 2 značajke" link (jsx:239/:188) | content delta; code shows more (arguably better). | SAFE | optional (lean leave) |
| Free-inline mobile `_FreeInline` (:868) — "Besplatno · €0" / "Plan nakon isteka probe · 1 jedinica" / tertiary "Zadrži besplatno" | **already matches** (jsx `SubFreeInline`:219). Button `onPressed:(){}` no-op = data-honest (keep-free needs no action). | — | — |

### Foot-note — `SubFootNote` (jsx:207) vs `_FootNote` (:924)
**Verdict: matches.** pad·`surfaceVariant`·`smAll`·verified_user-18 + Stripe blurb + "Usporedi sve značajke"(primary) ✓.
- **Always rendered** (:101) vs handoff hides on mobile (`!mobile`, jsx:248). Showing the Stripe-reassurance on mobile is fine/better. → optional, lean leave.
- "Usporedi sve značajke" is colored-but-non-tappable (no gesture); handoff is `href="#"` placeholder → data-honest decorative (no comparison feature exists). Low prio.

### FAQ — `_FaqItem` ×3 (:104-115, :972)
**Code-exceeds handoff** (handoff has NO FAQ; code comment :968 = "intentionally retained… refactored onto BbCard"). Per audit/135 `edit_profile` precedent = **NOT a gap; keep.**

### Native redirect — `_buildNativeRedirectContent` (:129)
**Code-exceeds** (App Store IAP → web-only redirect; "branch preserved as-is" :21). Not a handoff gap; **FROZEN-adjacent (do not redesign).**

---

## Data-honesty
- **Upgrade flow unwired** — `_showUpgradeDialog` is a "coming soon" placeholder; no Stripe checkout (screen comment: "Stripe / payment state machine logic UNTOUCHED"). Correct as-is; **leave the logic**, only fix the English copy.
- Hero trial figures (`12/14`, "10. lipnja 2026.") are **hardcoded constants** (`_TrialHero._daysLeft/_totalDays/_endDate`, :219-221) — NOT bound to `trial_status.dart`. Matches handoff's static mock; **flag as a known stub** (data-honest for a fidelity pass; real binding = separate feature, out of recon scope).
- FAQ + native redirect = code-exceeds-handoff → keep (don't invent removals).

---

## FROZEN check
Screen is **not** in NIKADA NE MIJENJAJ. Stripe/payment logic here = only the placeholder dialog + `launchUrl` redirect → all proposed edits are WEB chrome/card cosmetics + a nav-icon swap → **SAFE**. FROZEN-adjacent = native redirect branch (don't touch). Nav change is on a `context.push` route → `pop` always valid.

---

## Scope (operator picks)

### 🟢 Cheap-wins bundle (SAFE, high-confidence, ~1 small PR)
1. **App-bar → back-nav** (:45-50): `leadingIcon: Icons.arrow_back`, `onLeadingIconTap:(ctx)=>ctx.pop()` (or `Navigator.pop`), **drop `drawer: OwnerAppDrawer`** (+ unused import). Matches handoff `showBack` + `widget_advanced` exemplar. Highest-value.
2. **Pro card → clean featured border** (:697-699): drop `variant: BbCardVariant.accentLeft` + `accentTone` (keep `selected: true`) → 2px primary border only, no extra left bar. Matches handoff.
3. **Upgrade dialog → l10n + HR** (:430-433): replace hardcoded English with HR l10n keys (e.g. `subscriptionUpgradeComingSoonTitle/Body`).

### 🟠 Optional / low-yield (lean-leave)
- Mobile Pro-card 4-feature truncation + "+ još N značajke" (code shows all 6).
- Footnote hidden on mobile (code shows it).
- Featured-card **purple** shadow (127-adjacent, re-color domain).
- Tablet column cap 640 vs ~704; bottom pad `xl`→`lg`.

### 🟠 Already-deferred (global, NOT subscription-specific)
- Desktop/tablet **breadcrumb** appbar → audit/126 **§2B**.
- Persistent **sidebar/rail** → audit/126 **§3B**.

### ✅ Already matches / do NOT touch
Hero (full), billing toggle (+motion), plan-card content+geometry, price block, free-inline, footnote text. **Code-exceeds (keep):** FAQ, native redirect. **Data-honest stubs (keep logic):** upgrade dialog, hardcoded trial figures.

**Headline:** Subscription is in very good shape. The cheap-wins bundle (#1 back-nav + #2 Pro-card border + #3 dialog l10n) is the entire high-yield, low-risk pick — all SAFE, all conclusive from code. **Live-render deferred** (budget-lean, per audit/135): an apply-time eyeball is worth it for #1 + #2 only (back-arrow lands; Pro-card border-without-left-bar reads as "featured" in light + dark + 390-mobile) — render the screen at apply, not now.

**STOP — no apply. Operator picks.**
