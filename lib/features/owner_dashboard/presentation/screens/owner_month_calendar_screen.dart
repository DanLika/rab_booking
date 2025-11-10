import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/date_range_selection.dart';
import '../providers/owner_calendar_provider.dart';
import '../providers/calendar_filters_provider.dart';
import '../widgets/calendar/owner_month_grid_calendar.dart';
import '../widgets/calendar/calendar_top_toolbar.dart';
import '../widgets/calendar/calendar_filter_chips.dart';
import '../widgets/calendar/calendar_state_builders.dart';
import '../widgets/booking_create_dialog.dart';
import '../providers/notifications_provider.dart';
import '../mixins/calendar_common_methods_mixin.dart';
import '../../utils/calendar_grid_calculator.dart';

/// Owner Month Calendar Screen
/// Shows 28-31 day grid view of all units and bookings (full month)
class OwnerMonthCalendarScreen extends ConsumerStatefulWidget {
  const OwnerMonthCalendarScreen({super.key});

  @override
  ConsumerState<OwnerMonthCalendarScreen> createState() =>
      _OwnerMonthCalendarScreenState();
}

class _OwnerMonthCalendarScreenState
    extends ConsumerState<OwnerMonthCalendarScreen>
    with CalendarCommonMethodsMixin {
  late DateRangeSelection _currentMonth;

  @override
  void initState() {
    super.initState();
    // Initialize to current month (1st - last day)
    _currentMonth = DateRangeSelection.month(DateTime.now());
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
          dateRange: _currentMonth,
          isWeekView: false, // Month view
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
          isCompact:
              MediaQuery.of(context).size.width <
              CalendarGridCalculator.mobileBreakpoint,
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
                  return OwnerMonthGridCalendar(
                    dateRange: _currentMonth,
                    units: units,
                    bookings: bookingsMap,
                    onBookingTap: showBookingDetailsDialog,
                    onCellTap: (date, unit) {
                      _showCreateBookingDialog(date, unit.id);
                    },
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
          ),
        ),
      ],
    );
  }

  /// Go to previous month
  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = _currentMonth.previous(isWeek: false);
    });
  }

  /// Go to next month
  void _goToNextMonth() {
    setState(() {
      _currentMonth = _currentMonth.next(isWeek: false);
    });
  }

  /// Go to current month
  void _goToToday() {
    setState(() {
      _currentMonth = DateRangeSelection.month(DateTime.now());
    });
  }

  /// Show date picker dialog
  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentMonth.startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _currentMonth = DateRangeSelection.month(picked);
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
      unawaited(refreshCalendarData());
    }
  }
}
