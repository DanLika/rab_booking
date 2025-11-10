import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../widgets/booking_create_dialog.dart';
import '../mixins/calendar_common_methods_mixin.dart';
import '../../utils/calendar_grid_calculator.dart';

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

  @override
  void initState() {
    super.initState();
    // Initialize to current week (Monday-Sunday)
    _currentWeek = DateRangeSelection.week(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(allOwnerUnitsProvider);
    final bookingsAsync = ref.watch(filteredCalendarBookingsProvider);
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);

    return Column(
        children: [
          // Top toolbar
          CalendarTopToolbar(
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
            isCompact: MediaQuery.of(context).size.width < CalendarGridCalculator.mobileBreakpoint,
          ),

          // Filter chips (from shared widget)
          const CalendarFilterChips(),

          // Calendar grid
          Expanded(
            child: unitsAsync.when(
              data: (units) {
                if (units.isEmpty) {
                  return CalendarStateBuilders.buildEmptyState(context);
                }

                return bookingsAsync.when(
                  data: (bookingsMap) {
                    return OwnerWeekGridCalendar(
                      dateRange: _currentWeek,
                      units: units,
                      bookings: bookingsMap,
                      onBookingTap: showBookingDetailsDialog,
                      onCellTap: (date, unit) {
                        _showCreateBookingDialog(date, unit.id);
                      },
                      onRoomHeaderTap: _showUnitFutureBookings,
                      enableDragDrop: true,
                    );
                  },
                  loading: () => CalendarStateBuilders.buildLoadingState(),
                  error: (error, stack) => CalendarStateBuilders.buildErrorState(
                    context,
                    error,
                    refreshCalendarData,
                  ),
                );
              },
              loading: () => CalendarStateBuilders.buildLoadingState(),
              error: (error, stack) => CalendarStateBuilders.buildErrorState(
                context,
                error,
                refreshCalendarData,
              ),
            ),
          ),
        ],
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
  void _showCreateBookingDialog([DateTime? initialDate, String? unitId]) {
    showDialog(
      context: context,
      builder: (context) => BookingCreateDialog(
        unitId: unitId,
        initialCheckIn: initialDate,
      ),
    );
  }

  /// Show unit future bookings dialog
  void _showUnitFutureBookings(UnitModel unit, List<BookingModel> bookings) {
    // Filter for future bookings only (check-out >= today)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final futureBookings = bookings.where((booking) {
      return !booking.checkOut.isBefore(today);
    }).toList()
      ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

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
