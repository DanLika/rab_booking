import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../domain/models/date_range_selection.dart';
import '../providers/owner_calendar_provider.dart';
import '../providers/calendar_filters_provider.dart';
import '../providers/notifications_provider.dart';
import '../widgets/calendar/owner_week_grid_calendar.dart';
import '../widgets/calendar/calendar_top_toolbar.dart';
import '../widgets/calendar/calendar_filter_chips.dart';
import '../widgets/calendar/calendar_state_builders.dart';
import '../widgets/calendar/unit_future_bookings_dialog.dart';
import '../widgets/calendar/shared/calendar_summary_bar.dart';
import '../widgets/booking_create_dialog.dart';
import '../widgets/owner_app_drawer.dart';
import '../mixins/calendar_common_methods_mixin.dart';
import '../../utils/calendar_grid_calculator.dart';
import '../../../../shared/widgets/common_app_bar.dart';

/// Owner Week Calendar Screen
/// Shows 7-day grid view of all units and bookings
class OwnerWeekCalendarScreen extends ConsumerStatefulWidget {
  const OwnerWeekCalendarScreen({super.key});

  @override
  ConsumerState<OwnerWeekCalendarScreen> createState() =>
      _OwnerWeekCalendarScreenState();
}

class _OwnerWeekCalendarScreenState
    extends ConsumerState<OwnerWeekCalendarScreen>
    with CalendarCommonMethodsMixin {
  late DateRangeSelection _currentWeek;
  bool _showSummary = false;

  @override
  void initState() {
    super.initState();
    // Initialize to current week (Monday-Sunday)
    _currentWeek = DateRangeSelection.week(DateTime.now());
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
            onInvoke: (_) => _goToPreviousWeek(),
          ),
          _NextPeriodIntent: CallbackAction<_NextPeriodIntent>(
            onInvoke: (_) => _goToNextWeek(),
          ),
          _TodayIntent: CallbackAction<_TodayIntent>(
            onInvoke: (_) => _goToToday(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: CommonAppBar(
              title: 'Kalendar - Tjedni prikaz',
              leadingIcon: Icons.menu,
              onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
            ),
            drawer: const OwnerAppDrawer(currentRoute: 'calendar/week'),
      body: Column(
        children: [
          // Top toolbar with summary toggle - OPTIMIZED: Consumer for notifications only
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
                      dateRange: _currentWeek,
                      isWeekView: true,
                      onPreviousPeriod: _goToPreviousWeek,
                      onNextPeriod: _goToNextWeek,
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
                      isCompact:
                          MediaQuery.of(context).size.width <
                          CalendarGridCalculator.mobileBreakpoint,
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

          // Calendar grid + Summary bar - OPTIMIZED: Consumer for units + bookings
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final unitsAsync = ref.watch(allOwnerUnitsProvider);
                final bookingsAsync = ref.watch(filteredCalendarBookingsProvider);

                return unitsAsync.when(
                  data: (units) {
                    if (units.isEmpty) {
                      return CalendarStateBuilders.buildEmptyState(context);
                    }

                    return bookingsAsync.when(
                      data: (bookingsMap) {
                        // Check if there are any bookings at all
                        final hasAnyBookings = bookingsMap.values.any((list) => list.isNotEmpty);

                        // Show empty state if no bookings exist
                        if (!hasAnyBookings) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 80,
                                    color: Theme.of(context).colorScheme.primary.withAlpha((0.3 * 255).toInt()),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Nema rezervacija',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Dodajte prvu rezervaciju klikom na dugme ispod',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha((0.7 * 255).toInt()),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),
                                  ElevatedButton.icon(
                                    onPressed: _showCreateBookingDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Nova rezervacija'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final screenWidth = MediaQuery.of(context).size.width;
                        final dayCellWidth = CalendarGridCalculator.getDayCellWidth(screenWidth, 7);

                        return Column(
                          children: [
                            // Calendar grid
                            Expanded(
                              child: OwnerWeekGridCalendar(
                                dateRange: _currentWeek,
                                units: units,
                                bookings: bookingsMap,
                                onBookingTap: showBookingDetailsDialog,
                                onCellTap: (date, unit) {
                                  _showCreateBookingDialog(date, unit.id);
                                },
                                onRoomHeaderTap: _showUnitFutureBookings,
                              ),
                            ),
                            // Summary bar (optional)
                            if (_showSummary)
                              CalendarSummaryBar(
                                dates: _currentWeek.dates,
                                bookingsByUnit: bookingsMap,
                                cellWidth: dayCellWidth,
                              ),
                          ],
                        );
                      },
                      loading: CalendarStateBuilders.buildLoadingState,
                      error: (error, stack) => CalendarStateBuilders.buildErrorState(
                        context,
                        error,
                        refreshCalendarData,
                      ),
                    );
                  },
                  loading: CalendarStateBuilders.buildLoadingState,
                  error: (error, stack) => CalendarStateBuilders.buildErrorState(
                    context,
                    error,
                    refreshCalendarData,
                  ),
                );
              },
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

  /// Go to previous week
  void _goToPreviousWeek() {
    setState(() {
      _currentWeek = _currentWeek.previous(isWeek: true);
    });
  }

  /// Go to next week
  void _goToNextWeek() {
    setState(() {
      _currentWeek = _currentWeek.next(isWeek: true);
    });
  }

  /// Go to today's week
  void _goToToday() {
    setState(() {
      _currentWeek = DateRangeSelection.week(DateTime.now());
    });
  }

  /// Show date picker dialog
  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentWeek.startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _currentWeek = DateRangeSelection.week(picked);
      });
    }
  }

  /// Show create booking dialog
  void _showCreateBookingDialog([DateTime? initialDate, String? unitId]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          BookingCreateDialog(unitId: unitId, initialCheckIn: initialDate),
    );

    // If booking was created successfully, refresh calendar
    if (result == true && mounted) {
      await refreshCalendarData();
    }
  }

  /// Show unit future bookings dialog
  void _showUnitFutureBookings(UnitModel unit, List<BookingModel> bookings) {
    // Filter for future bookings only (check-out >= today)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final futureBookings = bookings.where((booking) {
      return !booking.checkOut.isBefore(today);
    }).toList()..sort((a, b) => a.checkIn.compareTo(b.checkIn));

    showDialog(
      context: context,
      builder: (context) => UnitFutureBookingsDialog(
        unit: unit,
        bookings: futureBookings,
        onBookingTap: showBookingDetailsDialog,
      ),
    );
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
