import 'package:flutter/material.dart';

/// Centralized helper for creating consistent InputDecoration across the app
class InputDecorationHelper {
  InputDecorationHelper._();

  /// Creates modern input decoration for form fields
  /// Matches Cjenovnik tab styling: borderRadius 12, default theme borders
  static InputDecoration buildDecoration(
    BuildContext context, {
    required String labelText,
    String? hintText,
    String? helperText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isMobile = false,
  }) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      // Match Cjenovnik tab: borderRadius 12, use theme default colors
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: theme.cardColor,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 12 : 16,
      ),
    );
  }

  /// Creates filter-specific input decoration (simplified variant)
  static InputDecoration buildFilterDecoration(
    BuildContext context, {
    required String labelText,
    Widget? prefixIcon,
    bool isMobile = false,
  }) {
    return buildDecoration(
      context,
      labelText: labelText,
      prefixIcon: prefixIcon,
      isMobile: isMobile,
    );
  }
}
