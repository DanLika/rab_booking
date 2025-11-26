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
  AppGradients get gradients => Theme.of(this).extension<AppGradients>()!;
}
