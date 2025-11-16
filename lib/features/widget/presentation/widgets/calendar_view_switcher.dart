import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/calendar_view_provider.dart';
import '../providers/realtime_calendar_provider.dart';
import '../providers/calendar_auto_refresh_provider.dart';
import '../../domain/models/calendar_view_type.dart';
import 'year_calendar_widget.dart';
import 'month_calendar_widget.dart';

class CalendarViewSwitcher extends ConsumerStatefulWidget {
  final String propertyId;
  final String unitId;
  final Function(DateTime? start, DateTime? end)? onRangeSelected;
  final bool forceMonthView;

  const CalendarViewSwitcher({
    super.key,
    required this.propertyId,
    required this.unitId,
    this.onRangeSelected,
    this.forceMonthView = false,
  });

  @override
  ConsumerState<CalendarViewSwitcher> createState() => _CalendarViewSwitcherState();
}

class _CalendarViewSwitcherState extends ConsumerState<CalendarViewSwitcher> {
  @override
  void initState() {
    super.initState();
    // Force month view on small devices
    if (widget.forceMonthView) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(calendarViewProvider.notifier).state = CalendarViewType.month;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentView = ref.watch(calendarViewProvider);

    // Watch for real-time updates
    ref.watch(realtimeCalendarDataProvider(widget.unitId));

    // Bug #68 Fix: Initialize auto-refresh to watch booking status changes
    ref.watch(calendarAutoRefreshProvider(widget.unitId));

    // No longer use Column with Expanded - parent now controls height via SizedBox
    return _buildCalendarView(currentView);
  }

  Widget _buildCalendarView(CalendarViewType viewType) {
    switch (viewType) {
      case CalendarViewType.month:
        return MonthCalendarWidget(
          propertyId: widget.propertyId,
          unitId: widget.unitId,
          onRangeSelected: widget.onRangeSelected,
        );
      case CalendarViewType.year:
        return YearCalendarWidget(
          propertyId: widget.propertyId,
          unitId: widget.unitId,
          onRangeSelected: widget.onRangeSelected,
        );
    }
  }
}
