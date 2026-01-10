import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/unified_dashboard_data.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/services/logging_service.dart';
import 'owner_bookings_provider.dart';
import 'owner_calendar_provider.dart';

part 'unified_dashboard_provider.g.dart';

/// Empty data when no bookings exist
const _emptyDashboardData = UnifiedDashboardData(
  revenue: 0.0,
  bookings: 0,
  upcomingCheckIns: 0,
  occupancyRate: 0.0,
  revenueHistory: [],
  bookingHistory: [],
);

/// Date range notifier for Dashboard time period selection
/// Default: Last 7 days (rolling window)
@riverpod
class DashboardDateRangeNotifier extends _$DashboardDateRangeNotifier {
  @override
  DateRangeFilter build() {
    return DateRangeFilter.last7Days();
  }

  void setPreset(String preset) {
    state = switch (preset) {
      'last7' => DateRangeFilter.last7Days(),
      'last30' => DateRangeFilter.last30Days(),
      'last90' => DateRangeFilter.last90Days(),
      'last365' => DateRangeFilter.last365Days(),
      // Legacy support (backward compatibility)
      'week' => DateRangeFilter.last7Days(),
      'month' => DateRangeFilter.last30Days(),
      'quarter' => DateRangeFilter.last90Days(),
      'year' => DateRangeFilter.last365Days(),
      _ => DateRangeFilter.last7Days(),
    };
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = DateRangeFilter(startDate: start, endDate: end, preset: 'custom');
  }
}

/// UNIFIED Dashboard Provider
/// Combines metrics calculation + chart data in one provider
/// Uses check_in date for filtering (consistent across all metrics)
@Riverpod(keepAlive: true)
class UnifiedDashboardNotifier extends _$UnifiedDashboardNotifier {
  @override
  Future<UnifiedDashboardData> build() async {
    // Watch date range - provider rebuilds when it changes
    final dateRange = ref.watch(dashboardDateRangeNotifierProvider);

    try {
      final auth = FirebaseAuth.instance;
      final userId = auth.currentUser?.uid;

      if (userId == null) {
        await LoggingService.logError('Dashboard: User not authenticated');
        throw AuthException(
          'User not authenticated',
          code: 'auth/not-authenticated',
        );
      }

      // Get cached data from existing providers
      final unitIds = await ref.watch(ownerUnitIdsProvider.future);
      final units = await ref.watch(allOwnerUnitsProvider.future);

      if (unitIds.isEmpty) {
        return _emptyDashboardData;
      }

      // Query bookings using check_in date (consistent logic)
      final bookings = await _queryBookingsForPeriod(
        unitIds: unitIds,
        dateRange: dateRange,
      );

      // Query upcoming check-ins (always next 7 days, regardless of selected period)
      final upcomingCheckIns = await _queryUpcomingCheckIns(unitIds: unitIds);

      // Filter for confirmed/completed bookings for metrics and charts
      // Pending bookings are excluded as they represent unconfirmed revenue
      final confirmedAndCompletedBookings = bookings
          .where(
            (b) => b['status'] == 'confirmed' || b['status'] == 'completed',
          )
          .toList();

      // Calculate metrics using only confirmed/completed bookings
      final revenue = confirmedAndCompletedBookings.fold<double>(
        0.0,
        (total, b) => total + ((b['total_price'] as num?)?.toDouble() ?? 0.0),
      );

      // Bookings count reflects only confirmed and completed bookings
      final bookingsCount = confirmedAndCompletedBookings.length;

      // Calculate occupancy rate based on UNITS (not properties)
      final totalDaysInRange = dateRange.endDate
          .difference(dateRange.startDate)
          .inDays;
      final bookedDays = confirmedAndCompletedBookings.fold<int>(0, (total, b) {
        final checkIn = _parseCheckIn(b);
        final checkOut = _parseCheckOut(b);
        if (checkIn == null || checkOut == null) return total; // Skip invalid

        // Calculate overlap with date range
        final overlapStart = checkIn.isAfter(dateRange.startDate)
            ? checkIn
            : dateRange.startDate;
        final overlapEnd = checkOut.isBefore(dateRange.endDate)
            ? checkOut
            : dateRange.endDate;

        final nights = overlapEnd.difference(overlapStart).inDays;
        return total + (nights > 0 ? nights : 0);
      });

      // Use units count (not properties) for accurate occupancy
      final availableDays = totalDaysInRange * units.length;
      var occupancyRate = availableDays > 0
          ? (bookedDays / availableDays) * 100
          : 0.0;
      if (occupancyRate > 100) occupancyRate = 100;

      // Generate chart data using confirmed/completed bookings for consistency
      // This ensures chart totals match summary metrics
      final revenueHistory = _generateRevenueHistory(
        confirmedAndCompletedBookings,
        dateRange,
      );
      final bookingHistory = _generateBookingHistory(
        confirmedAndCompletedBookings,
        dateRange,
      );

      return UnifiedDashboardData(
        revenue: revenue,
        bookings: bookingsCount,
        upcomingCheckIns: upcomingCheckIns.length,
        occupancyRate: occupancyRate,
        revenueHistory: revenueHistory,
        bookingHistory: bookingHistory,
      );
    } catch (e, stackTrace) {
      await LoggingService.logError('Dashboard provider error', e, stackTrace);
      rethrow;
    }
  }

