import '../models/calendar_date_status.dart';

/// Days of the week for weekend pricing (1 = Monday, 7 = Sunday).
///
/// Example: `[5, 6]` for Friday and Saturday weekend pricing.
typedef WeekendDays = List<int>;

/// Abstract repository for booking calendar operations.
///
/// Implementations can use Firebase, Supabase, REST API, or mock data.
///
/// This abstraction enables:
/// - Unit testing without Firebase emulator
/// - Swapping backend implementations
/// - Following Dependency Inversion Principle
///
/// See also:
/// - [FirebaseBookingCalendarRepository] for the production implementation
/// - [DatesNotAvailableException] thrown when dates conflict
abstract class IBookingCalendarRepository {
  /// Watch year calendar data with realtime updates
  ///
  /// Returns a stream of calendar data for the entire year,
  /// mapping each date to its booking information.
  Stream<Map<DateTime, CalendarDateInfo>> watchYearCalendarData({
    required String propertyId,
    required String unitId,
    required int year,
  });

  /// Watch month calendar data with realtime updates
  ///
  /// Returns a stream of calendar data for a specific month,
  /// mapping each date to its booking information.
  Stream<Map<DateTime, CalendarDateInfo>> watchCalendarData({
    required String propertyId,
    required String unitId,
    required int year,
    required int month,
  });

  /// Check if date range is available for booking
  ///
  /// Returns true if all dates in the range are available,
  /// false if any date is blocked or already booked.
  Future<bool> checkAvailability({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  });

  /// Calculate total price for date range.
  ///
  /// Uses price hierarchy:
  /// 1. Custom daily price (highest priority)
  /// 2. Weekend base price - for days in [weekendDays]
  /// 3. Base price - fallback for all other days
  ///
  /// Throws [DatesNotAvailableException] if dates are not available.
  Future<double> calculateBookingPrice({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required double basePrice,
    double? weekendBasePrice,
    WeekendDays? weekendDays,
  });
}
