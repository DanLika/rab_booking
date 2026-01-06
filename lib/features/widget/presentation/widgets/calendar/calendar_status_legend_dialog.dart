import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/calendar_date_status.dart';
import '../l10n/widget_translations.dart';
import '../theme/minimalist_colors.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import 'year_calendar_painters.dart';

/// A dialog that displays a legend for the calendar date statuses.
///
/// This helps users understand the meaning of different colors and patterns
/// on the calendar, improving clarity and accessibility.
class CalendarStatusLegendDialog extends ConsumerWidget {
  final WidgetColorScheme colors;

  const CalendarStatusLegendDialog({super.key, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = WidgetTranslations.of(context, ref);
    final isDarkMode = colors.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: colors.backgroundPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderTokens.circularMedium),
      title: Text(
        tr.calendarLegendTitle,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: TypographyTokens.semiBold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendItem(
              label: tr.legendAvailable,
              status: DateStatus.available,
            ),
            _buildLegendItem(
              label: tr.legendBooked,
              status: DateStatus.booked,
            ),
            _buildLegendItem(
              label: tr.legendPending,
              status: DateStatus.pending,
              isPending: true,
            ),
            _buildLegendItem(
              label: tr.legendTurnoverDay,
              status: DateStatus.partialBoth,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            tr.dialogClose,
            style: TextStyle(
                color: colors.primary, fontSize: TypographyTokens.fontSizeM),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required String label,
    required DateStatus status,
    bool isPending = false,
  }) {
    const cellSize = ConstraintTokens.medium;
    const iconSpacing = SpacingTokens.m;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.s),
      child: Row(
        children: [
          Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: status == DateStatus.pending
                  ? colors.statusPendingBackground
                  : status.getColor(colors),
              border: Border.all(color: status.getBorderColor(colors)),
              borderRadius: BorderTokens.circularTiny,
            ),
            child: _buildCellPattern(status),
          ),
          const SizedBox(width: iconSpacing),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: TypographyTokens.fontSizeS,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the visual pattern for the legend item (e.g., pending stripes).
  Widget? _buildCellPattern(DateStatus status) {
    if (status == DateStatus.partialBoth) {
      return CustomPaint(
        painter: PartialBothPainter(
          checkoutColor: colors.statusBookedBackground,
          checkinColor: colors.statusBookedBackground,
          isCheckOutPending: false,
          isCheckInPending: false,
          patternLineColor: colors.borderDefault,
        ),
      );
    }
    if (status == DateStatus.pending) {
      return CustomPaint(
        painter: PendingPatternPainter(
          lineColor: DateStatus.pending.getPatternLineColor(colors),
        ),
      );
    }
    return null;
  }
}
