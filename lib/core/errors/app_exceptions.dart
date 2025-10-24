/// Application-wide exception classes for better error handling
/// and user-friendly error messages

/// Base class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  final String? userMessage; // User-friendly message
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.userMessage,
    this.originalError,
    this.stackTrace,
  });

  /// Get the message to display to users
  String getUserMessage() {
    return userMessage ?? message;
  }

  @override
  String toString() => message;
}

// ============================================================================
// NETWORK & API EXCEPTIONS
// ============================================================================

/// Exception for network connectivity issues
class NetworkException extends AppException {
  const NetworkException({
    String message = 'Network error occurred',
    String? userMessage,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: message,
          userMessage: userMessage ?? 'No internet connection. Please check your network.',
        );
}

/// Exception for API/Server errors
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    String message = 'Server error occurred',
    String? userMessage,
    this.statusCode,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: message,
          userMessage: userMessage ?? 'Server error. Please try again later.',
        );
}

/// Exception for timeout errors
class TimeoutException extends AppException {
  const TimeoutException({
    String message = 'Request timed out',
    String? userMessage,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: message,
          userMessage: userMessage ?? 'Request took too long. Please try again.',
        );
}

// ============================================================================
// AUTHENTICATION & AUTHORIZATION EXCEPTIONS
// ============================================================================

/// Exception for authentication errors
class AuthException extends AppException {
  const AuthException({
    String message = 'Authentication error',
    String? userMessage,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: message,
          userMessage: userMessage ?? 'Authentication failed. Please log in again.',
        );
}

/// Exception for authorization/permission errors
class PermissionException extends AppException {
  const PermissionException({
    String message = 'Permission denied',
    String? userMessage,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: message,
          userMessage: userMessage ?? 'You don\'t have permission to perform this action.',
        );
}

// ============================================================================
// DATA & VALIDATION EXCEPTIONS
// ============================================================================

/// Exception for data validation errors
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    String message = 'Validation error',
    String? userMessage,
    this.fieldErrors,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: message,
          userMessage: userMessage ?? 'Please check your input and try again.',
        );

  /// Get error for a specific field
  String? getFieldError(String field) => fieldErrors?[field];
}

/// Exception for data not found errors
class NotFoundException extends AppException {
  const NotFoundException({
    String message = 'Data not found',
    String? userMessage,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: message,
          userMessage: userMessage ?? 'The requested data was not found.',
        );
}

// ============================================================================
// FILE & UPLOAD EXCEPTIONS
// ============================================================================

/// Exception for file upload errors
class FileUploadException extends AppException {
  const FileUploadException({
    String message = 'File upload failed',
    String? userMessage,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: message,
          userMessage: userMessage ?? 'Failed to upload file. Please try again.',
        );
}

/// Exception for file size errors
class FileSizeException extends AppException {
  final int? maxSize;
  final int? actualSize;

  const FileSizeException({
    String message = 'File too large',
    String? userMessage,
    this.maxSize,
    this.actualSize,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: message,
          userMessage: userMessage ?? 'File is too large. Please choose a smaller file.',
        );

  @override
  String getUserMessage() {
    if (maxSize != null && actualSize != null) {
      final maxMB = (maxSize! / (1024 * 1024)).toStringAsFixed(1);
      final actualMB = (actualSize! / (1024 * 1024)).toStringAsFixed(1);
      return 'File is too large ($actualMB MB). Maximum size is $maxMB MB.';
    }
    return super.getUserMessage();
  }
}

/// Exception for invalid file type errors
class FileTypeException extends AppException {
  final String? allowedTypes;

  const FileTypeException({
    String message = 'Invalid file type',
    String? userMessage,
    this.allowedTypes,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: message,
          userMessage: userMessage ?? 'Invalid file type. Please choose a different file.',
        );

  @override
  String getUserMessage() {
    if (allowedTypes != null) {
      return 'Invalid file type. Allowed types: $allowedTypes';
    }
    return super.getUserMessage();
  }
}

// ============================================================================
// DATABASE & STORAGE EXCEPTIONS
// ============================================================================

/// Exception for database errors
class DatabaseException extends AppException {
  const DatabaseException({
    String message = 'Database error',
    String? userMessage,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: message,
          userMessage: userMessage ?? 'A database error occurred. Please try again.',
        );
}

/// Exception for storage errors
class StorageException extends AppException {
  const StorageException({
    String message = 'Storage error',
    String? userMessage,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: message,
          userMessage: userMessage ?? 'A storage error occurred. Please try again.',
        );
}

// ============================================================================
// GENERIC EXCEPTIONS
// ============================================================================

/// Exception for authentication errors (user auth)
class AuthenticationException extends AppException {
  const AuthenticationException(
    String message, {
    String? userMessage,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: message,
          userMessage: userMessage ?? 'Authentication failed. Please try again.',
        );
}

/// Exception for payment processing errors
class PaymentException extends AppException {
  const PaymentException(
    String message, {
    String? userMessage,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: message,
          userMessage: userMessage ?? 'Payment processing failed. Please try again.',
        );
}

/// Exception for unknown/unexpected errors
class UnknownException extends AppException {
  const UnknownException({
    String message = 'An unexpected error occurred',
    String? userMessage,
    super.originalError,
    super.stackTrace,
  }) : super(
          message: message,
          userMessage: userMessage ?? 'An unexpected error occurred. Please try again.',
        );
}
