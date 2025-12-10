import 'package:flutter/material.dart';
import '../../../../core/design_tokens/color_tokens.dart';

/// Minimalist Color Palette
/// Black, White, and Grey tones for clean, modern aesthetic
/// Only green/red/amber for calendar status indicators
class MinimalistColors {
  // ==================== BASE COLORS ====================

  /// Pure white - primary background
  static const Color backgroundPrimary = Color(0xFFFFFFFF);

  /// Off-white - secondary background for subtle contrast
  static const Color backgroundSecondary = Color(0xFFFAFAFA);

  /// Light grey - tertiary background for headers, legends, banners
  static const Color backgroundTertiary = Color(0xFFF5F5F5);

  /// White with shadow - elevated cards
  static const Color backgroundCard = Color(0xFFFFFFFF);

  /// Day header background - light grey (same as tertiary for consistency)
  static const Color backgroundDayHeader = Color(0xFFF5F5F5); // #f5f5f5

  // ==================== TEXT COLORS ====================

  /// Pure black - primary text, headings, emphasis
  static const Color textPrimary = Color(0xFF000000);

  /// Medium grey - secondary text, labels
  static const Color textSecondary = Color(0xFF666666);

  /// Light grey - tertiary text, hints, placeholders
  static const Color textTertiary = Color(0xFF999999);

  /// Very light grey - disabled text
  static const Color textDisabled = Color(0xFFCCCCCC);

  /// White text - for dark backgrounds
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ==================== BORDER COLORS ====================

  /// Almost white - very subtle borders
  static const Color borderLight = Color(0xFFF0F0F0);

  /// Light grey - default borders
  static const Color borderDefault = Color(0xFFE0E0E0);

  /// Medium grey - hover borders (darker for better visibility on light backgrounds)
  static const Color borderMedium = Color(0xFF888888);

  /// Dark grey - active/strong borders
  static const Color borderStrong = Color(0xFF666666);

  /// Pure black - emphasis borders (selected, active)
  static const Color borderBlack = Color(0xFF000000);

  // ==================== CALENDAR STATUS COLORS ====================
  // Light mint/pink color scheme for modern booking widget (like reference image)

  /// Available date - mint green background
  static const Color statusAvailableBackground = Color(0xFF83e6bf); // #83e6bf

  /// Available date - mint green border
  static const Color statusAvailableBorder = Color(0xFF83e6bf); // #83e6bf

  /// Available date - teal text
  static const Color statusAvailableText = Color(0xFF83e6bf); // #83e6bf

  /// Booked date - pink/red background
  static const Color statusBookedBackground = Color(0xFFfba9aa); // #fba9aa

  /// Booked date - red border
  static const Color statusBookedBorder = Color(0xFFef4444); // #ef4444

  /// Booked date - red text
  static const Color statusBookedText = Color(0xFFef4444); // #ef4444

  /// Past booked date - light pink background
  static const Color statusPastReservationBackground = Color(0xFFebdae2); // #ebdae2

  /// Past booked date - border
  static const Color statusPastReservationBorder = Color(0xFFebdae2); // #ebdae2

  /// Pending date - amber background (vibrant)
  static const Color statusPendingBackground = Color(0xFFFDE68A); // Amber 200

  /// Pending date - amber border (strong)
  static const Color statusPendingBorder = Color(0xFFF59E0B); // Amber 500

  /// Pending date - amber text
  static const Color statusPendingText = Color(0xFFD97706); // Amber 600

  /// Blocked date - distinct grey background
  static const Color statusBlockedBackground = Color(0xFFD1D5DB); // Grey 300

  /// Blocked date - border
  static const Color statusBlockedBorder = Color(0xFF9CA3AF); // Grey 400

  // ==================== SHADOW COLORS ====================
  // Black-based shadows for subtle depth

  /// Lightest shadow - 4% opacity
  static const Color shadow01 = Color(0x0A000000);

  /// Light shadow - 8% opacity
  static const Color shadow02 = Color(0x14000000);

  /// Medium shadow - 12% opacity
  static const Color shadow03 = Color(0x1F000000);

  /// Strong shadow - 16% opacity
  static const Color shadow04 = Color(0x29000000);

