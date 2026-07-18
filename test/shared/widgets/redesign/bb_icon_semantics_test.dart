import 'package:bookbed/shared/widgets/redesign/bb_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Audit sweep F2.4 — BbIcon decorative-by-default semantics + glyph cache.
void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('default icon is excluded from the semantics tree', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const BbIcon(name: 'settings')));
    expect(
      find.ancestor(
        of: find.byType(Icon),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
    handle.dispose();
  });

  testWidgets('semanticLabel surfaces the icon to screen readers', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(const BbIcon(name: 'settings', semanticLabel: 'Postavke')),
    );
    expect(find.bySemanticsLabel('Postavke'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(Icon),
        matching: find.byType(ExcludeSemantics),
      ),
      findsNothing,
    );
    handle.dispose();
  });

  testWidgets('unknown name renders the question_mark fallback (no crash)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(const BbIcon(name: 'definitely_not_a_real_icon_xyz')),
    );
    expect(find.byType(Icon), findsOneWidget);
  });

  testWidgets('resolved glyphs are cached (identical IconData instance)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Row(
          textDirection: TextDirection.ltr,
          children: <Widget>[
            BbIcon(name: 'settings'),
            BbIcon(name: 'settings'),
          ],
        ),
      ),
    );
    final List<Icon> icons = tester
        .widgetList<Icon>(find.byType(Icon))
        .toList();
    expect(identical(icons[0].icon, icons[1].icon), isTrue);
  });
}
