import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/analytics_summary.dart';

part 'analytics_repository.g.dart';

@riverpod
AnalyticsRepository analyticsRepository(Ref ref) {
  return AnalyticsRepository(Supabase.instance.client);
}

class AnalyticsRepository {
  final SupabaseClient _supabase;

  AnalyticsRepository(this._supabase);

  Future<AnalyticsSummary> getAnalyticsSummary({
    required String ownerId,
    required DateRangeFilter dateRange,
  }) async {
    try {
      // Get all owner's properties
      final propertiesResponse = await _supabase
          .from('properties')
          .select('id')
          .eq('owner_id', ownerId);

      final propertyIds = (propertiesResponse as List)
          .map((p) => p['id'] as String)
          .toList();

      if (propertyIds.isEmpty) {
        return _emptyAnalytics();
      }

      // Get bookings within date range
      final bookingsResponse = await _supabase
          .from('bookings')
          .select('*, property:properties!inner(id, name, base_price)')
          .inFilter('property_id', propertyIds)
          .gte('check_in', dateRange.startDate.toIso8601String())
          .lte('check_in', dateRange.endDate.toIso8601String())
          .neq('status', 'cancelled');

      final bookings = bookingsResponse as List;

      // Calculate metrics
      final totalRevenue = bookings.fold<double>(
        0.0,
        (sum, b) => sum + ((b['total_price'] as num?)?.toDouble() ?? 0.0),
      );

      final totalBookings = bookings.length;

      // Get monthly bookings (last 30 days)
      final monthStart = DateTime.now().subtract(const Duration(days: 30));
      final monthlyBookings = bookings.where((b) {
        final checkIn = DateTime.parse(b['check_in'] as String);
        return checkIn.isAfter(monthStart);
      }).toList();

      final monthlyRevenue = monthlyBookings.fold<double>(
        0.0,
        (sum, b) => sum + ((b['total_price'] as num?)?.toDouble() ?? 0.0),
      );

      // Calculate occupancy rate
      final totalDaysInRange = dateRange.endDate.difference(dateRange.startDate).inDays;
      final bookedDays = bookings.fold<int>(
        0,
        (sum, b) {
          final checkIn = DateTime.parse(b['check_in'] as String);
          final checkOut = DateTime.parse(b['check_out'] as String);
          return sum + checkOut.difference(checkIn).inDays;
        },
      );
      final availableDays = totalDaysInRange * propertyIds.length;
      final occupancyRate = availableDays > 0 ? (bookedDays / availableDays) * 100 : 0.0;

      // Calculate average nightly rate
      final averageNightlyRate = totalBookings > 0
          ? totalRevenue / bookedDays
          : 0.0;

      // Get cancelled bookings for cancellation rate
      final cancelledResponse = await _supabase
          .from('bookings')
          .select('id')
          .inFilter('property_id', propertyIds)
          .gte('check_in', dateRange.startDate.toIso8601String())
          .lte('check_in', dateRange.endDate.toIso8601String())
          .eq('status', 'cancelled');

      final cancelledCount = (cancelledResponse as List).length;
      final totalBookingsIncludingCancelled = totalBookings + cancelledCount;
      final cancellationRate = totalBookingsIncludingCancelled > 0
          ? (cancelledCount / totalBookingsIncludingCancelled) * 100
          : 0.0;

      // Get revenue history (group by month)
      final revenueHistory = _generateRevenueHistory(bookings, dateRange);

      // Get booking history (group by month)
      final bookingHistory = _generateBookingHistory(bookings, dateRange);

      // Get property performance
      final propertyPerformance = await _getPropertyPerformance(
        propertyIds,
        dateRange,
      );

      // Get total and active properties count
      final activePropertiesResponse = await _supabase
          .from('properties')
          .select('id')
          .eq('owner_id', ownerId)
          .eq('is_active', true);

      final activeProperties = (activePropertiesResponse as List).length;

      return AnalyticsSummary(
        totalRevenue: totalRevenue,
        monthlyRevenue: monthlyRevenue,
        totalBookings: totalBookings,
        monthlyBookings: monthlyBookings.length,
        occupancyRate: occupancyRate,
        averageNightlyRate: averageNightlyRate,
        totalProperties: propertyIds.length,
        activeProperties: activeProperties,
        cancellationRate: cancellationRate,
        revenueHistory: revenueHistory,
        bookingHistory: bookingHistory,
        topPerformingProperties: propertyPerformance,
      );
    } catch (e) {
      throw Exception('Failed to fetch analytics: $e');
    }
  }

