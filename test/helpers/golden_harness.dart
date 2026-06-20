// Golden-net harness (P6 — `test/golden-net`).
//
// One place that defines the mandated golden matrix and how a subject is
// mounted for a baseline screenshot:
//
//   * 4 variants per the spec — light/dark × mobile(390) / tablet(768).
//   * Real-font loading (Inter + JetBrains Mono + Tabler + Material Symbols) so
//     baselines are tofu-free.
//   * The REAL `AppTheme.lightTheme` / `darkTheme` + `hr` locale (the owner
//     surface is Croatian-first), with `debugDisableShadows = false` so the
//     premium elevation rasterises faithfully.
//
// Two entry points:
//   * [goldenScreen]  — a full screen, captured at the device VIEWPORT (what the
//     user actually sees; off-screen content is clipped, which is realistic).
//   * [goldenSurface] — a focused surface from a `@visibleForTesting` builder,
//     captured WHOLE on a tall surface via a RepaintBoundary (so a change below
//     the fold is still caught).
//
// Baselines live next to each golden test under `goldens/`. They are a LOCAL
// (macOS-rasterised) regression net — run `flutter test --tags golden` after a
// visual change and eyeball any diff. They are NOT wired into Linux CI because
// font rasterisation differs per platform; see `test/golden/README.md`.

import 'dart:io';
import 'dart:typed_data';

import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugDisableShadows;
import 'package:flutter/services.dart' show ByteData, FontLoader, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// One cell of the golden matrix.
class GoldenVariant {
  const GoldenVariant(this.device, this.width, this.height, this.brightness);

  final String device;
  final double width;
  final double height;
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;
  bool get isMobile => width < 600;
  ThemeMode get themeMode => isDark ? ThemeMode.dark : ThemeMode.light;

  /// Stable id used in the baseline filename, e.g. `mobile_dark`.
  String get id => '${device}_${isDark ? 'dark' : 'light'}';
}

/// The 4 variants mandated by P6: light/dark × mobile(390) / tablet(768).
const List<GoldenVariant> kGoldenVariants = <GoldenVariant>[
  GoldenVariant('mobile', 390, 844, Brightness.light),
  GoldenVariant('mobile', 390, 844, Brightness.dark),
  GoldenVariant('tablet', 768, 1024, Brightness.light),
  GoldenVariant('tablet', 768, 1024, Brightness.dark),
];

bool _fontsLoaded = false;

