import 'package:flutter/foundation.dart';
import '../../../../shared/models/daily_price_model.dart';

/// Local state cache for calendar prices with optimistic updates
class PriceCalendarState extends ChangeNotifier {
  // Cache of monthly prices: Map<Month, Map<Date, Price>>
  final Map<DateTime, Map<DateTime, DailyPriceModel>> _priceCache = {};

  // Get prices for a specific month
  Map<DateTime, DailyPriceModel>? getMonthPrices(DateTime month) {
    final monthKey = DateTime(month.year, month.month);
    return _priceCache[monthKey];
  }

  // Set entire month data (from server)
  void setMonthPrices(DateTime month, Map<DateTime, DailyPriceModel> prices) {
    final monthKey = DateTime(month.year, month.month);
    _priceCache[monthKey] = Map.from(prices);
    notifyListeners();
  }

  // Optimistically update a single date
  void updateDateOptimistically(DateTime month, DateTime date, DailyPriceModel? newPrice, DailyPriceModel? oldPrice) {
    final monthKey = DateTime(month.year, month.month);
    final dateKey = DateTime(date.year, date.month, date.day);

    _priceCache[monthKey] ??= {};

    if (newPrice != null) {
      _priceCache[monthKey]![dateKey] = newPrice;
    } else {
      _priceCache[monthKey]!.remove(dateKey);
    }

    notifyListeners();
  }

  // Optimistically update multiple dates
  void updateDatesOptimistically(
    DateTime month,
    List<DateTime> dates,
    Map<DateTime, DailyPriceModel> oldPrices,
    Map<DateTime, DailyPriceModel> newPrices,
  ) {
    final monthKey = DateTime(month.year, month.month);
    _priceCache[monthKey] ??= {};

    for (final date in dates) {
      final dateKey = DateTime(date.year, date.month, date.day);
      if (newPrices.containsKey(dateKey)) {
        _priceCache[monthKey]![dateKey] = newPrices[dateKey]!;
      }
    }

    notifyListeners();
  }

  // BUG-012 FIX: Rollback optimistic update on error
  // Changed parameter type to allow null values for deleted prices
  void rollbackUpdate(DateTime month, Map<DateTime, DailyPriceModel?> oldPrices) {
    final monthKey = DateTime(month.year, month.month);
    _priceCache[monthKey] ??= {};

    for (final entry in oldPrices.entries) {
      if (entry.value != null) {
        // Restore the old price
        _priceCache[monthKey]![entry.key] = entry.value!;
      } else {
        // Price was deleted before, so remove it from cache
        _priceCache[monthKey]!.remove(entry.key);
      }
    }

    notifyListeners();
  }

  // Clear cache for a specific month (force refresh)
  void invalidateMonth(DateTime month) {
    final monthKey = DateTime(month.year, month.month);
    _priceCache.remove(monthKey);
    notifyListeners();
  }

  // Clear entire cache
  void clearCache() {
    _priceCache.clear();
    notifyListeners();
  }
}
