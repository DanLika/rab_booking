import 'package:flutter/material.dart';

/// Villa Jasko custom color palette for embedded booking widget
/// Inspired by Rab island Mediterranean aesthetics: azure sea, golden sand, terracotta sunsets
class VillaJaskoColors {
  VillaJaskoColors._(); // Private constructor

  // ============================================================================
  // PRIMARY BRAND COLORS - Azure Blue (DESIGN_SYSTEM.md 🌊)
  // ============================================================================

  /// Azure Blue - Kristalno čisto Jadransko more
  /// Use for: Primary buttons, selected states, CTAs, active elements
  static const Color primary = Color(0xFF0066FF); // Azure Blue

  /// Primary Hover - Darker Azure for hover states
  static const Color primaryHover = Color(0xFF0052CC); // Azure 700

  /// Primary Pressed - Darkest Azure for active/pressed states
  static const Color primaryPressed = Color(0xFF003D99); // Azure 800

  /// Primary Light - Light Azure for backgrounds and subtle highlights
  static const Color primaryLight = Color(0xFF99C2FF); // Azure 300

  /// Primary Surface - Very light Azure for surface backgrounds
  static const Color primarySurface = Color(0xFFEBF5FF); // Azure 50

  /// Coral Sunset - Mediteranski zalazak sunca 🌅
  static const Color accent = Color(0xFFFF6B6B); // Coral

  /// Accent Hover - Darker Coral for hover
  static const Color accentHover = Color(0xFFFF5252); // Coral 600

  // ============================================================================
  // CALENDAR STATE COLORS - Modern Design (Agent Plan)
  // ============================================================================

  /// Available day background - Light green
  static const Color dayAvailable = Color(0xFFD1FAE5); // Green 100

  /// Available day border - Green accent
  static const Color dayAvailableBorder = Color(0xFF34D399); // Green 400

  /// Booked day background - Light red
  static const Color dayBooked = Color(0xFFFEE2E2); // Red 100

  /// Booked day border - Red accent
  static const Color dayBookedBorder = Color(0xFFF87171); // Red 400

  /// Selected check-in/check-out - Blue background
  static const Color daySelected = Color(0xFFBFDBFE); // Blue 200

  /// Selected day border - Blue accent
  static const Color daySelectedBorder = Color(0xFF3B82F6); // Blue 500

  /// Days between check-in and check-out - Light blue
  static const Color dayBetween = Color(0xFFDBEAFE); // Blue 100

  /// Hover state background - Sky blue
  static const Color dayHover = Color(0xFFE0F2FE); // Sky 100

  /// Hover state border - Sky accent
  static const Color dayHoverBorder = Color(0xFF0EA5E9); // Sky 500

  /// Today indicator border - Warning orange
  static const Color dayToday = Color(0xFFF59E0B); // Amber 500

  /// Past/disabled days - Light gray
  static const Color dayDisabled = Color(0xFFF3F4F6); // Gray 100

  /// Disabled day text - Gray
  static const Color dayDisabledText = Color(0xFFD1D5DB); // Gray 300

  // ============================================================================
  // BACKGROUND COLORS
  // ============================================================================

  /// Main background - Warm white
  static const Color backgroundMain = Color(0xFFFAFAFA); // Gray 50

  /// Card/surface background - Pure white
  static const Color backgroundSurface = Color(0xFFFFFFFF); // White

  /// Sidebar background - Very light teal tint
  static const Color backgroundSidebar = Color(0xFFF0FDFA); // Teal 50

  /// Elevated surface (cards on hover)
  static const Color backgroundElevated = Color(0xFFFFFFFF); // White

  /// Surface white - Pure white for cards, modals
  static const Color surfaceWhite = Color(0xFFFFFFFF); // White

  // ============================================================================
  // BORDER COLORS
  // ============================================================================

  /// Default border color - Light gray
  static const Color borderDefault = Color(0xFFE5E7EB); // Gray 200

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  /// Primary text - Deep charcoal
  static const Color textPrimary = Color(0xFF111827); // Gray 900

  /// Secondary text - Medium gray
  static const Color textSecondary = Color(0xFF6B7280); // Gray 500

  /// Tertiary/muted text - Light gray
  static const Color textTertiary = Color(0xFF9CA3AF); // Gray 400

  /// Text on primary (teal) background - White
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White

  /// Text on accent (indigo) background - White
  static const Color textOnAccent = Color(0xFFFFFFFF); // White

  /// Disabled text - Very light gray
  static const Color textDisabled = Color(0xFFD1D5DB); // Gray 300

  // ============================================================================
  // BORDER & DIVIDER COLORS
  // ============================================================================

  /// Default border - Light gray
  static const Color border = Color(0xFFE5E7EB); // Gray 200

  /// Border hover - Teal accent
  static const Color borderHover = Color(0xFF14B8A6); // Teal 500

