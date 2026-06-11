import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router_owner.dart';
import '../../../../core/constants/auth_feature_flags.dart';
import '../../../../core/constants/breakpoints.dart';
import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../../../shared/widgets/universal_loader.dart';
import '../widgets/social_login_button.dart';

/// Enhanced Login Screen — refactored onto Bb* redesign primitives (Phase 2).
///
/// Visual layer rebuilt with [BbLogo], [BbInput], [BbButton] + glass card on
/// hero-gradient (intentional hero exception per `design_handoff/README.md`).
///
/// FROZEN / preserved logic:
///  - `firebase_auth.signInWithEmailAndPassword` via enhancedAuthProvider
///  - Email-verification gate routing
///  - SecureStorageService Remember Me
///  - Programmatic shake AnimationController (per .claude/rules/ui-ux.md)
///  - Form-key validation (BbInput's native `validator:` — Phase 1.1 PR #616)
///  - AndroidKeyboardDismissFixApproach1 mixin (per .claude/rules/keyboard-fix.md)
class EnhancedLoginScreen extends ConsumerStatefulWidget {
  const EnhancedLoginScreen({super.key});

  @override
  ConsumerState<EnhancedLoginScreen> createState() =>
      _EnhancedLoginScreenState();
}

class _EnhancedLoginScreenState extends ConsumerState<EnhancedLoginScreen>
    with
        AndroidKeyboardDismissFixApproach1<EnhancedLoginScreen>,
        SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _passwordErrorFromServer;
  String? _emailErrorFromServer;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Shake animation controller (per .claude/rules/ui-ux.md — stays on AnimationController)
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_clearServerError);
    _emailController.addListener(_clearServerError);

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _loadSavedCredentials();
  }

  /// Load saved email from secure storage.
  /// SECURITY FIX SF-007: Only loads email, not password.
  Future<void> _loadSavedCredentials() async {
    try {
      final email = await SecureStorageService().getEmail();
      if (email != null && mounted) {
        setState(() {
          _emailController.text = email;
          _rememberMe = true;
        });
      }
    } catch (e) {
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
      _shakeForm();
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        l10n.pleaseFixErrors,
        duration: const Duration(seconds: 10),
      );
      return;
    }

    // Store credentials before async operation (in case fields get cleared).
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(enhancedAuthProvider.notifier)
          .signInWithEmail(
            email: email,
            password: password,
            rememberMe: _rememberMe,
          );

      if (!mounted) return;

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
        context.go(OwnerRoutes.emailVerification);
        return;
      }

      if (!mounted) return;

      debugPrint('[LOGIN_SCREEN] Login successful, navigating to dashboard');
      if (mounted) {
        context.go(OwnerRoutes.overview);
      }
    } catch (e) {
      debugPrint('[LOGIN_SCREEN] Caught exception: ${e.runtimeType} = $e');
      if (!mounted) return;

      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint(
        '[LOGIN_SCREEN] Error message after processing: $errorMessage',
      );

      final localizedError = _getLocalizedError(errorMessage, l10n);
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        localizedError,
        duration: const Duration(seconds: 10),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      final isPassError = _isPasswordError(errorMessage);
      final isEmailErr = _isEmailError(errorMessage);
      debugPrint(
        '[LOGIN_SCREEN] Is password error: $isPassError, Is email error: $isEmailErr',
      );

      setState(() {
        _isLoading = false;
        _autovalidateMode = AutovalidateMode.onUserInteraction;
        if (isPassError) {
          _passwordErrorFromServer = localizedError;
        } else if (isEmailErr) {
          _emailErrorFromServer = localizedError;
        }
      });

      _shakeForm();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _formKey.currentState != null) {
            _formKey.currentState!.validate();
          }
        });
      });
    }
  }

  /// Map error messages to localized strings.
  String _getLocalizedError(String error, AppLocalizations l10n) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('user-not-found') ||
        errorLower.contains('no account found')) {
      return l10n.authErrorUserNotFound;
    }
    if (errorLower.contains('wrong-password') ||
        errorLower.contains('invalid-credential') ||
        errorLower.contains('incorrect password')) {
      return l10n.authErrorWrongPassword;
    }
    if (errorLower.contains('invalid-email') ||
        errorLower.contains('invalid email')) {
      return l10n.authErrorInvalidEmail;
    }
    if (errorLower.contains('user-disabled') ||
        errorLower.contains('account has been disabled')) {
      return l10n.authErrorUserDisabled;
    }
    if (error.startsWith('RATE_LIMIT_LOCKOUT:')) {
      final secondsStr = error.split(':')[1];
      final seconds = int.tryParse(secondsStr) ?? 60;
      return l10n.authErrorRateLimitWait(seconds);
    }
    if (errorLower.contains('too-many-requests') ||
        errorLower.contains('too many')) {
      return l10n.authErrorTooManyRequests;
    }
    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return l10n.errorNetworkFailed;
    }
    if (errorLower.contains('permission-denied') ||
        errorLower.contains('permission denied')) {
      return l10n.errorPermissionDenied;
    }
    if (errorLower.contains('not-found') || errorLower.contains('not found')) {
      return l10n.errorNotFound;
    }
    if (errorLower.contains('timeout')) {
      return l10n.errorTimeout;
    }
    if (errorLower.contains('already exists') ||
        errorLower.contains('email-already-in-use')) {
      return l10n.errorEmailInUse;
    }

    return l10n.authErrorGeneric;
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

  bool _isEmailError(String message) {
    const emailErrorPatterns = [
      'user-not-found',
      'No account found',
      'invalid-email',
      'Invalid email',
    ];
    return emailErrorPatterns.any(message.contains);
  }

  Future<void> _handleOAuthSignIn(Future<void> Function() signInMethod) async {
    setState(() => _isLoading = true);

    try {
      await signInMethod();
    } catch (e) {
      if (!mounted) return;
      final authState = ref.read(enhancedAuthProvider);
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        authState.error ?? e.toString(),
      );
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
    final rd = BbRedesignTokens.of(context);
    final c = BBColor.of(context);
    final isCompact = Breakpoints.isCompactMobile(context);
    final isSmallHeight = MediaQuery.of(context).size.height < 700;

    // PRISTUP 1 (keyboard-fix.md): resizeToAvoidBottomInset: true + mixin
    return KeyedSubtree(
      key: ValueKey('login_screen_$keyboardFixRebuildKey'),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          alignment: Alignment.topLeft,
          children: [
            // Soft auth backdrop (`BbRedesignTokens.softBg`) — pale lavender
            // wash per `design_handoff/screens/15-owner.png`. Was previously
            // `rd.heroGradient` (saturated brand purple); swapped per Phase 1.2
            // (#615) review feedback.
            Container(
              decoration: BoxDecoration(gradient: rd.softBg),
              child: SafeArea(
                child: LayoutBuilder(
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
                      final calculated = constraints.maxHeight - keyboardHeight;
                      minHeight = calculated.clamp(0.0, constraints.maxHeight);
                    } else {
                      minHeight = constraints.maxHeight.isFinite
                          ? constraints.maxHeight
                          : 0.0;
                    }
                    minHeight = minHeight.isFinite ? minHeight : 0.0;

                    return GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact
                              ? (MediaQuery.of(context).size.width < 340
                                    ? 8
                                    : 12)
                              : 20,
                          vertical: isSmallHeight ? 12 : (isCompact ? 16 : 20),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: minHeight),
                          // Handoff auth.jsx desktop split (≥1200): brand
                          // pitch panel left, 560px login card right.
                          // Narrower widths keep the centered card.
                          child: constraints.maxWidth >= 1200
                              // No stretch: the scroll view gives unbounded
                              // height, so the pitch panel pins its own
                              // viewport height and the card centers on it.
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: _LoginPitchPanel(
                                        viewportHeight: minHeight,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 560,
                                      child: Center(
                                        child: _buildGlassCard(
                                          context,
                                          theme,
                                          rd,
                                          c,
                                          l10n,
                                          isCompact,
                                          isSmallHeight,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Center(
                                  child: _buildGlassCard(
                                    context,
                                    theme,
                                    rd,
                                    c,
                                    l10n,
                                    isCompact,
                                    isSmallHeight,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_isLoading) UniversalLoader.forAuth(message: l10n.loading),
          ],
        ),
      ),
    );
  }

  /// Glass card surface (BackdropFilter + glassBg/glassBorder tokens).
  Widget _buildGlassCard(
    BuildContext context,
    ThemeData theme,
    BbRedesignTokens rd,
    BBColorSet c,
    AppLocalizations l10n,
    bool isCompact,
    bool isSmallHeight,
  ) {
    final cardPadding = isSmallHeight
        ? const EdgeInsets.all(BBSpace.sm)
        : EdgeInsets.all(isCompact ? BBSpace.md : 36);

    final card = ClipRRect(
      borderRadius: BBRadius.lgAll,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: rd.glassBg,
            border: Border.all(color: rd.glassBorder),
            borderRadius: BBRadius.lgAll,
            boxShadow: rd.panelShadow,
          ),
          padding: cardPadding,
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(theme, c, l10n, isCompact, isSmallHeight),
                SizedBox(height: isSmallHeight ? 16 : (isCompact ? 24 : 28)),
                _buildEmailField(l10n),
                SizedBox(height: isSmallHeight ? 10 : (isCompact ? 12 : 14)),
                _buildPasswordField(theme, c, l10n),
                SizedBox(height: isSmallHeight ? 10 : (isCompact ? 12 : 16)),
                _buildRememberMeRow(theme, c, l10n),
                SizedBox(height: isSmallHeight ? 16 : (isCompact ? 20 : 24)),
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: child,
                    );
                  },
                  child: BbButton(
                    key: const ValueKey('login_submit'),
                    label: l10n.login,
                    iconLeft: 'login',
                    size: BbButtonSize.lg,
                    fullWidth: true,
                    loading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                ),
                if (AuthFeatureFlags.isGoogleSignInEnabled ||
                    AuthFeatureFlags.isAppleSignInEnabled) ...[
                  SizedBox(height: isSmallHeight ? 16 : (isCompact ? 20 : 24)),
                  _buildDivider(theme, c, l10n),
                  SizedBox(height: isSmallHeight ? 12 : (isCompact ? 16 : 16)),
                  _buildSocialButtons(l10n),
                ],
                SizedBox(height: isSmallHeight ? 16 : (isCompact ? 20 : 24)),
                _buildRegisterLink(theme, c, l10n),
              ],
            ),
          ),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: card,
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    BBColorSet c,
    AppLocalizations l10n,
    bool isCompact,
    bool isSmallHeight,
  ) {
    final logoSize = isSmallHeight ? 56.0 : (isCompact ? 60.0 : 64.0);
    return Column(
      children: [
        Center(child: BbLogo(size: logoSize, useGradient: false)),
        SizedBox(height: isSmallHeight ? 12 : (isCompact ? 14 : 16)),
        Text(
          l10n.authOwnerLogin,
          style: BBType.h1(context).copyWith(color: c.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.authManageProperties,
          style: BBType.body(context).copyWith(color: c.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Email field — uses BbInput's native `validator:` (Phase 1.1 PR #616)
  /// so `_formKey.validate()` triggers through BbInput's internal
  /// `FormField<String>` wrap.
  Widget _buildEmailField(AppLocalizations l10n) {
    return BbInput(
      key: const ValueKey('login_email'),
      controller: _emailController,
      label: l10n.email,
      iconLeft: 'mail',
      placeholder: 'ime@primjer.hr',
      size: BbInputSize.lg,
      keyboardType: TextInputType.emailAddress,
      validator: (_) {
        if (_emailErrorFromServer != null) {
          return _emailErrorFromServer;
        }
        return ProfileValidators.validateEmail(_emailController.text);
      },
    );
  }

  Widget _buildPasswordField(
    ThemeData theme,
    BBColorSet c,
    AppLocalizations l10n,
  ) {
    return BbInput(
      key: const ValueKey('login_password'),
      controller: _passwordController,
      label: l10n.password,
      iconLeft: 'lock',
      placeholder: '••••••••',
      size: BbInputSize.lg,
      obscureText: _obscurePassword,
      validator: (_) {
        if (_passwordErrorFromServer != null) {
          return _passwordErrorFromServer;
        }
        return PasswordValidator.validateLoginPassword(
          _passwordController.text,
        );
      },
      trailingAction: Tooltip(
        message: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: c.textTertiary,
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.mediumImpact();
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ),
    );
  }

  Widget _buildRememberMeRow(
    ThemeData theme,
    BBColorSet c,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        Expanded(
          child: MergeSemantics(
            child: InkWell(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) =>
                            setState(() => _rememberMe = value!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        activeColor: c.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.authRememberMe,
                        style: BBType.caption(
                          context,
                        ).copyWith(color: c.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        BbButton(
          label: l10n.authForgotPassword,
          variant: BbButtonVariant.tertiary,
          size: BbButtonSize.sm,
          onPressed: () => context.push(OwnerRoutes.forgotPassword),
        ),
      ],
    );
  }

  Widget _buildDivider(ThemeData theme, BBColorSet c, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(child: Divider(color: c.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l10n.authOrContinueWith,
            style: BBType.caption(context).copyWith(color: c.textTertiary),
          ),
        ),
        Expanded(child: Divider(color: c.border, height: 1)),
      ],
    );
  }

  Widget _buildSocialButtons(AppLocalizations l10n) {
    final authNotifier = ref.read(enhancedAuthProvider.notifier);
    final isAppleEnabled = AuthFeatureFlags.isAppleSignInEnabled;
    final isGoogleEnabled = AuthFeatureFlags.isGoogleSignInEnabled;

    if (!isGoogleEnabled && !isAppleEnabled) {
      return const SizedBox.shrink();
    }

    final googleButton = SocialLoginButton(
      customIcon: const GoogleBrandIcon(),
      label: l10n.signInWithGoogle,
      enabled: !_isLoading,
      onPressed: () => _handleOAuthSignIn(authNotifier.signInWithGoogle),
    );

    final appleButton = SocialLoginButton(
      customIcon: const AppleBrandIcon(),
      label: l10n.signInWithApple,
      enabled: !_isLoading,
      onPressed: () => _handleOAuthSignIn(authNotifier.signInWithApple),
    );

    if (isGoogleEnabled && !isAppleEnabled) {
      return googleButton;
    }

    return Column(
      children: [googleButton, const SizedBox(height: 10), appleButton],
    );
  }

  Widget _buildRegisterLink(
    ThemeData theme,
    BBColorSet c,
    AppLocalizations l10n,
  ) {
    return Center(
      child: TextButton(
        onPressed: _isLoading ? null : () => context.go(OwnerRoutes.register),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        ),
        child: RichText(
          text: TextSpan(
            style: BBType.caption(context).copyWith(
              color: _isLoading
                  ? c.textPrimary.withValues(alpha: 0.4)
                  : c.textSecondary,
            ),
            children: [
              TextSpan(text: '${l10n.authNoAccount} '),
              TextSpan(
                text: l10n.authCreateAccount,
                style: TextStyle(
                  color: _isLoading
                      ? c.primary.withValues(alpha: 0.4)
                      : c.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desktop brand/pitch panel (handoff `auth.jsx` AuthLoginDesktop left side):
/// logo + wordmark top, pitch block with eyebrow/headline/copy/stats in the
/// middle, legal footer at the bottom. Copy is handoff-spec HR marketing.
class _LoginPitchPanel extends StatelessWidget {
  final double viewportHeight;

  const _LoginPitchPanel({required this.viewportHeight});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);

    // The surrounding scroll view has unbounded height — pin the panel to
    // the viewport so spaceBetween can park logo top / footer bottom.
    return SizedBox(
      height: viewportHeight > 0 ? viewportHeight : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(80, 64, 80, 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const BbLogo(size: 40),
                const SizedBox(width: 12),
                Text(
                  'BookBed',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.44,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'OWNER APLIKACIJA',
                    style: BBType.eyebrow(context).copyWith(color: c.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sve vaše rezervacije.\nJedno mjesto.',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.44,
                      height: 1.1,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Booking.com, Airbnb i vlastiti widget — sinkronizirano '
                    'svakih 15 minuta. Bez dvostrukih rezervacija.',
                    style: BBType.bodyLg(
                      context,
                    ).copyWith(color: c.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  const Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      _PitchStat(value: '45+', label: 'aktivnih vlasnika'),
                      _PitchStat(value: '12k', label: 'rezervacija godišnje'),
                      _PitchStat(value: '99.9%', label: 'uptime'),
                    ],
                  ),
                ],
              ),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  '© 2026 BookBed Inc.',
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textTertiary),
                ),
                Text(
                  '·',
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textTertiary),
                ),
                InkWell(
                  onTap: () => context.push(OwnerRoutes.termsConditions),
                  child: Text(
                    'Uvjeti',
                    style: BBType.caption(
                      context,
                    ).copyWith(color: c.textTertiary),
                  ),
                ),
                Text(
                  '·',
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textTertiary),
                ),
                InkWell(
                  onTap: () => context.push(OwnerRoutes.privacyPolicy),
                  child: Text(
                    'Privatnost',
                    style: BBType.caption(
                      context,
                    ).copyWith(color: c.textTertiary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pitch stat (handoff PitchStat): tabular value in primary + caption label.
class _PitchStat extends StatelessWidget {
  final String value;
  final String label;

  const _PitchStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.56,
            color: c.primary,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: BBType.caption(context).copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}
