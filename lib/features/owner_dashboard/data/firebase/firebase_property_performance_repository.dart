import 'package:cloud_firestore/cloud_firestore.dart';

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

/// Firebase implementation of Property Performance Repository
class FirebasePropertyPerformanceRepository {
  final FirebaseFirestore _firestore;

  FirebasePropertyPerformanceRepository(this._firestore);

  /// Helper method to get all unit IDs for given properties from subcollections
  Future<List<String>> _getUnitIdsForProperties(List<String> propertyIds) async {
    List<String> unitIds = [];
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

  /// Calculate occupancy rate for owner's properties
  /// Returns percentage of booked nights vs available nights
  Future<double> getOccupancyRate(String ownerId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Get all owner's active properties
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .where('is_active', isEqualTo: true)
          .get();

      if (propertiesSnapshot.docs.isEmpty) return 0.0;

      final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();

      // Get all units for these properties from subcollections
      final unitIds = await _getUnitIdsForProperties(propertyIds);
      final totalUnits = unitIds.length;

      if (totalUnits == 0) return 0.0;

      // Calculate total available nights (units * days in month)
      final daysInMonth = endOfMonth.day;
      final totalAvailableNights = totalUnits * daysInMonth;

      // Get all bookings for this month
      int totalBookedNights = 0;

      for (int i = 0; i < unitIds.length; i += 10) {
        final batch = unitIds.skip(i).take(10).toList();
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .where('status', whereIn: ['confirmed', 'completed'])
            .where('check_in', isGreaterThanOrEqualTo: startOfMonth)
            .where('check_in', isLessThanOrEqualTo: endOfMonth)
            .get();

        for (final doc in bookingsSnapshot.docs) {
          final data = doc.data();
          final checkIn = (data['check_in'] as Timestamp).toDate();
          final checkOut = (data['check_out'] as Timestamp).toDate();
          final nights = checkOut.difference(checkIn).inDays;
          totalBookedNights += nights;
        }
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

      // Get all owner's active properties
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .where('is_active', isEqualTo: true)
          .get();

      if (propertiesSnapshot.docs.isEmpty) return 0.0;

      final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();

      // Get all units for these properties from subcollections
      final unitIds = await _getUnitIdsForProperties(propertyIds);
      final totalUnits = unitIds.length;

      if (totalUnits == 0) return 0.0;

      // Calculate total available nights
      final daysInMonth = endOfLastMonth.day;
      final totalAvailableNights = totalUnits * daysInMonth;

      // Get all bookings for last month
      int totalBookedNights = 0;

      for (int i = 0; i < unitIds.length; i += 10) {
        final batch = unitIds.skip(i).take(10).toList();
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .where('status', whereIn: ['confirmed', 'completed'])
            .where('check_in', isGreaterThanOrEqualTo: startOfLastMonth)
            .where('check_in', isLessThanOrEqualTo: endOfLastMonth)
            .get();

        for (final doc in bookingsSnapshot.docs) {
          final data = doc.data();
          final checkIn = (data['check_in'] as Timestamp).toDate();
          final checkOut = (data['check_out'] as Timestamp).toDate();
          final nights = checkOut.difference(checkIn).inDays;
          totalBookedNights += nights;
        }
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
      // Get all owner's properties
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .get();

      if (propertiesSnapshot.docs.isEmpty) return 0;

      final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();

      // Get all units for these properties from subcollections
      final unitIds = await _getUnitIdsForProperties(propertyIds);

      if (unitIds.isEmpty) return 0;

      // Count all bookings
      int totalCount = 0;

      for (int i = 0; i < unitIds.length; i += 10) {
        final batch = unitIds.skip(i).take(10).toList();
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .where('status', whereIn: ['confirmed', 'completed', 'pending'])
            .get();

        totalCount += bookingsSnapshot.docs.length;
      }

      return totalCount;
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

      // Get all owner's properties
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .get();

      if (propertiesSnapshot.docs.isEmpty) return 0;

      final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();

      // Get all units for these properties from subcollections
      final unitIds = await _getUnitIdsForProperties(propertyIds);

      if (unitIds.isEmpty) return 0;

      // Count bookings for this month
      int totalCount = 0;

      for (int i = 0; i < unitIds.length; i += 10) {
        final batch = unitIds.skip(i).take(10).toList();
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .where('status', whereIn: ['confirmed', 'completed', 'pending'])
            .where('created_at', isGreaterThanOrEqualTo: startOfMonth)
            .where('created_at', isLessThanOrEqualTo: endOfMonth)
            .get();

        totalCount += bookingsSnapshot.docs.length;
      }

      return totalCount;
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

      // Get all owner's properties
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .get();

      if (propertiesSnapshot.docs.isEmpty) return 0;

      final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();

      // Get all units for these properties from subcollections
      final unitIds = await _getUnitIdsForProperties(propertyIds);

      if (unitIds.isEmpty) return 0;

      // Count bookings for last month
      int totalCount = 0;

      for (int i = 0; i < unitIds.length; i += 10) {
        final batch = unitIds.skip(i).take(10).toList();
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .where('status', whereIn: ['confirmed', 'completed', 'pending'])
            .where('created_at', isGreaterThanOrEqualTo: startOfLastMonth)
            .where('created_at', isLessThanOrEqualTo: endOfLastMonth)
            .get();

        totalCount += bookingsSnapshot.docs.length;
      }

      return totalCount;
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
      final snapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .where('is_active', isEqualTo: true)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get active listings: $e');
    }
  }

  /// Get cancellation rate
  Future<double> getCancellationRate(String ownerId) async {
    try {
      // Get all owner's properties
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .get();

      if (propertiesSnapshot.docs.isEmpty) return 0.0;

      final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();

      // Get all units for these properties from subcollections
      final unitIds = await _getUnitIdsForProperties(propertyIds);

      if (unitIds.isEmpty) return 0.0;

      // Get all bookings count
      int totalBookings = 0;
      int cancelledBookings = 0;

      for (int i = 0; i < unitIds.length; i += 10) {
        final batch = unitIds.skip(i).take(10).toList();

        // All bookings
        final allBookingsSnapshot = await _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .get();

        totalBookings += allBookingsSnapshot.docs.length;

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
