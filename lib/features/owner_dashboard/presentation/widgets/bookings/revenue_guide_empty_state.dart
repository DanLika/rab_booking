import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/config/router_owner.dart';
import '../../../../../core/theme/app_shadows.dart';

class RevenueGuideEmptyState extends ConsumerWidget {
  const RevenueGuideEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rocket_launch_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            )
                .animate()
                .scale(duration: 500.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // Title & Subtitle
            Text(
              l10n.revenueGuideTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 8),

            Text(
              l10n.revenueGuideSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 32),

            // Action Cards
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  _ActionCard(
                    icon: Icons.sync_alt_rounded,
                    title: l10n.revenueGuideActionIcal,
                    subtitle: l10n.revenueGuideActionIcalDesc,
                    onTap: () => context.push(OwnerRoutes.icalImport),
                    delay: 400.ms,
                  ),
                  const SizedBox(height: 16),
                  _ActionCard(
                    icon: Icons.code_rounded,
                    title: l10n.revenueGuideActionWidget,
                    subtitle: l10n.revenueGuideActionWidgetDesc,
                    onTap: () => context.push(OwnerRoutes.guideEmbedWidget),
                    delay: 500.ms,
                  ),
                  const SizedBox(height: 16),
                  _ActionCard(
                    icon: Icons.share_rounded,
                    title: l10n.revenueGuideActionShare,
                    subtitle: l10n.revenueGuideActionShareDesc,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.revenueGuideActionShare),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    delay: 600.ms,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Duration delay;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt()),
        ),
        boxShadow: isDark ? AppShadows.elevation1Dark : AppShadows.elevation1,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(delay: delay)
    .slideX(begin: 0.1, end: 0, delay: delay);
  }
}
