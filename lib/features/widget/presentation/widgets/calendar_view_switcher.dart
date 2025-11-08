import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/calendar_view_provider.dart';
import '../providers/realtime_calendar_provider.dart';
import 'year_calendar_widget.dart';
import 'week_calendar_widget.dart';
import 'month_calendar_widget.dart';

enum CalendarViewType {
  week,
  month,
  year,
}

class CalendarViewSwitcher extends ConsumerStatefulWidget {
  final String unitId;
  final Function(DateTime? start, DateTime? end)? onRangeSelected;
  final bool forceMonthView;

  const CalendarViewSwitcher({
    super.key,
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

    return Column(
      children: [
        // Tab bar removed - view switching now handled by external controls
        Expanded(
          child: _buildCalendarView(currentView),
        ),
      ],
    );
  }

  Widget _buildCalendarView(CalendarViewType viewType) {
    switch (viewType) {
      case CalendarViewType.week:
        return WeekCalendarWidget(
          unitId: widget.unitId,
          onRangeSelected: widget.onRangeSelected,
        );
      case CalendarViewType.month:
        return MonthCalendarWidget(
          unitId: widget.unitId,
          onRangeSelected: widget.onRangeSelected,
        );
      case CalendarViewType.year:
        return YearCalendarWidget(
          unitId: widget.unitId,
          onRangeSelected: widget.onRangeSelected,
        );
    }
  }
}
