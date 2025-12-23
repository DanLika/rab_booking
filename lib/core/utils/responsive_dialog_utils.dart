import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Responsive dialog sizing utilities
class ResponsiveDialogUtils {
  /// Standard header height matching CommonAppBar (52px)
  /// Used for dialog/bottom sheet headers to ensure visual consistency
  static const double kHeaderHeight = 52.0;

  /// Get responsive dialog width based on screen size
  /// - Very small mobile (< 400px): 90% width (with 0px inset padding = 90% total)
  /// - Mobile (400-600px): 90% width (with 5px inset padding)
  /// - Tablet (600-1024px): 80% width
  /// - Desktop (>= 1024px): 60% width (clamped between min and max)
  static double getDialogWidth(
    BuildContext context, {
    double verySmallMobilePercent = 0.9,
    double mobilePercent = 0.9,
    double tabletPercent = 0.8,
    double desktopPercent = 0.6,
    double minWidth = 500.0,
    double maxWidth = 600.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 400) {
      // Very small mobile
      return screenWidth * verySmallMobilePercent;
    } else if (screenWidth < 600) {
      // Mobile
      return screenWidth * mobilePercent;
    } else if (screenWidth < 1024) {
      // Tablet
      return screenWidth * tabletPercent;
    } else {
      // Desktop
      // Use math.max to prevent ArgumentError when minWidth > maxWidth
      return (screenWidth * desktopPercent).clamp(
        minWidth,
        math.max(minWidth, maxWidth),
      );
    }
  }

  /// Get responsive content padding
  /// - Mobile: minimal padding (12px) - always have some padding between content and dialog edge
  /// - Tablet/Desktop: normal padding (20px)
  static double getContentPadding(
    BuildContext context, {
    double mobilePadding = 12.0,
    double desktopPadding = 20.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600 ? mobilePadding : desktopPadding;
  }

  /// Get responsive header padding
  /// Compact padding to achieve kHeaderHeight (52px) total height
  /// - Mobile: 8px vertical padding
  /// - Desktop: 10px vertical padding
  /// With icon (20px) + text (~20px) + padding = ~52px
  static double getHeaderPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600 ? 8.0 : 10.0;
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// Get responsive dialog inset padding
  /// - Very small mobile (< 400px): 0px horizontal - maximize dialog width (90% + 0px = 90% total)
  /// - Mobile (400-600px): 10px horizontal - small padding (90% + 10px)
  /// - Desktop: normal (40px horizontal) - default Flutter behavior
  static EdgeInsets getDialogInsetPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return const EdgeInsets.symmetric(vertical: 24.0);
    } else if (screenWidth < 600) {
      return const EdgeInsets.symmetric(horizontal: 10.0, vertical: 24.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0);
    }
  }
}
