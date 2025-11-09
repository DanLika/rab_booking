import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../domain/models/calendar_date_status.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/constants/enums.dart';

/// Firebase repository for booking calendar with realtime updates and prices
class FirebaseBookingCalendarRepository {
  final FirebaseFirestore _firestore;

  FirebaseBookingCalendarRepository(this._firestore);

  /// Get year-view calendar data with realtime updates and prices
  Stream<Map<DateTime, CalendarDateInfo>> watchYearCalendarData({
    required String unitId,
    required int year,
  }) {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31, 23, 59, 59);

    // Stream bookings
    final bookingsStream = _firestore
        .collection('bookings')
        .where('unit_id', isEqualTo: unitId)
        .where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
        .where('check_in', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots();

    // Stream prices
    final pricesStream = _firestore
        .collection('daily_prices')
        .where('unit_id', isEqualTo: unitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots();

    // Stream iCal events (Booking.com, Airbnb, etc.)
    final icalEventsStream = _firestore
        .collection('ical_events')
        .where('unit_id', isEqualTo: unitId)
        .where('start_date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots();

    // Combine all three streams
    return Rx.combineLatest3(
      bookingsStream,
      pricesStream,
      icalEventsStream,
      (bookingsSnapshot, pricesSnapshot, icalEventsSnapshot) {
        // Parse bookings
        final bookings = bookingsSnapshot.docs
            .map((doc) {
              try {
                return BookingModel.fromJson({...doc.data(), 'id': doc.id});
              } catch (e) {
                LoggingService.logError('Error parsing booking', e);
                return null;
              }
            })
            .where((booking) =>
                booking != null && booking.checkOut.isAfter(startDate))
            .cast<BookingModel>()
            .toList();

        // Parse iCal events as "blocked" dates
        final icalEvents = icalEventsSnapshot.docs
            .map((doc) {
              try {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'start_date': (data['start_date'] as Timestamp).toDate(),
                  'end_date': (data['end_date'] as Timestamp).toDate(),
                  'source': data['source'] ?? 'ical',
                  'guest_name': data['guest_name'] ?? 'External Booking',
                };
              } catch (e) {
                LoggingService.logError('Error parsing iCal event', e);
                return null;
              }
            })
            .where((event) =>
                event != null && event['end_date'].isAfter(startDate))
            .cast<Map<String, dynamic>>()
            .toList();

        // Parse prices
        final Map<String, double> priceMap = {};
        for (final doc in pricesSnapshot.docs) {
          final data = doc.data();
          // Skip documents without valid date field
          if (data['date'] == null) continue;

          try {
            final price = DailyPriceModel.fromJson({...data, 'id': doc.id});
            final key = '${price.date.year}-${price.date.month}-${price.date.day}';
            priceMap[key] = price.price;
          } catch (e) {
            LoggingService.logError('Error parsing daily price', e);
          }
        }

        // Build calendar with both bookings and iCal events
        return _buildYearCalendarMap(bookings, priceMap, year, icalEvents);
      },
    );
  }

  /// Get month-view calendar data with realtime updates and prices
  /// UPDATED: Now includes iCal events (Booking.com, Airbnb, etc.)
  Stream<Map<DateTime, CalendarDateInfo>> watchCalendarData({
    required String unitId,
    required int year,
    required int month,
  }) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    // Stream bookings
    final bookingsStream = _firestore
        .collection('bookings')
        .where('unit_id', isEqualTo: unitId)
        .where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
        .where('check_in', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots();

    // Stream prices
    final pricesStream = _firestore
        .collection('daily_prices')
        .where('unit_id', isEqualTo: unitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots();

    // Stream iCal events (Booking.com, Airbnb, etc.) - OPTIONAL
    final icalEventsStream = _firestore
        .collection('ical_events')
        .where('unit_id', isEqualTo: unitId)
        .where('start_date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots();

    // Combine all three streams
    return Rx.combineLatest3(
      bookingsStream,
      pricesStream,
      icalEventsStream,
      (bookingsSnapshot, pricesSnapshot, icalEventsSnapshot) {
        // Parse bookings
        final bookings = bookingsSnapshot.docs
            .map((doc) {
              try {
                return BookingModel.fromJson({...doc.data(), 'id': doc.id});
              } catch (e) {
                LoggingService.logError('Error parsing booking', e);
                return null;
              }
            })
            .where((booking) =>
                booking != null && booking.checkOut.isAfter(startDate))
            .cast<BookingModel>()
            .toList();

        // Parse iCal events as "blocked" dates
        final icalEvents = icalEventsSnapshot.docs
            .map((doc) {
              try {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'start_date': (data['start_date'] as Timestamp).toDate(),
                  'end_date': (data['end_date'] as Timestamp).toDate(),
                  'source': data['source'] ?? 'ical',
                  'guest_name': data['guest_name'] ?? 'External Booking',
                };
              } catch (e) {
                LoggingService.logError('Error parsing iCal event', e);
                return null;
              }
            })
            .where((event) =>
                event != null && event['end_date'].isAfter(startDate))
            .cast<Map<String, dynamic>>()
            .toList();

        // Parse prices
        final Map<String, double> priceMap = {};
        for (final doc in pricesSnapshot.docs) {
          final data = doc.data();
          // Skip documents without valid date field
          if (data['date'] == null) continue;

          try {
            final price = DailyPriceModel.fromJson({...data, 'id': doc.id});
            final key = '${price.date.year}-${price.date.month}-${price.date.day}';
            priceMap[key] = price.price;
          } catch (e) {
            LoggingService.logError('Error parsing daily price', e);
          }
        }

        // Build calendar with bookings AND iCal events
        return _buildCalendarMap(bookings, priceMap, year, month, icalEvents);
      },
    );
  }

  /// Build calendar map for a specific month
  /// UPDATED: Now includes iCal events
  Map<DateTime, CalendarDateInfo> _buildCalendarMap(
    List<BookingModel> bookings,
    Map<String, double> priceMap,
    int year,
    int month,
    [List<Map<String, dynamic>>? icalEvents]
  ) {
    final Map<DateTime, CalendarDateInfo> calendar = {};
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Initialize all days as available with prices
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final priceKey = '${date.year}-${date.month}-${date.day}';
      final price = priceMap[priceKey];

      calendar[date] = CalendarDateInfo(
        date: date,
        status: DateStatus.available,
        price: price,
      );
    }

    // Mark booked dates
    for (final booking in bookings) {
      final checkIn = DateTime(
        booking.checkIn.year,
        booking.checkIn.month,
        booking.checkIn.day,
      );
      final checkOut = DateTime(
        booking.checkOut.year,
        booking.checkOut.month,
        booking.checkOut.day,
      );

      DateTime current = checkIn;
      while (current.isBefore(checkOut) ||
          current.isAtSameMomentAs(checkOut)) {
        if (current.year == year && current.month == month) {
          final isCheckIn = current.isAtSameMomentAs(checkIn);
          final isCheckOut = current.isAtSameMomentAs(checkOut);

          // Check if booking is pending to show orange/amber color
          final isPending = booking.status == BookingStatus.pending;

          DateStatus status;
          if (isPending) {
            // Pending bookings always show as orange regardless of check-in/out
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
          final priceKey = '${current.year}-${current.month}-${current.day}';
          calendar[current] = CalendarDateInfo(
            date: current,
            status: status,
            price: priceMap[priceKey],
          );
        }

        current = current.add(const Duration(days: 1));
      }
    }

    // Mark booked dates from iCal events (Booking.com, Airbnb, etc.)
    if (icalEvents != null) {
      for (final event in icalEvents) {
        final checkIn = DateTime(
          event['start_date'].year,
          event['start_date'].month,
          event['start_date'].day,
        );
        final checkOut = DateTime(
          event['end_date'].year,
          event['end_date'].month,
          event['end_date'].day,
        );

        DateTime current = checkIn;
        while (current.isBefore(checkOut) ||
            current.isAtSameMomentAs(checkOut)) {
          if (current.year == year && current.month == month) {
            // Mark as booked (from external source)
            final priceKey = '${current.year}-${current.month}-${current.day}';
            calendar[current] = CalendarDateInfo(
              date: current,
              status: DateStatus.booked, // Always fully booked for iCal events
              price: priceMap[priceKey],
            );
          }

          current = current.add(const Duration(days: 1));
        }

        LoggingService.log(
          '📅 iCal Event blocked (month view): ${event['source']} from $checkIn to $checkOut',
          tag: 'iCAL_SYNC',
        );
      }
    }

    return calendar;
  }

  /// Build calendar map for entire year
  Map<DateTime, CalendarDateInfo> _buildYearCalendarMap(
    List<BookingModel> bookings,
    Map<String, double> priceMap,
    int year,
    [List<Map<String, dynamic>>? icalEvents]
  ) {
    final Map<DateTime, CalendarDateInfo> calendar = {};

    // Initialize all days in year as available with prices
    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        final priceKey = '${date.year}-${date.month}-${date.day}';
        final price = priceMap[priceKey];

        calendar[date] = CalendarDateInfo(
          date: date,
          status: DateStatus.available,
          price: price,
        );
      }
    }

    // Mark booked dates from regular bookings
    for (final booking in bookings) {
      final checkIn = DateTime(
        booking.checkIn.year,
        booking.checkIn.month,
        booking.checkIn.day,
      );
      final checkOut = DateTime(
        booking.checkOut.year,
        booking.checkOut.month,
        booking.checkOut.day,
      );

      DateTime current = checkIn;
      while (current.isBefore(checkOut) ||
          current.isAtSameMomentAs(checkOut)) {
        if (current.year == year) {
          final isCheckIn = current.isAtSameMomentAs(checkIn);
          final isCheckOut = current.isAtSameMomentAs(checkOut);

          // Check if booking is pending to show orange/amber color
          final isPending = booking.status == BookingStatus.pending;

          DateStatus status;
          if (isPending) {
            // Pending bookings always show as orange regardless of check-in/out
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
          final priceKey = '${current.year}-${current.month}-${current.day}';
          calendar[current] = CalendarDateInfo(
            date: current,
            status: status,
            price: priceMap[priceKey],
          );
        }

        current = current.add(const Duration(days: 1));
      }
    }

    // Mark booked dates from iCal events (Booking.com, Airbnb, etc.)
    if (icalEvents != null) {
      for (final event in icalEvents) {
        final checkIn = DateTime(
          event['start_date'].year,
          event['start_date'].month,
          event['start_date'].day,
        );
        final checkOut = DateTime(
          event['end_date'].year,
          event['end_date'].month,
          event['end_date'].day,
        );

        DateTime current = checkIn;
        while (current.isBefore(checkOut) ||
            current.isAtSameMomentAs(checkOut)) {
          if (current.year == year) {
            // Mark as booked (from external source)
            final priceKey = '${current.year}-${current.month}-${current.day}';
            calendar[current] = CalendarDateInfo(
              date: current,
              status: DateStatus.booked, // Always fully booked for iCal events
              price: priceMap[priceKey],
            );
          }

          current = current.add(const Duration(days: 1));
        }

        LoggingService.log(
          '📅 iCal Event blocked: ${event['source']} from $checkIn to $checkOut',
          tag: 'iCAL_SYNC',
        );
      }
    }

    return calendar;
  }

  /// Check if date range is available for booking
  /// Checks both regular bookings AND iCal events (Booking.com, Airbnb, etc.)
  Future<bool> checkAvailability({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      // Check regular bookings
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('unit_id', isEqualTo: unitId)
          .where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
          .where('check_in', isLessThan: Timestamp.fromDate(checkOut))
          .get();

      for (final doc in bookingsSnapshot.docs) {
        try {
          final booking = BookingModel.fromJson({...doc.data(), 'id': doc.id});
          if (booking.checkOut.isAfter(checkIn)) {
            LoggingService.log(
              '❌ Booking conflict found: ${booking.id}',
              tag: 'AVAILABILITY_CHECK',
            );
            return false; // Conflict with regular booking
          }
        } catch (e) {
          LoggingService.logError('Error checking booking availability', e);
        }
      }

      // Check iCal events (Booking.com, Airbnb, etc.)
      final icalEventsSnapshot = await _firestore
          .collection('ical_events')
          .where('unit_id', isEqualTo: unitId)
          .where('start_date', isLessThan: Timestamp.fromDate(checkOut))
          .get();

      for (final doc in icalEventsSnapshot.docs) {
        try {
          final data = doc.data();
          final eventStartDate = (data['start_date'] as Timestamp).toDate();
          final eventEndDate = (data['end_date'] as Timestamp).toDate();

          // Check if events overlap
          if (eventEndDate.isAfter(checkIn)) {
            LoggingService.log(
              '❌ iCal conflict found: ${data['source']} event from $eventStartDate to $eventEndDate',
              tag: 'AVAILABILITY_CHECK',
            );
            return false; // Conflict with iCal event
          }
        } catch (e) {
          LoggingService.logError('Error checking iCal event availability', e);
        }
      }

      LoggingService.log(
        '✅ No conflicts found for $checkIn to $checkOut',
        tag: 'AVAILABILITY_CHECK',
      );

      return true; // No conflicts with either bookings or iCal events
    } catch (e) {
      LoggingService.logError('Error checking availability', e);
      return false;
    }
  }

  /// Calculate total price for date range
  Future<double> calculateBookingPrice({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      final pricesSnapshot = await _firestore
          .collection('daily_prices')
          .where('unit_id', isEqualTo: unitId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(checkIn))
          .where('date', isLessThan: Timestamp.fromDate(checkOut))
          .get();

      double total = 0.0;
      for (final doc in pricesSnapshot.docs) {
        final data = doc.data();
        // Skip documents without valid date field
        if (data['date'] == null) continue;

        try {
          final price = DailyPriceModel.fromJson({...data, 'id': doc.id});
          total += price.price;
        } catch (e) {
          LoggingService.logError('Error parsing price', e);
        }
      }

      return total;
    } catch (e) {
      LoggingService.logError('Error calculating booking price', e);
      return 0.0;
    }
  }
}
