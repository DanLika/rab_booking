import 'package:flutter/material.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../l10n/app_localizations.dart';

/// Timeline unit name cell widget
///
/// Displays unit name with icon and guest count in the left column of timeline.
/// Extracted from timeline_calendar_widget.dart for better maintainability.
class TimelineUnitNameCell extends StatelessWidget {
  /// The unit to display
  final UnitModel unit;

  /// Height of the unit row
  final double unitRowHeight;

  /// Callback when unit name is tapped (to show future bookings dialog)
  final VoidCallback? onTap;

  const TimelineUnitNameCell({super.key, required this.unit, required this.unitRowHeight, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppDimensions.mobile;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: unitRowHeight,
        padding: EdgeInsets.all(isMobile ? AppDimensions.spaceXS : AppDimensions.spaceS),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.6))),
        ),
        child: Row(
          children: [
            // Bed icon - smaller and more subtle
            Container(
              padding: EdgeInsets.all(isMobile ? 4 : 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.hotel_outlined,
                size: isMobile ? 14 : 16,
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(width: isMobile ? 6 : 8),
            // Unit info - more space for text
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
                        fontSize: isMobile ? 12 : 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Flexible(
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Text(
                          '${unit.maxGuests} ${l10n.guestsPlural}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: isMobile ? 10 : 11,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
