import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// Warning dialog shown before manually unblocking dates
///
/// Used when:
/// - Owner cancels a booking and tries to unblock dates
/// - Owner manually unblocks dates in calendar editor
/// - Unit has active platform integrations (Booking.com/Airbnb)
///
/// Returns true if user confirms, false if cancelled
class UnblockWarningDialog extends StatelessWidget {
  /// Platform names to display (e.g., "Booking.com", "Airbnb", or "all platforms")
  final String platformName;

  /// Start date of the range to unblock
  final DateTime startDate;

  /// End date of the range to unblock
  final DateTime endDate;

  const UnblockWarningDialog({
    super.key,
    required this.platformName,
    required this.startDate,
    required this.endDate,
  });

  /// Show the dialog and return true if confirmed, false otherwise
  static Future<bool> show({
    required BuildContext context,
    required String platformName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UnblockWarningDialog(
        platformName: platformName,
        startDate: startDate,
        endDate: endDate,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: theme.colorScheme.error,
        size: 48,
      ),
      title: Text(l10n.warningUnblockDatesTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.warningUnblockDatesMessage(
                platformName,
                _formatDateRange(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.warningUnblockDatesRisks,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildRiskItem(l10n.riskCancelledByMistake, theme, isDark),
            _buildRiskItem(l10n.riskPlanToReactivate, theme, isDark),
            _buildRiskItem(l10n.riskAnotherBookingExists, theme, isDark),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          child: Text(l10n.yesUnblock),
        ),
      ],
    );
  }

  Widget _buildRiskItem(String text, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: isDark ? AppColors.errorDark : AppColors.errorLight,
            ),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _formatDateRange(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat('d. MMM yyyy', locale);

    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return dateFormat.format(startDate);
    }

    return '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
  }
}