  // ==================== SEMANTIC COLORS ====================

  /// Success state (matches confirmed badge green)
  static const Color success = Color(0xFF66BB6A); // #66BB6A

  /// Error state (mirrors booked pink)
  static const Color error = Color(0xFFEC4899);

  /// Warning state (mirrors pending amber)
  static const Color warning = Color(0xFFF59E0B);

  /// Info state (medium grey)
  static const Color info = Color(0xFF666666);

  // ==================== BUTTON COLORS ====================

  /// Primary button background (black)
  static const Color buttonPrimary = Color(0xFF000000);

  /// Primary button hover (dark grey)
  static const Color buttonPrimaryHover = Color(0xFF333333);

  /// Primary button pressed (medium grey)
  static const Color buttonPrimaryPressed = Color(0xFF666666);

  /// Primary button text (white)
  static const Color buttonPrimaryText = Color(0xFFFFFFFF);

  /// Secondary button background (white)
  static const Color buttonSecondary = Color(0xFFFFFFFF);

  /// Secondary button border (black)
  static const Color buttonSecondaryBorder = Color(0xFF000000);

  /// Secondary button text (black)
  static const Color buttonSecondaryText = Color(0xFF000000);

  // ==================== HELPER METHODS ====================

  /// Get shadow with custom opacity
  static Color shadow(double opacity) {
    return Color.fromRGBO(0, 0, 0, opacity);
  }

  /// Get grey shade by percentage (0.0 = black, 1.0 = white)
  static Color grey(double brightness) {
    final value = (brightness * 255).round().clamp(0, 255);
    return Color.fromRGBO(value, value, value, 1.0);
  }

  /// Get white with custom opacity (for overlays)
  static Color white(double opacity) {
    return Color.fromRGBO(255, 255, 255, opacity);
  }

  /// Get black with custom opacity (for overlays)
  static Color black(double opacity) {
    return Color.fromRGBO(0, 0, 0, opacity);
  }
}

/// Dark Theme Colors - Inverted from light theme
class MinimalistColorsDark {
  // ==================== BASE COLORS ====================

  /// Pure black - primary background
  static const Color backgroundPrimary = Color(0xFF000000);

  /// Off-black - secondary background for subtle contrast
  static const Color backgroundSecondary = Color(0xFF0A0A0A);

  /// Dark grey - tertiary background for headers, legends, banners
  static const Color backgroundTertiary = Color(0xFF1f2937); // #1f2937

  /// Black with shadow - elevated cards
  static const Color backgroundCard = Color(0xFF000000);

  // ==================== TEXT COLORS ====================

  /// Pure white - primary text, headings, emphasis
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Light grey - secondary text, labels
  static const Color textSecondary = Color(0xFF999999);

  /// Medium grey - tertiary text, hints, placeholders
  static const Color textTertiary = Color(0xFF666666);

  /// Dark grey - disabled text
  static const Color textDisabled = Color(0xFF333333);

  /// Black text - for light backgrounds
  static const Color textOnDark = Color(0xFF000000);

  // ==================== BORDER COLORS ====================

  /// Dark grey - very subtle borders
  static const Color borderLight = Color(0xFF333333);

  /// Light grey - default borders (bright for visibility on black)
  static const Color borderDefault = Color(0xFFCCCCCC);

  /// Lighter grey - hover borders
  static const Color borderMedium = Color(0xFFDDDDDD);

  /// Almost white - active/strong borders
  static const Color borderStrong = Color(0xFFEEEEEE);

  /// Pure white - emphasis borders (selected, active)
  static const Color borderBlack = Color(0xFFFFFFFF);

  // ==================== CALENDAR STATUS COLORS ====================
  // Brighter versions for dark mode (more visible against dark background)

  /// Available date - teal background
  static const Color statusAvailableBackground = Color(0xFF15b8a6); // #15b8a6

  /// Available date - teal border
  static const Color statusAvailableBorder = Color(0xFF15b8a6); // #15b8a6

  /// Available date - teal text
  static const Color statusAvailableText = Color(0xFF15b8a6); // #15b8a6

