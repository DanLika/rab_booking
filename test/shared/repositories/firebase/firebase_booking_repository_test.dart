import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/shared/repositories/firebase/firebase_booking_repository.dart';
import 'package:bookbed/shared/models/booking_model.dart';
import 'package:bookbed/core/constants/enums.dart';

void main() {
  group('FirebaseBookingRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseBookingRepository repository;

    final now = DateTime.now();

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirebaseBookingRepository(fakeFirestore);
    });

    Future<void> seedBooking(BookingModel booking) async {
      await fakeFirestore
          .collection('properties')
          .doc(booking.propertyId)
          .collection('units')
          .doc(booking.unitId)
          .collection('bookings')
          .doc(booking.id)
          .set(booking.toJson());
    }

    group('initialization', () {
      test('repository can be instantiated', () {
        expect(repository, isNotNull);
      });
    });

    group('booking fetching', () {
      final sampleBooking = BookingModel(
        id: 'b1',
        unitId: 'u1',
        propertyId: 'p1',
        userId: 'user1',
        checkIn: now.add(const Duration(days: 1)),
        checkOut: now.add(const Duration(days: 3)),
        status: BookingStatus.confirmed,
        createdAt: now,
        totalPrice: 100,
      );

      final sampleBooking2 = BookingModel(
        id: 'b2',
        unitId: 'u1',
        propertyId: 'p1',
        userId: 'user2',
        checkIn: now.add(const Duration(days: 5)),
        checkOut: now.add(const Duration(days: 7)),
        status: BookingStatus.pending,
        createdAt: now,
        totalPrice: 150,
      );

      setUp(() async {
        await seedBooking(sampleBooking);
        await seedBooking(sampleBooking2);
      });

      test('fetchBookingById returns booking', () async {
        final booking = await repository.fetchBookingById('b1');
        expect(booking, isNotNull);
        expect(booking!.id, 'b1');
      });

      test('fetchBookingById returns null if not found', () async {
        final booking = await repository.fetchBookingById('not_found');
        expect(booking, isNull);
      });

      test('fetchUnitBookings returns correct bookings', () async {
        final bookings = await repository.fetchUnitBookings('u1');
        expect(bookings.length, 2);
        final ids = bookings.map((b) => b.id).toList();
        expect(ids, containsAll(['b1', 'b2']));
      });

      test('fetchUserBookings returns correct bookings', () async {
        final bookings = await repository.fetchUserBookings('user1');
        expect(bookings.length, 1);
        expect(bookings.first.id, 'b1');
      });

      test('fetchPropertyBookings returns correct bookings', () async {
        final bookings = await repository.fetchPropertyBookings('p1');
        expect(bookings.length, 2);
        final ids = bookings.map((b) => b.id).toList();
        expect(ids, containsAll(['b1', 'b2']));
      });

      test('getBookingsInRange filters by date and fields correctly', () async {
        final bookings = await repository.getBookingsInRange(
          unitId: 'u1',
          startDate: now.add(const Duration(days: 4)), // b2 overlap
          endDate: now.add(const Duration(days: 8)),
        );
        expect(bookings.length, 1);
        expect(bookings.first.id, 'b2');

        final userBookings = await repository.getBookingsInRange(
          userId: 'user1',
        );
        expect(userBookings.length, 1);
        expect(userBookings.first.id, 'b1');
      });
    });

    group('booking status and types queries', () {
      final pastBooking = BookingModel(
        id: 'b_past',
        unitId: 'u1',
        propertyId: 'p1',
        userId: 'user1',
        ownerId: 'owner1',
        checkIn: now.subtract(const Duration(days: 10)),
        checkOut: now.subtract(const Duration(days: 5)),
        status: BookingStatus.completed,
        totalPrice: 100,
        createdAt: now.subtract(const Duration(days: 15)),
      );

      final currentBooking = BookingModel(
        id: 'b_current',
        unitId: 'u1',
        propertyId: 'p1',
        userId: 'user1',
        ownerId: 'owner1',
        checkIn: now.subtract(const Duration(days: 2)),
        checkOut: now.add(const Duration(days: 2)),
        status: BookingStatus.confirmed,
        totalPrice: 150,
        createdAt: now.subtract(const Duration(days: 5)),
      );

      final upcomingBooking = BookingModel(
        id: 'b_upcoming',
        unitId: 'u1',
        propertyId: 'p1',
        userId: 'user1',
        ownerId: 'owner2',
        checkIn: now.add(const Duration(days: 5)),
        checkOut: now.add(const Duration(days: 10)),
        status: BookingStatus.pending,
        totalPrice: 200,
        createdAt: now,
      );

      setUp(() async {
        await seedBooking(pastBooking);
        await seedBooking(currentBooking);
        await seedBooking(upcomingBooking);
      });

      test('getBookingsByStatus returns correct bookings', () async {
        final confirmedBookings = await repository.getBookingsByStatus(
          userId: 'user1',
          status: BookingStatus.confirmed,
        );
        expect(confirmedBookings.length, 1);
        expect(confirmedBookings.first.id, 'b_current');

        final pendingBookings = await repository.getBookingsByStatus(
          userId: 'user1',
          status: BookingStatus.pending,
        );
        expect(pendingBookings.length, 1);
        expect(pendingBookings.first.id, 'b_upcoming');
      });

      test('getUpcomingBookings returns bookings in future', () async {
        final upcoming = await repository.getUpcomingBookings('user1');
        // Only b_upcoming has checkIn > now
        expect(upcoming.length, 1);
        expect(upcoming.first.id, 'b_upcoming');
      });

      test('getCurrentBookings returns ongoing bookings', () async {
        final current = await repository.getCurrentBookings('user1');
        // Both past and upcoming don't overlap with strictly 'now' internally using isCurrent
        // currentBooking checks checkIn <= now and checkOut >= now
        expect(current.length, 1);
        expect(current.first.id, 'b_current');
      });

      test('getPastBookings returns bookings in the past', () async {
        final past = await repository.getPastBookings('user1');
        // Only pastBooking has checkOut < now
        expect(past.length, 1);
        expect(past.first.id, 'b_past');
      });

      test('getOwnerBookings returns bookings for owner', () async {
        final owner1Bookings = await repository.getOwnerBookings('owner1');
        expect(owner1Bookings.length, 2);
        final ids = owner1Bookings.map((b) => b.id).toList();
        expect(ids, containsAll(['b_past', 'b_current']));

        final owner2Bookings = await repository.getOwnerBookings('owner2');
        expect(owner2Bookings.length, 1);
        expect(owner2Bookings.first.id, 'b_upcoming');
      });
    });

    group('booking creation and modification', () {
      final baseBooking = BookingModel(
        id: 'b_create',
        unitId: 'u1',
        propertyId: 'p1',
        userId: 'user1',
        checkIn: now.add(const Duration(days: 1)),
        checkOut: now.add(const Duration(days: 3)),
        status: BookingStatus.pending,
        totalPrice: 100,
        createdAt: now,
      );

      test('createBooking adds document and assigns reference', () async {
        final created = await repository.createBooking(baseBooking);
        expect(created.id, isNotEmpty);
        expect(
          created.id,
          isNot('b_create'),
        ); // Firestore generates new ID on add
        expect(created.bookingReference, startsWith('BK-'));

        final fetched = await repository.fetchBookingById(created.id);
        expect(fetched, isNotNull);
        expect(fetched!.unitId, 'u1');
        expect(fetched.propertyId, 'p1');
      });

      test('updateBooking updates existing document in same unit', () async {
        await seedBooking(baseBooking);
        final updatedBooking = baseBooking.copyWith(totalPrice: 250);

        await repository.updateBooking(updatedBooking);

        final fetched = await repository.fetchBookingById('b_create');
        expect(fetched!.totalPrice, 250);
      });

      test('updateBooking moves document if unit changed', () async {
        await seedBooking(baseBooking);
        final updatedBooking = baseBooking.copyWith(unitId: 'u2');

        await repository.updateBooking(
          updatedBooking,
          originalBooking: baseBooking,
        );

        // Check it's gone from u1
        final oldDoc = await fakeFirestore
            .collection('properties')
            .doc('p1')
            .collection('units')
            .doc('u1')
            .collection('bookings')
            .doc('b_create')
            .get();
        expect(oldDoc.exists, isFalse);

        // Check it exists in u2
        final newDoc = await fakeFirestore
            .collection('properties')
            .doc('p1')
            .collection('units')
            .doc('u2')
            .collection('bookings')
            .doc('b_create')
            .get();
        expect(newDoc.exists, isTrue);
      });

      test('updateBookingStatus updates status', () async {
        await seedBooking(baseBooking);

        final updated = await repository.updateBookingStatus(
          'b_create',
          BookingStatus.confirmed,
        );
        expect(updated.status, BookingStatus.confirmed);

        final fetched = await repository.fetchBookingById('b_create');
        expect(fetched!.status, BookingStatus.confirmed);
      });

      test('cancelBooking updates status to cancelled with reason', () async {
        await seedBooking(baseBooking);

        final cancelled = await repository.cancelBooking(
          'b_create',
          'Guest requested',
        );
        expect(cancelled.status, BookingStatus.cancelled);
        expect(cancelled.cancellationReason, 'Guest requested');

        final fetched = await repository.fetchBookingById('b_create');
        expect(fetched!.status, BookingStatus.cancelled);
      });

      test('deleteBooking removes document', () async {
        await seedBooking(baseBooking);

        await repository.deleteBooking('b_create', booking: baseBooking);

        final fetched = await repository.fetchBookingById('b_create');
        expect(fetched, isNull);
      });

      test('updateBookingPayment updates payment fields', () async {
        await seedBooking(baseBooking);

        final updated = await repository.updateBookingPayment(
          bookingId: 'b_create',
          paidAmount: 50.0,
          paymentIntentId: 'pi_123',
        );
        expect(updated.paidAmount, 50.0);
        expect(updated.paymentIntentId, 'pi_123');

        final fetched = await repository.fetchBookingById('b_create');
        expect(fetched!.paidAmount, 50.0);
      });

      test('completeBookingPayment marks as paid and confirmed', () async {
        await seedBooking(baseBooking);

        final completed = await repository.completeBookingPayment('b_create');
        expect(completed.paidAmount, 100.0); // total price
        expect(completed.paymentStatus, 'paid');
        expect(completed.status, BookingStatus.confirmed);

        final fetched = await repository.fetchBookingById('b_create');
        expect(fetched!.status, BookingStatus.confirmed);
        expect(fetched.paymentStatus, 'paid');
      });
    });

    group('dates and overlap logic', () {
      final baseDate = DateTime(2025, 1, 10);

      final existingBooking = BookingModel(
        id: 'b_exist',
        unitId: 'u1',
        propertyId: 'p1',
        userId: 'user1',
        checkIn: baseDate,
        checkOut: baseDate.add(const Duration(days: 5)), // Jan 10 - Jan 15
        status: BookingStatus.confirmed,
        totalPrice: 100,
        createdAt: now,
      );

      final cancelledBooking = BookingModel(
        id: 'b_cancelled',
        unitId: 'u1',
        propertyId: 'p1',
        userId: 'user1',
        checkIn: baseDate.add(const Duration(days: 2)),
        checkOut: baseDate.add(const Duration(days: 4)), // Jan 12 - Jan 14
        status: BookingStatus.cancelled,
        totalPrice: 100,
        createdAt: now,
      );

      setUp(() async {
        await seedBooking(existingBooking);
        await seedBooking(cancelledBooking);
      });

      test('getOverlappingBookings identifies true overlaps', () async {
        // Overlaps from left (Jan 8 - Jan 12)
        final overlapsLeft = await repository.getOverlappingBookings(
          unitId: 'u1',
          checkIn: baseDate.subtract(const Duration(days: 2)),
          checkOut: baseDate.add(const Duration(days: 2)),
        );
        expect(overlapsLeft.length, 1);
        expect(overlapsLeft.first.id, 'b_exist');

        // Overlaps inside (Jan 11 - Jan 13)
        final overlapsInside = await repository.getOverlappingBookings(
          unitId: 'u1',
          checkIn: baseDate.add(const Duration(days: 1)),
          checkOut: baseDate.add(const Duration(days: 3)),
        );
        expect(overlapsInside.length, 1);
        expect(overlapsInside.first.id, 'b_exist');
      });

      test('getOverlappingBookings ignores non-overlapping dates', () async {
        // Before (Jan 1 - Jan 5)
        final before = await repository.getOverlappingBookings(
          unitId: 'u1',
          checkIn: baseDate.subtract(const Duration(days: 9)),
          checkOut: baseDate.subtract(const Duration(days: 5)),
        );
        expect(before.isEmpty, isTrue);

        // After (Jan 20 - Jan 25)
        final after = await repository.getOverlappingBookings(
          unitId: 'u1',
          checkIn: baseDate.add(const Duration(days: 10)),
          checkOut: baseDate.add(const Duration(days: 15)),
        );
        expect(after.isEmpty, isTrue);
      });

      test(
        'getOverlappingBookings ignores same-day turnover (strict inequality)',
        () async {
          // Ends on Jan 10 (same day as existing check-in)
          final touchesStart = await repository.getOverlappingBookings(
            unitId: 'u1',
            checkIn: baseDate.subtract(const Duration(days: 5)),
            checkOut: baseDate,
          );
          expect(touchesStart.isEmpty, isTrue);

          // Starts on Jan 15 (same day as existing check-out)
          final touchesEnd = await repository.getOverlappingBookings(
            unitId: 'u1',
            checkIn: baseDate.add(const Duration(days: 5)),
            checkOut: baseDate.add(const Duration(days: 10)),
          );
          expect(touchesEnd.isEmpty, isTrue);
        },
      );

      test('areDatesAvailable handles overlaps correctly', () async {
        // Overlapping dates
        final isAvailableOverlap = await repository.areDatesAvailable(
          unitId: 'u1',
          checkIn: baseDate.add(const Duration(days: 1)),
          checkOut: baseDate.add(const Duration(days: 3)),
        );
        expect(isAvailableOverlap, isFalse);

        // Non-overlapping dates
        final isAvailableClear = await repository.areDatesAvailable(
          unitId: 'u1',
          checkIn: baseDate.add(const Duration(days: 10)),
          checkOut: baseDate.add(const Duration(days: 15)),
        );
        expect(isAvailableClear, isTrue);
      });

      test('areDatesAvailable handles excludeBookingId', () async {
        // Same dates as existing booking, but excluding it
        final isAvailableExclude = await repository.areDatesAvailable(
          unitId: 'u1',
          checkIn: baseDate,
          checkOut: baseDate.add(const Duration(days: 5)),
          excludeBookingId: 'b_exist',
        );
        expect(isAvailableExclude, isTrue);
      });
    });
  });
}
