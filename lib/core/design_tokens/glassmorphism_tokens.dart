import 'package:flutter/material.dart';
import 'dart:ui';

/// Glassmorphism Design Tokens
///
/// Defines all glass/frosted glass effects, blur levels, and transparency presets.
/// These tokens ensure consistent glassmorphism across the widget.
///
/// Browser Compatibility:
/// - Chrome/Edge: Full support (backdrop-filter)
/// - Safari: Full support (backdrop-filter)
/// - Firefox: Partial support (enable in about:config)
/// - Fallback: Semi-transparent backgrounds without blur
class GlassmorphismTokens {
  // ==================== BLUR INTENSITY LEVELS ====================

  /// No blur (disabled)
  static const double blurNone = 0.0;

  /// Subtle blur - barely noticeable (1-2px)
  static const double blurSubtle = 2.0;

  /// Light blur - gentle frosted glass (4-6px)
  static const double blurLight = 5.0;

  /// Medium blur - standard glassmorphism (8-12px)
  static const double blurMedium = 10.0;

  /// Strong blur - prominent glass effect (15-20px)
  static const double blurStrong = 18.0;

  /// Extra strong blur - maximum blur (25-30px)
  static const double blurExtraStrong = 28.0;

  // ==================== OPACITY LEVELS ====================

  /// Very transparent - 5% opacity
  static const double opacityVeryLight = 0.05;

  /// Light transparency - 10% opacity
  static const double opacityLight = 0.10;

  /// Medium-light transparency - 15% opacity
  static const double opacityMediumLight = 0.15;

  /// Medium transparency - 20% opacity
  static const double opacityMedium = 0.20;

  /// Medium-strong transparency - 30% opacity
  static const double opacityMediumStrong = 0.30;

  /// Strong transparency - 40% opacity
  static const double opacityStrong = 0.40;

  /// Very strong transparency - 60% opacity
  static const double opacityVeryStrong = 0.60;

  // ==================== BORDER OPACITY ====================

  /// Subtle border - 10% opacity
  static const double borderOpacitySubtle = 0.10;

  /// Normal border - 20% opacity
  static const double borderOpacityNormal = 0.20;

  /// Strong border - 30% opacity
  static const double borderOpacityStrong = 0.30;

  // ==================== PRESET CONFIGURATIONS ====================

  /// Subtle Glass - Barely noticeable glass effect
  /// Use for: Hover states, subtle overlays
  static const GlassPreset presetSubtle = GlassPreset(
    blur: blurSubtle,
    opacity: opacityLight,
    borderOpacity: borderOpacitySubtle,
    name: 'subtle',
  );

  /// Light Glass - Gentle frosted glass
  /// Use for: Cards, elevated surfaces in light mode
  static const GlassPreset presetLight = GlassPreset(
    blur: blurLight,
    opacity: opacityMediumLight,
    borderOpacity: borderOpacityNormal,
    name: 'light',
  );

  /// Medium Glass - Standard glassmorphism
  /// Use for: Modals, dialogs, app bars
  static const GlassPreset presetMedium = GlassPreset(
    blur: blurMedium,
    opacity: opacityMedium,
    borderOpacity: borderOpacityNormal,
    name: 'medium',
  );

  /// Strong Glass - Prominent glass effect
  /// Use for: Dark mode surfaces, emphasis areas
  static const GlassPreset presetStrong = GlassPreset(
    blur: blurStrong,
    opacity: opacityMediumStrong,
    borderOpacity: borderOpacityStrong,
    name: 'strong',
  );

  /// Extra Strong Glass - Maximum blur effect
  /// Use for: Full-screen overlays, modal scrims
  static const GlassPreset presetExtraStrong = GlassPreset(
    blur: blurExtraStrong,
    opacity: opacityStrong,
    borderOpacity: borderOpacityStrong,
    name: 'extra_strong',
  );

  // ==================== HELPER METHODS ====================

