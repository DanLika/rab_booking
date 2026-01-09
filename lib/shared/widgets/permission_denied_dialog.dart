import 'package:flutter/material.dart';
import 'package:bookbed/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookbed/shared/providers/service_providers.dart';

/// A dialog to inform the user that a permission is permanently denied and provide a button to open the app settings.
class PermissionDeniedDialog extends ConsumerWidget {
  const PermissionDeniedDialog({
    super.key,
    required this.permission,
  });

  final String permission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.permissionRequired(permission)),
      content: Text(l10n.permissionPermanentlyDenied(permission)),
      actions: <Widget>[
        TextButton(
          child: Text(l10n.cancel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(l10n.openSettings),
          onPressed: () {
            ref.read(permissionServiceProvider).openApplicationSettings();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
