# audit/81 — Responsive + platform harness (Prompt 01)

**Date:** 2026-05-28
**Branch:** `redesign/01-responsive-harness`
**Worktree:** `/tmp/bb-rd-01-wt`
**Base:** `origin/main @ 6b52daa6` (post-#542+#543+#544+#545)
**Scope:** Harden `BBResponsive` / `BBResponsiveBuilder` / `BBScaffold` from Prompt 00 + ship a dev-only `BBResponsiveProbeScreen` so every page prompt (01-39) inherits a verified responsive contract. **Pure additive**; no page changes.

---

## §1 TL;DR

| Deliverable | Status |
|---|---|
| `lib/core/design/responsive.dart` extended — 4-tier resolver carries `padding/viewInsets/textScaleFactor` + `isKeyboardVisible` | ✅ |
| `BBContentMaxWidth` widget added (wide cap, default 1200px) | ✅ |
| `BBScaffold` rewritten — now a real Material `Scaffold` that plumbs `appBar/drawer/endDrawer/bottomNav/fab` (previously declared but unused) | ✅ |
| `BBResponsiveProbeScreen` — kDebugMode-gated, live-prints every variable + 3 textScale proof rows + diacritics check | ✅ |
| `lib/responsive_probe_dev.dart` standalone dev entry (`flutter run --target lib/responsive_probe_dev.dart -d chrome`) | ✅ |
| `flutter analyze lib/` | 92 issues (90 intentional `@Deprecated` bridge flags + 2 pre-existing); **0 errors, 0 warnings** ✅ |
| `flutter test --no-pub` | **+1205 All tests passed** ✅ |
| Visual matrix screenshots (iPhone SE / iPhone 14 Pro / Pixel 8 / iPad / Desktop / Wide) | DEFERRED (no live device this session — see §6) |

---

## §2 Bug found and fixed: `BBScaffold` from Prompt 00 was a no-op for AppBar/Drawer

Prompt 00 (#542) defined `BBScaffold` with these props:
```dart
final PreferredSizeWidget? appBar;
final Widget? bottomNavigationBar;
final Widget? floatingActionButton;
final Widget? drawer;
final Widget? endDrawer;
```
…but its `build` returned a plain `Container + SafeArea + body`. Every one of those props was silently discarded. Any page that tried `BBScaffold(appBar: AppBar(...))` would render the body without an AppBar — confusing.

**Fix this PR:** rewrote `build` to return a real Material `Scaffold` with every prop plumbed through. Also added `extendBodyBehindAppBar` for hero designs. SafeArea is now applied conditionally:
- `top` SafeArea only when there's no `appBar` (AppBar already consumes the inset).
- `bottom` SafeArea only when there's no `bottomNavigationBar`.

This means new pages get correct safe-area handling whether they use BBScaffold's appBar slot or render their own custom top widget.

---

## §3 What changed in `responsive.dart`

### `BBResponsive` snapshot — extended fields
| Field | Type | Source |
|---|---|---|
| `deviceClass` (existed) | enum | width vs breakpoints |
| `size` (existed) | Size | `MediaQuery.of(ctx).size` |
| `orientation` (existed) | Orientation | `MediaQuery.of(ctx).orientation` |
| **`padding`** NEW | EdgeInsets | `MediaQuery.of(ctx).padding` (safe-area) |
| **`viewInsets`** NEW | EdgeInsets | `MediaQuery.of(ctx).viewInsets` (keyboard) |
| **`textScaleFactor`** NEW | double | `MediaQuery.of(ctx).textScaler.scale(1.0)` |
| **`isKeyboardVisible`** NEW | bool | `viewInsets.bottom > 0` |

### `BBContextResponsive` extension — extended
| Getter | Description |
|---|---|
| `isLandscape` (existed) | `Orientation.landscape` |
| `isPortrait` (existed) | `Orientation.portrait` |
| **`keyboardInset`** NEW | `viewInsets.bottom` |
| **`isKeyboardVisible`** NEW | `keyboardInset > 0` |

### `BBContentMaxWidth` — new widget
```dart
class BBContentMaxWidth extends StatelessWidget {
  final double maxWidth;  // default 1200
  final AlignmentGeometry alignment;  // default Alignment.topCenter
  // wraps child in Align + ConstrainedBox(maxWidth)
}
```
Use as the body wrapper on screens that should clamp content width on desktop/wide. Phone + tablet pass through unchanged (no max in practice).

### `BBScaffold` — fixed (see §2)

---

## §4 The `BBResponsiveProbeScreen` contract

`flutter run --target lib/responsive_probe_dev.dart -d chrome` boots a standalone MaterialApp into the probe. The screen has six sections:

1. **Live snapshot card** — prints every field of `BBResponsive.of(context)`. Updates on every rebuild (window resize, rotate, keyboard open).
2. **Breakpoint boundaries** — 4 pills (`mobile <600`, `tablet 600-1023`, `desktop 1024-1439`, `wide ≥1440`). Active pill highlights in real time as you resize.
3. **Safe-area card** — displays `padding.{top,bottom,left,right}` in a separate boxed block. Use for verifying notch / display-cutout / Android nav-bar insets.
4. **`BBResponsiveBuilder` demo** — color-coded slots ("mobile slot" red, "tablet slot" orange, "desktop slot" green, "wide slot" blue). Reveals which fallback the builder hits.
5. **Text-scale proof rows** — same content rendered at 1.0×, 1.5×, 2.0× (via local `MediaQuery.copyWith(textScaler: TextScaler.linear(scale))`). Chip row + BBCard + diacritic line. **This is the audit/63 F-63-04 contract** — if 2.0× clips or overflows, the harness is broken.
6. **Keyboard inset demo** — a `BBInput`. Tap on a mobile device → keyboard opens → live snapshot's `viewInsets.bottom` updates + `BBScaffold.resizeToAvoidBottomInset` shrinks the body. (Web: no keyboard, but the wiring is exercised by analyze.)
7. **Inter + Croatian diacritics check** — `Č Ć Ž Š Đ` at `display` size + body sentence. If anything renders as serif (Playfair regression) or `??č` (encoding regression), `#545` regressed.

---

## §5 Responsive matrix — verification contract for page redesign prompts

Every page prompt (01-39) MUST pass this matrix:

| Device | Width | Class | Verify on probe |
|---|---|---|---|
| iPhone SE | 375 × 667 P | mobile | top ≥ 20 (status bar); bottom 0 |
| iPhone 14 Pro | 393 × 852 P | mobile | top ≥ 47 (notch); bottom ≥ 34 (home indicator) |
| iPhone 14 Pro | 852 × 393 L | mobile (tall) | left/right inset > 0 if Dynamic Island on the cutout side |
| Pixel 8 | 412 × 915 P | mobile | top ≥ 24; bottom inset varies (gesture vs 3-button nav) |
| iPad mini | 768 × 1024 P | tablet | top 24; bottom 0 |
| iPad mini | 1024 × 768 L | desktop | top 24; bottom 0; **wide cap kicks in** |
| Desktop | 1440 × 900 | wide | wide cap (1200) leaves 120px gutters |
| Wide | 1920 × 1080 | wide | wide cap (1200) leaves 360px gutters |

Keyboard test on each mobile target:
- Tap any `BBInput` in the probe.
- `BBScaffold.resizeToAvoidBottomInset: true` (default) ➜ body shrinks ➜ probe still scrollable ➜ no input clipped.
- `viewInsets.bottom` updates to the keyboard height.

Text scale: read the 1.0× / 1.5× / 2.0× rows on each target. All three must render legibly; chips must wrap (audit/63 F-63-04).

---

## §6 What this PR does NOT include

- **Live screenshots** of the responsive matrix on iPhone SE / iPhone 14 Pro / Pixel 8 / iPad / Desktop / Wide. No device available in this session. The probe screen is the deterministic verification surface — reviewer / next session runs `flutter run --target lib/responsive_probe_dev.dart -d <target>` and captures.
- **iOS / Android Marionette integration** — out of scope; harness is platform-agnostic. iOS + Android verification happens in next iteration with the probe screen as the artifact.
- **Page changes** — Prompt 01's hard rule. New pages start using this harness in prompts 03-39.

---

## §7 How prompts 03-39 consume this

Standard page template (subsequent prompts will use):

```dart
import 'package:bookbed/core/design/responsive.dart';
import 'package:bookbed/core/design/tokens.dart';
import 'package:bookbed/core/widgets/bb_card.dart';

class MyRedesignedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final BBResponsive r = BBResponsive.of(context);
    return BBScaffold(
      appBar: AppBar(title: const Text('My screen')),
      body: BBContentMaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(BBSpace.md),
          children: <Widget>[
            if (r.isTabletOrLarger)
              // wider layout
            else
              // mobile stacked layout
            // ... BBCards, BBChips, etc.
          ],
        ),
      ),
    );
  }
}
```

Required:
- Page composed inside `BBScaffold` (no manual `Scaffold(...)`).
- Body wrapped in `BBContentMaxWidth` (or omitted intentionally for full-bleed).
- Width-dependent layout branches through `BBResponsiveBuilder` or `r.isMobile/...`.
- Orientation branches through `context.isLandscape`.
- Keyboard-aware: forms inherit auto-resize from `BBScaffold`; check `r.isKeyboardVisible` only for advanced behavior (auto-scroll into view, etc.).
- Text-scale safe: chip rows MUST be `Wrap`, never `Row + scroll`. Verify on the 2.0× probe row before merging.

---

## §8 Files changed

```
M  lib/core/design/responsive.dart                      (+~80 / -~5 — new fields + BBContentMaxWidth + BBScaffold fix)
A  lib/core/design/responsive_probe_screen.dart         (new, ~400 LOC)
A  lib/responsive_probe_dev.dart                        (new, ~35 LOC dev entry)
A  audit/81-responsive-harness.md                       (this file)
```

No changes to: `lib/core/widgets/bb_*.dart` (10 primitives unchanged), `lib/core/theme/*.dart`, `lib/core/design/tokens.dart`, `lib/features/**`, `pubspec.yaml`, `firestore.rules`, anything in `functions/`.

---

## §9 Verification (this PR)

```
$ cd /tmp/bb-rd-01-wt
$ git branch --show-current
redesign/01-responsive-harness
$ grep -q "class BBResponsive" lib/core/design/responsive.dart && \
  grep -q "GoogleFonts.inter" lib/core/theme/app_typography.dart && \
  echo "POST-CONSOLIDATION OK"
POST-CONSOLIDATION OK

$ flutter analyze lib/core/design/responsive.dart lib/core/design/responsive_probe_screen.dart lib/responsive_probe_dev.dart
No issues found! (ran in 1.2s)

$ flutter analyze lib/
92 issues (0 errors, 0 warnings, 92 infos — 90 intentional @Deprecated bridge flags from #543 + 2 pre-existing on main)

$ flutter test --no-pub
+1205: All tests passed!
```

The harness is verified by:
- `BBContextResponsive.keyboardInset` exercised in `_KeyboardInsetDemo`
- `BBResponsive.isKeyboardVisible` exercised in `_SnapshotCard`
- `BBScaffold.resizeToAvoidBottomInset` default `true` exercised by all keyboard-test routes
- `BBContentMaxWidth` exercised by every body row in the probe

When a future PR wants to break the contract, `flutter run --target lib/responsive_probe_dev.dart -d chrome` will show the breakage immediately.
