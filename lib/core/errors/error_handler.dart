import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../exceptions/app_exceptions.dart';
import '../services/logging_service.dart';

/// Utility class for handling errors and converting them to user-friendly messages
///
/// Usage:
/// ```dart
/// try {
///   await someOperation();
/// } catch (e, stackTrace) {
///   ErrorHandler.logError(e, stackTrace);
///   ErrorHandler.showErrorSnackBar(context, e);
/// }
/// ```
class ErrorHandler {
  // Prevent instantiation
  ErrorHandler._();

  /// Convert technical errors to user-friendly messages in Croatian/Serbian
  /// Uses getUserMessage() from AppException when available
  static String getUserFriendlyMessage(dynamic error) {
    // If it's an AppException, use its getUserMessage() method
    if (error is AppException) {
      final userMsg = error.getUserMessage();
      // If userMessage is set, use it; otherwise fall back to type-specific defaults
      if (error.userMessage != null) {
        return userMsg;
      }
    }

    // Type-specific fallback messages
    if (error is NetworkException) {
      return 'Provjerite internet konekciju i pokušajte ponovo.';
    } else if (error is AuthException) {
      return 'Greška prilikom autentifikacije. Molimo prijavite se ponovo.';
    } else if (error is DatabaseException) {
      return 'Greška u bazi podataka. Pokušajte ponovo.';
    } else if (error is ValidationException) {
      return error.getUserMessage();
    } else if (error is PaymentException) {
      return 'Došlo je do greške prilikom plaćanja. Molimo pokušajte ponovo.';
    } else if (error is BookingException) {
      return error.getUserMessage();
    } else if (error is NotFoundException) {
      return 'Traženi resurs nije pronađen.';
    } else if (error is ConflictException) {
      return 'Došlo je do konflikta u podacima. Molimo osvježite stranicu.';
    } else if (error is TimeoutException) {
      return 'Operacija je istekla. Pokušajte ponovo.';
    } else if (error is AuthorizationException) {
      return 'Nemate dozvolu za ovu akciju.';
    } else if (error is DatesNotAvailableException) {
      return error.getUserMessage();
    } else {
      return 'Došlo je do neočekivane greške. Pokušajte ponovo.';
    }
  }

  /// Show error message in a SnackBar
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getUserFriendlyMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Log error to console in debug mode and to error tracking service in production
  static Future<void> logError(dynamic error, StackTrace? stackTrace) async {
    // Log using LoggingService
    await LoggingService.logError(
      'ErrorHandler caught error',
      error,
      stackTrace,
    );

    // In production, send to error tracking service
    // NOTE: Crashlytics is NOT supported on web platform
    if (kReleaseMode && !kIsWeb) {
      // Send to Firebase Crashlytics
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'ErrorHandler caught error',
        information: [
          'source: ErrorHandler',
          'user_friendly_message: ${getUserFriendlyMessage(error)}',
        ],
        printDetails: false,
      );
    }
  }

  /// Show error dialog to user
  static void showErrorDialog(BuildContext context, dynamic error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Greška'),
        content: Text(getUserFriendlyMessage(error)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