/// Loads every bundled font (+ Material Symbols from pub-cache) so goldens are
/// tofu-free. Idempotent across the suite; called from each golden's `setUpAll`.
///
/// A miss on any single family never throws — a tofu glyph is a cosmetic golden
/// diff, not a test crash.
Future<void> loadGoldenFonts() async {
  if (_fontsLoaded) return;
  TestWidgetsFlutterBinding.ensureInitialized();

  // Inter (5 weights) — body / title / button text.
  try {
    final FontLoader inter = FontLoader('Inter');
    for (final String w in const [
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      inter.addFont(rootBundle.load('assets/google_fonts/Inter-$w.ttf'));
    }
    await inter.load();
  } catch (_) {}

  // JetBrains Mono — `BBType.mono`.
  try {
    await (FontLoader('JetBrains Mono')..addFont(
          rootBundle.load('assets/google_fonts/JetBrainsMono-Medium.ttf'),
        ))
        .load();
  } catch (_) {}

  // Tabler icons — custom icon font (`TablerIcons` family).
  try {
    await (FontLoader(
      'TablerIcons',
    )..addFont(rootBundle.load('assets/fonts/TablerIcons.ttf'))).load();
  } catch (_) {}

  // Material Symbols (`BbIcon`) — package font, not in the asset bundle. Pull it
  // from pub-cache; `BbIcon` sets `fontPackage`, so the real family is prefixed.
  try {
    final Directory base = Directory(
      '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev',
    );
    if (base.existsSync()) {
      for (final FileSystemEntity e in base.listSync()) {
        if (e.path.contains('/material_symbols_icons-')) {
          final File f = File('${e.path}/lib/fonts/MaterialSymbolsRounded.ttf');
          if (f.existsSync()) {
            final Uint8List bytes = await f.readAsBytes();
            await (FontLoader(
                  'packages/material_symbols_icons/MaterialSymbolsRounded',
                )..addFont(Future<ByteData>.value(ByteData.view(bytes.buffer))))
                .load();
            break;
          }
        }
      }
    }
  } catch (_) {}

  _fontsLoaded = true;
}

MaterialApp _app({
  required GoldenVariant v,
  required Widget home,
  required Locale locale,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: v.themeMode,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: home,
  );
}

void _sizeView(WidgetTester tester, double w, double h) {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Runs [body] with real (blurred) shadows so premium elevation rasterises
/// faithfully, restoring the test default before the framework's end-of-test
/// painting-invariant check. That check runs INSIDE the test body (before
/// `addTearDown` callbacks fire), so the restore must be a `finally`, not a
/// teardown — otherwise `debugAssertAllPaintingVarsUnset` throws.
Future<void> _withRealShadows(Future<void> Function() body) async {
  final bool prev = debugDisableShadows;
  debugDisableShadows = false;
  try {
    await body();
  } finally {
    debugDisableShadows = prev;
  }
}

void _drainOverflow(WidgetTester tester, bool tolerate) {
  final dynamic ex = tester.takeException();
  if (ex == null) return;
  if (tolerate &&
      ex is FlutterError &&
      ex.toString().toLowerCase().contains('overflow')) {
    return;
  }
  // ignore: only_throw_errors
  throw ex;
}

/// Golden-tests a full screen across the 4 mandated variants, captured at the
/// device viewport. Baselines: `goldens/<name>.<variant>.png`.
///
/// [build] returns the screen fresh per variant. [overrides] supplies any
/// Riverpod overrides the screen needs to pump without Firebase. Set
/// [tolerateOverflow] for screens whose intrinsic height exceeds the viewport
/// without their own scroll view.
void goldenScreen(
  String name, {
  required Widget Function(GoldenVariant v) build,
  List<Override> Function(GoldenVariant v)? overrides,
  Locale locale = const Locale('hr'),
  bool wrapInScaffold = true,
  bool tolerateOverflow = false,
  Duration settle = const Duration(milliseconds: 800),
}) {
  group(name, () {
    setUpAll(loadGoldenFonts);
    for (final GoldenVariant v in kGoldenVariants) {
      testWidgets('$name — ${v.id}', (WidgetTester tester) async {
        await _withRealShadows(() async {
          _sizeView(tester, v.width, v.height);
          final Widget subject = build(v);
          await tester.pumpWidget(
            ProviderScope(
              overrides: overrides?.call(v) ?? const <Override>[],
              child: _app(
                v: v,
                locale: locale,
                home: wrapInScaffold ? Scaffold(body: subject) : subject,
              ),
            ),
          );
          await tester.pump();
          await tester.pump(settle);
          _drainOverflow(tester, tolerateOverflow);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/$name.${v.id}.png'),
          );
        });
      }, tags: const <String>['golden']);
    }
  });
}

/// Golden-tests a focused surface (from a `@visibleForTesting` builder) across
/// the 4 variants, captured WHOLE on a tall surface via a RepaintBoundary — so a
/// change below the fold is still caught. Baselines: `goldens/<name>.<variant>.png`.
///
/// [build] receives the live `BuildContext` (for `BbRedesignTokens.of`, l10n,
/// `MediaQuery`) and the variant. [maxContentWidth] mirrors the live
/// `BBContentMaxWidth` clamp on tablet+ (mobile is always edge-to-edge).
void goldenSurface(
  String name, {
  required Widget Function(BuildContext context, GoldenVariant v) build,
  List<Override> Function(GoldenVariant v)? overrides,
  double tallHeight = 4000,
  double? maxContentWidth,
  EdgeInsets padding = EdgeInsets.zero,
  Locale locale = const Locale('hr'),
  Duration settle = const Duration(seconds: 2),
}) {
  group(name, () {
    setUpAll(loadGoldenFonts);
    for (final GoldenVariant v in kGoldenVariants) {
      testWidgets('$name — ${v.id}', (WidgetTester tester) async {
        await _withRealShadows(() async {
          _sizeView(tester, v.width, tallHeight);
          final GlobalKey boundaryKey = GlobalKey();
          await tester.pumpWidget(
            ProviderScope(
              overrides: overrides?.call(v) ?? const <Override>[],
              child: _app(
                v: v,
                locale: locale,
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: v.isMobile
                              ? double.infinity
                              : (maxContentWidth ?? double.infinity),
                        ),
                        child: Padding(
                          padding: padding,
                          child: RepaintBoundary(
                            key: boundaryKey,
                            child: Builder(
                              builder: (BuildContext context) =>
                                  build(context, v),
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
          await tester.pump();
          await tester.pump(settle);
          await expectLater(
            find.byKey(boundaryKey),
            matchesGoldenFile('goldens/$name.${v.id}.png'),
          );
        });
      }, tags: const <String>['golden']);
    }
  });
}
