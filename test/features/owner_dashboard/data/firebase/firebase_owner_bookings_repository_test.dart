import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bookbed/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart';
import 'package:bookbed/core/exceptions/app_exceptions.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  group('FirebaseOwnerBookingsRepository Error Paths', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late FirebaseOwnerBookingsRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('owner123');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      repository = FirebaseOwnerBookingsRepository(fakeFirestore, mockAuth);
    });

    group('Auth Exceptions', () {
      test('getOwnerBookings throws when unauthenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        expect(
          () => repository.getOwnerBookings(),
          throwsA(
            isA<BookingException>().having(
              (e) => e.originalError,
              'originalError',
              isA<AuthException>().having(
                (e) => e.code,
                'code',
                'auth/not-authenticated',
              ),
            ),
          ),
        );
      });
    });

    group('Booking Operations Exception paths', () {
      test('approveBooking throws when booking not found', () async {
        expect(
          () => repository.approveBooking('non_existent_booking'),
          throwsA(
            isA<BookingException>()
                .having((e) => e.code, 'code', 'booking/approval-failed')
                .having(
                  (e) => (e.originalError as BookingException).code,
                  'original error code',
                  'booking/not-found',
                ),
          ),
        );
      });

      test('rejectBooking throws when booking not found', () async {
        expect(
          () => repository.rejectBooking(
            'non_existent_booking',
            reason: 'Test reason',
          ),
          throwsA(
            isA<BookingException>()
                .having((e) => e.code, 'code', 'booking/rejection-failed')
                .having(
                  (e) => (e.originalError as BookingException).code,
                  'original error code',
                  'booking/not-found',
                ),
          ),
        );
      });

      test('confirmBooking throws when booking not found', () async {
        expect(
          () => repository.confirmBooking('non_existent_booking'),
          throwsA(
            isA<BookingException>()
                .having((e) => e.code, 'code', 'booking/confirmation-failed')
                .having(
                  (e) => (e.originalError as BookingException).code,
                  'original error code',
                  'booking/not-found',
                ),
          ),
        );
      });

      test('cancelBooking throws when booking not found', () async {
        expect(
          () => repository.cancelBooking('non_existent_booking', 'Test cancel'),
          throwsA(
            isA<BookingException>()
                .having((e) => e.code, 'code', 'booking/cancellation-failed')
                .having(
                  (e) => (e.originalError as BookingException).code,
                  'original error code',
                  'booking/not-found',
                ),
          ),
        );
      });

      test('completeBooking throws when booking not found', () async {
        expect(
          () => repository.completeBooking('non_existent_booking'),
          throwsA(
            isA<BookingException>()
                .having((e) => e.code, 'code', 'booking/completion-failed')
                .having(
                  (e) => (e.originalError as BookingException).code,
                  'original error code',
                  'booking/not-found',
                ),
          ),
        );
      });

      test('deleteBooking throws when booking not found', () async {
        expect(
          () => repository.deleteBooking('non_existent_booking'),
          throwsA(
            isA<BookingException>()
                .having((e) => e.code, 'code', 'booking/deletion-failed')
                .having(
                  (e) => (e.originalError as BookingException).code,
                  'original error code',
                  'booking/not-found',
                ),
          ),
        );
      });
    });
  });
}
