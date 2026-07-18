import 'package:bookbed/shared/widgets/redesign/bb_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Audit sweep F2.12 — BbDialog route semantics + bodyWidget slot.
void main() {
  testWidgets('title carries a heading role', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BbDialog(title: 'Potvrda', body: 'Jeste li sigurni?'),
        ),
      ),
    );
    // The route node shares the title label — target the Text element's own
    // node, which carries the header flag.
    final SemanticsNode node = tester.getSemantics(find.text('Potvrda'));
    expect(node.hasFlag(SemanticsFlag.isHeader), isTrue);
    handle.dispose();
  });

  testWidgets('dialog scopes and names its route', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BbDialog(title: 'Brisanje', body: 'Trajno?'),
        ),
      ),
    );
    // scopesRoute node exists in the tree wrapping the dialog.
    expect(
      find.ancestor(
        of: find.byType(Dialog),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Semantics && w.properties.scopesRoute == true,
        ),
      ),
      findsWidgets,
    );
    handle.dispose();
  });

  testWidgets('bodyWidget renders in place of the body string', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BbDialog(
            title: 'Bogat sadržaj',
            bodyWidget: Icon(Icons.warning_amber),
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
  });

  test('asserts when neither body nor bodyWidget is given', () {
    expect(() => BbDialog(title: 'Prazno'), throwsAssertionError);
  });

  testWidgets('backward compat: existing body-string call sites unchanged', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BbDialog(title: 'Stari poziv', body: 'Tekst tijela'),
        ),
      ),
    );
    expect(find.text('Tekst tijela'), findsOneWidget);
  });
}
