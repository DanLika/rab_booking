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
  /// Dodaje standardni Firestore timeout (30s)
  ///
  /// Baca [TimeoutException] ako operacija ne završi u roku.
  Future<T> withFirestoreTimeout([String? operationName]) {
    return timeout(
      TimeoutConstants.firestoreQuery,
      onTimeout: () => throw TimeoutException(
        operationName != null
            ? '$operationName timed out after ${TimeoutConstants.firestoreQuery.inSeconds}s'
            : 'Firestore query timed out after ${TimeoutConstants.firestoreQuery.inSeconds}s',
      ),
    );
  }

  /// Dodaje standardni HTTP timeout (15s)
  ///
  /// Baca [TimeoutException] ako operacija ne završi u roku.
  Future<T> withHttpTimeout([String? operationName]) {
    return timeout(
      TimeoutConstants.httpRequest,
      onTimeout: () => throw TimeoutException(
        operationName != null
            ? '$operationName timed out after ${TimeoutConstants.httpRequest.inSeconds}s'
            : 'HTTP request timed out after ${TimeoutConstants.httpRequest.inSeconds}s',
      ),
    );
  }

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

  /// Dodaje custom timeout
  ///
  /// Baca [TimeoutException] ako operacija ne završi u roku.
  Future<T> withCustomTimeout(Duration duration, [String? operationName]) {
    return timeout(
      duration,
      onTimeout: () => throw TimeoutException(
        operationName != null
            ? '$operationName timed out after ${duration.inSeconds}s'
            : 'Operation timed out after ${duration.inSeconds}s',
      ),
    );
  }
}

/// Extension za Stream timeout na prvi element
extension StreamTimeoutExtension<T> on Stream<T> {
  /// Čeka prvi element sa timeout-om
  ///
  /// Korisno za real-time listener-e gdje želimo prvi snapshot sa timeout-om.
  Future<T> firstWithTimeout([Duration? duration, String? operationName]) {
    final timeout = duration ?? TimeoutConstants.realtimeInitial;
    return first.timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        operationName != null
            ? '$operationName timed out waiting for first value after ${timeout.inSeconds}s'
            : 'Stream timed out waiting for first value after ${timeout.inSeconds}s',
      ),
    );
  }
}
