import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../domain/models/calendar_date_status.dart';
import '../../../../core/constants/enums.dart';

/// Provider for month calendar data with gap blocking support
final monthCalendarDataProvider =
    FutureProvider.family<
      Map<String, CalendarDateInfo>,
      (String, DateTime, int)
    >((ref, params) async {
      final (unitId, monthStart, minNights) = params;
      final bookingRepo = ref.watch(bookingRepositoryProvider);
      final dailyPriceRepo = ref.watch(dailyPriceRepositoryProvider);

      // Bug #65 Fix: Get first and last day of the month in UTC for DST-safe calculations
      final firstDay = DateTime.utc(monthStart.year, monthStart.month);
      final lastDay = DateTime.utc(monthStart.year, monthStart.month + 1, 0);

      // Load bookings from extended range to detect gaps across month boundaries
      // Load from 1 month before to 1 month after to catch adjacent bookings
      final extendedStart = DateTime.utc(monthStart.year, monthStart.month - 1);
      final extendedEnd = DateTime.utc(
        monthStart.year,
        monthStart.month + 2,
        0,
      );

      final allBookings = await bookingRepo.getBookingsInRange(
        unitId: unitId,
        startDate: extendedStart,
        endDate: extendedEnd,
      );

      // Filter out cancelled bookings - they should NOT block dates or gaps
      // Only include: pending, confirmed, checked_in, in_progress, blocked
      final bookings = allBookings.where((booking) {
        return booking.status != BookingStatus.cancelled &&
            booking.status != BookingStatus.completed &&
            booking.status != BookingStatus.checkedOut;
      }).toList();

      // Load iCal events (external bookings from Booking.com, Airbnb, etc.)
      // Note: Using client-side filtering to avoid Firestore limitation of
      // multiple inequality filters on different fields (start_date and end_date)
      final icalEventsSnapshot = await FirebaseFirestore.instance
          .collection('ical_events')
          .where('unit_id', isEqualTo: unitId)
          .get();

      // Client-side filtering: only include events that overlap with the extended range
      final icalEvents = icalEventsSnapshot.docs
          .map((doc) {
            final data = doc.data();
            return {
              'start_date': (data['start_date'] as Timestamp).toDate(),
              'end_date': (data['end_date'] as Timestamp).toDate(),
            };
          })
          .where((event) {
            final startDate = event['start_date'] as DateTime;
            final endDate = event['end_date'] as DateTime;
            // Include event if it overlaps with the extended range:
            // (endDate >= extendedStart) AND (startDate <= extendedEnd)
            return endDate.isAfter(extendedStart) ||
                endDate.isAtSameMomentAs(extendedStart) &&
                    startDate.isBefore(extendedEnd) ||
                startDate.isAtSameMomentAs(extendedEnd);
          })
          .toList();

      // Get daily prices for this month
      final dailyPrices = await dailyPriceRepo.getPricesForDateRange(
        unitId: unitId,
        startDate: firstDay,
        endDate: lastDay,
      );

      // Create a map for quick lookup
      final Map<String, DailyPriceModel> priceMap = {};
      for (final price in dailyPrices) {
        final key = _getDateKey(price.date);
        priceMap[key] = price;
      }

      // Build calendar data map
      final Map<String, CalendarDateInfo> calendarData = {};

      // Bug #65 Fix: Get today normalized to midnight UTC for DST-safe comparison
      final today = DateTime.now().toUtc();
      final todayNormalized = DateTime.utc(today.year, today.month, today.day);

      // Initialize all dates in the month as available or disabled (past dates)
      for (int day = 1; day <= lastDay.day; day++) {
        final date = DateTime.utc(monthStart.year, monthStart.month, day);
        final key = _getDateKey(date);

        // Mark past dates as disabled
        final isPast = date.isBefore(todayNormalized);

        // Get price data for this date
        final priceData = priceMap[key];

        calendarData[key] = CalendarDateInfo(
          date: date,
          status: isPast ? DateStatus.disabled : DateStatus.available,
          price: priceData?.price,
          blockCheckIn: priceData?.blockCheckIn ?? false,
          blockCheckOut: priceData?.blockCheckOut ?? false,
          minDaysAdvance: priceData?.minDaysAdvance,
          maxDaysAdvance: priceData?.maxDaysAdvance,
        );
      }

      // Mark booked dates with partial CheckIn/CheckOut support
      for (final booking in bookings) {
        final checkIn = DateTime.utc(
          booking.checkIn.year,
          booking.checkIn.month,
          booking.checkIn.day,
        );
        final checkOut = DateTime.utc(
          booking.checkOut.year,
          booking.checkOut.month,
          booking.checkOut.day,
        );

        DateTime current = checkIn;
        while (current.isBefore(checkOut) || _isSameDay(current, checkOut)) {
          final key = _getDateKey(current);
          if (calendarData.containsKey(key)) {
            // Check if date is in the past
            final isPast = current.isBefore(todayNormalized);

            final isCheckIn = _isSameDay(current, checkIn);
            final isCheckOut = _isSameDay(current, checkOut);

            // Preserve blockCheckIn/blockCheckOut from price data
            final existingInfo = calendarData[key]!;

            DateStatus status;
            if (isPast) {
              // Past dates that were part of a reservation show as pastReservation (red with opacity)
              status = DateStatus.pastReservation;
            } else if (isCheckIn && isCheckOut) {
              // Single-day booking
              status = DateStatus.booked;
            } else if (isCheckIn) {
              // Check if this date already has a check-out (turnover day)
              if (existingInfo.status == DateStatus.partialCheckOut) {
                status = DateStatus.partialBoth;
              } else {
                status = DateStatus.partialCheckIn;
              }
            } else if (isCheckOut) {
              // Check if this date already has a check-in (turnover day)
              if (existingInfo.status == DateStatus.partialCheckIn) {
                status = DateStatus.partialBoth;
              } else {
                status = DateStatus.partialCheckOut;
              }
            } else {
              status = DateStatus.booked;
            }

            calendarData[key] = CalendarDateInfo(
              date: current,
              status: status,
              price: existingInfo.price,
              blockCheckIn: existingInfo.blockCheckIn,
              blockCheckOut: existingInfo.blockCheckOut,
              minDaysAdvance: existingInfo.minDaysAdvance,
              maxDaysAdvance: existingInfo.maxDaysAdvance,
            );
          }
          current = current.add(const Duration(days: 1));
        }
      }

      // Mark iCal events as booked (external bookings from Booking.com, Airbnb, etc.)
      for (final event in icalEvents) {
        final startDate = event['start_date'] as DateTime;
        final endDate = event['end_date'] as DateTime;

        final checkIn = DateTime.utc(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        final checkOut = DateTime.utc(endDate.year, endDate.month, endDate.day);

        DateTime current = checkIn;
        while (current.isBefore(checkOut) || _isSameDay(current, checkOut)) {
          final key = _getDateKey(current);
          if (calendarData.containsKey(key)) {
            final existingInfo = calendarData[key]!;

            // iCal events are always fully booked (no partial check-in/out)
            calendarData[key] = CalendarDateInfo(
              date: current,
              status: DateStatus.booked,
              price: existingInfo.price,
              blockCheckIn: existingInfo.blockCheckIn,
              blockCheckOut: existingInfo.blockCheckOut,
              minDaysAdvance: existingInfo.minDaysAdvance,
              maxDaysAdvance: existingInfo.maxDaysAdvance,
            );
          }
          current = current.add(const Duration(days: 1));
        }
      }

      // Gap Blocking: Block small gaps between bookings AND iCal events that are < minNights
      // Combine bookings and iCal events into a single list for gap detection
      final allReservations = <Map<String, DateTime>>[];

      // Add regular bookings
      for (final booking in bookings) {
        allReservations.add({
          'checkIn': DateTime.utc(
            booking.checkIn.year,
            booking.checkIn.month,
            booking.checkIn.day,
          ),
          'checkOut': DateTime.utc(
            booking.checkOut.year,
            booking.checkOut.month,
            booking.checkOut.day,
          ),
        });
      }

      // Add iCal events
      for (final event in icalEvents) {
        final startDate = event['start_date'] as DateTime;
        final endDate = event['end_date'] as DateTime;
        allReservations.add({
          'checkIn': DateTime.utc(
            startDate.year,
            startDate.month,
            startDate.day,
          ),
          'checkOut': DateTime.utc(endDate.year, endDate.month, endDate.day),
        });
      }

      // Sort all reservations by checkout date to find gaps
      allReservations.sort((a, b) => a['checkOut']!.compareTo(b['checkOut']!));

      for (int i = 0; i < allReservations.length - 1; i++) {
        final currentReservation = allReservations[i];
        final nextReservation = allReservations[i + 1];

        final checkOut1 = currentReservation['checkOut']!;
        final checkIn2 = nextReservation['checkIn']!;

        // Bug #66 Fix: Calculate gap size (number of nights available between bookings)
        // Gap starts the day after checkout and ends the day before next checkin
        final gapStart = checkOut1.add(const Duration(days: 1));
        final gapEnd = checkIn2.subtract(const Duration(days: 1));
        final gapNights = gapEnd.difference(gapStart).inDays;

        // If gap is smaller than minNights, block it
        if (gapNights > 0 && gapNights < minNights) {
          DateTime gapDate = gapStart;
          while (gapDate.isBefore(checkIn2)) {
            final key = _getDateKey(gapDate);
            if (calendarData.containsKey(key)) {
              final existingInfo = calendarData[key]!;

              // Only block if not already booked and not in the past
              if (existingInfo.status == DateStatus.available) {
                calendarData[key] = CalendarDateInfo(
                  date: gapDate,
                  status: DateStatus.blocked,
                  price: existingInfo.price,
                  blockCheckIn: existingInfo.blockCheckIn,
                  blockCheckOut: existingInfo.blockCheckOut,
                  minDaysAdvance: existingInfo.minDaysAdvance,
                  maxDaysAdvance: existingInfo.maxDaysAdvance,
                );
              }
            }
            gapDate = gapDate.add(const Duration(days: 1));
          }
        }
      }

      return calendarData;
    });

String _getDateKey(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
