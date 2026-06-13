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
    required this.premium,
    required this.sectionBorder,
    required this.cardBackground,
    required this.inputFillColor,
  });

  /// Screen body gradient (TIP 1 diagonal, topLeft → bottomRight)
  /// Used for: main page backgrounds, scaffold bodies
  final LinearGradient pageBackground;

  /// Section/Card gradient (right → left, horizontal)
  /// Used for: sidebar panels, elevated sections
  final LinearGradient sectionBackground;

  /// Brand purple gradient (topLeft → bottomRight)
  /// Used for: AppBar, drawer header, primary buttons
  final LinearGradient brandPrimary;

  /// Premium gradient (topLeft → bottomRight)
  /// Used for: Subscription badges, Pro plan cards
  /// Deeper purple variant of brand primary
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

  // Page TIP 1 colors — user-mandated simple diagonal page-shell gradient:
  // 2 colors @100% opacity, 2 stops, topLeft → bottomRight, fade ends at 30%
  // (page direction mirrors the section's topRight → bottomLeft).
  // Light: shell light-gray #ECEDF2 (the family paired with border #E0DCE8,
  // replacing the old flat #F0F1F5 / the spec's #F8F9FA) → white.
  static const Color _lightStart = Color(0xFFECEDF2);
  static const Color _lightEnd = Color(0xFFFFFFFF);

  // Dark: veryDarkGray #1A1A1A → mediumDarkGray #2D2D2D (user spec; replaces
  // the old flat OLED #000000).
  static const Color _darkStart = Color(0xFF1A1A1A);
  static const Color _darkEnd = Color(0xFF2D2D2D);

  // Brand purple (same for light & dark)
  static const Color _brandStart = Color(0xFF6B4CE6); // Purple
  static const Color _brandEnd = Color(0xFF7E5FEE); // Lighter purple

  // Premium purple (deeper, richer purple for subscriptions)
  static const Color _premiumStart = Color(0xFF5233CC); // Deep purple
  static const Color _premiumEnd = Color(0xFF8B66F7); // Lavender purple

  // Section border colors — handoff hairline (`--bb-panel-border`).
  // Light: rgba(20,24,45,.05) over panel; dark: rgba(255,255,255,.06).
  static const Color _lightBorder = Color(0xFFE0DCE8);
  static const Color _darkBorder = Color(0xFF35323D);

  // Card background colors (flat, no gradient).
  // Light = `panelBg` `#FBFBFD`; dark = `panelBg` `#0B0B0D` per handoff
  // (`BbRedesignTokens.panelBg`).
  static const Color _lightCard = Color(0xFFFBFBFD);
  static const Color _darkCard = Color(0xFF0B0B0D);

  // Input fill colors — handoff `--bb-surface-variant` (subtle off-shell).
  // Light: shellBg lifted toward white; dark: panelBg lifted toward purple.
  static const Color _lightInputFill = Color(0xFFF5F6FA);
  static const Color _darkInputFill = Color(0xFF15151A);

  // Section TIP 1 colors — user-mandated simple diagonal section gradient:
  // 2 colors @100% opacity, 2 stops, topRight → bottomLeft, fade ends at 30%.
  // Light start is a cool light gray (user: replace #F8F9FA with a gray that
  // pairs with shell #F0F1F5 / border #E0DCE8). Dark pair is per user spec.
  static const Color _lightSectionStart = Color(0xFFECEDF2);
  static const Color _lightSectionEnd = Color(0xFFFFFFFF);
  static const Color _darkSectionStart = Color(0xFF1A1A1A);
  static const Color _darkSectionEnd = Color(0xFF2D2D2D);

  // ============================================================================
  // PREDEFINED THEME INSTANCES
  // ============================================================================

  /// Light theme gradients
  static const AppGradients light = AppGradients(
    pageBackground: LinearGradient(
      // User TIP 1: simple diagonal, 2 opaque colors, fade ends at 30% of the
      // screen. topLeft → bottomRight (mirror of the section direction).
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_lightStart, _lightEnd],
      stops: [0.0, 0.3],
    ),
    sectionBackground: LinearGradient(
      // User TIP 1 (overrides handoff flat `--bb-panel-bg`): simple diagonal,
      // 2 opaque colors, fade ends at 30% of the surface.
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [_lightSectionStart, _lightSectionEnd],
      stops: [0.0, 0.3],
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
      // User TIP 1: simple diagonal, 2 opaque colors, fade ends at 30% of the
      // screen. topLeft → bottomRight (mirror of the section direction).
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_darkStart, _darkEnd],
      stops: [0.0, 0.3],
    ),
    sectionBackground: LinearGradient(
      // User TIP 1 (overrides handoff flat `--bb-panel-bg`): simple diagonal,
      // 2 opaque colors, fade ends at 30% of the surface.
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [_darkSectionStart, _darkSectionEnd],
      stops: [0.0, 0.3],
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
