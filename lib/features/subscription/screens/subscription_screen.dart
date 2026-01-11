import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/web_utils.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/router_owner.dart';
import '../../../shared/widgets/common_app_bar.dart';
import '../data/subscription_repository.dart';
import '../models/trial_status.dart';
import '../providers/trial_status_provider.dart';

/// Subscription management screen
///
/// Handles subscription plan display, checkout flow, and status management.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check for success/cancel query params
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPaymentStatus();
    });
  }

  void _checkPaymentStatus() {
    final uri = GoRouterState.of(context).uri;
    final status = uri.queryParameters['status'];
    final l10n = AppLocalizations.of(context);

    if (status == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.subscriptionSuccess), // "Subscription updated successfully"
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
      // Refresh trial status
      ref.invalidate(trialStatusProvider);
    } else if (status == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.subscriptionCancelled), // "Payment was cancelled"
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleUpgrade(BuildContext context, AppLocalizations l10n) async {
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      // Use return URL that hits the router's success/cancel logic
      // Note: Cloud function will append ?session_id=... or ?status=cancelled
      const returnUrl = 'https://app.bookbed.io/owner/subscription/success';

      // TODO: Use real price ID from config/env
      final url = await repo.createCheckoutSession(
        priceId: 'price_monthly_pro', // Placeholder
        returnUrl: returnUrl,
      );

      // Redirect to Stripe
      navigateToUrl(url);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trialStatusAsync = ref.watch(trialStatusProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.subscriptionTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (ctx) => Navigator.of(ctx).pop(),
      ),
      body: Stack(
        children: [
          trialStatusAsync.when(
            data: (trialStatus) => _buildContent(context, theme, trialStatus, l10n),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(l10n.subscriptionErrorLoading(error.toString())),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    TrialStatus? trialStatus,
    AppLocalizations l10n,
  ) {
    if (trialStatus == null) {
      return Center(child: Text(l10n.subscriptionLoginRequired));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Status Card
          _StatusCard(trialStatus: trialStatus),
          const SizedBox(height: 24),

          // Plans Section
          Text(
            l10n.subscriptionAvailablePlans,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Free Plan
          _PlanCard(
            title: l10n.subscriptionFreeTrial,
            price: l10n.subscriptionFreeTrialPrice,
            period: l10n.subscriptionFreeTrialPeriod,
            features: [
              l10n.subscriptionFeatureProperties2,
              l10n.subscriptionFeatureBasicBooking,
              l10n.subscriptionFeatureEmailNotifications,
              l10n.subscriptionFeatureCalendarSync,
            ],
            isCurrentPlan: trialStatus.isInTrial,
            onSelect: null, // Can't select free plan
          ),
          const SizedBox(height: 16),

          // Pro Plan
          _PlanCard(
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
            isCurrentPlan: !trialStatus.isInTrial && trialStatus.isActive,
            isRecommended: true,
            onSelect: () => _handleUpgrade(context, l10n),
          ),
          const SizedBox(height: 32),

          // FAQ Section
          Text(
            l10n.subscriptionFaq,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _FaqItem(
            question: l10n.subscriptionFaqTrialEndQuestion,
            answer: l10n.subscriptionFaqTrialEndAnswer,
          ),
          _FaqItem(
            question: l10n.subscriptionFaqCancelQuestion,
            answer: l10n.subscriptionFaqCancelAnswer,
          ),
          _FaqItem(
            question: l10n.subscriptionFaqDataSafeQuestion,
            answer: l10n.subscriptionFaqDataSafeAnswer,
          ),
        ],
      ),
    );
  }

}

/// Card showing current subscription status
class _StatusCard extends StatelessWidget {
  final TrialStatus trialStatus;

  const _StatusCard({required this.trialStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    Color backgroundColor;
    Color borderColor;
    IconData icon;

    switch (trialStatus.accountStatus) {
      case AccountStatus.trial:
        backgroundColor = Colors.blue.shade50;
        borderColor = Colors.blue.shade200;
        icon = Icons.access_time_rounded;
        break;
      case AccountStatus.active:
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green.shade200;
        icon = Icons.check_circle_rounded;
        break;
      case AccountStatus.trialExpired:
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red.shade200;
        icon = Icons.warning_amber_rounded;
        break;
      case AccountStatus.suspended:
        backgroundColor = Colors.grey.shade100;
        borderColor = Colors.grey.shade300;
        icon = Icons.block_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: borderColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.subscriptionCurrentStatus,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trialStatus.statusText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (trialStatus.isInTrial &&
                    trialStatus.trialExpiresAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.subscriptionExpires(
                      _formatDate(trialStatus.trialExpiresAt!),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Card showing a subscription plan
class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isCurrentPlan;
  final bool isRecommended;
  final VoidCallback? onSelect;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    this.isCurrentPlan = false,
    this.isRecommended = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended ? theme.primaryColor : Colors.grey.shade200,
          width: isRecommended ? 2 : 1,
        ),
        boxShadow: isRecommended
            ? [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Text(
                l10n.subscriptionRecommended,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isCurrentPlan)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.subscriptionCurrent,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        period,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(feature),
                      ],
                    ),
                  ),
                ),
                if (onSelect != null && !isCurrentPlan) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSelect,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.subscriptionUpgradeNow),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// FAQ item widget
class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.answer,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
