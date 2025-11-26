import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../domain/models/calendar_date_status.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/errors/app_exceptions.dart';

/// Firebase repository for booking calendar with realtime updates and prices
class FirebaseBookingCalendarRepository {
  final FirebaseFirestore _firestore;

  FirebaseBookingCalendarRepository(this._firestore);

  /// Get year-view calendar data with realtime updates and prices
  Stream<Map<DateTime, CalendarDateInfo>> watchYearCalendarData({
    required String unitId,
    required int year,
  }) {
    // Bug #65 Fix: Use UTC for DST-safe date handling
    final startDate = DateTime.utc(year);
    final endDate = DateTime.utc(year, 12, 31, 23, 59, 59);

    // Stream bookings
    // Note: Using client-side filtering to avoid Firestore limitation of
    // whereIn + inequality filters requiring composite index
    final bookingsStream = _firestore
        .collection('bookings')
        .where('unit_id', isEqualTo: unitId)
        .where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
        .snapshots();

    // Stream prices
    final pricesStream = _firestore
        .collection('daily_prices')
        .where('unit_id', isEqualTo: unitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots();

    // Stream iCal events (Booking.com, Airbnb, etc.)
    // Note: Using client-side filtering to avoid Firestore index requirement for inequality filter
    final icalEventsStream = _firestore
        .collection('ical_events')
        .where('unit_id', isEqualTo: unitId)
        .snapshots();

    // Stream widget settings to get minNights
    final widgetSettingsStream = _firestore
        .collection('widget_settings')
        .doc(unitId)
        .snapshots();

    // Combine all four streams
    return Rx.combineLatest4(
      bookingsStream,
      pricesStream,
      icalEventsStream,
      widgetSettingsStream,
      (
        bookingsSnapshot,
        pricesSnapshot,
        icalEventsSnapshot,
        widgetSettingsSnapshot,
      ) {
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
            .where(
              (booking) =>
                  booking != null && booking.checkOut.isAfter(startDate),
            )
            .cast<BookingModel>()
            .toList();

        // Parse iCal events as "blocked" dates
        // Client-side filtering: include events that overlap with the date range
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
            .where(
              (event) =>
                  event != null &&
                  event['end_date'].isAfter(startDate) &&
                  event['start_date'].isBefore(endDate),
            )
            .cast<Map<String, dynamic>>()
            .toList();

        // Parse prices
        final Map<String, DailyPriceModel> priceMap = {};
        for (final doc in pricesSnapshot.docs) {
          final data = doc.data();
          // Skip documents without valid date or unit_id field
          // FIXED: Also check if date is a valid Timestamp
          if (data['date'] == null ||
              data['date'] is! Timestamp ||
              data['unit_id'] == null) {
            continue;
          }

          try {
            final price = DailyPriceModel.fromJson({...data, 'id': doc.id});
            final key =
                '${price.date.year}-${price.date.month}-${price.date.day}';
            priceMap[key] = price;
          } catch (e) {
            LoggingService.logError('Error parsing daily price', e);
          }
        }

        // Parse widget settings to get minNights
        int minNights = 1; // Default
        if (widgetSettingsSnapshot.exists) {
          final settingsData = widgetSettingsSnapshot.data();
          minNights = settingsData?['min_nights'] ?? 1;
        }

        // Build calendar with both bookings and iCal events
        return _buildYearCalendarMap(
          bookings,
          priceMap,
          year,
          minNights,
          icalEvents,
        );
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
    // Bug #65 Fix: Use UTC for DST-safe date handling
    final startDate = DateTime.utc(year, month);
    final endDate = DateTime.utc(year, month + 1, 0, 23, 59, 59);

    // Stream bookings
    // Note: Using client-side filtering to avoid Firestore limitation of
    // whereIn + inequality filters requiring composite index
    final bookingsStream = _firestore
        .collection('bookings')
        .where('unit_id', isEqualTo: unitId)
        .where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
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

    // Stream widget settings to get minNights
    final widgetSettingsStream = _firestore
        .collection('widget_settings')
        .doc(unitId)
        .snapshots();

    // Combine all four streams
    return Rx.combineLatest4(
      bookingsStream,
      pricesStream,
      icalEventsStream,
      widgetSettingsStream,
      (
        bookingsSnapshot,
        pricesSnapshot,
        icalEventsSnapshot,
        widgetSettingsSnapshot,
      ) {
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
            .where(
              (booking) =>
                  booking != null && booking.checkOut.isAfter(startDate),
            )
            .cast<BookingModel>()
            .toList();

        // Parse iCal events as "blocked" dates
        // Client-side filtering: include events that overlap with the date range
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
            .where(
              (event) =>
                  event != null &&
                  event['end_date'].isAfter(startDate) &&
                  event['start_date'].isBefore(endDate),
            )
            .cast<Map<String, dynamic>>()
            .toList();

        // Parse prices
        final Map<String, DailyPriceModel> priceMap = {};
        for (final doc in pricesSnapshot.docs) {
          final data = doc.data();
          // Skip documents without valid date or unit_id field
          // FIXED: Also check if date is a valid Timestamp
          if (data['date'] == null ||
              data['date'] is! Timestamp ||
              data['unit_id'] == null) {
            continue;
          }

          try {
            final price = DailyPriceModel.fromJson({...data, 'id': doc.id});
            final key =
                '${price.date.year}-${price.date.month}-${price.date.day}';
            priceMap[key] = price;
          } catch (e) {
            LoggingService.logError('Error parsing daily price', e);
          }
        }

        // Parse widget settings to get minNights
        int minNights = 1; // Default
        if (widgetSettingsSnapshot.exists) {
          final settingsData = widgetSettingsSnapshot.data();
          minNights = settingsData?['min_nights'] ?? 1;
        }

        // Build calendar with bookings AND iCal events
        return _buildCalendarMap(
          bookings,
          priceMap,
          year,
          month,
          minNights,
          icalEvents,
        );
      },
    );
  }

  /// Build calendar map for a specific month
  /// UPDATED: Now includes iCal events
  Map<DateTime, CalendarDateInfo> _buildCalendarMap(
    List<BookingModel> bookings,
    Map<String, DailyPriceModel> priceMap,
    int year,
    int month,
    int minNights, [
    List<Map<String, dynamic>>? icalEvents,
  ]) {
    final Map<DateTime, CalendarDateInfo> calendar = {};
    final daysInMonth = DateTime.utc(year, month + 1, 0).day;

    // Initialize all days as available with prices
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime.utc(year, month, day);
      final priceKey = '${date.year}-${date.month}-${date.day}';
      final priceModel = priceMap[priceKey];

      calendar[date] = CalendarDateInfo(
        date: date,
        status: DateStatus.available,
        price: priceModel?.price,
      );
    }

    // Mark booked dates
    // Bug #71 Fix: Optimize for long-term bookings by calculating date range intersection
    final monthStart = DateTime.utc(year, month);
    final monthEnd = DateTime.utc(year, month, daysInMonth);

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

      // Calculate intersection of booking range with current month
      // This avoids iterating through days outside the current month
      final rangeStart = checkIn.isAfter(monthStart) ? checkIn : monthStart;
      final rangeEnd = checkOut.isBefore(monthEnd) ? checkOut : monthEnd;

      // Only iterate if booking overlaps with current month
      if (!rangeStart.isAfter(rangeEnd)) {
        DateTime current = rangeStart;
        while (current.isBefore(rangeEnd) ||
            current.isAtSameMomentAs(rangeEnd)) {
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
            price: priceMap[priceKey]?.price,
          );

          current = current.add(const Duration(days: 1));
        }
      }
    }

    // Mark booked dates from iCal events (Booking.com, Airbnb, etc.)
    // Bug #71 Fix: Same optimization as bookings
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

        // Calculate intersection of event range with current month
        final rangeStart = checkIn.isAfter(monthStart) ? checkIn : monthStart;
        final rangeEnd = checkOut.isBefore(monthEnd) ? checkOut : monthEnd;

        // Only iterate if event overlaps with current month
        if (!rangeStart.isAfter(rangeEnd)) {
          DateTime current = rangeStart;
          while (current.isBefore(rangeEnd) ||
              current.isAtSameMomentAs(rangeEnd)) {
            // Mark as booked (from external source)
            final priceKey = '${current.year}-${current.month}-${current.day}';
            calendar[current] = CalendarDateInfo(
              date: current,
              status: DateStatus.booked, // Always fully booked for iCal events
              price: priceMap[priceKey]?.price,
            );

            current = current.add(const Duration(days: 1));
          }
        }

        LoggingService.log(
          '📅 iCal Event blocked (month view): ${event['source']} from $checkIn to $checkOut',
          tag: 'iCAL_SYNC',
        );
      }
    }

    // Apply gap blocking based on minimum nights requirement
    _applyMinNightsGapBlocking(calendar, bookings, priceMap, minNights);

    return calendar;
  }

  /// Build calendar map for entire year
  Map<DateTime, CalendarDateInfo> _buildYearCalendarMap(
    List<BookingModel> bookings,
    Map<String, DailyPriceModel> priceMap,
    int year,
    int minNights, [
    List<Map<String, dynamic>>? icalEvents,
  ]) {
    final Map<DateTime, CalendarDateInfo> calendar = {};

    // Initialize all days in year as available with prices
    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        final priceKey = '${date.year}-${date.month}-${date.day}';
        final priceModel = priceMap[priceKey];

        calendar[date] = CalendarDateInfo(
          date: date,
          status: DateStatus.available,
          price: priceModel?.price,
        );
      }
    }

    // Mark booked dates from regular bookings
    // Bug #71 Fix: Optimize for long-term bookings by calculating date range intersection
    final yearStart = DateTime(year);
    final yearEnd = DateTime(year, 12, 31);

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

      // Calculate intersection of booking range with current year
      final rangeStart = checkIn.isAfter(yearStart) ? checkIn : yearStart;
      final rangeEnd = checkOut.isBefore(yearEnd) ? checkOut : yearEnd;

      // Only iterate if booking overlaps with current year
      if (!rangeStart.isAfter(rangeEnd)) {
        DateTime current = rangeStart;
        while (current.isBefore(rangeEnd) ||
            current.isAtSameMomentAs(rangeEnd)) {
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
            price: priceMap[priceKey]?.price,
          );

          current = current.add(const Duration(days: 1));
        }
      }
    }

    // Mark booked dates from iCal events (Booking.com, Airbnb, etc.)
    // Bug #71 Fix: Same optimization as bookings
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

        // Calculate intersection of event range with current year
        final rangeStart = checkIn.isAfter(yearStart) ? checkIn : yearStart;
        final rangeEnd = checkOut.isBefore(yearEnd) ? checkOut : yearEnd;

        // Only iterate if event overlaps with current year
        if (!rangeStart.isAfter(rangeEnd)) {
          DateTime current = rangeStart;
          while (current.isBefore(rangeEnd) ||
              current.isAtSameMomentAs(rangeEnd)) {
            // Mark as booked (from external source)
            final priceKey = '${current.year}-${current.month}-${current.day}';
            calendar[current] = CalendarDateInfo(
              date: current,
              status: DateStatus.booked, // Always fully booked for iCal events
              price: priceMap[priceKey]?.price,
            );

            current = current.add(const Duration(days: 1));
          }
        }

        LoggingService.log(
          '📅 iCal Event blocked: ${event['source']} from $checkIn to $checkOut',
          tag: 'iCAL_SYNC',
        );
      }
    }

    // Apply gap blocking based on minimum nights requirement
    _applyMinNightsGapBlocking(calendar, bookings, priceMap, minNights);

    return calendar;
  }

  /// Apply gap blocking based on minimum nights requirement
  /// If gap between two bookings is less than minNights, block that gap
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

      final checkOutCurrent = DateTime(
        currentBooking.checkOut.year,
        currentBooking.checkOut.month,
        currentBooking.checkOut.day,
      );
      final checkInNext = DateTime(
        nextBooking.checkIn.year,
        nextBooking.checkIn.month,
        nextBooking.checkIn.day,
      );

      // Calculate gap in days (from checkout day to checkin day of next booking)
      final gapStart = checkOutCurrent;
      final gapEnd = checkInNext;
      final gapDays = gapEnd.difference(gapStart).inDays;

      // Get minNights from first day of gap (or use default)
      final priceKey = '${gapStart.year}-${gapStart.month}-${gapStart.day}';
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

  /// Check if date range is available for booking
  /// Checks both regular bookings AND iCal events (Booking.com, Airbnb, etc.)
  Future<bool> checkAvailability({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      // Fetch all active bookings for this unit
      // Note: Using client-side filtering to avoid Firestore limitation of
      // whereIn + inequality filters requiring composite index
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('unit_id', isEqualTo: unitId)
          .where('status', whereIn: ['pending', 'confirmed', 'in_progress'])
          .get();

      // Check for overlap in memory (client-side)
      for (final doc in bookingsSnapshot.docs) {
        try {
          final booking = BookingModel.fromJson({...doc.data(), 'id': doc.id});

          // Normalize booking dates to midnight (remove time component)
          // to match turnover day logic: checkOut day can be checkIn for next booking
          final bookingCheckIn = DateTime(
            booking.checkIn.year,
            booking.checkIn.month,
            booking.checkIn.day,
          );
          final bookingCheckOut = DateTime(
            booking.checkOut.year,
            booking.checkOut.month,
            booking.checkOut.day,
          );

          // Overlap logic with turnover day support:
          // Conflict exists if: (bookingCheckOut > checkIn) AND (bookingCheckIn < checkOut)
          // Using > (not >=) allows same-day turnover (checkOut = checkIn is OK)
          if (bookingCheckOut.isAfter(checkIn) &&
              bookingCheckIn.isBefore(checkOut)) {
            LoggingService.log(
              '❌ Booking conflict found: ${booking.id}',
              tag: 'AVAILABILITY_CHECK',
            );
            return false; // Conflict with regular booking
          }
        } catch (e) {
          unawaited(
            LoggingService.logError('Error checking booking availability', e),
          );
        }
      }

      // Check iCal events (Booking.com, Airbnb, etc.)
      // Note: Using client-side filtering to avoid Firestore index requirement for inequality filter
      final icalEventsSnapshot = await _firestore
          .collection('ical_events')
          .where('unit_id', isEqualTo: unitId)
          .get();

      for (final doc in icalEventsSnapshot.docs) {
        try {
          final data = doc.data();
          final eventStartDateRaw = (data['start_date'] as Timestamp).toDate();
          final eventEndDateRaw = (data['end_date'] as Timestamp).toDate();

          // Normalize iCal event dates to midnight (remove time component)
          // to match turnover day logic: checkOut day can be checkIn for next booking
          final eventStartDate = DateTime(
            eventStartDateRaw.year,
            eventStartDateRaw.month,
            eventStartDateRaw.day,
          );
          final eventEndDate = DateTime(
            eventEndDateRaw.year,
            eventEndDateRaw.month,
            eventEndDateRaw.day,
          );

          // Client-side filtering: Check if events overlap with the date range
          // Overlap logic with turnover day support:
          // Using > (not >=) allows same-day turnover (checkOut = checkIn is OK)
          if (eventEndDate.isAfter(checkIn) &&
              eventStartDate.isBefore(checkOut)) {
            LoggingService.log(
              '❌ iCal conflict found: ${data['source']} event from $eventStartDate to $eventEndDate',
              tag: 'AVAILABILITY_CHECK',
            );
            return false; // Conflict with iCal event
          }
        } catch (e) {
          unawaited(
            LoggingService.logError(
              'Error checking iCal event availability',
              e,
            ),
          );
        }
      }

      // Check blocked dates from daily_prices (available: false)
      final blockedDatesSnapshot = await _firestore
          .collection('daily_prices')
          .where('unit_id', isEqualTo: unitId)
          .where('available', isEqualTo: false)
          .get();

      for (final doc in blockedDatesSnapshot.docs) {
        try {
          final data = doc.data();
          final blockedDateRaw = (data['date'] as Timestamp).toDate();

          // Normalize blocked date to midnight
          final blockedDate = DateTime(
            blockedDateRaw.year,
            blockedDateRaw.month,
            blockedDateRaw.day,
          );

          // Check if blocked date falls within the requested range
          // Blocked date is a conflict if: blockedDate >= checkIn AND blockedDate < checkOut
          // (checkOut day is not counted as a night stay)
          if ((blockedDate.isAfter(checkIn) ||
                  blockedDate.isAtSameMomentAs(checkIn)) &&
              blockedDate.isBefore(checkOut)) {
            LoggingService.log(
              '❌ Blocked date conflict found: $blockedDate',
              tag: 'AVAILABILITY_CHECK',
            );
            return false; // Conflict with blocked date
          }
        } catch (e) {
          unawaited(
            LoggingService.logError('Error checking blocked date availability', e),
          );
        }
      }

      LoggingService.log(
        '✅ No conflicts found for $checkIn to $checkOut',
        tag: 'AVAILABILITY_CHECK',
      );

      return true; // No conflicts with bookings, iCal events, or blocked dates
    } catch (e) {
      unawaited(LoggingService.logError('Error checking availability', e));
      return false;
    }
  }

  /// Calculate total price for date range
  /// Uses price hierarchy: custom daily_price > weekendBasePrice (from unit) > basePrice
  /// [basePrice] - Unit's base price per night (required for fallback when no daily_price)
  /// [weekendBasePrice] - Unit's weekend base price (optional, for Sat-Sun by default)
  /// [weekendDays] - optional custom weekend days (1=Mon...7=Sun). Default: [6,7]
  Future<double> calculateBookingPrice({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required double basePrice,
    double? weekendBasePrice,
    List<int>? weekendDays,
  }) async {
    try {
      // Bug #73 Fix: Check availability BEFORE calculating price
      // This prevents race condition where price is shown for dates being booked by another user
      final isAvailable = await checkAvailability(
        unitId: unitId,
        checkIn: checkIn,
        checkOut: checkOut,
      );

      if (!isAvailable) {
        LoggingService.log(
          '⚠️ Price calculation skipped - dates not available',
          tag: 'PRICE_CALCULATION',
        );
        throw const DatesNotAvailableException();
      }

      final pricesSnapshot = await _firestore
          .collection('daily_prices')
          .where('unit_id', isEqualTo: unitId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(checkIn))
          .where('date', isLessThan: Timestamp.fromDate(checkOut))
          .get();

      // Build a map of date -> DailyPriceModel for quick lookup
      final Map<String, DailyPriceModel> priceMap = {};
      for (final doc in pricesSnapshot.docs) {
        final data = doc.data();
        if (data['date'] == null) continue;

        try {
          final price = DailyPriceModel.fromJson({...data, 'id': doc.id});
          final key = '${price.date.year}-${price.date.month}-${price.date.day}';
          priceMap[key] = price;
        } catch (e) {
          unawaited(LoggingService.logError('Error parsing price', e));
        }
      }

      // Calculate total for each day in the range with fallback
      final effectiveWeekendDays = weekendDays ?? [6, 7]; // Default: Sat=6, Sun=7
      double total = 0.0;
      DateTime current = checkIn;

      while (current.isBefore(checkOut)) {
        final key = '${current.year}-${current.month}-${current.day}';
        final dailyPrice = priceMap[key];

        if (dailyPrice != null) {
          // Use daily_price with its getEffectivePrice logic
          total += dailyPrice.getEffectivePrice(weekendDays: weekendDays);
        } else {
          // No daily_price → use fallback from unit
          final isWeekend = effectiveWeekendDays.contains(current.weekday);
          if (isWeekend && weekendBasePrice != null) {
            total += weekendBasePrice;
          } else {
            total += basePrice;
          }
        }

        current = current.add(const Duration(days: 1));
      }

      return total;
    } catch (e) {
      unawaited(LoggingService.logError('Error calculating booking price', e));
      return 0.0;
    }
  }
}
