import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../shared/models/unit_model.dart';
import '../../domain/models/date_range_selection.dart';
import '../providers/notifications_provider.dart';
import '../providers/owner_calendar_provider.dart';
import '../providers/overbooking_detection_provider.dart';
import '../../domain/models/overbooking_conflict.dart';
import '../widgets/timeline_calendar_widget.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../widgets/calendar/calendar_top_toolbar.dart';
import '../widgets/calendar/month_calendar_kpi_strip.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/calendar/tutorial/calendar_tutorial_overlay.dart';

/// Owner Timeline Calendar Screen
/// Shows BedBooking-style Gantt chart with booking blocks spanning dates
class OwnerTimelineCalendarScreen extends ConsumerStatefulWidget {
  const OwnerTimelineCalendarScreen({super.key});

  @override
  ConsumerState<OwnerTimelineCalendarScreen> createState() =>
      _OwnerTimelineCalendarScreenState();

  /// Headless render of the premium chrome for the responsive overflow harness
  /// (`test/.../calendar_chrome_responsive_test.dart`). Renders the real chrome
  /// widgets — premium header, toolbar, legend card, FAB — with the frozen,
  /// provider-bound grid swapped for a sized placeholder so the test needs no
  /// Firebase. The KPI strip is provider-bound (shared widget, separately
  /// covered) and is intentionally omitted here.
  @visibleForTesting
  Widget buildChromeForTest(
    BuildContext context, {
    required bool isMobile,
    int unitCount = 4,
    DateTime? month,
    DateTime? now,
  }) {
    final range = DateRangeSelection.days(month ?? DateTime(2026, 6), 30);
    final double pad = isMobile ? _kPagePadHMobile : _kPagePadH;
    return Column(
      children: [
        _PremiumCalendarHeader(
          isMobile: isMobile,
          unitCount: unitCount,
          month: range.startDate,
        ),
        CalendarTopToolbar(
          dateRange: range,
          isWeekView: false,
          onPreviousPeriod: () {},
          onNextPeriod: () {},
          onToday: () {},
          onDatePickerTap: () {},
          onSearchTap: () {},
          onRefresh: () {},
          onFilterTap: () {},
          notificationCount: 2,
          onNotificationsTap: () {},
          isCompact: isMobile,
          showSummaryToggle: true,
          showEmptyUnitsToggle: true,
          showMultiSelectToggle: true,
          overbookingConflictCount: 1,
          activeFilterCount: 2,
          now: now,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(pad, BBSpace.xxs, pad, _kPagePadBottom),
          child: _CalendarGridCard(
            child: Column(
              children: [
                const _TimelineStatusLegend(),
                SizedBox(
                  height: isMobile ? 360 : 480,
                  child: const Center(child: Text('Grid')),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(pad),
          child: Align(
            alignment: Alignment.centerRight,
            child: _AnimatedGradientFAB(onPressed: () {}),
          ),
        ),
      ],
    );
  }
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

  // Track vertical scroll position to preserve it during toolbar navigation
  // When user clicks left/right arrows, widget rebuilds but we restore scroll position
  double _verticalScrollOffset = 0.0;

  // Problem #19 fix: Counter to force scroll even when date hasn't changed
  // Incremented each time Today is clicked to ensure widget scrolls to today
  int _forceScrollKey = 0;

  // Track if tutorial has been dismissed in current session or persisted
  bool _tutorialDismissed = true; // Default to true to hide until check is done

  // Solution 1: Track if initial scroll to first booking has been performed
  // Prevents repeated scrolling on every provider update
  bool _hasScrolledToFirstBooking = false;

  // Key prefix - actual key includes user ID to be per-user, not per-device
  static const String _kTutorialDismissedKeyPrefix =
      'calendar_onboarding_dismissed_';

  /// Get user-specific SharedPreferences key for tutorial dismissal
  String get _tutorialDismissedKey {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    return '$_kTutorialDismissedKeyPrefix$userId';
  }

  /// Find the first upcoming booking (check-in date >= today)
  /// Returns the check-in date of the first upcoming booking, or null if none found
  DateTime? _findFirstUpcomingBooking(
    Map<String, List<dynamic>> bookingsByUnit,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? firstUpcomingDate;

    for (final bookings in bookingsByUnit.values) {
      for (final booking in bookings) {
        // Access check-in date (BookingModel has checkIn property)
        final checkIn = booking.checkIn as DateTime?;
        if (checkIn == null) continue;

        // Only consider future bookings (check-in >= today)
        final checkInDate = DateTime(checkIn.year, checkIn.month, checkIn.day);
        if (checkInDate.isBefore(today)) continue;

        // Track the earliest upcoming booking
        if (firstUpcomingDate == null ||
            checkInDate.isBefore(firstUpcomingDate)) {
          firstUpcomingDate = checkInDate;
        }
      }
    }

    return firstUpcomingDate;
  }

  @override
  void initState() {
    super.initState();
    // Initialize with today as start date
    // Number of days will be calculated in didChangeDependencies based on screen size
    _currentRange = DateRangeSelection.days(DateTime.now(), _visibleDays);
    _loadTutorialState();
  }

  Future<void> _loadTutorialState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _tutorialDismissed = prefs.getBool(_tutorialDismissedKey) ?? false;
      });
    }
  }