  /// Border focus - Teal dark
  static const Color borderFocus = Color(0xFF0D9488); // Teal 600

  /// Divider - Very light gray
  static const Color divider = Color(0xFFF3F4F6); // Gray 100

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================

  /// Success - Modern green
  static const Color success = Color(0xFF10B981); // Green 500

  /// Error - Modern red
  static const Color error = Color(0xFFEF4444); // Red 500

  /// Warning - Modern amber
  static const Color warning = Color(0xFFF59E0B); // Amber 500

  /// Info - Teal primary
  static const Color info = primary; // Teal 600

  // ============================================================================
  // SHADOW COLORS
  // ============================================================================

  /// Light shadow for elevation
  static const Color shadowLight = Color(0x1A000000); // 10% black

  /// Medium shadow for cards
  static const Color shadowMedium = Color(0x33000000); // 20% black

  /// Strong shadow for modals
  static const Color shadowStrong = Color(0x4D000000); // 30% black

  // ============================================================================
  // BUTTON COLORS
  // ============================================================================

  /// Primary button background - Teal
  static const Color buttonPrimary = primary; // Teal 600

  /// Primary button background (hover) - Darker teal
  static const Color buttonPrimaryHover = primaryHover; // Teal 700

  /// Primary button text - White
  static const Color buttonPrimaryText = Color(0xFFFFFFFF); // White

  /// Secondary button border - Teal
  static const Color buttonSecondaryBorder = primary;

  /// Secondary button text - Teal
  static const Color buttonSecondaryText = primary;

  /// Disabled button background - Light gray
  static const Color buttonDisabled = Color(0xFFE5E7EB); // Gray 200

  /// Disabled button text - Medium gray
  static const Color buttonDisabledText = Color(0xFF9CA3AF); // Gray 400

  // ============================================================================
  // PREMIUM GRADIENTS
  // ============================================================================

