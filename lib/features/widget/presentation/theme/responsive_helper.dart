import 'package:flutter/material.dart';

/// Responsive breakpoints helper
class ResponsiveHelper {
  /// Mobile breakpoint (phones)
  static const double mobile = 640;

  /// Tablet breakpoint
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

  /// Get year cell size
  static double getYearCellSize(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 32.0,  // Povećano sa 24 na 32
      tablet: 42.0,  // Povećano sa 28 na 42
      desktop: 48.0, // Povećano sa 32 na 48 - mnogo veći!
    );
  }
}
