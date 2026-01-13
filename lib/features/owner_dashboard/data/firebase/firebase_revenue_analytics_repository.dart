import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/models/booking_model.dart';
import '../../presentation/widgets/revenue_chart_widget.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import 'firestore_repository_mixin.dart';

/// Revenue statistics model
class RevenueStats {
  final double totalRevenue;
  final double thisMonthRevenue;
  final double trend;
  final Map<String, double> revenueByProperty;

  const RevenueStats({
    required this.totalRevenue,
    required this.thisMonthRevenue,
    required this.trend,
    required this.revenueByProperty,
  });

  static const empty = RevenueStats(totalRevenue: 0, thisMonthRevenue: 0, trend: 0, revenueByProperty: {});
}

/// Firebase implementation of Revenue Analytics Repository
class FirebaseRevenueAnalyticsRepository with FirestoreRepositoryMixin {
  final FirebaseFirestore _firestore;

  FirebaseRevenueAnalyticsRepository(this._firestore);

  // ============================================================
  // OPTIMIZED METHODS - Use these with pre-cached unitIds
  // ============================================================

  /// OPTIMIZED: Get all revenue stats in a single query batch.
  /// Fetches bookings ONCE and calculates all metrics from same dataset.
  /// Reduces queries from ~27 to ~2-3 (depending on unit count).
  Future<RevenueStats> getRevenueStatsOptimized({
    required List<String> unitIds,
    required Map<String, String> unitIdToPropertyName,
  }) async {
    if (unitIds.isEmpty) return RevenueStats.empty;

    try {
      final currentMonth = getCurrentMonthRange();
      final lastMonth = getLastMonthRange();

      // SINGLE QUERY: Fetch ALL confirmed/completed bookings for all units
      // Note: Aggregation queries (sum()) wouldn't help here - we calculate
      // multiple metrics (total, thisMonth, lastMonth, byProperty) from same data.
      // One fetch + in-memory calc is more efficient than multiple aggregations.
      final allBookings = await _fetchConfirmedBookings(unitIds);

      // Calculate ALL metrics from same dataset (no additional queries!)
      double totalRevenue = 0.0;
      double thisMonthRevenue = 0.0;
      double lastMonthRevenue = 0.0;
      final Map<String, double> revenueByProperty = {};

      for (final booking in allBookings) {
        final price = booking.totalPrice;
        totalRevenue += price;

        // This month revenue
        if (!booking.createdAt.isBefore(currentMonth.start)) {
          thisMonthRevenue += price;
        }

        // Last month revenue (for trend calculation)
        if (booking.createdAt.isAfter(lastMonth.start) && booking.createdAt.isBefore(lastMonth.end)) {
          lastMonthRevenue += price;
        }

        // Revenue by property
        final propertyName = unitIdToPropertyName[booking.unitId] ?? 'Unknown';
        revenueByProperty[propertyName] = (revenueByProperty[propertyName] ?? 0.0) + price;
      }

      return RevenueStats(
        totalRevenue: totalRevenue,
        thisMonthRevenue: thisMonthRevenue,
        trend: calculateTrend(thisMonthRevenue, lastMonthRevenue),
        revenueByProperty: revenueByProperty,
      );
    } catch (e) {
      throw AnalyticsException('Failed to get revenue stats', code: 'analytics/revenue-stats-failed', originalError: e);
    }
  }

