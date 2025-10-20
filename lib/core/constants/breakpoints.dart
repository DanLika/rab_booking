import 'package:flutter/widgets.dart';

/// Responsive breakpoints for different screen sizes
///
/// Updated breakpoints for better device coverage:
/// - Mobile: < 600px (all phones)
/// - Tablet: 600px - 1024px (tablets and small laptops)
/// - Desktop: >= 1024px (laptops and desktops)
///
/// Usage:
/// ```dart
/// if (Breakpoints.isMobile(context)) {
///   // Mobile layout
/// }
/// ```
class Breakpoints {
  /// Mobile breakpoint (< 600px)
  /// Covers: Small/Medium/Large phones
  static const double mobile = 600;

  /// Tablet breakpoint (600px - 1024px)
  /// Covers: iPads, Android tablets, small laptops
  static const double tablet = 1024;

  /// Desktop breakpoint (>= 1024px)
  /// Covers: Laptops, desktops, large displays
  static const double desktop = 1024;

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

  /// Check if screen is small mobile (< 375px)
  /// Covers: Small Android phones (360x640)
  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 375;

  /// Check if screen is medium mobile (375-414px)
  /// Covers: iPhone SE, iPhone 13, Pixel 5
  static bool isMediumMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 375 && width < 600;
  }

  /// Check if screen is small tablet (600-810px)
  /// Covers: iPad Mini, small Android tablets
  static bool isSmallTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 810;
  }

  /// Check if screen is large tablet (810-1024px)
  /// Covers: Android tablets, iPad Pro portrait
  static bool isLargeTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 810 && width < 1024;
  }

  /// Check if screen is small desktop (1024-1366px)
  /// Covers: Laptops
  static bool isSmallDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 1024 && width < 1366;
  }

  /// Check if screen is large desktop (>= 1920px)
  /// Covers: Full HD and 2K displays
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1920;

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

  /// Get fine-grained responsive value for all device sizes
  static T getValueDetailed<T>(
    BuildContext context, {
    required T mobile,
    T? smallTablet,
    T? largeTablet,
    T? smallDesktop,
    required T desktop,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) {
      return mobile; // Mobile
    } else if (width < 810) {
      return smallTablet ?? mobile; // Small tablet
    } else if (width < 1024) {
      return largeTablet ?? smallTablet ?? mobile; // Large tablet
    } else if (width < 1920) {
      return smallDesktop ?? desktop; // Small desktop
    } else {
      return desktop; // Large desktop
    }
  }

  /// Get responsive padding
  /// Returns: 16 (mobile), 24 (tablet), 32 (desktop)
  static double getHorizontalPadding(BuildContext context) {
    return getValue(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
  }

  /// Get responsive grid columns
  /// Returns: 1 (mobile), 2 (tablet), 3-4 (desktop)
  static int getGridColumns(BuildContext context, {int desktopColumns = 3}) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) return 1; // Mobile: 1 column
    if (width < 1024) return 2; // Tablet: 2 columns
    if (width < 1920) return desktopColumns; // Desktop: 3 columns
    return desktopColumns + 1; // Large desktop: 4 columns
  }

  Breakpoints._();
}
