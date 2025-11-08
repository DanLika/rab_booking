import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/enums.dart';
import '../../domain/models/onboarding_state.dart';
import '../providers/onboarding_provider.dart';

/// Step 1: Property Information (REQUIRED)
class OnboardingPropertyStep extends ConsumerStatefulWidget {
  const OnboardingPropertyStep({super.key});

  @override
  ConsumerState<OnboardingPropertyStep> createState() => _OnboardingPropertyStepState();
}

class _OnboardingPropertyStepState extends ConsumerState<OnboardingPropertyStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  PropertyType? _selectedType;

  @override
  void initState() {
    super.initState();
    // Load existing data if available
    final propertyData = ref.read(onboardingNotifierProvider).propertyData;
    if (propertyData != null) {
      _nameController.text = propertyData.name;
      _addressController.text = propertyData.address;
      _cityController.text = propertyData.city;
      _countryController.text = propertyData.country;
      _phoneController.text = propertyData.phone ?? '';
      _emailController.text = propertyData.email ?? '';
      _websiteController.text = propertyData.website ?? '';
      _selectedType = PropertyType.values.firstWhere(
        (e) => e.name == propertyData.propertyType,
        orElse: () => PropertyType.apartment,
      );
    } else {
      _countryController.text = 'Hrvatska'; // Default
    }

    // Listen to field changes and auto-save
    _nameController.addListener(_saveData);
    _addressController.addListener(_saveData);
    _cityController.addListener(_saveData);
    _countryController.addListener(_saveData);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _saveData() {
    if (_formKey.currentState?.validate() ?? false) {
      final data = PropertyFormData(
        name: _nameController.text.trim(),
        propertyType: _selectedType?.name ?? PropertyType.apartment.name,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      );

      ref.read(onboardingNotifierProvider.notifier).savePropertyData(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Osnovni podaci o objektu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unesite osnovne informacije o vašem smještaju',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),

            // Property Name (REQUIRED)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Naziv objekta *',
                hintText: 'npr. Villa Jasko',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Obavezno polje';
                }
                return null;
              },
              onChanged: (_) => _saveData(),
            ),
            const SizedBox(height: 20),

            // Property Type (REQUIRED)
            DropdownButtonFormField<PropertyType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tip smještaja *',
                border: OutlineInputBorder(),
              ),
              items: PropertyType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getPropertyTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value);
                _saveData();
              },
              validator: (value) {
                if (value == null) {
                  return 'Obavezno polje';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Address (REQUIRED)
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresa *',
                hintText: 'Ulica i broj',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Obavezno polje';
                }
                return null;
              },
              onChanged: (_) => _saveData(),
            ),
            const SizedBox(height: 20),

            // City and Country
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Grad *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Obavezno';
                      }
                      return null;
                    },
                    onChanged: (_) => _saveData(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: 'Država *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Obavezno';
                      }
                      return null;
                    },
                    onChanged: (_) => _saveData(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Optional Fields Section
            Text(
              'Dodatne informacije (opciono)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                hintText: '+385 xx xxx xxxx',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (_) => _saveData(),
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'info@example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => _saveData(),
            ),
            const SizedBox(height: 16),

            // Website
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => _saveData(),
            ),
          ],
        ),
      ),
    );
  }

  String _getPropertyTypeLabel(PropertyType type) {
    switch (type) {
      case PropertyType.villa:
        return 'Villa';
      case PropertyType.apartment:
        return 'Apartman';
      case PropertyType.studio:
        return 'Studio';
      case PropertyType.house:
        return 'Kuća';
      case PropertyType.room:
        return 'Soba';
    }
  }
}
