import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/date_range_selection.dart';
import '../providers/notifications_provider.dart';
import '../widgets/timeline_calendar_widget.dart';
import '../widgets/calendar/calendar_top_toolbar.dart';
import '../widgets/calendar/calendar_filter_chips.dart';
import '../mixins/calendar_common_methods_mixin.dart';
import '../../utils/calendar_grid_calculator.dart';

/// Owner Timeline Calendar Screen
/// Shows BedBooking-style Gantt chart with booking blocks spanning dates
class OwnerTimelineCalendarScreen extends ConsumerStatefulWidget {
  const OwnerTimelineCalendarScreen({super.key});

  @override
  ConsumerState<OwnerTimelineCalendarScreen> createState() =>
      _OwnerTimelineCalendarScreenState();
}

class _OwnerTimelineCalendarScreenState
    extends ConsumerState<OwnerTimelineCalendarScreen>
    with CalendarCommonMethodsMixin {
  late DateRangeSelection _currentRange;

  @override
  void initState() {
    super.initState();
    // Initialize with current month
    _currentRange = DateRangeSelection.month(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);

    return Column(
      children: [
        // Top toolbar with navigation and actions
        CalendarTopToolbar(
          dateRange: _currentRange,
          isWeekView: false,
          onPreviousPeriod: _goToPreviousMonth,
          onNextPeriod: _goToNextMonth,
          onToday: _goToToday,
          onDatePickerTap: _showDatePicker,
          onSearchTap: showSearchDialog,
          onRefresh: refreshCalendarData,
          onFilterTap: showFiltersPanel,
          notificationCount: unreadCountAsync.when(
            data: (count) => count,
            loading: () => 0,
            error: (error, stackTrace) => 0,
          ),
          onNotificationsTap: showNotificationsPanel,
          isCompact: MediaQuery.of(context).size.width < CalendarGridCalculator.mobileBreakpoint,
        ),

        // Filter chips (from shared widget)
        const CalendarFilterChips(),

        // Timeline calendar widget (it fetches its own data via providers)
        Expanded(
          child: TimelineCalendarWidget(
            key: ValueKey(_currentRange.startDate), // Rebuild on date change
          ),
        ),
      ],
    );
  }

  /// Go to previous month
  void _goToPreviousMonth() {
    setState(() {
      _currentRange = _currentRange.previous(isWeek: false);
    });
  }

  /// Go to next month
  void _goToNextMonth() {
    setState(() {
      _currentRange = _currentRange.next(isWeek: false);
    });
  }

  /// Go to today's month
  void _goToToday() {
    setState(() {
      _currentRange = DateRangeSelection.month(DateTime.now());
    });
  }

  /// Show date picker dialog
  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentRange.startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _currentRange = DateRangeSelection.month(picked);
      });
    }
  }

}
