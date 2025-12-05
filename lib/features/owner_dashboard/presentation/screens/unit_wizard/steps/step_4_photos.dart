import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../../../core/services/storage_service.dart';
import '../../../../../../core/utils/error_display_utils.dart';
import '../../../../../../core/theme/gradient_extensions.dart';
import '../state/unit_wizard_provider.dart';

/// Step 4: Photos - Upload and manage unit images
class Step4Photos extends ConsumerStatefulWidget {
  final String? unitId;

  const Step4Photos({super.key, this.unitId});

  @override
  ConsumerState<Step4Photos> createState() => _Step4PhotosState();
}

class _Step4PhotosState extends ConsumerState<Step4Photos> {
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

      // Get user ID
      final userId = ref.read(enhancedAuthProvider).firebaseUser?.uid;

      if (userId == null) {
        throw AuthException('User not authenticated', code: 'auth/not-authenticated');
      }

      // Use propertyId if available, otherwise use 'draft' folder
      // Images will be stored in user's draft folder during wizard flow
      // and can be moved/associated with proper property when unit is published
      final propertyId = wizardState.propertyId ?? 'draft';

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
      ref.read(unitWizardNotifierProvider(widget.unitId).notifier).updateField('images', updatedImages);

      // Set cover image if not set
      if (wizardState.coverImageUrl == null && updatedImages.isNotEmpty) {
        ref.read(unitWizardNotifierProvider(widget.unitId).notifier).updateField('coverImageUrl', updatedImages.first);
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showSuccessSnackBar(context, l10n.unitWizardStep4UploadSuccess(uploadedUrls.length));
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(context, l10n.unitWizardStep4UploadError(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Delete an image
  void _deleteImage(String imageUrl, List<String> currentImages) {
    // Remove from list
    final updatedImages = currentImages.where((url) => url != imageUrl).toList();

    ref.read(unitWizardNotifierProvider(widget.unitId).notifier).updateField('images', updatedImages);

    // Update cover image if deleted
    final wizardState = ref.read(unitWizardNotifierProvider(widget.unitId)).value;
    if (wizardState?.coverImageUrl == imageUrl) {
      ref
          .read(unitWizardNotifierProvider(widget.unitId).notifier)
          .updateField('coverImageUrl', updatedImages.isNotEmpty ? updatedImages.first : null);
    }

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ErrorDisplayUtils.showSuccessSnackBar(context, l10n.unitWizardStep4ImageDeleted);
    }
  }

  /// Set cover image
  void _setCoverImage(String imageUrl) {
    ref.read(unitWizardNotifierProvider(widget.unitId).notifier).updateField('coverImageUrl', imageUrl);

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ErrorDisplayUtils.showSuccessSnackBar(context, l10n.unitWizardStep4CoverUpdated);
    }
  }

  /// Build images grid with Wrap layout
  Widget _buildImagesGrid(List<String> images, String? coverImageUrl, ThemeData theme, AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: images.map((imageUrl) {
        final isCover = imageUrl == coverImageUrl;

        return SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            children: [
              // Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCover ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: isCover ? 3 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.broken_image, color: theme.colorScheme.error, size: 24),
                      );
                    },
                  ),
                ),
              ),

              // Cover badge
              if (isCover)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      l10n.unitWizardStep4Cover,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),

              // Action buttons - compact for 100x100
              Positioned(
                top: 4,
                right: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Set cover button (star icon)
                    if (!isCover)
                      IconButton.filled(
                        onPressed: () => _setCoverImage(imageUrl),
                        icon: const Icon(Icons.star_border, size: 14),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(24, 24),
                        ),
                        tooltip: l10n.unitWizardStep4SetCover,
                      ),

                    // Delete button
                    IconButton.filled(
                      onPressed: () => _deleteImage(imageUrl, images),
                      icon: const Icon(Icons.close, size: 14),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(24, 24),
                      ),
                      tooltip: l10n.unitWizardStep4Delete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wizardState = ref.watch(unitWizardNotifierProvider(widget.unitId));
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return wizardState.when(
      data: (draft) {
        final images = draft.images;
        final coverImageUrl = draft.coverImageUrl;

        // Horizontal gradient (left → right) - matches footer gradient for seamless transition
        return Container(
          decoration: BoxDecoration(gradient: context.gradients.pageBackground),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  l10n.unitWizardStep4Title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  l10n.unitWizardStep4Subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                // Upload Section Card - matching Step 1-3 styling
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.brightness == Brightness.dark
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
                        // Section cards: topRight → bottomLeft (tamniji desno 30%, svjetliji lijevo 70%)
                        color: context.gradients.cardBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: context.gradients.sectionBorder, width: 1.5),
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
                                    color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.photo_library, color: theme.colorScheme.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.unitWizardStep4Gallery,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.unitWizardStep4GalleryDesc,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 20),

                            // Content: Left controls + Right images grid
                            if (isMobile)
                              // Mobile: Vertical layout
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Upload button aligned left
                                  ElevatedButton.icon(
                                    onPressed: _isUploading ? null : _pickAndUploadImages,
                                    icon: _isUploading
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary),
                                            ),
                                          )
                                        : const Icon(Icons.add_photo_alternate, size: 20),
                                    label: Text(
                                      _isUploading ? l10n.unitWizardStep4Uploading : l10n.unitWizardStep4AddPhotos,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Photo count
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      l10n.unitWizardStep4PhotoCount(images.length),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Images grid or empty state
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
                                            l10n.unitWizardStep4NoPhotos,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    _buildImagesGrid(images, coverImageUrl, theme, l10n),
                                ],
                              )
                            else
                              // Desktop: Horizontal layout - Left controls, Right images
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left column: Button + count
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Upload button
                                      ElevatedButton.icon(
                                        onPressed: _isUploading ? null : _pickAndUploadImages,
                                        icon: _isUploading
                                            ? SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary),
                                                ),
                                              )
                                            : const Icon(Icons.add_photo_alternate, size: 20),
                                        label: Text(
                                          _isUploading ? l10n.unitWizardStep4Uploading : l10n.unitWizardStep4AddPhotos,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.colorScheme.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Photo count
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          l10n.unitWizardStep4PhotoCount(images.length),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 24),

                                  // Right: Images grid (expandable)
                                  Expanded(
                                    child: images.isEmpty
                                        ? Center(
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.photo_library_outlined,
                                                  size: 48,
                                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  l10n.unitWizardStep4NoPhotos,
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : _buildImagesGrid(images, coverImageUrl, theme, l10n),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
