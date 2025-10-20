import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/navigation_helpers.dart';
import '../providers/auth_notifier.dart';

/// Email Verification screen
/// Shown after user registers to verify their email
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({
    this.email,
    super.key,
  });

  final String? email;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isResending = false;
  bool _emailResent = false;

  Future<void> _handleResendEmail() async {
    if (widget.email == null) return;

    setState(() => _isResending = true);

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .resendVerificationEmail(widget.email!);

      if (mounted) {
        setState(() {
          _emailResent = true;
          _isResending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email za potvrdu je ponovo poslan!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _emailResent = false);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResending = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Potvrdite Email'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 24 : 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.email_outlined,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Provjerite svoj email',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    widget.email != null
                        ? 'Poslali smo email za potvrdu na:\n${widget.email}'
                        : 'Poslali smo vam email sa linkom za potvrdu računa.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: context.textColorSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Info Card
                  Card(
                    elevation: 0,
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sljedeći koraci:',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildStep('1', 'Otvorite svoj email inbox'),
                          _buildStep('2', 'Pronađite email od RAB Booking'),
                          _buildStep('3', 'Kliknite na link za potvrdu'),
                          _buildStep(
                              '4', 'Prijavite se sa svojim podacima'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Resend Email Section
                  Text(
                    'Niste dobili email?',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Resend Button
                  OutlinedButton.icon(
                    onPressed: _isResending || _emailResent || widget.email == null
                        ? null
                        : _handleResendEmail,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: _isResending
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.textColorSecondary,
                            ),
                          )
                        : Icon(
                            _emailResent ? Icons.check : Icons.refresh,
                            size: 20,
                          ),
                    label: Text(
                      _emailResent
                          ? 'Email poslan!'
                          : _isResending
                              ? 'Šaljem...'
                              : 'Pošalji ponovo',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Help Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Provjerite i spam folder ako ne vidite email nakon nekoliko minuta.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.orange.shade900,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: context.dividerColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'ili',
                          style: TextStyle(color: context.textColorSecondary),
                        ),
                      ),
                      Expanded(child: Divider(color: context.dividerColor)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Back to Login
                  TextButton.icon(
                    onPressed: () => context.goToLogin(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Povratak na prijavu'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
