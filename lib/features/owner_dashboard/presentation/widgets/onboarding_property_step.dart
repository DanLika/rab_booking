import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../domain/models/onboarding_state.dart';
import '../providers/onboarding_provider.dart';

/// Step 1: Property Information (REQUIRED)
class OnboardingPropertyStep extends ConsumerStatefulWidget {
  const OnboardingPropertyStep({super.key});

  @override
  ConsumerState<OnboardingPropertyStep> createState() =>
      _OnboardingPropertyStepState();
}

class _OnboardingPropertyStepState
    extends ConsumerState<OnboardingPropertyStep> {
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
        orElse: () => PropertyType.villa,
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
        propertyType: _selectedType?.name ?? PropertyType.villa.name,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
      );

      ref.read(onboardingNotifierProvider.notifier).savePropertyData(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.onboardingPropertyTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.onboardingPropertySubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Property Name (REQUIRED)
            TextFormField(
              controller: _nameController,
              decoration: InputDecorationHelper.buildDecoration(
                labelText: l10n.onboardingPropertyName,
                hintText: l10n.onboardingPropertyNameHint,
                context: context,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.onboardingPropertyRequired;
                }
                return null;
              },
              onChanged: (_) => _saveData(),
            ),
            const SizedBox(height: 20),

            // Property Type (REQUIRED)
            DropdownButtonFormField<PropertyType>(
              initialValue: _selectedType,
              dropdownColor: InputDecorationHelper.getDropdownColor(context),
              borderRadius: InputDecorationHelper.dropdownBorderRadius,
              decoration: InputDecorationHelper.buildDecoration(
                labelText: l10n.onboardingPropertyType,
                context: context,
              ),
              items: PropertyType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getPropertyTypeLabel(type, l10n)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value);
                _saveData();
              },
              validator: (value) {
                if (value == null) {
                  return l10n.onboardingPropertyRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Address (REQUIRED)
            TextFormField(
              controller: _addressController,
              decoration: InputDecorationHelper.buildDecoration(
                labelText: l10n.onboardingPropertyAddress,
                hintText: l10n.onboardingPropertyAddressHint,
                context: context,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.onboardingPropertyRequired;
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
                    decoration: InputDecorationHelper.buildDecoration(
                      labelText: l10n.onboardingPropertyCity,
                      context: context,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.onboardingPropertyRequiredShort;
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
                    decoration: InputDecorationHelper.buildDecoration(
                      labelText: l10n.onboardingPropertyCountry,
                      context: context,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.onboardingPropertyRequiredShort;
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
              l10n.onboardingPropertyOptional,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: InputDecorationHelper.buildDecoration(
                labelText: l10n.onboardingPropertyPhone,
                hintText: l10n.onboardingPropertyPhoneHint,
                prefixIcon: const Icon(Icons.phone),
                context: context,
              ),
              keyboardType: TextInputType.phone,
              onChanged: (_) => _saveData(),
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: InputDecorationHelper.buildDecoration(
                labelText: l10n.onboardingPropertyEmail,
                hintText: l10n.onboardingPropertyEmailHint,
                prefixIcon: const Icon(Icons.email),
                context: context,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => _saveData(),
            ),
            const SizedBox(height: 16),

            // Website
            TextFormField(
              controller: _websiteController,
              decoration: InputDecorationHelper.buildDecoration(
                labelText: l10n.onboardingPropertyWebsite,
                hintText: l10n.onboardingPropertyWebsiteHint,
                prefixIcon: const Icon(Icons.language),
                context: context,
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => _saveData(),
            ),
          ],
        ),
      ),
    );
  }

  String _getPropertyTypeLabel(PropertyType type, AppLocalizations l10n) =>
      switch (type) {
        PropertyType.villa => l10n.onboardingPropertyTypeVilla,
        PropertyType.house => l10n.onboardingPropertyTypeHouse,
        PropertyType.other => l10n.onboardingPropertyTypeOther,
      };
}
