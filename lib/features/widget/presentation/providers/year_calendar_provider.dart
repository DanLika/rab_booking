import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../domain/models/calendar_date_status.dart';
import '../../domain/services/calendar_data_service.dart';

/// Params record for year calendar data provider with pricing support
typedef YearCalendarParams = ({
  String unitId,
  int year,
  int minNights,
  double basePrice,
  double? weekendBasePrice,
  List<int>? weekendDays,
});

/// Provider for year calendar data with gap blocking support
/// Now uses CalendarDataService for centralized logic
/// Includes price fallback logic: custom daily_price > weekendBasePrice > basePrice
final yearCalendarDataProvider = FutureProvider.family<Map<String, CalendarDateInfo>, YearCalendarParams>((
  ref,
  params,
) async {
  final calendarService = ref.watch(calendarDataServiceProvider);

  // Calculate date range for the year (with extended range for gap detection)
  final startDate = DateTime.utc(params.year, 1, 1);
  final endDate = DateTime.utc(params.year, 12, 31);

  // Load calendar data using the service
  final calendarData = await calendarService.loadCalendarData(
    CalendarDataParams(
      unitId: params.unitId,
      startDate: startDate,
      endDate: endDate,
      minNights: params.minNights,
      basePrice: params.basePrice,
      weekendBasePrice: params.weekendBasePrice,
      weekendDays: params.weekendDays,
    ),
  );

  return calendarData;
});
