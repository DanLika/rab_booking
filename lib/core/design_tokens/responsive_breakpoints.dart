import 'package:flutter/widgets.dart';

/// Responsive breakpoints for the widget
class ResponsiveBreakpoints {
  // Breakpoint values
  static const double mobile = 768;
  static const double tablet = 1024;
  static const double desktop = 1440;

  // Device type detection
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

  // Responsive value selector
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
