import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/theme/app_colors.dart';

/// Success screen shown after completing onboarding wizard
class OnboardingSuccessScreen extends ConsumerWidget {
  const OnboardingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.success.withAlpha(25), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: AppColors.success.withAlpha(25), shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle, size: 100, color: AppColors.success),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      l10n.onboardingSuccessCongrats,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.success),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      l10n.onboardingSuccessSubtitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    Text(
                      l10n.onboardingSuccessDesc,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // What's Next Section
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lightbulb, color: AppColors.authPrimary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.onboardingSuccessNextSteps,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildNextStep(
                              icon: Icons.meeting_room,
                              title: l10n.onboardingSuccessAddUnits,
                              description: l10n.onboardingSuccessAddUnitsDesc,
                            ),
                            const SizedBox(height: 12),
                            _buildNextStep(
                              icon: Icons.euro,
                              title: l10n.onboardingSuccessSetPrices,
                              description: l10n.onboardingSuccessSetPricesDesc,
                            ),
                            const SizedBox(height: 12),
                            _buildNextStep(
                              icon: Icons.calendar_month,
                              title: l10n.onboardingSuccessViewCalendar,
                              description: l10n.onboardingSuccessViewCalendarDesc,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Go to Dashboard Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go(OwnerRoutes.calendarTimeline),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.authPrimary,
                          foregroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.onboardingSuccessGoToDashboard,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
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

  Widget _buildNextStep({required IconData icon, required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.authPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
