import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/analytics_repository.dart';
import '../../domain/models/analytics_summary.dart';
import '../../../../core/providers/auth_state_provider.dart';

part 'analytics_provider.g.dart';

@riverpod
class AnalyticsNotifier extends _$AnalyticsNotifier {
  @override
  Future<AnalyticsSummary> build({
    required DateRangeFilter dateRange,
  }) async {
    // Fixed: Use authStateNotifierProvider and .user instead of authStateProvider and .valueOrNull
    final user = ref.watch(authStateNotifierProvider).user;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    final repository = ref.watch(analyticsRepositoryProvider);
    return repository.getAnalyticsSummary(
      ownerId: user.id,
      dateRange: dateRange,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Fixed: Use authStateNotifierProvider and .user instead of authStateProvider and .valueOrNull
      final user = ref.read(authStateNotifierProvider).user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final repository = ref.read(analyticsRepositoryProvider);
      return repository.getAnalyticsSummary(
        ownerId: user.id,
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
    state = DateRangeFilter(
      startDate: start,
      endDate: end,
      preset: 'custom',
    );
  }
}
