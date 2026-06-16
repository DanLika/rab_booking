// Responsive + fidelity render harness for the owner Timeline/Kalendar AND
// Mjesečni (month) premium chrome — the premium header (eyebrow + "Kalendar"
// title + Timeline/Mjesečni view switch), the top toolbar (Timeline only), the
// status-badge legend card, and the FAB.
//
// Pumps the REAL chrome via `OwnerTimelineCalendarScreen.buildChromeForTest`
// and `MonthCalendarScreen.buildChromeForTest` (no Scaffold/drawer/Firebase —
// the FROZEN grid is swapped for a sized placeholder) across the full
// breakpoint range in light + dark.
//
//  * Primary assertion: NO overflow at any size (`tester.takeException`).
//  * Bonus: dumps a PNG per size/theme to /tmp/calendar-impl for the
//    handoff-vs-impl side-by-side (best-effort; never fails the test).
//
// Fonts (Inter) load via rootBundle so the dumped PNGs are tofu-free. The
// chrome itself uses built-in MaterialIcons (no asset symbols), so a font miss
// never affects the overflow gate.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/calendar/month_calendar_screen.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/owner_timeline_calendar_screen.dart';
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
      final sym = FontLoader(
        'packages/material_symbols_icons/MaterialSymbolsRounded',
      )..addFont(Future.value(ByteData.view(bytes.buffer)));
      await sym.load();
    }
  } catch (_) {}
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
      testWidgets('Calendar chrome — ${bp.name} $theme — no overflow', (
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
                      // Mirrors the live content-max-width clamp; mobile is
                      // edge-to-edge.
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 1100,
                      ),
                      child: RepaintBoundary(
                        key: boundaryKey,
                        child: Builder(
                          builder: (context) =>
                              const OwnerTimelineCalendarScreen()
                                  .buildChromeForTest(
                                    context,
                                    isMobile: isMobile,
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

        // Advance past the FAB / view-switch implicit animations.
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        // PRIMARY assertion — no RenderFlex / layout overflow at this size.
        expect(tester.takeException(), isNull);

        // audit/126 §2A — the calendar title now lives in THIS in-body premium
        // header (the AppBar no longer renders it). Lock that coverage here so
        // the strip can't silently drop the title.
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
        expect(find.text(l10n.ownerCalendar), findsWidgets);

        // Bonus — dump a PNG for the handoff side-by-side (never fails the test).
        await tester.runAsync(() async {
          try {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            if (data != null) {
              final dir = Directory('/tmp/calendar-impl')
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

  // ── Month (Mjesečni) calendar premium chrome — same harness, mirrors the
  // Timeline loop. Header (eyebrow + title + view switch, Mjesečni active) +
  // legend card + FAB; the unit-filter + KPI strip are provider/state-bound and
  // omitted from the seam.
  for (final bp in _breakpoints) {
    for (final dark in const [false, true]) {
      final theme = dark ? 'dark' : 'light';
      testWidgets('Month calendar chrome — ${bp.name} $theme — no overflow', (
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
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 1100,
                      ),
                      child: RepaintBoundary(
                        key: boundaryKey,
                        child: Builder(
                          builder: (context) => const MonthCalendarScreen()
                              .buildChromeForTest(context, isMobile: isMobile),
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
        await tester.pump(const Duration(seconds: 2));

        // PRIMARY assertion — no RenderFlex / layout overflow at this size.
        expect(tester.takeException(), isNull);

        // audit/126 §2A — the calendar title now lives in THIS in-body premium
        // header (the AppBar no longer renders it). Lock that coverage here so
        // the strip can't silently drop the title.
        final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
        expect(find.text(l10n.ownerCalendar), findsWidgets);

        // Bonus — dump a PNG for the handoff side-by-side (never fails the test).
        await tester.runAsync(() async {
          try {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            if (data != null) {
              final dir = Directory('/tmp/calendar-month-impl')
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
