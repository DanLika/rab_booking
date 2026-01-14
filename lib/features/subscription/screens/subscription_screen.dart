import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/design_tokens/design_tokens.dart';
import '../../../l10n/app_localizations.dart';

const String _webDashboardUrl = 'https://app.bookbed.io/owner/subscription';

/// Simplified Subscription Screen
///
/// Shows a redirect to web dashboard for subscription management.
/// App Store guidelines require in-app purchases for subscriptions,
/// but BookBed handles payments via web dashboard instead.
///
/// This avoids Firestore permission issues from trialStatusProvider.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final colors = isDark ? ColorTokens.dark : ColorTokens.light;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        title: Text(l10n.subscriptionTitle),
        backgroundColor: colors.backgroundPrimary,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.l),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.language_rounded,
                    size: 64,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xl),

                // Title
                Text(
                  l10n.subscriptionWebOnlyTitle,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeXXL,
                    fontWeight: TypographyTokens.bold,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SpacingTokens.m),

                // Description
                Text(
                  l10n.subscriptionWebOnlyMessage,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeM,
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SpacingTokens.xxl),

                // Continue to Web button
                FilledButton.icon(
                  onPressed: _launchWebDashboard,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.subscriptionContinueToWeb),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.xl,
                      vertical: SpacingTokens.m,
                    ),
                    textStyle: const TextStyle(
                      fontSize: TypographyTokens.fontSizeL,
                      fontWeight: TypographyTokens.semiBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchWebDashboard() async {
    final uri = Uri.parse(_webDashboardUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
