import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';

/// Compact legend/info banner displayed below the calendar.
///
/// Shows minimum stay requirement and color legend for date statuses.
/// Used by both MonthCalendarWidget and YearCalendarWidget.
class CalendarCompactLegend extends StatelessWidget {
  final int minNights;
  final WidgetColorScheme colors;

  const CalendarCompactLegend({
    super.key,
    required this.minNights,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 600;
    final isDesktop = screenWidth >= 1024;

    // Match calendar width: 650px desktop, 600px mobile/tablet
    final maxWidth = isDesktop ? 650.0 : 600.0;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.only(
          top: SpacingTokens.s,
          bottom: SpacingTokens.xs,
          left: SpacingTokens.xs,
          right: SpacingTokens.xs,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.s,
          vertical: SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderTokens.circularMedium,
          border: Border.all(color: colors.borderLight),
        ),
        child: isNarrowScreen
            ? Column(
                children: [
                  // Min stay info
                  _buildMinStayInfo(),
                  const SizedBox(height: SpacingTokens.xxs),
                  // Color legend
                  _buildColorLegend(),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Min stay info
                  _buildMinStayInfo(),
                  const SizedBox(width: SpacingTokens.m),
                  // Color legend
                  _buildColorLegend(),
                ],
              ),
      ),
    );
  }

  Widget _buildMinStayInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.bed_outlined,
          size: 14,
          color: colors.textSecondary,
        ),
        const SizedBox(width: SpacingTokens.xxs),
        Text(
          'Min. stay: $minNights ${minNights == 1 ? 'night' : 'nights'}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Build compact color legend with dots
  Widget _buildColorLegend() {
    return Wrap(
      spacing: SpacingTokens.xs,
      runSpacing: 4,
      children: [
        _buildLegendItem('Available', colors.statusAvailableBackground),
        _buildLegendItem('Booked', colors.statusBookedBackground),
        _buildLegendItem('Pending', colors.statusPendingBackground),
        _buildLegendItem('Unavailable', colors.backgroundTertiary),
      ],
    );
  }

  /// Build a single legend item with colored dot
  Widget _buildLegendItem(String label, Color dotColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            border: Border.all(color: colors.borderDefault, width: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colors.textSecondary),
        ),
      ],
    );
  }
}
