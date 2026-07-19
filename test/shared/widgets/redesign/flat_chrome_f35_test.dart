// Audit sweep F3.5 — flat-chrome regressions removed.
//
// The 2026-06-16 flat-chrome decision retired gradients from owner chrome
// (memory: flat-chrome-decision). This pins the repaired surfaces:
//   - BbLogo defaults to a FLAT primary tile (was gradient-by-default with
//     three live no-opt-out call sites: sidebar, rail, admin login);
//   - profile hero chrome (halo/strip/gauge/Pro tile) — asserted via the
//     gauge painter's flat arc (compile-level: gradient param removed).

import 'package:bookbed/core/design/tokens.dart';
import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/shared/widgets/redesign/bb_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BbLogo default renders a flat primary tile (no gradient)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Center(child: BbLogo())),
      ),
    );
    final Container tile = tester.widget<Container>(
      find.ancestor(of: find.text('b'), matching: find.byType(Container)),
    );
    final BoxDecoration deco = tile.decoration! as BoxDecoration;
    expect(deco.gradient, isNull);
    expect(deco.color, BBColor.light.primary);
  });

  testWidgets('BbLogo opt-in gradient still available for hero surfaces', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Center(child: BbLogo(useGradient: true))),
      ),
    );
    final Container tile = tester.widget<Container>(
      find.ancestor(of: find.text('b'), matching: find.byType(Container)),
    );
    expect((tile.decoration! as BoxDecoration).gradient, isNotNull);
  });
}
