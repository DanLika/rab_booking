import 'package:flutter/material.dart';
import 'timeline_date_header.dart';
import 'timeline_dimensions.dart';

/// Timeline date headers widget
/// Displays month and day headers above the timeline grid
/// Syncs scroll position with main timeline via external controller
class TimelineDateHeadersWidget extends StatelessWidget {
  /// List of dates to display
  final List<DateTime> dates;

  /// Offset width for windowing (maintains scroll position)
  final double offsetWidth;

  /// Scroll controller for syncing with main timeline
  final ScrollController scrollController;

  /// Timeline dimensions (includes zoom scale)
  final TimelineDimensions dimensions;

  /// Callback when a month header is tapped
  final Function(DateTime month)? onMonthTap;

  const TimelineDateHeadersWidget({
    super.key,
    required this.dates,
    required this.offsetWidth,
    required this.scrollController,
    required this.dimensions,
    this.onMonthTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: dimensions.headerHeight,
      child: Row(
        children: [
          // Empty space for unit names column
          Container(
            width: dimensions.unitColumnWidth,
            color: Colors.transparent,
          ),

          // Scrollable headers
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Month headers
                  SizedBox(
                    height: dimensions.monthHeaderHeight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // FIX: Use floorToDouble() for consistent positioning
                        if (offsetWidth > 0)
                          SizedBox(width: offsetWidth.floorToDouble()),
                        ..._buildMonthHeaders(context),
                      ],
                    ),
                  ),

                  // Day headers - RepaintBoundary isolates header repaints
                  // from grid content during scroll
                  RepaintBoundary(
                    child: SizedBox(
                      height: dimensions.dayHeaderHeight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // FIX: Use floorToDouble() for consistent positioning
                          if (offsetWidth > 0)
                            SizedBox(width: offsetWidth.floorToDouble()),
                          ...dates.map(
                            (date) => TimelineDayHeader(
                              date: date,
                              // FIX: Use floorToDouble() for consistent sizing
                              dayWidth: dimensions.dayWidth.floorToDouble(),
                              screenWidth: dimensions.screenWidth,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build month header widgets with proper grouping
  List<Widget> _buildMonthHeaders(BuildContext context) {
    final List<Widget> headers = [];
    DateTime? currentMonth;
    int dayCount = 0;

    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];

      if (currentMonth == null ||
          date.month != currentMonth.month ||
          date.year != currentMonth.year) {
        // New month started, add previous month header if exists
        if (currentMonth != null && dayCount > 0) {
          headers.add(
            TimelineMonthHeader(
              date: currentMonth,
              dayCount: dayCount,
              // FIX: Use floorToDouble() for consistent sizing
              dayWidth: dimensions.dayWidth.floorToDouble(),
              screenWidth: dimensions.screenWidth,
              onTap: onMonthTap,
            ),
          );
        }

        // Start new month
        currentMonth = date;
        dayCount = 1;
      } else {
        dayCount++;
      }
    }

    // Add last month header
    if (currentMonth != null && dayCount > 0) {
      headers.add(
        TimelineMonthHeader(
          date: currentMonth,
          dayCount: dayCount,
          // FIX: Use floorToDouble() for consistent sizing
          dayWidth: dimensions.dayWidth.floorToDouble(),
          screenWidth: dimensions.screenWidth,
          onTap: onMonthTap,
        ),
      );
    }

    return headers;
  }
}
