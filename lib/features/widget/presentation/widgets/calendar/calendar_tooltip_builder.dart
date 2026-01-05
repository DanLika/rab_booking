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
  // Layout constants
  static const double _tooltipWidth = 200.0;
  static const double _cursorOffset = 10.0;
  static const double _screenPadding = 20.0;

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
  /// - [fallbackPrice]: Unit's base price to use when daily price is not set
  static Widget build({
    required BuildContext context,
    required DateTime? hoveredDate,
    required Offset mousePosition,
    required Map<String, CalendarDateInfo> data,
    required WidgetColorScheme colors,
    double tooltipHeight = 150.0,
    bool ignorePointer = false,
    double? fallbackPrice,
  }) {
    if (hoveredDate == null) return const SizedBox.shrink();

    final key = CalendarDateUtils.getDateKey(hoveredDate);
    final dateInfo = data[key];

    if (dateInfo == null) return const SizedBox.shrink();

    // Defensive check: ensure MediaQuery is available
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) return const SizedBox.shrink();

    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Position tooltip near mouse cursor, offset to avoid cursor overlap
    // Defensive check: ensure mousePosition has valid values
    final dx = mousePosition.dx.isFinite ? mousePosition.dx : 0.0;
    final dy = mousePosition.dy.isFinite ? mousePosition.dy : 0.0;
    double xPosition = dx + _cursorOffset;
    double yPosition = dy - tooltipHeight - _cursorOffset;

    // Adjust if tooltip goes off screen
    if (xPosition + _tooltipWidth > screenWidth) {
      xPosition = dx - _tooltipWidth - _cursorOffset;
    }
    if (yPosition < _screenPadding) {
      yPosition = dy + _screenPadding;
    }

    // Clamp to screen bounds with padding
    xPosition = xPosition.clamp(
      _screenPadding,
      screenWidth - _tooltipWidth - _screenPadding,
    );
    yPosition = yPosition.clamp(
      _screenPadding,
      screenHeight - tooltipHeight - _screenPadding,
    );

    // For pending bookings, show "Pending" status instead of "Booked"
    final effectiveStatus = dateInfo.isPendingBooking
        ? DateStatus.pending
        : dateInfo.status;

    // Use fallback price (unit's base pricePerNight) when no daily_price exists
    final effectivePrice = dateInfo.price ?? fallbackPrice;

    final tooltip = CalendarHoverTooltip(
      date: hoveredDate,
      price: effectivePrice,
      status: effectiveStatus,
      colors: colors,
    );

    return Positioned(
      left: xPosition,
      top: yPosition,
      child: ignorePointer ? IgnorePointer(child: tooltip) : tooltip,
    );
  }
}
