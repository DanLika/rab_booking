import 'package:flutter/material.dart';
import 'package:bookbed/l10n/app_localizations.dart';

/// A dialog to explain to the user why a permission is needed before requesting it.
class PermissionRationaleDialog extends StatelessWidget {
  const PermissionRationaleDialog({
    super.key,
    required this.permission,
    required this.rationale,
  });

  final String permission;
  final String rationale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.permissionRequest(permission)),
      content: Text(rationale),
      actions: <Widget>[
        TextButton(
          child: Text(l10n.notNow),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        TextButton(
          child: Text(l10n.continueA),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}
