import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Extension to add custom brand colors to ColorScheme
///
/// This provides convenient access to brand colors via ColorScheme.
/// All colors reference [AppColors] constants for single source of truth.
///
/// Usage:
/// ```dart
/// final color = Theme.of(context).colorScheme.brandPurple;
/// ```
extension AppColorExtensions on ColorScheme {
  /// Primary brand purple color
  /// Used for: primary buttons, accents, highlights
  Color get brandPurple => AppColors.primary;

  /// Secondary brand blue color
  /// Used for: secondary buttons, gradients, accents
  Color get brandBlue => AppColors.authSecondary;

  /// Success/positive state color
  /// Used for: success messages, positive indicators
  Color get success => AppColors.success;

  /// Error/danger state color
  /// Used for: error messages, destructive actions, warnings
  Color get danger => AppColors.error;

  /// Warning state color
  /// Used for: warning messages, caution indicators
  Color get warning => AppColors.statusPending; // Amber 500

  /// Info state color
  /// Used for: informational messages, neutral indicators
  Color get info => AppColors.info;

  /// Light gray for backgrounds and borders
  /// Used for: card backgrounds, dividers, borders
  Color get lightGray => const Color(0xFFF3F4F6); // Not in AppColors

  /// Medium gray for text and icons
  /// Used for: secondary text, disabled states
  Color get mediumGray => AppColors.textDisabled;

  /// Dark gray for dark mode backgrounds
  /// Used for: dark mode surfaces, elevated cards
  Color get darkGray => AppColors.surfaceVariantDark;

  /// Very dark gray for dark mode
  /// Used for: dark mode page backgrounds, deep surfaces
  Color get veryDarkGray => const Color(0xFF1A1A1A); // Specific gradient color

  /// Medium dark gray for dark mode
  /// Used for: dark mode elevated surfaces
  Color get mediumDarkGray =>
      const Color(0xFF2D2D2D); // Specific gradient color

  /// Light gray for light mode backgrounds
  /// Used for: light mode page backgrounds, gradients
  Color get veryLightGray => AppColors.surfaceVariantLight;

  /// Beige for light mode backgrounds
  /// Used for: light mode drawer and warm backgrounds
  Color get beige => AppColors.authBackgroundStart;
}
