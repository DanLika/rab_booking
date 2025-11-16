import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../../../auth/presentation/widgets/auth_background.dart';
import '../../../auth/presentation/widgets/glass_card.dart';
import '../../../auth/presentation/widgets/premium_input_field.dart';
import '../../../auth/presentation/widgets/gradient_auth_button.dart';
import '../../../auth/presentation/widgets/profile_image_picker.dart';
import '../providers/user_profile_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Premium Edit Profile Screen with Auth Style Design
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;
  bool _isSaving = false;

  // Controllers - Personal Info
  final _displayNameController = TextEditingController();
  final _emailContactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // Controllers - Social & Business
  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();
  final _propertyTypeController = TextEditingController();

  // Controllers - Company Details
  final _companyNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _vatIdController = TextEditingController();
  final _ibanController = TextEditingController();
  final _swiftController = TextEditingController();
  final _companyCountryController = TextEditingController();
  final _companyCityController = TextEditingController();
  final _companyStreetController = TextEditingController();
  final _companyPostalCodeController = TextEditingController();

  // Profile image
  Uint8List? _profileImageBytes;
  String? _profileImageName;
  String? _currentAvatarUrl;

  UserProfile? _originalProfile;

  @override
  void dispose() {
    // Personal Info
    _displayNameController.dispose();
    _emailContactController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _postalCodeController.dispose();

    // Social & Business
    _websiteController.dispose();
    _facebookController.dispose();
    _propertyTypeController.dispose();

    // Company Details
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

  void _loadData(UserData userData) {
    if (_originalProfile != null) return;

    _originalProfile = userData.profile;
    final profile = userData.profile;
    final company = userData.company;

    // Personal Info
    _displayNameController.text = profile.displayName;
    _emailContactController.text = profile.emailContact;
    _phoneController.text = profile.phoneE164;
    _countryController.text = profile.address.country;
    _cityController.text = profile.address.city;
    _streetController.text = profile.address.street;
    _postalCodeController.text = profile.address.postalCode;

    // Social & Business
    _websiteController.text = profile.social.website;
    _facebookController.text = profile.social.facebook;
    _propertyTypeController.text = profile.propertyType;

    // Company Details
    _companyNameController.text = company.companyName;
    _taxIdController.text = company.taxId;
    _vatIdController.text = company.vatId;
    _ibanController.text = company.bankAccountIban;
    _swiftController.text = company.swift;
    _companyCountryController.text = company.address.country;
    _companyCityController.text = company.address.city;
    _companyStreetController.text = company.address.street;
    _companyPostalCodeController.text = company.address.postalCode;

    // Add listeners after loading
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

    setState(() => _isDirty = false);
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _saveProfile() async {
    // Validate form and show error if validation fails
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          'Please fill in all required fields correctly',
        );
      }
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      String? avatarUrl = _currentAvatarUrl;

      // Upload new profile image if selected
      if (_profileImageBytes != null && _profileImageName != null) {
        final storageService = StorageService();
        avatarUrl = await storageService.uploadProfileImage(
          userId: userId,
          imageBytes: _profileImageBytes!,
          fileName: _profileImageName!,
        );

        // Update avatarUrl in Firebase Auth user profile
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(avatarUrl);

        // Update avatarUrl in Firestore users collection
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {'avatar_url': avatarUrl},
        );
      }

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

      // Create updated company details
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

      // Save profile to Firestore
      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateProfile(updatedProfile);

      // Save company details to Firestore
      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateCompany(userId, updatedCompany);

      if (mounted) {
        setState(() {
          _isDirty = false;
          _isSaving = false;
        });

        // Refresh auth provider to update avatarUrl
        ref.invalidate(enhancedAuthProvider);

        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Profile updated successfully',
        );

        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);

        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Failed to save profile',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(userDataProvider);
    final authState = ref.watch(enhancedAuthProvider);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _isDirty) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Discard changes?'),
              content: const Text(
                'You have unsaved changes. Do you want to discard them?',
              ),
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
          if (shouldPop == true && context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AuthBackground(
          child: userDataAsync.when(
            data: (userData) {
              // Create default userData if null
              final effectiveUserData =
                  userData ??
                  UserData(
                    profile: UserProfile(
                      userId: FirebaseAuth.instance.currentUser!.uid,
                      displayName: authState.userModel?.fullName ?? '',
                      emailContact: authState.userModel?.email ?? '',
                      phoneE164: authState.userModel?.phone ?? '',
                    ),
                  );

              _loadData(effectiveUserData);
              _currentAvatarUrl = authState.userModel?.avatarUrl;

              return SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width < 400 ? 16 : 24,
                    ),
                    child: GlassCard(
                      maxWidth: 600,
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Back Button
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => context.pop(),
                                icon: const Icon(Icons.arrow_back),
                                tooltip: 'Back',
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Profile Image Picker
                            ProfileImagePicker(
                              imageUrl: _currentAvatarUrl,
                              initials: authState.userModel?.initials,
                              onImageSelected: (bytes, name) {
                                setState(() {
                                  _profileImageBytes = bytes;
                                  _profileImageName = name;
                                  _markDirty();
                                });
                              },
                            ),
                            const SizedBox(height: 32),

                            // Title
                            Text(
                              'Edit Profile',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            // Subtitle
                            Text(
                              'Update your personal information',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 15,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Display Name
                            PremiumInputField(
                              controller: _displayNameController,
                              labelText: 'Display Name',
                              prefixIcon: Icons.person_outline,
                              validator: ProfileValidators.validateName,
                            ),
                            const SizedBox(height: 20),

                            // Email
                            PremiumInputField(
                              controller: _emailContactController,
                              labelText: 'Contact Email',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: ProfileValidators.validateEmail,
                            ),
                            const SizedBox(height: 20),

                            // Phone
                            PremiumInputField(
                              controller: _phoneController,
                              labelText: 'Phone',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: ProfileValidators.validatePhone,
                            ),
                            const SizedBox(height: 20),

                            // Website
                            PremiumInputField(
                              controller: _websiteController,
                              labelText: 'Website',
                              prefixIcon: Icons.language_outlined,
                              keyboardType: TextInputType.url,
                            ),
                            const SizedBox(height: 20),

                            // Facebook
                            PremiumInputField(
                              controller: _facebookController,
                              labelText: 'Facebook Page',
                              prefixIcon: Icons.facebook,
                              keyboardType: TextInputType.url,
                            ),
                            const SizedBox(height: 20),

                            // Property Type
                            PremiumInputField(
                              controller: _propertyTypeController,
                              labelText: 'Property Type',
                              prefixIcon: Icons.business_outlined,
                            ),
                            const SizedBox(height: 28),

                            // Address Section Header
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.authSecondary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Address',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Country
                            PremiumInputField(
                              controller: _countryController,
                              labelText: 'Country',
                              prefixIcon: Icons.public,
                              validator: (v) =>
                                  ProfileValidators.validateAddressField(
                                    v,
                                    'Country',
                                  ),
                            ),
                            const SizedBox(height: 20),

                            // Street
                            PremiumInputField(
                              controller: _streetController,
                              labelText: 'Street',
                              prefixIcon: Icons.location_on_outlined,
                              validator: (v) =>
                                  ProfileValidators.validateAddressField(
                                    v,
                                    'Street',
                                  ),
                            ),
                            const SizedBox(height: 20),

                            // City & Postal Code Row
                            Row(
                              children: [
                                Expanded(
                                  child: PremiumInputField(
                                    controller: _cityController,
                                    labelText: 'City',
                                    prefixIcon: Icons.location_city,
                                    validator: (v) =>
                                        ProfileValidators.validateAddressField(
                                          v,
                                          'City',
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: PremiumInputField(
                                    controller: _postalCodeController,
                                    labelText: 'Postal Code',
                                    prefixIcon: Icons.markunread_mailbox,
                                    validator:
                                        ProfileValidators.validatePostalCode,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Company Details Section
                            Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                childrenPadding: const EdgeInsets.only(top: 20),
                                title: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.authSecondary,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(2),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Company Details',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  // Company Name
                                  PremiumInputField(
                                    controller: _companyNameController,
                                    labelText: 'Company Name',
                                    prefixIcon: Icons.business,
                                  ),
                                  const SizedBox(height: 20),

                                  // Tax ID
                                  PremiumInputField(
                                    controller: _taxIdController,
                                    labelText: 'Tax ID',
                                    prefixIcon: Icons.receipt_long,
                                  ),
                                  const SizedBox(height: 20),

                                  // VAT ID
                                  PremiumInputField(
                                    controller: _vatIdController,
                                    labelText: 'VAT ID',
                                    prefixIcon: Icons.account_balance,
                                  ),
                                  const SizedBox(height: 20),

                                  // IBAN
                                  PremiumInputField(
                                    controller: _ibanController,
                                    labelText: 'IBAN',
                                    prefixIcon: Icons.credit_card,
                                  ),
                                  const SizedBox(height: 20),

                                  // SWIFT
                                  PremiumInputField(
                                    controller: _swiftController,
                                    labelText: 'SWIFT/BIC',
                                    prefixIcon: Icons.code,
                                  ),
                                  const SizedBox(height: 28),

                                  // Company Address Header
                                  Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              AppColors.authSecondary,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(2),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Company Address',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Company Country
                                  PremiumInputField(
                                    controller: _companyCountryController,
                                    labelText: 'Country',
                                    prefixIcon: Icons.public,
                                  ),
                                  const SizedBox(height: 20),

                                  // Company Street
                                  PremiumInputField(
                                    controller: _companyStreetController,
                                    labelText: 'Street',
                                    prefixIcon: Icons.location_on_outlined,
                                  ),
                                  const SizedBox(height: 20),

                                  // Company City & Postal Code Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: PremiumInputField(
                                          controller: _companyCityController,
                                          labelText: 'City',
                                          prefixIcon: Icons.location_city,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: PremiumInputField(
                                          controller: _companyPostalCodeController,
                                          labelText: 'Postal Code',
                                          prefixIcon: Icons.markunread_mailbox,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Save Button
                            GradientAuthButton(
                              text: 'Save Changes',
                              onPressed: (_isDirty && !_isSaving)
                                  ? _saveProfile
                                  : null,
                              isLoading: _isSaving,
                              icon: Icons.save_rounded,
                            ),
                            const SizedBox(height: 16),

                            // Cancel Button
                            TextButton(
                              onPressed: () => context.pop(),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
    );
  }
}
