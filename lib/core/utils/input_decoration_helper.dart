import 'package:flutter/material.dart';

/// Centralized helper for creating consistent InputDecoration across the app
class InputDecorationHelper {
  InputDecorationHelper._();

  /// Creates modern input decoration for form fields
  /// Matches unit_pricing_screen styling: borderRadius 12, filled background
  static InputDecoration buildDecoration({
    required String labelText,
    String? hintText,
    String? helperText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isMobile = false,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 12 : 16,
      ),
    );
  }

  /// Creates filter-specific input decoration (simplified variant)
  static InputDecoration buildFilterDecoration({
    required String labelText,
    Widget? prefixIcon,
    bool isMobile = false,
    required BuildContext context,
  }) {
    return buildDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon,
      isMobile: isMobile,
      context: context,
    );
  }
}
