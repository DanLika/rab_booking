import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/color_tokens.dart';
import '../../../domain/models/calendar_date_status.dart';
import '../calendar_hover_tooltip.dart';
import 'calendar_date_utils.dart';

/// Shared tooltip builder for calendar widgets.
///
/// Extracts ~45 lines of duplicate tooltip positioning logic from both
/// YearCalendarWidget and MonthCalendarWidget.
///
/// Usage:
/// ```dart
/// CalendarTooltipBuilder.build(
///   context: context,
///   hoveredDate: _hoveredDate,
///   mousePosition: _mousePosition,
///   data: calendarData,
///   colors: colors,
///   tooltipHeight: 150.0, // Year uses 150, Month uses 120
///   ignorePointer: false, // Month uses true
/// )
/// ```
class CalendarTooltipBuilder {
  /// Builds a positioned hover tooltip for calendar date cells.
  ///
  /// Returns [SizedBox.shrink] if no date is hovered or date info is null.
  ///
  /// Parameters:
  /// - [context]: BuildContext for MediaQuery
  /// - [hoveredDate]: Currently hovered date (null if none)
  /// - [mousePosition]: Current mouse position (local to parent)
  /// - [data]: Map of date keys to CalendarDateInfo
  /// - [colors]: Widget color scheme
  /// - [tooltipHeight]: Height of tooltip (150 for year, 120 for month)
  /// - [ignorePointer]: Whether to wrap in IgnorePointer (true for month)
  static Widget build({
    required BuildContext context,
    required DateTime? hoveredDate,
    required Offset mousePosition,
    required Map<String, CalendarDateInfo> data,
    required WidgetColorScheme colors,
    double tooltipHeight = 150.0,
    bool ignorePointer = false,
  }) {
    if (hoveredDate == null) return const SizedBox.shrink();

    final key = CalendarDateUtils.getDateKey(hoveredDate);
    final dateInfo = data[key];

    if (dateInfo == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const tooltipWidth = 200.0;

    // Position tooltip near mouse cursor, offset to avoid cursor overlap
    double xPosition = mousePosition.dx + 10;
    double yPosition = mousePosition.dy - tooltipHeight - 10;

    // Adjust if tooltip goes off screen
    if (xPosition + tooltipWidth > screenWidth) {
      xPosition = mousePosition.dx - tooltipWidth - 10; // Show on left instead
    }
    if (yPosition < 20) {
      yPosition = mousePosition.dy + 20; // Show below cursor instead
    }

    // Clamp to screen bounds with padding
    xPosition = xPosition.clamp(20, screenWidth - tooltipWidth - 20);
    yPosition = yPosition.clamp(20, screenHeight - tooltipHeight - 20);

    // For pending bookings, show "Pending" status instead of "Booked"
    final effectiveStatus =
        dateInfo.isPendingBooking ? DateStatus.pending : dateInfo.status;

    final tooltip = CalendarHoverTooltip(
      date: hoveredDate,
      price: dateInfo.price,
      status: effectiveStatus,
      position: Offset(xPosition, yPosition),
      colors: colors,
    );

    return Positioned(
      left: xPosition,
      top: yPosition,
      child: ignorePointer ? IgnorePointer(child: tooltip) : tooltip,
    );
  }
}
