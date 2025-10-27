import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../domain/models/calendar_date_status.dart';

/// Firebase repository for booking calendar with realtime updates
class FirebaseBookingCalendarRepository {
  final FirebaseFirestore _firestore;

  FirebaseBookingCalendarRepository(this._firestore);

  /// Get calendar data for a unit with realtime updates
  /// Returns a stream that emits when bookings change
  Stream<Map<DateTime, CalendarDateInfo>> watchCalendarData({
    required String unitId,
    required int year,
    required int month,
  }) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return _firestore
        .collection('bookings')
        .where('unit_id', isEqualTo: unitId)
        .where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
        .where('check_in', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots()
        .map((snapshot) {
      // Filter bookings that overlap with our date range
      final bookings = snapshot.docs
          .map((doc) {
            try {
              return BookingModel.fromJson({...doc.data(), 'id': doc.id});
            } catch (e) {
              print('Error parsing booking: $e');
              return null;
            }
          })
          .where((booking) =>
              booking != null &&
              booking.checkOut.isAfter(startDate))
          .cast<BookingModel>()
          .toList();

      // Build calendar map
      return _buildCalendarMap(bookings, year, month);
    });
  }

  /// Get year-view calendar data with realtime updates
  Stream<Map<DateTime, CalendarDateInfo>> watchYearCalendarData({
    required String unitId,
    required int year,
  }) {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31, 23, 59, 59);

    return _firestore
        .collection('bookings')
        .where('unit_id', isEqualTo: unitId)
        .where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
        .where('check_in', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) {
            try {
              return BookingModel.fromJson({...doc.data(), 'id': doc.id});
            } catch (e) {
              print('Error parsing booking: $e');
              return null;
            }
          })
          .where((booking) =>
              booking != null &&
              booking.checkOut.isAfter(startDate))
          .cast<BookingModel>()
          .toList();

      return _buildYearCalendarMap(bookings, year);
    });
  }

  /// Build calendar map for a specific month
  Future<Map<DateTime, CalendarDateInfo>> _buildCalendarMapAsync(
    List<BookingModel> bookings,
    String unitId,
    int year,
    int month,
  ) async {
    final Map<DateTime, CalendarDateInfo> calendar = {};
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Fetch prices for this month
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month, daysInMonth);
    final pricesSnapshot = await _firestore
        .collection('daily_prices')
        .where('unit_id', isEqualTo: unitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

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

    // Initialize all days as available
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

      // Iterate through all dates in the booking
      DateTime current = checkIn;
      while (current.isBefore(checkOut) ||
          current.isAtSameMomentAs(checkOut)) {
        if (current.year == year && current.month == month) {
          // Check if this is check-in or check-out day
          final isCheckIn = current.isAtSameMomentAs(checkIn);
          final isCheckOut = current.isAtSameMomentAs(checkOut);

          DateStatus status;
          if (isCheckIn && isCheckOut) {
            // Same day check-in and check-out (rare, but possible)
            status = DateStatus.booked;
          } else if (isCheckIn) {
            // Check-in day: partial availability
            status = DateStatus.partialCheckIn;
          } else if (isCheckOut) {
            // Check-out day: partial availability
            status = DateStatus.partialCheckOut;
          } else {
            // Fully booked
            status = DateStatus.booked;
          }

          calendar[current] = CalendarDateInfo(
            date: current,
            status: status,
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
    int year,
  ) {
    final Map<DateTime, CalendarDateInfo> calendar = {};

    // Initialize all days in year as available
    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        calendar[date] = CalendarDateInfo(
          date: date,
          status: DateStatus.available,
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

          calendar[current] = CalendarDateInfo(
            date: current,
            status: status,
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

          // Check for overlap
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

  /// Get all pending bookings (awaiting bank transfer confirmation)
  Stream<List<BookingModel>> watchPendingBookings(String ownerId) {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final bookings = <BookingModel>[];

      for (final doc in snapshot.docs) {
        try {
          final booking = BookingModel.fromJson({...doc.data(), 'id': doc.id});

          // Verify this booking belongs to owner's property
          final unitDoc = await _firestore.collection('units').doc(booking.unitId).get();
          if (!unitDoc.exists) continue;

          final propertyId = unitDoc.data()!['property_id'] as String;
          final propertyDoc =
              await _firestore.collection('properties').doc(propertyId).get();

          if (propertyDoc.exists &&
              propertyDoc.data()!['owner_id'] == ownerId) {
            bookings.add(booking);
          }
        } catch (e) {
          print('Error parsing pending booking: $e');
        }
      }

      return bookings;
    });
  }
}
