import 'package:intl/intl.dart';

import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../../../shared/repositories/booking_repository.dart';
import '../../../../shared/repositories/daily_price_repository.dart';
import '../../../../core/constants/enums.dart';
import '../../../owner_dashboard/data/firebase/firebase_ical_repository.dart';
import '../../../owner_dashboard/domain/models/ical_feed.dart';
import '../models/calendar_date_status.dart';
import '../constants/calendar_constants.dart';
import '../constants/widget_constants.dart';

/// Parameters for loading calendar data
class CalendarDataParams {
  final String unitId;
  final DateTime startDate;
  final DateTime endDate;
  final int minNights;
  final double basePrice;
  final double? weekendBasePrice;
  final List<int>? weekendDays;

  const CalendarDataParams({
    required this.unitId,
    required this.startDate,
    required this.endDate,
    required this.minNights,
    required this.basePrice,
    this.weekendBasePrice,
    this.weekendDays,
  });
}

/// Service for loading and processing calendar data
///
/// Centralizes calendar logic previously duplicated in year_calendar_provider
/// and month_calendar_provider. Uses repository pattern for data access.
///
/// Multi-tenant safe: All queries filter by unit_id which belongs to a specific owner.
class CalendarDataService {
  final BookingRepository _bookingRepository;
  final DailyPriceRepository _dailyPriceRepository;
  final FirebaseIcalRepository _icalRepository;

  CalendarDataService({
    required BookingRepository bookingRepository,
    required DailyPriceRepository dailyPriceRepository,
    required FirebaseIcalRepository icalRepository,
  }) : _bookingRepository = bookingRepository,
       _dailyPriceRepository = dailyPriceRepository,
       _icalRepository = icalRepository;

  /// Load calendar data for a date range
  ///
  /// Returns a map of date keys (yyyy-MM-dd) to CalendarDateInfo
  /// Includes: bookings, iCal events, daily prices, gap blocking
  Future<Map<String, CalendarDateInfo>> loadCalendarData(CalendarDataParams params) async {
    final effectiveWeekendDays = params.weekendDays ?? WidgetConstants.defaultWeekendDays;

    // Calculate extended range for gap detection
    // Handle month/year overflow explicitly to avoid invalid DateTime values
    final startMonth = params.startDate.month - CalendarConstants.monthsBeforeForGapDetection;
    final startYear = params.startDate.year;
    final adjustedStartMonth = startMonth <= 0 ? 12 + startMonth : startMonth;
    final adjustedStartYear = startMonth <= 0 ? startYear - 1 : startYear;

    final extendedStart = DateTime.utc(adjustedStartYear, adjustedStartMonth);

    final endMonth = params.endDate.month + CalendarConstants.monthsAfterForGapDetection + 1;
    final endYear = params.endDate.year;
    final adjustedEndMonth = endMonth > 12 ? endMonth - 12 : endMonth;
    final adjustedEndYear = endMonth > 12 ? endYear + 1 : endYear;

    final extendedEnd = DateTime.utc(adjustedEndYear, adjustedEndMonth, 0);

    // Load data in parallel for performance
    final results = await Future.wait([
      _loadBookings(params.unitId, extendedStart, extendedEnd),
      _loadIcalEvents(params.unitId, extendedStart, extendedEnd),
      _loadDailyPrices(params.unitId, params.startDate, params.endDate),
    ]);

    final bookings = results[0] as List<BookingModel>;
    final icalEvents = results[1] as List<IcalEvent>;
    final dailyPrices = results[2] as List<DailyPriceModel>;

    // Build price map for quick lookup
    final priceMap = _buildPriceMap(dailyPrices);

    // Get today for past date detection
    final today = DateTime.now().toUtc();
    final todayNormalized = DateTime.utc(today.year, today.month, today.day);

    // Initialize calendar data
    final calendarData = <String, CalendarDateInfo>{};

    // Initialize all dates in range
    _initializeDateRange(
      calendarData: calendarData,
      startDate: params.startDate,
      endDate: params.endDate,
      todayNormalized: todayNormalized,
      priceMap: priceMap,
      basePrice: params.basePrice,
      weekendBasePrice: params.weekendBasePrice,
      weekendDays: effectiveWeekendDays,
    );

    // Mark booked dates from internal bookings
    _markBookedDates(calendarData: calendarData, bookings: bookings, todayNormalized: todayNormalized);

    // Mark booked dates from iCal events (Booking.com, Airbnb)
    _markIcalEventDates(calendarData: calendarData, icalEvents: icalEvents, todayNormalized: todayNormalized);

    // Block small gaps that are less than minNights
    _blockSmallGaps(
      calendarData: calendarData,
      bookings: bookings,
      icalEvents: icalEvents,
      minNights: params.minNights,
    );

    return calendarData;
  }

