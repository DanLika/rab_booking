import 'package:flutter/material.dart';

/// Application color palette
/// Inspired by Mediterranean coastal aesthetics and luxury vacation rentals
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ============================================================================
  // PRIMARY & SECONDARY COLORS
  // ============================================================================

  /// Primary brand color - Modern Purple
  /// Used for: primary actions, links, focus states, trust indicators
  /// Updated to modern Purple-Blue theme (2025)
  static const Color primary = Color(0xFF6B4CE6); // Purple

  /// Primary variant - Deeper purple
  static const Color primaryDark = Color(0xFF5B3DD6); // Deep Purple

  /// Primary light - Light purple
  static const Color primaryLight = Color(0xFF9B86F3); // Light Purple

  /// Secondary accent color - Coral Sunset
  /// Used for: CTAs, highlights, special offers, energy elements
  /// Inspired by Mediterranean sunsets and warmth
  static const Color secondary = Color(0xFFFF6B6B); // Coral Red

  /// Secondary dark
  static const Color secondaryDark = Color(0xFFE63946); // Deep Coral

  /// Secondary light
  static const Color secondaryLight = Color(0xFFFF8E8E); // Light Coral

  /// Tertiary accent color - Golden Sand
  /// Used for: premium elements, ratings, highlights
  /// Inspired by sun-kissed beaches
  static const Color tertiary = Color(0xFFFFB84D); // Golden Sand

  /// Tertiary dark
  static const Color tertiaryDark = Color(0xFFFF9500); // Deep Gold

  /// Tertiary light
  static const Color tertiaryLight = Color(0xFFFFCA80); // Light Gold

  // ============================================================================
  // NEUTRAL COLORS - LIGHT THEME
  // ============================================================================

  /// Background color - Warm White
  static const Color backgroundLight = Color(0xFFFAFAFA); // Warm White

  /// Surface color - Pure white
  static const Color surfaceLight = Color(0xFFFFFFFF); // White

  /// Surface variant - Light gray
  static const Color surfaceVariantLight = Color(0xFFF5F5F5); // Light Gray

  /// Text primary - Dark Gray
  static const Color textPrimaryLight = Color(0xFF2D3748); // Dark Gray

  /// Text secondary - Medium gray
  static const Color textSecondaryLight = Color(0xFF4A5568); // Medium Gray

  /// Text tertiary - Light gray
  static const Color textTertiaryLight = Color(0xFF718096); // Light Gray

  /// Border color - Light border (cool gray - legacy)
  static const Color borderLight = Color(0xFFE2E8F0); // Light Border

  /// Border color - Warm beige (Mediterranean theme)
  /// Used for: inputs, cards, sections - matches sectionBorder in AppGradients
  static const Color borderWarmLight = Color(0xFFE8E5DC); // Warm Beige

  /// Divider color - Very light (for subtle separators)
  static const Color dividerLight = Color(0xFFF7FAFC); // Very Light Gray

  /// Section divider color - Visible divider for dialog sections
  static const Color sectionDividerLight = Color(0xFFE0E0E8); // Cool Gray

  /// Dialog footer background color
  static const Color dialogFooterLight = Color(0xFFF8F8FA); // Very Light Gray

  // ============================================================================
  // NEUTRAL COLORS - DARK THEME (OLED-Optimized - 2025 Standard)
  // ============================================================================

  /// Background color - True Black (OLED-friendly for better battery life)
  /// UPGRADED: Was 0xFF1A202C (gray) → Now 0xFF000000 (true black)
  /// Impact: 20% better battery life on OLED screens, modern 2025 dark mode
  static const Color backgroundDark = Color(0xFF000000); // TRUE BLACK (OLED)

  /// Surface color - Material Design 3 dark surface
  /// UPGRADED: Was 0xFF2D3748 → Now 0xFF121212 (MD3 standard)
  /// Used for: Cards, elevated containers
  static const Color surfaceDark = Color(0xFF121212); // MD3 Dark Surface

  /// Surface variant - Elevated surface
  /// UPGRADED: Was 0xFF4A5568 → Now 0xFF1E1E1E (higher elevation)
  /// Used for: App bars, navigation, elevated elements
  static const Color surfaceVariantDark = Color(0xFF1E1E1E); // Elevated Surface

  /// Text primary - Light Gray
  static const Color textPrimaryDark = Color(0xFFE2E8F0); // Light Gray

  /// Text secondary - Medium light gray
  static const Color textSecondaryDark = Color(0xFFA0AEC0); // Medium light gray

  /// Text tertiary - Medium gray
  static const Color textTertiaryDark = Color(0xFF718096); // Medium gray

  /// Border color - Dark border (optimized for true black background)
  /// UPGRADED: Was 0xFF4A5568 → Now 0xFF2D3748 (better contrast with black)
  static const Color borderDark = Color(0xFF2D3748); // Dark border

  /// Border color - Warm gray (Mediterranean theme)
  /// Used for: inputs, cards, sections - matches sectionBorder in AppGradients
  static const Color borderWarmDark = Color(0xFF3D3733); // Warm Gray

  /// Divider color (optimized for true black background)
  /// UPGRADED: Was 0xFF2D3748 → Now 0xFF1E1E1E (subtle, not harsh)
  static const Color dividerDark = Color(0xFF1E1E1E); // Divider

  /// Section divider color - Visible divider for dialog sections
  static const Color sectionDividerDark = Color(0xFF2D2D3A); // Cool Dark Gray

  /// Dialog footer background color
  static const Color dialogFooterDark = Color(0xFF1E1E2A); // Dark Purple-Gray

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

  /// Text color for warning backgrounds (dark for contrast on orange)
  static const Color textOnWarning = Color(0xFF1C1917); // Stone 900

  /// Info color - Blue
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoLight = Color(0xFF60A5FA); // Blue 400
  static const Color infoDark = Color(0xFF2563EB); // Blue 600

  // ============================================================================
  // STATE COLORS
  // ============================================================================

  /// Disabled background color
  static const Color disabled = Color(0xFFE5E7EB); // Gray 200

  /// Disabled text color
  static const Color textDisabled = Color(0xFF9CA3AF); // Gray 400

  /// Generic text secondary color (theme-agnostic)
  static const Color textSecondary = Color(0xFF6B7280); // Gray 500

  // ============================================================================
  // GENERIC/ALIAS COLORS (for compatibility)
  // ============================================================================

  /// Generic text primary (defaults to light theme)
  static const Color textPrimary = textPrimaryLight;

  /// Generic surface (defaults to light theme)
  static const Color surface = surfaceLight;

  /// Generic divider (defaults to light theme)
  static const Color divider = dividerLight;

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

  /// Activity type colors
  static const Color activityBooking = Color(0xFF7C3AED); // Purple 600 - new booking
  static const Color activityConfirmed = Color(0xFF10B981); // Emerald 500 - confirmed
  static const Color activityReview = Color(0xFFD97706); // Amber 600
  static const Color activityMessage = Color(0xFF5B8DEE); // Blue 500
  static const Color activityPayment = Color(0xFF0891B2); // Cyan 600
  static const Color activityCancellation = Color(0xFFDC2626); // Red 600
  static const Color activityCompleted = Color(0xFF6B7280); // Gray 500 - completed

  // ============================================================================
  // AUTH SCREEN COLORS (Premium Purple-Blue Theme)
  // ============================================================================

  /// Auth primary color - Modern Purple
  static const Color authPrimary = Color(0xFF6B4CE6); // Purple

  /// Auth primary light - Lighter Purple
  static const Color authPrimaryLight = Color(0xFF8B6CEF); // Light Purple

  /// Auth primary dark - Darker Purple
  static const Color authPrimaryDark = Color(0xFF5436C3); // Dark Purple

  /// Auth secondary color - Lighter Blue
  static const Color authSecondary = Color(0xFF4A90E2); // Blue

  /// Auth background gradient start - Beige
  static const Color authBackgroundStart = Color(0xFFFAF8F3); // Beige

  /// Auth background gradient end - White
  static const Color authBackgroundEnd = Color(0xFFFFFFFF); // White

  /// Auth illustration color - Dark Gray
  static const Color authIllustration = Color(0xFF2C2C2C); // Dark Gray

  // ============================================================================
  // GRADIENT COLORS
  // ============================================================================

  /// Auth gradient - Modern Purple to Blue
  /// Use for: auth buttons, auth accents
  static const LinearGradient authGradient = LinearGradient(
    colors: [
      Color(0xFF6B4CE6), // Purple
      Color(0xFF4A90E2), // Blue
    ],
  );

  /// Auth primary gradient - Purple gradient
  /// Use for: auth primary buttons
  static const LinearGradient authPrimaryGradient = LinearGradient(
    colors: [
      Color(0xFF8B6CEF), // Light Purple
      Color(0xFF6B4CE6), // Purple
      Color(0xFF5436C3), // Dark Purple
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Auth background gradient - Cool lavender-gray to White (Light Mode)
  /// Use for: auth screen background in light mode
  static const LinearGradient authBackgroundGradient = LinearGradient(
    colors: [
      Color(0xFFF5F3F9), // Cool lavender-gray
      Color(0xFFFFFFFF), // White
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Auth background gradient - Cool dark purple-gray (Dark Mode)
  /// Use for: auth screen background in dark mode
  static const LinearGradient authBackgroundGradientDark = LinearGradient(
    colors: [
      Color(0xFF1A1820), // Cool dark purple-gray
      Color(0xFF211F26), // Slightly lighter
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Primary gradient - Purple Depths (Modern purple spectrum)
  /// Use for: hero sections, featured cards, primary backgrounds
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF9B86F3), // Light Purple
      Color(0xFF6B4CE6), // Purple
      Color(0xFF5B3DD6), // Deep Purple
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Secondary gradient - Coral Sunset (Warm coral spectrum)
  /// Use for: CTAs, highlights, energy elements
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [
      Color(0xFFFF8E8E), // Light Coral
      Color(0xFFFF6B6B), // Coral Red
      Color(0xFFE63946), // Deep Coral
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Tertiary gradient - Golden Hour (Golden sand spectrum)
  /// Use for: premium elements, special offers, ratings
  static const LinearGradient tertiaryGradient = LinearGradient(
    colors: [
      Color(0xFFFFCA80), // Light Gold
      Color(0xFFFFB84D), // Golden Sand
      Color(0xFFFF9500), // Deep Gold
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Mediterranean Sunset - Multi-color premium gradient
  /// Use for: special sections, featured content, premium cards
  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [
      Color(0xFFFFB84D), // Golden Sand
      Color(0xFFFF6B6B), // Coral Red
      Color(0xFF6B4CE6), // Purple
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Ocean Breeze - Purple to turquoise
  /// Use for: water-themed sections, calm backgrounds
  static const LinearGradient oceanGradient = LinearGradient(
    colors: [
      Color(0xFF6B4CE6), // Purple
      Color(0xFF00C9FF), // Turquoise
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Luxury Gold - Premium golden gradient
  /// Use for: VIP elements, premium badges, special offers
  static const LinearGradient luxuryGradient = LinearGradient(
    colors: [
      Color(0xFFFFCA80), // Light Gold
      Color(0xFFFFB84D), // Golden Sand
      Color(0xFFFF9500), // Deep Gold
      Color(0xFFE67E00), // Burnt Gold
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Overlay gradient (for image overlays - dark vignette)
  static const LinearGradient overlayGradient = LinearGradient(
    colors: [
      Color(0x00000000), // Transparent top
      Color(0x80000000), // Black 50% bottom
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Premium overlay - Subtle gradient with primary color tint
  /// Use for: property card images, hero section images
  static const LinearGradient premiumOverlayGradient = LinearGradient(
    colors: [
      Color(0x006B4CE6), // Transparent Purple top
      Color(0x33000000), // Black 20% middle
      Color(0x80000000), // Black 50% bottom
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  /// Hero gradient - Bold primary gradient for hero sections
  static const LinearGradient heroGradient = LinearGradient(
    colors: [
      Color(0xFF6B4CE6), // Purple
      Color(0xFF5B3DD6), // Deep Purple
      Color(0xFF4B2DC6), // Darker Purple
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// CTA gradient - Energetic coral-to-gold for call-to-action buttons
  static const LinearGradient ctaGradient = LinearGradient(
    colors: [
      Color(0xFFFF6B6B), // Coral Red
      Color(0xFFFF9500), // Deep Gold
      Color(0xFFFFB84D), // Golden Sand
    ],
  );

  /// Glass morphism gradient (for glass effect backgrounds)
  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF), // 10% white top
      Color(0x0DFFFFFF), // 5% white bottom
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dark glass gradient (for dark mode glass effects)
  static const LinearGradient glassGradientDark = LinearGradient(
    colors: [
      Color(0x1AFFFFFF), // 10% white top
      Color(0x0D000000), // 5% black bottom
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // OPACITY SCALES
  // ============================================================================

  /// Opacity scale for consistent transparency values
  static const double opacity0 = 0.0; // Completely transparent
  static const double opacity5 = 0.05; // Barely visible
  static const double opacity10 = 0.10; // Very light
  static const double opacity20 = 0.20; // Light
  static const double opacity30 = 0.30; // Light-medium
  static const double opacity40 = 0.40; // Medium
  static const double opacity50 = 0.50; // Half transparent
  static const double opacity60 = 0.60; // Semi-transparent
  static const double opacity70 = 0.70; // Medium-opaque
  static const double opacity80 = 0.80; // Almost opaque
  static const double opacity90 = 0.90; // Very opaque
  static const double opacity100 = 1.0; // Completely solid

  // ============================================================================
  // SURFACE ELEVATION COLORS (Material Design 3 inspired)
  // ============================================================================

  /// Surface elevation levels for light theme (subtle brightness variations)
  static const Color elevation0Light = surfaceLight; // Base surface (0dp)
  static const Color elevation1Light = Color(0xFFFEFEFE); // +1dp (cards)
  static const Color elevation2Light = Color(0xFFFDFDFD); // +2dp (floating buttons)
  static const Color elevation3Light = Color(0xFFFCFCFC); // +4dp (modals)
  static const Color elevation4Light = Color(0xFFFBFBFB); // +8dp (dialogs)

  /// Surface elevation levels for dark theme (brighter on elevation - Material Design 3)
  /// UPGRADED: All levels recalculated for true black base (0xFF000000)
  /// Uses white overlay technique: elevation = base + white opacity
  static const Color elevation0Dark = surfaceDark; // Base surface (0dp) = 0xFF121212
  static const Color elevation1Dark = Color(0xFF1E1E1E); // +1dp (cards) - 5% white overlay
  static const Color elevation2Dark = Color(0xFF232323); // +2dp (floating buttons) - 8% white overlay
  static const Color elevation3Dark = Color(0xFF282828); // +4dp (modals) - 11% white overlay
  static const Color elevation4Dark = Color(0xFF2C2C2C); // +8dp (dialogs) - 14% white overlay

  // ============================================================================
  // SCRIM & BACKDROP COLORS
  // ============================================================================

  /// Scrim color for modal backdrops (light)
  static const Color scrimLight = Color(0x66000000); // 40% black

  /// Scrim color for modal backdrops (dark)
  static const Color scrimDark = Color(0x99000000); // 60% black

  /// Blur backdrop color for glass morphism (light)
  static const Color blurBackdropLight = Color(0x1AFFFFFF); // 10% white

  /// Blur backdrop color for glass morphism (dark)
  static const Color blurBackdropDark = Color(0x1A000000); // 10% black

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
