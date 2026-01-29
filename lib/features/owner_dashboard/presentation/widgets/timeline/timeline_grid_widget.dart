import 'package:flutter/material.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../core/theme/calendar_cell_colors.dart';
import '../../../../../core/constants/enums.dart';
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

  /// List of visible dates (windowed for performance)
  final List<DateTime> dates;

  /// Offset width for windowing (positions visible window in scroll area)
  final double offsetWidth;

  /// Fixed start date of the full date range
  /// Used to calculate absolute positions for bookings
  final DateTime fixedStartDate;

  /// Timeline dimensions
  final TimelineDimensions dimensions;

  /// Callback when booking is tapped
  final Function(BookingModel booking)? onBookingTap;

  /// Callback when booking is long pressed
  final Function(BookingModel booking)? onBookingLongPress;

  /// Widget builder for drop zones (injected from parent with provider access)
  final Widget Function(UnitModel unit, DateTime date, int index)?
  dropZoneBuilder;

  const TimelineGridWidget({
    super.key,
    required this.units,
    required this.bookingsByUnit,
    required this.dates,
    required this.offsetWidth,
    required this.fixedStartDate,
    required this.dimensions,
    this.onBookingTap,
    this.onBookingLongPress,
    this.dropZoneBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Check if entire calendar is empty to trigger ghost mode
    final totalBookings = bookingsByUnit.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    final isCalendarEmpty = totalBookings == 0;

    // Container with transparent color wrapping Column
    // Column uses mainAxisSize.min to size to its children
    return Container(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: units.asMap().entries.map((entry) {
          final index = entry.key;
          final unit = entry.value;
          var bookings = bookingsByUnit[unit.id] ?? [];

          // GHOST DATA INJECTION
          // If calendar is completely empty, inject ghost bookings into first unit only
          if (isCalendarEmpty && index == 0) {
            bookings = _generateGhostBookings(unit.id);
          }

          // RepaintBoundary: Each unit row can repaint independently
          // when bookings change, without affecting other rows
          return RepaintBoundary(
            child: _TimelineUnitRow(
              unit: unit,
              bookings: bookings,
              dates: dates,
              offsetWidth: offsetWidth,
              fixedStartDate: fixedStartDate,
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

  /// Generate ghost (example) bookings for onboarding display
  List<BookingModel> _generateGhostBookings(String unitId) {
    final now = DateTime.now();
    // Create 2 example bookings spread across upcoming days
    return [
      BookingModel(
        id: 'ghost_1',
        unitId: unitId,
        propertyId: 'ghost_prop',
        guestName: 'Example Guest',
        checkIn: DateTime(now.year, now.month, now.day + 2),
        checkOut: DateTime(now.year, now.month, now.day + 5),
        status: BookingStatus.confirmed,
        source: 'manual',
        createdAt: now,
        updatedAt: now,
        totalPrice: 100,
      ),
      BookingModel(
        id: 'ghost_2',
        unitId: unitId,
        propertyId: 'ghost_prop',
        guestName: 'Example Guest',
        checkIn: DateTime(now.year, now.month, now.day + 8),
        checkOut: DateTime(now.year, now.month, now.day + 11),
        status: BookingStatus.confirmed,
        source: 'booking_com',
        createdAt: now,
        updatedAt: now,
        totalPrice: 200,
      ),
    ];
  }
}

/// Single unit row in the timeline grid
class _TimelineUnitRow extends StatelessWidget {
  final UnitModel unit;
  final List<BookingModel> bookings;
  final List<DateTime> dates;
  final double offsetWidth;
  final DateTime fixedStartDate;
  final TimelineDimensions dimensions;
  final Function(BookingModel booking)? onBookingTap;
  final Function(BookingModel booking)? onBookingLongPress;
  final Widget Function(UnitModel unit, DateTime date, int index)?
  dropZoneBuilder;

  const _TimelineUnitRow({
    required this.unit,
    required this.bookings,
    required this.dates,
    required this.offsetWidth,
    required this.fixedStartDate,
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
    final maxStackCount = TimelineBookingStacker.calculateMaxStackCount(
      bookings,
    );

    // Dynamic height based on stack count
    final unitRowHeight = dimensions.getStackedRowHeight(maxStackCount);

    // FIXED: Container needs explicit width when inside Column that's inside horizontal ScrollView
    // The width should match the content width (offsetWidth + dates.length * dayWidth)
    // FIX: Use floorToDouble() to avoid floating point precision errors that cause micro-overflow
    // Without this, we get RenderFlex overflow errors of ~1.06e-10 pixels
    final contentWidth = (offsetWidth + (dates.length * dimensions.dayWidth))
        .floorToDouble();
    return SizedBox(
      width: contentWidth,
      height: unitRowHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withAlpha((0.6 * 255).toInt()),
            ),
          ),
        ),
        child: Stack(
          alignment: Alignment
              .topLeft, // Explicit alignment to avoid TextDirection dependency on Chrome Mobile
          children: [
            // Day cells (background)
            // ClipRect prevents micro-overflow from floating point precision errors
            // mainAxisSize: MainAxisSize.min ensures Row doesn't try to expand beyond content
            ClipRect(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // FIX: Use floorToDouble() for offsetWidth to match container width calculation
                  if (offsetWidth > 0)
                    SizedBox(width: offsetWidth.floorToDouble()),
                  ...dates.map(
                    (date) =>
                        _TimelineDayCell(date: date, dimensions: dimensions),
                  ),
                ],
              ),
            ),

            // Drop zones layer (if provided)
            if (dropZoneBuilder != null)
              Stack(
                alignment: Alignment
                    .topLeft, // Explicit alignment to avoid TextDirection dependency on Chrome Mobile
                children: dates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final date = entry.value;
                  // FIX: Use floorToDouble() for consistent positioning
                  final left = (offsetWidth + (index * dimensions.dayWidth))
                      .floorToDouble();

                  return Positioned(
                    left: left,
                    top: 0,
                    width: dimensions.dayWidth.floorToDouble(),
                    height: dimensions.unitRowHeight,
                    child: dropZoneBuilder!(unit, date, index),
                  );
                }).toList(),
              ),

            // Reservation blocks (foreground)
            Stack(
              alignment: Alignment.topLeft,
              children: _buildReservationBlocks(stackLevels),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReservationBlocks(Map<String, int> stackLevels) {
    final List<Widget> blocks = [];

    // Calculate visible range boundaries for filtering
    // DST FIX: Use UTC for consistency with fixedStartDate and booking positions
    final visibleFirstDate = dates.isNotEmpty
        ? DateTime.utc(dates.first.year, dates.first.month, dates.first.day)
        : null;
    final visibleLastDate = dates.isNotEmpty
        ? DateTime.utc(dates.last.year, dates.last.month, dates.last.day)
        : null;

    for (final booking in bookings) {
      // Normalize check-in/check-out dates to midnight UTC for accurate comparison
      // DST FIX: Use UTC to match fixedStartDate (also UTC) and avoid off-by-one
      // errors when Duration.inDays miscalculates due to DST timezone changes
      final checkIn = DateTime.utc(
        booking.checkIn.year,
        booking.checkIn.month,
        booking.checkIn.day,
      );
      final checkOut = DateTime.utc(
        booking.checkOut.year,
        booking.checkOut.month,
        booking.checkOut.day,
      );
      // FIX: Use already UTC-normalized dates for nights calculation
      // Previously used booking.checkIn/checkOut which went through LOCAL normalization
      // in calculateNights(), causing position mismatch with UTC-based left offset
      final nights = checkOut.difference(checkIn).inDays;

      // Ensure nights is valid
      if (nights < 0) continue;

      // Check if booking overlaps with visible date range
      // A booking is visible if its check-in OR any part of it falls within visible range
      if (visibleFirstDate != null && visibleLastDate != null) {
        // Booking ends before visible range starts OR booking starts after visible range ends
        if (checkOut.isBefore(visibleFirstDate) ||
            checkIn.isAfter(visibleLastDate)) {
          // Booking is completely outside visible range - skip rendering
          continue;
        }
      }

      // Calculate absolute position from fixedStartDate (not from windowed dates list)
      // This ensures correct positioning regardless of windowing
      final daysSinceFixedStart = checkIn.difference(fixedStartDate).inDays;

      final dayWidth = dimensions.dayWidth;
      // Ensure dayWidth is valid
      if (!dayWidth.isFinite || dayWidth <= 0) continue;

      // Calculate absolute left position using daysSinceFixedStart
      // This positions the booking correctly in the full scrollable area
      //
      // PARALLELOGRAM POSITIONING:
      // The Positioned widget's left edge aligns with the check-in day column boundary.
      // The parallelogram shape (painted by SkewedBookingPainter) naturally creates
      // the diagonal check-in/check-out visual:
      //   - Bottom-left corner at x=0 (left edge of check-in day column)
      //   - Top-left corner at x=skewOffset (near right edge of check-in day column)
      //   - Top-right corner at x=width (right edge of check-out day column)
      //   - Bottom-right at x=width-skewOffset (near left edge of check-out day column)
      // On turnover days, diagonals meet at the center of the shared cell with a gap.
      final left = (daysSinceFixedStart * dayWidth).floorToDouble();
      final width = ((nights + 1) * dayWidth).floorToDouble();

      // Ensure left and width are valid
      if (!left.isFinite || !width.isFinite || width <= 0) continue;

      // Get stack level for vertical positioning
      final stackLevel = stackLevels[booking.id] ?? 0;
      final unitRowHeight = dimensions.unitRowHeight;
      // Ensure unitRowHeight is valid
      if (!unitRowHeight.isFinite || unitRowHeight <= 0) continue;

      // Use unitRowHeight for stack level offset to ensure proper vertical spacing
      // Each stack level should be offset by the full row height to prevent overlap
      final topPosition =
          (kTimelineBookingTopPadding + (stackLevel * unitRowHeight))
              .floorToDouble();
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
              onTap: onBookingTap != null
                  ? () => onBookingTap!(booking)
                  : () {},
              onLongPress: onBookingLongPress != null
                  ? () => onBookingLongPress!(booking)
                  : () {},
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
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final isFirstDayOfMonth = date.day == 1;

    return Container(
      // FIX: Use floorToDouble() to match other width calculations and prevent overflow
      width: dimensions.dayWidth.floorToDouble(),
      decoration: BoxDecoration(
        color: CalendarCellColors.getCellBackground(
          context: context,
          isToday: isToday,
          isWeekend: isWeekend,
        ),
        border: Border(
          left: BorderSide(
            color: isFirstDayOfMonth
                ? theme.colorScheme.primary
                : theme.dividerColor.withAlpha((0.5 * 255).toInt()),
            width: isFirstDayOfMonth ? 2 : 1,
          ),
          right: BorderSide(
            color: theme.dividerColor.withAlpha((0.6 * 255).toInt()),
            width: 0.5,
          ),
          top: BorderSide(
            color: theme.dividerColor.withAlpha((0.6 * 255).toInt()),
            width: 0.5,
          ),
          bottom: BorderSide(
            color: theme.dividerColor.withAlpha((0.6 * 255).toInt()),
            width: 0.5,
          ),
        ),
      ),
    );
  }
}
