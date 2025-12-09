import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/analytics_summary.dart';
import '../../../../core/exceptions/app_exceptions.dart';

/// Firebase implementation of Analytics Repository
class FirebaseAnalyticsRepository {
  final FirebaseFirestore _firestore;

  FirebaseAnalyticsRepository(this._firestore);

  // ============================================================
  // OPTIMIZED METHOD - Use with pre-cached data from providers
  // ============================================================

  /// OPTIMIZED: Get analytics summary using pre-cached unit IDs and property data
  /// Reduces queries by skipping properties/units fetch
  ///
  /// Parameters:
  /// - [unitIds]: Pre-cached from ownerUnitIdsProvider
  /// - [unitToPropertyId]: Map of unitId -> propertyId
  /// - [properties]: Pre-cached from ownerPropertiesCalendarProvider
  Future<AnalyticsSummary> getAnalyticsSummaryOptimized({
    required List<String> unitIds,
    required Map<String, String> unitToPropertyId,
    required List<Map<String, dynamic>> properties,
    required DateRangeFilter dateRange,
  }) async {
    if (unitIds.isEmpty || properties.isEmpty) {
      return _emptyAnalytics();
    }

    try {
      // Build property cache from pre-fetched data
      final Map<String, Map<String, dynamic>> propertiesDataCache = {
        for (final p in properties) p['id'] as String: p
      };

      // SINGLE COMBINED QUERY: Get ALL bookings (including cancelled) in date range
      final List<Map<String, dynamic>> allBookingsRaw = [];
      for (int i = 0; i < unitIds.length; i += 10) {
        final batch = unitIds.skip(i).take(10).toList();
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('unit_id', whereIn: batch)
            .where('check_in', isGreaterThanOrEqualTo: dateRange.startDate)
            .where('check_in', isLessThanOrEqualTo: dateRange.endDate)
            .get();

        for (final doc in bookingsSnapshot.docs) {
          allBookingsRaw.add({...doc.data(), 'id': doc.id});
        }
      }

      // Separate active and cancelled bookings (no second query needed!)
      final bookings = allBookingsRaw.where((b) => b['status'] != 'cancelled').toList();
      final cancelledBookings = allBookingsRaw.where((b) => b['status'] == 'cancelled').toList();

      // Calculate metrics using the same logic as original method
      return _calculateAnalyticsSummary(
        bookings: bookings,
        cancelledBookings: cancelledBookings,
        unitIds: unitIds,
        unitToPropertyId: unitToPropertyId,
        propertiesDataCache: propertiesDataCache,
        dateRange: dateRange,
      );
    } catch (e) {
      throw AnalyticsException(
        'Failed to fetch analytics',
        code: 'analytics/fetch-failed',
        originalError: e,
      );
    }
  }

  /// Shared calculation logic used by both original and optimized methods
  AnalyticsSummary _calculateAnalyticsSummary({
    required List<Map<String, dynamic>> bookings,
    required List<Map<String, dynamic>> cancelledBookings,
    required List<String> unitIds,
    required Map<String, String> unitToPropertyId,
    required Map<String, Map<String, dynamic>> propertiesDataCache,
    required DateRangeFilter dateRange,
  }) {
    // Calculate metrics
    final totalRevenue = bookings.fold<double>(
      0.0,
      (total, b) => total + ((b['total_price'] as num?)?.toDouble() ?? 0.0),
    );

    final totalBookings = bookings.length;

    // Get monthly bookings (last portion of date range, max 30 days)
    final totalDays = dateRange.endDate.difference(dateRange.startDate).inDays;
    final monthlyPeriodDays = totalDays > 30 ? 30 : totalDays;
    final monthStart = dateRange.endDate.subtract(Duration(days: monthlyPeriodDays));
    final monthlyBookings = bookings.where((b) {
      final checkIn = (b['check_in'] as Timestamp).toDate();
      return checkIn.isAfter(monthStart) && checkIn.isBefore(dateRange.endDate.add(const Duration(days: 1)));
    }).toList();

    final monthlyRevenue = monthlyBookings.fold<double>(
      0.0,
      (total, b) => total + ((b['total_price'] as num?)?.toDouble() ?? 0.0),
    );

    // Calculate widget analytics metrics
    final Map<String, int> bookingsBySource = {};
    int widgetBookings = 0;
    double widgetRevenue = 0.0;

    for (final booking in bookings) {
      final source = booking['source'] as String? ?? 'unknown';
      bookingsBySource[source] = (bookingsBySource[source] ?? 0) + 1;

      if (source == 'widget') {
        widgetBookings++;
        widgetRevenue += (booking['total_price'] as num?)?.toDouble() ?? 0.0;
      }
    }

    // Calculate occupancy rate
    final totalDaysInRange = dateRange.endDate.difference(dateRange.startDate).inDays;
    final bookedDays = bookings.fold<int>(0, (total, b) {
      final checkIn = (b['check_in'] as Timestamp).toDate();
      final checkOut = (b['check_out'] as Timestamp).toDate();
      return total + checkOut.difference(checkIn).inDays;
    });
    final availableDays = totalDaysInRange * unitIds.length;
    final occupancyRate = availableDays > 0 ? (bookedDays / availableDays) * 100 : 0.0;

    // Calculate average nightly rate
    final averageNightlyRate = bookedDays > 0 ? totalRevenue / bookedDays : 0.0;

    // Calculate cancellation rate
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
    final propertyPerformance = _getPropertyPerformanceFromCache(
      bookings,
      unitToPropertyId,
      propertiesDataCache,
      dateRange,
    );

    // Get total and active properties count
    final activeProperties = propertiesDataCache.values
        .where((data) => data['is_active'] == true)
        .length;

    return AnalyticsSummary(
      totalRevenue: totalRevenue,
      monthlyRevenue: monthlyRevenue,
      totalBookings: totalBookings,
      monthlyBookings: monthlyBookings.length,
      occupancyRate: occupancyRate,
      averageNightlyRate: averageNightlyRate,
      totalProperties: propertiesDataCache.length,
      activeProperties: activeProperties,
      cancellationRate: cancellationRate,
      revenueHistory: revenueHistory,
      bookingHistory: bookingHistory,
      topPerformingProperties: propertyPerformance,
      widgetBookings: widgetBookings,
      widgetRevenue: widgetRevenue,
      bookingsBySource: bookingsBySource,
    );
  }

