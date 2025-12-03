// ignore_for_file: avoid_redundant_argument_values
// Note: Explicit default values kept in tests for documentation clarity
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/data/helpers/availability_checker.dart';

void main() {
  group('AvailabilityCheckResult', () {
    group('available factory', () {
      test('creates result with isAvailable true', () {
        const result = AvailabilityCheckResult.available();

        expect(result.isAvailable, isTrue);
        expect(result.conflictType, isNull);
        expect(result.conflictMessage, isNull);
        expect(result.conflictingDocId, isNull);
      });
    });

    group('bookingConflict factory', () {
      test('creates result with booking conflict details', () {
        final result = AvailabilityCheckResult.bookingConflict('booking123');

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.booking);
        expect(result.conflictMessage, 'Conflict with existing booking');
        expect(result.conflictingDocId, 'booking123');
      });
    });

    group('icalConflict factory', () {
      test('creates result with iCal conflict details', () {
        final result =
            AvailabilityCheckResult.icalConflict('event456', 'Booking.com');

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.icalEvent);
        expect(result.conflictMessage, 'Conflict with Booking.com event');
        expect(result.conflictingDocId, 'event456');
      });

      test('creates result with Airbnb source', () {
        final result =
            AvailabilityCheckResult.icalConflict('event789', 'Airbnb');

        expect(result.conflictMessage, 'Conflict with Airbnb event');
      });
    });

    group('blockedDateConflict factory', () {
      test('creates result with blocked date details', () {
        final blockedDate = DateTime(2024, 1, 15);
        final result =
            AvailabilityCheckResult.blockedDateConflict('price123', blockedDate);

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.blockedDate);
        expect(result.conflictMessage, contains('2024-01-15'));
        expect(result.conflictingDocId, 'price123');
      });
    });

    group('constructor', () {
      test('creates result with all fields', () {
        const result = AvailabilityCheckResult(
          isAvailable: false,
          conflictType: ConflictType.booking,
          conflictMessage: 'Custom message',
          conflictingDocId: 'doc123',
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.booking);
        expect(result.conflictMessage, 'Custom message');
        expect(result.conflictingDocId, 'doc123');
      });
    });
  });

  group('ConflictType', () {
    test('has booking type', () {
      expect(ConflictType.booking, isNotNull);
    });

    test('has icalEvent type', () {
      expect(ConflictType.icalEvent, isNotNull);
    });

    test('has blockedDate type', () {
      expect(ConflictType.blockedDate, isNotNull);
    });

    test('has exactly 3 types', () {
      expect(ConflictType.values.length, 3);
    });
  });

  group('AvailabilityChecker', () {
    late FakeFirebaseFirestore fakeFirestore;
    late AvailabilityChecker checker;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      checker = AvailabilityChecker(fakeFirestore);
    });

    group('check - no conflicts', () {
      test('returns available when no bookings exist', () async {
        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isTrue);
        expect(result.conflictType, isNull);
      });

      test('returns available when bookings are for different unit', () async {
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'other_unit',
          'status': 'confirmed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isTrue);
      });

      test('returns available for non-overlapping dates (before)', () async {
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'confirmed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 25)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 10),
          checkOut: DateTime(2024, 1, 15),
        );

        expect(result.isAvailable, isTrue);
      });

      test('returns available for non-overlapping dates (after)', () async {
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'confirmed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 10)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 20),
          checkOut: DateTime(2024, 1, 25),
        );

        expect(result.isAvailable, isTrue);
      });
    });

    group('check - same-day turnover', () {
      test('allows checkIn on same day as existing checkOut', () async {
        // Existing booking: Jan 10-15
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'confirmed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 10)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        // New booking: Jan 15-20 (checkIn = existing checkOut)
        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isTrue);
      });

      test('allows checkOut on same day as existing checkIn', () async {
        // Existing booking: Jan 15-20
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'confirmed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        // New booking: Jan 10-15 (checkOut = existing checkIn)
        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 10),
          checkOut: DateTime(2024, 1, 15),
        );

        expect(result.isAvailable, isTrue);
      });
    });

    group('check - booking conflicts', () {
      test('detects full overlap', () async {
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'confirmed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 10)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 10,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        // New booking within existing booking dates
        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 12),
          checkOut: DateTime(2024, 1, 18),
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.booking);
      });

      test('detects partial overlap at start', () async {
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'confirmed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        // New booking overlaps at start
        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 10),
          checkOut: DateTime(2024, 1, 17),
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.booking);
      });

      test('detects partial overlap at end', () async {
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'confirmed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 10)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        // New booking overlaps at end
        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 13),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.booking);
      });

      test('detects conflict with encompassing booking', () async {
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'confirmed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 13)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 17)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 4,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        // New booking encompasses existing booking
        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 10),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.booking);
      });

      test('ignores cancelled bookings', () async {
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'cancelled',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isTrue);
      });

      test('ignores completed bookings', () async {
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'completed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isTrue);
      });

      test('detects conflict with pending booking', () async {
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'pending',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.booking);
      });

      // Note: 'in_progress' status is queried by AvailabilityChecker but
      // BookingModel enum only has: pending, confirmed, cancelled, completed.
      // This test is skipped as it would require model changes.
    });

    group('check - iCal conflicts', () {
      test('detects conflict with iCal event', () async {
        await fakeFirestore.collection('ical_events').add({
          'unit_id': 'unit123',
          'start_date': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'end_date': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'source': 'Booking.com',
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 17),
          checkOut: DateTime(2024, 1, 22),
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.icalEvent);
        expect(result.conflictMessage, contains('Booking.com'));
      });

      test('allows same-day turnover for iCal events', () async {
        await fakeFirestore.collection('ical_events').add({
          'unit_id': 'unit123',
          'start_date': Timestamp.fromDate(DateTime(2024, 1, 10)),
          'end_date': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'source': 'Airbnb',
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isTrue);
      });

      test('ignores iCal events for different unit', () async {
        await fakeFirestore.collection('ical_events').add({
          'unit_id': 'other_unit',
          'start_date': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'end_date': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'source': 'Booking.com',
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isTrue);
      });

      test('uses default source when source is missing', () async {
        await fakeFirestore.collection('ical_events').add({
          'unit_id': 'unit123',
          'start_date': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'end_date': Timestamp.fromDate(DateTime(2024, 1, 20)),
          // No source field
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 17),
          checkOut: DateTime(2024, 1, 22),
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictMessage, contains('iCal'));
      });
    });

    group('check - blocked dates', () {
      test('detects conflict with blocked date', () async {
        await fakeFirestore.collection('daily_prices').add({
          'unit_id': 'unit123',
          'date': Timestamp.fromDate(DateTime(2024, 1, 17)),
          'available': false,
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.blockedDate);
        expect(result.conflictMessage, contains('2024-01-17'));
      });

      test('detects conflict when blocked date is checkIn date', () async {
        await fakeFirestore.collection('daily_prices').add({
          'unit_id': 'unit123',
          'date': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'available': false,
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.blockedDate);
      });

      test('no conflict when blocked date is checkOut date', () async {
        // CheckOut day is not a stay night, so blocked checkOut should be OK
        await fakeFirestore.collection('daily_prices').add({
          'unit_id': 'unit123',
          'date': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'available': false,
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isTrue);
      });

      test('ignores available dates', () async {
        await fakeFirestore.collection('daily_prices').add({
          'unit_id': 'unit123',
          'date': Timestamp.fromDate(DateTime(2024, 1, 17)),
          'available': true,
          'price': 100.0,
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isTrue);
      });

      test('ignores blocked dates for different unit', () async {
        await fakeFirestore.collection('daily_prices').add({
          'unit_id': 'other_unit',
          'date': Timestamp.fromDate(DateTime(2024, 1, 17)),
          'available': false,
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isTrue);
      });

      test('ignores blocked dates outside requested range', () async {
        await fakeFirestore.collection('daily_prices').add({
          'unit_id': 'unit123',
          'date': Timestamp.fromDate(DateTime(2024, 1, 25)),
          'available': false,
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isTrue);
      });
    });

    group('check - priority order', () {
      test('returns booking conflict before iCal conflict', () async {
        // Add both booking and iCal conflict
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'confirmed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        await fakeFirestore.collection('ical_events').add({
          'unit_id': 'unit123',
          'start_date': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'end_date': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'source': 'Booking.com',
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 17),
          checkOut: DateTime(2024, 1, 22),
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.booking);
      });

      test('returns iCal conflict before blocked date conflict', () async {
        // Add both iCal and blocked date conflict
        await fakeFirestore.collection('ical_events').add({
          'unit_id': 'unit123',
          'start_date': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'end_date': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'source': 'Airbnb',
        });

        await fakeFirestore.collection('daily_prices').add({
          'unit_id': 'unit123',
          'date': Timestamp.fromDate(DateTime(2024, 1, 17)),
          'available': false,
        });

        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 17),
          checkOut: DateTime(2024, 1, 22),
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.icalEvent);
      });
    });

    group('check - date normalization', () {
      test('normalizes dates with time components', () async {
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'confirmed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        // Dates with time components should be normalized
        final result = await checker.check(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 17, 14, 30, 0),
          checkOut: DateTime(2024, 1, 22, 10, 0, 0),
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.booking);
      });
    });

    group('isAvailable', () {
      test('returns true when available', () async {
        final isAvail = await checker.isAvailable(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(isAvail, isTrue);
      });

      test('returns false when not available', () async {
        await fakeFirestore.collection('bookings').add({
          'unit_id': 'unit123',
          'status': 'confirmed',
          'check_in': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'check_out': Timestamp.fromDate(DateTime(2024, 1, 20)),
          'guest_name': 'Test Guest',
          'guest_email': 'test@test.com',
          'property_id': 'prop123',
          'total_price': 500.0,
          'nights': 5,
          'guests': 2,
          'created_at': Timestamp.now(),
        });

        final isAvail = await checker.isAvailable(
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 17),
          checkOut: DateTime(2024, 1, 22),
        );

        expect(isAvail, isFalse);
      });
    });
  });
}
