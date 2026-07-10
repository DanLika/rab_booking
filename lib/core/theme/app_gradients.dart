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

  /// Screen body fill — FLAT shell tone (gradient retired 2026-06-16).
  /// Used for: main page backgrounds, scaffold bodies
  final LinearGradient pageBackground;

  /// Section/card fill — FLAT raised tone (gradient retired 2026-06-16).
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
  /// Light: cool gray (#E2E8F0), Dark: dark cool gray (#2D3748)
  final Color sectionBorder;

  /// Card background color (flat, no gradient)
  /// Used for: info cards, list tiles, flat containers
  final Color cardBackground;

  /// Input fill color for text fields, dropdowns, and form inputs
  /// Light: #F5F5F5, Dark: #1E1E1E (handoff surface-variant)
  final Color inputFillColor;

  // ============================================================================
  // CENTRAL COLOR DEFINITIONS - CHANGE HERE = UPDATE EVERYWHERE!
  // ============================================================================

  // Page shell colors — FLAT (no gradient). Both stops = one shell tone so
  // `pageBackground` renders as a solid fill. Handoff ladder (audit/127):
  // light shell = near-white `#FAFAFB` (minimalist pass 1; was #F0F1F5, the
  // audit/127 convergence value). Both stops EQUAL = solid flat fill. Raised
  // surfaces (section/card) go white #FFFFFF.
  static const Color _lightStart = Color(0xFFFAFAFB);
  static const Color _lightEnd = Color(0xFFFAFAFB);

  // Dark shell: FLAT OLED #000 (handoff `--bb-shell-bg`/`--bb-bg`, audit/127).
  // Page is the DARKEST layer → raised surfaces (panel #141414, card #1E1E1E)
  // sit ABOVE it. WIDENED (audit/127 dark-depth): flat dark has no box-shadow,
  // so lightness steps must carry the elevation the handoff shadow would.
  static const Color _darkStart = Color(0xFF000000);
  static const Color _darkEnd = Color(0xFF000000);

  // Brand purple (same for light & dark)
  static const Color _brandStart = Color(0xFF6B4CE6); // Purple
  static const Color _brandEnd = Color(0xFF7E5FEE); // Lighter purple

  // Premium purple (deeper, richer purple for subscriptions)
  static const Color _premiumStart = Color(0xFF5233CC); // Deep purple
  static const Color _premiumEnd = Color(0xFF8B66F7); // Lavender purple

  // Section border colors — handoff `--bb-border`, cool low-chroma (audit/127;
  // replaces the warm #E0DCE8/#35323D drift).
  static const Color _lightBorder = Color(0xFFE2E8F0);
  static const Color _darkBorder = Color(0xFF2D3748);

  // Card background colors (flat, no gradient) — handoff `--bb-surface`.
  // Light #FFFFFF. Dark WIDENED to #1E1E1E (audit/127 dark-depth): the
  // lightness step is the ONLY thing lifting cards above the panel (#141414)
  // / OLED shell (#000) when there is no shadow.
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _darkCard = Color(0xFF1E1E1E);

  // Input fill colors — handoff `--bb-surface-variant`:
  // light #F5F5F5, dark WIDENED to #2A2A2A (audit/127 dark-depth).
  static const Color _lightInputFill = Color(0xFFF5F5F5);
  static const Color _darkInputFill = Color(0xFF2A2A2A);

  // Section colors — FLAT raised-surface tone = handoff `--bb-surface`,
  // one step above the page shell: white #FFFFFF on light, #1E1E1E on dark
  // (matches card; widened audit/127 dark-depth so it lifts above #000).
  static const Color _lightSectionStart = Color(0xFFFFFFFF);
  static const Color _lightSectionEnd = Color(0xFFFFFFFF);
  static const Color _darkSectionStart = Color(0xFF1E1E1E);
  static const Color _darkSectionEnd = Color(0xFF1E1E1E);

  // ============================================================================
  // PREDEFINED THEME INSTANCES
  // ============================================================================

  /// Light theme gradients
  static const AppGradients light = AppGradients(
    pageBackground: LinearGradient(
      // FLAT shell — gradient retired 2026-06-16. Both stops resolve to one
      // shell tone, so this paints a solid fill (begin/end/stops inert).
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_lightStart, _lightEnd],
      stops: [0.0, 0.3],
    ),
    sectionBackground: LinearGradient(
      // FLAT raised surface — gradient retired 2026-06-16. Solid fill (both
      // stops equal; begin/end/stops inert).
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
      // FLAT shell — gradient retired 2026-06-16. Both stops resolve to one
      // shell tone, so this paints a solid fill (begin/end/stops inert).
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_darkStart, _darkEnd],
      stops: [0.0, 0.3],
    ),
    sectionBackground: LinearGradient(
      // FLAT raised surface — gradient retired 2026-06-16. Solid fill (both
      // stops equal; begin/end/stops inert).
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
