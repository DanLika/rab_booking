// Responsive regression for the priority-card fact chip (`_Fact`) inside
// `bookings_premium_header.dart`.
//
// Live repro: navigating to Rezervacije at a ~1352px window threw
// `A RenderFlex overflowed by 114 pixels on the right` — the chip's Text had
// no Flexible/ellipsis, so a long fact (property·unit name) blew out the Wrap
// row inside the *constrained* priority card. Fix = Flexible + ellipsis.
//
// The public `BookingsPremiumHeader` reads two Riverpod codegen notifiers that
// hit Firestore on build (see bookings_premium_header_refresh_decouple_test),
// so we pump the chip directly via the `buildBookingFactForTest` seam across a
// range of *constrained container* widths — the real overflow driver is the
// card width, not the viewport.

import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/owner_dashboard/presentation/widgets/bookings/bookings_premium_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A deliberately long property·unit label — the real-world overflow trigger.
  const longFact = 'Vila Marina Premium · Apartman Deluxe Sjever (3. kat)';

  // Container widths spanning a cramped mobile card → a roomy desktop column.
  const containerWidths = <double>[160, 200, 240, 280, 320, 400, 520, 760];

  for (final w in containerWidths) {
    for (final dark in const <bool>[false, true]) {
      final theme = dark ? 'dark' : 'light';
      testWidgets('booking fact chips — no overflow @${w}px $theme', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1400, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: w,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: <Widget>[
                      buildBookingFactForTest(
                        icon: Icons.home_outlined,
                        text: longFact,
                      ),
                      buildBookingFactForTest(
                        icon: Icons.event,
                        text: '12.–15. lipnja · 3 noći',
                      ),
                      buildBookingFactForTest(
                        icon: Icons.people_outline,
                        text: '4 gosta',
                      ),
                      buildBookingFactForTest(
                        icon: Icons.sell_outlined,
                        text: 'Booking.com',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // The fix: a long fact ellipsizes within the constrained Wrap instead
        // of overflowing. Pre-fix this threw at the narrow widths.
        expect(
          tester.takeException(),
          isNull,
          reason: 'fact chip overflowed at container width ${w}px ($theme)',
        );
      });
    }
  }
}
