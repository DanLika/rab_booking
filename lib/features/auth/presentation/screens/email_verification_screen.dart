import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
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
    extends ConsumerState<EmailVerificationScreen>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  bool _hasShownNetworkError = false; // Prevent repeated error snackbars

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Auto-check verification status every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkVerificationStatus();
    });

    // Start with initial cooldown to prevent immediate resend after registration
    // Email was already sent during registration, so user must wait before resending
    _startInitialCooldown();
  }

  /// Start initial 60-second cooldown when screen opens
  /// Firebase Auth has an internal rate limit (~60s) on sendEmailVerification()
  /// Since email is already sent during registration, we must wait before allowing resend
  void _startInitialCooldown() {
    _resendCooldown = 60;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown == 0) {
          timer.cancel();
        }
      });
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
      // Reset error flag when returning to app - network may have been restored
      _hasShownNetworkError = false;
      _checkVerificationStatus();
    }
  }

  Future<void> _checkVerificationStatus() async {
    try {
      await ref
          .read(enhancedAuthProvider.notifier)
          .refreshEmailVerificationStatus();

      // Reset error flag on success
      _hasShownNetworkError = false;

      final authState = ref.read(enhancedAuthProvider);
      if (!authState.requiresEmailVerification && mounted) {
        // Email verified! Navigate to owner overview
        // Router will handle onboarding redirect if needed
        context.go(OwnerRoutes.overview);
      }
    } catch (e) {
      // Only show network error ONCE to avoid spamming user every 3 seconds
      // Permission-denied errors (e.g., Firestore token refresh race condition)
      // are silently retried - they usually resolve on next attempt
      final errorString = e.toString().toLowerCase();
      final isNetworkError =
          errorString.contains('network') ||
          errorString.contains('socket') ||
          errorString.contains('timeout') ||
          errorString.contains('connection');

      if (isNetworkError && !_hasShownNetworkError && mounted) {
        _hasShownNetworkError = true;
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          AppLocalizations.of(context).errorNetworkFailed,
        );
      }
      // For non-network errors (permission-denied, etc.), silently retry
      // The timer will try again in 3 seconds
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0) return;

    final authState = ref.read(enhancedAuthProvider);
    final firebaseEmail = authState.firebaseUser?.email;
    final firestoreEmail = authState.userModel?.email;

    // If emails differ, user has a pending email change
    // Need to show password dialog because verifyBeforeUpdateEmail requires recent auth
    if (firestoreEmail != null &&
        firebaseEmail != null &&
        firestoreEmail.toLowerCase() != firebaseEmail.toLowerCase()) {
      await _showResendPasswordDialog(firestoreEmail);
      return;
    }

    setState(() => _isResending = true);

    try {
      // Normal case: send verification to current Firebase Auth email
      await ref.read(enhancedAuthProvider.notifier).sendEmailVerification();

      if (mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          AppLocalizations.of(context).authVerifyEmailSuccess,
          duration: const Duration(seconds: 3),
        );
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('too-many-requests')) {
          // Firebase rate limit hit - start cooldown so user knows when to retry
          _startCooldown();
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            AppLocalizations.of(context).authErrorTooManyRequests,
          );
        } else if (errorString.contains('network') ||
            errorString.contains('socket') ||
            errorString.contains('timeout') ||
            errorString.contains('connection')) {
          // Network error - show user-friendly message
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            AppLocalizations.of(context).errorNetworkFailed,
          );
        } else {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            '${AppLocalizations.of(context).error}: $e',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  /// Show password dialog for resending email change verification
  /// Required because verifyBeforeUpdateEmail is a sensitive operation
  Future<void> _showResendPasswordDialog(String newEmail) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.authResendVerificationEmail),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.authPasswordHelper,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (ctx) => TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecorationHelper.buildDecoration(
                      labelText: l10n.authPasswordLabel,
                      prefixIcon: const Icon(Icons.lock),
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final navigator = Navigator.of(context);
                navigator.pop();

                setState(() => _isResending = true);

                try {
                  // Re-authenticate and resend verification
                  await ref
                      .read(enhancedAuthProvider.notifier)
                      .updateEmail(
                        newEmail: newEmail,
                        currentPassword: passwordController.text,
                      );

                  if (mounted) {
                    ErrorDisplayUtils.showSuccessSnackBar(
                      this.context,
                      l10n.authVerifyEmailSuccess,
                      duration: const Duration(seconds: 3),
                    );
                    _startCooldown();
                  }
                } catch (e) {
                  if (mounted) {
                    ErrorDisplayUtils.showErrorSnackBar(this.context, e);
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isResending = false);
                  }
                }
              },
              child: Text(l10n.submit),
            ),
          ],
        );
      },
    );
  }

  /// Start 60 second cooldown after sending verification email
  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() {
      _resendCooldown = 60;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown == 0) {
          timer.cancel();
        }
      });
    });
  }

  /// Show dialog to change email address (Phase 3 feature)
  Future<void> _showChangeEmailDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.email_outlined, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(l10n.authChangeEmailTitle),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.authChangeEmailDesc,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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
                            l10n.authLogoutHint,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
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
                      l10n.authUpdateEmailSuccess,
                    );
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
    // Prefer Firestore email (userModel) which is updated immediately after email change
    // Firebase Auth email only updates AFTER user clicks verification link
    final email =
        authState.userModel?.email ??
        authState.firebaseUser?.email ??
        'your email';
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CommonAppBar(
        title: AppLocalizations.of(context).authEmailVerificationTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (_) async {
          // Use this.context instead of passed context for proper navigation
          try {
            await ref.read(enhancedAuthProvider.notifier).signOut();
          } catch (e) {
            // Ignore sign out errors, just navigate
          }
          if (mounted) {
            this.context.go(OwnerRoutes.login);
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
                AuthLogoIcon(
                  isWhite: Theme.of(context).brightness == Brightness.dark,
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  AppLocalizations.of(context).authCheckInbox,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  AppLocalizations.of(context).authEmailVerificationSentTo,
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
                              AppLocalizations.of(
                                context,
                              ).authClickLinkToVerify,
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
                        AppLocalizations.of(context).authEmailArrivalHint,
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
                              ? AppLocalizations.of(
                                  context,
                                ).authResendInSeconds(_resendCooldown)
                              : AppLocalizations.of(
                                  context,
                                ).authResendVerificationEmail,
                        ),
                ),
                const SizedBox(height: 32),

                // Action Buttons - Vertical Layout
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Change Email Button
                    TextButton.icon(
                      onPressed: _showChangeEmailDialog,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      label: Text(
                        AppLocalizations.of(context).authWrongEmail,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Back to Login Button
                    TextButton.icon(
                      onPressed: () async {
                        await ref.read(enhancedAuthProvider.notifier).signOut();
                        if (mounted) {
                          this.context.go(OwnerRoutes.login);
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      icon: Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      label: Text(
                        AppLocalizations.of(context).authBackToLogin,
                        style: const TextStyle(fontSize: 14),
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
