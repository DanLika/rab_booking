import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';

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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.getElevation(1, isDark: theme.brightness == Brightness.dark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            // TIP 1: JEDNOSTAVNI DIJAGONALNI GRADIENT (2 boje, 2 stops)
            // topRight → bottomLeft za section
            gradient: context.gradients.sectionBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.borderColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                _buildSectionHeader(theme),
                const SizedBox(height: 8),
                Text(
                  'Configure guest email verification settings',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.textColorSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),

                // Verification toggle
                SwitchListTile(
                  value: requireEmailVerification,
                  onChanged: onChanged,
                  title: const Text('Require Email Verification'),
                  subtitle: const Text(
                    'Guest must verify their email address before completing booking',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),

                // Info message
                _buildInfoMessage(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(
              (0.12 * 255).toInt(),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.verified_user,
            color: theme.colorScheme.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Email Verification',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.info,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              requireEmailVerification
                  ? 'Verification button will be shown in Step 2 of the booking flow. Guests cannot proceed without verifying their email.'
                  : 'Email verification is disabled. Guests can complete bookings without verifying their email address.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.7 * 255).toInt(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
