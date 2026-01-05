import 'package:flutter/material.dart';

/// Responsive breakpoints helper
/// UNIFIED with /lib/core/constants/breakpoints.dart
class ResponsiveHelper {
  /// Mobile breakpoint (phones) - < 600px
  static const double mobile = 600;

  /// Tablet breakpoint - >= 1024px
  static const double tablet = 1024;

  /// Check if screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  /// Check if screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }

  /// Check if screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tablet;
  }

  /// Get responsive value based on screen size
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Get cell size for calendar (Month view)
  static double getCalendarCellSize(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 50.0, // Mobile - trenutno OK
      tablet: 70.0, // Tablet - smanjeno sa prevelikog
      desktop: 60.0, // Desktop - smanjeno sa prevelikog
    );
  }

  /// Get year cell size based on available width
  /// [availableWidth] is the actual container width (after padding)
  static double getYearCellSizeForWidth(double availableWidth) {
    // monthLabelWidth = 60px (from ConstraintTokens)
    const monthLabelWidth = 60.0;
    final widthForCells = availableWidth - monthLabelWidth;
    // 31 days in a month - calculate cell size to fit
    // Minimum 14px to keep text readable, max 40px for aesthetics
    return (widthForCells / 31).clamp(14.0, 40.0);
  }

  /// Legacy method - uses screen width estimate (less accurate)
  static double getYearCellSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Estimate padding: 32px mobile, 48px desktop
    final isDesktop = screenWidth >= tablet;
    final estimatedPadding = isDesktop ? 48.0 : 32.0;
    return getYearCellSizeForWidth(screenWidth - estimatedPadding);
  }
}
