import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Payment security trust badges
/// Features: SSL/TLS indicator, Stripe badge, PCI compliance, money-back guarantee
class PaymentSecurityBadges extends StatelessWidget {
  /// Show all badges
  final bool showAllBadges;

  /// Compact mode
  final bool compact;

  const PaymentSecurityBadges({
    super.key,
    this.showAllBadges = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main security notice
        _buildMainSecurityNotice(),

        if (showAllBadges) ...[
          SizedBox(
            height: compact ? AppDimensions.spaceM : AppDimensions.spaceL,
          ),

          // Trust badges grid
          Wrap(
            spacing: AppDimensions.spaceM,
            runSpacing: AppDimensions.spaceM,
            children: [
              _buildTrustBadge(
                icon: Icons.security,
                title: 'SSL/TLS Encrypted',
                subtitle: '256-bit encryption',
                color: AppColors.success,
              ),
              _buildTrustBadge(
                icon: Icons.verified_user,
                title: 'PCI Compliant',
                subtitle: 'Level 1 certified',
                color: AppColors.info,
              ),
              _buildTrustBadge(
                icon: Icons.payment,
                title: 'Powered by Stripe',
                subtitle: 'Secure payments',
                color: AppColors.primary,
              ),
              _buildTrustBadge(
                icon: Icons.policy,
                title: '100% Secure',
                subtitle: 'Money-back guarantee',
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMainSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(AppColors.success, AppColors.opacity10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.success,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceS),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock,
              color: Colors.white,
              size: AppDimensions.iconM,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: AppTypography.weightSemibold,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXXS),
                Text(
                  'Your payment information is encrypted and never stored on our servers.',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: compact ? 150 : 160,
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(color, AppColors.opacity10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.withOpacity(color, AppColors.opacity30),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: compact ? AppDimensions.iconL : AppDimensions.iconXL,
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            title,
            style: (compact ? AppTypography.small : AppTypography.bodyMedium)
                .copyWith(
              fontWeight: AppTypography.weightSemibold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spaceXXS),
          Text(
            subtitle,
            style: AppTypography.small.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Stripe payment badge widget
class StripePoweredBadge extends StatelessWidget {
  /// Show full text or just logo
  final bool showText;

  const StripePoweredBadge({
    super.key,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showText ? AppDimensions.spaceM : AppDimensions.spaceS,
        vertical: AppDimensions.spaceS,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.payment,
            size: AppDimensions.iconS,
            color: AppColors.primary,
          ),
          if (showText) ...[
            const SizedBox(width: AppDimensions.spaceS),
            Text(
              'Powered by Stripe',
              style: AppTypography.small.copyWith(
                fontWeight: AppTypography.weightMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// PCI compliance badge
class PCIComplianceBadge extends StatelessWidget {
  const PCIComplianceBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceS,
      ),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(AppColors.info, AppColors.opacity10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.info),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user,
            size: AppDimensions.iconS,
            color: AppColors.info,
          ),
          const SizedBox(width: AppDimensions.spaceS),
          Text(
            'PCI DSS Level 1',
            style: AppTypography.small.copyWith(
              fontWeight: AppTypography.weightMedium,
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }
}
