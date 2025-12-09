import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/analytics_summary.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import 'owner_bookings_provider.dart';
import 'owner_calendar_provider.dart';

part 'analytics_provider.g.dart';

/// OPTIMIZED: Analytics provider using cached unit IDs and properties
/// - Reuses ownerUnitIdsProvider (keepAlive: true)
/// - Reuses ownerPropertiesCalendarProvider (keepAlive: true)
/// - Combines active + cancelled bookings query
/// - keepAlive: true to cache results during session
@Riverpod(keepAlive: true)
class AnalyticsNotifier extends _$AnalyticsNotifier {
  @override
  Future<AnalyticsSummary> build({required DateRangeFilter dateRange}) async {
    final auth = FirebaseAuth.instance;
    final userId = auth.currentUser?.uid;

    if (userId == null) {
      throw AuthException('User not authenticated', code: 'auth/not-authenticated');
    }

    final repository = ref.watch(analyticsRepositoryProvider);

    // OPTIMIZED: Get cached data from existing providers
    final unitIds = await ref.watch(ownerUnitIdsProvider.future);
    final properties = await ref.watch(ownerPropertiesCalendarProvider.future);
    final units = await ref.watch(allOwnerUnitsProvider.future);

    if (unitIds.isEmpty || properties.isEmpty) {
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
        widgetBookings: 0,
        widgetRevenue: 0.0,
        bookingsBySource: {},
      );
    }

    // Build unitId -> propertyId map from cached units
    final unitToPropertyId = <String, String>{
      for (final unit in units) unit.id: unit.propertyId,
    };

    // Convert PropertyModel to Map for repository
    final propertiesData = properties.map((p) => {
      'id': p.id,
      'name': p.name,
      'is_active': p.isActive,
      'rating': p.rating,
    }).toList();

    // Use optimized method with cached data
    return repository.getAnalyticsSummaryOptimized(
      unitIds: unitIds,
      unitToPropertyId: unitToPropertyId,
      properties: propertiesData,
      dateRange: dateRange,
    );
  }

  Future<void> refresh() async {
    // Invalidate cached providers to force fresh data
    ref.invalidate(ownerUnitIdsProvider);
    ref.invalidate(ownerPropertiesCalendarProvider);
    ref.invalidate(allOwnerUnitsProvider);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final auth = FirebaseAuth.instance;
      final userId = auth.currentUser?.uid;

      if (userId == null) {
        throw AuthException('User not authenticated', code: 'auth/not-authenticated');
      }

      final repository = ref.read(analyticsRepositoryProvider);

      // Re-fetch all data
      final unitIds = await ref.read(ownerUnitIdsProvider.future);
      final properties = await ref.read(ownerPropertiesCalendarProvider.future);
      final units = await ref.read(allOwnerUnitsProvider.future);

      if (unitIds.isEmpty || properties.isEmpty) {
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
          widgetBookings: 0,
          widgetRevenue: 0.0,
          bookingsBySource: {},
        );
      }

      final unitToPropertyId = <String, String>{
        for (final unit in units) unit.id: unit.propertyId,
      };

      final propertiesData = properties.map((p) => {
        'id': p.id,
        'name': p.name,
        'is_active': p.isActive,
        'rating': p.rating,
      }).toList();

      return repository.getAnalyticsSummaryOptimized(
        unitIds: unitIds,
        unitToPropertyId: unitToPropertyId,
        properties: propertiesData,
        dateRange: dateRange,
      );
    });
  }
}

@riverpod
class DateRangeNotifier extends _$DateRangeNotifier {
  @override
  DateRangeFilter build() {
    return DateRangeFilter.lastMonth();
  }

  void setDateRange(DateRangeFilter newRange) {
    state = newRange;
  }

  void setPreset(String preset) {
    switch (preset) {
      case 'week':
        state = DateRangeFilter.lastWeek();
        break;
      case 'month':
        state = DateRangeFilter.lastMonth();
        break;
      case 'quarter':
        state = DateRangeFilter.lastQuarter();
        break;
      case 'year':
        state = DateRangeFilter.lastYear();
        break;
      default:
        state = DateRangeFilter.lastMonth();
    }
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = DateRangeFilter(startDate: start, endDate: end);
  }
}
