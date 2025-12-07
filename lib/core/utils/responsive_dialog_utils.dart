import 'package:flutter/material.dart';

/// Responsive dialog sizing utilities
class ResponsiveDialogUtils {
  /// Get responsive dialog width based on screen size
  /// - Mobile (< 600px): 90% width (no padding needed)
  /// - Tablet (600-1024px): 80% width
  /// - Desktop (>= 1024px): 60% width (clamped between min and max)
  static double getDialogWidth(
    BuildContext context, {
    double mobilePercent = 0.9,
    double tabletPercent = 0.8,
    double desktopPercent = 0.6,
    double minWidth = 500.0,
    double maxWidth = 600.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      // Mobile
      return screenWidth * mobilePercent;
    } else if (screenWidth < 1024) {
      // Tablet
      return screenWidth * tabletPercent;
    } else {
      // Desktop
      return (screenWidth * desktopPercent).clamp(minWidth, maxWidth);
    }
  }

  /// Get responsive content padding
  /// - Mobile: no padding (0px) - dialog is 90% so no extra padding needed
  /// - Tablet/Desktop: normal padding (20px)
  static double getContentPadding(BuildContext context, {double mobilePadding = 0.0, double desktopPadding = 20.0}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600 ? mobilePadding : desktopPadding;
  }

  /// Get responsive header padding
  /// - Mobile: minimal (8px) - save space
  /// - Desktop: normal (16px)
  static double getHeaderPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600 ? 8.0 : 16.0;
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
}
