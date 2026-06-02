import 'package:bookbed/shared/widgets/redesign.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Admin login screen with `isAdmin` verification, redesign-r6 chrome.
class AdminLoginScreen extends ConsumerStatefulWidget {
  final String? errorMessage;

  const AdminLoginScreen({super.key, this.errorMessage});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _isPasswordVisible = ValueNotifier<bool>(false);
  bool _isLoading = false;
  String? _error;
  bool _notAdmin = false;

  @override
  void initState() {
    super.initState();
    // initState runs before context.l10n is reachable; defer 'not_admin'
    // localization to didChangeDependencies.
    _notAdmin = widget.errorMessage == 'not_admin';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_notAdmin && _error == null) {
      _error = AppLocalizations.of(context).adminAccessDenied;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _isPasswordVisible.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref
          .read(enhancedAuthProvider.notifier)
          .signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final authState = ref.read(enhancedAuthProvider);
      if (!authState.isAdmin) {
        await ref.read(enhancedAuthProvider.notifier).signOut();
        if (mounted) {
          setState(() {
            _error = AppLocalizations.of(context).adminAccessDenied;
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _sanitizeLoginError(e);
          _isLoading = false;
        });
      }
    }
  }

  String _sanitizeLoginError(Object error) {
    String message = error.toString();
    final authMatch = RegExp(
      r'\[firebase_auth/[^\]]+\]\s*(.*)',
    ).firstMatch(message);
    if (authMatch != null && authMatch.group(1)!.isNotEmpty) {
      return authMatch.group(1)!;
    }
    message = message
        .replaceAll('Exception: ', '')
        .replaceAll(RegExp(r'^\[.*?\]\s*'), '')
        .trim();
    if (message.isEmpty || message.length > 200) {
      return AppLocalizations.of(context).adminLoginFailed;
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = BbAdminDarkTokens.of(context);
    final c = BBColor.of(context);

    return Scaffold(
      backgroundColor: t.shellBg,
      body: DecoratedBox(
        // TIP 1 — single dijagonalni gradient (2 boje, 2 stops), topLeft→bottomRight.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.3],
            colors: [t.shellBg, t.panelBg],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AdminBrandMark(primary: c.primary),
                  const SizedBox(height: 32),
                  BbCard(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.adminWelcomeBack,
                            style: BBType.h3(context).copyWith(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.adminLoginSubtitle,
                            style: BBType.body(
                              context,
                            ).copyWith(color: t.textSecondary),
                          ),
                          const SizedBox(height: 32),
                          if (_error != null) ...[
                            _ErrorBanner(message: _error!, errorColor: c.error),
                            const SizedBox(height: 24),
                          ],
                          BbInput(
                            label: l10n.adminEmailLabel,
                            placeholder: l10n.adminEmailHint,
                            controller: _emailController,
                            iconLeft: 'mail',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.adminEmailRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          ValueListenableBuilder<bool>(
                            valueListenable: _isPasswordVisible,
                            builder: (context, isVisible, _) {
                              return BbInput(
                                label: l10n.adminPasswordLabel,
                                controller: _passwordController,
                                iconLeft: 'lock',
                                obscureText: !isVisible,
                                trailingAction: _PasswordVisibilityToggle(
                                  isVisible: isVisible,
                                  color: t.textSecondary,
                                  onPressed: () =>
                                      _isPasswordVisible.value = !isVisible,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.adminPasswordRequired;
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _login(),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          BbButton(
                            label: l10n.adminSignInButton,
                            size: BbButtonSize.lg,
                            fullWidth: true,
                            loading: _isLoading,
                            onPressed: _isLoading ? null : _login,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.adminFooterCopyright(DateTime.now().year),
                    style: BBType.caption(
                      context,
                    ).copyWith(color: t.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminBrandMark extends StatelessWidget {
  final Color primary;

  const _AdminBrandMark({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.admin_panel_settings,
        size: 40,
        color: Colors.white,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final Color errorColor;

  const _ErrorBanner({required this.message, required this.errorColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BBRadius.sm),
        border: Border.all(color: errorColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: errorColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: BBType.caption(
                context,
              ).copyWith(color: errorColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordVisibilityToggle extends StatelessWidget {
  final bool isVisible;
  final Color color;
  final VoidCallback onPressed;

  const _PasswordVisibilityToggle({
    required this.isVisible,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: color,
        size: 20,
      ),
      splashRadius: 18,
      tooltip: AppLocalizations.of(context).adminPasswordLabel,
      onPressed: onPressed,
    );
  }
}
