import 'package:flutter/material.dart';

/// Centralized SnackBar helper for consistent styling and auto-dismiss functionality
/// Uses theme-aware colors with automatic light/dark mode detection
class SnackBarHelper {
  SnackBarHelper._();

  /// Show a success SnackBar with theme-aware colors
  /// Automatically dismisses any previous snackbar before showing the new one
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: isDark
          ? const Color(0xFF2D5A47) // Dark green
          : const Color(0xFFD4EDDA), // Light green
      textColor: isDark ? Colors.white : const Color(0xFF155724),
      icon: Icons.check_circle_outline,
      duration: duration,
    );
  }

  /// Show an error SnackBar with theme-aware colors
  /// Automatically dismisses any previous snackbar before showing the new one
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: isDark
          ? const Color(0xFF5A2D2D) // Dark red
          : const Color(0xFFF8D7DA), // Light red/pink
      textColor: isDark ? Colors.white : const Color(0xFF721C24),
      icon: Icons.error_outline,
      duration: duration,
    );
  }

  /// Show an info SnackBar with theme-aware colors
  /// Automatically dismisses any previous snackbar before showing the new one
  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: isDark
          ? const Color(0xFF2D4A5A) // Dark blue
          : const Color(0xFFD1ECF1), // Light blue
      textColor: isDark ? Colors.white : const Color(0xFF0C5460),
      icon: Icons.info_outline,
      duration: duration,
    );
  }

  /// Show a warning SnackBar with theme-aware colors
  /// Automatically dismisses any previous snackbar before showing the new one
  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: isDark
          ? const Color(0xFF5A4A2D) // Dark amber
          : const Color(0xFFFFF3CD), // Light amber
      textColor: isDark ? Colors.white : const Color(0xFF856404),
      icon: Icons.warning_amber_rounded,
      duration: duration,
    );
  }

  /// Internal helper to show SnackBar with consistent styling
  /// Clears all snackbars before showing new one
  static void _showSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
    required Duration duration,
  }) {
    try {
      // Get ScaffoldMessenger safely
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) {
        // If no ScaffoldMessenger available, print to console as fallback
        return;
      }

      // Clear ALL snackbars (queue + current) to ensure new one is always shown
      // This fixes the issue where repeated taps wouldn't show the snackbar
      messenger.clearSnackBars();

      // Show new snackbar - no need to track reference, ScaffoldMessenger handles lifecycle
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                icon,
                color: textColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
          duration: duration,
          elevation: 4,
        ),
      );
    } catch (e) {
      // Gracefully handle snackbar display errors (e.g., empty scaffold queue in dialogs)
      // This prevents "Bad state: No element" crashes when showing snackbars in dialog contexts
    }
  }

  /// Dismiss all current snackbars
  static void dismissAll(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
  }
}
