import '../../../../core/constants/enums.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../domain/models/calendar_date_status.dart';
import '../../utils/date_key_generator.dart';
import '../../utils/date_normalizer.dart';

/// Parsed iCal event data for calendar building.
///
/// Using Dart 3 record for immutable, value-equality data.
typedef ParsedIcalEvent = ({
  String id,
  DateTime startDate,
  DateTime endDate,
  String source,
  String guestName,
});

/// Date range intersection result.
typedef _DateRangeIntersection = ({
  DateTime start,
  DateTime end,
  bool hasOverlap,
});

/// Builds calendar data maps from bookings, prices, and iCal events.
///
/// This helper class extracts calendar building logic from the booking
/// calendar repository for better separation of concerns.
///
/// ## Responsibilities
/// - Initialize calendar with available dates and prices
/// - Mark booked dates from regular bookings
/// - Mark booked dates from iCal events
/// - Apply gap blocking based on minimum nights
///
/// ## Usage
/// ```dart
/// const builder = CalendarDataBuilder();
///
/// final calendar = builder.buildMonthCalendar(
///   bookings: bookings,
///   priceMap: priceMap,
///   year: 2024,
///   month: 1,
///   minNights: 2,
///   icalEvents: icalEvents,
/// );
/// ```
class CalendarDataBuilder {
  const CalendarDataBuilder();

  static const _oneDay = Duration(days: 1);

  /// Build calendar map for a specific month.
  Map<DateTime, CalendarDateInfo> buildMonthCalendar({
    required List<BookingModel> bookings,
    required Map<String, DailyPriceModel> priceMap,
    required int year,
    required int month,
    required int minNights,
    List<ParsedIcalEvent>? icalEvents,
  }) {
    final calendar = <DateTime, CalendarDateInfo>{};
    final daysInMonth = DateTime.utc(year, month + 1, 0).day;

    // Bug #65 Fix: Use UTC for DST-safe date handling
    final monthStart = DateTime.utc(year, month);
    final monthEnd = DateTime.utc(year, month, daysInMonth);

    _initializeMonthDays(calendar, priceMap, year, month, daysInMonth);
    _markBookedDates(calendar, bookings, priceMap, monthStart, monthEnd);

    if (icalEvents != null && icalEvents.isNotEmpty) {
      _markIcalEventDates(calendar, icalEvents, priceMap, monthStart, monthEnd);
    }

    _applyMinNightsGapBlocking(calendar, bookings, priceMap, minNights);

    return calendar;
  }

  /// Build calendar map for entire year.
  Map<DateTime, CalendarDateInfo> buildYearCalendar({
    required List<BookingModel> bookings,
    required Map<String, DailyPriceModel> priceMap,
    required int year,
    required int minNights,
    List<ParsedIcalEvent>? icalEvents,
  }) {
    final calendar = <DateTime, CalendarDateInfo>{};

    // Bug fix: Use UTC consistently (was using local DateTime)
    final yearStart = DateTime.utc(year);
    final yearEnd = DateTime.utc(year, 12, 31);

    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime.utc(year, month + 1, 0).day;
      _initializeMonthDays(calendar, priceMap, year, month, daysInMonth);
    }

    _markBookedDates(calendar, bookings, priceMap, yearStart, yearEnd);

    if (icalEvents != null && icalEvents.isNotEmpty) {
      _markIcalEventDates(calendar, icalEvents, priceMap, yearStart, yearEnd);
    }

    _applyMinNightsGapBlocking(calendar, bookings, priceMap, minNights);

