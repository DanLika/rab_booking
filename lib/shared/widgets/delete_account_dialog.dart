import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/enhanced_auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/input_decoration_helper.dart';
import '../../l10n/app_localizations.dart';

/// Dialog for confirming account deletion
///
/// Shows a warning message and requires user confirmation.
/// Supports both email/password and social sign-in (Google/Apple) users.
/// On confirm, calls the deleteAccount method from auth provider.
///
/// Required for Apple App Store compliance (mandatory since 2022).
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isDeleting = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _socialReauthCompleted = false;
  AuthCredential? _socialCredential;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// Get the user's sign-in provider
  String? _getLastProvider() {
    final authState = ref.read(enhancedAuthProvider);
    return authState.userModel?.lastProvider;
  }

  /// Check if user signed in with social provider (Google/Apple)
  bool get _isSocialSignIn {
    final provider = _getLastProvider();
    return provider == 'google.com' || provider == 'apple.com';
  }

  /// Check if user signed in with Google
  bool get _isGoogleSignIn => _getLastProvider() == 'google.com';

  /// Check if user signed in with Apple
  bool get _isAppleSignIn => _getLastProvider() == 'apple.com';

  /// Handle re-authentication with Google
  Future<void> _handleGoogleReauth() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      final credential = await ref
          .read(enhancedAuthProvider.notifier)
          .reauthenticateWithGoogle();

      setState(() {
        _socialCredential = credential;
        _socialReauthCompleted = true;
        _isDeleting = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Handle re-authentication with Apple
  Future<void> _handleAppleReauth() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      final credential = await ref
          .read(enhancedAuthProvider.notifier)
          .reauthenticateWithApple();

      setState(() {
        _socialCredential = credential;
        _socialReauthCompleted = true;
        _isDeleting = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Handle final deletion after re-authentication
  Future<void> _handleDelete() async {
    // For password users, validate form
    if (!_isSocialSignIn && !_formKey.currentState!.validate()) return;

    // For social users, ensure re-auth completed
    if (_isSocialSignIn && !_socialReauthCompleted) {
      setState(() {
        _errorMessage = 'Please re-authenticate first';
      });
      return;
    }

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(enhancedAuthProvider.notifier)
          .deleteAccount(
            password: _isSocialSignIn ? null : _passwordController.text,
            credential: _socialCredential,
          );

      // Dialog will be dismissed automatically when user is signed out
      // because the profile screen will navigate away
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.deleteAccountTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.deleteAccountWarning,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.deleteAccountPermanent,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Show different UI based on auth provider
                if (_isSocialSignIn)
                  _buildSocialReauthSection(theme, l10n, isDark)
                else
                  _buildPasswordSection(theme, l10n),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isDeleting
              ? null
              : (_isSocialSignIn && !_socialReauthCompleted)
              ? null // Disabled until re-auth
              : _handleDelete,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.error.withValues(alpha: 0.5),
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.deleteAccount),
        ),
      ],
    );
  }

  /// Build password input section for email/password users
  Widget _buildPasswordSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.password, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration:
              InputDecorationHelper.buildDecoration(
                labelText: l10n.password,
                context: context,
                suffixIcon: IconButton(
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
              ).copyWith(
                // Override focus color to error color to warn user
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 2,
                  ),
                ),
              ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.requiredField;
            }
            return null;
          },
          onFieldSubmitted: (_) => _handleDelete(),
        ),
      ],
    );
  }

  /// Build social re-authentication section for Google/Apple users
  Widget _buildSocialReauthSection(
    ThemeData theme,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final providerName = _isGoogleSignIn ? 'Google' : 'Apple';

    if (_socialReauthCompleted) {
      // Show success message after re-auth
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.deleteAccountReauthSuccess,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show re-auth button
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.deleteAccountReauthRequired,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.deleteAccountReauthDescription(providerName),
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isDeleting
                ? null
                : (_isGoogleSignIn ? _handleGoogleReauth : _handleAppleReauth),
            icon: Icon(
              _isGoogleSignIn ? Icons.g_mobiledata : Icons.apple,
              size: 24,
            ),
            label: Text(l10n.deleteAccountReauthButton(providerName)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: isDark ? Colors.white30 : Colors.black26),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows the delete account confirmation dialog
///
/// Returns true if account was deleted, false if cancelled.
Future<bool?> showDeleteAccountDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const DeleteAccountDialog(),
  );
}
