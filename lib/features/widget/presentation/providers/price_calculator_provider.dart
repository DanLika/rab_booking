import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../domain/models/booking_price_breakdown.dart';

/// Provider for calculating booking price
final bookingPriceProvider = FutureProvider.family<BookingPriceBreakdown?, (String, DateTime?, DateTime?)>(
  (ref, params) async {
    final (unitId, checkIn, checkOut) = params;

    // If dates are not selected, return null
    if (checkIn == null || checkOut == null) {
      return null;
    }

    // Validate dates
    if (checkOut.isBefore(checkIn) || checkOut.isAtSameMomentAs(checkIn)) {
      return null;
    }

    final dailyPriceRepo = ref.watch(dailyPriceRepositoryProvider);
    final unitRepo = ref.watch(unitRepositoryProvider);

    // Get unit for fallback price
    final unit = await unitRepo.fetchUnitById(unitId);
    final fallbackPrice = unit?.pricePerNight ?? 100.0;

    // Calculate total price
    final totalPrice = await dailyPriceRepo.calculateBookingPrice(
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
      fallbackPrice: fallbackPrice,
    );

    // Get detailed prices for each night
    final dailyPrices = await dailyPriceRepo.getPricesForDateRange(
      unitId: unitId,
      startDate: checkIn,
      endDate: checkOut.subtract(const Duration(days: 1)), // Exclude check-out day
    );

    // Performance Optimization: Convert list to a map for O(1) lookups.
    // This avoids iterating through the list for every night of the booking.
    final dailyPriceMap = {
      for (var p in dailyPrices)
        if (p != null) DateTime(p.date.year, p.date.month, p.date.day): p.price
    };

    // Build nightly prices list with fallback to base price
    final List<NightlyPrice> nightlyPrices = [];
    DateTime current = checkIn;
    while (current.isBefore(checkOut)) {
      // Optimized lookup
      final currentDate = DateTime(current.year, current.month, current.day);
      final priceForNight = dailyPriceMap[currentDate] ?? fallbackPrice;

      nightlyPrices.add(NightlyPrice(
        date: current,
        price: priceForNight,
      ));

      current = current.add(const Duration(days: 1));
    }

    final numberOfNights = checkOut.difference(checkIn).inDays;

    return BookingPriceBreakdown(
      subtotal: totalPrice,
      nightlyPrices: nightlyPrices,
      numberOfNights: numberOfNights,
      checkIn: checkIn,
      checkOut: checkOut,
    );
  },
);
