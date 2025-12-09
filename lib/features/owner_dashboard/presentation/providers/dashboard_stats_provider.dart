import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/providers/repository_providers.dart';
import 'owner_bookings_provider.dart';
import 'owner_calendar_provider.dart';

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
/// OPTIMIZED: Uses dedicated queries instead of recentOwnerBookings
/// - Queries only this year's bookings for revenue calculations
/// - Separate optimized query for upcoming check-ins
/// - Reduces Firestore reads from O(all_bookings) to O(year_bookings + 7_day_checkins)
@riverpod
Future<DashboardStats> dashboardStats(Ref ref) async {
  final repository = ref.watch(ownerBookingsRepositoryProvider);
  // OPTIMIZED: Use cached keepAlive provider instead of stream
  final properties = await ref.watch(ownerPropertiesCalendarProvider.future);

  // Get cached unit IDs (reuses existing provider)
  final unitIds = await ref.watch(ownerUnitIdsProvider.future);

  if (unitIds.isEmpty) {
    return DashboardStats(
      monthlyRevenue: 0.0,
      yearlyRevenue: 0.0,
      monthlyBookings: 0,
      upcomingCheckIns: 0,
      activeProperties: properties.where((p) => p.isActive).length,
      occupancyRate: 0.0,
    );
  }

  // Fetch dashboard-specific data with optimized queries
  final statsData = await repository.getDashboardStatsData(unitIds: unitIds);

  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month);

  // Calculate monthly revenue (confirmed/completed bookings created this month)
  double monthlyRevenue = 0.0;
  int monthlyBookingsCount = 0;

  // Calculate yearly revenue (already filtered to current year by query)
  double yearlyRevenue = 0.0;

  for (final booking in statsData.confirmedBookings) {
    // Yearly revenue - all confirmed/completed bookings from query (already filtered to this year)
    yearlyRevenue += booking.totalPrice;

    // Monthly revenue and bookings - check if booking was created this month
    if (booking.createdAt.isAfter(currentMonth) &&
        booking.createdAt.month == now.month &&
        booking.createdAt.year == now.year) {
      monthlyRevenue += booking.totalPrice;
      monthlyBookingsCount++;
    }
  }

  // Upcoming check-ins (already filtered by query to next 7 days)
  final upcomingCheckIns = statsData.upcomingCheckIns.length;

  // Count active properties
  final activeProperties = properties.where((p) => p.isActive).length;

  // Calculate occupancy rate using confirmed bookings
  double occupancyRate = 0.0;
  if (properties.isNotEmpty) {
    // Calculate total nights this month
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final totalAvailableNights = properties.length * daysInMonth;

    // Calculate booked nights this month
    int bookedNights = 0;
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    for (final booking in statsData.confirmedBookings) {
      // Check if booking overlaps with current month
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
