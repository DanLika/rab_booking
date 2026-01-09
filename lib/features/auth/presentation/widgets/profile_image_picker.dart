import 'dart:typed_data';
import 'package:bookbed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bookbed/shared/widgets/permission_denied_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookbed/shared/providers/service_providers.dart';

/// Profile Image Picker Widget
/// Displays a circular avatar with option to upload/change image
class ProfileImagePicker extends ConsumerStatefulWidget {
  final String? imageUrl;
  final Function(Uint8List?, String?) onImageSelected;
  final double size;
  final String? initials;

  const ProfileImagePicker({
    super.key,
    this.imageUrl,
    required this.onImageSelected,
    this.size = 120,
    this.initials,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends ConsumerState<ProfileImagePicker> {
  Uint8List? _imageBytes;
  bool _isHovered = false;
  bool _isUploading = false;

  Future<void> _showImageSourceDialog() async {
    final l10n = AppLocalizations.of(context);
    final isWeb = ref.read(platformServiceProvider).isWeb;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.photos),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              if (!isWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: Text(l10n.camera),
                  onTap: () {
                    _pickImage(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    final permissionService = ref.read(permissionServiceProvider);
    final platformService = ref.read(platformServiceProvider);

    Permission permission;
    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      permission =
          platformService.isAndroid ? Permission.storage : Permission.photos;
    }

    final status = await permissionService.requestPermission(permission, context);

    if (status.isGranted) {
      setState(() => _isUploading = true);

      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );

        if (image != null) {
          final bytes = await image.readAsBytes();
          if (!mounted) return;
          setState(() {
            _imageBytes = bytes;
            _isUploading = false;
          });
          widget.onImageSelected(bytes, image.name);
        } else {
          // User cancelled picker
          if (!mounted) return;
          setState(() => _isUploading = false);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to pick image: ${e.toString().split(':').last.trim()}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(source);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.permissionDenied(source == ImageSource.camera ? l10n.camera : l10n.photos),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPermissionDeniedDialog(ImageSource source) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PermissionDeniedDialog(
          permission: source == ImageSource.camera ? l10n.camera : l10n.photos,
        );
      },
    );
  }

  Widget _buildImageContent() {
    // Show picked image
    if (_imageBytes != null) {
      return ClipOval(
        child: Image.memory(
          _imageBytes!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      );
    }

    // Show existing URL image
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          widget.imageUrl!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholder();
          },
        ),
      );
    }

    // Show placeholder with initials
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final theme = Theme.of(context);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
        ),
      ),
      child: Center(
        child: Text(
          widget.initials?.toUpperCase() ?? '?',
          style: TextStyle(
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Stack(
          alignment:
              Alignment.topLeft, // Explicit to avoid TextDirection null check
          children: [
            // Main Image Container with Border
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(
                    (0.3 * 255).toInt(),
                  ),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(
                      (0.2 * 255).toInt(),
                    ),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildImageContent(),
            ),

            // Loading Overlay (during image processing)
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withAlpha((0.6 * 255).toInt()),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: widget.size * 0.3,
                      height: widget.size * 0.3,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Hover Overlay (only when not loading)
            if (_isHovered && !_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.shadow.withAlpha(
                      (0.4 * 255).toInt(),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.camera_alt,
                      size: widget.size * 0.25,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),

            // Edit Button (disabled during upload)
            Positioned(
              bottom: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isUploading ? null : _showImageSourceDialog,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primaryContainer,
                        ],
                      ),
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withAlpha(
                            (0.4 * 255).toInt(),
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _imageBytes != null || widget.imageUrl != null
                          ? Icons.edit
                          : Icons.add_a_photo,
                      size: 20,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
