import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/enums.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../providers/owner_properties_provider.dart';
import '../../../../core/theme/app_colors.dart';

/// Property form screen for add/edit
class PropertyFormScreen extends ConsumerStatefulWidget {
  const PropertyFormScreen({this.property, super.key});

  final PropertyModel? property;

  @override
  ConsumerState<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends ConsumerState<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();

  PropertyType _selectedType = PropertyType.apartment;
  Set<PropertyAmenity> _selectedAmenities = {};
  final List<XFile> _selectedImages = [];
  List<String> _existingImages = [];
  bool _isPublished = false;
  bool _isLoading = false;

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
    _descriptionController.text = property.description;
    _selectedType = property.propertyType;
    _locationController.text = property.location;
    _addressController.text = property.address ?? '';
    _selectedAmenities = property.amenities.toSet();
    _existingImages = property.images.toList();
    _isPublished = property.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Uredi Nekretninu' : 'Dodaj Nekretninu'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Property Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Naziv nekretnine *',
                hintText: 'npr. Villa Mediteran',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Naziv je obavezan';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Property Type
            DropdownButtonFormField<PropertyType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tip nekretnine *',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Opis *',
                hintText: 'Detaljno opišite vašu nekretninu...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
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
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Lokacija *',
                hintText: 'npr. Rab (grad), Otok Rab',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lokacija je obavezna';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresa',
                hintText: 'Ulica i broj',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
            ),
            const SizedBox(height: 24),

            // Amenities section
            Text(
              'Sadržaji',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildAmenitiesGrid(),
            const SizedBox(height: 24),

            // Images section
            Text(
              'Fotografije ${_isEditing ? '' : '(min 3)'}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildImagesSection(),
            const SizedBox(height: 24),

            // Published toggle
            SwitchListTile(
              title: const Text('Objavi odmah'),
              subtitle: Text(
                _isPublished
                    ? 'Nekretnina će biti vidljiva korisnicima'
                    : 'Nekretnina će biti skrivena',
              ),
              value: _isPublished,
              onChanged: (value) => setState(() => _isPublished = value),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton(
              onPressed: _isLoading ? null : _handleSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Spremi Izmjene' : 'Dodaj Nekretninu'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PropertyAmenity.values.map((amenity) {
        final isSelected = _selectedAmenities.contains(amenity);
        return FilterChip(
          label: Text(
            amenity.displayName,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[800],
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
            color: isSelected ? Colors.white : Colors.grey[700],
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
            totalImages == 0 ? 'Dodaj fotografije (min 3)' : 'Dodaj još fotografija',
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),

        if (totalImages > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Ukupno: $totalImages fotografija',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildExistingImageCard(String imageUrl, int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.surfaceVariantLight,
                  child: const Icon(Icons.broken_image),
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
              backgroundColor: AppColors.error,
              padding: EdgeInsets.zero,
              minimumSize: const Size(24, 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewImageCard(XFile image, int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
            color: AppColors.surfaceVariantLight,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(image.path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, size: 40);
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
              backgroundColor: AppColors.error,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Morate dodati najmanje 3 fotografije'),
        ),
      );
      return;
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
      List<String> uploadedImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        try {
          // Generate temporary property ID for new properties
          final propertyId = _isEditing
              ? widget.property!.id
              : 'temp-${DateTime.now().millisecondsSinceEpoch}';

          // Upload images one by one
          for (int i = 0; i < _selectedImages.length; i++) {
            final image = _selectedImages[i];
            final bytes = await image.readAsBytes();

            final imageUrl = await repository.uploadPropertyImage(
              propertyId: propertyId,
              filePath: image.path,
              bytes: bytes,
            );

            uploadedImageUrls.add(imageUrl);

            // Show upload progress
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Uploading images: ${i + 1}/${_selectedImages.length}'),
                  duration: const Duration(milliseconds: 500),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Greška pri upload-u slika: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      final allImages = [..._existingImages, ...uploadedImageUrls];

      if (_isEditing) {
        // Update existing property
        await repository.updateProperty(
          propertyId: widget.property!.id,
          name: _nameController.text,
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
        // Create new property
        await repository.createProperty(
          ownerId: ownerId,
          name: _nameController.text,
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

      // Refresh properties list
      ref.invalidate(ownerPropertiesProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Nekretnina uspješno ažurirana'
                  : 'Nekretnina uspješno dodana',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: $e')),
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
