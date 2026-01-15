import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/config/router_owner.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/card.dart';

/// Unit Hub Empty State
///
/// Displays a beautiful, animated onboarding screen when the owner
/// has no properties or units yet. Encourages adding the first property.
class UnitHubEmptyState extends StatelessWidget {
  const UnitHubEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeroSection(context, l10n),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildBenefitsSection(context, isDark, l10n),
            ),
          ),
          const SizedBox(height: 24),
          _buildCtaSection(context, l10n),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 80),
      decoration: BoxDecoration(gradient: context.gradients.brandPrimary),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.apartment_rounded,
              size: 48,
              color: Colors.white,
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            l10n.unitHubEmptyWelcome,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            l10n.unitHubEmptyDescription,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive layout: Column on mobile, Row on tablet/desktop
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildBenefitCard(
                context,
                icon: Icons.public,
                title: l10n.unitHubBenefitVisibilityTitle,
                description: l10n.unitHubBenefitVisibilityDesc,
                delay: 400.ms,
              ),
              const SizedBox(height: 16),
              _buildBenefitCard(
                context,
                icon: Icons.auto_awesome,
                title: l10n.unitHubBenefitAutomationTitle,
                description: l10n.unitHubBenefitAutomationDesc,
                delay: 500.ms,
              ),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildBenefitCard(
                  context,
                  icon: Icons.public,
                  title: l10n.unitHubBenefitVisibilityTitle,
                  description: l10n.unitHubBenefitVisibilityDesc,
                  delay: 400.ms,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildBenefitCard(
                  context,
                  icon: Icons.auto_awesome,
                  title: l10n.unitHubBenefitAutomationTitle,
                  description: l10n.unitHubBenefitAutomationDesc,
                  delay: 500.ms,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildBenefitCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Duration delay,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumCard.elevated(
      elevation: 4,
      borderRadius: 16,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay).slideY(begin: 0.2, end: 0);
  }

  Widget _buildCtaSection(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        children: [
          Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => context.push(OwnerRoutes.propertyNew),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_business, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        l10n.unitHubAddFirstProperty,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(
                begin: 1.0,
                end: 1.05,
                duration: 1500.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                l10n.unitHubNeedHelp,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
