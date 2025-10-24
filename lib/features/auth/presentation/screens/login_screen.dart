import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/navigation_helpers.dart';
import '../../../../core/utils/responsive_breakpoints.dart';
import '../../../../shared/presentation/widgets/adaptive_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_notifier.dart';
import '../utils/form_validators.dart';

/// Login screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    this.redirectTo,
    super.key,
  });

  final String? redirectTo;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref.read(authNotifierProvider.notifier).signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (mounted) {
        // Navigate based on redirect or role
        if (widget.redirectTo != null) {
          context.go(widget.redirectTo!);
        } else {
          final authState = ref.read(authNotifierProvider);
          if (authState.isAdmin) {
            context.goToAdminDashboard();
          } else if (authState.isOwner) {
            context.goToOwnerDashboard();
          } else {
            context.goToHome();
          }
        }

        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.loginSuccessful),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final authState = ref.read(authNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error ?? l10n.loginFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.googleLoginFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return AuthScaffold(
      showBackButton: true,  // Allow user to exit auth flow - NO DEAD END!
      showLogo: false,       // Show custom logo below instead
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.horizontalPadding),
          child: ResponsiveContainer(
            maxWidth: 400,
            child: RepaintBoundary(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo or title
                    Semantics(
                      label: '${l10n.appName} logo',
                      image: true,
                      child: Icon(
                        Icons.villa,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Semantics(
                      header: true,
                      child: Text(
                        l10n.welcomeBack,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Semantics(
                      readOnly: true,
                      child: Text(
                        l10n.loginToYourAccount,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: context.textColorSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Email field
                    Semantics(
                      label: l10n.email,
                      hint: l10n.enterYourEmail,
                      textField: true,
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n.email,
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        validator: FormValidators.validateEmail,
                        enabled: !authState.isLoading,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    Semantics(
                      label: l10n.password,
                      hint: 'Enter your password',
                      textField: true,
                      obscured: _obscurePassword,
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: l10n.password,
                          prefixIcon: const Icon(Icons.lock_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: Semantics(
                            label: _obscurePassword ? 'Show password' : 'Hide password',
                            hint: 'Double tap to toggle visibility',
                            button: true,
                            child: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.requiredField;
                          }
                          return null;
                        },
                        enabled: !authState.isLoading,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: authState.isLoading
                            ? null
                            : () => context.goToForgotPassword(),
                        child: Text(l10n.forgotPassword),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login button
                    Semantics(
                      label: authState.isLoading ? '${l10n.loading}...' : l10n.signIn,
                      hint: authState.isLoading
                        ? 'Please wait while signing in'
                        : 'Double tap to sign in to your account',
                      button: true,
                      enabled: !authState.isLoading,
                      child: FilledButton(
                        onPressed: authState.isLoading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: authState.isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.textColorInverted,
                                ),
                              )
                            : Text(l10n.signIn),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: context.dividerColor)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'ili',
                            style: TextStyle(color: context.textColorSecondary),
                          ),
                        ),
                        Expanded(child: Divider(color: context.dividerColor)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Google sign in
                    Semantics(
                      label: l10n.signInWithGoogle,
                      hint: 'Double tap to sign in with Google',
                      button: true,
                      enabled: !authState.isLoading,
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: authState.isLoading ? null : _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CachedNetworkImage(
                                imageUrl: 'https://www.google.com/favicon.ico',
                                width: 20,
                                height: 20,
                                placeholder: (context, url) => const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.g_mobiledata, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  l10n.continueWithGoogle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Register link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.dontHaveAccount,
                          style: TextStyle(color: context.textColorSecondary),
                        ),
                        TextButton(
                          onPressed: authState.isLoading
                              ? null
                              : () => context.goToRegister(),
                          child: Text(l10n.register),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
