import 'package:bookbed/shared/widgets/redesign/bb_button.dart';
import 'package:bookbed/shared/widgets/redesign/bb_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal MaterialApp wrap so theme-aware token accessors
/// (BBColor.of, BbRedesignTokens.of) can resolve.
Widget _scaffold(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('BbDialog (dialogs-states sweep)', () {
    testWidgets('renders title + body', (WidgetTester tester) async {
      await tester.pumpWidget(
        _scaffold(const BbDialog(title: 'Odjava', body: 'Jeste li sigurni?')),
      );
      expect(find.text('Odjava'), findsOneWidget);
      expect(find.text('Jeste li sigurni?'), findsOneWidget);
    });

    testWidgets('primary + secondary actions fire callbacks', (
      WidgetTester tester,
    ) async {
      int primary = 0;
      int secondary = 0;
      await tester.pumpWidget(
        _scaffold(
          BbDialog(
            title: 'T',
            body: 'B',
            secondary: BbDialogAction(
              label: 'Odustani',
              onPressed: () => secondary++,
            ),
            primary: BbDialogAction(
              label: 'Potvrdi',
              onPressed: () => primary++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Odustani'));
      await tester.tap(find.text('Potvrdi'));
      await tester.pump();
      expect(primary, 1);
      expect(secondary, 1);
    });

    testWidgets('destructive routes primary to destructive BbButton variant', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(
          BbDialog(
            title: 'Obriši',
            body: 'Trajno?',
            destructive: true,
            primary: BbDialogAction(label: 'Obriši', onPressed: () {}),
          ),
        ),
      );
      final BbButton btn = tester.widget<BbButton>(find.byType(BbButton));
      expect(btn.variant, BbButtonVariant.destructive);
    });

    testWidgets('non-destructive primary uses primary variant', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(
          BbDialog(
            title: 'U redu',
            body: 'Info',
            primary: BbDialogAction(label: 'OK', onPressed: () {}),
          ),
        ),
      );
      final BbButton btn = tester.widget<BbButton>(find.byType(BbButton));
      expect(btn.variant, BbButtonVariant.primary);
    });
  });
}
