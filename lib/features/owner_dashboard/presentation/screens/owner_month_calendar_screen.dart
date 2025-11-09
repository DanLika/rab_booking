import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../domain/models/date_range_selection.dart';
import '../../domain/models/calendar_filter_options.dart';
import '../providers/owner_calendar_provider.dart';
import '../providers/calendar_filters_provider.dart';
import '../widgets/calendar/owner_month_grid_calendar.dart';
import '../widgets/calendar/calendar_top_toolbar.dart';
import '../widgets/calendar/booking_inline_edit_dialog.dart';
import '../widgets/calendar/calendar_filters_panel.dart';
import '../widgets/booking_create_dialog.dart';
import '../widgets/calendar/calendar_search_dialog.dart';
import '../providers/notifications_provider.dart';
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
    extends ConsumerState<OwnerMonthCalendarScreen> {
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
    final filters = ref.watch(calendarFiltersProvider);
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
            onSearchTap: _showSearch,
            onRefresh: _refreshData,
            onFilterTap: _showFilters,
            notificationCount: unreadCountAsync.when(
              data: (count) => count,
              loading: () => 0,
              error: (error, stackTrace) => 0,
            ),
            onNotificationsTap: _showNotifications,
            isCompact: MediaQuery.of(context).size.width < CalendarGridCalculator.mobileBreakpoint,
          ),

          // Filter chips (if any filters are active)
          if (filters.hasActiveFilters)
            Container(
              constraints: const BoxConstraints(maxHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Chip(
                            label: Text('${filters.activeFilterCount} filters'),
                            onDeleted: () {
                              ref
                                  .read(calendarFiltersProvider.notifier)
                                  .clearFilters();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear all'),
                    onPressed: () {
                      ref.read(calendarFiltersProvider.notifier).clearFilters();
                    },
                  ),
                ],
              ),
            ),

          // Calendar grid
          Expanded(
            child: unitsAsync.when(
              data: (units) {
                if (units.isEmpty) {
                  return _buildEmptyState();
                }

                return bookingsAsync.when(
                  data: (bookingsMap) {
                    return OwnerMonthGridCalendar(
                      dateRange: _currentMonth,
                      units: units,
                      bookings: bookingsMap,
                      onBookingTap: _showBookingDetails,
                      onCellTap: (date, unit) {
                        _showCreateBookingDialog(date, unit.id);
                      },
                      enableDragDrop: true,
                    );
                  },
                  loading: () => _buildLoadingState(),
                  error: (error, stack) => _buildErrorState(error),
                );
              },
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error),
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

  /// Show search dialog
  void _showSearch() async {
    final selectedBooking = await showDialog<BookingModel>(
      context: context,
      builder: (context) => const CalendarSearchDialog(),
    );

    // If user selected a booking from search results, show its details
    if (selectedBooking != null && mounted) {
      _showBookingDetails(selectedBooking);
    }
  }

  /// Refresh calendar data - FULL page refresh
  void _refreshData() async {
    // Show loading snackbar
    ErrorDisplayUtils.showLoadingSnackBar(context, 'Osvježavam podatke...');

    try {
      // Properly await all provider refreshes
      await Future.wait([
        ref.refresh(calendarBookingsProvider.future),
        ref.refresh(allOwnerUnitsProvider.future),
        ref.refresh(unreadNotificationsCountProvider.future),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ErrorDisplayUtils.showSuccessSnackBar(context, 'Podaci osvježeni');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ErrorDisplayUtils.showErrorSnackBar(context, e);
      }
    }
  }

  /// Show filters panel
  void _showFilters() async {
    await showDialog(
      context: context,
      builder: (context) => const CalendarFiltersPanel(),
    );
  }

  /// Show notifications panel
  void _showNotifications() {
    // TODO: Implement notifications panel
    ErrorDisplayUtils.showInfoSnackBar(
      context,
      'Notifications panel - coming soon',
    );
  }

  /// Show booking details dialog with quick edit option
  void _showBookingDetails(BookingModel booking) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BookingInlineEditDialog(booking: booking),
    );

    // If edited successfully, result will be true
    if (result == true && mounted) {
      // Calendar already refreshed by dialog
    }
  }

  /// Show create booking dialog
  void _showCreateBookingDialog([DateTime? initialDate, String? unitId]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BookingCreateDialog(
        unitId: unitId,
        initialCheckIn: initialDate,
      ),
    );

    // If booking was created successfully, refresh calendar
    if (result == true && mounted) {
      _refreshData();
    }
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_work_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No units found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add units to your properties to see them in the calendar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return Column(
      children: [
        const SkeletonLoader(
          width: double.infinity,
          height: 60,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: 8,
            itemBuilder: (context, index) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 60,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build error state
  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading calendar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
