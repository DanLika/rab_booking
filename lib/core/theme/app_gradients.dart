import 'package:flutter/material.dart';

/// Centralized gradient system using ThemeExtension
///
/// This class provides theme-aware gradients that automatically adapt
/// to light/dark mode. Change colors here = update everywhere!
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     gradient: context.gradients.pageBackground,
///   ),
/// )
/// ```
@immutable
class AppGradients extends ThemeExtension<AppGradients> {
  const AppGradients({
    required this.pageBackground,
    required this.sectionBackground,
    required this.brandPrimary,
    required this.sectionBorder,
  });

  /// Screen body gradient (left → right, horizontal)
  /// Used for: main page backgrounds, scaffold bodies
  final LinearGradient pageBackground;

  /// Section/Card gradient (right → left, horizontal)
  /// Used for: cards, sections, elevated containers
  final LinearGradient sectionBackground;

  /// Brand purple gradient (topLeft → bottomRight)
  /// Used for: AppBar, drawer header, primary buttons
  final LinearGradient brandPrimary;

  /// Section border color (theme-aware)
  /// Light: warm beige (#E8E5DC), Dark: warm gray (#3D3733)
  final Color sectionBorder;

  // ============================================================================
  // CENTRAL COLOR DEFINITIONS - CHANGE HERE = UPDATE EVERYWHERE!
  // ============================================================================

  // Light theme: Warm cream → White (Mediterranean sun feel)
  static const Color _lightStart = Color(0xFFFAF8F3); // Cream/beige
  static const Color _lightEnd = Color(0xFFFFFFFF); // White

  // Dark theme: Warm charcoal → Warm stone (Mediterranean evening feel)
  static const Color _darkStart = Color(0xFF1C1917); // Warm charcoal
  static const Color _darkEnd = Color(0xFF292524); // Warm stone

  // Brand purple (same for light & dark)
  static const Color _brandStart = Color(0xFF6B4CE6); // Purple
  static const Color _brandEnd = Color(0xFF7E5FEE); // Lighter purple

  // Section border colors (warm tones to match backgrounds)
  static const Color _lightBorder = Color(0xFFE8E5DC); // Warm beige
  static const Color _darkBorder = Color(0xFF3D3733); // Warm gray

  // ============================================================================
  // PREDEFINED THEME INSTANCES
  // ============================================================================

  /// Light theme gradients
  static const AppGradients light = AppGradients(
    pageBackground: LinearGradient(
      colors: [_lightStart, _lightEnd],
      stops: [0.0, 0.3],
    ),
    sectionBackground: LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [_lightStart, _lightEnd],
      stops: [0.0, 0.3],
    ),
    brandPrimary: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_brandStart, _brandEnd],
    ),
    sectionBorder: _lightBorder,
  );

  /// Dark theme gradients
  static const AppGradients dark = AppGradients(
    pageBackground: LinearGradient(
      colors: [_darkStart, _darkEnd],
      stops: [0.0, 0.3],
    ),
    sectionBackground: LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [_darkStart, _darkEnd],
      stops: [0.0, 0.3],
    ),
    brandPrimary: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_brandStart, _brandEnd],
    ),
    sectionBorder: _darkBorder,
  );

  // ============================================================================
  // THEME EXTENSION OVERRIDES
  // ============================================================================

  @override
  AppGradients copyWith({
    LinearGradient? pageBackground,
    LinearGradient? sectionBackground,
    LinearGradient? brandPrimary,
    Color? sectionBorder,
  }) {
    return AppGradients(
      pageBackground: pageBackground ?? this.pageBackground,
      sectionBackground: sectionBackground ?? this.sectionBackground,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      sectionBorder: sectionBorder ?? this.sectionBorder,
    );
  }

  @override
  AppGradients lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;

    return AppGradients(
      pageBackground: LinearGradient.lerp(pageBackground, other.pageBackground, t)!,
      sectionBackground: LinearGradient.lerp(sectionBackground, other.sectionBackground, t)!,
      brandPrimary: LinearGradient.lerp(brandPrimary, other.brandPrimary, t)!,
      sectionBorder: Color.lerp(sectionBorder, other.sectionBorder, t)!,
    );
  }

  // ============================================================================
  // HELPER GETTERS FOR DIRECT COLOR ACCESS
  // ============================================================================

  /// Get the start color of page background gradient
  Color get pageBackgroundStart => pageBackground.colors.first;

  /// Get the end color of page background gradient
  Color get pageBackgroundEnd => pageBackground.colors.last;

  /// Get the start color of brand gradient
  Color get brandStart => brandPrimary.colors.first;

  /// Get the end color of brand gradient
  Color get brandEnd => brandPrimary.colors.last;

  // ============================================================================
  // STATIC COLOR ACCESS (for use without context)
  // ============================================================================

  /// Light theme page background start color
  static Color get lightPageStart => _lightStart;

  /// Light theme page background end color
  static Color get lightPageEnd => _lightEnd;

  /// Dark theme page background start color
  static Color get darkPageStart => _darkStart;

  /// Dark theme page background end color
  static Color get darkPageEnd => _darkEnd;

  /// Brand gradient start color
  static Color get brandPrimaryStart => _brandStart;

  /// Brand gradient end color
  static Color get brandPrimaryEnd => _brandEnd;
}
