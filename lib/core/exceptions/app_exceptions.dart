/// Base application exception
abstract class AppException implements Exception {
  const AppException(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() => code != null ? '[$code] $message' : message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException([String? message])
      : super(message ?? 'Network connection failed', 'NETWORK_ERROR');
}

/// Server/API exceptions
class ServerException extends AppException {
  const ServerException([String? message, String? code])
      : super(message ?? 'Server error occurred', code ?? 'SERVER_ERROR');
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException([String? message, String? code])
      : super(message ?? 'Authentication failed', code ?? 'AUTH_ERROR');
}

/// Authorization exceptions (user doesn't have permission)
class AuthorizationException extends AppException {
  const AuthorizationException([String? message])
      : super(
          message ?? 'You do not have permission to perform this action',
          'AUTHORIZATION_ERROR',
        );
}

/// Validation exceptions (invalid input data)
class ValidationException extends AppException {
  const ValidationException(String message, [String? code])
      : super(message, code ?? 'VALIDATION_ERROR');

  /// Create validation exception with field-specific error
  factory ValidationException.field(String field, String error) {
    return ValidationException('$field: $error', 'FIELD_VALIDATION_ERROR');
  }
}

/// Not found exceptions (resource doesn't exist)
class NotFoundException extends AppException {
  const NotFoundException([String? message, String? code])
      : super(message ?? 'Resource not found', code ?? 'NOT_FOUND');

  /// Create not found exception for specific resource type
  factory NotFoundException.resource(String resourceType, String id) {
    return NotFoundException('$resourceType with id $id not found', 'RESOURCE_NOT_FOUND');
  }
}

/// Conflict exceptions (e.g., duplicate booking)
class ConflictException extends AppException {
  const ConflictException([String? message, String? code])
      : super(message ?? 'Resource conflict occurred', code ?? 'CONFLICT');
}

/// Database exceptions
class DatabaseException extends AppException {
  const DatabaseException([String? message, String? code])
      : super(message ?? 'Database operation failed', code ?? 'DATABASE_ERROR');
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException([String? message, String? code])
      : super(message ?? 'Cache operation failed', code ?? 'CACHE_ERROR');
}

/// Timeout exceptions
class TimeoutException extends AppException {
  const TimeoutException([String? message])
      : super(message ?? 'Operation timed out', 'TIMEOUT_ERROR');
}

/// Booking-specific exceptions
class BookingException extends AppException {
  const BookingException(String message, [String? code])
      : super(message, code ?? 'BOOKING_ERROR');

  /// Unit is not available for selected dates
  factory BookingException.unitNotAvailable() {
    return const BookingException(
      'This unit is not available for the selected dates',
      'UNIT_NOT_AVAILABLE',
    );
  }

  /// Dates overlap with existing booking
  factory BookingException.datesOverlap() {
    return const BookingException(
      'Selected dates overlap with an existing booking',
      'DATES_OVERLAP',
    );
  }

  /// Minimum stay requirement not met
  factory BookingException.minimumStayNotMet(int minNights) {
    return BookingException(
      'Minimum stay requirement is $minNights ${minNights == 1 ? 'night' : 'nights'}',
      'MINIMUM_STAY_NOT_MET',
    );
  }

  /// Guest count exceeds capacity
  factory BookingException.guestCountExceeded(int maxGuests) {
    return BookingException(
      'Maximum guest capacity is $maxGuests',
      'GUEST_COUNT_EXCEEDED',
    );
  }

  /// Booking cannot be cancelled
  factory BookingException.cannotCancel(String reason) {
    return BookingException(
      'Booking cannot be cancelled: $reason',
      'CANNOT_CANCEL',
    );
  }

  /// Invalid date range
  factory BookingException.invalidDateRange() {
    return const BookingException(
      'Check-out date must be after check-in date',
      'INVALID_DATE_RANGE',
    );
  }

  /// Booking in the past
  factory BookingException.pastDate() {
    return const BookingException(
      'Cannot create booking for past dates',
      'PAST_DATE',
    );
  }
}

/// Payment exceptions
class PaymentException extends AppException {
  const PaymentException(String message, [String? code])
      : super(message, code ?? 'PAYMENT_ERROR');

  /// Payment failed
  factory PaymentException.paymentFailed([String? reason]) {
    return PaymentException(
      'Payment failed${reason != null ? ': $reason' : ''}',
      'PAYMENT_FAILED',
    );
  }

  /// Payment cancelled by user
  factory PaymentException.paymentCancelled() {
    return const PaymentException(
      'Payment was cancelled',
      'PAYMENT_CANCELLED',
    );
  }

  /// Invalid payment amount
  factory PaymentException.invalidAmount() {
    return const PaymentException(
      'Invalid payment amount',
      'INVALID_AMOUNT',
    );
  }

  /// Insufficient funds
  factory PaymentException.insufficientFunds() {
    return const PaymentException(
      'Insufficient funds',
      'INSUFFICIENT_FUNDS',
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
