import 'package:bookbed/shared/widgets/redesign/bb_button.dart';
import 'package:bookbed/shared/widgets/redesign/bb_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal MaterialApp wrap so theme-aware token accessors
/// (BBColor.of, BbRedesignTokens.of) can resolve.
Widget _scaffold(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

void main() {
  group('BbButton (Phase 1.5a)', () {
    testWidgets('renders label + invokes onPressed on tap', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        _scaffold(BbButton(label: 'Submit', onPressed: () => taps++)),
      );
      expect(find.text('Submit'), findsOneWidget);
      await tester.tap(find.byType(BbButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('each variant renders label without throwing', (
      WidgetTester tester,
    ) async {
      for (final BbButtonVariant v in BbButtonVariant.values) {
        await tester.pumpWidget(
          _scaffold(BbButton(label: v.name, variant: v, onPressed: () {})),
        );
        expect(
          find.text(v.name),
          findsOneWidget,
          reason: 'variant ${v.name} did not render label',
        );
      }
    });

    testWidgets('disabled=true blocks onPressed', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        _scaffold(
          BbButton(label: 'Locked', disabled: true, onPressed: () => taps++),
        ),
      );
      await tester.tap(find.byType(BbButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('null onPressed disables tap (no callback wired)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_scaffold(const BbButton(label: 'Idle')));
      // No callback to fire, no throw expected.
      await tester.tap(find.byType(BbButton));
      await tester.pump();
      expect(find.text('Idle'), findsOneWidget);
    });

    testWidgets('loading=true shows BbSpinner and hides label', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        _scaffold(
          BbButton(label: 'Saving', loading: true, onPressed: () => taps++),
        ),
      );
      expect(find.byType(BbSpinner), findsOneWidget);
      expect(find.text('Saving'), findsNothing);
      // Loading also disables tap (per _disabled getter).
      await tester.tap(find.byType(BbButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('MouseRegion present to drive hover state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(BbButton(label: 'Hover me', onPressed: () {})),
      );
      expect(
        find.descendant(
          of: find.byType(BbButton),
          matching: find.byType(MouseRegion),
        ),
        findsWidgets,
      );
    });

    testWidgets('semanticLabel surfaces on Semantics node', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(
          BbButton(
            label: 'visible',
            semanticLabel: 'screenreader only',
            onPressed: () {},
          ),
        ),
      );
      final SemanticsNode node = tester.getSemantics(find.byType(BbButton));
      expect(node.label, contains('screenreader only'));
      // Drain Semantics handle on teardown — tester.getSemantics enables it.
    });
  });
}
