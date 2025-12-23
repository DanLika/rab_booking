import 'package:flutter/material.dart';
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
/// Usage:
/// ```dart
/// AnimatedFAB(
///   onPressed: () => handleAdd(),
///   icon: Icons.add,
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

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: AnimationTokens.long,
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: AnimationTokens.easeInOut,
      ),
    );

    if (widget.showPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showPulse && !oldWidget.showPulse) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.showPulse && oldWidget.showPulse) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final pulseScale = widget.showPulse ? _pulseAnimation.value : 1.0;
          final pressScale = _isPressed ? widget.pressedScale : 1.0;

          return Transform.scale(scale: pulseScale * pressScale, child: child);
        },
        child: fab,
      ),
    );
  }
}
