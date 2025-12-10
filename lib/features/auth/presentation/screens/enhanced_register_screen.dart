import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/auth_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/premium_input_field.dart';
import '../widgets/gradient_auth_button.dart';
import '../widgets/profile_image_picker.dart';
import 'terms_conditions_screen.dart';
import 'privacy_policy_screen.dart';

/// Enhanced Registration Screen with Premium Design
class EnhancedRegisterScreen extends ConsumerStatefulWidget {
  const EnhancedRegisterScreen({super.key});

  @override
  ConsumerState<EnhancedRegisterScreen> createState() => _EnhancedRegisterScreenState();
}

class _EnhancedRegisterScreenState extends ConsumerState<EnhancedRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _newsletterOptIn = false;
  String? _emailErrorFromServer; // Store Firebase auth errors for inline display

  // Profile image
  Uint8List? _profileImageBytes;
  String? _profileImageName;

  @override
  void initState() {
    super.initState();
    // Clear server error when user starts typing
    _emailController.addListener(() {
      if (_emailErrorFromServer != null) {
        setState(() => _emailErrorFromServer = null);
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      // Show feedback for validation errors
      ErrorDisplayUtils.showErrorSnackBar(context, 'Please fix the errors above');
      return;
    }

    if (!_acceptedTerms || !_acceptedPrivacy) {
      final l10n = AppLocalizations.of(context);
      ErrorDisplayUtils.showErrorSnackBar(context, l10n.authMustAcceptTerms);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse full name into first and last name (handles multiple spaces)
      final fullName = _fullNameController.text.trim();
      final nameParts = fullName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await ref
          .read(enhancedAuthProvider.notifier)
          .registerWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: firstName,
            lastName: lastName,
            phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
            acceptedTerms: _acceptedTerms,
            acceptedPrivacy: _acceptedPrivacy,
            newsletterOptIn: _newsletterOptIn,
            profileImageBytes: _profileImageBytes,
            profileImageName: _profileImageName,
          );

      // Registration successful - navigate to email verification
      if (mounted) {
        final authState = ref.read(enhancedAuthProvider);

        // Check for errors from provider
        if (authState.error != null) {
          setState(() => _isLoading = false);
          ErrorDisplayUtils.showErrorSnackBar(context, authState.error);
          return;
        }

        // Check if email verification required (always true for new registrations)
        if (authState.requiresEmailVerification) {
          setState(() => _isLoading = false);
          context.go(OwnerRoutes.emailVerification);
          return;
        }

        // If somehow email is already verified, continue to dashboard
        // Router will handle navigation
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        final authState = ref.read(enhancedAuthProvider);
        final errorMessage = authState.error ?? e.toString();

        // Check if it's an email-related error - show inline
        if (errorMessage.contains('already exists') ||
            errorMessage.contains('email-already-in-use') ||
            errorMessage.contains('Invalid email')) {
          setState(() {
            _emailErrorFromServer =
                errorMessage.contains('already exists') || errorMessage.contains('email-already-in-use')
                ? 'An account already exists with this email'
                : 'Invalid email address';
            _isLoading = false;
          });
          // Trigger form validation to show inline error
          _formKey.currentState!.validate();
        } else {
          // Other errors - show SnackBar
          setState(() => _isLoading = false);
          ErrorDisplayUtils.showErrorSnackBar(context, errorMessage);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = MediaQuery.of(context).size.width < 400;
              return Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: isMobile ? 16 : 20),
                            child: GlassCard(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Profile Image Picker
                                    ProfileImagePicker(
                                      size: MediaQuery.of(context).size.width < 400 ? 80 : 90,
                                      initials: _fullNameController.text.trim().isNotEmpty
                                          ? _fullNameController.text.trim().substring(0, 1).toUpperCase()
                                          : null,
                                      onImageSelected: (bytes, name) {
                                        setState(() {
                                          _profileImageBytes = bytes;
                                          _profileImageName = name;
                                        });
                                      },
                                    ),
                                    SizedBox(height: MediaQuery.of(context).size.width < 400 ? 16 : 20),

                                    // Title
                                    Text(
                                      l10n.authCreateAccount,
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: MediaQuery.of(context).size.width < 400 ? 22 : 26,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),

                                    // Subtitle
                                    Text(
                                      l10n.authStartManaging,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontSize: MediaQuery.of(context).size.width < 400 ? 13 : 14,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: MediaQuery.of(context).size.width < 400 ? 20 : 24),

                                    // Full Name field
                                    PremiumInputField(
                                      controller: _fullNameController,
                                      labelText: l10n.authFullName,
                                      prefixIcon: Icons.person_outline,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return l10n.authEnterFullName;
                                        }
                                        // Split by whitespace and filter empty parts
                                        final parts = value
                                            .trim()
                                            .split(RegExp(r'\s+'))
                                            .where((p) => p.isNotEmpty)
                                            .toList();
                                        if (parts.length < 2) {
                                          return l10n.authEnterFirstLastName;
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: MediaQuery.of(context).size.width < 400 ? 12 : 14),

                                    // Email
                                    PremiumInputField(
                                      controller: _emailController,
                                      labelText: l10n.email,
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (_emailErrorFromServer != null) {
                                          return _emailErrorFromServer;
                                        }
                                        return ProfileValidators.validateEmail(value);
                                      },
                                    ),
                                    SizedBox(height: MediaQuery.of(context).size.width < 400 ? 12 : 14),

                                    // Phone
                                    PremiumInputField(
                                      controller: _phoneController,
                                      labelText: l10n.authPhone,
                                      prefixIcon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                      validator: ProfileValidators.validatePhone,
                                    ),
                                    SizedBox(height: MediaQuery.of(context).size.width < 400 ? 12 : 14),

                                    // Password
                                    PremiumInputField(
                                      controller: _passwordController,
                                      labelText: l10n.password,
                                      prefixIcon: Icons.lock_outline,
                                      obscureText: _obscurePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          color: theme.colorScheme.onSurfaceVariant,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() => _obscurePassword = !_obscurePassword);
                                        },
                                      ),
                                      validator: PasswordValidator.validateMinimumLength,
                                    ),
                                    SizedBox(height: MediaQuery.of(context).size.width < 400 ? 12 : 14),

                                    // Confirm Password
                                    PremiumInputField(
                                      controller: _confirmPasswordController,
                                      labelText: l10n.authConfirmPassword,
                                      prefixIcon: Icons.lock_outline,
                                      obscureText: _obscureConfirmPassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                          color: theme.colorScheme.onSurfaceVariant,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                        },
                                      ),
                                      validator: (value) {
                                        return PasswordValidator.validateConfirmPassword(
                                          _passwordController.text,
                                          value,
                                        );
                                      },
                                    ),
                                    SizedBox(height: MediaQuery.of(context).size.width < 400 ? 12 : 14),

                                    // Terms & Conditions Checkbox
                                    _buildCheckbox(
                                      value: _acceptedTerms,
                                      onChanged: (value) => setState(() => _acceptedTerms = value!),
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                          children: [
                                            TextSpan(text: l10n.authAcceptTerms),
                                            TextSpan(
                                              text: l10n.authTermsConditions,
                                              style: TextStyle(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                                decoration: TextDecoration.underline,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) => const TermsConditionsScreen(),
                                                    ),
                                                  );
                                                },
                                            ),
                                            const TextSpan(text: ' *'),
                                          ],
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Privacy Policy Checkbox
                                    _buildCheckbox(
                                      value: _acceptedPrivacy,
                                      onChanged: (value) => setState(() => _acceptedPrivacy = value!),
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                          children: [
                                            TextSpan(text: l10n.authAcceptTerms),
                                            TextSpan(
                                              text: l10n.authPrivacyPolicy,
                                              style: TextStyle(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                                decoration: TextDecoration.underline,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) => const PrivacyPolicyScreen(),
                                                    ),
                                                  );
                                                },
                                            ),
                                            const TextSpan(text: ' *'),
                                          ],
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Newsletter Checkbox
                                    _buildCheckbox(
                                      value: _newsletterOptIn,
                                      onChanged: (value) => setState(() => _newsletterOptIn = value!),
                                      child: Text(
                                        l10n.authNewsletterOptIn,
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(height: MediaQuery.of(context).size.width < 400 ? 20 : 24),

                                    // Register Button
                                    GradientAuthButton(
                                      text: l10n.authCreateAccount,
                                      onPressed: _handleRegister,
                                      isLoading: _isLoading,
                                      icon: Icons.person_add_rounded,
                                    ),
                                    SizedBox(height: MediaQuery.of(context).size.width < 400 ? 16 : 20),

                                    // Login Link
                                    Center(
                                      child: TextButton(
                                        onPressed: () => context.go(OwnerRoutes.login),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                        ),
                                        child: RichText(
                                          text: TextSpan(
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontSize: 13,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                            children: [
                                              TextSpan(text: '${l10n.authHaveAccount} '),
                                              TextSpan(
                                                text: l10n.login,
                                                style: TextStyle(
                                                  color: theme.colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox({required bool value, required ValueChanged<bool?> onChanged, required Widget child}) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 22,
          width: 22,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            activeColor: theme.colorScheme.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(padding: const EdgeInsets.only(top: 2), child: child),
        ),
      ],
    );
  }
}
