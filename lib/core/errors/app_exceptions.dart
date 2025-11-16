/// Application-wide exception classes for better error handling
/// and user-friendly error messages
library;

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
    super.message = 'Network error occurred',
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });
}

/// Exception for API/Server errors
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    super.message = 'Server error occurred',
    super.userMessage,
    this.statusCode,
    super.originalError,
    super.stackTrace,
  });
}

/// Exception for timeout errors
class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Request timed out',
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });
}

// ============================================================================
// AUTHENTICATION & AUTHORIZATION EXCEPTIONS
// ============================================================================

/// Exception for authentication errors
class AuthException extends AppException {
  const AuthException({
    super.message = 'Authentication error',
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });
}

/// Exception for authorization/permission errors
class PermissionException extends AppException {
  const PermissionException({
    super.message = 'Permission denied',
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });
}

// ============================================================================
// DATA & VALIDATION EXCEPTIONS
// ============================================================================

/// Exception for data validation errors
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    super.message = 'Validation error',
    super.userMessage,
    this.fieldErrors,
    super.originalError,
    super.stackTrace,
  });

  /// Get error for a specific field
  String? getFieldError(String field) => fieldErrors?[field];
}

/// Exception for data not found errors
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Data not found',
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });
}

// ============================================================================
// FILE & UPLOAD EXCEPTIONS
// ============================================================================

/// Exception for file upload errors
class FileUploadException extends AppException {
  const FileUploadException({
    super.message = 'File upload failed',
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });
}

/// Exception for file size errors
class FileSizeException extends AppException {
  final int? maxSize;
  final int? actualSize;

  const FileSizeException({
    super.message = 'File too large',
    super.userMessage,
    this.maxSize,
    this.actualSize,
    super.originalError,
    super.stackTrace,
  });

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
    super.message = 'Invalid file type',
    super.userMessage,
    this.allowedTypes,
    super.originalError,
    super.stackTrace,
  });

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
    super.message = 'Database error',
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });
}

/// Exception for storage errors
class StorageException extends AppException {
  const StorageException({
    super.message = 'Storage error',
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });
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
    super.message = 'An unexpected error occurred',
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });
}

/// Exception for authorization/permission errors
class AuthorizationException extends AppException {
  const AuthorizationException({
    super.message = 'Permission denied',
    super.userMessage = 'You do not have permission to perform this action',
    super.originalError,
    super.stackTrace,
  });
}

/// Exception for resource conflicts (e.g., duplicate booking)
class ConflictException extends AppException {
  const ConflictException({
    super.message = 'Resource conflict occurred',
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });
}

// ============================================================================
// BOOKING EXCEPTIONS
// ============================================================================

/// Exception for booking-related errors
class BookingException extends AppException {
  const BookingException({
    super.message = 'Booking error occurred',
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });
}

/// Exception for dates that are no longer available (Bug #73 Fix)
/// Thrown when price calculation or booking attempt is made for dates
/// that have been booked by another user in the meantime
class DatesNotAvailableException extends AppException {
  const DatesNotAvailableException({
    super.message = 'Selected dates are no longer available',
    super.userMessage = 'Sorry, these dates were just booked by another guest. Please select different dates.',
    super.originalError,
    super.stackTrace,
  });
}
