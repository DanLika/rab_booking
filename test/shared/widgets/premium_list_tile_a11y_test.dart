import 'package:bookbed/shared/widgets/premium_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Audit sweep F2.10 — PremiumListTile tap-target floor + inert-tile fixes.
void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Column(children: <Widget>[child])),
  );

  testWidgets('tile is at least 48px tall (was ~40 with dense+density)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(
        PremiumListTile(icon: Icons.settings, title: 'Postavke', onTap: () {}),
      ),
    );
    expect(
      tester.getSize(find.byType(ListTile)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('chevron hidden on tiles without onTap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(const PremiumListTile(icon: Icons.info, title: 'Info')),
    );
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);

    await tester.pumpWidget(
      host(PremiumListTile(icon: Icons.info, title: 'Info', onTap: () {})),
    );
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  testWidgets('disabled tile is not enabled for semantics/interaction', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(const PremiumListTile(icon: Icons.lock, title: 'Zaključano')),
    );
    expect(tester.widget<ListTile>(find.byType(ListTile)).enabled, isFalse);
  });
}
