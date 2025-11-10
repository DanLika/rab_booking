import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../../../core/constants/enums.dart';
import '../../../domain/models/date_range_selection.dart';
import '../../../utils/calendar_grid_calculator.dart';
import '../../../utils/date_range_utils.dart';
import '../../providers/calendar_drag_drop_provider.dart';
import 'booking_block_widget.dart';
import 'booking_context_menu.dart';
import 'room_row_header.dart';
import '../send_email_dialog.dart';

/// Owner week grid calendar widget
/// Shows 7-day grid (Monday-Sunday) with all units and bookings
class OwnerWeekGridCalendar extends ConsumerStatefulWidget {
  final DateRangeSelection dateRange;
  final List<UnitModel> units;
  final Map<String, List<BookingModel>> bookings;
  final Function(BookingModel) onBookingTap;
  final Function(DateTime date, UnitModel unit)? onCellTap;
  final Function(UnitModel unit, List<BookingModel> bookings)? onRoomHeaderTap;
  final bool enableDragDrop;

  const OwnerWeekGridCalendar({
    super.key,
    required this.dateRange,
    required this.units,
    required this.bookings,
    required this.onBookingTap,
    this.onCellTap,
    this.onRoomHeaderTap,
    this.enableDragDrop = true,
  });

  @override
  ConsumerState<OwnerWeekGridCalendar> createState() =>
      _OwnerWeekGridCalendarState();
}

class _OwnerWeekGridCalendarState extends ConsumerState<OwnerWeekGridCalendar> {
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

