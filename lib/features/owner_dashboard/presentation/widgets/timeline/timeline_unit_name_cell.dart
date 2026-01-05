import 'package:flutter/material.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/utils/responsive_spacing_helper.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppDimensions.mobile;
    final isLandscape = ResponsiveSpacingHelper.isLandscapeMobile(context);

    // Landscape mobile needs more compact layout
    final cellPadding = isLandscape
        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
        : EdgeInsets.all(
            isMobile ? AppDimensions.spaceXS : AppDimensions.spaceS,
          );
    final iconPadding = isLandscape ? 3.0 : (isMobile ? 4.0 : 6.0);
    final iconSize = isLandscape ? 12.0 : (isMobile ? 14.0 : 16.0);
    final nameFontSize = isLandscape ? 11.0 : (isMobile ? 12.0 : 13.0);
    final guestsFontSize = isLandscape ? 9.0 : (isMobile ? 10.0 : 11.0);
    final spacingBetween = isLandscape ? 2.0 : 1.0;
    final iconSpacing = isLandscape ? 4.0 : (isMobile ? 6.0 : 8.0);

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
              padding: EdgeInsets.all(iconPadding),
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
            SizedBox(width: iconSpacing),
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
                  SizedBox(height: spacingBetween),
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