  /// Booked date - red background
  static const Color statusBookedBackground = Color(0xFFef4444); // #ef4444

  /// Booked date - red border
  static const Color statusBookedBorder = Color(0xFFef4444); // #ef4444

  /// Booked date - red text
  static const Color statusBookedText = Color(0xFFef4444); // #ef4444

  /// Past booked date - dark purple background
  static const Color statusPastReservationBackground = Color(0xFF180710); // #180710

  /// Past booked date - border
  static const Color statusPastReservationBorder = Color(0xFF180710); // #180710

  /// Day header background - slate gray
  static const Color backgroundDayHeader = Color(0xFF334255); // #334255

  /// Pending date - amber background (brighter for visibility)
  static const Color statusPendingBackground = Color(0xFFAB9A6D);

  /// Pending date - amber border
  static const Color statusPendingBorder = Color(0xFFF59E0B);

  /// Pending date - amber text
  static const Color statusPendingText = Color(0xFFFDE68A);

  /// Blocked date - distinct dark grey background
  static const Color statusBlockedBackground = Color(0xFF4B5563); // Grey 600

  /// Blocked date - border
  static const Color statusBlockedBorder = Color(0xFF64748B); // Slate 500

  // ==================== SHADOW COLORS ====================
  // White-based shadows for dark theme

  /// Lightest shadow - 4% opacity
  static const Color shadow01 = Color(0x0AFFFFFF);

  /// Light shadow - 8% opacity
  static const Color shadow02 = Color(0x14FFFFFF);

  /// Medium shadow - 12% opacity
  static const Color shadow03 = Color(0x1FFFFFFF);

  /// Strong shadow - 16% opacity
  static const Color shadow04 = Color(0x29FFFFFF);

  // ==================== SEMANTIC COLORS ====================

  /// Success state (matches confirmed badge green)
  static const Color success = Color(0xFF66BB6A); // #66BB6A

  /// Error state
  static const Color error = Color(0xFFEC4899);

  /// Warning state
  static const Color warning = Color(0xFFF59E0B);

  /// Info state
  static const Color info = Color(0xFF999999);

  // ==================== BUTTON COLORS ====================

  /// Primary button background (white)
  static const Color buttonPrimary = Color(0xFFFFFFFF);

  /// Primary button hover (light grey)
  static const Color buttonPrimaryHover = Color(0xFFCCCCCC);

  /// Primary button pressed (medium grey)
  static const Color buttonPrimaryPressed = Color(0xFF999999);

  /// Primary button text (black)
  static const Color buttonPrimaryText = Color(0xFF000000);

  /// Secondary button background (black)
  static const Color buttonSecondary = Color(0xFF000000);

  /// Secondary button border (white)
  static const Color buttonSecondaryBorder = Color(0xFFFFFFFF);

  /// Secondary button text (white)
  static const Color buttonSecondaryText = Color(0xFFFFFFFF);

  // ==================== ADDITIONAL BACKGROUNDS ====================

  /// Dark background (same as primary for consistency)
  static const Color backgroundDark = Color(0xFF000000);

  /// Elevated background level 1
  static const Color backgroundElevated1 = Color(0xFF1A1A1A);

  /// Elevated background level 2
  static const Color backgroundElevated2 = Color(0xFF2A2A2A);

  // ==================== ADDITIONAL BORDERS ====================

  /// Subtle border (very dark grey)
  static const Color borderSubtle = Color(0xFF0F0F0F);

  /// Emphasis border (white for dark theme)
  static const Color borderEmphasis = Color(0xFFFFFFFF);

  // ==================== OVERLAY COLORS ====================

  /// Hover overlay
  static const Color overlayHover = Color(0x1AFFFFFF); // 10% white

  /// Pressed overlay
  static const Color overlayPressed = Color(0x33FFFFFF); // 20% white

  // ==================== DISABLED STATE ====================

  /// Disabled background
  static const Color statusDisabledBackground = Color(0xFF1A1A1A);

  // ==================== HELPER METHODS ====================

  /// Get shadow with custom opacity
  static Color shadow(double opacity) {
    return Color.fromRGBO(255, 255, 255, opacity);
  }

