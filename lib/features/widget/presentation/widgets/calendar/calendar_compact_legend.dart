import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../l10n/widget_translations.dart';

/// Compact info banner showing minimum stay requirement.
///
/// Displayed between the header and calendar.
/// Used by both MonthCalendarWidget and YearCalendarWidget.
class CalendarCompactLegend extends StatelessWidget {
  final int minNights;
  final WidgetColorScheme colors;
  final WidgetTranslations translations;

  const CalendarCompactLegend({super.key, required this.minNights, required this.colors, required this.translations});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    // Match calendar width: 650px desktop, 600px mobile/tablet
    final maxWidth = isDesktop ? 650.0 : 600.0;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.m, vertical: SpacingTokens.s),
        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.m, vertical: SpacingTokens.s),
        decoration: BoxDecoration(
          color: colors.backgroundTertiary,
          borderRadius: BorderTokens.circularMedium,
          border: Border.all(color: colors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 16, color: colors.textSecondary),
            const SizedBox(width: SpacingTokens.xs),
            Text(
              translations.minStayNights(minNights),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
