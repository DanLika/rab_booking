import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../../../shared/providers/repository_providers.dart';

/// Provider for monthly price data for a specific unit
final monthlyPricesProvider =
    FutureProvider.family<Map<DateTime, DailyPriceModel>, MonthlyPricesParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(dailyPriceRepositoryProvider);

      // Get first and last day of month
      final firstDay = DateTime(params.month.year, params.month.month);
      final lastDay = DateTime(params.month.year, params.month.month + 1, 0);

      // Fetch all prices for the month
      final prices = await repository.getPricesForDateRange(
        unitId: params.unitId,
        startDate: firstDay,
        endDate: lastDay,
      );

      // Convert list to map for fast lookups
      final priceMap = <DateTime, DailyPriceModel>{};
      for (final price in prices) {
        final dateKey = DateTime(
          price.date.year,
          price.date.month,
          price.date.day,
        );
        priceMap[dateKey] = price;
      }

      return priceMap;
    });

/// Parameters for monthly prices provider
class MonthlyPricesParams {
  final String unitId;
  final DateTime month;

  const MonthlyPricesParams({required this.unitId, required this.month});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonthlyPricesParams &&
        other.unitId == unitId &&
        other.month.year == month.year &&
        other.month.month == month.month;
  }

  @override
  int get hashCode =>
      unitId.hashCode ^ month.year.hashCode ^ month.month.hashCode;
}
