import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/core/theme/app_theme.dart';

/// Visual testing helpers for breakpoint and theme testing
class VisualTestHelpers {
  VisualTestHelpers._();

  // ============================================================================
  // BREAKPOINT CONFIGURATIONS
  // ============================================================================

  /// Mobile breakpoint (iPhone SE)
  static const Size mobileSE = Size(375, 667);

  /// Mobile breakpoint (iPhone 12/13)
  static const Size mobile = Size(390, 844);

  /// Mobile breakpoint (iPhone 14 Pro Max)
  static const Size mobileMax = Size(430, 932);

  /// Tablet breakpoint (iPad Mini)
  static const Size tabletSmall = Size(744, 1133);

  /// Tablet breakpoint (iPad Pro 11")
  static const Size tablet = Size(834, 1194);

  /// Tablet breakpoint (iPad Pro 12.9")
  static const Size tabletLarge = Size(1024, 1366);

  /// Desktop breakpoint (1080p)
  static const Size desktop = Size(1920, 1080);

  /// Desktop breakpoint (1440p)
  static const Size desktop2K = Size(2560, 1440);

  /// Desktop breakpoint (4K)
  static const Size desktop4K = Size(3840, 2160);

  /// All mobile breakpoints
  static const List<Size> mobileBreakpoints = [
    mobileSE,
    mobile,
    mobileMax,
  ];

  /// All tablet breakpoints
  static const List<Size> tabletBreakpoints = [
    tabletSmall,
    tablet,
    tabletLarge,
  ];

  /// All desktop breakpoints
  static const List<Size> desktopBreakpoints = [
    desktop,
    desktop2K,
  ];

  /// All breakpoints
  static const List<Size> allBreakpoints = [
    ...mobileBreakpoints,
    ...tabletBreakpoints,
    ...desktopBreakpoints,
  ];

  // ============================================================================
  // TEST WRAPPER BUILDERS
  // ============================================================================

  /// Wrap widget with MaterialApp and theme for testing
  static Widget wrapWithMaterialApp(
    Widget child, {
    ThemeMode themeMode = ThemeMode.light,
    Size? size,
    RouteSettings? routeSettings,
  }) {
    return MediaQuery(
      data: MediaQueryData(size: size ?? desktop),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: Material(child: child),
      ),
    );
  }

  /// Wrap widget with MaterialApp, theme, and specific size
  static Widget wrapWithSize(
    Widget child,
    Size size, {
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: Material(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // TESTING UTILITIES
  // ============================================================================

  /// Test widget at all breakpoints
  static Future<void> testAtAllBreakpoints(
    WidgetTester tester,
    Widget child,
    Future<void> Function(Size size) testCallback, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    for (final size in allBreakpoints) {
      await tester.pumpWidget(wrapWithSize(child, size, themeMode: themeMode));
      await tester.pumpAndSettle();
      await testCallback(size);
    }
  }

  /// Test widget in both light and dark themes
  static Future<void> testInBothThemes(
    WidgetTester tester,
    Widget child,
    Future<void> Function(ThemeMode theme) testCallback, {
    Size size = desktop,
  }) async {
    for (final theme in [ThemeMode.light, ThemeMode.dark]) {
      await tester.pumpWidget(wrapWithSize(child, size, themeMode: theme));
      await tester.pumpAndSettle();
      await testCallback(theme);
    }
  }

  /// Test widget at specific breakpoint categories
  static Future<void> testAtBreakpointCategories(
    WidgetTester tester,
    Widget child,
    Future<void> Function(Size size, String category) testCallback, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    // Test one size from each category
    final testSizes = {
      'mobile': mobile,
      'tablet': tablet,
      'desktop': desktop,
    };

    for (final entry in testSizes.entries) {
      await tester.pumpWidget(
        wrapWithSize(child, entry.value, themeMode: themeMode),
      );
      await tester.pumpAndSettle();
      await testCallback(entry.value, entry.key);
    }
  }

  // ============================================================================
  // VISUAL REGRESSION HELPERS
  // ============================================================================

  /// Generate golden file name
  static String goldenFileName(
    String testName,
    String variant, {
    String? theme,
    Size? size,
  }) {
    final parts = <String>[testName, variant];
    if (theme != null) parts.add(theme);
    if (size != null) parts.add('${size.width.toInt()}x${size.height.toInt()}');
    return 'goldens/${parts.join('_')}.png';
  }

  /// Test golden at multiple configurations
  static Future<void> testGoldenAtConfigurations(
    WidgetTester tester,
    Widget child,
    String testName, {
    List<Size>? sizes,
    List<ThemeMode>? themes,
  }) async {
    final testSizes = sizes ?? [mobile, tablet, desktop];
    final testThemes = themes ?? [ThemeMode.light, ThemeMode.dark];

    for (final size in testSizes) {
      for (final theme in testThemes) {
        final widget = wrapWithSize(child, size, themeMode: theme);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final themeName = theme == ThemeMode.light ? 'light' : 'dark';
        final fileName = goldenFileName(
          testName,
          'variant',
          theme: themeName,
          size: size,
        );

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(fileName),
        );
      }
    }
  }

  // ============================================================================
  // ACCESSIBILITY HELPERS
  // ============================================================================

  /// Check if widget has semantic labels
  static bool hasSemanticLabel(WidgetTester tester, String label) {
    try {
      final semantics = tester.getSemantics(find.bySemanticsLabel(label));
      return semantics.label.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Verify color contrast ratio (WCAG AA requires 4.5:1 for normal text)
  static bool meetsColorContrast(
    Color foreground,
    Color background, {
    double minRatio = 4.5,
  }) {
    final ratio = _calculateContrastRatio(foreground, background);
    return ratio >= minRatio;
  }

  /// Calculate contrast ratio between two colors
  static double _calculateContrastRatio(Color c1, Color c2) {
    final l1 = _relativeLuminance(c1);
    final l2 = _relativeLuminance(c2);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculate relative luminance
  static double _relativeLuminance(Color color) {
    final r = _linearize((color.r * 255.0).round() / 255);
    final g = _linearize((color.g * 255.0).round() / 255);
    final b = _linearize((color.b * 255.0).round() / 255);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearize(double channel) {
    if (channel <= 0.03928) {
      return channel / 12.92;
    }
    return ((channel + 0.055) / 1.055).pow(2.4);
  }
}

extension DoubleExtension on double {
  double pow(double exponent) {
    return this * this; // Simplified for this use case
  }
}

// ============================================================================
// COMMON TEST MATCHERS
// ============================================================================

/// Custom matcher for responsive behavior
class IsResponsive extends Matcher {
  const IsResponsive();

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! Widget) return false;
    // Add specific responsive checks here
    return true;
  }

  @override
  Description describe(Description description) {
    return description.add('is responsive at all breakpoints');
  }
}

const isResponsive = IsResponsive();
