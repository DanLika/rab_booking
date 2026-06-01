import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/providers/language_provider.dart';
import 'package:bookbed/l10n/app_localizations.dart';

/// Creates a test wrapper widget with proper Riverpod scope and English language
///
/// Use this instead of raw MaterialApp + ProviderScope to ensure consistent
/// test behavior with English translations (tests are written with English expectations).
///
/// Pass `withL10n: true` for screens that read [AppLocalizations] (Material
/// l10n delegates + English locale). Default off to preserve the existing
/// widget-translation path used by `WidgetTranslations` in the widget feature.
///
/// Usage:
/// ```dart
/// await tester.pumpWidget(
///   createTestWidget(
///     child: MyWidgetToTest(),
///     withL10n: true,
///   ),
/// );
/// ```
Widget createTestWidget({
  required Widget child,
  bool isDarkMode = false,
  bool withL10n = false,
  List<dynamic>? overrides,
}) {
  return ProviderScope(
    overrides: [
      // Default to English for tests (tests expect English strings)
      languageProvider.overrideWith((ref) => 'en'),
      ...?overrides,
    ],
    child: MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      locale: withL10n ? const Locale('en') : null,
      localizationsDelegates: withL10n
          ? const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ]
          : null,
      supportedLocales: withL10n
          ? const [Locale('en'), Locale('hr')]
          : const [Locale('en')],
      home: Scaffold(body: child),
    ),
  );
}

/// Drains a layout-overflow `FlutterError` from the binding without failing
/// the test. Re-throws anything else so genuine exceptions still surface.
///
/// Use after `pumpWidget` for screens whose intrinsic widths overflow the
/// fixed test surface — auth glass cards, dashboard charts. The smoke-test
/// purpose ("did it mount + render Bb* primitives") is still met.
void allowOverflow(WidgetTester tester) {
  final dynamic exception = tester.takeException();
  if (exception == null) return;
  if (exception is FlutterError &&
      exception.message.toLowerCase().contains('overflow')) {
    return;
  }
  // ignore: only_throw_errors
  throw exception;
}

/// Creates a test wrapper with Croatian language
///
/// Use when testing Croatian-specific translations.
Widget createTestWidgetHr({
  required Widget child,
  bool isDarkMode = false,
  List<dynamic>? overrides,
}) {
  return ProviderScope(
    overrides: [languageProvider.overrideWith((ref) => 'hr'), ...?overrides],
    child: MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(body: child),
    ),
  );
}
