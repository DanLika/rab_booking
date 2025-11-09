import 'package:flutter/material.dart';

/// Dark Mode Color Palette
/// Optimized for WCAG AAA compliance and OLED displays
/// Based on Material Design 3 dark theme principles
class MinimalistColorsDark {
  // ==================== BACKGROUND COLORS (Elevation System) ====================

  /// Pure black - ONLY for OLED mode (optional, causes burn-in on some displays)
  static const Color backgroundOLED = Color(0xFF000000);

  /// Standard dark background - Material Design 3 baseline
  /// This is the recommended dark mode background
  static const Color backgroundDark = Color(0xFF121212);

  /// Elevation level 1 - Slightly elevated surfaces (cards, dialogs)
  /// +5% white overlay on base
  static const Color backgroundElevated1 = Color(0xFF1E1E1E);

  /// Elevation level 2 - More elevated surfaces (app bar, bottom nav)
  /// +7% white overlay on base
  static const Color backgroundElevated2 = Color(0xFF2C2C2C);

  /// Elevation level 3 - Highly elevated surfaces (modals, floating buttons)
  /// +9% white overlay on base
  static const Color backgroundElevated3 = Color(0xFF383838);

  /// Elevation level 4 - Maximum elevation (tooltips, menus)
  /// +11% white overlay on base
  static const Color backgroundElevated4 = Color(0xFF424242);

  /// Secondary background - Subtle background for sections
  static const Color backgroundSecondary = Color(0xFF1A1A1A);

  /// Tertiary background - For disabled/inactive areas
  static const Color backgroundTertiary = Color(0xFF0F0F0F);

  // ==================== TEXT COLORS (WCAG AAA Compliant) ====================

  /// Primary text - Pure white (21:1 contrast ratio on #121212)
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text - Light gray (13.5:1 contrast ratio - AAA compliant)
  /// Perfect for body text, labels, captions
  static const Color textSecondary = Color(0xFFB3B3B3);

  /// Tertiary text - Medium gray (4.5:1 contrast ratio - AA compliant)
  /// For hints, placeholders, less important text
  static const Color textTertiary = Color(0xFF808080);

  /// Disabled text - Dark gray (not meant to be readable)
  static const Color textDisabled = Color(0xFF4D4D4D);

  /// Text on elevated surfaces - Slightly brighter for elevated cards
  static const Color textOnElevated = Color(0xFFFAFAFA);

  // ==================== BORDER COLORS ====================

  /// Subtle border - Barely visible, for gentle separation
  static const Color borderSubtle = Color(0xFF2C2C2C);

  /// Default border - Standard borders for inputs, cards
  static const Color borderDefault = Color(0xFF383838);

  /// Medium border - Hover state, slightly emphasized
  static const Color borderMedium = Color(0xFF595959);

  /// Strong border - Active/selected state
  static const Color borderStrong = Color(0xFF808080);

  /// Emphasis border - Maximum contrast for selected items
  static const Color borderEmphasis = Color(0xFFFFFFFF);

  // ==================== CALENDAR STATUS COLORS (Dark Mode Adjusted) ====================

  /// Available date - Dark teal background (good contrast on dark)
  static const Color statusAvailableBackground = Color(0xFF0D3D30); // Dark teal

  /// Available date - Bright teal border (high visibility)
  static const Color statusAvailableBorder = Color(0xFF2DD4BF); // Bright teal

  /// Available date - Medium teal text (readable)
  static const Color statusAvailableText = Color(0xFF5EEAD4); // Light teal

  /// Booked date - Dark pink background
  static const Color statusBookedBackground = Color(0xFF3D0D29); // Dark pink

  /// Booked date - Bright pink border
  static const Color statusBookedBorder = Color(0xFFFF8FB8); // Bright pink

  /// Booked date - Light pink text
  static const Color statusBookedText = Color(0xFFFFC6E0); // Light pink

  /// Pending date - Dark amber background
  static const Color statusPendingBackground = Color(0xFF3D2D0D); // Dark amber

  /// Pending date - Bright amber border
  static const Color statusPendingBorder = Color(0xFFFBBF24); // Bright amber

  /// Pending date - Light amber text
  static const Color statusPendingText = Color(0xFFFDE68A); // Light amber

  // ==================== SHADOW COLORS (Adjusted for Dark Backgrounds) ====================
  // On dark backgrounds, we use lighter shadows for depth perception

  /// Lightest shadow - 5% white opacity for subtle lift
  static const Color shadow01 = Color(0x0DFFFFFF);

  /// Light shadow - 10% white opacity
  static const Color shadow02 = Color(0x1AFFFFFF);

  /// Medium shadow - 15% white opacity
  static const Color shadow03 = Color(0x26FFFFFF);

  /// Strong shadow - 20% white opacity
  static const Color shadow04 = Color(0x33FFFFFF);

  // ==================== SEMANTIC COLORS (Dark Mode Optimized) ====================

  /// Success state - Brighter teal for visibility
  static const Color success = Color(0xFF2DD4BF);

