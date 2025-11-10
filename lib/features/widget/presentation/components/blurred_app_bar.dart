import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/design_tokens/glassmorphism_tokens.dart';

/// Blurred App Bar - Modern app bar with glassmorphism effect
///
/// Features:
/// - Frosted glass background that blurs content behind
/// - Semi-transparent surface
/// - Smooth scrolling blur effect
/// - Works with both SliverAppBar and regular AppBar
/// - Customizable blur intensity
///
/// Usage:
/// ```dart
/// BlurredAppBar(
///   title: Text('My App'),
///   preset: GlassmorphismTokens.presetMedium,
/// )
/// ```
class BlurredAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final GlassPreset? preset;
  final bool enabled;
  final double? elevation;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double toolbarHeight;

  const BlurredAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.preset,
    this.enabled = true,
    this.elevation,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.toolbarHeight = kToolbarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine preset (default to light for app bar)
    final effectivePreset = preset ?? GlassmorphismTokens.presetLight;

    // Determine colors
    final effectiveForegroundColor =
        foregroundColor ??
        theme.appBarTheme.foregroundColor ??
        (isDark ? Colors.white : Colors.black);

    // If disabled, render as normal app bar
    if (!enabled) {
      return AppBar(
        title: title,
        leading: leading,
        actions: actions,
        centerTitle: centerTitle,
        elevation: elevation ?? 0,
        backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
        foregroundColor: effectiveForegroundColor,
        toolbarHeight: toolbarHeight,
      );
    }

    // Build glass app bar with backdrop filter
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: effectivePreset.blur,
          sigmaY: effectivePreset.blur,
          tileMode: TileMode.clamp,
        ),
        child: AppBar(
          title: title,
          leading: leading,
          actions: actions,
          centerTitle: centerTitle,
          elevation: elevation ?? 0,
          toolbarHeight: toolbarHeight,
          backgroundColor: _getGlassBackgroundColor(
            isDark,
            effectivePreset,
            backgroundColor,
          ),
          foregroundColor: effectiveForegroundColor,
          // Add subtle border at bottom
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: effectivePreset.borderOpacity,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get glass background color
  Color _getGlassBackgroundColor(
    bool isDark,
    GlassPreset preset,
    Color? customColor,
  ) {
    if (customColor != null) {
      return customColor.withValues(alpha: preset.opacity);
    }

    if (isDark) {
      // Dark mode: White overlay
      return Colors.white.withValues(alpha: preset.opacity);
    } else {
      // Light mode: White with slight opacity
      return Colors.white.withValues(
        alpha: preset.opacity + 0.7,
      ); // More opaque in light mode
    }
  }
}

/// Blurred Sliver App Bar - Scrollable app bar with glassmorphism
///
/// Use this with CustomScrollView for scrolling blur effects
///
/// Usage:
/// ```dart
/// CustomScrollView(
///   slivers: [
///     BlurredSliverAppBar(
///       title: Text('Scrollable'),
///       floating: true,
///     ),
///     // ... other slivers
///   ],
/// )
/// ```
class BlurredSliverAppBar extends StatelessWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final GlassPreset? preset;
  final bool enabled;
  final bool floating;
  final bool pinned;
  final bool snap;
  final double expandedHeight;
  final Widget? flexibleSpace;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const BlurredSliverAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.preset,
    this.enabled = true,
    this.floating = false,
    this.pinned = true,
    this.snap = false,
    this.expandedHeight = kToolbarHeight,
    this.flexibleSpace,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectivePreset = preset ?? GlassmorphismTokens.presetLight;
    final effectiveForegroundColor =
        foregroundColor ??
        theme.appBarTheme.foregroundColor ??
        (isDark ? Colors.white : Colors.black);

    // If disabled, render as normal sliver app bar
    if (!enabled) {
      return SliverAppBar(
        title: title,
        leading: leading,
        actions: actions,
        centerTitle: centerTitle,
        floating: floating,
        pinned: pinned,
        snap: snap,
        expandedHeight: expandedHeight,
        flexibleSpace: flexibleSpace,
        backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
        foregroundColor: effectiveForegroundColor,
      );
    }

    // Build glass sliver app bar with backdrop filter
    return SliverAppBar(
      title: title,
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      floating: floating,
      pinned: pinned,
      snap: snap,
      expandedHeight: expandedHeight,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: effectiveForegroundColor,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectivePreset.blur,
            sigmaY: effectivePreset.blur,
            tileMode: TileMode.clamp,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _getGlassBackgroundColor(
                isDark,
                effectivePreset,
                backgroundColor,
              ),
              border: Border(
                bottom: BorderSide(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: effectivePreset.borderOpacity,
                  ),
                ),
              ),
            ),
            child: flexibleSpace,
          ),
        ),
      ),
    );
  }

  /// Get glass background color
  Color _getGlassBackgroundColor(
    bool isDark,
    GlassPreset preset,
    Color? customColor,
  ) {
    if (customColor != null) {
      return customColor.withValues(alpha: preset.opacity);
    }

    if (isDark) {
      return Colors.white.withValues(alpha: preset.opacity);
    } else {
      return Colors.white.withValues(alpha: preset.opacity + 0.7);
    }
  }
}

/// Floating Action Button with Glass Effect
class GlassFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final GlassPreset? preset;
  final bool enabled;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const GlassFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.preset,
    this.enabled = true,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effectivePreset = preset ?? GlassmorphismTokens.presetMedium;

    if (!enabled) {
      return FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        child: child,
      );
    }

    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: effectivePreset.blur,
          sigmaY: effectivePreset.blur,
          tileMode: TileMode.clamp,
        ),
        child: FloatingActionButton(
          onPressed: onPressed,
          tooltip: tooltip,
          elevation: 0,
          highlightElevation: 0,
          backgroundColor: (backgroundColor ?? theme.colorScheme.primary)
              .withValues(alpha: effectivePreset.opacity + 0.5),
          foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
          child: child,
        ),
      ),
    );
  }
}
