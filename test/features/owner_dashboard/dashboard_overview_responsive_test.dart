// Responsive + fidelity render harness for the owner Pregled (Dashboard
// Overview) panel.
//
// Pumps the REAL dashboard sections via
// `DashboardOverviewTab.buildPanelForTest` (the same `_pregledPanelChildren`
// the live screen renders — no Scaffold/drawer/providers) across the full
// breakpoint range in light + dark, with a fixture that mirrors the handoff
// sample (€3.840 / 14 / 78% / 768·3072 / direct·booking·airbnb / 4 arrivals).
//
//  * Primary assertion: NO overflow at any size (`tester.takeException`).
//  * Bonus: dumps a PNG per size/theme to <tmp>/pregled-impl for the
//    handoff-vs-impl side-by-side (best-effort; never fails the test).
//
// Fonts (Inter + MaterialSymbolsRounded) load via rootBundle so the render is
// CI-safe and tofu-free.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/owner_dashboard/domain/models/unified_dashboard_data.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/dashboard_overview_tab.dart';
import 'package:bookbed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle, FontLoader;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Best-effort font loading so the dumped PNGs are tofu-free. A miss never
/// fails the test — the overflow assertion is the real gate.
Future<void> _loadFonts() async {
  try {
    final inter = FontLoader('Inter');
    for (final w in const ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold']) {
      inter.addFont(rootBundle.load('assets/google_fonts/Inter-$w.ttf'));
    }
    await inter.load();
  } catch (_) {}

  try {
    final base = Directory(
      '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev',
    );
    String path = '';
    if (base.existsSync()) {
      for (final e in base.listSync()) {
        if (e.path.contains('/material_symbols_icons-')) {
          final f = File('${e.path}/lib/fonts/MaterialSymbolsRounded.ttf');
          if (f.existsSync()) {
            path = f.path;
            break;
          }
        }
      }
    }
    if (path.isNotEmpty) {
      final bytes = await File(path).readAsBytes();
      // BbIcon sets fontPackage → real family is prefixed.
      final sym = FontLoader(
        'packages/material_symbols_icons/MaterialSymbolsRounded',
      )..addFont(Future.value(ByteData.view(bytes.buffer)));
      await sym.load();
    }
  } catch (_) {}
}

DateRangeFilter get _range => DateRangeFilter(
  startDate: DateTime(2026, 5, 1),
  endDate: DateTime(2026, 5, 30),
  preset: 'last30',
);

UnifiedDashboardData _fixture() {
  final base = DateTime(2026, 5, 1);
  const amounts = <double>[
    600,
    950,
    800,
    1300,
    1500,
    1200,
    1750,
    1600,
    2100,
    2300,
    2600,
    3000,
    3600,
    3840,
  ];
  final revenueHistory = <RevenueDataPoint>[
    for (var i = 0; i < amounts.length; i++)
      RevenueDataPoint(
        date: base.add(Duration(days: i * 2)),
        amount: amounts[i],
        label: '${1 + i * 2}.',
      ),
  ];
  final bookingHistory = <BookingDataPoint>[
    for (var i = 0; i < amounts.length; i++)
      BookingDataPoint(
        date: base.add(Duration(days: i * 2)),
        count: 6 + i,
        label: '${1 + i * 2}.',
      ),
  ];
  return UnifiedDashboardData(
    revenue: 3840,
    bookings: 14,
    upcomingCheckIns: 4,
    distinctGuests: 9,
    occupancyRate: 78,
    revenueBySource: const {'direct': 2640, 'booking_com': 840, 'airbnb': 360},
    depositsCollected: 768,
    depositsOutstanding: 3072,
    upcomingArrivals: [
      UpcomingArrival(
        bookingId: '1',
        guestName: 'Marko Horvat',
        propertyName: 'Vila Marina',
        unitName: 'Studio 4',
        checkIn: DateTime(2026, 7, 8),
        nights: 3,
        status: 'pending',
      ),
      UpcomingArrival(
        bookingId: '2',
        guestName: 'Sandra Kovač',
        propertyName: 'Stan Lavanda',
        unitName: 'Apartman A',
        checkIn: DateTime(2026, 7, 12),
        nights: 3,
        status: 'confirmed',
      ),
      UpcomingArrival(
        bookingId: '3',
        guestName: 'Eva Novak',
        propertyName: 'Vila Marina',
        unitName: 'Premium',
        checkIn: DateTime(2026, 7, 15),
        nights: 5,
        status: 'confirmed',
      ),
      UpcomingArrival(
        bookingId: '4',
        guestName: 'Luka Babić',
        propertyName: 'Stan Lavanda',
        unitName: 'Studio B',
        checkIn: DateTime(2026, 7, 19),
        nights: 2,
        status: 'confirmed',
      ),
    ],
    revenueHistory: revenueHistory,
    bookingHistory: bookingHistory,
  );
}

const _breakpoints = <({String name, double width})>[
  (name: 'mobile', width: 390),
  (name: 'tablet', width: 768),
  (name: 'desktop', width: 1440),
  (name: 'uhd4k', width: 2560),
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  for (final bp in _breakpoints) {
    for (final dark in const [false, true]) {
      final theme = dark ? 'dark' : 'light';
      testWidgets('Pregled panel — ${bp.name} $theme — no overflow', (
        tester,
      ) async {
        tester.view.physicalSize = Size(bp.width, 6000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final isMobile = bp.width < 600;
        final boundaryKey = GlobalKey();

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('hr'),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      // Mirrors the live BBContentMaxWidth(1100) clamp; mobile is
                      // edge-to-edge.
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 1100,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 8 : 16),
                        child: RepaintBoundary(
                          key: boundaryKey,
                          child: Builder(
                            builder: (context) =>
                                const DashboardOverviewTab().buildPanelForTest(
                                  context,
                                  data: _fixture(),
                                  dateRange: _range,
                                  isMobile: isMobile,
                                  userName: 'Ivana',
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // Advance past the entrance animations (radial 1200ms, chart, sparkline).
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        // PRIMARY assertion — no RenderFlex / layout overflow at this size.
        expect(tester.takeException(), isNull);

        // Bonus — dump a PNG for the handoff side-by-side (never fails the test).
        await tester.runAsync(() async {
          try {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1.0);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            if (data != null) {
              final dir = Directory('/tmp/pregled-impl')
                ..createSync(recursive: true);
              File(
                '${dir.path}/${bp.name}_$theme.png',
              ).writeAsBytesSync(data.buffer.asUint8List());
            }
          } catch (_) {
            // Render dump is best-effort; the overflow assertion is the gate.
          }
        });
      });
    }
  }
}
