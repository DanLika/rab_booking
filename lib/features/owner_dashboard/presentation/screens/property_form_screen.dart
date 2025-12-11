import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/design_tokens/gradient_tokens.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/keyboard_dismiss_fix_mixin.dart';
import '../../../../core/utils/slug_utils.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/app_filter_chip.dart';
import '../providers/owner_properties_provider.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../core/exceptions/app_exceptions.dart';

/// Modern Property form screen for add/edit with enhanced UI
class PropertyFormScreen extends ConsumerStatefulWidget {
  const PropertyFormScreen({this.property, super.key});

  final PropertyModel? property;

  @override
  ConsumerState<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends ConsumerState<PropertyFormScreen>
    with AndroidKeyboardDismissFix {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _subdomainController = TextEditingController();
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

  // Subdomain state
  bool _isManualSubdomainEdit = false;
  bool _isCheckingSubdomain = false;
  bool? _isSubdomainAvailable;
  String? _subdomainError;
  String? _subdomainSuggestion;
  Timer? _subdomainDebounceTimer;

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
    _subdomainController.text = property.subdomain ?? '';
    _descriptionController.text = property.description;
    _selectedType = property.propertyType;
    _locationController.text = property.location;
    _addressController.text = property.address ?? '';
    _selectedAmenities = property.amenities.toSet();
    _existingImages = property.images.toList();
    _isPublished = property.isActive;
    _isManualSlugEdit = property.slug != null;
    _isManualSubdomainEdit =
        property.subdomain != null && property.subdomain!.isNotEmpty;

    // Check existing subdomain availability (should be valid, but good UX feedback)
    if (_subdomainController.text.isNotEmpty) {
      _checkSubdomainAvailability(_subdomainController.text);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _subdomainController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _subdomainDebounceTimer?.cancel();
    super.dispose();
  }

  void _autoGenerateSlug() {
    if (!_isManualSlugEdit && _nameController.text.isNotEmpty) {
      _slugController.text = generateSlug(_nameController.text);
    }
  }

  /// Auto-generate subdomain from property name (with debounce)
  void _autoGenerateSubdomain() {
    if (!_isManualSubdomainEdit && _nameController.text.isNotEmpty) {
      _generateSubdomainFromName(_nameController.text);
    }
  }

  /// Generate subdomain from name using Cloud Function
  Future<void> _generateSubdomainFromName(String propertyName) async {
    if (propertyName.isEmpty) return;

    setState(() {
      _isCheckingSubdomain = true;
      _isSubdomainAvailable = null;
      _subdomainError = null;
      _subdomainSuggestion = null;
    });

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateSubdomainFromName');
      final result = await callable.call<Map<String, dynamic>>({
        'propertyName': propertyName,
        'propertyId': _isEditing ? widget.property!.id : null,
      });

      if (mounted) {
        final data = result.data;
        final generatedSubdomain = data['subdomain'] as String;

        setState(() {
          _subdomainController.text = generatedSubdomain;
          _isCheckingSubdomain = false;
          _isSubdomainAvailable = true;
          _subdomainError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _isCheckingSubdomain = false;
          _subdomainError = l10n.propertyFormGeneratingError(
            e.toString().replaceFirst('Exception: ', ''),
          );
        });
      }
    }
  }

