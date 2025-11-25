import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../../../auth/presentation/widgets/auth_background.dart';
import '../../../auth/presentation/widgets/glass_card.dart';
import '../../../auth/presentation/widgets/premium_input_field.dart';
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

  // Controllers - Company Details (Bank details moved to dedicated Bank Account screen)
  final _companyNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _vatIdController = TextEditingController();
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

    // Company Details (Bank details moved to dedicated Bank Account screen)
    _companyNameController.dispose();
    _taxIdController.dispose();
    _vatIdController.dispose();
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

    // Company Details (Bank details managed in dedicated Bank Account screen)
    _companyNameController.text = company.companyName;
    _taxIdController.text = company.taxId;
    _vatIdController.text = company.vatId;
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

      // Create updated company details (preserve bank data from original - managed in Bank Account screen)
      final userData = ref.read(userDataProvider).value;
      final existingCompany = userData?.company;
      final updatedCompany = CompanyDetails(
        companyName: _companyNameController.text.trim(),
        taxId: _taxIdController.text.trim(),
        vatId: _vatIdController.text.trim(),
        bankAccountIban: existingCompany?.bankAccountIban ?? '',
        swift: existingCompany?.swift ?? '',
        bankName: existingCompany?.bankName ?? '',
        accountHolder: existingCompany?.accountHolder ?? '',
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

  // ========== HELPER METHODS ==========

  bool _hasAddressData() {
    return _countryController.text.isNotEmpty ||
        _streetController.text.isNotEmpty ||
        _cityController.text.isNotEmpty ||
        _postalCodeController.text.isNotEmpty;
  }

  Widget _buildProfileCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
    bool isOptional = false,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.getElevation(1, isDark: isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? const [Color(0xFF1A1A1A), Color(0xFF2D2D2D)]
                  : const [Color(0xFFF5F5F5), Colors.white],
              stops: const [0.0, 0.3],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.dividerColor.withAlpha((0.4 * 255).toInt()),
              width: 1.5,
            ),
          ),
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: initiallyExpanded,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 18),
              ),
              title: Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isOptional) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'opcionalno',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: subtitle != null
                  ? Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDivider(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Save Button - sa app bar gradient
        SizedBox(
          width: double.infinity,
          height: 52,
          child: Container(
            decoration: BoxDecoration(
              gradient: (_isDirty && !_isSaving)
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.7),
                      ],
                    )
                  : null,
              color: (_isDirty && !_isSaving)
                  ? null
                  : theme.disabledColor.withAlpha((0.3 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: (_isDirty && !_isSaving) ? _saveProfile : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                disabledForegroundColor: theme.disabledColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Spremanje...' : 'Spremi Promjene'),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Cancel Button - veći height
        SizedBox(
          width: double.infinity,
          height: 52,
          child: TextButton(
            onPressed: () => context.pop(),
            style: TextButton.styleFrom(
              foregroundColor:
                  theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.dividerColor,
                ),
              ),
            ),
            child: const Text('Odustani'),
          ),
        ),
      ],
    );
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
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
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

                            // ========== KARTICA 1: LIČNI PODACI ==========
                            _buildProfileCard(
                              title: 'Lični Podaci',
                              icon: Icons.person_outline,
                              initiallyExpanded: true,
                              subtitle: 'Osnovni kontakt podaci',
                              children: [
                                PremiumInputField(
                                  controller: _displayNameController,
                                  labelText: 'Ime i Prezime',
                                  prefixIcon: Icons.person_outline,
                                  validator: ProfileValidators.validateName,
                                ),
                                const SizedBox(height: 16),
                                PremiumInputField(
                                  controller: _emailContactController,
                                  labelText: 'Email',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: ProfileValidators.validateEmail,
                                ),
                                const SizedBox(height: 16),
                                PremiumInputField(
                                  controller: _phoneController,
                                  labelText: 'Telefon',
                                  prefixIcon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: ProfileValidators.validatePhone,
                                ),
                              ],
                            ),

                            // ========== KARTICA 2: ADRESA ==========
                            _buildProfileCard(
                              title: 'Adresa',
                              icon: Icons.location_on_outlined,
                              initiallyExpanded: _hasAddressData(),
                              isOptional: true,
                              subtitle: 'Vaša fizička adresa',
                              children: [
                                PremiumInputField(
                                  controller: _countryController,
                                  labelText: 'Država',
                                  prefixIcon: Icons.public,
                                ),
                                const SizedBox(height: 16),
                                PremiumInputField(
                                  controller: _streetController,
                                  labelText: 'Ulica i Broj',
                                  prefixIcon: Icons.location_on_outlined,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: PremiumInputField(
                                        controller: _cityController,
                                        labelText: 'Grad',
                                        prefixIcon: Icons.location_city,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: PremiumInputField(
                                        controller: _postalCodeController,
                                        labelText: 'Poštanski Broj',
                                        prefixIcon: Icons.markunread_mailbox,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // ========== KARTICA 3: KOMPANIJA ==========
                            // Note: Bankovni Podaci moved to dedicated Bank Account screen
                            // in Integracije → Plaćanja → Bankovni Račun
                            _buildProfileCard(
                              title: 'Kompanija',
                              icon: Icons.business_outlined,
                              isOptional: true,
                              subtitle: 'Za poslovne korisnike i fakture',
                              children: [
                                // Company Info
                                PremiumInputField(
                                  controller: _companyNameController,
                                  labelText: 'Naziv Kompanije',
                                  prefixIcon: Icons.business,
                                ),
                                const SizedBox(height: 16),
                                PremiumInputField(
                                  controller: _taxIdController,
                                  labelText: 'OIB / Porezni Broj',
                                  prefixIcon: Icons.receipt_long,
                                ),
                                const SizedBox(height: 16),
                                PremiumInputField(
                                  controller: _vatIdController,
                                  labelText: 'PDV ID',
                                  prefixIcon: Icons.account_balance,
                                ),
                                const SizedBox(height: 20),

                                // Company Address
                                _buildSectionDivider('Adresa Kompanije'),
                                PremiumInputField(
                                  controller: _companyCountryController,
                                  labelText: 'Država',
                                  prefixIcon: Icons.public,
                                ),
                                const SizedBox(height: 16),
                                PremiumInputField(
                                  controller: _companyStreetController,
                                  labelText: 'Ulica i Broj',
                                  prefixIcon: Icons.location_on_outlined,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: PremiumInputField(
                                        controller: _companyCityController,
                                        labelText: 'Grad',
                                        prefixIcon: Icons.location_city,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: PremiumInputField(
                                        controller: _companyPostalCodeController,
                                        labelText: 'Poštanski Broj',
                                        prefixIcon: Icons.markunread_mailbox,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Online Presence
                                _buildSectionDivider('Online Prisutnost'),
                                PremiumInputField(
                                  controller: _websiteController,
                                  labelText: 'Web Stranica',
                                  prefixIcon: Icons.language_outlined,
                                  keyboardType: TextInputType.url,
                                ),
                                const SizedBox(height: 16),
                                PremiumInputField(
                                  controller: _facebookController,
                                  labelText: 'Facebook Stranica',
                                  prefixIcon: Icons.facebook,
                                  keyboardType: TextInputType.url,
                                ),
                                const SizedBox(height: 16),
                                PremiumInputField(
                                  controller: _propertyTypeController,
                                  labelText: 'Tip Nekretnine',
                                  prefixIcon: Icons.home_work_outlined,
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // ========== ACTION BUTTONS ==========
                            _buildActionButtons(),
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
