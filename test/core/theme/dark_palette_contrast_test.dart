// WCAG AA floor for the dark text tiers, measured against every dark surface
// they can land on.
//
// WHY THIS EXISTS: audit/127 widened the dark ladder (#0B0B0D→#141414, cards
// #1E1E1E, variant #2A2A2A) so panels would lift off the shell — a deliberate,
// correct change. But the TEXT tiers were never re-measured against the newly
// LIGHTER surfaces, and textTertiaryDark (#718096) silently dropped to 4.15:1
// on #1E1E1E and 3.57:1 on #2A2A2A, under the 4.5:1 floor for the 12px/w400
// captions that use it.
//
// So this guards the RELATIONSHIP, not one hex: lighten a surface again, or
// dim a text tier, and the offending pair fails here by name.

import 'dart:math' as math;
import 'dart:ui';

import 'package:bookbed/core/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';

/// Relative luminance per WCAG 2.1.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// Contrast ratio per WCAG 2.1. Both colours must be opaque.
double _contrast(Color fg, Color bg) {
  final a = _luminance(fg);
  final b = _luminance(bg);
  final hi = math.max(a, b);
  final lo = math.min(a, b);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Surfaces tertiary/secondary/primary text actually sits on, darkest first.
  // #333333 (elevatedDark) is omitted deliberately — it is buttonPrimaryHover
  // and a shadow tier, not a text backdrop.
  const surfaces = <String, Color>{
    'bgDark #000000': Color(0xFF000000),
    'panelBg #141414': Color(0xFF141414),
    'surfaceDark #1E1E1E': Color(0xFF1E1E1E), // BbCard's fill via c.surface
    'surfaceVarDark #2A2A2A': Color(0xFF2A2A2A),
  };

  const tiers = <String, Color>{
    'textPrimaryDark': AppColors.textPrimaryDark,
    'textSecondaryDark': AppColors.textSecondaryDark,
    'textTertiaryDark': AppColors.textTertiaryDark,
  };

  // 4.5:1 — BBType.caption is 12px/w400, i.e. NORMAL text. The 3:1 large-text
  // allowance needs ≥18.66px bold or ≥24px regular; no tier here qualifies.
  const aaNormalText = 4.5;

  group('dark text tiers clear WCAG AA on every dark surface', () {
    tiers.forEach((tierName, fg) {
      surfaces.forEach((surfaceName, bg) {
        test('$tierName on $surfaceName', () {
          final ratio = _contrast(fg, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(aaNormalText),
            reason:
                '$tierName on $surfaceName is ${ratio.toStringAsFixed(2)}:1, '
                'below the $aaNormalText:1 AA floor for 12px text. Either lift '
                'the text tier or darken the surface — do not ship the pair.',
          );
        });
      });
    });
  });

  test('THE BITE: the pre-fix tertiary would fail on card + variant', () {
    // #718096 was the value audit/127 left behind. Pinned so the regression is
    // legible: this is what "silently under AA" measured as.
    const preFix = Color(0xFF718096);
    expect(
      _contrast(preFix, const Color(0xFF1E1E1E)),
      lessThan(aaNormalText),
      reason: 'documents why textTertiaryDark moved',
    );
    expect(_contrast(preFix, const Color(0xFF2A2A2A)), lessThan(aaNormalText));
  });

  test('tertiary stays visually distinct from secondary', () {
    // The fix lifts tertiary toward white; it must not collapse into the
    // secondary tier, or the hierarchy the palette encodes is gone.
    final lumSecondary = _luminance(AppColors.textSecondaryDark);
    final lumTertiary = _luminance(AppColors.textTertiaryDark);
    expect(
      lumTertiary,
      lessThan(lumSecondary),
      reason: 'tertiary must remain dimmer than secondary',
    );
  });
}
