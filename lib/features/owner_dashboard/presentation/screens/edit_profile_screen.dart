import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
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

  // Controllers
  final _displayNameController = TextEditingController();
  final _emailContactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // Profile image
  Uint8List? _profileImageBytes;
  String? _profileImageName;
  String? _currentAvatarUrl;

  UserProfile? _originalProfile;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailContactController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _loadData(UserData userData) {
    if (_originalProfile != null) return;

    _originalProfile = userData.profile;
    final profile = userData.profile;

    _displayNameController.text = profile.displayName;
    _emailContactController.text = profile.emailContact;
    _phoneController.text = profile.phoneE164;
    _countryController.text = profile.address.country;
    _cityController.text = profile.address.city;
    _streetController.text = profile.address.street;
    _postalCodeController.text = profile.address.postalCode;

    // Add listeners after loading
    _displayNameController.addListener(_markDirty);
    _emailContactController.addListener(_markDirty);
    _phoneController.addListener(_markDirty);
    _countryController.addListener(_markDirty);
    _cityController.addListener(_markDirty);
    _streetController.addListener(_markDirty);
    _postalCodeController.addListener(_markDirty);

    setState(() => _isDirty = false);
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

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
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'avatar_url': avatarUrl});
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
        social: _originalProfile?.social ?? const SocialLinks(),
        propertyType: _originalProfile?.propertyType ?? '',
        logoUrl: _originalProfile?.logoUrl ?? '',
      );

      // Save to Firestore
      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateProfile(updatedProfile);

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
              content: const Text('You have unsaved changes. Do you want to discard them?'),
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
        body: AuthBackground(
          child: userDataAsync.when(
            data: (userData) {
              // Create default userData if null
              final effectiveUserData = userData ??
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width < 400 ? 16 : 24
                      ),
                      child: GlassCard(
                        maxWidth: 600,
                        child: Form(
                          key: _formKey,
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
                                size: 120,
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
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28,
                                      color: const Color(0xFF2D3748),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),

                              // Subtitle
                              Text(
                                'Update your personal information',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF718096),
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
                              const SizedBox(height: 28),

                              // Address Section Header
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF6B4CE6), Color(0xFF4A90E2)],
                                      ),
                                      borderRadius: BorderRadius.all(Radius.circular(2)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Address',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3748),
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
                                validator: (v) => ProfileValidators.validateAddressField(v, 'Country'),
                              ),
                              const SizedBox(height: 20),

                              // Street
                              PremiumInputField(
                                controller: _streetController,
                                labelText: 'Street',
                                prefixIcon: Icons.location_on_outlined,
                                validator: (v) => ProfileValidators.validateAddressField(v, 'Street'),
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
                                      validator: (v) => ProfileValidators.validateAddressField(v, 'City'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: PremiumInputField(
                                      controller: _postalCodeController,
                                      labelText: 'Postal Code',
                                      prefixIcon: Icons.markunread_mailbox,
                                      validator: ProfileValidators.validatePostalCode,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // Save Button
                              GradientAuthButton(
                                text: 'Save Changes',
                                onPressed: (_isDirty && !_isSaving) ? _saveProfile : null,
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
                                    color: const Color(0xFF718096),
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
