# audit/134 — Owner Unit Hub (`/owner/unit-hub`) fidelity RECON

**DRAFT — READ-ONLY — NOT committed.** Recon-first; no code changed; no worktree created (see §0). Awaiting operator review of the component-by-component scope (§5) before any fix phase.

- **Date:** 2026-06-19 · **Branch:** `main` (read-only; nothing modified except this draft file)
- **Target:** owner Unit Hub screen + its full surface (4 tabs · drawer/endDrawer · dialogs · Unit Wizard · shared chrome)
- **Why this screen is special:** the **most FROZEN-saturated owner screen** — it hosts the FROZEN Cjenovnik pricing grid AND the FROZEN Unit Wizard publish flow. The FROZEN/SAFE boundary runs *through* the screen, not around it. **§2 (FROZEN intersection map) is the #1 output.**

---

## §0 — Numbering + setup notes (READ FIRST)

| Item | Prompt assumption | Reality (verified firsthand) | Action |
|---|---|---|---|
| **Audit #** | "133 je sljedeći slobodan (130/131/132 zauzeti)" | **133 is TAKEN** — `audit/133-merged-screens-eyeball-2026-06-19.md` was created **today**. `ls audit/` highest = 133. | This recon = **`audit/134`**. Branch (when fix phase starts) = **`design/134-unit-hub`**, not 133. |
| **Worktree** | step 0 said `git worktree add … design/133-unit-hub` + `build_runner` | This pass is **pure read-only recon ending in STOP**. No edits → worktree isolation has zero value; `build_runner` (1–3 min) is unneeded for grep/read recon; the specified branch name collides with the taken audit #. | **Deferred.** Create `git worktree add /tmp/bb-unithub-wt -b design/134-unit-hub origin/main` + `build_runner` **at fix-phase kickoff** (after scope approval), per the standing parallel-session protocol. `main` is untouched. |
| **Base-verify** | light `#F0F1F5` / dark `#000` / card `#1E1E1E` | ✅ `app_gradients.dart` — `_lightStart/End = 0xFFF0F1F5` (66-67), `_darkStart/End = 0xFF000000` (73-74), `_darkCard = 0xFF1E1E1E` (94). FLAT (start==end). | Confirmed. Palette = audit/127 ladder, intact. |

---

## §1 — Hub composition map

**Root:** `lib/features/owner_dashboard/presentation/screens/unified_unit_hub_screen.dart` — **1718 LOC**, `ConsumerStatefulWidget`, 4-tab `TabController`, master-detail (desktop ≥1200 = 280px right sidebar; mobile/tablet = `endDrawer`). Body bg `context.gradients.pageBackground` (:275); `UnitsPremiumHeader` (:278); master panel `context.gradients.sectionBackground` (:299-302).

### Tabs
| # | Label (HR) | Renders | LOC | What it does |
|---|---|---|---|---|
| 1 | **Osnovno** | inline `_buildBasicInfoTab()` (:1299-1507) | — | Read-only info cards (capacity/price/services/info) + Edit btn |
| 2 | **Cjenovnik** | `unit_pricing_screen.dart` → embeds `price_list_calendar_widget.dart` | 797 / **2573** | Base price + per-day pricing calendar grid + bulk edit ⚠️ **FROZEN content** |
| 3 | **Widget** | `widget_settings_screen.dart` | 1626 | Embed booking-widget config (modes/appearance/platforms) |
| 4 | **Napredno** | `widget_advanced_settings_screen.dart` | 460 | Email-verify, tax/legal disclaimer |

### Drawer / endDrawer / dialogs / wizard / chrome
- **Drawer (left):** `OwnerAppDrawer` (936, shared). **endDrawer (mobile/tablet):** custom `Drawer` → `_buildMasterPanel()` 280px, `sectionBackground`.
- **Dialogs (hub):** 3× `AlertDialog` — cannot-delete-property (:806), delete-property (:822), delete-unit (:890). **(wizard):** `AdditionalServiceDialog` (180) + delete-confirm.
- **Unit Wizard:** `unit_wizard_screen.dart` (488) + steps `step_1_basic_info` (430) / `step_2_capacity` (932) / `step_3_pricing` (671) / `step_4_review` (462) + `wizard_progress_bar` (252) / `wizard_navigation_buttons` (113) / `wizard_step_container` (68). Entry via `context.push` (new :726, duplicate :1082, edit :1454). **Publish = `_publishUnit()` :235-366** ⚠️ **FROZEN**.
- **Shared chrome:** `CommonAppBar` (63), `UnitsPremiumHeader` (226), `UnitHubEmptyState` (259), `OwnerAppDrawer` (936), `Bb*` from `redesign.dart`.

