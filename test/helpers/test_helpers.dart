import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/core/theme/app_theme.dart';

/// Pump a widget with ProviderScope for testing
Future<void> pumpWithProviders(
  WidgetTester tester,
  Widget widget, {
  List<Override>? overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: widget,
      ),
    ),
  );
}

/// Pump an app with full routing and providers
Future<void> pumpRabBookingApp(
  WidgetTester tester, {
  List<Override>? overrides,
  Widget? home,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: home ?? const Scaffold(body: Text('Home')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Extension on WidgetTester for convenience methods
extension WidgetTesterX on WidgetTester {
  /// Pump a widget with ProviderScope
  Future<void> pumpWithProviders(
    Widget widget, {
    List<Override>? overrides,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides ?? [],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: widget,
        ),
      ),
    );
  }

  /// Tap and settle
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Enter text and settle
  Future<void> enterTextAndSettle(Finder finder, String text) async {
    await enterText(finder, text);
    await pumpAndSettle();
  }

  /// Scroll until visible and tap
  Future<void> scrollUntilVisibleAndTap(
    Finder finder, {
    required Finder scrollable,
    double delta = 100,
  }) async {
    await scrollUntilVisible(
      finder,
      delta,
      scrollable: scrollable,
    );
    await tapAndSettle(finder);
  }
}
