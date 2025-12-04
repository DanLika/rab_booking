// Custom exception hierarchy for RabBooking app
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
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

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
