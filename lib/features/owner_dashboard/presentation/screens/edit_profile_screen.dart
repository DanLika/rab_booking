import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../core/utils/profile_validator_error_l10n.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../../../../shared/widgets/redesign.dart';
import '../providers/user_profile_provider.dart';

/// Edit Profile screen — refactored onto Bb* redesign primitives
/// (PR redesign/r3-edit-profile). Mirrors the Bank Account + Change Password
/// settings-form pattern: bare Scaffold + floating BbCard sections + Phase 1.1
/// native [BbInput.validator] wiring + [BbAvatarUpload] hero (PR #629).
///
/// FROZEN / preserved logic:
///  - `updateProfileAndCompany` / `completeProfile` Firestore writes
///  - display-name first/last split + `users/{uid}` merge write
///    (`audit/35` digit-strip + cooldown semantics intact)
///  - Avatar upload via `StorageService.uploadProfileImage` + Firebase Auth
///    `updatePhotoURL` + `users/{uid}.avatar_url` merge
///  - `_isDirty` dirty tracking, `PopScope` discard dialog, `_formKey`,
///    autovalidate-on-user-interaction
///  - [AndroidKeyboardDismissFixApproach1] mixin + `KeyedSubtree(ValueKey(...))`
///  - `resizeToAvoidBottomInset: true`
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with AndroidKeyboardDismissFixApproach1<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;
  bool _isSaving = false;

  // Personal Info
  final _displayNameController = TextEditingController();
  final _emailContactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // Social & Business
  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();
  final _propertyTypeController = TextEditingController();

  // Company Details (bank fields live in dedicated Bank Account screen)
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

    _companyNameController.text = company.companyName;
    _taxIdController.text = company.taxId;
    _vatIdController.text = company.vatId;
    _companyCountryController.text = company.address.country;
    _companyCityController.text = company.address.city;
    _companyStreetController.text = company.address.street;
    _companyPostalCodeController.text = company.address.postalCode;

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
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          l10n.editProfileValidationError,
        );
      }
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      String? avatarUrl = _currentAvatarUrl;

      if (_profileImageBytes != null && _profileImageName != null) {
        final storageService = StorageService();
        avatarUrl = await storageService.uploadProfileImage(
          userId: userId,
          imageBytes: _profileImageBytes!,
          fileName: _profileImageName!,
        );

        await FirebaseAuth.instance.currentUser?.updatePhotoURL(avatarUrl);

        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'avatar_url': avatarUrl,
        }, SetOptions(merge: true));
      }

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

      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateProfileAndCompany(updatedProfile, updatedCompany);

      final displayName = _displayNameController.text.trim();
      final nameParts = displayName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'first_name': firstName,
        'last_name': lastName,
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final authState = ref.read(enhancedAuthProvider);
      if (authState.requiresProfileCompletion) {
        await ref.read(enhancedAuthProvider.notifier).completeProfile();
      }

      if (mounted) {
        setState(() {
          _isDirty = false;
          _isSaving = false;
        });

        ref.invalidate(enhancedAuthProvider);

        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          l10n.editProfileSaveSuccess,
        );

        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/owner/profile');
        }
      }
    } catch (e, stackTrace) {
      LoggingService.log('Error saving profile: $e', tag: 'EditProfileScreen');
      await LoggingService.logError('Failed to save profile', e, stackTrace);

      if (mounted) {
        setState(() => _isSaving = false);

        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.editProfileSaveError,
        );
      }
    }
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/owner/profile');
    }
  }

  Widget _buildWelcomeBanner(AppLocalizations l10n, BBColorSet c) {
    return BbCard(
      variant: BbCardVariant.accentLeft,
      accentTone: BbCardAccentTone.primary,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: BbIcon(name: 'celebration', size: 22, color: c.primary),
          ),
          const SizedBox(width: BBSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.editProfileWelcomeTitle,
                  style: BBType.label(
                    context,
                  ).copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.editProfileWelcomeMessage,
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalCard(AppLocalizations l10n, BBColorSet c) {
    // Premium verified badge — settings.jsx §192 trailing chip.
    // Surfaces only when contact email matches the (verified) Firebase Auth
    // email — never claims verification of an unmatched/edited address.
    final authUser = FirebaseAuth.instance.currentUser;
    final authEmail = authUser?.email?.trim().toLowerCase();
    final contactEmail = _emailContactController.text.trim().toLowerCase();
    final isContactEmailVerified =
        authUser?.emailVerified == true &&
        authEmail != null &&
        authEmail.isNotEmpty &&
        authEmail == contactEmail;

    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BbSectionHeader(
            title: l10n.editProfilePersonalData,
            level: BbSectionHeaderLevel.h3,
          ),
          if (l10n.editProfilePersonalDataSubtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: BBSpace.sm),
              child: Text(
                l10n.editProfilePersonalDataSubtitle,
                style: BBType.caption(context).copyWith(color: c.textTertiary),
              ),
            ),
          BbInput(
            key: const ValueKey('edit_profile_display_name'),
            controller: _displayNameController,
            label: l10n.editProfileFullName,
            iconLeft: 'person',
            size: BbInputSize.lg,
            validator: (v) {
              final e = ProfileValidators.nameError(v);
              return e == null ? null : l10n.profileValidatorErrorText(e);
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: BBSpace.md),
          BbInput(
            key: const ValueKey('edit_profile_email'),
            controller: _emailContactController,
            label: l10n.editProfileEmail,
            iconLeft: 'mail',
            size: BbInputSize.lg,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final e = ProfileValidators.emailError(v);
              return e == null ? null : l10n.profileValidatorErrorText(e);
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
            trailingAction: isContactEmailVerified
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BbIcon(name: 'verified', size: 16, color: c.success),
                      const SizedBox(width: 4),
                      Text(
                        l10n.editProfileEmailVerified,
                        style: BBType.caption(context).copyWith(
                          color: c.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: BBSpace.md),
          BbInput(
            key: const ValueKey('edit_profile_phone'),
            controller: _phoneController,
            label: l10n.editProfilePhone,
            iconLeft: 'phone',
            size: BbInputSize.lg,
            keyboardType: TextInputType.phone,
            validator: (v) {
              final e = ProfileValidators.phoneError(v);
              return e == null ? null : l10n.profileValidatorErrorText(e);
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
            // Premium helper — settings.jsx §181 phone hint
            helper: l10n.editProfilePhoneHelper,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(AppLocalizations l10n, BBColorSet c) {
    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BbSectionHeader(
            title: l10n.editProfileAddress,
            level: BbSectionHeaderLevel.h3,
          ),
          if (l10n.editProfileAddressSubtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: BBSpace.sm),
              child: Text(
                l10n.editProfileAddressSubtitle,
                style: BBType.caption(context).copyWith(color: c.textTertiary),
              ),
            ),
          BbInput(
            key: const ValueKey('edit_profile_country'),
            controller: _countryController,
            label: l10n.editProfileCountry,
            iconLeft: 'public',
            size: BbInputSize.lg,
          ),
          const SizedBox(height: BBSpace.md),
          BbInput(
            key: const ValueKey('edit_profile_street'),
            controller: _streetController,
            label: l10n.editProfileStreet,
            iconLeft: 'location_on',
            size: BbInputSize.lg,
          ),
          const SizedBox(height: BBSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: BbInput(
                  key: const ValueKey('edit_profile_city'),
                  controller: _cityController,
                  label: l10n.editProfileCity,
                  iconLeft: 'location_city',
                  size: BbInputSize.lg,
                ),
              ),
              const SizedBox(width: BBSpace.sm),
              Expanded(
                child: BbInput(
                  key: const ValueKey('edit_profile_postal_code'),
                  controller: _postalCodeController,
                  label: l10n.editProfilePostalCode,
                  iconLeft: 'markunread_mailbox',
                  size: BbInputSize.lg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(AppLocalizations l10n, BBColorSet c) {
    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BbSectionHeader(
            title: l10n.editProfileCompany,
            level: BbSectionHeaderLevel.h3,
          ),
          if (l10n.editProfileCompanySubtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: BBSpace.sm),
              child: Text(
                l10n.editProfileCompanySubtitle,
                style: BBType.caption(context).copyWith(color: c.textTertiary),
              ),
            ),
          BbInput(
            key: const ValueKey('edit_profile_company_name'),
            controller: _companyNameController,
            label: l10n.editProfileCompanyName,
            iconLeft: 'business',
            size: BbInputSize.lg,
          ),
          const SizedBox(height: BBSpace.md),
          BbInput(
            key: const ValueKey('edit_profile_tax_id'),
            controller: _taxIdController,
            label: l10n.editProfileTaxId,
            iconLeft: 'receipt_long',
            size: BbInputSize.lg,
          ),
          const SizedBox(height: BBSpace.md),
          BbInput(
            key: const ValueKey('edit_profile_vat_id'),
            controller: _vatIdController,
            label: l10n.editProfileVatId,
            iconLeft: 'account_balance',
            size: BbInputSize.lg,
          ),
          const SizedBox(height: BBSpace.md),
          _buildSubSectionLabel(l10n.editProfileCompanyAddress, c),
          const SizedBox(height: BBSpace.sm),
          BbInput(
            key: const ValueKey('edit_profile_company_country'),
            controller: _companyCountryController,
            label: l10n.editProfileCountry,
            iconLeft: 'public',
            size: BbInputSize.lg,
          ),
          const SizedBox(height: BBSpace.md),
          BbInput(
            key: const ValueKey('edit_profile_company_street'),
            controller: _companyStreetController,
            label: l10n.editProfileStreet,
            iconLeft: 'location_on',
            size: BbInputSize.lg,
          ),
          const SizedBox(height: BBSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: BbInput(
                  key: const ValueKey('edit_profile_company_city'),
                  controller: _companyCityController,
                  label: l10n.editProfileCity,
                  iconLeft: 'location_city',
                  size: BbInputSize.lg,
                ),
              ),
              const SizedBox(width: BBSpace.sm),
              Expanded(
                child: BbInput(
                  key: const ValueKey('edit_profile_company_postal_code'),
                  controller: _companyPostalCodeController,
                  label: l10n.editProfilePostalCode,
                  iconLeft: 'markunread_mailbox',
                  size: BbInputSize.lg,
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpace.md),
          _buildSubSectionLabel(l10n.editProfileOnlinePresence, c),
          const SizedBox(height: BBSpace.sm),
          BbInput(
            key: const ValueKey('edit_profile_website'),
            controller: _websiteController,
            label: l10n.editProfileWebsite,
            iconLeft: 'language',
            size: BbInputSize.lg,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: BBSpace.md),
          BbInput(
            key: const ValueKey('edit_profile_facebook'),
            controller: _facebookController,
            label: l10n.editProfileFacebook,
            // 'facebook' brand glyph not shipped in material_symbols_icons map;
            // 'link' renders as a generic chain icon (works for any social URL).
            iconLeft: 'link',
            size: BbInputSize.lg,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: BBSpace.md),
          BbInput(
            key: const ValueKey('edit_profile_property_type'),
            controller: _propertyTypeController,
            label: l10n.editProfilePropertyType,
            iconLeft: 'home_work',
            size: BbInputSize.lg,
          ),
        ],
      ),
    );
  }

  Widget _buildSubSectionLabel(String title, BBColorSet c) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: BBSpace.xs),
        Text(
          title,
          style: BBType.label(
            context,
          ).copyWith(color: c.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BbButton(
          key: const ValueKey('edit_profile_save'),
          label: _isSaving
              ? l10n.editProfileSaving
              : l10n.editProfileSaveChanges,
          iconLeft: _isSaving ? null : 'save',
          size: BbButtonSize.lg,
          fullWidth: true,
          loading: _isSaving,
          disabled: !_isDirty,
          onPressed: (_isDirty && !_isSaving) ? _saveProfile : null,
        ),
        const SizedBox(height: BBSpace.sm),
        BbButton(
          key: const ValueKey('edit_profile_cancel'),
          label: l10n.cancel,
          variant: BbButtonVariant.secondary,
          size: BbButtonSize.lg,
          fullWidth: true,
          onPressed: _exit,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(userDataProvider);
    final authState = ref.watch(enhancedAuthProvider);
    final l10n = AppLocalizations.of(context);
    final c = BBColor.of(context);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _isDirty) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => BbDialog(
              title: l10n.editProfileDiscardTitle,
              body: l10n.editProfileDiscardMessage,
              destructive: true,
              secondary: BbDialogAction(
                label: l10n.cancel,
                onPressed: () => Navigator.pop(dialogContext, false),
              ),
              primary: BbDialogAction(
                label: l10n.editProfileDiscard,
                onPressed: () => Navigator.pop(dialogContext, true),
              ),
            ),
          );
          if (shouldPop == true && context.mounted) {
            _exit();
          }
        }
      },
      child: KeyedSubtree(
        key: ValueKey('edit_profile_$keyboardFixRebuildKey'),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: c.bg,
          body: Container(
            decoration: BoxDecoration(
              gradient: context.gradients.pageBackground,
            ),
            child: SafeArea(
              child: userDataAsync.when(
                data: (userData) {
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

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final mediaQuery = MediaQuery.maybeOf(context);
                      final keyboardHeight =
                          (mediaQuery?.viewInsets.bottom ?? 0.0).clamp(
                            0.0,
                            double.infinity,
                          );
                      final isKeyboardOpen = keyboardHeight > 0;

                      double minHeight;
                      if (isKeyboardOpen &&
                          constraints.maxHeight.isFinite &&
                          constraints.maxHeight > 0) {
                        final calculated =
                            constraints.maxHeight - keyboardHeight;
                        minHeight = calculated.clamp(
                          0.0,
                          constraints.maxHeight,
                        );
                      } else {
                        minHeight = constraints.maxHeight.isFinite
                            ? constraints.maxHeight
                            : 0.0;
                      }
                      minHeight = minHeight.isFinite ? minHeight : 0.0;

                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(BBSpace.sm),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: minHeight),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 680),
                              child: Form(
                                key: _formKey,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: IconButton(
                                        onPressed: _exit,
                                        icon: const Icon(Icons.arrow_back),
                                        tooltip: l10n.back,
                                      ),
                                    ),
                                    const SizedBox(height: BBSpace.xs),
                                    Center(
                                      child: BbAvatarUpload(
                                        key: const ValueKey(
                                          'edit_profile_avatar',
                                        ),
                                        imageUrl: _currentAvatarUrl,
                                        initials: authState.userModel?.initials,
                                        size: BbAvatarSize.xl,
                                        isUploading: _isSaving,
                                        ring: false,
                                        onImageSelected: (bytes, name) {
                                          setState(() {
                                            _profileImageBytes = bytes;
                                            _profileImageName = name;
                                            _markDirty();
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: BBSpace.md),
                                    Text(
                                      l10n.editProfileTitle,
                                      textAlign: TextAlign.center,
                                      style: BBType.h2(context).copyWith(
                                        color: c.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: BBSpace.xs),
                                    Text(
                                      l10n.editProfileSubtitle,
                                      textAlign: TextAlign.center,
                                      style: BBType.body(
                                        context,
                                      ).copyWith(color: c.textSecondary),
                                    ),
                                    const SizedBox(height: BBSpace.md),
                                    if (authState
                                        .requiresProfileCompletion) ...[
                                      _buildWelcomeBanner(l10n, c),
                                      const SizedBox(height: BBSpace.md),
                                    ],
                                    _buildPersonalCard(l10n, c),
                                    const SizedBox(height: BBSpace.md),
                                    _buildAddressCard(l10n, c),
                                    const SizedBox(height: BBSpace.md),
                                    _buildCompanyCard(l10n, c),
                                    const SizedBox(height: BBSpace.md),
                                    _buildActionButtons(l10n),
                                    const SizedBox(height: BBSpace.md),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(l10n.errorWithMessage(error.toString())),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
