import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bookbed/core/services/booking_service.dart';
import 'package:bookbed/shared/models/booking_model.dart';
import 'package:bookbed/core/constants/enums.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}
class MockHttpsCallable extends Mock implements HttpsCallable {}
class MockHttpsCallableResult<T> extends Mock implements HttpsCallableResult<T> {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late BookingService bookingService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();

    when(() => mockFunctions.httpsCallable('createBookingAtomic'))
        .thenReturn(mockCallable);

    bookingService = BookingService(
      firestore: fakeFirestore,
      functions: mockFunctions,
    );
  });

  group('createBooking', () {
    test('throws Exception if required fields are missing', () async {
      expect(
        () => bookingService.createBooking(
          unitId: '', // Invalid
          propertyId: 'prop123',
          ownerId: 'owner123',
          checkIn: DateTime(2024, 8, 1),
          checkOut: DateTime(2024, 8, 5),
          guestName: 'John Doe',
          guestEmail: 'john@example.com',
          guestPhone: '+1234567890',
          guestCount: 2,
          totalPrice: 500.0,
          paymentOption: 'full',
          paymentMethod: 'bank_transfer',
        ),
        throwsException,
      );
    });

    test('returns booking for successful creation', () async {
      final mockResult = MockHttpsCallableResult<Map<String, dynamic>>();
      when(() => mockResult.data).thenReturn({
        'isStripeValidation': false,
        'bookingId': 'book123',
        'bookingReference': 'BK-123456',
        'depositAmount': 0.0,
      });

      when(() => mockCallable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => mockResult);

      final result = await bookingService.createBooking(
        unitId: 'unit123',
        propertyId: 'prop123',
        ownerId: 'owner123',
        checkIn: DateTime(2024, 8, 1),
        checkOut: DateTime(2024, 8, 5),
        guestName: 'John Doe',
        guestEmail: 'john@example.com',
        guestPhone: '+1234567890',
        guestCount: 2,
        totalPrice: 500.0,
        paymentOption: 'full',
        paymentMethod: 'bank_transfer',
      );

      expect(result.isStripeValidation, isFalse);
      expect(result.booking, isNotNull);
      expect(result.booking!.id, 'book123');
      expect(result.booking!.bookingReference, 'BK-123456');
      expect(result.booking!.status, BookingStatus.pending);
    });

    test('returns Stripe validation data for Stripe payments', () async {
      final mockResult = MockHttpsCallableResult<Map<String, dynamic>>();
      when(() => mockResult.data).thenReturn({
        'isStripeValidation': true,
        'bookingData': {
          'depositAmount': 100.0,
        },
      });

      when(() => mockCallable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => mockResult);

      final result = await bookingService.createBooking(
        unitId: 'unit123',
        propertyId: 'prop123',
        ownerId: 'owner123',
        checkIn: DateTime(2024, 8, 1),
        checkOut: DateTime(2024, 8, 5),
        guestName: 'John Doe',
        guestEmail: 'john@example.com',
        guestPhone: '+1234567890',
        guestCount: 2,
        totalPrice: 500.0,
        paymentOption: 'deposit',
        paymentMethod: 'stripe',
      );

      expect(result.isStripeValidation, isTrue);
      expect(result.depositAmount, 100.0);
      expect(result.stripeBookingData, isNotNull);
    });

    test('handles already-exists FirebaseFunctionsException', () async {
      when(() => mockCallable.call<Map<String, dynamic>>(any()))
          .thenThrow(FirebaseFunctionsException(message: 'Already exists', code: 'already-exists'));

      expect(
        () => bookingService.createBooking(
          unitId: 'unit123',
          propertyId: 'prop123',
          ownerId: 'owner123',
          checkIn: DateTime(2024, 8, 1),
          checkOut: DateTime(2024, 8, 5),
          guestName: 'John Doe',
          guestEmail: 'john@example.com',
          guestPhone: '+1234567890',
          guestCount: 2,
          totalPrice: 500.0,
          paymentOption: 'full',
          paymentMethod: 'bank_transfer',
        ),
        throwsA(isA<BookingConflictException>()),
      );
    });

    test('handles invalid-argument FirebaseFunctionsException', () async {
      when(() => mockCallable.call<Map<String, dynamic>>(any()))
          .thenThrow(FirebaseFunctionsException(message: 'Invalid argument', code: 'invalid-argument'));

      expect(
        () => bookingService.createBooking(
          unitId: 'unit123',
          propertyId: 'prop123',
          ownerId: 'owner123',
          checkIn: DateTime(2024, 8, 1),
          checkOut: DateTime(2024, 8, 5),
          guestName: 'John Doe',
          guestEmail: 'john@example.com',
          guestPhone: '+1234567890',
          guestCount: 2,
          totalPrice: 500.0,
          paymentOption: 'full',
          paymentMethod: 'bank_transfer',
        ),
        throwsA(isA<BookingServiceException>()),
      );
    });
  });

  group('getBookingById', () {
    test('finds booking in legacy top-level collection', () async {
      await fakeFirestore.collection('bookings').doc('legacy123').set({
        'unit_id': 'unit123',
        'status': 'confirmed',
        'check_in': Timestamp.fromDate(DateTime(2024, 8, 1)),
        'check_out': Timestamp.fromDate(DateTime(2024, 8, 5)),
        'guest_name': 'Jane Doe',
        'total_price': 300.0,
        'advance_amount': 0.0,
        'payment_method': 'none',
        'payment_status': 'not_required',
        'booking_reference': 'BK-LEGACY',
        'created_at': Timestamp.fromDate(DateTime(2024, 7, 1)),
      });

      final booking = await bookingService.getBookingById('legacy123');
      expect(booking, isNotNull);
      expect(booking!.id, 'legacy123');
      expect(booking.unitId, 'unit123');
    });

    test('finds booking via collectionGroup query if not in top-level', () async {
      await fakeFirestore
          .collection('properties')
          .doc('prop1')
          .collection('bookings')
          .doc('nested123')
          .set({
        'unit_id': 'unit123',
        'status': 'pending',
        'check_in': Timestamp.fromDate(DateTime(2024, 8, 1)),
        'check_out': Timestamp.fromDate(DateTime(2024, 8, 5)),
        'guest_name': 'Jane Doe',
        'total_price': 300.0,
        'advance_amount': 0.0,
        'payment_method': 'none',
        'payment_status': 'not_required',
        'booking_reference': 'BK-NESTED',
        'created_at': Timestamp.fromDate(DateTime(2024, 7, 1)),
      });

      final booking = await bookingService.getBookingById('nested123');
      expect(booking, isNotNull);
      expect(booking!.id, 'nested123');
      expect(booking.bookingReference, 'BK-NESTED');
    });

    test('returns null if booking not found', () async {
      final booking = await bookingService.getBookingById('nonexistent');
      expect(booking, isNull);
    });
  });
}
