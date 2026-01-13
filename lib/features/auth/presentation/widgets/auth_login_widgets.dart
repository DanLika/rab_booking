import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/auth_logo_icon.dart';
import '../../../../core/constants/auth_feature_flags.dart';
import '../widgets/social_login_button.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';

class AuthHeader extends StatelessWidget {
  final bool isCompact;

  const AuthHeader({
    super.key,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Center(
          child: AuthLogoIcon(size: isCompact ? 70 : 80, isWhite: theme.brightness == Brightness.dark),
        ),
        SizedBox(height: isCompact ? 16 : 20),
        Text(
          l10n.authOwnerLogin,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: isCompact ? 22 : 26),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.authManageProperties,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: isCompact ? 13 : 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class SocialLoginSection extends ConsumerWidget {
  final bool isCompact;
  final bool isLoading;

  const SocialLoginSection({
    super.key,
    required this.isCompact,
    required this.isLoading,
  });

  Future<void> _handleOAuthSignIn(BuildContext context, WidgetRef ref, Future<void> Function() signInMethod) async {
    // Note: Loading state is handled by parent or provider usually, but here we just invoke method.
    // The parent widget might set local loading state.
    // However, since we extracted this, we should rely on provider state or callbacks.
    // But for now, let's just call the notifier method.
    try {
      await signInMethod();
    } catch (e) {
      if (!context.mounted) return;
      // Error handling is ideally done by observing state, but we can show snackbar here if needed.
      // Or just let the provider state update handle it.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final authNotifier = ref.read(enhancedAuthProvider.notifier);
    final isAppleEnabled = AuthFeatureFlags.isAppleSignInEnabled;
    final isGoogleEnabled = AuthFeatureFlags.isGoogleSignInEnabled;

    if (!isGoogleEnabled && !isAppleEnabled) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(height: isCompact ? 16 : 20),
        Row(
          children: [
            Expanded(child: Divider(color: theme.colorScheme.outline)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.authOrContinueWith,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
            Expanded(child: Divider(color: theme.colorScheme.outline)),
          ],
        ),
        SizedBox(height: isCompact ? 16 : 20),
        _buildButtons(context, ref, l10n, authNotifier),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, WidgetRef ref, AppLocalizations l10n, EnhancedAuthNotifier authNotifier) {
    final isAppleEnabled = AuthFeatureFlags.isAppleSignInEnabled;
    final isGoogleEnabled = AuthFeatureFlags.isGoogleSignInEnabled;

    if (isGoogleEnabled && !isAppleEnabled) {
      return SocialLoginButton(
        customIcon: const GoogleBrandIcon(),
        label: l10n.continueWithGoogle,
        enabled: !isLoading,
        onPressed: () => _handleOAuthSignIn(context, ref, authNotifier.signInWithGoogle),
      );
    }

    if (!isGoogleEnabled && isAppleEnabled) {
      return SocialLoginButton(
        customIcon: const AppleBrandIcon(),
        label: l10n.continueWithApple,
        enabled: !isLoading,
        onPressed: () => _handleOAuthSignIn(context, ref, authNotifier.signInWithApple),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final googleButton = SocialLoginButton(
          customIcon: const GoogleBrandIcon(),
          label: l10n.continueWithGoogle,
          enabled: !isLoading,
          onPressed: () => _handleOAuthSignIn(context, ref, authNotifier.signInWithGoogle),
        );

        final appleButton = SocialLoginButton(
          customIcon: const AppleBrandIcon(),
          label: l10n.continueWithApple,
          enabled: !isLoading,
          onPressed: () => _handleOAuthSignIn(context, ref, authNotifier.signInWithApple),
        );

        if (constraints.maxWidth < 280) {
          return Column(children: [googleButton, const SizedBox(height: 10), appleButton]);
        }

        return Row(
          children: [
            Expanded(child: googleButton),
            const SizedBox(width: 10),
            Expanded(child: appleButton),
          ],
        );
      },
    );
  }
}

class RegisterLink extends StatelessWidget {
  final bool isLoading;

  const RegisterLink({
    super.key,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: TextButton(
        onPressed: isLoading ? null : () => context.go(OwnerRoutes.register),
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12)),
        child: RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: isLoading ? theme.colorScheme.onSurface.withAlpha(100) : null,
            ),
            children: [
              TextSpan(text: '${l10n.authNoAccount} '),
              TextSpan(
                text: l10n.authCreateAccount,
                style: TextStyle(
                  color: isLoading ? theme.colorScheme.primary.withAlpha(100) : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
