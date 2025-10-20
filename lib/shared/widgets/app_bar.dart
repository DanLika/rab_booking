import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_effects.dart';
import '../../core/constants/app_dimensions.dart';

/// Premium app bar component with blur effects and scroll animations
/// Features: Glass morphism, blur effects, scroll behavior, custom styling
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// App bar title
  final String? title;

  /// Title widget (overrides title string)
  final Widget? titleWidget;

  /// Leading widget (back button, menu icon, etc.)
  final Widget? leading;

  /// Actions widgets
  final List<Widget>? actions;

  /// Enable back button
  final bool automaticallyImplyLeading;

  /// Enable blur effect
  final bool enableBlur;

  /// Enable glass morphism
  final bool enableGlass;

  /// Enable elevation shadow
  final bool enableElevation;

  /// Custom background color
  final Color? backgroundColor;

  /// Center title
  final bool centerTitle;

  /// App bar variant
  final AppBarVariant variant;

  /// Bottom widget (usually TabBar)
  final PreferredSizeWidget? bottom;

  /// Scroll controller for scroll-based effects
  final ScrollController? scrollController;

  /// Threshold for scroll effects (in pixels)
  final double scrollThreshold;

  const PremiumAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.enableBlur = false,
    this.enableGlass = false,
    this.enableElevation = true,
    this.backgroundColor,
    this.centerTitle = true,
    this.variant = AppBarVariant.standard,
    this.bottom,
    this.scrollController,
    this.scrollThreshold = 10,
  });

  /// Glass morphism app bar
  factory PremiumAppBar.glass({
    String? title,
    Widget? titleWidget,
    Widget? leading,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
    bool centerTitle = true,
    PreferredSizeWidget? bottom,
    ScrollController? scrollController,
  }) {
    return PremiumAppBar(
      title: title,
      titleWidget: titleWidget,
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      enableGlass: true,
      enableBlur: true,
      enableElevation: false,
      variant: AppBarVariant.glass,
      bottom: bottom,
      scrollController: scrollController,
    );
  }

  /// Transparent app bar (for overlays)
  factory PremiumAppBar.transparent({
    String? title,
    Widget? titleWidget,
    Widget? leading,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
    bool centerTitle = true,
    PreferredSizeWidget? bottom,
  }) {
    return PremiumAppBar(
      title: title,
      titleWidget: titleWidget,
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      enableElevation: false,
      variant: AppBarVariant.transparent,
      backgroundColor: Colors.transparent,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        AppDimensions.appBarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget appBar = AppBar(
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: AppTypography.h3.copyWith(
                    color: _getTitleColor(isDark),
                    fontWeight: AppTypography.weightBold,
                  ),
                )
              : null),
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      backgroundColor: _getBackgroundColor(isDark),
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      iconTheme: IconThemeData(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        size: AppDimensions.iconM,
      ),
      actionsIconTheme: IconThemeData(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        size: AppDimensions.iconM,
      ),
      bottom: bottom,
    );

    // Wrap with blur effect if enabled
    if (enableBlur || variant == AppBarVariant.glass) {
      appBar = ClipRRect(
        child: BackdropFilter(
          filter: AppEffects.blurMedium,
          child: appBar,
        ),
      );
    }

    // Add elevation shadow if enabled
    if (enableElevation && variant == AppBarVariant.standard) {
      appBar = Container(
        decoration: const BoxDecoration(
          boxShadow: AppShadows.elevation1,
        ),
        child: appBar,
      );
    }

    return appBar;
  }

  Color? _getBackgroundColor(bool isDark) {
    if (backgroundColor != null) return backgroundColor;

    switch (variant) {
      case AppBarVariant.standard:
        return isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
      case AppBarVariant.glass:
        return isDark
            ? AppColors.withOpacity(AppColors.surfaceDark, AppColors.opacity80)
            : AppColors.withOpacity(AppColors.surfaceLight, AppColors.opacity80);
      case AppBarVariant.transparent:
        return Colors.transparent;
      case AppBarVariant.gradient:
        return null; // Gradient will be applied separately
    }
  }

  Color _getTitleColor(bool isDark) {
    if (variant == AppBarVariant.transparent) {
      return Colors.white;
    }
    return isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  }
}

/// Scrollable app bar with scroll effects
class PremiumSliverAppBar extends StatelessWidget {
  /// App bar title
  final String? title;

  /// Title widget (overrides title string)
  final Widget? titleWidget;

  /// Leading widget
  final Widget? leading;

  /// Actions widgets
  final List<Widget>? actions;

  /// Flexible space widget (for hero sections)
  final Widget? flexibleSpace;

  /// Expanded height (when not scrolled)
  final double? expandedHeight;

  /// Enable pinned app bar
  final bool pinned;

  /// Enable floating app bar
  final bool floating;

  /// Enable snap behavior
  final bool snap;

  /// Enable blur effect
  final bool enableBlur;

  /// Enable glass morphism
  final bool enableGlass;

  /// Background image
  final ImageProvider? backgroundImage;

  const PremiumSliverAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.flexibleSpace,
    this.expandedHeight,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.enableBlur = false,
    this.enableGlass = false,
    this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: AppTypography.h3.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontWeight: AppTypography.weightBold,
                  ),
                )
              : null),
      leading: leading,
      actions: actions,
      pinned: pinned,
      floating: floating,
      snap: snap,
      expandedHeight: expandedHeight ?? 200,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      flexibleSpace: flexibleSpace != null
          ? FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (backgroundImage != null)
                    Image(
                      image: backgroundImage!,
                      fit: BoxFit.cover,
                    ),
                  if (enableBlur || enableGlass)
                    BackdropFilter(
                      filter: AppEffects.blurLight,
                      child: Container(
                        color: isDark
                            ? AppColors.withOpacity(
                                AppColors.surfaceDark,
                                AppColors.opacity60,
                              )
                            : AppColors.withOpacity(
                                AppColors.surfaceLight,
                                AppColors.opacity60,
                              ),
                      ),
                    ),
                  flexibleSpace!,
                ],
              ),
            )
          : null,
      iconTheme: IconThemeData(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        size: AppDimensions.iconM,
      ),
    );
  }
}

/// App bar variant enum
enum AppBarVariant {
  /// Standard app bar with solid background
  standard,

  /// Glass morphism app bar with blur
  glass,

  /// Transparent app bar (for overlays)
  transparent,

  /// Gradient background app bar
  gradient,
}
