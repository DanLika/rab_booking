# audit/80d — Inter font unified app-wide (Phase 2b)

**Date:** 2026-05-28
**Branch:** `redesign/2b-app-theme-inter`
**Worktree:** `/tmp/bb-rd-2b-wt`
**Base:** `origin/main @ b3951b2a` (post-#543)
**Scope:** Close audit/542-verdict point C — Inter only inside BB primitives → Inter everywhere via `ThemeData.textTheme`.

---

## §1 TL;DR

**Single-file change:** `lib/core/theme/app_typography.dart`. Replaced every `GoogleFonts.playfairDisplay(...)` call with `GoogleFonts.inter(...)`. Sizes, weights, letter spacing, line height, italic flags — all preserved. Effect: every Material widget that reads `Theme.of(context).textTheme.<style>` now renders in Inter.

| Metric | Value |
|---|---|
| Files changed | **1** (`lib/core/theme/app_typography.dart`) |
| Font-face change | PlayfairDisplay → Inter (for `display*` + `headline*` slots that previously used Playfair) |
| Size / weight / letter-spacing changes | **None** |
| `flutter analyze lib/` | 2 pre-existing infos, **0 new** ✅ |
| `flutter test --no-pub` | **+1205 All tests passed** ✅ |

---

## §2 What changed exactly

`AppTypography.textTheme` previously mapped:
- `displayLarge` (72/700) → PlayfairDisplay
- `displayMedium` (48/700) → PlayfairDisplay
- `displaySmall` (32/700) → PlayfairDisplay
- `headlineLarge` (32/600) → PlayfairDisplay
- `headlineMedium` (28/600) → PlayfairDisplay
- `headlineSmall` (24/600) → PlayfairDisplay
- `titleLarge` (22/600) → Inter
- `titleMedium..bodySmall..labelSmall` → Inter

Now:
- ALL → Inter (sizes/weights/letterSpacing/height unchanged)

Plus `AppTypography.{quote, testimonial, pullQuote}` (also previously Playfair, italic) → Inter italic. Same sizes/weights.

Plus `AppTypography.headingFont` getter already returned `GoogleFonts.inter().fontFamily!` (no edit needed — this getter was named "headingFont" but had already been switched to Inter previously; just kept).

3 comments mentioning "PlayfairDisplay doesn't have light weights" updated to "switched from PlayfairDisplay to Inter (unified font, audit/80d)" — Inter has all weights, so the historical reason is moot.

## §3 What's NOT in this PR (deferred)

### AppColors → BBColor rename in app_theme.dart
`app_theme.dart` references `AppColors.<token>` 144 times for `ColorScheme.light/dark` + every component theme (AppBar, Card, Input, FAB, etc.). BBColor values are IDENTICAL to AppColors values today (BBColor was built as a delegating namespace in #542). A rename would be value-equivalent but touch 144 lines and is high risk surface for review. **Deferred.** Rationale: the "Inter app-wide" goal (audit/542-verdict point C) is closed by the font swap alone. Color sourcing remains AppColors → still feeds the same hex values into the ColorScheme.

If a future redesign sweep wants to canonicalize on BB tokens for color sourcing too, that's a clean ~144-rename PR with no value drift.

### PlayfairDisplay asset removal from pubspec.yaml
`pubspec.yaml` still lists `assets/google_fonts/PlayfairDisplay-{Regular,SemiBold,Bold,ExtraBold,Italic}.ttf` (5 TTF files). After this PR they're dead-weight in the bundle. **Not removed** here — out of scope for the textTheme fix, and removing assets in the same PR that swaps fonts increases blast radius for review. Recommend: Phase 2b-cont PR that drops the Playfair asset list (5 lines from pubspec + delete 5 TTF files = ~XXX KB bundle reduction).

### Migration of audit/80c §4 Group B residuals (ColorTokens.light/dark, BorderTokens.onlyTop, etc.)
Same as #544 (Phase 2a) — deferred to Phase 2a-cont.

---

## §4 Verification

```
$ cd /tmp/bb-rd-2b-wt
$ git branch --show-current
redesign/2b-app-theme-inter
$ grep -rn "playfairDisplay\|PlayfairDisplay" lib/
lib/core/theme/app_typography.dart:404:  /// 2026-05-28: switched from PlayfairDisplay to Inter (unified font, audit/80d).
lib/core/theme/app_typography.dart:414:  /// 2026-05-28: switched from PlayfairDisplay to Inter (unified font, audit/80d).
lib/core/theme/app_typography.dart:424:  /// 2026-05-28: switched from PlayfairDisplay to Inter (unified font, audit/80d).
# 3 historical-context comments only; zero code references.

$ flutter analyze lib/
2 issues found (pre-existing infos: rate_limit_service.dart:167, web_utils_web.dart:349 — both on main, untouched by 2b)
0 NEW issues

$ flutter test --no-pub
+1205: All tests passed!
```

### Visual change observable in
- Owner Dashboard hero sections (any screen that uses `theme.textTheme.displayLarge/Medium/Small`): font face changes from elegant serif (Playfair) to clean sans-serif (Inter). Sizes unchanged.
- Owner Pregled section headers (`headlineLarge/Medium/Small`): same as above.
- Title/body/label styles: ALREADY Inter pre-PR — no change.
- BB primitives: ALREADY Inter via direct `BBType.*(context)` calls — no change.

### Visual change NOT observable in
- Any Material widget that uses a non-textTheme TextStyle (e.g. custom inline `GoogleFonts.playfairDisplay(...)` calls anywhere in features) — but `grep` confirms there are none in `lib/` outside `app_typography.dart` historical comments.

---

## §5 Closure audit/542-verdict point C

The verdict said:
> Inter only inside primitives, not app-wide

Resolved by this PR:
> `grep -nE "BBType|GoogleFonts|Inter|BBColor" lib/core/theme/app_theme.dart` still returns NONE (intentional — app_theme.dart uses `AppTypography.textTheme.apply(...)` to feed colors, and AppTypography.textTheme is now 100% Inter)
> `grep -rn "playfairDisplay" lib/` returns ZERO code matches (3 historical comments only)
> `Theme.of(context).textTheme.<any style>` everywhere in the app now resolves to Inter

The point-C bug class is closed.

---

## §6 Files changed this PR

```
M  lib/core/theme/app_typography.dart  (+~10 / -~10 — Playfair → Inter rename, 3 comments updated)
A  audit/80d-app-theme-inter.md
```

No changes to: `lib/core/theme/app_theme.dart`, `lib/core/theme/app_colors.dart`, `lib/core/design/tokens.dart`, `lib/core/widgets/bb_*.dart`, `lib/features/**`, `pubspec.yaml`, anything in `functions/`.
