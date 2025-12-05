import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/config/router_owner.dart';
import '../widgets/owner_app_drawer.dart';

/// Stripe Connect setup screen for property owners
/// Allows owners to connect their Stripe account to receive payments
class StripeConnectSetupScreen extends ConsumerStatefulWidget {
  const StripeConnectSetupScreen({super.key});

  @override
  ConsumerState<StripeConnectSetupScreen> createState() => _StripeConnectSetupScreenState();
}

class _StripeConnectSetupScreenState extends ConsumerState<StripeConnectSetupScreen> {
  bool _isLoading = false;
  String? _stripeAccountId;
  String? _stripeAccountStatus;

  @override
  void initState() {
    super.initState();
    _loadStripeAccountInfo();
  }

  Future<void> _loadStripeAccountInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Call Cloud Function to get Stripe account status
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('getStripeAccountStatus');

      final result = await callable.call();
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
    } catch (e) {
      LoggingService.log('Error loading account info', tag: 'StripeConnect');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _connectStripeAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Call Cloud Function to create Stripe Connect account link
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('createStripeConnectAccount');

      // Get current URL for return/refresh URLs
      // Use authority (host:port) instead of just host to include port number
      final currentUri = Uri.base;
      final baseUrl = '${currentUri.scheme}://${currentUri.authority}';
      final returnUrl = '$baseUrl/owner/stripe-return';
      final refreshUrl = '$baseUrl/owner/stripe-refresh';

      final result = await callable.call({'returnUrl': returnUrl, 'refreshUrl': refreshUrl});

      final data = result.data as Map<String, dynamic>;
      final success = data['success'] == true;
      final onboardingUrl = data['onboardingUrl'] as String?;

      if (success && onboardingUrl != null) {
        // Launch Stripe onboarding URL
        final uri = Uri.parse(onboardingUrl);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (!launched && mounted) {
          final l10n = AppLocalizations.of(context);
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            l10n.stripeCannotOpenPage,
            userMessage: l10n.stripeCannotOpenPageDesc,
          );
        }
      } else if (mounted) {
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          l10n.stripeCreateAccountError,
          userMessage: l10n.stripeCreateAccountError,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      LoggingService.log('Error connecting account', tag: 'StripeConnect');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: l10n.stripeConnectError);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Hardcoded horizontal gradient colors (left → right)
    const gradientStart = Color(0xFF6B4CE6); // Purple
    const gradientEnd = Color(0xFF7E5FEE); // Lighter purple

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [gradientStart, gradientEnd])),
          child: AppBar(
            title: Text(
              l10n.stripeTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Menu',
              ),
            ),
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
          ),
        ),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'integrations/stripe'),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [gradientStart, gradientEnd])),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status card
                    _buildStatusCard(theme, l10n),

                    const SizedBox(height: 24),

                    // Info section
                    _buildInfoSection(l10n),

                    const SizedBox(height: 32),

                    // Action button
                    if (_stripeAccountId == null)
                      FilledButton.icon(
                        onPressed: _connectStripeAccount,
                        icon: const Icon(Icons.link, size: 20),
                        label: Text(
                          l10n.stripeConnectAccount,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    else if (_stripeAccountStatus != 'complete')
                      FilledButton.icon(
                        onPressed: _connectStripeAccount,
                        icon: const Icon(Icons.pending, size: 20),
                        label: Text(
                          l10n.stripeFinishSetup,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Help link
                    TextButton.icon(
                      onPressed: () => context.go(OwnerRoutes.guideStripe),
                      icon: const Icon(Icons.help_outline, color: Colors.white),
                      label: Text(l10n.stripeHowItWorks, style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, AppLocalizations l10n) {
    final isDark = theme.brightness == Brightness.dark;
    const cardColorDark = Color(0xFF2D2D2D);
    const confirmedGreen = Color(0xFF66BB6A);
    const pendingOrange = Color(0xFFFFA726);

    final cardColor = isDark ? cardColorDark : AppColors.surfaceLight;
    final textSecondary = isDark ? Colors.white70 : AppColors.textSecondaryLight;
    final textTertiary = isDark ? Colors.white54 : AppColors.textTertiaryLight;

    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusDescription;

    if (_stripeAccountId == null) {
      statusColor = isDark ? textTertiary : AppColors.textTertiaryLight;
      statusIcon = Icons.warning_amber_rounded;
      statusTitle = l10n.stripeNotConnected;
      statusDescription = l10n.stripeNotConnectedDesc;
    } else if (_stripeAccountStatus != 'complete') {
      statusColor = pendingOrange;
      statusIcon = Icons.pending;
      statusTitle = l10n.stripeSetupInProgress;
      statusDescription = l10n.stripeSetupInProgressDesc;
    } else {
      statusColor = confirmedGreen;
      statusIcon = Icons.check_circle;
      statusTitle = l10n.stripeActive;
      statusDescription = l10n.stripeActiveDesc;
    }

    final borderColor = isDark
        ? statusColor.withAlpha((0.3 * 255).toInt())
        : statusColor.withAlpha((0.3 * 255).toInt());

    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: statusColor.withAlpha((0.2 * 255).toInt()),
              child: Icon(statusIcon, color: statusColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusTitle,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                  const SizedBox(height: 4),
                  Text(statusDescription, style: TextStyle(fontSize: 14, color: textSecondary)),
                  if (_stripeAccountId != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'ID: $_stripeAccountId',
                      style: TextStyle(fontSize: 12, color: textTertiary, fontFamily: 'monospace'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.stripeWhyConnect,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        _buildInfoItem(Icons.credit_card, l10n.stripeReceivePayments, l10n.stripeReceivePaymentsDesc),
        _buildInfoItem(Icons.security, l10n.stripeSecurity, l10n.stripeSecurityDesc),
        _buildInfoItem(Icons.flash_on, l10n.stripeInstantConfirmations, l10n.stripeInstantConfirmationsDesc),
        _buildInfoItem(Icons.money_off, l10n.stripeNoHiddenFees, l10n.stripeNoHiddenFeesDesc),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 13, color: Colors.white.withAlpha((0.85 * 255).toInt()))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
