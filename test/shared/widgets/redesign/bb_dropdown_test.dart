import 'package:bookbed/shared/widgets/redesign/bb_dropdown.dart';
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

const List<BbDropdownItem<String>> _items = <BbDropdownItem<String>>[
  BbDropdownItem<String>(value: 'a', label: 'Option A'),
  BbDropdownItem<String>(value: 'b', label: 'Option B'),
  BbDropdownItem<String>(value: 'c', label: 'Option C'),
];

void main() {
  group('BbDropdown (Phase 1.6)', () {
    testWidgets('renders label + placeholder when value is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(
          BbDropdown<String>(
            label: 'Platform',
            placeholder: 'Pick one',
            value: null,
            items: _items,
            onChanged: (String? _) {},
          ),
        ),
      );

      expect(find.text('Platform'), findsOneWidget);
      expect(find.text('Pick one'), findsOneWidget);
    });

    testWidgets('selection fires onChanged with chosen value', (
      WidgetTester tester,
    ) async {
      String? picked;

      await tester.pumpWidget(
        _scaffold(
          StatefulBuilder(
            builder: (BuildContext ctx, void Function(VoidCallback) setS) {
              return BbDropdown<String>(
                value: picked,
                placeholder: 'Pick',
                items: _items,
                onChanged: (String? v) => setS(() => picked = v),
              );
            },
          ),
        ),
      );

      // Open the menu.
      await tester.tap(find.byType(BbDropdown<String>));
      await tester.pumpAndSettle();

      // Tap Option B in the overlay. `.last` selects the menu item
      // rather than any hidden trigger-row text.
      await tester.tap(find.text('Option B').last);
      await tester.pumpAndSettle();

      expect(picked, equals('b'));
    });

    testWidgets('validator returns error when value is null (Form-bearing)', (
      WidgetTester tester,
    ) async {
      final GlobalKey<FormState> formKey = GlobalKey<FormState>();
      String? picked;

      await tester.pumpWidget(
        _scaffold(
          Form(
            key: formKey,
            child: StatefulBuilder(
              builder: (BuildContext ctx, void Function(VoidCallback) setS) {
                return BbDropdown<String>(
                  value: picked,
                  placeholder: 'Pick',
                  items: _items,
                  onChanged: (String? v) => setS(() => picked = v),
                  validator: (String? v) => v == null ? 'must pick' : null,
                );
              },
            ),
          ),
        ),
      );

      // value=null → validator returns 'must pick'.
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('must pick'), findsOneWidget);
    });

    testWidgets(
      'backward compat: BbDropdown without validator works outside a Form',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _scaffold(
            BbDropdown<String>(
              value: 'a',
              items: _items,
              onChanged: (String? _) {},
            ),
          ),
        );

        // No FormField wrap when validator is absent.
        expect(find.byType(FormField<String>), findsNothing);
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
            child: BbDropdown<String>(
              value: null,
              items: _items,
              onChanged: (String? _) {},
              error: 'from error',
              validator: (String? _) => 'from validator',
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
