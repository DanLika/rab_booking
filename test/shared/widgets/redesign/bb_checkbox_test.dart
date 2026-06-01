import 'package:bookbed/shared/widgets/redesign/bb_checkbox.dart';
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
  group('BbCheckbox (Phase 1.3)', () {
    testWidgets('tap toggles value via onChanged', (WidgetTester tester) async {
      bool current = false;
      await tester.pumpWidget(
        _scaffold(
          StatefulBuilder(
            builder: (BuildContext context, void Function(VoidCallback) setS) {
              return BbCheckbox(
                value: current,
                label: 'Accept terms',
                onChanged: (bool v) => setS(() => current = v),
              );
            },
          ),
        ),
      );

      expect(current, isFalse);
      await tester.tap(find.byType(BbCheckbox));
      await tester.pump();
      expect(current, isTrue);

      await tester.tap(find.byType(BbCheckbox));
      await tester.pump();
      expect(current, isFalse);
    });

    testWidgets('disabled when onChanged is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        _scaffold(
          const BbCheckbox(value: false, onChanged: null, label: 'Locked'),
        ),
      );

      // Renders label; tap should not crash and the parent value stays.
      expect(find.text('Locked'), findsOneWidget);
      await tester.tap(find.byType(BbCheckbox));
      await tester.pump();
      // No assertions about value — null onChanged means the parent never
      // hears about a tap and there's no internal state to mutate.
    });

    testWidgets('validator returns error when value=false (Form-bearing)', (
      WidgetTester tester,
    ) async {
      final GlobalKey<FormState> formKey = GlobalKey<FormState>();
      bool current = false;

      await tester.pumpWidget(
        _scaffold(
          Form(
            key: formKey,
            child: StatefulBuilder(
              builder: (BuildContext ctx, void Function(VoidCallback) setS) {
                return BbCheckbox(
                  value: current,
                  label: 'Required',
                  onChanged: (bool v) => setS(() => current = v),
                  validator: (bool? v) => (v ?? false) ? null : 'must accept',
                );
              },
            ),
          ),
        ),
      );

      // value=false → validator returns 'must accept'.
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('must accept'), findsOneWidget);

      // Tap to set true and revalidate.
      await tester.tap(find.byType(BbCheckbox));
      await tester.pump();
      expect(current, isTrue);
      expect(formKey.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('must accept'), findsNothing);
    });

    testWidgets(
      'backward compat: BbCheckbox without validator works outside a Form',
      (WidgetTester tester) async {
        bool current = false;
        await tester.pumpWidget(
          _scaffold(
            StatefulBuilder(
              builder: (BuildContext c, void Function(VoidCallback) setS) {
                return BbCheckbox(
                  value: current,
                  label: 'Plain',
                  onChanged: (bool v) => setS(() => current = v),
                );
              },
            ),
          ),
        );

        // No FormField wrap when validator is absent.
        expect(find.byType(FormField<bool>), findsNothing);
        expect(find.text('Plain'), findsOneWidget);
      },
    );

    testWidgets('error precedence: widget.error wins over validator output', (
      WidgetTester tester,
    ) async {
      final GlobalKey<FormState> formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        _scaffold(
          Form(
            key: formKey,
            child: BbCheckbox(
              value: false,
              onChanged: (bool _) {},
              label: 'Email',
              error: 'from error',
              validator: (bool? _) => 'from validator',
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      // widget.error must win.
      expect(find.text('from error'), findsOneWidget);
      expect(find.text('from validator'), findsNothing);
    });
  });
}
