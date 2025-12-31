import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../domain/models/date_range_selection.dart';
import '../../../utils/calendar_grid_calculator.dart';
import '../../../utils/date_range_utils.dart';
import '../../providers/calendar_drag_drop_provider.dart';
import 'booking_block_widget.dart';
import 'booking_context_menu.dart';
import 'room_row_header.dart';
import '../send_email_dialog.dart';

/// Owner month grid calendar widget
/// Shows 28-31 day grid with all units and bookings (one month view)
class OwnerMonthGridCalendar extends ConsumerStatefulWidget {
  final DateRangeSelection dateRange;
  final List<UnitModel> units;
  final Map<String, List<BookingModel>> bookings;
  final Function(BookingModel) onBookingTap;
  final Function(DateTime date, UnitModel unit)? onCellTap;
  final bool enableDragDrop;

  const OwnerMonthGridCalendar({
    super.key,
    required this.dateRange,
    required this.units,
    required this.bookings,
    required this.onBookingTap,
    this.onCellTap,
    this.enableDragDrop = true,
  });

  @override
  ConsumerState<OwnerMonthGridCalendar> createState() =>
      _OwnerMonthGridCalendarState();
}

class _OwnerMonthGridCalendarState
    extends ConsumerState<OwnerMonthGridCalendar> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dates = widget.dateRange.dates;
    final daysInMonth = dates.length;

    // Calculate dimensions
    final rowHeaderWidth =
        CalendarGridCalculator.getRowHeaderWidth(screenWidth);
    final rowHeight = CalendarGridCalculator.getRowHeight(screenWidth);
    final dayCellWidth =
        CalendarGridCalculator.getDayCellWidth(screenWidth, daysInMonth);
    final headerHeight = CalendarGridCalculator.headerHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Date headers row (fixed, doesn't scroll vertically)
            SizedBox(
              height: headerHeight,
              child: Row(
                children: [
                  // Empty corner (aligns with room headers)
                  SizedBox(width: rowHeaderWidth),

                  // Date headers (scroll horizontally with grid)
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: dates.map((date) {
                          return _buildDateHeader(
                            date: date,
                            width: dayCellWidth,
                            height: headerHeight,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Grid body (scrolls both horizontally and vertically)
            Expanded(
              child: Row(
                children: [
                  // Room headers column (fixed, scrolls vertically with grid)
                  SizedBox(
                    width: rowHeaderWidth,
                    child: SingleChildScrollView(
                      controller: _verticalScrollController,
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        children: widget.units.map((unit) {
                          // Get bookings for this unit
                          final unitBookings = widget.bookings[unit.id] ?? [];

                          return RoomRowHeader(
                            unit: unit,
                            width: rowHeaderWidth,
                            height: rowHeight,
                            isCompact: screenWidth <
                                CalendarGridCalculator.mobileBreakpoint,
                            bookings: unitBookings,
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Calendar grid (scrolls both directions)
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: dayCellWidth * daysInMonth,
                        child: SingleChildScrollView(
                          controller: _verticalScrollController,
                          physics: const ClampingScrollPhysics(),
                          child: Stack(
                            children: [
                              // Grid cells (background)
                              Column(
                                children: widget.units.map((unit) {
                                  return _buildUnitRow(
                                    unit: unit,
                                    dates: dates,
                                    rowHeight: rowHeight,
                                    dayCellWidth: dayCellWidth,
                                  );
                                }).toList(),
                              ),

                              // Booking blocks (overlay)
                              ...widget.units.asMap().entries.map((entry) {
                                final index = entry.key;
                                final unit = entry.value;
                                return _buildBookingBlocks(
                                  unit: unit,
                                  rowIndex: index,
                                  dates: dates,
                                  rowHeight: rowHeight,
                                  dayCellWidth: dayCellWidth,
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build date header cell
  Widget _buildDateHeader({
    required DateTime date,
    required double width,
    required double height,
  }) {
    final theme = Theme.of(context);
    final isToday = DateRangeUtils.isToday(date);
    final isWeekend = DateRangeUtils.isWeekend(date);
    final isFirstOfMonth = date.day == 1;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isToday
            ? theme.colorScheme.primary.withAlpha((0.2 * 255).toInt())
            : theme.cardColor,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withAlpha((0.3 * 255).toInt()),
          ),
          bottom: BorderSide(color: theme.dividerColor),
          left: isFirstOfMonth
              ? BorderSide(color: theme.dividerColor, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Weekday name (abbreviated for month view)
          Text(
            _getWeekdayAbbreviation(date.weekday),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isWeekend
                  ? theme.colorScheme.error
                  : (isToday ? theme.colorScheme.primary : null),
            ),
          ),
          const SizedBox(height: 2),
          // Day number
          Container(
            width: 24,
            height: 24,
            decoration: isToday
                ? BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  )
                : null,
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isToday ? theme.colorScheme.onPrimary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build unit row (grid cells for one unit across all dates)
  Widget _buildUnitRow({
    required UnitModel unit,
    required List<DateTime> dates,
    required double rowHeight,
    required double dayCellWidth,
  }) {
    final theme = Theme.of(context);
    final unitBookings = widget.bookings[unit.id] ?? [];

    // Performance Optimization: Pre-calculate booked days for O(1) lookup.
    // This avoids iterating through all bookings for every single day cell.
    final bookedDates = <DateTime>{};
    if (unitBookings.isNotEmpty) {
      for (final booking in unitBookings) {
        final checkIn = DateTime(
            booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
        final checkOut = DateTime(
            booking.checkOut.year, booking.checkOut.month, booking.checkOut.day);

        // Add all days from check-in up to (but not including) check-out.
        for (var d = checkIn;
            d.isBefore(checkOut);
            d = d.add(const Duration(days: 1))) {
          bookedDates.add(d);
        }
        // The original logic also considered the checkout day as "booked" for the
        // purpose of hiding the '+' icon, so we add it here to match.
        bookedDates.add(checkOut);
      }
    }

    return SizedBox(
      height: rowHeight,
      child: Row(
        children: dates.map((date) {
          final isToday = DateRangeUtils.isToday(date);
          final isPast = DateRangeUtils.isPast(date);
          final isFirstOfMonth = date.day == 1;

          // Optimized check: O(1) lookup in the pre-calculated set.
          final hasBookingOnDate =
              bookedDates.contains(DateTime(date.year, date.month, date.day));

          return GestureDetector(
            onTap: widget.onCellTap != null
                ? () => widget.onCellTap!(date, unit)
                : null,
            child: DragTarget<BookingModel>(
              onWillAcceptWithDetails: (details) {
                return widget.enableDragDrop;
              },
              onAcceptWithDetails: (details) {
                _handleBookingDrop(details.data, date, unit);
              },
              builder: (context, candidateData, rejectedData) {
                final isHighlighted = candidateData.isNotEmpty;

                return MouseRegion(
                  cursor: widget.onCellTap != null && !isPast
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: Container(
                    width: dayCellWidth,
                    height: rowHeight,
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? theme.colorScheme.primary
                              .withAlpha((0.1 * 255).toInt())
                          : (isPast
                              ? theme.disabledColor
                                  .withAlpha((0.05 * 255).toInt())
                              : (isToday
                                  ? theme.colorScheme.primary
                                      .withAlpha((0.05 * 255).toInt())
                                  : theme.scaffoldBackgroundColor)),
                      border: Border(
                        right: BorderSide(
                          color:
                              theme.dividerColor.withAlpha((0.3 * 255).toInt()),
                        ),
                        bottom: BorderSide(
                          color:
                              theme.dividerColor.withAlpha((0.3 * 255).toInt()),
                        ),
                        left: isFirstOfMonth
                            ? BorderSide(color: theme.dividerColor, width: 2)
                            : BorderSide.none,
                      ),
                    ),
                    // Show + icon for empty cells (not past, no booking)
                    child: !hasBookingOnDate && !isPast
                        ? Center(
                            child: Icon(
                              Icons.add_circle_outline,
                              size: 20,
                              color: theme.colorScheme.primary
                                  .withAlpha((0.3 * 255).toInt()),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build booking blocks for a unit
  Widget _buildBookingBlocks({
    required UnitModel unit,
    required int rowIndex,
    required List<DateTime> dates,
    required double rowHeight,
    required double dayCellWidth,
  }) {
    final unitBookings = widget.bookings[unit.id] ?? [];

    // Filter bookings that are visible in this month
    final visibleBookings = unitBookings.where((booking) {
      return _isBookingVisible(booking, dates.first, dates.last);
    }).toList();

    return Positioned(
      top: rowIndex * rowHeight,
      left: 0,
      child: SizedBox(
        height: rowHeight,
        width: dayCellWidth * dates.length,
        child: Stack(
          children: visibleBookings.map((booking) {
            return _buildBookingBlock(
              booking: booking,
              dates: dates,
              rowHeight: rowHeight,
              dayCellWidth: dayCellWidth,
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Build individual booking block
  Widget _buildBookingBlock({
    required BookingModel booking,
    required List<DateTime> dates,
    required double rowHeight,
    required double dayCellWidth,
  }) {
    final startDate = dates.first;
    final endDate = dates.last;

    // Calculate booking start position and width
    final bookingStart = booking.checkIn.isBefore(startDate)
        ? startDate
        : booking.checkIn;
    final bookingEnd =
        booking.checkOut.isAfter(endDate) ? endDate : booking.checkOut;

    final startDayOffset = bookingStart.difference(startDate).inDays.toDouble();
    final duration = bookingEnd.difference(bookingStart).inDays.toDouble();

    final left = startDayOffset * dayCellWidth;
    final width = duration * dayCellWidth;

    return Positioned(
      left: left,
      top: 4,
      child: BookingBlockWidget(
        booking: booking,
        width: width,
        height: rowHeight - 8,
        onTap: () => widget.onBookingTap(booking),
        onSecondaryTap: () => _showBookingContextMenu(booking),
        isDraggable: widget.enableDragDrop,
        showGuestName: width > 60,
        showCheckInOut: width > 30,
      ),
    );
  }

  /// Check if booking is visible in date range
  bool _isBookingVisible(
    BookingModel booking,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    return booking.checkIn.isBefore(rangeEnd) &&
        booking.checkOut.isAfter(rangeStart);
  }

  /// Handle booking drop on a cell
  void _handleBookingDrop(
    BookingModel booking,
    DateTime dropDate,
    UnitModel targetUnit,
  ) {
    // Execute drag-drop operation via provider
    ref.read(dragDropProvider.notifier).executeDrop(
          dropDate: dropDate,
          targetUnit: targetUnit,
          allBookings: widget.bookings,
          context: context,
        );
  }

  /// Get weekday abbreviation (2 letters for month view)
  String _getWeekdayAbbreviation(int weekday) {
    const weekdays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    return weekdays[weekday - 1];
  }

  /// Show context menu for booking (right-click)
  void _showBookingContextMenu(BookingModel booking) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    // Get cursor position (approximate center of screen as fallback)
    final position = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );

    showBookingContextMenu(
      context: context,
      booking: booking,
      position: position,
      onEdit: () => widget.onBookingTap(booking),
      onDelete: () => _deleteBooking(booking),
      onSendEmail: () => _sendEmailToGuest(booking),
      onChangeStatus: (newStatus) => _changeBookingStatus(booking, newStatus),
    );
  }

  /// Delete booking
  Future<void> _deleteBooking(BookingModel booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši rezervaciju'),
        content: Text(
          'Jeste li sigurni da želite obrisati rezervaciju za ${booking.guestName ?? 'N/A'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final repository = ref.read(bookingRepositoryProvider);
        await repository.deleteBooking(booking.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervacija obrisana'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Change booking status
  Future<void> _changeBookingStatus(BookingModel booking, BookingStatus newStatus) async {
    try {
      final repository = ref.read(bookingRepositoryProvider);
      final updatedBooking = booking.copyWith(status: newStatus);
      await repository.updateBooking(updatedBooking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status promijenjen u ${newStatus.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Send email to guest
  void _sendEmailToGuest(BookingModel booking) {
    showSendEmailDialog(context, ref, booking);
  }
}
