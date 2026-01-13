import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Auto-check verification status every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkVerificationStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVerificationStatus();
    }
  }

  Future<void> _checkVerificationStatus() async {
    await ref.read(enhancedAuthProvider.notifier).refreshEmailVerificationStatus();

    final authState = ref.read(enhancedAuthProvider);
    if (!authState.requiresEmailVerification && mounted) {
      // Email verified! Let router handle navigation based on onboarding status
      // Router will redirect to:
      // - /onboarding/wizard if requiresOnboarding is true
      // - /owner/overview if requiresOnboarding is false
      context.go(OwnerRoutes.overview);
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
          AppLocalizations.of(context)!.authVerifyEmailSuccess,
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
        ErrorDisplayUtils.showErrorSnackBar(context, '${AppLocalizations.of(context)!.error}: $e');
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

    return showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.email_outlined, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(l10n.authChangeEmailTitle),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.authChangeEmailDesc, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 20),
                Builder(
                  builder: (ctx) => TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecorationHelper.buildDecoration(
                      labelText: l10n.authNewEmailLabel,
                      prefixIcon: const Icon(Icons.email),
                      context: ctx,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.emailRequired;
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return l10n.validEmailRequired;
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
                      labelText: l10n.authPasswordLabel,
                      prefixIcon: const Icon(Icons.lock),
                      helperText: l10n.authPasswordHelper,
                      context: ctx,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.passwordRequired;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary.withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.tertiary.withAlpha((0.3 * 255).toInt())),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.tertiary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.authLogoutHint,
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final navigator = Navigator.of(context);
                navigator.pop();

                try {
                  // Re-authenticate and update email via provider
                  await ref
                      .read(enhancedAuthProvider.notifier)
                      .updateEmail(newEmail: emailController.text.trim(), currentPassword: passwordController.text);

                  if (mounted) {
                    ErrorDisplayUtils.showSuccessSnackBar(this.context, l10n.authUpdateEmailSuccess);
                  }
                } catch (e) {
                  if (mounted) {
                    ErrorDisplayUtils.showErrorSnackBar(this.context, e);
                  }
                }
              },
              child: Text(l10n.authChangeEmail),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(enhancedAuthProvider);
    final email = authState.firebaseUser?.email ?? 'your email';
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CommonAppBar(
        title: AppLocalizations.of(context)!.authEmailVerificationTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) async {
          try {
            await ref.read(enhancedAuthProvider.notifier).signOut();
          } catch (e) {
            // Ignore sign out errors, just navigate
          }
          if (context.mounted) {
            context.go(OwnerRoutes.login);
          }
        },
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
                AuthLogoIcon(size: 100, isWhite: Theme.of(context).brightness == Brightness.dark),
                const SizedBox(height: 32),

                // Title
                Text(
                  AppLocalizations.of(context)!.authCheckInbox,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  AppLocalizations.of(context)!.authEmailVerificationSentTo,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withAlpha((0.2 * 255).toInt()),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.authClickLinkToVerify,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.authEmailArrivalHint,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha((0.8 * 255).toInt()),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Resend Button
                OutlinedButton(
                  onPressed: _resendCooldown > 0 || _isResending ? null : _resendVerificationEmail,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32)),
                  child: _isResending
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          _resendCooldown > 0
                              ? AppLocalizations.of(context)!.authResendInSeconds(_resendCooldown)
                              : AppLocalizations.of(context)!.authResendVerificationEmail,
                        ),
                ),
                const SizedBox(height: 32),

                // Action Buttons Row (Single line as requested)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Change Email
                    Flexible(
                      child: TextButton(
                        onPressed: _showChangeEmailDialog,
                        child: Text(
                          AppLocalizations.of(context)!.authWrongEmail,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 16,
                      color: theme.dividerColor.withAlpha((0.5 * 255).toInt()),
                    ),
                    // Back to Login
                    Flexible(
                      child: TextButton.icon(
                        onPressed: () async {
                          // Force sign out and redirect
                          await ref.read(enhancedAuthProvider.notifier).signOut();
                          if (context.mounted) {
                            context.go(OwnerRoutes.login);
                          }
                        },
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: Text(
                          AppLocalizations.of(context)!.authBackToLogin,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
