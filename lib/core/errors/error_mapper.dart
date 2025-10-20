import 'dart:io';
import 'dart:async' as dart_async;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import 'app_exceptions.dart';

/// Maps various exceptions to user-friendly AppException types
class ErrorMapper {
  ErrorMapper._(); // Private constructor

  /// Map any exception to an AppException with user-friendly message
  static AppException mapException(dynamic error, [StackTrace? stackTrace]) {
    // Already an AppException - return as is
    if (error is AppException) {
      return error;
    }

    // Network errors
    if (error is SocketException) {
      return NetworkException(
        message: 'Socket error: ${error.message}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is HttpException) {
      return NetworkException(
        message: 'HTTP error: ${error.message}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Supabase Auth errors
    if (error is supabase_flutter.AuthException) {
      return _mapAuthException(error, stackTrace);
    }

    // Supabase Storage errors
    if (error is supabase_flutter.StorageException) {
      return StorageException(
        message: 'Storage error: ${error.message}',
        userMessage: _getStorageErrorMessage(error),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Supabase Postgrest errors
    if (error is supabase_flutter.PostgrestException) {
      return _mapPostgrestException(error, stackTrace);
    }

    // Dart Async Timeout errors
    if (error is dart_async.TimeoutException) {
      return TimeoutException(
        message: 'Operation timed out',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Format exceptions (validation)
    if (error is FormatException) {
      return ValidationException(
        message: 'Format error: ${error.message}',
        userMessage: 'Invalid data format. Please check your input.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Unknown error
    return UnknownException(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Map Supabase AuthException to user-friendly messages
  static AppException _mapAuthException(
    supabase_flutter.AuthException error,
    StackTrace? stackTrace,
  ) {
    final message = error.message.toLowerCase();

    // Invalid credentials
    if (message.contains('invalid') && message.contains('credentials')) {
      return AuthException(
        message: error.message,
        userMessage: 'Invalid email or password. Please try again.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Email not confirmed
    if (message.contains('email') && message.contains('not confirmed')) {
      return AuthException(
        message: error.message,
        userMessage: 'Please confirm your email address before logging in.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // User not found
    if (message.contains('user') && message.contains('not found')) {
      return AuthException(
        message: error.message,
        userMessage: 'No account found with this email.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Email already registered
    if (message.contains('already') && message.contains('registered')) {
      return AuthException(
        message: error.message,
        userMessage: 'An account with this email already exists.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Weak password
    if (message.contains('password') && (message.contains('weak') || message.contains('short'))) {
      return ValidationException(
        message: error.message,
        userMessage: 'Password must be at least 8 characters long.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Generic auth error
    return AuthException(
      message: error.message,
      userMessage: 'Authentication failed. Please try again.',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Map Supabase PostgrestException to user-friendly messages
  static AppException _mapPostgrestException(
    supabase_flutter.PostgrestException error,
    StackTrace? stackTrace,
  ) {
    final message = error.message.toLowerCase();
    final code = error.code;

    // Permission denied (RLS)
    if (code == '42501' || message.contains('permission denied')) {
      return PermissionException(
        message: error.message,
        userMessage: 'You don\'t have permission to access this data.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Not found
    if (code == '404' || message.contains('not found')) {
      return NotFoundException(
        message: error.message,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Unique constraint violation
    if (code == '23505' || message.contains('unique constraint')) {
      return ValidationException(
        message: error.message,
        userMessage: 'This record already exists.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Foreign key constraint violation
    if (code == '23503' || message.contains('foreign key')) {
      return ValidationException(
        message: error.message,
        userMessage: 'Related data not found. Please refresh and try again.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Generic database error
    return DatabaseException(
      message: error.message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Get user-friendly message for Supabase Storage errors
  static String _getStorageErrorMessage(supabase_flutter.StorageException error) {
    final message = error.message.toLowerCase();

    if (message.contains('not found')) {
      return 'File not found.';
    }
    if (message.contains('already exists')) {
      return 'File already exists.';
    }
    if (message.contains('too large') || message.contains('file size')) {
      return 'File is too large. Please choose a smaller file.';
    }
    if (message.contains('permission')) {
      return 'You don\'t have permission to access this file.';
    }

    return 'Storage error. Please try again.';
  }

  /// Get user-friendly message for any exception
  static String getUserMessage(dynamic error) {
    final appException = mapException(error);
    return appException.getUserMessage();
  }

  /// Check if error is a network error
  static bool isNetworkError(dynamic error) {
    return error is SocketException ||
        error is HttpException ||
        error is NetworkException;
  }

  /// Check if error is an auth error
  static bool isAuthError(dynamic error) {
    return error is AuthException ||
        (error is supabase_flutter.AuthException);
  }

  /// Check if error is a validation error
  static bool isValidationError(dynamic error) {
    return error is ValidationException || error is FormatException;
  }
}
