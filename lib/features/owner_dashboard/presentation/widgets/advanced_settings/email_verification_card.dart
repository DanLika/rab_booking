import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../../../core/theme/app_shadows.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.getElevation(1, isDark: isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? const [
                      Color(0xFF1A1A1A), // veryDarkGray
                      Color(0xFF1F1F1F),
                      Color(0xFF242424),
                      Color(0xFF292929),
                      Color(0xFF2D2D2D), // mediumDarkGray
                    ]
                  : const [
                      Color(0xFFF0F0F0), // Lighter grey
                      Color(0xFFF2F2F2),
                      Color(0xFFF5F5F5),
                      Color(0xFFF8F8F8),
                      Color(0xFFFAFAFA), // Very light grey
                    ],
              stops: const [0.0, 0.125, 0.25, 0.375, 0.5],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.borderColor.withOpacity(0.4),
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
