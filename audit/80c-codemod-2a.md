# audit/80c — Token codemod Phase 2a (rename-only, no visual change)

**Date:** 2026-05-28
**Branch:** `redesign/2a-token-codemod`
**Worktree:** `/tmp/bb-rd-2a-wt`
**Base:** `origin/main @ b3951b2a` (post-#543 merge)
**Scope:** Mechanical rename of `lib/core/design_tokens/*` symbols → BB bridge aliases per audit/80b §3. **Zero visual change** — all values preserved through the `@Deprecated` bridges that 00b (#543) added to `tokens.dart`.

---

## §1 TL;DR

| Metric | Value |
|---|---|
| Worklist (non-frozen, non-app_theme) | 80 files |
| **Fully migrated** (legacy import dropped) | **54 files** ✅ |
| Partially migrated (BB import added, Group B leftovers remain) | 26 files |
| Frozen + skipped | 15 calendar/timeline + 1 Cjenovnik = 16 files (untouched per CLAUDE.md) |
| Total design_tokens importers (post-codemod) | 49 (was 96; -47) |
| Total `core/design/tokens.dart` importers | 75 (was 0 for BB tokens via this path) |
| `flutter analyze lib/` | 0 errors, 0 warnings, **91 infos** (90 intentional `@Deprecated` bridge flags + 1 pre-existing) |
| `flutter test` | **+1205 All tests passed** ✅ |
| `flutter analyze` errors | **0** ✅ |
| `flutter analyze` warnings | **0** ✅ |
| **Visual change** | **ZERO** (all renames use exact-value bridges) |

The 90 `'medium' is deprecated` / `'subtle' is deprecated` infos are the snap-review surface from audit/80b §5 — each one tells Phase 2a-cont exactly where a value SNAP would change pixels.

---

## §2 What was done — Group A symbol renames (sed/perl batch)

Cleanly renamed via word-boundary pattern matches across all 80 worklist files. Every legacy `<Class>.<member>` → corresponding BB equivalent **with exact value preservation** through the `tokens.dart` bridges (#543).

| Old class | Operations |
|---|---|
| `SpacingTokens` | 14 scalar tokens + `formFieldGap` |
| `BorderTokens` (width + radius scalars) | 13 entries |
| `TypographyTokens` | 22 entries (fontSizes, lineHeights, letterSpacings, font family, weight aliases) |
| `AnimationTokens` | 25 entries (durations, curves, compound presets) |
| `OpacityTokens` | 16 entries |
| `IconSizeTokens` | 18 entries (sizes + semantic aliases) |
| `ConstraintTokens` (non-calendar) | 34 entries |
| `ShadowTokens` (non-calendar) | 7 entries |
| `GradientTokens` | 8 entries |
| `ColorTokens.{pureBlack, pureWhite}` | → `Colors.black` / `Colors.white` |
| `ColorTokens.<step>` palette | 50+ entries (grey, azure, coral, teal, pink, amber, emerald, slate, sky) |

**Total straight renames:** ~210 per-symbol transforms across ~1100 call-sites.

## §3 What was done — Group B partial (BorderTokens.circular*, semantic radii, EdgeInsets presets)

These require expression-level rewrites (constructor wraps, EdgeInsets inline). Done safely via sed where the rewrite is deterministic:

| Old | Operation | Notes |
|---|---|---|
| `BorderTokens.circularSubtle` | → `BorderRadius.all(Radius.circular(BBRadiusBridges.subtle))` | 4px |
| `BorderTokens.circularSmall` | → `BBRadius.xsAll` | 6px (existing BB const) |
| `BorderTokens.circularMedium` | → `BorderRadius.all(Radius.circular(BBRadiusBridges.medium))` | 8px (off-scale; @Deprecated flag) |
| `BorderTokens.circularRounded` | → `BBRadius.smAll` | 12px (existing BB const) |
| `BorderTokens.circularLarge` | → `BorderRadius.all(Radius.circular(BBRadiusBridges.large))` | 16px (off-scale; @Deprecated flag) |
| `BorderTokens.circularXL` | → `BBRadius.mdAll` | 20px |
| `BorderTokens.{input, button, card, widgetContainer}` | → `BorderRadius.all(Radius.circular(BBRadiusBridges.medium))` | 8px legacy preserved |
| `SpacingTokens.{allXS, allS, allM, allL, allXL}` | → `const EdgeInsets.all(BBSpace.<size>)` | inline |
| `SpacingTokens.{horizontalM/L, verticalM/L}` | → `const EdgeInsets.symmetric(<axis>: BBSpace.<size>)` | inline |
| `SpacingTokens.buttonPadding` | → `const EdgeInsets.symmetric(horizontal: BBSpace.md, vertical: 14)` | vertical 14 preserved off-grid |

---

## §4 What was NOT done (Group B residuals → Phase 2a-cont)

Some patterns require per-call-site judgment (different API shape between legacy and BB):

| Pattern | Count | Why deferred |
|---|---|---|
| `ColorTokens.light.<prop>` / `ColorTokens.dark.<prop>` | 38 refs across ~26 files | API shape diff: `WidgetColorScheme` interface (e.g. `.light.backgroundPrimary`) ≠ `BBColorSet` (e.g. `.surface`). Phase 2a-cont needs per-call translation per audit/80b §3.4.1 mapping. Many call-sites are inside `build(BuildContext context)` methods → `BBColor.of(context).<prop>` works; some are in static helpers without context. |
| `BorderTokens.onlyTop` / `BorderTokens.onlyBottom` / `BorderTokens.only` | 3 refs | Helper functions taking `double` arg; need rewrite to native `BorderRadius.vertical(...)` / `BorderRadius.only(...)`. |
| `ColorTokens.cancelLight` / `cancelDark` / `blockedLight/Dark` / `pastReservation*` | 2 refs in worklist | Calendar status colors — frozen-area leakage into 1 non-frozen file. Audit which file uses them; either move that file into frozen list or migrate per-call to BB equivalent. |
| `ColorTokens.forBrightness(b)` | 1 ref | Runtime function (returns `WidgetColorScheme`); no direct BB equivalent. Rewrite to `BBColor.of(context)` after context plumbing. |

**Phase 2a-cont scope:** 26 files, ~44 refs total, expression-level rewrites. Recommend doing this as a focused PR after operator reviews the `'medium'`/`'subtle'` deprecation flags from this PR.

---

## §5 What was NOT touched

### Frozen — calendar (14 files)
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

### Frozen — Cjenovnik (1 file)
```
lib/features/owner_dashboard/presentation/screens/unit_pricing_screen.dart
```

### Not in scope this PR
- `lib/core/theme/app_theme.dart` — Phase 2b (Inter app-wide).
- `lib/core/design_tokens/*` (12 legacy files) — Phase 3 (deletion gated on calendar+Cjenovnik redesign sweep).

---

## §6 Verification

```
$ cd /tmp/bb-rd-2a-wt
$ git branch --show-current
redesign/2a-token-codemod
$ grep -rl "core/design_tokens" lib test | wc -l
49   # was 96; -47
$ grep -rl "core/design/tokens.dart" lib test | wc -l
75
$ dart run build_runner build --delete-conflicting-outputs
Built with build_runner in ~30s; wrote 99 outputs.
$ flutter analyze lib/
91 issues found (0 errors, 0 warnings, 91 infos — 90 are intentional @Deprecated bridge flags + 1 pre-existing on main)
$ flutter test --no-pub
+1205: All tests passed!
```

### Zero-visual-change argument

The whole rewrite leans on the bridges from #543:
- Every off-grid spacing maps to `BBSpaceBridges.<name>` carrying the exact legacy value (`xxs2=2, xs6=6, sm20=20, lg40=40, xl56=56`).
- Every off-scale radius maps to `BBRadiusBridges.<name>` (`subtle=4, medium=8, large=16`) — **exact same px on the wire**.
- Every animation duration / curve maps to `BBMotionBridges.<name>` carrying exact `Curves.*` / `Duration(...)`.
- Color palette steps are 1:1 hex preservation (`ColorTokens.azure600` = `BBColorPalette.azure600` = `Color(0xFF6B4CE6)`).
- `Colors.black/white` is just a different way to refer to the same `Color(0xFF000000)/0xFFFFFFFF`.

Spot-check candidates (not screenshotted this PR — no live device this session):
- Owner Pregled — uses heavy `SpacingTokens.m/s/xs` + `BorderTokens.radiusRounded` — should render identical.
- Auth login — `SpacingTokens.l/m` + `BorderTokens.radiusMedium` → `BBRadiusBridges.medium` (8) — same px.
- Widget booking summary cards — uses `BorderTokens.circularMedium` heavily → `BorderRadius.all(Radius.circular(BBRadiusBridges.medium))` (8) — same px.

Phase 2a-cont after merge should re-run a visual spot-check to confirm.

---

## §7 Files changed this PR

```
~78 files modified (Dart source)
+1 file created (audit/80c-codemod-2a.md)
0 files deleted
```

**Outside scope (unchanged):** `lib/core/design/tokens.dart` (no Phase 2 changes — #543 set the bridges), `lib/core/theme/app_theme.dart` (Phase 2b), `lib/core/design_tokens/*.dart` (12 files), `pubspec.yaml`, `firestore.rules`, all functions/, all tests.

---

## §8 Hand-off to next phase

**Phase 2a-cont** (small focused PR — Claude Code or Jules):
- Migrate the 26 files with Group B residuals per audit/80b §3.4.1 mapping table
- Rewrite `ColorTokens.light/dark.<prop>` → `BBColor.of(context).<prop>` (context-aware)
- Rewrite `BorderTokens.onlyTop(x)` → `BorderRadius.vertical(top: Radius.circular(x))`
- Find the 1 non-frozen leak using `ColorTokens.cancelLight/Dark` — either move to frozen or migrate

**Phase 2b** (separate PR — Claude Code):
- Rewire `lib/core/theme/app_theme.dart`:
  - `AppTypography.textTheme` → `BBType`-based TextTheme (Inter app-wide)
  - `ColorScheme.light/dark` sourcing `BBColor.light`/`dark`
- Closes audit/542-verdict point C (Inter only in primitives → Inter everywhere)

**Phase 3** (calendar+Cjenovnik redesign sweep):
- Migrate the 15 frozen files
- Delete `lib/core/design_tokens/*.dart` (12 files) when grep finally returns 0

---

## §9 Snap-review surface (operator decision sheet)

The 90 `@Deprecated` info hints surfaced by this PR fall into these bands. Phase 2a-cont can either KEEP the off-scale bridges (zero visual change) or SNAP to the nearest BB token (visible delta).

| Bridge | Old value | Snap candidate | Hit count this PR | Visual delta |
|---|---|---|---|---|
| `BBRadiusBridges.medium` | 8px | `BBRadius.sm` (12) for buttons/inputs (mandate); `BBRadius.md` (20) for cards | ~62 hits | +4px buttons/inputs, +12px cards — **highest impact** |
| `BBRadiusBridges.subtle` | 4px | `BBRadius.xs` (6) | ~4 hits | +2px (subtle) |
| `BBRadiusBridges.large` | 16px | `BBRadius.md` (20) | ~3 hits | +4px (modest) |
| `BBSpaceBridges.xxs2` | 2px | `BBSpace.xxs` (4) | ~30 hits | +2px in microspacing |
| `BBSpaceBridges.xs6` | 6px | `BBSpace.xs` (8) | ~6 hits | +2px |
| `BBSpaceBridges.sm20` | 20px | `BBSpace.sm`/`md` (16/24) | ~4 hits | ±4px |

Each row is a Y/N for Phase 2a-cont. Defaulting to "keep bridges" = zero visual delta (recommended for a first migration pass). Snap decisions later when redesign sweep takes that surface.
