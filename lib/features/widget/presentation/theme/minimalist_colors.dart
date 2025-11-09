import 'package:flutter/material.dart';

/// Minimalist Color Palette
/// Black, White, and Grey tones for clean, modern aesthetic
/// Only green/red/amber for calendar status indicators
class MinimalistColors {
  // ==================== BASE COLORS ====================

  /// Pure white - primary background
  static const Color backgroundPrimary = Color(0xFFFFFFFF);

  /// Off-white - secondary background for subtle contrast
  static const Color backgroundSecondary = Color(0xFFFAFAFA);

  /// Light grey - tertiary background for disabled/inactive areas
  static const Color backgroundTertiary = Color(0xFFF5F5F5);

  /// White with shadow - elevated cards
  static const Color backgroundCard = Color(0xFFFFFFFF);

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

  /// Medium grey - hover borders
  static const Color borderMedium = Color(0xFFCCCCCC);

  /// Dark grey - active/strong borders
  static const Color borderStrong = Color(0xFF666666);

  /// Pure black - emphasis borders (selected, active)
  static const Color borderBlack = Color(0xFF000000);

  // ==================== CALENDAR STATUS COLORS ====================
  // Light mint/pink color scheme for modern booking widget (like reference image)

  /// Available date - light mint green background
  static const Color statusAvailableBackground = Color(0xFFCCF5E8); // Light mint

  /// Available date - mint green border
  static const Color statusAvailableBorder = Color(0xFF5CD4B4); // Mint green

  /// Available date - teal text
  static const Color statusAvailableText = Color(0xFF0D9488); // Teal 600

  /// Booked date - light pink background
  static const Color statusBookedBackground = Color(0xFFFFD4E5); // Light pink

  /// Booked date - pink border
  static const Color statusBookedBorder = Color(0xFFFF8FB8); // Pink

  /// Booked date - pink text
  static const Color statusBookedText = Color(0xFFDB2777); // Pink 600

  /// Pending date - amber background (vibrant)
  static const Color statusPendingBackground = Color(0xFFFDE68A); // Amber 200

  /// Pending date - amber border (strong)
  static const Color statusPendingBorder = Color(0xFFF59E0B); // Amber 500

  /// Pending date - amber text
  static const Color statusPendingText = Color(0xFFD97706); // Amber 600

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

  /// Success state (mirrors available teal)
  static const Color success = Color(0xFF14B8A6);

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

  /// Dark grey - tertiary background for disabled/inactive areas
  static const Color backgroundTertiary = Color(0xFF1A1A1A);

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

  /// Almost black - very subtle borders
  static const Color borderLight = Color(0xFF0F0F0F);

  /// Dark grey - default borders
  static const Color borderDefault = Color(0xFF1F1F1F);

  /// Medium grey - hover borders
  static const Color borderMedium = Color(0xFF333333);

  /// Light grey - active/strong borders
  static const Color borderStrong = Color(0xFF999999);

  /// Pure white - emphasis borders (selected, active)
  static const Color borderBlack = Color(0xFFFFFFFF);

  // ==================== CALENDAR STATUS COLORS ====================
  // Darker versions of status colors

  /// Available date - dark mint green background
  static const Color statusAvailableBackground = Color(0xFF1A3D35);

  /// Available date - mint green border
  static const Color statusAvailableBorder = Color(0xFF5CD4B4);

  /// Available date - teal text
  static const Color statusAvailableText = Color(0xFF5CD4B4);

  /// Booked date - dark pink background
  static const Color statusBookedBackground = Color(0xFF3D1A28);

  /// Booked date - pink border
  static const Color statusBookedBorder = Color(0xFFFF8FB8);

  /// Booked date - pink text
  static const Color statusBookedText = Color(0xFFFF8FB8);

  /// Pending date - dark amber background
  static const Color statusPendingBackground = Color(0xFF3D3318);

  /// Pending date - amber border
  static const Color statusPendingBorder = Color(0xFFF59E0B);

  /// Pending date - amber text
  static const Color statusPendingText = Color(0xFFFDE68A);

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

  /// Success state
  static const Color success = Color(0xFF14B8A6);

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
}

/// Extension for BoxShadow presets
extension MinimalistShadows on MinimalistColors {
  /// Minimal shadow for subtle elevation (1-level)
  static List<BoxShadow> get minimal => [
        const BoxShadow(
          color: MinimalistColors.shadow01,
          offset: Offset(0, 1),
          blurRadius: 2,
          spreadRadius: 0,
        ),
      ];

  /// Light shadow for cards (2-level)
  static List<BoxShadow> get light => [
        const BoxShadow(
          color: MinimalistColors.shadow02,
          offset: Offset(0, 2),
          blurRadius: 4,
          spreadRadius: 0,
        ),
      ];

  /// Medium shadow for elevated components (3-level)
  static List<BoxShadow> get medium => [
        const BoxShadow(
          color: MinimalistColors.shadow02,
          offset: Offset(0, 2),
          blurRadius: 4,
          spreadRadius: -1,
        ),
        const BoxShadow(
          color: MinimalistColors.shadow03,
          offset: Offset(0, 4),
          blurRadius: 8,
          spreadRadius: -2,
        ),
      ];

  /// Strong shadow for emphasis (4-level)
  static List<BoxShadow> get strong => [
        const BoxShadow(
          color: MinimalistColors.shadow02,
          offset: Offset(0, 4),
          blurRadius: 6,
          spreadRadius: -2,
        ),
        const BoxShadow(
          color: MinimalistColors.shadow04,
          offset: Offset(0, 8),
          blurRadius: 16,
          spreadRadius: -4,
        ),
      ];

  /// Hover shadow for interactive elements
  static List<BoxShadow> get hover => [
        const BoxShadow(
          color: MinimalistColors.shadow03,
          offset: Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];
}
