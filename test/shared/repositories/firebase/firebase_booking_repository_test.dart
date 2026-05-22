import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookbed/shared/repositories/firebase/firebase_booking_repository.dart';
import 'package:bookbed/shared/models/booking_model.dart';
import 'package:bookbed/core/constants/enums.dart';
import 'package:bookbed/core/exceptions/app_exceptions.dart';

void main() {
  group('FirebaseBookingRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirebaseBookingRepository repository;

    final now = DateTime.now();
    final checkIn = now.add(const Duration(days: 1));
    final checkOut = now.add(const Duration(days: 3));

    BookingModel createTestBooking({
      String id = '', // Empty for creation since add() generates one
      String propertyId = 'prop_1',
      String unitId = 'unit_1',
      String userId = 'user_1',
      String ownerId = 'owner_1',
      BookingStatus status = BookingStatus.confirmed,
      DateTime? start,
      DateTime? end,
    }) {
      return BookingModel(
        id: id,
        propertyId: propertyId,
        unitId: unitId,
        userId: userId,
        ownerId: ownerId,
        checkIn: start ?? checkIn,
        checkOut: end ?? checkOut,
        status: status,
        totalPrice: 100.0,
        guestName: 'John Doe',
        guestCount: 2,
        createdAt: now,
        updatedAt: now,
      );
    }

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirebaseBookingRepository(firestore);
    });

    group('createBooking', () {
      test('creates booking correctly in subcollection', () async {
        final booking = createTestBooking();

        final result = await repository.createBooking(booking);

        expect(result.id, isNotEmpty);
        expect(result.id, isNot(booking.id)); // Should be a generated ID
        expect(result.bookingReference, isNotNull);

        // Verify in Firestore
        final doc = await firestore
            .collection('properties')
            .doc('prop_1')
            .collection('units')
            .doc('unit_1')
            .collection('bookings')
            .doc(result.id)
            .get();

        expect(doc.exists, isTrue);
        expect(doc.data()!['user_id'], 'user_1');
      });
    });

    group('fetchBookingById', () {
      test('fetches booking correctly with unitId hint', () async {
        final booking = createTestBooking();
        final created = await repository.createBooking(booking);

        final fetched = await repository.fetchBookingById(
          created.id,
          unitId: 'unit_1',
        );

        expect(fetched, isNotNull);
        expect(fetched?.id, created.id);
      });

      test('fetches booking correctly without unitId hint using collectionGroup', () async {
        final booking = createTestBooking();
        final created = await repository.createBooking(booking);

        final fetched = await repository.fetchBookingById(created.id);

        expect(fetched, isNotNull);
        expect(fetched?.id, created.id);
      });

      test('returns null if booking does not exist', () async {
        final fetched = await repository.fetchBookingById('non_existent');
        expect(fetched, isNull);
      });
    });

    group('updateBooking', () {
      test('updates booking in same unit', () async {
        final booking = createTestBooking();
        final created = await repository.createBooking(booking);

        final updatedBooking = created.copyWith(guestName: 'Jane Doe');

        final result = await repository.updateBooking(updatedBooking);

        expect(result.guestName, 'Jane Doe');

        final doc = await firestore
            .collection('properties')
            .doc('prop_1')
            .collection('units')
            .doc('unit_1')
            .collection('bookings')
            .doc(created.id)
            .get();

        expect(doc.data()!['guest_name'], 'Jane Doe');
      });

      test('moves booking across units using batch', () async {
        final booking = createTestBooking();
        final created = await repository.createBooking(booking);

        final updatedBooking = created.copyWith(unitId: 'unit_2');

        await repository.updateBooking(updatedBooking, originalBooking: created);

        // Verify old location is empty
        final oldDoc = await firestore
            .collection('properties')
            .doc('prop_1')
            .collection('units')
            .doc('unit_1')
            .collection('bookings')
            .doc(created.id)
            .get();
        expect(oldDoc.exists, isFalse);

        // Verify new location exists
        final newDoc = await firestore
            .collection('properties')
            .doc('prop_1')
            .collection('units')
            .doc('unit_2')
            .collection('bookings')
            .doc(created.id)
            .get();
        expect(newDoc.exists, isTrue);
      });
    });

    group('deleteBooking', () {
      test('deletes booking when provided directly', () async {
        final booking = createTestBooking();
        final created = await repository.createBooking(booking);

        await repository.deleteBooking(created.id, booking: created);

        final fetched = await repository.fetchBookingById(created.id);
        expect(fetched, isNull);
      });

      test('throws BookingException if not found', () async {
        expect(
          () => repository.deleteBooking('non_existent'),
          throwsA(isA<BookingException>()),
        );
      });
    });

    group('Collection queries', () {
      late BookingModel b1;
      late BookingModel b2;
      late BookingModel b3;

      setUp(() async {
        b1 = await repository.createBooking(createTestBooking());
        b2 = await repository.createBooking(createTestBooking(propertyId: 'prop_2'));
        b3 = await repository.createBooking(createTestBooking(userId: 'user_2'));
      });

      test('fetchUserBookings retrieves for specific user', () async {
        final bookings = await repository.fetchUserBookings('user_1');
        expect(bookings.length, 2);
        expect(bookings.map((b) => b.id).toSet(), {b1.id, b2.id});
      });

      test('fetchPropertyBookings retrieves for specific property', () async {
        final bookings = await repository.fetchPropertyBookings('prop_1');
        expect(bookings.length, 2);
        expect(bookings.map((b) => b.id).toSet(), {b1.id, b3.id});
      });
    });

    group('Status updates', () {
      test('updateBookingStatus updates status', () async {
        final booking = createTestBooking(status: BookingStatus.pending);
        final created = await repository.createBooking(booking);

        final result = await repository.updateBookingStatus(created.id, BookingStatus.confirmed);

        expect(result.status, BookingStatus.confirmed);
      });

      test('cancelBooking updates status and reason', () async {
        final booking = createTestBooking();
        final created = await repository.createBooking(booking);

        final result = await repository.cancelBooking(created.id, 'Changed mind');

        expect(result.status, BookingStatus.cancelled);
        expect(result.cancellationReason, 'Changed mind');
        expect(result.cancelledAt, isNotNull);
      });
    });

    group('Availability', () {
      test('areDatesAvailable returns false for overlapping', () async {
        final start = now.add(const Duration(days: 10));
        final end = now.add(const Duration(days: 15));

        await repository.createBooking(createTestBooking(start: start, end: end));

        final available = await repository.areDatesAvailable(
          unitId: 'unit_1',
          checkIn: start.add(const Duration(days: 2)), // overlaps
          checkOut: end.add(const Duration(days: 2)),
        );

        expect(available, isFalse);
      });

      test('areDatesAvailable returns true for non-overlapping', () async {
        final start = now.add(const Duration(days: 10));
        final end = now.add(const Duration(days: 15));

        await repository.createBooking(createTestBooking(start: start, end: end));

        final available = await repository.areDatesAvailable(
          unitId: 'unit_1',
          checkIn: end, // check-in on same day as check-out is allowed
          checkOut: end.add(const Duration(days: 5)),
        );

        expect(available, isTrue);
      });

      test('areDatesAvailable allows exclusion', () async {
        final start = now.add(const Duration(days: 10));
        final end = now.add(const Duration(days: 15));

        final booking = createTestBooking(start: start, end: end);
        final created = await repository.createBooking(booking);

        final available = await repository.areDatesAvailable(
          unitId: 'unit_1',
          checkIn: start,
          checkOut: end,
          excludeBookingId: created.id,
        );

        expect(available, isTrue);
      });
    });

    group('Data Path Extraction', () {
      test('extracts missing propertyId from path during query', () async {
        final booking = createTestBooking();
        // Insert manually missing property_id
        await firestore
            .collection('properties')
            .doc('prop_test_123')
            .collection('units')
            .doc('unit_1')
            .collection('bookings')
            .doc('missing_prop_booking')
            .set({
              'unit_id': 'unit_1',
              'user_id': 'user_1',
              'owner_id': 'owner_1',
              'check_in': Timestamp.fromDate(booking.checkIn),
              'check_out': Timestamp.fromDate(booking.checkOut),
              'status': 'confirmed',
              'total_price': 100.0,
              'guest_name': 'Test',
              'guest_count': 2,
              'created_at': Timestamp.fromDate(booking.createdAt),
              'updated_at': Timestamp.fromDate(booking.updatedAt!),
              // No property_id
            });

        final result = await repository.fetchBookingById('missing_prop_booking');
        expect(result, isNotNull);
        expect(result!.propertyId, 'prop_test_123'); // Extracted from path
      });
    });
  });
}
