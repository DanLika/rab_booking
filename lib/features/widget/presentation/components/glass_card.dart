import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/design_tokens/glassmorphism_tokens.dart';

/// Glass Card - Reusable card component with glassmorphism effect
///
/// Features:
/// - Frosted glass background with blur
/// - Semi-transparent surface
/// - Subtle border for definition
/// - Customizable blur intensity
/// - Works in both light and dark mode
/// - Graceful degradation for non-supporting browsers
///
/// Usage:
/// ```dart
/// GlassCard(
///   child: Text('Content'),
///   preset: GlassmorphismTokens.presetMedium,
/// )
/// ```
class GlassCard extends StatelessWidget {
  final Widget child;
  final GlassPreset? preset;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final bool enabled;

  const GlassCard({
    super.key,
    required this.child,
    this.preset,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.shadows,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine preset (default to medium)
    final effectivePreset = preset ?? GlassmorphismTokens.presetMedium;

    // Determine border radius (default to 12)
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);

    // If disabled, render as normal container
    if (!enabled) {
      return _buildNormalCard(context, isDark, effectiveBorderRadius);
    }

    // Build glass card with backdrop filter
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          child: ClipRRect(
            borderRadius: effectiveBorderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: effectivePreset.blur,
                sigmaY: effectivePreset.blur,
                tileMode: TileMode.clamp,
              ),
              child: Container(
                padding: padding ?? const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getGlassColor(isDark, effectivePreset),
                  borderRadius: effectiveBorderRadius,
                  border: Border.all(
                    color: _getBorderColor(isDark, effectivePreset),
                  ),
                  boxShadow: shadows ?? _getDefaultShadows(isDark),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build normal card without blur (fallback)
  Widget _buildNormalCard(
    BuildContext context,
    bool isDark,
    BorderRadius borderRadius,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: borderRadius,
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha((0.3 * 255).toInt()),
        ),
        boxShadow: shadows ?? _getDefaultShadows(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: borderRadius, child: child),
      ),
    );
  }

  /// Get glass background color based on theme and preset
  Color _getGlassColor(bool isDark, GlassPreset preset) {
    if (isDark) {
      // Dark mode: White overlay with preset opacity
      return Colors.white.withValues(alpha: preset.opacity);
    } else {
      // Light mode: Black overlay with preset opacity
      return Colors.black.withValues(alpha: preset.opacity);
    }
  }

  /// Get border color based on theme and preset
  Color _getBorderColor(bool isDark, GlassPreset preset) {
    if (isDark) {
      // Dark mode: White border with preset border opacity
      return Colors.white.withValues(alpha: preset.borderOpacity);
    } else {
      // Light mode: Black border with preset border opacity
      return Colors.black.withValues(alpha: preset.borderOpacity);
    }
  }

  /// Get default shadows based on theme
  List<BoxShadow> _getDefaultShadows(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
    }
  }
}

/// Glass Card with Hover Effect
///
/// Variant of GlassCard that responds to hover with enhanced blur
class GlassCardHoverable extends StatefulWidget {
  final Widget child;
  final GlassPreset? preset;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool enabled;

  const GlassCardHoverable({
    super.key,
    required this.child,
    this.preset,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<GlassCardHoverable> createState() => _GlassCardHoverableState();
}

class _GlassCardHoverableState extends State<GlassCardHoverable> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final basePreset = widget.preset ?? GlassmorphismTokens.presetMedium;

    // On hover, increase blur by 20%
    final currentPreset = _isHovered ? basePreset.scale(1.2) : basePreset;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: GlassCard(
          preset: currentPreset,
          padding: widget.padding,
          margin: widget.margin,
          width: widget.width,
          height: widget.height,
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          enabled: widget.enabled,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Glass Container - Similar to GlassCard but without Material ripple
///
/// Use when you don't need tap interaction
class GlassContainer extends StatelessWidget {
  final Widget child;
  final GlassPreset? preset;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final bool enabled;
  final Alignment? alignment;

  const GlassContainer({
    super.key,
    required this.child,
    this.preset,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.shadows,
    this.enabled = true,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectivePreset = preset ?? GlassmorphismTokens.presetMedium;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);

    if (!enabled) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        alignment: alignment,
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: effectiveBorderRadius,
        ),
        child: child,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectivePreset.blur,
            sigmaY: effectivePreset.blur,
            tileMode: TileMode.clamp,
          ),
          child: Container(
            padding: padding,
            alignment: alignment,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: effectivePreset.opacity,
              ),
              borderRadius: effectiveBorderRadius,
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: effectivePreset.borderOpacity,
                ),
              ),
              boxShadow: shadows,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
