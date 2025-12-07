import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/design_tokens/gradient_tokens.dart';

/// Email Verification Settings Card
///
/// Extracted from widget_advanced_settings_screen.dart to reduce nesting.
/// Contains toggle for requiring email verification before booking completion.
class EmailVerificationCard extends StatelessWidget {
  final bool requireEmailVerification;
  final ValueChanged<bool> onChanged;
  final bool isMobile;

  const EmailVerificationCard({
    super.key,
    required this.requireEmailVerification,
    required this.onChanged,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.getElevation(1, isDark: theme.brightness == Brightness.dark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.gradients.sectionBorder, width: 1.5),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                _buildSectionHeader(theme, l10n),
                const SizedBox(height: 8),
                Text(
                  l10n.emailVerificationSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: context.textColorSecondary, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Compact toggle with inline layout
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.emailVerificationToggleTitle,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            l10n.emailVerificationToggleSubtitle,
                            style: theme.textTheme.bodySmall?.copyWith(color: context.textColorSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: requireEmailVerification,
                      onChanged: onChanged,
                      activeThumbColor: theme.colorScheme.primary,
                    ),
                  ],
                ),

                // Compact info message
                if (requireEmailVerification) ...[const SizedBox(height: 12), _buildInfoMessage(theme, l10n)],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.verified_user, color: theme.colorScheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.emailVerificationTitle,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                height: 2,
                width: 40,
                decoration: BoxDecoration(
                  gradient: GradientTokens.brandPrimary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoMessage(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha((0.08 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withAlpha((0.2 * 255).toInt())),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.emailVerificationInfoEnabled,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt())),
            ),
          ),
        ],
      ),
    );
  }
}
