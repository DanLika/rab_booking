import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/analytics_summary.dart';

/// Firebase implementation of Analytics Repository
class FirebaseAnalyticsRepository {
  final FirebaseFirestore _firestore;

  FirebaseAnalyticsRepository(this._firestore);

  Future<AnalyticsSummary> getAnalyticsSummary({
    required String ownerId,
    required DateRangeFilter dateRange,
  }) async {
    try {
      // Get all owner's properties
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .get();

      final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();

      if (propertyIds.isEmpty) {
        return _emptyAnalytics();
      }

      // Get all units for these properties from subcollections
      final List<String> unitIds = [];
      for (final propertyId in propertyIds) {
        final unitsSnapshot = await _firestore
            .collection('properties')
            .doc(propertyId)
            .collection('units')
            .get();
        unitIds.addAll(unitsSnapshot.docs.map((doc) => doc.id));
      }

      if (unitIds.isEmpty) {
        return _emptyAnalytics();
      }

      // Get bookings within date range (in batches)
      final List<Map<String, dynamic>> bookings = [];
      for (int i = 0; i < unitIds.length; i += 10) {
        final batch = unitIds.skip(i).take(10).toList();
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .where('check_in', isGreaterThanOrEqualTo: dateRange.startDate)
            .where('check_in', isLessThanOrEqualTo: dateRange.endDate)
            .get();

        for (final doc in bookingsSnapshot.docs) {
          final data = doc.data();
          if (data['status'] != 'cancelled') {
            bookings.add({...data, 'id': doc.id});
          }
        }
      }

      // Calculate metrics
      final totalRevenue = bookings.fold<double>(
        0.0,
        (total, b) => total + ((b['total_price'] as num?)?.toDouble() ?? 0.0),
      );

      final totalBookings = bookings.length;

      // Get monthly bookings (last 30 days)
      final monthStart = DateTime.now().subtract(const Duration(days: 30));
      final monthlyBookings = bookings.where((b) {
        final checkIn = (b['check_in'] as Timestamp).toDate();
        return checkIn.isAfter(monthStart);
      }).toList();

      final monthlyRevenue = monthlyBookings.fold<double>(
        0.0,
        (total, b) => total + ((b['total_price'] as num?)?.toDouble() ?? 0.0),
      );

      // Calculate occupancy rate
      final totalDaysInRange = dateRange.endDate.difference(dateRange.startDate).inDays;
      final bookedDays = bookings.fold<int>(
        0,
        (total, b) {
          final checkIn = (b['check_in'] as Timestamp).toDate();
          final checkOut = (b['check_out'] as Timestamp).toDate();
          return total + checkOut.difference(checkIn).inDays;
        },
      );
      final availableDays = totalDaysInRange * unitIds.length;
      final occupancyRate = availableDays > 0 ? (bookedDays / availableDays) * 100 : 0.0;

      // Calculate average nightly rate
      final averageNightlyRate = bookedDays > 0 ? totalRevenue / bookedDays : 0.0;

      // Get cancelled bookings for cancellation rate
      final List<Map<String, dynamic>> cancelledBookings = [];
      for (int i = 0; i < unitIds.length; i += 10) {
        final batch = unitIds.skip(i).take(10).toList();
        final cancelledSnapshot = await _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .where('check_in', isGreaterThanOrEqualTo: dateRange.startDate)
            .where('check_in', isLessThanOrEqualTo: dateRange.endDate)
            .where('status', isEqualTo: 'cancelled')
            .get();

        cancelledBookings.addAll(cancelledSnapshot.docs.map((doc) => doc.data()));
      }

      final cancelledCount = cancelledBookings.length;
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
        unitIds,
        dateRange,
      );

      // Get total and active properties count
      final activeProperties = propertiesSnapshot.docs
          .where((doc) => doc.data()['is_active'] == true)
          .length;

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
    List<Map<String, dynamic>> bookings,
    DateRangeFilter dateRange,
  ) {
    final Map<String, double> monthlyRevenue = {};

    for (final booking in bookings) {
      final checkIn = (booking['check_in'] as Timestamp).toDate();
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
    List<Map<String, dynamic>> bookings,
    DateRangeFilter dateRange,
  ) {
    final Map<String, int> monthlyBookings = {};

    for (final booking in bookings) {
      final checkIn = (booking['check_in'] as Timestamp).toDate();
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
    List<String> unitIds,
    DateRangeFilter dateRange,
  ) async {
    final List<PropertyPerformance> performances = [];

    // Create a map of unitId -> propertyId
    final Map<String, String> unitToPropertyMap = {};
    for (final propertyId in propertyIds) {
      final unitsSnapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .get();

      for (final doc in unitsSnapshot.docs) {
        unitToPropertyMap[doc.id] = propertyId;
      }
    }

    // Get bookings grouped by property
    final Map<String, List<Map<String, dynamic>>> bookingsByProperty = {};

    for (int i = 0; i < unitIds.length; i += 10) {
      final batch = unitIds.skip(i).take(10).toList();
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('unit_id', whereIn: batch)
          .where('check_in', isGreaterThanOrEqualTo: dateRange.startDate)
          .where('check_in', isLessThanOrEqualTo: dateRange.endDate)
          .get();

      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'cancelled') continue;

        final unitId = data['unit_id'] as String;
        final propertyId = unitToPropertyMap[unitId];
        if (propertyId == null) continue;

        if (!bookingsByProperty.containsKey(propertyId)) {
          bookingsByProperty[propertyId] = [];
        }
        bookingsByProperty[propertyId]!.add(data);
      }
    }

    // Calculate performance for each property
    for (final entry in bookingsByProperty.entries) {
      final propertyId = entry.key;
      final bookings = entry.value;

      if (bookings.isEmpty) continue;

      // Get property details
      final propertyDoc = await _firestore.collection('properties').doc(propertyId).get();
      if (!propertyDoc.exists) continue;

      final propertyData = propertyDoc.data()!;

      final revenue = bookings.fold<double>(
        0.0,
        (total, b) => total + ((b['total_price'] as num?)?.toDouble() ?? 0.0),
      );

      final bookedDays = bookings.fold<int>(
        0,
        (total, b) {
          final checkIn = (b['check_in'] as Timestamp).toDate();
          final checkOut = (b['check_out'] as Timestamp).toDate();
          return total + checkOut.difference(checkIn).inDays;
        },
      );

      final totalDays = dateRange.endDate.difference(dateRange.startDate).inDays;
      final occupancyRate = totalDays > 0 ? (bookedDays / totalDays) * 100 : 0.0;

      // Get rating
      final avgRating = (propertyData['rating'] as num?)?.toDouble() ?? 0.0;

      performances.add(PropertyPerformance(
        propertyId: propertyId,
        propertyName: propertyData['name'] as String,
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
