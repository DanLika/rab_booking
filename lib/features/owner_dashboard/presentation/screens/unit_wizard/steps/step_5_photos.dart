import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../../../core/services/storage_service.dart';
import '../../../../../../core/utils/error_display_utils.dart';
import '../state/unit_wizard_provider.dart';
import '../widgets/wizard_step_container.dart';

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

    return wizardState.when(
      data: (draft) {
        final images = draft.images;
        final coverImageUrl = draft.coverImageUrl;

        return WizardStepContainer(
          title: 'Fotografije',
          subtitle: 'Dodajte fotografije smještajne jedinice (preporučeno min. 5)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upload button
              Center(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickAndUploadImages,
                  icon: _isUploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                          ),
                        )
                      : const Icon(Icons.add_photo_alternate, size: 20),
                  label: Text(_isUploading ? 'Uploading...' : 'Add Photos'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spaceL),

              // Images grid
              if (images.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No photos yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add at least 5 photos for better presentation',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
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
                                'Cover',
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
                                  tooltip: 'Set as cover',
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
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
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