  /// OPTIMIZED: Get revenue data for last N days using pre-cached unitIds.
  /// Reduces queries from ~5 to ~1-2 (depending on unit count).
  Future<List<RevenueDataPoint>> getRevenueByDaysOptimized({required List<String> unitIds, required int days}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));

    if (unitIds.isEmpty) {
      return _generateEmptyDataPoints(startDate, days);
    }

    try {
      final Map<String, double> revenueByDate = {};

      // Query bookings with pre-cached unitIds
      for (int i = 0; i < unitIds.length; i += FirestoreRepositoryMixin.batchLimit) {
        final batch = unitIds.skip(i).take(FirestoreRepositoryMixin.batchLimit).toList();
        // NEW STRUCTURE: Use collection group query for subcollection
        final bookingsSnapshot = await _firestore
            .collectionGroup('bookings')
            .where('unit_id', whereIn: batch)
            .where('status', whereIn: FirestoreRepositoryMixin.confirmedStatuses)
            .where('created_at', isGreaterThanOrEqualTo: startDate)
            .where('created_at', isLessThanOrEqualTo: endDate)
            .get();

        for (final doc in bookingsSnapshot.docs) {
          final booking = BookingModel.fromJson({...doc.data(), 'id': doc.id});
          final date = _dateKey(booking.createdAt);
          revenueByDate[date] = (revenueByDate[date] ?? 0) + booking.totalPrice;
        }
      }

      return _buildDataPoints(startDate, days, revenueByDate);
    } catch (e) {
      throw AnalyticsException(
        'Failed to get revenue by days',
        code: 'analytics/revenue-by-days-failed',
        originalError: e,
      );
    }
  }

  // ============================================================
  // LEGACY METHODS - Kept for backward compatibility
  // ============================================================

  /// Get revenue data for last N days
  Future<List<RevenueDataPoint>> getRevenueByDays(String ownerId, int days) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days - 1));

      final unitIds = await _getOwnerUnitIds(ownerId);
      if (unitIds.isEmpty) {
        return _generateEmptyDataPoints(startDate, days);
      }

      final Map<String, double> revenueByDate = {};

      for (int i = 0; i < unitIds.length; i += FirestoreRepositoryMixin.batchLimit) {
        final batch = unitIds.skip(i).take(FirestoreRepositoryMixin.batchLimit).toList();
        // NEW STRUCTURE: Use collection group query for subcollection
        final bookingsSnapshot = await _firestore
            .collectionGroup('bookings')
            .where('unit_id', whereIn: batch)
            .where('status', whereIn: FirestoreRepositoryMixin.confirmedStatuses)
            .where('created_at', isGreaterThanOrEqualTo: startDate)
            .where('created_at', isLessThanOrEqualTo: endDate)
            .get();

        for (final doc in bookingsSnapshot.docs) {
          final booking = BookingModel.fromJson({...doc.data(), 'id': doc.id});
          final date = _dateKey(booking.createdAt);
          revenueByDate[date] = (revenueByDate[date] ?? 0) + booking.totalPrice;
        }
      }

      return _buildDataPoints(startDate, days, revenueByDate);
    } catch (e) {
      throw AnalyticsException(
        'Failed to get revenue by days',
        code: 'analytics/revenue-by-days-failed',
        originalError: e,
      );
    }
  }

  /// Get total revenue for owner
  /// OPTIMIZED: Uses server-side aggregation (sum) instead of fetching docs
  Future<double> getTotalRevenue(String ownerId) async {
    try {
      final result = await _firestore
          .collectionGroup('bookings')
          .where('owner_id', isEqualTo: ownerId)
          .where('status', whereIn: FirestoreRepositoryMixin.confirmedStatuses)
          .aggregate(sum('total_price'))
          .get();

      return result.getSum('total_price') ?? 0.0;
    } catch (e) {
      throw AnalyticsException('Failed to get total revenue', code: 'analytics/total-revenue-failed', originalError: e);
    }
  }

  /// Get revenue for current month
  /// OPTIMIZED: Uses server-side aggregation with date filters
  Future<double> getRevenueThisMonth(String ownerId) async {
    try {
      final range = getCurrentMonthRange();
      return await _getRevenueInRangeAggregated(ownerId, range.start, range.end);
    } catch (e) {
      throw AnalyticsException(
        'Failed to get revenue this month',
        code: 'analytics/revenue-this-month-failed',
        originalError: e,
      );
    }
  }

  /// Get revenue for last month
  /// OPTIMIZED: Uses server-side aggregation with date filters
  Future<double> getRevenueLastMonth(String ownerId) async {
    try {
      final range = getLastMonthRange();
      return await _getRevenueInRangeAggregated(ownerId, range.start, range.end);
    } catch (e) {
      throw AnalyticsException(
        'Failed to get revenue last month',
        code: 'analytics/revenue-last-month-failed',
        originalError: e,
      );
    }
  }

  /// Calculate revenue trend (percentage change from last period)
  Future<double> getRevenueTrend(String ownerId) async {
    try {
      final thisMonth = await getRevenueThisMonth(ownerId);
      final lastMonth = await getRevenueLastMonth(ownerId);
      return calculateTrend(thisMonth, lastMonth);
    } catch (e) {
      return 0.0;
    }
  }

  /// Get revenue by property
  Future<Map<String, double>> getRevenueByProperty(String ownerId) async {
    try {
      final propertiesSnapshot = await _firestore.collection('properties').where('owner_id', isEqualTo: ownerId).get();

      final Map<String, double> revenueByProperty = {};

      for (final propertyDoc in propertiesSnapshot.docs) {
        final propertyName = propertyDoc.data()['name'] as String;
        final unitIds = await _getPropertyUnitIds(propertyDoc.id);

        if (unitIds.isEmpty) {
          revenueByProperty[propertyName] = 0.0;
          continue;
        }

        final bookings = await _fetchConfirmedBookings(unitIds);
        revenueByProperty[propertyName] = bookings.fold<double>(0.0, (total, b) => total + b.totalPrice);
      }

      return revenueByProperty;
    } catch (e) {
      throw AnalyticsException(
        'Failed to get revenue by property',
        code: 'analytics/revenue-by-property-failed',
        originalError: e,
      );
    }
  }

  /// Get revenue statistics (legacy method)
  Future<RevenueStats> getRevenueStats(String ownerId) async {
    try {
      // Run independent queries in parallel
      final results = await Future.wait([
        getTotalRevenue(ownerId),
        getRevenueThisMonth(ownerId),
        getRevenueTrend(ownerId),
        getRevenueByProperty(ownerId),
      ]);

      return RevenueStats(
        totalRevenue: results[0] as double,
        thisMonthRevenue: results[1] as double,
        trend: results[2] as double,
        revenueByProperty: results[3] as Map<String, double>,
      );
    } catch (e) {
      throw AnalyticsException('Failed to get revenue stats', code: 'analytics/revenue-stats-failed', originalError: e);
    }
  }

  // ============================================================
  // PRIVATE HELPER METHODS
  // ============================================================

  /// Get all unit IDs for an owner
  Future<List<String>> _getOwnerUnitIds(String ownerId) async {
    final propertiesSnapshot = await _firestore.collection('properties').where('owner_id', isEqualTo: ownerId).get();

    final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();
    if (propertyIds.isEmpty) return [];

    return await getUnitIdsForProperties(_firestore, propertyIds);
  }

  /// Get unit IDs for a specific property
  Future<List<String>> _getPropertyUnitIds(String propertyId) async {
    final unitsSnapshot = await _firestore.collection('properties').doc(propertyId).collection('units').get();
    return unitsSnapshot.docs.map((doc) => doc.id).toList();
  }

  /// Fetch confirmed/completed bookings for unit IDs
  Future<List<BookingModel>> _fetchConfirmedBookings(
    List<String> unitIds, {
    DateTime? createdAfter,
    DateTime? createdBefore,
  }) async {
    if (unitIds.isEmpty) return [];

    final List<BookingModel> bookings = [];

    for (int i = 0; i < unitIds.length; i += FirestoreRepositoryMixin.batchLimit) {
      final batch = unitIds.skip(i).take(FirestoreRepositoryMixin.batchLimit).toList();

      // NEW STRUCTURE: Use collection group query for subcollection
      Query<Map<String, dynamic>> query = _firestore
          .collectionGroup('bookings')
          .where('unit_id', whereIn: batch)
          .where('status', whereIn: FirestoreRepositoryMixin.confirmedStatuses);

      if (createdAfter != null) {
        query = query.where('created_at', isGreaterThanOrEqualTo: createdAfter);
      }
      if (createdBefore != null) {
        query = query.where('created_at', isLessThanOrEqualTo: createdBefore);
      }

      final snapshot = await query.get();

      for (final doc in snapshot.docs) {
        try {
          bookings.add(BookingModel.fromJson({...doc.data(), 'id': doc.id}));
        } catch (_) {
          // Skip invalid bookings
        }
      }
    }

    return bookings;
  }

  /// Get revenue in a date range using server-side aggregation
  /// OPTIMIZED: Uses Firestore sum() instead of fetching all docs
  Future<double> _getRevenueInRangeAggregated(String ownerId, DateTime startDate, DateTime endDate) async {
    final result = await _firestore
        .collectionGroup('bookings')
        .where('owner_id', isEqualTo: ownerId)
        .where('status', whereIn: FirestoreRepositoryMixin.confirmedStatuses)
        .where('created_at', isGreaterThanOrEqualTo: startDate)
        .where('created_at', isLessThanOrEqualTo: endDate)
        .aggregate(sum('total_price'))
        .get();

    return result.getSum('total_price') ?? 0.0;
  }

  /// Generate date key for grouping (YYYY-MM-DD)
  String _dateKey(DateTime date) => date.toIso8601String().split('T')[0];

  /// Build data points for chart
  List<RevenueDataPoint> _buildDataPoints(DateTime startDate, int days, Map<String, double> revenueByDate) {
    return List.generate(days, (i) {
      final date = startDate.add(Duration(days: i));
      final dateStr = _dateKey(date);
      return RevenueDataPoint(label: _formatDateLabel(date, i, days), value: revenueByDate[dateStr] ?? 0.0, date: date);
    });
  }

  /// Generate empty data points when there's no data
  List<RevenueDataPoint> _generateEmptyDataPoints(DateTime startDate, int days) {
    return List.generate(days, (i) {
      final date = startDate.add(Duration(days: i));
      return RevenueDataPoint(label: _formatDateLabel(date, i, days), value: 0.0, date: date);
    });
  }

  /// Format date label based on period
  String _formatDateLabel(DateTime date, int index, int totalDays) {
    if (totalDays <= 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } else if (totalDays <= 30) {
      return '${date.day}';
    } else {
      return getMonthLabel(date.month);
    }
  }
}
