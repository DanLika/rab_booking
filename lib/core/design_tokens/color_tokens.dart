import 'package:flutter/material.dart';

/// Unified color design tokens for the booking widget
///
/// Provides semantic color naming that works across themes
/// Supports both light and dark modes
/// Replaces MinimalistColors and VillaJaskoColors with a unified system
///
/// Usage:
/// - Light mode: ColorTokens.light.primary
/// - Dark mode: ColorTokens.dark.primary
/// - Get color set: ColorTokens.forBrightness(Brightness.light)
class ColorTokens {
  // ============================================================================
  // THEME COLORS - Access point for all colors
  // ============================================================================

  /// Light mode colors
  static const WidgetColorScheme light = LightColorScheme();

  /// Dark mode colors
  static const WidgetColorScheme dark = DarkColorScheme();

  /// Get color scheme based on brightness
  static WidgetColorScheme forBrightness(Brightness brightness) {
    return brightness == Brightness.light ? light : dark;
  }

  // ============================================================================
  // RAW COLOR VALUES - For custom theming and advanced use cases
  // ============================================================================

  // Pure colors
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // Greys (light to dark)
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // Brand colors - Purple (Modern 2025 Theme)
  static const Color azure50 = Color(0xFFF3F0FF);
  static const Color azure100 = Color(0xFFE0D7FF);
  static const Color azure200 = Color(0xFF9B86F3);
  static const Color azure400 = Color(0xFF8164F0);
  static const Color azure500 = Color(0xFF7B5DED);
  static const Color azure600 = Color(0xFF6B4CE6);
  static const Color azure700 = Color(0xFF5B3DD6);
  static const Color azure800 = Color(0xFF4B2DC6);
  static const Color azure900 = Color(0xFF3B1FB6);

  // Accent colors - Coral
  static const Color coral400 = Color(0xFFFF8A80);
  static const Color coral500 = Color(0xFFFF6B6B);
  static const Color coral600 = Color(0xFFFF5252);

  // Status colors - Teal/Green (Available)
  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal100 = Color(0xFFCCF5E8);
  static const Color teal200 = Color(0xFFD1FAE5);
  static const Color teal400 = Color(0xFF34D399);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color teal600 = Color(0xFF0D9488);
  static const Color teal700 = Color(0xFF0F766E);
  static const Color teal900 = Color(0xFF134E4A);

  // Status colors - Pink/Red (Booked)
  static const Color pink100 = Color(0xFFFFD4E5);
  static const Color pink200 = Color(0xFFFEE2E2);
  static const Color pink400 = Color(0xFFF87171);
  static const Color pink500 = Color(0xFFEC4899);
  static const Color pink600 = Color(0xFFDB2777);
  static const Color pink700 = Color(0xFFEF4444);
  static const Color pink900 = Color(0xFF7F1D1D);

  // Status colors - Amber (Pending/Warning)
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber900 = Color(0xFF78350F);

  // Status colors - Emerald (Success)
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald900 = Color(0xFF064E3B);

  // Slate (for dark mode)
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Sky blue (for selection/hover states)
  static const Color sky100 = Color(0xFFE0F2FE);
  static const Color sky500 = Color(0xFF0EA5E9);
  static const Color sky900 = Color(0xFF0C4A6E);

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get color with custom opacity (0.0 to 1.0)
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Get grey shade by percentage (0.0 = black, 1.0 = white)
  static Color grey(double brightness) {
    final value = (brightness * 255).round().clamp(0, 255);
    return Color.fromRGBO(value, value, value, 1.0);
  }

  /// Get shadow color with custom opacity
  static Color shadow(double opacity) {
    return Color.fromRGBO(0, 0, 0, opacity);
  }
}

// ============================================================================
// COLOR SCHEME INTERFACE
// ============================================================================

/// Base interface for widget color scheme
/// Provides semantic color names that work across themes
abstract class WidgetColorScheme {
  // Backgrounds
  Color get backgroundPrimary;
  Color get backgroundSecondary;
  Color get backgroundTertiary;
  Color get backgroundCard;
  Color get backgroundElevated;

  // Text
  Color get textPrimary;
  Color get textSecondary;
  Color get textTertiary;
  Color get textDisabled;
  Color get textOnPrimary;
  Color get textOnAccent;

  // Borders
  Color get borderLight;
  Color get borderDefault;
  Color get borderMedium;
  Color get borderStrong;
  Color get borderFocus;
  Color get divider;

  // Brand/Theme colors
  Color get primary;
  Color get primaryHover;
  Color get primaryPressed;
  Color get primaryLight;
  Color get primarySurface;
  Color get accent;
  Color get accentHover;

