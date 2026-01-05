import 'package:flutter/material.dart';

import 'app_gradients.dart';

/// BuildContext extension for easy gradient access
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     gradient: context.gradients.pageBackground,
///   ),
/// )
/// ```
extension GradientExtension on BuildContext {
  /// Access theme-aware gradients
  ///
  /// Returns the [AppGradients] instance for the current theme (light/dark).
  /// Automatically switches gradients when theme changes.
  ///
  /// If the theme doesn't have AppGradients extension (e.g., widget themes),
  /// returns the appropriate default based on brightness to prevent crashes.
  ///
  /// Available gradients:
  /// - `pageBackground` - For screen body backgrounds (topLeft → bottomRight)
  /// - `sectionBackground` - For cards/sections (topRight → bottomLeft)
  /// - `brandPrimary` - For AppBar, headers, primary buttons
  ///
  /// Example:
  /// ```dart
  /// Container(
  ///   decoration: BoxDecoration(
  ///     gradient: context.gradients.pageBackground,
  ///   ),
  /// )
  /// ```
  AppGradients get gradients {
    final extension = Theme.of(this).extension<AppGradients>();
    if (extension != null) {
      return extension;
    }
    // Fallback for themes without AppGradients (e.g., MinimalistTheme in widget)
    // Use default gradients based on current brightness
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? AppGradients.dark : AppGradients.light;
  }
}
