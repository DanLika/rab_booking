import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/onboarding_provider.dart';

/// Welcome screen shown BEFORE login/register for first-time users
/// This introduces the onboarding wizard
class OnboardingWelcomeScreen extends ConsumerWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.authPrimary.withValues(alpha: 0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo or Icon
                    const Icon(Icons.hotel, size: 100, color: AppColors.authPrimary),
                    const SizedBox(height: 32),

                    // Welcome Title
                    Text(
                      l10n.onboardingWelcomeTitle,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.authPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      l10n.onboardingWelcomeSubtitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Description
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.onboardingWhatYouWillLearn,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureItem(
                              icon: Icons.home_work,
                              title: l10n.onboardingCreateProperty,
                              description: l10n.onboardingCreatePropertyDesc,
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureItem(
                              icon: Icons.meeting_room,
                              title: l10n.onboardingSetupUnits,
                              description: l10n.onboardingSetupUnitsDesc,
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureItem(
                              icon: Icons.euro,
                              title: l10n.onboardingSetupPricing,
                              description: l10n.onboardingSetupPricingDesc,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Start Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go(OwnerRoutes.onboardingWizard),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.authPrimary,
                          foregroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.onboardingStart,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Skip Button
                    TextButton(
                      onPressed: () => _showSkipDialog(context, ref, l10n),
                      child: Text(l10n.onboardingSkipForNow, style: TextStyle(color: Colors.grey[600])),
                    ),
                    const SizedBox(height: 24),

                    // Login/Register Links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.onboardingAlreadyHaveAccount, style: TextStyle(color: Colors.grey[600])),
                        TextButton(onPressed: () => context.go(OwnerRoutes.login), child: Text(l10n.onboardingSignIn)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.authPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showSkipDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.onboardingSkipTitle),
        content: Text(l10n.onboardingSkipDesc),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text(l10n.onboardingSkip),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Skip onboarding
      await ref.read(onboardingNotifierProvider.notifier).skip();

      // Redirect to login
      if (context.mounted) {
        context.go(OwnerRoutes.login);
      }
    }
  }
}
