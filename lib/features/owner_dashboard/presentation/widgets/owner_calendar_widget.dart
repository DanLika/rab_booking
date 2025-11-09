import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/calendar_view_mode.dart';
import '../providers/owner_calendar_provider.dart';
import '../providers/owner_calendar_view_provider.dart';
import 'timeline_calendar_widget.dart';
import 'owner_month_calendar_widget.dart';

/// Owner calendar widget with multiple view options
/// Supports Timeline and Month views
/// Displays ALL units for ALL properties
class OwnerCalendarWidget extends ConsumerStatefulWidget {
  const OwnerCalendarWidget({super.key});

  @override
  ConsumerState<OwnerCalendarWidget> createState() => _OwnerCalendarWidgetState();
}

class _OwnerCalendarWidgetState extends ConsumerState<OwnerCalendarWidget> {

  @override
  Widget build(BuildContext context) {
    // Enable realtime subscription for automatic updates
    ref.watch(ownerCalendarRealtimeManagerProvider);

    final currentView = ref.watch(ownerCalendarViewProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // View switcher
          _buildViewSwitcher(currentView),
          const SizedBox(height: 16),

          // Calendar view based on selection
          Expanded(
            child: _buildCalendarView(currentView),
          ),
        ],
      ),
    );
  }

  /// Build view switcher tabs
  Widget _buildViewSwitcher(CalendarViewMode currentView) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewTab(
            context: context,
            label: 'Timeline',
            icon: Icons.view_timeline,
            viewType: CalendarViewMode.timeline,
            isSelected: currentView == CalendarViewMode.timeline,
          ),
          _buildViewTab(
            context: context,
            label: 'Mjesec',
            icon: Icons.calendar_month,
            viewType: CalendarViewMode.month,
            isSelected: currentView == CalendarViewMode.month,
          ),
        ],
      ),
    );
  }

  /// Build individual view tab button
  Widget _buildViewTab({
    required BuildContext context,
    required String label,
    required IconData icon,
    required CalendarViewMode viewType,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        ref.read(ownerCalendarViewProvider.notifier).setView(viewType);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build calendar view based on selected view type
  Widget _buildCalendarView(CalendarViewMode viewType) {
    switch (viewType) {
      case CalendarViewMode.timeline:
        return const TimelineCalendarWidget();
      case CalendarViewMode.month:
        return const OwnerMonthCalendarWidget();
      case CalendarViewMode.week:
        // Week view not supported in this legacy widget
        return const TimelineCalendarWidget();
    }
  }
}
