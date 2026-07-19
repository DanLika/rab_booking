import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/slug_utils.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../../../shared/widgets/app_filter_chip.dart';
import '../widgets/embed_code_generator_dialog.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../providers/owner_properties_provider.dart';
import '../providers/owner_calendar_provider.dart';

/// Unit form screen for add/edit
class UnitFormScreen extends ConsumerStatefulWidget {
  const UnitFormScreen({required this.propertyId, this.unit, super.key});

  final String propertyId;
  final UnitModel? unit;

  @override
  ConsumerState<UnitFormScreen> createState() => _UnitFormScreenState();
}

class _UnitFormScreenState extends ConsumerState<UnitFormScreen>
    with AndroidKeyboardDismissFixApproach1<UnitFormScreen> {
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
    // Restore amenities — without this the save path wrote the empty
    // selection and silently wiped them (audit F4.2).
    _selectedAmenities
      ..clear()
      ..addAll(PropertyAmenity.fromStringList(unit.amenities));

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
    final l10n = AppLocalizations.of(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Handle browser back button on Chrome Android
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/owner/properties');
          }
        }
      },
      child: KeyedSubtree(
        key: ValueKey('unit_form_$keyboardFixRebuildKey'),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: CommonAppBar(
            title: _isEditing ? l10n.unitFormTitleEdit : l10n.unitFormTitleAdd,
            leadingIcon: Icons.arrow_back,
            onLeadingIconTap: (context) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/owner/properties');
              }
            },
          ),
          body: Container(
            // Page background — FLAT solid fill since CHANGELOG 7.23
            // (pageBackground renders as solid; matches PropertyFormScreen)
            decoration: BoxDecoration(
              gradient: context.gradients.pageBackground,
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Note: ListView handles keyboard spacing automatically when resizeToAvoidBottomInset is true
                  return Stack(
                    children: [
                      Form(
                        key: _formKey,
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
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
                              title: l10n.unitFormBasicInfo,
                              icon: Icons.info_outline,
                              children: [
                                BbInput(
                                  key: const ValueKey('unit_form_name'),
                                  controller: _nameController,
                                  label: l10n.unitFormUnitName,
                                  placeholder: l10n.unitFormUnitNameHint,
                                  iconLeft: 'meeting_room',
                                  size: BbInputSize.lg,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.unitFormUnitNameRequired;
                                    }
                                    return null;
                                  },
                                  onChanged: (value) => _autoGenerateSlug(),
                                ),
                                const SizedBox(height: AppDimensions.spaceM),
                                BbInput(
                                  key: const ValueKey('unit_form_slug'),
                                  controller: _slugController,
                                  label: l10n.unitFormUrlSlug,
                                  placeholder: l10n.unitFormUrlSlugHint,
                                  helper: l10n.unitFormUrlSlugHelper,
                                  iconLeft: 'link',
                                  size: BbInputSize.lg,
                                  trailingAction: IconButton(
                                    icon: const Icon(Icons.refresh),
                                    tooltip: l10n.unitFormRegenerateSlug,
                                    onPressed: () {
                                      setState(() {
                                        _isManualSlugEdit = false;
                                        _autoGenerateSlug();
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.unitFormSlugRequired;
                                    }
                                    if (!isValidSlug(value)) {
                                      return l10n.unitFormSlugInvalid;
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
                                BbInput(
                                  key: const ValueKey('unit_form_description'),
                                  controller: _descriptionController,
                                  label: l10n.unitFormDescription,
                                  placeholder: l10n.unitFormDescriptionHint,
                                  size: BbInputSize.lg,
                                  maxLines: 3,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spaceM),

                            // Capacity Section
                            _buildSection(
                              context,
                              title: l10n.unitFormCapacity,
                              icon: Icons.people_outline,
                              children: [
                                BbInput(
                                  key: const ValueKey('unit_form_bedrooms'),
                                  controller: _bedroomsController,
                                  label: l10n.unitFormBedrooms,
                                  iconLeft: 'bed',
                                  size: BbInputSize.lg,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.unitFormRequired;
                                    }
                                    final num = int.tryParse(value);
                                    if (num == null || num < 0) {
                                      return l10n.unitFormInvalidNumber;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppDimensions.spaceS),
                                BbInput(
                                  key: const ValueKey('unit_form_bathrooms'),
                                  controller: _bathroomsController,
                                  label: l10n.unitFormBathrooms,
                                  iconLeft: 'bathroom',
                                  size: BbInputSize.lg,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.unitFormRequired;
                                    }
                                    final num = int.tryParse(value);
                                    if (num == null || num < 1) {
                                      return l10n.unitFormMin1;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppDimensions.spaceS),
                                BbInput(
                                  key: const ValueKey('unit_form_max_guests'),
                                  controller: _maxGuestsController,
                                  label: l10n.unitFormMaxGuests,
                                  iconLeft: 'person',
                                  size: BbInputSize.lg,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.unitFormRequired;
                                    }
                                    final num = int.tryParse(value);
                                    if (num == null || num < 1 || num > 16) {
                                      return l10n.unitFormRange1to16;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppDimensions.spaceS),
                                BbInput(
                                  key: const ValueKey('unit_form_area'),
                                  controller: _areaController,
                                  label: l10n.unitFormArea,
                                  iconLeft: 'aspect_ratio',
                                  size: BbInputSize.lg,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spaceM),

                            // Pricing Section
                            _buildSection(
                              context,
                              title: l10n.unitFormPricing,
                              icon: Icons.euro,
                              children: [
                                BbInput(
                                  key: const ValueKey('unit_form_price'),
                                  controller: _priceController,
                                  label: l10n.unitFormPricePerNight,
                                  iconLeft: 'payments',
                                  size: BbInputSize.lg,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.unitFormRequired;
                                    }
                                    final num = double.tryParse(value);
                                    if (num == null || num <= 0) {
                                      return l10n.unitFormInvalidAmount;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppDimensions.spaceS),
                                BbInput(
                                  key: const ValueKey('unit_form_min_stay'),
                                  controller: _minStayController,
                                  label: l10n.unitFormMinNights,
                                  iconLeft: 'nights_stay',
                                  size: BbInputSize.lg,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.unitFormRequired;
                                    }
                                    final num = int.tryParse(value);
                                    if (num == null || num < 1) {
                                      return l10n.unitFormMin1;
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
                              title: l10n.unitFormAmenities,
                              icon: Icons.star_outline,
                              children: [_buildAmenitiesGrid()],
                            ),
                            const SizedBox(height: AppDimensions.spaceM),

                            // Images Section
                            _buildSection(
                              context,
                              title: l10n.unitFormPhotos,
                              icon: Icons.photo_library_outlined,
                              children: [_buildImagesSection()],
                            ),
                            const SizedBox(height: AppDimensions.spaceM),

                            // Availability Section
                            _buildSection(
                              context,
                              title: l10n.unitFormAvailability,
                              icon: Icons.toggle_on_outlined,
                              children: [
                                BbSwitch(
                                  value: _isAvailable,
                                  onChanged: (value) =>
                                      setState(() => _isAvailable = value),
                                  label: l10n.unitFormAvailableForBooking,
                                  subtitle: _isAvailable
                                      ? l10n.unitFormAvailableDesc
                                      : l10n.unitFormUnavailableDesc,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spaceM),

                            // Primary save CTA on design-system `BbButton` —
                            // replaces hand-rolled `GradientButton` with the
                            // handoff `--bb-primary` + `--bb-shadow-purple-sm`
                            // surface (matches Bank Account / Edit Profile / iCal).
                            BbButton(
                              label: _isEditing
                                  ? l10n.unitFormSaveChanges
                                  : l10n.unitFormAddUnit,
                              iconLeft: _isEditing ? 'save' : 'add',
                              size: BbButtonSize.lg,
                              fullWidth: true,
                              loading: _isLoading,
                              onPressed: _isLoading ? null : _handleSave,
                            ),

                            // Widget Settings & Embed Code section (only when editing)
                            if (_isEditing && widget.unit != null) ...[
                              const SizedBox(height: AppDimensions.spaceM),
                              _buildSection(
                                context,
                                title: l10n.unitFormEmbedWidget,
                                icon: Icons.widgets,
                                children: [
                                  Text(
                                    l10n.unitFormEmbedDesc,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withAlpha((0.7 * 255).toInt()),
                                    ),
                                  ),
                                  const SizedBox(height: AppDimensions.spaceM),
                                  BbButton(
                                    label: l10n.unitFormWidgetSettings,
                                    iconLeft: 'settings',
                                    variant: BbButtonVariant.secondary,
                                    size: BbButtonSize.lg,
                                    fullWidth: true,
                                    onPressed: () {
                                      context.push(
                                        OwnerRoutes.unitWidgetSettings
                                            .replaceAll(':id', widget.unit!.id),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: AppDimensions.spaceS),
                                  BbButton(
                                    label: l10n.unitFormGenerateEmbed,
                                    iconLeft: 'code',
                                    variant: BbButtonVariant.secondary,
                                    size: BbButtonSize.lg,
                                    fullWidth: true,
                                    onPressed: () async {
                                      final property = await ref.read(
                                        propertyByIdProvider(
                                          widget.propertyId,
                                        ).future,
                                      );
                                      if (!context.mounted) return;
                                      await showDialog(
                                        context: context,
                                        builder: (context) =>
                                            EmbedCodeGeneratorDialog(
                                              unitId: widget.unit!.id,
                                              propertyId: widget.propertyId,
                                              unitName: widget.unit!.name,
                                              propertySubdomain:
                                                  property?.subdomain,
                                              unitSlug: widget.unit!.slug,
                                            ),
                                      );
                                    },
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
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      l10n.unitFormSaving,
                                      style: const TextStyle(
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
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to build consistent section cards — FLAT recipe since
  /// CHANGELOG 7.23 (cardBackground renders as a solid fill + sectionBorder
  /// + radius 24), matching [PropertyFormScreen._buildSection] and the
  /// Widget Settings sections.
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
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
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.gradients.sectionBorder,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmenitiesGrid() {
    final locale = Localizations.localeOf(context).languageCode;

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
        return AppFilterChip(
          label: amenity.localizedName(locale),
          selected: isSelected,
          icon: _getAmenityIcon(amenity.iconName),
          onSelected: () {
            setState(() {
              if (isSelected) {
                _selectedAmenities.remove(amenity);
              } else {
                _selectedAmenities.add(amenity);
              }
            });
          },
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

        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return BbButton(
              label: totalImages == 0
                  ? l10n.unitFormAddPhotos
                  : l10n.unitFormAddMore,
              iconLeft: 'add_photo_alternate',
              variant: BbButtonVariant.secondary,
              onPressed: _pickImages,
            );
          },
        ),

        if (totalImages > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Text(
                  l10n.unitFormTotalPhotos(totalImages),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textColorSecondary,
                  ),
                );
              },
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: ImageUtils.cacheSize(context, 100),
                placeholder: (context, url) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image,
                    color: theme.colorScheme.onSurface.withAlpha(
                      (0.3 * 255).toInt(),
                    ),
                  ),
                ),
              ),
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
    final List<XFile> images = await picker.pickMultiImage(
      maxWidth: ImageUtils.kMaxUploadWidth.toDouble(),
      maxHeight: ImageUtils.kMaxUploadWidth.toDouble(), // Allow square max
      imageQuality: 85,
    );

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
          area: double.tryParse(_areaController.text),
          minStayNights: int.parse(_minStayController.text),
          amenities: PropertyAmenity.toStringList(_selectedAmenities.toList()),
          images: allImages,
          coverImage: allImages.isNotEmpty ? allImages.first : null,
          isAvailable: _isAvailable,
        );
      } else {
        // Create new unit
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }
        await repository.createUnit(
          propertyId: widget.propertyId,
          ownerId: currentUser.uid,
          name: _nameController.text,
          slug: _slugController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          basePrice: double.parse(_priceController.text),
          bedrooms: int.parse(_bedroomsController.text),
          bathrooms: int.parse(_bathroomsController.text),
          maxGuests: int.parse(_maxGuestsController.text),
          area: double.tryParse(_areaController.text),
          minStayNights: int.parse(_minStayController.text),
          amenities: PropertyAmenity.toStringList(_selectedAmenities.toList()),
          images: allImages,
          coverImage: allImages.isNotEmpty ? allImages.first : null,
        );
      }

      // Invalidate calendar provider so timeline shows new unit immediately
      ref.invalidate(allOwnerUnitsProvider);

      if (mounted) {
        final l10nSuccess = AppLocalizations.of(context);
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/owner/properties');
        }
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          _isEditing
              ? l10nSuccess.unitFormSuccessUpdate
              : l10nSuccess.unitFormSuccessAdd,
        );
      }
    } catch (e) {
      // FIXED: Use ErrorDisplayUtils for user-friendly error messages
      if (mounted) {
        final l10nError = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: _isEditing
              ? l10nError.unitFormErrorUpdate
              : l10nError.unitFormErrorAdd,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getAmenityIcon(String iconName) => switch (iconName) {
    'wifi' => Icons.wifi,
    'ac_unit' => Icons.ac_unit,
    'whatshot' => Icons.whatshot,
    'kitchen' => Icons.kitchen,
    'tv' => Icons.tv,
    'balcony' => Icons.balcony,
    'beach_access' => Icons.beach_access,
    'local_laundry_service' => Icons.local_laundry_service,
    _ => Icons.check,
  };
}
