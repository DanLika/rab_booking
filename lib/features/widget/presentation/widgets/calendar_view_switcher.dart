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
        _buildTabBar(currentView),
        const SizedBox(height: 16),
        Expanded(
          child: _buildCalendarView(currentView),
        ),
      ],
    );
  }

  Widget _buildTabBar(CalendarViewType currentView) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildTabButton(
            label: 'Week',
            icon: Icons.view_week,
            viewType: CalendarViewType.week,
            isSelected: currentView == CalendarViewType.week,
          ),
          _buildTabButton(
            label: 'Month',
            icon: Icons.calendar_month,
            viewType: CalendarViewType.month,
            isSelected: currentView == CalendarViewType.month,
          ),
          // Hide year view on small phones
          if (!widget.forceMonthView)
            _buildTabButton(
              label: 'Year',
              icon: Icons.calendar_today,
              viewType: CalendarViewType.year,
              isSelected: currentView == CalendarViewType.year,
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required CalendarViewType viewType,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(calendarViewProvider.notifier).state = viewType;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
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
