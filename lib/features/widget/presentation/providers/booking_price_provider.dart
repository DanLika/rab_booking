import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/providers/repository_providers.dart';
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
  final double?
  lockedTotalPrice; // Bug #64: Original locked price for comparison

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

  String get formattedRoomPrice => '€${roomPrice.toStringAsFixed(2)}';
  String get formattedAdditionalServices =>
      '€${additionalServicesTotal.toStringAsFixed(2)}';
  String get formattedTotal => '€${totalPrice.toStringAsFixed(2)}';
  String get formattedDeposit => '€${depositAmount.toStringAsFixed(2)}';
  String get formattedRemaining => '€${remainingAmount.toStringAsFixed(2)}';

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
  BookingPriceCalculation copyWithServices(
    double servicesTotal,
    int depositPercentage,
  ) {
    final newTotal = roomPrice + servicesTotal;
    final newDeposit = (depositPercentage == 0 || depositPercentage == 100)
        ? newTotal
        : double.parse(
            (newTotal * (depositPercentage / 100)).toStringAsFixed(2),
          );
    final newRemaining = (depositPercentage == 0 || depositPercentage == 100)
        ? 0.0
        : double.parse(
            (newTotal * ((100 - depositPercentage) / 100)).toStringAsFixed(2),
          );

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
  String?
  propertyId, // Optional: enables cache reuse from widgetContextProvider
  int depositPercentage = 20, // Configurable deposit percentage (0-100)
}) async {
  // Return null if dates not selected
  if (checkIn == null || checkOut == null) {
    return null;
  }

  final repository = ref.watch(bookingCalendarRepositoryProvider);

  // OPTIMIZED: Try to get unit from cached widgetContext first
  // Falls back to direct fetch if propertyId not provided or cache miss
  double basePrice = 100.0;
  double? weekendBasePrice;
  List<int>? weekendDays;

  if (propertyId != null) {
    // Try to get unit from cached context (no additional query)
    try {
      final context = await ref.read(
        widgetContextProvider((propertyId: propertyId, unitId: unitId)).future,
      );
      basePrice = context.unit.pricePerNight;
      weekendBasePrice = context.unit.weekendBasePrice;
      weekendDays = context.unit.weekendDays;
    } catch (_) {
      // Fall back to direct fetch if context not available
      final unitRepo = ref.watch(unitRepositoryProvider);
      final unit = await unitRepo.fetchUnitById(unitId);
      basePrice = unit?.pricePerNight ?? 100.0;
      weekendBasePrice = unit?.weekendBasePrice;
      weekendDays = unit?.weekendDays;
    }
  } else {
    // No propertyId provided - must fetch directly
    final unitRepo = ref.watch(unitRepositoryProvider);
    final unit = await unitRepo.fetchUnitById(unitId);
    basePrice = unit?.pricePerNight ?? 100.0;
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

  // Calculate nights
  final nights = checkOut.difference(checkIn).inDays;

  // Calculate deposit and remaining amount based on configurable percentage
  // Note: Additional services total will be 0 initially, can be updated with copyWithServices()
  // If depositPercentage is 0 or 100, treat as full payment (no split)
  // Bug #29: Round to 2 decimal places to prevent rounding errors
  final depositAmount = (depositPercentage == 0 || depositPercentage == 100)
      ? roomPrice
      : double.parse(
          (roomPrice * (depositPercentage / 100)).toStringAsFixed(2),
        );
  final remainingAmount = (depositPercentage == 0 || depositPercentage == 100)
      ? 0.0
      : double.parse(
          (roomPrice * ((100 - depositPercentage) / 100)).toStringAsFixed(2),
        );

  return BookingPriceCalculation(
    roomPrice: roomPrice,
    depositAmount: depositAmount,
    remainingAmount: remainingAmount,
    nights: nights,
  );
}