  // ============================================
  // Price Calculation (SHARED LOGIC)
  // ============================================

  /// Calculate effective price for a date
  ///
  /// Priority: custom daily_price > weekendBasePrice (if weekend) > basePrice
  double getEffectivePrice({
    required DateTime date,
    required double basePrice,
    double? customDailyPrice,
    double? weekendBasePrice,
    List<int>? weekendDays,
  }) {
    // 1. Custom daily price has highest priority
    if (customDailyPrice != null) {
      return customDailyPrice;
    }

    // 2. Weekend price (if it's a weekend and weekendBasePrice is set)
    final effectiveWeekendDays = weekendDays ?? WidgetConstants.defaultWeekendDays;
    if (weekendBasePrice != null && effectiveWeekendDays.contains(date.weekday)) {
      return weekendBasePrice;
    }

    // 3. Base price as fallback
    return basePrice;
  }

  // ============================================
  // Date Helpers (SHARED LOGIC)
  // ============================================

  /// Format date as yyyy-MM-dd key for map lookup
  ///
  /// Normalizes date to UTC before formatting to ensure consistent keys
  /// regardless of timezone. This prevents timezone offset issues when
  /// formatting dates that may have time components.
  String getDateKey(DateTime date) {
    // Normalize to UTC by extracting year/month/day components
    // This ensures we format the correct day regardless of timezone
    final utcDate = DateTime.utc(date.year, date.month, date.day);
    return DateFormat('yyyy-MM-dd').format(utcDate);
  }

  /// Check if two dates are the same day
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ============================================
  // Private Helper Methods
  // ============================================

  /// Load bookings from repository, filtering out cancelled
  Future<List<BookingModel>> _loadBookings(String unitId, DateTime start, DateTime end) async {
    final allBookings = await _bookingRepository.getBookingsInRange(unitId: unitId, startDate: start, endDate: end);

    // Filter out bookings that should NOT block dates
    // Uses BookingStatus.blocksCalendarDates helper:
    // - cancelled: Does NOT block
    // - pending/confirmed/completed: BLOCKS dates
    return allBookings.where((booking) => booking.status.blocksCalendarDates).toList();
  }

  /// Load iCal events from repository
  Future<List<IcalEvent>> _loadIcalEvents(String unitId, DateTime start, DateTime end) async {
    // Using repository instead of direct Firestore access
    final events = await _icalRepository.getUnitIcalEventsInRange(unitId: unitId, startDate: start, endDate: end);

    return events;
  }

  /// Load daily prices from repository
  Future<List<DailyPriceModel>> _loadDailyPrices(String unitId, DateTime start, DateTime end) async {
    return await _dailyPriceRepository.getPricesForDateRange(unitId: unitId, startDate: start, endDate: end);
  }

  /// Build a map of date keys to DailyPriceModel for quick lookup
  Map<String, DailyPriceModel> _buildPriceMap(List<DailyPriceModel> prices) {
    final priceMap = <String, DailyPriceModel>{};
    for (final price in prices) {
      final key = getDateKey(price.date);
      priceMap[key] = price;
    }
    return priceMap;
  }

  /// Initialize all dates in range with default status
  void _initializeDateRange({
    required Map<String, CalendarDateInfo> calendarData,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime todayNormalized,
    required Map<String, DailyPriceModel> priceMap,
    required double basePrice,
    double? weekendBasePrice,
    required List<int> weekendDays,
  }) {
    DateTime current = DateTime.utc(startDate.year, startDate.month);
    final lastDay = DateTime.utc(endDate.year, endDate.month + 1, 0);

    while (!current.isAfter(lastDay)) {
      final key = getDateKey(current);
      final isPast = current.isBefore(todayNormalized);
      final priceData = priceMap[key];

      // Determine initial status
      DateStatus initialStatus;
      if (isPast) {
        initialStatus = DateStatus.disabled;
      } else if (priceData?.available == false) {
        initialStatus = DateStatus.blocked;
      } else {
        initialStatus = DateStatus.available;
      }

      // Calculate effective price
      final effectivePrice = getEffectivePrice(
        date: current,
        basePrice: basePrice,
        customDailyPrice: priceData?.price,
        weekendBasePrice: weekendBasePrice,
        weekendDays: weekendDays,
      );

      calendarData[key] = CalendarDateInfo(
        date: current,
        status: initialStatus,
        price: effectivePrice,
        blockCheckIn: priceData?.blockCheckIn ?? false,
        blockCheckOut: priceData?.blockCheckOut ?? false,
        minDaysAdvance: priceData?.minDaysAdvance,
        maxDaysAdvance: priceData?.maxDaysAdvance,
        minNightsOnArrival: priceData?.minNightsOnArrival,
        maxNightsOnArrival: priceData?.maxNightsOnArrival,
      );

      current = current.add(const Duration(days: 1));
    }
  }

