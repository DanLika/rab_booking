import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/design_tokens/animation_tokens.dart';

/// Animated button with scale effect on press
///
/// Usage:
/// ```dart
/// AnimatedPressButton(
///   onPressed: () => handleSave(),
///   child: Text('Save'),
/// )
/// ```
class AnimatedPressButton extends StatefulWidget {
  /// Button press callback
  final VoidCallback? onPressed;

  /// Button child content
  final Widget child;

  /// Scale factor when pressed (default: 0.95)
  final double pressedScale;

  /// Animation duration (default: instant - 100ms)
  final Duration duration;

  /// Button style
  final ButtonStyle? style;

  /// Whether this is a filled/elevated button (true) or text/outlined button (false)
  final bool isFilled;

  const AnimatedPressButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.pressedScale = 0.95,
    this.duration = AnimationTokens.instant,
    this.style,
    this.isFilled = true,
  });

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final button = widget.isFilled
        ? ElevatedButton(
            onPressed: widget.onPressed,
            style: widget.style,
            child: widget.child,
          )
        : OutlinedButton(
            onPressed: widget.onPressed,
            style: widget.style,
            child: widget.child,
          );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: AnimationTokens.easeOut,
        child: button,
      ),
    );
  }
}

/// Animated icon button with scale effect on press
///
/// Usage:
/// ```dart
/// AnimatedIconButton(
///   onPressed: () => handleAction(),
///   icon: Icons.add,
/// )
/// ```
class AnimatedIconButton extends StatefulWidget {
  /// Button press callback
  final VoidCallback? onPressed;

  /// Icon to display
  final IconData icon;

  /// Icon size (default: 24)
  final double iconSize;

  /// Icon color
  final Color? iconColor;

  /// Scale factor when pressed (default: 0.85)
  final double pressedScale;

  /// Animation duration (default: instant - 100ms)
  final Duration duration;

  /// Tooltip text
  final String? tooltip;

  const AnimatedIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.iconSize = 24,
    this.iconColor,
    this.pressedScale = 0.85,
    this.duration = AnimationTokens.instant,
    this.tooltip,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: AnimationTokens.easeOut,
        child: IconButton(
          onPressed: widget.onPressed,
          icon: Icon(widget.icon),
          iconSize: widget.iconSize,
          color: widget.iconColor,
          tooltip: widget.tooltip,
        ),
      ),
    );
  }
}

/// Animated FAB with scale effect and optional pulse animation
///
/// Uses flutter_animate for pulse animation with BookBed's
/// animation design tokens. Press scale uses AnimatedScale for
/// responsive feedback.
///
/// Usage:
/// ```dart
/// AnimatedFAB(
///   onPressed: () => handleAdd(),
///   icon: Icons.add,
///   showPulse: true, // Optional attention-grabbing pulse
/// )
/// ```
class AnimatedFAB extends StatefulWidget {
  /// Button press callback
  final VoidCallback? onPressed;

  /// Icon to display
  final IconData icon;

  /// FAB label (for extended FAB)
  final String? label;

  /// Scale factor when pressed (default: 0.9)
  final double pressedScale;

  /// Whether to show pulse animation when idle
  final bool showPulse;

  /// FAB background color
  final Color? backgroundColor;

  /// FAB foreground color
  final Color? foregroundColor;

  const AnimatedFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.pressedScale = 0.9,
    this.showPulse = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Widget fab;

    if (widget.label != null) {
      fab = FloatingActionButton.extended(
        onPressed: widget.onPressed,
        icon: Icon(widget.icon),
        label: Text(widget.label!),
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.foregroundColor,
      );
    } else {
      fab = FloatingActionButton(
        onPressed: widget.onPressed,
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.foregroundColor,
        child: Icon(widget.icon),
      );
    }

    // Apply pulse animation if enabled
    if (widget.showPulse) {
      fab = fab
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            duration: AnimationTokens.long,
            curve: AnimationTokens.easeInOut,
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.08, 1.08),
          );
    }

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: AnimationTokens.instant,
        curve: AnimationTokens.easeOut,
        child: fab,
      ),
    );
  }
}
