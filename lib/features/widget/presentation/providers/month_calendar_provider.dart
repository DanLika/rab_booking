import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../domain/models/calendar_date_status.dart';
import '../../domain/services/calendar_data_service.dart';

/// Params record for month calendar data provider with pricing support
typedef MonthCalendarParams = ({
  String unitId,
  DateTime monthStart,
  int minNights,
  double basePrice,
  double? weekendBasePrice,
  List<int>? weekendDays,
});

/// Provider for month calendar data with gap blocking support
/// Now uses CalendarDataService for centralized logic
/// Includes price fallback logic: custom daily_price > weekendBasePrice > basePrice
final monthCalendarDataProvider = FutureProvider.family<Map<String, CalendarDateInfo>, MonthCalendarParams>((
  ref,
  params,
) async {
  final calendarService = ref.watch(calendarDataServiceProvider);

  // Calculate date range for the month
  final startDate = DateTime.utc(params.monthStart.year, params.monthStart.month, 1);
  final endDate = DateTime.utc(params.monthStart.year, params.monthStart.month + 1, 0);

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
