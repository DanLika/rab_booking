import 'package:flutter/material.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../core/constants/app_dimensions.dart';

/// Timeline unit name cell widget
///
/// Displays unit name with icon and guest count in the left column of timeline.
/// Extracted from timeline_calendar_widget.dart for better maintainability.
class TimelineUnitNameCell extends StatelessWidget {
  /// The unit to display
  final UnitModel unit;

  /// Height of the unit row
  final double unitRowHeight;

  const TimelineUnitNameCell({
    super.key,
    required this.unit,
    required this.unitRowHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppDimensions.mobile;

    return Container(
      height: unitRowHeight,
      padding: EdgeInsets.all(
        isMobile ? AppDimensions.spaceXS : AppDimensions.spaceS,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Row(
        children: [
          // Bed icon
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.hotel_outlined,
              size: isMobile ? 18 : 20,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(
            width: isMobile ? AppDimensions.spaceXS : AppDimensions.spaceS,
          ),
          // Unit info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    unit.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    '${unit.maxGuests} gostiju',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
