import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// A dialog that displays a legend for the timeline booking block colors.
class TimelineLegendDialog extends StatelessWidget {
  const TimelineLegendDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.ownerCalendarLegendTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendItem(
              color: AppColors.getBookingStatusColor(
                'confirmed',
                theme.brightness,
              ),
              label: l10n.bookingStatusConfirmed,
              isDark: isDark,
            ),
            _buildLegendItem(
              color: AppColors.getBookingStatusColor('pending', theme.brightness),
              label: l10n.bookingStatusPending,
              isDark: isDark,
            ),
            _buildLegendItem(
              color: AppColors.getBookingStatusColor('blocked', theme.brightness),
              label: l10n.bookingStatusBlocked,
              isDark: isDark,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.dialogClose),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.s),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.m),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: TypographyTokens.fontSizeM),
            ),
          ),
        ],
      ),
    );
  }
}
