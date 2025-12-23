// Custom exception hierarchy for BookBed app
// Replaces generic Exception objects with typed exceptions for better error handling
//
// Usage:
// ```dart
// try {
//   // Some operation
// } catch (e) {
//   if (e is AuthException) {
//     // Handle auth error
//   } else if (e is BookingException) {
//     // Handle booking error
//   }
// }
// ```

/// Base class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final String? userMessage; // User-friendly message for UI display
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException(
    this.message, {
    this.code,
    this.userMessage,
    this.originalError,
    this.stackTrace,
  });

  /// Get the message to display to users
  String getUserMessage() {
    return userMessage ?? message;
  }

  @override
  String toString() {
    final buffer = StringBuffer(runtimeType.toString());
    buffer.write(': $message');
    if (code != null) buffer.write(' (code: $code)');
    if (originalError != null) buffer.write('\nCaused by: $originalError');
    return buffer.toString();
  }
}

// ============================================================================
// AUTHENTICATION EXCEPTIONS
// ============================================================================

/// Thrown when authentication operations fail
class AuthException extends AppException {
  AuthException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for sign-in failures
  factory AuthException.signInFailed(dynamic error) {
    return AuthException(
      'Sign-in failed',
      code: 'auth/sign-in-failed',
      originalError: error,
    );
  }

  /// Factory for sign-up failures
  factory AuthException.signUpFailed(dynamic error) {
    return AuthException(
      'Sign-up failed',
      code: 'auth/sign-up-failed',
      originalError: error,
    );
  }

  /// Factory for missing user data
  factory AuthException.noUserReturned(String provider) {
    return AuthException(
      '$provider Sign-In failed: No user returned',
      code: 'auth/no-user',
    );
  }
}

// ============================================================================
// BOOKING EXCEPTIONS
// ============================================================================

/// Thrown when booking operations fail
class BookingException extends AppException {
  BookingException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for booking creation failures
  factory BookingException.creationFailed(dynamic error) {
    return BookingException(
      'Failed to create booking',
      code: 'booking/creation-failed',
      originalError: error,
    );
  }

  /// Factory for booking update failures
  factory BookingException.updateFailed(dynamic error) {
    return BookingException(
      'Failed to update booking',
      code: 'booking/update-failed',
      originalError: error,
    );
  }

  /// Factory for booking deletion failures
  factory BookingException.deletionFailed(dynamic error) {
    return BookingException(
      'Failed to delete booking',
      code: 'booking/deletion-failed',
      originalError: error,
    );
  }

  /// Factory for booking lookup failures
  factory BookingException.lookupFailed(dynamic error) {
    return BookingException(
      'Failed to look up booking',
      code: 'booking/lookup-failed',
      originalError: error,
    );
  }

  /// Factory for booking approval failures
  factory BookingException.approvalFailed(dynamic error) {
    return BookingException(
      'Failed to approve booking',
      code: 'booking/approval-failed',
      originalError: error,
    );
  }

  /// Factory for booking cancellation failures
  factory BookingException.cancellationFailed(dynamic error) {
    return BookingException(
      'Failed to cancel booking',
      code: 'booking/cancellation-failed',
      originalError: error,
    );
  }
}

// ============================================================================
// PROPERTY/UNIT EXCEPTIONS
// ============================================================================

/// Thrown when property/unit operations fail
class PropertyException extends AppException {
  PropertyException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for property creation failures
  factory PropertyException.creationFailed(dynamic error) {
    return PropertyException(
      'Failed to create property',
      code: 'property/creation-failed',
      originalError: error,
    );
  }

  /// Factory for property update failures
  factory PropertyException.updateFailed(dynamic error) {
    return PropertyException(
      'Failed to update property',
      code: 'property/update-failed',
      originalError: error,
    );
  }
}

// ============================================================================
// STORAGE EXCEPTIONS
// ============================================================================

/// Thrown when file storage operations fail
class StorageException extends AppException {
  StorageException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for upload failures
  factory StorageException.uploadFailed(String fileType, dynamic error) {
    return StorageException(
      'Failed to upload $fileType',
      code: 'storage/upload-failed',
      originalError: error,
    );
  }
}

// ============================================================================
// NOTIFICATION EXCEPTIONS
// ============================================================================

/// Thrown when notification operations fail
class NotificationException extends AppException {
  NotificationException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for notification creation failures
  factory NotificationException.creationFailed(dynamic error) {
    return NotificationException(
      'Failed to create notification',
      code: 'notification/creation-failed',
      originalError: error,
    );
  }

