import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_animations.dart';
import '../../core/constants/app_dimensions.dart';

/// Premium tab bar component with smooth animations and custom styling
/// Features: Multiple variants, smooth transitions, custom styling
class PremiumTabBar extends StatelessWidget {
  /// Tab labels
  final List<String> tabs;

  /// Current selected tab index
  final int selectedIndex;

  /// On tab selected callback
  final ValueChanged<int> onTabSelected;

  /// Tab bar variant
  final TabBarVariant variant;

  /// Enable scroll (for many tabs)
  final bool isScrollable;

  /// Tab padding
  final EdgeInsets? tabPadding;

  /// Indicator color (overrides default)
  final Color? indicatorColor;

  /// Label color (overrides default)
  final Color? labelColor;

  /// Unselected label color (overrides default)
  final Color? unselectedLabelColor;

  const PremiumTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.variant = TabBarVariant.underline,
    this.isScrollable = false,
    this.tabPadding,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (variant) {
      case TabBarVariant.underline:
        return _buildUnderlineTabBar(isDark);
      case TabBarVariant.pill:
        return _buildPillTabBar(isDark);
      case TabBarVariant.segmented:
        return _buildSegmentedTabBar(isDark);
    }
  }

  /// Underline tab bar (Material Design style)
  Widget _buildUnderlineTabBar(bool isDark) {
    return TabBar(
      tabs: tabs.map((label) => Tab(text: label)).toList(),
      isScrollable: isScrollable,
      padding: tabPadding,
      labelStyle: AppTypography.bodyMedium.copyWith(
        fontWeight: AppTypography.weightSemibold,
        letterSpacing: AppTypography.letterSpacingNormal,
      ),
      unselectedLabelStyle: AppTypography.bodyMedium.copyWith(
        fontWeight: AppTypography.weightRegular,
        letterSpacing: AppTypography.letterSpacingNormal,
      ),
      labelColor:
          labelColor ??
          (isDark ? AppColors.textPrimaryDark : AppColors.authPrimary),
      unselectedLabelColor:
          unselectedLabelColor ??
          (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: indicatorColor ?? AppColors.authPrimary,
          width: 3,
        ),
        insets: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceS),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    );
  }

  /// Pill tab bar (rounded background indicator)
  Widget _buildPillTabBar(bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => Expanded(
            child: _PillTab(
              label: tabs[index],
              isSelected: index == selectedIndex,
              onTap: () => onTabSelected(index),
              isDark: isDark,
            ),
          ),
        ),
      ),
    );
  }

  /// Segmented tab bar (Material 3 style)
  Widget _buildSegmentedTabBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => Expanded(
            child: _SegmentedTab(
              label: tabs[index],
              isSelected: index == selectedIndex,
              isFirst: index == 0,
              isLast: index == tabs.length - 1,
              onTap: () => onTabSelected(index),
              isDark: isDark,
            ),
          ),
        ),
      ),
    );
  }
}

/// Internal pill tab widget
class _PillTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _PillTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.fast,
      curve: AppAnimations.smooth,
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: isSelected ? AppShadows.elevation1 : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Center(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: isSelected
                    ? AppTypography.weightSemibold
                    : AppTypography.weightMedium,
                color: isSelected
                    ? (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.authPrimary)
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Internal segmented tab widget
class _SegmentedTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final bool isDark;

  const _SegmentedTab({
    required this.label,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.fast,
      curve: AppAnimations.smooth,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.authPrimary : Colors.transparent,
        borderRadius: BorderRadius.horizontal(
          left: isFirst
              ? const Radius.circular(AppDimensions.radiusM)
              : Radius.zero,
          right: isLast
              ? const Radius.circular(AppDimensions.radiusM)
              : Radius.zero,
        ),
        border: !isLast
            ? Border(
                right: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.horizontal(
            left: isFirst
                ? const Radius.circular(AppDimensions.radiusM)
                : Radius.zero,
            right: isLast
                ? const Radius.circular(AppDimensions.radiusM)
                : Radius.zero,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spaceS,
              horizontal: AppDimensions.spaceM,
            ),
            child: Center(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: isSelected
                      ? AppTypography.weightSemibold
                      : AppTypography.weightMedium,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tab bar variant enum
enum TabBarVariant {
  /// Underline indicator (Material Design)
  underline,

  /// Pill-shaped background indicator
  pill,

  /// Segmented control style
  segmented,
}
