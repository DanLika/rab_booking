import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/config/router_owner.dart';

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
      final currentUri = Uri.base;
      final returnUrl = '${currentUri.scheme}://${currentUri.host}/owner/stripe-return';
      final refreshUrl = '${currentUri.scheme}://${currentUri.host}/owner/stripe-refresh';

      final result = await callable.call({
        'returnUrl': returnUrl,
        'refreshUrl': refreshUrl,
      });

      final data = result.data as Map<String, dynamic>;
      final success = data['success'] == true;
      final onboardingUrl = data['onboardingUrl'] as String?;

      if (success && onboardingUrl != null) {
        // Launch Stripe onboarding URL
        final uri = Uri.parse(onboardingUrl);
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched && mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            'Ne mogu otvoriti Stripe stranicu',
            userMessage: 'Ne mogu otvoriti Stripe stranicu. Pokušajte ponovo.',
          );
        }
      } else if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          'Greška prilikom kreiranja Stripe računa',
          userMessage: 'Greška prilikom kreiranja Stripe računa.',
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
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška prilikom povezivanja Stripe računa',
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe Plaćanja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => context.go(OwnerRoutes.guideStripe),
            tooltip: 'Pomoć',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.payment,
                          size: 32,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stripe Connect',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Prijem plaćanja karticama',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Status card
                  _buildStatusCard(),

                  const SizedBox(height: 24),

                  // Info section
                  _buildInfoSection(),

                  const SizedBox(height: 32),

                  // Action button
                  if (_stripeAccountId == null)
                    ElevatedButton(
                      onPressed: _connectStripeAccount,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.indigo,
                      ),
                      child: const Text(
                        'Poveži Stripe Račun',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  else if (_stripeAccountStatus != 'complete')
                    ElevatedButton(
                      onPressed: _connectStripeAccount,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text(
                        'Završi Stripe Setup',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Help link
                  TextButton.icon(
                    onPressed: () => context.go(OwnerRoutes.guideStripe),
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Kako funkcionira Stripe Connect?'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusDescription;

    if (_stripeAccountId == null) {
      statusColor = Colors.grey;
      statusIcon = Icons.warning_amber_rounded;
      statusTitle = 'Nije povezano';
      statusDescription = 'Stripe račun nije povezan. Prijem plaćanja nije moguć.';
    } else if (_stripeAccountStatus != 'complete') {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusTitle = 'Setup u toku';
      statusDescription = 'Završite Stripe setup da biste mogli primati plaćanja.';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusTitle = 'Aktivno';
      statusDescription = 'Stripe račun je povezan. Možete primati plaćanja!';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withAlpha((0.3 * 255).toInt()), width: 2),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (_stripeAccountId != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'ID: $_stripeAccountId',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
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

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Zašto Stripe Connect?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          Icons.credit_card,
          'Prijem plaćanja',
          'Primajte plaćanja karticama direktno na vaš račun',
        ),
        _buildInfoItem(
          Icons.security,
          'Sigurnost',
          'PCI-DSS komplijantan sistem za sigurne transakcije',
        ),
        _buildInfoItem(
          Icons.flash_on,
          'Instant potvrde',
          'Automatska potvrda rezervacija nakon uspješne uplate',
        ),
        _buildInfoItem(
          Icons.money_off,
          'Nema skrivenih troškova',
          'Stripe naplaćuje ~2.9% + €0.30 po transakciji',
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
