import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Custom page route with fade + slide transition
class FadeSlidePageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final RouteSettings? routeSettings;

  FadeSlidePageRoute({
    required this.builder,
    this.routeSettings,
  }) : super(settings: routeSettings);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade animation
    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    );

    // Slide animation
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}

/// Platform-specific page route
class PlatformPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final RouteSettings? routeSettings;

  PlatformPageRoute({
    required this.builder,
    this.routeSettings,
  }) : super(settings: routeSettings);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration {
    if (kIsWeb) {
      return const Duration(milliseconds: 300);
    }
    return Platform.isIOS
        ? const Duration(milliseconds: 350)
        : const Duration(milliseconds: 300);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // iOS-style slide transition
    if (!kIsWeb && Platform.isIOS) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        )),
        child: child,
      );
    }

    // Android/Web-style fade + scale transition
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}

/// Scale fade page route (for dialogs/modals)
class ScaleFadePageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final RouteSettings? routeSettings;

  ScaleFadePageRoute({
    required this.builder,
    this.routeSettings,
  }) : super(settings: routeSettings);

  @override
  Color? get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  bool get barrierDismissible => true;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  bool get opaque => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}

/// Slide up page route (for bottom sheets)
class SlideUpPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final RouteSettings? routeSettings;

  SlideUpPageRoute({
    required this.builder,
    this.routeSettings,
  }) : super(settings: routeSettings);

  @override
  Color? get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  bool get barrierDismissible => true;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  bool get opaque => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    );
  }
}

/// Navigation helper extensions
extension NavigationExtensions on BuildContext {
  /// Navigate with fade + slide transition
  Future<T?> pushFadeSlide<T>(Widget page) {
    return Navigator.of(this).push<T>(
      FadeSlidePageRoute(builder: (_) => page),
    );
  }

  /// Navigate with platform-specific transition
  Future<T?> pushPlatform<T>(Widget page) {
    return Navigator.of(this).push<T>(
      PlatformPageRoute(builder: (_) => page),
    );
  }

  /// Navigate with scale + fade transition (modal)
  Future<T?> pushScaleFade<T>(Widget page) {
    return Navigator.of(this).push<T>(
      ScaleFadePageRoute(builder: (_) => page),
    );
  }

  /// Navigate with slide up transition (bottom sheet style)
  Future<T?> pushSlideUp<T>(Widget page) {
    return Navigator.of(this).push<T>(
      SlideUpPageRoute(builder: (_) => page),
    );
  }
}
