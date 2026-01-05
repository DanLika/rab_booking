import 'package:flutter/material.dart';

/// Snackbar color scheme matching calendar status colors for visual consistency
/// Success → Available (green), Error → Booked (red), Warning → Pending (amber)
class SnackBarColors {
  SnackBarColors._();

  // Light theme colors (matching calendar status colors)
  static const Color successLight = Color(
    0xFF10B981,
  ); // Emerald 500 - harmonizes with available #83e6bf
  static const Color errorLight = Color(
    0xFFEF4444,
  ); // Red - matches booked border #ef4444
  static const Color warningLight = Color(
    0xFFF59E0B,
  ); // Amber 500 - matches pending border #F59E0B
  static const Color infoLight = Color(0xFF3B82F6); // Blue 500 - standard info

  // Dark theme colors (slightly lighter for visibility on dark backgrounds)
  static const Color successDark = Color(0xFF34D399); // Emerald 400
  static const Color errorDark = Color(0xFFF87171); // Red 400
  static const Color warningDark = Color(0xFFFBBF24); // Amber 400
  static const Color infoDark = Color(0xFF60A5FA); // Blue 400
}

/// Minimal SnackBar helper for showing themed snackbars
/// Uses calendar-consistent colors for visual language continuity
class SnackBarHelper {
  SnackBarHelper._();

  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context: context,
      message: message,
      backgroundColor: isDark
          ? SnackBarColors.successDark
          : SnackBarColors.successLight,
      icon: Icons.check_circle_outline,
      duration: duration,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context: context,
      message: message,
      backgroundColor: isDark
          ? SnackBarColors.errorDark
          : SnackBarColors.errorLight,
      icon: Icons.error_outline,
      duration: duration,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context: context,
      message: message,
      backgroundColor: isDark
          ? SnackBarColors.warningDark
          : SnackBarColors.warningLight,
      icon: Icons.warning_amber_outlined,
      duration: duration,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context: context,
      message: message,
      backgroundColor: isDark
          ? SnackBarColors.infoDark
          : SnackBarColors.infoLight,
      icon: Icons.info_outline,
      duration: duration,
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    // Always hide previous snackbar to prevent stacking
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment:
              MainAxisAlignment.center, // Center content horizontally
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center, // Center text
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: duration,
        elevation: 4,
      ),
    );
  }
}
