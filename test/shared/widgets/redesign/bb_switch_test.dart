import 'package:bookbed/shared/widgets/redesign/bb_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scaffold(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

void main() {
  group('BbSwitch (Phase 1.3)', () {
    testWidgets('tap toggles value via onChanged', (WidgetTester tester) async {
      bool current = false;
      await tester.pumpWidget(
        _scaffold(
          StatefulBuilder(
            builder: (BuildContext c, void Function(VoidCallback) setS) {
              return BbSwitch(
                value: current,
                label: 'Push notifications',
                onChanged: (bool v) => setS(() => current = v),
              );
            },
          ),
        ),
      );

      expect(current, isFalse);
      await tester.tap(find.byType(BbSwitch));
      await tester.pump();
      // Wait for the AnimatedAlign / AnimatedContainer to settle.
      await tester.pumpAndSettle();
      expect(current, isTrue);

      await tester.tap(find.byType(BbSwitch));
      await tester.pumpAndSettle();
      expect(current, isFalse);
    });

    testWidgets('disabled when onChanged is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        _scaffold(
          const BbSwitch(value: true, onChanged: null, label: 'Locked'),
        ),
      );

      expect(find.text('Locked'), findsOneWidget);
      // Tap is a no-op — no parent setter to mutate.
      await tester.tap(find.byType(BbSwitch));
      await tester.pump();
    });

    testWidgets('thumb animation completes (reduce-motion safe)', (
      WidgetTester tester,
    ) async {
      bool current = false;
      await tester.pumpWidget(
        _scaffold(
          StatefulBuilder(
            builder: (BuildContext c, void Function(VoidCallback) setS) {
              return BbSwitch(
                value: current,
                onChanged: (bool v) => setS(() => current = v),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(BbSwitch));
      // pumpAndSettle drains every running ticker including AnimatedAlign;
      // passes even if BBMotion.adapt collapsed it to Duration.zero.
      await tester.pumpAndSettle();
      expect(current, isTrue);
    });
  });
}
