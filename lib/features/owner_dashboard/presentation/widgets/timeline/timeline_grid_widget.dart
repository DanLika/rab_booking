import 'package:flutter/material.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../core/theme/calendar_cell_colors.dart';
import 'timeline_booking_block.dart';
import 'timeline_booking_stacker.dart';
import 'timeline_constants.dart';
import 'timeline_dimensions.dart';

/// Timeline grid widget
/// Displays the main calendar grid with day cells and booking blocks
/// Handles layout of overlapping bookings via stacking
class TimelineGridWidget extends StatelessWidget {
  /// List of units to display rows for
  final List<UnitModel> units;

  /// Bookings grouped by unit ID
  final Map<String, List<BookingModel>> bookingsByUnit;

  /// List of visible dates
  final List<DateTime> dates;

  /// Offset width for windowing
  final double offsetWidth;

  /// Timeline dimensions
  final TimelineDimensions dimensions;

  /// Callback when booking is tapped
  final Function(BookingModel booking)? onBookingTap;

  /// Callback when booking is long pressed
  final Function(BookingModel booking)? onBookingLongPress;

  /// Widget builder for drop zones (injected from parent with provider access)
  final Widget Function(UnitModel unit, DateTime date, int index)? dropZoneBuilder;

  const TimelineGridWidget({
    super.key,
    required this.units,
    required this.bookingsByUnit,
    required this.dates,
    required this.offsetWidth,
    required this.dimensions,
    this.onBookingTap,
    this.onBookingLongPress,
    this.dropZoneBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Container with transparent color wrapping Column
    // Column uses mainAxisSize.min to size to its children
    return Container(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: units.map((unit) {
          final bookings = bookingsByUnit[unit.id] ?? [];
          // RepaintBoundary: Each unit row can repaint independently
          // when bookings change, without affecting other rows
          return RepaintBoundary(
            child: _TimelineUnitRow(
              unit: unit,
              bookings: bookings,
              dates: dates,
              offsetWidth: offsetWidth,
              allBookingsByUnit: bookingsByUnit,
              dimensions: dimensions,
              onBookingTap: onBookingTap,
              onBookingLongPress: onBookingLongPress,
              dropZoneBuilder: dropZoneBuilder,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Single unit row in the timeline grid
class _TimelineUnitRow extends StatelessWidget {
  final UnitModel unit;
  final List<BookingModel> bookings;
  final List<DateTime> dates;
  final double offsetWidth;
  final Map<String, List<BookingModel>> allBookingsByUnit;
  final TimelineDimensions dimensions;
  final Function(BookingModel booking)? onBookingTap;
  final Function(BookingModel booking)? onBookingLongPress;
  final Widget Function(UnitModel unit, DateTime date, int index)? dropZoneBuilder;

  const _TimelineUnitRow({
    required this.unit,
    required this.bookings,
    required this.dates,
    required this.offsetWidth,
    required this.allBookingsByUnit,
    required this.dimensions,
    this.onBookingTap,
    this.onBookingLongPress,
    this.dropZoneBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate stack levels for overlapping bookings
    final stackLevels = TimelineBookingStacker.assignStackLevels(bookings);
    final maxStackCount = TimelineBookingStacker.calculateMaxStackCount(bookings);

    // Dynamic height based on stack count
    final unitRowHeight = dimensions.getStackedRowHeight(maxStackCount);

    // FIXED: Container needs explicit width when inside Column that's inside horizontal ScrollView
    // The width should match the content width (offsetWidth + dates.length * dayWidth)
    final contentWidth = offsetWidth + (dates.length * dimensions.dayWidth);
    return SizedBox(
      width: contentWidth,
      height: unitRowHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(bottom: BorderSide(color: theme.dividerColor.withAlpha((0.6 * 255).toInt()))),
        ),
        child: Stack(
          alignment: Alignment.topLeft, // Explicit alignment to avoid TextDirection dependency on Chrome Mobile
          children: [
            // Day cells (background)
            Row(
              children: [
                if (offsetWidth > 0) SizedBox(width: offsetWidth),
                ...dates.map((date) => _TimelineDayCell(date: date, dimensions: dimensions)),
              ],
            ),

            // Drop zones layer (if provided)
            if (dropZoneBuilder != null)
              Stack(
                alignment: Alignment.topLeft, // Explicit alignment to avoid TextDirection dependency on Chrome Mobile
                children: dates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final date = entry.value;
                  final left = offsetWidth + (index * dimensions.dayWidth);

                  return Positioned(
                    left: left,
                    top: 0,
                    width: dimensions.dayWidth,
                    height: dimensions.unitRowHeight,
                    child: dropZoneBuilder!(unit, date, index),
                  );
                }).toList(),
              ),

            // Reservation blocks (foreground)
            Stack(alignment: Alignment.topLeft, children: _buildReservationBlocks(stackLevels)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReservationBlocks(Map<String, int> stackLevels) {
    final List<Widget> blocks = [];

    for (final booking in bookings) {
      // Normalize check-in date to midnight for accurate comparison
      final checkIn = DateTime(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
      final nights = TimelineBookingBlock.calculateNights(booking.checkIn, booking.checkOut);

      // Ensure nights is valid
      if (nights < 0) continue;

      // Find index of check-in date in visible range
      // Normalize dates to midnight for accurate comparison
      final startIndex = dates.indexWhere((d) {
        final normalizedDate = DateTime(d.year, d.month, d.day);
        return normalizedDate.isAtSameMomentAs(checkIn);
      });

      if (startIndex == -1) continue;

      final dayWidth = dimensions.dayWidth;
      // Ensure dayWidth is valid
      if (!dayWidth.isFinite || dayWidth <= 0) continue;

      final left = offsetWidth + (startIndex * dayWidth);
      final width = (nights + 1) * dayWidth;

      // Ensure left and width are valid
      if (!left.isFinite || !width.isFinite || width <= 0) continue;

      // Get stack level for vertical positioning
      final stackLevel = stackLevels[booking.id] ?? 0;
      final unitRowHeight = dimensions.unitRowHeight;
      // Ensure unitRowHeight is valid
      if (!unitRowHeight.isFinite || unitRowHeight <= 0) continue;

      // Use unitRowHeight for stack level offset to ensure proper vertical spacing
      // Each stack level should be offset by the full row height to prevent overlap
      final topPosition = kTimelineBookingTopPadding + (stackLevel * unitRowHeight);
      // Ensure topPosition is valid
      if (!topPosition.isFinite) continue;

      blocks.add(
        Positioned(
          left: left,
          top: topPosition,
          // RepaintBoundary isolates repaints for better web performance
          child: RepaintBoundary(
            child: TimelineBookingBlock(
              booking: booking,
              width: width,
              unitRowHeight: unitRowHeight,
              dayWidth: dayWidth,
              allBookingsByUnit: allBookingsByUnit,
              onTap: onBookingTap != null ? () => onBookingTap!(booking) : () {},
              onLongPress: onBookingLongPress != null ? () => onBookingLongPress!(booking) : () {},
            ),
          ),
        ),
      );
    }

    return blocks;
  }
}

/// Single day cell in the timeline grid
class _TimelineDayCell extends StatelessWidget {
  final DateTime date;
  final TimelineDimensions dimensions;

  const _TimelineDayCell({required this.date, required this.dimensions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final isFirstDayOfMonth = date.day == 1;

    return Container(
      width: dimensions.dayWidth,
      decoration: BoxDecoration(
        color: CalendarCellColors.getCellBackground(context: context, isToday: isToday, isWeekend: isWeekend),
        border: Border(
          left: BorderSide(
            color: isFirstDayOfMonth ? theme.colorScheme.primary : theme.dividerColor.withAlpha((0.5 * 255).toInt()),
            width: isFirstDayOfMonth ? 2 : 1,
          ),
          right: BorderSide(color: theme.dividerColor.withAlpha((0.6 * 255).toInt()), width: 0.5),
          top: BorderSide(color: theme.dividerColor.withAlpha((0.6 * 255).toInt()), width: 0.5),
          bottom: BorderSide(color: theme.dividerColor.withAlpha((0.6 * 255).toInt()), width: 0.5),
        ),
      ),
    );
  }
}
