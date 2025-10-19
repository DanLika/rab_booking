import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'property_performance_repository.g.dart';

/// Property performance repository
class PropertyPerformanceRepository {
  final SupabaseClient _supabase;

  PropertyPerformanceRepository(this._supabase);

  /// Calculate occupancy rate for owner's properties
  /// Returns percentage of booked nights vs available nights
  Future<double> getOccupancyRate(String ownerId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Get all owner's properties with units
      final propertiesResponse = await _supabase
          .from('properties')
          .select('id, units(id)')
          .eq('owner_id', ownerId)
          .eq('is_active', true);

      if (propertiesResponse.isEmpty) return 0.0;

      // Count total units
      int totalUnits = 0;
      for (final property in propertiesResponse as List) {
        final units = property['units'] as List?;
        if (units != null) {
          totalUnits += units.length;
        }
      }

      if (totalUnits == 0) return 0.0;

      // Calculate total available nights (units * days in month)
      final daysInMonth = endOfMonth.day;
      final totalAvailableNights = totalUnits * daysInMonth;

      // Get all bookings for this month
      final bookingsResponse = await _supabase
          .from('bookings')
          .select('''
            check_in,
            check_out,
            status,
            properties!inner(owner_id)
          ''')
          .eq('properties.owner_id', ownerId)
          .inFilter('status', ['confirmed', 'completed'])
          .gte('check_in', startOfMonth.toIso8601String().split('T')[0])
          .lte('check_out', endOfMonth.toIso8601String().split('T')[0]);

      // Calculate total booked nights
      int totalBookedNights = 0;
      for (final data in bookingsResponse as List) {
        final checkIn = DateTime.parse(data['check_in'] as String);
        final checkOut = DateTime.parse(data['check_out'] as String);
        final nights = checkOut.difference(checkIn).inDays;
        totalBookedNights += nights;
      }

      // Calculate occupancy rate
      if (totalAvailableNights == 0) return 0.0;
      return (totalBookedNights / totalAvailableNights) * 100;
    } catch (e) {
      throw Exception('Failed to calculate occupancy rate: $e');
    }
  }

  /// Get occupancy rate for last month
  Future<double> getOccupancyRateLastMonth(String ownerId) async {
    try {
      final now = DateTime.now();
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0);

      // Get all owner's properties with units
      final propertiesResponse = await _supabase
          .from('properties')
          .select('id, units(id)')
          .eq('owner_id', ownerId)
          .eq('is_active', true);

      if (propertiesResponse.isEmpty) return 0.0;

      // Count total units
      int totalUnits = 0;
      for (final property in propertiesResponse as List) {
        final units = property['units'] as List?;
        if (units != null) {
          totalUnits += units.length;
        }
      }

      if (totalUnits == 0) return 0.0;

      // Calculate total available nights
      final daysInMonth = endOfLastMonth.day;
      final totalAvailableNights = totalUnits * daysInMonth;

      // Get all bookings for last month
      final bookingsResponse = await _supabase
          .from('bookings')
          .select('''
            check_in,
            check_out,
            status,
            properties!inner(owner_id)
          ''')
          .eq('properties.owner_id', ownerId)
          .inFilter('status', ['confirmed', 'completed'])
          .gte('check_in', startOfLastMonth.toIso8601String().split('T')[0])
          .lte('check_out', endOfLastMonth.toIso8601String().split('T')[0]);

      // Calculate total booked nights
      int totalBookedNights = 0;
      for (final data in bookingsResponse as List) {
        final checkIn = DateTime.parse(data['check_in'] as String);
        final checkOut = DateTime.parse(data['check_out'] as String);
        final nights = checkOut.difference(checkIn).inDays;
        totalBookedNights += nights;
      }

      // Calculate occupancy rate
      if (totalAvailableNights == 0) return 0.0;
      return (totalBookedNights / totalAvailableNights) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculate occupancy trend (percentage change from last month)
  Future<double> getOccupancyTrend(String ownerId) async {
    try {
      final currentRate = await getOccupancyRate(ownerId);
      final lastMonthRate = await getOccupancyRateLastMonth(ownerId);

      if (lastMonthRate == 0) return 0.0;

      return ((currentRate - lastMonthRate) / lastMonthRate) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get total bookings count
  Future<int> getTotalBookingsCount(String ownerId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('id, properties!inner(owner_id)')
          .eq('properties.owner_id', ownerId)
          .inFilter('status', ['confirmed', 'completed', 'pending']);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get bookings count: $e');
    }
  }

  /// Get bookings count for this month
  Future<int> getBookingsThisMonth(String ownerId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final response = await _supabase
          .from('bookings')
          .select('id, properties!inner(owner_id)')
          .eq('properties.owner_id', ownerId)
          .inFilter('status', ['confirmed', 'completed', 'pending'])
          .gte('created_at', startOfMonth.toIso8601String())
          .lte('created_at', endOfMonth.toIso8601String());

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get bookings this month: $e');
    }
  }

  /// Get bookings count for last month
  Future<int> getBookingsLastMonth(String ownerId) async {
    try {
      final now = DateTime.now();
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);

      final response = await _supabase
          .from('bookings')
          .select('id, properties!inner(owner_id)')
          .eq('properties.owner_id', ownerId)
          .inFilter('status', ['confirmed', 'completed', 'pending'])
          .gte('created_at', startOfLastMonth.toIso8601String())
          .lte('created_at', endOfLastMonth.toIso8601String());

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Calculate bookings trend (percentage change from last month)
  Future<double> getBookingsTrend(String ownerId) async {
    try {
      final thisMonth = await getBookingsThisMonth(ownerId);
      final lastMonth = await getBookingsLastMonth(ownerId);

      if (lastMonth == 0) return 0.0;

      return ((thisMonth - lastMonth) / lastMonth) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get active listings count (active properties)
  Future<int> getActiveListingsCount(String ownerId) async {
    try {
      final response = await _supabase
          .from('properties')
          .select('id')
          .eq('owner_id', ownerId)
          .eq('is_active', true);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get active listings: $e');
    }
  }

  /// Get cancellation rate
  Future<double> getCancellationRate(String ownerId) async {
    try {
      // Get all bookings
      final allBookings = await _supabase
          .from('bookings')
          .select('id, properties!inner(owner_id)')
          .eq('properties.owner_id', ownerId);

      if (allBookings.isEmpty) return 0.0;

      // Get cancelled bookings
      final cancelledBookings = await _supabase
          .from('bookings')
          .select('id, properties!inner(owner_id)')
          .eq('properties.owner_id', ownerId)
          .eq('status', 'cancelled');

      final totalCount = (allBookings as List).length;
      final cancelledCount = (cancelledBookings as List).length;

      return (cancelledCount / totalCount) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get performance statistics
  Future<PerformanceStats> getPerformanceStats(String ownerId) async {
    try {
      final occupancyRate = await getOccupancyRate(ownerId);
      final occupancyTrend = await getOccupancyTrend(ownerId);
      final totalBookings = await getTotalBookingsCount(ownerId);
      final bookingsTrend = await getBookingsTrend(ownerId);
      final activeListings = await getActiveListingsCount(ownerId);
      final cancellationRate = await getCancellationRate(ownerId);

      return PerformanceStats(
        occupancyRate: occupancyRate,
        occupancyTrend: occupancyTrend,
        totalBookings: totalBookings,
        bookingsTrend: bookingsTrend,
        activeListings: activeListings,
        cancellationRate: cancellationRate,
      );
    } catch (e) {
      throw Exception('Failed to get performance stats: $e');
    }
  }
}

/// Performance statistics model
class PerformanceStats {
  final double occupancyRate;
  final double occupancyTrend;
  final int totalBookings;
  final double bookingsTrend;
  final int activeListings;
  final double cancellationRate;

  PerformanceStats({
    required this.occupancyRate,
    required this.occupancyTrend,
    required this.totalBookings,
    required this.bookingsTrend,
    required this.activeListings,
    required this.cancellationRate,
  });
}

/// Provider for property performance repository
@riverpod
PropertyPerformanceRepository propertyPerformanceRepository(
  Ref ref,
) {
  return PropertyPerformanceRepository(Supabase.instance.client);
}
