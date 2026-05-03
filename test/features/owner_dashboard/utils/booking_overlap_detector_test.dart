import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/owner_dashboard/utils/booking_overlap_detector.dart';
import 'package:bookbed/shared/models/booking_model.dart';
import 'package:bookbed/core/constants/enums.dart';

void main() {
  // Helper function to create a mock booking for testing
  BookingModel createBooking({
    required String id,
    required DateTime checkIn,
    required DateTime checkOut,
    BookingStatus status = BookingStatus.confirmed,
    String unitId = 'unit_1',
  }) {
    return BookingModel(
      id: id,
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
      status: status,
      createdAt: DateTime.now(),
      totalPrice: 100,
    );
  }

  group('isActiveBooking', () {
    test('returns true for pending status', () {
      final booking = createBooking(
        id: '1',
        checkIn: DateTime.now(),
        checkOut: DateTime.now().add(const Duration(days: 1)),
        status: BookingStatus.pending,
      );
      expect(isActiveBooking(booking), isTrue);
    });

    test('returns true for confirmed status', () {
      final booking = createBooking(
        id: '1',
        checkIn: DateTime.now(),
        checkOut: DateTime.now().add(const Duration(days: 1)),
        status: BookingStatus.confirmed,
      );
      expect(isActiveBooking(booking), isTrue);
    });

    test('returns false for cancelled status', () {
      final booking = createBooking(
        id: '1',
        checkIn: DateTime.now(),
        checkOut: DateTime.now().add(const Duration(days: 1)),
        status: BookingStatus.cancelled,
      );
      expect(isActiveBooking(booking), isFalse);
    });

    test('returns false for completed status', () {
      final booking = createBooking(
        id: '1',
        checkIn: DateTime.now(),
        checkOut: DateTime.now().add(const Duration(days: 1)),
        status: BookingStatus.completed,
      );
      expect(isActiveBooking(booking), isFalse);
    });
  });

  group('doBookingsOverlap', () {
    test('returns false for non-overlapping sequential bookings', () {
      // B1: May 1 - May 5, B2: May 10 - May 15
      final b1Start = DateTime(2024, 5, 1);
      final b1End = DateTime(2024, 5, 5);
      final b2Start = DateTime(2024, 5, 10);
      final b2End = DateTime(2024, 5, 15);

      expect(
        BookingOverlapDetector.doBookingsOverlap(
          start1: b1Start,
          end1: b1End,
          start2: b2Start,
          end2: b2End,
        ),
        isFalse,
      );
      // Reverse check
      expect(
        BookingOverlapDetector.doBookingsOverlap(
          start1: b2Start,
          end1: b2End,
          start2: b1Start,
          end2: b1End,
        ),
        isFalse,
      );
    });

    test(
      'returns false for same-day turnover (checkout equals next checkin)',
      () {
        // B1: May 1 - May 5, B2: May 5 - May 10
        final b1Start = DateTime(2024, 5, 1);
        final b1End = DateTime(2024, 5, 5);
        final b2Start = DateTime(2024, 5, 5);
        final b2End = DateTime(2024, 5, 10);

        expect(
          BookingOverlapDetector.doBookingsOverlap(
            start1: b1Start,
            end1: b1End,
            start2: b2Start,
            end2: b2End,
          ),
          isFalse,
        );
        // Reverse check
        expect(
          BookingOverlapDetector.doBookingsOverlap(
            start1: b2Start,
            end1: b2End,
            start2: b1Start,
            end2: b1End,
          ),
          isFalse,
        );
      },
    );

    test('returns true for fully overlapping bookings', () {
      // B1: May 5 - May 10, B2: May 5 - May 10
      final start = DateTime(2024, 5, 5);
      final end = DateTime(2024, 5, 10);

      expect(
        BookingOverlapDetector.doBookingsOverlap(
          start1: start,
          end1: end,
          start2: start,
          end2: end,
        ),
        isTrue,
      );
    });

    test('returns true for partially overlapping bookings (overlap end)', () {
      // B1: May 5 - May 10, B2: May 8 - May 12
      final b1Start = DateTime(2024, 5, 5);
      final b1End = DateTime(2024, 5, 10);
      final b2Start = DateTime(2024, 5, 8);
      final b2End = DateTime(2024, 5, 12);

      expect(
        BookingOverlapDetector.doBookingsOverlap(
          start1: b1Start,
          end1: b1End,
          start2: b2Start,
          end2: b2End,
        ),
        isTrue,
      );
    });

    test('returns true for partially overlapping bookings (overlap start)', () {
      // B1: May 5 - May 10, B2: May 1 - May 7
      final b1Start = DateTime(2024, 5, 5);
      final b1End = DateTime(2024, 5, 10);
      final b2Start = DateTime(2024, 5, 1);
      final b2End = DateTime(2024, 5, 7);

      expect(
        BookingOverlapDetector.doBookingsOverlap(
          start1: b1Start,
          end1: b1End,
          start2: b2Start,
          end2: b2End,
        ),
        isTrue,
      );
    });

    test('returns true for contained bookings', () {
      // B1: May 1 - May 15, B2: May 5 - May 10
      final b1Start = DateTime(2024, 5, 1);
      final b1End = DateTime(2024, 5, 15);
      final b2Start = DateTime(2024, 5, 5);
      final b2End = DateTime(2024, 5, 10);

      expect(
        BookingOverlapDetector.doBookingsOverlap(
          start1: b1Start,
          end1: b1End,
          start2: b2Start,
          end2: b2End,
        ),
        isTrue,
      );
      // Reverse check
      expect(
        BookingOverlapDetector.doBookingsOverlap(
          start1: b2Start,
          end1: b2End,
          start2: b1Start,
          end2: b1End,
        ),
        isTrue,
      );
    });

    test('ignores time components when checking overlap', () {
      // B1: May 5 23:59 - May 10 00:01
      // B2: May 10 23:59 - May 15 00:01
      // They should NOT overlap (same-day turnover)
      final b1Start = DateTime(2024, 5, 5, 23, 59);
      final b1End = DateTime(2024, 5, 10, 0, 1);
      final b2Start = DateTime(2024, 5, 10, 23, 59);
      final b2End = DateTime(2024, 5, 15, 0, 1);

      expect(
        BookingOverlapDetector.doBookingsOverlap(
          start1: b1Start,
          end1: b1End,
          start2: b2Start,
          end2: b2End,
        ),
        isFalse,
      );
    });
  });

  group('canPlaceBooking & getConflictingBookings', () {
    final Map<String, List<BookingModel>> allBookings = {
      'unit_1': [
        createBooking(
          id: 'b1',
          unitId: 'unit_1',
          checkIn: DateTime(2024, 5, 1),
          checkOut: DateTime(2024, 5, 5),
          status: BookingStatus.confirmed,
        ),
        createBooking(
          id: 'b2',
          unitId: 'unit_1',
          checkIn: DateTime(2024, 5, 10),
          checkOut: DateTime(2024, 5, 15),
          status: BookingStatus.pending,
        ),
        createBooking(
          id: 'b3_cancelled',
          unitId: 'unit_1',
          checkIn: DateTime(2024, 5, 20),
          checkOut: DateTime(2024, 5, 25),
          status: BookingStatus.cancelled,
        ),
      ],
      'unit_2': [],
    };

    test('canPlaceBooking returns true for empty unit', () {
      expect(
        BookingOverlapDetector.canPlaceBooking(
          unitId: 'unit_2',
          newCheckIn: DateTime(2024, 5, 1),
          newCheckOut: DateTime(2024, 5, 10),
          bookingIdToExclude: null,
          allBookings: allBookings,
        ),
        isTrue,
      );

      expect(
        BookingOverlapDetector.getConflictingBookings(
          unitId: 'unit_2',
          newCheckIn: DateTime(2024, 5, 1),
          newCheckOut: DateTime(2024, 5, 10),
          bookingIdToExclude: null,
          allBookings: allBookings,
        ),
        isEmpty,
      );
    });

    test('canPlaceBooking returns true for valid placement (no overlaps)', () {
      expect(
        BookingOverlapDetector.canPlaceBooking(
          unitId: 'unit_1',
          newCheckIn: DateTime(2024, 5, 5), // Same-day turnover with b1
          newCheckOut: DateTime(2024, 5, 10), // Same-day turnover with b2
          bookingIdToExclude: null,
          allBookings: allBookings,
        ),
        isTrue,
      );
    });

    test('canPlaceBooking returns false for invalid placement (overlap)', () {
      expect(
        BookingOverlapDetector.canPlaceBooking(
          unitId: 'unit_1',
          newCheckIn: DateTime(2024, 5, 4), // Overlaps with b1 (ends May 5)
          newCheckOut: DateTime(2024, 5, 8),
          bookingIdToExclude: null,
          allBookings: allBookings,
        ),
        isFalse,
      );

      final conflicts = BookingOverlapDetector.getConflictingBookings(
        unitId: 'unit_1',
        newCheckIn: DateTime(2024, 5, 4),
        newCheckOut: DateTime(2024, 5, 8),
        bookingIdToExclude: null,
        allBookings: allBookings,
      );
      expect(conflicts.length, 1);
      expect(conflicts.first.id, 'b1');
    });

    test(
      'canPlaceBooking returns true when overlapping with inactive booking',
      () {
        expect(
          BookingOverlapDetector.canPlaceBooking(
            unitId: 'unit_1',
            newCheckIn: DateTime(2024, 5, 20), // Overlaps with b3_cancelled
            newCheckOut: DateTime(2024, 5, 25),
            bookingIdToExclude: null,
            allBookings: allBookings,
          ),
          isTrue,
        );

        expect(
          BookingOverlapDetector.getConflictingBookings(
            unitId: 'unit_1',
            newCheckIn: DateTime(2024, 5, 20),
            newCheckOut: DateTime(2024, 5, 25),
            bookingIdToExclude: null,
            allBookings: allBookings,
          ),
          isEmpty,
        );
      },
    );

    test(
      'canPlaceBooking returns true when editing existing booking (exclude self)',
      () {
        expect(
          BookingOverlapDetector.canPlaceBooking(
            unitId: 'unit_1',
            newCheckIn: DateTime(2024, 5, 1), // Exact same dates as b1
            newCheckOut: DateTime(2024, 5, 5),
            bookingIdToExclude: 'b1', // Exclude b1
            allBookings: allBookings,
          ),
          isTrue,
        );

        expect(
          BookingOverlapDetector.getConflictingBookings(
            unitId: 'unit_1',
            newCheckIn: DateTime(2024, 5, 1),
            newCheckOut: DateTime(2024, 5, 5),
            bookingIdToExclude: 'b1',
            allBookings: allBookings,
          ),
          isEmpty,
        );
      },
    );
  });

  group('validateBookingMove', () {
    final Map<String, List<BookingModel>> allBookings = {
      'unit_1': [
        createBooking(
          id: 'b1',
          unitId: 'unit_1',
          checkIn: DateTime.now().add(const Duration(days: 10)),
          checkOut: DateTime.now().add(const Duration(days: 15)),
        ),
      ],
      'unit_2': [],
    };

    test('returns valid result for a valid move', () {
      final newCheckIn = DateTime.now().add(const Duration(days: 15));
      final newCheckOut = DateTime.now().add(const Duration(days: 20));

      final result = BookingOverlapDetector.validateBookingMove(
        bookingId: 'b2',
        currentUnitId: 'unit_2',
        targetUnitId: 'unit_1',
        newCheckIn: newCheckIn,
        newCheckOut: newCheckOut,
        allBookings: allBookings,
      );

      expect(result.isValid, isTrue);
    });

    test('returns invalid when target unit does not exist', () {
      final newCheckIn = DateTime.now().add(const Duration(days: 15));
      final newCheckOut = DateTime.now().add(const Duration(days: 20));

      final result = BookingOverlapDetector.validateBookingMove(
        bookingId: 'b2',
        currentUnitId: 'unit_2',
        targetUnitId: 'non_existent_unit',
        newCheckIn: newCheckIn,
        newCheckOut: newCheckOut,
        allBookings: allBookings,
      );

      expect(result.isValid, isFalse);
      expect(result.reason, 'Target unit does not exist');
    });

    test('returns invalid when booking overlaps in target unit', () {
      final newCheckIn = DateTime.now().add(const Duration(days: 12));
      final newCheckOut = DateTime.now().add(const Duration(days: 16));

      final result = BookingOverlapDetector.validateBookingMove(
        bookingId: 'b2',
        currentUnitId: 'unit_2',
        targetUnitId: 'unit_1',
        newCheckIn: newCheckIn,
        newCheckOut: newCheckOut,
        allBookings: allBookings,
      );

      expect(result.isValid, isFalse);
      expect(result.reason, contains('overlaps'));
      expect(result.conflictingBookings, isNotNull);
      expect(result.conflictingBookings!.length, 1);
    });

    test('returns invalid when moving to past dates', () {
      final newCheckIn = DateTime.now().subtract(const Duration(days: 2));
      final newCheckOut = DateTime.now().add(const Duration(days: 2));

      final result = BookingOverlapDetector.validateBookingMove(
        bookingId: 'b2',
        currentUnitId: 'unit_2',
        targetUnitId: 'unit_2',
        newCheckIn: newCheckIn,
        newCheckOut: newCheckOut,
        allBookings: allBookings,
      );

      expect(result.isValid, isFalse);
      expect(result.reason, 'Cannot move booking to past dates');
    });

    test('returns invalid when check-out is before or equal to check-in', () {
      final now = DateTime.now();
      final newCheckIn = now.add(const Duration(days: 2));
      final newCheckOut = newCheckIn; // Same as check-in

      final result = BookingOverlapDetector.validateBookingMove(
        bookingId: 'b2',
        currentUnitId: 'unit_2',
        targetUnitId: 'unit_2',
        newCheckIn: newCheckIn,
        newCheckOut: newCheckOut,
        allBookings: allBookings,
      );

      expect(result.isValid, isFalse);
      expect(result.reason, 'Check-out must be after check-in');
    });
  });

  group('findAvailableSlots', () {
    final Map<String, List<BookingModel>> allBookings = {
      'unit_1': [
        createBooking(
          id: 'b1',
          unitId: 'unit_1',
          checkIn: DateTime(2024, 5, 5),
          checkOut: DateTime(2024, 5, 10),
        ),
        createBooking(
          id: 'b2',
          unitId: 'unit_1',
          checkIn: DateTime(2024, 5, 15),
          checkOut: DateTime(2024, 5, 20),
        ),
        createBooking(
          id: 'b3_cancelled',
          unitId: 'unit_1',
          checkIn: DateTime(2024, 5, 22),
          checkOut: DateTime(2024, 5, 28),
          status: BookingStatus.cancelled,
        ),
      ],
      'empty_unit': [],
    };

    test('returns single slot for empty unit', () {
      final rangeStart = DateTime(2024, 5, 1);
      final rangeEnd = DateTime(2024, 5, 30);

      final slots = BookingOverlapDetector.findAvailableSlots(
        unitId: 'empty_unit',
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        allBookings: allBookings,
      );

      expect(slots.length, 1);
      expect(slots.first.start, rangeStart);
      expect(slots.first.end, rangeEnd);
    });

    test('finds slots between and around bookings', () {
      final rangeStart = DateTime(2024, 5, 1);
      final rangeEnd = DateTime(2024, 5, 30);

      final slots = BookingOverlapDetector.findAvailableSlots(
        unitId: 'unit_1',
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        allBookings: allBookings,
      );

      // Should find:
      // 1. May 1 - May 5 (gap before b1)
      // 2. May 10 - May 15 (gap between b1 and b2)
      // 3. May 20 - May 30 (gap after b2, ignoring cancelled b3)
      expect(slots.length, 3);

      expect(slots[0].start, DateTime(2024, 5, 1));
      expect(slots[0].end, DateTime(2024, 5, 5));
      expect(slots[0].nights, 4);

      expect(slots[1].start, DateTime(2024, 5, 10));
      expect(slots[1].end, DateTime(2024, 5, 15));
      expect(slots[1].nights, 5);

      expect(slots[2].start, DateTime(2024, 5, 20));
      expect(slots[2].end, DateTime(2024, 5, 30));
      expect(slots[2].nights, 10);
    });

    test('respects minNights parameter', () {
      final rangeStart = DateTime(2024, 5, 1);
      final rangeEnd = DateTime(2024, 5, 30);

      final slots = BookingOverlapDetector.findAvailableSlots(
        unitId: 'unit_1',
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        allBookings: allBookings,
        minNights: 5,
      );

      // Should skip May 1-5 (4 nights), include others
      expect(slots.length, 2);
      expect(slots[0].start, DateTime(2024, 5, 10)); // 5 nights
      expect(slots[1].start, DateTime(2024, 5, 20)); // 10 nights
    });

    test('DateRange toString formats correctly', () {
      final range = DateRange(
        start: DateTime(2024, 5, 1),
        end: DateTime(2024, 5, 5),
      );
      expect(
        range.toString(),
        '${range.start.toIso8601String()} - ${range.end.toIso8601String()}',
      );
    });
  });
}
