import 'package:flutter/material.dart';

/// Gradient design tokens for consistent gradients across the app
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     gradient: GradientTokens.brandPrimary,
///   ),
/// )
/// ```
class GradientTokens {
  // Prevent instantiation
  GradientTokens._();

  // ============================================================================
  // Linear Gradients
  // ============================================================================

  /// Subtle background gradient (light mode)
  static const LinearGradient subtleBackgroundLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFAF8F3), // Cream/beige
      Color(0xFFFFFFFF), // White
    ],
  );

  /// Subtle background gradient (dark mode)
  static const LinearGradient subtleBackgroundDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A1A), // Dark gray
      Color(0xFF121212), // Darker gray
    ],
  );

  /// Brand gradient - Purple solid colors (no alpha transparency)
  /// Used for: App Bar, Drawer Header, Primary Buttons
  /// Consistent across Light and Dark themes
  static const LinearGradient brandPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6B4CE6), // Purple (start)
      Color(0xFF7E5FEE), // Lighter purple (end) - solid, no alpha
    ],
  );

  /// Brand gradient colors (for custom usage with gradientColors parameter)
  static const Color brandPrimaryStart = Color(0xFF6B4CE6);
  static const Color brandPrimaryEnd = Color(0xFF7E5FEE); // Solid lighter purple

  /// Primary accent gradient
  static const LinearGradient primaryAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2196F3), // Material Blue
      Color(0xFF1976D2), // Darker Blue
    ],
  );

  /// Success gradient (for confirmations, available states)
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4CAF50), // Green
      Color(0xFF388E3C), // Darker Green
    ],
  );

  /// Warning gradient (for pending states)
  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFC107), // Amber
      Color(0xFFFFA000), // Darker Amber
    ],
  );

  /// Error gradient (for unavailable states, errors)
  static const LinearGradient error = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF44336), // Red
      Color(0xFFD32F2F), // Darker Red
    ],
  );

  /// Shimmer gradient for loading states
  static const LinearGradient shimmer = LinearGradient(
    colors: [Color(0xFFEBEBF4), Color(0xFFF4F4F4), Color(0xFFEBEBF4)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Shimmer gradient for loading states (dark mode)
  static const LinearGradient shimmerDark = LinearGradient(
    colors: [Color(0xFF2A2A2A), Color(0xFF3A3A3A), Color(0xFF2A2A2A)],
    stops: [0.0, 0.5, 1.0],
  );

  // ============================================================================
  // Radial Gradients
  // ============================================================================

  /// Spotlight effect (for highlighting elements)
  static const RadialGradient spotlight = RadialGradient(
    radius: 1.0,
    colors: [
      Color(0x33FFFFFF), // Semi-transparent white center
      Color(0x00FFFFFF), // Fully transparent edge
    ],
  );

  /// Overlay gradient (for modal backgrounds)
  static const RadialGradient overlay = RadialGradient(
    radius: 1.5,
    colors: [
      Color(0x99000000), // Semi-transparent black
      Color(0xCC000000), // More opaque black
    ],
  );

  // ============================================================================
  // Sweep Gradients (for circular elements)
  // ============================================================================

  /// Loading spinner gradient
  static const SweepGradient loadingSpinner = SweepGradient(
    endAngle: 6.28, // 2π radians
    colors: [
      Color(0xFF2196F3), // Blue
      Color(0x002196F3), // Transparent blue
    ],
  );

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Create a custom linear gradient with any two colors
  static LinearGradient customLinear({
    required Color startColor,
    required Color endColor,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(begin: begin, end: end, colors: [startColor, endColor]);
  }

  /// Create a three-color linear gradient
  static LinearGradient customLinearThreeColor({
    required Color startColor,
    required Color middleColor,
    required Color endColor,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    List<double>? stops,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [startColor, middleColor, endColor],
      stops: stops ?? [0.0, 0.5, 1.0],
    );
  }

  /// Create a custom radial gradient
  static RadialGradient customRadial({
    required Color centerColor,
    required Color edgeColor,
    AlignmentGeometry center = Alignment.center,
    double radius = 1.0,
  }) {
    return RadialGradient(center: center, radius: radius, colors: [centerColor, edgeColor]);
  }
}
