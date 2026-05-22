import '../../data/helpers/booking_price_calculator.dart';
import '../repositories/i_booking_calendar_repository.dart' show WeekendDays;

/// Abstract price calculator interface.
/// Separates pricing logic from Firebase implementation.
///
/// Implementations calculate booking prices using price hierarchy:
/// 1. Custom daily_price (highest priority) - from daily_prices collection
/// 2. Weekend base price - for weekend days
/// 3. Base price - fallback for all other days
///
/// This abstraction enables:
/// - Unit testing without Firebase
/// - Swapping backend implementations
/// - Dependency Inversion Principle
abstract class IPriceCalculator {
  /// Calculate total price for a booking with availability check.
  ///
  /// [propertyId] is required when [checkAvailability] is true (the embedded
  /// availability check calls `getUnitAvailability` CF which needs the
  /// parent property). Pass `null` only when [checkAvailability] is false.
  ///
  /// Throws [DatesNotAvailableException] if dates are not available
  /// and [checkAvailability] is true.
  ///
  /// Throws [PriceCalculationException] if calculation fails due to
  /// network errors, Firestore errors, or other unexpected issues.
  ///
  /// Returns [PriceCalculationResult] with total price and breakdown.
  Future<PriceCalculationResult> calculate({
    String? propertyId,
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required double basePrice,
    double? weekendBasePrice,
    WeekendDays? weekendDays,
    bool checkAvailability = true,
  });

  /// Calculate price without availability check.
  ///
  /// Useful for preview calculations or when availability is already known.
  Future<PriceCalculationResult> calculateWithoutAvailabilityCheck({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required double basePrice,
    double? weekendBasePrice,
    WeekendDays? weekendDays,
  });

  /// Get effective price for a single date.
  ///
  /// Useful for displaying price in calendar UI.
  /// Uses price hierarchy: daily_price > weekend base > base price.
  Future<double> getEffectivePriceForDate({
    required String unitId,
    required DateTime date,
    required double basePrice,
    double? weekendBasePrice,
    WeekendDays? weekendDays,
  });
}
