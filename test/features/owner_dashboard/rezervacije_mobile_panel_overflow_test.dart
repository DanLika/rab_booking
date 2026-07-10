// RED→GREEN overflow seam for the owner Rezervacije MOBILE console panel
// (handoff RezervacijePremiumMobile `<main>`: PV_PANEL_BG, radius 24, 1px
// panel border, PV_PANEL_SHADOW, 16/16/24 inner padding).
//
// The live screen wraps the primary bookings content in this single elevated
// panel on mobile (<600). This seam reconstructs the panel shell + inner
// column (ledger + a long fact chip) at the three tightest phone widths
// (320 / 360 / 390) with an over-long guest name + over-long property, and
// asserts NO RenderFlex overflow. Guards the panel horizontal padding budget:
// a naive fixed-width inner card (or an unbounded fact Row) overflows the
// 16px-gutter panel at 320px — this is the regression the seam bites.
//
// Hermetic: BookingsLedger + buildBookingFactForTest read no l10n / providers.

import 'package:bookbed/core/design/bb_redesign_tokens.dart';
import 'package:bookbed/core/design/tokens.dart';
import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/owner_dashboard/presentation/widgets/bookings/bookings_ledger.dart';
import 'package:bookbed/features/owner_dashboard/presentation/widgets/bookings/bookings_premium_header.dart'
    show buildBookingFactForTest;
import 'package:bookbed/shared/widgets/redesign.dart' show BbBookingStatus;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _kMobilePanelPadH = 16.0;

const _entries = <BookingsLedgerEntry>[
  BookingsLedgerEntry(
    detailBookingId: 'BB-2403',
    guestName: 'Petra Jurić-Maksimović Vrlo Dugačko Ime Za Test Overflowa',
    reference: '#BB-2403',
    propertyName: 'Stan Lavanda na samome moru s dugačkim imenom objekta',
    unitName: 'Apartman A Premium Deluxe Suite',
    range: '18.–22. srp',
    nights: 4,
    guests: 2,
    status: BbBookingStatus.pending,
    isCancelled: false,
    hasPayment: true,
    total: 520,
    paid: 104,
  ),
  BookingsLedgerEntry(
    detailBookingId: 'BB-2405',
    guestName: 'Ivan Perić',
    reference: '#BB-2405',
    propertyName: 'Vila Marina',
    unitName: 'Premium suite',
    range: '15.–20. srp',
    nights: 5,
    guests: 2,
    status: BbBookingStatus.confirmed,
    isCancelled: false,
    hasPayment: true,
    total: 900,
    paid: 180,
  ),
];

/// Rebuilds the live `_buildMobilePanel` shell (same tokens + padding) so the
/// seam exercises the real panel geometry without the provider-bound screen.
class _MobilePanelHarness extends StatelessWidget {
  const _MobilePanelHarness();

  @override
  Widget build(BuildContext context) {
    final rd = BbRedesignTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: rd.panelBg,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: rd.panelBorder),
        boxShadow: rd.panelShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _kMobilePanelPadH,
          _kMobilePanelPadH,
          _kMobilePanelPadH,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Long fact chip (pending-queue stay fact) — must ellipsis, not
            // overflow the panel gutter.
            buildBookingFactForTest(
              icon: Icons.apartment,
              text:
                  'Stan Lavanda na samome moru s dugačkim imenom · Apartman A',
            ),
            const SizedBox(height: 14),
            BookingsLedger(
              tabBar: const SizedBox(height: 32),
              entries: _entries,
              onOpenDetail: (_) {},
              onFilters: () {},
              footerLabel: 'Prikazano svih 2 rezervacije',
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  const widths = <double>[320, 360, 390];

  for (final w in widths) {
    for (final dark in const [false, true]) {
      final theme = dark ? 'dark' : 'light';
      testWidgets('Rezervacije mobile panel — ${w.toInt()}px $theme — '
          'no overflow', (tester) async {
        tester.view.physicalSize = Size(w, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: const Scaffold(
              body: SingleChildScrollView(
                // Live outer gutter is 12px each side (handoff `0 12px`).
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: _MobilePanelHarness(),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
