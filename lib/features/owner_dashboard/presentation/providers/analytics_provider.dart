import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/analytics_summary.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/exceptions/app_exceptions.dart';

part 'analytics_provider.g.dart';

@riverpod
class AnalyticsNotifier extends _$AnalyticsNotifier {
  @override
  Future<AnalyticsSummary> build({required DateRangeFilter dateRange}) async {
    final auth = FirebaseAuth.instance;
    final userId = auth.currentUser?.uid;

    if (userId == null) {
      throw AuthException('User not authenticated', code: 'auth/not-authenticated');
    }

    final repository = ref.watch(analyticsRepositoryProvider);
    return repository.getAnalyticsSummary(
      ownerId: userId,
      dateRange: dateRange,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final auth = FirebaseAuth.instance;
      final userId = auth.currentUser?.uid;

      if (userId == null) {
        throw AuthException('User not authenticated', code: 'auth/not-authenticated');
      }

      final repository = ref.read(analyticsRepositoryProvider);
      return repository.getAnalyticsSummary(
        ownerId: userId,
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
