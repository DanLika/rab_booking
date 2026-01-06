import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Utility for displaying user-friendly error messages
/// Hides technical details (stack traces) from users in production
///
/// Snackbar color palette (Mediterranean theme):
/// - Success: Emerald (#10B981) - White text + check_circle icon
/// - Error: Red (#EF4444) - White text + error_outline icon
/// - Warning: Orange (#F97316) - Dark text + warning_amber icon
/// - Info: Blue (#3B82F6) - White text + info_outline icon
///
/// All snackbars use:
/// - SnackBarBehavior.floating for proper z-index
/// - Constrained width on desktop (max 400px) for cleaner appearance
/// - Auto-dismiss previous snackbar before showing new one
/// - Consistent 12px border radius
class ErrorDisplayUtils {
  ErrorDisplayUtils._(); // Private constructor

  // Standard snackbar elevation for floating effect
  static const double _snackBarElevation = 6;

  // Preferred max width for desktop snackbars (content-based, not forced)
  static const double _preferredMaxWidth = 500.0;

  // Breakpoint for desktop layout
  static const double _desktopBreakpoint = 600.0;

  /// Build a styled snackbar with consistent appearance
  /// Uses margin-based positioning to prevent full-width on desktop
  static SnackBar _buildSnackBar({
    required BuildContext context,
    required Widget content,
    required Color backgroundColor,
    required Duration duration,
    SnackBarAction? action,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _desktopBreakpoint;

    // Calculate horizontal margin to achieve max width effect on desktop
    // This allows content to expand naturally while capping max width
    final double horizontalMargin;
    if (isDesktop && screenWidth > _preferredMaxWidth) {
      // Center snackbar with calculated margins to cap max width
      horizontalMargin = ((screenWidth - _preferredMaxWidth) / 2).clamp(
        16.0,
        double.infinity,
      );
    } else {
      // Mobile or small desktop: standard margins
      horizontalMargin = 16.0;
    }

    return SnackBar(
      content: content,
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(
        bottom: 16,
        left: horizontalMargin,
        right: horizontalMargin,
      ),
      elevation: _snackBarElevation,
      duration: duration,
      action: action,
    );
  }

  /// Build snackbar content row with icon and text
  static Widget _buildContent({
    required IconData icon,
    required String message,
    required Color iconColor,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message, style: TextStyle(color: textColor)),
        ),
      ],
    );
  }

  /// Show error snackbar with user-friendly message
  /// Hides stack traces and technical details in release mode
  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    String? userMessage,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    // Extract user-friendly message
    final displayMessage = _getUserFriendlyMessage(error, userMessage);

    messenger.showSnackBar(
      _buildSnackBar(
        context: context,
        content: _buildContent(
          icon: Icons.error_outline,
          message: displayMessage,
          iconColor: Colors.white,
          textColor: Colors.white,
        ),
        backgroundColor: AppColors.error,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Pokušaj ponovo',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show success snackbar
  /// Optional [actionLabel] and [onAction] for undo-style actions
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      _buildSnackBar(
        context: context,
        content: _buildContent(
          icon: Icons.check_circle_outline,
          message: message,
          iconColor: Colors.white,
          textColor: Colors.white,
        ),
        backgroundColor: AppColors.success,
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Show warning snackbar
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      _buildSnackBar(
        context: context,
        content: _buildContent(
          icon: Icons.warning_amber_outlined,
          message: message,
          iconColor: AppColors.textOnWarning,
          textColor: AppColors.textOnWarning,
        ),
        backgroundColor: AppColors.warning,
        duration: duration,
      ),
    );
  }

  /// Show info snackbar
  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      _buildSnackBar(
        context: context,
        content: _buildContent(
          icon: Icons.info_outline,
          message: message,
          iconColor: Colors.white,
          textColor: Colors.white,
        ),
        backgroundColor: AppColors.info,
        duration: duration,
      ),
    );
  }

  /// Show loading snackbar (dismissible by calling clearSnackBars)
  static void showLoadingSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      _buildSnackBar(
        context: context,
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: AppColors.info,
        duration: const Duration(
          seconds: 30,
        ), // Long duration, manually dismissed
      ),
    );
  }

  /// Extract user-friendly error message
  /// In release mode, hides technical details
  /// Uses localization if context is available (passed via BuildContext in calling method)
  static String _getUserFriendlyMessage(dynamic error, String? userMessage) {
    // If custom user message provided, use it
    if (userMessage != null && userMessage.isNotEmpty) {
      return userMessage;
    }

    // Handle null error case - return error string directly
    // (In production, caller should provide userMessage)
    if (error == null) {
      return 'An error occurred. Please try again';
    }

    // In debug mode, show full error for developers
    if (kDebugMode) {
      try {
        return error.toString();
      } catch (e) {
        return 'Error: Unable to display error details';
      }
    }

    // In release mode, return a generic message to avoid leaking implementation details.
    // The calling code should provide a user-friendly `userMessage` for specific errors.
    return 'An error occurred. Please try again';
  }

  /// Show error dialog for critical errors
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) async {
    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zatvori'),
          ),
          if (onRetry != null)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Pokušaj ponovo'),
            ),
        ],
      ),
    );
  }
}
