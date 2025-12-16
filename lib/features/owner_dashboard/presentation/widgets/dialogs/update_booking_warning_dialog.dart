import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// Warning dialog shown before updating booking dates
///
/// Used when:
/// - Owner changes check-in or check-out dates
/// - Unit has active platform integrations (Booking.com/Airbnb)
/// - Prevents accidental double-booking on external platforms
///
/// Returns true if user confirms, false if cancelled
class UpdateBookingWarningDialog extends StatelessWidget {
  /// Original check-in date
  final DateTime oldCheckIn;

  /// Original check-out date
  final DateTime oldCheckOut;

  /// New check-in date
  final DateTime newCheckIn;

  /// New check-out date
  final DateTime newCheckOut;

  /// List of platform names (e.g., ["Booking.com", "Airbnb"])
  final List<String> platformNames;

  const UpdateBookingWarningDialog({
    super.key,
    required this.oldCheckIn,
    required this.oldCheckOut,
    required this.newCheckIn,
    required this.newCheckOut,
    required this.platformNames,
  });

  /// Show the dialog and return true if confirmed, false otherwise
  static Future<bool> show({
    required BuildContext context,
    required DateTime oldCheckIn,
    required DateTime oldCheckOut,
    required DateTime newCheckIn,
    required DateTime newCheckOut,
    required List<String> platformNames,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateBookingWarningDialog(
        oldCheckIn: oldCheckIn,
        oldCheckOut: oldCheckOut,
        newCheckIn: newCheckIn,
        newCheckOut: newCheckOut,
        platformNames: platformNames,
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
        Icons.sync_alt_rounded,
        color: theme.colorScheme.primary,
        size: 48,
      ),
      title: Text(l10n.warningUpdateBookingTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.warningUpdateBookingMessage),
            const SizedBox(height: 16),

            // Old dates (will be unblocked) - red/warning style
            _buildDateChange(
              label: l10n.oldDatesWillBeUnblocked,
              checkIn: oldCheckIn,
              checkOut: oldCheckOut,
              context: context,
              theme: theme,
              isOld: true,
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            // New dates (will be blocked) - primary/success style
            _buildDateChange(
              label: l10n.newDatesWillBeBlocked,
              checkIn: newCheckIn,
              checkOut: newCheckOut,
              context: context,
              theme: theme,
              isOld: false,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Platform sync info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.infoDark : AppColors.infoLight)
                    .withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (isDark ? AppColors.infoDark : AppColors.infoLight)
                      .withAlpha((0.3 * 255).toInt()),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: isDark ? AppColors.infoDark : AppColors.infoLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.platformSyncInfo(_formatPlatformNames()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          child: Text(l10n.updateBooking),
        ),
      ],
    );
  }

  Widget _buildDateChange({
    required String label,
    required DateTime checkIn,
    required DateTime checkOut,
    required BuildContext context,
    required ThemeData theme,
    required bool isOld,
    required bool isDark,
  }) {
    final backgroundColor = isOld
        ? (isDark ? AppColors.errorDark : AppColors.errorLight)
            .withAlpha((0.1 * 255).toInt())
        : (isDark ? AppColors.successDark : AppColors.successLight)
            .withAlpha((0.1 * 255).toInt());

    final borderColor = isOld
        ? (isDark ? AppColors.errorDark : AppColors.errorLight)
            .withAlpha((0.3 * 255).toInt())
        : (isDark ? AppColors.successDark : AppColors.successLight)
            .withAlpha((0.3 * 255).toInt());

    final iconColor = isOld
        ? (isDark ? AppColors.errorDark : AppColors.errorLight)
        : (isDark ? AppColors.successDark : AppColors.successLight);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOld ? Icons.event_busy_rounded : Icons.event_available_rounded,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDateRange(context, checkIn, checkOut),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _formatDateRange(
      BuildContext context, DateTime checkIn, DateTime checkOut) {
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat('d. MMM yyyy', locale);
    return '${dateFormat.format(checkIn)} - ${dateFormat.format(checkOut)}';
  }

  String _formatPlatformNames() {
    if (platformNames.isEmpty) return 'external platforms';
    if (platformNames.length == 1) return platformNames.first;
    return platformNames.join(', ');
  }
}
