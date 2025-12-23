import 'package:flutter/widgets.dart';
import '../constants/breakpoints.dart';

/// Extension methods for BuildContext to access responsive utilities
///
/// Example:
/// ```dart
/// if (context.isMobile) {
///   // Mobile layout
/// }
///
/// final spacing = context.responsiveSpacing(16, 24, 32);
/// ```
extension ResponsiveExtension on BuildContext {
  /// Check if current screen is mobile (< 600px)
  bool get isMobile => Breakpoints.isMobile(this);

  /// Check if current screen is tablet (600px - 1440px)
  bool get isTablet => Breakpoints.isTablet(this);

  /// Check if current screen is desktop (>= 1440px)
  bool get isDesktop => Breakpoints.isDesktop(this);

  /// Check if screen is mobile or tablet
  bool get isMobileOrTablet => Breakpoints.isMobileOrTablet(this);

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// Get device pixel ratio
  double get devicePixelRatio => MediaQuery.of(this).devicePixelRatio;

  /// Get responsive spacing value
  ///
  /// Example:
  /// ```dart
  /// final padding = context.responsiveSpacing(16, 24, 32);
  /// ```
  double responsiveSpacing(double mobile, double tablet, double desktop) {
    if (isMobile) return mobile;
    if (isTablet) return tablet;
    return desktop;
  }

  /// Get responsive font size
  ///
  /// Example:
  /// ```dart
  /// final fontSize = context.responsiveFontSize(14, 16, 18);
  /// ```
  double responsiveFontSize(double mobile, double tablet, double desktop) {
    if (isMobile) return mobile;
    if (isTablet) return tablet;
    return desktop;
  }

  /// Get responsive value of any type
  ///
  /// Example:
  /// ```dart
  /// final columns = context.responsiveValue(
  ///   mobile: 1,
  ///   tablet: 2,
  ///   desktop: 3,
  /// );
  /// ```
  T responsiveValue<T>({required T mobile, T? tablet, required T desktop}) {
    if (isMobile) return mobile;
    if (isTablet) return tablet ?? mobile;
    return desktop;
  }
}

/// Extension methods for screen size utilities
extension ScreenUtilsExtension on BuildContext {
  /// Get responsive padding based on screen size
  EdgeInsets responsivePadding({
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    required EdgeInsets desktop,
  }) {
    if (isMobile) return mobile;
    if (isTablet) return tablet ?? mobile;
    return desktop;
  }

  /// Get responsive margin
  EdgeInsets responsiveMargin({
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    required EdgeInsets desktop,
  }) {
    if (isMobile) return mobile;
    if (isTablet) return tablet ?? mobile;
    return desktop;
  }

  /// Check if orientation is portrait
  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;

  /// Check if orientation is landscape
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;
}
