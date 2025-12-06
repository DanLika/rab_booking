import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/config/router_owner.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../widgets/owner_app_drawer.dart';

/// Stripe Integration Guide Screen
/// Interactive step-by-step guide for connecting Stripe payments
class StripeGuideScreen extends StatefulWidget {
  const StripeGuideScreen({super.key});

  @override
  State<StripeGuideScreen> createState() => _StripeGuideScreenState();
}

class _StripeGuideScreenState extends State<StripeGuideScreen> {
  int? _expandedStep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: const OwnerAppDrawer(currentRoute: 'guides/stripe'),
      appBar: CommonAppBar(
        title: l10n.stripeGuideTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: context.gradients.brandPrimary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((0.2 * 255).toInt()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.payment, size: 32, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.stripeGuideHeaderTitle,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.stripeGuideHeaderSubtitle,
                                  style: TextStyle(fontSize: 14, color: Colors.white.withAlpha((0.9 * 255).toInt())),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.stripeGuideHeaderTip,
                        style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white.withAlpha((0.9 * 255).toInt())),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Step 1: Create Stripe Account
              _buildStep(
                stepNumber: 1,
                title: l10n.stripeGuideStep1Title,
                icon: Icons.account_circle,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.stripeGuideStep1Desc, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildBulletPoint(l10n.stripeGuideStep1Bullet1),
                    _buildBulletPoint(l10n.stripeGuideStep1Bullet2),
                    _buildBulletPoint(l10n.stripeGuideStep1Bullet3),
                    _buildBulletPoint(l10n.stripeGuideStep1Bullet4),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final theme = Theme.of(context);
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.colorScheme.primary.withAlpha((0.3 * 255).toInt())),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.stripeGuideStep1Note,
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildPlaceholder('Slika: Stripe registracija ekran'),
                  ],
                ),
              ),

              // Step 2: Complete Stripe Onboarding
              _buildStep(
                stepNumber: 2,
                title: l10n.stripeGuideStep2Title,
                icon: Icons.assignment_turned_in,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.stripeGuideStep2Desc, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildBulletPoint(l10n.stripeGuideStep2Bullet1),
                    _buildBulletPoint(l10n.stripeGuideStep2Bullet2),
                    _buildBulletPoint(l10n.stripeGuideStep2Bullet3),
                    _buildBulletPoint(l10n.stripeGuideStep2Bullet4),
                    _buildBulletPoint(l10n.stripeGuideStep2Bullet5),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.stripeGuideStep2Warning,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPlaceholder('Slika: Stripe onboarding forma'),
                  ],
                ),
              ),

              // Step 3: Connect in Owner App
              _buildStep(
                stepNumber: 3,
                title: l10n.stripeGuideStep3Title,
                icon: Icons.link,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.stripeGuideStep3Desc, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildBulletPoint(l10n.stripeGuideStep3Bullet1),
                    _buildBulletPoint(l10n.stripeGuideStep3Bullet2),
                    _buildBulletPoint(l10n.stripeGuideStep3Bullet3),
                    _buildBulletPoint(l10n.stripeGuideStep3Bullet4),
                    _buildBulletPoint(l10n.stripeGuideStep3Bullet5),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final theme = Theme.of(context);
                        final l10n = AppLocalizations.of(context);
                        return ElevatedButton.icon(
                          onPressed: () {
                            context.go(OwnerRoutes.stripeIntegration);
                          },
                          icon: const Icon(Icons.payment),
                          label: Text(l10n.stripeGuideGoToIntegration),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.all(16),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildPlaceholder('GIF: Proces povezivanja Stripe-a'),
                  ],
                ),
              ),

              // Step 4: Enable Stripe in Widget Settings
              _buildStep(
                stepNumber: 4,
                title: l10n.stripeGuideStep4Title,
                icon: Icons.settings,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.stripeGuideStep4Desc, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildBulletPoint(l10n.stripeGuideStep4Bullet1),
                    _buildBulletPoint(l10n.stripeGuideStep4Bullet2),
                    _buildBulletPoint(l10n.stripeGuideStep4Bullet3),
                    _buildBulletPoint(l10n.stripeGuideStep4Bullet4),
                    _buildBulletPoint(l10n.stripeGuideStep4Bullet5),
                    _buildBulletPoint(l10n.stripeGuideStep4Bullet6),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.stripeGuideStep4Success,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPlaceholder('Slika: Widget settings sa Stripe toggle-om'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // FAQ Section
              _buildFAQSection(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({required int stepNumber, required String title, required IconData icon, required Widget content}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpanded = _expandedStep == stepNumber;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: context.gradients.sectionBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: stepNumber == 1,
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedStep = expanded ? stepNumber : null;
            });
          },
          leading: CircleAvatar(
            backgroundColor: isExpanded
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withAlpha((0.2 * 255).toInt()),
            foregroundColor: isExpanded
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
            child: Text('$stepNumber'),
          ),
          title: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          children: [Padding(padding: const EdgeInsets.all(16), child: content)],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    final theme = Theme.of(context);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withAlpha((0.08 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.onSurface.withAlpha((0.2 * 255).toInt())),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 48, color: theme.colorScheme.onSurface.withAlpha((0.4 * 255).toInt())),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(color: theme.colorScheme.onSurface.withAlpha((0.5 * 255).toInt()), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: context.gradients.sectionBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.question_answer, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.stripeGuideFaq, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildFAQItem(l10n.stripeGuideFaq1Q, l10n.stripeGuideFaq1A),
            _buildFAQItem(l10n.stripeGuideFaq2Q, l10n.stripeGuideFaq2A),
            _buildFAQItem(l10n.stripeGuideFaq3Q, l10n.stripeGuideFaq3A),
            _buildFAQItem(l10n.stripeGuideFaq4Q, l10n.stripeGuideFaq4A),
            _buildFAQItem(l10n.stripeGuideFaq5Q, l10n.stripeGuideFaq5A),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('❓ $question', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
