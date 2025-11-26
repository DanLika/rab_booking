import 'package:flutter/material.dart';

/// Helper class for theme-aware color selection in booking widget.
///
/// Provides utilities to select between light and dark theme colors
/// without creating adapter instances each time.
///
/// Usage:
/// ```dart
/// final isDarkMode = ref.watch(themeProvider);
///
/// // Option 1: Static method (recommended for single use)
/// final bgColor = ThemeColorsHelper.getColor(
///   isDarkMode: isDarkMode,
///   light: MinimalistColors.backgroundPrimary,
///   dark: MinimalistColorsDark.backgroundPrimary,
/// );
///
/// // Option 2: Create a getter function (recommended for multiple uses)
/// final getColor = ThemeColorsHelper.createColorGetter(isDarkMode);
/// final bgColor = getColor(MinimalistColors.backgroundPrimary, MinimalistColorsDark.backgroundPrimary);
/// final textColor = getColor(MinimalistColors.textPrimary, MinimalistColorsDark.textPrimary);
/// ```
class ThemeColorsHelper {
  ThemeColorsHelper._(); // Private constructor to prevent instantiation

  /// Returns the appropriate color based on the current theme mode.
  ///
  /// [isDarkMode] - Whether dark mode is active
  /// [light] - Color to use in light mode
  /// [dark] - Color to use in dark mode
  static Color getColor({
    required bool isDarkMode,
    required Color light,
    required Color dark,
  }) {
    return isDarkMode ? dark : light;
  }

  /// Creates a color getter function that captures the theme mode.
  ///
  /// Useful when you need to get multiple theme-aware colors
  /// without repeating the isDarkMode parameter.
  ///
  /// Returns a function with signature: `Color Function(Color light, Color dark)`
  static Color Function(Color light, Color dark) createColorGetter(
    bool isDarkMode,
  ) {
    return (Color light, Color dark) => isDarkMode ? dark : light;
  }
}
