import 'dart:async';
import '../constants/timeout_constants.dart';

/// Extension za dodavanje standardnih timeout-ova na Future
///
/// Primjeri korištenja:
/// ```dart
/// // Sa default timeout porukom
/// final result = await repository.getBooking(id).withFirestoreTimeout();
///
/// // Sa custom imenom operacije za bolji error message
/// final result = await repository.getBooking(id).withFirestoreTimeout('getBookingById');
///
/// // Sa custom timeout duration
/// final result = await repository.getBooking(id).withCustomTimeout(
///   Duration(seconds: 45),
///   'longRunningOperation',
/// );
/// ```
extension FutureTimeoutExtension<T> on Future<T> {
  /// Dodaje standardni Cloud Function timeout (60s)
  ///
  /// Baca [TimeoutException] ako operacija ne završi u roku.
  Future<T> withCloudFunctionTimeout([String? operationName]) {
    return timeout(
      TimeoutConstants.cloudFunction,
      onTimeout: () => throw TimeoutException(
        operationName != null
            ? '$operationName timed out after ${TimeoutConstants.cloudFunction.inSeconds}s'
            : 'Cloud Function timed out after ${TimeoutConstants.cloudFunction.inSeconds}s',
      ),
    );
  }

  /// Dodaje timeout za booking fetch operacije (10s)
  ///
  /// Baca [TimeoutException] ako operacija ne završi u roku.
  Future<T> withBookingFetchTimeout([String? operationName]) {
    return timeout(
      TimeoutConstants.bookingFetch,
      onTimeout: () => throw TimeoutException(
        operationName != null
            ? '$operationName timed out after ${TimeoutConstants.bookingFetch.inSeconds}s'
            : 'Booking fetch timed out after ${TimeoutConstants.bookingFetch.inSeconds}s',
      ),
    );
  }

  /// Dodaje timeout za list fetch operacije (20s)
  ///
  /// Baca [TimeoutException] ako operacija ne završi u roku.
  Future<T> withListFetchTimeout([String? operationName]) {
    return timeout(
      TimeoutConstants.listFetch,
      onTimeout: () => throw TimeoutException(
        operationName != null
            ? '$operationName timed out after ${TimeoutConstants.listFetch.inSeconds}s'
            : 'List fetch timed out after ${TimeoutConstants.listFetch.inSeconds}s',
      ),
    );
  }

  /// Dodaje short operation timeout (5s)
  ///
  /// Baca [TimeoutException] ako operacija ne završi u roku.
  Future<T> withShortTimeout([String? operationName]) {
    return timeout(
      TimeoutConstants.shortOperation,
      onTimeout: () => throw TimeoutException(
        operationName != null
            ? '$operationName timed out after ${TimeoutConstants.shortOperation.inSeconds}s'
            : 'Operation timed out after ${TimeoutConstants.shortOperation.inSeconds}s',
      ),
    );
  }

}
