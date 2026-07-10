import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookbed/features/owner_dashboard/presentation/widgets/bookings/bookings_premium_header.dart';

/// RED→GREEN seam: the mobile (<600) Rezervacije KPI strip renders exactly the
/// 2 handoff cards ("Na čekanju" + "Zarada (mj.)"); tablet/desktop (≥600) keep
/// all 4. Handoff: `rezervacije-premium.jsx` `RezervacijePremiumMobile`.
///
/// Labels are rendered upper-cased by `_RezStatTile`, so finders match the
/// upper-cased forms.
void main() {
  Future<void> pump(WidgetTester tester, {required bool isMobile}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: isMobile ? 390 : 1440,
              child: buildRezKpiStripForTest(isMobile: isMobile),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('mobile renders exactly 2 KPI cards (Na čekanju + Zarada)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pump(tester, isMobile: true);

    expect(find.text('NA ČEKANJU'), findsOneWidget);
    expect(find.text('ZARADA (MJ.)'), findsOneWidget);
    expect(find.text('POTVRĐENO (MJ.)'), findsNothing);
    expect(find.text('NADOLAZEĆI'), findsNothing);
  });

  testWidgets('tablet/desktop renders all 4 KPI cards', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pump(tester, isMobile: false);

    expect(find.text('NA ČEKANJU'), findsOneWidget);
    expect(find.text('POTVRĐENO (MJ.)'), findsOneWidget);
    expect(find.text('ZARADA (MJ.)'), findsOneWidget);
    expect(find.text('NADOLAZEĆI'), findsOneWidget);
  });

  testWidgets('mobile strip has no overflow at narrow widths', (tester) async {
    for (final width in <double>[320, 360, 390]) {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              child: SingleChildScrollView(
                child: buildRezKpiStripForTest(isMobile: true),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'overflow at $width');
    }
  });
}
