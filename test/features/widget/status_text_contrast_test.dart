// Audit sweep F3.1 — guest-widget status TEXT contrast matrix (#951 style).
//
// Guards the AA floor (4.5:1) for every text-role token on every surface it
// renders on, so a future "lighten the background" or "brighten the token"
// change fails BY NAME instead of silently regressing guest-facing text.
//
// Fill tokens (success/warning) are NOT asserted — they colour icons, tints
// and borders, where AA text rules don't apply.

import 'package:bookbed/features/widget/presentation/theme/minimalist_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double lighter = la > lb ? la : lb;
  final double darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('light surfaces', () {
    const Map<String, Color> surfaces = {
      'backgroundPrimary(white)': MinimalistColors.backgroundPrimary,
      'backgroundSecondary(#FAFAFA)': MinimalistColors.backgroundSecondary,
      'backgroundTertiary(#F5F5F5)': MinimalistColors.backgroundTertiary,
      'backgroundCard(white)': MinimalistColors.backgroundCard,
    };
    const Map<String, Color> textTokens = {
      'textTertiary': MinimalistColors.textTertiary,
      'successText': MinimalistColors.successText,
      'warningText': MinimalistColors.warningText,
    };

    for (final MapEntry<String, Color> t in textTokens.entries) {
      for (final MapEntry<String, Color> b in surfaces.entries) {
        test('${t.key} on ${b.key} ≥ 4.5:1', () {
          final double ratio = _contrast(t.value, b.value);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '${t.key} ${t.value} on ${b.key} ${b.value} = '
                '${ratio.toStringAsFixed(2)}:1',
          );
        });
      }
    }

    test('status-chip labels clear AA on their 10% tint', () {
      // Chip bg = fill at 10% alpha over white — composite, then check the
      // AA-safe text variant against it.
      Color composite(Color fg, Color bg, double alpha) {
        return Color.lerp(bg, fg, alpha)!;
      }

      final Color successTint = composite(
        MinimalistColors.success,
        MinimalistColors.backgroundPrimary,
        0.1,
      );
      final Color warningTint = composite(
        MinimalistColors.warning,
        MinimalistColors.backgroundPrimary,
        0.1,
      );
      expect(
        _contrast(MinimalistColors.successText, successTint),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(MinimalistColors.warningText, warningTint),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('dark surfaces', () {
    const Map<String, Color> textTokens = {
      'successText': MinimalistColorsDark.successText,
      'warningText': MinimalistColorsDark.warningText,
    };
    for (final MapEntry<String, Color> t in textTokens.entries) {
      test('${t.key} on dark backgroundPrimary ≥ 4.5:1', () {
        final double ratio = _contrast(
          t.value,
          MinimalistColorsDark.backgroundPrimary,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${t.key} = ${ratio.toStringAsFixed(2)}:1',
        );
      });
    }
  });
}
