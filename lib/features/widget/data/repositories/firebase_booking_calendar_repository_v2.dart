import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../domain/models/calendar_date_status.dart';

/// Firebase repository for booking calendar with realtime updates and prices
class FirebaseBookingCalendarRepositoryV2 {
  final FirebaseFirestore _firestore;

  FirebaseBookingCalendarRepositoryV2(this._firestore);

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

    // Combine both streams
    return Rx.combineLatest2(
      bookingsStream,
      pricesStream,
      (bookingsSnapshot, pricesSnapshot) {
        // Parse bookings
        final bookings = bookingsSnapshot.docs
            .map((doc) {
              try {
                return BookingModel.fromJson({...doc.data(), 'id': doc.id});
              } catch (e) {
                print('Error parsing booking: $e');
                return null;
              }
            })
            .where((booking) =>
                booking != null && booking.checkOut.isAfter(startDate))
            .cast<BookingModel>()
            .toList();

        // Parse prices
        final Map<String, double> priceMap = {};
        for (final doc in pricesSnapshot.docs) {
          try {
            final price = DailyPriceModel.fromJson({...doc.data(), 'id': doc.id});
            final key = '${price.date.year}-${price.date.month}-${price.date.day}';
            priceMap[key] = price.price;
          } catch (e) {
            print('Error parsing daily price: $e');
          }
        }

        // Build calendar
        return _buildYearCalendarMap(bookings, priceMap, year);
      },
    );
  }

  /// Get month-view calendar data with realtime updates and prices
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

    // Combine both streams
    return Rx.combineLatest2(
      bookingsStream,
      pricesStream,
      (bookingsSnapshot, pricesSnapshot) {
        // Parse bookings
        final bookings = bookingsSnapshot.docs
            .map((doc) {
              try {
                return BookingModel.fromJson({...doc.data(), 'id': doc.id});
              } catch (e) {
                print('Error parsing booking: $e');
                return null;
              }
            })
            .where((booking) =>
                booking != null && booking.checkOut.isAfter(startDate))
            .cast<BookingModel>()
            .toList();

        // Parse prices
        final Map<String, double> priceMap = {};
        for (final doc in pricesSnapshot.docs) {
          try {
            final price = DailyPriceModel.fromJson({...doc.data(), 'id': doc.id});
            final key = '${price.date.year}-${price.date.month}-${price.date.day}';
            priceMap[key] = price.price;
          } catch (e) {
            print('Error parsing daily price: $e');
          }
        }

        // Build calendar
        return _buildCalendarMap(bookings, priceMap, year, month);
      },
    );
  }

  /// Build calendar map for a specific month
  Map<DateTime, CalendarDateInfo> _buildCalendarMap(
    List<BookingModel> bookings,
    Map<String, double> priceMap,
    int year,
    int month,
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

          DateStatus status;
          if (isCheckIn && isCheckOut) {
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

    return calendar;
  }

  /// Build calendar map for entire year
  Map<DateTime, CalendarDateInfo> _buildYearCalendarMap(
    List<BookingModel> bookings,
    Map<String, double> priceMap,
    int year,
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
        if (current.year == year) {
          final isCheckIn = current.isAtSameMomentAs(checkIn);
          final isCheckOut = current.isAtSameMomentAs(checkOut);

          DateStatus status;
          if (isCheckIn && isCheckOut) {
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

    return calendar;
  }

  /// Check if date range is available for booking
  Future<bool> checkAvailability({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('unit_id', isEqualTo: unitId)
          .where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
          .where('check_in', isLessThan: Timestamp.fromDate(checkOut))
          .get();

      for (final doc in snapshot.docs) {
        try {
          final booking = BookingModel.fromJson({...doc.data(), 'id': doc.id});
          if (booking.checkOut.isAfter(checkIn)) {
            return false; // Conflict found
          }
        } catch (e) {
          print('Error checking booking availability: $e');
        }
      }

      return true; // No conflicts
    } catch (e) {
      print('Error checking availability: $e');
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
        try {
          final price = DailyPriceModel.fromJson({...doc.data(), 'id': doc.id});
          total += price.price;
        } catch (e) {
          print('Error parsing price: $e');
        }
      }

      return total;
    } catch (e) {
      print('Error calculating booking price: $e');
      return 0.0;
    }
  }
}
