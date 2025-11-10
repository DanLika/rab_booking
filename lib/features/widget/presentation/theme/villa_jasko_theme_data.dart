import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'villa_jasko_colors.dart';

/// Villa Jasko ThemeData with Azure Blue design system
/// Based on DESIGN_SYSTEM.md - Jadransko more 🌊
class VillaJaskoTheme {
  VillaJaskoTheme._();

  /// Get ThemeData based on brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

  /// Light theme - Azure Blue primary with modern shadows
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: VillaJaskoColors.surfaceWhite,
      primaryColor: VillaJaskoColors.primary,

      colorScheme: const ColorScheme.light(
        primary: VillaJaskoColors.primary, // Azure Blue #0066FF
        secondary: VillaJaskoColors.accent, // Coral Sunset #FF6B6B
        error: VillaJaskoColors.error,
        onSecondary: VillaJaskoColors.surfaceWhite,
        onSurface: VillaJaskoColors.textPrimary,
      ),

      // App bar theme with Azure Blue
      appBarTheme: AppBarTheme(
        backgroundColor: VillaJaskoColors.primary,
        foregroundColor: VillaJaskoColors.surfaceWhite,
        elevation: 0,
        shadowColor: VillaJaskoColors.shadowLight,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.surfaceWhite,
          letterSpacing: -0.3,
        ),
      ),

      // Card theme with modern shadows
      cardTheme: CardThemeData(
        color: VillaJaskoColors.surfaceWhite,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VillaJaskoColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: VillaJaskoColors.borderDefault,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: VillaJaskoColors.borderDefault,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: VillaJaskoColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: VillaJaskoColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VillaJaskoColors.error, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          color: VillaJaskoColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: VillaJaskoColors.textTertiary,
          fontSize: 14,
        ),
      ),

      // Text theme with Inter font
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: VillaJaskoColors.textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: VillaJaskoColors.textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.textPrimary,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.textPrimary,
          letterSpacing: -0.3,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.textPrimary,
          letterSpacing: -0.2,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: VillaJaskoColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: VillaJaskoColors.textPrimary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: VillaJaskoColors.textSecondary,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.textPrimary,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.textSecondary,
          letterSpacing: 0.1,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: VillaJaskoColors.textTertiary,
          letterSpacing: 0.1,
        ),
      ),

      // Elevated button theme with Azure Blue
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VillaJaskoColors.primary,
          foregroundColor: VillaJaskoColors.surfaceWhite,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VillaJaskoColors.primary,
          side: const BorderSide(color: VillaJaskoColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VillaJaskoColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: VillaJaskoColors.textPrimary,
        size: 24,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: VillaJaskoColors.borderDefault,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Dark theme - Full implementation with VillaJaskoDarkColors
  /// Automatically detects parent website dark mode via CSS media queries
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,

      colorScheme: const ColorScheme.dark(
        primary: VillaJaskoDarkColors.primary,
        onPrimary: VillaJaskoDarkColors.textOnPrimary,
        secondary: VillaJaskoDarkColors.accent,
        onSecondary: VillaJaskoDarkColors.textOnAccent,
        surface: VillaJaskoDarkColors.backgroundSurface,
        onSurface: VillaJaskoDarkColors.textPrimary,
        error: VillaJaskoDarkColors.error,
        onError: VillaJaskoDarkColors.textOnPrimary,
      ),

      scaffoldBackgroundColor: VillaJaskoDarkColors.backgroundMain,

      appBarTheme: AppBarTheme(
        backgroundColor: VillaJaskoDarkColors.backgroundSurface,
        foregroundColor: VillaJaskoDarkColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: VillaJaskoDarkColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: VillaJaskoDarkColors.textPrimary),
      ),

      cardTheme: const CardThemeData(
        color: VillaJaskoDarkColors.backgroundSurface,
        elevation: 4,
        shadowColor: VillaJaskoDarkColors.shadowHeavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VillaJaskoDarkColors.primary,
          foregroundColor: VillaJaskoDarkColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VillaJaskoDarkColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VillaJaskoDarkColors.primary,
          side: const BorderSide(color: VillaJaskoDarkColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VillaJaskoDarkColors.backgroundElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: VillaJaskoDarkColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: VillaJaskoDarkColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: VillaJaskoDarkColors.borderFocus,
            width: 2,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: VillaJaskoDarkColors.error),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: VillaJaskoDarkColors.textSecondary,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: VillaJaskoDarkColors.textTertiary,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: VillaJaskoDarkColors.divider,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(color: VillaJaskoDarkColors.textSecondary),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: VillaJaskoDarkColors.textPrimary,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: VillaJaskoDarkColors.textPrimary,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: VillaJaskoDarkColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: VillaJaskoDarkColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: VillaJaskoDarkColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: VillaJaskoDarkColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: VillaJaskoDarkColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: VillaJaskoDarkColors.textPrimary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: VillaJaskoDarkColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: VillaJaskoDarkColors.textPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: VillaJaskoDarkColors.textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: VillaJaskoDarkColors.textTertiary,
        ),
      ),
    );
  }

  /// Helper to convert theme mode string to ThemeMode enum
  static ThemeMode themeModeFromString(String mode) {
    switch (mode.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
