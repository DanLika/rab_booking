import 'package:flutter/material.dart';
import '../../../../../shared/models/unit_model.dart';
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

  const TimelineUnitNameCell({
    super.key,
    required this.unit,
    required this.unitRowHeight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Fixed compact values — matches fixed 42px row height from TimelineDimensions.
    // Same on all devices (mobile cell size is the standard).
    const cellPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 2);
    const iconPadding = 4.0;
    const iconSize = 14.0;
    const nameFontSize = 12.0;
    const guestsFontSize = 10.0;
    const spacingBetween = 1.0;
    const iconSpacing = 6.0;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: unitRowHeight,
        padding: cellPadding,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.6),
            ),
          ),
        ),
        child: Row(
          children: [
            // Bed icon - smaller and more subtle
            Container(
              padding: const EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.hotel_outlined,
                size: iconSize,
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: iconSpacing),
            // Unit info - more space for text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    unit.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: nameFontSize,
                      height: 1.1, // Tighter line height for landscape
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: spacingBetween),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        '${unit.maxGuests} ${l10n.guestsPlural}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: guestsFontSize,
                          height: 1.1, // Tighter line height for landscape
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
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
