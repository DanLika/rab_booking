import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/shared/models/booking_model.dart';
import 'package:bookbed/core/constants/enums.dart';

void main() {
  group('BookingModel', () {
    BookingModel createBooking({
      String id = 'test-booking-123',
      String unitId = 'unit-1',
      DateTime? checkIn,
      DateTime? checkOut,
      BookingStatus status = BookingStatus.confirmed,
      double totalPrice = 500.0,
      double paidAmount = 100.0,
      String? source,
      String? paymentMethod,
      int guestCount = 2,
      String? guestName,
      String? guestEmail,
    }) {
      return BookingModel(
        id: id,
        unitId: unitId,
        checkIn: checkIn ?? DateTime.utc(2025, 6, 15),
        checkOut: checkOut ?? DateTime.utc(2025, 6, 20),
        status: status,
        totalPrice: totalPrice,
        paidAmount: paidAmount,
        source: source,
        paymentMethod: paymentMethod,
        guestCount: guestCount,
        guestName: guestName,
        guestEmail: guestEmail,
        createdAt: DateTime.utc(2025, 1),
      );
    }

    group('numberOfNights', () {
      test('calculates correct nights for multi-day stay', () {
        final booking = createBooking(
          checkIn: DateTime.utc(2025, 6, 15),
          checkOut: DateTime.utc(2025, 6, 20),
        );
        expect(booking.numberOfNights, 5);
      });

      test('returns 1 for single night stay', () {
        final booking = createBooking(
          checkIn: DateTime.utc(2025, 6, 15),
          checkOut: DateTime.utc(2025, 6, 16),
        );
        expect(booking.numberOfNights, 1);
      });

      test('handles month boundary correctly', () {
        final booking = createBooking(
          checkIn: DateTime.utc(2025, 1, 29),
          checkOut: DateTime.utc(2025, 2, 3),
        );
        expect(booking.numberOfNights, 5);
      });

      test('handles year boundary correctly', () {
        final booking = createBooking(
          checkIn: DateTime.utc(2025, 12, 29),
          checkOut: DateTime.utc(2026, 1, 3),
        );
        expect(booking.numberOfNights, 5);
      });
    });

    group('payment calculations', () {
      test('remainingBalance returns correct value', () {
        final booking = createBooking(paidAmount: 100.0);
        expect(booking.remainingBalance, 400.0);
      });

      test('remainingBalance returns 0 when fully paid', () {
        final booking = createBooking(paidAmount: 500.0);
        expect(booking.remainingBalance, 0.0);
      });

      test('isFullyPaid returns true when paid >= total', () {
        final booking = createBooking(paidAmount: 500.0);
        expect(booking.isFullyPaid, isTrue);
      });

      test('isFullyPaid returns true when overpaid', () {
        final booking = createBooking(paidAmount: 600.0);
        expect(booking.isFullyPaid, isTrue);
      });

      test('isFullyPaid returns false when partially paid', () {
        final booking = createBooking(paidAmount: 100.0);
        expect(booking.isFullyPaid, isFalse);
      });

      test('paymentPercentage calculates correctly', () {
        final booking = createBooking(paidAmount: 100.0);
        expect(booking.paymentPercentage, 20.0);
      });

      test('paymentPercentage returns 0 when totalPrice is 0', () {
        final booking = createBooking(totalPrice: 0.0, paidAmount: 0.0);
        expect(booking.paymentPercentage, 0.0);
      });

      test('calculateAdvancePayment returns 20%', () {
        expect(BookingModel.calculateAdvancePayment(500.0), 100.0);
        expect(BookingModel.calculateAdvancePayment(1000.0), 200.0);
        expect(BookingModel.calculateAdvancePayment(0.0), 0.0);
      });
    });

    group('formatted strings', () {
      test('formattedTotalPrice formats with euro symbol', () {
        final booking = createBooking();
        expect(booking.formattedTotalPrice, '€500.00');
      });

      test('formattedPaidAmount formats with euro symbol', () {
        final booking = createBooking();
        expect(booking.formattedPaidAmount, '€100.00');
      });

      test('formattedRemainingBalance formats with euro symbol', () {
        final booking = createBooking(paidAmount: 100.0);
        expect(booking.formattedRemainingBalance, '€400.00');
      });

      test('nightsLabel singular', () {
        final booking = createBooking(
          checkIn: DateTime.utc(2025, 6, 15),
          checkOut: DateTime.utc(2025, 6, 16),
        );
        expect(booking.nightsLabel, '1 night');
      });

      test('nightsLabel plural', () {
        final booking = createBooking(
          checkIn: DateTime.utc(2025, 6, 15),
          checkOut: DateTime.utc(2025, 6, 20),
        );
        expect(booking.nightsLabel, '5 nights');
      });

      test('guestsLabel singular', () {
        final booking = createBooking(guestCount: 1);
        expect(booking.guestsLabel, '1 guest');
      });

      test('guestsLabel plural', () {
        final booking = createBooking(guestCount: 3);
        expect(booking.guestsLabel, '3 guests');
      });

      test('summary combines nights and guests', () {
        final booking = createBooking(
          checkIn: DateTime.utc(2025, 6, 15),
          checkOut: DateTime.utc(2025, 6, 20),
          guestCount: 3,
        );
        expect(booking.summary, '5 nights • 3 guests');
      });
    });

    group('dateRangeFormatted', () {
      test('same month same year', () {
        final booking = createBooking(
          checkIn: DateTime.utc(2025, 6, 15),
          checkOut: DateTime.utc(2025, 6, 20),
        );
        expect(booking.dateRangeFormatted, 'Jun 15-20, 2025');
      });

      test('different months same year', () {
        final booking = createBooking(
          checkIn: DateTime.utc(2025, 6, 28),
          checkOut: DateTime.utc(2025, 7, 5),
        );
        expect(booking.dateRangeFormatted, 'Jun 28 - Jul 5, 2025');
      });

      test('different years', () {
        final booking = createBooking(
          checkIn: DateTime.utc(2025, 12, 28),
          checkOut: DateTime.utc(2026, 1, 3),
        );
        expect(booking.dateRangeFormatted, 'Dec 28, 2025 - Jan 3, 2026');
      });
    });

    group('isExternalBooking', () {
      test('returns true for ical_ prefix ID', () {
        final booking = createBooking(id: 'ical_abc123');
        expect(booking.isExternalBooking, isTrue);
      });

      test('returns true for booking_com source', () {
        final booking = createBooking(source: 'booking_com');
        expect(booking.isExternalBooking, isTrue);
      });

      test('returns true for airbnb source', () {
        final booking = createBooking(source: 'airbnb');
        expect(booking.isExternalBooking, isTrue);
      });

      test('returns true for ical source', () {
        final booking = createBooking(source: 'ical');
        expect(booking.isExternalBooking, isTrue);
      });

      test('returns true for external source', () {
        final booking = createBooking(source: 'external');
        expect(booking.isExternalBooking, isTrue);
      });

      test('returns true for external payment method', () {
        final booking = createBooking(paymentMethod: 'external');
        expect(booking.isExternalBooking, isTrue);
      });

      test('returns false for widget source', () {
        final booking = createBooking(source: 'widget');
        expect(booking.isExternalBooking, isFalse);
      });

      test('returns false for manual source', () {
        final booking = createBooking(source: 'manual');
        expect(booking.isExternalBooking, isFalse);
      });

      test('returns false for null source with normal ID', () {
        final booking = createBooking(id: 'normal-id');
        expect(booking.isExternalBooking, isFalse);
      });

      test('case insensitive source matching', () {
        final booking = createBooking(source: 'BOOKING_COM');
        expect(booking.isExternalBooking, isTrue);
      });
    });

    group('sourceDisplayName', () {
      test('returns Booking.com for booking_com', () {
        final booking = createBooking(source: 'booking_com');
        expect(booking.sourceDisplayName, 'Booking.com');
      });

      test('returns Airbnb for airbnb', () {
        final booking = createBooking(source: 'airbnb');
        expect(booking.sourceDisplayName, 'Airbnb');
      });

      test('returns iCal Import for ical', () {
        final booking = createBooking(source: 'ical');
        expect(booking.sourceDisplayName, 'iCal Import');
      });

      test('returns Website Widget for widget', () {
        final booking = createBooking(source: 'widget');
        expect(booking.sourceDisplayName, 'Website Widget');
      });

      test('returns Direct for null source', () {
        final booking = createBooking();
        expect(booking.sourceDisplayName, 'Direct');
      });

      test('returns Direct for manual source', () {
        final booking = createBooking(source: 'manual');
        expect(booking.sourceDisplayName, 'Direct');
      });

      test('returns Admin for admin source', () {
        final booking = createBooking(source: 'admin');
        expect(booking.sourceDisplayName, 'Admin');
      });

      test('returns raw source for unknown value', () {
        final booking = createBooking(source: 'custom_platform');
        expect(booking.sourceDisplayName, 'custom_platform');
      });
    });

    group('datesOverlap (static)', () {
      test('returns true for fully overlapping ranges', () {
        expect(
          BookingModel.datesOverlap(
            start1: DateTime.utc(2025, 2, 15),
            end1: DateTime.utc(2025, 2, 20),
            start2: DateTime.utc(2025, 2, 16),
            end2: DateTime.utc(2025, 2, 19),
          ),
          isTrue,
        );
      });

      test('returns true for partially overlapping ranges', () {
        expect(
          BookingModel.datesOverlap(
            start1: DateTime.utc(2025, 2, 15),
            end1: DateTime.utc(2025, 2, 20),
            start2: DateTime.utc(2025, 2, 18),
            end2: DateTime.utc(2025, 2, 25),
          ),
          isTrue,
        );
      });

      test('returns false for same-day turnover (checkout == checkin)', () {
        // Per Changelog 6.38: same-day turnover is allowed
        expect(
          BookingModel.datesOverlap(
            start1: DateTime.utc(2025, 2, 15),
            end1: DateTime.utc(2025, 2, 20),
            start2: DateTime.utc(2025, 2, 20),
            end2: DateTime.utc(2025, 2, 25),
          ),
          isFalse,
        );
      });

      test('returns false for non-overlapping ranges', () {
        expect(
          BookingModel.datesOverlap(
            start1: DateTime.utc(2025, 2, 15),
            end1: DateTime.utc(2025, 2, 20),
            start2: DateTime.utc(2025, 3),
            end2: DateTime.utc(2025, 3, 5),
          ),
          isFalse,
        );
      });

      test('normalizes dates with time components to midnight', () {
        expect(
          BookingModel.datesOverlap(
            start1: DateTime(2025, 2, 15, 14, 30),
            end1: DateTime(2025, 2, 20, 10),
            start2: DateTime(2025, 2, 18, 9),
            end2: DateTime(2025, 2, 22, 16, 45),
          ),
          isTrue,
        );
      });

      test('returns true for identical ranges', () {
        expect(
          BookingModel.datesOverlap(
            start1: DateTime.utc(2025, 2, 15),
            end1: DateTime.utc(2025, 2, 20),
            start2: DateTime.utc(2025, 2, 15),
            end2: DateTime.utc(2025, 2, 20),
          ),
          isTrue,
        );
      });

      test('returns true when one range contains the other', () {
        expect(
          BookingModel.datesOverlap(
            start1: DateTime.utc(2025, 2, 10),
            end1: DateTime.utc(2025, 2, 25),
            start2: DateTime.utc(2025, 2, 15),
            end2: DateTime.utc(2025, 2, 20),
          ),
          isTrue,
        );
      });
    });

    group('overlapsWithDates', () {
      test('delegates to static datesOverlap method', () {
        final booking = createBooking(
          checkIn: DateTime.utc(2025, 6, 15),
          checkOut: DateTime.utc(2025, 6, 20),
        );

        expect(
          booking.overlapsWithDates(
            DateTime.utc(2025, 6, 18),
            DateTime.utc(2025, 6, 25),
          ),
          isTrue,
        );

        expect(
          booking.overlapsWithDates(
            DateTime.utc(2025, 6, 20),
            DateTime.utc(2025, 6, 25),
          ),
          isFalse,
        );
      });
    });

    group('canBeCancelled', () {
      test('confirmed upcoming booking can be cancelled', () {
        final booking = createBooking(
          checkIn: DateTime.now().add(const Duration(days: 30)),
          checkOut: DateTime.now().add(const Duration(days: 35)),
        );
        expect(booking.canBeCancelled, isTrue);
      });

      test('pending booking cannot be cancelled', () {
        final booking = createBooking(
          status: BookingStatus.pending,
          checkIn: DateTime.now().add(const Duration(days: 30)),
          checkOut: DateTime.now().add(const Duration(days: 35)),
        );
        expect(booking.canBeCancelled, isFalse);
      });

      test('already cancelled booking cannot be cancelled', () {
        final booking = createBooking(
          status: BookingStatus.cancelled,
          checkIn: DateTime.now().add(const Duration(days: 30)),
          checkOut: DateTime.now().add(const Duration(days: 35)),
        );
        expect(booking.canBeCancelled, isFalse);
      });

      test('completed booking cannot be cancelled', () {
        final booking = createBooking(
          status: BookingStatus.completed,
          checkIn: DateTime.now().add(const Duration(days: 30)),
          checkOut: DateTime.now().add(const Duration(days: 35)),
        );
        expect(booking.canBeCancelled, isFalse);
      });
    });
  });

  group('BookingStatus', () {
    test('canBeCancelled only for confirmed', () {
      expect(BookingStatus.confirmed.canBeCancelled, isTrue);
      expect(BookingStatus.pending.canBeCancelled, isFalse);
      expect(BookingStatus.cancelled.canBeCancelled, isFalse);
      expect(BookingStatus.completed.canBeCancelled, isFalse);
    });

    test('blocksCalendarDates for all except cancelled', () {
      expect(BookingStatus.pending.blocksCalendarDates, isTrue);
      expect(BookingStatus.confirmed.blocksCalendarDates, isTrue);
      expect(BookingStatus.completed.blocksCalendarDates, isTrue);
      expect(BookingStatus.cancelled.blocksCalendarDates, isFalse);
    });

    test('isFinal for completed and cancelled only', () {
      expect(BookingStatus.completed.isFinal, isTrue);
      expect(BookingStatus.cancelled.isFinal, isTrue);
      expect(BookingStatus.pending.isFinal, isFalse);
      expect(BookingStatus.confirmed.isFinal, isFalse);
    });

    test('needsOwnerAction only for pending', () {
      expect(BookingStatus.pending.needsOwnerAction, isTrue);
      expect(BookingStatus.confirmed.needsOwnerAction, isFalse);
      expect(BookingStatus.cancelled.needsOwnerAction, isFalse);
      expect(BookingStatus.completed.needsOwnerAction, isFalse);
    });

    test('sortPriority ordering is correct', () {
      expect(BookingStatus.pending.sortPriority, 4);
      expect(BookingStatus.confirmed.sortPriority, 3);
      expect(BookingStatus.completed.sortPriority, 2);
      expect(BookingStatus.cancelled.sortPriority, 1);
    });

    test('fromString parses known values', () {
      expect(BookingStatus.fromString('pending'), BookingStatus.pending);
      expect(BookingStatus.fromString('confirmed'), BookingStatus.confirmed);
      expect(BookingStatus.fromString('cancelled'), BookingStatus.cancelled);
      expect(BookingStatus.fromString('completed'), BookingStatus.completed);
    });

    test('fromString defaults to pending for unknown values', () {
      expect(BookingStatus.fromString('unknown'), BookingStatus.pending);
      expect(BookingStatus.fromString(''), BookingStatus.pending);
    });
  });
}
