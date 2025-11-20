import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Continuously rotating icon animation
/// Perfect for loading indicators, refresh icons
class RotatingIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final Duration duration;
  final bool animate;
  final Curve curve;

  const RotatingIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.duration = const Duration(seconds: 2),
    this.animate = true,
    this.curve = Curves.linear,
  });

  @override
  State<RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<RotatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(RotatingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: widget.curve),
      ),
      child: Icon(
        widget.icon,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}

/// Scale animation for icons (pulse effect)
/// Perfect for notification badges, attention grabbers
class ScaleIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final double minScale;
  final double maxScale;
  final Duration duration;
  final bool animate;
  final bool repeat;

  const ScaleIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.minScale = 1.0,
    this.maxScale = 1.2,
    this.duration = const Duration(milliseconds: 600),
    this.animate = true,
    this.repeat = true,
  });

  @override
  State<ScaleIcon> createState() => ScaleIconState();
}

class ScaleIconState extends State<ScaleIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: widget.minScale, end: widget.maxScale),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.maxScale, end: widget.minScale),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.animate) {
      if (widget.repeat) {
        _controller.repeat();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void didUpdateWidget(ScaleIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        if (widget.repeat) {
          _controller.repeat();
        } else {
          _controller.forward();
        }
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

  /// Trigger animation programmatically
  void pulse() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Icon(
        widget.icon,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}

/// Color shift animation for icons
/// Perfect for state changes, favorites, likes
class ColorShiftIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color startColor;
  final Color endColor;
  final Duration duration;
  final bool animate;
  final Curve curve;

  const ColorShiftIcon({
    super.key,
    required this.icon,
    this.size = 24,
    required this.startColor,
    required this.endColor,
    this.duration = const Duration(milliseconds: 300),
    this.animate = false,
    this.curve = Curves.easeInOut,
  });

  @override
  State<ColorShiftIcon> createState() => ColorShiftIconState();
}

class ColorShiftIconState extends State<ColorShiftIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _colorAnimation = ColorTween(
      begin: widget.startColor,
      end: widget.endColor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ColorShiftIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Toggle color animation
  void toggle() {
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  /// Set animation state
  void setAnimated(bool animated) {
    if (animated) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Icon(
          widget.icon,
          size: widget.size,
          color: _colorAnimation.value,
        );
      },
    );
  }
}

/// Pulse icon with glow effect
/// Perfect for notifications, alerts, live indicators
class PulseIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final bool showPulse;
  final Duration pulseDuration;

  const PulseIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.showPulse = true,
    this.pulseDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<PulseIcon>
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.showPulse) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PulseIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showPulse != oldWidget.showPulse) {
      if (widget.showPulse) {
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
    final iconColor = widget.color ?? AppColors.authPrimary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring
            if (widget.showPulse)
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Icon(
                  widget.icon,
                  size: widget.size,
                  color: iconColor.withOpacity(_opacityAnimation.value),
                ),
              ),

            // Main icon
            Icon(
              widget.icon,
              size: widget.size,
              color: iconColor,
            ),
          ],
        );
      },
    );
  }
}

/// Bouncing icon animation
/// Perfect for playful interactions, success indicators
class BouncingIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final bool animate;
  final Duration duration;

  const BouncingIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.animate = false,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<BouncingIcon> createState() => BouncingIconState();
}

class BouncingIconState extends State<BouncingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.95), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(BouncingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate && widget.animate) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Trigger bounce animation
  void bounce() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: child,
        );
      },
      child: Icon(
        widget.icon,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}

/// Shake icon animation
/// Perfect for errors, warnings, attention
class ShakeIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final bool animate;
  final Duration duration;

  const ShakeIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.animate = false,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<ShakeIcon> createState() => ShakeIconState();
}

class ShakeIconState extends State<ShakeIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticIn,
    ));

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ShakeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate && widget.animate) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Trigger shake animation
  void shake() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Icon(
        widget.icon,
        size: widget.size,
        color: widget.color ?? AppColors.error,
      ),
    );
  }
}
