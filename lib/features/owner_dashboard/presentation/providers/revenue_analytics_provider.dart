import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/auth_state_provider.dart';
import '../../data/revenue_analytics_repository.dart';
import '../widgets/revenue_chart_widget.dart';

part 'revenue_analytics_provider.g.dart';

/// Get revenue data for last 7 days
@riverpod
Future<List<RevenueDataPoint>> revenueWeekly(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final repository = ref.watch(revenueAnalyticsRepositoryProvider);
  return repository.getRevenueByDays(userId, 7);
}

/// Get revenue data for last 30 days
@riverpod
Future<List<RevenueDataPoint>> revenueMonthly(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final repository = ref.watch(revenueAnalyticsRepositoryProvider);
  return repository.getRevenueByDays(userId, 30);
}

/// Get total revenue
@riverpod
Future<double> totalRevenue(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0.0;

  final repository = ref.watch(revenueAnalyticsRepositoryProvider);
  return repository.getTotalRevenue(userId);
}

/// Get revenue this month
@riverpod
Future<double> revenueThisMonth(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0.0;

  final repository = ref.watch(revenueAnalyticsRepositoryProvider);
  return repository.getRevenueThisMonth(userId);
}

/// Get revenue trend (percentage change)
@riverpod
Future<double> revenueTrend(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0.0;

  final repository = ref.watch(revenueAnalyticsRepositoryProvider);
  return repository.getRevenueTrend(userId);
}

/// Get revenue by property
@riverpod
Future<Map<String, double>> revenueByProperty(
  Ref ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return {};

  final repository = ref.watch(revenueAnalyticsRepositoryProvider);
  return repository.getRevenueByProperty(userId);
}

/// Get complete revenue stats
@riverpod
Future<RevenueStats> revenueStats(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return RevenueStats(
      totalRevenue: 0.0,
      thisMonthRevenue: 0.0,
      trend: 0.0,
      revenueByProperty: {},
    );
  }

  final repository = ref.watch(revenueAnalyticsRepositoryProvider);
  return repository.getRevenueStats(userId);
}
