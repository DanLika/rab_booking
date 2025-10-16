import 'package:flutter/widgets.dart';
import '../constants/breakpoints.dart';

/// Responsive layout widget that adapts to screen size
///
/// Automatically switches between mobile, tablet, and desktop layouts
/// based on screen width.
///
/// Example:
/// ```dart
/// ResponsiveLayout(
///   mobile: MobileLayout(),
///   tablet: TabletLayout(),
///   desktop: DesktopLayout(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    required this.desktop,
    super.key,
  });

  /// Widget to display on mobile devices (< 600px)
  final Widget mobile;

  /// Widget to display on tablets (600px - 1440px)
  /// Falls back to [mobile] if not provided
  final Widget? tablet;

  /// Widget to display on desktop (>= 1440px)
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < Breakpoints.mobile) {
          return mobile;
        } else if (constraints.maxWidth < Breakpoints.desktop) {
          return tablet ?? mobile;
        } else {
          return desktop;
        }
      },
    );
  }
}

/// Get a responsive value based on screen size
///
/// Example:
/// ```dart
/// final padding = getResponsiveValue(
///   context,
///   mobile: 16.0,
///   tablet: 24.0,
///   desktop: 32.0,
/// );
/// ```
T getResponsiveValue<T>(
  BuildContext context, {
  required T mobile,
  T? tablet,
  required T desktop,
}) {
  return Breakpoints.getValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
  );
}
