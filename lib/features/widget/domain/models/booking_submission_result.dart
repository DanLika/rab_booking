import '../../../../shared/models/booking_model.dart';

/// Result of booking submission attempt.
///
/// Sealed class for exhaustive pattern matching:
/// - [BookingSubmissionStripe]: Stripe flow (booking not yet created)
/// - [BookingSubmissionCreated]: Non-Stripe flow (booking already created)
sealed class BookingSubmissionResult {
  const BookingSubmissionResult();

  /// Whether this is a Stripe validation result (booking not created yet).
  bool get isStripeFlow;

  /// Factory for Stripe validation result (booking not created yet).
  factory BookingSubmissionResult.stripeValidation({
    required Map<String, dynamic> bookingData,
  }) = BookingSubmissionStripe;

  /// Factory for non-Stripe booking result (booking already created).
  factory BookingSubmissionResult.bookingCreated({
    required BookingModel booking,
  }) = BookingSubmissionCreated;
}

/// Stripe flow result - booking data for checkout (booking not yet created).
final class BookingSubmissionStripe extends BookingSubmissionResult {
  final Map<String, dynamic> bookingData;

  const BookingSubmissionStripe({required this.bookingData});

  @override
  bool get isStripeFlow => true;
}

/// Non-Stripe flow result - booking already created.
final class BookingSubmissionCreated extends BookingSubmissionResult {
  final BookingModel booking;

  const BookingSubmissionCreated({required this.booking});

  @override
  bool get isStripeFlow => false;
}
