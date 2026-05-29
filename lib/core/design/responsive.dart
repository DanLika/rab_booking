/// Responsive helpers for BookBed primitives + pages.
///
/// One way to ask "what device are we on?": [BBResponsive.of(context)].
/// Reach into [BBResponsive] only at composition time; widgets that depend
/// on width should rebuild via [BBResponsiveBuilder] so the layout reflows
/// on resize (desktop window drag, foldables, rotation).
///
/// Breakpoints (from [BBBreakpoint]):
/// - mobile: width <  600
/// - tablet: width >= 600 and < 1024
/// - desktop: width >= 1024 and < 1440
/// - wide: width >= 1440
///
/// Wide cap: pages should clamp content to [BBContentMaxWidth] (default 1200px,
/// centered) on `desktop` and `wide` so line lengths stay readable. Phone +
/// tablet stay edge-to-edge.
library;

import 'package:flutter/material.dart';

import 'tokens.dart';

// ===========================================================================
// BBResponsive snapshot
// ===========================================================================

/// Resolved device-class for the current width.
enum BBDeviceClass { mobile, tablet, desktop, wide }

/// Snapshot of responsive state for the current [BuildContext]. Carries the
/// resolved device-class plus raw [MediaQuery] data callers commonly need
/// (size, orientation, safe-area, view-insets, textScale).
@immutable
class BBResponsive {
  const BBResponsive({
    required this.deviceClass,
    required this.size,
    required this.orientation,
    required this.padding,
    required this.viewInsets,
    required this.textScaleFactor,
  });

  /// Resolve for the current [BuildContext]. Triggers rebuild on [MediaQuery]
  /// changes (size, orientation, safe-area, keyboard).
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
      padding: mq.padding,
      viewInsets: mq.viewInsets,
      textScaleFactor: mq.textScaler.scale(1.0),
    );
  }

  final BBDeviceClass deviceClass;
  final Size size;
  final Orientation orientation;

  /// Safe-area padding (notch, cutout, status bar, nav bar).
  final EdgeInsets padding;

  /// View insets — chiefly the on-screen keyboard.
  final EdgeInsets viewInsets;

  /// User-controlled font scale (1.0 default; phones may go up to ~2.0+).
  /// Pages that lay out fixed-height rows MUST `Wrap`/flex to remain usable.
  final double textScaleFactor;

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

  /// True when the on-screen keyboard is visible.
  bool get isKeyboardVisible => viewInsets.bottom > 0;
}

/// Convenience getters on [BuildContext]. Use in build methods so the page
/// reads `context.isLandscape` instead of `BBResponsive.of(context).isLandscape`.
extension BBContextResponsive on BuildContext {
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;
  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;

  /// Current view-insets bottom (typically the on-screen keyboard).
  double get keyboardInset => MediaQuery.of(this).viewInsets.bottom;
  bool get isKeyboardVisible => keyboardInset > 0;
}

// ===========================================================================
// BBResponsiveBuilder — pick a widget per tier
// ===========================================================================

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

// ===========================================================================
// BBContentMaxWidth — wide cap helper
// ===========================================================================

/// Centers and clamps child width to a max (default 1200px). Phone + tablet
/// pass through (no max). Use as a page-body wrapper on desktop-friendly
/// screens so columns of text stay readable on wide monitors.
class BBContentMaxWidth extends StatelessWidget {
  const BBContentMaxWidth({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

// ===========================================================================
// BBScaffold — page-shell wrapper
// ===========================================================================

/// Lightweight Material [Scaffold] wrapper that defaults:
/// - SafeArea around the body (notch, status bar, nav bar)
/// - `resizeToAvoidBottomInset: true` so the keyboard pushes the body up
/// - background color from the active BB color set
///
/// Use as the page root. Pages compose primitives inside `body`.
///
/// `appBar` / `drawer` / `endDrawer` / `bottomNavigationBar` /
/// `floatingActionButton` are all plumbed through to the underlying
/// [Scaffold] unchanged. `safeAreaTop` / `safeAreaBottom` let the page opt
/// out of safe-area on edges where an app-bar / bottom-nav already handles
/// the inset.
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
    this.extendBodyBehindAppBar = false,
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
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Scaffold(
      backgroundColor: backgroundColor ?? c.bg,
      appBar: appBar,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      // Top inset is consumed by AppBar when present; bottom by bottomNavigationBar.
      // Use SafeArea so contentless areas still respect notch/cutout.
      body: SafeArea(
        top: safeAreaTop && appBar == null,
        bottom: safeAreaBottom && bottomNavigationBar == null,
        child: body,
      ),
    );
  }
}
