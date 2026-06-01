# audit/105 — Foundation primitive consistency audit (2026-06-01)

**Scope:** `lib/shared/widgets/redesign/*.dart` — 23 Bb\* primitives delivered by Phase 1.x (PRs #611/#624/#625/#626/#627/#629).
**Lens:** test coverage, validator-API consistency, design-token hygiene, reduced-motion gating.
**Mode:** READ-ONLY. No code changes in this PR — findings drive Phase 1.5 follow-ups.
**Predecessors:** `audit/103-redesign-tokens-primitives-shell.md` (foundation delivery), `audit/104-phase2-screen-readiness.md` (Phase 2 swap matrix).

---

## 1. Headline

| Axis | Score | Notes |
|---|---|---|
| **Test coverage** | 4 / 23 (17%) | Only validator-bearing trio + `BbSwitch` tested. 19 primitives untested. |
| **Validator-API consistency** | 2 / 3 fully consistent | `BbInput` + `BbCheckbox` mirror exactly; `BbRadioGroup` diverges on `error` override + render-path. |
| **Token hygiene** | mixed | 8 raw `Color(0x…)` overlays (mostly handoff-justified); ~35 off-scale `EdgeInsets` numeric literals (heaviest in `bb_sidebar.dart`). |
| **Reduced-motion gating** | 7 / 8 animated paths gated | All `BBMotion.adapt(context, …)` (auto-collapses to `Duration.zero`) or explicit `BBMotion.reduced(context)` (skeleton). **Gap:** `BbSpinner` rotation is OS-level (`CircularProgressIndicator` material delegate) — ungated. |

---

## 2. Per-primitive table

Legend — `✓` clean, `~` partial, `✗` gap, `n/a` not applicable.

| Primitive | LoC | Test | API consistent | Token clean | Reduced-motion | Notes / gaps |
|---|---:|:---:|:---:|:---:|:---:|---|
| `bb_app_bar.dart` | 249 | ✗ | n/a | ✗ raw `EdgeInsets.symmetric(horizontal: 20/2/5)` (L94, L157, L224) | n/a (no anim) | Off-scale 20/2/5 spacing — promote to `BBSpace` or extend scale. |
| `bb_avatar.dart` | 119 | ✗ | n/a | ~ `Color(0x2EFFFFFF)`, `Color(0x33FFFFFF)` shadow (L56, L113) | n/a | Opacity overlays — candidate `BBColor.overlayLight` token. |
| `bb_avatar_slot.dart` | 72 | ✗ | n/a | ~ `Color(0x40FFFFFF)` default `ringColor` (L18) | n/a | Same overlay-token candidate. |
| `bb_bottom_sheet.dart` | 76 | ✗ | n/a | ✗ raw `EdgeInsets.fromLTRB(20, 12, …)` (L54, L59, L65) | n/a | Off-scale 12 (could use `BBSpace.xs2`), 20 (no token). |
| `bb_button.dart` | 271 | ✗ | n/a | ~ `Color(0x29FFFFFF)`, `Color(0x38FFFFFF)` glass-mode bg/border (L170, L172) | ✓ `AnimatedContainer` w/ `BBMotion.adapt(…fast)` (L230) | Hover-only state (no scale/opacity tween on press); intentional. |
| `bb_card.dart` | 143 | ✗ | n/a | ✗ raw `EdgeInsets.all(20)` (L72) | ✓ `AnimatedContainer` w/ `BBMotion.adapt(…fast)` (L113) | 20px padding off-scale; widely used `padded` default. |
| `bb_checkbox.dart` | 247 | ✓ `bb_checkbox_test.dart` (toggle / disabled / validator / autovalidate / error-precedence) | ✓ mirrors `BbInput` exactly (`FormField<bool>` conditional, `_buildChrome(validatorError:)`, `effectiveError = widget.error ?? validatorError`) | ~ raw `EdgeInsets.only(top: 2)` (L171) | ✓ `AnimatedContainer` + `AnimatedOpacity` w/ `BBMotion.adapt(…fast)` (L167, L183) | API gold-standard. |
| `bb_chip.dart` | 138 | ✗ | n/a | ✗ raw `EdgeInsets.symmetric(horizontal: 6)` (L104) | n/a | Off-scale 6px. |
| `bb_dialog.dart` | 86 | ✗ | n/a | — | n/a | Visually-trivial wrapper; low risk. |
| `bb_empty_state.dart` | 189 | ✗ | n/a | ✗ raw `EdgeInsets.all(20)`, `.only(bottom: 8/12)` (L68, L158, L170) | n/a | 12 → `BBSpace.xs2`; 20 → no token. |
| `bb_icon.dart` | 59 | ✗ | n/a | — | n/a | Thin wrapper; deferring tests acceptable. |
| `bb_input.dart` | 293 | ✓ `bb_input_form_test.dart` (validator / autovalidate / error-precedence) | ✓ canonical validator-pattern reference | ~ raw `EdgeInsets.symmetric(horizontal: 14)`, `.only(top: 6)` (L205, L266) | n/a (no anim — focus rebuild only) | 14/6 off-scale; rest of chrome on tokens. |
| `bb_logo.dart` | 37 | ✗ | n/a | — | n/a | Static asset; tests low value. |
| `bb_radio.dart` | 267 | ✓ `bb_radio_test.dart` (group dedup / validator / autovalidate) | ~ **diverges**: no `this.error` explicit override field; inline error render at L251–258 (not via shared chrome). Otherwise validator-pattern matches. | ~ raw `EdgeInsets.only(top: 2/6)` (L81, L253 mixed w/ `BBSpace.xxs`) | ✓ `AnimatedContainer` + `AnimatedScale` w/ `BBMotion.adapt(…fast)` (L77, L92) | **Phase 1.5 candidate** — see §3.2. |
| `bb_scaffold.dart` | 205 | ✗ | n/a | — | n/a | Shell wrapper; visual regression hard to unit-test. |
| `bb_section_header.dart` | 101 | ✗ | n/a | ✗ raw `EdgeInsets.only(bottom: 2)` (L56) | n/a | Off-scale 2px. |
| `bb_sidebar.dart` | 546 | ✗ | n/a | ✗ **heaviest offender** — 14 raw EdgeInsets sites, 2 raw `Color(0x0D101828)` / `Color(0x2914182D)` shadows (L265, L270) | ✓ `AnimatedRotation` w/ `BBMotion.adapt(…fast)` (L297) | 546L untested; expand-chevron is sole anim. |
| `bb_sidebar_rail.dart` | 179 | ✗ | n/a | ✗ raw `EdgeInsets.symmetric(vertical: 16/horizontal: 4)` (L49, L150) | n/a | 16 → `BBSpace.sm`; 4 → `BBSpace.xxs`. Easy migration. |
| `bb_skeleton.dart` | 79 | ✗ | n/a | — | ✓ **explicit** `BBMotion.reduced(context)` gate at L42 (returns static box); 1400ms shimmer otherwise | Only primitive with explicit reduce-motion branch (vs `adapt()` collapse). |
| `bb_sparkline.dart` | 125 | ✗ | n/a | — | n/a (static `CustomPainter`) | No animation. |
| `bb_spinner.dart` | 31 | ✗ | n/a | — | ✗ **gap** — `AlwaysStoppedAnimation<Color>` freezes the **color** tween only; the underlying `CircularProgressIndicator` rotation is driven by the material delegate and is **not** observed by `BBMotion`. Reduce-motion users still see continuous rotation. | Needs `BBMotion.reduced(context)` guard returning a static glyph (filled circle / hourglass icon) instead of the spinning indicator. |
| `bb_status_badge.dart` | 109 | ✗ | n/a | ✗ raw `EdgeInsets.symmetric(horizontal: 10)` (L82) | n/a | 10 off-scale. |
| `bb_switch.dart` | 141 | ✓ `bb_switch_test.dart` (toggle / disabled / animation completes under reduce-motion) | n/a — pure on/off, no validation surface (intentional — toggle UX) | ~ raw `EdgeInsets.all(2)` (L64), `Color(0x29000000)` thumb shadow (L77, JSX-handoff comment) | ✓ `AnimatedContainer` + `AnimatedAlign` w/ `BBMotion.adapt(…base)` (L54, L65) | Cleanest animated primitive. |

---

## 3. Findings

### 3.1 — Test gap (P1)
**Coverage 4 / 23 primitives (17%).** Only the validator-bearing trio (`BbInput` / `BbCheckbox` / `BbRadio`) plus `BbSwitch` have widget tests.

**Highest-leverage gaps** (animation, interaction surface, churn):
1. `BbButton` (271L) — hover-state + glass-mode visual variants, no test of disabled vs press vs hover precedence.
2. `BbCard` (143L) — animated lift on `lifted` prop, untested.
3. `BbSkeleton` (79L) — sole primitive with explicit `BBMotion.reduced(…)` branch; needs assertion that reduced-motion path renders static (no `AnimationController` ticking).
4. `BbSidebar` (546L) — largest primitive, fully untested; expand-chevron rotation gate.
5. `BbChip`, `BbStatusBadge`, `BbEmptyState`, `BbBottomSheet` — visual primitives used widely in Phase 2 swaps.

Lower-priority (thin wrappers, static assets): `BbIcon`, `BbLogo`, `BbSpinner`, `BbSparkline`, `BbSectionHeader`.

### 3.2 — `BbRadioGroup` validator-API divergence (P2)
`BbInput` + `BbCheckbox` share a canonical shape:

```
final String? error;                              // explicit override
final FormFieldValidator<…>? validator;           // form integration
final AutovalidateMode? autovalidateMode;
// inside _buildChrome():
final String? effectiveError = widget.error ?? validatorError;
```

`BbRadioGroup` **omits** the `error` explicit-override field — `validator` is the only error source. Server-side errors (e.g., "this slot is no longer available") cannot be surfaced through the group without faking a validator. Also: error render is **inlined** at L251–258 (separate `Padding` + `Text`), whereas the input/checkbox pair share a chrome path.

**Recommendation:** Phase 1.5 PR — add `final String? error;` to `BbRadioGroup`, thread through to inline render (or, ideally, extract a shared `BbFormFieldChrome` helper). Cost: ~15 LoC; symmetry win.

### 3.3 — Off-scale `EdgeInsets` (P2)
~35 raw numeric `EdgeInsets` sites across primitives. `BBSpace` scale: `xxs=4, xs=8, xs2=12, sm=16, md=24, lg=32`. Frequently-used off-scale values:

| Value | Sites | Suggested action |
|---|---:|---|
| `2` | 5 | new `BBSpace.xxs2 = 2`? (or accept inline — micro-rhythm) |
| `5`, `6` | 4 | one-offs; accept inline |
| `10` | 4 | new `BBSpace.xs2_5 = 10`? or refactor to `8 + 12` rhythm |
| `12` | 5 | **use `BBSpace.xs2`** — pure migration win |
| `14` | 1 | one-off (`bb_input.dart:205` chrome padding) |
| `16` | 2 | **use `BBSpace.sm`** |
| `18` | 1 | one-off |
| `20` | 7 | new `BBSpace.md2 = 20`? widely used (card, app_bar, empty_state, bottom_sheet) |

`bb_sidebar.dart` carries 14 of the 35 sites — single-file cleanup high-impact.

**Recommendation:** Phase 1.5 PR — (a) migrate the `12 → xs2` and `16 → sm` sites mechanically; (b) decide whether to extend `BBSpace` with `xxs2=2` + `md2=20` constants, or accept the off-scale rhythm. `bb_sidebar.dart` is a new Phase 1 primitive (not on the `CLAUDE.md` NIKADA NE MIJENJAJ list) but is 546L with no test coverage — pair the spacing migration with design-owner review and land **after** 1.5a's sidebar smoke test, not in the same mechanical sweep.

### 3.4 — Raw `Color(0x…)` overlays (P3)
8 sites total:

| File | Color | Justified? |
|---|---|---|
| `bb_avatar.dart:56,113` | `0x2EFFFFFF`, `0x33FFFFFF` | white-on-dark ring + shadow overlays |
| `bb_avatar_slot.dart:18` | `0x40FFFFFF` | default `ringColor` |
| `bb_button.dart:170,172` | `0x29FFFFFF`, `0x38FFFFFF` | glass-mode bg/border |
| `bb_sidebar.dart:265,270` | `0x0D101828`, `0x2914182D` | shadow layers — JSX handoff verbatim |
| `bb_switch.dart:77` | `0x29000000` | thumb shadow — inline `// handoff JSX` comment |

All eight are opacity overlays where `colorScheme` blending would produce different visuals. **Recommendation:** Phase 1.5 — add `BBColor.overlay*` (e.g., `overlayWhite16/24/40`, `overlayShadowSm/Md`) tokens, replace in place. Keeps current pixel output, gains semantic source. P3 — cosmetic.

### 3.5 — Reduced-motion: 7 / 8 animated paths gated (1 gap)
Seven of eight animated primitives (`BbButton`, `BbCard`, `BbCheckbox`, `BbRadio`, `BbSidebar`, `BbSkeleton`, `BbSwitch`) call `BBMotion.adapt(context, …)` (auto-collapses to `Duration.zero` when reduced) or an explicit `BBMotion.reduced(context)` guard (`bb_skeleton.dart:42` — returns static box, never starts the 1400ms shimmer).

**Gap: `BbSpinner`.** `AlwaysStoppedAnimation<Color>` only stops the `valueColor` tween; the rotation animation lives inside the material `CircularProgressIndicator` delegate and ticks regardless of `BBMotion`. Reduce-motion users still see continuous rotation. **Fix:** wrap in `if (BBMotion.reduced(context)) return staticGlyph;` early-return inside `BbSpinner.build` — see §4 1.5f.

`BBMotion.reduced` (`lib/core/design/tokens.dart:594`) checks both `MediaQuery.disableAnimations` AND `SchedulerBinding.…accessibilityFeatures.reduceMotion` — covers system-level + per-app toggles.

---

## 4. Phase 1.5 recommendation (proposed PRs)

| ID | Scope | Cost | Priority |
|---|---|---|---|
| **1.5a** | Widget tests for `BbButton` + `BbCard` + `BbSkeleton` + `BbSidebar` expand-chevron | ~250 LoC tests | P1 — unblocks safe Phase 2 refactors |
| **1.5b** | `BbRadioGroup` — add `String? error` override + share chrome path with `BbInput`/`BbCheckbox` (or extract `BbFormFieldChrome`) | ~30 LoC + 2 tests | P2 — API symmetry |
| **1.5c** | Off-scale `EdgeInsets` sweep — mechanical `12 → BBSpace.xs2`, `16 → BBSpace.sm` outside `bb_sidebar.dart`; extend `BBSpace` w/ `xxs2=2, md2=20` if desired | ~40 line touches | P2 — token hygiene |
| **1.5d** | `BBColor.overlay*` tokens for 8 raw `Color(0x…)` overlay sites | ~10 LoC tokens + replace | P3 — cosmetic |
| **1.5e** | Smoke tests for the remaining 10 visual primitives (`BbChip`, `BbStatusBadge`, `BbEmptyState`, `BbBottomSheet`, `BbDialog`, `BbAvatar*`, `BbSectionHeader`, `BbSparkline`, `BbAppBar`, `BbScaffold`) — "renders without throwing" + token-application | ~400 LoC tests | P2 — pre-Phase-2 regression net |
| **1.5f** | `BbSpinner` reduce-motion gate — early-return static glyph when `BBMotion.reduced(context)` (CircularProgressIndicator rotation is ungated otherwise) | ~10 LoC + 1 test | P2 — a11y correctness |

**Order:** 1.5a + 1.5f (a11y + test gap, parallel; close Phase 2 risk) → 1.5b (API symmetry — touches public API, do early) → 1.5c + 1.5d (cosmetic, batchable) → 1.5e (broad smoke net).

---

## 5. Out of scope here (not investigated)

- Golden image tests / pixel parity vs Figma — needs design owner pairing.
- `BbAvatarUpload` — Phase 1.4 addition not located in `lib/shared/widgets/redesign/`; mirror-vs-wrap status owned by `memory/avatar-picker-logic-duplication.md`, separate Phase 1.5 path.
- `lib/core/design/tokens.dart` itself — assumed `audit/103` foundation correct.
- FROZEN areas (calendar, Cjenovnik, unit_pricing) — covered by `CLAUDE.md` NIKADA NE MIJENJAJ contract.
- Integration with `app_router.dart`, theme-extension wiring — Phase 2 territory (`audit/104`).

---

## 6. Cross-refs
- `audit/103-redesign-tokens-primitives-shell.md` — foundation delivery
- `audit/104-phase2-screen-readiness.md` — Phase 2 swap matrix
- `memory/redesign-phase1-foundation.md`
- `memory/canvaskit-tier3-screenshot-policy.md` — Phase 2 verification policy
- `memory/avatar-picker-logic-duplication.md` — `BbAvatarUpload` exception
- `.claude/rules/ui-ux.md` — animation tokens, dialog standards
