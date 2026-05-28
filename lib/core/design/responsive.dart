/// Responsive helpers for BookBed primitives + pages.
///
/// One way to ask "what device are we on?": [BBResponsive.of(context)].
/// Reach into [BBResponsive] only at composition time; widgets that depend
/// on width should rebuild via [BBResponsiveBuilder] so the layout reflows
/// on resize (desktop window drag, foldables, rotation).
library;

import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// Resolved device-class for the current width.
enum BBDeviceClass { mobile, tablet, desktop, wide }

/// Snapshot of responsive state for the current [BuildContext].
@immutable
class BBResponsive {
  const BBResponsive({
    required this.deviceClass,
    required this.size,
    required this.orientation,
  });

  /// Resolve for the current [BuildContext]. Triggers rebuild on [MediaQuery]
  /// changes (size, orientation).
  factory BBResponsive.of(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final double w = mq.size.width;
    final BBDeviceClass cls;
    if (w < BBBreakpoint.mobile) {
      cls = BBDeviceClass.mobile;
    } else if (w < BBBreakpoint.tablet) {
      cls = BBDeviceClass.tablet;
    } else if (w < BBBreakpoint.desktop) {
      cls = BBDeviceClass.desktop;
    } else {
      cls = BBDeviceClass.wide;
    }
    return BBResponsive(
      deviceClass: cls,
      size: mq.size,
      orientation: mq.orientation,
    );
  }

  final BBDeviceClass deviceClass;
  final Size size;
  final Orientation orientation;

  bool get isMobile => deviceClass == BBDeviceClass.mobile;
  bool get isTablet => deviceClass == BBDeviceClass.tablet;
  bool get isDesktop => deviceClass == BBDeviceClass.desktop;
  bool get isWide => deviceClass == BBDeviceClass.wide;

  /// True for tablet and up — useful for "should we render a sidebar?"
  bool get isTabletOrLarger => deviceClass != BBDeviceClass.mobile;

  /// True for desktop and up — useful for "should we render side-by-side?"
  bool get isDesktopOrLarger =>
      deviceClass == BBDeviceClass.desktop || deviceClass == BBDeviceClass.wide;

  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;
}

/// Convenience getters on [BuildContext] so widgets don't have to call
/// `BBResponsive.of(context).isLandscape` — just `context.isLandscape`.
extension BBContextResponsive on BuildContext {
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;
  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;
}

/// Renders one of [mobile] / [tablet] / [desktop] / [wide] based on width.
/// Falls through downward: a missing [wide] uses [desktop], a missing
/// [desktop] uses [tablet], a missing [tablet] uses [mobile]. [mobile] is
/// required.
class BBResponsiveBuilder extends StatelessWidget {
  const BBResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.wide,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? wide;

  @override
  Widget build(BuildContext context) {
    final BBResponsive r = BBResponsive.of(context);
    switch (r.deviceClass) {
      case BBDeviceClass.wide:
        return wide ?? desktop ?? tablet ?? mobile;
      case BBDeviceClass.desktop:
        return desktop ?? tablet ?? mobile;
      case BBDeviceClass.tablet:
        return tablet ?? mobile;
      case BBDeviceClass.mobile:
        return mobile;
    }
  }
}

/// Value resolver. Use for non-Widget responsive data (counts, sizes, etc.).
/// `BBResponsiveValue<int>(context, mobile: 1, desktop: 3).value`
@immutable
class BBResponsiveValue<T> {
  factory BBResponsiveValue(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? wide,
  }) {
    final BBResponsive r = BBResponsive.of(context);
    switch (r.deviceClass) {
      case BBDeviceClass.wide:
        return BBResponsiveValue._(wide ?? desktop ?? tablet ?? mobile);
      case BBDeviceClass.desktop:
        return BBResponsiveValue._(desktop ?? tablet ?? mobile);
      case BBDeviceClass.tablet:
        return BBResponsiveValue._(tablet ?? mobile);
      case BBDeviceClass.mobile:
        return BBResponsiveValue._(mobile);
    }
  }

  const BBResponsiveValue._(this.value);

  final T value;
}

/// `Scaffold` wrapper that defaults SafeArea + handles viewInsets (keyboard,
/// notch, cutout). Use as the body of any page composed from BB primitives.
class BBScaffold extends StatelessWidget {
  const BBScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool safeAreaTop;
  final bool safeAreaBottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Avoid pulling Scaffold here — primitives shouldn't impose a Material
      // ancestor on every screen. The host MaterialApp already provides one.
      color: backgroundColor ?? BBColor.of(context).bg,
      child: SafeArea(top: safeAreaTop, bottom: safeAreaBottom, child: body),
    );
  }
}
