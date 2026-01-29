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
  final double
  extraGuestFees; // Extra guest fees (extraGuests * extraBedFee * nights)
  final double petFees; // Pet fees (petCount * petFee * nights)
  final double additionalServicesTotal; // Total from additional services
  final double depositAmount; // 20% avans (of total)
  final double remainingAmount; // 80% preostalo (of total)
  final int nights;
  final DateTime? priceLockTimestamp; // Bug #64: When price was locked
  final double?
  lockedTotalPrice; // Bug #64: Original locked price for comparison

  BookingPriceCalculation({
    required this.roomPrice,
    this.extraGuestFees = 0.0,
    this.petFees = 0.0,
    this.additionalServicesTotal = 0.0,
    required this.depositAmount,
    required this.remainingAmount,
    required this.nights,
    this.priceLockTimestamp,
    this.lockedTotalPrice,
  });

  // Total price = room price + extra guest fees + pet fees + additional services
  double get totalPrice =>
      roomPrice + extraGuestFees + petFees + additionalServicesTotal;

  /// Format price with currency symbol
  /// Multi-currency support: use currencySymbol from WidgetTranslations
  String formatRoomPrice(String currency) =>
      '$currency${roomPrice.toStringAsFixed(2)}';
  String formatExtraGuestFees(String currency) =>
      '$currency${extraGuestFees.toStringAsFixed(2)}';
  String formatPetFees(String currency) =>
      '$currency${petFees.toStringAsFixed(2)}';
  String formatAdditionalServices(String currency) =>
      '$currency${additionalServicesTotal.toStringAsFixed(2)}';
  String formatTotal(String currency) =>
      '$currency${totalPrice.toStringAsFixed(2)}';
  String formatDeposit(String currency) =>
      '$currency${depositAmount.toStringAsFixed(2)}';
  String formatRemaining(String currency) =>
      '$currency${remainingAmount.toStringAsFixed(2)}';

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
      extraGuestFees: extraGuestFees,
      petFees: petFees,
      additionalServicesTotal: additionalServicesTotal,
      depositAmount: depositAmount,
      remainingAmount: remainingAmount,
      nights: nights,
      priceLockTimestamp: DateTime.now(),
      lockedTotalPrice: totalPrice,
    );
  }

  // Copy with method for updating extra guest & pet fees (sync, no async re-fetch)
  BookingPriceCalculation copyWithFees(
    double newExtraGuestFees,
    double newPetFees,
    int depositPercentage,
  ) {
    final newTotal =
        roomPrice + newExtraGuestFees + newPetFees + additionalServicesTotal;
    final newDeposit = (depositPercentage == 0 || depositPercentage == 100)
        ? newTotal
        : (newTotal * depositPercentage).roundToDouble() / 100;
    final newRemaining = (depositPercentage == 0 || depositPercentage == 100)
        ? 0.0
        : (newTotal * (100 - depositPercentage)).roundToDouble() / 100;

    return BookingPriceCalculation(
      roomPrice: roomPrice,
      extraGuestFees: newExtraGuestFees,
      petFees: newPetFees,
      additionalServicesTotal: additionalServicesTotal,
      depositAmount: newDeposit,
      remainingAmount: newRemaining,
      nights: nights,
      priceLockTimestamp: priceLockTimestamp,
      lockedTotalPrice: lockedTotalPrice,
    );
  }

  // Copy with method for updating additional services
  BookingPriceCalculation copyWithServices(
    double servicesTotal,
    int depositPercentage,
  ) {
    final newTotal = roomPrice + extraGuestFees + petFees + servicesTotal;
    // Bug Fix: Use integer multiplication for precise rounding instead of toStringAsFixed
    final newDeposit = (depositPercentage == 0 || depositPercentage == 100)
        ? newTotal
        : (newTotal * depositPercentage).roundToDouble() / 100;
    final newRemaining = (depositPercentage == 0 || depositPercentage == 100)
        ? 0.0
        : (newTotal * (100 - depositPercentage)).roundToDouble() / 100;

    return BookingPriceCalculation(
      roomPrice: roomPrice,
      extraGuestFees: extraGuestFees,
      petFees: petFees,
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
///
/// PRICE MISMATCH FIX: When [forceServerFetch] is true, bypasses all caches
/// and fetches fresh unit data directly from Firestore server. Use this
/// before booking submission to prevent stale price errors.
@riverpod
Future<BookingPriceCalculation?> bookingPrice(
  Ref ref, {
  required String unitId,
  required DateTime? checkIn,
  required DateTime? checkOut,
  String?
  propertyId, // Optional: enables cache reuse from widgetContextProvider
  int depositPercentage = 20, // Configurable deposit percentage (0-100)
  bool forceServerFetch =
      false, // PRICE FIX: Force fresh server fetch for booking submission
  // Extra guest & pet fee parameters
  int guestCount = 1, // Total guests (adults + children)
  int petCount = 0, // Number of pets
  int? maxGuests, // Base capacity (fees apply above this)
  double? extraBedFee, // Per extra person per night
  double? petFee, // Per pet per night
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

  // Mutable fee params: use fresh values from server when forceServerFetch is true,
  // otherwise fall back to caller-provided values (from cached _unit object).
  int? effectiveMaxGuests = maxGuests;
  double? effectiveExtraBedFee = extraBedFee;
  double? effectivePetFee = petFee;

  // PRICE MISMATCH FIX: Force fresh fetch from server before booking submission
  // This prevents 50% price mismatch errors caused by stale cached unit data
  if (forceServerFetch && propertyId != null) {
    final unitRepo = ref.watch(unitRepositoryProvider);
    final unit = await unitRepo.fetchUnitByIdFresh(
      unitId: unitId,
      propertyId: propertyId,
    );
    if (unit != null) {
      basePrice = unit.pricePerNight;
      weekendBasePrice = unit.weekendBasePrice;
      weekendDays = unit.weekendDays;
      // Also refresh fee params to prevent stale extra guest/pet fee calculations
      effectiveMaxGuests = unit.maxGuests;
      effectiveExtraBedFee = unit.extraBedFee;
      effectivePetFee = unit.petFee;

      LoggingService.log(
        '🔄 [PRICE_FIX] Fresh price fetch for booking: '
        'basePrice=$basePrice, weekendPrice=$weekendBasePrice, '
        'maxGuests=$effectiveMaxGuests, extraBedFee=$effectiveExtraBedFee, '
        'petFee=$effectivePetFee',
        tag: 'BOOKING_PRICE',
      );
    } else {
      LoggingService.logWarning(
        '[PRICE_FIX] Fresh fetch failed for unit $unitId, using fallback',
      );
    }
  } else if (propertyId != null) {
    // Try to get unit from cached context (no additional query)
    try {
      final context = await ref.read(
        widgetContextProvider((propertyId: propertyId, unitId: unitId)).future,
      );
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

  // Calculate extra guest fees: extraGuests * extraBedFee * nights
  // Extra guests = guests beyond base capacity (maxGuests)
  // Uses effectiveMaxGuests/effectiveExtraBedFee which are fresh when forceServerFetch=true
  double extraGuestFees = 0.0;
  if (effectiveMaxGuests != null &&
      effectiveExtraBedFee != null &&
      guestCount > effectiveMaxGuests) {
    final extraGuests = guestCount - effectiveMaxGuests;
    extraGuestFees = extraGuests * effectiveExtraBedFee * nights;
  }

  // Calculate pet fees: petCount * petFee * nights
  // Uses effectivePetFee which is fresh when forceServerFetch=true
  double petFeesTotal = 0.0;
  if (effectivePetFee != null && petCount > 0) {
    petFeesTotal = petCount * effectivePetFee * nights;
  }

  // Calculate deposit and remaining amount based on configurable percentage
  // Total includes room price + extra guest fees + pet fees
  // Note: Additional services total will be 0 initially, can be updated with copyWithServices()
  // If depositPercentage is 0 or 100, treat as full payment (no split)
  // Bug Fix: Use integer multiplication for precise rounding instead of toStringAsFixed
  // This avoids floating point representation errors (e.g., 0.1 + 0.2 != 0.3)
  final baseTotal = roomPrice + extraGuestFees + petFeesTotal;
  final depositAmount = (depositPercentage == 0 || depositPercentage == 100)
      ? baseTotal
      : (baseTotal * depositPercentage).roundToDouble() / 100;
  final remainingAmount = (depositPercentage == 0 || depositPercentage == 100)
      ? 0.0
      : (baseTotal * (100 - depositPercentage)).roundToDouble() / 100;

  return BookingPriceCalculation(
    roomPrice: roomPrice,
    extraGuestFees: extraGuestFees,
    petFees: petFeesTotal,
    depositAmount: depositAmount,
    remainingAmount: remainingAmount,
    nights: nights,
  );
}
