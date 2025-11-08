import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'minimalist_colors.dart';
import '../../../../core/design_tokens/design_tokens.dart';

/// Modern Minimalist Theme for the widget
/// Clean black-white-grey design with subtle accents
class MinimalistTheme {
  /// Light theme
  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        primaryColor: MinimalistColors.buttonPrimary,
        backgroundColor: MinimalistColors.backgroundPrimary,
        textColor: MinimalistColors.textPrimary,
        borderColor: MinimalistColors.borderDefault,
      );

  /// Dark theme
  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        primaryColor: MinimalistColors.backgroundPrimary,
        backgroundColor: MinimalistColors.buttonPrimary,
        textColor: MinimalistColors.textOnDark,
        borderColor: MinimalistColors.borderMedium,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
  }) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      // Primary colors
      primary: primaryColor,
      onPrimary: isDark ? MinimalistColors.textPrimary : MinimalistColors.textOnDark,
      primaryContainer: isDark ? MinimalistColors.buttonPrimaryHover : MinimalistColors.backgroundSecondary,
      onPrimaryContainer: textColor,

      // Secondary colors (grey tones)
      secondary: isDark ? MinimalistColors.borderMedium : MinimalistColors.textSecondary,
      onSecondary: isDark ? MinimalistColors.textPrimary : MinimalistColors.textOnDark,
      secondaryContainer: isDark ? MinimalistColors.borderMedium : MinimalistColors.backgroundTertiary,
      onSecondaryContainer: textColor,

      // Tertiary (accent for calendar states)
      tertiary: MinimalistColors.statusAvailableBorder,
      onTertiary: MinimalistColors.statusAvailableText,
      tertiaryContainer: MinimalistColors.statusAvailableBackground,
      onTertiaryContainer: MinimalistColors.statusAvailableText,

      // Error colors
      error: MinimalistColors.error,
      onError: MinimalistColors.textOnDark,
      errorContainer: MinimalistColors.statusBookedBackground,
      onErrorContainer: MinimalistColors.statusBookedText,

      // Surface colors
      surface: backgroundColor,
      onSurface: textColor,
      surfaceContainerHighest: isDark ? MinimalistColors.buttonPrimaryHover : MinimalistColors.backgroundSecondary,

      // Outline
      outline: borderColor,
      outlineVariant: isDark ? MinimalistColors.borderMedium : MinimalistColors.borderLight,

      // Other
      shadow: MinimalistColors.shadow03,
      scrim: MinimalistColors.black(0.5),
      inverseSurface: isDark ? MinimalistColors.backgroundPrimary : MinimalistColors.buttonPrimary,
      onInverseSurface: isDark ? MinimalistColors.textPrimary : MinimalistColors.textOnDark,
      inversePrimary: isDark ? MinimalistColors.buttonPrimary : MinimalistColors.backgroundPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,

      // Typography using design tokens
      textTheme: _buildTextTheme(textColor),

      // App Bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: TypographyTokens.fontSizeXXL,
          fontWeight: TypographyTokens.semiBold,
          color: textColor,
        ),
      ),

      // Card theme using design tokens
      cardTheme: CardThemeData(
        color: isDark ? MinimalistColors.buttonPrimaryHover : MinimalistColors.backgroundCard,
        elevation: 0,
        shadowColor: MinimalistColors.shadow02,
        shape: RoundedRectangleBorder(
          borderRadius: BorderTokens.card,
          side: BorderSide(
            color: borderColor,
            width: BorderTokens.widthThin,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Button themes using design tokens
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MinimalistColors.buttonPrimary,
          foregroundColor: MinimalistColors.buttonPrimaryText,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: SpacingTokens.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderTokens.button,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: TypographyTokens.fontSizeL,
            fontWeight: TypographyTokens.semiBold,
            letterSpacing: TypographyTokens.letterSpacingWide,
          ),
        ).copyWith(
          // Hover effect
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return MinimalistColors.white(0.1);
            }
            if (states.contains(WidgetState.pressed)) {
              return MinimalistColors.white(0.2);
            }
            return null;
          }),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: MinimalistColors.buttonSecondary,
          foregroundColor: MinimalistColors.buttonSecondaryText,
          side: const BorderSide(
            color: MinimalistColors.buttonSecondaryBorder,
            width: BorderTokens.widthMedium,
          ),
          padding: SpacingTokens.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderTokens.button,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: TypographyTokens.fontSizeL,
            fontWeight: TypographyTokens.semiBold,
            letterSpacing: TypographyTokens.letterSpacingWide,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textColor,
          padding: SpacingTokens.buttonPadding,
          textStyle: GoogleFonts.inter(
            fontSize: TypographyTokens.fontSizeL,
            fontWeight: TypographyTokens.medium,
          ),
        ),
      ),

      // Input decoration theme using design tokens
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? MinimalistColors.buttonPrimaryHover : MinimalistColors.backgroundSecondary,
        contentPadding: SpacingTokens.allM,
        border: OutlineInputBorder(
          borderRadius: BorderTokens.input,
          borderSide: BorderSide(
            color: borderColor,
            width: BorderTokens.widthThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderTokens.input,
          borderSide: BorderSide(
            color: borderColor,
            width: BorderTokens.widthThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderTokens.input,
          borderSide: BorderSide(
            color: primaryColor,
            width: BorderTokens.widthMedium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderTokens.input,
          borderSide: const BorderSide(
            color: MinimalistColors.error,
            width: BorderTokens.widthThin,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderTokens.input,
          borderSide: const BorderSide(
            color: MinimalistColors.error,
            width: BorderTokens.widthMedium,
          ),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: TypographyTokens.fontSizeM,
          color: MinimalistColors.textSecondary,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: TypographyTokens.fontSizeM,
          color: MinimalistColors.textTertiary,
        ),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: BorderTokens.widthThin,
        space: SpacingTokens.m,
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: textColor,
        size: 24,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      // Display styles
      displayLarge: GoogleFonts.inter(
        fontSize: TypographyTokens.fontSizeXXXL,
        fontWeight: TypographyTokens.bold,
        height: TypographyTokens.lineHeightTight,
        letterSpacing: TypographyTokens.letterSpacingTight,
        color: textColor,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: TypographyTokens.fontSizeXXL,
        fontWeight: TypographyTokens.bold,
        height: TypographyTokens.lineHeightTight,
        color: textColor,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: TypographyTokens.fontSizeXL,
        fontWeight: TypographyTokens.semiBold,
        height: TypographyTokens.lineHeightNormal,
        color: textColor,
      ),

      // Headline styles
      headlineLarge: GoogleFonts.inter(
        fontSize: TypographyTokens.fontSizeXXL,
        fontWeight: TypographyTokens.semiBold,
        height: TypographyTokens.lineHeightNormal,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: TypographyTokens.fontSizeXL,
        fontWeight: TypographyTokens.semiBold,
        height: TypographyTokens.lineHeightNormal,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: TypographyTokens.fontSizeL,
        fontWeight: TypographyTokens.semiBold,
        height: TypographyTokens.lineHeightNormal,
        color: textColor,
      ),

      // Title styles
      titleLarge: GoogleFonts.inter(
        fontSize: TypographyTokens.fontSizeXL,
        fontWeight: TypographyTokens.medium,
        height: TypographyTokens.lineHeightNormal,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: TypographyTokens.fontSizeL,
        fontWeight: TypographyTokens.medium,
        height: TypographyTokens.lineHeightNormal,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: TypographyTokens.fontSizeM,
        fontWeight: TypographyTokens.medium,
        height: TypographyTokens.lineHeightNormal,
        color: textColor,
      ),

      // Body styles
      bodyLarge: GoogleFonts.inter(
        fontSize: TypographyTokens.fontSizeL,
        fontWeight: TypographyTokens.regular,
        height: TypographyTokens.lineHeightNormal,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: TypographyTokens.fontSizeM,
        fontWeight: TypographyTokens.regular,
        height: TypographyTokens.lineHeightNormal,
        color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: TypographyTokens.fontSizeS,
        fontWeight: TypographyTokens.regular,
        height: TypographyTokens.lineHeightNormal,
        color: MinimalistColors.textSecondary,
      ),

      // Label styles
      labelLarge: GoogleFonts.inter(
        fontSize: TypographyTokens.fontSizeM,
        fontWeight: TypographyTokens.medium,
        letterSpacing: TypographyTokens.letterSpacingWide,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: TypographyTokens.fontSizeS,
        fontWeight: TypographyTokens.medium,
        letterSpacing: TypographyTokens.letterSpacingWide,
        color: textColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: TypographyTokens.fontSizeXS,
        fontWeight: TypographyTokens.regular,
        letterSpacing: TypographyTokens.letterSpacingNormal,
        color: MinimalistColors.textTertiary,
      ),
    );
  }

  /// Get calendar date color based on status
  static Color getCalendarDateBackground(String status, {required bool isDark}) {
    switch (status.toLowerCase()) {
      case 'available':
        return MinimalistColors.statusAvailableBackground;
      case 'booked':
        return MinimalistColors.statusBookedBackground;
      case 'pending':
        return MinimalistColors.statusPendingBackground;
      default:
        return isDark ? MinimalistColors.buttonPrimaryHover : MinimalistColors.backgroundPrimary;
    }
  }

  static Color getCalendarDateBorder(String status, {required bool isDark, bool isSelected = false}) {
    if (isSelected) {
      return MinimalistColors.borderBlack;
    }

    switch (status.toLowerCase()) {
      case 'available':
        return MinimalistColors.statusAvailableBorder;
      case 'booked':
        return MinimalistColors.statusBookedBorder;
      case 'pending':
        return MinimalistColors.statusPendingBorder;
      default:
        return isDark ? MinimalistColors.borderMedium : MinimalistColors.borderDefault;
    }
  }

  static Color getCalendarDateText(String status, {required bool isDark}) {
    switch (status.toLowerCase()) {
      case 'available':
        return MinimalistColors.statusAvailableText;
      case 'booked':
        return MinimalistColors.statusBookedText;
      case 'pending':
        return MinimalistColors.statusPendingText;
      default:
        return isDark ? MinimalistColors.textOnDark : MinimalistColors.textPrimary;
    }
  }
}
