import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/breakpoints.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_logo_icon.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_auth_button.dart';
import '../widgets/premium_input_field.dart';

/// Forgot password screen
///
/// Uses [AndroidKeyboardDismissFixApproach1] mixin to handle the Android Chrome
/// keyboard dismiss bug (Flutter issue #175074).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with AndroidKeyboardDismissFixApproach1<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(enhancedAuthProvider.notifier)
          .resetPassword(_emailController.text.trim());

      // SECURITY: Firebase sendPasswordResetEmail already returns success
      // regardless of whether email exists (prevents user enumeration)
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorDisplayUtils.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = Breakpoints.isCompactMobile(context);

    // Isti pristup kao Login: resizeToAvoidBottomInset: true
    return KeyedSubtree(
      key: ValueKey('forgot_password_screen_$keyboardFixRebuildKey'),
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
                        left: isCompact ? 16 : 24,
                        right: isCompact ? 16 : 24,
                        top: 24,
                        bottom: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minHeight),
                        child: Center(
                          child: GlassCard(
                            child: _emailSent
                                ? _buildSuccessView()
                                : _buildFormView(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormView() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isCompact = Breakpoints.isCompactMobile(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AuthLogoIcon(
              size: isCompact ? 70 : 80,
              isWhite: theme.brightness == Brightness.dark,
            ),
          ),
          SizedBox(height: isCompact ? 16 : 20),
          Text(
            l10n.authResetPassword,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 22 : 26,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.authResetPasswordDesc,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: isCompact ? 13 : 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isCompact ? 24 : 32),
          PremiumInputField(
            controller: _emailController,
            labelText: l10n.email,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: ProfileValidators.validateEmail,
          ),
          SizedBox(height: isCompact ? 20 : 24),
          GradientAuthButton(
            text: l10n.authSendResetLink,
            onPressed: _handleResetPassword,
            isLoading: _isLoading,
            icon: Icons.email_outlined,
          ),
          SizedBox(height: isCompact ? 16 : 20),
          _buildBackToLogin(theme, l10n),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isCompact = Breakpoints.isCompactMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: isCompact ? 72 : 88,
            height: isCompact ? 72 : 88,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withAlpha(64),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: isCompact ? 36 : 44,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: isCompact ? 20 : 24),
        Text(
          l10n.authEmailSent,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isCompact ? 22 : 26,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.authResetEmailSentTo,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: isCompact ? 13 : 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          _emailController.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontSize: isCompact ? 14 : 15,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isCompact ? 24 : 32),
        GradientAuthButton(
          text: l10n.authReturnToLogin,
          onPressed: () => context.go('/login'),
          icon: Icons.arrow_forward,
        ),
        SizedBox(height: isCompact ? 12 : 14),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _emailSent = false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            ),
            child: Text(
              l10n.authResendEmail,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackToLogin(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: TextButton(
        onPressed: () => context.go('/login'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              l10n.authBackToLogin,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
