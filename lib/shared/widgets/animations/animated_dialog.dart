import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/design_tokens/animation_tokens.dart';

/// Shows a dialog with scale + fade entrance animation
///
/// Usage:
/// ```dart
/// showAnimatedDialog(
///   context: context,
///   builder: (context) => MyDialog(),
/// );
/// ```
Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color? barrierColor,
  Duration? transitionDuration,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel:
        barrierLabel ??
        MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor ?? Colors.black54,
    transitionDuration: transitionDuration ?? AnimationTokens.normal,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: AnimationTokens.fastOutSlowIn,
        ),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: AnimationTokens.easeOut,
          ),
          child: child,
        ),
      );
    },
  );
}

/// Shows a dialog with slide up + fade entrance animation
///
/// Usage:
/// ```dart
/// showSlideUpDialog(
///   context: context,
///   builder: (context) => MyDialog(),
/// );
/// ```
Future<T?> showSlideUpDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color? barrierColor,
  Duration? transitionDuration,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel:
        barrierLabel ??
        MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor ?? Colors.black54,
    transitionDuration: transitionDuration ?? AnimationTokens.normal,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final slideAnimation =
          Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: AnimationTokens.easeOut),
          );

      return SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: AnimationTokens.easeOut,
          ),
          child: child,
        ),
      );
    },
  );
}

/// Shows a bottom sheet with smooth slide + fade animation
///
/// Usage:
/// ```dart
/// showAnimatedBottomSheet(
///   context: context,
///   builder: (context) => MyBottomSheet(),
/// );
/// ```
Future<T?> showAnimatedBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool isScrollControlled = false,
  Color? backgroundColor,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    transitionAnimationController: AnimationController(
      duration: AnimationTokens.normal,
      vsync: Navigator.of(context),
    ),
    builder: builder,
  );
}

/// Animated dialog wrapper that adds entrance animation to any dialog content
///
/// Uses flutter_animate for declarative scale + fade entrance animation.
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => AnimatedDialogWrapper(
///     child: AlertDialog(...),
///   ),
/// );
/// ```
class AnimatedDialogWrapper extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  /// Whether to animate (set false to skip animation)
  final bool animate;

  const AnimatedDialogWrapper({
    super.key,
    required this.child,
    this.duration = AnimationTokens.normal,
    this.curve = AnimationTokens.fastOutSlowIn,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!animate) {
      return child;
    }

    return child
        .animate()
        .fadeIn(duration: duration, curve: AnimationTokens.easeOut)
        .scale(
          duration: duration,
          curve: curve,
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
        );
  }
}
