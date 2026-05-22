import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/models/booking_details_model.dart';

/// Provider for Firebase Functions instance
final functionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instance;
});

/// Provider for booking lookup service
final bookingLookupServiceProvider = Provider<BookingLookupService>((ref) {
  final functions = ref.watch(functionsProvider);
  return BookingLookupService(functions: functions);
});

/// Service for looking up booking details
class BookingLookupService {
  final FirebaseFunctions _functions;

  BookingLookupService({required FirebaseFunctions functions})
    : _functions = functions;

  /// Verify booking access and retrieve booking details
  ///
  /// Parameters:
  /// - [bookingReference]: The booking reference (e.g., "BK-123456")
  /// - [email]: Guest email address
  /// - [accessToken]: Optional access token from email link
  ///
  /// Returns: BookingDetailsModel with booking information
  /// Throws: Exception if verification fails
  Future<BookingDetailsModel> verifyBookingAccess({
    required String bookingReference,
    required String email,
    String? accessToken,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyBookingAccess');
      final result = await callable.call<Map<String, dynamic>>({
        'bookingReference': bookingReference,
        'email': email,
        if (accessToken != null) 'accessToken': accessToken,
      });

      final data = result.data;
      final success = data['success'] == true;

      if (!success) {
        // Server now returns structured `reason` for expected rejections
        // instead of throwing HttpsError. Map reason → user-facing message.
        final reason = data['reason'] as String? ?? 'unknown';
        switch (reason) {
          case 'invalid_credentials':
            throw BookingException(
              'Booking reference or email is incorrect.',
              code: 'booking/permission-denied',
            );
          case 'invalid_token':
          case 'expired_token':
            throw BookingException(
              'Access link is invalid or has expired. '
              'Please try manual lookup.',
              code: 'booking/permission-denied',
            );
          default:
            throw BookingException.lookupFailed('Booking verification failed');
        }
      }

      return BookingLookupResponse.fromJson(data).booking;
    } on FirebaseFunctionsException catch (e) {
      // Only structural / abuse errors still arrive as HttpsError.
      switch (e.code) {
        case 'invalid-argument':
          throw BookingException(
            'Booking reference and email are required.',
            code: 'booking/invalid-argument',
          );
        case 'resource-exhausted':
          throw BookingException(
            'Too many attempts. Please try again in an hour.',
            code: 'booking/rate-limited',
          );
        default:
          throw BookingException.lookupFailed(e.message);
      }
    } on BookingException {
      rethrow;
    } catch (e, stackTrace) {
      // Log the original error before wrapping it
      await LoggingService.logError(
        'BookingLookupService: Unexpected error during booking verification',
        e,
        stackTrace,
      );
      throw BookingException.lookupFailed(e);
    }
  }

  /// Look up a booking by Stripe checkout session ID.
  ///
  /// Replaces the previous direct Firestore collectionGroup read on
  /// `bookings.where('stripe_session_id', '==', sessionId)`. That clause
  /// was removed from `firestore.rules` in the T11-hotfix-partial pass;
  /// the lookup now goes through the `getBookingByStripeSession` callable
  /// which runs as Admin SDK and is rate-limited per IP.
  ///
  /// Returns `null` when the booking is not yet visible (webhook in
  /// flight). Throws on rate-limit, invalid session id, or unexpected
  /// failure.
  Future<BookingDetailsModel?> getBookingByStripeSession(
    String sessionId,
  ) async {
    try {
      final callable = _functions.httpsCallable('getBookingByStripeSession');
      final result = await callable.call<Map<String, dynamic>>({
        'sessionId': sessionId,
      });
      final data = result.data;
      // Server returns {success: false, pending: true} when the webhook
      // hasn't created the booking yet — caller polls again.
      if (data['success'] != true) {
        return null;
      }
      return BookingLookupResponse.fromJson(data).booking;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'invalid-argument') {
        throw BookingException(
          'Invalid Stripe session.',
          code: 'booking/invalid-argument',
        );
      }
      if (e.code == 'resource-exhausted') {
        throw BookingException(
          'Too many lookups. Please try again later.',
          code: 'booking/rate-limited',
        );
      }
      throw BookingException.lookupFailed(e.message);
    } catch (e, stackTrace) {
      await LoggingService.logError(
        'BookingLookupService: Unexpected error during Stripe session lookup',
        e,
        stackTrace,
      );
      throw BookingException.lookupFailed(e);
    }
  }
}

/// State provider for manual lookup form
/// SECURITY: autoDispose clears sensitive data (email) when user leaves screen
final bookingReferenceProvider = StateProvider.autoDispose<String>((ref) => '');
final lookupEmailProvider = StateProvider.autoDispose<String>((ref) => '');

/// Async provider for booking lookup result
/// This provider is used when user performs manual lookup
final bookingLookupProvider =
    FutureProvider.family<BookingDetailsModel, LookupParams>((
      ref,
      params,
    ) async {
      final service = ref.watch(bookingLookupServiceProvider);

      return await service.verifyBookingAccess(
        bookingReference: params.bookingReference,
        email: params.email,
        accessToken: params.accessToken,
      );
    });

/// Parameters for booking lookup
class LookupParams {
  final String bookingReference;
  final String email;
  final String? accessToken;

  const LookupParams({
    required this.bookingReference,
    required this.email,
    this.accessToken,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LookupParams &&
        other.bookingReference == bookingReference &&
        other.email == email &&
        other.accessToken == accessToken;
  }

  @override
  int get hashCode =>
      bookingReference.hashCode ^ email.hashCode ^ (accessToken?.hashCode ?? 0);
}
