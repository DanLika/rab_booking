import 'package:flutter/foundation.dart';
import '../../../../core/constants/enums.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../domain/models/calendar_date_status.dart';
import '../../utils/date_key_generator.dart';
import '../../utils/date_normalizer.dart';

/// Parsed iCal event data for calendar building.
class ParsedIcalEvent {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final String source;
  final String guestName;

  const ParsedIcalEvent({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.source,
    required this.guestName,
  });
}

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
/// final builder = CalendarDataBuilder();
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
  /// Build calendar map for a specific month.
  Map<DateTime, CalendarDateInfo> buildMonthCalendar({
    required List<BookingModel> bookings,
    required Map<String, DailyPriceModel> priceMap,
    required int year,
    required int month,
    required int minNights,
    List<ParsedIcalEvent>? icalEvents,
  }) {
    final Map<DateTime, CalendarDateInfo> calendar = {};
    final daysInMonth = DateTime.utc(year, month + 1, 0).day;

    // Bug #65 Fix: Use UTC for DST-safe date handling
    final monthStart = DateTime.utc(year, month);
    final monthEnd = DateTime.utc(year, month, daysInMonth);

    // 1. Initialize all days as available with prices
    _initializeMonthDays(calendar, priceMap, year, month, daysInMonth);

    // 2. Mark booked dates from regular bookings
    _markBookedDates(calendar, bookings, priceMap, monthStart, monthEnd);

    // 3. Mark booked dates from iCal events
    if (icalEvents != null && icalEvents.isNotEmpty) {
      _markIcalEventDates(calendar, icalEvents, priceMap, monthStart, monthEnd);
    }

    // 4. Apply gap blocking based on minimum nights requirement
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
    final Map<DateTime, CalendarDateInfo> calendar = {};

    final yearStart = DateTime(year);
    final yearEnd = DateTime(year, 12, 31);

    // 1. Initialize all days in year as available with prices
    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      _initializeMonthDays(calendar, priceMap, year, month, daysInMonth);
    }

    // 2. Mark booked dates from regular bookings
    _markBookedDates(calendar, bookings, priceMap, yearStart, yearEnd);

    // 3. Mark booked dates from iCal events
    if (icalEvents != null && icalEvents.isNotEmpty) {
      _markIcalEventDates(calendar, icalEvents, priceMap, yearStart, yearEnd);
    }

    // 4. Apply gap blocking based on minimum nights requirement
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
      final priceKey = DateKeyGenerator.fromDate(date);
      final priceModel = priceMap[priceKey];

      calendar[date] = CalendarDateInfo(
        date: date,
        status: DateStatus.available,
        price: priceModel?.price,
      );
    }
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
    debugPrint('[CalendarDataBuilder] Processing ${bookings.length} bookings');
    for (final booking in bookings) {
      final checkIn = DateNormalizer.normalize(booking.checkIn);
      final checkOut = DateNormalizer.normalize(booking.checkOut);
      final isPending = booking.status == BookingStatus.pending;

      debugPrint('[CalendarDataBuilder] Booking ${booking.id.substring(0, 8)}: '
          'status=${booking.status}, isPending=$isPending, '
          'checkIn=$checkIn, checkOut=$checkOut');

      // Calculate intersection of booking range with current range
      final effectiveStart = checkIn.isAfter(rangeStart) ? checkIn : rangeStart;
      final effectiveEnd = checkOut.isBefore(rangeEnd) ? checkOut : rangeEnd;

      // Only iterate if booking overlaps with current range
      if (!effectiveStart.isAfter(effectiveEnd)) {
        _markDateRange(
          calendar: calendar,
          priceMap: priceMap,
          start: effectiveStart,
          end: effectiveEnd,
          checkIn: checkIn,
          checkOut: checkOut,
          isPending: isPending,
        );
      }
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

      // Calculate intersection of event range with current range
      final effectiveStart = checkIn.isAfter(rangeStart) ? checkIn : rangeStart;
      final effectiveEnd = checkOut.isBefore(rangeEnd) ? checkOut : rangeEnd;

      // Only iterate if event overlaps with current range
      if (!effectiveStart.isAfter(effectiveEnd)) {
        DateTime current = effectiveStart;
        while (current.isBefore(effectiveEnd) ||
            current.isAtSameMomentAs(effectiveEnd)) {
          // Mark as booked (always fully booked for iCal events)
          final priceKey = DateKeyGenerator.fromDate(current);
          calendar[current] = CalendarDateInfo(
            date: current,
            status: DateStatus.booked,
            price: priceMap[priceKey]?.price,
          );

          current = current.add(const Duration(days: 1));
        }
      }
    }
  }

  /// Mark a date range with appropriate status.
  void _markDateRange({
    required Map<DateTime, CalendarDateInfo> calendar,
    required Map<String, DailyPriceModel> priceMap,
    required DateTime start,
    required DateTime end,
    required DateTime checkIn,
    required DateTime checkOut,
    required bool isPending,
  }) {
    DateTime current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      final isCheckIn = DateNormalizer.isSameDay(current, checkIn);
      final isCheckOut = DateNormalizer.isSameDay(current, checkOut);

      DateStatus status;
      if (isPending) {
        // Pending bookings show as RED with diagonal pattern (blocks dates)
        status = DateStatus.pending;
      } else if (isCheckIn && isCheckOut) {
        status = DateStatus.booked;
      } else if (isCheckIn) {
        status = DateStatus.partialCheckIn;
      } else if (isCheckOut) {
        status = DateStatus.partialCheckOut;
      } else {
        status = DateStatus.booked;
      }

      // Preserve price when updating status
      final priceKey = DateKeyGenerator.fromDate(current);
      calendar[current] = CalendarDateInfo(
        date: current,
        status: status,
        price: priceMap[priceKey]?.price,
      );

      current = current.add(const Duration(days: 1));
    }
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
    // Sort bookings by check-in date
    final sortedBookings = List<BookingModel>.from(bookings)
      ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

    // Check gaps between consecutive bookings
    for (int i = 0; i < sortedBookings.length - 1; i++) {
      final currentBooking = sortedBookings[i];
      final nextBooking = sortedBookings[i + 1];

      final checkOutCurrent = DateNormalizer.normalize(currentBooking.checkOut);
      final checkInNext = DateNormalizer.normalize(nextBooking.checkIn);

      // Calculate gap in days
      final gapStart = checkOutCurrent;
      final gapEnd = checkInNext;
      final gapDays = gapEnd.difference(gapStart).inDays;

      // Get minNights from first day of gap (or use default)
      final priceKey = DateKeyGenerator.fromDate(gapStart);
      final priceModel = priceMap[priceKey];
      final minNights = priceModel?.minNightsOnArrival ?? defaultMinNights;

      // If gap is less than minNights, block all days in the gap
      if (gapDays > 0 && gapDays < minNights) {
        DateTime current = gapStart;
        while (current.isBefore(gapEnd)) {
          // Only block if it exists in calendar and is available
          final existingInfo = calendar[current];
          if (existingInfo != null &&
              existingInfo.status == DateStatus.available) {
            calendar[current] = CalendarDateInfo(
              date: current,
              status: DateStatus.blocked,
              price: existingInfo.price,
            );
          }
          current = current.add(const Duration(days: 1));
        }
      }
    }
  }

  /// Check if a date falls within a booking range.
  bool isDateInBookingRange(DateTime date, BookingModel booking) {
    final normalizedDate = DateNormalizer.normalize(date);
    final checkIn = DateNormalizer.normalize(booking.checkIn);
    final checkOut = DateNormalizer.normalize(booking.checkOut);

    return !normalizedDate.isBefore(checkIn) &&
        normalizedDate.isBefore(checkOut);
  }

  /// Get the status for a specific date within a booking.
  DateStatus getBookingDateStatus(
    DateTime date,
    BookingModel booking,
  ) {
    final normalizedDate = DateNormalizer.normalize(date);
    final checkIn = DateNormalizer.normalize(booking.checkIn);
    final checkOut = DateNormalizer.normalize(booking.checkOut);

    if (booking.status == BookingStatus.pending) {
      return DateStatus.pending;
    }

    final isCheckIn = DateNormalizer.isSameDay(normalizedDate, checkIn);
    final isCheckOut = DateNormalizer.isSameDay(normalizedDate, checkOut);

    if (isCheckIn && isCheckOut) {
      return DateStatus.booked;
    } else if (isCheckIn) {
      return DateStatus.partialCheckIn;
    } else if (isCheckOut) {
      return DateStatus.partialCheckOut;
    }

    return DateStatus.booked;
  }
}
