import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application typography configuration
/// Using Playfair Display for headings and Inter for body text
class AppTypography {
  AppTypography._(); // Private constructor

  // ============================================================================
  // FONT FAMILIES
  // ============================================================================

  /// Heading font - Playfair Display (elegant serif for titles)
  static String get headingFont => GoogleFonts.playfairDisplay().fontFamily!;

  /// Body font - Inter (clean sans-serif for readability)
  static String get bodyFont => GoogleFonts.inter().fontFamily!;

  // ============================================================================
  // TEXT THEME
  // ============================================================================

  /// Complete text theme for the app
  static TextTheme get textTheme {
    return TextTheme(
      // Display styles (largest text, usually for hero sections)
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.16,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.22,
      ),

      // Headline styles (section headers, card titles)
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.29,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
      ),

      // Title styles (list items, dialog titles)
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.27,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      ),

      // Body styles (main content)
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      ),

      // Label styles (buttons, tabs, form labels)
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.45,
      ),
    );
  }

  // ============================================================================
  // CUSTOM TEXT STYLES
  // ============================================================================

  /// Hero title style (for landing page)
  static TextStyle get heroTitle => GoogleFonts.playfairDisplay(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.1,
      );

  /// Hero subtitle style
  static TextStyle get heroSubtitle => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.6,
      );

  /// Property card title
  static TextStyle get propertyCardTitle => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
      );

  /// Property card subtitle (location)
  static TextStyle get propertyCardSubtitle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      );

  /// Price text style
  static TextStyle get priceText => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.33,
      );

  /// Price label style (per night, total, etc.)
  static TextStyle get priceLabel => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      );

  /// Button text style
  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.25,
      );

  /// Caption text (image captions, footnotes)
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      );

  /// Overline text (labels, categories)
  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        height: 1.6,
      ).copyWith(
        textBaseline: TextBaseline.alphabetic,
      );

  // ============================================================================
  // RESPONSIVE SCALING
  // ============================================================================

  /// Scale text theme based on screen width
  static TextTheme responsiveTextTheme(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Mobile (< 600)
    if (width < 600) {
      return textTheme.apply(
        fontSizeFactor: 0.9,
      );
    }

    // Tablet (600-1024)
    if (width < 1024) {
      return textTheme.apply(
        fontSizeFactor: 1.0,
      );
    }

    // Desktop (>= 1024)
    return textTheme.apply(
      fontSizeFactor: 1.1,
    );
  }

  /// Get responsive hero title size
  static double getHeroTitleSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 36; // Mobile
    if (width < 1024) return 48; // Tablet
    return 56; // Desktop
  }

  /// Get responsive property card title size
  static double getPropertyTitleSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 16; // Mobile
    if (width < 1024) return 18; // Tablet
    return 20; // Desktop
  }

  // ============================================================================
  // TEXT STYLES WITH COLOR
  // ============================================================================

  /// Get text style with specific color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Get text style with opacity
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(
      color: style.color?.withValues(alpha: opacity),
    );
  }

  /// Get bold variant of text style
  static TextStyle bold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w700);
  }

  /// Get semibold variant
  static TextStyle semibold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w600);
  }

  /// Get medium variant
  static TextStyle medium(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w500);
  }

  /// Get italic variant
  static TextStyle italic(TextStyle style) {
    return style.copyWith(fontStyle: FontStyle.italic);
  }

  /// Get underlined variant
  static TextStyle underlined(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.underline);
  }
}
