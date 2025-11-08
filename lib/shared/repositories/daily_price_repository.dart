import '../models/daily_price_model.dart';

/// Abstract daily price repository interface
abstract class DailyPriceRepository {
  /// Get price for specific date
  Future<double?> getPriceForDate({
    required String unitId,
    required DateTime date,
  });

  /// Get prices for date range
  Future<List<DailyPriceModel>> getPricesForDateRange({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Calculate total booking price for date range
  Future<double> calculateBookingPrice({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    double? fallbackPrice,
  });

  /// Set price for specific date
  /// If priceModel is provided, all its fields will be saved
  /// Otherwise, only basic price will be set
  Future<DailyPriceModel> setPriceForDate({
    required String unitId,
    required DateTime date,
    required double price,
    DailyPriceModel? priceModel,
  });

  /// Bulk update prices for date range
  Future<List<DailyPriceModel>> bulkUpdatePrices({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
    required double price,
  });

  /// Bulk update prices with full model template
  Future<List<DailyPriceModel>> bulkUpdatePricesWithModel({
    required String unitId,
    required List<DateTime> dates,
    required DailyPriceModel modelTemplate,
  });

  /// Delete price for specific date (revert to base price)
  Future<void> deletePriceForDate({
    required String unitId,
    required DateTime date,
  });

  /// Delete prices for date range
  Future<void> deletePricesForDateRange({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get all custom prices for unit
  Future<List<DailyPriceModel>> fetchAllPricesForUnit(String unitId);

  /// Check if date has custom price
  Future<bool> hasCustomPrice({
    required String unitId,
    required DateTime date,
  });
}
