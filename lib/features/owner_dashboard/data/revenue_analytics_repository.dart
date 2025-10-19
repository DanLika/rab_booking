import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/booking_model.dart';
import '../presentation/widgets/revenue_chart_widget.dart';

part 'revenue_analytics_repository.g.dart';

/// Revenue analytics repository
class RevenueAnalyticsRepository {
  final SupabaseClient _supabase;

  RevenueAnalyticsRepository(this._supabase);

  /// Get revenue data for last N days
  Future<List<RevenueDataPoint>> getRevenueByDays(
    String ownerId,
    int days,
  ) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days - 1));

      // Get all confirmed/completed bookings for owner's properties
      final response = await _supabase
          .from('bookings')
          .select('''
            *,
            properties!inner(owner_id)
          ''')
          .eq('properties.owner_id', ownerId)
          .inFilter('status', ['confirmed', 'completed'])
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: true);

      // Group by date and sum revenue
      final Map<String, double> revenueByDate = {};

      for (final data in response as List) {
        final booking = BookingModel.fromJson(data);
        final date = booking.createdAt.toIso8601String().split('T')[0];

        revenueByDate[date] = (revenueByDate[date] ?? 0) + booking.totalPrice;
      }

      // Create data points for all days (including days with 0 revenue)
      final List<RevenueDataPoint> dataPoints = [];
      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T')[0];
        final label = _formatDateLabel(date, i, days);

        dataPoints.add(RevenueDataPoint(
          label: label,
          value: revenueByDate[dateStr] ?? 0.0,
          date: date,
        ));
      }

      return dataPoints;
    } catch (e) {
      throw Exception('Failed to get revenue by days: $e');
    }
  }

  /// Format date label based on period
  String _formatDateLabel(DateTime date, int index, int totalDays) {
    if (totalDays <= 7) {
      // Show day of week for 7 days or less
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } else if (totalDays <= 30) {
      // Show date for monthly view
      return '${date.day}';
    } else {
      // Show month for longer periods
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return months[date.month - 1];
    }
  }

  /// Get total revenue for owner
  Future<double> getTotalRevenue(String ownerId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            total_price,
            properties!inner(owner_id)
          ''')
          .eq('properties.owner_id', ownerId)
          .inFilter('status', ['confirmed', 'completed']);

      double total = 0.0;
      for (final data in response as List) {
        total += (data['total_price'] as num).toDouble();
      }

      return total;
    } catch (e) {
      throw Exception('Failed to get total revenue: $e');
    }
  }

  /// Get revenue for current month
  Future<double> getRevenueThisMonth(String ownerId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final response = await _supabase
          .from('bookings')
          .select('''
            total_price,
            properties!inner(owner_id)
          ''')
          .eq('properties.owner_id', ownerId)
          .inFilter('status', ['confirmed', 'completed'])
          .gte('created_at', startOfMonth.toIso8601String())
          .lte('created_at', endOfMonth.toIso8601String());

      double total = 0.0;
      for (final data in response as List) {
        total += (data['total_price'] as num).toDouble();
      }

      return total;
    } catch (e) {
      throw Exception('Failed to get revenue this month: $e');
    }
  }

  /// Get revenue for last month
  Future<double> getRevenueLastMonth(String ownerId) async {
    try {
      final now = DateTime.now();
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);

      final response = await _supabase
          .from('bookings')
          .select('''
            total_price,
            properties!inner(owner_id)
          ''')
          .eq('properties.owner_id', ownerId)
          .inFilter('status', ['confirmed', 'completed'])
          .gte('created_at', startOfLastMonth.toIso8601String())
          .lte('created_at', endOfLastMonth.toIso8601String());

      double total = 0.0;
      for (final data in response as List) {
        total += (data['total_price'] as num).toDouble();
      }

      return total;
    } catch (e) {
      throw Exception('Failed to get revenue last month: $e');
    }
  }

  /// Calculate revenue trend (percentage change from last period)
  Future<double> getRevenueTrend(String ownerId) async {
    try {
      final thisMonth = await getRevenueThisMonth(ownerId);
      final lastMonth = await getRevenueLastMonth(ownerId);

      if (lastMonth == 0) return 0.0;

      return ((thisMonth - lastMonth) / lastMonth) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get revenue by property
  Future<Map<String, double>> getRevenueByProperty(String ownerId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            total_price,
            property_id,
            properties!inner(owner_id, name)
          ''')
          .eq('properties.owner_id', ownerId)
          .inFilter('status', ['confirmed', 'completed']);

      final Map<String, double> revenueByProperty = {};

      for (final data in response as List) {
        final propertyName = data['properties']['name'] as String;
        final totalPrice = (data['total_price'] as num).toDouble();

        revenueByProperty[propertyName] =
            (revenueByProperty[propertyName] ?? 0) + totalPrice;
      }

      return revenueByProperty;
    } catch (e) {
      throw Exception('Failed to get revenue by property: $e');
    }
  }

  /// Get revenue statistics
  Future<RevenueStats> getRevenueStats(String ownerId) async {
    try {
      final totalRevenue = await getTotalRevenue(ownerId);
      final thisMonthRevenue = await getRevenueThisMonth(ownerId);
      final trend = await getRevenueTrend(ownerId);
      final revenueByProperty = await getRevenueByProperty(ownerId);

      return RevenueStats(
        totalRevenue: totalRevenue,
        thisMonthRevenue: thisMonthRevenue,
        trend: trend,
        revenueByProperty: revenueByProperty,
      );
    } catch (e) {
      throw Exception('Failed to get revenue stats: $e');
    }
  }
}

/// Revenue statistics model
class RevenueStats {
  final double totalRevenue;
  final double thisMonthRevenue;
  final double trend;
  final Map<String, double> revenueByProperty;

  RevenueStats({
    required this.totalRevenue,
    required this.thisMonthRevenue,
    required this.trend,
    required this.revenueByProperty,
  });
}

/// Provider for revenue analytics repository
@riverpod
RevenueAnalyticsRepository revenueAnalyticsRepository(
  Ref ref,
) {
  return RevenueAnalyticsRepository(Supabase.instance.client);
}