  // Semantic colors
  Color get success;
  Color get successBackground;
  Color get error;
  Color get errorBackground;
  Color get warning;
  Color get warningBackground;
  Color get info;

  // Calendar status colors
  Color get statusAvailableBackground;
  Color get statusAvailableBorder;
  Color get statusAvailableText;
  Color get statusBookedBackground;
  Color get statusBookedBorder;
  Color get statusBookedText;
  Color get statusPendingBackground;
  Color get statusPendingBorder;
  Color get statusPendingText;
  Color get statusSelectedBackground;
  Color get statusSelectedBorder;
  Color get statusHoverBackground;
  Color get statusHoverBorder;
  Color get statusTodayBorder;
  Color get statusDisabledBackground;
  Color get statusDisabledText;
  Color get statusPastReservationBackground;
  Color get statusPastReservationBorder;

  // Buttons
  Color get buttonPrimary;
  Color get buttonPrimaryHover;
  Color get buttonPrimaryPressed;
  Color get buttonPrimaryText;
  Color get buttonSecondary;
  Color get buttonSecondaryBorder;
  Color get buttonSecondaryText;
  Color get buttonDisabled;
  Color get buttonDisabledText;

  // Shadows
  Color get shadow01;
  Color get shadow02;
  Color get shadow03;
  Color get shadow04;

  // Overlays
  Color get overlay;
  Color get glassOverlay;

  // Helper methods
  List<BoxShadow> get shadowMinimal;
  List<BoxShadow> get shadowLight;
  List<BoxShadow> get shadowMedium;
  List<BoxShadow> get shadowStrong;
  List<BoxShadow> get shadowHover;
}

// ============================================================================
// LIGHT COLOR SCHEME
// ============================================================================

class LightColorScheme implements WidgetColorScheme {
  const LightColorScheme();

  // Backgrounds - Clean white/grey
  @override
  Color get backgroundPrimary => ColorTokens.pureWhite;
  @override
  Color get backgroundSecondary => ColorTokens.grey50;
  @override
  Color get backgroundTertiary => ColorTokens.grey100;
  @override
  Color get backgroundCard => ColorTokens.pureWhite;
  @override
  Color get backgroundElevated => ColorTokens.pureWhite;

  // Text - Black to grey
  @override
  Color get textPrimary => ColorTokens.pureBlack;
  @override
  Color get textSecondary => ColorTokens.grey500;
  @override
  Color get textTertiary => ColorTokens.grey400;
  @override
  Color get textDisabled => ColorTokens.grey300;
  @override
  Color get textOnPrimary => ColorTokens.pureWhite;
  @override
  Color get textOnAccent => ColorTokens.pureWhite;

  // Borders
  @override
  Color get borderLight => const Color(0xFFF0F0F0);
  @override
  Color get borderDefault => ColorTokens.grey200;
  @override
  Color get borderMedium => ColorTokens.grey300;
  @override
  Color get borderStrong => ColorTokens.grey500;
  @override
  Color get borderFocus => ColorTokens.azure600;
  @override
  Color get divider => ColorTokens.grey100;

  // Brand colors - Azure blue
  @override
  Color get primary => ColorTokens.azure600;
  @override
  Color get primaryHover => ColorTokens.azure700;
  @override
  Color get primaryPressed => ColorTokens.azure800;
  @override
  Color get primaryLight => ColorTokens.azure200;
  @override
  Color get primarySurface => ColorTokens.azure50;
  @override
  Color get accent => ColorTokens.coral500;
  @override
  Color get accentHover => ColorTokens.coral600;

  // Semantic colors
  @override
  Color get success => ColorTokens.emerald500;
  @override
  Color get successBackground => ColorTokens.teal100;
  @override
  Color get error => ColorTokens.pink500;
  @override
  Color get errorBackground => ColorTokens.pink200;
  @override
  Color get warning => ColorTokens.amber500;
  @override
  Color get warningBackground => ColorTokens.amber200;
  @override
  Color get info => ColorTokens.azure600;

