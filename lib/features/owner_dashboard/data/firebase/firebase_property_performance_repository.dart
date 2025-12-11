import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import 'firestore_repository_mixin.dart';

/// Performance statistics model
class PerformanceStats {
  final double occupancyRate;
  final double occupancyTrend;
  final int totalBookings;
  final double bookingsTrend;
  final int activeListings;
  final double cancellationRate;

  const PerformanceStats({
    required this.occupancyRate,
    required this.occupancyTrend,
    required this.totalBookings,
    required this.bookingsTrend,
    required this.activeListings,
    required this.cancellationRate,
  });

  static const empty = PerformanceStats(
    occupancyRate: 0,
    occupancyTrend: 0,
    totalBookings: 0,
    bookingsTrend: 0,
    activeListings: 0,
    cancellationRate: 0,
  );
}

/// Firebase implementation of Property Performance Repository
class FirebasePropertyPerformanceRepository with FirestoreRepositoryMixin {
  final FirebaseFirestore _firestore;

  FirebasePropertyPerformanceRepository(this._firestore);

  /// Get all owner's property IDs (active only if specified)
  Future<List<String>> _getOwnerPropertyIds(
    String ownerId, {
    bool activeOnly = false,
  }) async {
    var query = _firestore
        .collection('properties')
        .where('owner_id', isEqualTo: ownerId);

    if (activeOnly) {
      query = query.where('is_active', isEqualTo: true);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /// Calculate booked nights from bookings in a date range
  Future<int> _calculateBookedNights({
    required List<String> unitIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (unitIds.isEmpty) return 0;

    int totalBookedNights = 0;

    for (
      int i = 0;
      i < unitIds.length;
      i += FirestoreRepositoryMixin.batchLimit
    ) {
      final batch = unitIds
          .skip(i)
          .take(FirestoreRepositoryMixin.batchLimit)
          .toList();
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('unit_id', whereIn: batch)
          .where('status', whereIn: FirestoreRepositoryMixin.confirmedStatuses)
          .where('check_in', isGreaterThanOrEqualTo: startDate)
          .where('check_in', isLessThanOrEqualTo: endDate)
          .get();

      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final checkIn = (data['check_in'] as Timestamp).toDate();
        final checkOut = (data['check_out'] as Timestamp).toDate();
        totalBookedNights += checkOut.difference(checkIn).inDays;
      }
    }

    return totalBookedNights;
  }

  /// Calculate occupancy rate for a date range
  Future<double> _calculateOccupancyRate({
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final propertyIds = await _getOwnerPropertyIds(ownerId, activeOnly: true);
    if (propertyIds.isEmpty) return 0.0;

    final unitIds = await getUnitIdsForProperties(_firestore, propertyIds);
    if (unitIds.isEmpty) return 0.0;

    final daysInRange = endDate.difference(startDate).inDays + 1;
    final totalAvailableNights = unitIds.length * daysInRange;
    if (totalAvailableNights == 0) return 0.0;

    final bookedNights = await _calculateBookedNights(
      unitIds: unitIds,
      startDate: startDate,
      endDate: endDate,
    );

    return (bookedNights / totalAvailableNights) * 100;
  }

  /// Calculate occupancy rate for owner's properties (current month)
  Future<double> getOccupancyRate(String ownerId) async {
    try {
      final range = getCurrentMonthRange();
      return await _calculateOccupancyRate(
        ownerId: ownerId,
        startDate: range.start,
        endDate: range.end,
      );
    } catch (e) {
      throw AnalyticsException(
        'Failed to calculate occupancy rate',
        code: 'analytics/occupancy-rate-failed',
        originalError: e,
      );
    }
  }

  /// Get occupancy rate for last month
  Future<double> getOccupancyRateLastMonth(String ownerId) async {
    try {
      final range = getLastMonthRange();
      return await _calculateOccupancyRate(
        ownerId: ownerId,
        startDate: range.start,
        endDate: range.end,
      );
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculate occupancy trend (percentage change from last month)
  Future<double> getOccupancyTrend(String ownerId) async {
    try {
      final currentRate = await getOccupancyRate(ownerId);
      final lastMonthRate = await getOccupancyRateLastMonth(ownerId);
      return calculateTrend(currentRate, lastMonthRate);
    } catch (e) {
      return 0.0;
    }
  }

  /// Count bookings with optional date filter
  Future<int> _countBookings({
    required List<String> unitIds,
    DateTime? createdAfter,
    DateTime? createdBefore,
  }) async {
    if (unitIds.isEmpty) return 0;

    int totalCount = 0;

    for (
      int i = 0;
      i < unitIds.length;
      i += FirestoreRepositoryMixin.batchLimit
    ) {
      final batch = unitIds
          .skip(i)
          .take(FirestoreRepositoryMixin.batchLimit)
          .toList();

      Query<Map<String, dynamic>> query = _firestore
          .collection('bookings')
          .where('unit_id', whereIn: batch)
          .where('status', whereIn: FirestoreRepositoryMixin.activeStatuses);

      if (createdAfter != null) {
        query = query.where('created_at', isGreaterThanOrEqualTo: createdAfter);
      }
      if (createdBefore != null) {
        query = query.where('created_at', isLessThanOrEqualTo: createdBefore);
      }

      final snapshot = await query.get();
      totalCount += snapshot.docs.length;
    }

    return totalCount;
  }

  /// Get total bookings count
  Future<int> getTotalBookingsCount(String ownerId) async {
    try {
      final propertyIds = await _getOwnerPropertyIds(ownerId);
      if (propertyIds.isEmpty) return 0;

      final unitIds = await getUnitIdsForProperties(_firestore, propertyIds);
      return await _countBookings(unitIds: unitIds);
    } catch (e) {
      throw AnalyticsException(
        'Failed to get bookings count',
        code: 'analytics/bookings-count-failed',
        originalError: e,
      );
    }
  }

  /// Get bookings count for this month
  Future<int> getBookingsThisMonth(String ownerId) async {
    try {
      final propertyIds = await _getOwnerPropertyIds(ownerId);
      if (propertyIds.isEmpty) return 0;

      final unitIds = await getUnitIdsForProperties(_firestore, propertyIds);
      final range = getCurrentMonthRange();

      return await _countBookings(
        unitIds: unitIds,
        createdAfter: range.start,
        createdBefore: range.end,
      );
    } catch (e) {
      throw AnalyticsException(
        'Failed to get bookings this month',
        code: 'analytics/bookings-this-month-failed',
        originalError: e,
      );
    }
  }

  /// Get bookings count for last month
  Future<int> getBookingsLastMonth(String ownerId) async {
    try {
      final propertyIds = await _getOwnerPropertyIds(ownerId);
      if (propertyIds.isEmpty) return 0;

      final unitIds = await getUnitIdsForProperties(_firestore, propertyIds);
      final range = getLastMonthRange();

      return await _countBookings(
        unitIds: unitIds,
        createdAfter: range.start,
        createdBefore: range.end,
      );
    } catch (e) {
      return 0;
    }
  }

  /// Calculate bookings trend (percentage change from last month)
  Future<double> getBookingsTrend(String ownerId) async {
    try {
      final thisMonth = await getBookingsThisMonth(ownerId);
      final lastMonth = await getBookingsLastMonth(ownerId);
      return calculateTrend(thisMonth.toDouble(), lastMonth.toDouble());
    } catch (e) {
      return 0.0;
    }
  }

  /// Get active listings count (active properties)
  Future<int> getActiveListingsCount(String ownerId) async {
    try {
      final snapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .where('is_active', isEqualTo: true)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw AnalyticsException(
        'Failed to get active listings',
        code: 'analytics/active-listings-failed',
        originalError: e,
      );
    }
  }

  /// Get cancellation rate
  Future<double> getCancellationRate(String ownerId) async {
    try {
      final propertyIds = await _getOwnerPropertyIds(ownerId);
      if (propertyIds.isEmpty) return 0.0;

      final unitIds = await getUnitIdsForProperties(_firestore, propertyIds);
      if (unitIds.isEmpty) return 0.0;

      int totalBookings = 0;
      int cancelledBookings = 0;

      for (
        int i = 0;
        i < unitIds.length;
        i += FirestoreRepositoryMixin.batchLimit
      ) {
        final batch = unitIds
            .skip(i)
            .take(FirestoreRepositoryMixin.batchLimit)
            .toList();

        // All bookings
        final allSnapshot = await _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .get();
        totalBookings += allSnapshot.docs.length;

        // Cancelled bookings
        final cancelledSnapshot = await _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .where('status', isEqualTo: 'cancelled')
            .get();
        cancelledBookings += cancelledSnapshot.docs.length;
      }

      if (totalBookings == 0) return 0.0;
      return (cancelledBookings / totalBookings) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get all performance statistics in parallel
  Future<PerformanceStats> getPerformanceStats(String ownerId) async {
    try {
      // Run independent queries in parallel for better performance
      final results = await Future.wait([
        getOccupancyRate(ownerId),
        getOccupancyTrend(ownerId),
        getTotalBookingsCount(ownerId),
        getBookingsTrend(ownerId),
        getActiveListingsCount(ownerId),
        getCancellationRate(ownerId),
      ]);

      return PerformanceStats(
        occupancyRate: results[0] as double,
        occupancyTrend: results[1] as double,
        totalBookings: results[2] as int,
        bookingsTrend: results[3] as double,
        activeListings: results[4] as int,
        cancellationRate: results[5] as double,
      );
    } catch (e) {
      throw AnalyticsException(
        'Failed to get performance stats',
        code: 'analytics/performance-stats-failed',
        originalError: e,
      );
    }
  }
}
