import 'package:flutter/material.dart';
import '../../domain/models/calendar_day.dart';
import '../../domain/models/calendar_update_event.dart';

/// Animation controller for real-time calendar updates
class RealtimeCalendarAnimations {
  /// Pulse animation duration
  static const pulseDuration = Duration(milliseconds: 800);

  /// Fade duration
  static const fadeDuration = Duration(milliseconds: 300);

  /// Scale animation curve
  static const scaleCurve = Curves.easeOutBack;

  /// Color animation curve
  static const colorCurve = Curves.easeInOut;
}

/// Animated calendar cell that shows real-time updates
class AnimatedCalendarCell extends StatefulWidget {
  final DateTime date;
  final CalendarDay dayData;
  final Widget child;
  final bool isUpdated;
  final CalendarUpdateAction? updateAction;
  final VoidCallback? onTap;

  const AnimatedCalendarCell({
    Key? key,
    required this.date,
    required this.dayData,
    required this.child,
    this.isUpdated = false,
    this.updateAction,
    this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedCalendarCell> createState() => _AnimatedCalendarCellState();
}

class _AnimatedCalendarCellState extends State<AnimatedCalendarCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: RealtimeCalendarAnimations.pulseDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: RealtimeCalendarAnimations.scaleCurve,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: RealtimeCalendarAnimations.colorCurve,
    ));

    if (widget.isUpdated) {
      _playAnimation();
    }
  }

  @override
  void didUpdateWidget(AnimatedCalendarCell oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger animation when isUpdated changes from false to true
    if (!oldWidget.isUpdated && widget.isUpdated) {
      _playAnimation();
    }
  }

  void _playAnimation() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                decoration: widget.isUpdated
                    ? BoxDecoration(
                        border: Border.all(
                          color: _getUpdateColor(widget.updateAction),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: _getUpdateColor(widget.updateAction)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      )
                    : null,
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getUpdateColor(CalendarUpdateAction? action) {
    switch (action) {
      case CalendarUpdateAction.insert:
        return Colors.green;
      case CalendarUpdateAction.update:
        return Colors.blue;
      case CalendarUpdateAction.delete:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}

/// Pulse overlay for newly updated cells
class PulseOverlay extends StatefulWidget {
  final Widget child;
  final bool shouldPulse;
  final Color pulseColor;

  const PulseOverlay({
    Key? key,
    required this.child,
    this.shouldPulse = false,
    this.pulseColor = Colors.blue,
  }) : super(key: key);

  @override
  State<PulseOverlay> createState() => _PulseOverlayState();
}

class _PulseOverlayState extends State<PulseOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    if (widget.shouldPulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.shouldPulse && widget.shouldPulse) {
      _controller.repeat(reverse: true);
    } else if (oldWidget.shouldPulse && !widget.shouldPulse) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.shouldPulse)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.pulseColor.withOpacity(_animation.value * 0.5),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Shimmer effect for loading/updating states
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const ShimmerEffect({
    Key? key,
    required this.child,
    this.isActive = false,
  }) : super(key: key);

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isActive && widget.isActive) {
      _controller.repeat();
    } else if (oldWidget.isActive && !widget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
              colors: [
                Colors.grey.shade300,
                Colors.white,
                Colors.grey.shade300,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Conflict indicator overlay
class ConflictIndicator extends StatelessWidget {
  final bool hasConflict;
  final String? conflictMessage;

  const ConflictIndicator({
    Key? key,
    required this.hasConflict,
    this.conflictMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!hasConflict) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          border: Border.all(
            color: Colors.red,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Tooltip(
            message: conflictMessage ?? 'Date conflict',
            child: Icon(
              Icons.warning,
              color: Colors.red,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Update notification banner
class UpdateNotificationBanner extends StatefulWidget {
  final String message;
  final CalendarUpdateAction action;
  final VoidCallback? onDismiss;
  final Duration duration;

  const UpdateNotificationBanner({
    Key? key,
    required this.message,
    required this.action,
    this.onDismiss,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<UpdateNotificationBanner> createState() =>
      _UpdateNotificationBannerState();
}

class _UpdateNotificationBannerState extends State<UpdateNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted && widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getBackgroundColor(widget.action),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getIcon(widget.action),
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _dismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(CalendarUpdateAction action) {
    switch (action) {
      case CalendarUpdateAction.insert:
        return Colors.green.shade600;
      case CalendarUpdateAction.update:
        return Colors.blue.shade600;
      case CalendarUpdateAction.delete:
        return Colors.red.shade600;
    }
  }

  IconData _getIcon(CalendarUpdateAction action) {
    switch (action) {
      case CalendarUpdateAction.insert:
        return Icons.add_circle;
      case CalendarUpdateAction.update:
        return Icons.update;
      case CalendarUpdateAction.delete:
        return Icons.delete;
    }
  }
}
