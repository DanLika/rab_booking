import 'package:bookbed/shared/widgets/redesign/bb_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Audit sweep F2.5 — BbSectionHeader heading semantics (ROOT, A11y 0/4).
void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('title announces as a heading', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const BbSectionHeader(title: 'Postavke')));
    final SemanticsNode node = tester.getSemantics(
      find.bySemanticsLabel('Postavke'),
    );
    expect(node.flagsCollection.isHeader, isTrue);
    handle.dispose();
  });

  testWidgets('action announces as ONE button node (icon merged away)', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        BbSectionHeader(
          title: 'Rezervacije',
          actionLabel: 'Prikaži sve',
          onActionTap: () {},
        ),
      ),
    );
    final SemanticsNode action = tester.getSemantics(
      find.bySemanticsLabel('Prikaži sve'),
    );
    expect(action.flagsCollection.isButton, isTrue);
    // Arrow glyph must not surface as its own stop.
    expect(find.bySemanticsLabel(RegExp('arrow')), findsNothing);
    handle.dispose();
  });

  testWidgets('action tap still fires through the Semantics wrapper', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      host(
        BbSectionHeader(
          title: 'Rezervacije',
          actionLabel: 'Prikaži sve',
          onActionTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('Prikaži sve'));
    expect(taps, 1);
  });

  testWidgets('count renders alongside a heading title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(const BbSectionHeader(title: 'Jedinice', count: 7)),
    );
    expect(find.text('7'), findsOneWidget);
  });
}
