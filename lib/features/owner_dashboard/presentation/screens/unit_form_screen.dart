import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';

/// Unit form screen for add/edit
class UnitFormScreen extends ConsumerStatefulWidget {
  const UnitFormScreen({
    required this.propertyId,
    this.unit,
    super.key,
  });

  final String propertyId;
  final UnitModel? unit;

  @override
  ConsumerState<UnitFormScreen> createState() => _UnitFormScreenState();
}

class _UnitFormScreenState extends ConsumerState<UnitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _bedroomsController = TextEditingController(text: '1');
  final _bathroomsController = TextEditingController(text: '1');
  final _maxGuestsController = TextEditingController(text: '2');
  final _areaController = TextEditingController();
  final _minStayController = TextEditingController(text: '1');

  Set<PropertyAmenity> _selectedAmenities = {};
  final List<XFile> _selectedImages = [];
  List<String> _existingImages = [];
  bool _isAvailable = true;
  bool _isLoading = false;

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
    _descriptionController.text = unit.description ?? '';
    _priceController.text = unit.pricePerNight.toStringAsFixed(0);
    _bedroomsController.text = unit.bedrooms.toString();
    _bathroomsController.text = unit.bathrooms.toString();
    _maxGuestsController.text = unit.maxGuests.toString();
    _areaController.text = unit.areaSqm?.toStringAsFixed(0) ?? '';
    _minStayController.text = unit.minStayNights.toString();
    _existingImages = unit.images.toList();
    _isAvailable = unit.isAvailable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _maxGuestsController.dispose();
    _areaController.dispose();
    _minStayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Uredi Jedinicu' : 'Dodaj Jedinicu'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Unit Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Naziv jedinice *',
                hintText: 'npr. Apartman prizemlje',
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

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Opis',
                hintText: 'Dodatne informacije o jedinici...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Capacity section
            Text(
              'Kapacitet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            // Bedrooms
            TextFormField(
              controller: _bedroomsController,
              decoration: const InputDecoration(
                labelText: 'Spavaće sobe *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bed),
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
            const SizedBox(height: 12),

            // Bathrooms
            TextFormField(
              controller: _bathroomsController,
              decoration: const InputDecoration(
                labelText: 'Kupaonice *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bathroom),
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
            const SizedBox(height: 12),
            // Max guests
            TextFormField(
              controller: _maxGuestsController,
              decoration: const InputDecoration(
                labelText: 'Max gostiju *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
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
            const SizedBox(height: 12),

            // Area
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'Površina (m²)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.aspect_ratio),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24),

            // Pricing section
            Text(
              'Cijena i uvjeti',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            // Price
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Cijena po noći (€) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro),
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
            const SizedBox(height: 12),

            // Min nights
            TextFormField(
              controller: _minStayController,
              decoration: const InputDecoration(
                labelText: 'Min noći *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.nights_stay),
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
              'Fotografije',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildImagesSection(),
            const SizedBox(height: 24),

            // Available toggle
            SwitchListTile(
              title: const Text('Dostupno za rezervaciju'),
              subtitle: Text(
                _isAvailable
                    ? 'Jedinica će biti dostupna za rezervacije'
                    : 'Jedinica neće biti prikazana',
              ),
              value: _isAvailable,
              onChanged: (value) => setState(() => _isAvailable = value),
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
                  : Text(_isEditing ? 'Spremi Izmjene' : 'Dodaj Jedinicu'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesGrid() {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Jedinica uspješno ažurirana'
                  : 'Jedinica uspješno dodana',
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
