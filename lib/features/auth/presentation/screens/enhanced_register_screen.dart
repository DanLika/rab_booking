import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router_owner.dart';
import '../../../../core/constants/breakpoints.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../shared/utils/validators/input_sanitizer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../widgets/auth_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_auth_button.dart';
import '../widgets/premium_input_field.dart';
import '../widgets/profile_image_picker.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

/// Enhanced Registration Screen with Premium Design
///
/// Uses [AndroidKeyboardDismissFixApproach1] mixin to handle the Android Chrome
/// keyboard dismiss bug (Flutter issue #175074).
class EnhancedRegisterScreen extends ConsumerStatefulWidget {
  const EnhancedRegisterScreen({super.key});

  @override
  ConsumerState<EnhancedRegisterScreen> createState() =>
      _EnhancedRegisterScreenState();
}

class _EnhancedRegisterScreenState extends ConsumerState<EnhancedRegisterScreen>
    with AndroidKeyboardDismissFixApproach1<EnhancedRegisterScreen> {
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
  String? _emailErrorFromServer;

  Uint8List? _profileImageBytes;
  String? _profileImageName;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearServerError);
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

  void _clearServerError() {
    if (_emailErrorFromServer != null) {
      setState(() => _emailErrorFromServer = null);
    }
  }

  Future<void> _handleRegister() async {
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      ErrorDisplayUtils.showErrorSnackBar(context, l10n.pleaseFixErrors);
      return;
    }

    if (!_acceptedTerms || !_acceptedPrivacy) {
      ErrorDisplayUtils.showErrorSnackBar(context, l10n.authMustAcceptTerms);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final (firstName, lastName) = _parseFullName(_fullNameController.text);

      // SECURITY: Sanitize all inputs before sending to backend
      final sanitizedEmail =
          InputSanitizer.sanitizeEmail(_emailController.text.trim()) ??
          _emailController.text.trim();
      final sanitizedFirstName =
          InputSanitizer.sanitizeName(firstName) ?? firstName;
      final sanitizedLastName =
          InputSanitizer.sanitizeName(lastName) ?? lastName;
      final sanitizedPhone = _phoneController.text.trim().isNotEmpty
          ? (InputSanitizer.sanitizePhone(_phoneController.text.trim()) ??
                _phoneController.text.trim())
          : null;

      await ref
          .read(enhancedAuthProvider.notifier)
          .registerWithEmail(
            email: sanitizedEmail,
            password: _passwordController
                .text, // Password doesn't need sanitization (Firebase Auth handles it)
            firstName: sanitizedFirstName,
            lastName: sanitizedLastName,
            phone: sanitizedPhone,
            acceptedTerms: _acceptedTerms,
            acceptedPrivacy: _acceptedPrivacy,
            newsletterOptIn: _newsletterOptIn,
            profileImageBytes: _profileImageBytes,
            profileImageName: _profileImageName,
          );

      if (!mounted) return;

      final authState = ref.read(enhancedAuthProvider);

      if (authState.error != null) {
        setState(() => _isLoading = false);
        ErrorDisplayUtils.showErrorSnackBar(context, authState.error);
        return;
      }

      if (authState.requiresEmailVerification) {
        // Keep loader visible during navigation (widget will dispose naturally)
        context.go(OwnerRoutes.emailVerification);
        return;
      }

      // Registration successful without email verification - navigate to dashboard
      // Keep loader visible during navigation (widget will dispose naturally)
      context.go(OwnerRoutes.overview);
    } catch (e) {
      if (!mounted) return;

      final authState = ref.read(enhancedAuthProvider);
      final errorMessage = authState.error ?? e.toString();

      if (_isEmailError(errorMessage)) {
        setState(() {
          _emailErrorFromServer =
              errorMessage.contains('already exists') ||
                  errorMessage.contains('email-already-in-use')
              ? l10n.errorEmailInUse
              : l10n.authErrorInvalidEmail;
          _isLoading = false;
        });
        _formKey.currentState!.validate();
      } else {
        setState(() => _isLoading = false);
        ErrorDisplayUtils.showErrorSnackBar(context, errorMessage);
      }
    }
  }

  (String, String) _parseFullName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    return (firstName, lastName);
  }

  bool _isEmailError(String message) {
    const emailErrorPatterns = [
      'already exists',
      'email-already-in-use',
      'Invalid email',
    ];
    return emailErrorPatterns.any(message.contains);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isCompact = Breakpoints.isCompactMobile(context);

    // Isti pristup kao Login: resizeToAvoidBottomInset: true
    return KeyedSubtree(
      key: ValueKey('register_screen_$keyboardFixRebuildKey'),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          alignment:
              Alignment.topLeft, // Explicit to avoid TextDirection null check
          children: [
            AuthBackground(
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Get keyboard height to adjust padding dynamically (with null safety)
                    final mediaQuery = MediaQuery.maybeOf(context);
                    final keyboardHeight =
                        (mediaQuery?.viewInsets.bottom ?? 0.0).clamp(
                          0.0,
                          double.infinity,
                        );
                    final isKeyboardOpen = keyboardHeight > 0;

                    // Calculate minHeight safely - ensure it's always finite and valid
                    double minHeight;
                    if (isKeyboardOpen &&
                        constraints.maxHeight.isFinite &&
                        constraints.maxHeight > 0) {
                      final calculated = constraints.maxHeight - keyboardHeight;
                      minHeight = calculated.clamp(0.0, constraints.maxHeight);
                    } else {
                      minHeight = constraints.maxHeight.isFinite
                          ? constraints.maxHeight
                          : 0.0;
                    }
                    // Ensure minHeight is always finite (never infinity)
                    minHeight = minHeight.isFinite ? minHeight : 0.0;

                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(
                        left: isCompact ? 12 : 20,
                        right: isCompact ? 12 : 20,
                        top: isCompact ? 16 : 20,
                        bottom: isCompact ? 16 : 20,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minHeight),
                        child: Center(
                          child: GlassCard(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildHeader(theme, l10n, isCompact),
                                  SizedBox(height: isCompact ? 20 : 24),
                                  _buildFormFields(theme, l10n, isCompact),
                                  SizedBox(height: isCompact ? 12 : 14),
                                  _buildCheckboxes(theme, l10n),
                                  SizedBox(height: isCompact ? 20 : 24),
                                  GradientAuthButton(
                                    text: l10n.authCreateAccount,
                                    onPressed: _handleRegister,
                                    isLoading: _isLoading,
                                    icon: Icons.person_add_rounded,
                                  ),
                                  SizedBox(height: isCompact ? 16 : 20),
                                  _buildLoginLink(theme, l10n),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_isLoading)
              const LoadingOverlay(message: 'Creating your account...'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations l10n, bool isCompact) {
    return Column(
      children: [
        ProfileImagePicker(
          size: isCompact ? 80 : 90,
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
        SizedBox(height: isCompact ? 16 : 20),
        Text(
          l10n.authCreateAccount,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isCompact ? 22 : 26,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.authStartManaging,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: isCompact ? 13 : 14,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFormFields(
    ThemeData theme,
    AppLocalizations l10n,
    bool isCompact,
  ) {
    final fieldSpacing = SizedBox(height: isCompact ? 12 : 14);

    return Column(
      children: [
        PremiumInputField(
          controller: _fullNameController,
          labelText: l10n.authFullName,
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.authEnterFullName;
            }
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
        fieldSpacing,
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
        fieldSpacing,
        PremiumInputField(
          controller: _phoneController,
          labelText: l10n.authPhone,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: ProfileValidators.validatePhone,
        ),
        fieldSpacing,
        PremiumInputField(
          controller: _passwordController,
          labelText: l10n.password,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          // UX-019: Add tooltip for accessibility (screen readers)
          suffixIcon: Tooltip(
            message: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
            child: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          validator: (value) =>
              PasswordValidator.validateMinimumLength(value, l10n),
        ),
        fieldSpacing,
        PremiumInputField(
          controller: _confirmPasswordController,
          labelText: l10n.authConfirmPassword,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          // UX-019: Add tooltip for accessibility (screen readers)
          suffixIcon: Tooltip(
            message: _obscureConfirmPassword
                ? l10n.showPassword
                : l10n.hidePassword,
            child: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                );
              },
            ),
          ),
          validator: (value) => PasswordValidator.validateConfirmPassword(
            _passwordController.text,
            value,
            l10n,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxes(ThemeData theme, AppLocalizations l10n) {
    return Column(
      children: [
        _buildLegalCheckbox(
          value: _acceptedTerms,
          onChanged: (value) => setState(() => _acceptedTerms = value!),
          linkText: l10n.authTermsConditions,
          prefixText: l10n.authAcceptTerms,
          onLinkTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
          ),
          theme: theme,
        ),
        const SizedBox(height: 6),
        _buildLegalCheckbox(
          value: _acceptedPrivacy,
          onChanged: (value) => setState(() => _acceptedPrivacy = value!),
          linkText: l10n.authPrivacyPolicy,
          prefixText: l10n.authAcceptTerms,
          onLinkTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
          ),
          theme: theme,
        ),
        const SizedBox(height: 6),
        _buildCheckboxRow(
          value: _newsletterOptIn,
          onChanged: (value) => setState(() => _newsletterOptIn = value!),
          child: Text(
            l10n.authNewsletterOptIn,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildLegalCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String linkText,
    required String prefixText,
    required VoidCallback onLinkTap,
    required ThemeData theme,
  }) {
    return _buildCheckboxRow(
      value: value,
      onChanged: onChanged,
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          children: [
            TextSpan(text: prefixText),
            TextSpan(
              text: linkText,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()..onTap = onLinkTap,
            ),
            const TextSpan(text: ' *'),
          ],
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      theme: theme,
    );
  }

  Widget _buildCheckboxRow({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget child,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 22,
          width: 22,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
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

  Widget _buildLoginLink(ThemeData theme, AppLocalizations l10n) {
    return Center(
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
    );
  }
}
