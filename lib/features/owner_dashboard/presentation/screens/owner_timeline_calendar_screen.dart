import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/date_range_selection.dart';
import '../providers/notifications_provider.dart';
import '../providers/owner_calendar_provider.dart';
import '../widgets/timeline_calendar_widget.dart';
import '../widgets/calendar/calendar_top_toolbar.dart';
import '../widgets/calendar/calendar_filter_chips.dart';
import '../widgets/booking_create_dialog.dart';
import '../widgets/owner_app_drawer.dart';
import '../mixins/calendar_common_methods_mixin.dart';
import '../../utils/calendar_grid_calculator.dart';
import '../../../../shared/widgets/common_app_bar.dart';

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
  bool _showSummary = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current month
    _currentRange = DateRangeSelection.month(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const _PreviousPeriodIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const _NextPeriodIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyT): const _TodayIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _PreviousPeriodIntent: CallbackAction<_PreviousPeriodIntent>(
            onInvoke: (_) => _goToPreviousMonth(),
          ),
          _NextPeriodIntent: CallbackAction<_NextPeriodIntent>(
            onInvoke: (_) => _goToNextMonth(),
          ),
          _TodayIntent: CallbackAction<_TodayIntent>(
            onInvoke: (_) => _goToToday(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: CommonAppBar(
              title: 'Kalendar - Gantt prikaz',
              leadingIcon: Icons.menu,
              onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
            ),
            drawer: const OwnerAppDrawer(currentRoute: 'calendar/timeline'),
      body: Column(
        children: [
          // Top toolbar with navigation and actions - OPTIMIZED: Consumer for notifications only
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);

                    return CalendarTopToolbar(
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
                    );
                  },
                ),
                // Summary toggle button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Statistika',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _showSummary,
                        onChanged: (value) {
                          setState(() {
                            _showSummary = value;
                          });
                        },
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filter chips (from shared widget)
          const CalendarFilterChips(),

          // Timeline calendar widget (it fetches its own data via providers)
          Expanded(
            child: TimelineCalendarWidget(
              key: ValueKey(_currentRange.startDate), // Rebuild on date change
              showSummary: _showSummary,
            ),
          ),
        ],
      ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _showCreateBookingDialog,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nova rezervacija',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              elevation: 4,
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          ),
        ),
      ),
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

  /// Show create booking dialog
  void _showCreateBookingDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const BookingCreateDialog(),
    );

    // If booking was created successfully, refresh calendar
    if (result == true && mounted) {
      await Future.wait([
        ref.refresh(calendarBookingsProvider.future),
        ref.refresh(allOwnerUnitsProvider.future),
      ]);
    }
  }
}

// Keyboard shortcut intents
class _PreviousPeriodIntent extends Intent {
  const _PreviousPeriodIntent();
}

class _NextPeriodIntent extends Intent {
  const _NextPeriodIntent();
}

class _TodayIntent extends Intent {
  const _TodayIntent();
}
