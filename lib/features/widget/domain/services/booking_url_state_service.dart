import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/services/logging_service.dart';
import '../../../../core/utils/web_utils.dart';

/// Service for managing booking-related URL state.
///
/// This service handles:
/// - Clearing booking parameters from URL after confirmation
/// - Adding confirmation parameters to URL for browser history
/// - Parsing Stripe return parameters from URL
///
/// All methods are static since they only manipulate URL state
/// and don't require instance-level dependencies.
///
/// Usage:
/// ```dart
/// // Clear booking params after confirmation shown
/// BookingUrlStateService.clearBookingParams();
///
/// // Add confirmation params for browser history
/// BookingUrlStateService.addConfirmationParams(
///   bookingRef: 'ABC123',
///   email: 'guest@example.com',
///   bookingId: 'booking_xyz',
///   paymentMethod: 'stripe',
/// );
///
/// // Parse Stripe return from URL
/// final stripeReturn = BookingUrlStateService.parseStripeReturn();
/// if (stripeReturn != null) {
///   handleStripeReturn(stripeReturn.sessionId);
/// }
/// ```
class BookingUrlStateService {
  static const String _tag = 'URL_PARAMS';

  /// Private constructor to prevent instantiation
  BookingUrlStateService._();

  /// Clear booking-related URL params and reset to base URL.
  ///
  /// Preserves only `property` and `unit` query parameters,
  /// removing all booking confirmation params.
  ///
  /// No-op on non-web platforms.
  static void clearBookingParams() {
    if (!kIsWeb) return;

    try {
      final uri = Uri.base;
      // Keep only property and unit params
      final cleanParams = <String, String>{};
      if (uri.queryParameters.containsKey('property')) {
        cleanParams['property'] = uri.queryParameters['property']!;
      }
      if (uri.queryParameters.containsKey('unit')) {
        cleanParams['unit'] = uri.queryParameters['unit']!;
      }

      final newUri = uri.replace(queryParameters: cleanParams);
      replaceUrlState(newUri.toString());

      LoggingService.log(
        '[URL] Cleared booking params, new URL: ${newUri.toString()}',
        tag: _tag,
      );
    } catch (e) {
      LoggingService.log('[URL] Failed to clear URL params: $e', tag: _tag);
    }
  }

  /// Add booking confirmation params to URL for browser history support.
  ///
  /// This enables the back button to navigate away from confirmation
  /// and forward button to return to it.
  ///
  /// NOTE: Email is NOT included in URL for security/privacy reasons.
  /// Email is already verified in the booking form, so no need to include it.
  ///
  /// No-op on non-web platforms.
  static void addConfirmationParams({
    required String bookingRef,
    required String bookingId,
    required String paymentMethod,
  }) {
    if (!kIsWeb) return;

    try {
      final uri = Uri.base;
      final newParams = Map<String, String>.from(uri.queryParameters);

      // Add booking confirmation params (email NOT included for security/privacy)
      newParams['booking_status'] = 'success';
      newParams['confirmation'] = bookingRef;
      newParams['bookingId'] = bookingId;
      newParams['payment'] = paymentMethod;

      final newUri = uri.replace(queryParameters: newParams);
      // Use pushState to add to browser history (back button works)
      pushUrlState(newUri.toString());

      LoggingService.log(
        '[URL] Added booking params, new URL: ${newUri.toString()}',
        tag: _tag,
      );
    } catch (e) {
      LoggingService.log('[URL] Failed to add URL params: $e', tag: _tag);
    }
  }

  /// Parse Stripe return parameters from current URL.
  ///
  /// Returns [StripeReturnParams] if URL contains valid Stripe return params,
  /// otherwise returns null.
  ///
  /// Checks for:
  /// - `stripe_status=success` or `stripe_status=cancel`
  /// - `session_id=cs_xxx` (optional for cancel)
  static StripeReturnParams? parseStripeReturn() {
    if (!kIsWeb) return null;

    try {
      final uri = Uri.base;
      final stripeStatus = uri.queryParameters['stripe_status'];

      if (stripeStatus == null) return null;

      return StripeReturnParams(
        status: stripeStatus,
        sessionId: uri.queryParameters['session_id'],
        bookingId: uri.queryParameters['bookingId'],
      );
    } catch (e) {
      LoggingService.log(
        '[URL] Failed to parse Stripe return params: $e',
        tag: _tag,
      );
      return null;
    }
  }

  /// Check if URL contains booking confirmation params.
  ///
  /// Returns true if `booking_status=success` is present.
  static bool hasConfirmationParams() {
    if (!kIsWeb) return false;

    try {
      final uri = Uri.base;
      return uri.queryParameters['booking_status'] == 'success';
    } catch (e) {
      return false;
    }
  }

  /// Get confirmation params from URL if present.
  ///
  /// Returns [ConfirmationParams] if URL contains valid confirmation,
  /// otherwise returns null.
  ///
  /// NOTE: Email is NOT required - booking is fetched by bookingId.
  static ConfirmationParams? parseConfirmationParams() {
    if (!kIsWeb) return null;

    try {
      final uri = Uri.base;
      final bookingStatus = uri.queryParameters['booking_status'];

      if (bookingStatus != 'success') return null;

      final confirmation = uri.queryParameters['confirmation'];
      final bookingId = uri.queryParameters['bookingId'];

      // Only bookingRef and bookingId are required (email not needed)
      if (confirmation == null || bookingId == null) return null;

      return ConfirmationParams(
        bookingRef: confirmation,
        bookingId: bookingId,
        paymentMethod: uri.queryParameters['payment'],
      );
    } catch (e) {
      LoggingService.log(
        '[URL] Failed to parse confirmation params: $e',
        tag: _tag,
      );
      return null;
    }
  }
}

/// Parameters from Stripe redirect return URL.
class StripeReturnParams {
  /// Stripe return status ('success' or 'cancel')
  final String status;

  /// Stripe Checkout session ID (e.g., 'cs_xxx')
  final String? sessionId;

  /// Booking ID if created before redirect
  final String? bookingId;

  const StripeReturnParams({
    required this.status,
    this.sessionId,
    this.bookingId,
  });

  /// Whether the payment was successful
  bool get isSuccess => status == 'success';

  /// Whether the payment was cancelled
  bool get isCancelled => status == 'cancel';
}

/// Parameters from booking confirmation URL.
class ConfirmationParams {
  /// Booking reference code (e.g., 'ABC123')
  final String bookingRef;

  /// Firestore booking document ID
  final String? bookingId;

  /// Payment method used (e.g., 'stripe', 'bank_transfer')
  final String? paymentMethod;

  const ConfirmationParams({
    required this.bookingRef,
    this.bookingId,
    this.paymentMethod,
  });
}