  /// Query bookings for the selected period using check_in date
  Future<List<Map<String, dynamic>>> _queryBookingsForPeriod({
    required List<String> unitIds,
    required DateRangeFilter dateRange,
  }) async {
    final firestore = ref.read(firestoreProvider);
    final auth = FirebaseAuth.instance;
    final userId = auth.currentUser?.uid;
    if (userId == null) return [];

    final List<Map<String, dynamic>> allBookings = [];

    // Convert DateTime to Timestamp for Firestore
    final startTimestamp = Timestamp.fromDate(dateRange.startDate);
    final endTimestamp = Timestamp.fromDate(dateRange.endDate);

    // Query using collection group with owner_id (efficient)
    // Get confirmed/completed/pending bookings (exclude cancelled)
    for (final status in ['confirmed', 'completed', 'pending']) {
      try {
        final snapshot = await firestore
            .collectionGroup('bookings')
            .where('owner_id', isEqualTo: userId)
            .where('status', isEqualTo: status)
            .where('check_in', isGreaterThanOrEqualTo: startTimestamp)
            .where('check_in', isLessThanOrEqualTo: endTimestamp)
            .get();

        for (final doc in snapshot.docs) {
          // Filter by unitIds client-side (owner_id already verified by query)
          final data = doc.data();
          if (unitIds.contains(data['unit_id'])) {
            allBookings.add({...data, 'id': doc.id});
          }
        }
      } catch (e) {
        // Log but continue - don't fail entire dashboard for one status
        await LoggingService.logError(
          'Dashboard: Failed to query $status bookings',
          e,
        );
      }
    }

    return allBookings;
  }

  /// Query upcoming check-ins (next 7 days)
  Future<List<Map<String, dynamic>>> _queryUpcomingCheckIns({
    required List<String> unitIds,
  }) async {
    final firestore = ref.read(firestoreProvider);
    final auth = FirebaseAuth.instance;
    final userId = auth.currentUser?.uid;
    if (userId == null) return [];

    final now = DateTime.now();
    final nowTimestamp = Timestamp.fromDate(now);
    final next7Days = Timestamp.fromDate(now.add(const Duration(days: 7)));

    final List<Map<String, dynamic>> checkIns = [];

    // Query confirmed and pending bookings checking in within next 7 days
    for (final status in ['confirmed', 'pending']) {
      try {
        final snapshot = await firestore
            .collectionGroup('bookings')
            .where('owner_id', isEqualTo: userId)
            .where('status', isEqualTo: status)
            .where('check_in', isGreaterThanOrEqualTo: nowTimestamp)
            .where('check_in', isLessThan: next7Days)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (unitIds.contains(data['unit_id'])) {
            checkIns.add({...data, 'id': doc.id});
          }
        }
      } catch (e) {
        await LoggingService.logError(
          'Dashboard: Failed to query upcoming check-ins',
          e,
        );
      }
    }

