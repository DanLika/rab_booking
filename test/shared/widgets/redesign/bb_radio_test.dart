import 'package:bookbed/shared/widgets/redesign/bb_radio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scaffold(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

enum _Lang { hr, en }

void main() {
  group('BbRadio + BbRadioGroup (Phase 1.3)', () {
    testWidgets('selecting one option in BbRadioGroup deselects others', (
      WidgetTester tester,
    ) async {
      _Lang? current = _Lang.hr;
      await tester.pumpWidget(
        _scaffold(
          StatefulBuilder(
            builder: (BuildContext c, void Function(VoidCallback) setS) {
              return BbRadioGroup<_Lang>(
                value: current,
                onChanged: (_Lang v) => setS(() => current = v),
                options: const <BbRadioOption<_Lang>>[
                  (value: _Lang.hr, label: 'Hrvatski', subtitle: null),
                  (value: _Lang.en, label: 'English', subtitle: 'Beta'),
                ],
              );
            },
          ),
        ),
      );

      // 2 BbRadio children inside the group.
      expect(find.byType(BbRadio<_Lang>), findsNWidgets(2));
      expect(current, _Lang.hr);

      // Tap the English option.
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(current, _Lang.en);

      // Tap the Hrvatski option.
      await tester.tap(find.text('Hrvatski'));
      await tester.pumpAndSettle();
      expect(current, _Lang.hr);
    });

    testWidgets('validator on group renders error when value is null', (
      WidgetTester tester,
    ) async {
      final GlobalKey<FormState> formKey = GlobalKey<FormState>();
      _Lang? current; // start unselected

      await tester.pumpWidget(
        _scaffold(
          Form(
            key: formKey,
            child: StatefulBuilder(
              builder: (BuildContext c, void Function(VoidCallback) setS) {
                return BbRadioGroup<_Lang>(
                  value: current,
                  onChanged: (_Lang v) => setS(() => current = v),
                  options: const <BbRadioOption<_Lang>>[
                    (value: _Lang.hr, label: 'HR', subtitle: null),
                    (value: _Lang.en, label: 'EN', subtitle: null),
                  ],
                  validator: (_Lang? v) =>
                      v == null ? 'choose a language' : null,
                );
              },
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('choose a language'), findsOneWidget);

      // Select one and revalidate.
      await tester.tap(find.text('HR'));
      await tester.pumpAndSettle();
      expect(current, _Lang.hr);
      expect(formKey.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('choose a language'), findsNothing);
    });

    testWidgets(
      'backward compat: BbRadioGroup without validator renders no FormField',
      (WidgetTester tester) async {
        _Lang? current = _Lang.hr;
        await tester.pumpWidget(
          _scaffold(
            BbRadioGroup<_Lang>(
              value: current,
              onChanged: (_Lang v) {
                current = v;
              },
              options: const <BbRadioOption<_Lang>>[
                (value: _Lang.hr, label: 'HR', subtitle: null),
                (value: _Lang.en, label: 'EN', subtitle: null),
              ],
            ),
          ),
        );

        // No FormField in the tree when validator is null.
        expect(find.byType(FormField<_Lang>), findsNothing);
        expect(find.text('HR'), findsOneWidget);
        expect(find.text('EN'), findsOneWidget);
      },
    );
  });
}