  // Calendar status - Modern mint/pink
  @override
  Color get statusAvailableBackground => ColorTokens.teal100; // Light mint
  @override
  Color get statusAvailableBorder => ColorTokens.teal500;
  @override
  Color get statusAvailableText => ColorTokens.teal600;
  @override
  Color get statusBookedBackground => ColorTokens.pink100; // Light pink
  @override
  Color get statusBookedBorder => ColorTokens.pink500;
  @override
  Color get statusBookedText => ColorTokens.pink600;
  @override
  Color get statusPendingBackground => ColorTokens.amber200;
  @override
  Color get statusPendingBorder => ColorTokens.amber500;
  @override
  Color get statusPendingText => ColorTokens.amber600;
  @override
  Color get statusSelectedBackground => ColorTokens.azure100;
  @override
  Color get statusSelectedBorder => ColorTokens.azure500;
  @override
  Color get statusHoverBackground => ColorTokens.sky100;
  @override
  Color get statusHoverBorder => ColorTokens.sky500;
  @override
  Color get statusTodayBorder => ColorTokens.amber500;
  @override
  Color get statusDisabledBackground => ColorTokens.grey100;
  @override
  Color get statusDisabledText => ColorTokens.grey300;
  @override
  Color get statusPastReservationBackground => ColorTokens.coral500.withValues(alpha: 0.5); // Red with 50% opacity
  @override
  Color get statusPastReservationBorder => ColorTokens.coral600.withValues(alpha: 0.5); // Darker red border with 50% opacity

  // Buttons - Black primary
  @override
  Color get buttonPrimary => ColorTokens.pureBlack;
  @override
  Color get buttonPrimaryHover => const Color(0xFF333333);
  @override
  Color get buttonPrimaryPressed => ColorTokens.grey500;
  @override
  Color get buttonPrimaryText => ColorTokens.pureWhite;
  @override
  Color get buttonSecondary => ColorTokens.pureWhite;
  @override
  Color get buttonSecondaryBorder => ColorTokens.pureBlack;
  @override
  Color get buttonSecondaryText => ColorTokens.pureBlack;
  @override
  Color get buttonDisabled => ColorTokens.grey200;
  @override
  Color get buttonDisabledText => ColorTokens.grey400;

  // Shadows - Black with opacity
  @override
  Color get shadow01 => const Color(0x0A000000); // 4%
  @override
  Color get shadow02 => const Color(0x14000000); // 8%
  @override
  Color get shadow03 => const Color(0x1F000000); // 12%
  @override
  Color get shadow04 => const Color(0x29000000); // 16%

  // Overlays
  @override
  Color get overlay => const Color(0x66000000); // 40% black
  @override
  Color get glassOverlay => const Color(0x1AFFFFFF); // 10% white

  // Shadow presets
  @override
  List<BoxShadow> get shadowMinimal => [
        BoxShadow(
          color: shadow01,
          offset: const Offset(0, 1),
          blurRadius: 2,
          spreadRadius: 0,
        ),
      ];

  @override
  List<BoxShadow> get shadowLight => [
        BoxShadow(
          color: shadow02,
          offset: const Offset(0, 2),
          blurRadius: 4,
          spreadRadius: 0,
        ),
      ];

  @override
  List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: shadow02,
          offset: const Offset(0, 2),
          blurRadius: 4,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: shadow03,
          offset: const Offset(0, 4),
          blurRadius: 8,
          spreadRadius: -2,
        ),
      ];

  @override
  List<BoxShadow> get shadowStrong => [
        BoxShadow(
          color: shadow02,
          offset: const Offset(0, 4),
          blurRadius: 6,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: shadow04,
          offset: const Offset(0, 8),
          blurRadius: 16,
          spreadRadius: -4,
        ),
      ];

  @override
  List<BoxShadow> get shadowHover => [
        BoxShadow(
          color: shadow03,
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];
}

// ============================================================================
// DARK COLOR SCHEME
// ============================================================================

class DarkColorScheme implements WidgetColorScheme {
  const DarkColorScheme();

  // Backgrounds - Dark slate
  @override
  Color get backgroundPrimary => ColorTokens.slate900;
  @override
  Color get backgroundSecondary => ColorTokens.slate800;
  @override
  Color get backgroundTertiary => ColorTokens.slate700;
  @override
  Color get backgroundCard => ColorTokens.slate800;
  @override
  Color get backgroundElevated => ColorTokens.slate700;

  // Text - Light to medium
  @override
  Color get textPrimary => ColorTokens.slate100;
  @override
  Color get textSecondary => ColorTokens.slate300;
  @override
  Color get textTertiary => ColorTokens.slate400;
  @override
  Color get textDisabled => ColorTokens.slate500;
  @override
  Color get textOnPrimary => ColorTokens.pureWhite;
  @override
  Color get textOnAccent => ColorTokens.pureWhite;

  // Borders
  @override
  Color get borderLight => ColorTokens.slate700;
  @override
  Color get borderDefault => ColorTokens.slate600;
  @override
  Color get borderMedium => ColorTokens.slate500;
  @override
  Color get borderStrong => ColorTokens.slate400;
  @override
  Color get borderFocus => ColorTokens.azure400;
  @override
  Color get divider => ColorTokens.slate700;

