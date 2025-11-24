import 'package:flutter/material.dart';

/// Extension to add custom brand colors to ColorScheme
///
/// This centralizes all hardcoded color values used throughout the app,
/// making it easier to maintain consistency and update the brand colors.
extension AppColorExtensions on ColorScheme {
  /// Primary brand purple color
  /// Used for: primary buttons, accents, highlights
  Color get brandPurple => const Color(0xFF6B4CE6);

  /// Secondary brand blue color
  /// Used for: secondary buttons, gradients, accents
  Color get brandBlue => const Color(0xFF4A90E2);

  /// Success/positive state color
  /// Used for: success messages, positive indicators
  Color get success => const Color(0xFF10B981);

  /// Error/danger state color
  /// Used for: error messages, destructive actions, warnings
  Color get danger => const Color(0xFFEF4444);

  /// Warning state color
  /// Used for: warning messages, caution indicators
  Color get warning => const Color(0xFFF59E0B);

  /// Info state color
  /// Used for: informational messages, neutral indicators
  Color get info => const Color(0xFF3B82F6);

  /// Light gray for backgrounds and borders
  /// Used for: card backgrounds, dividers, borders
  Color get lightGray => const Color(0xFFF3F4F6);

  /// Medium gray for text and icons
  /// Used for: secondary text, disabled states
  Color get mediumGray => const Color(0xFF9CA3AF);

  /// Dark gray for dark mode backgrounds
  /// Used for: dark mode surfaces, elevated cards
  Color get darkGray => const Color(0xFF1E1E1E);

  /// Very dark gray for dark mode
  /// Used for: dark mode page backgrounds, deep surfaces
  Color get veryDarkGray => const Color(0xFF1A1A1A);

  /// Medium dark gray for dark mode
  /// Used for: dark mode elevated surfaces
  Color get mediumDarkGray => const Color(0xFF2D2D2D);

  /// Very light blue for light mode backgrounds
  /// Used for: light mode page backgrounds
  Color get veryLightGray => const Color(0xFFE8F4FF);

  /// Beige for light mode backgrounds
  /// Used for: light mode drawer and warm backgrounds
  Color get beige => const Color(0xFFFAF8F3);
}
