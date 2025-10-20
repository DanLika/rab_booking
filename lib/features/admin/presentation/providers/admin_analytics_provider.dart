import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../owner_dashboard/domain/models/analytics_summary.dart';

part 'admin_analytics_provider.g.dart';

/// Admin Analytics Provider - Shows platform-wide analytics for all properties
@riverpod
class AdminAnalyticsNotifier extends _$AdminAnalyticsNotifier {
  @override
  Future<AnalyticsSummary> build({
    required DateRangeFilter dateRange,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      // Get ALL bookings within date range (no owner filter for admin)
      final bookingsResponse = await supabase
          .from('bookings')
          .select('*, property:properties!inner(id, name, base_price, owner_id)')
          .gte('check_in', dateRange.startDate.toIso8601String())
          .lte('check_in', dateRange.endDate.toIso8601String())
          .neq('status', 'cancelled');

      final bookings = bookingsResponse as List;

      if (bookings.isEmpty) {
        return _emptyAnalytics();
      }

      // Calculate metrics
      final totalRevenue = bookings.fold<double>(
        0.0,
        (sum, booking) => sum + ((booking['total_price'] as num?)?.toDouble() ?? 0.0),
      );

      final totalBookings = bookings.length;

      // Calculate monthly bookings and revenue
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthBookings = bookings.where((b) {
        final checkIn = DateTime.parse(b['check_in'] as String);
        return checkIn.isAfter(monthStart);
      }).toList();

      final monthlyBookings = monthBookings.length;
      final monthlyRevenue = monthBookings.fold<double>(
        0.0,
        (sum, booking) => sum + ((booking['total_price'] as num?)?.toDouble() ?? 0.0),
      );

      // Get all properties for occupancy calculation
      final propertiesResponse = await supabase
          .from('properties')
          .select('id, is_active');

      final allProperties = propertiesResponse as List;
      final activeProperties = allProperties.where((p) => p['is_active'] == true).length;
      final totalProperties = allProperties.length;

      // Calculate occupancy rate (simplified)
      final occupancyRate = activeProperties > 0
          ? (totalBookings / activeProperties) * 10.0 // Simplified calculation
          : 0.0;

      // Calculate average nightly rate
      final averageNightlyRate = bookings.isNotEmpty
          ? bookings.fold<double>(
              0.0,
              (sum, booking) {
                final property = booking['property'] as Map<String, dynamic>?;
                return sum + ((property?['base_price'] as num?)?.toDouble() ?? 0.0);
              },
            ) / bookings.length
          : 0.0;

      // Calculate cancellation rate
      final cancelledBookingsResponse = await supabase
          .from('bookings')
          .select('id')
          .gte('check_in', dateRange.startDate.toIso8601String())
          .lte('check_in', dateRange.endDate.toIso8601String())
          .eq('status', 'cancelled');

      final cancelledCount = (cancelledBookingsResponse as List).length;
      final totalWithCancelled = totalBookings + cancelledCount;
      final cancellationRate = totalWithCancelled > 0
          ? (cancelledCount / totalWithCancelled) * 100
          : 0.0;

      // Generate revenue history
      final revenueHistory = _generateRevenueHistory(bookings, dateRange);

      // Generate booking history
      final bookingHistory = _generateBookingHistory(bookings, dateRange);

      // Calculate top performing properties
      final topPerformingProperties = _calculateTopProperties(bookings);

      return AnalyticsSummary(
        totalRevenue: totalRevenue,
        totalBookings: totalBookings,
        occupancyRate: occupancyRate.clamp(0.0, 100.0),
        averageNightlyRate: averageNightlyRate,
        cancellationRate: cancellationRate,
        monthlyRevenue: monthlyRevenue,
        monthlyBookings: monthlyBookings,
        activeProperties: activeProperties,
        totalProperties: totalProperties,
        revenueHistory: revenueHistory,
        bookingHistory: bookingHistory,
        topPerformingProperties: topPerformingProperties,
      );
    } catch (e) {
      throw Exception('Failed to fetch admin analytics: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(dateRange: dateRange));
  }

  AnalyticsSummary _emptyAnalytics() {
    return const AnalyticsSummary(
      totalRevenue: 0,
      totalBookings: 0,
      occupancyRate: 0,
      averageNightlyRate: 0,
      cancellationRate: 0,
      monthlyRevenue: 0,
      monthlyBookings: 0,
      activeProperties: 0,
      totalProperties: 0,
      revenueHistory: [],
      bookingHistory: [],
      topPerformingProperties: [],
    );
  }

  List<RevenueDataPoint> _generateRevenueHistory(
    List<dynamic> bookings,
    DateRangeFilter dateRange,
  ) {
    final Map<String, _DateRevenue> revenueByDate = {};

    for (final booking in bookings) {
      final checkIn = DateTime.parse(booking['check_in'] as String);
      final label = _formatDateLabel(checkIn, dateRange);
      final revenue = (booking['total_price'] as num?)?.toDouble() ?? 0.0;

      if (!revenueByDate.containsKey(label)) {
        revenueByDate[label] = _DateRevenue(date: checkIn, amount: 0.0);
      }
      revenueByDate[label]!.amount += revenue;
    }

    return revenueByDate.entries
        .map((e) => RevenueDataPoint(
              date: e.value.date,
              label: e.key,
              amount: e.value.amount,
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<BookingDataPoint> _generateBookingHistory(
    List<dynamic> bookings,
    DateRangeFilter dateRange,
  ) {
    final Map<String, _DateBooking> bookingsByDate = {};

    for (final booking in bookings) {
      final checkIn = DateTime.parse(booking['check_in'] as String);
      final label = _formatDateLabel(checkIn, dateRange);

      if (!bookingsByDate.containsKey(label)) {
        bookingsByDate[label] = _DateBooking(date: checkIn, count: 0);
      }
      bookingsByDate[label]!.count += 1;
    }

    return bookingsByDate.entries
        .map((e) => BookingDataPoint(
              date: e.value.date,
              label: e.key,
              count: e.value.count,
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<PropertyPerformance> _calculateTopProperties(List<dynamic> bookings) {
    final Map<String, _PropertyData> propertyData = {};

    for (final booking in bookings) {
      final property = booking['property'] as Map<String, dynamic>?;
      if (property == null) continue;

      final propertyId = property['id'] as String;
      final propertyName = property['name'] as String? ?? 'Unknown Property';
      final revenue = (booking['total_price'] as num?)?.toDouble() ?? 0.0;

      if (!propertyData.containsKey(propertyId)) {
        propertyData[propertyId] = _PropertyData(
          id: propertyId,
          name: propertyName,
        );
      }

      propertyData[propertyId]!.bookings++;
      propertyData[propertyId]!.revenue += revenue;
    }

    final performances = propertyData.values
        .map((data) => PropertyPerformance(
              propertyId: data.id,
              propertyName: data.name,
              bookings: data.bookings,
              revenue: data.revenue,
              occupancyRate: (data.bookings * 10).toDouble().clamp(0.0, 100.0),
              rating: 4.5, // Placeholder - would need to fetch from reviews
            ))
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return performances.take(10).toList();
  }

  String _formatDateLabel(DateTime date, DateRangeFilter dateRange) {
    final daysDiff = dateRange.endDate.difference(dateRange.startDate).inDays;

    if (daysDiff <= 7) {
      // Show day of week for weekly view
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } else if (daysDiff <= 31) {
      // Show date for monthly view
      return '${date.month}/${date.day}';
    } else if (daysDiff <= 120) {
      // Show week number for quarterly view
      final weekNum = ((date.day - 1) / 7).floor() + 1;
      return 'W$weekNum';
    } else {
      // Show month for yearly view
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[date.month - 1];
    }
  }
}

/// Helper class for property data aggregation
class _PropertyData {
  final String id;
  final String name;
  int bookings = 0;
  double revenue = 0.0;

  _PropertyData({required this.id, required this.name});
}

/// Helper class for tracking revenue with date
class _DateRevenue {
  final DateTime date;
  double amount;

  _DateRevenue({required this.date, required this.amount});
}

/// Helper class for tracking bookings with date
class _DateBooking {
  final DateTime date;
  int count;

  _DateBooking({required this.date, required this.count});
}