  /// Factory for notification update failures
  factory NotificationException.updateFailed(dynamic error) {
    return NotificationException(
      'Failed to update notification',
      code: 'notification/update-failed',
      originalError: error,
    );
  }
}

// ============================================================================
// ANALYTICS EXCEPTIONS
// ============================================================================

/// Thrown when analytics operations fail
class AnalyticsException extends AppException {
  AnalyticsException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });
}

// ============================================================================
// INTEGRATION EXCEPTIONS
// ============================================================================

/// Thrown when external integrations fail (Booking.com, Airbnb, iCal, etc.)
class IntegrationException extends AppException {
  IntegrationException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for API failures
  factory IntegrationException.apiFailed(String service, dynamic error) {
    return IntegrationException(
      '$service API error',
      code: 'integration/api-failed',
      originalError: error,
    );
  }
}

// ============================================================================
// PAYMENT EXCEPTIONS
// ============================================================================

/// Thrown when payment operations fail
class PaymentException extends AppException {
  PaymentException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for Stripe validation failures
  factory PaymentException.stripeValidationFailed({dynamic error}) {
    return PaymentException(
      'Stripe validation failed - invalid response from booking service',
      code: 'payment/stripe-validation-failed',
      originalError: error,
    );
  }

  /// Factory for payment processing failures
  factory PaymentException.processingFailed(String provider, dynamic error) {
    return PaymentException(
      'Payment processing failed with $provider',
      code: 'payment/processing-failed',
      originalError: error,
    );
  }

  /// Factory for payment verification failures
  factory PaymentException.verificationFailed(dynamic error) {
    return PaymentException(
      'Payment verification failed',
      code: 'payment/verification-failed',
      originalError: error,
    );
  }
}

// ============================================================================
// FILE EXCEPTIONS
// ============================================================================

/// Thrown when file operations fail
class FileException extends AppException {
  FileException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for ICS download failures (web platform)
  factory FileException.icsDownloadFailedWeb(dynamic error) {
    return FileException(
      'Failed to download ICS file in browser',
      code: 'file/ics-download-web-failed',
      originalError: error,
    );
  }

  /// Factory for ICS share failures (mobile/desktop platform)
  factory FileException.icsShareFailed(dynamic error) {
    return FileException(
      'Failed to share ICS file',
      code: 'file/ics-share-failed',
      originalError: error,
    );
  }

  /// Factory for file read failures
  factory FileException.readFailed(String path, dynamic error) {
    return FileException(
      'Failed to read file: $path',
      code: 'file/read-failed',
      originalError: error,
    );
  }

  /// Factory for file write failures
  factory FileException.writeFailed(String path, dynamic error) {
    return FileException(
      'Failed to write file: $path',
      code: 'file/write-failed',
      originalError: error,
    );
  }
}

// ============================================================================
// NETWORK & API EXCEPTIONS
// ============================================================================

/// Exception for network connectivity issues
class NetworkException extends AppException {
  NetworkException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for connection failures
  factory NetworkException.connectionFailed([dynamic error]) {
    return NetworkException(
      'Network connection failed',
      code: 'network/connection-failed',
      userMessage: 'Provjerite internet konekciju i pokušajte ponovo.',
      originalError: error,
    );
  }
}

/// Exception for API/Server errors
class ServerException extends AppException {
  final int? statusCode;

