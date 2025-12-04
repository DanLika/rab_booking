import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Extension for easy theme-aware color access throughout the app
///
/// This extension provides convenient getters for theme-aware colors
/// that automatically adapt between light and dark modes.
///
/// Usage:
/// ```dart
/// Container(color: context.surfaceColor)
/// Text('Label', style: TextStyle(color: context.textColor))
/// Divider(color: context.dividerColor)
/// Icon(Icons.star, color: context.iconColor)
/// ```
extension ThemeColors on BuildContext {
  // ============================================================================
  // THEME DETECTION
  // ============================================================================

  /// Check if dark mode is currently active
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Check if light mode is currently active
  bool get isLightMode => Theme.of(this).brightness == Brightness.light;

  // ============================================================================
  // BACKGROUND & SURFACE COLORS
  // ============================================================================

  /// Get theme-aware background color
  ///
  /// Returns:
  /// - Light mode: AppColors.backgroundLight (0xFFFAFAFA)
  /// - Dark mode: AppColors.backgroundDark (0xFF000000 - TRUE BLACK, OLED optimized)
  Color get backgroundColor => isDarkMode
      ? AppColors.backgroundDark
      : AppColors.backgroundLight;

  /// Get theme-aware surface color (for cards, dialogs, etc.)
  ///
  /// Returns:
  /// - Light mode: AppColors.surfaceLight (0xFFFFFFFF)
  /// - Dark mode: AppColors.surfaceDark (0xFF121212 - MD3 standard)
  Color get surfaceColor => isDarkMode
      ? AppColors.surfaceDark
      : AppColors.surfaceLight;

  /// Get theme-aware surface variant color
  ///
  /// Returns:
  /// - Light mode: AppColors.surfaceVariantLight (0xFFF5F5F5)
  /// - Dark mode: AppColors.surfaceVariantDark (0xFF1E1E1E - higher elevation)
  Color get surfaceVariantColor => isDarkMode
      ? AppColors.surfaceVariantDark
      : AppColors.surfaceVariantLight;

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  /// Get theme-aware primary text color
  ///
  /// Returns:
  /// - Light mode: AppColors.textPrimaryLight (0xFF2D3748)
  /// - Dark mode: AppColors.textPrimaryDark (0xFFE2E8F0)
  Color get textColor => isDarkMode
      ? AppColors.textPrimaryDark
      : AppColors.textPrimaryLight;

  /// Get theme-aware secondary text color
  ///
  /// Returns:
  /// - Light mode: AppColors.textSecondaryLight (0xFF4A5568)
  /// - Dark mode: AppColors.textSecondaryDark (0xFFA0AEC0)
  Color get textColorSecondary => isDarkMode
      ? AppColors.textSecondaryDark
      : AppColors.textSecondaryLight;

  /// Get theme-aware tertiary text color (hint text, disabled text)
  ///
  /// Returns:
  /// - Light mode: AppColors.textTertiaryLight (0xFF718096)
  /// - Dark mode: AppColors.textTertiaryDark (0xFF718096)
  Color get textColorTertiary => isDarkMode
      ? AppColors.textTertiaryDark
      : AppColors.textTertiaryLight;

  // ============================================================================
  // BORDER & DIVIDER COLORS
  // ============================================================================

  /// Get theme-aware border color
  ///
  /// Returns:
  /// - Light mode: AppColors.borderLight (0xFFE2E8F0)
  /// - Dark mode: AppColors.borderDark (0xFF2D3748 - better contrast with black)
  Color get borderColor => isDarkMode
      ? AppColors.borderDark
      : AppColors.borderLight;

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================

  /// Get theme-aware warning color
  Color get warningColor => AppColors.warning;

  /// Get theme-aware success color
  Color get successColor => AppColors.success;

  /// Get theme-aware info color
  Color get infoColor => AppColors.info;

  /// Get theme-aware divider color
  ///
  /// Returns:
  /// - Light mode: AppColors.dividerLight (0xFFF7FAFC)
  /// - Dark mode: AppColors.dividerDark (0xFF1E1E1E - subtle, not harsh)
  Color get dividerColor => isDarkMode
      ? AppColors.dividerDark
      : AppColors.dividerLight;

  // ============================================================================
  // ICON COLORS
  // ============================================================================

  /// Get theme-aware icon color (same as primary text color)
  Color get iconColor => textColor;

