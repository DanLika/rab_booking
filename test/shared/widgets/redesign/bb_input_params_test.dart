import 'package:bookbed/shared/widgets/redesign/bb_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Audit sweep F2.1 — keyboard/autofill params backported into [BbInput].
///
/// Guards the exact constructor gaps flagged as the 3×P0 systemic root
/// (no `textInputAction`, no external `focusNode`, no `autofillHints`):
/// every assertion here fails on the pre-F2.1 widget.
void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );

  TextField innerField(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField));

  testWidgets('textInputAction is forwarded to the inner TextField', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(
        const BbInput(label: 'Email', textInputAction: TextInputAction.next),
      ),
    );
    expect(innerField(tester).textInputAction, TextInputAction.next);
  });

  testWidgets('autofillHints are forwarded to the inner TextField', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(
        const BbInput(
          label: 'Lozinka',
          obscureText: true,
          autofillHints: <String>[AutofillHints.password],
        ),
      ),
    );
    expect(innerField(tester).autofillHints, contains(AutofillHints.password));
  });

  testWidgets('textCapitalization and autofocus are forwarded', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(
        const BbInput(
          label: 'Ime',
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
      ),
    );
    final TextField field = innerField(tester);
    expect(field.textCapitalization, TextCapitalization.words);
    expect(field.autofocus, isTrue);
  });

  testWidgets('external focusNode drives focus and survives the widget', (
    WidgetTester tester,
  ) async {
    final FocusNode node = FocusNode();
    addTearDown(node.dispose);

    await tester.pumpWidget(host(BbInput(label: 'Email', focusNode: node)));
    expect(node.hasFocus, isFalse);

    node.requestFocus();
    await tester.pump();
    expect(node.hasFocus, isTrue);
    expect(innerField(tester).focusNode, same(node));

    // Widget unmount must NOT dispose the caller-owned node.
    await tester.pumpWidget(host(const SizedBox()));
    node.requestFocus(); // throws if the widget disposed it
  });

  testWidgets('keyboard submit fires onFieldSubmitted (form chain seam)', (
    WidgetTester tester,
  ) async {
    String? submitted;
    await tester.pumpWidget(
      host(
        BbInput(
          label: 'Email',
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (String v) => submitted = v,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'a@b.hr');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, 'a@b.hr');
  });

  testWidgets('controller swap re-attaches (stale-controller guard)', (
    WidgetTester tester,
  ) async {
    final TextEditingController first = TextEditingController(text: 'aa');
    final TextEditingController second = TextEditingController(text: 'bbbb');
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await tester.pumpWidget(
      host(BbInput(label: 'X', controller: first, charLimit: 10)),
    );
    expect(find.text('2/10'), findsOneWidget);

    await tester.pumpWidget(
      host(BbInput(label: 'X', controller: second, charLimit: 10)),
    );
    // Counter must reflect the NEW controller, and track its edits.
    expect(find.text('4/10'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'cccccc');
    await tester.pump();
    expect(find.text('6/10'), findsOneWidget);
    expect(second.text, 'cccccc');
    expect(first.text, 'aa'); // old controller untouched
  });

  testWidgets(
    'defaults preserve previous behavior (no action, internal node)',
    (WidgetTester tester) async {
      await tester.pumpWidget(host(const BbInput(label: 'Y')));
      final TextField field = innerField(tester);
      expect(field.textInputAction, isNull);
      expect(field.autofillHints, isNull);
      expect(field.autofocus, isFalse);
      expect(field.textCapitalization, TextCapitalization.none);
    },
  );
}
