import 'package:bookbed/shared/widgets/redesign/bb_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scaffold(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('BbSpinner (Phase 1.5f)', () {
    testWidgets('default renders CircularProgressIndicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_scaffold(const BbSpinner()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsNothing);
    });

    testWidgets(
      'reduced-motion renders static hourglass glyph, no CircularProgressIndicator',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _scaffold(const BbSpinner(), disableAnimations: true),
        );

        expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets('reduced-motion glyph honors size + color', (
      WidgetTester tester,
    ) async {
      const testColor = Color(0xFFAA00BB);
      await tester.pumpWidget(
        _scaffold(
          const BbSpinner(size: 32, color: testColor),
          disableAnimations: true,
        ),
      );

      final Icon icon = tester.widget<Icon>(find.byIcon(Icons.hourglass_empty));
      expect(icon.size, 32);
      expect(icon.color, testColor);

      final SizedBox box = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byIcon(Icons.hourglass_empty),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(box.width, 32);
      expect(box.height, 32);
    });
  });
}
