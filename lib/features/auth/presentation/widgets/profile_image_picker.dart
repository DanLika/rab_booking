import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../../../../l10n/app_localizations.dart';
class ProfileImagePicker extends StatefulWidget {
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

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  Uint8List? _imageBytes;
  bool _isHovered = false;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    setState(() => _isUploading = true);
    final l10n = AppLocalizations.of(context);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        // Keep resizing options to compress larger images on the client-side
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      // User cancelled the picker
      if (image == null) {
        if (mounted) setState(() => _isUploading = false);
        return;
      }

      // === Validation Logic ===
      const maxSizeInBytes = 5 * 1024 * 1024; // 5 MB
      final imageSizeBytes = await image.length();

      // 1. Size Check
      if (imageSizeBytes > maxSizeInBytes) {
        if (mounted) {
          setState(() => _isUploading = false);
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            l10n.profileImageTooLarge(5), // Assuming l10n has this
          );
        }
        return;
      }

      // 2. Format Check
      final supportedFormats = ['.jpg', '.jpeg', '.png'];
      final fileExtension = p.extension(image.name).toLowerCase();
      if (!supportedFormats.contains(fileExtension)) {
        if (mounted) {
          setState(() => _isUploading = false);
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            l10n.profileImageInvalidFormat, // Assuming l10n has this
          );
        }
        return;
      }
      // === End Validation ===

      final bytes = await image.readAsBytes();
      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _isUploading = false;
      });
      widget.onImageSelected(bytes, image.name);

    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        l10n.profileImagePickError, // Assuming l10n has this
        error: e,
      );
    }
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
                  onTap: _isUploading ? null : _pickImage,
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
