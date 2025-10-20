import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/constants/app_dimensions.dart';

/// Premium bottom sheet component with animations and custom styling
/// Features: Draggable handle, custom heights, smooth animations
class PremiumBottomSheet {
  /// Show modal bottom sheet
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    double? height,
    bool isDismissible = true,
    bool enableDrag = true,
    bool showHandle = true,
  }) async {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      builder: (context) => _PremiumBottomSheetWidget(
        title: title,
        height: height,
        showHandle: showHandle,
        child: child,
      ),
    );
  }

  /// Show scrollable bottom sheet with list
  static Future<T?> showList<T>(
    BuildContext context, {
    required List<Widget> items,
    String? title,
    double? height,
    bool isDismissible = true,
    bool enableDrag = true,
  }) async {
    return show<T>(
      context,
      title: title,
      height: height,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => items[index],
      ),
    );
  }

  /// Show bottom sheet with custom content and action buttons
  static Future<T?> showWithActions<T>(
    BuildContext context, {
    required Widget content,
    required List<Widget> actions,
    String? title,
    double? height,
    bool isDismissible = true,
    bool enableDrag = true,
  }) async {
    return show<T>(
      context,
      title: title,
      height: height,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: content),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            child: Row(
              children: actions
                  .expand((action) => [
                        Expanded(child: action),
                        const SizedBox(width: AppDimensions.spaceS),
                      ])
                  .take(actions.length * 2 - 1)
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal premium bottom sheet widget
class _PremiumBottomSheetWidget extends StatelessWidget {
  final Widget child;
  final String? title;
  final double? height;
  final bool showHandle;

  const _PremiumBottomSheetWidget({
    required this.child,
    this.title,
    this.height,
    this.showHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxHeight = MediaQuery.of(context).size.height * AppDimensions.maxBottomSheetHeight;

    return Container(
      height: height,
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
        boxShadow: AppShadows.elevation5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          if (showHandle)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spaceS,
              ),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          // Title
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.spaceL,
                showHandle ? 0 : AppDimensions.spaceM,
                AppDimensions.spaceL,
                AppDimensions.spaceS,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: AppTypography.h3.copyWith(
                        fontWeight: AppTypography.weightBold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    iconSize: AppDimensions.iconM,
                  ),
                ],
              ),
            ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.spaceL,
                title == null ? AppDimensions.spaceM : 0,
                AppDimensions.spaceL,
                AppDimensions.spaceL,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet list item
class PremiumBottomSheetItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isDestructive;

  const PremiumBottomSheetItem({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: icon != null
          ? Icon(
              icon,
              color: isDestructive
                  ? AppColors.error
                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              size: AppDimensions.iconM,
            )
          : null,
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: AppTypography.weightMedium,
          color: isDestructive
              ? AppColors.error
              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.small.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceL,
        vertical: AppDimensions.spaceXS,
      ),
    );
  }
}
