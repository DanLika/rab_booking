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
    required this.cardBackground,
    required this.inputFillColor,
    required this.premium,
  });

  /// Screen body gradient (left → right, horizontal)
  /// Used for: main page backgrounds, scaffold bodies
  final LinearGradient pageBackground;

  /// Section/Card gradient (right → left, horizontal)
  /// Used for: sidebar panels, elevated sections
  final LinearGradient sectionBackground;

  /// Brand purple gradient (topLeft → bottomRight)
  /// Used for: AppBar, drawer header, primary buttons
  final LinearGradient brandPrimary;

  /// Premium/Gold gradient (topLeft → bottomRight)
  /// Used for: Subscription badges, Pro plan cards
  final LinearGradient premium;

  /// Section border color (theme-aware)
  /// Light: cool gray (#E0DCE8), Dark: dark cool gray (#35323D)
  final Color sectionBorder;

  /// Card background color (flat, no gradient)
  /// Used for: info cards, list tiles, flat containers
  final Color cardBackground;

  /// Input fill color for text fields, dropdowns, and form inputs
  /// Light: subtle lavender (#F5F3F9), Dark: darker purple-gray (#1E1C24)
  final Color inputFillColor;

  // ============================================================================
  // CENTRAL COLOR DEFINITIONS - CHANGE HERE = UPDATE EVERYWHERE!
  // ============================================================================

  // Light theme: Cool lavender-gray → White (matches purple brand)
  static const Color _lightStart = Color(0xFFF5F3F9); // Lavender-gray
  static const Color _lightEnd = Color(0xFFFFFFFF); // White

  // Dark theme: Cool dark purple-gray (matches purple brand)
  static const Color _darkStart = Color(0xFF1A1820); // Dark purple-gray
  static const Color _darkEnd = Color(0xFF211F26); // Slightly lighter

  // Brand purple (same for light & dark)
  static const Color _brandStart = Color(0xFF6B4CE6); // Purple
  static const Color _brandEnd = Color(0xFF7E5FEE); // Lighter purple

  // Premium Gold/Orange
  static const Color _premiumStart = Color(0xFFFF9966); // Orange
  static const Color _premiumEnd = Color(0xFFFF5E62); // Red-Orange (Sunset)

  // Section border colors (cool tones to match backgrounds)
  static const Color _lightBorder = Color(0xFFE0DCE8); // Cool gray
  static const Color _darkBorder = Color(0xFF35323D); // Dark cool gray

  // Card background colors (flat, no gradient)
  static const Color _lightCard = Color(0xFFFFFFFF); // White
  static const Color _darkCard = Color(0xFF252330); // Dark purple-gray

  // Input fill colors (for text fields, dropdowns)
  static const Color _lightInputFill = Color(0xFFF5F3F9); // Subtle lavender
  static const Color _darkInputFill = Color(0xFF1E1C24); // Darker purple-gray

  // ============================================================================
  // PREDEFINED THEME INSTANCES
  // ============================================================================

  /// Light theme gradients
  static const AppGradients light = AppGradients(
    pageBackground: LinearGradient(
      colors: [_lightStart, _lightEnd],
      stops: [0.0, 0.6],
    ),
    sectionBackground: LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [Color(0xFFEFECF5), Color(0xFFF8F7FB)],
      stops: [0.0, 0.5],
    ),
    brandPrimary: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_brandStart, _brandEnd],
    ),
    premium: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_premiumStart, _premiumEnd],
    ),
    sectionBorder: _lightBorder,
    cardBackground: _lightCard,
    inputFillColor: _lightInputFill,
  );

  /// Dark theme gradients
  static const AppGradients dark = AppGradients(
    pageBackground: LinearGradient(
      colors: [_darkStart, _darkEnd],
      stops: [0.0, 0.6],
    ),
    sectionBackground: LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [Color(0xFF252330), Color(0xFF1E1C24)],
      stops: [0.0, 0.5],
    ),
    brandPrimary: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_brandStart, _brandEnd],
    ),
    premium: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_premiumStart, _premiumEnd],
    ),
    sectionBorder: _darkBorder,
    cardBackground: _darkCard,
    inputFillColor: _darkInputFill,
  );

  // ============================================================================
  // THEME EXTENSION OVERRIDES
  // ============================================================================

  @override
  AppGradients copyWith({
    LinearGradient? pageBackground,
    LinearGradient? sectionBackground,
    LinearGradient? brandPrimary,
    LinearGradient? premium,
    Color? sectionBorder,
    Color? cardBackground,
    Color? inputFillColor,
  }) {
    return AppGradients(
      pageBackground: pageBackground ?? this.pageBackground,
      sectionBackground: sectionBackground ?? this.sectionBackground,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      premium: premium ?? this.premium,
      sectionBorder: sectionBorder ?? this.sectionBorder,
      cardBackground: cardBackground ?? this.cardBackground,
      inputFillColor: inputFillColor ?? this.inputFillColor,
    );
  }

  @override
  AppGradients lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;

    return AppGradients(
      pageBackground: LinearGradient.lerp(
        pageBackground,
        other.pageBackground,
        t,
      )!,
      sectionBackground: LinearGradient.lerp(
        sectionBackground,
        other.sectionBackground,
        t,
      )!,
      brandPrimary: LinearGradient.lerp(brandPrimary, other.brandPrimary, t)!,
      premium: LinearGradient.lerp(premium, other.premium, t)!,
      sectionBorder: Color.lerp(sectionBorder, other.sectionBorder, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      inputFillColor: Color.lerp(inputFillColor, other.inputFillColor, t)!,
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

  /// Get the start color of premium gradient
  Color get premiumStart => premium.colors.first;

  /// Get the end color of premium gradient
  Color get premiumEnd => premium.colors.last;

  // ============================================================================
  // STATIC COLOR ACCESS (for card backgrounds)
  // ============================================================================

  /// Light theme card background
  static Color get lightCardBackground => _lightCard;

  /// Dark theme card background
  static Color get darkCardBackground => _darkCard;

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
