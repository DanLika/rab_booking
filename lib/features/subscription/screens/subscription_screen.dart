import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/design_tokens/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/common_app_bar.dart';
import '../../owner_dashboard/presentation/widgets/owner_app_drawer.dart';

/// Subscription Screen
///
/// Platform-aware screen that shows:
/// - On WEB: Full subscription plans with upgrade options
/// - On NATIVE (Android/iOS): Redirect to web dashboard
///
/// App Store guidelines require in-app purchases for subscriptions in native apps,
/// but BookBed handles payments via web dashboard instead.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final colors = isDark ? ColorTokens.dark : ColorTokens.light;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: CommonAppBar(
        title: l10n.subscriptionTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'subscription'),
      body: SafeArea(
        child: kIsWeb
            ? _buildWebSubscriptionContent(context, colors, l10n)
            : _buildNativeRedirectContent(context, colors, l10n),
      ),
    );
  }

  /// Web: Show subscription plans with upgrade options
  Widget _buildWebSubscriptionContent(
    BuildContext context,
    WidgetColorScheme colors,
    AppLocalizations l10n,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current status card
          _buildStatusCard(colors, l10n),
          const SizedBox(height: SpacingTokens.xl),

          // Available plans title
          Text(
            l10n.subscriptionAvailablePlans,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeXL,
              fontWeight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),

          // Plans
          _buildPlanCard(
            colors: colors,
            title: l10n.subscriptionFreeTrial,
            price: l10n.subscriptionFreeTrialPrice,
            period: l10n.subscriptionFreeTrialPeriod,
            features: [
              l10n.subscriptionFeatureProperties2,
              l10n.subscriptionFeatureBasicBooking,
              l10n.subscriptionFeatureEmailNotifications,
              l10n.subscriptionFeatureCalendarSync,
            ],
            isCurrent: true,
            isRecommended: false,
          ),
          const SizedBox(height: SpacingTokens.m),

          _buildPlanCard(
            colors: colors,
            title: l10n.subscriptionPlanPro,
            price: l10n.subscriptionProPrice,
            period: l10n.subscriptionProPeriod,
            features: [
              l10n.subscriptionFeatureUnlimitedProperties,
              l10n.subscriptionFeatureAdvancedAnalytics,
              l10n.subscriptionFeaturePrioritySupport,
              l10n.subscriptionFeatureCustomBranding,
              l10n.subscriptionFeatureApiAccess,
              l10n.subscriptionFeatureMultiUser,
            ],
            isCurrent: false,
            isRecommended: true,
            onUpgrade: () => _showUpgradeDialog(context, l10n),
          ),
          const SizedBox(height: SpacingTokens.xxl),

          // FAQ Section
          Text(
            l10n.subscriptionFaq,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeXL,
              fontWeight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),

          _buildFaqItem(
            colors: colors,
            question: l10n.subscriptionFaqTrialEndQuestion,
            answer: l10n.subscriptionFaqTrialEndAnswer,
          ),
          _buildFaqItem(
            colors: colors,
            question: l10n.subscriptionFaqCancelQuestion,
            answer: l10n.subscriptionFaqCancelAnswer,
          ),
          _buildFaqItem(
            colors: colors,
            question: l10n.subscriptionFaqDataSafeQuestion,
            answer: l10n.subscriptionFaqDataSafeAnswer,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(WidgetColorScheme colors, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.l),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: colors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: SpacingTokens.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.subscriptionCurrentStatus,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeS,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.subscriptionStatusTrial,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeL,
                    fontWeight: TypographyTokens.semiBold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required WidgetColorScheme colors,
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required bool isCurrent,
    required bool isRecommended,
    VoidCallback? onUpgrade,
  }) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.l),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(
          color: isRecommended
              ? colors.accent
              : colors.textSecondary.withValues(alpha: 0.2),
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with badge
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeXL,
                    fontWeight: TypographyTokens.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.s,
                    vertical: SpacingTokens.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      BorderTokens.radiusSmall,
                    ),
                  ),
                  child: Text(
                    'Current',
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeXS,
                      fontWeight: TypographyTokens.semiBold,
                      color: colors.success,
                    ),
                  ),
                ),
              if (isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.s,
                    vertical: SpacingTokens.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(
                      BorderTokens.radiusSmall,
                    ),
                  ),
                  child: const Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeXS,
                      fontWeight: TypographyTokens.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: SpacingTokens.s),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeXXL + 8,
                  fontWeight: TypographyTokens.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                period,
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeM,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.m),

          // Features
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: colors.success,
                    size: 18,
                  ),
                  const SizedBox(width: SpacingTokens.s),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: TypographyTokens.fontSizeM,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Upgrade button
          if (onUpgrade != null) ...[
            const SizedBox(height: SpacingTokens.m),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onUpgrade,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: SpacingTokens.m,
                  ),
                ),
                child: const Text(
                  'Upgrade Now',
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeL,
                    fontWeight: TypographyTokens.semiBold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFaqItem({
    required WidgetColorScheme colors,
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.m),
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeM,
              fontWeight: TypographyTokens.semiBold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            answer,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeS,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, AppLocalizations l10n) {
    final colors = Theme.of(context).brightness == Brightness.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Pro'),
        content: Text(
          'Pro subscription coming soon! We\'re working on integrating '
          'Stripe payments. Stay tuned for unlimited properties and '
          'premium features.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Native: Show redirect to web dashboard
  Widget _buildNativeRedirectContent(
    BuildContext context,
    WidgetColorScheme colors,
    AppLocalizations l10n,
  ) {
    return Center(
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
              onPressed: () => _launchWebDashboard(context),
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
    );
  }

  static const String _webDashboardUrl = 'https://app.bookbed.io';

  Future<void> _launchWebDashboard(BuildContext context) async {
    final uri = Uri.parse(_webDashboardUrl);
    try {
      // Note: Don't use canLaunchUrl() - it returns false on Android 11+
      // even when launchUrl() would work. Just try to launch directly.
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open browser. Please visit app.bookbed.io manually.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open browser. Please visit app.bookbed.io manually.',
            ),
          ),
        );
      }
    }
  }
}
