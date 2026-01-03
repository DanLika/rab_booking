import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility for displaying user-friendly error messages
/// Hides technical details (stack traces) from users in production
class ErrorDisplayUtils {
  ErrorDisplayUtils._(); // Private constructor

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
      SnackBar(
        content: Text(displayMessage),
        backgroundColor: const Color(0xFFEF5350), // Red
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF66BB6A), // Green
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: duration,
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
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFFA726), // Orange
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF42A5F5), // Blue
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
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
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 30), // Long duration, manually dismissed
        backgroundColor: const Color(0xFF42A5F5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

    // In debug mode, show full error for developers
    if (kDebugMode) {
      return error.toString();
    }

    // In release mode, provide user-friendly messages
    final errorString = error.toString().toLowerCase();

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