  /// Primary button gradient - Teal depths
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [
      Color(0xFF14B8A6), // Teal 500
      Color(0xFF0D9488), // Teal 600
      Color(0xFF0F766E), // Teal 700
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Accent gradient - Indigo flow
  static const LinearGradient gradientAccent = LinearGradient(
    colors: [
      Color(0xFF818CF8), // Indigo 400
      Color(0xFF6366F1), // Indigo 500
      Color(0xFF4F46E5), // Indigo 600
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Success gradient - Green growth
  static const LinearGradient gradientSuccess = LinearGradient(
    colors: [
      Color(0xFF34D399), // Green 400
      Color(0xFF10B981), // Green 500
      Color(0xFF059669), // Green 600
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ============================================================================
  // OVERLAY COLORS
  // ============================================================================

  /// Modal backdrop - Semi-transparent black
  static const Color overlay = Color(0x66000000); // 40% black

  /// Glass effect backdrop - Semi-transparent white
  static const Color glassOverlay = Color(0x1AFFFFFF); // 10% white

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get color with custom opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Get day cell background color based on state
  static Color getDayBackgroundColor({
    required bool isAvailable,
    required bool isBooked,
    required bool isSelected,
    required bool isBetween,
    required bool isDisabled,
    required bool isHovered,
  }) {
    if (isDisabled) return dayDisabled;
    if (isSelected) return daySelected;
    if (isBetween) return dayBetween;
    if (isBooked) return dayBooked;
    if (isHovered) return dayHover;
    return dayAvailable;
  }

  /// Get day cell border color based on state
  static Color getDayBorderColor({
    required bool isAvailable,
    required bool isBooked,
    required bool isSelected,
    required bool isToday,
    required bool isHovered,
  }) {
    if (isSelected) return daySelectedBorder;
    if (isToday) return dayToday;
    if (isBooked) return dayBookedBorder;
    if (isHovered) return dayHoverBorder;
    return border;
  }

  /// Get day cell text color based on state
  static Color getDayTextColor({
    required bool isSelected,
    required bool isDisabled,
    required bool isBooked,
  }) {
    if (isSelected) return textOnPrimary;
    if (isDisabled) return textDisabled;
    if (isBooked) return textSecondary;
    return textPrimary;
  }
}

/// Villa Jasko Dark Theme Colors
/// Designed for dark mode with proper contrast ratios (WCAG AA compliant)
class VillaJaskoDarkColors {
  VillaJaskoDarkColors._(); // Private constructor

  // ============================================================================
  // PRIMARY BRAND COLORS - Adjusted for dark backgrounds
  // ============================================================================

  /// Primary - Lighter Azure for dark mode (better contrast)
  static const Color primary = Color(0xFF3B82F6); // Blue 500

  /// Primary Hover
  static const Color primaryHover = Color(0xFF60A5FA); // Blue 400

  /// Primary Pressed
  static const Color primaryPressed = Color(0xFF2563EB); // Blue 600

  /// Primary Light - For dark surfaces
  static const Color primaryLight = Color(0xFF1E40AF); // Blue 800

  /// Primary Surface - Very dark blue tint
  static const Color primarySurface = Color(0xFF1E293B); // Slate 800

  /// Accent - Slightly muted coral for dark mode
  static const Color accent = Color(0xFFFF8A80); // Coral lighter

  /// Accent Hover
  static const Color accentHover = Color(0xFFFF5252); // Coral 600

  // ============================================================================
  // CALENDAR STATE COLORS - Dark Mode
  // ============================================================================

  /// Available day - Dark green
  static const Color dayAvailable = Color(0xFF134E4A); // Teal 900
  static const Color dayAvailableBorder = Color(0xFF14B8A6); // Teal 500

  /// Booked day - Dark red
  static const Color dayBooked = Color(0xFF7F1D1D); // Red 900
  static const Color dayBookedBorder = Color(0xFFF87171); // Red 400

  /// Selected day - Dark blue
  static const Color daySelected = Color(0xFF1E3A8A); // Blue 900
  static const Color daySelectedBorder = Color(0xFF60A5FA); // Blue 400

  /// Days between selection - Darker blue
  static const Color dayBetween = Color(0xFF1E3A8A); // Blue 900

  /// Hover state - Dark sky blue
  static const Color dayHover = Color(0xFF0C4A6E); // Sky 900
  static const Color dayHoverBorder = Color(0xFF0EA5E9); // Sky 500

  /// Today indicator
  static const Color dayToday = Color(0xFFF59E0B); // Amber 500

  /// Past/disabled days - Very dark gray
  static const Color dayDisabled = Color(0xFF1F2937); // Gray 800
  static const Color dayDisabledText = Color(0xFF4B5563); // Gray 600

  // ============================================================================
  // BACKGROUND COLORS - Dark Mode
  // ============================================================================

  /// Main background - True dark
  static const Color backgroundMain = Color(0xFF0F172A); // Slate 900

  /// Card/surface background - Elevated dark
  static const Color backgroundSurface = Color(0xFF1E293B); // Slate 800

  /// Surface white replacement - Light surface for dark mode
  static const Color surfaceWhite = Color(0xFF334155); // Slate 700

  /// Sidebar background - Slightly lighter
  static const Color backgroundSidebar = Color(0xFF1E293B); // Slate 800

  /// Elevated surface (cards on hover)
  static const Color backgroundElevated = Color(0xFF334155); // Slate 700

  // ============================================================================
  // BORDER COLORS - Dark Mode
  // ============================================================================

  /// Default border - Medium gray
  static const Color borderDefault = Color(0xFF475569); // Slate 600
  static const Color border = Color(0xFF475569); // Slate 600

  /// Border hover
  static const Color borderHover = Color(0xFF14B8A6); // Teal 500

  /// Border focus
  static const Color borderFocus = Color(0xFF0D9488); // Teal 600

  /// Divider - Subtle dark
  static const Color divider = Color(0xFF334155); // Slate 700

  // ============================================================================
  // TEXT COLORS - Dark Mode
  // ============================================================================

  /// Primary text - Light gray (high contrast)
  static const Color textPrimary = Color(0xFFF1F5F9); // Slate 100

  /// Secondary text - Medium gray
  static const Color textSecondary = Color(0xFFCBD5E1); // Slate 300

  /// Tertiary/muted text
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400

  /// Text on primary - White
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White

  /// Text on accent - White
  static const Color textOnAccent = Color(0xFFFFFFFF); // White

  /// Disabled text
  static const Color textDisabled = Color(0xFF64748B); // Slate 500

  // ============================================================================
  // SEMANTIC COLORS - Dark Mode
  // ============================================================================

  /// Success - Green
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successBackground = Color(0xFF064E3B); // Emerald 900

  /// Error - Red
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorBackground = Color(0xFF7F1D1D); // Red 900

  /// Warning - Amber
  static const Color warning = Color(0xFFFBBF24); // Amber 400
  static const Color warningBackground = Color(0xFF78350F); // Amber 900

  /// Info - Blue
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoBackground = Color(0xFF1E3A8A); // Blue 900

  // ============================================================================
  // SHADOW & OVERLAY - Dark Mode
  // ============================================================================

  /// Shadow - Darker and more prominent
  static const Color shadowLight = Color(0x40000000); // 25% black
  static const Color shadowMedium = Color(0x60000000); // 37.5% black
  static const Color shadowHeavy = Color(0x80000000); // 50% black

  /// Overlay - For modals/dialogs
  static const Color overlay = Color(0xCC0F172A); // 80% slate 900

  // ============================================================================
  // POWERED BY BADGE - Dark Mode
  // ============================================================================

  static const Color badgeBackground = Color(0xFF1E293B); // Slate 800
  static const Color badgeText = Color(0xFFCBD5E1); // Slate 300
  static const Color badgeBorder = Color(0xFF334155); // Slate 700
}