  /// Get grey shade by percentage (0.0 = black, 1.0 = white)
  static Color grey(double brightness) {
    final value = (brightness * 255).round().clamp(0, 255);
    return Color.fromRGBO(value, value, value, 1.0);
  }

  /// Get white with custom opacity (for overlays)
  static Color white(double opacity) {
    return Color.fromRGBO(255, 255, 255, opacity);
  }

  /// Get black with custom opacity (for overlays)
  static Color black(double opacity) {
    return Color.fromRGBO(0, 0, 0, opacity);
  }
}

/// Extension for BoxShadow presets
extension MinimalistShadows on MinimalistColors {
  /// Minimal shadow for subtle elevation (1-level)
  static List<BoxShadow> get minimal => [
    const BoxShadow(color: MinimalistColors.shadow01, offset: Offset(0, 1), blurRadius: 2),
  ];

  /// Light shadow for cards (2-level)
  static List<BoxShadow> get light => [
    const BoxShadow(color: MinimalistColors.shadow02, offset: Offset(0, 2), blurRadius: 4),
  ];

  /// Medium shadow for elevated components (3-level)
  static List<BoxShadow> get medium => [
    const BoxShadow(color: MinimalistColors.shadow02, offset: Offset(0, 2), blurRadius: 4, spreadRadius: -1),
    const BoxShadow(color: MinimalistColors.shadow03, offset: Offset(0, 4), blurRadius: 8, spreadRadius: -2),
  ];

  /// Strong shadow for emphasis (4-level)
  static List<BoxShadow> get strong => [
    const BoxShadow(color: MinimalistColors.shadow02, offset: Offset(0, 4), blurRadius: 6, spreadRadius: -2),
    const BoxShadow(color: MinimalistColors.shadow04, offset: Offset(0, 8), blurRadius: 16, spreadRadius: -4),
  ];

  /// Hover shadow for interactive elements
  static List<BoxShadow> get hover => [
    const BoxShadow(color: MinimalistColors.shadow03, offset: Offset(0, 4), blurRadius: 12),
  ];
}

/// Adapter class to convert MinimalistColors to WidgetColorScheme interface
/// This allows using minimalist black/white theme with components that expect WidgetColorScheme
class MinimalistColorSchemeAdapter implements WidgetColorScheme {
  final bool dark;

  const MinimalistColorSchemeAdapter({this.dark = false});

  // Backgrounds
  @override
  Color get backgroundPrimary => dark ? MinimalistColorsDark.backgroundPrimary : MinimalistColors.backgroundPrimary;

  @override
  Color get backgroundSecondary =>
      dark ? MinimalistColorsDark.backgroundSecondary : MinimalistColors.backgroundSecondary;

  @override
  Color get backgroundTertiary => dark ? MinimalistColorsDark.backgroundTertiary : MinimalistColors.backgroundTertiary;

  @override
  Color get backgroundCard => dark ? MinimalistColorsDark.backgroundCard : MinimalistColors.backgroundCard;

  @override
  Color get backgroundElevated => dark ? MinimalistColorsDark.backgroundTertiary : MinimalistColors.backgroundTertiary;

  // Text
  @override
  Color get textPrimary => dark ? MinimalistColorsDark.textPrimary : MinimalistColors.textPrimary;

  @override
  Color get textSecondary => dark ? MinimalistColorsDark.textSecondary : MinimalistColors.textSecondary;

  @override
  Color get textTertiary => dark ? MinimalistColorsDark.textTertiary : MinimalistColors.textTertiary;

  @override
  Color get textDisabled => dark ? MinimalistColorsDark.textDisabled : MinimalistColors.textDisabled;

  @override
  Color get textOnPrimary => dark ? MinimalistColorsDark.textOnDark : MinimalistColors.textOnDark;

  @override
  Color get textOnAccent => dark ? MinimalistColorsDark.textOnDark : MinimalistColors.textOnDark;

  // Borders
  @override
  Color get borderLight => dark ? MinimalistColorsDark.borderLight : MinimalistColors.borderLight;

  @override
  Color get borderDefault => dark ? MinimalistColorsDark.borderDefault : MinimalistColors.borderDefault;

