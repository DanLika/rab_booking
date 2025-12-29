// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dashboardDateRangeNotifierHash() =>
    r'f1bd705280e67a42df18e6a509c3ecd1a15c9cf3';

/// Date range notifier for Dashboard time period selection
/// Default: Last 7 days (rolling window)
///
/// Copied from [DashboardDateRangeNotifier].
@ProviderFor(DashboardDateRangeNotifier)
final dashboardDateRangeNotifierProvider =
    AutoDisposeNotifierProvider<
      DashboardDateRangeNotifier,
      DateRangeFilter
    >.internal(
      DashboardDateRangeNotifier.new,
      name: r'dashboardDateRangeNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$dashboardDateRangeNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DashboardDateRangeNotifier = AutoDisposeNotifier<DateRangeFilter>;
String _$unifiedDashboardNotifierHash() =>
    r'87ba48d783da106cb34612807eb9b3f08261286d';

/// UNIFIED Dashboard Provider
/// Combines metrics calculation + chart data in one provider
/// Uses check_in date for filtering (consistent across all metrics)
///
/// Copied from [UnifiedDashboardNotifier].
@ProviderFor(UnifiedDashboardNotifier)
final unifiedDashboardNotifierProvider =
    AsyncNotifierProvider<
      UnifiedDashboardNotifier,
      UnifiedDashboardData
    >.internal(
      UnifiedDashboardNotifier.new,
      name: r'unifiedDashboardNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$unifiedDashboardNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UnifiedDashboardNotifier = AsyncNotifier<UnifiedDashboardData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
