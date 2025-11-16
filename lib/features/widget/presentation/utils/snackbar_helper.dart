import 'package:flutter/material.dart';
import '../theme/minimalist_colors.dart';

/// Centralized SnackBar helper for consistent styling and auto-dismiss functionality
/// Uses theme-aware colors based on "booked" color scheme (#83e6bf)
class SnackBarHelper {
  // Keep track of current snackbar controller for auto-dismiss
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _currentSnackBar;

  /// Show a success SnackBar with theme-aware colors
  /// Automatically dismisses any previous snackbar before showing the new one
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    bool isDarkMode = false,
  }) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: isDarkMode
          ? MinimalistColorsDark.statusAvailableBackground  // #83e6bf with dark mode adjustment
          : MinimalistColors.statusAvailableBackground,      // #83e6bf
      textColor: isDarkMode
          ? MinimalistColorsDark.textPrimary
          : MinimalistColors.textPrimary,
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
    bool isDarkMode = false,
  }) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: isDarkMode
          ? MinimalistColorsDark.error
          : MinimalistColors.error,
      textColor: Colors.white,
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
    bool isDarkMode = false,
  }) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: isDarkMode
          ? MinimalistColorsDark.backgroundCard
          : MinimalistColors.backgroundCard,
      textColor: isDarkMode
          ? MinimalistColorsDark.textPrimary
          : MinimalistColors.textPrimary,
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
    bool isDarkMode = false,
  }) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: isDarkMode
          ? MinimalistColorsDark.warning
          : MinimalistColors.warning,
      textColor: isDarkMode
          ? MinimalistColorsDark.textPrimary
          : MinimalistColors.textPrimary,
      icon: Icons.warning_amber_rounded,
      duration: duration,
    );
  }

  /// Internal helper to show SnackBar with consistent styling
  /// Auto-dismisses previous snackbar before showing new one
  static void _showSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
    required Duration duration,
  }) {
    // Dismiss any existing snackbar first
    _currentSnackBar?.close();

    // Show new snackbar
    _currentSnackBar = ScaffoldMessenger.of(context).showSnackBar(
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
  }

  /// Manually dismiss current snackbar if needed
  static void dismiss() {
    _currentSnackBar?.close();
    _currentSnackBar = null;
  }
}
