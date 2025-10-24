import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/unit.dart';
import '../providers/units_provider.dart';

class AddEditUnitScreen extends ConsumerStatefulWidget {
  final String propertyId;
  final String? unitId; // null = Add, not null = Edit

  const AddEditUnitScreen({
    super.key,
    required this.propertyId,
    this.unitId,
  });

  @override
  ConsumerState<AddEditUnitScreen> createState() => _AddEditUnitScreenState();
}

class _AddEditUnitScreenState extends ConsumerState<AddEditUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _maxGuestsController = TextEditingController(text: '2');
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaSqmController = TextEditingController();
  final _minStayNightsController = TextEditingController(text: '1');

  bool _isLoading = false;
  Unit? _existingUnit;

  // Amenities
  final Map<String, bool> _amenities = {
    'wifi': false,
    'parking': false,
    'air_conditioning': false,
    'heating': false,
    'kitchen': false,
    'tv': false,
    'washing_machine': false,
    'balcony': false,
    'sea_view': false,
    'pets_allowed': false,
  };

  @override
  void initState() {
    super.initState();
    if (widget.unitId != null) {
      _loadExistingUnit();
    }
  }

  Future<void> _loadExistingUnit() async {
    setState(() => _isLoading = true);

    try {
      final unit = await ref
          .read(unitsRepositoryProvider)
          .getUnitById(widget.unitId!);

      if (unit != null && mounted) {
        setState(() {
          _existingUnit = unit;
          _nameController.text = unit.name;
          _descriptionController.text = unit.description ?? '';
          _basePriceController.text = unit.basePrice.toString();
          _maxGuestsController.text = unit.maxGuests.toString();
          _bedroomsController.text = unit.bedrooms?.toString() ?? '';
          _bathroomsController.text = unit.bathrooms?.toString() ?? '';
          _areaSqmController.text = unit.areaSqm?.toString() ?? '';
          _minStayNightsController.text = unit.minStayNights?.toString() ?? '1';

          // Load amenities
          for (var amenity in unit.amenities) {
            if (_amenities.containsKey(amenity)) {
              _amenities[amenity] = true;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri učitavanju: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _maxGuestsController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaSqmController.dispose();
    _minStayNightsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.unitId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Uredi jedinicu' : 'Dodaj jedinicu'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Naziv
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Naziv jedinice *',
                        hintText: 'npr. Apartman 1, Studio 2',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Unesite naziv jedinice';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Opis
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Opis',
                        hintText: 'Kratki opis smještaja...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    // Base Price
                    TextFormField(
                      controller: _basePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Osnovna cijena (€/noć) *',
                        hintText: '50',
                        border: OutlineInputBorder(),
                        suffixText: '€',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Unesite cijenu';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Unesite validnu cijenu';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Kapacitet Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _maxGuestsController,
                            decoration: const InputDecoration(
                              labelText: 'Max gostiju *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Obavezno';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _bedroomsController,
                            decoration: const InputDecoration(
                              labelText: 'Spavaće sobe',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Bathrooms & Area Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _bathroomsController,
                            decoration: const InputDecoration(
                              labelText: 'Kupatila',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _areaSqmController,
                            decoration: const InputDecoration(
                              labelText: 'Površina (m²)',
                              border: OutlineInputBorder(),
                              suffixText: 'm²',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Min stay nights
                    TextFormField(
                      controller: _minStayNightsController,
                      decoration: const InputDecoration(
                        labelText: 'Minimalan broj noćenja',
                        border: OutlineInputBorder(),
                        suffixText: 'noći',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Amenities Section
                    Text(
                      'Sadržaji',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildAmenitiesGrid(),

                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveUnit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isEdit ? 'Sačuvaj izmjene' : 'Kreiraj jedinicu',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAmenitiesGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _amenities.keys.map((key) {
        return FilterChip(
          label: Text(_getAmenityLabel(key)),
          selected: _amenities[key]!,
          onSelected: (selected) {
            setState(() {
              _amenities[key] = selected;
            });
          },
        );
      }).toList(),
    );
  }

  String _getAmenityLabel(String key) {
    const labels = {
      'wifi': 'WiFi',
      'parking': 'Parking',
      'air_conditioning': 'Klima',
      'heating': 'Grijanje',
      'kitchen': 'Kuhinja',
      'tv': 'TV',
      'washing_machine': 'Mašina za pranje',
      'balcony': 'Balkon',
      'sea_view': 'Pogled na more',
      'pets_allowed': 'Kućni ljubimci dozvoljeni',
    };
    return labels[key] ?? key;
  }

  Future<void> _saveUnit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedAmenities = _amenities.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      if (widget.unitId == null) {
        // Create new unit
        final newUnit = Unit(
          id: '', // Will be generated by Supabase
          propertyId: widget.propertyId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          basePrice: double.parse(_basePriceController.text),
          maxGuests: int.parse(_maxGuestsController.text),
          bedrooms: _bedroomsController.text.isEmpty
              ? null
              : int.parse(_bedroomsController.text),
          bathrooms: _bathroomsController.text.isEmpty
              ? null
              : int.parse(_bathroomsController.text),
          areaSqm: _areaSqmController.text.isEmpty
              ? null
              : double.parse(_areaSqmController.text),
          amenities: selectedAmenities,
          minStayNights: _minStayNightsController.text.isEmpty
              ? null
              : int.parse(_minStayNightsController.text),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await ref
            .read(unitsNotifierProvider(widget.propertyId).notifier)
            .createUnit(newUnit);
      } else {
        // Update existing unit
        final updates = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'base_price': double.parse(_basePriceController.text),
          'max_guests': int.parse(_maxGuestsController.text),
          'bedrooms': _bedroomsController.text.isEmpty
              ? null
              : int.parse(_bedroomsController.text),
          'bathrooms': _bathroomsController.text.isEmpty
              ? null
              : int.parse(_bathroomsController.text),
          'area_sqm': _areaSqmController.text.isEmpty
              ? null
              : double.parse(_areaSqmController.text),
          'amenities': selectedAmenities,
          'min_stay_nights': _minStayNightsController.text.isEmpty
              ? null
              : int.parse(_minStayNightsController.text),
        };

        await ref
            .read(unitsNotifierProvider(widget.propertyId).notifier)
            .updateUnit(widget.unitId!, updates);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.unitId == null
                  ? 'Jedinica kreirana uspješno!'
                  : 'Jedinica ažurirana uspješno!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
