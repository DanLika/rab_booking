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
              final widget = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  widget,
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
