import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/gradient_extensions.dart';
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
import '../../../../l10n/app_localizations.dart';

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
  int _visibleDays =
      30; // Default to 30 days, will be updated based on screen size
  int _calendarRebuildCounter = 0; // Force rebuild counter for Today button

  // FIXED: Flag to prevent onVisibleDateRangeChanged from overwriting _currentRange
  // during programmatic navigation (Today, Previous, Next, DatePicker)
  bool _isProgrammaticNavigation = false;

  // Track vertical scroll position to preserve it during toolbar navigation
  // When user clicks left/right arrows, widget rebuilds but we restore scroll position
  double _verticalScrollOffset = 0.0;

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
    final newVisibleDays = CalendarGridCalculator.getTimelineVisibleDays(
      context,
    );
    if (newVisibleDays != _visibleDays) {
      setState(() {
        _visibleDays = newVisibleDays;
        // Recreate range with new day count
        _currentRange = DateRangeSelection.days(
          _currentRange.startDate,
          _visibleDays,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Activate real-time listener for calendar updates
    // This ensures bookings created/modified anywhere are reflected immediately
    ref.watch(ownerCalendarRealtimeManagerProvider);

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowLeft):
            const _PreviousPeriodIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const _NextPeriodIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyT): const _TodayIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _PreviousPeriodIntent: CallbackAction<_PreviousPeriodIntent>(
            onInvoke: (_) => _goToPreviousPeriod(),
          ),
          _NextPeriodIntent: CallbackAction<_NextPeriodIntent>(
            onInvoke: (_) => _goToNextPeriod(),
          ),
          _TodayIntent: CallbackAction<_TodayIntent>(
            onInvoke: (_) => _goToToday(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor:
                Colors.transparent, // Transparent to show gradient background
            appBar: CommonAppBar(
              title: AppLocalizations.of(context).ownerCalendar,
              leadingIcon: Icons.menu,
              onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
            ),
            drawer: const OwnerAppDrawer(currentRoute: 'calendar/timeline'),
            body: Container(
              decoration: BoxDecoration(
                gradient: context.gradients.pageBackground,
              ),
              child: Column(
                children: [
                  // Top toolbar with integrated analytics toggle - OPTIMIZED: Single row
                  Consumer(
                    builder: (context, ref, child) {
                      final unreadCountAsync = ref.watch(
                        unreadNotificationsCountProvider,
                      );
                      final multiSelectState = ref.watch(multiSelectProvider);

                      return CalendarTopToolbar(
                        dateRange: _currentRange,
                        isWeekView: false,
                        onPreviousPeriod: _goToPreviousPeriod,
                        onNextPeriod: _goToNextPeriod,
                        onToday: _goToToday,
                        onDatePickerTap: _showDatePicker,
                        onSearchTap: showSearchDialog,
                        onRefresh: refreshCalendarData,
                        onFilterTap: _showFiltersAndNavigateToToday,
                        notificationCount: unreadCountAsync.when(
                          data: (count) => count,
                          loading: () => 0,
                          error: (error, stackTrace) => 0,
                        ),
                        onNotificationsTap: showNotificationsPanel,
                        // Show all icons on screens >= 600px
                        isCompact: MediaQuery.of(context).size.width < 600,
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
                            ref
                                .read(multiSelectProvider.notifier)
                                .disableMultiSelect();
                          } else {
                            ref
                                .read(multiSelectProvider.notifier)
                                .enableMultiSelect();
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
                      // FIXED: Only use counter in key, NOT startDate
                      // Including startDate caused infinite rebuild loop:
                      // scroll → onVisibleDateRangeChanged → setState → key changes → rebuild → scroll...
                      key: ValueKey(_calendarRebuildCounter),
                      initialScrollToDate:
                          _currentRange.startDate, // Scroll to selected date
                      showSummary: _showSummary,
                      // FIXED: Preserve vertical scroll position during toolbar navigation
                      // When user clicks left/right arrows, widget rebuilds but we restore scroll position
                      initialVerticalOffset: _verticalScrollOffset,
                      onVerticalOffsetChanged: (offset) {
                        // Track vertical scroll position (don't call setState to avoid rebuild)
                        _verticalScrollOffset = offset;
                      },
                      onCellLongPress: (date, unit) => _showCreateBookingDialog(
                        initialCheckIn: date,
                        unitId: unit.id,
                      ),
                      onUnitNameTap: _showUnitFutureBookings,
                      onVisibleDateRangeChanged: (startDate) {
                        // FIXED: Only update toolbar when user scrolls MANUALLY
                        // Skip update during programmatic navigation (Today, arrows, date picker)
                        // to prevent overwriting the intended navigation target
                        if (_isProgrammaticNavigation) return;

                        // Update toolbar date range when user scrolls manually
                        setState(() {
                          _currentRange = DateRangeSelection.days(
                            startDate,
                            _visibleDays,
                          );
                        });
                      },
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

                return _AnimatedGradientFAB(
                  onPressed: _showCreateBookingDialog,
                  gradient: context.gradients.brandPrimary,
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
  void _goToPreviousPeriod() {
    _navigateTo(_currentRange.previous(isWeek: false));
  }

  /// Go to next period (moves forward by visible days count)
  void _goToNextPeriod() {
    _navigateTo(_currentRange.next(isWeek: false));
  }

  /// Go to today - creates new range starting from today
  void _goToToday() {
    _navigateTo(DateRangeSelection.days(DateTime.now(), _visibleDays));
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
      _navigateTo(DateRangeSelection.days(picked, _visibleDays));
    }
  }

  /// Show filters panel and navigate to today if filters were applied
  Future<void> _showFiltersAndNavigateToToday() async {
    final filtersApplied = await showFiltersPanel();
    if (filtersApplied == true && mounted) {
      // Navigate to today after applying filters
      _goToToday();
    }
  }

  /// Helper: Navigate to a new date range programmatically
  /// Sets flag to prevent onVisibleDateRangeChanged from overwriting the target
  void _navigateTo(DateRangeSelection newRange) {
    setState(() {
      _isProgrammaticNavigation = true;
      _currentRange = newRange;
      _calendarRebuildCounter++;
    });

    // Reset flag after scroll animation completes (~500ms for smooth animation)
    // This allows manual scrolling to update toolbar after programmatic navigation
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isProgrammaticNavigation = false;
        });
      }
    });
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
      builder: (context) =>
          BookingCreateDialog(initialCheckIn: initialCheckIn, unitId: unitId),
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

/// Animated gradient FAB with hover and press effects
class _AnimatedGradientFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final LinearGradient gradient;

  const _AnimatedGradientFAB({required this.onPressed, required this.gradient});

  @override
  State<_AnimatedGradientFAB> createState() => _AnimatedGradientFABState();
}

class _AnimatedGradientFABState extends State<_AnimatedGradientFAB> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 56,
          height: 56,
          transform: Matrix4.diagonal3Values(
            _isPressed ? 0.92 : (_isHovered ? 1.08 : 1.0),
            _isPressed ? 0.92 : (_isHovered ? 1.08 : 1.0),
            1.0,
          ),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withAlpha(
                  (_isHovered ? 0.5 : 0.35 * 255).toInt(),
                ),
                blurRadius: _isHovered ? 20 : 12,
                offset: Offset(0, _isHovered ? 8 : 4),
                spreadRadius: _isHovered ? 2 : 0,
              ),
            ],
          ),
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: _isHovered ? 0.125 : 0, // 45 degree rotation on hover
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
