import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design_tokens/animation_tokens.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/platform_scroll_physics.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/common_app_bar.dart';
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
                            maxWidth: isDesktop ? 1200.0 : double.infinity,
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

    // Status-based styling
    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusDescription;
    String? actionLabel;
    VoidCallback? actionOnPressed;

    if (_isConnected) {
      statusColor = const Color(0xFF4CAF50);
      statusIcon = Icons.check_circle;
      statusTitle = l10n.stripeActive;
      statusDescription = l10n.stripeActiveDesc;
    } else if (_isIncomplete) {
      statusColor = const Color(0xFFFFA726);
      statusIcon = Icons.pending;
      statusTitle = l10n.stripeSetupInProgress;
      statusDescription = l10n.stripeSetupInProgressDesc;
      actionLabel = l10n.stripeFinishSetup;
      actionOnPressed = _isConnecting ? null : _connectStripeAccount;
    } else {
      statusColor = theme.colorScheme.primary;
      statusIcon = Icons.payment;
      statusTitle = l10n.stripeNotConnected;
      statusDescription = l10n.stripeNotConnectedDesc;
      actionLabel = l10n.stripeConnectAccount;
      actionOnPressed = _isConnecting ? null : _connectStripeAccount;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: context.gradients.brandPrimary,
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
                    color: Colors.white.withAlpha((0.2 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha((0.9 * 255).toInt()),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statusDescription,
                        style: TextStyle(
                          color: Colors.white.withAlpha((0.9 * 255).toInt()),
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
                  color: Colors.white.withAlpha((0.15 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 16,
                      color: Colors.white.withAlpha((0.8 * 255).toInt()),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ID: $_stripeAccountId',
                      style: TextStyle(
                        color: Colors.white.withAlpha((0.9 * 255).toInt()),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: actionOnPressed,
                  icon: _isConnecting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isIncomplete ? Icons.arrow_forward : Icons.link,
                          size: 20,
                        ),
                  label: Text(
                    actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            // Disconnect button (when connected)
            if (_isConnected) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isConnecting
                      ? null
                      : () => _confirmDisconnect(context),
                  icon: const Icon(Icons.link_off, size: 20),
                  label: Text(
                    l10n.stripeDisconnect,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withAlpha((0.5 * 255).toInt()),
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final benefits = [
      (
        Icons.credit_card,
        l10n.stripeReceivePayments,
        l10n.stripeReceivePaymentsDesc,
      ),
      (Icons.security, l10n.stripeSecurity, l10n.stripeSecurityDesc),
      (
        Icons.flash_on,
        l10n.stripeInstantConfirmations,
        l10n.stripeInstantConfirmationsDesc,
      ),
      (Icons.money_off, l10n.stripeNoHiddenFees, l10n.stripeNoHiddenFeesDesc),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                l10n.stripeWhyConnect,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...benefits.map((b) => _buildBenefitItem(context, b.$1, b.$2, b.$3)),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    IconData icon,
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
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
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
        Icons.account_circle,
        l10n.stripeGuideStep1Title,
        l10n.stripeGuideStep1Desc,
      ),
      (
        2,
        Icons.assignment_turned_in,
        l10n.stripeGuideStep2Title,
        l10n.stripeGuideStep2Desc,
      ),
      (3, Icons.link, l10n.stripeGuideStep3Title, l10n.stripeGuideStep3Desc),
      (
        4,
        Icons.settings,
        l10n.stripeGuideStep4Title,
        l10n.stripeGuideStep4Desc,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.checklist,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.stripeGuideHeaderTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark
                ? AppColors.sectionDividerDark
                : AppColors.sectionDividerLight,
          ),
          // Steps
          ...steps.map((s) => _buildStepItem(context, s.$1, s.$2, s.$3, s.$4)),
        ],
      ),
    );
  }

  Widget _buildStepItem(
    BuildContext context,
    int number,
    IconData icon,
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
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
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

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Column(
        children: [
          // Header (clickable)
          InkWell(
            onTap: () => setState(() => _showFaq = !_showFaq),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.question_answer,
                    color: theme.colorScheme.primary,
                    size: 22,
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
                  Icon(
                    _showFaq ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          // FAQ items
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
                  .slideY(
                    duration: Duration(milliseconds: 800 + (index * 150)),
                    curve: AnimationTokens.easeInOut,
                    begin: 0,
                    end: -20,
                  )
                  .fade(
                    duration: Duration(milliseconds: 800 + (index * 150)),
                    curve: AnimationTokens.easeInOut,
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
