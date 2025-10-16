import 'package:flutter/material.dart';

/// Application color palette
/// Inspired by Mediterranean coastal aesthetics and luxury vacation rentals
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ============================================================================
  // PRIMARY & SECONDARY COLORS
  // ============================================================================

  /// Primary brand color - Mediterranean Teal
  /// Used for: primary actions, links, focus states
  static const Color primary = Color(0xFF0891B2); // Cyan 600

  /// Primary variant - Darker teal
  static const Color primaryDark = Color(0xFF0E7490); // Cyan 700

  /// Primary light - Lighter teal
  static const Color primaryLight = Color(0xFF06B6D4); // Cyan 500

  /// Secondary accent color - Sunset Gold
  /// Used for: CTAs, highlights, special offers
  static const Color secondary = Color(0xFFF59E0B); // Amber 500

  /// Secondary dark
  static const Color secondaryDark = Color(0xFFD97706); // Amber 600

  /// Secondary light
  static const Color secondaryLight = Color(0xFFFBBF24); // Amber 400

  // ============================================================================
  // NEUTRAL COLORS - LIGHT THEME
  // ============================================================================

  /// Background color - Warm off-white
  static const Color backgroundLight = Color(0xFFFAFAF9); // Stone 50

  /// Surface color - Pure white
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Surface variant - Light gray
  static const Color surfaceVariantLight = Color(0xFFF5F5F4); // Stone 100

  /// Text primary - Dark charcoal
  static const Color textPrimaryLight = Color(0xFF1C1917); // Stone 900

  /// Text secondary - Medium gray
  static const Color textSecondaryLight = Color(0xFF57534E); // Stone 600

  /// Text tertiary - Light gray
  static const Color textTertiaryLight = Color(0xFF78716C); // Stone 500

  /// Border color - Light border
  static const Color borderLight = Color(0xFFE7E5E4); // Stone 200

  /// Divider color
  static const Color dividerLight = Color(0xFFF5F5F4); // Stone 100

  // ============================================================================
  // NEUTRAL COLORS - DARK THEME
  // ============================================================================

  /// Background color - Deep charcoal
  static const Color backgroundDark = Color(0xFF0C0A09); // Stone 950

  /// Surface color - Dark gray
  static const Color surfaceDark = Color(0xFF1C1917); // Stone 900

  /// Surface variant - Medium dark
  static const Color surfaceVariantDark = Color(0xFF292524); // Stone 800

  /// Text primary - Off-white
  static const Color textPrimaryDark = Color(0xFFFAFAF9); // Stone 50

  /// Text secondary - Light gray
  static const Color textSecondaryDark = Color(0xFFA8A29E); // Stone 400

  /// Text tertiary - Medium gray
  static const Color textTertiaryDark = Color(0xFF78716C); // Stone 500

  /// Border color - Dark border
  static const Color borderDark = Color(0xFF292524); // Stone 800

  /// Divider color
  static const Color dividerDark = Color(0xFF1C1917); // Stone 900

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================

  /// Success color - Green
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successLight = Color(0xFF34D399); // Emerald 400
  static const Color successDark = Color(0xFF059669); // Emerald 600

  /// Error color - Red
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFF87171); // Red 400
  static const Color errorDark = Color(0xFFDC2626); // Red 600

  /// Warning color - Orange
  static const Color warning = Color(0xFFF97316); // Orange 500
  static const Color warningLight = Color(0xFFFB923C); // Orange 400
  static const Color warningDark = Color(0xFFEA580C); // Orange 600

  /// Info color - Blue
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoLight = Color(0xFF60A5FA); // Blue 400
  static const Color infoDark = Color(0xFF2563EB); // Blue 600

  // ============================================================================
  // FUNCTIONAL COLORS
  // ============================================================================

  /// Overlay color for modals/dialogs
  static const Color overlay = Color(0x80000000); // Black with 50% opacity

  /// Shimmer base color (for loading skeletons)
  static const Color shimmerBase = Color(0xFFE7E5E4); // Stone 200
  static const Color shimmerHighlight = Color(0xFFF5F5F4); // Stone 100

  /// Rating star color
  static const Color star = Color(0xFFFBBF24); // Amber 400

  /// Favorite/like color
  static const Color favorite = Color(0xFFEC4899); // Pink 500

  /// Booking status colors
  static const Color statusPending = Color(0xFFF59E0B); // Amber 500
  static const Color statusConfirmed = Color(0xFF10B981); // Emerald 500
  static const Color statusCancelled = Color(0xFFEF4444); // Red 500
  static const Color statusCompleted = Color(0xFF6B7280); // Gray 500

  // ============================================================================
  // GRADIENT COLORS
  // ============================================================================

  /// Primary gradient (for hero sections, featured cards)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF06B6D4), // Cyan 500
      Color(0xFF0891B2), // Cyan 600
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Secondary gradient (for CTAs, highlights)
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [
      Color(0xFFFBBF24), // Amber 400
      Color(0xFFF59E0B), // Amber 500
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Sunset gradient (for special sections)
  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [
      Color(0xFFF59E0B), // Amber 500
      Color(0xFFF97316), // Orange 500
      Color(0xFFEC4899), // Pink 500
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Overlay gradient (for image overlays)
  static const LinearGradient overlayGradient = LinearGradient(
    colors: [
      Color(0x00000000), // Transparent
      Color(0x80000000), // Black 50%
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Get status color based on booking status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return statusPending;
      case 'confirmed':
        return statusConfirmed;
      case 'cancelled':
        return statusCancelled;
      case 'completed':
        return statusCompleted;
      default:
        return textSecondaryLight;
    }
  }

  /// Get rating color based on value (1-5 stars)
  static Color getRatingColor(double rating) {
    if (rating >= 4.5) return success;
    if (rating >= 3.5) return star;
    if (rating >= 2.5) return warning;
    return error;
  }
}
