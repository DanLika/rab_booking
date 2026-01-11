import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../errors/error_handler.dart';

/// Utility for displaying user-friendly error messages
/// Hides technical details (stack traces) from users in production
class ErrorDisplayUtils {
  ErrorDisplayUtils._(); // Private constructor

  // Standard snackbar elevation for floating effect
  static const double _snackBarElevation = 6;

  // Preferred max width for desktop snackbars (content-based, not forced)
  static const double _preferredMaxWidth = 500.0;

  // Breakpoint for desktop layout
  static const double _desktopBreakpoint = 600.0;

  /// Build a styled snackbar with consistent appearance
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
    final double horizontalMargin;
    if (isDesktop && screenWidth > _preferredMaxWidth) {
      horizontalMargin = ((screenWidth - _preferredMaxWidth) / 2).clamp(
        16.0,
        double.infinity,
      );
    } else {
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

    final l10n = AppLocalizations.of(context);

    // Extract user-friendly message using ErrorHandler and localization
    final displayMessage = userMessage ?? ErrorHandler.getUserFriendlyMessage(error, l10n);

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
                label: l10n.retry,
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show success snackbar
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

  /// Show error dialog for critical errors
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) async {
    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context);

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
            child: Text(l10n.close),
          ),
          if (onRetry != null)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text(l10n.retry),
            ),
        ],
      ),
    );
  }
}
