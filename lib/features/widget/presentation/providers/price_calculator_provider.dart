import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/widget_repository_providers.dart';
import '../../domain/models/booking_price_breakdown.dart';
import '../../utils/date_normalizer.dart';

/// Provider for calculating booking price
final bookingPriceProvider =
    FutureProvider.family<
      BookingPriceBreakdown?,
      (String, DateTime?, DateTime?)
    >((ref, params) async {
      final (unitId, checkIn, checkOut) = params;

      // If dates are not selected, return null
      if (checkIn == null || checkOut == null) {
        return null;
      }

      // Normalize dates for consistent comparison (ignores time components)
      final normalizedCheckIn = DateNormalizer.normalize(checkIn);
      final normalizedCheckOut = DateNormalizer.normalize(checkOut);

      // Validate dates
      if (normalizedCheckOut.isBefore(normalizedCheckIn) ||
          normalizedCheckOut.isAtSameMomentAs(normalizedCheckIn)) {
        return null;
      }

      final dailyPriceRepo = ref.watch(dailyPriceRepositoryProvider);
      final unitRepo = ref.watch(unitRepositoryProvider);

      // Get unit for fallback price and weekend pricing
      final unit = await unitRepo.fetchUnitById(unitId);
      final fallbackPrice = unit?.pricePerNight ?? 100.0;
      final weekendBasePrice = unit?.weekendBasePrice;
      final weekendDays = unit?.weekendDays;

      // Calculate total price with weekend pricing support
      final totalPrice = await dailyPriceRepo.calculateBookingPrice(
        unitId: unitId,
        checkIn: normalizedCheckIn,
        checkOut: normalizedCheckOut,
        fallbackPrice: fallbackPrice,
        weekendBasePrice: weekendBasePrice,
        weekendDays: weekendDays,
      );

      // Get detailed prices for each night
      final dailyPrices = await dailyPriceRepo.getPricesForDateRange(
        unitId: unitId,
        startDate: normalizedCheckIn,
        endDate: normalizedCheckOut.subtract(
          const Duration(days: 1),
        ), // Exclude check-out day
      );

      // Build nightly prices list with fallback using weekend pricing
      final effectiveWeekendDays =
          weekendDays ?? [5, 6]; // Default: Fri=5, Sat=6 (hotel nights)
      final List<NightlyPrice> nightlyPrices = [];
      DateTime current = normalizedCheckIn;
      while (current.isBefore(normalizedCheckOut)) {
        // Try to find daily price, fallback to base/weekend price if not found
        final dailyPriceModel = dailyPrices.cast<dynamic>().firstWhere(
          (p) => p != null && DateNormalizer.isSameDay(p.date, current),
          orElse: () => null,
        );

        double priceForNight;
        if (dailyPriceModel != null) {
          // Use getEffectivePrice if available (handles weekendPrice in daily_price)
          priceForNight = dailyPriceModel.getEffectivePrice(
            weekendDays: weekendDays,
          );
        } else {
          // Fallback: use weekendBasePrice if weekend, otherwise basePrice
          final isWeekend = effectiveWeekendDays.contains(current.weekday);
          priceForNight = (isWeekend && weekendBasePrice != null)
              ? weekendBasePrice
              : fallbackPrice;
        }

        nightlyPrices.add(NightlyPrice(date: current, price: priceForNight));

        current = current.add(const Duration(days: 1));
      }

      final numberOfNights = DateNormalizer.nightsBetween(
        normalizedCheckIn,
        normalizedCheckOut,
      );

      return BookingPriceBreakdown(
        subtotal: totalPrice,
        nightlyPrices: nightlyPrices,
        numberOfNights: numberOfNights,
        checkIn: normalizedCheckIn,
        checkOut: normalizedCheckOut,
      );
    });