    return calendar;
  }

  /// Initialize calendar days as available with prices.
  void _initializeMonthDays(
    Map<DateTime, CalendarDateInfo> calendar,
    Map<String, DailyPriceModel> priceMap,
    int year,
    int month,
    int daysInMonth,
  ) {
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime.utc(year, month, day);
      calendar[date] = CalendarDateInfo(
        date: date,
        status: DateStatus.available,
        price: priceMap[DateKeyGenerator.fromDate(date)]?.price,
      );
    }
  }

  /// Calculate intersection of two date ranges.
  _DateRangeIntersection _calculateIntersection({
    required DateTime bookingStart,
    required DateTime bookingEnd,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final effectiveStart = bookingStart.isAfter(rangeStart)
        ? bookingStart
        : rangeStart;
    final effectiveEnd = bookingEnd.isBefore(rangeEnd) ? bookingEnd : rangeEnd;

    return (
      start: effectiveStart,
      end: effectiveEnd,
      hasOverlap: !effectiveStart.isAfter(effectiveEnd),
    );
  }

  /// Mark dates as booked from regular bookings.
  ///
  /// Bug #71 Fix: Optimized for long-term bookings by calculating
  /// date range intersection instead of iterating through all booking days.
  void _markBookedDates(
    Map<DateTime, CalendarDateInfo> calendar,
    List<BookingModel> bookings,
    Map<String, DailyPriceModel> priceMap,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    for (final booking in bookings) {
      final checkIn = DateNormalizer.normalize(booking.checkIn);
      final checkOut = DateNormalizer.normalize(booking.checkOut);

      final intersection = _calculateIntersection(
        bookingStart: checkIn,
        bookingEnd: checkOut,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      if (!intersection.hasOverlap) continue;

      _markDateRange(
        calendar: calendar,
        priceMap: priceMap,
        start: intersection.start,
        end: intersection.end,
        checkIn: checkIn,
        checkOut: checkOut,
        isPending: booking.status == BookingStatus.pending,
      );
    }
  }

  /// Mark dates as booked from iCal events.
  void _markIcalEventDates(
    Map<DateTime, CalendarDateInfo> calendar,
    List<ParsedIcalEvent> events,
    Map<String, DailyPriceModel> priceMap,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    for (final event in events) {
      final checkIn = DateNormalizer.normalize(event.startDate);
      final checkOut = DateNormalizer.normalize(event.endDate);

      final intersection = _calculateIntersection(
        bookingStart: checkIn,
        bookingEnd: checkOut,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      if (!intersection.hasOverlap) continue;

      // Mark all days as booked (iCal events are always confirmed)
      _iterateDates(intersection.start, intersection.end, (date) {
        calendar[date] = CalendarDateInfo(
          date: date,
          status: DateStatus.booked,
          price: priceMap[DateKeyGenerator.fromDate(date)]?.price,
        );
      });
    }
  }

  /// Iterate over dates in range [start, end) exclusive of end date.
  ///
  /// Bug Fix #4: Changed from inclusive to exclusive end date.
  /// For booking logic, checkout day is NOT a night - the guest leaves on checkout day.
  /// This matches standard booking industry practice where:
  /// - Check-in day IS included (first night)
  /// - Check-out day is NOT included (no night spent)
  ///
  /// Example: Booking Jan 1-5 iterates Jan 1, 2, 3, 4 (4 nights), NOT Jan 5.
  void _iterateDates(
    DateTime start,
    DateTime end,
    void Function(DateTime date) action,
  ) {
    var current = start;
    while (current.isBefore(end)) {
      action(current);
      current = current.add(_oneDay);
    }
  }

  /// Mark a date range with appropriate status.
  ///
  /// Bug Fix #4: Now explicitly marks checkout day since _iterateDates
  /// uses exclusive end date. Checkout day gets partialCheckOut status
  /// (or pending if booking is pending) to show it's available for new check-ins.
  void _markDateRange({
    required Map<DateTime, CalendarDateInfo> calendar,
    required Map<String, DailyPriceModel> priceMap,
    required DateTime start,
    required DateTime end,
    required DateTime checkIn,
    required DateTime checkOut,
    required bool isPending,
  }) {
    // Mark all nights (check-in through day before check-out)
    _iterateDates(start, end, (current) {
      final status = _determineStatus(
        isCheckInDay: DateNormalizer.isSameDay(current, checkIn),
        isCheckOutDay: false, // Never true in iteration (checkout excluded)
        isPending: isPending,
      );

      calendar[current] = CalendarDateInfo(
        date: current,
        status: status,
        price: priceMap[DateKeyGenerator.fromDate(current)]?.price,
        isPendingBooking: isPending,
      );
    });

    // Bug Fix #4: Explicitly mark checkout day if within range
    // Checkout day shows as partialCheckOut (guest leaving, available for new check-in)
    if (!checkOut.isBefore(start) && !checkOut.isAfter(end)) {
      final checkoutStatus = isPending
          ? DateStatus.pending
          : DateStatus.partialCheckOut;
      calendar[checkOut] = CalendarDateInfo(
        date: checkOut,
        status: checkoutStatus,
        price: priceMap[DateKeyGenerator.fromDate(checkOut)]?.price,
        isPendingBooking: isPending,
      );
    }
  }

  /// Determine the appropriate DateStatus for a date in a booking.
  DateStatus _determineStatus({
    required bool isCheckInDay,
    required bool isCheckOutDay,
    required bool isPending,
  }) {
    if (isPending) return DateStatus.pending;
    if (isCheckInDay && isCheckOutDay) return DateStatus.booked;
    if (isCheckInDay) return DateStatus.partialCheckIn;
    if (isCheckOutDay) return DateStatus.partialCheckOut;
    return DateStatus.booked;
  }

  /// Apply gap blocking based on minimum nights requirement.
  ///
  /// If gap between two bookings is less than minNights, block that gap.
  void _applyMinNightsGapBlocking(
    Map<DateTime, CalendarDateInfo> calendar,
    List<BookingModel> bookings,
    Map<String, DailyPriceModel> priceMap,
    int defaultMinNights,
  ) {
    if (bookings.length < 2) return;

    final sortedBookings = bookings.toList()
      ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

    for (int i = 0; i < sortedBookings.length - 1; i++) {
      final gapStart = DateNormalizer.normalize(sortedBookings[i].checkOut);
      final gapEnd = DateNormalizer.normalize(sortedBookings[i + 1].checkIn);
      final gapDays = gapEnd.difference(gapStart).inDays;

      if (gapDays <= 0) continue;

      final minNights =
          priceMap[DateKeyGenerator.fromDate(gapStart)]?.minNightsOnArrival ??
          defaultMinNights;

      if (gapDays < minNights) {
        _blockGapDates(calendar, gapStart, gapEnd);
      }
    }
  }

  /// Block all available dates in a gap range.
  void _blockGapDates(
    Map<DateTime, CalendarDateInfo> calendar,
    DateTime gapStart,
    DateTime gapEnd,
  ) {
    var current = gapStart;
    while (current.isBefore(gapEnd)) {
      final existingInfo = calendar[current];
      if (existingInfo?.status == DateStatus.available) {
        calendar[current] = existingInfo!.copyWith(status: DateStatus.blocked);
      }
      current = current.add(_oneDay);
    }
  }

  /// Get the status for a specific date within a booking.
  DateStatus getBookingDateStatus(DateTime date, BookingModel booking) {
    final normalizedDate = DateNormalizer.normalize(date);
    final checkIn = DateNormalizer.normalize(booking.checkIn);
    final checkOut = DateNormalizer.normalize(booking.checkOut);

    return _determineStatus(
      isCheckInDay: DateNormalizer.isSameDay(normalizedDate, checkIn),
      isCheckOutDay: DateNormalizer.isSameDay(normalizedDate, checkOut),
      isPending: booking.status == BookingStatus.pending,
    );
  }
}