  Future<void> _dismissTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialDismissedKey, true);
    if (mounted) {
      setState(() {
        _tutorialDismissed = true;
      });
    }
  }

  // Helper to check if we should show tutorial
  bool _shouldShowTutorial(bool hasUnits, bool isCalendarEmpty) {
    // Show only if user has units, calendar is empty, and tutorial hasn't been dismissed
    return hasUnits && isCalendarEmpty && !_tutorialDismissed;
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

    // Activate auto-resolution of overbooking conflicts
    // Automatically rejects pending bookings when they conflict with confirmed bookings
    ref.watch(overbookingAutoResolverProvider);

    // Solution 1: Scroll to first upcoming booking on initial load
    // Uses ref.listen to detect when bookings first become available
    ref.listen<
      AsyncValue<Map<String, List<dynamic>>>
    >(timelineCalendarBookingsProvider, (previous, next) {
      // Only scroll once on initial load (not on every update)
      if (_hasScrolledToFirstBooking) return;

      // Wait for data to be available
      if (!next.hasValue || next.value == null) return;

      final bookingsByUnit = next.value!;
      final firstUpcoming = _findFirstUpcomingBooking(bookingsByUnit);

      if (firstUpcoming != null && mounted) {
        _hasScrolledToFirstBooking = true;
        // Small delay to ensure widget is fully built
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _forceScrollKey++;
              _currentRange = DateRangeSelection.days(
                firstUpcoming,
                _visibleDays,
              );
            });
          }
        });
      } else if (bookingsByUnit.isNotEmpty) {
        // No upcoming bookings found, mark as done to prevent repeated attempts
        _hasScrolledToFirstBooking = true;
      }
    });

    // Check if owner has any units - hide toolbar and FAB if empty
    final unitsAsync = ref.watch(allOwnerUnitsProvider);
    final hasUnits = unitsAsync.when(
      data: (units) => units.isNotEmpty,
      loading: () => true, // Show toolbar while loading to avoid flicker
      error: (_, _) => false, // Hide toolbar on error
    );

    // Check if calendar is empty to trigger tutorial (using filtered provider for accuracy)
    final bookingsAsync = ref.watch(timelineCalendarBookingsProvider);
    final isCalendarEmpty = bookingsAsync.when(
      data: (bookings) =>
          bookings.values.fold<int>(0, (sum, list) => sum + list.length) == 0,
      loading: () => false,
      error: (_, _) => false,
    );

    // Premium header inputs: month/year eyebrow (from the visible range start)
    // + unit count (filtered set, falling back to all units while filters load).
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final int unitCount =
        ref.watch(filteredUnitsProvider).valueOrNull?.length ??
        unitsAsync.valueOrNull?.length ??
        0;

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
                backgroundColor: Colors
                    .transparent, // Transparent to show gradient background
                appBar: CommonAppBar(
                  title: calendarTitle,
                  leadingIcon: Icons.menu,
                  onLeadingIconTap: (context) =>
                      Scaffold.of(context).openDrawer(),
                  // in-body header carries title (audit/126 §2A)
                  showTitle: false,
                ),
                drawer: const OwnerAppDrawer(currentRoute: 'calendar/timeline'),
                body: Container(
                  decoration: BoxDecoration(
                    gradient: context.gradients.pageBackground,
                  ),
                  child: Column(
                    children: [
                      // Premium header — eyebrow (month · unit count) + "Kalendar"
                      // title + Timeline/Mjesečni view switch. Matches handoff
                      // `calendar-premium.jsx` CALPHeader. Chrome only — the
                      // frozen grid below is untouched.
                      if (hasUnits)
                        _PremiumCalendarHeader(
                          isMobile: isMobile,
                          unitCount: unitCount,
                          month: _currentRange.startDate,
                        ),
                      // KPI strip — matches handoff `screens/03-owner.png` row
                      // above the timeline grid. Self-contained (watches the
                      // unified dashboard provider). Hidden when owner has no
                      // units (same gate as toolbar).
                      if (hasUnits) const MonthCalendarKpiStrip(),
                      // Top toolbar with integrated analytics toggle - OPTIMIZED: Single row
                      // CONDITIONAL: Hide toolbar when owner has no units
                      if (hasUnits)
                        Consumer(
                          builder: (context, ref, child) {
                            final unreadCountAsync = ref.watch(
                              unreadNotificationsCountProvider,
                            );
                            final multiSelectState = ref.watch(
                              multiSelectProvider,
                            );
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
                              isCompact:
                                  MediaQuery.of(context).size.width < 600,
                              // ENHANCED: Analytics toggle integrated in single row
                              showSummaryToggle: true,
                              isSummaryVisible: _showSummary,
                              onSummaryToggleChanged: (value) {
                                // Single setState; postFrameCallback lets
                                // AnimatedSize measure the new height before
                                // the second layout pass renders the summary bar.
                                setState(() {
                                  _showSummary = value;
                                });
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) setState(() {});
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
                                ref.invalidate(
                                  filteredCalendarBookingsProvider,
                                );
                                ref.invalidate(
                                  timelineCalendarBookingsProvider,
                                );
                              },
                            );
                          },
                        ),

                      // Timeline grid wrapped in the premium card (handoff
                      // `calendar-premium.jsx` CALPGridCard): the status legend
                      // becomes the card header, the frozen grid sits below in a
                      // bordered, rounded, soft-shadow surface. The grid keeps
                      // its bounded height via the inner Expanded — cell
                      // geometry, scroll controllers, and z-index are untouched.
                      Expanded(
                        child: hasUnits
                            ? Padding(
                                padding: EdgeInsets.fromLTRB(
                                  isMobile ? _kPagePadHMobile : _kPagePadH,
                                  BBSpace.xxs,
                                  isMobile ? _kPagePadHMobile : _kPagePadH,
                                  _kPagePadBottom,
                                ),
                                child: _CalendarGridCard(
                                  child: Column(
                                    children: [
                                      const _TimelineStatusLegend(),
                                      Expanded(child: _buildTimelineCalendar()),
                                    ],
                                  ),
                                ),
                              )
                            : _buildTimelineCalendar(),
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
                    );
                  },
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.endFloat,
              ),

              // Tutorial Overlay
              if (_shouldShowTutorial(hasUnits, isCalendarEmpty))
                CalendarTutorialOverlay(onDismiss: _dismissTutorial),
            ],
          ),
        ),
      ),
    );
  }

  /// The frozen timeline grid. Extracted so it can be hosted either bare
  /// (empty state) or inside the premium `_CalendarGridCard`. Cell geometry,
  /// scroll controllers, and the data providers are unchanged.
  Widget _buildTimelineCalendar() {
    return Consumer(
      builder: (context, ref, child) {
        final showEmptyUnits = ref.watch(showEmptyUnitsProvider);
        return TimelineCalendarWidget(
          // FIXED: Only use counter in key, NOT startDate
          // Including startDate caused infinite rebuild loop:
          // scroll → onVisibleDateRangeChanged → setState → key changes → rebuild → scroll...
          key: timelineKey,
          initialScrollToDate:
              _currentRange.startDate, // Scroll to selected date
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
              _showCreateBookingDialog(initialCheckIn: date, unitId: unit.id),
          onUnitNameTap: _showUnitFutureBookings,
          onVisibleDateRangeChanged: (startDate) {
            setState(() {
              _currentRange = DateRangeSelection.days(startDate, _visibleDays);
            });
          },
        );
      },
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
        backgroundColor: AppColors.error,
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
        await context.push(
          OwnerRoutes.bookingDetail.replaceFirst(
            ':bookingId',
            ownerBooking.booking.id,
          ),
        );
      }
    } catch (e) {
      // If booking not found, show error
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.ownerBookingsNotFound),
            backgroundColor: AppColors.error,
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

      final newRange = DateRangeSelection.days(picked, _visibleDays);
      _navigateTo(newRange);
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
  void _navigateTo(DateRangeSelection newRange) {
    setState(() {
      _currentRange = newRange;
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
  /// Returns DateTime (check-in date) on success, null on cancel
  void _showCreateBookingDialog({
    DateTime? initialCheckIn,
    String? unitId,
  }) async {
    final result = await showDialog<DateTime?>(
      context: context,
      builder: (context) =>
          BookingCreateDialog(initialCheckIn: initialCheckIn, unitId: unitId),
    );

    // If booking was created successfully, refresh calendar and scroll to new booking
    if (result != null && mounted) {
      // CRITICAL: Refresh providers BEFORE scrolling to ensure new data is available
      await Future.wait([
        ref.refresh(calendarBookingsProvider.future),
        ref.refresh(allOwnerUnitsProvider.future),
      ]);

      // Safety delay - ensures widget processes new data before scroll
      await Future.delayed(const Duration(milliseconds: 50));

      if (mounted) {
        // Scroll to the newly created booking's check-in date
        setState(() {
          _forceScrollKey++;
          _currentRange = DateRangeSelection.days(result, _visibleDays);
        });
      }
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

  const _AnimatedGradientFAB({required this.onPressed});

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
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Nova rezervacija',
      child: MouseRegion(
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
                  // Handoff CALPFab: solid primary circle + purple glow. Color
                  // from the BB token so dark mode lifts to #8B6FFF.
                  final Color fabColor = BBColor.of(context).primary;
                  return AnimatedContainer(
                    duration: BBMotion.base,
                    curve: Curves.easeOutCubic,
                    width: _kFabSize,
                    height: _kFabSize,
                    transform: Matrix4.diagonal3Values(
                      isPressed ? 0.92 : (isHovered ? 1.08 : 1.0),
                      isPressed ? 0.92 : (isHovered ? 1.08 : 1.0),
                      1.0,
                    ),
                    transformAlignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: fabColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: fabColor.withValues(
                            alpha: isHovered ? 0.5 : 0.35,
                          ),
                          blurRadius: isHovered ? 20 : 12,
                          offset: Offset(0, isHovered ? 8 : 4),
                          spreadRadius: isHovered ? 2 : 0,
                        ),
                      ],
                    ),
                    child: AnimatedRotation(
                      duration: BBMotion.base,
                      turns: isHovered
                          ? 0.125
                          : 0, // 45 degree rotation on hover
                      child: Icon(
                        Icons.add,
                        color: theme.colorScheme.onPrimary,
                        size: _kFabIcon,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Status legend row above the timeline grid — handoff
/// `calendar-timeline.jsx` legend (Potvrđeno · Na čekanju · Završeno ·
/// Otkazano · Uvezene). Mirrors `MonthCalendarScreen._buildStatusLegend`
/// shape but stays self-contained so it doesn't drag a state-bound private
/// builder across files.
class _TimelineStatusLegend extends StatelessWidget {
  const _TimelineStatusLegend();

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: _kCardPad,
        vertical: _kLegendPadV,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Wrap(
        spacing: BBSpace.xs,
        runSpacing: BBSpace.xs,
        children: [
          _legendBadge(
            context,
            BookingStatus.confirmed.colorOf(context),
            l10n.ownerStatusConfirmed,
          ),
          _legendBadge(
            context,
            BookingStatus.pending.colorOf(context),
            l10n.ownerStatusPending,
          ),
          _legendBadge(
            context,
            BookingStatus.completed.colorOf(context),
            l10n.ownerStatusCompleted,
          ),
          _legendBadge(
            context,
            BookingStatus.cancelled.colorOf(context),
            l10n.ownerStatusCancelled,
          ),
          _legendBadge(context, c.statusImported, l10n.bookingsTabImported),
        ],
      ),
    );
  }

  /// Handoff status badge: status dot + label in a rounded-full chip with a
  /// soft tint of the status colour.
  Widget _legendBadge(BuildContext context, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _kBadgePadH,
        vertical: _kBadgePadV,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BBRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _kBadgeDot,
            height: _kBadgeDot,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: BBSpace.xs),
          Text(
            label,
            style: BBType.caption(
              context,
            ).copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Premium chrome constants (handoff `calendar-premium.jsx`) ──
// Off-scale values kept exact via named consts per the BookBed token standard
// (BB* tokens + named in-file consts; no bare literals in new chrome). On-scale
// values (4/8/16/24 spacing, 20 radius) use BBSpace/BBRadius directly.
const double _kPagePadH = 20.0; // desktop page edge — aligns with KPI strip
const double _kPagePadHMobile =
    12.0; // mobile page edge — aligns with KPI strip
const double _kPagePadBottom = 16.0;
const double _kCardPad = 16.0; // grid-card / legend horizontal padding
const double _kLegendPadV = 12.0; // legend header vertical padding
const double _kBadgePadH = 10.0; // status badge horizontal padding
const double _kBadgePadV = 5.0; // status badge vertical padding
const double _kBadgeDot = 7.0; // status badge dot diameter
const double _kFabSize = 56.0; // FAB diameter (handoff CALPFab)
const double _kFabIcon = 28.0; // FAB add-icon size
const double _kSegPadH = 14.0; // view-switch segment horizontal padding
const double _kSegFont = 13.0; // view-switch segment label size
const double _kSegIcon = 16.0; // view-switch segment icon size
const double _kTitleDesktop = 30.0; // "Kalendar" title (desktop)
const double _kTitleMobile = 24.0; // "Kalendar" title (mobile)

/// Premium calendar header — eyebrow (`<Mjesec> <god> · N jedinica`) + the
/// "Kalendar" H1 title + the Timeline/Mjesečni view switch. Mirrors the
/// Rezervacije/Pregled `_PremiumHeaderRow` composition. Pure (no provider
/// watch) so the `buildChromeForTest` overflow harness can render it headless.
class _PremiumCalendarHeader extends StatelessWidget {
  final bool isMobile;
  final int unitCount;
  final DateTime month;

  const _PremiumCalendarHeader({
    required this.isMobile,
    required this.unitCount,
    required this.month,
  });

  // Nominative Croatian month names (handoff eyebrow shows "Lipanj 2026").
  static const List<String> _hrMonths = <String>[
    'Siječanj',
    'Veljača',
    'Ožujak',
    'Travanj',
    'Svibanj',
    'Lipanj',
    'Srpanj',
    'Kolovoz',
    'Rujan',
    'Listopad',
    'Studeni',
    'Prosinac',
  ];

  /// Croatian count agreement for "jedinica" (1 → jedinica, 2-4 → jedinice,
  /// else → jedinica; 11-14 exception handled).
  static String _unitsWord(int n) {
    final int mod10 = n % 10;
    final int mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'jedinica';
    if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) {
      return 'jedinice';
    }
    return 'jedinica';
  }

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);
    final String monthName = _hrMonths[(month.month - 1).clamp(0, 11)];
    final String eyebrow =
        '$monthName ${month.year} · $unitCount ${_unitsWord(unitCount)}';

    final Widget titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          eyebrow.toUpperCase(),
          style: BBType.eyebrow(context).copyWith(color: c.primary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: BBSpace.xxs),
        Text(
          l10n.ownerCalendar,
          style: BBType.h1(context).copyWith(
            fontSize: isMobile ? _kTitleMobile : _kTitleDesktop,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );

    final EdgeInsets pad = EdgeInsets.fromLTRB(
      isMobile ? _kPagePadHMobile : _kPagePadH,
      isMobile ? _kPagePadHMobile : _kPagePadH,
      isMobile ? _kPagePadHMobile : _kPagePadH,
      BBSpace.xxs,
    );

    return Padding(
      padding: pad,
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                titleBlock,
                const SizedBox(height: BBSpace.xs),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: _CalendarViewSwitch(),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(child: titleBlock),
                const SizedBox(width: BBSpace.sm),
                const _CalendarViewSwitch(),
              ],
            ),
    );
  }
}

/// Timeline / Mjesečni segmented control (handoff CALPViewSwitch). "Timeline"
/// is the active no-op (we are on it); "Mjesečni" routes to the existing
/// month-calendar screen. Pill track + surface chip on the active segment —
/// mirrors the Pregled `_DateRangeSelector` / `_PeriodSegment` visual.
class _CalendarViewSwitch extends StatelessWidget {
  const _CalendarViewSwitch();

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Container(
      padding: const EdgeInsets.all(BBSpace.xxs),
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BorderRadius.circular(BBRadius.full),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _ViewSegment(
            icon: Icons.view_timeline_outlined,
            label: 'Timeline',
            selected: true,
            onTap: null,
          ),
          _ViewSegment(
            icon: Icons.calendar_view_month_outlined,
            label: 'Mjesečni',
            selected: false,
            onTap: () => context.go(OwnerRoutes.calendarMonth),
          ),
        ],
      ),
    );
  }
}

