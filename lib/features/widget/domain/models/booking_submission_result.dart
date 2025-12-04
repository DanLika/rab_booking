import '../../../../shared/models/booking_model.dart';

/// Result of booking submission attempt.
///
/// For Stripe payments: Contains booking data for checkout (booking not yet created).
/// For non-Stripe payments: Contains created booking model.
class BookingSubmissionResult {
  /// Indicates whether this is a Stripe validation result (booking not created yet).
  final bool isStripeFlow;

  /// Booking data for Stripe checkout (null if not Stripe flow).
  final Map<String, dynamic>? stripeBookingData;

  /// Created booking model (null if Stripe flow).
  final BookingModel? booking;

  const BookingSubmissionResult({
    required this.isStripeFlow,
    this.stripeBookingData,
    this.booking,
  });

  /// Factory for Stripe validation result (booking not created yet).
  factory BookingSubmissionResult.stripeValidation({
    required Map<String, dynamic> bookingData,
  }) {
    return BookingSubmissionResult(
      isStripeFlow: true,
      stripeBookingData: bookingData,
    );
  }

  /// Factory for non-Stripe booking result (booking already created).
  factory BookingSubmissionResult.bookingCreated({
    required BookingModel booking,
  }) {
    return BookingSubmissionResult(
      isStripeFlow: false,
      booking: booking,
    );
  }
}
