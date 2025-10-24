import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/calendar_day.dart';
import '../../domain/models/calendar_update_event.dart';
import '../providers/calendar_providers_refactored.dart';
import '../providers/calendar_update_tracker.dart';
import '../providers/booking_flow_provider.dart';
import 'calendar_cell_builder.dart';
import 'realtime_calendar_animations.dart';

/// Animated calendar grid with real-time update support
class AnimatedCalendarGrid extends ConsumerWidget {
  final String unitId;
  final DateTime month;
  final void Function(DateTime date, CalendarDay dayData)? onDateTap;
  final bool enableAnimations;
  final bool showNotifications;

  const AnimatedCalendarGrid({
    Key? key,
    required this.unitId,
    required this.month,
    this.onDateTap,
    this.enableAnimations = true,
    this.showNotifications = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarData = ref.watch(calendarDataProvider(unitId, month));
    final updateTracker = ref.watch(calendarUpdateTrackerProvider);
    final notifications = ref.watch(updateNotificationManagerProvider);

    return Stack(
      children: [
        // Main calendar grid
        calendarData.when(
          data: (state) => _buildGrid(context, ref, state, updateTracker),
          loading: () => _buildLoadingGrid(context),
          error: (error, stack) => _buildErrorGrid(context, error),
        ),

        // Update notifications
        if (showNotifications && notifications.isNotEmpty)
          _buildNotifications(context, ref, notifications),
      ],
    );
  }

  /// Build the calendar grid
  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    CalendarState state,
    Map<DateTime, UpdateInfo> updateTracker,
  ) {
    final cellBuilder = CalendarCellBuilder();
    final daysInMonth = state.days;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: _getAspectRatio(context),
      ),
      itemCount: daysInMonth.length + _getFirstDayOffset(daysInMonth),
      itemBuilder: (context, index) {
        final offset = _getFirstDayOffset(daysInMonth);

        // Empty cells before month starts
        if (index < offset) {
          return const SizedBox.shrink();
        }

        final dayIndex = index - offset;
        if (dayIndex >= daysInMonth.length) {
          return const SizedBox.shrink();
        }

        final dayData = daysInMonth[dayIndex];
        final date = dayData.date;
        final isToday = _isToday(date);
        final isSelected = _isSelected(ref, date);

        // Check if this date was recently updated
        final updateInfo = updateTracker[date];
        final isUpdated = updateInfo != null && updateInfo.isFresh;

        // Build the cell
        final cell = cellBuilder.buildCell(
          context,
          date,
          dayData,
          onTap: () => onDateTap?.call(date, dayData),
          isSelected: isSelected,
          isToday: isToday,
        );

        // Wrap with animation if enabled and updated
        if (enableAnimations && isUpdated) {
          return AnimatedCalendarCell(
            date: date,
            dayData: dayData,
            isUpdated: true,
            updateAction: updateInfo.action,
            onTap: () => onDateTap?.call(date, dayData),
            child: cell,
          );
        }

        return cell;
      },
    );
  }

  /// Build loading state
  Widget _buildLoadingGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: _getAspectRatio(context),
      ),
      itemCount: 35, // ~5 weeks
      itemBuilder: (context, index) {
        return ShimmerEffect(
          isActive: true,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }

  /// Build error state
  Widget _buildErrorGrid(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Failed to load calendar',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build notification banners
  Widget _buildNotifications(
    BuildContext context,
    WidgetRef ref,
    List<UpdateNotification> notifications,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Column(
        children: notifications.map((notification) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: UpdateNotificationBanner(
              message: notification.message,
              action: notification.action,
              onDismiss: () {
                ref
                    .read(updateNotificationManagerProvider.notifier)
                    .dismiss(notification.id);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Get first day offset for the month
  int _getFirstDayOffset(List<CalendarDay> days) {
    if (days.isEmpty) return 0;
    final firstDay = days.first.date;
    return firstDay.weekday % 7; // 0 = Sunday, 1 = Monday, etc.
  }

  /// Check if date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is selected
  bool _isSelected(WidgetRef ref, DateTime date) {
    final calendarInteraction = ref.watch(calendarInteractionProvider);
    return calendarInteraction.isRangeEndpoint(date) ||
        calendarInteraction.isInRange(date);
  }

  /// Get aspect ratio based on screen size
  double _getAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1024) {
      return 1.0; // Desktop: square cells
    } else if (width > 600) {
      return 1.1; // Tablet: slightly wider
    } else {
      return 1.2; // Mobile: more compact
    }
  }
}

/// Calendar grid with conflict detection overlay
class ConflictAwareCalendarGrid extends ConsumerWidget {
  final String unitId;
  final DateTime month;
  final void Function(DateTime date, CalendarDay dayData)? onDateTap;

  const ConflictAwareCalendarGrid({
    Key? key,
    required this.unitId,
    required this.month,
    this.onDateTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflicts = ref.watch(calendarConflictDetectorProvider);

    return Stack(
      children: [
        AnimatedCalendarGrid(
          unitId: unitId,
          month: month,
          onDateTap: onDateTap,
        ),

        // Conflict indicators
        if (conflicts.isNotEmpty) _buildConflictOverlay(context, conflicts),
      ],
    );
  }

  /// Build conflict overlay
  Widget _buildConflictOverlay(
    BuildContext context,
    Set<DateTime> conflicts,
  ) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.red.shade700,
            ),
            const SizedBox(height: 8),
            Text(
              'Date Conflict Detected',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'The selected dates were just booked by another user.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Clear conflicts and refresh
                ref.read(calendarConflictDetectorProvider.notifier).clearConflicts();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Select Different Dates'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
