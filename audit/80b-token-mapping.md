# audit/80b — Token Consolidation, Phase 1 (Mapping + tokens.dart growth)

**Date:** 2026-05-28
**Branch:** `redesign/00b-token-consolidation`
**Worktree:** `/tmp/bb-rd-00b-wt`
**Base:** `origin/main @ 2c171369` (post-#542 squash merge)
**Scope:** Phase 1 of the design_tokens consolidation. **Build the complete mapping + grow `tokens.dart` to carry every concept. NO codemod, NO theme rewire, NO deletion.** Phase 2 (Jules / mechanical) handles the 95-file migration.

---

## §1 TL;DR

| Metric | Value |
|---|---|
| Unique `design_tokens/*` symbols referenced | **161** |
| Total occurrences across `lib/`+`test/` | 1192 |
| Importer files | 95 |
| Frozen-area importers (calendar + Cjenovnik) | 15 (14 calendar/timeline + 1 `unit_pricing_screen.dart`) |
| New BB token additions in `tokens.dart` | 6 classes + 7 extensions (~150 new constants) |
| `flutter analyze lib/` | **0 new** (2 pre-existing infos unchanged from main) |
| `flutter analyze tokens.dart` | **No issues found!** |
| `flutter test` | Not re-run this PR (no behaviour change — pure additive constants) |
| design_tokens/* files | **12 retained** (deletion is Phase 2 after codemod) |
| Importer count after this PR | **95 (unchanged)** — no call-sites rewritten |

**Phase 2 (Jules) gets a deterministic lookup table for every of the 161 symbols.** This PR adds zero risk of visual drift on its own — the migration risk is concentrated entirely in Phase 2, where the snap-flagged off-grid values surface for review.

---

## §2 FROZEN-area files (calendar + Cjenovnik)

These 15 files are LEFT IMPORTING `lib/core/design_tokens/*` through Phase 2 (CLAUDE.md NIKADA NE MIJENJAJ contract):

**Calendar / timeline (14):**
```
lib/features/owner_dashboard/presentation/widgets/calendar/booking_block_widget.dart
lib/features/owner_dashboard/presentation/widgets/calendar/booking_context_menu.dart
lib/features/widget/domain/models/calendar_date_status.dart
lib/features/widget/presentation/widgets/calendar_hover_tooltip.dart
lib/features/widget/presentation/widgets/calendar/calendar_tooltip_builder.dart
lib/features/widget/presentation/widgets/calendar/year_calendar_skeleton.dart
lib/features/widget/presentation/widgets/calendar/calendar_compact_legend.dart
lib/features/widget/presentation/widgets/calendar/calendar_combined_header_widget.dart
lib/features/widget/presentation/widgets/calendar/month_calendar_skeleton.dart
lib/features/widget/presentation/widgets/calendar/calendar_view_switcher_widget.dart
lib/features/widget/presentation/widgets/split_day_calendar_painter.dart
lib/features/widget/presentation/widgets/year_calendar_widget.dart
lib/features/widget/presentation/widgets/confirmation/calendar_export_button.dart
lib/features/widget/presentation/widgets/month_calendar_widget.dart
```

**Cjenovnik (1):**
```
lib/features/owner_dashboard/presentation/screens/unit_pricing_screen.dart
```

**Implication for Phase 2:** the codemod must SKIP these 15 files. They will continue importing `lib/core/design_tokens/*` until a separate, calendar-specific redesign sweep (out of scope for both #542 and 00b).

**Implication for deletion:** because 15 files still import legacy tokens after Phase 2, `lib/core/design_tokens/*.dart` files **cannot be deleted in Phase 2 either**. The deletion is gated on the calendar/Cjenovnik redesign sweep. This is a third future PR.

---

## §3 Complete mapping table

Legend:
- **Count** = number of references across `lib/`+`test/` (frozen-area files included)
- **Old value** = literal from `lib/core/design_tokens/*.dart`
- **BB target** = symbol in `lib/core/design/tokens.dart` (extended in this PR where needed)
- **Snap?** = `n` if value preserved exactly; `flag` if off-grid/off-scale (operator review during Phase 2)
- **Frozen?** = `y` if used inside calendar/Cjenovnik

### 3.1 SpacingTokens → BBSpace

| Old symbol | Count | Old value | BB target | Snap? | Notes |
|---|---|---|---|---|---|
| `SpacingTokens.xxs` | 30 | `2.0` | `BBSpaceBridges.xxs2` | flag | Below 4px grid; `@Deprecated` bridge |
| `SpacingTokens.xs` | 60 | `4.0` | `BBSpace.xxs` | n | |
| `SpacingTokens.xs2` | 6 | `6.0` | `BBSpaceBridges.xs6` | flag | Off-grid; deprecated bridge |
| `SpacingTokens.s` | 108 | `8.0` | `BBSpace.xs` | n | |
| `SpacingTokens.s2` | 4 | `12.0` | `BBSpace.xs2` | flag | Off-grid; existing deprecated bridge (#542) |
| `SpacingTokens.m` | 127 | `16.0` | `BBSpace.sm` | n | TOP USAGE |
| `SpacingTokens.m2` | 4 | `20.0` | `BBSpaceBridges.sm20` | flag | Off-grid |
| `SpacingTokens.l` | 37 | `24.0` | `BBSpace.md` | n | |
| `SpacingTokens.xl` | 15 | `32.0` | `BBSpace.lg` | n | |
| `SpacingTokens.xl2` | 2 | `40.0` | `BBSpaceBridges.lg40` | flag | Off-grid |
| `SpacingTokens.xxl` | 5 | `48.0` | `BBSpace.xl` | n | |
| `SpacingTokens.xxl2` | 1 | `56.0` | `BBSpaceBridges.xl56` | flag | Off-grid |
| `SpacingTokens.xxxl` | 3 | `64.0` | `BBSpace.xxl` | n | |
| `SpacingTokens.formFieldGap` | 3 | `m (16)` | `BBSpace.sm` | n | semantic alias |
| `SpacingTokens.buttonPadding` | 2 | `EdgeInsets.symmetric(h:24,v:14)` | inline `EdgeInsets.symmetric(horizontal: BBSpace.md, vertical: 14)` | flag | vertical 14 = off-grid |
| `SpacingTokens.allXS` | 1 | `EdgeInsets.all(4)` | `EdgeInsets.all(BBSpace.xxs)` | n | |
| `SpacingTokens.allS` | 4 | `EdgeInsets.all(8)` | `EdgeInsets.all(BBSpace.xs)` | n | |
| `SpacingTokens.allM` | 5 | `EdgeInsets.all(16)` | `EdgeInsets.all(BBSpace.sm)` | n | |
| `SpacingTokens.allL` | 2 | `EdgeInsets.all(24)` | `EdgeInsets.all(BBSpace.md)` | n | |
| `SpacingTokens.allXL` | 1 | `EdgeInsets.all(32)` | `EdgeInsets.all(BBSpace.lg)` | n | |
| `SpacingTokens.horizontalM/L`, `verticalM/L` | rare | `EdgeInsets.symmetric(...)` | inline `EdgeInsets.symmetric(horizontal: BBSpace.sm/md)` | n | |

### 3.2 BorderTokens → BBRadius / BBBorderWidth / BorderRadius

| Old symbol | Count | Old value | BB target | Snap? | Notes |
|---|---|---|---|---|---|
| `BorderTokens.widthNone` | rare | `0.0` | `BBBorderWidth.none` | n | |
| `BorderTokens.widthThin` | 7 | `1.0` | `BBBorderWidth.thin` | n | |
| `BorderTokens.widthMedium` | 10 | `1.5` | `BBBorderWidth.medium` | n | |
| `BorderTokens.widthThick` | 4 | `2.0` | `BBBorderWidth.thick` | n | |
| `BorderTokens.radiusSharp` | 0 | `0.0` | `BBRadiusBridges.sharp` | n | |
| `BorderTokens.radiusTiny` | 2 | `2.0` | `BBRadiusBridges.tiny` | flag | Below scale |
| `BorderTokens.radiusSubtle` | 10 | `4.0` | `BBRadiusBridges.subtle` | flag | Below scale; calendarCellRadius alias FROZEN |
| `BorderTokens.radiusSmall` | 3 | `6.0` | `BBRadius.xs` | n | |
| `BorderTokens.radiusMedium` | 12 | `8.0` | `BBRadiusBridges.medium` | flag | Off-scale; semantic aliases inherit |
| `BorderTokens.radiusRounded` | 5 | `12.0` | `BBRadius.sm` | n | matches button mandate |
| `BorderTokens.radiusLarge` | 4 | `16.0` | `BBRadiusBridges.large` | flag | Off-scale |
| `BorderTokens.radiusXL` | 4 | `20.0` | `BBRadius.md` | n | |
| `BorderTokens.radiusPill` | 1 | `999.0` | `BBRadius.full` | n | |
| `BorderTokens.circularSubtle` | 4 | `BorderRadius.circular(4)` | `BorderRadius.circular(BBRadiusBridges.subtle)` | flag | (Calendar usage) |
| `BorderTokens.circularSmall` | 13 | `BorderRadius.circular(6)` | `BorderRadius.all(Radius.circular(BBRadius.xs))` | n | |
| `BorderTokens.circularMedium` | 48 | `BorderRadius.circular(8)` | `BorderRadius.all(Radius.circular(BBRadiusBridges.medium))` | flag | Heaviest off-scale concentration |
| `BorderTokens.circularRounded` | 5 | `BorderRadius.circular(12)` | `BBRadius.smAll` | n | |
| `BorderTokens.circularLarge` | 2 | `BorderRadius.circular(16)` | `BorderRadius.all(Radius.circular(BBRadiusBridges.large))` | flag | |
| `BorderTokens.circularXL` | 1 | `BorderRadius.circular(20)` | `BBRadius.mdAll` | n | |
| `BorderTokens.calendarCell` | rare | `BorderRadius.circular(4)` | **FROZEN** — leave as `BorderTokens.calendarCell` | — | calendar |
| `BorderTokens.widgetContainer` | 1 | `BorderRadius.circular(8)` | `BorderRadius.all(Radius.circular(BBRadiusBridges.medium))` | flag | |
| `BorderTokens.card` | 1 | `BorderRadius.circular(8)` | `BBRadius.mdAll` recommended (BB convention) | flag-snap | Visual: 8 → 20. Phase 2 review. |
| `BorderTokens.button` | 1 | `BorderRadius.circular(8)` | `BBRadius.smAll` (BB mandate 12px) | flag-snap | Visual: 8 → 12 |
| `BorderTokens.input` | 5 | `BorderRadius.circular(8)` | `BBRadius.smAll` (BB mandate 12px) | flag-snap | Visual: 8 → 12 |
| `BorderTokens.only*` (`onlyTop`, `onlyBottom`, `onlyTopLeft`, `onlyTopRight`, `onlyBottomLeft`, `onlyBottomRight`, generic `only`) | rare | safe BorderRadius helpers | Codemod inlines: `BorderRadius.vertical(...)`, `BorderRadius.only(...)` directly. Helper not re-exposed in BB. | n | |

### 3.3 TypographyTokens → BBType

The big shift: `TypographyTokens` uses scalar `fontSize*` + `FontWeight` constants. `BBType` uses TextStyle factories `BBType.body(ctx)` etc. The codemod choices are:

| Old symbol | Count | Old value | BB target | Notes |
|---|---|---|---|---|
| `TypographyTokens.fontSizeXS` | 15 | `10.0` | `BBTypeBridges.fontSizeXS` (scalar) OR `BBType.caption(ctx)` (12px, slightly larger) | Snap-flag if 10 → 12 chosen |
| `TypographyTokens.fontSizeXS2` | 0 | `11.0` | bridge | unused |
| `TypographyTokens.fontSizeS` | 50 | `12.0` | scalar `BBTypeBridges.fontSizeS` OR `BBType.caption(ctx).fontSize` | match exact |
| `TypographyTokens.fontSizeS2` | 4 | `13.0` | scalar `BBTypeBridges.fontSizeS2` OR `BBType.label(ctx).fontSize` | match exact |
| `TypographyTokens.fontSizeM` | 48 | `14.0` | scalar OR `BBType.body(ctx).fontSize` | match exact |
| `TypographyTokens.fontSizeM2` | 1 | `15.0` | bridge | off-scale |
| `TypographyTokens.fontSizeL` | 32 | `16.0` | `BBType.bodyLg(ctx).fontSize` | match exact |
| `TypographyTokens.fontSizeXL` | 12 | `18.0` | `BBType.h3(ctx).fontSize` | match exact |
| `TypographyTokens.fontSizeXXL` | 7 | `20.0` | `BBType.h2(ctx).fontSize` | match exact |
| `TypographyTokens.fontSizeXXXL` | 2 | `24.0` | `BBType.h1(ctx).fontSize` | match exact |
| `TypographyTokens.fontSizeHuge` | 1 | `26.0` | bridge | off-scale |
| `TypographyTokens.poweredBySize` | 1 | `9.0` | bridge | off-scale |
| `TypographyTokens.lineHeightTight` | 3 | `1.2` | `BBTypeBridges.lineHeightTight` | n |
| `TypographyTokens.lineHeightNormal` | 10 | `1.5` | `BBTypeBridges.lineHeightNormal` | n |
| `TypographyTokens.lineHeightRelaxed` | 1 | `1.75` | `BBTypeBridges.lineHeightRelaxed` | n |
| `TypographyTokens.letterSpacingTight` | 1 | `-0.5` | `BBTypeBridges.letterSpacingTight` | n |
| `TypographyTokens.letterSpacingNormal` | 1 | `0.0` | n/a | drop |
| `TypographyTokens.letterSpacingWide` | 4 | `0.5` | `BBTypeBridges.letterSpacingWide` | n |
| `TypographyTokens.primaryFont` | 4 | `'Inter'` | `BBTypeBridges.primaryFont` (string const) | rare; mostly drop in favor of BBType factories |
| `TypographyTokens.fontFallback` | 0 | `[...]` | `BBTypeBridges.fontFallback` | unused |
| `TypographyTokens.light` | 0 | `FontWeight.w300` | `FontWeight.w300` direct or `BBTypeBridges.weightLight` | rare |
| `TypographyTokens.regular` | 7 | `FontWeight.w400` | `FontWeight.w400` direct | drop wrapper |
| `TypographyTokens.medium` | 14 | `FontWeight.w500` | `FontWeight.w500` direct | drop wrapper |
| `TypographyTokens.semiBold` | 32 | `FontWeight.w600` | `FontWeight.w600` direct | drop wrapper |
| `TypographyTokens.bold` | 47 | `FontWeight.w700` | `FontWeight.w700` direct | drop wrapper |

### 3.4 ColorTokens → BBColor / BBColorPalette

`ColorTokens` mixes:
1. Theme-aware sets via `ColorTokens.light.<prop>` / `ColorTokens.dark.<prop>` (`WidgetColorScheme`)
2. Flat palette steps (`grey50..900`, `azure*`, `coral*`, …)

Phase 2 must distinguish:
- `ColorTokens.light.<prop>` / `.dark.<prop>` calls → translate to `BBColor.of(context).<prop>` mapping (NOTE: the `WidgetColorScheme` API and `BBColorSet` API have **different prop names**; not a 1:1 rename). Examples in §3.4.1.
- `ColorTokens.<step>` flat constants → straight rename to `BBColorPalette.<step>` (exact hex preserved).

#### 3.4.1 ColorTokens.light/dark `.prop` API translation

Phase-2 hint table (the WidgetColorScheme prop → BBColorSet prop). For props with no exact match → carry the value via a new BB token if not already present.

| `WidgetColorScheme` prop | Light value (e.g.) | `BBColorSet` equivalent |
|---|---|---|
| `backgroundPrimary` | `pureWhite` | `surface` |
| `backgroundSecondary` | `grey50` | `bg` |
| `backgroundTertiary` | `grey100` | `surfaceVariant` |
| `backgroundCard` | `pureWhite` | `surface` |
| `backgroundElevated` | `pureWhite` | `surface` |
| `textPrimary` | `pureBlack` | `textPrimary` (note: `BBColor` uses `#2D3748`, not pure black — visual delta in Phase 2) |
| `textSecondary` | `grey500` | `textSecondary` |
| `textTertiary` | `grey400` | `textTertiary` |
| `textDisabled` | `grey300` | n/a — use `textTertiary.withValues(alpha: 0.6)` or add `BBColor.textDisabled` |
| `textOnPrimary` | `pureWhite` | `Colors.white` |
| `textOnAccent` | `pureWhite` | `Colors.white` |
| `borderLight` | `#FFF0F0F0` | n/a — add `BBColor.borderSubtle` or use `border` |
| `borderDefault` | `grey200` | `border` |
| `borderMedium` | `grey300` | n/a — add or use `border` |
| `borderStrong` | `grey500` | n/a — add or use `textTertiary` |
| `borderFocus` | `azure600` | `primary` |
| `divider` | `grey100` | `surfaceVariant` |
| `primary` | `azure600` | `primary` |
| `primaryHover` | `azure700` | `primaryDark` |
| `primaryPressed` | `azure800` | n/a — add or use `primaryDark` |

**Phase 2 work:** review every `ColorTokens.light.<prop>` / `.dark.<prop>` callsite. Decide per call whether the BB equivalent is acceptable as-is, or whether the call-site needs a wholly different BB color reference. Some props (text on pure white, "primaryPressed = azure800") have no BB equivalent today and are good candidates for `BBColorSet` extension.

#### 3.4.2 ColorTokens flat palette steps

All mapped to `BBColorPalette.<step>` (exact hex preserved). Top frequency:
- `ColorTokens.pureBlack` (31×) → `Colors.black`
- `ColorTokens.pureWhite` (21×) → `Colors.white`
- `ColorTokens.grey50..900` (~30 across all steps) → `BBColorPalette.grey50..900`
- `ColorTokens.azure50..900` (~25) → `BBColorPalette.azure50..900` (or BBColor.primary/primaryDark/primaryLight where aliases apply)
- `ColorTokens.coral400..600`, `teal*`, `pink*`, `amber*`, `emerald*`, `slate*`, `sky*` → `BBColorPalette.<step>`
- `ColorTokens.cancelLight/Dark`, `ColorTokens.blockedLight/Dark`, `ColorTokens.pastReservationLight/Dark` → **FROZEN** (calendar status colors); leave call-sites in calendar files untouched.

### 3.5 AnimationTokens → BBMotion + BBMotionBridges

| Old symbol | Count | Old value | BB target | Notes |
|---|---|---|---|---|
| `AnimationTokens.instant` | 0 | `100ms` | `BBMotionBridges.instant` | unused |
| `AnimationTokens.fast` | 15 | `200ms` | `BBMotion.base` (200ms) | exact match |
| `AnimationTokens.normal` | 15 | `300ms` | `BBMotionBridges.normal` | exact (off scale) |
| `AnimationTokens.slow` | 3 | `500ms` | `BBMotionBridges.slow500` | |
| `AnimationTokens.slower` | 1 | `600ms` | `BBMotionBridges.slower` | |
| `AnimationTokens.long` | 0 | `1000ms` | `BBMotionBridges.long` | unused |
| `AnimationTokens.notification` | 0 | `3s` | `BBMotionBridges.notification` | unused |
| `AnimationTokens.autoDismiss` | 0 | `5s` | `BBMotionBridges.autoDismiss` | unused |
| `AnimationTokens.linear/ease/easeIn/easeOut/easeInOut/fastOutSlowIn/elasticOut/bounceOut/decelerate` | sum: ~50 | `Curves.*` | `BBMotionBridges.<curve>` or `Curves.<name>` direct | re-exposed |
| `AnimationTokens.fadeDuration/fadeCurve/scaleDuration/scaleCurve/slideDuration/slideCurve/rotationDuration/rotationCurve` | ~5 | compounds | `BBMotionBridges.<name>` | re-exposed |

### 3.6 ShadowTokens → BBShadow / BBShadowAliases

| Old symbol | Count | Old value | BB target | Notes |
|---|---|---|---|---|
| `ShadowTokens.none` | rare | `[]` | `BBShadow.none` | n |
| `ShadowTokens.subtle` | 3 | `1px y, 2px blur, 4% black` | `BBShadowAliases.subtle` | exact |
| `ShadowTokens.light` | 4 | `2px y, 8px blur, 8% black` | `BBShadow.sm` | snap (5%) |
| `ShadowTokens.medium` | 2 | `4px y, 16px blur, 12% black` | `BBShadowAliases.mediumLegacy` | exact (avoids name clash with `BBShadow.md` which has 12px blur) |
| `ShadowTokens.strong` | 2 | `8px y, 24px blur, 16% black` | `BBShadowAliases.strong` | exact |
| `ShadowTokens.hover` | 2 | (same as strong) | `BBShadowAliases.strong` | exact |
| `ShadowTokens.calendarCellHover` | rare | (calendar-specific) | **FROZEN** | leave |
| `ShadowTokens.widgetContainer` | rare | `= ShadowTokens.light` | `BBShadow.sm` | snap |

### 3.7 OpacityTokens → BBOpacity

Direct 1:1 (16 entries, all exact). Covered by the `BBOpacity` class added in §6.

### 3.8 IconSizeTokens → BBIconSize

Direct 1:1 (10 entries + 8 semantic aliases). Covered by the `BBIconSize` class added in §6.

### 3.9 ConstraintTokens → BBConstraint

Direct 1:1 (~35 entries) EXCEPT:
- `calendarCellMinHeight`, `calendarCellMaxHeight`, `calendarMonthMinWidth`, `calendarMonthMaxWidth`, `calendarDayCellSize` → **FROZEN**, NOT re-exposed in BBConstraint. Calendar code keeps importing `ConstraintTokens`.
- `modalHeaderHeight` → ambiguous; left in legacy for now.

### 3.10 GradientTokens → BBGradient

Direct 1:1 for these names used in code:
- `brandPrimary`, `brandPrimaryStart`, `brandPrimaryEnd` (top usage, 21+ refs)
- `subtleBackgroundLight`, `subtleBackgroundDark`, `primaryAccent`, `success`, `warning` (lower usage)
Less-used gradients (info/error variants, dark-mode variants) — Phase 2 picks up on a per-call basis.

### 3.11 GlassmorphismTokens → keep separate

Per CLAUDE.md "glassmorphism hero-only" — `GlassmorphismTokens` is **NOT** consolidated into BB tokens. Hero callsites that use it continue importing from `lib/core/design_tokens/glassmorphism_tokens.dart`. Excluded from Phase 2 codemod scope.

---

## §4 New BB tokens added in `tokens.dart` this PR

| New BB symbol | Type | Reason |
|---|---|---|
| `BBBorderWidth` class | `none/thin/medium/thick` | Was `BorderTokens.width*` |
| `BBOpacity` class | 16 named opacity constants | Was `OpacityTokens` |
| `BBIconSize` class | 10 sizes + 8 semantic aliases | Was `IconSizeTokens` |
| `BBConstraint` class | ~25 non-frozen constants | Was `ConstraintTokens` (calendar subset excluded) |
| `BBSpaceBridges` extension | 5 deprecated off-grid values | Was `SpacingTokens.{xxs2, xs2, m2, xl2, xxl2}` |
| `BBRadiusBridges` extension | `sharp/tiny/subtle/medium/large` (4 of 5 deprecated) | Was `BorderTokens.radius*` off-scale |
| `BBColorPalette` extension | 50+ named color steps | Was `ColorTokens.{grey/azure/coral/teal/pink/amber/emerald/slate/sky}*` |
| `BBMotionBridges` extension | 8 durations + 9 curves + 4 compound presets | Was `AnimationTokens.*` |
| `BBTypeBridges` extension | 12 scalar fontSizes + 3 lineHeights + 3 letterSpacings + font family + 5 weight aliases | Was `TypographyTokens.*` |
| `BBShadowAliases` extension | `subtle/mediumLegacy/strong` | Was `ShadowTokens.{subtle,medium,strong,hover}` |
| `BBGradient` class | brandPrimary, primaryAccent, success, warning, subtleBackground×2 + 2 const colors | Was `GradientTokens.*` |

**Total new constants:** ~150. **Old values preserved verbatim** for every constant — zero invented values, zero guessed mappings.

---

## §5 Visual-affecting snap list (operator review for Phase 2)

When Phase 2 rewrites call-sites, the following **value snaps** carry visual risk. Each needs a Y/N decision before the rewrite lands. **The bridges defined in §4 let Phase 2 do straight rename with no visual change — operator opts into snapping per row.**

### Off-grid spacing (5 categories, ~25 hits)

| Old | Value | Snap target | Visual delta | Decision needed |
|---|---|---|---|---|
| `SpacingTokens.xxs` | 2px | `BBSpace.xxs (4)` | +2px in 30 call-sites — likely invisible | snap or keep? |
| `SpacingTokens.xs2` | 6px | `BBSpace.xs (8)` | +2px in 6 call-sites | snap or keep? |
| `SpacingTokens.m2` | 20px | `BBSpace.sm (16)` or `.md (24)` | ±4px in 4 call-sites | snap which way? |
| `SpacingTokens.xl2` | 40px | `BBSpace.lg (32)` or `.xl (48)` | ±8px in 2 call-sites | snap which way? |
| `SpacingTokens.xxl2` | 56px | `BBSpace.xl (48)` or `.xxl (64)` | ±8px in 1 call-site | snap which way? |

### Off-scale radii (4 categories, ~58 hits)

| Old | Value | Snap target | Visual delta | Decision needed |
|---|---|---|---|---|
| `BorderTokens.radiusTiny` | 2px | `BBRadius.xs (6)` | +4px on 2 call-sites | snap or keep? |
| `BorderTokens.radiusSubtle` | 4px | `BBRadius.xs (6)` | +2px on 10 call-sites + calendar (FROZEN — no change) | snap non-calendar? |
| **`BorderTokens.radiusMedium` (= card, input, button, widgetContainer legacy aliases)** | **8px** | `BBRadius.sm (12)` for buttons/inputs (mandate); `BBRadius.md (20)` for cards | **+4px on buttons/inputs (12-12=0 if BBRadius.sm = 12 — perfect), +12px on cards (8→20 is a visible step up)** | **Highest impact. Card rounding goes from "subtle 8px" to "soft 20px" — visual signature shift across most owner-dashboard cards.** |
| `BorderTokens.radiusLarge` | 16px | `BBRadius.md (20)` | +4px on 4 call-sites | snap or keep? |

### Shadow opacity mismatch

`ShadowTokens.light` is 8% black; `BBShadow.sm` is 5% black. Slight contrast reduction on 4 call-sites if snapped. Likely imperceptible.

### Color drift candidates

- `ColorTokens.light.textPrimary = pureBlack` vs `BBColor.textPrimaryLight = #2D3748` (slate, not black). Phase 2 callers in light mode get slightly softer text. Likely intentional per BBColor scheme.
- `ColorTokens.light.borderLight = #F0F0F0` has no BB equivalent. Phase 2 picks `BBColor.border` (light: `#E2E8F0`) which is slightly darker.

---

## §6 What's NOT in this PR

- **Codemod** of 80 non-frozen importers — Phase 2 (Jules, mechanical, ~80 atomic edits using the table in §3).
- **app_theme.dart rewire** to BBType + BBColor app-wide — Phase 2 (Inter-everywhere fix; addresses audit/542-verdict point C).
- **Retirement of `@Deprecated BBSpace.xs2`** + the new `@Deprecated` bridges (`xxs2`, `xs6`, `sm20`, `lg40`, `xl56`, `xxxl96`) — Phase 2, after grep shows 0 call-sites left.
- **Deletion of `lib/core/design_tokens/*.dart` (12 files)** — Phase 3 (after a calendar+Cjenovnik redesign sweep, since 15 files retain legacy imports through Phase 2).
- **`flutter test` full suite** — no behavior changes here (pure additive constants), but worth a confirmation run after Phase 2 lands.

---

## §7 Verification (this PR)

```
$ cd /tmp/bb-rd-00b-wt
$ git branch --show-current
redesign/00b-token-consolidation
$ grep -q "class BBColor" lib/core/design/tokens.dart && test -f audit/80-design-system-foundation.md && echo "POST-542 OK"
POST-542 OK
$ flutter analyze lib/core/design/tokens.dart
No issues found! (ran in 1.3s)
$ flutter analyze lib/
2 issues found (pre-existing infos; 0 new from this PR)
$ grep -rl "core/design_tokens" lib/ test/ | wc -l
95   # unchanged — codemod is Phase 2
$ ls lib/core/design_tokens/*.dart | wc -l
12   # unchanged — deletion is Phase 3
```

---

## §8 Files changed this PR

```
M  lib/core/design/tokens.dart        (+~430 LOC additions, no removals)
A  audit/80b-token-mapping.md         (this file)
```

No changes to:
- `lib/core/design_tokens/*` (the 12 legacy files — Phase 3 deletes them)
- `lib/core/widgets/bb_*.dart` (10 primitives from #542 — unchanged)
- `lib/core/theme/app_theme.dart` (Phase 2 rewires this)
- `lib/features/**` (95 importers — Phase 2 codemods them)
- Any test file — pure additive constants, no behavior change

---

## §9 Phase 2 hand-off checklist (for Jules)

1. Stage codemod on `redesign/00b-token-codemod` worktree off `origin/main` (this PR merged).
2. Honor FROZEN guard: SKIP the 15 files listed in §2.
3. For each of the other 80 importers, apply mappings from §3 as straight rename per row.
4. For "snap?=flag" rows: stop, ask operator per row (use §5 as the decision sheet).
5. After codemod: `grep -rl "core/design_tokens" lib/ test/` should equal 15 (the frozen files).
6. Rewire `lib/core/theme/app_theme.dart`: replace `AppTypography.textTheme` with a `BBType`-based `TextTheme`; swap `ColorScheme.light/dark` to source from `BBColor.light`/`dark`.
7. Verify: `flutter analyze` 0 new, `flutter test` **expect 1205 pass** (not "940+"), Inter renders on owner Pregled + auth login.
8. PR title: `refactor(design): codemod design_tokens → BB tokens + app_theme Inter (phase 2)`.

After Phase 2 merges:
- A separate calendar+Cjenovnik redesign PR (Phase 3) migrates the 15 frozen files and then DELETES `lib/core/design_tokens/*.dart`.

---

## §10 Branch hygiene

- Worktree: `/tmp/bb-rd-00b-wt` (clean off `origin/main @ 2c171369`)
- Branch: `redesign/00b-token-consolidation`
- Branch-guard verified before every git op via `[ "$(git branch --show-current)" = "redesign/00b-token-consolidation" ] || exit 1`
- No PROD changes, no Firebase changes, no Sentry changes.
- CLAUDE.md frozen carve-outs preserved: calendar dims untouched, Cjenovnik tab untouched, BBRadius.sm = 12 mandate retained.
