import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../widgets/auth_logo_icon.dart';

/// Email Verification Screen with resend functionality
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  Timer? _refreshTimer;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Auto-check verification status every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkVerificationStatus();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    await ref
        .read(enhancedAuthProvider.notifier)
        .refreshEmailVerificationStatus();

    final authState = ref.read(enhancedAuthProvider);
    if (!authState.requiresEmailVerification && mounted) {
      // Email verified! Let router handle navigation based on onboarding status
      // Router will redirect to:
      // - /onboarding/wizard if requiresOnboarding is true
      // - /owner/overview if requiresOnboarding is false
      context.go('/');
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0) return;

    setState(() => _isResending = true);

    try {
      await ref.read(enhancedAuthProvider.notifier).sendEmailVerification();

      if (mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Verification email sent! Check your inbox.',
          duration: const Duration(seconds: 3),
        );

        // Start 60 second cooldown
        setState(() {
          _resendCooldown = 60;
        });

        _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _resendCooldown--;
            if (_resendCooldown == 0) {
              timer.cancel();
            }
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          'Failed to send email: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  /// Show dialog to change email address (Phase 3 feature)
  Future<void> _showChangeEmailDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final l10n = AppLocalizations.of(context);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.email_outlined, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(l10n.editProfileEmail),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your new email address. You will need to verify it.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Builder(
                builder: (ctx) => TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecorationHelper.buildDecoration(
                    labelText: 'New Email *',
                    prefixIcon: const Icon(Icons.email),
                    context: ctx,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (ctx) => TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecorationHelper.buildDecoration(
                    labelText: 'Current Password *',
                    prefixIcon: const Icon(Icons.lock),
                    helperText: 'Required to confirm identity',
                    context: ctx,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiary.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiary.withAlpha((0.3 * 255).toInt()),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will be logged out and need to verify the new email',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final navigator = Navigator.of(context);
              navigator.pop();

              try {
                // Re-authenticate and update email via provider
                await ref
                    .read(enhancedAuthProvider.notifier)
                    .updateEmail(
                      newEmail: emailController.text.trim(),
                      currentPassword: passwordController.text,
                    );

                if (mounted) {
                  ErrorDisplayUtils.showSuccessSnackBar(
                    this.context,
                    'Email updated! Check your new inbox for verification.',
                  );
                }
              } catch (e) {
                if (mounted) {
                  ErrorDisplayUtils.showErrorSnackBar(this.context, e);
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(enhancedAuthProvider);
    final email = authState.firebaseUser?.email ?? 'your email';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CommonAppBar(
        title: 'Verify Email',
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                AuthLogoIcon(
                  size: 100,
                  isWhite: Theme.of(context).brightness == Brightness.dark,
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Check your inbox',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'We sent a verification link to',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha((0.2 * 255).toInt()),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Click the link in the email to verify your account',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Email may take up to 10 minutes to arrive. Check your spam folder if needed.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant
                              .withAlpha((0.8 * 255).toInt()),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Resend Button
                OutlinedButton(
                  onPressed: _resendCooldown > 0 || _isResending
                      ? null
                      : _resendVerificationEmail,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 32,
                    ),
                  ),
                  child: _isResending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _resendCooldown > 0
                              ? 'Resend in ${_resendCooldown}s'
                              : 'Resend verification email',
                        ),
                ),
                const SizedBox(height: 16),

                // Change Email
                TextButton(
                  onPressed: _showChangeEmailDialog,
                  child: const Text('Wrong email?'),
                ),
                const SizedBox(height: 32),

                // Back to Login
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(enhancedAuthProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go(OwnerRoutes.login);
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: Text(AppLocalizations.of(context).authBackToLogin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
