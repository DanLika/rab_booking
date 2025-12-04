import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/exceptions/app_exceptions.dart';
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

      // Parse the response
      final response = BookingLookupResponse.fromJson(result.data);

      if (!response.success) {
        throw BookingException.lookupFailed('Booking verification failed');
      }

      return response.booking;
    } on FirebaseFunctionsException catch (e) {
      // Handle specific Firebase Functions errors
      switch (e.code) {
        case 'not-found':
          throw BookingException(
              'Booking not found. Please check your booking reference.',
              code: 'booking/not-found');
        case 'permission-denied':
          throw BookingException(
              'Email does not match booking records or link has expired.',
              code: 'booking/permission-denied');
        case 'invalid-argument':
          throw BookingException('Booking reference and email are required.',
              code: 'booking/invalid-argument');
        default:
          throw BookingException.lookupFailed(e.message);
      }
    } catch (e) {
      throw BookingException.lookupFailed(e);
    }
  }
}

/// State provider for manual lookup form
final bookingReferenceProvider = StateProvider<String>((ref) => '');
final lookupEmailProvider = StateProvider<String>((ref) => '');

/// Async provider for booking lookup result
/// This provider is used when user performs manual lookup
final bookingLookupProvider =
    FutureProvider.family<BookingDetailsModel, LookupParams>((ref, params) async {
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