  /// Mark dates as booked from internal bookings
  void _markBookedDates({
    required Map<String, CalendarDateInfo> calendarData,
    required List<BookingModel> bookings,
    required DateTime todayNormalized,
  }) {
    for (final booking in bookings) {
      final checkIn = DateTime.utc(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
      final checkOut = DateTime.utc(booking.checkOut.year, booking.checkOut.month, booking.checkOut.day);

      // Check if booking is pending (awaiting owner approval)
      final isPending = booking.status == BookingStatus.pending;

      DateTime current = checkIn;
      // NOTE: Checkout day is included in the loop (isSameDay) for visual display.
      // This shows checkout day with partialCheckOut status in the calendar.
      // However, checkout day does NOT block new check-ins (turnover day is supported),
      // and is NOT included in price calculation or night count.
      // Availability checking is handled separately by AvailabilityChecker which uses
      // end1.isAfter(start2) && start1.isBefore(end2) to allow same-day turnover.
      while (current.isBefore(checkOut) || isSameDay(current, checkOut)) {
        final key = getDateKey(current);
        if (calendarData.containsKey(key)) {
          final isPast = current.isBefore(todayNormalized);
          final isCheckIn = isSameDay(current, checkIn);
          final isCheckOut = isSameDay(current, checkOut);
          final existingInfo = calendarData[key]!;

          final status = _calculateBookingStatus(
            isPast: isPast,
            isPending: false, // Use normal status, isPendingBooking flag handles the pattern
            isCheckIn: isCheckIn,
            isCheckOut: isCheckOut,
            existingStatus: existingInfo.status,
          );

          // Track pending status for each half of partialBoth (turnover day)
          bool newIsCheckOutPending = existingInfo.isCheckOutPending;
          bool newIsCheckInPending = existingInfo.isCheckInPending;

          if (status == DateStatus.partialBoth) {
            // Turnover day: one reservation checks out, another checks in
            if (existingInfo.status == DateStatus.partialCheckOut) {
              // Existing checkout, current booking is checking IN
              // Keep existing isCheckOutPending, set isCheckInPending from current booking
              newIsCheckInPending = isPending;
            } else if (existingInfo.status == DateStatus.partialCheckIn) {
              // Existing checkin, current booking is checking OUT
              // Keep existing isCheckInPending, set isCheckOutPending from current booking
              newIsCheckOutPending = isPending;
            }
          } else if (status == DateStatus.partialCheckIn) {
            // This booking's checkin day
            newIsCheckInPending = isPending;
          } else if (status == DateStatus.partialCheckOut) {
            // This booking's checkout day
            newIsCheckOutPending = isPending;
          }

          calendarData[key] = existingInfo.copyWith(
            status: status,
            isPendingBooking: isPending, // Set flag for pending pattern overlay (full days)
            isCheckOutPending: newIsCheckOutPending,
            isCheckInPending: newIsCheckInPending,
          );
        }
        current = current.add(const Duration(days: 1));
      }
    }
  }

  /// Mark dates as booked from iCal events
  void _markIcalEventDates({
    required Map<String, CalendarDateInfo> calendarData,
    required List<IcalEvent> icalEvents,
    required DateTime todayNormalized,
  }) {
    for (final event in icalEvents) {
      final checkIn = DateTime.utc(event.startDate.year, event.startDate.month, event.startDate.day);
      final checkOut = DateTime.utc(event.endDate.year, event.endDate.month, event.endDate.day);

      DateTime current = checkIn;
      // NOTE: Checkout day is included in the loop (isSameDay) for visual display.
      // This shows checkout day with partialCheckOut status in the calendar.
      // However, checkout day does NOT block new check-ins (turnover day is supported).
      // Availability checking is handled separately by AvailabilityChecker.
      while (current.isBefore(checkOut) || isSameDay(current, checkOut)) {
        final key = getDateKey(current);
        if (calendarData.containsKey(key)) {
          final isPast = current.isBefore(todayNormalized);
          final isCheckIn = isSameDay(current, checkIn);
          final isCheckOut = isSameDay(current, checkOut);
          final existingInfo = calendarData[key]!;

          final status = _calculateBookingStatus(
            isPast: isPast,
            isPending: false,
            isCheckIn: isCheckIn,
            isCheckOut: isCheckOut,
            existingStatus: existingInfo.status,
          );

          calendarData[key] = existingInfo.copyWith(status: status);
        }
        current = current.add(const Duration(days: 1));
      }
    }
  }

  /// Calculate booking status for a date
  DateStatus _calculateBookingStatus({
    required bool isPast,
    required bool isPending,
    required bool isCheckIn,
    required bool isCheckOut,
    required DateStatus existingStatus,
  }) {
    if (isPast) {
      return DateStatus.pastReservation;
    }

    // Pending bookings show as RED with diagonal pattern (blocks dates)
    if (isPending) {
      return DateStatus.pending;
    }

    if (isCheckIn && isCheckOut) {
      // Single day booking
      return DateStatus.booked;
    }

    if (isCheckIn) {
      // Check for turnover day (check-out + check-in same day)
      if (existingStatus == DateStatus.partialCheckOut) {
        return DateStatus.partialBoth;
      }
      return DateStatus.partialCheckIn;
    }

    if (isCheckOut) {
      // Check for turnover day
      if (existingStatus == DateStatus.partialCheckIn) {
        return DateStatus.partialBoth;
      }
      return DateStatus.partialCheckOut;
    }

    // Full day booked
    return DateStatus.booked;
  }

  /// Block small gaps between bookings that are less than minNights
  void _blockSmallGaps({
    required Map<String, CalendarDateInfo> calendarData,
    required List<BookingModel> bookings,
    required List<IcalEvent> icalEvents,
    required int minNights,
  }) {
    // Combine all reservations (bookings + iCal events)
    final allReservations = <_ReservationPeriod>[];

    for (final booking in bookings) {
      allReservations.add(
        _ReservationPeriod(
          checkIn: DateTime.utc(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day),
          checkOut: DateTime.utc(booking.checkOut.year, booking.checkOut.month, booking.checkOut.day),
        ),
      );
    }

    for (final event in icalEvents) {
      allReservations.add(
        _ReservationPeriod(
          checkIn: DateTime.utc(event.startDate.year, event.startDate.month, event.startDate.day),
          checkOut: DateTime.utc(event.endDate.year, event.endDate.month, event.endDate.day),
        ),
      );
    }

    // Sort by checkout date
    allReservations.sort((a, b) => a.checkOut.compareTo(b.checkOut));

    // Find and block small gaps
    for (int i = 0; i < allReservations.length - 1; i++) {
      final current = allReservations[i];
      final next = allReservations[i + 1];

      // Calculate gap boundaries
      final gapStart = current.checkOut.add(const Duration(days: 1));
      final gapEnd = next.checkIn.subtract(const Duration(days: 1));

      // Check if there's actually a gap (no overlap or adjacency)
      // If reservations overlap or are adjacent (checkout == checkin), gapEnd will be before gapStart
      if (gapEnd.isBefore(gapStart)) {
        // Reservations overlap or are adjacent - no gap to block
        continue;
      }

      // Calculate gap size
      final gapNights = gapEnd.difference(gapStart).inDays;

      // Block if gap is positive but less than minNights
      if (gapNights > 0 && gapNights < minNights) {
        DateTime gapDate = gapStart;
        while (gapDate.isBefore(next.checkIn)) {
          final key = getDateKey(gapDate);
          if (calendarData.containsKey(key)) {
            final existingInfo = calendarData[key]!;
            // Only block if currently available
            if (existingInfo.status == DateStatus.available) {
              calendarData[key] = existingInfo.copyWith(status: DateStatus.blocked);
            }
          }
          gapDate = gapDate.add(const Duration(days: 1));
        }
      }
    }
  }
}

/// Internal helper class for reservation periods
class _ReservationPeriod {
  final DateTime checkIn;
  final DateTime checkOut;

  const _ReservationPeriod({required this.checkIn, required this.checkOut});
}
