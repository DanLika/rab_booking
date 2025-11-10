import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/constants/enums.dart';
import 'owner_bookings_provider.dart';
import 'owner_properties_provider.dart';

part 'dashboard_stats_provider.g.dart';

/// Dashboard statistics model
class DashboardStats {
  final double monthlyRevenue;
  final double yearlyRevenue;
  final int monthlyBookings;
  final int upcomingCheckIns;
  final int activeProperties;
  final double occupancyRate;

  const DashboardStats({
    required this.monthlyRevenue,
    required this.yearlyRevenue,
    required this.monthlyBookings,
    required this.upcomingCheckIns,
    required this.activeProperties,
    required this.occupancyRate,
  });
}

/// Dashboard statistics provider
@riverpod
Future<DashboardStats> dashboardStats(Ref ref) async {
  final bookings = await ref.watch(ownerBookingsProvider.future);
  final properties = await ref.watch(ownerPropertiesProvider.future);

  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month);
  final currentYear = DateTime(now.year);
  final next7Days = now.add(const Duration(days: 7));

  // Calculate monthly revenue (completed/confirmed bookings this month)
  double monthlyRevenue = 0.0;
  int monthlyBookingsCount = 0;

  // Calculate yearly revenue
  double yearlyRevenue = 0.0;

  // Count upcoming check-ins (next 7 days)
  int upcomingCheckIns = 0;

  for (final ownerBooking in bookings) {
    final booking = ownerBooking.booking;

    // Monthly revenue and bookings - check if booking was created this month and is confirmed/completed
    if (booking.createdAt.isAfter(currentMonth) &&
        booking.createdAt.month == now.month &&
        booking.createdAt.year == now.year &&
        (booking.status == BookingStatus.confirmed ||
            booking.status == BookingStatus.completed ||
            booking.status == BookingStatus.inProgress ||
            booking.status == BookingStatus.checkedIn ||
            booking.status == BookingStatus.checkedOut)) {
      monthlyRevenue += booking.totalPrice;
      monthlyBookingsCount++;
    }

    // Yearly revenue - bookings created this year and confirmed/completed
    if (booking.createdAt.isAfter(currentYear) &&
        booking.createdAt.year == now.year &&
        (booking.status == BookingStatus.confirmed ||
            booking.status == BookingStatus.completed ||
            booking.status == BookingStatus.inProgress ||
            booking.status == BookingStatus.checkedIn ||
            booking.status == BookingStatus.checkedOut)) {
      yearlyRevenue += booking.totalPrice;
    }

    // Upcoming check-ins (next 7 days)
    if (booking.checkIn.isAfter(now) &&
        booking.checkIn.isBefore(next7Days) &&
        (booking.status == BookingStatus.confirmed ||
            booking.status == BookingStatus.pending)) {
      upcomingCheckIns++;
    }
  }

  // Count active properties
  final activeProperties = properties.where((p) => p.isActive).length;

  // Calculate occupancy rate
  double occupancyRate = 0.0;
  if (properties.isNotEmpty) {
    // Calculate total nights this month
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final totalAvailableNights = properties.length * daysInMonth;

    // Calculate booked nights this month
    int bookedNights = 0;
    for (final ownerBooking in bookings) {
      final booking = ownerBooking.booking;

      // Only count confirmed/in-progress bookings
      if (booking.status == BookingStatus.confirmed ||
          booking.status == BookingStatus.inProgress ||
          booking.status == BookingStatus.checkedIn ||
          booking.status == BookingStatus.completed) {
        // Check if booking overlaps with current month
        final monthStart = DateTime(now.year, now.month);
        final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

        if (booking.checkOut.isAfter(monthStart) &&
            booking.checkIn.isBefore(monthEnd)) {
          // Calculate overlap
          final overlapStart = booking.checkIn.isAfter(monthStart)
              ? booking.checkIn
              : monthStart;
          final overlapEnd = booking.checkOut.isBefore(monthEnd)
              ? booking.checkOut
              : monthEnd;

          final nights = overlapEnd.difference(overlapStart).inDays;
          if (nights > 0) {
            bookedNights += nights;
          }
        }
      }
    }

    if (totalAvailableNights > 0) {
      occupancyRate = (bookedNights / totalAvailableNights) * 100;
      // Cap at 100%
      if (occupancyRate > 100) occupancyRate = 100;
    }
  }

  return DashboardStats(
    monthlyRevenue: monthlyRevenue,
    yearlyRevenue: yearlyRevenue,
    monthlyBookings: monthlyBookingsCount,
    upcomingCheckIns: upcomingCheckIns,
    activeProperties: activeProperties,
    occupancyRate: occupancyRate,
  );
}
