import 'package:flutter/material.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/models/unit_model.dart';
import 'timeline_unit_name_cell.dart';
import 'timeline_booking_stacker.dart';
import 'timeline_dimensions.dart';

/// Timeline unit names column widget
/// Fixed left column showing unit names with dynamic heights
/// Syncs vertical scroll with main timeline grid
class TimelineUnitColumnWidget extends StatelessWidget {
  /// List of units to display
  final List<UnitModel> units;

  /// Bookings grouped by unit ID
  final Map<String, List<BookingModel>> bookingsByUnit;

  /// Scroll controller for syncing with main timeline
  final ScrollController scrollController;

  /// Callback when unit name is tapped
  final Function(UnitModel unit)? onUnitNameTap;

  /// Timeline dimensions
  final TimelineDimensions dimensions;

  /// Callback for vertical scroll sync
  final Function(ScrollNotification notification)? onScrollNotification;

  /// Whether to show bottom padding for summary bar alignment
  final bool showSummarySpacing;

  /// Summary bar height for bottom spacing
  static const double _kSummaryBarHeight = 120.0;

  const TimelineUnitColumnWidget({
    super.key,
    required this.units,
    required this.bookingsByUnit,
    required this.scrollController,
    required this.dimensions,
    this.onUnitNameTap,
    this.onScrollNotification,
    this.showSummarySpacing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: dimensions.unitColumnWidth,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          onScrollNotification?.call(notification);
          return false;
        },
        child: SingleChildScrollView(
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              ...units.map((unit) {
                // Calculate dynamic height based on booking stacks
                final bookings = bookingsByUnit[unit.id] ?? [];
                final maxStackCount =
                    TimelineBookingStacker.calculateMaxStackCount(bookings);
                final dynamicHeight = dimensions.getStackedRowHeight(
                  maxStackCount,
                );

                return TimelineUnitNameCell(
                  unit: unit,
                  unitRowHeight: dynamicHeight,
                  onTap: onUnitNameTap != null
                      ? () => onUnitNameTap!(unit)
                      : null,
                );
              }),
              // Bottom spacing to align with summary bar
              if (showSummarySpacing)
                Container(
                  height: _kSummaryBarHeight,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(
                      (0.3 * 255).toInt(),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: theme.dividerColor.withAlpha(
                          (0.5 * 255).toInt(),
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
