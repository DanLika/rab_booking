// Responsive + fidelity render harness for the owner Rezervacije lean ledger.
//
// Pumps the REAL [BookingsLedger] (the pure presentation widget the live
// screen renders — no Scaffold/drawer/providers) across the full breakpoint
// range in light + dark, with a fixture that exercises every row variant:
// pending / confirmed / completed / cancelled / imported, full + partial +
// zero payment, an over-long guest name (ellipsis stress), and a non-navigable
// imported row.
//
//  * Primary assertion: NO overflow at any size (`tester.takeException`).
//  * Bonus: dumps a PNG per size/theme to /tmp/rezervacije-impl for the
//    handoff-vs-impl side-by-side (best-effort; never fails the test).
//
// Fonts (Inter + MaterialSymbolsRounded) load via rootBundle so the render is
// CI-safe and tofu-free. The lean ledger reads no l10n + no providers, so the
// harness stays hermetic (a lightweight stub stands in for the status tabs).

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bookbed/core/design/tokens.dart';
import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/owner_dashboard/presentation/widgets/bookings/bookings_ledger.dart';
import 'package:bookbed/shared/widgets/redesign.dart' show BbBookingStatus;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle, FontLoader;
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

List<BookingsLedgerEntry> _fixture() => const <BookingsLedgerEntry>[
  BookingsLedgerEntry(
    detailBookingId: 'BB-2403',
    guestName: 'Petra Jurić-Maksimović Vrlo Dugačko Ime Za Test',
    reference: '#BB-2403',
    propertyName: 'Stan Lavanda na samome moru',
    unitName: 'Apartman A',
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
  BookingsLedgerEntry(
    detailBookingId: 'BB-2398',
    guestName: 'Sandra Kovač',
    reference: '#BB-2398',
    propertyName: 'Stan Lavanda',
    unitName: 'Apartman A',
    range: '12.–15. srp',
    nights: 3,
    guests: 4,
    status: BbBookingStatus.confirmed,
    isCancelled: false,
    hasPayment: true,
    total: 420,
    paid: 420,
  ),
  BookingsLedgerEntry(
    detailBookingId: 'BB-2391',
    guestName: 'Luka Babić',
    reference: '#BB-2391',
    propertyName: 'Vila Marina',
    unitName: 'Premium suite',
    range: '24.–27. tra',
    nights: 3,
    guests: 2,
    status: BbBookingStatus.completed,
    isCancelled: false,
    hasPayment: true,
    total: 540,
    paid: 540,
  ),
  BookingsLedgerEntry(
    detailBookingId: 'BB-2380',
    guestName: 'Ana Šimić',
    reference: '#BB-2380',
    propertyName: 'Vila Marina',
    unitName: 'Studio 4',
    range: '2.–5. svi',
    nights: 3,
    guests: 2,
    status: BbBookingStatus.cancelled,
    isCancelled: true,
    hasPayment: false,
    total: 0,
    paid: 0,
  ),
  BookingsLedgerEntry(
    detailBookingId: null, // imported iCal — not navigable
    guestName: 'Tomislav Vukić',
    reference: '#BDC-99812',
    propertyName: 'Booking.com',
    unitName: 'Uvezena rezervacija',
    range: '25.–28. srp',
    nights: 3,
    guests: 0,
    status: BbBookingStatus.imported,
    isCancelled: false,
    hasPayment: false,
    total: 0,
    paid: 0,
  ),
  BookingsLedgerEntry(
    detailBookingId: 'BB-2402',
    guestName: 'Marko Horvat',
    reference: '#BB-2402',
    propertyName: 'Vila Marina',
    unitName: 'Studio 4',
    range: '8.–11. srp',
    nights: 3,
    guests: 2,
    status: BbBookingStatus.pending,
    isCancelled: false,
    hasPayment: true,
    total: 360,
    paid: 0,
  ),
  BookingsLedgerEntry(
    detailBookingId: 'BB-2385',
    guestName: 'Eva Novak',
    reference: '#BB-2385',
    propertyName: 'Stan Lavanda',
    unitName: 'Apartman A',
    range: '9.–12. svi',
    nights: 3,
    guests: 3,
    status: BbBookingStatus.completed,
    isCancelled: false,
    hasPayment: true,
    total: 300,
    paid: 300,
  ),
];

/// Lightweight stand-in for `BookingsTabBar` (which reads providers + l10n).
/// Mirrors its Wrap-of-chips shape so the ledger header layout is realistic.
class _StubTabs extends StatelessWidget {
  const _StubTabs();

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    const labels = <String>[
      'Sve',
      'Na čekanju',
      'Potvrđene',
      'Završene',
      'Otkazane',
      'Uvezene',
    ];
    return Wrap(
      spacing: BBSpace.xs,
      runSpacing: BBSpace.xs,
      children: <Widget>[
        for (final l in labels)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: c.surfaceVariant,
              borderRadius: BBRadius.fullAll,
            ),
            child: Text(l, style: BBType.label(context)),
          ),
      ],
    );
  }
}

const _breakpoints = <({String name, double w, double h})>[
  (name: 'phone', w: 390, h: 844),
  (name: 'tablet_portrait', w: 768, h: 1024),
  (name: 'tablet_landscape', w: 1024, h: 768),
  (name: 'desktop_1280', w: 1280, h: 900),
  (name: 'desktop_1440', w: 1440, h: 900),
  (name: 'large_1920', w: 1920, h: 1080),
  (name: 'uhd_2560', w: 2560, h: 1440),
  (name: 'uhd_3840', w: 3840, h: 2160),
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  for (final bp in _breakpoints) {
    for (final dark in const [false, true]) {
      final theme = dark ? 'dark' : 'light';
      testWidgets('Rezervacije ledger — ${bp.name} $theme — no overflow', (
        tester,
      ) async {
        tester.view.physicalSize = Size(bp.w, bp.h);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final isMobile = bp.w < 600;
        final boundaryKey = GlobalKey();

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
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
                      padding: EdgeInsets.all(
                        isMobile ? BBSpace.xs : BBSpace.sm,
                      ),
                      child: RepaintBoundary(
                        key: boundaryKey,
                        child: BookingsLedger(
                          tabBar: const _StubTabs(),
                          entries: _fixture(),
                          onOpenDetail: (_) {},
                          onFilters: () {},
                          footerLabel: 'Prikazano svih 8 rezervacija',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // PRIMARY assertion — no RenderFlex / layout overflow at this size.
        expect(tester.takeException(), isNull);

        // Bonus — dump a PNG for the handoff side-by-side (never fails).
        await tester.runAsync(() async {
          try {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            if (data != null) {
              final dir = Directory('/tmp/rezervacije-impl')
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

  // Empty-state body override still lays out (tabs header + empty body, no
  // footer) without overflow at the tight phone width.
  testWidgets('Rezervacije ledger — empty bodyOverride — no overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BookingsLedger(
              tabBar: const _StubTabs(),
              entries: const <BookingsLedgerEntry>[],
              onOpenDetail: (_) {},
              onFilters: () {},
              bodyOverride: const Padding(
                padding: EdgeInsets.all(BBSpace.md),
                child: Text('Nema rezervacija'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
