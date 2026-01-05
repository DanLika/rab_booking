import '../../data/helpers/availability_checker.dart';

/// Abstract availability checker interface.
/// Separates availability logic from Firebase implementation.
///
/// Implementations check for booking conflicts across multiple sources:
/// - Regular bookings (pending, confirmed, in_progress)
/// - iCal events (Booking.com, Airbnb, etc.)
/// - Blocked dates (daily_prices with available: false)
///
/// This abstraction enables:
/// - Unit testing without Firebase
/// - Swapping backend implementations
/// - Dependency Inversion Principle
abstract class IAvailabilityChecker {
  /// Check if date range is available for booking.
  ///
  /// Returns [AvailabilityCheckResult] with detailed conflict information.
  /// This is the main method that provides full conflict details.
  Future<AvailabilityCheckResult> check({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  });

  /// Simple boolean check for backward compatibility.
  ///
  /// Returns true if available, false if any conflict exists.
  /// Internally calls [check] and returns [AvailabilityCheckResult.isAvailable].
  Future<bool> isAvailable({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  });
}