  // Brand colors - Lighter azure for dark mode
  @override
  Color get primary => ColorTokens.azure500;
  @override
  Color get primaryHover => ColorTokens.azure400;
  @override
  Color get primaryPressed => ColorTokens.azure600;
  @override
  Color get primaryLight => ColorTokens.azure800;
  @override
  Color get primarySurface => ColorTokens.slate800;
  @override
  Color get accent => ColorTokens.coral400;
  @override
  Color get accentHover => ColorTokens.coral600;

  // Semantic colors
  @override
  Color get success => ColorTokens.emerald500;
  @override
  Color get successBackground => ColorTokens.emerald900;
  @override
  Color get error => ColorTokens.pink700;
  @override
  Color get errorBackground => ColorTokens.pink900;
  @override
  Color get warning => ColorTokens.amber400;
  @override
  Color get warningBackground => ColorTokens.amber900;
  @override
  Color get info => ColorTokens.azure500;

  // Calendar status - Dark mode adjusted
  @override
  Color get statusAvailableBackground => ColorTokens.teal900;
  @override
  Color get statusAvailableBorder => ColorTokens.teal500;
  @override
  Color get statusAvailableText => ColorTokens.teal400;
  @override
  Color get statusBookedBackground => ColorTokens.pink900;
  @override
  Color get statusBookedBorder => ColorTokens.pink400;
  @override
  Color get statusBookedText => ColorTokens.pink400;
  @override
  Color get statusPendingBackground => ColorTokens.amber900;
  @override
  Color get statusPendingBorder => ColorTokens.amber500;
  @override
  Color get statusPendingText => ColorTokens.amber400;
  @override
  Color get statusSelectedBackground => ColorTokens.azure900;
  @override
  Color get statusSelectedBorder => ColorTokens.azure400;
  @override
  Color get statusHoverBackground => ColorTokens.sky900;
  @override
  Color get statusHoverBorder => ColorTokens.sky500;
  @override
  Color get statusTodayBorder => ColorTokens.amber500;
  @override
  Color get statusDisabledBackground => ColorTokens.grey800;
  @override
  Color get statusDisabledText => ColorTokens.grey600;
  @override
  Color get statusPastReservationBackground => ColorTokens.coral500.withValues(alpha: 0.5); // Red with 50% opacity
  @override
  Color get statusPastReservationBorder => ColorTokens.coral600.withValues(alpha: 0.5); // Darker red border with 50% opacity

  // Buttons
  @override
  Color get buttonPrimary => ColorTokens.azure500;
  @override
  Color get buttonPrimaryHover => ColorTokens.azure400;
  @override
  Color get buttonPrimaryPressed => ColorTokens.azure600;
  @override
  Color get buttonPrimaryText => ColorTokens.pureWhite;
  @override
  Color get buttonSecondary => ColorTokens.slate700;
  @override
  Color get buttonSecondaryBorder => ColorTokens.azure500;
  @override
  Color get buttonSecondaryText => ColorTokens.azure400;
  @override
  Color get buttonDisabled => ColorTokens.slate700;
  @override
  Color get buttonDisabledText => ColorTokens.slate500;

  // Shadows - Darker for dark mode
  @override
  Color get shadow01 => const Color(0x40000000); // 25%
  @override
  Color get shadow02 => const Color(0x60000000); // 37.5%
  @override
  Color get shadow03 => const Color(0x80000000); // 50%
  @override
  Color get shadow04 => const Color(0x99000000); // 60%

  // Overlays
  @override
  Color get overlay => const Color(0xCC0F172A); // 80% slate 900
  @override
  Color get glassOverlay => const Color(0x1AFFFFFF); // 10% white

  // Shadow presets
  @override
  List<BoxShadow> get shadowMinimal => [
        BoxShadow(
          color: shadow01,
          offset: const Offset(0, 1),
          blurRadius: 3,
          spreadRadius: 0,
        ),
      ];

  @override
  List<BoxShadow> get shadowLight => [
        BoxShadow(
          color: shadow02,
          offset: const Offset(0, 2),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ];

  @override
  List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: shadow02,
          offset: const Offset(0, 3),
          blurRadius: 6,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: shadow03,
          offset: const Offset(0, 6),
          blurRadius: 12,
          spreadRadius: -2,
        ),
      ];

  @override
  List<BoxShadow> get shadowStrong => [
        BoxShadow(
          color: shadow02,
          offset: const Offset(0, 6),
          blurRadius: 10,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: shadow04,
          offset: const Offset(0, 12),
          blurRadius: 24,
          spreadRadius: -4,
        ),
      ];

  @override
  List<BoxShadow> get shadowHover => [
        BoxShadow(
          color: shadow03,
          offset: const Offset(0, 6),
          blurRadius: 16,
          spreadRadius: 0,
        ),
      ];
}
