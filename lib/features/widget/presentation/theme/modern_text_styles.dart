import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'villa_jasko_colors.dart';

/// Modern text styles using Inter font with optimized sizes
/// Based on 2024-2025 design trends
class ModernTextStyles {
  ModernTextStyles._(); // Private constructor

  // ============================================================================
  // DISPLAY STYLES - Hero sections, large headings
  // ============================================================================

  /// Display Large - 32px, Bold (700) - Hero headings
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: VillaJaskoColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  /// Display Medium - 28px, Bold (700) - Section headings
  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: VillaJaskoColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );

  /// Display Small - 24px, Semibold (600) - Card headings
  static TextStyle displaySmall = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: VillaJaskoColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  // ============================================================================
  // HEADLINE STYLES - Page titles, subsection headings
  // ============================================================================

  /// Headline Large - 22px, Semibold (600)
  static TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: VillaJaskoColors.textPrimary,
    letterSpacing: -0.15,
    height: 1.35,
  );

  /// Headline Medium - 20px, Semibold (600)
  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: VillaJaskoColors.textPrimary,
    height: 1.4,
  );

  /// Headline Small - 18px, Semibold (600)
  static TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: VillaJaskoColors.textPrimary,
    letterSpacing: -0.1,
    height: 1.4,
  );

  // ============================================================================
  // TITLE STYLES - Component titles, labels
  // ============================================================================

  /// Title Large - 18px, Semibold (600)
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: VillaJaskoColors.textPrimary,
    height: 1.4,
  );

  /// Title Medium - 16px, Semibold (600) - Card titles
  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: VillaJaskoColors.textPrimary,
    height: 1.5,
  );

  /// Title Small - 14px, Semibold (600) - Small component titles
  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: VillaJaskoColors.textPrimary,
    height: 1.5,
  );

  // ============================================================================
  // BODY STYLES - Main content, descriptions
  // ============================================================================

  /// Body Large - 16px, Regular (400) - Main content
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: VillaJaskoColors.textPrimary,
    height: 1.5,
  );

  /// Body Medium - 14px, Regular (400) - Secondary content
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: VillaJaskoColors.textSecondary,
    height: 1.5,
  );

  /// Body Small - 12px, Regular (400) - Captions, notes
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: VillaJaskoColors.textTertiary,
    height: 1.5,
  );

  // ============================================================================
  // LABEL STYLES - Buttons, badges, tags
  // ============================================================================

  /// Label Large - 16px, Semibold (600) - Large buttons
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: VillaJaskoColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.25,
  );

  /// Label Medium - 14px, Semibold (600) - Standard buttons
  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: VillaJaskoColors.textSecondary,
    letterSpacing: 0.5,
    height: 1.25,
  );

  /// Label Small - 12px, Semibold (600) - Small buttons, badges
  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: VillaJaskoColors.textTertiary,
    letterSpacing: 0.5,
    height: 1.25,
  );

  // ============================================================================
  // SPECIAL STYLES - Calendar, prices, etc.
  // ============================================================================

  /// Calendar Day Number - 16px, Medium (500)
  static TextStyle calendarDay = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: VillaJaskoColors.textPrimary,
    height: 1.0,
  );

  /// Calendar Day Number (Selected) - 16px, Semibold (600), White
  static TextStyle calendarDaySelected = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: VillaJaskoColors.textOnPrimary,
    height: 1.0,
  );

  /// Calendar Month Name - 18px, Semibold (600)
  static TextStyle calendarMonth = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: VillaJaskoColors.textPrimary,
    height: 1.2,
  );

  /// Price Large - 28px, Bold (700) - Main price display
  static TextStyle priceLarge = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: VillaJaskoColors.primary,
    height: 1.2,
  );

  /// Price Medium - 20px, Semibold (600) - Secondary prices
  static TextStyle priceMedium = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: VillaJaskoColors.primary,
    height: 1.2,
  );

  /// Price Small - 16px, Medium (500) - Price details
  static TextStyle priceSmall = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: VillaJaskoColors.textSecondary,
    height: 1.2,
  );

  /// Button Text Large - 16px, Semibold (600), Uppercase - Primary CTAs
  static TextStyle buttonLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: VillaJaskoColors.textOnPrimary,
    letterSpacing: 0.8,
    height: 1.0,
  );

  /// Button Text Medium - 14px, Semibold (600) - Secondary buttons
  static TextStyle buttonMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: VillaJaskoColors.primary,
    letterSpacing: 0.5,
    height: 1.0,
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get style with custom color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Get style with custom size
  static TextStyle withSize(TextStyle style, double fontSize) {
    return style.copyWith(fontSize: fontSize);
  }

  /// Get style with custom weight
  static TextStyle withWeight(TextStyle style, FontWeight fontWeight) {
    return style.copyWith(fontWeight: fontWeight);
  }

  /// Get uppercase style (for buttons, labels)
  static TextStyle uppercase(TextStyle style) {
    return style.copyWith(letterSpacing: 0.8);
  }

  /// Get style for error state
  static TextStyle error(TextStyle style) {
    return style.copyWith(color: VillaJaskoColors.error);
  }

  /// Get style for success state
  static TextStyle success(TextStyle style) {
    return style.copyWith(color: VillaJaskoColors.success);
  }

  /// Get style for disabled state
  static TextStyle disabled(TextStyle style) {
    return style.copyWith(color: VillaJaskoColors.textDisabled);
  }
}
