import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../shared/models/booking_model.dart';
import '../../domain/models/calendar_filter_options.dart';
import '../../domain/models/date_range_selection.dart';
import '../providers/calendar_filters_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/owner_calendar_provider.dart';
import '../widgets/timeline_calendar_widget.dart';
import '../widgets/calendar/calendar_top_toolbar.dart';
import '../widgets/calendar/calendar_filters_panel.dart';
import '../widgets/calendar/calendar_search_dialog.dart';
import '../widgets/calendar/booking_inline_edit_dialog.dart';
import '../../utils/calendar_grid_calculator.dart';

/// Owner Timeline Calendar Screen
/// Shows BedBooking-style Gantt chart with booking blocks spanning dates
class OwnerTimelineCalendarScreen extends ConsumerStatefulWidget {
  const OwnerTimelineCalendarScreen({super.key});

  @override
  ConsumerState<OwnerTimelineCalendarScreen> createState() =>
      _OwnerTimelineCalendarScreenState();
}

class _OwnerTimelineCalendarScreenState
    extends ConsumerState<OwnerTimelineCalendarScreen> {
  late DateRangeSelection _currentRange;

  @override
  void initState() {
    super.initState();
    // Initialize with current month
    _currentRange = DateRangeSelection.month(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(calendarFiltersProvider);
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);

    return Column(
      children: [
        // Top toolbar with navigation and actions
        CalendarTopToolbar(
          dateRange: _currentRange,
          isWeekView: false,
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

        // Timeline calendar widget (it fetches its own data via providers)
        Expanded(
          child: TimelineCalendarWidget(
            key: ValueKey(_currentRange.startDate), // Rebuild on date change
          ),
        ),
      ],
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

  /// Show search dialog (unified with Week and Month views)
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

  /// Show booking details dialog
  void _showBookingDetails(BookingModel booking) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BookingInlineEditDialog(booking: booking),
    );

    if (result == true && mounted) {
      // Calendar already refreshed by dialog
    }
  }

  /// Refresh calendar data
  void _refreshData() async {
    ErrorDisplayUtils.showLoadingSnackBar(context, 'Osvježavam podatke...');

    try {
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
}
