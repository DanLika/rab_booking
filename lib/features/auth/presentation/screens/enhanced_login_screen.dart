import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router_owner.dart';
import '../../../../core/constants/auth_feature_flags.dart';
import '../../../../core/constants/breakpoints.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
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
    with AndroidKeyboardDismissFixApproach1<EnhancedLoginScreen>, SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _passwordErrorFromServer;
  String? _emailErrorFromServer;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Shake animation controller
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_clearServerError);
    _emailController.addListener(_clearServerError);

    // Initialize shake animation
    _shakeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));

    // Auto-fill saved credentials if "Remember Me" was enabled
    _loadSavedCredentials();
  }

  /// Load saved email from secure storage
  /// SECURITY FIX SF-007: Only loads email, not password
  Future<void> _loadSavedCredentials() async {
    try {
      final email = await SecureStorageService().getEmail();
      if (email != null && mounted) {
        setState(() {
          _emailController.text = email;
          // SF-007: Password is no longer stored/loaded
          _rememberMe = true;
        });
      }
    } catch (e) {
      // Silently fail - secure storage might not be available
      debugPrint('[LOGIN_SCREEN] Failed to load saved email: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// Trigger shake animation on validation error
  void _shakeForm() {
    _shakeController.reset();
    _shakeController.forward().then((_) => _shakeController.reverse());
  }

  void _clearServerError() {
    if (_passwordErrorFromServer != null || _emailErrorFromServer != null) {
      setState(() {
        _passwordErrorFromServer = null;
        _emailErrorFromServer = null;
      });
    }
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      _shakeForm(); // Shake animation on validation error
      ErrorDisplayUtils.showErrorSnackBar(context, l10n.pleaseFixErrors, duration: const Duration(seconds: 10));
      return;
    }

    // Store credentials before async operation (in case fields get cleared)
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(enhancedAuthProvider.notifier)
          .signInWithEmail(email: email, password: password, rememberMe: _rememberMe);

      if (!mounted) return;

      // Give auth state a moment to fully update after sign in
      await Future.delayed(const Duration(milliseconds: 100));

      final authState = ref.read(enhancedAuthProvider);

      debugPrint(
        '[LOGIN_SCREEN] After signIn - isAuthenticated: ${authState.isAuthenticated}, error: ${authState.error}, requiresEmailVerification: ${authState.requiresEmailVerification}',
      );

      if (authState.error != null) {
        if (!mounted) return;
        debugPrint('[LOGIN_SCREEN] Auth state has error, showing snackbar');

        final errorMsg = authState.error!;
        final isPassError = _isPasswordError(errorMsg);
        final isEmailErr = _isEmailError(errorMsg);

        setState(() {
          _isLoading = false;
          _autovalidateMode = AutovalidateMode.onUserInteraction;
          if (isPassError) {
            _passwordErrorFromServer = _getLocalizedError(errorMsg, l10n);
          } else if (isEmailErr) {
            _emailErrorFromServer = _getLocalizedError(errorMsg, l10n);
          }
        });

        _shakeForm();

        // Force form validation to show inline errors
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _formKey.currentState != null) {
            _formKey.currentState!.validate();
          }
        });

        ErrorDisplayUtils.showErrorSnackBar(
          context,
          _getLocalizedError(errorMsg, l10n),
          duration: const Duration(seconds: 10),
        );
        return;
      }

      if (authState.requiresEmailVerification) {
        if (!mounted) return;
        debugPrint('[LOGIN_SCREEN] Email verification required, redirecting');
        // Keep loader visible during navigation (widget will dispose naturally)
        context.go(OwnerRoutes.emailVerification);
        return;
      }

      // User is authenticated - redirect immediately to dashboard
      if (!mounted) return;

      // Keep loader visible during navigation to dashboard
      // (will be disposed when widget unmounts)
      debugPrint('[LOGIN_SCREEN] Login successful, navigating to dashboard');
      if (mounted) {
        context.go(OwnerRoutes.overview);
      }
    } catch (e) {
      debugPrint('[LOGIN_SCREEN] Caught exception: ${e.runtimeType} = $e');
      if (!mounted) return;

      // Give auth state a moment to update after error
      await Future.delayed(const Duration(milliseconds: 100));

      // Get error message from exception (prefer thrown message over state)
      // When a string is thrown directly, toString() returns the string itself
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint('[LOGIN_SCREEN] Error message after processing: $errorMessage');

      final isPassError = _isPasswordError(errorMessage);
      final isEmailErr = _isEmailError(errorMessage);
      debugPrint('[LOGIN_SCREEN] Is password error: $isPassError, Is email error: $isEmailErr');

      // Set appropriate field error and enable autovalidate mode
      setState(() {
        _isLoading = false;
        _autovalidateMode = AutovalidateMode.onUserInteraction;
        if (isPassError) {
          _passwordErrorFromServer = _getLocalizedError(errorMessage, l10n);
        } else if (isEmailErr) {
          _emailErrorFromServer = _getLocalizedError(errorMessage, l10n);
        }
      });

      // Shake animation on error
      _shakeForm();

      // Force form validation to show inline errors
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _formKey.currentState != null) {
            _formKey.currentState!.validate();
          }
        });
      });

      // ALWAYS show snackbar for visibility - this is the primary user feedback
      // Use longer duration (10 seconds) so user has time to read
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          _getLocalizedError(errorMessage, l10n),
          duration: const Duration(seconds: 10),
        );
      }
    }
  }

  /// Map error messages to localized strings
  String _getLocalizedError(String error, AppLocalizations l10n) {
    final errorLower = error.toLowerCase();

    // Authentication errors - use new auth-specific keys
    if (errorLower.contains('user-not-found') || errorLower.contains('no account found')) {
      return l10n.authErrorUserNotFound;
    }
    if (errorLower.contains('wrong-password') ||
        errorLower.contains('invalid-credential') ||
        errorLower.contains('incorrect password')) {
      return l10n.authErrorWrongPassword;
    }
    if (errorLower.contains('invalid-email') || errorLower.contains('invalid email')) {
      return l10n.authErrorInvalidEmail;
    }
    if (errorLower.contains('user-disabled') || errorLower.contains('account has been disabled')) {
      return l10n.authErrorUserDisabled;
    }
    if (errorLower.contains('too-many-requests') || errorLower.contains('too many')) {
      return l10n.authErrorTooManyRequests;
    }
    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return l10n.errorNetworkFailed;
    }
    if (errorLower.contains('permission-denied') || errorLower.contains('permission denied')) {
      return l10n.errorPermissionDenied;
    }
    if (errorLower.contains('not-found') || errorLower.contains('not found')) {
      return l10n.errorNotFound;
    }
    if (errorLower.contains('timeout')) {
      return l10n.errorTimeout;
    }
    if (errorLower.contains('already exists') || errorLower.contains('email-already-in-use')) {
      return l10n.errorEmailInUse;
    }

    // Fallback to generic auth error for unmapped errors
    return l10n.authErrorGeneric;
  }

  bool _isPasswordError(String message) {
    const passwordErrorPatterns = ['Incorrect password', 'Invalid password', 'wrong-password', 'invalid-credential'];
    return passwordErrorPatterns.any(message.contains);
  }

  bool _isEmailError(String message) {
    const emailErrorPatterns = ['user-not-found', 'No account found', 'invalid-email', 'Invalid email'];
    return emailErrorPatterns.any(message.contains);
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

    // PRISTUP 1: resizeToAvoidBottomInset: true - klasičan Flutter pristup
    return KeyedSubtree(
      key: ValueKey('login_screen_$keyboardFixRebuildKey'),
      child: Scaffold(
        resizeToAvoidBottomInset: true, // PRISTUP 1: Omogući automatsko prilagođavanje
        body: Stack(
          alignment: Alignment.topLeft, // Explicit to avoid TextDirection null check
          children: [
            AuthBackground(
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Get keyboard height to adjust padding dynamically (with null safety)
                    final mediaQuery = MediaQuery.maybeOf(context);
                    final keyboardHeight = (mediaQuery?.viewInsets.bottom ?? 0.0).clamp(0.0, double.infinity);
                    final isKeyboardOpen = keyboardHeight > 0;

                    // Calculate minHeight safely - ensure it's always finite and valid
                    double minHeight;
                    if (isKeyboardOpen && constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
                      final calculated = constraints.maxHeight - keyboardHeight;
                      minHeight = calculated.clamp(0.0, constraints.maxHeight);
                    } else {
                      minHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0;
                    }
                    // Ensure minHeight is always finite (never infinity)
                    minHeight = minHeight.isFinite ? minHeight : 0.0;

                    return SingleChildScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                              autovalidateMode: _autovalidateMode,
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
                                  AnimatedBuilder(
                                    animation: _shakeAnimation,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(_shakeAnimation.value, 0),
                                        child: child,
                                      );
                                    },
                                    child: GradientAuthButton(
                                      text: l10n.login,
                                      onPressed: _handleLogin,
                                      isLoading: _isLoading,
                                      icon: Icons.login_rounded,
                                    ),
                                  ),
                                  if (AuthFeatureFlags.isGoogleSignInEnabled ||
                                      AuthFeatureFlags.isAppleSignInEnabled) ...[
                                    SizedBox(height: isCompact ? 16 : 20),
                                    _buildDivider(theme, l10n),
                                    SizedBox(height: isCompact ? 16 : 20),
                                    _buildSocialButtons(),
                                  ],
                                  SizedBox(height: isCompact ? 20 : 24),
                                  _buildRegisterLink(theme, l10n),
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
          child: AuthLogoIcon(size: isCompact ? 70 : 80, isWhite: theme.brightness == Brightness.dark),
        ),
        SizedBox(height: isCompact ? 16 : 20),
        Text(
          l10n.authOwnerLogin,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: isCompact ? 22 : 26),
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
      validator: (value) {
        // Show server error if present (e.g., "No account found with this email")
        if (_emailErrorFromServer != null) {
          return _emailErrorFromServer;
        }
        return ProfileValidators.validateEmail(value);
      },
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
        onPressed: () {
          // SF-013: Add haptic feedback for better UX on mobile
          HapticFeedback.mediumImpact();
          setState(() => _obscurePassword = !_obscurePassword);
        },
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    activeColor: theme.colorScheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Text(l10n.authRememberMe, style: theme.textTheme.bodySmall?.copyWith(fontSize: 13)),
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
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: theme.colorScheme.outline)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    final authNotifier = ref.read(enhancedAuthProvider.notifier);
    final isAppleEnabled = AuthFeatureFlags.isAppleSignInEnabled;
    final isGoogleEnabled = AuthFeatureFlags.isGoogleSignInEnabled;

    // Hide entire section if no social logins are enabled
    if (!isGoogleEnabled && !isAppleEnabled) {
      return const SizedBox.shrink();
    }

    // If only one provider is enabled, show it full width
    if (isGoogleEnabled && !isAppleEnabled) {
      return SocialLoginButton(
        customIcon: const GoogleBrandIcon(),
        label: 'Google',
        onPressed: () => _handleOAuthSignIn(authNotifier.signInWithGoogle),
      );
    }

    if (!isGoogleEnabled && isAppleEnabled) {
      return SocialLoginButton(
        customIcon: const AppleBrandIcon(),
        label: 'Apple',
        onPressed: () => _handleOAuthSignIn(authNotifier.signInWithApple),
      );
    }

    // Both enabled - show side by side
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
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12)),
        child: RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            children: [
              TextSpan(text: '${l10n.authNoAccount} '),
              TextSpan(
                text: l10n.authCreateAccount,
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
