import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../l10n/widget_translations.dart';

/// Compact info banner showing minimum stay requirement.
///
/// Displayed between the header and calendar.
/// Used by both MonthCalendarWidget and YearCalendarWidget.
class CalendarCompactLegend extends StatelessWidget {
  final int minNights;
  final WidgetColorScheme colors;
  final WidgetTranslations translations;

  const CalendarCompactLegend({
    super.key,
    required this.minNights,
    required this.colors,
    required this.translations,
  });

  // Layout constants
  static const _desktopBreakpoint = 1024.0;
  static const _desktopMaxWidth = 650.0;
  static const _mobileMaxWidth = 600.0;
  static const _iconSize = 16.0;
  static const _fontSize = 12.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _desktopBreakpoint;

    // Match calendar width responsive sizing
    final maxWidth = isDesktop ? _desktopMaxWidth : _mobileMaxWidth;
    // Responsive vertical spacing
    final verticalMargin = isDesktop ? SpacingTokens.l : SpacingTokens.m;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: EdgeInsets.symmetric(
          horizontal: SpacingTokens.m,
          vertical: verticalMargin,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.m,
          vertical: SpacingTokens.s,
        ),
        decoration: BoxDecoration(
          color: colors.backgroundTertiary,
          borderRadius: BorderTokens.circularMedium,
          border: Border.all(color: colors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: _iconSize,
              color: colors.textSecondary,
            ),
            const SizedBox(width: SpacingTokens.xs),
            Text(
              translations.minStayNights(minNights),
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
