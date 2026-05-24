/// Parses `Uri.base` into a discriminated [BookingUrlIntent] so the booking
/// widget can dispatch its post-frame init on a single switch instead of a
/// nested if-chain over loosely-coupled query parameters.
library;

import 'booking_widget_url_helpers.dart';

/// Discrete intent the booking widget should dispatch on at first paint.
///
/// The variants are exhaustive: every URL shape maps to exactly one branch.
/// See [parseInitialUrlIntent] for the resolution order.
sealed class BookingUrlIntent {
  const BookingUrlIntent();
}

/// No special booking parameters in the URL — render the normal calendar
/// flow and let the user pick dates.
final class FreshLoad extends BookingUrlIntent {
  const FreshLoad();
}

/// Stripe Checkout has redirected back with `stripe_status=success` and a
/// valid `session_id`. The booking record is created asynchronously by the
/// webhook; the widget polls Firestore by [sessionId].
final class StripeReturnSession extends BookingUrlIntent {
  final String sessionId;
  const StripeReturnSession({required this.sessionId});
}

/// Legacy Stripe return — booking was created BEFORE checkout and the URL
/// carries both `confirmation` and `bookingId`. Used until the webhook-first
/// flow lands across all environments.
final class LegacyStripeReturn extends BookingUrlIntent {
  final String confirmationRef;
  final String bookingId;
  final String? paymentType;
  const LegacyStripeReturn({
    required this.confirmationRef,
    required this.bookingId,
    this.paymentType,
  });
}

/// Same-tab return from a non-Stripe flow (Pay on Arrival, Bank Transfer)
/// where `booking_status=success` is set client-side after submission.
final class DirectBookingReturn extends BookingUrlIntent {
  final String confirmationRef;
  final String bookingId;
  final String? paymentType;
  const DirectBookingReturn({
    required this.confirmationRef,
    required this.bookingId,
    this.paymentType,
  });
}

/// Resolution order (highest priority first):
///
/// 1. [StripeReturnSession] — `stripe_status=success` + valid `session_id`,
///    AND no legacy `confirmation`/`bookingId` pair.
/// 2. [LegacyStripeReturn] — valid `confirmation` + `bookingId`, AND
///    (`payment=stripe` OR `stripe_status=success`).
/// 3. [DirectBookingReturn] — `booking_status=success` + valid
///    `confirmation` + valid `bookingId`.
/// 4. [FreshLoad] — anything else.
///
/// All parameter validation uses the strict regex checks in
/// `booking_widget_url_helpers.dart`; malformed values are treated as
/// missing (fail-safe).
BookingUrlIntent parseInitialUrlIntent(Uri uri) {
  final confirmationRef = uri.queryParameters['confirmation'];
  final bookingId = uri.queryParameters['bookingId'];
  final paymentType = uri.queryParameters['payment'];
  final stripeStatus = uri.queryParameters['stripe_status'];
  final stripeSessionId = uri.queryParameters['session_id'];
  final bookingStatus = uri.queryParameters['booking_status'];

  final isValidConfirmation = isValidBookingReference(confirmationRef);
  final isValidBookingId = isValidFirestoreId(bookingId);
  final isValidSessionId = isValidStripeSessionId(stripeSessionId);

  final isStripeReturn = stripeStatus == 'success' && isValidSessionId;
  final hasLegacyStripeParams =
      isValidConfirmation &&
      isValidBookingId &&
      (paymentType == 'stripe' || stripeStatus == 'success');
  final isDirectBookingReturn =
      bookingStatus == 'success' && isValidConfirmation && isValidBookingId;

  if (isStripeReturn && !hasLegacyStripeParams) {
    return StripeReturnSession(sessionId: stripeSessionId!);
  }
  if (hasLegacyStripeParams) {
    return LegacyStripeReturn(
      confirmationRef: confirmationRef!,
      bookingId: bookingId!,
      paymentType: paymentType,
    );
  }
  if (isDirectBookingReturn) {
    return DirectBookingReturn(
      confirmationRef: confirmationRef!,
      bookingId: bookingId!,
      paymentType: paymentType,
    );
  }
  return const FreshLoad();
}
