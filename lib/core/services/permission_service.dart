import 'package:bookbed/l10n/app_localizations.dart';
import 'package:bookbed/shared/widgets/permission_rationale_dialog.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// A service to handle requesting permissions from the user.
class PermissionService {
  /// Requests the specified permission, showing a rationale dialog if needed.
  Future<PermissionStatus> requestPermission(
    Permission permission,
    BuildContext context,
  ) async {
    final status = await permission.status;
    if (status.isPermanentlyDenied) {
      return status;
    }

    if (status.isDenied) {
      final l10n = AppLocalizations.of(context);
      final bool? shouldProceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => PermissionRationaleDialog(
          permission: l10n.permissionName(permission.toString()),
          rationale: permission == Permission.camera
              ? l10n.permissionRationaleCamera
              : l10n.permissionRationalePhotos,
        ),
      );

      if (shouldProceed == true) {
        return await permission.request();
      } else {
        return PermissionStatus.denied;
      }
    }

    return permission.request();
  }

  /// Opens the app settings.
  Future<void> openApplicationSettings() async {
    await openAppSettings();
  }
}