  ServerException(
    super.message, {
    this.statusCode,
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for server errors with status code
  factory ServerException.withStatusCode(int statusCode, [dynamic error]) {
    return ServerException(
      'Server error: $statusCode',
      statusCode: statusCode,
      code: 'server/error-$statusCode',
      userMessage: 'Greška na serveru. Pokušajte ponovo.',
      originalError: error,
    );
  }
}

/// Exception for timeout errors
class TimeoutException extends AppException {
  TimeoutException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for request timeout
  factory TimeoutException.requestTimeout([dynamic error]) {
    return TimeoutException(
      'Request timed out',
      code: 'timeout/request',
      userMessage: 'Operacija je istekla. Pokušajte ponovo.',
      originalError: error,
    );
  }
}

// ============================================================================
// DATA & VALIDATION EXCEPTIONS
// ============================================================================

/// Exception for data validation errors
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Get error for a specific field
  String? getFieldError(String field) => fieldErrors?[field];

  /// Factory for field validation failure
  factory ValidationException.fieldInvalid(
    String field,
    String reason, [
    dynamic error,
  ]) {
    return ValidationException(
      'Validation failed for $field: $reason',
      fieldErrors: {field: reason},
      code: 'validation/field-invalid',
      userMessage: reason,
      originalError: error,
    );
  }
}

/// Exception for data not found errors
class NotFoundException extends AppException {
  NotFoundException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for resource not found
  factory NotFoundException.resource(String resourceType, [dynamic error]) {
    return NotFoundException(
      '$resourceType not found',
      code: 'not-found/$resourceType',
      userMessage: 'Traženi resurs nije pronađen.',
      originalError: error,
    );
  }
}

/// Exception for database errors
class DatabaseException extends AppException {
  DatabaseException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for database operation failure
  factory DatabaseException.operationFailed(String operation, [dynamic error]) {
    return DatabaseException(
      'Database operation failed: $operation',
      code: 'database/operation-failed',
      userMessage: 'Greška u bazi podataka. Pokušajte ponovo.',
      originalError: error,
    );
  }
}

// ============================================================================
// AUTHORIZATION EXCEPTIONS
// ============================================================================

/// Exception for authorization/permission errors
class PermissionException extends AppException {
  PermissionException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for permission denied
  factory PermissionException.denied(String action, [dynamic error]) {
    return PermissionException(
      'Permission denied for: $action',
      code: 'permission/denied',
      userMessage: 'Nemate dozvolu za ovu akciju.',
      originalError: error,
    );
  }
}

/// Exception for authorization errors (different from PermissionException)
class AuthorizationException extends AppException {
  AuthorizationException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for unauthorized access
  factory AuthorizationException.unauthorized([dynamic error]) {
    return AuthorizationException(
      'Unauthorized access',
      code: 'authorization/unauthorized',
      userMessage: 'Nemate dozvolu za pristup ovom resursu.',
      originalError: error,
    );
  }
}

// ============================================================================
// CONFLICT EXCEPTIONS
// ============================================================================

/// Exception for resource conflicts (e.g., duplicate booking)
class ConflictException extends AppException {
  ConflictException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for resource conflict
  factory ConflictException.resourceConflict(
    String resourceType, [
    dynamic error,
  ]) {
    return ConflictException(
      'Conflict occurred for $resourceType',
      code: 'conflict/$resourceType',
      userMessage: 'Konflikt podataka. Pokušajte ponovo.',
      originalError: error,
    );
  }
}

/// Exception for dates that are no longer available
/// Thrown when price calculation or booking attempt is made for dates
/// that have been booked by another user in the meantime
class DatesNotAvailableException extends AppException {
  DatesNotAvailableException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for dates conflict
  factory DatesNotAvailableException.conflict([dynamic error]) {
    return DatesNotAvailableException(
      'Selected dates are no longer available',
      code: 'booking/dates-unavailable',
      userMessage:
          'Sorry, these dates were just booked by another guest. Please select different dates.',
      originalError: error,
    );
  }
}

/// Exception for price calculation failures
/// Thrown when price calculation encounters an error (network, Firestore, etc.)
/// Bug Fix #3: Fail-safe approach - expose errors instead of returning zero price
class PriceCalculationException extends AppException {
  final String unitId;
  final DateTime checkIn;
  final DateTime checkOut;

  PriceCalculationException(
    super.message, {
    required this.unitId,
    required this.checkIn,
    required this.checkOut,
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for general calculation failures
  factory PriceCalculationException.failed({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    dynamic error,
  }) {
    return PriceCalculationException(
      'Failed to calculate booking price',
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
      code: 'price/calculation-failed',
      userMessage: 'Unable to calculate price. Please try again.',
      originalError: error,
    );
  }

  @override
  String toString() {
    return 'PriceCalculationException: $message '
        '(unit: $unitId, dates: $checkIn - $checkOut, error: $originalError)';
  }
}

// ============================================================================
// GENERIC EXCEPTIONS
// ============================================================================

/// Exception for unknown/unexpected errors
class UnknownException extends AppException {
  UnknownException(
    super.message, {
    super.code,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Factory for unknown errors
  factory UnknownException.unexpected([dynamic error]) {
    return UnknownException(
      'An unexpected error occurred',
      code: 'unknown/unexpected',
      userMessage: 'Došlo je do neočekivane greške. Pokušajte ponovo.',
      originalError: error,
    );
  }
}
