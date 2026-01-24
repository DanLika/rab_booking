import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookbed/features/widget/presentation/providers/language_provider.dart';

/// Creates a test wrapper widget with proper Riverpod scope and English language
///
/// Use this instead of raw MaterialApp + ProviderScope to ensure consistent
/// test behavior with English translations (tests are written with English expectations).
///
/// Usage:
/// ```dart
/// await tester.pumpWidget(
///   createTestWidget(
///     child: MyWidgetToTest(),
///   ),
/// );
/// ```
Widget createTestWidget({
  required Widget child,
  bool isDarkMode = false,
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
      home: Scaffold(body: child),
    ),
  );
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