class _ViewSegment extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ViewSegment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BBRadius.full),
          child: AnimatedContainer(
            duration: BBMotion.base,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: _kSegPadH,
              vertical: BBSpace.xs,
            ),
            decoration: BoxDecoration(
              // Active state: surface chip + shadow-sm on the surface-variant
              // track (handoff PVPeriod), not a primary fill.
              color: selected ? c.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(BBRadius.full),
              boxShadow: selected ? BBShadow.sm : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: _kSegIcon,
                  color: selected ? c.primary : c.textSecondary,
                ),
                const SizedBox(width: BBSpace.xxs),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? c.textPrimary : c.textSecondary,
                    fontSize: _kSegFont,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: -0.1,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium grid card (handoff CALPGridCard). Wraps the legend header + frozen
/// timeline grid in one bordered, rounded, soft-shadow surface. The shadow +
/// border are painted by the outer [DecoratedBox] (a [ClipRRect] cannot paint a
/// shadow, and the 1px border must survive the clip); the grid scrolls INSIDE
/// the [ClipRRect]. Cell geometry, scroll controllers, and z-index are
/// untouched — only a visual container is added around the grid.
class _CalendarGridCard extends StatelessWidget {
  final Widget child;

  const _CalendarGridCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BBRadius.mdAll,
        border: Border.all(color: c.border),
        boxShadow: BBShadow.cardElevated,
      ),
      child: ClipRRect(borderRadius: BBRadius.mdAll, child: child),
    );
  }
}
