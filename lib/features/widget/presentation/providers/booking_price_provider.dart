import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'realtime_booking_calendar_provider.dart';

part 'booking_price_provider.g.dart';

/// Model for booking price calculation with price locking support
class BookingPriceCalculation {
  final double totalPrice;
  final double depositAmount; // 20% avans
  final double remainingAmount; // 80% preostalo
  final int nights;
  final DateTime? priceLockTimestamp; // Bug #64: When price was locked
  final double? lockedTotalPrice; // Bug #64: Original locked price for comparison

  BookingPriceCalculation({
    required this.totalPrice,
    required this.depositAmount,
    required this.remainingAmount,
    required this.nights,
    this.priceLockTimestamp,
    this.lockedTotalPrice,
  });

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
      totalPrice: totalPrice,
      depositAmount: depositAmount,
      remainingAmount: remainingAmount,
      nights: nights,
      priceLockTimestamp: DateTime.now(),
      lockedTotalPrice: totalPrice,
    );
  }
}

/// Provider for calculating booking price
@riverpod
Future<BookingPriceCalculation?> bookingPrice(
  Ref ref, {
  required String unitId,
  required DateTime? checkIn,
  required DateTime? checkOut,
  int depositPercentage = 20, // Configurable deposit percentage (0-100)
}) async {
  // Return null if dates not selected
  if (checkIn == null || checkOut == null) {
    return null;
  }

  final repository = ref.watch(bookingCalendarRepositoryProvider);

  // Calculate total price from daily prices
  final totalPrice = await repository.calculateBookingPrice(
    unitId: unitId,
    checkIn: checkIn,
    checkOut: checkOut,
  );

  // Calculate nights
  final nights = checkOut.difference(checkIn).inDays;

  // Calculate deposit and remaining amount based on configurable percentage
  // If depositPercentage is 0 or 100, treat as full payment (no split)
  // Bug #29: Round to 2 decimal places to prevent rounding errors
  final depositAmount = (depositPercentage == 0 || depositPercentage == 100)
      ? totalPrice
      : double.parse((totalPrice * (depositPercentage / 100)).toStringAsFixed(2));
  final remainingAmount = (depositPercentage == 0 || depositPercentage == 100)
      ? 0.0
      : double.parse((totalPrice * ((100 - depositPercentage) / 100)).toStringAsFixed(2));

  return BookingPriceCalculation(
    totalPrice: totalPrice,
    depositAmount: depositAmount,
    remainingAmount: remainingAmount,
    nights: nights,
  );
}
