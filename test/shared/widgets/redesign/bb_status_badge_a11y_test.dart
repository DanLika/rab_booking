// Audit sweep F3.2 — status badge AA + semantics.
//
// Token corrections (computed minima, not eyeballed):
//   statusImported  light #4A90D9 -> #2B6CB0 (was 2.95:1 on its tint)
//   statusPending   light #B7791F -> #A05E14 (was 3.30:1 on its tint)
//   statusCompleted dark  #8B6FFF -> #A78BFF (was 3.76:1 on its tint)
// The matrix below composites each tint over its page surface and guards
// every badge fg at ≥4.5:1 in BOTH themes, so any future tint/fg drift
// fails by name.

import 'package:bookbed/core/design/bb_redesign_tokens.dart';
import 'package:bookbed/core/design/tokens.dart';
import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/shared/widgets/redesign/bb_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

/// Badge bg is a translucent tint — composite it over the page surface.
Color _over(Color tint, Color surface) => Color.alphaBlend(tint, surface);

void main() {
  group('badge fg on composited tint ≥ 4.5:1', () {
    const Color lightSurface = Colors.white;
    const Color darkSurface = Color(0xFF1E1E1E); // BbCard dark fill

    test('light theme — all five statuses', () {
      const BbRedesignTokens rd = BbRedesignTokens.light;
      final cases = <String, (Color, Color)>{
        'confirmed': (rd.statusConfirmedDeep, rd.statusConfirmedTint),
        'pending': (rd.statusPendingDeep, rd.statusPendingTint),
        'cancelled': (rd.statusCancelledDeep, rd.statusCancelledTint),
        'completed': (BBColor.statusCompleted, rd.statusCompletedTint),
        'imported': (BBColor.statusImported, rd.statusImportedTint),
      };
      for (final MapEntry<String, (Color, Color)> e in cases.entries) {
        final double r = _contrast(e.value.$1, _over(e.value.$2, lightSurface));
        expect(
          r,
          greaterThanOrEqualTo(4.5),
          reason: 'light ${e.key} = ${r.toStringAsFixed(2)}:1',
        );
      }
    });

    test('dark theme — all five statuses', () {
      const BbRedesignTokens rd = BbRedesignTokens.dark;
      final cases = <String, (Color, Color)>{
        'confirmed': (rd.statusConfirmedDeep, rd.statusConfirmedTint),
        'pending': (rd.statusPendingDeep, rd.statusPendingTint),
        'cancelled': (rd.statusCancelledDeep, rd.statusCancelledTint),
        'completed': (BBColor.statusCompletedDarkMode, rd.statusCompletedTint),
        'imported': (BBColor.statusImportedDarkMode, rd.statusImportedTint),
      };
      for (final MapEntry<String, (Color, Color)> e in cases.entries) {
        final double r = _contrast(e.value.$1, _over(e.value.$2, darkSurface));
        expect(
          r,
          greaterThanOrEqualTo(4.5),
          reason: 'dark ${e.key} = ${r.toStringAsFixed(2)}:1',
        );
      }
    });
  });

  testWidgets('badge is one labeled semantics node', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: BbStatusBadge(status: BbBookingStatus.pending),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Na čekanju'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('pending dot uses the pending deep tone, not warning', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: BbStatusBadge(status: BbBookingStatus.pending),
        ),
      ),
    );
    final Iterable<Container> dots = tester
        .widgetList<Container>(find.byType(Container))
        .where(
          (Container w) =>
              (w.decoration is BoxDecoration) &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle,
        );
    expect(dots.length, 1);
    expect(
      ((dots.first.decoration!) as BoxDecoration).color,
      BbRedesignTokens.light.statusPendingDeep,
    );
  });
}
