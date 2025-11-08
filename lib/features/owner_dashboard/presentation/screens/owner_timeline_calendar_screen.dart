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
  Widget build(BuildContext context, WidgetRef ref) {
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
        const Expanded(
          child: TimelineCalendarWidget(),
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

  /// Show search dialog
  void _showSearch() async {
    final TextEditingController searchController = TextEditingController();

    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pretraži rezervacije'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Pretraga',
                    hintText: 'Ime gosta, email, ID rezervacije...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty && mounted) {
                      Navigator.of(context).pop();
                      _performSearch(value.trim());
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Pretražuje se po:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                ...['Ime gosta', 'Email', 'Telefon', 'ID rezervacije'].map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(item, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () {
                if (searchController.text.trim().isNotEmpty && mounted) {
                  Navigator.of(context).pop();
                  _performSearch(searchController.text.trim());
                }
              },
              child: const Text('Pretraži'),
            ),
          ],
        ),
      );
    } finally {
      searchController.dispose();
    }
  }

  /// Perform search and show results
  void _performSearch(String query) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final bookingsMap = await ref.read(calendarBookingsProvider.future);
      final allBookings = bookingsMap.values.expand((list) => list).toList();

      final queryLower = query.toLowerCase();
      final results = allBookings.where((booking) {
        return (booking.guestName?.toLowerCase().contains(queryLower) ?? false) ||
            (booking.guestEmail?.toLowerCase().contains(queryLower) ?? false) ||
            (booking.guestPhone?.toLowerCase().contains(queryLower) ?? false) ||
            booking.id.toLowerCase().contains(queryLower);
      }).toList();

      if (mounted) {
        Navigator.of(context).pop();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Rezultati pretrage (${results.length})'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 600,
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: results.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Nema rezultata za traženi pojam'),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final booking = results[index];
                        final guestName = booking.guestName ?? 'Unknown';
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(guestName.isNotEmpty ? guestName[0].toUpperCase() : '?'),
                          ),
                          title: Text(guestName),
                          subtitle: Text(
                            '${booking.guestEmail ?? "No email"}\n'
                            'Check-in: ${booking.checkIn.day}.${booking.checkIn.month}.${booking.checkIn.year}.',
                          ),
                          trailing: Chip(
                            label: Text(booking.status.displayName),
                            backgroundColor: booking.status.color.withValues(alpha: 0.2),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showBookingDetails(booking);
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Zatvori'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška pri pretraživanju rezervacija',
        );
      }
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
}
