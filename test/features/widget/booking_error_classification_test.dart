// Guards the guest-facing error copy fix (2026-07-13 PROD widget E2E): a guest
// who lost wifi mid-submit was shown "Error creating booking:
// BookingServiceException: Failed to create booking: internal" — raw
// developer text. Connectivity failures must be classified so the guest gets
// an actionable "check your connection" instead.

import 'package:bookbed/features/widget/presentation/helpers/booking_widget_url_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isConnectivityError', () {
    for (final msg in const [
      'BookingServiceException: Failed to create booking: unavailable',
      '[firebase_functions/unavailable] Could not reach Cloud Firestore',
      'FirebaseFunctionsException: DEADLINE-EXCEEDED',
      'SocketException: Failed host lookup: view.bookbed.io',
      'Network request failed',
      'Connection closed before full header was received',
      'FirebaseException: Client is offline',
    ]) {
      test('flags "$msg" as connectivity', () {
        expect(isConnectivityError(msg), isTrue);
      });
    }

    for (final msg in const [
      'Price mismatch detected',
      'Dates no longer available',
      'invalid-argument: guestEmail is required',
      'permission-denied',
    ]) {
      test('does NOT flag "$msg" as connectivity', () {
        expect(isConnectivityError(msg), isFalse);
      });
    }

    test('null is not connectivity', () {
      expect(isConnectivityError(null), isFalse);
    });
  });
}