  /// Get theme-aware icon color for secondary icons
  Color get iconColorSecondary => textColorSecondary;

  // ============================================================================
  // ELEVATION & SHADOW COLORS
  // ============================================================================

  /// Get theme-aware elevation color for cards at level 1 (1dp)
  Color get elevation1Color => isDarkMode
      ? AppColors.elevation1Dark
      : AppColors.elevation1Light;

  /// Get theme-aware elevation color for level 2 (2dp)
  Color get elevation2Color => isDarkMode
      ? AppColors.elevation2Dark
      : AppColors.elevation2Light;

  /// Get theme-aware shadow color for subtle shadows
  Color get shadowColor => isDarkMode
      ? Colors.black.withValues(alpha: 0.3)
      : Colors.black.withValues(alpha: 0.1);

  /// Get theme-aware shadow color for prominent shadows
  Color get shadowColorProminent => isDarkMode
      ? Colors.black.withValues(alpha: 0.5)
      : Colors.black.withValues(alpha: 0.2);

  // ============================================================================
  // SCRIM & OVERLAY COLORS
  // ============================================================================

  /// Get theme-aware scrim color for modal backdrops
  Color get scrimColor => isDarkMode
      ? AppColors.scrimDark
      : AppColors.scrimLight;

  /// Get theme-aware blur backdrop color for glass morphism
  Color get blurBackdropColor => isDarkMode
      ? AppColors.blurBackdropDark
      : AppColors.blurBackdropLight;

  // ============================================================================
  // INVERTED COLORS (for buttons on primary background)
  // ============================================================================

  /// Get inverted text color (for text on primary colored backgrounds)
  ///
  /// Returns:
  /// - Light mode: Colors.white
  /// - Dark mode: Colors.black
  Color get textColorInverted => isDarkMode ? Colors.black : Colors.white;

  /// Get inverted icon color
  Color get iconColorInverted => textColorInverted;

  // ============================================================================
  // GRADIENT OVERLAY COLORS
  // ============================================================================

  /// Get text color for colored gradient backgrounds
  ///
  /// Always returns white for consistent contrast on both:
  /// - Light mode: Purple/Blue gradients (dark backgrounds)
  /// - Dark mode: Dark gray gradients (dark backgrounds)
  Color get onGradientColor => Colors.white;

  /// Get icon color for colored gradient backgrounds
  Color get onGradientIconColor => Colors.white;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get color with theme-aware opacity
  ///
  /// Useful for creating hover, pressed, or disabled states
  ///
  /// Example:
  /// ```dart
  /// color: context.getColorWithOpacity(context.textColor, 0.5)
  /// ```
  Color getColorWithOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Get theme-aware text color with opacity
  Color textWithOpacity(double opacity) {
    return textColor.withValues(alpha: opacity);
  }

  /// Get theme-aware surface color with opacity
  Color surfaceWithOpacity(double opacity) {
    return surfaceColor.withValues(alpha: opacity);
  }
}

/// Extension for common ColorScheme access
extension ThemeColorScheme on BuildContext {
  /// Get current ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Primary color
  Color get primaryColor => colorScheme.primary;

  /// Primary container color
  Color get primaryContainerColor => colorScheme.primaryContainer;

  /// On primary color (text/icons on primary background)
  Color get onPrimaryColor => colorScheme.onPrimary;

  /// Secondary color
  Color get secondaryColor => colorScheme.secondary;

  /// Secondary container color
  Color get secondaryContainerColor => colorScheme.secondaryContainer;

  /// On secondary color
  Color get onSecondaryColor => colorScheme.onSecondary;

  /// Error color
  Color get errorColor => colorScheme.error;

  /// On error color
  Color get onErrorColor => colorScheme.onError;

  /// Outline color (for borders)
  Color get outlineColor => colorScheme.outline;
}

/// Extension for conditional theme values
extension ThemeConditional on BuildContext {
  /// Get value based on current theme
  ///
  /// Example:
  /// ```dart
  /// final padding = context.themeValue(light: 16.0, dark: 20.0);
  /// ```
  T themeValue<T>({required T light, required T dark}) {
    return isDarkMode ? dark : light;
  }

  /// Get optional value based on theme (returns light value if dark is null)
  T themeValueOr<T>({required T light, T? dark}) {
    return isDarkMode ? (dark ?? light) : light;
  }
}
