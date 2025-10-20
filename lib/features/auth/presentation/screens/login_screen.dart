import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/navigation_helpers.dart';
import '../../../../core/utils/accessibility_utils.dart';
import '../../../../core/utils/responsive_breakpoints.dart';
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uspješno ste se prijavili!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final authState = ref.read(authNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error ?? 'Prijava neuspješna'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google prijava neuspješna'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
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
                      label: 'Rab Booking logo',
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
                        'Dobrodošli nazad',
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
                        'Prijavite se na svoj račun',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: context.textColorSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Email field
                    Semantics(
                      label: 'Email adresa',
                      hint: 'Unesite vašu email adresu',
                      textField: true,
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: FormValidators.validateEmail,
                        enabled: !authState.isLoading,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    Semantics(
                      label: 'Lozinka',
                      hint: 'Unesite vašu lozinku',
                      textField: true,
                      obscured: _obscurePassword,
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Lozinka',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: Semantics(
                            label: _obscurePassword ? 'Prikaži lozinku' : 'Sakrij lozinku',
                            hint: 'Dvostruki dodir za promjenu vidljivosti',
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
                            return 'Lozinka je obavezna';
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
                        child: const Text('Zaboravili ste lozinku?'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login button
                    Semantics(
                      label: authState.isLoading ? 'Prijavljuje se...' : 'Prijavite se',
                      hint: authState.isLoading
                        ? 'Molimo pričekajte dok se prijavljujete'
                        : 'Dvostruki dodir za prijavu na račun',
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
                            : const Text('Prijavite se'),
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
                      label: 'Prijavite se s Google računom',
                      hint: 'Dvostruki dodir za prijavu preko Google-a',
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
                              const Flexible(
                                child: Text(
                                  'Nastavite s Google',
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
                          'Nemate račun?',
                          style: TextStyle(color: context.textColorSecondary),
                        ),
                        TextButton(
                          onPressed: authState.isLoading
                              ? null
                              : () => context.goToRegister(),
                          child: const Text('Registrirajte se'),
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
      ),
    );
  }
}
