import 'package:flutter/widgets.dart';
import '../../../core/utils/context_extensions.dart';

/// Adaptive padding that changes based on screen size
///
/// Example:
/// ```dart
/// AdaptivePadding(
///   mobile: EdgeInsets.all(16),
///   tablet: EdgeInsets.all(24),
///   desktop: EdgeInsets.all(32),
///   child: YourWidget(),
/// )
/// ```
class AdaptivePadding extends StatelessWidget {
  const AdaptivePadding({
    required this.child,
    required this.mobile,
    this.tablet,
    required this.desktop,
    super.key,
  });

  /// Child widget
  final Widget child;

  /// Padding for mobile devices
  final EdgeInsets mobile;

  /// Padding for tablets (falls back to mobile if not provided)
  final EdgeInsets? tablet;

  /// Padding for desktop
  final EdgeInsets desktop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.responsivePadding(
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      ),
      child: child,
    );
  }
}

/// Adaptive margin that changes based on screen size
class AdaptiveMargin extends StatelessWidget {
  const AdaptiveMargin({
    required this.child,
    required this.mobile,
    this.tablet,
    required this.desktop,
    super.key,
  });

  /// Child widget
  final Widget child;

  /// Margin for mobile devices
  final EdgeInsets mobile;

  /// Margin for tablets (falls back to mobile if not provided)
  final EdgeInsets? tablet;

  /// Margin for desktop
  final EdgeInsets desktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: context.responsiveMargin(
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      ),
      child: child,
    );
  }
}