    return checkIns;
  }

  /// Generate revenue history for chart (grouped by day/week/month based on range)
  List<RevenueDataPoint> _generateRevenueHistory(
    List<Map<String, dynamic>> bookings,
    DateRangeFilter dateRange,
  ) {
    final totalDays = dateRange.endDate.difference(dateRange.startDate).inDays;

    if (totalDays <= 14) {
      // Daily grouping for short ranges
      return _generateDailyRevenue(bookings, dateRange);
    } else if (totalDays <= 90) {
      // Weekly grouping for medium ranges
      return _generateWeeklyRevenue(bookings, dateRange);
    } else {
      // Monthly grouping for long ranges
      return _generateMonthlyRevenue(bookings);
    }
  }

  List<RevenueDataPoint> _generateDailyRevenue(
    List<Map<String, dynamic>> bookings,
    DateRangeFilter dateRange,
  ) {
    final Map<String, double> dailyRevenue = {};

    for (final booking in bookings) {
      final checkIn = _parseCheckIn(booking);
      if (checkIn == null) continue; // Skip invalid
      final dayKey =
          '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}-${checkIn.day.toString().padLeft(2, '0')}';
      final revenue = (booking['total_price'] as num?)?.toDouble() ?? 0.0;
      dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0.0) + revenue;
    }

    return dailyRevenue.entries.map((entry) {
      final parts = entry.key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return RevenueDataPoint(
        date: date,
        amount: entry.value,
        label: '${date.day}/${date.month}',
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  List<RevenueDataPoint> _generateWeeklyRevenue(
    List<Map<String, dynamic>> bookings,
    DateRangeFilter dateRange,
  ) {
    final Map<String, double> weeklyRevenue = {};

    for (final booking in bookings) {
      final checkIn = _parseCheckIn(booking);
      if (checkIn == null) continue; // Skip invalid
      // Get week number (ISO week)
      final weekStart = checkIn.subtract(Duration(days: checkIn.weekday - 1));
      final weekKey =
          '${weekStart.year}-W${_getWeekNumber(weekStart).toString().padLeft(2, '0')}';
      final revenue = (booking['total_price'] as num?)?.toDouble() ?? 0.0;
      weeklyRevenue[weekKey] = (weeklyRevenue[weekKey] ?? 0.0) + revenue;
    }

    return weeklyRevenue.entries.map((entry) {
      final parts = entry.key.split('-W');
      final year = int.parse(parts[0]);
      final week = int.parse(parts[1]);
      // Approximate date for week start
      final date = DateTime(year).add(Duration(days: (week - 1) * 7));
      return RevenueDataPoint(date: date, amount: entry.value, label: 'W$week');
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  List<RevenueDataPoint> _generateMonthlyRevenue(
    List<Map<String, dynamic>> bookings,
  ) {
    final Map<String, double> monthlyRevenue = {};

    for (final booking in bookings) {
      final checkIn = _parseCheckIn(booking);
      if (checkIn == null) continue; // Skip invalid
      final monthKey =
          '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}';
      final revenue = (booking['total_price'] as num?)?.toDouble() ?? 0.0;
      monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0.0) + revenue;
    }

    return monthlyRevenue.entries.map((entry) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month);
      return RevenueDataPoint(
        date: date,
        amount: entry.value,
        label: _getMonthLabel(month),
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Generate booking history for chart
  List<BookingDataPoint> _generateBookingHistory(
    List<Map<String, dynamic>> bookings,
    DateRangeFilter dateRange,
  ) {
    final totalDays = dateRange.endDate.difference(dateRange.startDate).inDays;

    if (totalDays <= 14) {
      return _generateDailyBookings(bookings);
    } else if (totalDays <= 90) {
      return _generateWeeklyBookings(bookings);
    } else {
      return _generateMonthlyBookings(bookings);
    }
  }

  List<BookingDataPoint> _generateDailyBookings(
    List<Map<String, dynamic>> bookings,
  ) {
    final Map<String, int> dailyBookings = {};

    for (final booking in bookings) {
      final checkIn = _parseCheckIn(booking);
      if (checkIn == null) continue; // Skip invalid
      final dayKey =
          '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}-${checkIn.day.toString().padLeft(2, '0')}';
      dailyBookings[dayKey] = (dailyBookings[dayKey] ?? 0) + 1;
    }

    return dailyBookings.entries.map((entry) {
      final parts = entry.key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return BookingDataPoint(
        date: date,
        count: entry.value,
        label: '${date.day}/${date.month}',
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  List<BookingDataPoint> _generateWeeklyBookings(
    List<Map<String, dynamic>> bookings,
  ) {
    final Map<String, int> weeklyBookings = {};

    for (final booking in bookings) {
      final checkIn = _parseCheckIn(booking);
      if (checkIn == null) continue; // Skip invalid
      final weekStart = checkIn.subtract(Duration(days: checkIn.weekday - 1));
      final weekKey =
          '${weekStart.year}-W${_getWeekNumber(weekStart).toString().padLeft(2, '0')}';
      weeklyBookings[weekKey] = (weeklyBookings[weekKey] ?? 0) + 1;
    }

    return weeklyBookings.entries.map((entry) {
      final parts = entry.key.split('-W');
      final year = int.parse(parts[0]);
      final week = int.parse(parts[1]);
      final date = DateTime(year).add(Duration(days: (week - 1) * 7));
      return BookingDataPoint(date: date, count: entry.value, label: 'W$week');
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  List<BookingDataPoint> _generateMonthlyBookings(
    List<Map<String, dynamic>> bookings,
  ) {
    final Map<String, int> monthlyBookings = {};

    for (final booking in bookings) {
      final checkIn = _parseCheckIn(booking);
      if (checkIn == null) continue; // Skip invalid
      final monthKey =
          '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}';
      monthlyBookings[monthKey] = (monthlyBookings[monthKey] ?? 0) + 1;
    }

    return monthlyBookings.entries.map((entry) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month);
      return BookingDataPoint(
        date: date,
        count: entry.value,
        label: _getMonthLabel(month),
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year);
    final dayOfYear = date.difference(firstDayOfYear).inDays;
    return ((dayOfYear + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  String _getMonthLabel(int month) {
    if (month < 1 || month > 12) return 'Invalid';
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
      'Dec',
    ];
    return months[month - 1];
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    // Invalidate cached providers to force fresh data
    ref.invalidate(ownerUnitIdsProvider);
    ref.invalidate(ownerPropertiesCalendarProvider);
    ref.invalidate(allOwnerUnitsProvider);

    // Trigger rebuild
    ref.invalidateSelf();
  }

  /// Safely parse check_in from booking data
  /// Handles Timestamp, DateTime, or null values gracefully
  DateTime? _parseCheckIn(Map<String, dynamic> booking) {
    final value = booking['check_in'];
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Safely parse check_out from booking data
  DateTime? _parseCheckOut(Map<String, dynamic> booking) {
    final value = booking['check_out'];
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
