import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/unit_model.dart';
import '../../domain/models/date_range_selection.dart';
import '../providers/notifications_provider.dart';
import '../providers/owner_calendar_provider.dart';
import '../widgets/timeline_calendar_widget.dart';
import '../widgets/calendar/calendar_top_toolbar.dart';
import '../widgets/calendar/calendar_filter_chips.dart';
import '../widgets/calendar/multi_select_action_bar.dart';
import '../widgets/calendar/unit_future_bookings_dialog.dart';
import '../widgets/booking_create_dialog.dart';
import '../widgets/owner_app_drawer.dart';
import '../mixins/calendar_common_methods_mixin.dart';
import '../providers/multi_select_provider.dart';
import '../../utils/calendar_grid_calculator.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../core/theme/app_color_extensions.dart';

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
  int _visibleDays = 30; // Default to 30 days, will be updated based on screen size
  int _calendarRebuildCounter = 0; // Force rebuild counter for Today button

  @override
  void initState() {
    super.initState();
    // Initialize with today as start date
    // Number of days will be calculated in didChangeDependencies based on screen size
    _currentRange = DateRangeSelection.days(DateTime.now(), _visibleDays);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update visible days based on screen width
    final newVisibleDays = CalendarGridCalculator.getTimelineVisibleDays(context);
    if (newVisibleDays != _visibleDays) {
      setState(() {
        _visibleDays = newVisibleDays;
        // Recreate range with new day count
        _currentRange = DateRangeSelection.days(_currentRange.startDate, _visibleDays);
      });
    }
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
            backgroundColor: Colors.transparent, // Transparent to show gradient background
            appBar: CommonAppBar(
              title: 'Kalendar',
              leadingIcon: Icons.menu,
              onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
            ),
            drawer: const OwnerAppDrawer(currentRoute: 'calendar/timeline'),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          Theme.of(context).colorScheme.veryDarkGray,
                          Theme.of(context).colorScheme.mediumDarkGray,
                        ]
                      : [
                          Theme.of(context).colorScheme.veryLightGray,
                          Colors.white,
                        ],
                  stops: const [0.0, 0.3],
                ),
              ),
              child: Column(
                children: [
          // Top toolbar with integrated analytics toggle - OPTIMIZED: Single row
          Consumer(
            builder: (context, ref, child) {
              final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);
              final multiSelectState = ref.watch(multiSelectProvider);

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
                // Use higher breakpoint for toolbar to prevent overflow
                isCompact: MediaQuery.of(context).size.width < 900,
                // ENHANCED: Analytics toggle integrated in single row
                showSummaryToggle: true,
                isSummaryVisible: _showSummary,
                onSummaryToggleChanged: (value) {
                  setState(() {
                    _showSummary = value;
                  });
                },
                // ENHANCED: Multi-select mode toggle
                showMultiSelectToggle: true,
                isMultiSelectActive: multiSelectState.isEnabled,
                onMultiSelectToggle: () {
                  if (multiSelectState.isEnabled) {
                    ref.read(multiSelectProvider.notifier).disableMultiSelect();
                  } else {
                    ref.read(multiSelectProvider.notifier).enableMultiSelect();
                  }
                },
              );
            },
          ),

          // Filter chips (from shared widget)
          const CalendarFilterChips(),

          // Timeline calendar widget (it fetches its own data via providers)
          Expanded(
            child: TimelineCalendarWidget(
              key: ValueKey('${_currentRange.startDate}_$_calendarRebuildCounter'), // Rebuild on date change + counter
              initialScrollToDate: _currentRange.startDate, // Scroll to selected date
              showSummary: _showSummary,
              onCellLongPress: (date, unit) => _showCreateBookingDialog(
                initialCheckIn: date,
                unitId: unit.id,
              ),
              onUnitNameTap: _showUnitFutureBookings,
            ),
          ),

          // Multi-select action bar (bottom)
          const MultiSelectActionBar(),
                ],
              ), // Column
            ), // Container with gradient background
            floatingActionButton: Consumer(
              builder: (context, ref, child) {
                final multiSelectState = ref.watch(multiSelectProvider);

                // Hide FAB when multi-select is active
                if (multiSelectState.isEnabled) {
                  return const SizedBox.shrink();
                }

                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6B4CE6), // Purple
                        Color(0xFF4A90E2), // Blue
                      ],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: FloatingActionButton(
                    onPressed: _showCreateBookingDialog,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    hoverElevation: 0,
                    focusElevation: 0,
                    highlightElevation: 0,
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                );
              },
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          ),
        ),
      ),
    );
  }

  /// Go to previous period (moves back by visible days count)
  void _goToPreviousMonth() {
    setState(() {
      _currentRange = _currentRange.previous(isWeek: false);
    });
  }

  /// Go to next period (moves forward by visible days count)
  void _goToNextMonth() {
    setState(() {
      _currentRange = _currentRange.next(isWeek: false);
    });
  }

  /// Go to today - creates new range starting from today
  void _goToToday() {
    setState(() {
      _currentRange = DateRangeSelection.days(DateTime.now(), _visibleDays);
      _calendarRebuildCounter++; // Force widget rebuild to trigger scroll
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
        // Create new range starting from picked date with current visible days
        _currentRange = DateRangeSelection.days(picked, _visibleDays);
      });
    }
  }

  /// Show unit future bookings dialog
  void _showUnitFutureBookings(UnitModel unit) async {
    // Get all bookings from provider
    final bookingsAsyncValue = ref.read(calendarBookingsProvider);

    // Handle loading/error states
    if (bookingsAsyncValue.isLoading) {
      return; // Don't show dialog while loading
    }

    final bookingsByUnit = bookingsAsyncValue.value ?? {};
    final unitBookings = bookingsByUnit[unit.id] ?? [];

    // Filter for future bookings only (check-out >= today)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final futureBookings = unitBookings.where((booking) {
      return !booking.checkOut.isBefore(today);
    }).toList()..sort((a, b) => a.checkIn.compareTo(b.checkIn));

    // Show dialog
    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => UnitFutureBookingsDialog(
          unit: unit,
          bookings: futureBookings,
          onBookingTap: showBookingDetailsDialog,
        ),
      );
    }
  }

  /// Show create booking dialog
  /// ENHANCED: Now accepts optional initialCheckIn date and unitId for auto-fill
  void _showCreateBookingDialog({
    DateTime? initialCheckIn,
    String? unitId,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BookingCreateDialog(
        initialCheckIn: initialCheckIn,
        unitId: unitId,
      ),
    );

    // If booking was created successfully, refresh calendar
    if (result == true && mounted) {
      await Future.wait([
        ref.refresh(calendarBookingsProvider.future),
        ref.refresh(allOwnerUnitsProvider.future),
      ]);
    }
  }

  /// Override refresh to also reset date range to today
  /// Bug Fix: Refresh button was showing wrong date/month
  /// Solution: Reset range to today + force calendar rebuild with counter
  @override
  Future<void> refreshCalendarData() async {
    // First, reset to today (this will rebuild widget with new key)
    setState(() {
      _currentRange = DateRangeSelection.days(DateTime.now(), _visibleDays);
      _calendarRebuildCounter++; // Force widget rebuild to trigger scroll to today
    });

    // Then, refresh providers
    await super.refreshCalendarData();
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
