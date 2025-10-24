import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/calendar_grid_repository.dart';
import '../../domain/models/calendar_day.dart';

/// Provider za Calendar Grid Repository
final calendarGridRepositoryProvider = Provider<CalendarGridRepository>((ref) {
  return CalendarGridRepository(Supabase.instance.client);
});

/// Provider za dohvatanje kalendar podataka (jednog mjeseca)
final calendarDataProvider = FutureProvider.family<List<CalendarDay>,
    CalendarDataParams>((ref, params) async {
  final repository = ref.watch(calendarGridRepositoryProvider);
  return repository.getCalendarData(params.unitId, params.month);
});

/// Stream provider za real-time kalendar updates
final calendarStreamProvider = StreamProvider.family<List<CalendarDay>,
    CalendarDataParams>((ref, params) {
  final repository = ref.watch(calendarGridRepositoryProvider);
  return repository.watchCalendarData(params.unitId, params.month);
});

/// Provider za godišnji kalendar (12 mjeseci)
final yearlyCalendarProvider = FutureProvider.family<
    Map<int, List<CalendarDay>>, YearlyCalendarParams>((ref, params) async {
  final repository = ref.watch(calendarGridRepositoryProvider);
  return repository.getYearlyCalendarData(params.unitId, params.year);
});

/// State Notifier za upravljanje calendar state-om
class CalendarGridNotifier
    extends StateNotifier<AsyncValue<List<CalendarDay>>> {
  final CalendarGridRepository _repository;
  final String unitId;
  DateTime _currentMonth;

  CalendarGridNotifier(
    this._repository,
    this.unitId,
    DateTime initialMonth,
  )   : _currentMonth = DateTime(initialMonth.year, initialMonth.month, 1),
        super(const AsyncValue.loading()) {
    _loadCalendar();
  }

  DateTime get currentMonth => _currentMonth;

  Future<void> _loadCalendar() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getCalendarData(unitId, _currentMonth);
      if (mounted) {
        state = AsyncValue.data(data);
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  void goToNextMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    _loadCalendar();
  }

  void goToPreviousMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    _loadCalendar();
  }

  void goToMonth(DateTime month) {
    _currentMonth = DateTime(month.year, month.month, 1);
    _loadCalendar();
  }

  void refresh() {
    _loadCalendar();
  }
}

/// Provider za Calendar Grid Notifier
final calendarGridNotifierProvider = StateNotifierProvider.family<
    CalendarGridNotifier,
    AsyncValue<List<CalendarDay>>,
    CalendarGridParams>((ref, params) {
  final repository = ref.watch(calendarGridRepositoryProvider);
  return CalendarGridNotifier(
    repository,
    params.unitId,
    params.initialMonth ?? DateTime.now(),
  );
});

/// Parameters classes
class CalendarDataParams {
  final String unitId;
  final DateTime month;

  CalendarDataParams({
    required this.unitId,
    required this.month,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarDataParams &&
          runtimeType == other.runtimeType &&
          unitId == other.unitId &&
          month.year == other.month.year &&
          month.month == other.month.month;

  @override
  int get hashCode => unitId.hashCode ^ month.hashCode;
}

class YearlyCalendarParams {
  final String unitId;
  final int year;

  YearlyCalendarParams({
    required this.unitId,
    required this.year,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearlyCalendarParams &&
          runtimeType == other.runtimeType &&
          unitId == other.unitId &&
          year == other.year;

  @override
  int get hashCode => unitId.hashCode ^ year.hashCode;
}

class CalendarGridParams {
  final String unitId;
  final DateTime? initialMonth;

  CalendarGridParams({
    required this.unitId,
    this.initialMonth,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarGridParams &&
          runtimeType == other.runtimeType &&
          unitId == other.unitId;

  @override
  int get hashCode => unitId.hashCode;
}
