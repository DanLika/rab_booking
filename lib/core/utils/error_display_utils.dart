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
      horizontalMargin = ((screenWidth - _preferredMaxWidth) / 2).clamp(16.0, double.infinity);
    } else {
      // Mobile or small desktop: standard margins
      horizontalMargin = 16.0;
    }

    return SnackBar(
      content: content,
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 16, left: horizontalMargin, right: horizontalMargin),
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
        Expanded(child: Text(message, style: TextStyle(color: textColor))),
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
            ? SnackBarAction(label: 'Pokušaj ponovo', textColor: Colors.white, onPressed: onRetry)
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
            ? SnackBarAction(label: actionLabel, textColor: Colors.white, onPressed: onAction)
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
  static void showLoadingSnackBar(
    BuildContext context,
    String message,
  ) {
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
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.info,
        duration: const Duration(seconds: 30), // Long duration, manually dismissed
      ),
    );
  }

  /// Extract user-friendly error message
  /// In release mode, hides technical details
  static String _getUserFriendlyMessage(dynamic error, String? userMessage) {
    // If custom user message provided, use it
    if (userMessage != null && userMessage.isNotEmpty) {
      return userMessage;
    }

    // Handle null error case
    if (error == null) {
      return 'Došlo je do greške. Pokušajte ponovo ili kontaktirajte podršku.';
    }

    // In debug mode, show full error for developers
    if (kDebugMode) {
      try {
        return error.toString();
      } catch (e) {
        return 'Error: Unable to display error details';
      }
    }

    // In release mode, provide user-friendly messages
    String errorString;
    try {
      errorString = error.toString().toLowerCase();
    } catch (e) {
      return 'Došlo je do greške. Pokušajte ponovo ili kontaktirajte podršku.';
    }

    // Firebase errors
    if (errorString.contains('permission-denied') || errorString.contains('permission denied')) {
      return 'Nemate dozvolu za ovu akciju. Kontaktirajte administratora.';
    }
    if (errorString.contains('not-found') || errorString.contains('not found')) {
      return 'Traženi podaci nisu pronađeni.';
    }
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Greška u vezi s mrežom. Provjerite internet vezu.';
    }
    if (errorString.contains('timeout')) {
      return 'Operacija je istekla. Pokušajte ponovo.';
    }
    if (errorString.contains('already exists')) {
      return 'Podaci već postoje u sustavu.';
    }
    if (errorString.contains('invalid')) {
      return 'Neispravni podaci. Provjerite unesene vrijednosti.';
    }

    // Authentication errors
    if (errorString.contains('email-already-in-use')) {
      return 'Email adresa je već u upotrebi.';
    }
    if (errorString.contains('user-not-found')) {
      return 'Korisnik nije pronađen.';
    }
    if (errorString.contains('wrong-password')) {
      return 'Neispravna lozinka.';
    }
    if (errorString.contains('too-many-requests')) {
      return 'Previše pokušaja. Pokušajte kasnije.';
    }

    // Booking errors
    if (errorString.contains('overlap') || errorString.contains('preklapaju')) {
      return 'Izabrani datumi se preklapaju s postojećom rezervacijom.';
    }
    if (errorString.contains('past date')) {
      return 'Ne možete kreirati rezervaciju u prošlosti.';
    }
    if (errorString.contains('unit') && errorString.contains('not available')) {
      return 'Odabrana jedinica nije dostupna za izabrane datume.';
    }

    // Generic error
    return 'Došlo je do greške. Pokušajte ponovo ili kontaktirajte podršku.';
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
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
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
