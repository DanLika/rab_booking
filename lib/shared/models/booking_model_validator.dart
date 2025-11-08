import 'booking_model.dart';
import '../../core/constants/enums.dart';

/// Validation exceptions for BookingModel
class BookingValidationException implements Exception {
  final String message;
  const BookingValidationException(this.message);

  @override
  String toString() => 'BookingValidationException: $message';
}

/// Extension methods for BookingModel validation
extension BookingModelValidator on BookingModel {
  /// Validate booking data
  /// Throws [BookingValidationException] if validation fails
  void validate() {
    // Validate check-in and check-out dates
    if (checkOut.isBefore(checkIn) || checkOut.isAtSameMomentAs(checkIn)) {
      throw const BookingValidationException(
        'Check-out date must be after check-in date',
      );
    }

    // Validate number of nights (at least 1, max 365)
    if (numberOfNights < 1) {
      throw const BookingValidationException(
        'Booking must be for at least 1 night',
      );
    }

    if (numberOfNights > 365) {
      throw const BookingValidationException(
        'Booking cannot exceed 365 nights',
      );
    }

    // Validate check-in date (cannot be in the past, except for admin/system bookings)
    final now = DateTime.now();
    final checkInDate = DateTime(checkIn.year, checkIn.month, checkIn.day);
    final today = DateTime(now.year, now.month, now.day);

    if (checkInDate.isBefore(today) && status == BookingStatus.pending) {
      throw const BookingValidationException(
        'Check-in date cannot be in the past for new bookings',
      );
    }

    // Validate guest count
    if (guestCount < 1) {
      throw const BookingValidationException(
        'At least 1 guest is required',
      );
    }

    if (guestCount > 50) {
      throw const BookingValidationException(
        'Guest count cannot exceed 50',
      );
    }

    // Validate prices
    if (totalPrice < 0) {
      throw const BookingValidationException(
        'Total price cannot be negative',
      );
    }

    if (paidAmount < 0) {
      throw const BookingValidationException(
        'Paid amount cannot be negative',
      );
    }

    if (paidAmount > totalPrice) {
      throw const BookingValidationException(
        'Paid amount cannot exceed total price',
      );
    }

    // Validate total price is reasonable (at least €1 per night)
    if (totalPrice > 0 && totalPrice < numberOfNights) {
      throw const BookingValidationException(
        'Total price is suspiciously low (less than €1 per night)',
      );
    }

    // Validate status-specific rules
    if (status == BookingStatus.cancelled) {
      if (cancellationReason == null || cancellationReason!.trim().isEmpty) {
        throw const BookingValidationException(
          'Cancellation reason is required for cancelled bookings',
        );
      }
    }

    // Validate payment intent exists for non-blocked bookings
    if (status != BookingStatus.blocked && paidAmount > 0 && paymentIntentId == null) {
      // Warning only, not an exception (for backward compatibility)
      // In production, you might want to log this as a warning
    }

    // Validate IDs are not empty
    if (id.trim().isEmpty) {
      throw const BookingValidationException('Booking ID cannot be empty');
    }

    if (unitId.trim().isEmpty) {
      throw const BookingValidationException('Unit ID cannot be empty');
    }

    if (userId?.trim().isEmpty ?? true) {
      throw const BookingValidationException('User ID cannot be empty');
    }
  }

  /// Check if booking is valid (returns bool instead of throwing)
  bool get isValid {
    try {
      validate();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get validation errors as a list of strings
  List<String> get validationErrors {
    final errors = <String>[];

    try {
      validate();
    } catch (e) {
      if (e is BookingValidationException) {
        errors.add(e.message);
      }
    }

    return errors;
  }
}

/// Factory methods with validation
extension BookingModelFactory on BookingModel {
  /// Create a validated booking
  /// Throws [BookingValidationException] if validation fails
  static BookingModel createValidated({
    required String id,
    required String unitId,
    required String userId,
    required DateTime checkIn,
    required DateTime checkOut,
    required BookingStatus status,
    required double totalPrice,
    required double paidAmount,
    required int guestCount,
    String? notes,
    String? paymentIntentId,
    required DateTime createdAt,
    DateTime? updatedAt,
    String? cancellationReason,
    DateTime? cancelledAt,
  }) {
    final booking = BookingModel(
      id: id,
      unitId: unitId,
      userId: userId,
      checkIn: checkIn,
      checkOut: checkOut,
      status: status,
      totalPrice: totalPrice,
      paidAmount: paidAmount,
      guestCount: guestCount,
      notes: notes,
      paymentIntentId: paymentIntentId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      cancellationReason: cancellationReason,
      cancelledAt: cancelledAt,
    );

    // Validate the booking
    booking.validate();

    return booking;
  }
}
