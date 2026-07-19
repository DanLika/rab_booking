import 'package:bookbed/shared/widgets/redesign/bb_button.dart';
import 'package:bookbed/shared/widgets/redesign/bb_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Audit sweep F2.2 — BbButton tap-target floor + semantics hardening.
///
/// The `sm` pill (36px) and `sm` asIcon (36×36) were the ROOT of the
/// sub-44px systemic finding (35+ call sites). The visual pill is untouched;
/// only the hit area is floored to 44. md/lg must stay byte-identical.
void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[child],
      ),
    ),
  );

  testWidgets('sm text button hit box is >=44 tall', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(BbButton(label: 'Mali', size: BbButtonSize.sm, onPressed: () {})),
    );
    final Size size = tester.getSize(find.byType(BbButton));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('sm asIcon hit box is >=44x44', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        BbButton(
          iconLeft: 'close',
          asIcon: true,
          size: BbButtonSize.sm,
          onPressed: () {},
        ),
      ),
    );
    final Size size = tester.getSize(find.byType(BbButton));
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, greaterThanOrEqualTo(44));
  });

  testWidgets('sm width behavior matches md (wrapper is width-transparent)', (
    WidgetTester tester,
  ) async {
    // Pre-F2.2 the AnimatedContainer expanded in loose-bounded contexts for
    // ALL sizes; the hit-area wrapper must not change that for sm.
    await tester.pumpWidget(
      host(BbButton(label: 'Isti', size: BbButtonSize.sm, onPressed: () {})),
    );
    final double smWidth = tester.getSize(find.byType(BbButton)).width;
    await tester.pumpWidget(host(BbButton(label: 'Isti', onPressed: () {})));
    await tester.pumpAndSettle();
    final double mdWidth = tester.getSize(find.byType(BbButton)).width;
    expect(smWidth, mdWidth);
  });

  testWidgets('md and lg layout is unchanged (44 / 52)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(BbButton(label: 'Srednji', onPressed: () {})));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(BbButton)).height, 44);

    await tester.pumpWidget(
      host(BbButton(label: 'Veliki', size: BbButtonSize.lg, onPressed: () {})),
    );
    await tester.pumpAndSettle(); // AnimatedContainer height 44→52
    expect(tester.getSize(find.byType(BbButton)).height, 52);
  });

  testWidgets('sm tap on the expanded hit area (outside the 36px pill) fires', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      host(
        BbButton(label: 'Mali', size: BbButtonSize.sm, onPressed: () => taps++),
      ),
    );
    // Tap 1px inside the top edge of the 44px hit box — outside the
    // vertically-centered 36px pill (4px slack top/bottom).
    final Rect box = tester.getRect(find.byType(BbButton));
    await tester.tapAt(Offset(box.center.dx, box.top + 2));
    expect(taps, 1);
  });

  testWidgets('loading spinner is excluded from semantics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(BbButton(label: 'Spremi', loading: true, onPressed: () {})),
    );
    // Button label still announced; spinner wrapped in ExcludeSemantics.
    expect(find.bySemanticsLabel('Spremi'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(BbSpinner),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
  });

  testWidgets('fullWidth sm still spans the parent width', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(
        BbButton(
          label: 'Puna širina',
          size: BbButtonSize.sm,
          fullWidth: true,
          onPressed: () {},
        ),
      ),
    );
    final Size size = tester.getSize(find.byType(BbButton));
    expect(size.width, 800); // test viewport width
    expect(size.height, greaterThanOrEqualTo(44));
  });

  test('constructor asserts on a content-less button', () {
    expect(() => BbButton(onPressed: () {}), throwsAssertionError);
  });
}