  @override
  Color get borderMedium => dark ? MinimalistColorsDark.borderMedium : MinimalistColors.borderMedium;

  @override
  Color get borderStrong => dark ? MinimalistColorsDark.borderStrong : MinimalistColors.borderStrong;

  @override
  Color get borderFocus => dark ? MinimalistColorsDark.borderBlack : MinimalistColors.borderBlack;

  @override
  Color get divider => dark ? MinimalistColorsDark.borderLight : MinimalistColors.borderLight;

  // Brand colors - Use black/white (no purple!)
  @override
  Color get primary => dark ? MinimalistColorsDark.textPrimary : MinimalistColors.textPrimary; // White in dark, Black in light

  @override
  Color get primaryHover => dark ? MinimalistColorsDark.textSecondary : MinimalistColors.textSecondary;

  @override
  Color get primaryPressed => dark ? MinimalistColorsDark.textTertiary : MinimalistColors.textTertiary;

  @override
  Color get primaryLight => dark ? MinimalistColorsDark.backgroundTertiary : MinimalistColors.backgroundTertiary;

  @override
  Color get primarySurface => dark ? MinimalistColorsDark.backgroundSecondary : MinimalistColors.backgroundSecondary;

  @override
  Color get accent => dark ? MinimalistColorsDark.statusAvailableBorder : MinimalistColors.statusAvailableBorder;

  @override
  Color get accentHover => dark ? MinimalistColorsDark.statusAvailableText : MinimalistColors.statusAvailableText;

  // Semantic colors
  @override
  Color get success => dark ? MinimalistColorsDark.success : MinimalistColors.success;

  @override
  Color get successBackground =>
      dark ? MinimalistColorsDark.statusAvailableBackground : MinimalistColors.statusAvailableBackground;

  @override
  Color get error => dark ? MinimalistColorsDark.error : MinimalistColors.error;

  @override
  Color get errorBackground =>
      dark ? MinimalistColorsDark.statusBookedBackground : MinimalistColors.statusBookedBackground;

  @override
  Color get warning => dark ? MinimalistColorsDark.warning : MinimalistColors.warning;

  @override
  Color get warningBackground =>
      dark ? MinimalistColorsDark.statusPendingBackground : MinimalistColors.statusPendingBackground;

  @override
  Color get info => dark ? MinimalistColorsDark.info : MinimalistColors.info;

  // Calendar status colors
  @override
  Color get statusAvailableBackground =>
      dark ? MinimalistColorsDark.statusAvailableBackground : MinimalistColors.statusAvailableBackground;

  @override
  Color get statusAvailableBorder =>
      dark ? MinimalistColorsDark.statusAvailableBorder : MinimalistColors.statusAvailableBorder;

  @override
  Color get statusAvailableText =>
      dark ? MinimalistColorsDark.statusAvailableText : MinimalistColors.statusAvailableText;

  @override
  Color get statusBookedBackground =>
      dark ? MinimalistColorsDark.statusBookedBackground : MinimalistColors.statusBookedBackground;

  @override
  Color get statusBookedBorder => dark ? MinimalistColorsDark.statusBookedBorder : MinimalistColors.statusBookedBorder;

  @override
  Color get statusBookedText => dark ? MinimalistColorsDark.statusBookedText : MinimalistColors.statusBookedText;

  @override
  Color get statusPendingBackground =>
      dark ? MinimalistColorsDark.statusPendingBackground : MinimalistColors.statusPendingBackground;

  @override
  Color get statusPendingBorder =>
      dark ? MinimalistColorsDark.statusPendingBorder : MinimalistColors.statusPendingBorder;

  @override
  Color get statusPendingText => dark ? MinimalistColorsDark.statusPendingText : MinimalistColors.statusPendingText;

  @override
  Color get statusBlockedBackground =>
      dark ? MinimalistColorsDark.statusBlockedBackground : MinimalistColors.statusBlockedBackground;

  @override
  Color get statusBlockedBorder =>
      dark ? MinimalistColorsDark.statusBlockedBorder : MinimalistColors.statusBlockedBorder;

  @override
  Color get statusSelectedBackground =>
      dark ? MinimalistColorsDark.backgroundTertiary : MinimalistColors.backgroundTertiary;

