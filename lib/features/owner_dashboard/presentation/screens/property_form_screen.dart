import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/design_tokens/gradient_tokens.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/slug_utils.dart';
import '../../../../core/utils/input_decoration_helper.dart';
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
    _isManualSubdomainEdit = property.subdomain != null && property.subdomain!.isNotEmpty;

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
        setState(() {
          _isCheckingSubdomain = false;
          _subdomainError = 'Greška pri generiranju: ${e.toString().replaceFirst('Exception: ', '')}';
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
        setState(() {
          _isCheckingSubdomain = false;
          _isSubdomainAvailable = false;
          _subdomainError = 'Greška pri provjeri: ${e.toString().replaceFirst('Exception: ', '')}';
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CommonAppBar(
        title: _isEditing ? 'Uredi Nekretninu' : 'Dodaj Nekretninu',
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      body: Container(
        // Page background gradient (topLeft → bottomRight)
        decoration: BoxDecoration(
          gradient: context.gradients.pageBackground,
        ),
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
                  title: 'Osnovne Informacije',
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
                                decoration: InputDecorationHelper.buildDecoration(
                                  labelText: 'Naziv nekretnine *',
                                  hintText: 'npr. Villa Mediteran',
                                  isMobile: isMobile,
                                  context: context,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Naziv je obavezan';
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
                                decoration: InputDecorationHelper.buildDecoration(
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
                                  context: context,
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
                              // Subdomain
                              _buildSubdomainField(isMobile),
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
                                decoration: InputDecorationHelper.buildDecoration(
                                  labelText: 'Naziv nekretnine *',
                                  hintText: 'npr. Villa Mediteran',
                                  isMobile: isMobile,
                                  context: context,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Naziv je obavezan';
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
                                decoration: InputDecorationHelper.buildDecoration(
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
                                  context: context,
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
                      decoration: InputDecorationHelper.buildDecoration(
                        labelText: 'Tip nekretnine *',
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
                        labelText: 'Opis *',
                        hintText: 'Detaljno opišite vašu nekretninu...',
                        isMobile: isMobile,
                        context: context,
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
                                decoration: InputDecorationHelper.buildDecoration(
                                  labelText: 'Lokacija *',
                                  hintText: 'npr. Rab (grad), Otok Rab',
                                  prefixIcon: const Icon(Icons.location_on),
                                  isMobile: isMobile,
                                  context: context,
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
                                  labelText: 'Adresa',
                                  hintText: 'Ulica i broj',
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
                                decoration: InputDecorationHelper.buildDecoration(
                                  labelText: 'Lokacija *',
                                  hintText: 'npr. Rab (grad), Otok Rab',
                                  prefixIcon: const Icon(Icons.location_on),
                                  isMobile: isMobile,
                                  context: context,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Lokacija je obavezna';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _addressController,
                                decoration: InputDecorationHelper.buildDecoration(
                                  labelText: 'Adresa',
                                  hintText: 'Ulica i broj',
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
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Objavi odmah'),
                      subtitle: Text(
                        _isPublished
                            ? 'Nekretnina će biti vidljiva korisnicima'
                            : 'Nekretnina će biti skrivena',
                      ),
                      trailing: Switch(
                        value: _isPublished,
                        onChanged: (value) =>
                            setState(() => _isPublished = value),
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                        activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceL),

                // Modern Gradient Save Button - uses brand gradient (GradientTokens.brandPrimary)
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
            gradient: context.gradients.sectionBackground,
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
        tooltip: 'Generiši iz naziva',
        onPressed: () {
          setState(() => _isManualSubdomainEdit = false);
          _autoGenerateSubdomain();
        },
      );
    }

    // Build helper text with suggestion
    String? helperText = 'URL za email linkove: {subdomain}.rabbooking.com';
    if (_subdomainSuggestion != null && _isSubdomainAvailable == false) {
      helperText = null; // We'll show error + suggestion separately
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _subdomainController,
          decoration: InputDecorationHelper.buildDecoration(
            labelText: 'Subdomena (za email linkove)',
            hintText: 'npr. villa-mediteran',
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
                        'Predlog: ',
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
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                        label: const Text('Koristi'),
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
        if (_isSubdomainAvailable == true && !_isCheckingSubdomain && _subdomainController.text.isNotEmpty) ...[
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
                'Subdomena je dostupna',
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
            debugPrint('🎯 [AMENITY] Chip tapped: ${amenity.displayName}');
            debugPrint('📊 [AMENITY] Selected: $selected (was: $isSelected)');
            debugPrint(
              '📋 [AMENITY] Current set (${_selectedAmenities.length} items): ${_selectedAmenities.map((a) => a.displayName).join(", ")}',
            );

            setState(() {
              // Force create new Set to trigger rebuild
              if (selected) {
                _selectedAmenities = {..._selectedAmenities, amenity};
                debugPrint('✅ [AMENITY] Added ${amenity.displayName}');
              } else {
                _selectedAmenities = Set.from(_selectedAmenities)
                  ..remove(amenity);
                debugPrint('❌ [AMENITY] Removed ${amenity.displayName}');
              }
              debugPrint(
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
          ElevatedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate, size: 20),
            label: Text(
              totalImages == 0 ? 'Dodaj Fotografije' : 'Dodaj Još',
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
              '$totalImages fotografija',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
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
        debugPrint(
          '🔍 [UPLOAD] Starting upload for ${_selectedImages.length} images',
        );

        try {
          final propertyId = _isEditing
              ? widget.property!.id
              : 'temp-${DateTime.now().millisecondsSinceEpoch}';

          debugPrint('📦 [UPLOAD] PropertyId: $propertyId');

          for (int i = 0; i < _selectedImages.length; i++) {
            final image = _selectedImages[i];
            debugPrint(
              '📸 [UPLOAD] Image ${i + 1}/${_selectedImages.length} - Path: ${image.path}',
            );

            final bytes = await image.readAsBytes();
            debugPrint('✅ [UPLOAD] Read ${bytes.length} bytes');

            debugPrint('☁️ [UPLOAD] Calling uploadPropertyImage...');
            final imageUrl = await repository.uploadPropertyImage(
              propertyId: propertyId,
              filePath: image.path,
              bytes: bytes,
            );
            debugPrint('✅ [UPLOAD] Success! URL: $imageUrl');

            uploadedImageUrls.add(imageUrl);

            if (mounted) {
              ErrorDisplayUtils.showInfoSnackBar(
                context,
                'Upload fotografija: ${i + 1}/${_selectedImages.length}',
                duration: const Duration(milliseconds: 500),
              );
            }
          }

          debugPrint('🎉 [UPLOAD] All images uploaded successfully!');
        } catch (e, stackTrace) {
          debugPrint('❌ [UPLOAD ERROR] $e');
          debugPrint('📚 [STACK TRACE] $stackTrace');

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
                    debugPrint('💥 [FULL ERROR] $e\n$stackTrace');
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

      // Get subdomain value (only if available or empty string)
      final subdomainValue = _subdomainController.text.trim().isEmpty
          ? null
          : _subdomainController.text.trim().toLowerCase();

      if (_isEditing) {
        await repository.updateProperty(
          propertyId: widget.property!.id,
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
      } else {
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