---

## §2 — ★ FROZEN INTERSECTION MAP (#1 output) ★

Classified **firsthand** (code, not comments). `SAFE` = chrome/token consumption, restyle OK. `FROZEN` = touching it needs a **per-edit GO**.

| Component | file:line | Class | Evidence (verified) |
|---|---|---|---|
| Hub shell (Scaffold/AppBar/body-bg/premium header/master-detail/master panel/endDrawer) | hub :274-306 | **SAFE** | `pageBackground`/`sectionBackground`/`sectionBorder` tokens; CLAUDE.md: "hub screen-shell chrome … additive-OK". |
| **Osnovno** tab (`_buildBasicInfoTab` + `_buildInfoCard` :1585 + `_buildDetailRow` :1676 + `_buildServicesCard`) | hub :1299-1717 | **SAFE** | NOT the Cjenovnik content; freely editable; has handoff `units.jsx`. |
| Hub dialogs (3× delete/confirm) | hub :806/822/890 | **SAFE** | raw `AlertDialog`; restyle OK. |
| **Cjenovnik SHELL** (Scaffold + `CommonAppBar` + body `Container(gradient: pageBackground)`) | pricing :136-160 | **SAFE** | Verified: zero hardcoded; everything OUTSIDE the body-`Container` = restyle-safe. |
| **Cjenovnik CONTENT** (`_buildMainContent` → base-price section + `_buildSaveButton` "Spremi" + calendar) | pricing :149-160 inward; save :671-685 | 🔒 **FROZEN** | CLAUDE.md "Cjenovnik tab CONTENT — pricing grid + Spremi". `_buildSaveButton`→`_updateBasePrice` (:685). **Note straggler:** still wears `GradientTokens.brandPrimary` purple (:679) — a 120/127 flatten miss, but **FROZEN-located** → GO-gated. |
| **`price_list_calendar_widget.dart`** (entire 2573 — grid, day cells, bulk dialogs) | whole file | 🔒 **FROZEN** | CLAUDE.md. 4 hardcoded hex (`:511-513`, `:1619-20`) are all FROZEN-grid-internal (bulk-selection disabled-state / dialog footer). |
| `unit_pricing_screen.dart` LAYOUT (base-price ↔ calendar arrangement) | pricing :245-301 interior | 🔒 **FROZEN** | operator step-3 listed "unit_pricing_screen.dart layout"; conservative = layout interior frozen, only Scaffold/appbar/body-bg safe. |
| **Widget** tab (`widget_settings_screen.dart`) | whole | **SAFE** | already Bb=13/tok=14; restyle OK (low priority, no handoff). |
| **Napredno** tab (`widget_advanced_settings_screen.dart`) | whole | **SAFE** | audit/129 already assessed clean. |
| Wizard CHROME (progress bar, step container, nav buttons, step UIs) | wizard widgets + steps | **SAFE** | restyle OK; has handoff `wizard.jsx`. `wizard_progress_bar` has 1 hardcoded color (:~? — cheap). |
| **Wizard `_publishUnit()` 2-doc serial write** (DOC1 `createUnit` :321-323 → DOC2 `createDefaultSettings(unitId: savedUnit.id)` :326-333, id from Doc 1 at :331) | wizard :235-366 | 🔒 **FROZEN** | CLAUDE.md "Unit Wizard publish flow (2-doc serial write) — redoslijed kritičan". `step_3_pricing` feeds it → treat its save path FROZEN-adjacent. |
| **`Navigator.push`/`context.push` confirmation/entry** | hub :726/1082/1454 | 🔒 **FROZEN** | CLAUDE.md "Navigator.push za confirmation — NE vraćaj state-based navigaciju". Don't refactor nav. |
| Empty state (`unit_hub_empty_state.dart`) | whole | **SAFE** | restyle OK; **+ robustness** (listtile-asset-fail-robustness-gap) = **separate prod PR**, not bundled. |

