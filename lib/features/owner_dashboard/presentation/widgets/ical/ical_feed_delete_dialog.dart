import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../booking_actions/base_booking_dialog.dart';

/// Dialog for confirming iCal feed deletion
///
/// Returns `true` if user confirms, `false` or `null` if cancelled
class IcalFeedDeleteDialog extends StatelessWidget {
  final String platformName;
  final int eventCount;

  const IcalFeedDeleteDialog({
    super.key,
    required this.platformName,
    required this.eventCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BaseBookingDialog(
      icon: Icons.delete_outline,
      title: l10n.icalDeleteFeedTitle,
      content: Text(
        l10n.icalDeleteFeedMessage(platformName, eventCount),
        style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
      ),
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.delete,
      confirmButtonColor: AppColors.error,
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    );
  }
}
