import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/services/logging_service.dart';
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

  /// Number of nights that used weekend pricing (from any source).
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

  static const _dailyPricesCollection = 'daily_prices';

  BookingPriceCalculator({
    required FirebaseFirestore firestore,
    AvailabilityChecker? availabilityChecker,
  }) : _firestore = firestore,
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
      final effectiveWeekendDays =
          weekendDays ?? WidgetConstants.defaultWeekendDays;

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
        weekendDays: effectiveWeekendDays,
      );
    } catch (e) {
      if (e is DatesNotAvailableException) rethrow;
      if (e is PriceCalculationException) rethrow;

      unawaited(LoggingService.logError('Error calculating booking price', e));
      // Bug Fix #3: Throw exception instead of returning zero to expose errors
      // Previously returned PriceCalculationResult.zero() which masked critical issues
      // (Firestore failures, network errors) and made debugging difficult
      throw PriceCalculationException.failed(
        unitId: unitId,
        checkIn: checkIn,
        checkOut: checkOut,
        error: e,
      );
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
  }) => calculate(
    unitId: unitId,
    checkIn: checkIn,
    checkOut: checkOut,
    basePrice: basePrice,
    weekendBasePrice: weekendBasePrice,
    weekendDays: weekendDays,
    checkAvailability: false,
  );

  /// Cache for unit document references (unitId -> DocumentSnapshot)
  final Map<String, DocumentSnapshot> _unitDocumentCache = {};

  /// Find unit document to get propertyId.
  /// Returns null if unit not found.
  ///
  /// NOTE: Cannot use collectionGroup().where(FieldPath.documentId) - Firestore bug
  /// requires full document path for documentId queries on collection groups.
  Future<DocumentSnapshot?> _findUnitDocument(String unitId) async {
    // Check cache first
    if (_unitDocumentCache.containsKey(unitId)) {
      return _unitDocumentCache[unitId];
    }

    try {
      // Query all units and find the one with matching document ID
      // Using simple collectionGroup without filter
      final snapshot = await _firestore.collectionGroup('units').get();

      for (final doc in snapshot.docs) {
        if (doc.id == unitId) {
          _unitDocumentCache[unitId] = doc;
          return doc;
        }
      }

      return null;
    } catch (e) {
      unawaited(LoggingService.logError('Error finding unit document', e));
      return null;
    }
  }

  /// Fetch daily prices from Firestore.
  /// Uses exact subcollection path to ensure data consistency with server.
  Future<Map<String, DailyPriceModel>> _fetchDailyPrices({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    // Find unit to get propertyId for correct subcollection path
    final unitDoc = await _findUnitDocument(unitId);
    if (unitDoc == null) {
      LoggingService.log(
        '⚠️ Unit not found for price fetch: $unitId',
        tag: 'PRICE_CALCULATION',
      );
      return {};
    }

    // Extract propertyId from unit's parent path: properties/{propertyId}/units/{unitId}
    final propertyId = unitDoc.reference.parent.parent!.id;

    // Query exact subcollection path (matches server-side validation)
    final snapshot = await _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId)
        .collection(_dailyPricesCollection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(checkIn))
        .where('date', isLessThan: Timestamp.fromDate(checkOut))
        .get();

    final priceMap = <String, DailyPriceModel>{};

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
      final isWeekend = _isWeekendDay(current, weekendDays);

      final double priceForNight;

      if (dailyPrice != null) {
        // Use daily_price with its getEffectivePrice logic
        priceForNight = dailyPrice.getEffectivePrice(weekendDays: weekendDays);
      } else {
        // No daily_price → use fallback from unit
        usedFallback = true;
        priceForNight = isWeekend && weekendBasePrice != null
            ? weekendBasePrice
            : basePrice;
      }

      // Count weekend nights regardless of price source
      if (isWeekend) weekendNights++;

      total += priceForNight;
      priceBreakdown[key] = priceForNight;
      current = current.add(const Duration(days: 1));
    }

    return PriceCalculationResult(
      totalPrice: total,
      nights: priceBreakdown.length,
      priceBreakdown: priceBreakdown,
      usedFallback: usedFallback,
      weekendNights: weekendNights,
    );
  }

  /// Get effective price for a single date.
  ///
  /// Useful for displaying price in calendar UI.
  ///
  /// **WARNING: DO NOT use this method in loops** (e.g., iterating through
  /// calendar days). Each call performs a Firestore query, which would result
  /// in N queries for N days. Instead, use [calculate] or [_fetchDailyPrices]
  /// to batch-fetch prices for a date range.
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

      // Find unit to get propertyId for correct subcollection path
      final unitDoc = await _findUnitDocument(unitId);
      if (unitDoc == null) {
        // Unit not found, fall back to base price
        if (_isWeekendDay(normalizedDate, effectiveWeekendDays) &&
            weekendBasePrice != null) {
          return weekendBasePrice;
        }
        return basePrice;
      }

      // Extract propertyId from unit's parent path
      final propertyId = unitDoc.reference.parent.parent!.id;

      // Query exact subcollection path (matches server-side validation)
      final snapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .doc(unitId)
          .collection(_dailyPricesCollection)
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
      if (_isWeekendDay(normalizedDate, effectiveWeekendDays) &&
          weekendBasePrice != null) {
        return weekendBasePrice;
      }

      return basePrice;
    } catch (e) {
      unawaited(LoggingService.logError('Error getting effective price', e));
      return basePrice;
    }
  }

  /// Check if a date falls on a weekend day.
  bool _isWeekendDay(DateTime date, List<int> weekendDays) =>
      weekendDays.contains(date.weekday);
}
