import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/logging_service.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../domain/constants/widget_constants.dart';
import '../../domain/services/i_price_calculator.dart';
import '../../utils/date_key_generator.dart';
import '../../utils/date_normalizer.dart';
import 'availability_checker.dart';

/// Result of a price calculation with breakdown details.
class PriceCalculationResult {
  /// Total price for the booking.
  final double totalPrice;

  /// Number of nights in the booking.
  final int nights;

  /// Price per night breakdown (date -> price).
  final Map<String, double> priceBreakdown;

  /// Whether base price fallback was used for any night.
  final bool usedFallback;

  /// Number of nights that used weekend pricing.
  final int weekendNights;

  const PriceCalculationResult({
    required this.totalPrice,
    required this.nights,
    required this.priceBreakdown,
    required this.usedFallback,
    required this.weekendNights,
  });

  /// Average price per night.
  double get averagePrice => nights > 0 ? totalPrice / nights : 0.0;

  /// Factory for zero price (when calculation fails).
  const PriceCalculationResult.zero()
      : totalPrice = 0.0,
        nights = 0,
        priceBreakdown = const {},
        usedFallback = false,
        weekendNights = 0;
}

/// Calculates booking prices using price hierarchy.
///
/// ## Price Hierarchy (Airbnb-style)
/// 1. **Custom daily_price** - Highest priority, from daily_prices collection
/// 2. **Weekend base price** - For weekend days (Sat/Sun by default)
/// 3. **Base price** - Fallback for all other days
///
/// ## Usage
/// ```dart
/// final calculator = BookingPriceCalculator(
///   firestore: firestore,
///   availabilityChecker: checker,
/// );
///
/// final result = await calculator.calculate(
///   unitId: 'unit123',
///   checkIn: DateTime(2024, 1, 15),
///   checkOut: DateTime(2024, 1, 20),
///   basePrice: 100.0,
///   weekendBasePrice: 120.0,
/// );
///
/// print('Total: ${result.totalPrice}');
/// print('Per night: ${result.priceBreakdown}');
/// ```
class BookingPriceCalculator implements IPriceCalculator {
  final FirebaseFirestore _firestore;
  final AvailabilityChecker? _availabilityChecker;

  BookingPriceCalculator({
    required FirebaseFirestore firestore,
    AvailabilityChecker? availabilityChecker,
  })  : _firestore = firestore,
        _availabilityChecker = availabilityChecker;

  /// Calculate total price for a booking with availability check.
  ///
  /// Throws [DatesNotAvailableException] if dates are not available.
  @override
  Future<PriceCalculationResult> calculate({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required double basePrice,
    double? weekendBasePrice,
    List<int>? weekendDays,
    bool checkAvailability = true,
  }) async {
    try {
      final normalizedCheckIn = DateNormalizer.normalize(checkIn);
      final normalizedCheckOut = DateNormalizer.normalize(checkOut);

      // Validate date range
      final nights = DateNormalizer.nightsBetween(
        normalizedCheckIn,
        normalizedCheckOut,
      );
      if (nights <= 0) {
        LoggingService.log(
          '⚠️ Invalid date range for price calculation',
          tag: 'PRICE_CALCULATION',
        );
        return const PriceCalculationResult.zero();
      }

      // Bug #73 Fix: Check availability BEFORE calculating price
      if (checkAvailability && _availabilityChecker != null) {
        final availabilityResult = await _availabilityChecker.check(
          unitId: unitId,
          checkIn: normalizedCheckIn,
          checkOut: normalizedCheckOut,
        );

        if (!availabilityResult.isAvailable) {
          LoggingService.log(
            '⚠️ Price calculation skipped - dates not available',
            tag: 'PRICE_CALCULATION',
          );
          throw DatesNotAvailableException.conflict();
        }
      }

      // Fetch daily prices for the date range
      final priceMap = await _fetchDailyPrices(
        unitId: unitId,
        checkIn: normalizedCheckIn,
        checkOut: normalizedCheckOut,
      );

      // Calculate total using price hierarchy
      return _calculateTotal(
        checkIn: normalizedCheckIn,
        checkOut: normalizedCheckOut,
        priceMap: priceMap,
        basePrice: basePrice,
        weekendBasePrice: weekendBasePrice,
        weekendDays: weekendDays ?? WidgetConstants.defaultWeekendDays,
      );
    } catch (e) {
      if (e is DatesNotAvailableException) rethrow;

      unawaited(LoggingService.logError('Error calculating booking price', e));
      return const PriceCalculationResult.zero();
    }
  }

