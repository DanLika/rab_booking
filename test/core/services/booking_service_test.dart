import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:bookbed/core/services/booking_service.dart';
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

  group('BookingService.createBooking', () {
    final checkInDate = DateTime(2024, 7, 1);
    final checkOutDate = DateTime(2024, 7, 5);

    test('throws Exception when missing required fields (empty strings)', () async {
      expect(
        () => bookingService.createBooking(
          unitId: '', // Empty unitId
          propertyId: 'prop123',
          ownerId: 'owner123',
          checkIn: checkInDate,
          checkOut: checkOutDate,
          guestName: 'John Doe',
          guestEmail: 'john@example.com',
          guestPhone: '+123456789',
          guestCount: 2,
          totalPrice: 500.0,
          paymentOption: 'full',
          paymentMethod: 'bank_transfer',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Missing required booking fields'))),
      );
    });

    test('returns stripeValidation correctly when function returns isStripeValidation', () async {
      final mockResult = MockHttpsCallableResult<Map<String, dynamic>>();
      when(() => mockResult.data).thenReturn(
        {
          'isStripeValidation': true,
          'bookingData': {
            'depositAmount': 100.0,
            'other': 'data',
          },
        },
      );

      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => mockResult,
      );

      final result = await bookingService.createBooking(
        unitId: 'unit123',
        propertyId: 'prop123',
        ownerId: 'owner123',
        checkIn: checkInDate,
        checkOut: checkOutDate,
        guestName: 'John Doe',
        guestEmail: 'john@example.com',
        guestPhone: '+123456789',
        guestCount: 2,
        totalPrice: 500.0,
        paymentOption: 'deposit',
        paymentMethod: 'stripe',
      );

      expect(result.isStripeValidation, true);
      expect(result.depositAmount, 100.0);
      expect(result.stripeBookingData, {'depositAmount': 100.0, 'other': 'data'});
      expect(result.booking, isNull);
    });

    test('returns booking correctly for non-Stripe', () async {
      final mockResult = MockHttpsCallableResult<Map<String, dynamic>>();
      when(() => mockResult.data).thenReturn(
        {
          'isStripeValidation': false,
          'bookingId': 'booking_123',
          'bookingReference': 'REF-123',
          'depositAmount': 0.0,
        },
      );

      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => mockResult,
      );

      final result = await bookingService.createBooking(
        unitId: 'unit123',
        propertyId: 'prop123',
        ownerId: 'owner123',
        checkIn: checkInDate,
        checkOut: checkOutDate,
        guestName: 'John Doe',
        guestEmail: 'john@example.com',
        guestPhone: '+123456789',
        guestCount: 2,
        totalPrice: 500.0,
        paymentOption: 'none',
        paymentMethod: 'none',
      );

      expect(result.isStripeValidation, false);
      expect(result.booking, isNotNull);
      expect(result.booking!.id, 'booking_123');
      expect(result.booking!.bookingReference, 'REF-123');
      expect(result.booking!.status, BookingStatus.pending);
      expect(result.booking!.paymentStatus, 'not_required');
    });

    test('throws BookingConflictException on already-exists FirebaseFunctionsException', () async {
      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(
          message: 'Already exists',
          code: 'already-exists',
        ),
      );

      expect(
        () => bookingService.createBooking(
          unitId: 'unit123',
          propertyId: 'prop123',
          ownerId: 'owner123',
          checkIn: checkInDate,
          checkOut: checkOutDate,
          guestName: 'John Doe',
          guestEmail: 'john@example.com',
          guestPhone: '+123456789',
          guestCount: 2,
          totalPrice: 500.0,
          paymentOption: 'full',
          paymentMethod: 'bank_transfer',
        ),
        throwsA(isA<BookingConflictException>()),
      );
    });

    test('throws BookingServiceException on invalid-argument FirebaseFunctionsException', () async {
      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(
          message: 'Invalid argument',
          code: 'invalid-argument',
        ),
      );

      expect(
        () => bookingService.createBooking(
          unitId: 'unit123',
          propertyId: 'prop123',
          ownerId: 'owner123',
          checkIn: checkInDate,
          checkOut: checkOutDate,
          guestName: 'John Doe',
          guestEmail: 'john@example.com',
          guestPhone: '+123456789',
          guestCount: 2,
          totalPrice: 500.0,
          paymentOption: 'full',
          paymentMethod: 'bank_transfer',
        ),
        throwsA(isA<BookingServiceException>().having((e) => e.message, 'message', contains('Invalid booking data'))),
      );
    });
  });
}
