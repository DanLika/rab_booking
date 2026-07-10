import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'minimalist_colors.dart';
import '../../../../core/design/tokens.dart';

/// Modern Minimalist Theme for the widget
/// Clean black-white-grey design with subtle accents
/// Supports universal embedding with shadow levels and transparent mode
class MinimalistTheme {
  /// Light theme
  static ThemeData get light => _buildTheme(
    brightness: Brightness.light,
    primaryColor: MinimalistColors.buttonPrimary,
    backgroundColor: MinimalistColors.backgroundPrimary,
    textColor: MinimalistColors.textPrimary,
    borderColor: MinimalistColors.borderDefault,
  );

  /// Dark theme (optimized for WCAG AAA and OLED displays)
  static ThemeData get dark => _buildTheme(
    brightness: Brightness.dark,
    primaryColor: MinimalistColorsDark.buttonPrimary,
    backgroundColor: MinimalistColorsDark.backgroundDark,
    textColor: MinimalistColorsDark.textPrimary,
    borderColor: MinimalistColorsDark.borderDefault,
  );

  /// Universal light theme with shadow level and transparent mode
  ///
  /// [shadowLevel]: 0-5 (0=flat, 2=default, 5=maximum depth)
  /// [transparentMode]: Blend seamlessly with parent site
  /// [accentColor]: Override default black with custom color
  static ThemeData lightWithOptions({
    int shadowLevel = 2,
    bool transparentMode = false,
    Color? accentColor,
  }) {
    return _buildTheme(
      brightness: Brightness.light,
      primaryColor: accentColor ?? MinimalistColors.buttonPrimary,
      backgroundColor: transparentMode
          ? Colors.transparent
          : MinimalistColors.backgroundPrimary,
      textColor: MinimalistColors.textPrimary,
      borderColor: MinimalistColors.borderDefault,
      shadowLevel: shadowLevel,
      transparentMode: transparentMode,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
    int shadowLevel = 2,
    bool transparentMode = false,
  }) {
    final bool isDark = brightness == Brightness.dark;
    final double elevation = shadowLevel > 0 ? (shadowLevel * 0.5) : 0;

    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      // Primary colors
      primary: primaryColor,
      onPrimary: isDark
          ? MinimalistColorsDark.buttonPrimaryText
          : MinimalistColors.textOnDark,
      primaryContainer: isDark
          ? MinimalistColorsDark.backgroundElevated2
          : MinimalistColors.backgroundSecondary,
      onPrimaryContainer: textColor,

      // Secondary colors (grey tones)
      secondary: isDark
          ? MinimalistColorsDark.borderMedium
          : MinimalistColors.textSecondary,
      onSecondary: isDark
          ? MinimalistColorsDark.textPrimary
          : MinimalistColors.textOnDark,
      secondaryContainer: isDark
          ? MinimalistColorsDark.backgroundElevated1
          : MinimalistColors.backgroundTertiary,
      onSecondaryContainer: textColor,

      // Tertiary (accent for calendar states)
      tertiary: isDark
          ? MinimalistColorsDark.statusAvailableBorder
          : MinimalistColors.statusAvailableBorder,
      onTertiary: isDark
          ? MinimalistColorsDark.statusAvailableText
          : MinimalistColors.statusAvailableText,
      tertiaryContainer: isDark
          ? MinimalistColorsDark.statusAvailableBackground
          : MinimalistColors.statusAvailableBackground,
      onTertiaryContainer: isDark
          ? MinimalistColorsDark.statusAvailableText
          : MinimalistColors.statusAvailableText,

      // Error colors
      error: isDark ? MinimalistColorsDark.error : MinimalistColors.error,
      onError: isDark
          ? MinimalistColorsDark.textPrimary
          : MinimalistColors.textOnDark,
      errorContainer: isDark
          ? MinimalistColorsDark.statusBookedBackground
          : MinimalistColors.statusBookedBackground,
      onErrorContainer: isDark
          ? MinimalistColorsDark.statusBookedText
          : MinimalistColors.statusBookedText,

      // Surface colors
      surface: backgroundColor,
      onSurface: textColor,
      surfaceContainerHighest: isDark
          ? MinimalistColorsDark.backgroundElevated1
          : MinimalistColors.backgroundSecondary,

      // Outline
      outline: borderColor,
      outlineVariant: isDark
          ? MinimalistColorsDark.borderSubtle
          : MinimalistColors.borderLight,

      // Other
      shadow: isDark
          ? MinimalistColorsDark.shadow03
          : MinimalistColors.shadow03,
      scrim: isDark
          ? MinimalistColorsDark.black(0.5)
          : MinimalistColors.black(0.5),
      inverseSurface: isDark
          ? MinimalistColorsDark.buttonPrimary
          : MinimalistColors.buttonPrimary,
      onInverseSurface: isDark
          ? MinimalistColorsDark.buttonPrimaryText
          : MinimalistColors.textOnDark,
      inversePrimary: isDark
          ? MinimalistColorsDark.backgroundDark
          : MinimalistColors.backgroundPrimary,
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
          fontSize: BBTypeBridges.fontSizeXXL,
          fontWeight: BBTypeBridges.weightSemiBold,
          color: textColor,
        ),
      ),

      // Card theme using design tokens
      cardTheme: CardThemeData(
        color: isDark
            ? MinimalistColorsDark.backgroundElevated1
            : MinimalistColors.backgroundCard,
        elevation: elevation,
        shadowColor: isDark
            ? MinimalistColorsDark.shadow02
            : MinimalistColors.shadow02,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(BBRadiusBridges.medium),
          ),
          side: shadowLevel == 0
              ? BorderSide(color: borderColor)
              : BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),

      // Button themes using design tokens
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? MinimalistColorsDark.buttonPrimary
                  : MinimalistColors.buttonPrimary,
              foregroundColor: isDark
                  ? MinimalistColorsDark.buttonPrimaryText
                  : MinimalistColors.buttonPrimaryText,
              elevation: elevation,
              shadowColor: shadowLevel > 0
                  ? (isDark
                        ? MinimalistColorsDark.shadow02
                        : MinimalistColors.shadow02)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(
                horizontal: BBSpace.md,
                vertical: 14,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(BBRadiusBridges.medium),
                ),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: BBTypeBridges.fontSizeL,
                fontWeight: BBTypeBridges.weightSemiBold,
                letterSpacing: BBTypeBridges.letterSpacingWide,
              ),
            ).copyWith(
              // Hover effect
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return isDark
                      ? MinimalistColorsDark.overlayHover
                      : MinimalistColors.white(0.1);
                }
                if (states.contains(WidgetState.pressed)) {
                  return isDark
                      ? MinimalistColorsDark.overlayPressed
                      : MinimalistColors.white(0.2);
                }
                return null;
              }),
            ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark
              ? MinimalistColorsDark.buttonSecondary
              : MinimalistColors.buttonSecondary,
          foregroundColor: isDark
              ? MinimalistColorsDark.buttonSecondaryText
              : MinimalistColors.buttonSecondaryText,
          side: BorderSide(
            color: isDark
                ? MinimalistColorsDark.buttonSecondaryBorder
                : MinimalistColors.buttonSecondaryBorder,
            width: BBBorderWidth.medium,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: BBSpace.md,
            vertical: 14,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(BBRadiusBridges.medium),
            ),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: BBTypeBridges.fontSizeL,
            fontWeight: BBTypeBridges.weightSemiBold,
            letterSpacing: BBTypeBridges.letterSpacingWide,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(
            horizontal: BBSpace.md,
            vertical: 14,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: BBTypeBridges.fontSizeL,
            fontWeight: BBTypeBridges.weightMedium,
          ),
        ),
      ),

      // Input decoration theme using design tokens
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? MinimalistColorsDark.backgroundElevated1
            : MinimalistColors.backgroundSecondary,
        contentPadding: const EdgeInsets.all(BBSpace.sm),
        border: OutlineInputBorder(
          borderRadius: BBRadius.smAll,
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BBRadius.smAll,
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BBRadius.smAll,
          borderSide: BorderSide(
            color: isDark ? MinimalistColorsDark.borderStrong : primaryColor,
            width: BBBorderWidth.medium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BBRadius.smAll,
          borderSide: BorderSide(
            color: isDark ? MinimalistColorsDark.error : MinimalistColors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BBRadius.smAll,
          borderSide: BorderSide(
            color: isDark ? MinimalistColorsDark.error : MinimalistColors.error,
            width: BBBorderWidth.medium,
          ),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: BBTypeBridges.fontSizeM,
          color: isDark
              ? MinimalistColorsDark.textSecondary
              : MinimalistColors.textSecondary,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: BBTypeBridges.fontSizeM,
          color: isDark
              ? MinimalistColorsDark.textTertiary
              : MinimalistColors.textTertiary,
        ),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: BBBorderWidth.thin,
        space: BBSpace.sm,
      ),

      // Icon theme
      iconTheme: IconThemeData(color: textColor, size: 24),
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      // Display styles
      displayLarge: GoogleFonts.inter(
        fontSize: BBTypeBridges.fontSizeXXXL,
        fontWeight: BBTypeBridges.weightBold,
        height: BBTypeBridges.lineHeightTight,
        letterSpacing: BBTypeBridges.letterSpacingTight,
        color: textColor,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: BBTypeBridges.fontSizeXXL,
        fontWeight: BBTypeBridges.weightBold,
        height: BBTypeBridges.lineHeightTight,
        color: textColor,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: BBTypeBridges.fontSizeXL,
        fontWeight: BBTypeBridges.weightSemiBold,
        height: BBTypeBridges.lineHeightNormal,
        color: textColor,
      ),

      // Headline styles
      headlineLarge: GoogleFonts.inter(
        fontSize: BBTypeBridges.fontSizeXXL,
        fontWeight: BBTypeBridges.weightSemiBold,
        height: BBTypeBridges.lineHeightNormal,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: BBTypeBridges.fontSizeXL,
        fontWeight: BBTypeBridges.weightSemiBold,
        height: BBTypeBridges.lineHeightNormal,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: BBTypeBridges.fontSizeL,
        fontWeight: BBTypeBridges.weightSemiBold,
        height: BBTypeBridges.lineHeightNormal,
        color: textColor,
      ),

      // Title styles
      titleLarge: GoogleFonts.inter(
        fontSize: BBTypeBridges.fontSizeXL,
        fontWeight: BBTypeBridges.weightMedium,
        height: BBTypeBridges.lineHeightNormal,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: BBTypeBridges.fontSizeL,
        fontWeight: BBTypeBridges.weightMedium,
        height: BBTypeBridges.lineHeightNormal,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: BBTypeBridges.fontSizeM,
        fontWeight: BBTypeBridges.weightMedium,
        height: BBTypeBridges.lineHeightNormal,
        color: textColor,
      ),

      // Body styles
      bodyLarge: GoogleFonts.inter(
        fontSize: BBTypeBridges.fontSizeL,
        fontWeight: BBTypeBridges.weightRegular,
        height: BBTypeBridges.lineHeightNormal,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: BBTypeBridges.fontSizeM,
        fontWeight: BBTypeBridges.weightRegular,
        height: BBTypeBridges.lineHeightNormal,
        color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: BBTypeBridges.fontSizeS,
        fontWeight: BBTypeBridges.weightRegular,
        height: BBTypeBridges.lineHeightNormal,
        color: MinimalistColors.textSecondary,
      ),

      // Label styles
      labelLarge: GoogleFonts.inter(
        fontSize: BBTypeBridges.fontSizeM,
        fontWeight: BBTypeBridges.weightMedium,
        letterSpacing: BBTypeBridges.letterSpacingWide,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: BBTypeBridges.fontSizeS,
        fontWeight: BBTypeBridges.weightMedium,
        letterSpacing: BBTypeBridges.letterSpacingWide,
        color: textColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: BBTypeBridges.fontSizeXS,
        fontWeight: BBTypeBridges.weightRegular,
        letterSpacing: BBTypeBridges.letterSpacingNormal,
        color: MinimalistColors.textTertiary,
      ),
    );
  }

  /// Get calendar date color based on status
  static Color getCalendarDateBackground(
    String status, {
    required bool isDark,
  }) {
    switch (status.toLowerCase()) {
      case 'available':
        return isDark
            ? MinimalistColorsDark.statusAvailableBackground
            : MinimalistColors.statusAvailableBackground;
      case 'booked':
        return isDark
            ? MinimalistColorsDark.statusBookedBackground
            : MinimalistColors.statusBookedBackground;
      case 'pending':
        return isDark
            ? MinimalistColorsDark.statusPendingBackground
            : MinimalistColors.statusPendingBackground;
      default:
        return isDark
            ? MinimalistColorsDark.backgroundDark
            : MinimalistColors.backgroundPrimary;
    }
  }

  static Color getCalendarDateBorder(
    String status, {
    required bool isDark,
    bool isSelected = false,
  }) {
    if (isSelected) {
      return isDark
          ? MinimalistColorsDark.borderEmphasis
          : MinimalistColors.borderBlack;
    }

    switch (status.toLowerCase()) {
      case 'available':
        return isDark
            ? MinimalistColorsDark.statusAvailableBorder
            : MinimalistColors.statusAvailableBorder;
      case 'booked':
        return isDark
            ? MinimalistColorsDark.statusBookedBorder
            : MinimalistColors.statusBookedBorder;
      case 'pending':
        return isDark
            ? MinimalistColorsDark.statusPendingBorder
            : MinimalistColors.statusPendingBorder;
      default:
        return isDark
            ? MinimalistColorsDark.borderDefault
            : MinimalistColors.borderDefault;
    }
  }

  static Color getCalendarDateText(String status, {required bool isDark}) {
    switch (status.toLowerCase()) {
      case 'available':
        return isDark
            ? MinimalistColorsDark.statusAvailableText
            : MinimalistColors.statusAvailableText;
      case 'booked':
        return isDark
            ? MinimalistColorsDark.statusBookedText
            : MinimalistColors.statusBookedText;
      case 'pending':
        return isDark
            ? MinimalistColorsDark.statusPendingText
            : MinimalistColors.statusPendingText;
      default:
        return isDark
            ? MinimalistColorsDark.textPrimary
            : MinimalistColors.textPrimary;
    }
  }
}
