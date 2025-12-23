import 'package:flutter/material.dart';
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
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => AnimatedDialogWrapper(
///     child: AlertDialog(...),
///   ),
/// );
/// ```
class AnimatedDialogWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AnimatedDialogWrapper({
    super.key,
    required this.child,
    this.duration = AnimationTokens.normal,
    this.curve = AnimationTokens.fastOutSlowIn,
  });

  @override
  State<AnimatedDialogWrapper> createState() => _AnimatedDialogWrapperState();
}

class _AnimatedDialogWrapperState extends State<AnimatedDialogWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AnimationTokens.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}