  @override
  Color get statusSelectedBorder => dark ? MinimalistColorsDark.textPrimary : MinimalistColors.textPrimary;

  @override
  Color get statusHoverBackground =>
      dark ? MinimalistColorsDark.backgroundSecondary : MinimalistColors.backgroundSecondary;

  @override
  Color get statusHoverBorder => dark ? MinimalistColorsDark.borderMedium : MinimalistColors.borderMedium;

  @override
  Color get statusTodayBorder =>
      dark ? MinimalistColorsDark.statusAvailableBorder : MinimalistColors.statusAvailableBorder;

  @override
  Color get statusDisabledBackground =>
      dark ? MinimalistColorsDark.statusDisabledBackground : MinimalistColors.backgroundTertiary;

  @override
  Color get statusDisabledText => dark ? MinimalistColorsDark.textDisabled : MinimalistColors.textDisabled;

  @override
  Color get statusPastReservationBackground =>
      dark ? MinimalistColorsDark.statusPastReservationBackground : MinimalistColors.statusPastReservationBackground;

  @override
  Color get statusPastReservationBorder =>
      dark ? MinimalistColorsDark.statusPastReservationBorder : MinimalistColors.statusPastReservationBorder;

  @override
  Color get statusCancelledBackground => dark ? ColorTokens.cancelDark : ColorTokens.cancelLight;

  @override
  Color get statusCancelledBorder => dark ? ColorTokens.pink700 : ColorTokens.pink400;

  // Buttons
  @override
  Color get buttonPrimary => dark ? MinimalistColorsDark.buttonPrimary : MinimalistColors.buttonPrimary;

  @override
  Color get buttonPrimaryHover => dark ? MinimalistColorsDark.buttonPrimaryHover : MinimalistColors.buttonPrimaryHover;

  @override
  Color get buttonPrimaryPressed =>
      dark ? MinimalistColorsDark.buttonPrimaryPressed : MinimalistColors.buttonPrimaryPressed;

  @override
  Color get buttonPrimaryText => dark ? MinimalistColorsDark.buttonPrimaryText : MinimalistColors.buttonPrimaryText;

  @override
  Color get buttonSecondary => dark ? MinimalistColorsDark.buttonSecondary : MinimalistColors.buttonSecondary;

  @override
  Color get buttonSecondaryBorder =>
      dark ? MinimalistColorsDark.buttonSecondaryBorder : MinimalistColors.buttonSecondaryBorder;

  @override
  Color get buttonSecondaryText =>
      dark ? MinimalistColorsDark.buttonSecondaryText : MinimalistColors.buttonSecondaryText;

  @override
  Color get buttonDisabled => dark ? MinimalistColorsDark.textDisabled : MinimalistColors.textDisabled;

  @override
  Color get buttonDisabledText => dark ? MinimalistColorsDark.textTertiary : MinimalistColors.textTertiary;

  // Shadows
  @override
  Color get shadow01 => dark ? MinimalistColorsDark.shadow01 : MinimalistColors.shadow01;

  @override
  Color get shadow02 => dark ? MinimalistColorsDark.shadow02 : MinimalistColors.shadow02;

  @override
  Color get shadow03 => dark ? MinimalistColorsDark.shadow03 : MinimalistColors.shadow03;

  @override
  Color get shadow04 => dark ? MinimalistColorsDark.shadow04 : MinimalistColors.shadow04;

  // Overlays
  @override
  Color get overlay => dark ? MinimalistColorsDark.black(0.5) : MinimalistColors.black(0.5);

  @override
  Color get glassOverlay => dark ? MinimalistColorsDark.white(0.1) : MinimalistColors.white(0.1);

  // Helper methods
  @override
  List<BoxShadow> get shadowMinimal => MinimalistShadows.minimal;

  @override
  List<BoxShadow> get shadowLight => MinimalistShadows.light;

  @override
  List<BoxShadow> get shadowMedium => MinimalistShadows.medium;

  @override
  List<BoxShadow> get shadowStrong => MinimalistShadows.strong;

  @override
  List<BoxShadow> get shadowHover => MinimalistShadows.hover;
}
