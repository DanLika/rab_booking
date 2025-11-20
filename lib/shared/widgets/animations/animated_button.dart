import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/haptic_service.dart';

/// Animated button with scale and ripple effects
/// Press animation: scales down slightly
/// Release animation: bounces back with ripple
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final EdgeInsets padding;
  final double? width;
  final double? height;
  final bool enabled;
  final bool isLoading;
  final double scaleOnPress;
  final Duration scaleDuration;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = AppDimensions.radiusM,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.spaceL,
      vertical: AppDimensions.spaceM,
    ),
    this.width,
    this.height,
    this.enabled = true,
    this.isLoading = false,
    this.scaleOnPress = 0.95,
    this.scaleDuration = const Duration(milliseconds: 100),
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.scaleDuration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleOnPress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && !widget.isLoading && widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ??
        (isDark ? AppColors.authPrimaryDark : AppColors.authPrimary);
    final fgColor = widget.foregroundColor ?? Colors.white;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.enabled && !widget.isLoading && widget.onPressed != null
          ? () async {
              await HapticService.buttonPress();
              widget.onPressed!();
            }
          : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.enabled ? bgColor : bgColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: widget.isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                  ),
                )
              : DefaultTextStyle(
                  style: TextStyle(color: fgColor),
                  child: IconTheme(
                    data: IconThemeData(color: fgColor),
                    child: widget.child,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Ripple button with custom ripple effect
class RippleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? rippleColor;
  final Color? backgroundColor;
  final double borderRadius;
  final EdgeInsets padding;
  final double? width;
  final double? height;

  const RippleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.rippleColor,
    this.backgroundColor,
    this.borderRadius = AppDimensions.radiusM,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.spaceL,
      vertical: AppDimensions.spaceM,
    ),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.authPrimary,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onPressed == null
            ? null
            : () async {
                await HapticService.buttonPress();
                onPressed!();
              },
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: rippleColor ?? Colors.white.withOpacity(0.3),
        highlightColor: rippleColor ?? Colors.white.withOpacity(0.1),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Loading button that shows spinner when isLoading is true
class LoadingButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final bool isFullWidth;

  const LoadingButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = AppDimensions.radiusM,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      borderRadius: borderRadius,
      isLoading: isLoading,
      enabled: !isLoading,
      width: isFullWidth ? double.infinity : null,
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null && !isLoading) ...[
            Icon(icon, size: 20),
            const SizedBox(width: AppDimensions.spaceS),
          ],
          Text(label),
        ],
      ),
    );
  }
}

/// Pulse button - pulses to draw attention
class PulseButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? pulseColor;
  final double borderRadius;
  final EdgeInsets padding;
  final bool enablePulse;
  final Duration pulseDuration;

  const PulseButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.pulseColor,
    this.borderRadius = AppDimensions.radiusM,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.spaceL,
      vertical: AppDimensions.spaceM,
    ),
    this.enablePulse = true,
    this.pulseDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<PulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.pulseDuration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.enablePulse) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PulseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enablePulse != oldWidget.enablePulse) {
      if (widget.enablePulse) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? AppColors.authPrimary;
    final pulseColor = widget.pulseColor ?? bgColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse rings
            if (widget.enablePulse) ...[
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: pulseColor.withOpacity(_opacityAnimation.value),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                  child: Opacity(opacity: 0, child: widget.child),
                ),
              ),
            ],

            // Actual button
            Material(
              color: bgColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: InkWell(
                onTap: widget.onPressed == null
                    ? null
                    : () async {
                        await HapticService.buttonPress();
                        widget.onPressed!();
                      },
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Container(
                  padding: widget.padding,
                  child: widget.child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Icon button with rotation animation
class RotatingIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final bool rotateOnPress;
  final Duration rotationDuration;

  const RotatingIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.size = 48,
    this.rotateOnPress = true,
    this.rotationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<RotatingIconButton> createState() => _RotatingIconButtonState();
}

class _RotatingIconButtonState extends State<RotatingIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.rotationDuration,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePressed() async {
    await HapticService.buttonPress();
    if (widget.rotateOnPress) {
      unawaited(_controller.forward().then((_) => _controller.reverse()));
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _rotationAnimation,
      child: Material(
        color: widget.backgroundColor ?? Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: _handlePressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              color: widget.iconColor ?? AppColors.authPrimary,
              size: widget.size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouncy button with spring animation
class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final double borderRadius;
  final EdgeInsets padding;

  const BouncyButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.borderRadius = AppDimensions.radiusM,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.spaceL,
      vertical: AppDimensions.spaceM,
    ),
  });

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.98), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePressed() async {
    await HapticService.buttonPress();
    unawaited(_controller.forward(from: 0));
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handlePressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.authPrimary,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
