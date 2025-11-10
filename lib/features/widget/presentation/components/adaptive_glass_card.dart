import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_tokens/glassmorphism_tokens.dart';
import '../providers/blur_config_provider.dart';
import 'glass_card.dart';

/// Adaptive Glass Card - Automatically uses glassmorphism when enabled
///
/// This is a smart wrapper that:
/// - Uses GlassCard when blur is enabled in widget settings
/// - Falls back to regular Card when blur is disabled
/// - Seamlessly integrates with existing code (drop-in replacement for Card)
///
/// Usage (drop-in replacement for Card):
/// ```dart
/// // Old:
/// Card(child: Text('Content'))
///
/// // New:
/// AdaptiveGlassCard(child: Text('Content'))
/// ```
class AdaptiveGlassCard extends ConsumerWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;

  const AdaptiveGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.onTap,
    this.color,
    this.elevation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if card blur is enabled
    final isCardBlurEnabled = ref.watch(isCardBlurEnabledProvider);
    final blurConfig = ref.watch(blurConfigProvider);

    // If blur is enabled, use GlassCard
    if (isCardBlurEnabled) {
      final preset = GlassmorphismTokens.getPreset(blurConfig.intensity);

      return GlassCard(
        preset: preset,
        padding: padding,
        margin: margin,
        width: width,
        height: height,
        borderRadius: borderRadius,
        onTap: onTap,
        child: child,
      );
    }

    // Otherwise, use regular Card (fallback)
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Card(
        elevation: elevation ?? 1,
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Adaptive Glass Card with Hover - With hover effect when enabled
class AdaptiveGlassCardHoverable extends ConsumerWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;

  const AdaptiveGlassCardHoverable({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.onTap,
    this.color,
    this.elevation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCardBlurEnabled = ref.watch(isCardBlurEnabledProvider);
    final blurConfig = ref.watch(blurConfigProvider);

    if (isCardBlurEnabled) {
      final preset = GlassmorphismTokens.getPreset(blurConfig.intensity);

      return GlassCardHoverable(
        preset: preset,
        padding: padding,
        margin: margin,
        width: width,
        height: height,
        borderRadius: borderRadius,
        onTap: onTap,
        child: child,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Card(
        elevation: elevation ?? 1,
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Adaptive Blurred App Bar - Automatically uses blur when enabled
class AdaptiveBlurredAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double toolbarHeight;

  const AdaptiveBlurredAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.toolbarHeight = kToolbarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAppBarBlurEnabled = ref.watch(isAppBarBlurEnabledProvider);

    if (isAppBarBlurEnabled) {
      // Use semi-transparent AppBar when blur is enabled
      return AppBar(
        title: title,
        leading: leading,
        actions: actions,
        centerTitle: centerTitle,
        backgroundColor: backgroundColor?.withValues(alpha: 0.9),
        foregroundColor: foregroundColor,
        elevation: 0,
        toolbarHeight: toolbarHeight,
      );
    }

    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      toolbarHeight: toolbarHeight,
    );
  }
}