  /// Get preset by name
  static GlassPreset getPreset(String name) {
    switch (name.toLowerCase()) {
      case 'subtle':
        return presetSubtle;
      case 'light':
        return presetLight;
      case 'medium':
        return presetMedium;
      case 'strong':
        return presetStrong;
      case 'extra_strong':
      case 'extrastrong':
        return presetExtraStrong;
      case 'none':
      case 'disabled':
        return const GlassPreset(
          blur: 0,
          opacity: 0,
          borderOpacity: 0,
          name: 'none',
        );
      default:
        return presetMedium; // Default to medium
    }
  }

  /// Get preset by intensity (0.0 - 1.0)
  static GlassPreset getPresetByIntensity(double intensity) {
    if (intensity <= 0.0) {
      return const GlassPreset(
        blur: 0,
        opacity: 0,
        borderOpacity: 0,
        name: 'none',
      );
    }
    if (intensity <= 0.2) return presetSubtle;
    if (intensity <= 0.4) return presetLight;
    if (intensity <= 0.6) return presetMedium;
    if (intensity <= 0.8) return presetStrong;
    return presetExtraStrong;
  }

  /// Check if browser supports backdrop-filter
  /// Note: This is a simplified check. In production, use feature detection.
  static bool get supportsBackdropFilter {
    // For web, assume support (graceful degradation)
    // For mobile, always supported
    return true;
  }

  /// Create a glass box decoration
  static BoxDecoration createGlassDecoration({
    required GlassPreset preset,
    required bool isDark,
    Color? customColor,
    double? customOpacity,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
  }) {
    final baseColor = customColor ?? (isDark ? Colors.white : Colors.black);
    final opacity = customOpacity ?? preset.opacity;

    return BoxDecoration(
      color: baseColor.withOpacity(opacity),
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: Border.all(
        color: (isDark ? Colors.white : Colors.black).withValues(
          alpha: preset.borderOpacity,
        ),
      ),
      boxShadow:
          shadows ??
          [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
    );
  }

  /// Create backdrop filter with glass effect
  static ImageFilter createBackdropFilter(GlassPreset preset) {
    return ImageFilter.blur(
      sigmaX: preset.blur,
      sigmaY: preset.blur,
      tileMode: TileMode.clamp,
    );
  }
}

/// Glass Preset Configuration
///
/// Defines a complete glassmorphism configuration with blur, opacity, and border.
class GlassPreset {
  final double blur;
  final double opacity;
  final double borderOpacity;
  final String name;

  const GlassPreset({
    required this.blur,
    required this.opacity,
    required this.borderOpacity,
    required this.name,
  });

  /// Create custom preset
  factory GlassPreset.custom({
    required double blur,
    required double opacity,
    double? borderOpacity,
  }) {
    return GlassPreset(
      blur: blur,
      opacity: opacity,
      borderOpacity: borderOpacity ?? opacity * 0.5,
      name: 'custom',
    );
  }

  /// Scale the preset (multiply all values)
  GlassPreset scale(double factor) {
    return GlassPreset(
      blur: blur * factor,
      opacity: (opacity * factor).clamp(0.0, 1.0),
      borderOpacity: (borderOpacity * factor).clamp(0.0, 1.0),
      name: '${name}_scaled',
    );
  }

  /// Disable blur (keep opacity)
  GlassPreset get withoutBlur {
    return GlassPreset(
      blur: 0,
      opacity: opacity,
      borderOpacity: borderOpacity,
      name: '${name}_no_blur',
    );
  }

  @override
  String toString() => 'GlassPreset($name: blur=$blur, opacity=$opacity)';
}

/// Extension for easy glassmorphism widget wrapping
extension GlassmorphismWidget on Widget {
  /// Wrap widget with glass effect
  Widget withGlass({
    required GlassPreset preset,
    required bool isDark,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: GlassmorphismTokens.createGlassDecoration(
        preset: preset,
        isDark: isDark,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: BackdropFilter(
          filter: GlassmorphismTokens.createBackdropFilter(preset),
          child: this,
        ),
      ),
    );
  }
}
