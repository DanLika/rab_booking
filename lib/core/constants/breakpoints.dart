import 'package:flutter/widgets.dart';

/// Responsive breakpoints for different screen sizes
///
/// Usage:
/// ```dart
/// if (Breakpoints.isMobile(context)) {
///   // Mobile layout
/// }
/// ```
class Breakpoints {
  /// Mobile breakpoint (< 600px)
  static const double mobile = 600;

  /// Tablet breakpoint (600px - 1024px)
  static const double tablet = 1024;

  /// Desktop breakpoint (>= 1440px)
  static const double desktop = 1440;

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobile &&
      MediaQuery.of(context).size.width < desktop;

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  /// Check if screen width is less than tablet
  static bool isMobileOrTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < desktop;

  /// Get responsive value based on screen size
  static T getValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width < Breakpoints.mobile) {
      return mobile;
    } else if (width < Breakpoints.desktop) {
      return tablet ?? mobile;
    } else {
      return desktop;
    }
  }

  Breakpoints._();
}
