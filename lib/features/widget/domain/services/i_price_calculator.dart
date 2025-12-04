import '../../data/helpers/booking_price_calculator.dart';

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
  /// Throws [DatesNotAvailableException] if dates are not available
  /// and [checkAvailability] is true.
  ///
  /// Returns [PriceCalculationResult] with total price and breakdown.
  Future<PriceCalculationResult> calculate({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required double basePrice,
    double? weekendBasePrice,
    List<int>? weekendDays,
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
    List<int>? weekendDays,
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
    List<int>? weekendDays,
  });
}
