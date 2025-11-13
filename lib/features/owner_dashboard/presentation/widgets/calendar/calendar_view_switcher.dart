import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/calendar_view_mode.dart';

/// Calendar view switcher widget
/// Segmented control to switch between Week, Month, and Timeline views
class CalendarViewSwitcher extends StatelessWidget {
  final CalendarViewMode currentView;
  final ValueChanged<CalendarViewMode> onViewChanged;
  final bool isCompact;

  const CalendarViewSwitcher({
    super.key,
    required this.currentView,
    required this.onViewChanged,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isCompact) {
      // Mobile: dropdown menu
      return PopupMenuButton<CalendarViewMode>(
        initialValue: currentView,
        onSelected: onViewChanged,
        itemBuilder: (context) => [
          _buildMenuItem(CalendarViewMode.week, Icons.view_week),
          _buildMenuItem(CalendarViewMode.timeline, Icons.view_timeline),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForView(currentView),
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                currentView.displayName,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      );
    }

    // Desktop: segmented button with custom purple theme
    return SegmentedButton<CalendarViewMode>(
      segments: const [
        ButtonSegment<CalendarViewMode>(
          value: CalendarViewMode.week,
          icon: Icon(Icons.view_week, size: 18),
          label: Text('Tjedni'),
        ),
        ButtonSegment<CalendarViewMode>(
          value: CalendarViewMode.timeline,
          icon: Icon(Icons.view_timeline, size: 18),
          label: Text('Gantt'),
        ),
      ],
      selected: {currentView},
      onSelectionChanged: (Set<CalendarViewMode> newSelection) {
        if (newSelection.isNotEmpty) {
          onViewChanged(newSelection.first);
        }
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary; // Purple when selected
            }
            return Colors.transparent;
          },
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return theme.colorScheme.onSurface;
          },
        ),
        side: WidgetStateProperty.all(
          BorderSide(color: AppColors.primary.withAlpha((0.3 * 255).toInt())),
        ),
      ),
    );
  }

  PopupMenuItem<CalendarViewMode> _buildMenuItem(
    CalendarViewMode mode,
    IconData icon,
  ) {
    return PopupMenuItem<CalendarViewMode>(
      value: mode,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(mode.displayName),
          const Spacer(),
          if (mode == currentView)
            const Icon(Icons.check, size: 20, color: Colors.green),
        ],
      ),
    );
  }

  IconData _getIconForView(CalendarViewMode mode) {
    switch (mode) {
      case CalendarViewMode.week:
        return Icons.view_week;
      case CalendarViewMode.timeline:
        return Icons.view_timeline;
    }
  }
}
