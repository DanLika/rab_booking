import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../shared/models/unit_model.dart';
import '../../domain/models/date_range_selection.dart';
import '../providers/notifications_provider.dart';
import '../providers/owner_calendar_provider.dart';
import '../providers/overbooking_detection_provider.dart';
import '../../domain/models/overbooking_conflict.dart';
import '../widgets/timeline_calendar_widget.dart';
import '../widgets/booking_details_dialog.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../widgets/calendar/calendar_top_toolbar.dart';
import '../widgets/calendar/multi_select_action_bar.dart';
import '../widgets/calendar/unit_future_bookings_dialog.dart';
import '../widgets/booking_create_dialog.dart';
import '../widgets/owner_app_drawer.dart';
import '../mixins/calendar_common_methods_mixin.dart';
import '../providers/multi_select_provider.dart';
import '../providers/show_empty_units_provider.dart';
import '../providers/calendar_filters_provider.dart';
import '../../domain/models/calendar_filter_options.dart';
import '../../utils/calendar_grid_calculator.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/calendar/tutorial/calendar_tutorial_overlay.dart';

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

  // GlobalKey for accessing TimelineCalendarWidget's scroll methods
  final GlobalKey timelineKey = GlobalKey();
  bool _showSummary = false;
  int _visibleDays =
      30; // Default to 30 days, will be updated based on screen size

  // FIXED: Flag to prevent onVisibleDateRangeChanged from overwriting _currentRange
  // during programmatic navigation (Today, Previous, Next, DatePicker)
  bool _isProgrammaticNavigation = false;

  // Track vertical scroll position to preserve it during toolbar navigation
  // When user clicks left/right arrows, widget rebuilds but we restore scroll position
  double _verticalScrollOffset = 0.0;

  // Problem #19 fix: Counter to force scroll even when date hasn't changed
  // Incremented each time Today is clicked to ensure widget scrolls to today
  int _forceScrollKey = 0;

  // Track if tutorial has been dismissed in this session
  bool _showTutorialDismissed = false;

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

  // Helper to check if we should show tutorial
  bool _shouldShowTutorial(bool hasUnits, bool isCalendarEmpty) {
    // Only show if:
    // 1. User has units (so calendar grid is visible)
    // 2. Calendar is empty (new user scenario)
    // 3. Not already showing or dismissed (handled by _showTutorial flag logic ideally)
    // Since we can't easily modify state during build, we rely on a manual trigger or just
    // simple condition here.
    // Let's use a "one-shot" approach: if calendar IS empty and we haven't dismissed it manually.
    // We initialize _showTutorial = true in initState? No, we don't know data there.

    // Simplification: logic moved to build method's Stack
    return hasUnits && isCalendarEmpty;
  }

  @override
  Widget build(BuildContext context) {
    // Activate real-time listener for calendar updates
    // This ensures bookings created/modified anywhere are reflected immediately
    ref.watch(ownerCalendarRealtimeManagerProvider);

    // Activate auto-resolution of overbooking conflicts
    // Automatically rejects pending bookings when they conflict with confirmed bookings
    ref.watch(overbookingAutoResolverProvider);

    // Check if owner has any units - hide toolbar and FAB if empty
    final unitsAsync = ref.watch(allOwnerUnitsProvider);
    final hasUnits = unitsAsync.when(
      data: (units) => units.isNotEmpty,
      loading: () => true, // Show toolbar while loading to avoid flicker
      error: (_, _) => false, // Hide toolbar on error
    );

    // Check if calendar is empty to trigger tutorial
    // If we have units but no bookings, show tutorial
    final bookingsAsync = ref.watch(timelineCalendarBookingsProvider);
    final isCalendarEmpty = bookingsAsync.when(
      data: (bookings) => bookings.values.fold<int>(0, (sum, list) => sum + list.length) == 0,
      loading: () => false,
      error: (_, __) => false,
    );


    // Safely get localizations - use try-catch to prevent errors if context is not ready
    String calendarTitle;
    try {
      calendarTitle = AppLocalizations.of(context).ownerCalendar;
    } catch (e) {
      calendarTitle = 'Calendar'; // Fallback title
    }

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
          child: Stack(
            children: [
            Scaffold(
            backgroundColor:
                Colors.transparent, // Transparent to show gradient background
            appBar: CommonAppBar(
              title: calendarTitle,
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
                  // CONDITIONAL: Hide toolbar when owner has no units
                  if (hasUnits)
                    Consumer(
                      builder: (context, ref, child) {
                        final unreadCountAsync = ref.watch(
                          unreadNotificationsCountProvider,
                        );
                        final multiSelectState = ref.watch(multiSelectProvider);
                        final conflictCount = ref.watch(
                          overbookingConflictCountProvider,
                        );
                        final showEmptyUnits = ref.watch(
                          showEmptyUnitsProvider,
                        );
                        final filters = ref.watch(calendarFiltersProvider);
                        final activeFilterCount = filters.activeFilterCount;

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
                            // Force immediate rebuild to prevent delay
                            // Without this, summary bar wouldn't appear until user scrolled
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  // Trigger second rebuild to ensure AnimatedSize processes
                                });
                              }
                            });
                          },
                          // Show empty units toggle (persisted via provider)
                          showEmptyUnitsToggle: true,
                          isEmptyUnitsVisible: showEmptyUnits,
                          onEmptyUnitsToggleChanged: (value) {
                            ref
                                .read(showEmptyUnitsProvider.notifier)
                                .setValue(value);
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
                          // Overbooking conflict badge
                          overbookingConflictCount: conflictCount,
                          onOverbookingBadgeTap: () {
                            _handleOverbookingBadgeTap(ref);
                          },
                          // Active filters inline display
                          activeFilterCount: activeFilterCount > 0
                              ? activeFilterCount
                              : null,
                          onClearFilters: () {
                            ref
                                .read(calendarFiltersProvider.notifier)
                                .clearFilters();
                            // Force refresh of calendar data after clearing filters
                            ref.invalidate(filteredUnitsProvider);
                            ref.invalidate(filteredCalendarBookingsProvider);
                            ref.invalidate(timelineCalendarBookingsProvider);
                          },
                        );
                      },
                    ),

                  // Timeline calendar widget (it fetches its own data via providers)
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final showEmptyUnits = ref.watch(
                          showEmptyUnitsProvider,
                        );
                        return TimelineCalendarWidget(
                          // FIXED: Only use counter in key, NOT startDate
                          // Including startDate caused infinite rebuild loop:
                          // scroll → onVisibleDateRangeChanged → setState → key changes → rebuild → scroll...
                          key: timelineKey,
                          initialScrollToDate: _currentRange
                              .startDate, // Scroll to selected date
                          showSummary: _showSummary,
                          showEmptyUnits: showEmptyUnits,
                          // Problem #19 fix: Pass forceScrollKey to ensure Today button scrolls
                          forceScrollKey: _forceScrollKey,
                          // FIXED: Preserve vertical scroll position during toolbar navigation
                          // When user clicks left/right arrows, widget rebuilds but we restore scroll position
                          initialVerticalOffset: _verticalScrollOffset,
                          onVerticalOffsetChanged: (offset) {
                            // Track vertical scroll position (don't call setState to avoid rebuild)
                            _verticalScrollOffset = offset;
                          },
                          onCellLongPress: (date, unit) =>
                              _showCreateBookingDialog(
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
                        );
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

                // Hide FAB when multi-select is active OR when owner has no units
                if (multiSelectState.isEnabled || !hasUnits) {
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
          // Tutorial Overlay
          if (_shouldShowTutorial(hasUnits, isCalendarEmpty) && !_showTutorialDismissed)
            CalendarTutorialOverlay(
              onDismiss: () {
                setState(() {
                  _showTutorialDismissed = true;
                });
              },
            ),
        ],
      ), // Stack wrapping Scaffold to allow overlay
      ), // Focus
      ), // Actions
    );
  }

  /// Go to previous period (moves back by visible days count)
  /// Increment forceScrollKey to ensure widget scrolls (required after feedback loop fix)
  void _goToPreviousPeriod() {
    setState(() {
      _forceScrollKey++;
    });
    _navigateTo(_currentRange.previous(isWeek: false));
  }

  /// Go to next period (moves forward by visible days count)
  /// Increment forceScrollKey to ensure widget scrolls (required after feedback loop fix)
  void _goToNextPeriod() {
    setState(() {
      _forceScrollKey++;
    });
    _navigateTo(_currentRange.next(isWeek: false));
  }

  /// Go to today - creates new range starting from today
  /// Problem #19 fix: Also increment _forceScrollKey to ensure widget scrolls
  /// even if the date range hasn't changed (user might have scrolled away)
  void _goToToday() {
    setState(() {
      _forceScrollKey++;
    });
    _navigateTo(DateRangeSelection.days(DateTime.now(), _visibleDays));
  }

  /// Handle overbooking badge tap
  /// Scrolls to first conflict and shows snackbar with details
  void _handleOverbookingBadgeTap(WidgetRef ref) {
    if (!mounted) return;

    final conflictsAsync = ref.read(overbookingConflictsProvider);
    final conflicts = conflictsAsync.valueOrNull ?? [];

    if (conflicts.isEmpty) return;

    final firstConflict = conflicts.first;

    // Scroll to conflict location
    final timelineState = timelineKey.currentState;
    if (timelineState != null && firstConflict.conflictDates.isNotEmpty) {
      final conflictDate = firstConflict.conflictDates.first;
      // Use dynamic call since we can't import private class
      try {
        (timelineState as dynamic).scrollToConflict(
          firstConflict.unitId,
          conflictDate,
        );
      } catch (e) {
        // If scroll fails, just show snackbar
        debugPrint('Failed to scroll to conflict: $e');
      }
    }

    // Show snackbar with conflict details
    // Include platform source for external bookings (Booking.com, Airbnb, etc.)
    final source1 = firstConflict.booking1.isExternalBooking
        ? ' (${firstConflict.booking1.sourceDisplayName})'
        : '';
    final source2 = firstConflict.booking2.isExternalBooking
        ? ' (${firstConflict.booking2.sourceDisplayName})'
        : '';
    final guest1 = '${firstConflict.booking1.guestName ?? 'Unknown'}$source1';
    final guest2 = '${firstConflict.booking2.guestName ?? 'Unknown'}$source2';
    final l10n = AppLocalizations.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.overbookingConflictDetails(guest1, guest2)),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: l10n.overbookingViewBooking,
          textColor: Colors.white,
          onPressed: () {
            // Navigate to booking details
            _showBookingDetailsFromConflict(ref, firstConflict);
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Show booking details dialog for a conflict
  void _showBookingDetailsFromConflict(
    WidgetRef ref,
    OverbookingConflict conflict,
  ) async {
    // Try to get booking from repository
    try {
      final repository = ref.read(ownerBookingsRepositoryProvider);
      final ownerBooking = await repository.getOwnerBookingById(
        conflict.booking1.id,
      );

      if (ownerBooking != null && mounted) {
        await showDialog(
          context: context,
          builder: (context) =>
              BookingDetailsDialog(ownerBooking: ownerBooking),
        );
      }
    } catch (e) {
      // If booking not found, show error
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.ownerBookingsNotFound),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      // Increment forceScrollKey to ensure widget scrolls (required after feedback loop fix)
      setState(() {
        _forceScrollKey++;
      });
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
    });

    // Problem #16 fix: Increased timeout from 600ms to 1000ms
    // Timeline animation takes 500ms, then there's a 150ms delay before flag reset
    // Total time needed: ~700-800ms. Using 1000ms for safety margin.
    // Old value (600ms) caused race condition where onVisibleDateRangeChanged
    // would fire after flag reset, causing toolbar to "jump back" to old position.
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted || !context.mounted) return;
      setState(() {
        _isProgrammaticNavigation = false;
      });
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
  // SECURITY FIX SF-016: Use ValueNotifier instead of setState for hover/press state
  // This prevents unnecessary rebuilds of the entire FAB widget on each state change
  late final ValueNotifier<bool> _isHoveredNotifier;
  late final ValueNotifier<bool> _isPressedNotifier;

  @override
  void initState() {
    super.initState();
    _isHoveredNotifier = ValueNotifier<bool>(false);
    _isPressedNotifier = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _isHoveredNotifier.dispose();
    _isPressedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _isHoveredNotifier.value = true,
      onExit: (_) => _isHoveredNotifier.value = false,
      child: GestureDetector(
        onTapDown: (_) => _isPressedNotifier.value = true,
        onTapUp: (_) {
          _isPressedNotifier.value = false;
          widget.onPressed();
        },
        onTapCancel: () => _isPressedNotifier.value = false,
        // SF-016: Nested ValueListenableBuilders to rebuild only FAB content
        child: ValueListenableBuilder<bool>(
          valueListenable: _isHoveredNotifier,
          builder: (context, isHovered, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: _isPressedNotifier,
              builder: (context, isPressed, _) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 56,
                  height: 56,
                  transform: Matrix4.diagonal3Values(
                    isPressed ? 0.92 : (isHovered ? 1.08 : 1.0),
                    isPressed ? 0.92 : (isHovered ? 1.08 : 1.0),
                    1.0,
                  ),
                  transformAlignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradient.colors.first.withAlpha(
                          ((isHovered ? 0.5 : 0.35) * 255).toInt(),
                        ),
                        blurRadius: isHovered ? 20 : 12,
                        offset: Offset(0, isHovered ? 8 : 4),
                        spreadRadius: isHovered ? 2 : 0,
                      ),
                    ],
                  ),
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: isHovered ? 0.125 : 0, // 45 degree rotation on hover
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
