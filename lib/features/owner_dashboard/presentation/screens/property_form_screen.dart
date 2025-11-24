import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/slug_utils.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../providers/owner_properties_provider.dart';
import '../../../../shared/widgets/common_app_bar.dart';

/// Modern Property form screen for add/edit with enhanced UI
class PropertyFormScreen extends ConsumerStatefulWidget {
  const PropertyFormScreen({this.property, super.key});

  final PropertyModel? property;

  @override
  ConsumerState<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends ConsumerState<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();

  PropertyType _selectedType = PropertyType.apartment;
  Set<PropertyAmenity> _selectedAmenities = {};
  final List<XFile> _selectedImages = [];
  List<String> _existingImages = [];
  bool _isPublished = false;
  bool _isLoading = false;
  bool _isManualSlugEdit = false;

  bool get _isEditing => widget.property != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadPropertyData();
    }
  }

  void _loadPropertyData() {
    final property = widget.property!;
    _nameController.text = property.name;
    _slugController.text = property.slug ?? generateSlug(property.name);
    _descriptionController.text = property.description;
    _selectedType = property.propertyType;
    _locationController.text = property.location;
    _addressController.text = property.address ?? '';
    _selectedAmenities = property.amenities.toSet();
    _existingImages = property.images.toList();
    _isPublished = property.isActive;
    _isManualSlugEdit = property.slug != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _autoGenerateSlug() {
    if (!_isManualSlugEdit && _nameController.text.isNotEmpty) {
      _slugController.text = generateSlug(_nameController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.colorScheme.surface,
      appBar: CommonAppBar(
        title: _isEditing ? 'Uredi Nekretninu' : 'Dodaj Nekretninu',
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 16 : 24,
                isMobile ? 16 : 24,
                24,
              ),
              children: [
                // Basic Info Section
                _buildSection(
                  context,
                  title: 'Osnovne Informacije',
                  icon: Icons.info_outline,
                  children: [
                    // Property Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecorationHelper.buildDecoration(
                        context,
                        labelText: 'Naziv nekretnine *',
                        hintText: 'npr. Villa Mediteran',
                        isMobile: isMobile,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Naziv je obavezan';
                        }
                        return null;
                      },
                      onChanged: (value) => _autoGenerateSlug(),
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    // URL Slug
                    TextFormField(
                      controller: _slugController,
                      decoration: InputDecorationHelper.buildDecoration(
                        context,
                        labelText: 'URL Slug',
                        hintText: 'villa-mediteran',
                        helperText: 'SEO-friendly URL: /booking/{slug}',
                        isMobile: isMobile,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Regeneriši iz naziva',
                          onPressed: () {
                            setState(() {
                              _isManualSlugEdit = false;
                              _autoGenerateSlug();
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Slug je obavezan';
                        }
                        if (!isValidSlug(value)) {
                          return 'Slug može sadržavati samo mala slova, brojeve i crtice';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(() => _isManualSlugEdit = true);
                        }
                      },
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    // Property Type
                    DropdownButtonFormField<PropertyType>(
                      initialValue: _selectedType,
                      decoration: InputDecorationHelper.buildDecoration(
                        context,
                        labelText: 'Tip nekretnine *',
                        isMobile: isMobile,
                      ),
                      items: PropertyType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.displayNameHR),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecorationHelper.buildDecoration(
                        context,
                        labelText: 'Opis *',
                        hintText: 'Detaljno opišite vašu nekretninu...',
                        isMobile: isMobile,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Opis je obavezan';
                        }
                        if (value.length < 100) {
                          return 'Opis mora imati najmanje 100 znakova (trenutno: ${value.length})';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceL),

                // Location Section
                _buildSection(
                  context,
                  title: 'Lokacija',
                  icon: Icons.location_on,
                  children: [
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecorationHelper.buildDecoration(
                        context,
                        labelText: 'Lokacija *',
                        hintText: 'npr. Rab (grad), Otok Rab',
                        prefixIcon: const Icon(Icons.location_on),
                        isMobile: isMobile,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lokacija je obavezna';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecorationHelper.buildDecoration(
                        context,
                        labelText: 'Adresa',
                        hintText: 'Ulica i broj',
                        prefixIcon: const Icon(Icons.home),
                        isMobile: isMobile,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceL),

                // Amenities Section
                _buildSection(
                  context,
                  title: 'Sadržaji',
                  icon: Icons.local_offer,
                  children: [_buildAmenitiesGrid()],
                ),
                const SizedBox(height: AppDimensions.spaceL),

                // Images Section
                _buildSection(
                  context,
                  title: 'Fotografije ${_isEditing ? '' : '(min 3)'}',
                  icon: Icons.photo_library,
                  children: [_buildImagesSection()],
                ),
                const SizedBox(height: AppDimensions.spaceL),

                // Settings Section
                _buildSection(
                  context,
                  title: 'Postavke',
                  icon: Icons.settings,
                  children: [
                    SwitchListTile(
                      title: const Text('Objavi odmah'),
                      subtitle: Text(
                        _isPublished
                            ? 'Nekretnina će biti vidljiva korisnicima'
                            : 'Nekretnina će biti skrivena',
                      ),
                      value: _isPublished,
                      onChanged: (value) =>
                          setState(() => _isPublished = value),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceL),

                // Modern Gradient Save Button
                GradientButton(
                  text: _isEditing ? 'Spremi Izmjene' : 'Dodaj Nekretninu',
                  onPressed: _handleSave,
                  isLoading: _isLoading,
                  icon: _isEditing ? Icons.save : Icons.add,
                  width: double.infinity,
                ),
                const SizedBox(height: AppDimensions.spaceXL),
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha((0.5 * 255).toInt()),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.authSecondary,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Čuvanje...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Helper: Build a section card with title and icon
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Section Content
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesGrid() {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PropertyAmenity.values.map((amenity) {
        final isSelected = _selectedAmenities.contains(amenity);
        return FilterChip(
          label: Text(
            amenity.displayName,
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            print('🎯 [AMENITY] Chip tapped: ${amenity.displayName}');
            print('📊 [AMENITY] Selected: $selected (was: $isSelected)');
            print(
              '📋 [AMENITY] Current set (${_selectedAmenities.length} items): ${_selectedAmenities.map((a) => a.displayName).join(", ")}',
            );

            setState(() {
              // Force create new Set to trigger rebuild
              if (selected) {
                _selectedAmenities = {..._selectedAmenities, amenity};
                print('✅ [AMENITY] Added ${amenity.displayName}');
              } else {
                _selectedAmenities = Set.from(_selectedAmenities)
                  ..remove(amenity);
                print('❌ [AMENITY] Removed ${amenity.displayName}');
              }
              print(
                '📊 [AMENITY] New set (${_selectedAmenities.length} items): ${_selectedAmenities.map((a) => a.displayName).join(", ")}',
              );
            });
          },
          avatar: Icon(
            _getAmenityIcon(amenity.iconName),
            size: 18,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImagesSection() {
    final totalImages = _existingImages.length + _selectedImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing images
        if (_existingImages.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _existingImages.asMap().entries.map((entry) {
              final index = entry.key;
              final imageUrl = entry.value;
              return _buildExistingImageCard(imageUrl, index);
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // New images
        if (_selectedImages.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;
              return _buildNewImageCard(image, index);
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Add images button
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: Text(
            totalImages == 0
                ? 'Dodaj fotografije (min 3)'
                : 'Dodaj još fotografija',
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        if (totalImages > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Ukupno: $totalImages fotografija',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.textColorSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExistingImageCard(String imageUrl, int index) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withAlpha((0.5 * 255).toInt()),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image,
                    color: theme.colorScheme.onSurface.withAlpha(
                      (0.3 * 255).toInt(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton.filled(
            onPressed: () {
              setState(() => _existingImages.removeAt(index));
            },
            icon: const Icon(Icons.close, size: 16),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              padding: EdgeInsets.zero,
              minimumSize: const Size(24, 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewImageCard(XFile image, int index) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withAlpha((0.5 * 255).toInt()),
            ),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(image.path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.broken_image,
                  size: 40,
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.3 * 255).toInt(),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton.filled(
            onPressed: () {
              setState(() => _selectedImages.removeAt(index));
            },
            icon: const Icon(Icons.close, size: 16),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              padding: EdgeInsets.zero,
              minimumSize: const Size(24, 24),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final totalImages = _existingImages.length + _selectedImages.length;
    if (!_isEditing && totalImages < 3) {
      // Soft warning - allow save without blocking
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Preporuka: Dodajte najmanje 3 fotografije za bolju vidljivost',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      // Continue with save (no return)
    }

    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuth.instance;
      final ownerId = auth.currentUser?.uid;

      if (ownerId == null) {
        throw Exception('Korisnik nije prijavljen');
      }

      final repository = ref.read(ownerPropertiesRepositoryProvider);

      // Upload new images to Firebase Storage
      final List<String> uploadedImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        print(
          '🔍 [UPLOAD] Starting upload for ${_selectedImages.length} images',
        );

        try {
          final propertyId = _isEditing
              ? widget.property!.id
              : 'temp-${DateTime.now().millisecondsSinceEpoch}';

          print('📦 [UPLOAD] PropertyId: $propertyId');

          for (int i = 0; i < _selectedImages.length; i++) {
            final image = _selectedImages[i];
            print(
              '📸 [UPLOAD] Image ${i + 1}/${_selectedImages.length} - Path: ${image.path}',
            );

            final bytes = await image.readAsBytes();
            print('✅ [UPLOAD] Read ${bytes.length} bytes');

            print('☁️ [UPLOAD] Calling uploadPropertyImage...');
            final imageUrl = await repository.uploadPropertyImage(
              propertyId: propertyId,
              filePath: image.path,
              bytes: bytes,
            );
            print('✅ [UPLOAD] Success! URL: $imageUrl');

            uploadedImageUrls.add(imageUrl);

            if (mounted) {
              ErrorDisplayUtils.showInfoSnackBar(
                context,
                'Upload fotografija: ${i + 1}/${_selectedImages.length}',
                duration: const Duration(milliseconds: 500),
              );
            }
          }

          print('🎉 [UPLOAD] All images uploaded successfully!');
        } catch (e, stackTrace) {
          print('❌ [UPLOAD ERROR] $e');
          print('📚 [STACK TRACE] $stackTrace');

          if (mounted) {
            // Direct SnackBar for guaranteed visibility
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Greška pri uploadu: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Detalji',
                  textColor: Colors.white,
                  onPressed: () {
                    print('💥 [FULL ERROR] $e\n$stackTrace');
                  },
                ),
              ),
            );

            // Also try original method
            ErrorDisplayUtils.showErrorSnackBar(
              context,
              e,
              userMessage: 'Greška pri uploadu fotografija',
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      final allImages = [..._existingImages, ...uploadedImageUrls];

      if (_isEditing) {
        await repository.updateProperty(
          propertyId: widget.property!.id,
          name: _nameController.text,
          slug: _slugController.text,
          description: _descriptionController.text,
          propertyType: _selectedType.value,
          location: _locationController.text,
          address: _addressController.text.isEmpty
              ? null
              : _addressController.text,
          amenities: PropertyAmenity.toStringList(_selectedAmenities.toList()),
          images: allImages,
          coverImage: allImages.isNotEmpty ? allImages.first : null,
          isActive: _isPublished,
        );
      } else {
        await repository.createProperty(
          ownerId: ownerId,
          name: _nameController.text,
          slug: _slugController.text,
          description: _descriptionController.text,
          propertyType: _selectedType.value,
          location: _locationController.text,
          address: _addressController.text.isEmpty
              ? null
              : _addressController.text,
          amenities: PropertyAmenity.toStringList(_selectedAmenities.toList()),
          images: allImages,
          coverImage: allImages.isNotEmpty ? allImages.first : null,
          isActive: _isPublished,
        );
      }

      ref.invalidate(ownerPropertiesProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          _isEditing
              ? 'Nekretnina uspješno ažurirana'
              : 'Nekretnina uspješno dodana',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: _isEditing
              ? 'Greška pri ažuriranju nekretnine'
              : 'Greška pri dodavanju nekretnine',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getAmenityIcon(String iconName) {
    switch (iconName) {
      case 'wifi':
        return Icons.wifi;
      case 'local_parking':
        return Icons.local_parking;
      case 'pool':
        return Icons.pool;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'whatshot':
        return Icons.whatshot;
      case 'kitchen':
        return Icons.kitchen;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      case 'tv':
        return Icons.tv;
      case 'balcony':
        return Icons.balcony;
      case 'beach_access':
        return Icons.beach_access;
      case 'pets':
        return Icons.pets;
      case 'outdoor_grill':
        return Icons.outdoor_grill;
      case 'deck':
        return Icons.deck;
      case 'fireplace':
        return Icons.fireplace;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'hot_tub':
        return Icons.hot_tub;
      case 'spa':
        return Icons.spa;
      case 'pedal_bike':
        return Icons.pedal_bike;
      case 'sailing':
        return Icons.sailing;
      default:
        return Icons.check;
    }
  }
}
