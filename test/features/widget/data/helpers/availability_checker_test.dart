// ignore_for_file: avoid_redundant_argument_values
// Note: Explicit default values kept in tests for documentation clarity
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/data/helpers/availability_checker.dart';
import 'package:bookbed/features/widget/data/models/availability_window.dart';
import 'package:bookbed/features/widget/domain/constants/widget_constants.dart';
import 'package:bookbed/features/widget/domain/services/i_availability_repository.dart';

/// In-memory fake for [IAvailabilityRepository].
///
/// Production calls `getUnitAvailability` Cloud Function (SF-023) which
/// requires Firebase init. Tests inject this fake to skip that — set
/// [windows] per test to drive `_checkIcalEvents` behavior in the checker.
class _FakeAvailabilityRepository implements IAvailabilityRepository {
  List<AvailabilityWindow> windows = const [];

  @override
  Future<List<AvailabilityWindow>> fetchAvailability({
    required String propertyId,
    required String unitId,
    required DateTime start,
    required DateTime end,
  }) async => windows;
}

void main() {
  group('AvailabilityCheckResult', () {
    group('available factory', () {
      test('creates result with isAvailable true', () {
        const result = AvailabilityCheckResult.available();

        expect(result.isAvailable, isTrue);
        expect(result.conflictType, isNull);
        expect(result.errorCode, isNull);
        expect(result.conflictingDocId, isNull);
      });
    });

    group('bookingConflict factory', () {
      test('creates result with booking conflict details', () {
        final result = AvailabilityCheckResult.bookingConflict('booking123');

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.booking);
        expect(result.errorCode, AvailabilityErrorCode.bookingConflict);
        expect(result.conflictingDocId, 'booking123');
      });
    });

    group('icalConflict factory', () {
      test('creates result with iCal conflict details', () {
        final result = AvailabilityCheckResult.icalConflict(
          'event456',
          'Booking.com',
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.icalEvent);
        expect(result.errorCode, AvailabilityErrorCode.icalConflict);
        expect(result.icalSource, 'Booking.com');
        expect(result.conflictingDocId, 'event456');
      });

      test('creates result with Airbnb source', () {
        final result = AvailabilityCheckResult.icalConflict(
          'event789',
          'Airbnb',
        );

        expect(result.icalSource, 'Airbnb');
      });
    });

    group('blockedDateConflict factory', () {
      test('creates result with blocked date details', () {
        final blockedDate = DateTime(2024, 1, 15);
        final result = AvailabilityCheckResult.blockedDateConflict(
          'price123',
          blockedDate,
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.blockedDate);
        expect(result.errorCode, AvailabilityErrorCode.blockedDate);
        expect(result.conflictDate, blockedDate);
        expect(result.conflictingDocId, 'price123');
      });
    });

    group('constructor', () {
      test('creates result with all fields', () {
        final conflictDate = DateTime(2024, 1, 15);
        final result = AvailabilityCheckResult(
          isAvailable: false,
          conflictType: ConflictType.booking,
          errorCode: AvailabilityErrorCode.bookingConflict,
          conflictingDocId: 'doc123',
          conflictDate: conflictDate,
          icalSource: 'Booking.com',
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.booking);
        expect(result.errorCode, AvailabilityErrorCode.bookingConflict);
        expect(result.conflictingDocId, 'doc123');
        expect(result.conflictDate, conflictDate);
        expect(result.icalSource, 'Booking.com');
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

    test('has blockedCheckIn type', () {
      expect(ConflictType.blockedCheckIn, isNotNull);
    });

    test('has blockedCheckOut type', () {
      expect(ConflictType.blockedCheckOut, isNotNull);
    });

    test('has exactly 5 types', () {
      expect(ConflictType.values.length, 5);
    });
  });

  group('AvailabilityChecker', () {
    late FakeFirebaseFirestore fakeFirestore;
    late _FakeAvailabilityRepository fakeRepo;
    late AvailabilityChecker checker;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      fakeRepo = _FakeAvailabilityRepository();
      checker = AvailabilityChecker(
        fakeFirestore,
        availabilityRepository: fakeRepo,
      );
    });

    group('check - no conflicts', () {
      test('returns available when no bookings exist', () async {
        final result = await checker.check(
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
      // SF-023: iCal events are fetched server-side via the
      // getUnitAvailability CF. Tests drive the [IAvailabilityRepository]
      // fake directly with [AvailabilityWindow]s instead of seeding the old
      // collectionGroup('ical_events') path.
      test('detects conflict with iCal event', () async {
        fakeRepo.windows = [
          AvailabilityWindow(
            start: DateTime(2024, 1, 15),
            end: DateTime(2024, 1, 20),
            source: AvailabilityWindowSource.icalExternal,
            platform: 'Booking.com',
          ),
        ];

        final result = await checker.check(
          propertyId: 'prop123',
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 17),
          checkOut: DateTime(2024, 1, 22),
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.icalEvent);
        expect(result.icalSource, 'Booking.com');
      });

      test('allows same-day turnover for iCal events', () async {
        fakeRepo.windows = [
          AvailabilityWindow(
            start: DateTime(2024, 1, 10),
            end: DateTime(2024, 1, 15),
            source: AvailabilityWindowSource.icalExternal,
            platform: 'Airbnb',
          ),
        ];

        final result = await checker.check(
          propertyId: 'prop123',
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isTrue);
      });

      test('uses default source when platform is missing', () async {
        fakeRepo.windows = [
          AvailabilityWindow(
            start: DateTime(2024, 1, 15),
            end: DateTime(2024, 1, 20),
            source: AvailabilityWindowSource.icalExternal,
            // No platform field — CF emits null for unmapped sources
          ),
        ];

        final result = await checker.check(
          propertyId: 'prop123',
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 17),
          checkOut: DateTime(2024, 1, 22),
        );

        expect(result.isAvailable, isFalse);
        expect(result.icalSource, 'iCal');
      });

      test('ignores non-icalExternal windows', () async {
        // The CF may emit booking/manualBlock windows too — _checkIcalEvents
        // must filter to icalExternal so it doesn't double-report bookings
        // that _checkBookings already covers.
        fakeRepo.windows = [
          AvailabilityWindow(
            start: DateTime(2024, 1, 15),
            end: DateTime(2024, 1, 20),
            source: AvailabilityWindowSource.booking,
          ),
        ];

        final result = await checker.check(
          propertyId: 'prop123',
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 17),
          checkOut: DateTime(2024, 1, 22),
        );

        expect(result.isAvailable, isTrue);
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
          propertyId: 'prop123',
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.blockedDate);
        expect(result.conflictDate, DateTime.utc(2024, 1, 17));
      });

      test('detects conflict when blocked date is checkIn date', () async {
        await fakeFirestore.collection('daily_prices').add({
          'unit_id': 'unit123',
          'date': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'available': false,
        });

        final result = await checker.check(
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
          propertyId: 'prop123',
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 15),
          checkOut: DateTime(2024, 1, 20),
        );

        expect(result.isAvailable, isTrue);
      });
    });

    group('check - priority order', () {
      test('returns booking conflict before iCal conflict', () async {
        // Booking via fakeFirestore, iCal via fake repo
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

        fakeRepo.windows = [
          AvailabilityWindow(
            start: DateTime(2024, 1, 15),
            end: DateTime(2024, 1, 20),
            source: AvailabilityWindowSource.icalExternal,
            platform: 'Booking.com',
          ),
        ];

        final result = await checker.check(
          propertyId: 'prop123',
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 17),
          checkOut: DateTime(2024, 1, 22),
        );

        expect(result.isAvailable, isFalse);
        expect(result.conflictType, ConflictType.booking);
      });

      test('returns iCal conflict before blocked date conflict', () async {
        // Both iCal (via fake repo) and blocked date (via fakeFirestore)
        fakeRepo.windows = [
          AvailabilityWindow(
            start: DateTime(2024, 1, 15),
            end: DateTime(2024, 1, 20),
            source: AvailabilityWindowSource.icalExternal,
            platform: 'Airbnb',
          ),
        ];

        await fakeFirestore.collection('daily_prices').add({
          'unit_id': 'unit123',
          'date': Timestamp.fromDate(DateTime(2024, 1, 17)),
          'available': false,
        });

        final result = await checker.check(
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
          propertyId: 'prop123',
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
          propertyId: 'prop123',
          unitId: 'unit123',
          checkIn: DateTime(2024, 1, 17),
          checkOut: DateTime(2024, 1, 22),
        );

        expect(isAvail, isFalse);
      });
    });
  });
}
