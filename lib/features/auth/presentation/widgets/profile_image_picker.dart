import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Profile Image Picker Widget
/// Displays a circular avatar with option to upload/change image
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
  String? _imageName;
  bool _isHovered = false;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = image.name;
        });
        widget.onImageSelected(bytes, image.name);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
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
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B4CE6), // Purple
            Color(0xFF4A90E2), // Blue
          ],
        ),
      ),
      child: Center(
        child: Text(
          widget.initials?.toUpperCase() ?? '?',
          style: TextStyle(
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Stack(
          children: [
            // Main Image Container with Border
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6B4CE6).withAlpha((0.3 * 255).toInt()),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4CE6).withAlpha((0.2 * 255).toInt()),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildImageContent(),
            ),

            // Hover Overlay
            if (_isHovered)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withAlpha((0.4 * 255).toInt()),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.camera_alt,
                      size: widget.size * 0.25,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Edit Button
            Positioned(
              bottom: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6B4CE6),
                          Color(0xFF4A90E2),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B4CE6).withAlpha((0.4 * 255).toInt()),
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
                      color: Colors.white,
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
