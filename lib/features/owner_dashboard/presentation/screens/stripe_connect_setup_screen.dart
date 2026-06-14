import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/platform_scroll_physics.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/redesign.dart';
import '../widgets/owner_app_drawer.dart';

/// Stripe Connect setup screen for property owners
/// Redesigned: Premium feel with consistent theme support
class StripeConnectSetupScreen extends ConsumerStatefulWidget {
  const StripeConnectSetupScreen({super.key});

  @override
  ConsumerState<StripeConnectSetupScreen> createState() =>
      _StripeConnectSetupScreenState();
}

class _StripeConnectSetupScreenState
    extends ConsumerState<StripeConnectSetupScreen> {
  bool _isLoading = true;
  bool _isConnecting = false;
  String? _stripeAccountId;
  String? _stripeAccountStatus;
  int? _expandedStep;
  bool _showFaq = false;

  @override
  void initState() {
    super.initState();
    _loadStripeAccountInfo();
  }

  Future<void> _loadStripeAccountInfo() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('getStripeAccountStatus');
      final result = await callable.call().withCloudFunctionTimeout(
        'getStripeAccountStatus',
      );
      final data = result.data as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          if (data['connected'] == true) {
            _stripeAccountId = data['accountId'] as String?;
            final isOnboarded = data['onboarded'] == true;
            _stripeAccountStatus = isOnboarded ? 'complete' : 'incomplete';
          } else {
            _stripeAccountId = null;
            _stripeAccountStatus = null;
          }
          _isLoading = false;
        });
      }
    } on TimeoutException {
      // Timeout already logged by withCloudFunctionTimeout
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          'Request timed out. Please check your connection and try again.',
        );
      }
    } catch (e, stackTrace) {
      await LoggingService.logError(
        'Failed to load Stripe account info',
        e,
        stackTrace,
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _connectStripeAccount() async {
    setState(() => _isConnecting = true);

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('createStripeConnectAccount');

      // On mobile apps, Uri.base returns empty/invalid URL
      // Use hardcoded production URL as fallback
      String baseUrl;
      final currentUri = Uri.base;
      if (currentUri.scheme.isNotEmpty && currentUri.authority.isNotEmpty) {
        baseUrl = '${currentUri.scheme}://${currentUri.authority}';
      } else {
        // Mobile app fallback - use production owner dashboard URL
        baseUrl = 'https://app.bookbed.io';
      }
      final returnUrl = '$baseUrl/owner/stripe-return';
      final refreshUrl = '$baseUrl/owner/stripe-refresh';

      final result = await callable
          .call({'returnUrl': returnUrl, 'refreshUrl': refreshUrl})
          .withCloudFunctionTimeout('createStripeConnectAccount');
      final data = result.data as Map<String, dynamic>;
      final success = data['success'] == true;
      final onboardingUrl = data['onboardingUrl'] as String?;

      if (success && onboardingUrl != null) {
        final uri = Uri.parse(onboardingUrl);
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched && mounted) {
          final l10n = AppLocalizations.of(context);
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            l10n.stripeCannotOpenPage,
          );
        }
      } else if (mounted) {
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          l10n.stripeCreateAccountError,
        );
      }
    } on TimeoutException {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          'Request timed out. Please check your connection and try again.',
        );
      }
    } catch (e, stackTrace) {
      await LoggingService.logError(
        'Failed to connect Stripe account',
        e,
        stackTrace,
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.stripeConnectError,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  bool get _isConnected =>
      _stripeAccountId != null && _stripeAccountStatus == 'complete';
  bool get _isIncomplete =>
      _stripeAccountId != null && _stripeAccountStatus != 'complete';

  Future<void> _confirmDisconnect(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.stripeDisconnectTitle),
        content: Text(l10n.stripeDisconnectMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text(l10n.stripeDisconnectConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _disconnectStripeAccount();
    }
  }

  Future<void> _disconnectStripeAccount() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isConnecting = true);

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('disconnectStripeAccount');
      final result = await callable.call().withCloudFunctionTimeout(
        'disconnectStripeAccount',
      );
      final data = result.data as Map<String, dynamic>;
      final success = data['success'] == true;

      if (mounted) {
        if (success) {
          setState(() {
            _stripeAccountId = null;
            _stripeAccountStatus = null;
          });
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10n.stripeDisconnectSuccess,
          );
        } else {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            l10n.stripeDisconnectError,
          );
        }
      }
    } on TimeoutException {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          'Request timed out. Please check your connection and try again.',
        );
      }
    } catch (e, stackTrace) {
      await LoggingService.logError(
        'Failed to disconnect Stripe account',
        e,
        stackTrace,
      );
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.stripeDisconnectError,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.stripeTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'integrations/stripe'),
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: _isLoading
            ? const Center(child: _MoneyLoadingAnimation())
            : RefreshIndicator(
                onRefresh: _loadStripeAccountInfo,
                color: theme.colorScheme.primary,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 900;
                    final isTablet = constraints.maxWidth > 600;
                    final horizontalPadding = isDesktop
                        ? 48.0
                        : (isTablet ? 32.0 : 16.0);

                    return SingleChildScrollView(
                      physics: PlatformScrollPhysics.adaptive,
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 20,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            // Page content clamp — center on tablet+desktop
                            // web (was isDesktop ? 1200 : infinity → tablet
                            // stretched edge-to-edge).
                            maxWidth: 1000,
                            minHeight: constraints.maxHeight - 40,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Hero card - always full width
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isDesktop ? 800.0 : double.infinity,
                                ),
                                child: _buildHeroCard(context),
                              ),
                              const SizedBox(height: 24),

                              // Premium payouts dashboard — kDebug-gated
                              // (see _StripePayoutsDashboard for rationale).
                              // Renders only when Stripe account is connected.
                              if (_isConnected) ...[
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: isDesktop
                                        ? 800.0
                                        : double.infinity,
                                  ),
                                  child: const _StripePayoutsDashboard(),
                                ),
                              ],

                              // Desktop: Benefits + Steps/FAQ side by side
                              if (isDesktop) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left column: Benefits
                                    Expanded(
                                      child: _buildBenefitsSection(context),
                                    ),
                                    const SizedBox(width: 24),
                                    // Right column: Steps (if not connected) or FAQ
                                    Expanded(
                                      child: !_isConnected
                                          ? _buildStepsSection(context)
                                          : _buildFaqSection(context),
                                    ),
                                  ],
                                ),
                                if (!_isConnected) ...[
                                  const SizedBox(height: 24),
                                  _buildFaqSection(context),
                                ],
                              ] else ...[
                                // Mobile/Tablet: Stack vertically
                                _buildBenefitsSection(context),
                                const SizedBox(height: 24),
                                if (!_isConnected) ...[
                                  _buildStepsSection(context),
                                  const SizedBox(height: 24),
                                ],
                                _buildFaqSection(context),
                              ],
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Status-based composition — semantic mapping into BbBookingStatus
    // (Stripe Connect lifecycle ≅ booking lifecycle for badge tone)
    IconData statusIcon;
    BbBookingStatus badgeStatus;
    String statusTitle;
    String statusDescription;
    String? actionLabel;
    String? actionIcon;
    VoidCallback? actionOnPressed;

    if (_isConnected) {
      statusIcon = Icons.check_circle;
      badgeStatus = BbBookingStatus.confirmed;
      statusTitle = l10n.stripeActive;
      statusDescription = l10n.stripeActiveDesc;
    } else if (_isIncomplete) {
      statusIcon = Icons.pending;
      badgeStatus = BbBookingStatus.pending;
      statusTitle = l10n.stripeSetupInProgress;
      statusDescription = l10n.stripeSetupInProgressDesc;
      actionLabel = l10n.stripeFinishSetup;
      actionIcon = 'arrow_forward';
      actionOnPressed = _isConnecting ? null : _connectStripeAccount;
    } else {
      statusIcon = Icons.payment;
      badgeStatus = BbBookingStatus.cancelled;
      statusTitle = l10n.stripeNotConnected;
      statusDescription = l10n.stripeNotConnectedDesc;
      actionLabel = l10n.stripeConnectAccount;
      actionIcon = 'link';
      actionOnPressed = _isConnecting ? null : _connectStripeAccount;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? AppShadows.elevation3Dark : AppShadows.elevation3,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusIcon,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: BbStatusBadge(
                          status: badgeStatus,
                          label: statusTitle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statusDescription,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Account ID (if connected)
            if (_stripeAccountId != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ID: $_stripeAccountId',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              BbButton(
                label: actionLabel,
                iconLeft: actionIcon,
                onPressed: actionOnPressed,
                size: BbButtonSize.lg,
                fullWidth: true,
                loading: _isConnecting,
              ),
            ],

            // Disconnect button (when connected)
            if (_isConnected) ...[
              const SizedBox(height: 20),
              BbButton(
                label: l10n.stripeDisconnect,
                iconLeft: 'link_off',
                onPressed: _isConnecting
                    ? null
                    : () => _confirmDisconnect(context),
                variant: BbButtonVariant.secondary,
                size: BbButtonSize.lg,
                fullWidth: true,
                loading: _isConnecting,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final benefits = [
      (
        'credit_card',
        l10n.stripeReceivePayments,
        l10n.stripeReceivePaymentsDesc,
      ),
      ('security', l10n.stripeSecurity, l10n.stripeSecurityDesc),
      (
        'flash_on',
        l10n.stripeInstantConfirmations,
        l10n.stripeInstantConfirmationsDesc,
      ),
      ('money_off', l10n.stripeNoHiddenFees, l10n.stripeNoHiddenFeesDesc),
    ];

    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BbSectionHeader(
            title: l10n.stripeWhyConnect,
            level: BbSectionHeaderLevel.h3,
          ),
          const SizedBox(height: 8),
          ...benefits.map((b) => _buildBenefitItem(context, b.$1, b.$2, b.$3)),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    String iconName,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: BbIcon(name: iconName, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(
                      (0.7 * 255).toInt(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final steps = [
      (
        1,
        'account_circle',
        l10n.stripeGuideStep1Title,
        l10n.stripeGuideStep1Desc,
      ),
      (
        2,
        'assignment_turned_in',
        l10n.stripeGuideStep2Title,
        l10n.stripeGuideStep2Desc,
      ),
      (3, 'link', l10n.stripeGuideStep3Title, l10n.stripeGuideStep3Desc),
      (4, 'settings', l10n.stripeGuideStep4Title, l10n.stripeGuideStep4Desc),
    ];

    return BbCard(
      padded: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: BbSectionHeader(
              title: l10n.stripeGuideHeaderTitle,
              level: BbSectionHeaderLevel.h3,
            ),
          ),
          Divider(
            height: 1,
            color: isDark
                ? AppColors.sectionDividerDark
                : AppColors.sectionDividerLight,
          ),
          ...steps.map((s) => _buildStepItem(context, s.$1, s.$2, s.$3, s.$4)),
        ],
      ),
    );
  }

  Widget _buildStepItem(
    BuildContext context,
    int number,
    String iconName,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);
    final isExpanded = _expandedStep == number;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedStep = isExpanded ? null : number;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isExpanded
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withAlpha(
                          (0.15 * 255).toInt(),
                        ),
                  foregroundColor: isExpanded
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withAlpha(
                          (0.7 * 255).toInt(),
                        ),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                BbIcon(name: iconName, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                BbIcon(
                  name: isExpanded ? 'expand_less' : 'expand_more',
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.5 * 255).toInt(),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(68, 0, 20, 16),
            child: Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.7 * 255).toInt(),
                ),
                height: 1.5,
              ),
            ),
          ),
        if (number < 4)
          Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.sectionDividerDark
                : AppColors.sectionDividerLight,
          ),
      ],
    );
  }

  Widget _buildFaqSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final faqs = [
      (l10n.stripeGuideFaq1Q, l10n.stripeGuideFaq1A),
      (l10n.stripeGuideFaq2Q, l10n.stripeGuideFaq2A),
      (l10n.stripeGuideFaq3Q, l10n.stripeGuideFaq3A),
      (l10n.stripeGuideFaq4Q, l10n.stripeGuideFaq4A),
      (l10n.stripeGuideFaq5Q, l10n.stripeGuideFaq5A),
    ];

    return BbCard(
      padded: false,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showFaq = !_showFaq),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  BbIcon(
                    name: 'question_answer',
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.stripeGuideFaq,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  BbIcon(
                    name: _showFaq ? 'expand_less' : 'expand_more',
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_showFaq) ...[
            Divider(
              height: 1,
              color: isDark
                  ? AppColors.sectionDividerDark
                  : AppColors.sectionDividerLight,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: faqs
                    .map((faq) => _buildFaqItem(context, faq.$1, faq.$2))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('❓', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              answer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.7 * 255).toInt(),
                ),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated money loading widget with floating currency symbols
///
/// Uses flutter_animate for staggered bouncing animations.
class _MoneyLoadingAnimation extends StatelessWidget {
  const _MoneyLoadingAnimation();

  // Currency symbols to animate
  static const _symbols = ['€', '\$', '£', '¥', '₣'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated currency symbols
        SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_symbols.length, (index) {
              return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _symbols[index],
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  )
                  .animate(
                    delay: Duration(milliseconds: index * 120),
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .moveY(
                    duration: Duration(milliseconds: 800 + (index * 150)),
                    curve: BBMotionBridges.easeInOut,
                    begin: 0,
                    end:
                        -20, // 20 pixels max movement (moveY uses absolute pixels)
                  )
                  .fade(
                    delay: Duration.zero, // Run in parallel with moveY
                    duration: Duration(milliseconds: 800 + (index * 150)),
                    curve: BBMotionBridges.easeInOut,
                    begin: 0.4,
                    end: 1.0,
                  );
            }),
          ),
        ),
        const SizedBox(height: 16),
        // Subtle loading indicator
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: primaryColor.withAlpha((0.6 * 255).toInt()),
          ),
        ),
        const SizedBox(height: 16),
        // Loading text
        Text(
          AppLocalizations.of(context).stripeLoadingAccount,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Premium payouts dashboard — payouts.jsx §150 PayoutsDesktop composition.
//
// Renders 3 balance tiles (Available / Pending / Paid this month), a payout
// schedule card (3 rows), and a recent payouts list (3 entries) when the
// Stripe account is connected.
//
// GATED on `bool.fromEnvironment('STRIPE_PAYOUTS')` OR `kDebugMode` because
// the supporting CFs (`getStripeBalance` / `listStripePayouts`) do NOT exist
// yet. Shipping placeholder amounts in prod would misrepresent owner balances
// and break trust. Once Terminal A wires the CFs + provider, swap the static
// data here for a `ref.watch(stripeBalanceProvider)` / `listPayoutsProvider`.
// ============================================================================
class _StripePayoutsDashboard extends StatelessWidget {
  const _StripePayoutsDashboard();

  static const bool _enabled = bool.fromEnvironment('STRIPE_PAYOUTS');

  // Sample placeholder data lifted directly from payouts.jsx so the gated
  // build renders the design intent for dev review without inventing values.
  static const List<_PayoutEntry> _recent = <_PayoutEntry>[
    _PayoutEntry(
      date: '27.05.2026',
      amount: '€420,00',
      ref: 'po_2Kx91',
      dest: 'Zagrebačka banka ····1234',
      paid: true,
    ),
    _PayoutEntry(
      date: '20.05.2026',
      amount: '€288,00',
      ref: 'po_2Kw84',
      dest: 'Zagrebačka banka ····1234',
      paid: false,
    ),
    _PayoutEntry(
      date: '14.05.2026',
      amount: '€540,00',
      ref: 'po_2Kv57',
      dest: 'Zagrebačka banka ····1234',
      paid: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_enabled && !kDebugMode) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StripeBalanceGrid(isMobile: isMobile),
        const SizedBox(height: 16),
        const _PayoutScheduleCard(),
        const SizedBox(height: 16),
        const _RecentPayoutsList(rows: _recent),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PayoutEntry {
  final String date;
  final String amount;
  final String ref;
  final String dest;
  final bool paid;

  const _PayoutEntry({
    required this.date,
    required this.amount,
    required this.ref,
    required this.dest,
    required this.paid,
  });
}

class _StripeBalanceGrid extends StatelessWidget {
  final bool isMobile;
  const _StripeBalanceGrid({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final tiles = <Widget>[
      _BalanceTile(
        icon: 'account_balance_wallet',
        label: 'DOSTUPNO ZA ISPLATU',
        value: '€1.240,00',
        accent: c.success,
        valueColor: c.success,
        sub: 'Isplata sutra',
      ),
      _BalanceTile(
        icon: 'hourglass_top',
        label: 'U OBRADI',
        value: '€288,00',
        accent: c.warning,
        sub: 'Nakon dolaska gosta',
      ),
      _BalanceTile(
        icon: 'payments',
        label: 'ISPLAĆENO (SVIBANJ)',
        value: '€3.840,00',
        accent: c.primary,
        sub: '14 isplata',
      ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: tiles[0]),
              const SizedBox(width: 12),
              Expanded(child: tiles[1]),
            ],
          ),
          const SizedBox(height: 12),
          tiles[2],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: tiles[0]),
        const SizedBox(width: 12),
        Expanded(child: tiles[1]),
        const SizedBox(width: 12),
        Expanded(child: tiles[2]),
      ],
    );
  }
}

