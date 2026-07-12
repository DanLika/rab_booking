// Guards the minimum touch target on the guest calendar's controls.
//
// The month/year navigation arrows and the zoom chips were 28–32dp — below the
// 48dp minimum (WCAG 2.5.5 / Material `kMinInteractiveDimension`). These are the
// only way a guest on a phone changes month or zooms the calendar, so a missed
// tap is a missed booking. The icons keep their size; only the hit box grew, so
// these cells assert the rendered *button* box, not the glyph.

import 'package:bookbed/features/widget/presentation/widgets/zoom_control_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        // ZoomControlButtons returns a Positioned — it only renders inside a Stack.
        home: Scaffold(body: Stack(children: [child])),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ZoomControlButtons — touch targets', () {
    testWidgets('both chips meet the 48dp minimum', (tester) async {
      await _pump(
        tester,
        ZoomControlButtons(
          currentScale: 1.5, // mid-range so neither button is disabled
          onScaleChanged: (_) {},
        ),
        const Size(390, 844),
      );

      final buttons = find.byType(InkWell);
      expect(buttons, findsNWidgets(2));

      for (var i = 0; i < 2; i++) {
        final size = tester.getSize(buttons.at(i));
        expect(
          size.width,
          greaterThanOrEqualTo(kMinInteractiveDimension),
          reason: 'zoom control $i is only ${size.width}dp wide',
        );
        expect(
          size.height,
          greaterThanOrEqualTo(kMinInteractiveDimension),
          reason: 'zoom control $i is only ${size.height}dp tall',
        );
      }
    });

    testWidgets('both chips carry an accessible name', (tester) async {
      final handle = tester.ensureSemantics();

      await _pump(
        tester,
        ZoomControlButtons(currentScale: 1.5, onScaleChanged: (_) {}),
        const Size(390, 844),
      );

      // Icon-only controls: without a label the screen reader announces nothing
      // at all. The exact wording is locale-dependent (WidgetTranslations reads
      // the widget's own locale provider, not MaterialApp's), so the contract
      // asserted here is that each control HAS a non-empty name — not which one.
      final labelled = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(ZoomControlButtons),
              matching: find.byType(Semantics),
            ),
          )
          .where(
            (s) =>
                s.properties.button == true &&
                (s.properties.label ?? '').trim().isNotEmpty,
          );

      expect(
        labelled.length,
        2,
        reason: 'both zoom controls must expose a non-empty accessible name',
      );

      handle.dispose();
    });
  });
}