**Off-limits this campaign (do NOT code-edit without GO):** Cjenovnik tab CONTENT, `price_list_calendar_widget.dart`, `unit_pricing_screen` layout interior, Wizard `_publishUnit`, Navigator/context.push nav. **Other CLAUDE.md FROZEN items (Timeline z-index/dims, calendar repository) do NOT intersect this hub** — they live in the timeline/calendar screens.

---

## §3 — Handoff coverage

| Handoff | LOC | Depicts | Maps to | Owner-facing |
|---|---|---|---|---|
| `design_handoff/source/units.jsx` | 444 | Units hub **Osnovno**: sidebar property tree, gallery (desktop 2-col), info+capacity+price cards, PriceTiles, Cjenovnik info-banner | Hub shell + **Osnovno** tab | ✅ yes |
| `design_handoff/source/wizard.jsx` | 525 | 4-step create flow (Osnovno→Kapacitet→Fotografije→Objava) | Unit Wizard (full-screen modal) | ✅ yes |
| `design_handoff/source/widget-pricing.jsx` | 344 | Guest checkout pricing breakdown | **NOT owner** — widget/guest | ❌ out of scope |

**Index html:** `id="units"` (3 artboards: desktop/tablet/mobile), `id="unit-wizard"` (7 artboards: 4 desktop steps + tablet + mobile).

**GAPS — no handoff artboard** → these get **design-to-system audit only**, not pixel-fidelity: Cjenovnik tab, Widget tab, Napredno tab, unit edit/detail modal, photo/gallery editor.

⚠️ **Wizard step delta:** handoff = {Osnovno, Kapacitet, **Fotografije**, Objava}; code = {basic_info, capacity, **pricing**, review}. Handoff has a Photos step; code has Pricing as step 3 + Review as step 4. Fidelity note (publish stays FROZEN regardless).

---

## §4 — Design-to-system: what's left ABOVE color

Audit/127 closed the **palette** — fingerprint confirms it: NON-comment hardcoded hex ≈ **0** everywhere except FROZEN internals. So remaining work = **structure / component-adoption / handoff layout**, not color.

```
file                                 LOC  hex rawC grad ctxG  Bb boxD mBtn ink tok   read
unified_unit_hub_screen.dart        1718    0    0    0   10   2   15   10   1   4   ← Bb-LOW, hand-rolled cards/dialogs
unit_pricing_screen.dart             797    0    0    2*   9   0   13    0   2   0   * brandPrimary on FROZEN save btn
price_list_calendar_widget.dart     2573    4🔒  4🔒   0   19   0   21   13   2   0   FROZEN; hex all internal
units_premium_header.dart            227    0    0    0    0   2    1    0   0   6   ✅ clean/tokenized/premium
unit_hub_empty_state.dart            260    0    0    0    0   0    4    1   0   0   no Bb/tok; +robustness PR
unit_wizard_screen.dart              489    0    0    0    0   0    0    0   0   0   pure logic
step_1..4 (wizard)                  431-933 0    0    0  1-3 0-1  3-6  0-3   0  2-11 token-decent
wizard_progress_bar.dart             253    1    1    0    2   0    3    0   1   4   1 hardcoded color (cheap)
widget_settings_screen.dart         1626    0    0    0    1  13   12    0   0  14   ✅ well-adopted, no handoff
widget_advanced_settings_screen     460     0    0    0    1   2    3    2   0   8   ✅ audit/129 clean
```
`ctxG=context.gradients · Bb=distinct Bb* primitives · boxD/mBtn/ink=NON-comment BoxDecoration/MaterialButton/InkWell`

**Headline:** the only meaningful "above color" debt is concentrated in **`unified_unit_hub_screen.dart` itself** (Bb=2 vs 15 BoxDecoration / 10 Material buttons) — the **Osnovno tab cards, master-panel rows, and dialogs are hand-rolled (token-colored) Material, not `Bb*` primitives**. Everything else is already adopted or FROZEN.

