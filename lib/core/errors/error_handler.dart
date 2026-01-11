import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../l10n/app_localizations.dart';
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

  /// Convert technical errors to user-friendly messages
  /// Uses [AppLocalizations] if provided, otherwise falls back to English or hardcoded defaults.
  static String getUserFriendlyMessage(dynamic error, [AppLocalizations? l10n]) {
    // Helper to return localized string or fallback
    String loc(String Function(AppLocalizations) selector, String fallback) {
      if (l10n != null) {
        return selector(l10n);
      }
      return fallback;
    }

    // If it's an AppException with a specific userMessage, prioritize it?
    // Ideally, we want localized messages. If userMessage is hardcoded in Croatian,
    // we should prefer the localized version based on type/code if available.
    // However, if the exception carries a dynamic message from backend, we might need to use it.
    // Strategy: Check type/code first for standard errors.

    if (error is NetworkException) {
      return loc((l) => l.errorNetworkFailed, 'Network error. Please check your internet connection');
    } else if (error is TimeoutException) {
      return loc((l) => l.errorTimeout, 'Operation timed out. Please try again');
    } else if (error is AuthException) {
       // Check for specific auth codes if available, otherwise generic
       if (error.code == 'auth/user-not-found') return loc((l) => l.authErrorUserNotFound, 'No account found with this email');
       if (error.code == 'auth/wrong-password') return loc((l) => l.authErrorWrongPassword, 'Incorrect password');
       if (error.code == 'auth/email-already-in-use') return loc((l) => l.errorEmailInUse, 'Email already in use');
       if (error.code == 'auth/invalid-email') return loc((l) => l.authErrorInvalidEmail, 'Invalid email address');
       if (error.code == 'auth/user-disabled') return loc((l) => l.authErrorUserDisabled, 'Account disabled');
       if (error.code == 'auth/too-many-requests') return loc((l) => l.authErrorTooManyRequests, 'Too many attempts');

       return loc((l) => l.authErrorGeneric, 'Authentication failed. Please login again.');
    } else if (error is DatabaseException) {
      return loc((l) => l.errorGeneric, 'Database error. Please try again.');
    } else if (error is ValidationException) {
      return error.getUserMessage(); // Validation messages are often specific fields
    } else if (error is NotFoundException) {
      return loc((l) => l.errorNotFound, 'Requested resource not found.');
    } else if (error is ConflictException) {
      return loc((l) => l.errorAlreadyExists, 'Conflict occurred.');
    } else if (error is AuthorizationException || error is PermissionException) {
      return loc((l) => l.errorPermissionDenied, 'Permission denied.');
    } else if (error is DatesNotAvailableException) {
       return loc((l) => l.widgetDatesNotAvailable, 'Selected dates are not available');
    }

    // Check for string errors that might be thrown directly (legacy)
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return loc((l) => l.errorNetworkFailed, 'Network error.');
    }
    if (errorStr.contains('timeout')) {
      return loc((l) => l.errorTimeout, 'Timeout.');
    }

    // Default fallback
    if (error is AppException && error.userMessage != null) {
      return error.userMessage!;
    }

    return loc((l) => l.errorGeneric, 'An unexpected error occurred. Please try again.');
  }

  /// Show error message in a SnackBar
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final l10n = AppLocalizations.of(context);
    final message = getUserFriendlyMessage(error, l10n);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: l10n.ok,
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
          // We don't have context here, so we get english/default message
          'user_friendly_message: ${getUserFriendlyMessage(error)}',
        ],
        printDetails: false,
      );
    }
  }

  /// Show error dialog to user
  static void showErrorDialog(BuildContext context, dynamic error) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.error),
        content: Text(getUserFriendlyMessage(error, l10n)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}
