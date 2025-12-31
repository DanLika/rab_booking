import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/utils/profile_validators.dart';
import '../widgets/auth_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/auth_logo_icon.dart';
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

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _newsletterOptIn = false;

  PasswordStrength _passwordStrength = PasswordStrength.weak;
  List<String> _missingRequirements = [];

  // Profile image
  Uint8List? _profileImageBytes;
  String? _profileImageName;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);

    // Performance Optimization: Initialize recognizers once to avoid re-creation on build.
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TermsConditionsScreen(),
            ),
          );
        }
      };

    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PrivacyPolicyScreen(),
            ),
          );
        }
      };
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final result = PasswordValidator.validate(_passwordController.text);
    setState(() {
      _passwordStrength = result.strength;
      _missingRequirements = result.missingRequirements;
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms || !_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must accept the Terms & Conditions and Privacy Policy'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse full name into first and last name
      final fullName = _fullNameController.text.trim();
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await ref.read(enhancedAuthProvider.notifier).registerWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: firstName,
            lastName: lastName,
            phone: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
            acceptedTerms: _acceptedTerms,
            acceptedPrivacy: _acceptedPrivacy,
            newsletterOptIn: _newsletterOptIn,
            profileImageBytes: _profileImageBytes,
            profileImageName: _profileImageName,
          );

      if (mounted) {
        // Navigate to email verification screen
        context.go(OwnerRoutes.emailVerification);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SingleChildScrollView(
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
                  maxWidth: 460,
                  child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Image Picker
                    ProfileImagePicker(
                      size: 100,
                      initials: _fullNameController.text.isNotEmpty
                          ? _fullNameController.text.substring(0, 1)
                          : null,
                      onImageSelected: (bytes, name) {
                        setState(() {
                          _profileImageBytes = bytes;
                          _profileImageName = name;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Create Account',
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
                      'Start managing your properties today',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF718096),
                            fontSize: 15,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Full Name field
                    PremiumInputField(
                      controller: _fullNameController,
                      labelText: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        if (value.trim().split(' ').length < 2) {
                          return 'Please enter both first and last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    PremiumInputField(
                      controller: _emailController,
                      labelText: 'Email Address',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: ProfileValidators.validateEmail,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    PremiumInputField(
                      controller: _phoneController,
                      labelText: 'Phone (optional)',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: ProfileValidators.validatePhone,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    PremiumInputField(
                      controller: _passwordController,
                      labelText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF718096),
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: PasswordValidator.validateSimple,
                    ),
                    const SizedBox(height: 12),

                    // Password Strength Indicator
                    if (_passwordController.text.isNotEmpty)
                      _buildPasswordStrengthIndicator(),
                    const SizedBox(height: 16),

                    // Confirm Password
                    PremiumInputField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF718096),
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
                    const SizedBox(height: 20),

                    // Terms & Conditions Checkbox
                    _buildCheckbox(
                      value: _acceptedTerms,
                      onChanged: (value) => setState(() => _acceptedTerms = value!),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4A5568),
                          ),
                          children: [
                            const TextSpan(text: 'I accept the '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: const TextStyle(
                                color: Color(0xFF6B4CE6),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: _termsRecognizer,
                            ),
                            const TextSpan(text: ' *'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Privacy Policy Checkbox
                    _buildCheckbox(
                      value: _acceptedPrivacy,
                      onChanged: (value) => setState(() => _acceptedPrivacy = value!),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4A5568),
                          ),
                          children: [
                            const TextSpan(text: 'I accept the '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: Color(0xFF6B4CE6),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: _privacyRecognizer,
                            ),
                            const TextSpan(text: ' *'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Newsletter Checkbox
                    _buildCheckbox(
                      value: _newsletterOptIn,
                      onChanged: (value) => setState(() => _newsletterOptIn = value!),
                      child: const Text(
                        'Send me updates and promotional offers',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Register Button
                    GradientAuthButton(
                      text: 'Create Account',
                      onPressed: _handleRegister,
                      isLoading: _isLoading,
                      icon: Icons.person_add_rounded,
                    ),
                    const SizedBox(height: 24),

                    // Login Link
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(OwnerRoutes.login),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  color: const Color(0xFF4A5568),
                                ),
                            children: const [
                              TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Login',
                                style: TextStyle(
                                  color: Color(0xFF6B4CE6),
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
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final color = _passwordStrength == PasswordStrength.weak
        ? const Color(0xFFEF4444) // Red
        : _passwordStrength == PasswordStrength.medium
            ? const Color(0xFFF97316) // Orange
            : const Color(0xFF10B981); // Green

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha((0.08 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withAlpha((0.2 * 255).toInt()),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _passwordStrength == PasswordStrength.weak
                        ? 0.33
                        : _passwordStrength == PasswordStrength.medium
                            ? 0.66
                            : 1.0,
                    backgroundColor: Colors.grey.shade300,
                    color: color,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _passwordStrength == PasswordStrength.weak
                    ? 'Weak'
                    : _passwordStrength == PasswordStrength.medium
                        ? 'Medium'
                        : 'Strong',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (_missingRequirements.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...(_missingRequirements.map((req) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.close, size: 13, color: color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          req,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 20,
          width: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            activeColor: const Color(0xFF6B4CE6),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(top: 1),
          child: child,
        )),
      ],
    );
  }
}
