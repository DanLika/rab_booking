import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../domain/models/date_range_selection.dart';
import '../../domain/models/calendar_filter_options.dart';
import '../providers/owner_calendar_provider.dart';
import '../providers/calendar_filters_provider.dart';
import '../providers/notifications_provider.dart';
import '../widgets/calendar/owner_week_grid_calendar.dart';
import '../widgets/calendar/calendar_top_toolbar.dart';
import '../widgets/calendar/booking_inline_edit_dialog.dart';
import '../widgets/calendar/calendar_filters_panel.dart';
import '../widgets/calendar/unit_future_bookings_dialog.dart';
import '../widgets/booking_create_dialog.dart';
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
    extends ConsumerState<OwnerWeekCalendarScreen> {
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
    final filters = ref.watch(calendarFiltersProvider);
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

          // Calendar grid
          Expanded(
            child: unitsAsync.when(
              data: (units) {
                if (units.isEmpty) {
                  return _buildEmptyState();
                }

                return bookingsAsync.when(
                  data: (bookingsMap) {
                    return OwnerWeekGridCalendar(
                      dateRange: _currentWeek,
                      units: units,
                      bookings: bookingsMap,
                      onBookingTap: _showBookingDetails,
                      onCellTap: (date, unit) {
                        _showCreateBookingDialog(date, unit.id);
                      },
                      onRoomHeaderTap: _showUnitFutureBookings,
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
              ...['Ime gosta', 'Email', 'Telefon', 'ID rezervacije', 'Referenca'].map(
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
      // Always dispose controller after dialog closes
      searchController.dispose();
    }
  }

  /// Perform search and show results
  void _performSearch(String query) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // FIXED: Get all bookings properly with async/await
      final bookingsMap = await ref.read(calendarBookingsProvider.future);
      final allBookings = bookingsMap.values.expand((list) => list).toList();

      final queryLower = query.toLowerCase();
      final results = allBookings.where((booking) {
        return (booking.guestName?.toLowerCase().contains(queryLower) ?? false) ||
               (booking.guestEmail?.toLowerCase().contains(queryLower) ?? false) ||
               (booking.guestPhone?.toLowerCase().contains(queryLower) ?? false) ||
               booking.id.toLowerCase().contains(queryLower);
      }).toList();

      // Close loading
      if (mounted) {
        Navigator.of(context).pop();

        // Show results dialog
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
      // Close loading
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
        onBookingTap: _showBookingDetails,
      ),
    );
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
        // Header skeleton
        const SkeletonLoader(
          width: double.infinity,
          height: 60,
        ),
        const SizedBox(height: 8),
        // Grid skeleton
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
