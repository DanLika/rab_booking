import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/models/booking_model.dart';
import '../../presentation/widgets/revenue_chart_widget.dart';

/// Firebase implementation of Revenue Analytics Repository
class FirebaseRevenueAnalyticsRepository {
  final FirebaseFirestore _firestore;

  FirebaseRevenueAnalyticsRepository(this._firestore);

  /// Helper method to get all unit IDs for given properties from subcollections
  Future<List<String>> _getUnitIdsForProperties(List<String> propertyIds) async {
    final List<String> unitIds = [];
    for (final propertyId in propertyIds) {
      final unitsSnapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .get();
      unitIds.addAll(unitsSnapshot.docs.map((doc) => doc.id));
    }
    return unitIds;
  }

  /// Get revenue data for last N days
  Future<List<RevenueDataPoint>> getRevenueByDays(
    String ownerId,
    int days,
  ) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days - 1));

      // Step 1: Get all properties for owner
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .get();

      final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();

      if (propertyIds.isEmpty) {
        return _generateEmptyDataPoints(startDate, days);
      }

      // Step 2: Get all units for these properties from subcollections
      final unitIds = await _getUnitIdsForProperties(propertyIds);

      if (unitIds.isEmpty) {
        return _generateEmptyDataPoints(startDate, days);
      }

      // Step 3: Get all confirmed/completed bookings
      final Map<String, double> revenueByDate = {};

      for (int i = 0; i < unitIds.length; i += 10) {
        final batch = unitIds.skip(i).take(10).toList();
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .where('status', whereIn: ['confirmed', 'completed'])
            .where('created_at', isGreaterThanOrEqualTo: startDate)
            .where('created_at', isLessThanOrEqualTo: endDate)
            .get();

        for (final doc in bookingsSnapshot.docs) {
          final data = doc.data();
          final booking = BookingModel.fromJson({...data, 'id': doc.id});
          final date = booking.createdAt.toIso8601String().split('T')[0];

          revenueByDate[date] = (revenueByDate[date] ?? 0) + booking.totalPrice;
        }
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

  /// Generate empty data points when there's no data
  List<RevenueDataPoint> _generateEmptyDataPoints(DateTime startDate, int days) {
    final List<RevenueDataPoint> dataPoints = [];
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final label = _formatDateLabel(date, i, days);

      dataPoints.add(RevenueDataPoint(
        label: label,
        value: 0.0,
        date: date,
      ));
    }
    return dataPoints;
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
      // Get all properties for owner
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .get();

      final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();

      if (propertyIds.isEmpty) return 0.0;

      // Get all units for these properties
      final List<String> unitIds = [];
      for (int i = 0; i < propertyIds.length; i += 10) {
        final batch = propertyIds.skip(i).take(10).toList();
        final unitsSnapshot = await _firestore
            .collection('units')
            .where('property_id', whereIn: batch)
            .get();
        unitIds.addAll(unitsSnapshot.docs.map((doc) => doc.id));
      }

      if (unitIds.isEmpty) return 0.0;

      // Get total revenue from all confirmed/completed bookings
      double total = 0.0;
      for (int i = 0; i < unitIds.length; i += 10) {
        final batch = unitIds.skip(i).take(10).toList();
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .where('status', whereIn: ['confirmed', 'completed'])
            .get();

        for (final doc in bookingsSnapshot.docs) {
          final data = doc.data();
          total += (data['total_price'] as num).toDouble();
        }
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

      return await _getRevenueInRange(ownerId, startOfMonth, endOfMonth);
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

      return await _getRevenueInRange(ownerId, startOfLastMonth, endOfLastMonth);
    } catch (e) {
      throw Exception('Failed to get revenue last month: $e');
    }
  }

  /// Helper method to get revenue in a date range
  Future<double> _getRevenueInRange(
    String ownerId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Get all properties for owner
    final propertiesSnapshot = await _firestore
        .collection('properties')
        .where('owner_id', isEqualTo: ownerId)
        .get();

    final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();

    if (propertyIds.isEmpty) return 0.0;

    // Get all units for these properties
    final List<String> unitIds = [];
    for (int i = 0; i < propertyIds.length; i += 10) {
      final batch = propertyIds.skip(i).take(10).toList();
      final unitsSnapshot = await _firestore
          .collection('units')
          .where('property_id', whereIn: batch)
          .get();
      unitIds.addAll(unitsSnapshot.docs.map((doc) => doc.id));
    }

    if (unitIds.isEmpty) return 0.0;

    // Get revenue from bookings in range
    double total = 0.0;
    for (int i = 0; i < unitIds.length; i += 10) {
      final batch = unitIds.skip(i).take(10).toList();
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('unit_id', whereIn: batch)
          .where('status', whereIn: ['confirmed', 'completed'])
          .where('created_at', isGreaterThanOrEqualTo: startDate)
          .where('created_at', isLessThanOrEqualTo: endDate)
          .get();

      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        total += (data['total_price'] as num).toDouble();
      }
    }

    return total;
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
      // Get all properties for owner
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .get();

      final Map<String, double> revenueByProperty = {};

      for (final propertyDoc in propertiesSnapshot.docs) {
        final propertyName = propertyDoc.data()['name'] as String;

        // Get units for this property from subcollection
        final unitsSnapshot = await _firestore
            .collection('properties')
            .doc(propertyDoc.id)
            .collection('units')
            .get();

        final unitIds = unitsSnapshot.docs.map((doc) => doc.id).toList();

        if (unitIds.isEmpty) {
          revenueByProperty[propertyName] = 0.0;
          continue;
        }

        // Get revenue from bookings
        double totalRevenue = 0.0;
        for (int i = 0; i < unitIds.length; i += 10) {
          final batch = unitIds.skip(i).take(10).toList();
          final bookingsSnapshot = await _firestore
              .collection('bookings')
              .where('unit_id', whereIn: batch)
              .where('status', whereIn: ['confirmed', 'completed'])
              .get();

          for (final doc in bookingsSnapshot.docs) {
            final data = doc.data();
            totalRevenue += (data['total_price'] as num).toDouble();
          }
        }

        revenueByProperty[propertyName] = totalRevenue;
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
