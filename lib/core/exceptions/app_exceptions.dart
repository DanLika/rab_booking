/// Base application exception
abstract class AppException implements Exception {
  const AppException(this.message, {this.code, this.details});

  final String message;
  final String? code;
  final dynamic details;

  @override
  String toString() => code != null ? '[$code] $message' : message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException([String? message, dynamic details])
      : super(message ?? 'Network connection failed', code: 'NETWORK_ERROR', details: details);
}

/// Server/API exceptions
class ServerException extends AppException {
  const ServerException([String? message, String? code, dynamic details])
      : super(message ?? 'Server error occurred', code: code ?? 'SERVER_ERROR', details: details);
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException([String? message, String? code, dynamic details])
      : super(message ?? 'Authentication failed', code: code ?? 'AUTH_ERROR', details: details);
}

/// Authorization exceptions (user doesn't have permission)
class AuthorizationException extends AppException {
  const AuthorizationException([String? message, dynamic details])
      : super(
          message ?? 'You do not have permission to perform this action',
          code: 'AUTHORIZATION_ERROR',
          details: details,
        );
}

/// Validation exceptions (invalid input data)
class ValidationException extends AppException {
  const ValidationException(String message, {String? code, dynamic details})
      : super(message, code: code ?? 'VALIDATION_ERROR', details: details);

  /// Create validation exception with field-specific error
  factory ValidationException.field(String field, String error) {
    return ValidationException('$field: $error', code: 'FIELD_VALIDATION_ERROR');
  }
}

/// Not found exceptions (resource doesn't exist)
class NotFoundException extends AppException {
  const NotFoundException([String? message, String? code, dynamic details])
      : super(message ?? 'Resource not found', code: code ?? 'NOT_FOUND', details: details);

  /// Create not found exception for specific resource type
  factory NotFoundException.resource(String resourceType, String id) {
    return NotFoundException('$resourceType with id $id not found', 'RESOURCE_NOT_FOUND');
  }
}

/// Conflict exceptions (e.g., duplicate booking)
class ConflictException extends AppException {
  const ConflictException([String? message, String? code, dynamic details])
      : super(message ?? 'Resource conflict occurred', code: code ?? 'CONFLICT', details: details);
}

/// Database exceptions
class DatabaseException extends AppException {
  const DatabaseException([String? message, String? code, dynamic details])
      : super(message ?? 'Database operation failed', code: code ?? 'DATABASE_ERROR', details: details);
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException([String? message, String? code, dynamic details])
      : super(message ?? 'Cache operation failed', code: code ?? 'CACHE_ERROR', details: details);
}

/// Timeout exceptions
class TimeoutException extends AppException {
  const TimeoutException([String? message, dynamic details])
      : super(message ?? 'Operation timed out', code: 'TIMEOUT_ERROR', details: details);
}

/// Booking-specific exceptions
class BookingException extends AppException {
  const BookingException(String message, {String? code, dynamic details})
      : super(message, code: code ?? 'BOOKING_ERROR', details: details);

  /// Unit is not available for selected dates
  factory BookingException.unitNotAvailable() {
    return const BookingException(
      'This unit is not available for the selected dates',
      code: 'UNIT_NOT_AVAILABLE',
    );
  }

  /// Dates overlap with existing booking
  factory BookingException.datesOverlap() {
    return const BookingException(
      'Selected dates overlap with an existing booking',
      code: 'DATES_OVERLAP',
    );
  }

  /// Minimum stay requirement not met
  factory BookingException.minimumStayNotMet(int minNights) {
    return BookingException(
      'Minimum stay requirement is $minNights ${minNights == 1 ? 'night' : 'nights'}',
      code: 'MINIMUM_STAY_NOT_MET',
    );
  }

  /// Guest count exceeds capacity
  factory BookingException.guestCountExceeded(int maxGuests) {
    return BookingException(
      'Maximum guest capacity is $maxGuests',
      code: 'GUEST_COUNT_EXCEEDED',
    );
  }

  /// Booking cannot be cancelled
  factory BookingException.cannotCancel(String reason) {
    return BookingException(
      'Booking cannot be cancelled: $reason',
      code: 'CANNOT_CANCEL',
    );
  }

  /// Invalid date range
  factory BookingException.invalidDateRange() {
    return const BookingException(
      'Check-out date must be after check-in date',
      code: 'INVALID_DATE_RANGE',
    );
  }

  /// Booking in the past
  factory BookingException.pastDate() {
    return const BookingException(
      'Cannot create booking for past dates',
      code: 'PAST_DATE',
    );
  }
}

/// Payment exceptions
class PaymentException extends AppException {
  const PaymentException(String message, {String? code, dynamic details})
      : super(message, code: code ?? 'PAYMENT_ERROR', details: details);

  /// Payment failed
  factory PaymentException.paymentFailed([String? reason]) {
    return PaymentException(
      'Payment failed${reason != null ? ': $reason' : ''}',
      code: 'PAYMENT_FAILED',
    );
  }

  /// Payment cancelled by user
  factory PaymentException.paymentCancelled() {
    return const PaymentException(
      'Payment was cancelled',
      code: 'PAYMENT_CANCELLED',
    );
  }

  /// Invalid payment amount
  factory PaymentException.invalidAmount() {
    return const PaymentException(
      'Invalid payment amount',
      code: 'INVALID_AMOUNT',
    );
  }

  /// Insufficient funds
  factory PaymentException.insufficientFunds() {
    return const PaymentException(
      'Insufficient funds',
      code: 'INSUFFICIENT_FUNDS',
    );
  }
}

/// Extension to convert Supabase exceptions to app exceptions
extension SupabaseExceptionHandler on Object {
  /// Convert Supabase exception to AppException
  AppException toAppException() {
    final error = toString();

    // Authentication errors
    if (error.contains('invalid_credentials') ||
        error.contains('invalid_grant') ||
        error.contains('unauthorized')) {
      return const AuthException('Invalid credentials');
    }

    // Not found errors
    if (error.contains('not found') || error.contains('404')) {
      return const NotFoundException();
    }

    // Conflict errors (duplicate, constraint violation)
    if (error.contains('duplicate') ||
        error.contains('unique constraint') ||
        error.contains('conflict') ||
        error.contains('409')) {
      return const ConflictException('Resource already exists');
    }

    // Network errors
    if (error.contains('network') ||
        error.contains('connection') ||
        error.contains('timeout')) {
      return const NetworkException();
    }

    // Validation errors
    if (error.contains('validation') || error.contains('invalid')) {
      return ValidationException(error);
    }

    // Default to server exception
    return ServerException(error);
  }
}
