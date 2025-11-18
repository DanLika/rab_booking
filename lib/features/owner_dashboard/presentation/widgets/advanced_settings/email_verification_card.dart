import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Email Verification Settings Card
///
/// Extracted from widget_advanced_settings_screen.dart to reduce nesting.
/// Contains toggle for requiring email verification before booking completion.
class EmailVerificationCard extends StatelessWidget {
  final bool requireEmailVerification;
  final ValueChanged<bool> onChanged;

  const EmailVerificationCard({
    super.key,
    required this.requireEmailVerification,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            _buildSectionHeader(),
            const SizedBox(height: 16),
            const Divider(),

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
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withAlpha((0.15 * 255).toInt()),
                AppColors.secondary.withAlpha((0.08 * 255).toInt()),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.verified_user,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email Verification',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Configure guest email verification',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
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