class _BalanceTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color accent;
  final Color? valueColor;
  final String? sub;

  const _BalanceTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.valueColor,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(BBRadius.sm),
            ),
            alignment: Alignment.center,
            child: BbIcon(name: icon, size: 19, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: BBType.eyebrow(
              context,
            ).copyWith(color: c.textTertiary, fontSize: 10, letterSpacing: 0.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: BBType.h1Num(context).copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: valueColor ?? c.textPrimary,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(
              sub!,
              style: BBType.caption(
                context,
              ).copyWith(color: c.textTertiary, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _PayoutScheduleCard extends StatelessWidget {
  const _PayoutScheduleCard();

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return BbCard(
      padded: false,
      child: Padding(
        padding: const EdgeInsets.all(BBSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Raspored isplata',
              style: BBType.h3(context).copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: BBSpace.sm),
            _scheduleRow(
              context,
              icon: 'schedule',
              label: 'Učestalost isplata',
              value: 'Automatski · 2 radna dana',
              hasChevron: true,
            ),
            Divider(height: 1, thickness: 1, color: c.border),
            _scheduleRow(
              context,
              icon: 'payments',
              label: 'Minimalni iznos isplate',
              value: '€50,00',
              hasChevron: true,
            ),
            Divider(height: 1, thickness: 1, color: c.border),
            _scheduleRow(
              context,
              icon: 'notifications',
              label: 'Obavijest o svakoj isplati',
              sub: 'Email kad isplata krene prema banci',
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleRow(
    BuildContext context, {
    required String icon,
    required String label,
    String? value,
    String? sub,
    bool hasChevron = false,
  }) {
    final c = BBColor.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(BBRadius.sm),
            ),
            alignment: Alignment.center,
            child: BbIcon(name: icon, size: 18, color: c.primary),
          ),
          const SizedBox(width: BBSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: BBType.label(
                    context,
                  ).copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: BBType.caption(
                      context,
                    ).copyWith(color: c.textTertiary),
                  ),
                ],
              ],
            ),
          ),
          if (value != null)
            Text(
              value,
              style: BBType.label(
                context,
              ).copyWith(color: c.textSecondary, fontWeight: FontWeight.w600),
            ),
          if (hasChevron) ...[
            const SizedBox(width: 4),
            BbIcon(name: 'chevron_right', color: c.textTertiary),
          ],
        ],
      ),
    );
  }
}

