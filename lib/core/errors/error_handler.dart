import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'app_exceptions.dart';
import '../services/logging_service.dart';

/// Utility class for handling errors and converting them to user-friendly messages
class ErrorHandler {
  /// Convert technical errors to user-friendly messages in Croatian/Serbian
  static String getUserFriendlyMessage(dynamic error) {
    if (error is NetworkException) {
      return 'Provjerite internet konekciju i pokušajte ponovo.';
    } else if (error is AuthException) {
      return 'Greška prilikom autentifikacije. Molimo prijavite se ponovo.';
    } else if (error is DatabaseException) {
      return 'Greška u bazi podataka. Pokušajte ponovo.';
    } else if (error is ValidationException) {
      return error.message;
    } else if (error is PaymentException) {
      return 'Greška prilikom plaćanja: ${error.message}';
    } else if (error is BookingException) {
      return error.message;
    } else if (error is NotFoundException) {
      return 'Traženi resurs nije pronađen.';
    } else if (error is ConflictException) {
      return 'Konflikt podataka. ${error.message}';
    } else if (error is TimeoutException) {
      return 'Operacija je istekla. Pokušajte ponovo.';
    } else if (error is AuthorizationException) {
      return 'Nemate dozvolu za ovu akciju.';
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
    if (kReleaseMode) {
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
      // );
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
