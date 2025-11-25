import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/slug_utils.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../widgets/embed_code_generator_dialog.dart';
import '../../../../shared/widgets/common_app_bar.dart';

/// Unit form screen for add/edit
class UnitFormScreen extends ConsumerStatefulWidget {
  const UnitFormScreen({required this.propertyId, this.unit, super.key});

  final String propertyId;
  final UnitModel? unit;

  @override
  ConsumerState<UnitFormScreen> createState() => _UnitFormScreenState();
}

class _UnitFormScreenState extends ConsumerState<UnitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _bedroomsController = TextEditingController(text: '1');
  final _bathroomsController = TextEditingController(text: '1');
  final _maxGuestsController = TextEditingController(text: '2');
  final _areaController = TextEditingController();
  final _minStayController = TextEditingController(text: '1');

  final Set<PropertyAmenity> _selectedAmenities = {};
  final List<XFile> _selectedImages = [];
  List<String> _existingImages = [];
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isManualSlugEdit = false;

  bool get _isEditing => widget.unit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.unit != null) {
      _loadUnitData();
    }
  }

  void _loadUnitData() {
    final unit = widget.unit!;
    _nameController.text = unit.name;
    _slugController.text = unit.slug ?? generateSlug(unit.name);
    _descriptionController.text = unit.description ?? '';
    _priceController.text = unit.pricePerNight.toStringAsFixed(0);
    _bedroomsController.text = unit.bedrooms.toString();
    _bathroomsController.text = unit.bathrooms.toString();
    _maxGuestsController.text = unit.maxGuests.toString();
    _areaController.text = unit.areaSqm?.toStringAsFixed(0) ?? '';
    _minStayController.text = unit.minStayNights.toString();
    _existingImages = unit.images.toList();
    _isAvailable = unit.isAvailable;

    // If editing existing unit, consider slug as manually set
    _isManualSlugEdit = unit.slug != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _maxGuestsController.dispose();
    _areaController.dispose();
    _minStayController.dispose();
    super.dispose();
  }

  /// Auto-generate slug from unit name
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
        title: _isEditing ? 'Uredi Jedinicu' : 'Dodaj Jedinicu',
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
                  title: 'Osnovne informacije',
                  icon: Icons.info_outline,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecorationHelper.buildDecoration(
                        labelText: 'Naziv jedinice *',
                        hintText: 'npr. Apartman prizemlje',
                        prefixIcon: const Icon(Icons.meeting_room),
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
                    TextFormField(
                      controller: _slugController,
                      decoration: InputDecorationHelper.buildDecoration(
                        labelText: 'URL Slug',
                        hintText: 'apartman-prizemlje',
                        helperText: 'SEO-friendly URL: /booking/{slug}',
                        prefixIcon: const Icon(Icons.link),
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
                        isMobile: isMobile,
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
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecorationHelper.buildDecoration(
                        labelText: 'Opis',
                        hintText: 'Dodatne informacije o jedinici...',
                        prefixIcon: const Icon(Icons.description),
                        isMobile: isMobile,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceM),

                // Capacity Section
                _buildSection(
                  context,
                  title: 'Kapacitet',
                  icon: Icons.people_outline,
                  children: [
                    TextFormField(
                      controller: _bedroomsController,
                      decoration: InputDecorationHelper.buildDecoration(
                        labelText: 'Spavaće sobe *',
                        prefixIcon: const Icon(Icons.bed),
                        isMobile: isMobile,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obavezno';
                        }
                        final num = int.tryParse(value);
                        if (num == null || num < 0) {
                          return 'Nevažeći broj';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    TextFormField(
                      controller: _bathroomsController,
                      decoration: InputDecorationHelper.buildDecoration(
                        labelText: 'Kupaonice *',
                        prefixIcon: const Icon(Icons.bathroom),
                        isMobile: isMobile,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obavezno';
                        }
                        final num = int.tryParse(value);
                        if (num == null || num < 1) {
                          return 'Min 1';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    TextFormField(
                      controller: _maxGuestsController,
                      decoration: InputDecorationHelper.buildDecoration(
                        labelText: 'Max gostiju *',
                        prefixIcon: const Icon(Icons.person),
                        isMobile: isMobile,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obavezno';
                        }
                        final num = int.tryParse(value);
                        if (num == null || num < 1 || num > 16) {
                          return '1-16';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    TextFormField(
                      controller: _areaController,
                      decoration: InputDecorationHelper.buildDecoration(
                        labelText: 'Površina (m²)',
                        prefixIcon: const Icon(Icons.aspect_ratio),
                        isMobile: isMobile,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceM),

                // Pricing Section
                _buildSection(
                  context,
                  title: 'Cijena i uvjeti',
                  icon: Icons.euro,
                  children: [
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecorationHelper.buildDecoration(
                        labelText: 'Cijena po noći (€) *',
                        prefixIcon: const Icon(Icons.payments),
                        isMobile: isMobile,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obavezno';
                        }
                        final num = double.tryParse(value);
                        if (num == null || num <= 0) {
                          return 'Nevažeći iznos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    TextFormField(
                      controller: _minStayController,
                      decoration: InputDecorationHelper.buildDecoration(
                        labelText: 'Min noći *',
                        prefixIcon: const Icon(Icons.nights_stay),
                        isMobile: isMobile,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obavezno';
                        }
                        final num = int.tryParse(value);
                        if (num == null || num < 1) {
                          return 'Min 1';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceM),

                // Amenities Section
                _buildSection(
                  context,
                  title: 'Sadržaji',
                  icon: Icons.star_outline,
                  children: [_buildAmenitiesGrid()],
                ),
                const SizedBox(height: AppDimensions.spaceM),

                // Images Section
                _buildSection(
                  context,
                  title: 'Fotografije',
                  icon: Icons.photo_library_outlined,
                  children: [_buildImagesSection()],
                ),
                const SizedBox(height: AppDimensions.spaceM),

                // Availability Section
                _buildSection(
                  context,
                  title: 'Dostupnost',
                  icon: Icons.toggle_on_outlined,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dostupno za rezervaciju'),
                      subtitle: Text(
                        _isAvailable
                            ? 'Jedinica će biti dostupna za rezervacije'
                            : 'Jedinica neće biti prikazana',
                      ),
                      trailing: Switch(
                        value: _isAvailable,
                        onChanged: (value) =>
                            setState(() => _isAvailable = value),
                        thumbColor: WidgetStateProperty.all(Colors.transparent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceM),

                // Modern Gradient Save Button
                GradientButton(
                  text: _isEditing ? 'Spremi Izmjene' : 'Dodaj Jedinicu',
                  onPressed: _handleSave,
                  isLoading: _isLoading,
                  icon: _isEditing ? Icons.save : Icons.add,
                  width: double.infinity,
                ),

                // Widget Settings & Embed Code section (only when editing)
                if (_isEditing && widget.unit != null) ...[
                  const SizedBox(height: AppDimensions.spaceM),
                  _buildSection(
                    context,
                    title: 'Embed Widget',
                    icon: Icons.widgets,
                    children: [
                      Text(
                        'Integrirajte booking widget na vašu web stranicu',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(
                            (0.7 * 255).toInt(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceM),
                      OutlinedButton.icon(
                        onPressed: () {
                          context.push(
                            OwnerRoutes.unitWidgetSettings.replaceAll(
                              ':id',
                              widget.unit!.id,
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Postavke Widgeta'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => EmbedCodeGeneratorDialog(
                              unitId: widget.unit!.id,
                              unitSlug: widget.unit!.slug,
                              unitName: widget.unit!.name,
                            ),
                          );
                        },
                        icon: const Icon(Icons.code),
                        label: const Text('Generiši Embed Kod'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

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
                          'Spremanje...',
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

  /// Helper method to build consistent section cards
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outline.withAlpha((0.2 * 255).toInt()),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesGrid() {
    final theme = Theme.of(context);

    // Show most common amenities for units
    final commonAmenities = [
      PropertyAmenity.wifi,
      PropertyAmenity.airConditioning,
      PropertyAmenity.heating,
      PropertyAmenity.kitchen,
      PropertyAmenity.tv,
      PropertyAmenity.balcony,
      PropertyAmenity.seaView,
      PropertyAmenity.washingMachine,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: commonAmenities.map((amenity) {
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
            setState(() {
              if (selected) {
                _selectedAmenities.add(amenity);
              } else {
                _selectedAmenities.remove(amenity);
              }
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

        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: Text(totalImages == 0 ? 'Dodaj fotografije' : 'Dodaj još'),
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

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(ownerPropertiesRepositoryProvider);

      // Upload new images
      List<String> uploadedImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        // Image upload implementation pending - currently skipped
        uploadedImageUrls = [];
      }

      final allImages = [..._existingImages, ...uploadedImageUrls];

      if (_isEditing) {
        // Update existing unit
        await repository.updateUnit(
          propertyId: widget.propertyId,
          unitId: widget.unit!.id,
          name: _nameController.text,
          slug: _slugController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          basePrice: double.parse(_priceController.text),
          bedrooms: int.parse(_bedroomsController.text),
          bathrooms: int.parse(_bathroomsController.text),
          maxGuests: int.parse(_maxGuestsController.text),
          area: double.parse(_areaController.text),
          minStayNights: int.parse(_minStayController.text),
          amenities: PropertyAmenity.toStringList(_selectedAmenities.toList()),
          images: allImages,
          coverImage: allImages.isNotEmpty ? allImages.first : null,
          isAvailable: _isAvailable,
        );
      } else {
        // Create new unit
        await repository.createUnit(
          propertyId: widget.propertyId,
          name: _nameController.text,
          slug: _slugController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          basePrice: double.parse(_priceController.text),
          bedrooms: int.parse(_bedroomsController.text),
          bathrooms: int.parse(_bathroomsController.text),
          maxGuests: int.parse(_maxGuestsController.text),
          area: double.parse(_areaController.text),
          minStayNights: int.parse(_minStayController.text),
          amenities: PropertyAmenity.toStringList(_selectedAmenities.toList()),
          images: allImages,
          coverImage: allImages.isNotEmpty ? allImages.first : null,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          _isEditing
              ? 'Jedinica uspješno ažurirana'
              : 'Jedinica uspješno dodana',
        );
      }
    } catch (e) {
      // FIXED: Use ErrorDisplayUtils for user-friendly error messages
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: _isEditing
              ? 'Greška pri ažuriranju jedinice'
              : 'Greška pri dodavanju jedinice',
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
      case 'ac_unit':
        return Icons.ac_unit;
      case 'whatshot':
        return Icons.whatshot;
      case 'kitchen':
        return Icons.kitchen;
      case 'tv':
        return Icons.tv;
      case 'balcony':
        return Icons.balcony;
      case 'beach_access':
        return Icons.beach_access;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      default:
        return Icons.check;
    }
  }
}
