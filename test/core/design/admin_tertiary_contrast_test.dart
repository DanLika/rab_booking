// Audit sweep F3.4 — admin dark-console tertiary text contrast (#951 class;
// the admin surface was never covered by a contrast guard).
//
// textTertiary is translucent white — composite it over each admin surface
// and hold the 4.5:1 floor by name.

import 'package:bookbed/core/design/bb_redesign_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  test('admin textTertiary ≥ 4.5:1 on every admin surface', () {
    const BbAdminDarkTokens t = BbAdminDarkTokens.preset;
    final Map<String, Color> surfaces = <String, Color>{
      'shellBg': t.shellBg,
      'panelBg': t.panelBg,
    };
    for (final MapEntry<String, Color> e in surfaces.entries) {
      final Color composited = Color.alphaBlend(t.textTertiary, e.value);
      final double r = _contrast(composited, e.value);
      expect(
        r,
        greaterThanOrEqualTo(4.5),
        reason: 'textTertiary on ${e.key} = ${r.toStringAsFixed(2)}:1',
      );
    }
  });
}