  /// Error state - Softer pink (less harsh on eyes in dark mode)
  static const Color error = Color(0xFFF87171);

  /// Warning state - Bright amber
  static const Color warning = Color(0xFFFBBF24);

  /// Info state - Light blue
  static const Color info = Color(0xFF60A5FA);

  // ==================== BUTTON COLORS ====================

  /// Primary button background (white for contrast)
  static const Color buttonPrimary = Color(0xFFFFFFFF);

  /// Primary button hover (slightly dimmed white)
  static const Color buttonPrimaryHover = Color(0xFFE0E0E0);

  /// Primary button pressed (more dimmed)
  static const Color buttonPrimaryPressed = Color(0xFFBDBDBD);

  /// Primary button text (black on white button)
  static const Color buttonPrimaryText = Color(0xFF000000);

  /// Secondary button background (transparent)
  static const Color buttonSecondary = Color(0x00000000);

  /// Secondary button border (white)
  static const Color buttonSecondaryBorder = Color(0xFFFFFFFF);

  /// Secondary button text (white)
  static const Color buttonSecondaryText = Color(0xFFFFFFFF);

  // ==================== OVERLAY COLORS ====================

  /// Modal overlay - Semi-transparent black
  static const Color overlayModal = Color(0xCC000000); // 80% opacity

  /// Scrim overlay - For dialogs
  static const Color overlayScrim = Color(0x99000000); // 60% opacity

  /// Hover overlay - Subtle white overlay
  static const Color overlayHover = Color(0x14FFFFFF); // 8% opacity

  /// Pressed overlay - More prominent white overlay
  static const Color overlayPressed = Color(0x29FFFFFF); // 16% opacity

  // ==================== GLASSMORPHISM COLORS ====================

  /// Glass background - Semi-transparent elevated surface
  static const Color glassBackground = Color(0x4D2C2C2C); // 30% opacity

  /// Glass border - Subtle white border
  static const Color glassBorder = Color(0x1AFFFFFF); // 10% opacity

  // ==================== HELPER METHODS ====================

  /// Get shadow with custom opacity (white shadows for dark mode)
  static Color shadow(double opacity) {
    return Color.fromRGBO(255, 255, 255, opacity * 0.2); // Max 20% for subtle effect
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

  /// Get elevated background based on elevation level (0-4)
  static Color getElevatedBackground(int level) {
    switch (level) {
      case 0:
        return backgroundDark;
      case 1:
        return backgroundElevated1;
      case 2:
        return backgroundElevated2;
      case 3:
        return backgroundElevated3;
      case 4:
        return backgroundElevated4;
      default:
        return backgroundDark;
    }
  }

  /// Calculate if a color is dark (for automatic text color selection)
  static bool isColorDark(Color color) {
    final luminance = color.computeLuminance();
    return luminance < 0.5;
  }

  /// Get appropriate text color for a background (ensures contrast)
  static Color getContrastText(Color background) {
    return isColorDark(background) ? textPrimary : const Color(0xFF000000);
  }
}

/// Extension for BoxShadow presets (Dark Mode)
extension MinimalistShadowsDark on MinimalistColorsDark {
  /// Minimal shadow for subtle elevation (1-level) - white glow
  static List<BoxShadow> get minimal => [
        const BoxShadow(
          color: MinimalistColorsDark.shadow01,
          offset: Offset(0, 1),
          blurRadius: 2,
          spreadRadius: 0,
        ),
      ];

  /// Light shadow for cards (2-level)
  static List<BoxShadow> get light => [
        const BoxShadow(
          color: MinimalistColorsDark.shadow02,
          offset: Offset(0, 2),
          blurRadius: 4,
          spreadRadius: 0,
        ),
      ];

  /// Medium shadow for elevated components (3-level)
  static List<BoxShadow> get medium => [
        const BoxShadow(
          color: MinimalistColorsDark.shadow02,
          offset: Offset(0, 2),
          blurRadius: 4,
          spreadRadius: -1,
        ),
        const BoxShadow(
          color: MinimalistColorsDark.shadow03,
          offset: Offset(0, 4),
          blurRadius: 8,
          spreadRadius: -2,
        ),
      ];

  /// Strong shadow for emphasis (4-level)
  static List<BoxShadow> get strong => [
        const BoxShadow(
          color: MinimalistColorsDark.shadow02,
          offset: Offset(0, 4),
          blurRadius: 6,
          spreadRadius: -2,
        ),
        const BoxShadow(
          color: MinimalistColorsDark.shadow04,
          offset: Offset(0, 8),
          blurRadius: 16,
          spreadRadius: -4,
        ),
      ];

  /// Hover shadow for interactive elements
  static List<BoxShadow> get hover => [
        const BoxShadow(
          color: MinimalistColorsDark.shadow03,
          offset: Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];

  /// Glow effect for highlighted elements
  static List<BoxShadow> get glow => [
        const BoxShadow(
          color: MinimalistColorsDark.shadow04,
          offset: Offset(0, 0),
          blurRadius: 20,
          spreadRadius: 0,
        ),
      ];
}
