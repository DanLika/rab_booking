import 'package:bookbed/shared/widgets/redesign/bb_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wrap a widget tree in a minimal MaterialApp so theme-aware token
/// accessors (BBColor.of, BbRedesignTokens.of) can resolve.
Widget _scaffold(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

void main() {
  group('BbInput Form integration (Phase 1.1)', () {
    testWidgets('validator fires via Form.validate() and renders error text', (
      WidgetTester tester,
    ) async {
      final GlobalKey<FormState> formKey = GlobalKey<FormState>();
      final TextEditingController ctrl = TextEditingController();

      await tester.pumpWidget(
        _scaffold(
          Form(
            key: formKey,
            child: BbInput(
              controller: ctrl,
              label: 'Email',
              validator: (String? v) =>
                  (v == null || v.isEmpty) ? 'required' : null,
            ),
          ),
        ),
      );

      // Empty → validator returns 'required' → validate() returns false.
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump(); // let the FormField rebuild its errorText
      expect(find.text('required'), findsOneWidget);

      // Now fill the field and revalidate.
      ctrl.text = 'someone@example.com';
      await tester.pump();
      expect(formKey.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('required'), findsNothing);

      ctrl.dispose();
    });

    testWidgets(
      'backward compat: BbInput without validator works outside a Form',
      (WidgetTester tester) async {
        final TextEditingController ctrl = TextEditingController();
        await tester.pumpWidget(
          _scaffold(
            BbInput(controller: ctrl, label: 'Plain', placeholder: 'type here'),
          ),
        );

        // No Form ancestor, no validator → no throw, label + placeholder
        // render normally and the input accepts text input. The no-validator
        // branch uses a plain TextField (no FormField wrap — zero overhead).
        expect(find.text('Plain'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(FormField<String>), findsNothing);

        await tester.enterText(find.byType(TextField), 'hello');
        await tester.pump();
        expect(ctrl.text, 'hello');

        ctrl.dispose();
      },
    );

    testWidgets('error precedence: widget.error wins over validator output', (
      WidgetTester tester,
    ) async {
      final GlobalKey<FormState> formKey = GlobalKey<FormState>();
      final TextEditingController ctrl = TextEditingController();

      await tester.pumpWidget(
        _scaffold(
          Form(
            key: formKey,
            child: BbInput(
              controller: ctrl,
              label: 'Email',
              error: 'from error',
              validator: (String? v) => 'from validator',
            ),
          ),
        ),
      );

      // Trigger the validator so its message is populated on the
      // underlying FormFieldState.
      formKey.currentState!.validate();
      await tester.pump();

      // widget.error must win — only 'from error' is shown.
      expect(find.text('from error'), findsOneWidget);
      expect(find.text('from validator'), findsNothing);

      ctrl.dispose();
    });
  });
}
