import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/auth_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/auth_logo_icon.dart';
import '../widgets/premium_input_field.dart';
import '../widgets/gradient_auth_button.dart';

/// Forgot password screen
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
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
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      // Show feedback for validation errors
      ErrorDisplayUtils.showErrorSnackBar(context, 'Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(enhancedAuthProvider.notifier).resetPassword(_emailController.text.trim());

      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorDisplayUtils.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width < 400 ? 16 : 24,
                              vertical: 24,
                            ),
                            child: GlassCard(child: _emailSent ? _buildSuccessView() : _buildFormView()),
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

  Widget _buildFormView() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 400;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Animated Logo
          Center(
            child: AuthLogoIcon(size: isMobile ? 70 : 80, isWhite: theme.brightness == Brightness.dark),
          ),
          SizedBox(height: isMobile ? 16 : 20),

          // Title
          Text(
            l10n.authResetPassword,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 22 : 26,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Subtitle
          Text(
            l10n.authResetPasswordDesc,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: isMobile ? 13 : 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 24 : 32),

          // Email field
          PremiumInputField(
            controller: _emailController,
            labelText: l10n.email,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: ProfileValidators.validateEmail,
          ),
          SizedBox(height: isMobile ? 20 : 24),

          // Send Reset Link Button
          GradientAuthButton(
            text: l10n.authSendResetLink,
            onPressed: _handleResetPassword,
            isLoading: _isLoading,
            icon: Icons.email_outlined,
          ),
          SizedBox(height: isMobile ? 16 : 20),

          // Back to Login
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    l10n.authBackToLogin,
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success Icon
        Center(
          child: Container(
            width: isMobile ? 72 : 88,
            height: isMobile ? 72 : 88,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withAlpha((0.25 * 255).toInt()),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(Icons.check_circle_outline, size: isMobile ? 36 : 44, color: Colors.white),
          ),
        ),
        SizedBox(height: isMobile ? 20 : 24),

        // Title
        Text(
          l10n.authEmailSent,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 22 : 26,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          l10n.authResetEmailSentTo,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: isMobile ? 13 : 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),

        // Email address
        Text(
          _emailController.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontSize: isMobile ? 14 : 15,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isMobile ? 24 : 32),

        // Return to Login Button
        GradientAuthButton(
          text: l10n.authReturnToLogin,
          onPressed: () => context.go('/login'),
          icon: Icons.arrow_forward,
        ),
        SizedBox(height: isMobile ? 12 : 14),

        // Resend email option
        Center(
          child: TextButton(
            onPressed: () => setState(() => _emailSent = false),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12)),
            child: Text(
              l10n.authResendEmail,
              style: TextStyle(fontSize: 13, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