class _RecentPayoutsList extends StatelessWidget {
  final List<_PayoutEntry> rows;
  const _RecentPayoutsList({required this.rows});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final rd = BbRedesignTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BbSectionHeader(
          title: 'Nedavne isplate',
          level: BbSectionHeaderLevel.h3,
        ),
        const SizedBox(height: 6),
        BbCard(
          padded: false,
          child: Column(
            children: List<Widget>.generate(rows.length, (int i) {
              final p = rows[i];
              final isLast = i == rows.length - 1;
              final tileBg = p.paid
                  ? rd.statusConfirmedTint
                  : rd.statusPendingTint;
              final tileFg = p.paid
                  ? rd.statusConfirmedDeep
                  : rd.statusPendingDeep;
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isLast ? Colors.transparent : c.border,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BBSpace.md,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: tileBg,
                          borderRadius: BorderRadius.circular(BBRadius.sm),
                        ),
                        alignment: Alignment.center,
                        child: BbIcon(
                          name: p.paid ? 'north_east' : 'hourglass_top',
                          size: 18,
                          color: tileFg,
                        ),
                      ),
                      const SizedBox(width: BBSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Isplata na ${p.dest}',
                              style: BBType.label(context).copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.ref} · ${p.date}',
                              style: BBType.mono(
                                context,
                              ).copyWith(color: c.textTertiary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: BBSpace.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.amount,
                            style: BBType.label(context).copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          BbStatusBadge(
                            status: p.paid
                                ? BbBookingStatus.confirmed
                                : BbBookingStatus.pending,
                            label: p.paid ? 'Isplaćeno' : 'U obradi',
                            dot: false,
                            size: BbStatusBadgeSize.sm,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
