import 'package:flutter/material.dart';

/// Centralized dialog colors utility for consistent theming across all dialogs
/// Provides theme-aware colors for success, error, warning, info states
/// and ensures all dialogs work correctly in both light and dark modes
class DialogColors {
  /// Get success colors (green) for dialog alerts/banners
  static Color getSuccessBackground(BuildContext context, {bool subtle = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (subtle) {
      return isDark
          ? const Color(0xFF1B5E20).withValues(alpha: 0.3) // Dark green transparent
          : const Color(0xFFE8F5E9); // Light green (green[50])
    }
    return isDark ? const Color(0xFF2E7D32) : const Color(0xFF81C784); // green[200]
  }

  static Color getSuccessBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF4CAF50) : const Color(0xFF66BB6A); // green[700] / green[400]
  }

  static Color getSuccessText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32); // green[200] / green[800]
  }

  /// Get error colors (red) for dialog alerts/banners
  static Color getErrorBackground(BuildContext context, {bool subtle = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (subtle) {
      return isDark
          ? const Color(0xFFB71C1C).withValues(alpha: 0.3) // Dark red transparent
          : const Color(0xFFFFEBEE); // Light red (red[50])
    }
    return isDark ? const Color(0xFFC62828) : const Color(0xFFEF9A9A); // red[200]
  }

  static Color getErrorBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFEF5350) : const Color(0xFFE53935); // red[400] / red[600]
  }

  static Color getErrorText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828); // red[200] / red[800]
  }

  /// Get warning colors (orange/amber) for dialog alerts/banners
  static Color getWarningBackground(BuildContext context, {bool subtle = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (subtle) {
      return isDark
          ? const Color(0xFFE65100).withValues(alpha: 0.3) // Dark orange transparent
          : const Color(0xFFFFF3E0); // Light orange (orange[50])
    }
    return isDark ? const Color(0xFFF57C00) : const Color(0xFFFFCC80); // orange[200]
  }

  static Color getWarningBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFFFB74D) : const Color(0xFFFB8C00); // orange[300] / orange[600]
  }

  static Color getWarningText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFFFCC80) : const Color(0xFFE65100); // orange[200] / orange[900]
  }

  /// Get info colors (blue) for dialog alerts/banners
  static Color getInfoBackground(BuildContext context, {bool subtle = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (subtle) {
      return isDark
          ? const Color(0xFF0D47A1).withValues(alpha: 0.3) // Dark blue transparent
          : const Color(0xFFE3F2FD); // Light blue (blue[50])
    }
    return isDark ? const Color(0xFF1976D2) : const Color(0xFF90CAF9); // blue[200]
  }

  static Color getInfoBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF64B5F6) : const Color(0xFF1E88E5); // blue[300] / blue[600]
  }

  static Color getInfoText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF90CAF9) : const Color(0xFF0D47A1); // blue[200] / blue[900]
  }

  /// Get neutral/grey colors for subtle backgrounds and borders
  static Color getNeutralBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF424242) : const Color(0xFFFAFAFA); // grey[800] / grey[50]
  }

  static Color getNeutralBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF616161) : const Color(0xFFE0E0E0); // grey[700] / grey[300]
  }

  static Color getNeutralText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575); // grey[400] / grey[600]
  }

  /// Get code/monospace background (for embed code displays)
  static Color getCodeBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5); // Dark grey / grey[100]
  }

  static Color getCodeBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0); // grey[800] / grey[300]
  }

  /// Get progress indicator color (white for dark backgrounds, primary for light)
  static Color getProgressColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : Theme.of(context).colorScheme.primary;
  }

  /// Get snackbar background color
  static Color getSnackBarBackground(BuildContext context, {required bool isError}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isError) {
      return isDark ? const Color(0xFFD32F2F) : const Color(0xFFC62828); // red[700] / red[800]
    }
    return isDark ? const Color(0xFF388E3C) : const Color(0xFF2E7D32); // green[700] / green[800]
  }
}