  List<RevenueDataPoint> _generateRevenueHistory(
    List<dynamic> bookings,
    DateRangeFilter dateRange,
  ) {
    final Map<String, double> monthlyRevenue = {};

    for (final booking in bookings) {
      final checkIn = DateTime.parse(booking['check_in'] as String);
      final monthKey = '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}';
      final revenue = (booking['total_price'] as num?)?.toDouble() ?? 0.0;

      monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0.0) + revenue;
    }

    final dataPoints = monthlyRevenue.entries.map((entry) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month, 1);

      return RevenueDataPoint(
        date: date,
        amount: entry.value,
        label: _getMonthLabel(month),
      );
    }).toList();

    dataPoints.sort((a, b) => a.date.compareTo(b.date));

    return dataPoints;
  }

  List<BookingDataPoint> _generateBookingHistory(
    List<dynamic> bookings,
    DateRangeFilter dateRange,
  ) {
    final Map<String, int> monthlyBookings = {};

    for (final booking in bookings) {
      final checkIn = DateTime.parse(booking['check_in'] as String);
      final monthKey = '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}';

      monthlyBookings[monthKey] = (monthlyBookings[monthKey] ?? 0) + 1;
    }

    final dataPoints = monthlyBookings.entries.map((entry) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month, 1);

      return BookingDataPoint(
        date: date,
        count: entry.value,
        label: _getMonthLabel(month),
      );
    }).toList();

    dataPoints.sort((a, b) => a.date.compareTo(b.date));

    return dataPoints;
  }

  Future<List<PropertyPerformance>> _getPropertyPerformance(
    List<String> propertyIds,
    DateRangeFilter dateRange,
  ) async {
    final List<PropertyPerformance> performances = [];

    for (final propertyId in propertyIds) {
      // Get property details
      final property = await _supabase
          .from('properties')
          .select('id, name, base_price')
          .eq('id', propertyId)
          .single();

      // Get bookings for this property
      final bookingsResponse = await _supabase
          .from('bookings')
          .select('*')
          .eq('property_id', propertyId)
          .gte('check_in', dateRange.startDate.toIso8601String())
          .lte('check_in', dateRange.endDate.toIso8601String())
          .neq('status', 'cancelled');

      final bookings = bookingsResponse as List;

      if (bookings.isEmpty) continue;

      final revenue = bookings.fold<double>(
        0.0,
        (sum, b) => sum + ((b['total_price'] as num?)?.toDouble() ?? 0.0),
      );

      final bookedDays = bookings.fold<int>(
        0,
        (sum, b) {
          final checkIn = DateTime.parse(b['check_in'] as String);
          final checkOut = DateTime.parse(b['check_out'] as String);
          return sum + checkOut.difference(checkIn).inDays;
        },
      );

      final totalDays = dateRange.endDate.difference(dateRange.startDate).inDays;
      final occupancyRate = totalDays > 0 ? (bookedDays / totalDays) * 100 : 0.0;

      // Get reviews for rating
      final reviewsResponse = await _supabase
          .from('reviews')
          .select('rating')
          .eq('property_id', propertyId);

      final reviews = reviewsResponse as List;
      final avgRating = reviews.isEmpty
          ? 0.0
          : reviews.fold<double>(0.0, (sum, r) => sum + ((r['rating'] as num?)?.toDouble() ?? 0.0)) / reviews.length;

      performances.add(PropertyPerformance(
        propertyId: propertyId,
        propertyName: property['name'] as String,
        revenue: revenue,
        bookings: bookings.length,
        occupancyRate: occupancyRate,
        rating: avgRating,
      ));
    }

    // Sort by revenue (descending) and take top 5
    performances.sort((a, b) => b.revenue.compareTo(a.revenue));
    return performances.take(5).toList();
  }

  String _getMonthLabel(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  AnalyticsSummary _emptyAnalytics() {
    return const AnalyticsSummary(
      totalRevenue: 0.0,
      monthlyRevenue: 0.0,
      totalBookings: 0,
      monthlyBookings: 0,
      occupancyRate: 0.0,
      averageNightlyRate: 0.0,
      totalProperties: 0,
      activeProperties: 0,
      cancellationRate: 0.0,
      revenueHistory: [],
      bookingHistory: [],
      topPerformingProperties: [],
    );
  }
}
