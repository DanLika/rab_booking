import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router_owner.dart';
import '../../../../core/constants/breakpoints.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/keyboard_dismiss_fix_mixin.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_logo_icon.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_auth_button.dart';
import '../widgets/premium_input_field.dart';
import '../widgets/social_login_button.dart';

/// Enhanced Login Screen with Premium Design
///
/// Uses [AndroidKeyboardDismissFix] mixin to handle the Android Chrome
/// keyboard dismiss bug (Flutter issue #175074).
class EnhancedLoginScreen extends ConsumerStatefulWidget {
  const EnhancedLoginScreen({super.key});

  @override
  ConsumerState<EnhancedLoginScreen> createState() => _EnhancedLoginScreenState();
}

class _EnhancedLoginScreenState extends ConsumerState<EnhancedLoginScreen>
    with AndroidKeyboardDismissFix {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _passwordErrorFromServer;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_clearServerError);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearServerError() {
    if (_passwordErrorFromServer != null) {
      setState(() => _passwordErrorFromServer = null);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      ErrorDisplayUtils.showErrorSnackBar(context, 'Please fix the errors above');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(enhancedAuthProvider.notifier).signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      final authState = ref.read(enhancedAuthProvider);

      if (authState.error != null) {
        setState(() => _isLoading = false);
        ErrorDisplayUtils.showErrorSnackBar(context, authState.error);
        return;
      }

      if (authState.requiresEmailVerification) {
        setState(() => _isLoading = false);
        context.go(OwnerRoutes.emailVerification);
        return;
      }

      setState(() => _isLoading = false);
      ErrorDisplayUtils.showSuccessSnackBar(
        context,
        'Welcome back, ${authState.userModel?.firstName ?? "User"}!',
      );
    } catch (e) {
      if (!mounted) return;

      final authState = ref.read(enhancedAuthProvider);
      final errorMessage = authState.error ?? e.toString();

      if (_isPasswordError(errorMessage)) {
        setState(() {
          _passwordErrorFromServer = 'Incorrect password. Try again or reset your password.';
          _isLoading = false;
        });
        _formKey.currentState!.validate();
      } else {
        setState(() => _isLoading = false);
        ErrorDisplayUtils.showErrorSnackBar(context, errorMessage);
      }
    }
  }

  bool _isPasswordError(String message) {
    const passwordErrorPatterns = [
      'Incorrect password',
      'Invalid password',
      'wrong-password',
      'invalid-credential',
    ];
    return passwordErrorPatterns.any(message.contains);
  }

  Future<void> _handleOAuthSignIn(Future<void> Function() signInMethod) async {
    setState(() => _isLoading = true);

    try {
      await signInMethod();
    } catch (e) {
      if (!mounted) return;
      final authState = ref.read(enhancedAuthProvider);
      ErrorDisplayUtils.showErrorSnackBar(context, authState.error ?? e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isCompact = Breakpoints.isCompactMobile(context);

    return KeyedSubtree(
      key: ValueKey('login_screen_$keyboardFixRebuildKey'),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            AuthBackground(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 12 : 20,
                        vertical: isCompact ? 16 : 20,
                      ),
                      child: GlassCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(theme, l10n, isCompact),
                              SizedBox(height: isCompact ? 24 : 32),
                              _buildEmailField(l10n),
                              SizedBox(height: isCompact ? 12 : 14),
                              _buildPasswordField(theme, l10n),
                              SizedBox(height: isCompact ? 12 : 14),
                              _buildRememberMeRow(theme, l10n),
                              SizedBox(height: isCompact ? 20 : 24),
                              GradientAuthButton(
                                text: l10n.login,
                                onPressed: _handleLogin,
                                isLoading: _isLoading,
                                icon: Icons.login_rounded,
                              ),
                              SizedBox(height: isCompact ? 16 : 20),
                              _buildDivider(theme, l10n),
                              SizedBox(height: isCompact ? 16 : 20),
                              _buildSocialButtons(),
                              SizedBox(height: isCompact ? 20 : 24),
                              _buildRegisterLink(theme, l10n),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading) const LoadingOverlay(message: 'Signing in...'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations l10n, bool isCompact) {
    return Column(
      children: [
        Center(
          child: AuthLogoIcon(
            size: isCompact ? 70 : 80,
            isWhite: theme.brightness == Brightness.dark,
          ),
        ),
        SizedBox(height: isCompact ? 16 : 20),
        Text(
          l10n.authOwnerLogin,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isCompact ? 22 : 26,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.authManageProperties,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: isCompact ? 13 : 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField(AppLocalizations l10n) {
    return PremiumInputField(
      controller: _emailController,
      labelText: l10n.email,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: ProfileValidators.validateEmail,
    );
  }

  Widget _buildPasswordField(ThemeData theme, AppLocalizations l10n) {
    return PremiumInputField(
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
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
      validator: (value) {
        if (_passwordErrorFromServer != null) {
          return _passwordErrorFromServer;
        }
        return PasswordValidator.validateMinimumLength(value);
      },
    );
  }

  Widget _buildRememberMeRow(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _rememberMe = !_rememberMe),
            child: Row(
              children: [
                SizedBox(
                  height: 22,
                  width: 22,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (value) => setState(() => _rememberMe = value!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    activeColor: theme.colorScheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.authRememberMe,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: () => context.push(OwnerRoutes.forgotPassword),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.authForgotPassword,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(child: Divider(color: theme.colorScheme.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l10n.authOrContinueWith,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Divider(color: theme.colorScheme.outline)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    final authNotifier = ref.read(enhancedAuthProvider.notifier);

    return Row(
      children: [
        Expanded(
          child: SocialLoginButton(
            customIcon: const GoogleBrandIcon(),
            label: 'Google',
            onPressed: () => _handleOAuthSignIn(authNotifier.signInWithGoogle),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SocialLoginButton(
            customIcon: const AppleBrandIcon(),
            label: 'Apple',
            onPressed: () => _handleOAuthSignIn(authNotifier.signInWithApple),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: TextButton(
        onPressed: () => context.go(OwnerRoutes.register),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        ),
        child: RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            children: [
              TextSpan(text: '${l10n.authNoAccount} '),
              TextSpan(
                text: l10n.authCreateAccount,
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