  /// Check subdomain availability with debounce
  void _onSubdomainChanged(String value) {
    _subdomainDebounceTimer?.cancel();

    if (value.isEmpty) {
      setState(() {
        _isSubdomainAvailable = null;
        _subdomainError = null;
        _subdomainSuggestion = null;
        _isCheckingSubdomain = false;
      });
      return;
    }

    // Mark as manual edit
    setState(() {
      _isManualSubdomainEdit = true;
      _isCheckingSubdomain = true;
      _isSubdomainAvailable = null;
    });

    // Debounce the availability check (500ms)
    _subdomainDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkSubdomainAvailability(value);
    });
  }

  /// Check subdomain availability using Cloud Function
  Future<void> _checkSubdomainAvailability(String subdomain) async {
    if (subdomain.isEmpty) return;

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('checkSubdomainAvailability');
      final result = await callable.call<Map<String, dynamic>>({
        'subdomain': subdomain,
        'propertyId': _isEditing ? widget.property!.id : null,
      });

      if (mounted) {
        final data = result.data;
        setState(() {
          _isCheckingSubdomain = false;
          _isSubdomainAvailable = data['available'] as bool;
          _subdomainError = data['error'] as String?;
          _subdomainSuggestion = data['suggestion'] as String?;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _isCheckingSubdomain = false;
          _isSubdomainAvailable = false;
          _subdomainError = l10n.propertyFormCheckingError(
            e.toString().replaceFirst('Exception: ', ''),
          );
        });
      }
    }
  }

  /// Apply suggested subdomain
  void _applySuggestion() {
    if (_subdomainSuggestion != null) {
      setState(() {
        _subdomainController.text = _subdomainSuggestion!;
        _isManualSubdomainEdit = true;
      });
      _checkSubdomainAvailability(_subdomainSuggestion!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final l10n = AppLocalizations.of(context);

    return KeyedSubtree(
      key: ValueKey('property_form_$keyboardFixRebuildKey'),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: CommonAppBar(
          title: _isEditing
              ? l10n.propertyFormTitleEdit
              : l10n.propertyFormTitleAdd,
          leadingIcon: Icons.arrow_back,
          onLeadingIconTap: (context) => Navigator.of(context).pop(),
        ),
        body: Container(
          // Page background gradient (topLeft → bottomRight)
          decoration: BoxDecoration(gradient: context.gradients.pageBackground),
          child: Stack(
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
                      title: l10n.propertyFormBasicInfo,
                      icon: Icons.info_outline,
                      children: [
                        // Property Name + URL Slug - Responsive layout
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isVerySmall = constraints.maxWidth < 500;

                            if (isVerySmall) {
                              // Column layout for small screens
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Property Name
                                  TextFormField(
                                    controller: _nameController,
                                    decoration:
                                        InputDecorationHelper.buildDecoration(
                                          labelText:
                                              l10n.propertyFormPropertyName,
                                          hintText:
                                              l10n.propertyFormPropertyNameHint,
                                          isMobile: isMobile,
                                          context: context,
                                        ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return l10n
                                            .propertyFormPropertyNameRequired;
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      _autoGenerateSlug();
                                      _autoGenerateSubdomain();
                                    },
                                  ),
                                  const SizedBox(height: AppDimensions.spaceM),
                                  // URL Slug
                                  TextFormField(
                                    controller: _slugController,
                                    decoration:
                                        InputDecorationHelper.buildDecoration(
                                          labelText: l10n.propertyFormUrlSlug,
                                          hintText:
                                              l10n.propertyFormUrlSlugHint,
                                          helperText:
                                              l10n.propertyFormUrlSlugHelper,
                                          isMobile: isMobile,
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.refresh),
                                            tooltip:
                                                l10n.propertyFormRegenerateSlug,
                                            onPressed: () {
                                              setState(() {
                                                _isManualSlugEdit = false;
                                                _autoGenerateSlug();
                                              });
                                            },
                                          ),
                                          context: context,
                                        ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return l10n.propertyFormSlugRequired;
                                      }
                                      if (!isValidSlug(value)) {
                                        return l10n.propertyFormSlugInvalid;
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        setState(
                                          () => _isManualSlugEdit = true,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              );
                            }

                            // Row layout for larger screens
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Property Name
                                Expanded(
                                  child: TextFormField(
                                    controller: _nameController,
                                    decoration:
                                        InputDecorationHelper.buildDecoration(
                                          labelText:
                                              l10n.propertyFormPropertyName,
                                          hintText:
                                              l10n.propertyFormPropertyNameHint,
                                          isMobile: isMobile,
                                          context: context,
                                        ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return l10n
                                            .propertyFormPropertyNameRequired;
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      _autoGenerateSlug();
                                      _autoGenerateSubdomain();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // URL Slug
                                Expanded(
                                  child: TextFormField(
                                    controller: _slugController,
                                    decoration:
                                        InputDecorationHelper.buildDecoration(
                                          labelText: l10n.propertyFormUrlSlug,
                                          hintText:
                                              l10n.propertyFormUrlSlugHint,
                                          helperText:
                                              l10n.propertyFormUrlSlugHelper,
                                          isMobile: isMobile,
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.refresh),
                                            tooltip:
                                                l10n.propertyFormRegenerateSlug,
                                            onPressed: () {
                                              setState(() {
                                                _isManualSlugEdit = false;
                                                _autoGenerateSlug();
                                              });
                                            },
                                          ),
                                          context: context,
                                        ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return l10n.propertyFormSlugRequired;
                                      }
                                      if (!isValidSlug(value)) {
                                        return l10n.propertyFormSlugInvalid;
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        setState(
                                          () => _isManualSlugEdit = true,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppDimensions.spaceM),
                        // Subdomain field (full width)
                        _buildSubdomainField(isMobile),
                        const SizedBox(height: AppDimensions.spaceM),
                        // Property Type
                        DropdownButtonFormField<PropertyType>(
                          initialValue: _selectedType,
                          dropdownColor: InputDecorationHelper.getDropdownColor(
                            context,
                          ),
                          borderRadius:
                              InputDecorationHelper.dropdownBorderRadius,
                          decoration: InputDecorationHelper.buildDecoration(
                            labelText: l10n.propertyFormPropertyType,
                            isMobile: isMobile,
                            context: context,
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
                            labelText: l10n.propertyFormDescription,
                            hintText: l10n.propertyFormDescriptionHint,
                            isMobile: isMobile,
                            context: context,
                          ),
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.propertyFormDescriptionRequired;
                            }
                            if (value.length < 100) {
                              return l10n.propertyFormDescriptionTooShort(
                                value.length,
                              );
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
                      title: l10n.propertyFormLocation,
                      icon: Icons.location_on,
                      children: [
                        // Location + Address - Responsive layout
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isVerySmall = constraints.maxWidth < 500;

                            if (isVerySmall) {
                              // Column layout for small screens
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _locationController,
                                    decoration:
                                        InputDecorationHelper.buildDecoration(
                                          labelText:
                                              l10n.propertyFormLocationLabel,
                                          hintText:
                                              l10n.propertyFormLocationHint,
                                          prefixIcon: const Icon(
                                            Icons.location_on,
                                          ),
                                          isMobile: isMobile,
                                          context: context,
                                        ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return l10n
                                            .propertyFormLocationRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppDimensions.spaceM),
                                  TextFormField(
                                    controller: _addressController,
                                    decoration:
                                        InputDecorationHelper.buildDecoration(
                                          labelText: l10n.propertyFormAddress,
                                          hintText:
                                              l10n.propertyFormAddressHint,
                                          prefixIcon: const Icon(Icons.home),
                                          isMobile: isMobile,
                                          context: context,
                                        ),
                                  ),
                                ],
                              );
                            }

                            // Row layout for larger screens
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _locationController,
                                    decoration:
                                        InputDecorationHelper.buildDecoration(
                                          labelText:
                                              l10n.propertyFormLocationLabel,
                                          hintText:
                                              l10n.propertyFormLocationHint,
                                          prefixIcon: const Icon(
                                            Icons.location_on,
                                          ),
                                          isMobile: isMobile,
                                          context: context,
                                        ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return l10n
                                            .propertyFormLocationRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _addressController,
                                    decoration:
                                        InputDecorationHelper.buildDecoration(
                                          labelText: l10n.propertyFormAddress,
                                          hintText:
                                              l10n.propertyFormAddressHint,
                                          prefixIcon: const Icon(Icons.home),
                                          isMobile: isMobile,
                                          context: context,
                                        ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceL),

                    // Amenities Section
                    _buildSection(
                      context,
                      title: l10n.propertyFormAmenities,
                      icon: Icons.local_offer,
                      children: [_buildAmenitiesGrid()],
                    ),
                    const SizedBox(height: AppDimensions.spaceL),

                    // Images Section
                    _buildSection(
                      context,
                      title: _isEditing
                          ? l10n.propertyFormPhotos
                          : l10n.propertyFormPhotosMin,
                      icon: Icons.photo_library,
                      children: [_buildImagesSection()],
                    ),
                    const SizedBox(height: AppDimensions.spaceL),

                    // Settings Section
                    _buildSection(
                      context,
                      title: l10n.propertyFormSettings,
                      icon: Icons.settings,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.propertyFormPublishNow),
                          subtitle: Text(
                            _isPublished
                                ? l10n.propertyFormPublishNowActive
                                : l10n.propertyFormPublishNowInactive,
                          ),
                          trailing: Switch(
                            value: _isPublished,
                            onChanged: (value) =>
                                setState(() => _isPublished = value),
                            activeThumbColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            activeTrackColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceL),

                    // Modern Gradient Save Button - uses brand gradient (GradientTokens.brandPrimary)
                    GradientButton(
                      text: _isEditing
                          ? l10n.propertyFormSaveChanges
                          : l10n.propertyFormAddProperty,
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
                                gradient: GradientTokens.brandPrimary,
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
                            Text(
                              l10n.propertyFormSaving,
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
          ),
        ),
      ),
    );
  }

  /// Helper: Build a section card with title and icon
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    String? subtitle,
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
            // Section cards: topRight → bottomLeft gradient
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
                // Section Header - Minimalist style
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
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 20),
                // Section Content
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build the subdomain input field with availability indicator
  Widget _buildSubdomainField(bool isMobile) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Determine suffix icon based on state
    Widget? suffixIcon;
    if (_isCheckingSubdomain) {
      suffixIcon = const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(2),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (_isSubdomainAvailable == true) {
      suffixIcon = Icon(Icons.check_circle, color: theme.colorScheme.primary);
    } else if (_isSubdomainAvailable == false) {
      suffixIcon = Icon(Icons.error, color: theme.colorScheme.error);
    } else {
      suffixIcon = IconButton(
        icon: const Icon(Icons.auto_fix_high),
        tooltip: l10n.propertyFormGenerateFromName,
        onPressed: () {
          setState(() => _isManualSubdomainEdit = false);
          _autoGenerateSubdomain();
        },
      );
    }

    // Build helper text with suggestion
    String? helperText = l10n.propertyFormSubdomainEmailHelper;
    if (_subdomainSuggestion != null && _isSubdomainAvailable == false) {
      helperText = null; // We'll show error + suggestion separately
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _subdomainController,
          decoration: InputDecorationHelper.buildDecoration(
            labelText: l10n.propertyFormSubdomainLabel,
            hintText: l10n.propertyFormSubdomainHint,
            helperText: helperText,
            isMobile: isMobile,
            suffixIcon: suffixIcon,
            prefixIcon: const Icon(Icons.link),
            context: context,
          ),
          onChanged: _onSubdomainChanged,
        ),
        // Show error and suggestion if subdomain is not available
        if (_subdomainError != null && !_isCheckingSubdomain) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _subdomainError!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_subdomainSuggestion != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        l10n.propertyFormSubdomainSuggestion,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      InkWell(
                        onTap: _applySuggestion,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _subdomainSuggestion!,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _applySuggestion,
                        icon: const Icon(Icons.check, size: 16),
                        label: Text(l10n.propertyFormUseSuggestion),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        // Show success message when available
        if (_isSubdomainAvailable == true &&
            !_isCheckingSubdomain &&
            _subdomainController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: theme.colorScheme.primary,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.propertyFormSubdomainAvailable,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAmenitiesGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PropertyAmenity.values.map((amenity) {
        final isSelected = _selectedAmenities.contains(amenity);
        return AppFilterChip(
          label: amenity.displayName,
          selected: isSelected,
          icon: _getAmenityIcon(amenity.iconName),
          onSelected: () {
            setState(() {
              // Force create new Set to trigger rebuild
              if (isSelected) {
                _selectedAmenities = Set.from(_selectedAmenities)
                  ..remove(amenity);
              } else {
                _selectedAmenities = {..._selectedAmenities, amenity};
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildImagesSection() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final totalImages = _existingImages.length + _selectedImages.length;

    // Build the images grid (combines existing and new images)
    Widget buildImagesGrid() {
      if (totalImages == 0) {
        return Center(
          child: Column(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.propertyFormNoPhotos,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Existing images
          ..._existingImages.asMap().entries.map((entry) {
            final index = entry.key;
            final imageUrl = entry.value;
            return _buildExistingImageCard(imageUrl, index);
          }),
          // New images
          ..._selectedImages.asMap().entries.map((entry) {
            final index = entry.key;
            final image = entry.value;
            return _buildNewImageCard(image, index);
          }),
        ],
      );
    }

    // Left controls widget
    Widget buildLeftControls() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add images button
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate, size: 20),
                label: Text(
                  totalImages == 0
                      ? l10n.propertyFormAddPhotos
                      : l10n.propertyFormAddMore,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Photo count
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.propertyFormPhotoCount(totalImages),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    if (isMobile) {
      // Mobile: Vertical layout
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLeftControls(),
          const SizedBox(height: 16),
          buildImagesGrid(),
        ],
      );
    }

    // Desktop: Horizontal layout - Left controls, Right images
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLeftControls(),
        const SizedBox(width: 24),
        Expanded(child: buildImagesGrid()),
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
            child: FutureBuilder<Uint8List>(
              future: image.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Icon(
                    Icons.broken_image,
                    size: 40,
                    color: theme.colorScheme.onSurface.withAlpha(
                      (0.3 * 255).toInt(),
                    ),
                  );
                }
                return Image.memory(
                  snapshot.data!,
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
      final l10nSnack = AppLocalizations.of(context);
      ErrorDisplayUtils.showWarningSnackBar(
        context,
        l10nSnack.propertyFormPhotoRecommendation,
      );
      // Continue with save (no return)
    }

    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuth.instance;
      final ownerId = auth.currentUser?.uid;

      if (ownerId == null) {
        final l10nAuth = AppLocalizations.of(context);
        throw AuthException(
          l10nAuth.propertyFormUserNotLoggedIn,
          code: 'auth/not-authenticated',
        );
      }

      final repository = ref.read(ownerPropertiesRepositoryProvider);

      // Upload new images to Firebase Storage
      final List<String> uploadedImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        try {
          final propertyId = _isEditing
              ? widget.property!.id
              : 'temp-${DateTime.now().millisecondsSinceEpoch}';

          for (int i = 0; i < _selectedImages.length; i++) {
            final image = _selectedImages[i];

            final bytes = await image.readAsBytes();

            final imageUrl = await repository.uploadPropertyImage(
              propertyId: propertyId,
              filePath: image.path,
              bytes: bytes,
            );

            uploadedImageUrls.add(imageUrl);

            if (mounted) {
              final l10nUpload = AppLocalizations.of(context);
              ErrorDisplayUtils.showInfoSnackBar(
                context,
                l10nUpload.propertyFormUploadProgress(
                  i + 1,
                  _selectedImages.length,
                ),
                duration: const Duration(milliseconds: 500),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            final l10nErr = AppLocalizations.of(context);
            ErrorDisplayUtils.showErrorSnackBar(
              context,
              e,
              userMessage: l10nErr.propertyFormUploadErrorGeneric,
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      final allImages = [..._existingImages, ...uploadedImageUrls];

      // Get subdomain value (only if available or empty string)
      final subdomainValue = _subdomainController.text.trim().isEmpty
          ? null
          : _subdomainController.text.trim().toLowerCase();

      // ========================================================================
      // SECURITY: Validate subdomain availability before save
      // ========================================================================
      if (subdomainValue != null && subdomainValue.isNotEmpty) {
        if (_isSubdomainAvailable != true) {
          if (mounted) {
            final l10nSub = AppLocalizations.of(context);
            ErrorDisplayUtils.showErrorSnackBar(
              context,
              Exception('Subdomain not available'),
              userMessage:
                  _subdomainError ?? l10nSub.propertyFormSubdomainError,
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      if (_isEditing) {
        // Check if subdomain changed and needs to be updated via Cloud Function
        final oldSubdomain = widget.property!.subdomain;
        final subdomainChanged = subdomainValue != oldSubdomain;

        if (subdomainChanged &&
            subdomainValue != null &&
            subdomainValue.isNotEmpty) {
          // Use Cloud Function for server-side validation
          try {
            final functions = FirebaseFunctions.instance;
            final callable = functions.httpsCallable('setPropertySubdomain');
            await callable.call<Map<String, dynamic>>({
              'propertyId': widget.property!.id,
              'subdomain': subdomainValue,
            });
          } catch (e) {
            if (mounted) {
              final l10nSubErr = AppLocalizations.of(context);
              ErrorDisplayUtils.showErrorSnackBar(
                context,
                e,
                userMessage: l10nSubErr.propertyFormSubdomainSetError,
              );
            }
            setState(() => _isLoading = false);
            return;
          }
        }

        // Update other fields (subdomain already updated by Cloud Function if changed)
        await repository.updateProperty(
          propertyId: widget.property!.id,
          name: _nameController.text,
          slug: _slugController.text,
          subdomain: subdomainChanged
              ? null
              : subdomainValue, // Skip if already set by Cloud Function
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
        // Create mode - subdomain validation already done above
        await repository.createProperty(
          ownerId: ownerId,
          name: _nameController.text,
          slug: _slugController.text,
          subdomain: subdomainValue,
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
        final l10nSuccess = AppLocalizations.of(context);
        Navigator.of(context).pop();
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          _isEditing
              ? l10nSuccess.propertyFormSuccessUpdate
              : l10nSuccess.propertyFormSuccessAdd,
        );
      }
    } catch (e) {
      if (mounted) {
        final l10nFail = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: _isEditing
              ? l10nFail.propertyFormErrorUpdate
              : l10nFail.propertyFormErrorAdd,
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
    'local_parking' => Icons.local_parking,
    'pool' => Icons.pool,
    'ac_unit' => Icons.ac_unit,
    'whatshot' => Icons.whatshot,
    'kitchen' => Icons.kitchen,
    'local_laundry_service' => Icons.local_laundry_service,
    'tv' => Icons.tv,
    'balcony' => Icons.balcony,
    'beach_access' => Icons.beach_access,
    'pets' => Icons.pets,
    'outdoor_grill' => Icons.outdoor_grill,
    'deck' => Icons.deck,
    'fireplace' => Icons.fireplace,
    'fitness_center' => Icons.fitness_center,
    'hot_tub' => Icons.hot_tub,
    'spa' => Icons.spa,
    'pedal_bike' => Icons.pedal_bike,
    'sailing' => Icons.sailing,
    _ => Icons.check,
  };
}
