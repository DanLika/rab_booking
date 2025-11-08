import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'villa_jasko_colors.dart';

/// Villa Jasko custom theme for embedded booking widget
class VillaJaskoTheme {
  VillaJaskoTheme._();

  /// Get complete ThemeData for Villa Jasko widget
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme using VillaJaskoColors
      colorScheme: const ColorScheme.light(
        primary: VillaJaskoColors.primary,
        onPrimary: VillaJaskoColors.textOnPrimary,
        primaryContainer: VillaJaskoColors.primaryLight,
        secondary: VillaJaskoColors.accent,
        onSecondary: VillaJaskoColors.textOnAccent,
        secondaryContainer: VillaJaskoColors.accentHover,
        tertiary: VillaJaskoColors.accent,
        error: VillaJaskoColors.error,
        onError: Colors.white,
        surface: VillaJaskoColors.backgroundSurface,
        onSurface: VillaJaskoColors.textPrimary,
        surfaceContainerHighest: VillaJaskoColors.backgroundMain,
        outline: VillaJaskoColors.border,
      ),

      // Background
      scaffoldBackgroundColor: VillaJaskoColors.backgroundMain,

      // Typography - Inter font for clean, modern look
      textTheme: TextTheme(
        // Display styles - Large headings
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: VillaJaskoColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: VillaJaskoColors.textPrimary,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.textPrimary,
        ),

        // Headline styles
        headlineLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.textPrimary,
        ),

        // Title styles
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.textPrimary,
        ),

        // Body styles
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: VillaJaskoColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: VillaJaskoColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: VillaJaskoColors.textTertiary,
        ),

        // Label styles
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.textPrimary,
          letterSpacing: 0.5,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.textSecondary,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: VillaJaskoColors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: VillaJaskoColors.backgroundSurface,
        foregroundColor: VillaJaskoColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        shadowColor: VillaJaskoColors.shadowLight,
        toolbarHeight: AppDimensions.appBarHeight,
      ),

      // Card theme - Modern rounded cards with multi-layer shadows
      cardTheme: CardThemeData(
        color: VillaJaskoColors.backgroundSurface,
        elevation: 0, // Using custom shadows instead
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // 16px - Modern standard
        ),
        margin: const EdgeInsets.all(AppDimensions.spaceS), // 16px
      ),

      // Elevated button theme - Azure blue primary button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VillaJaskoColors.buttonPrimary,
          foregroundColor: VillaJaskoColors.buttonPrimaryText,
          minimumSize: const Size(0, AppDimensions.buttonHeight), // 48px height
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceM, // 24px
            vertical: AppDimensions.spaceS, // 16px
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          // Hover state
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return VillaJaskoColors.buttonPrimaryHover;
            }
            if (states.contains(WidgetState.disabled)) {
              return VillaJaskoColors.buttonDisabled;
            }
            return VillaJaskoColors.buttonPrimary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return VillaJaskoColors.buttonDisabledText;
            }
            return VillaJaskoColors.buttonPrimaryText;
          }),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VillaJaskoColors.buttonSecondaryText,
          minimumSize: const Size(0, AppDimensions.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceM,
            vertical: AppDimensions.spaceS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          side: const BorderSide(
            color: VillaJaskoColors.buttonSecondaryBorder,
            width: 1.5,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VillaJaskoColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceS,
            vertical: 12,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Icon button theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: VillaJaskoColors.textPrimary,
          highlightColor: VillaJaskoColors.primary.withValues(alpha: 0.1),
        ),
      ),

      // Input decoration theme - Clean, modern inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VillaJaskoColors.backgroundSurface,
        constraints: const BoxConstraints(minHeight: AppDimensions.inputHeight), // 48px
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceS,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXS), // 6px
          borderSide: const BorderSide(color: VillaJaskoColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
          borderSide: const BorderSide(color: VillaJaskoColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
          borderSide: const BorderSide(
            color: VillaJaskoColors.borderFocus,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
          borderSide: const BorderSide(color: VillaJaskoColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
          borderSide: const BorderSide(
            color: VillaJaskoColors.error,
            width: 2,
          ),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: VillaJaskoColors.textSecondary,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: VillaJaskoColors.textTertiary,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          color: VillaJaskoColors.error,
        ),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: VillaJaskoColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Dialog theme with modern shadows
      dialogTheme: DialogThemeData(
        backgroundColor: VillaJaskoColors.backgroundSurface,
        elevation: 0, // Using custom shadows
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // 20px
        ),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VillaJaskoColors.textPrimary,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: VillaJaskoColors.primary,
      ),
    );
  }
}
