import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../../../core/services/storage_service.dart';
import '../../../../../../core/utils/error_display_utils.dart';
import '../state/unit_wizard_provider.dart';

/// Step 5: Photos - Upload and manage unit images
class Step5Photos extends ConsumerStatefulWidget {
  final String? unitId;

  const Step5Photos({super.key, this.unitId});

  @override
  ConsumerState<Step5Photos> createState() => _Step5PhotosState();
}

class _Step5PhotosState extends ConsumerState<Step5Photos> {
  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = StorageService();
  bool _isUploading = false;

  /// Pick and upload images
  Future<void> _pickAndUploadImages() async {
    try {
      // Pick multiple images
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 80, // Compress to 80% quality
      );

      if (pickedFiles.isEmpty) return;

      setState(() => _isUploading = true);

      final wizardState = ref.read(unitWizardNotifierProvider(widget.unitId)).value;
      if (wizardState == null) return;

      // Get user ID and property ID
      final userId = ref.read(enhancedAuthProvider).firebaseUser?.uid;
      final propertyId = wizardState.propertyId;

      if (userId == null || propertyId == null) {
        throw Exception('Missing user ID or property ID');
      }

      // Upload images one by one
      final List<String> uploadedUrls = [];
      for (final file in pickedFiles) {
        final bytes = await file.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

        final url = await _storageService.uploadUnitImage(
          userId: userId,
          propertyId: propertyId,
          unitId: widget.unitId ?? 'draft_${DateTime.now().millisecondsSinceEpoch}',
          imageBytes: bytes,
          fileName: fileName,
        );

        uploadedUrls.add(url);
      }

      // Add uploaded URLs to existing images
      final currentImages = wizardState.images;
      final updatedImages = [...currentImages, ...uploadedUrls];

      // Update draft
      await ref
          .read(unitWizardNotifierProvider(widget.unitId).notifier)
          .updateField('images', updatedImages);

      // Set cover image if not set
      if (wizardState.coverImageUrl == null && updatedImages.isNotEmpty) {
        await ref
            .read(unitWizardNotifierProvider(widget.unitId).notifier)
            .updateField('coverImageUrl', updatedImages.first);
      }

      if (mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Uploaded ${uploadedUrls.length} image(s) successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          'Failed to upload images: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Delete an image
  Future<void> _deleteImage(String imageUrl, List<String> currentImages) async {
    try {
      // Remove from list
      final updatedImages = currentImages.where((url) => url != imageUrl).toList();

      await ref
          .read(unitWizardNotifierProvider(widget.unitId).notifier)
          .updateField('images', updatedImages);

      // Update cover image if deleted
      final wizardState = ref.read(unitWizardNotifierProvider(widget.unitId)).value;
      if (wizardState?.coverImageUrl == imageUrl) {
        await ref
            .read(unitWizardNotifierProvider(widget.unitId).notifier)
            .updateField('coverImageUrl', updatedImages.isNotEmpty ? updatedImages.first : null);
      }

      if (mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(context, 'Image deleted');
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(context, 'Failed to delete image: $e');
      }
    }
  }

  /// Set cover image
  Future<void> _setCoverImage(String imageUrl) async {
    try {
      await ref
          .read(unitWizardNotifierProvider(widget.unitId).notifier)
          .updateField('coverImageUrl', imageUrl);

      if (mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(context, 'Cover image updated');
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(context, 'Failed to update cover image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(unitWizardNotifierProvider(widget.unitId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return wizardState.when(
      data: (draft) {
        final images = draft.images;
        final coverImageUrl = draft.coverImageUrl;

        return Container(
          decoration: BoxDecoration(
            // TIP 1: JEDNOSTAVNI DIJAGONALNI GRADIENT (2 boje, 2 stops)
            // topLeft → bottomRight za body
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF1A1A1A), // veryDarkGray
                      Color(0xFF2D2D2D), // mediumDarkGray
                    ]
                  : const [
                      Color(0xFFF5F5F5), // Light grey
                      Colors.white,      // white
                    ],
              stops: const [0.0, 0.3],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Fotografije',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Dodajte fotografije smještajne jedinice (preporučeno min. 5)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Upload Section Card - matching Step 1-4 styling
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        // TIP 1: JEDNOSTAVNI DIJAGONALNI GRADIENT (2 boje, 2 stops)
                        // topRight → bottomLeft za section
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: isDark
                              ? const [
                                  Color(0xFF1A1A1A), // veryDarkGray
                                  Color(0xFF2D2D2D), // mediumDarkGray
                                ]
                              : const [
                                  Color(0xFFF5F5F5), // Light grey
                                  Colors.white,      // white
                                ],
                          stops: const [0.0, 0.3],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 16 : 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with icon - Minimalist
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(
                                      (0.12 * 255).toInt(),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.photo_library,
                                    color: theme.colorScheme.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Galerija Fotografija',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Upload fotografija vaše jedinice',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 20),

                            // Upload button
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _isUploading ? null : _pickAndUploadImages,
                                icon: _isUploading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            theme.colorScheme.onPrimary,
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.add_photo_alternate, size: 20),
                                label: Text(_isUploading ? 'Uploading...' : 'Dodaj Fotografije'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Empty state or image count
                            if (images.isEmpty)
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.photo_library_outlined,
                                      size: 48,
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Nema fotografija',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${images.length} ${images.length == 1 ? 'fotografija' : 'fotografija'}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Images grid
                if (images.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spaceL),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final imageUrl = images[index];
                      final isCover = imageUrl == coverImageUrl;

                      return Stack(
                        children: [
                          // Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isCover
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                                  width: isCover ? 3 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.broken_image,
                                      color: theme.colorScheme.error,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // Cover badge
                          if (isCover)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Naslovna',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                          // Action buttons
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Set cover button
                                if (!isCover)
                                  IconButton(
                                    onPressed: () => _setCoverImage(imageUrl),
                                    icon: const Icon(Icons.star_border, size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(8),
                                    ),
                                    tooltip: 'Postavi kao naslovnu',
                                  ),

                                const SizedBox(width: 4),

                                // Delete button
                                IconButton(
                                  onPressed: () => _deleteImage(imageUrl, images),
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(8),
                                  ),
                                  tooltip: 'Obriši',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