---

## §5 — ★ Component-by-component scope proposal ★

**Per-component, NOT a monolithic "redesign the hub" pass.** Each is independently shippable; FROZEN items are walled off. Tags: **SAFE/FROZEN** + **cheap/med/heavy**.

| # | Component / work unit | Class | Cost | Has handoff? | Recommendation |
|---|---|---|---|---|---|
| **A** | Hub shell chrome (scaffold/appbar/bg/premium header/master-detail/endDrawer/OwnerAppDrawer) | SAFE | — | units.jsx (sidebar) | **Near-done** (126 chrome + 127 palette). Only a side-by-side vs `units.jsx` sidebar to confirm. Likely **no-op**. |
| **B** | **Osnovno tab fidelity** (`_buildBasicInfoTab` + cards) — the meat | SAFE | **med→heavy** | ✅ units.jsx | **Primary PR.** Sub-stage: **B1** `_buildInfoCard`/`_buildDetailRow` → `BbCard` + KeyValue primitive (med, structure); **B2** add gallery section (**heavy — needs data check first:** does the unit model expose photos? if not it's a feature, not a restyle); **B3** PriceTile-grid price emphasis + "Kopiraj" button + "Cjenovnik" cross-ref banner (med). |
| **C** | **Cjenovnik tab** | shell SAFE / **content FROZEN** | cheap-but-GO | ❌ (FROZEN structure) | Shell needs **nothing** (already on ladder). The **only** cosmetic item = flatten the `brandPrimary` purple on `_buildSaveButton` (:679) to match 120/127 — but it's **FROZEN-located → explicit per-edit GO required**. Recommend: leave unless operator wants the purple gone. |
| **D** | Widget tab (`widget_settings_screen`) | SAFE | low | ❌ | Already Bb=13/tok=14. **Skip** or light hygiene only. |
| **E** | Napredno tab (`widget_advanced_settings`) | SAFE | low | ❌ | audit/129 clean. **Skip.** |
| **F** | Unit Wizard chrome (progress/steps/nav UI) | SAFE | cheap→med | ✅ wizard.jsx | Optional polish + `wizard_progress_bar` 1-color hygiene. **`_publishUnit` serial-write FROZEN — do not touch.** Note step-order delta (§3). |
| **G** | Empty state (`unit_hub_empty_state`) | SAFE | low | ❌ | Low-priority hygiene. **Robustness fix = separate prod PR** (listtile-asset-fail-robustness-gap), not bundled. |
| **H** | Hub dialogs (delete/confirm) | SAFE | cheap | ❌ | Optional `AlertDialog`→Bb dialog. Low visual priority. |

**Suggested sequencing:** **B** first (only component with a real fidelity target + the actual structural debt), gated behind a data-availability check for the gallery (B2). A is a quick confirm. C/D/E/F/G/H are low-value or FROZEN-gated — bundle opportunistically or skip. **Do not open a "hub redesign" PR.**

---

## §6 — Decisions for operator (before fix phase)

1. **Confirm renumber → `audit/134` / branch `design/134-unit-hub`** (133 taken today). OK to proceed?
2. **Osnovno B2 gallery:** does the unit model/owner app have photo data to render a gallery, or is units.jsx's gallery aspirational? (Determines cheap-restyle vs new-feature.)
3. **Cjenovnik purple save button (C):** want the `brandPrimary` straggler (:679) flattened to match 120/127? It's FROZEN-located → needs your explicit GO. (Default: leave it.)
4. **Scope cut:** approve **B (+A confirm)** as the campaign; defer/skip D/E/F/G/H? Or include any?

**STOP — no code. Awaiting operator review.**

---

## §7 — APPLIED: B (Osnovno tab) + A (shell confirm) — `design/134-unit-hub` (NOT committed)

Scope **B+A, SAFE only**, per operator APPLY + a 7-question alignment interview. Worktree `/tmp/bb-unithub-wt` on `design/134-unit-hub` (off `origin/main` `ec9be53b`). **No commit** (awaiting operator 100/100).

**Aligned decisions (interview):** scope = Osnovno tab + 3 dialogs, **master panel DEFERRED** · gallery desktop-only, render only when ≥1 photo · Vidljivost + Polog **DROPPED** (no backing field — verified in `unit_model.dart`) · extra-bed/pet fees kept as rows · cards desktop+tablet 2-col / mobile stacked · banner **tappable → Cjenovnik tab** · Kopiraj = duplicate · proper l10n keys.

**Changes (`unified_unit_hub_screen.dart` + `app_en.arb`/`app_hr.arb`):**
- `_buildBasicInfoTab` rebuilt to `units.jsx`: gallery (cover + 2×2 of `unit.images`, desktop-only) → header (`unit.name` + subtitle + **Kopiraj** secondary/duplicate + **Uredi** primary) → 2-col `BbCard` Informacije/Kapacitet → full-width Cijena `BbCard` (emphasized PriceTile grid + extra-fee rows + tappable Cjenovnik banner).
- Hand-rolled `_buildInfoCard`/`_buildDetailRow` (AnimatedContainer/BoxDecoration) → `BbCard` + handoff primitives: `_osnovnoCardHeader` (32px tint badge), `_kvRow` (uppercase label; stack-mode for the OPIS prose; status → `BbStatusBadge`), `_priceTile`, `_buildUnitGallery`/`_galleryTile` (`Image.network` + `errorBuilder` fallback), `_buildCjenovnikHint` (`InkWell` → `_tabController.animateTo(1)`).
- 3 dialogs `AlertDialog` → `BbDialog` (delete logic + bool returns preserved; deletes `destructive`; 2 dead `theme` locals dropped).
- l10n: +`unitHubCopy` / `unitHubBasicDataSubtitle` / `unitHubAdvancedPricingHint` (en + hr).

**FROZEN fence honored (0 touch):** Cjenovnik content / `price_list_calendar_widget` / `_buildSaveButton:679` purple / Wizard `_publishUnit` / Navigator.push. Banner = local tab switch only (never reads/writes Cjenovnik). Master panel untouched (deferred).

**Attestation:** `flutter analyze` **0 net-new** (my file: No issues; 3 self-introduced redundant-default infos fixed) · `dart format` clean · full suite **+1535, All tests passed** (exit 0; no test references the hub → nothing to re-point) · `flutter build web --no-tree-shake-icons` **clean**.

**Live render** (bookbed-dev `:8094`; `scripts/seed-osnovno-eyeball-dev.js` patches Studio B + 5 `data:` photos + 2 services; chrome-devtools / CanvasKit): Osnovno **verified all 6 — desktop/tablet/mobile × light/dark.** Gallery (desktop-only) + header + Bb cards + emphasized €120 tile + fee rows + tappable banner faithful to `units.jsx`; mobile stacks + ellipsizes (no overflow); dark = `#000` page + `#1E1E1E` cards (audit/127 ladder). Console **0 errors**.

**Interaction-verified LIVE** (chrome-devtools semantic taps — screenshots prove layout, these prove wiring; same class as the audit/132 silently-unwired call site):
- **Banner tap** → selected tab flips `Osnovno`→`Cjenovnik` (`_tabController.animateTo(1)` fires); Cjenovnik renders its own FROZEN pricing screen → banner only *links*, never touches Cjenovnik content.
- **Delete dialog** → opens a `BbDialog` (premium modal, NOT Material `AlertDialog`); **Odustani** leaves the unit (`pop(false)` → no delete); **Obriši** deletes it — **Firestore `exists:false` confirmed** — on a throwaway `SEED_del_me` unit (now removed). Both bool paths proven; delete logic unchanged from original.
- **Conditional rendering** confirmed by contrast: minimal €1 unit (no images/desc/fees) → no gallery, no OPIS row, only price+min tiles, no fee rows; Studio B → all present.

**NOT live-exercised:** real Firebase-Storage gallery photo (render used `data:` seed photos — `img-src` blocks external URLs; the `Image.network` + `errorBuilder` path is exercised, and `firebasestorage.googleapis.com` IS CSP-allowed, but no unit with real Storage URLs was seeded this pass).

**Pending operator:** eyeball + 100/100 → commit (+ CHANGELOG). Deferred: master-panel Bb-migration (own pass); Services-card primitives are the same `_osnovnoCardHeader`/`_kvRow` already shown in the other cards.

---

## §8 — APPLIED: F (Unit Wizard chrome) — `design/134-unit-wizard` (squash-merged)

Scope **F only**, per operator APPLY (`dalje`). Worktree `/tmp/bb-unit-wizard-wt` on `design/134-unit-wizard` (off `origin/main` `54f0820a`). §4 fingerprint had already scoped the wizard-chrome debt to **"1 hardcoded color (cheap)"** → this is a **1-file polish, not a stepper re-layout** (the icon-led vertical 3-tone treatment is kept — see traps below).

**Changes (`wizard_progress_bar.dart`, +25/−13):**
- **1-color hygiene:** retired `static const _completedColor = Color(0xFF66BB6A)` (off-palette bright Material green) → theme-aware `BBColor.of(context).success` (`#2E7D5B` / `#4FAE7F`), resolved per-build. Applied to completed node bg/border, completed label, completed connector, **and** the mobile `LinearProgressIndicator` fill. Same "done = green" semantic, now on the system success/confirmed palette. Helpers `_buildStepIndicator`/`_buildConnector` gained a `BuildContext` param to resolve the token.
- **Handoff polish:** current step node `BoxDecoration.boxShadow` → `BBShadow.purpleGlow(context)` (handoff `wizard.jsx` stepper `--bb-shadow-purple-sm`) — active-step lift.

**Handoff elements deliberately NOT replicated** (recorded so the boundary is explicit):
- **Stepper "FROZEN" badge** — `wizard.jsx` marks step 4 with a FROZEN chip. That is design-doc **meta-annotation** of the locked publish flow, *not* user-facing UI. Showing owners a "FROZEN" badge is nonsensical → omitted.
- **"Skica spremljena" autosave caption** (footer) — the wizard holds draft state in-memory (`unitWizardNotifierProvider`); nothing persists until `_publishUnit`. The caption would **fabricate** a save that didn't happen → omitted (data-honesty, same principle as the §7 Vidljivost/Polog drop).
- **Step-1 "Odustani" tertiary** — `CommonAppBar` back already closes the pushed route; adding it needs a new callback for marginal value → left out (cheaply addable if wanted).
- **Stepper re-layout** (handoff horizontal label-beside-node + bare step numbers + mobile discrete-segment bar) — beyond §F's "1-color + polish" scope; the current icon-led vertical treatment distinguishes done/current/pending in 3 tones (arguably clearer) and is a working widget → not churned. Available as a follow-up for fuller `wizard.jsx` parity.

**FROZEN fence honored (0 touch):** Wizard `_publishUnit()` 2-doc serial write (`unit_wizard_screen.dart:235–366`) · `CommonAppBar` unification (audit/124–126 deliberate decision) · step-content (`step_1..4`) / `UnitModel`. The progress-bar labels stay l10n-driven (`Info/Capacity/Price/Review`) — the code flow (basic→capacity→pricing→review) differs from the handoff steps (Osnovno→Kapacitet→Fotografije→Objava) by design (§3 step-order delta); only the visual treatment was touched.

**Coverage (new):** `test/.../unit_wizard/wizard_progress_bar_test.dart` — **42 cells** (7 breakpoints × light/dark × 3 step-states: none-done / mixed completed+current / all-done) asserting no RenderFlex overflow + clean token resolve across BOTH render branches (compact `< 600` / full stepper `≥ 600`). No prior coverage existed → additive, nothing re-pointed.

**Attestation:** `flutter analyze` **0 issues** (touched paths) · `dart format` clean · render/overflow **42/42 green** · `flutter build web --release --no-tree-shake-icons` **clean** (the no-flag build trips a *pre-existing* non-const `IconData` in `bb_icon.dart:40` — BbIcon's dynamic `MaterialSymbolsRounded` lookup, unrelated to this change). **Live eyeball** (bookbed-dev `:8097`, worktree branch): operator-gated **light + dark + mobile**. **Dev-only → not deployed.**
