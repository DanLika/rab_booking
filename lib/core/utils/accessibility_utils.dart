import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility utilities for WCAG 2.1 AAA compliance
class AccessibilityUtils {
  AccessibilityUtils._();

  /// WCAG 2.1 minimum contrast ratios
  static const double wcagAAANormalText = 7.0; // AAA for normal text
  static const double wcagAANormalText = 4.5; // AA for normal text
  static const double wcagAAALargeText = 4.5; // AAA for large text (18pt+)
  static const double wcagAALargeText = 3.0; // AA for large text

  /// Calculate contrast ratio between two colors
  /// Returns value between 1 (no contrast) and 21 (maximum contrast)
  static double calculateContrastRatio(Color foreground, Color background) {
    final fgLuminance = _calculateRelativeLuminance(foreground);
    final bgLuminance = _calculateRelativeLuminance(background);

    final lighter = math.max(fgLuminance, bgLuminance);
    final darker = math.min(fgLuminance, bgLuminance);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculate relative luminance of a color
  /// Based on WCAG 2.1 formula
  static double _calculateRelativeLuminance(Color color) {
    final r = _sRGBtoLinear(((color.r * 255.0).round() & 0xff) / 255);
    final g = _sRGBtoLinear(((color.g * 255.0).round() & 0xff) / 255);
    final b = _sRGBtoLinear(((color.b * 255.0).round() & 0xff) / 255);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Convert sRGB color component to linear RGB
  static double _sRGBtoLinear(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    }
    return math.pow((component + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Check if color combination meets WCAG AAA standard
  static bool meetsWcagAaa({
    required Color foreground,
    required Color background,
    bool isLargeText = false,
  }) {
    final ratio = calculateContrastRatio(foreground, background);
    final threshold = isLargeText ? wcagAAALargeText : wcagAAANormalText;
    return ratio >= threshold;
  }

  /// Check if color combination meets WCAG AA standard
  static bool meetsWcagAa({
    required Color foreground,
    required Color background,
    bool isLargeText = false,
  }) {
    final ratio = calculateContrastRatio(foreground, background);
    final threshold = isLargeText ? wcagAALargeText : wcagAANormalText;
    return ratio >= threshold;
  }

  /// Get accessible text color (black or white) for given background
  /// Ensures AAA compliance
  static Color getAccessibleTextColor(Color background) {
    final whiteContrast = calculateContrastRatio(Colors.white, background);
    final blackContrast = calculateContrastRatio(Colors.black, background);

    // Return color with better contrast
    return whiteContrast > blackContrast ? Colors.white : Colors.black;
  }

  /// Adjust color to meet WCAG AAA contrast requirement
  /// Returns adjusted foreground color
  static Color adjustColorForAccessibility({
    required Color foreground,
    required Color background,
    bool isLargeText = false,
  }) {
    if (meetsWcagAaa(
      foreground: foreground,
      background: background,
      isLargeText: isLargeText,
    )) {
      return foreground; // Already accessible
    }

    // Try darkening/lightening the foreground color
    final bgLuminance = _calculateRelativeLuminance(background);
    final shouldDarken = bgLuminance > 0.5;

    Color adjusted = foreground;
    for (var i = 0; i < 100; i++) {
      if (shouldDarken) {
        adjusted = Color.fromRGBO(
          (((adjusted.r * 255.0).round() & 0xff) * 0.95).round().clamp(0, 255),
          (((adjusted.g * 255.0).round() & 0xff) * 0.95).round().clamp(0, 255),
          (((adjusted.b * 255.0).round() & 0xff) * 0.95).round().clamp(0, 255),
          adjusted.a,
        );
      } else {
        adjusted = Color.fromRGBO(
          math.min(255, (((adjusted.r * 255.0).round() & 0xff) * 1.05).round()),
          math.min(255, (((adjusted.g * 255.0).round() & 0xff) * 1.05).round()),
          math.min(255, (((adjusted.b * 255.0).round() & 0xff) * 1.05).round()),
          adjusted.a,
        );
      }

      if (meetsWcagAaa(
        foreground: adjusted,
        background: background,
        isLargeText: isLargeText,
      )) {
        return adjusted;
      }
    }

    // Fallback to black or white
    return getAccessibleTextColor(background);
  }

  /// Check if text size is considered "large" by WCAG
  /// Large text is 18pt (24px) or 14pt (18.66px) bold
  static bool isLargeText(double fontSize, {bool isBold = false}) {
    if (isBold) {
      return fontSize >= 18.66; // 14pt bold
    }
    return fontSize >= 24.0; // 18pt regular
  }

  /// Minimum touch target size (WCAG 2.1 Level AAA)
  static const double minTouchTargetSize = 44.0;

  /// Check if widget meets touch target size requirements
  static bool meetsTouchTargetSize(Size size) {
    return size.width >= minTouchTargetSize &&
        size.height >= minTouchTargetSize;
  }

  /// Wrap widget with proper touch target padding
  static Widget ensureTouchTarget({
    required Widget child,
    Size? currentSize,
  }) {
    if (currentSize != null && meetsTouchTargetSize(currentSize)) {
      return child;
    }

    return Container(
      constraints: const BoxConstraints(
        minWidth: minTouchTargetSize,
        minHeight: minTouchTargetSize,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  /// Generate semantic label for screen readers
  /// Removes special characters and formats for natural speech
  static String generateSemanticLabel(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove special chars
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Check if reduce motion is enabled (for animations)
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get accessible duration for animations
  /// Returns 0ms if reduce motion is enabled, otherwise normal duration
  static Duration getAccessibleDuration(
    BuildContext context,
    Duration normalDuration,
  ) {
    return shouldReduceMotion(context) ? Duration.zero : normalDuration;
  }

  /// Focus management for keyboard navigation
  static void requestFocusWithDelay(
    FocusNode focusNode, {
    Duration delay = const Duration(milliseconds: 100),
  }) {
    Future.delayed(delay, () {
      if (!focusNode.hasFocus) {
        focusNode.requestFocus();
      }
    });
  }

  /// Announce to screen readers (for dynamic content changes)
  static void announce(BuildContext context, String message) {
    // This uses SemanticsService to announce to screen readers
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Check if high contrast mode is enabled
  static bool isHighContrastMode(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Get text scale factor (for text scaling accessibility)
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(1.0);
  }

  /// Check if text scaling is within recommended bounds (1.0 - 2.0)
  static bool isTextScalingReasonable(BuildContext context) {
    final scale = getTextScaleFactor(context);
    return scale >= 1.0 && scale <= 2.0;
  }

  /// Support text scaling up to 200% (WCAG AAA requirement)
  static TextStyle scaleTextStyle(
    BuildContext context,
    TextStyle baseStyle, {
    double maxScale = 2.0,
  }) {
    final scale = math.min(getTextScaleFactor(context), maxScale);
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * scale,
    );
  }
}

/// Accessible color palette generator
class AccessibleColorPalette {
  AccessibleColorPalette._();

  /// Generate accessible color variants from base color
  /// Returns colors that meet AAA contrast with white/black backgrounds
  static Map<String, Color> generateAccessibleVariants(Color baseColor) {
    return {
      'onLight': AccessibilityUtils.adjustColorForAccessibility(
        foreground: baseColor,
        background: Colors.white,
      ),
      'onDark': AccessibilityUtils.adjustColorForAccessibility(
        foreground: baseColor,
        background: Colors.black,
      ),
      'lightBackground': _generateAccessibleBackground(baseColor, true),
      'darkBackground': _generateAccessibleBackground(baseColor, false),
    };
  }

  /// Generate accessible background color from foreground color
  static Color _generateAccessibleBackground(Color foreground, bool light) {
    final target = light ? Colors.white : Colors.black;
    Color background = target;

    // Gradually adjust until we meet contrast requirements
    for (var i = 0; i < 10; i++) {
      if (AccessibilityUtils.meetsWcagAaa(
        foreground: foreground,
        background: background,
      )) {
        return background;
      }

      // Mix with foreground color slightly
      background = Color.lerp(target, foreground, i * 0.05)!;
    }

    return target; // Fallback
  }

  /// Validate entire color scheme for accessibility
  static Map<String, bool> validateColorScheme(ColorScheme scheme) {
    return {
      'primary_on_surface': AccessibilityUtils.meetsWcagAaa(
        foreground: scheme.primary,
        background: scheme.surface,
      ),
      'onPrimary_on_primary': AccessibilityUtils.meetsWcagAaa(
        foreground: scheme.onPrimary,
        background: scheme.primary,
      ),
      'secondary_on_surface': AccessibilityUtils.meetsWcagAaa(
        foreground: scheme.secondary,
        background: scheme.surface,
      ),
      'onSecondary_on_secondary': AccessibilityUtils.meetsWcagAaa(
        foreground: scheme.onSecondary,
        background: scheme.secondary,
      ),
      'error_on_surface': AccessibilityUtils.meetsWcagAaa(
        foreground: scheme.error,
        background: scheme.surface,
      ),
    };
  }
}

/// Focus indicator widget for keyboard navigation
class FocusIndicator extends StatelessWidget {
  const FocusIndicator({
    required this.child,
    this.focusNode,
    this.borderRadius,
    this.indicatorColor,
    super.key,
  });

  final Widget child;
  final FocusNode? focusNode;
  final BorderRadius? borderRadius;
  final Color? indicatorColor;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;

          return Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(8),
              border: isFocused
                  ? Border.all(
                      color: indicatorColor ?? Theme.of(context).focusColor,
                      width: 2,
                    )
                  : null,
            ),
            child: child,
          );
        },
      ),
    );
  }
}
