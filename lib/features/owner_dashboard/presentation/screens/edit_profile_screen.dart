import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../providers/user_profile_provider.dart';

/// Edit Profile Screen with tabs: Location/Contact and Company Details
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;
  bool _isSaving = false;

  // Profile fields
  final _displayNameController = TextEditingController();
  final _emailContactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();
  final _propertyTypeController = TextEditingController();

  // Company fields
  final _companyNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _vatIdController = TextEditingController();
  final _ibanController = TextEditingController();
  final _swiftController = TextEditingController();
  final _companyCountryController = TextEditingController();
  final _companyCityController = TextEditingController();
  final _companyStreetController = TextEditingController();
  final _companyPostalCodeController = TextEditingController();

  UserProfile? _originalProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen for changes to mark form as dirty
    _displayNameController.addListener(_markDirty);
    _emailContactController.addListener(_markDirty);
    _phoneController.addListener(_markDirty);
    _countryController.addListener(_markDirty);
    _cityController.addListener(_markDirty);
    _streetController.addListener(_markDirty);
    _postalCodeController.addListener(_markDirty);
    _websiteController.addListener(_markDirty);
    _facebookController.addListener(_markDirty);
    _propertyTypeController.addListener(_markDirty);
    _companyNameController.addListener(_markDirty);
    _taxIdController.addListener(_markDirty);
    _vatIdController.addListener(_markDirty);
    _ibanController.addListener(_markDirty);
    _swiftController.addListener(_markDirty);
    _companyCountryController.addListener(_markDirty);
    _companyCityController.addListener(_markDirty);
    _companyStreetController.addListener(_markDirty);
    _companyPostalCodeController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _displayNameController.dispose();
    _emailContactController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _postalCodeController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _propertyTypeController.dispose();
    _companyNameController.dispose();
    _taxIdController.dispose();
    _vatIdController.dispose();
    _ibanController.dispose();
    _swiftController.dispose();
    _companyCountryController.dispose();
    _companyCityController.dispose();
    _companyStreetController.dispose();
    _companyPostalCodeController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  void _loadData(UserData userData) {
    if (_originalProfile != null) return; // Already loaded

    _originalProfile = userData.profile;

    final profile = userData.profile;
    final company = userData.company;

    // Profile fields
    _displayNameController.text = profile.displayName;
    _emailContactController.text = profile.emailContact;
    _phoneController.text = profile.phoneE164;
    _countryController.text = profile.address.country;
    _cityController.text = profile.address.city;
    _streetController.text = profile.address.street;
    _postalCodeController.text = profile.address.postalCode;
    _websiteController.text = profile.social.website;
    _facebookController.text = profile.social.facebook;
    _propertyTypeController.text = profile.propertyType;

    // Company fields
    _companyNameController.text = company.companyName;
    _taxIdController.text = company.taxId;
    _vatIdController.text = company.vatId;
    _ibanController.text = company.bankAccountIban;
    _swiftController.text = company.swift;
    _companyCountryController.text = company.address.country;
    _companyCityController.text = company.address.city;
    _companyStreetController.text = company.address.street;
    _companyPostalCodeController.text = company.address.postalCode;

    setState(() => _isDirty = false);
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content:
            const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      // Create updated profile
      final updatedProfile = UserProfile(
        userId: userId,
        displayName: _displayNameController.text.trim(),
        emailContact: _emailContactController.text.trim(),
        phoneE164: _phoneController.text.trim(),
        address: Address(
          country: _countryController.text.trim(),
          city: _cityController.text.trim(),
          street: _streetController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
        ),
        social: SocialLinks(
          website: _websiteController.text.trim(),
          facebook: _facebookController.text.trim(),
        ),
        propertyType: _propertyTypeController.text.trim(),
        logoUrl: _originalProfile?.logoUrl ?? '',
      );

      // Create updated company
      final updatedCompany = CompanyDetails(
        companyName: _companyNameController.text.trim(),
        taxId: _taxIdController.text.trim(),
        vatId: _vatIdController.text.trim(),
        bankAccountIban: _ibanController.text.trim(),
        swift: _swiftController.text.trim(),
        address: Address(
          country: _companyCountryController.text.trim(),
          city: _companyCityController.text.trim(),
          street: _companyStreetController.text.trim(),
          postalCode: _companyPostalCodeController.text.trim(),
        ),
      );

      // Save to Firestore
      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateProfile(updatedProfile);
      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateCompany(userId, updatedCompany);

      if (mounted) {
        setState(() {
          _isDirty = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(userDataProvider);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _isDirty) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Location & Contact'),
              Tab(text: 'Company Details'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isDirty && !_isSaving ? _saveProfile : null,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        color: _isDirty && !_isSaving
                            ? Colors.white
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: userDataAsync.when(
          data: (userData) {
            if (userData == null) {
              return const Center(child: Text('No profile data'));
            }

            _loadData(userData);

            return Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLocationContactTab(),
                  _buildCompanyTab(),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildLocationContactTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Personal Info Section
        Text(
          'Personal Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _displayNameController,
          decoration: const InputDecoration(
            labelText: 'Display Name *',
            hintText: 'Your name',
            border: OutlineInputBorder(),
          ),
          validator: ProfileValidators.validateName,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailContactController,
          decoration: const InputDecoration(
            labelText: 'Contact Email *',
            hintText: 'contact@example.com',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: ProfileValidators.validateEmail,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone',
            hintText: '+385911234567',
            border: OutlineInputBorder(),
            helperText: 'E.164 format (e.g., +385911234567)',
          ),
          keyboardType: TextInputType.phone,
          validator: ProfileValidators.validatePhone,
        ),
        const SizedBox(height: 24),

        // Address Section
        Text(
          'Address',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _countryController,
          decoration: const InputDecoration(
            labelText: 'Country',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              ProfileValidators.validateAddressField(v, 'Country'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _streetController,
          decoration: const InputDecoration(
            labelText: 'Street',
            border: OutlineInputBorder(),
          ),
          validator: (v) => ProfileValidators.validateAddressField(v, 'Street'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _postalCodeController,
                decoration: const InputDecoration(
                  labelText: 'Postal Code',
                  border: OutlineInputBorder(),
                ),
                validator: ProfileValidators.validatePostalCode,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    ProfileValidators.validateAddressField(v, 'City'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Social Section
        Text(
          'Social & Website',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _websiteController,
          decoration: const InputDecoration(
            labelText: 'Website',
            hintText: 'https://example.com',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          validator: ProfileValidators.validateWebsite,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _facebookController,
          decoration: const InputDecoration(
            labelText: 'Facebook Page',
            hintText: 'https://facebook.com/yourpage',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          validator: ProfileValidators.validateWebsite,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _propertyTypeController,
          decoration: const InputDecoration(
            labelText: 'Property Type',
            hintText: 'e.g., Apartment, Villa, Hotel',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCompanyTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Company Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _companyNameController,
          decoration: const InputDecoration(
            labelText: 'Company Name',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              ProfileValidators.validateAddressField(v, 'Company Name'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _taxIdController,
          decoration: const InputDecoration(
            labelText: 'Tax ID',
            border: OutlineInputBorder(),
          ),
          validator: ProfileValidators.validateTaxId,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _vatIdController,
          decoration: const InputDecoration(
            labelText: 'VAT ID',
            border: OutlineInputBorder(),
          ),
          validator: ProfileValidators.validateVatId,
        ),
        const SizedBox(height: 24),

        // Banking Section
        Text(
          'Banking Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _ibanController,
          decoration: const InputDecoration(
            labelText: 'IBAN',
            hintText: 'HR1234567890123456789',
            border: OutlineInputBorder(),
          ),
          validator: ProfileValidators.validateIban,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _swiftController,
          decoration: const InputDecoration(
            labelText: 'SWIFT/BIC',
            hintText: 'ZABAHR2X',
            border: OutlineInputBorder(),
          ),
          validator: ProfileValidators.validateSwift,
        ),
        const SizedBox(height: 24),

        // Company Address Section
        Text(
          'Company Address',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _companyCountryController,
          decoration: const InputDecoration(
            labelText: 'Country',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              ProfileValidators.validateAddressField(v, 'Country'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _companyStreetController,
          decoration: const InputDecoration(
            labelText: 'Street',
            border: OutlineInputBorder(),
          ),
          validator: (v) => ProfileValidators.validateAddressField(v, 'Street'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _companyPostalCodeController,
                decoration: const InputDecoration(
                  labelText: 'Postal Code',
                  border: OutlineInputBorder(),
                ),
                validator: ProfileValidators.validatePostalCode,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _companyCityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    ProfileValidators.validateAddressField(v, 'City'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
