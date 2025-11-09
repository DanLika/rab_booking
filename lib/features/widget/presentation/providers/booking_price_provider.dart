import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'realtime_booking_calendar_provider.dart';

part 'booking_price_provider.g.dart';

/// Model for booking price calculation
class BookingPriceCalculation {
  final double totalPrice;
  final double depositAmount; // 20% avans
  final double remainingAmount; // 80% preostalo
  final int nights;

  BookingPriceCalculation({
    required this.totalPrice,
    required this.depositAmount,
    required this.remainingAmount,
    required this.nights,
  });

  String get formattedTotal => '€${totalPrice.toStringAsFixed(2)}';
  String get formattedDeposit => '€${depositAmount.toStringAsFixed(2)}';
  String get formattedRemaining => '€${remainingAmount.toStringAsFixed(2)}';
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
  final depositAmount = (depositPercentage == 0 || depositPercentage == 100)
      ? totalPrice
      : totalPrice * (depositPercentage / 100);
  final remainingAmount = (depositPercentage == 0 || depositPercentage == 100)
      ? 0.0
      : totalPrice * ((100 - depositPercentage) / 100);

  return BookingPriceCalculation(
    totalPrice: totalPrice,
    depositAmount: depositAmount,
    remainingAmount: remainingAmount,
    nights: nights,
  );
}
