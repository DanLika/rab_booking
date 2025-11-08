import 'package:flutter/material.dart';

/// Centralized helper for creating consistent InputDecoration across the app
class InputDecorationHelper {
  InputDecorationHelper._();

  /// Creates modern input decoration for form fields
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withAlpha((0.3 * 255).toInt()),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.error,
          width: 2,
        ),
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
