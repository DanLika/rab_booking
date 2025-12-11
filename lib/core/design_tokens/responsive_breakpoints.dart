import 'package:flutter/widgets.dart';

/// Responsive breakpoints for the app
///
/// Usage:
/// ```dart
/// // Check device type
/// if (ResponsiveBreakpoints.isMobile(context)) {
///   return MobileLayout();
/// }
///
/// // Get responsive value
/// final padding = ResponsiveBreakpoints.responsive(
///   context,
///   mobile: 16.0,
///   tablet: 24.0,
///   desktop: 32.0,
/// );
/// ```
class ResponsiveBreakpoints {
  // Prevent instantiation
  ResponsiveBreakpoints._();

  // ============================================================
  // BREAKPOINT VALUES
  // ============================================================
  static const double mobile = 768;
  static const double tablet = 1024;
  static const double desktop = 1440;

  // ============================================================
  // DEVICE TYPE DETECTION
  // ============================================================

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tablet;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  // Get device type as enum
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobile) return DeviceType.mobile;
    if (width < tablet) return DeviceType.tablet;
    if (width < desktop) return DeviceType.desktop;
    return DeviceType.largeDesktop;
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Select value based on current device type
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  // Get current screen width
  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Get current screen height
  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}