    // Calculate dimensions
    final rowHeaderWidth = CalendarGridCalculator.getRowHeaderWidth(
      screenWidth,
    );
    final rowHeight = CalendarGridCalculator.getRowHeight(screenWidth);
    final dayCellWidth = CalendarGridCalculator.getDayCellWidth(screenWidth, 7);
    final headerHeight = CalendarGridCalculator.getHeaderHeight(screenWidth);

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
                            isCompact:
                                screenWidth <
                                CalendarGridCalculator.mobileBreakpoint,
                            bookings: unitBookings,
                            onTap: widget.onRoomHeaderTap != null
                                ? () => widget.onRoomHeaderTap!(
                                    unit,
                                    unitBookings,
                                  )
                                : null,
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
                        width: dayCellWidth * 7,
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

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isToday
            ? theme.colorScheme.primary.withAlpha((0.2 * 255).toInt())
            : theme.cardColor,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withAlpha((0.5 * 255).toInt()),
          ),
          bottom: BorderSide(color: theme.dividerColor, width: 1.5),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Weekday name
          Text(
            _getWeekdayName(date.weekday),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isWeekend
                  ? theme.colorScheme.error
                  : (isToday ? theme.colorScheme.primary : null),
            ),
          ),
          const SizedBox(height: 4),
          // Day number
          Container(
            width: 28,
            height: 28,
            decoration: isToday
                ? BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  )
                : null,
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: theme.textTheme.titleSmall?.copyWith(
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

    return SizedBox(
      height: rowHeight,
      child: Row(
        children: dates.map((date) {
          final isToday = DateRangeUtils.isToday(date);
          final isPast = DateRangeUtils.isPast(date);

          // Check if there's a booking on this date
          final hasBookingOnDate = unitBookings.any((booking) {
            final checkIn = DateTime(
              booking.checkIn.year,
              booking.checkIn.month,
              booking.checkIn.day,
            );
            final checkOut = DateTime(
              booking.checkOut.year,
              booking.checkOut.month,
              booking.checkOut.day,
            );
            final cellDate = DateTime(date.year, date.month, date.day);
            return cellDate.isAtSameMomentAs(checkIn) ||
                cellDate.isAtSameMomentAs(checkOut) ||
                (cellDate.isAfter(checkIn) && cellDate.isBefore(checkOut));
          });

          return GestureDetector(
            onTap: widget.onCellTap != null
                ? () => widget.onCellTap!(date, unit)
                : null,
            child: DragTarget<BookingModel>(
              onWillAcceptWithDetails: (details) {
                if (!widget.enableDragDrop) return false;

                // Validate drop target in real-time
                ref
                    .read(dragDropProvider.notifier)
                    .validateDrop(
                      dropDate: date,
                      targetUnitId: unit.id,
                      allBookings: widget.bookings,
                    );

                return true; // Always accept to show feedback, actual validation in executeDrop
              },
              onAcceptWithDetails: (details) {
                // Only execute drop if validation passed
                final dragState = ref.read(dragDropProvider);
                if (dragState.isValidDrop) {
                  _handleBookingDrop(details.data, date, unit);
                }
              },
              builder: (context, candidateData, rejectedData) {
                final isHighlighted = candidateData.isNotEmpty;
                final dragState = ref.watch(dragDropProvider);
                final isValid = dragState.isValidDrop;

                return MouseRegion(
                  cursor: widget.onCellTap != null && !isPast
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: Container(
                    width: dayCellWidth,
                    height: rowHeight,
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? (isValid
                                ? Colors.green.withAlpha((0.2 * 255).toInt())
                                : Colors.red.withAlpha((0.2 * 255).toInt()))
                          : (isPast
                                ? theme.disabledColor.withAlpha(
                                    (0.05 * 255).toInt(),
                                  )
                                : (isToday
                                      ? theme.colorScheme.primary.withAlpha(
                                          (0.05 * 255).toInt(),
                                        )
                                      : theme.scaffoldBackgroundColor)),
                      border: Border(
                        right: BorderSide(
                          color: theme.dividerColor.withAlpha(
                            (0.6 * 255).toInt(),
                          ),
                        ),
                        bottom: BorderSide(
                          color: theme.dividerColor.withAlpha(
                            (0.6 * 255).toInt(),
                          ),
                        ),
                      ),
                    ),
                    // Show + icon for empty cells (not past, no booking)
                    child: !hasBookingOnDate && !isPast
                        ? Center(
                            child: Icon(
                              Icons.add,
                              size: 24,
                              color: theme.colorScheme.primary.withAlpha(
                                (0.4 * 255).toInt(),
                              ),
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

    // Filter bookings that are visible in this week
    final visibleBookings = unitBookings.where((booking) {
      return _isBookingVisible(booking, dates.first, dates.last);
    }).toList();

    return Positioned(
      top: rowIndex * rowHeight,
      left: 0,
      child: SizedBox(
        height: rowHeight,
        width: dayCellWidth * 7,
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
    final bookingEnd = booking.checkOut.isAfter(endDate)
        ? endDate
        : booking.checkOut;

    final startDayOffset = bookingStart.difference(startDate).inDays.toDouble();
    final duration = bookingEnd.difference(bookingStart).inDays.toDouble();

    final left = startDayOffset * dayCellWidth;
    final width = duration * dayCellWidth;

    // Center booking block vertically with equal margins
    // Reduced from 8.0 to 6.0 for better space utilization on mobile
    const verticalMargin = 6.0;

    return Positioned(
      left: left,
      top: verticalMargin,
      child: BookingBlockWidget(
        booking: booking,
        width: width,
        height: rowHeight - (verticalMargin * 2), // Equal margins top & bottom
        onTap: () => widget.onBookingTap(booking),
        onSecondaryTapDown: (details) =>
            _showBookingContextMenu(booking, details),
        isDraggable: widget.enableDragDrop,
        showGuestName: width > 80,
        showCheckInOut: width > 40,
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
    ref
        .read(dragDropProvider.notifier)
        .executeDrop(
          dropDate: dropDate,
          targetUnit: targetUnit,
          allBookings: widget.bookings,
          context: context,
        );
  }

  /// FIXED: Get localized weekday name (3 letters)
  String _getWeekdayName(int weekday) {
    // Use Croatian names for owner dashboard
    const weekdaysHr = ['PON', 'UTO', 'SRI', '\u010cET', 'PET', 'SUB', 'NED'];
    return weekdaysHr[weekday - 1];
  }

  /// Show context menu for booking (right-click or long-press)
  void _showBookingContextMenu(BookingModel booking, TapDownDetails details) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    // FIXED: Use actual tap position instead of screen center
    final position = details.globalPosition;

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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            SnackBar(content: Text('Greška: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  /// Change booking status
  Future<void> _changeBookingStatus(
    BookingModel booking,
    BookingStatus newStatus,
  ) async {
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
          SnackBar(content: Text('Greška: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Send email to guest
  void _sendEmailToGuest(BookingModel booking) {
    showSendEmailDialog(context, ref, booking);
  }
}
