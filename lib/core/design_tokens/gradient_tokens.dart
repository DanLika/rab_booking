import 'package:flutter/widgets.dart';

/// Gradient design tokens for consistent gradients across the widget
class GradientTokens {
  // ============================================================================
  // Linear Gradients
  // ============================================================================

  /// Subtle background gradient (light mode)
  static const LinearGradient subtleBackgroundLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFAFAFA), // Very light gray
      Color(0xFFF5F5F5), // Slightly darker gray
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
    end: Alignment(1.0, 0.0),
    colors: [Color(0xFFEBEBF4), Color(0xFFF4F4F4), Color(0xFFEBEBF4)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Shimmer gradient for loading states (dark mode)
  static const LinearGradient shimmerDark = LinearGradient(
    end: Alignment(1.0, 0.0),
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
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [startColor, endColor],
    );
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
    return RadialGradient(
      center: center,
      radius: radius,
      colors: [centerColor, edgeColor],
    );
  }
}
