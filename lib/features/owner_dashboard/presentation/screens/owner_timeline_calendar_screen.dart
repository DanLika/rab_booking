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
import '../widgets/calendar/multi_select_action_bar.dart';
import '../widgets/booking_create_dialog.dart';
import '../widgets/booking_quick_create_dialog.dart';
import '../widgets/owner_app_drawer.dart';
import '../mixins/calendar_common_methods_mixin.dart';
import '../providers/multi_select_provider.dart';
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
            appBar: CommonAppBar(
              title: 'Kalendar - Gantt prikaz',
              leadingIcon: Icons.menu,
              onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
            ),
            drawer: const OwnerAppDrawer(currentRoute: 'calendar/timeline'),
      body: Column(
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
            ),
          ),

          // Multi-select action bar (bottom)
          const MultiSelectActionBar(),
        ],
      ),
            floatingActionButton: Consumer(
              builder: (context, ref, child) {
                final multiSelectState = ref.watch(multiSelectProvider);

                // Hide FAB when multi-select is active
                if (multiSelectState.isEnabled) {
                  return const SizedBox.shrink();
                }

                return FloatingActionButton(
                  onPressed: _showBookingOptionsBottomSheet,
                  backgroundColor: AppColors.primary,
                  elevation: 4,
                  child: const Icon(Icons.add, color: Colors.white),
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

  /// Show booking options bottom sheet
  void _showBookingOptionsBottomSheet() async {
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Odaberi način kreiranja',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Quick booking option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Brza rezervacija',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Samo osnovni podaci - brzo i jednostavno'),
                onTap: () {
                  Navigator.pop(context);
                  _showQuickBookingDialog();
                },
              ),
              const Divider(height: 1),
              // Full booking option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: AppColors.secondary,
                  ),
                ),
                title: const Text(
                  'Detaljna rezervacija',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Svi detalji i dodatne opcije'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateBookingDialog();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Show quick booking dialog
  void _showQuickBookingDialog({
    DateTime? initialCheckIn,
    String? unitId,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BookingQuickCreateDialog(
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
  /// Bug Fix: Refresh button was showing August instead of current month (November)
  /// because _currentRange was not being reset to today
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