  /// Calculate price without availability check.
  ///
  /// Useful for preview calculations or when availability is already known.
  @override
  Future<PriceCalculationResult> calculateWithoutAvailabilityCheck({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required double basePrice,
    double? weekendBasePrice,
    List<int>? weekendDays,
  }) {
    return calculate(
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
      basePrice: basePrice,
      weekendBasePrice: weekendBasePrice,
      weekendDays: weekendDays,
      checkAvailability: false,
    );
  }

  /// Fetch daily prices from Firestore.
  Future<Map<String, DailyPriceModel>> _fetchDailyPrices({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    final snapshot = await _firestore
        .collection('daily_prices')
        .where('unit_id', isEqualTo: unitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(checkIn))
        .where('date', isLessThan: Timestamp.fromDate(checkOut))
        .get();

    final Map<String, DailyPriceModel> priceMap = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['date'] == null) continue;

      try {
        final price = DailyPriceModel.fromJson({...data, 'id': doc.id});
        final key = DateKeyGenerator.fromDate(price.date);
        priceMap[key] = price;
      } catch (e) {
        unawaited(LoggingService.logError('Error parsing daily price', e));
      }
    }

    return priceMap;
  }

  /// Calculate total price using price hierarchy.
  PriceCalculationResult _calculateTotal({
    required DateTime checkIn,
    required DateTime checkOut,
    required Map<String, DailyPriceModel> priceMap,
    required double basePrice,
    double? weekendBasePrice,
    required List<int> weekendDays,
  }) {
    double total = 0.0;
    int weekendNights = 0;
    bool usedFallback = false;
    final priceBreakdown = <String, double>{};

    DateTime current = checkIn;

    while (current.isBefore(checkOut)) {
      final key = DateKeyGenerator.fromDate(current);
      final dailyPrice = priceMap[key];
      double priceForNight;

      if (dailyPrice != null) {
        // Use daily_price with its getEffectivePrice logic
        priceForNight = dailyPrice.getEffectivePrice(weekendDays: weekendDays);
      } else {
        // No daily_price → use fallback from unit
        usedFallback = true;
        final isWeekend = weekendDays.contains(current.weekday);

        if (isWeekend && weekendBasePrice != null) {
          priceForNight = weekendBasePrice;
          weekendNights++;
        } else {
          priceForNight = basePrice;
        }
      }

      total += priceForNight;
      priceBreakdown[key] = priceForNight;
      current = current.add(const Duration(days: 1));
    }

    final nights = priceBreakdown.length;

    return PriceCalculationResult(
      totalPrice: total,
      nights: nights,
      priceBreakdown: priceBreakdown,
      usedFallback: usedFallback,
      weekendNights: weekendNights,
    );
  }

  /// Get effective price for a single date.
  ///
  /// Useful for displaying price in calendar UI.
  @override
  Future<double> getEffectivePriceForDate({
    required String unitId,
    required DateTime date,
    required double basePrice,
    double? weekendBasePrice,
    List<int>? weekendDays,
  }) async {
    try {
      final normalizedDate = DateNormalizer.normalize(date);
      final effectiveWeekendDays =
          weekendDays ?? WidgetConstants.defaultWeekendDays;

      // Try to fetch daily price
      final snapshot = await _firestore
          .collection('daily_prices')
          .where('unit_id', isEqualTo: unitId)
          .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final dailyPrice = DailyPriceModel.fromJson({
          ...data,
          'id': snapshot.docs.first.id,
        });
        return dailyPrice.getEffectivePrice(weekendDays: effectiveWeekendDays);
      }

      // Fallback to base/weekend price
      final isWeekend = effectiveWeekendDays.contains(normalizedDate.weekday);
      if (isWeekend && weekendBasePrice != null) {
        return weekendBasePrice;
      }

      return basePrice;
    } catch (e) {
      unawaited(LoggingService.logError('Error getting effective price', e));
      return basePrice;
    }
  }
}
