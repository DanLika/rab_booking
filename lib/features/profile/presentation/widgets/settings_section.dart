import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/widgets.dart';

/// Premium settings section widget
/// Features: Grouped settings, icons, switches, navigation arrows
class PremiumSettingsSection extends StatelessWidget {
  /// Section title
  final String title;

  /// Settings items (can be PremiumSettingsItem or any Widget like Consumer)
  final List<dynamic> items;

  const PremiumSettingsSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.spaceM,
            bottom: AppDimensions.spaceS,
          ),
          child: Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: AppTypography.weightSemibold,
              color: AppColors.textSecondaryLight,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Settings card
        PremiumCard.elevated(
          elevation: 1,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              // Convert PremiumSettingsItem to Widget if needed
              final Widget itemWidget = item is PremiumSettingsItem
                  ? _buildSettingsItem(context, item)
                  : item as Widget;

              return Column(
                children: [
                  itemWidget,
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: AppDimensions.spaceL + AppDimensions.iconM + AppDimensions.spaceM,
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Build a widget from a PremiumSettingsItem
  Widget _buildSettingsItem(BuildContext context, PremiumSettingsItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceL,
          vertical: AppDimensions.spaceM,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: AppDimensions.iconM,
              height: AppDimensions.iconM,
              decoration: BoxDecoration(
                gradient: item.iconGradient ??
                    LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(
                item.icon,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceM),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: AppTypography.weightMedium,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: AppDimensions.spaceXXS),
                    Text(
                      item.subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Trailing widget or arrow
            if (item.trailing != null)
              item.trailing!
            else if (item.showArrow)
              Icon(
                Icons.chevron_right,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
          ],
        ),
      ),
    );
  }
}

/// Premium settings item model
class PremiumSettingsItem {
  /// Icon
  final IconData icon;

  /// Title
  final String title;

  /// Subtitle
  final String? subtitle;

  /// Trailing widget (switch, arrow, etc.)
  final Widget? trailing;

  /// Show arrow
  final bool showArrow;

  /// On tap callback
  final VoidCallback? onTap;

  /// Icon gradient
  final LinearGradient? iconGradient;

  const PremiumSettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showArrow = true,
    this.onTap,
    this.iconGradient,
  });
}
