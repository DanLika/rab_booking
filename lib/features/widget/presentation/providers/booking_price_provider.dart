import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../shared/providers/widget_repository_providers.dart';
import '../../utils/date_normalizer.dart';
import 'realtime_booking_calendar_provider.dart';
import 'widget_context_provider.dart';

part 'booking_price_provider.g.dart';

/// Model for booking price calculation with price locking support
class BookingPriceCalculation {
  final double roomPrice; // Base room price (formerly totalPrice)
  final double additionalServicesTotal; // Total from additional services
  final double depositAmount; // 20% avans (of total)
  final double remainingAmount; // 80% preostalo (of total)
  final int nights;
  final DateTime? priceLockTimestamp; // Bug #64: When price was locked
  final double? lockedTotalPrice; // Bug #64: Original locked price for comparison

  BookingPriceCalculation({
    required this.roomPrice,
    this.additionalServicesTotal = 0.0,
    required this.depositAmount,
    required this.remainingAmount,
    required this.nights,
    this.priceLockTimestamp,
    this.lockedTotalPrice,
  });

  // Total price = room price + additional services
  double get totalPrice => roomPrice + additionalServicesTotal;

  /// Format price with currency symbol
  /// Multi-currency support: use currencySymbol from WidgetTranslations
  String formatRoomPrice(String currency) => '$currency${roomPrice.toStringAsFixed(2)}';
  String formatAdditionalServices(String currency) => '$currency${additionalServicesTotal.toStringAsFixed(2)}';
  String formatTotal(String currency) => '$currency${totalPrice.toStringAsFixed(2)}';
  String formatDeposit(String currency) => '$currency${depositAmount.toStringAsFixed(2)}';
  String formatRemaining(String currency) => '$currency${remainingAmount.toStringAsFixed(2)}';

  // Bug #64: Check if price has changed since lock
  bool get hasPriceChanged {
    if (lockedTotalPrice == null) return false;
    return (totalPrice - lockedTotalPrice!).abs() > 0.01; // 1 cent tolerance
  }

  double get priceChangeDelta {
    if (lockedTotalPrice == null) return 0.0;
    return totalPrice - lockedTotalPrice!;
  }

  // Copy with method for price locking
  BookingPriceCalculation copyWithLock() {
    return BookingPriceCalculation(
      roomPrice: roomPrice,
      additionalServicesTotal: additionalServicesTotal,
      depositAmount: depositAmount,
      remainingAmount: remainingAmount,
      nights: nights,
      priceLockTimestamp: DateTime.now(),
      lockedTotalPrice: totalPrice,
    );
  }

  // Copy with method for updating additional services
  BookingPriceCalculation copyWithServices(double servicesTotal, int depositPercentage) {
    final newTotal = roomPrice + servicesTotal;
    // Bug Fix: Use integer multiplication for precise rounding instead of toStringAsFixed
    final newDeposit = (depositPercentage == 0 || depositPercentage == 100)
        ? newTotal
        : (newTotal * depositPercentage).roundToDouble() / 100;
    final newRemaining = (depositPercentage == 0 || depositPercentage == 100)
        ? 0.0
        : (newTotal * (100 - depositPercentage)).roundToDouble() / 100;

    return BookingPriceCalculation(
      roomPrice: roomPrice,
      additionalServicesTotal: servicesTotal,
      depositAmount: newDeposit,
      remainingAmount: newRemaining,
      nights: nights,
      priceLockTimestamp: priceLockTimestamp,
      lockedTotalPrice: lockedTotalPrice,
    );
  }
}

/// Provider for calculating booking price
///
/// OPTIMIZED: Now accepts optional [propertyId] to reuse cached unit data
/// from [widgetContextProvider], eliminating duplicate Firestore queries.
@riverpod
Future<BookingPriceCalculation?> bookingPrice(
  Ref ref, {
  required String unitId,
  required DateTime? checkIn,
  required DateTime? checkOut,
  String? propertyId, // Optional: enables cache reuse from widgetContextProvider
  int depositPercentage = 20, // Configurable deposit percentage (0-100)
}) async {
  // Return null if dates not selected
  if (checkIn == null || checkOut == null) {
    return null;
  }

  final repository = ref.watch(bookingCalendarRepositoryProvider);

  // OPTIMIZED: Try to get unit from cached widgetContext first
  // Falls back to direct fetch if propertyId not provided or cache miss
  const fallbackBasePrice = 100.0;
  double basePrice = fallbackBasePrice;
  double? weekendBasePrice;
  List<int>? weekendDays;

  if (propertyId != null) {
    // Try to get unit from cached context (no additional query)
    try {
      final context = await ref.read(widgetContextProvider((propertyId: propertyId, unitId: unitId)).future);
      // Defensive null checks: properties are required but handle edge cases
      final unit = context.unit;
      basePrice = unit.pricePerNight;
      weekendBasePrice = unit.weekendBasePrice;
      weekendDays = unit.weekendDays;
    } catch (e) {
      // Fall back to direct fetch if context not available
      final unitRepo = ref.watch(unitRepositoryProvider);
      final unit = await unitRepo.fetchUnitById(unitId);
      if (unit?.pricePerNight != null) {
        basePrice = unit!.pricePerNight;
      } else {
        LoggingService.logWarning(
          'BookingPrice: Unit $unitId has no pricePerNight, using fallback $fallbackBasePrice. Error: $e',
        );
      }
      weekendBasePrice = unit?.weekendBasePrice;
      weekendDays = unit?.weekendDays;
    }
  } else {
    // No propertyId provided - must fetch directly
    final unitRepo = ref.watch(unitRepositoryProvider);
    final unit = await unitRepo.fetchUnitById(unitId);
    if (unit?.pricePerNight != null) {
      basePrice = unit!.pricePerNight;
    } else {
      LoggingService.logWarning(
        'BookingPrice: Unit $unitId not found or has no pricePerNight, using fallback $fallbackBasePrice',
      );
    }
    weekendBasePrice = unit?.weekendBasePrice;
    weekendDays = unit?.weekendDays;
  }

  // Calculate room price from daily prices with weekend pricing support
  final roomPrice = await repository.calculateBookingPrice(
    unitId: unitId,
    checkIn: checkIn,
    checkOut: checkOut,
    basePrice: basePrice,
    weekendBasePrice: weekendBasePrice,
    weekendDays: weekendDays,
  );

  // Bug Fix: Use DateNormalizer for consistent night calculation across timezones
  final nights = DateNormalizer.nightsBetween(checkIn, checkOut);

  // Calculate deposit and remaining amount based on configurable percentage
  // Note: Additional services total will be 0 initially, can be updated with copyWithServices()
  // If depositPercentage is 0 or 100, treat as full payment (no split)
  // Bug Fix: Use integer multiplication for precise rounding instead of toStringAsFixed
  // This avoids floating point representation errors (e.g., 0.1 + 0.2 != 0.3)
  final depositAmount = (depositPercentage == 0 || depositPercentage == 100)
      ? roomPrice
      : (roomPrice * depositPercentage).roundToDouble() / 100;
  final remainingAmount = (depositPercentage == 0 || depositPercentage == 100)
      ? 0.0
      : (roomPrice * (100 - depositPercentage)).roundToDouble() / 100;

  return BookingPriceCalculation(
    roomPrice: roomPrice,
    depositAmount: depositAmount,
    remainingAmount: remainingAmount,
    nights: nights,
  );
}
