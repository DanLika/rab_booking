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
  })  : _bookingRepository = bookingRepository,
        _dailyPriceRepository = dailyPriceRepository,
        _icalRepository = icalRepository;

  /// Load calendar data for a date range
  ///
  /// Returns a map of date keys (yyyy-MM-dd) to CalendarDateInfo
  /// Includes: bookings, iCal events, daily prices, gap blocking
  Future<Map<String, CalendarDateInfo>> loadCalendarData(
    CalendarDataParams params,
  ) async {
    final effectiveWeekendDays =
        params.weekendDays ?? CalendarConstants.defaultWeekendDays;

    // Calculate extended range for gap detection
    final extendedStart = DateTime.utc(
      params.startDate.year,
      params.startDate.month - CalendarConstants.monthsBeforeForGapDetection,
    );
    final extendedEnd = DateTime.utc(
      params.endDate.year,
      params.endDate.month + CalendarConstants.monthsAfterForGapDetection + 1,
      0,
    );

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
    _markBookedDates(
      calendarData: calendarData,
      bookings: bookings,
      todayNormalized: todayNormalized,
    );

    // Mark booked dates from iCal events (Booking.com, Airbnb)
    _markIcalEventDates(
      calendarData: calendarData,
      icalEvents: icalEvents,
      todayNormalized: todayNormalized,
    );

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
    final effectiveWeekendDays =
        weekendDays ?? CalendarConstants.defaultWeekendDays;
    if (weekendBasePrice != null &&
        effectiveWeekendDays.contains(date.weekday)) {
      return weekendBasePrice;
    }

    // 3. Base price as fallback
    return basePrice;
  }

  // ============================================
  // Date Helpers (SHARED LOGIC)
  // ============================================

  /// Format date as yyyy-MM-dd key for map lookup
  String getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Check if two dates are the same day
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ============================================
  // Private Helper Methods
  // ============================================

  /// Load bookings from repository, filtering out cancelled
  Future<List<BookingModel>> _loadBookings(
    String unitId,
    DateTime start,
    DateTime end,
  ) async {
    final allBookings = await _bookingRepository.getBookingsInRange(
      unitId: unitId,
      startDate: start,
      endDate: end,
    );

    // Filter out cancelled bookings - they should NOT block dates
    return allBookings
        .where((booking) => booking.status != BookingStatus.cancelled)
        .toList();
  }

  /// Load iCal events from repository
  Future<List<IcalEvent>> _loadIcalEvents(
    String unitId,
    DateTime start,
    DateTime end,
  ) async {
    // Using repository instead of direct Firestore access
    final events = await _icalRepository.getUnitIcalEventsInRange(
      unitId: unitId,
      startDate: start,
      endDate: end,
    );

    return events;
  }

  /// Load daily prices from repository
  Future<List<DailyPriceModel>> _loadDailyPrices(
    String unitId,
    DateTime start,
    DateTime end,
  ) async {
    return await _dailyPriceRepository.getPricesForDateRange(
      unitId: unitId,
      startDate: start,
      endDate: end,
    );
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
    DateTime current = DateTime.utc(startDate.year, startDate.month, 1);
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
      while (current.isBefore(checkOut) || isSameDay(current, checkOut)) {
        final key = getDateKey(current);
        if (calendarData.containsKey(key)) {
          final isPast = current.isBefore(todayNormalized);
          final isCheckIn = isSameDay(current, checkIn);
          final isCheckOut = isSameDay(current, checkOut);
          final existingInfo = calendarData[key]!;

          final status = _calculateBookingStatus(
            isPast: isPast,
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

  /// Mark dates as booked from iCal events
  void _markIcalEventDates({
    required Map<String, CalendarDateInfo> calendarData,
    required List<IcalEvent> icalEvents,
    required DateTime todayNormalized,
  }) {
    for (final event in icalEvents) {
      final checkIn = DateTime.utc(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      final checkOut = DateTime.utc(
        event.endDate.year,
        event.endDate.month,
        event.endDate.day,
      );

      DateTime current = checkIn;
      while (current.isBefore(checkOut) || isSameDay(current, checkOut)) {
        final key = getDateKey(current);
        if (calendarData.containsKey(key)) {
          final isPast = current.isBefore(todayNormalized);
          final isCheckIn = isSameDay(current, checkIn);
          final isCheckOut = isSameDay(current, checkOut);
          final existingInfo = calendarData[key]!;

          final status = _calculateBookingStatus(
            isPast: isPast,
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
    required bool isCheckIn,
    required bool isCheckOut,
    required DateStatus existingStatus,
  }) {
    if (isPast) {
      return DateStatus.pastReservation;
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
      allReservations.add(_ReservationPeriod(
        checkIn: DateTime.utc(
          booking.checkIn.year,
          booking.checkIn.month,
          booking.checkIn.day,
        ),
        checkOut: DateTime.utc(
          booking.checkOut.year,
          booking.checkOut.month,
          booking.checkOut.day,
        ),
      ));
    }

    for (final event in icalEvents) {
      allReservations.add(_ReservationPeriod(
        checkIn: DateTime.utc(
          event.startDate.year,
          event.startDate.month,
          event.startDate.day,
        ),
        checkOut: DateTime.utc(
          event.endDate.year,
          event.endDate.month,
          event.endDate.day,
        ),
      ));
    }

    // Sort by checkout date
    allReservations.sort((a, b) => a.checkOut.compareTo(b.checkOut));

    // Find and block small gaps
    for (int i = 0; i < allReservations.length - 1; i++) {
      final current = allReservations[i];
      final next = allReservations[i + 1];

      // Calculate gap size
      final gapStart = current.checkOut.add(const Duration(days: 1));
      final gapEnd = next.checkIn.subtract(const Duration(days: 1));
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
              calendarData[key] = existingInfo.copyWith(
                status: DateStatus.blocked,
              );
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

  const _ReservationPeriod({
    required this.checkIn,
    required this.checkOut,
  });
}