  // ============================================================
  // LEGACY METHOD - Kept for backward compatibility
  // ============================================================

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

      // OPTIMIZATION: Cache property data for reuse in _getPropertyPerformance
      // Eliminates 5 individual property lookups later
      final Map<String, Map<String, dynamic>> propertiesDataCache = {
        for (final doc in propertiesSnapshot.docs) doc.id: {...doc.data(), 'id': doc.id}
      };

      // OPTIMIZATION: Fetch units in PARALLEL instead of sequential loop
      // Saves ~(N-1) round trips where N = number of properties
      final unitsFutures = propertyIds.map((propertyId) async {
        final unitsSnapshot = await _firestore
            .collection('properties')
            .doc(propertyId)
            .collection('units')
            .get();
        return unitsSnapshot.docs.map((doc) => MapEntry(doc.id, propertyId)).toList();
      });

      final unitsResults = await Future.wait(unitsFutures);

      final List<String> unitIds = [];
      final Map<String, String> unitToPropertyMap = {}; // Cache for optimization
      for (final unitEntries in unitsResults) {
        for (final entry in unitEntries) {
          unitIds.add(entry.key);
          unitToPropertyMap[entry.key] = entry.value; // Map unitId -> propertyId
        }
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

      // Get monthly bookings (last portion of date range, max 30 days)
      final totalDays = dateRange.endDate.difference(dateRange.startDate).inDays;
      final monthlyPeriodDays = totalDays > 30 ? 30 : totalDays;
      final monthStart = dateRange.endDate.subtract(Duration(days: monthlyPeriodDays));
      final monthlyBookings = bookings.where((b) {
        final checkIn = (b['check_in'] as Timestamp).toDate();
        return checkIn.isAfter(monthStart) && checkIn.isBefore(dateRange.endDate.add(const Duration(days: 1)));
      }).toList();

      final monthlyRevenue = monthlyBookings.fold<double>(
        0.0,
        (total, b) => total + ((b['total_price'] as num?)?.toDouble() ?? 0.0),
      );

      // Calculate widget analytics metrics
      final Map<String, int> bookingsBySource = {};
      int widgetBookings = 0;
      double widgetRevenue = 0.0;

      for (final booking in bookings) {
        final source = booking['source'] as String? ?? 'unknown';
        bookingsBySource[source] = (bookingsBySource[source] ?? 0) + 1;

        if (source == 'widget') {
          widgetBookings++;
          widgetRevenue += (booking['total_price'] as num?)?.toDouble() ?? 0.0;
        }
      }

      // Calculate occupancy rate
      final totalDaysInRange = dateRange.endDate
          .difference(dateRange.startDate)
          .inDays;
      final bookedDays = bookings.fold<int>(0, (total, b) {
        final checkIn = (b['check_in'] as Timestamp).toDate();
        final checkOut = (b['check_out'] as Timestamp).toDate();
        return total + checkOut.difference(checkIn).inDays;
      });
      final availableDays = totalDaysInRange * unitIds.length;
      final occupancyRate = availableDays > 0
          ? (bookedDays / availableDays) * 100
          : 0.0;

      // Calculate average nightly rate
      final averageNightlyRate = bookedDays > 0
          ? totalRevenue / bookedDays
          : 0.0;

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

        cancelledBookings.addAll(
          cancelledSnapshot.docs.map((doc) => doc.data()),
        );
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
      // OPTIMIZATION: Pass already-fetched bookings and property data to avoid duplicate queries
      final propertyPerformance = _getPropertyPerformanceFromCache(
        bookings,
        unitToPropertyMap,
        propertiesDataCache,
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
        // Widget Analytics
        widgetBookings: widgetBookings,
        widgetRevenue: widgetRevenue,
        bookingsBySource: bookingsBySource,
      );
    } catch (e) {
      throw AnalyticsException(
        'Failed to fetch analytics',
        code: 'analytics/fetch-failed',
        originalError: e,
      );
    }
  }

  List<RevenueDataPoint> _generateRevenueHistory(
    List<Map<String, dynamic>> bookings,
    DateRangeFilter dateRange,
  ) {
    final Map<String, double> monthlyRevenue = {};

    for (final booking in bookings) {
      final checkIn = (booking['check_in'] as Timestamp).toDate();
      final monthKey =
          '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}';
      final revenue = (booking['total_price'] as num?)?.toDouble() ?? 0.0;

      monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0.0) + revenue;
    }

    final dataPoints = monthlyRevenue.entries.map((entry) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month);

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
      final monthKey =
          '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}';

      monthlyBookings[monthKey] = (monthlyBookings[monthKey] ?? 0) + 1;
    }

    final dataPoints = monthlyBookings.entries.map((entry) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month);

      return BookingDataPoint(
        date: date,
        count: entry.value,
        label: _getMonthLabel(month),
      );
    }).toList();

    dataPoints.sort((a, b) => a.date.compareTo(b.date));

    return dataPoints;
  }

  /// OPTIMIZED: Uses pre-fetched bookings and cached property data
  /// Eliminates ~5 property lookups + duplicate bookings query
  /// Saves ~6-10 Firestore queries per invocation
  List<PropertyPerformance> _getPropertyPerformanceFromCache(
    List<Map<String, dynamic>> allBookings,
    Map<String, String> unitToPropertyMap,
    Map<String, Map<String, dynamic>> propertiesDataCache,
    DateRangeFilter dateRange,
  ) {
    final List<PropertyPerformance> performances = [];

    // Group already-fetched bookings by property (no query needed!)
    final Map<String, List<Map<String, dynamic>>> bookingsByProperty = {};

    for (final booking in allBookings) {
      final unitId = booking['unit_id'] as String;
      final propertyId = unitToPropertyMap[unitId];
      if (propertyId == null) continue;

      if (!bookingsByProperty.containsKey(propertyId)) {
        bookingsByProperty[propertyId] = [];
      }
      bookingsByProperty[propertyId]!.add(booking);
    }

    // Calculate performance for each property using cached data
    for (final entry in bookingsByProperty.entries) {
      final propertyId = entry.key;
      final bookings = entry.value;

      if (bookings.isEmpty) continue;

      // Use cached property data (no query needed!)
      final propertyData = propertiesDataCache[propertyId];
      if (propertyData == null) continue;

      final revenue = bookings.fold<double>(
        0.0,
        (total, b) => total + ((b['total_price'] as num?)?.toDouble() ?? 0.0),
      );

      final bookedDays = bookings.fold<int>(0, (total, b) {
        final checkIn = (b['check_in'] as Timestamp).toDate();
        final checkOut = (b['check_out'] as Timestamp).toDate();
        return total + checkOut.difference(checkIn).inDays;
      });

      final totalDays = dateRange.endDate
          .difference(dateRange.startDate)
          .inDays;
      final occupancyRate = totalDays > 0
          ? (bookedDays / totalDays) * 100
          : 0.0;

      // Get rating from cached data
      final avgRating = (propertyData['rating'] as num?)?.toDouble() ?? 0.0;

      performances.add(
        PropertyPerformance(
          propertyId: propertyId,
          propertyName: propertyData['name'] as String,
          revenue: revenue,
          bookings: bookings.length,
          occupancyRate: occupancyRate,
          rating: avgRating,
        ),
      );
    }

    // Sort by revenue (descending) and take top 5
    performances.sort((a, b) => b.revenue.compareTo(a.revenue));
    return performances.take(5).toList();
  }

  String _getMonthLabel(int month) {
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
      // Widget Analytics
      widgetBookings: 0,
      widgetRevenue: 0.0,
      bookingsBySource: {},
    );
  }
}
