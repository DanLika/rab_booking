import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/adaptive_spacing.dart';
import '../../../../core/utils/responsive_breakpoints.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../calendar/data/calendar_realtime_manager.dart';
import '../../../calendar/domain/models/calendar_day.dart';
import '../../../calendar/domain/models/calendar_update_event.dart';
import '../../../calendar/presentation/widgets/realtime_calendar_animations.dart';
import '../../../calendar/data/calendar_repository.dart';
import '../../domain/models/property_unit.dart';

/// Real-time calendar section for property details page
///
/// Shows availability calendar with:
/// - Real-time updates via Supabase subscriptions
/// - Color-coded availability (available, booked, blocked)
/// - Interactive date selection for booking
/// - Responsive layout (collapsible on mobile)
class RealtimeCalendarSection extends ConsumerStatefulWidget {
  const RealtimeCalendarSection({
    required this.unit,
    this.onDateRangeSelected,
    this.isExpandedByDefault = true,
    super.key,
  });

  final PropertyUnit unit;
  final Function(DateTime start, DateTime end)? onDateRangeSelected;
  final bool isExpandedByDefault;

  @override
  ConsumerState<RealtimeCalendarSection> createState() =>
      _RealtimeCalendarSectionState();
}

class _RealtimeCalendarSectionState
    extends ConsumerState<RealtimeCalendarSection> {
  late DateTime _focusedDay;
  DateTime? _selectedStart;
  DateTime? _selectedEnd;
  Map<DateTime, CalendarDay> _calendarData = {};
  Set<DateTime> _updatedDates = {};
  CalendarRealtimeManager? _realtimeManager;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _isExpanded = widget.isExpandedByDefault;
    _setupRealtimeSubscription();
    _loadCalendarData();
  }

  @override
  void didUpdateWidget(RealtimeCalendarSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unit.id != widget.unit.id) {
      _realtimeManager?.unsubscribe();
      _setupRealtimeSubscription();
      _loadCalendarData();
    }
  }

  @override
  void dispose() {
    _realtimeManager?.dispose();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    final supabase = Supabase.instance.client;
    _realtimeManager = CalendarRealtimeManager(supabase);
    _realtimeManager!.subscribeToUnit(widget.unit.id);

    // Listen to real-time updates
    _realtimeManager!.updates.listen((event) {
      _handleRealtimeUpdate(event);
    });
  }

  void _handleRealtimeUpdate(CalendarUpdateEvent event) {
    // Mark dates as updated for animation
    final affectedDates = _getAffectedDates(event);
    setState(() {
      _updatedDates.addAll(affectedDates);
    });

    // Reload calendar data
    _loadCalendarData();

    // Clear update markers after animation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _updatedDates.clear();
        });
      }
    });
  }

  Set<DateTime> _getAffectedDates(CalendarUpdateEvent event) {
    final dates = <DateTime>{};
    // TODO: Extract dates from event
    // For now, just mark the current month
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      dates.add(now.add(Duration(days: i)));
    }
    return dates;
  }

  Future<void> _loadCalendarData() async {
    try {
      final repository = CalendarRepository(Supabase.instance.client);
      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final data = await repository.getCalendarData(
        unitId: widget.unit.id,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _calendarData = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading calendar data: $e');
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (_selectedStart == null || _selectedEnd != null) {
      // Start new selection
      setState(() {
        _selectedStart = selectedDay;
        _selectedEnd = null;
      });
    } else {
      // Complete selection
      final start = _selectedStart!.isBefore(selectedDay)
          ? _selectedStart!
          : selectedDay;
      final end = _selectedStart!.isBefore(selectedDay)
          ? selectedDay
          : _selectedStart!;

      setState(() {
        _selectedStart = start;
        _selectedEnd = end;
      });

      // Notify parent
      widget.onDateRangeSelected?.call(start, end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(context, isMobile),

          // Calendar (collapsible on mobile)
          if (_isExpanded) ...[
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(context.spacing.medium),
              child: _buildCalendar(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return InkWell(
      onTap: isMobile
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.medium),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.spacing.small),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_month,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            SizedBox(width: context.spacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Availability Calendar',
                    style: context.typography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: context.spacing.extraSmall),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: context.spacing.extraSmall),
                      Text(
                        'Real-time updates',
                        style: context.typography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isMobile)
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    return TableCalendar<CalendarDay>(
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      rangeStartDay: _selectedStart,
      rangeEndDay: _selectedEnd,

      // Styling
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendTextStyle: context.typography.bodyMedium,
        rangeHighlightColor:
            Theme.of(context).colorScheme.primary.withOpacity(0.2),
        rangeStartDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        rangeEndDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          shape: BoxShape.circle,
        ),
      ),

      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: context.typography.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),

      // Event loader
      eventLoader: (day) {
        final normalizedDay = DateTime(day.year, day.month, day.day);
        final dayData = _calendarData[normalizedDay];
        return dayData != null ? [dayData] : [];
      },

      // Day builder with animations
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          return _buildDayCell(context, day, focusedDay);
        },
        todayBuilder: (context, day, focusedDay) {
          return _buildDayCell(context, day, focusedDay, isToday: true);
        },
        selectedBuilder: (context, day, focusedDay) {
          return _buildDayCell(context, day, focusedDay, isSelected: true);
        },
      ),

      onDaySelected: _onDaySelected,
      onPageChanged: (focusedDay) {
        setState(() => _focusedDay = focusedDay);
        _loadCalendarData();
      },
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    DateTime focusedDay, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final dayData = _calendarData[normalizedDay];
    final isUpdated = _updatedDates.contains(normalizedDay);

    Color? backgroundColor;
    Color? textColor;

    if (dayData != null) {
      if (!dayData.isAvailable) {
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red.shade700;
      } else if (dayData.hasBooking) {
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue.shade700;
      } else {
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green.shade700;
      }
    }

    Widget cell = Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: context.typography.bodyMedium.copyWith(
            color: textColor ?? Theme.of(context).colorScheme.onSurface,
            fontWeight: isToday ? FontWeight.bold : null,
          ),
        ),
      ),
    );

    if (isUpdated && dayData != null) {
      return AnimatedCalendarCell(
        date: day,
        dayData: dayData,
        isUpdated: true,
        child: cell,
      );
    }

    return cell;
  }
}
