import 'package:flutter/material.dart';

/// Avatar picker dialog - choose between camera and gallery
class AvatarPickerDialog extends StatelessWidget {
  final VoidCallback onCameraSelected;
  final VoidCallback onGallerySelected;

  const AvatarPickerDialog({
    required this.onCameraSelected,
    required this.onGallerySelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Odaberi izvor slike'),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.camera_alt,
              color: Color(0xFF667eea),
            ),
            title: const Text('Kamera'),
            subtitle: const Text('Fotografiraj novu sliku'),
            onTap: () {
              Navigator.of(context).pop();
              onCameraSelected();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.photo_library,
              color: Color(0xFF667eea),
            ),
            title: const Text('Galerija'),
            subtitle: const Text('Odaberi postojeću sliku'),
            onTap: () {
              Navigator.of(context).pop();
              onGallerySelected();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Odustani'),
        ),
      ],
    );
  }

  /// Show avatar picker dialog
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onCameraSelected,
    required VoidCallback onGallerySelected,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AvatarPickerDialog(
        onCameraSelected: onCameraSelected,
        onGallerySelected: onGallerySelected,
      ),
    );
  }
}
