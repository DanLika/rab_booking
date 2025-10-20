import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Scroll-triggered reveal animation widget
///
/// Animates child when it becomes visible during scrolling.
/// Supports fade, slide, and scale animations.
///
/// Example:
/// ```dart
/// ScrollReveal(
///   child: PropertyCard(...),
/// )
/// ```
class ScrollReveal extends StatefulWidget {
  /// Child widget to animate
  final Widget child;

  /// Animation type
  final ScrollRevealAnimation animation;

  /// Animation duration
  final Duration duration;

  /// Animation curve
  final Curve curve;

  /// Delay before animation starts
  final Duration delay;

  /// Visibility threshold (0.0 to 1.0)
  /// 0.2 = animate when 20% of widget is visible
  final double visibilityThreshold;

  /// Whether to animate only once or every time widget becomes visible
  final bool animateOnce;

  const ScrollReveal({
    required this.child,
    this.animation = ScrollRevealAnimation.fadeSlideUp,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
    this.visibilityThreshold = 0.2,
    this.animateOnce = true,
    super.key,
  });

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal> with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  bool _hasAnimated = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Fade animation (0.0 to 1.0)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Slide animation (depends on animation type)
    final slideOffset = _getSlideOffset();
    _slideAnimation = Tween<Offset>(
      begin: slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Scale animation (0.8 to 1.0)
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _getSlideOffset() {
    switch (widget.animation) {
      case ScrollRevealAnimation.fadeSlideUp:
        return const Offset(0, 0.3);
      case ScrollRevealAnimation.fadeSlideDown:
        return const Offset(0, -0.3);
      case ScrollRevealAnimation.fadeSlideLeft:
        return const Offset(0.3, 0);
      case ScrollRevealAnimation.fadeSlideRight:
        return const Offset(-0.3, 0);
      case ScrollRevealAnimation.fadeScale:
      case ScrollRevealAnimation.fade:
        return Offset.zero;
    }
  }

  void _handleVisibilityChange(VisibilityInfo info) {
    // Check if widget is visible enough
    final isVisible = info.visibleFraction >= widget.visibilityThreshold;

    // Animate only once if animateOnce is true
    if (widget.animateOnce && _hasAnimated) return;

    if (isVisible && !_isVisible) {
      setState(() => _isVisible = true);
      _hasAnimated = true;

      // Apply delay if specified
      if (widget.delay > Duration.zero) {
        Future.delayed(widget.delay, () {
          if (mounted) {
            _controller.forward();
          }
        });
      } else {
        _controller.forward();
      }
    } else if (!isVisible && _isVisible && !widget.animateOnce) {
      setState(() => _isVisible = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('scroll_reveal_${widget.child.hashCode}'),
      onVisibilityChanged: _handleVisibilityChange,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return _buildAnimatedChild();
        },
      ),
    );
  }

  Widget _buildAnimatedChild() {
    switch (widget.animation) {
      case ScrollRevealAnimation.fade:
        return FadeTransition(
          opacity: _fadeAnimation,
          child: widget.child,
        );

      case ScrollRevealAnimation.fadeSlideUp:
      case ScrollRevealAnimation.fadeSlideDown:
      case ScrollRevealAnimation.fadeSlideLeft:
      case ScrollRevealAnimation.fadeSlideRight:
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );

      case ScrollRevealAnimation.fadeScale:
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: widget.child,
          ),
        );
    }
  }
}

/// Animation types for ScrollReveal
enum ScrollRevealAnimation {
  /// Fade in only
  fade,

  /// Fade + slide from bottom (most common)
  fadeSlideUp,

  /// Fade + slide from top
  fadeSlideDown,

  /// Fade + slide from right
  fadeSlideLeft,

  /// Fade + slide from left
  fadeSlideRight,

  /// Fade + scale up
  fadeScale,
}

/// Batch scroll reveal widget
///
/// Reveals multiple children with staggered delays.
///
/// Example:
/// ```dart
/// ScrollRevealBatch(
///   children: [
///     PropertyCard(...),
///     PropertyCard(...),
///     PropertyCard(...),
///   ],
/// )
/// ```
class ScrollRevealBatch extends StatelessWidget {
  /// Children to animate
  final List<Widget> children;

  /// Stagger delay between children (in milliseconds)
  final int staggerDelay;

  /// Animation type
  final ScrollRevealAnimation animation;

  /// Animation duration
  final Duration duration;

  const ScrollRevealBatch({
    required this.children,
    this.staggerDelay = 100,
    this.animation = ScrollRevealAnimation.fadeSlideUp,
    this.duration = const Duration(milliseconds: 600),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        children.length,
        (index) => ScrollReveal(
          animation: animation,
          duration: duration,
          delay: Duration(milliseconds: index * staggerDelay),
          child: children[index],
        ),
      ),
    );
  }
}

/// Section reveal widget - for home screen sections
///
/// Wraps entire sections with scroll reveal animation.
///
/// Example:
/// ```dart
/// SectionReveal(
///   child: FeaturedPropertiesSection(),
/// )
/// ```
class SectionReveal extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const SectionReveal({
    required this.child,
    this.delay = Duration.zero,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollReveal(
      animation: ScrollRevealAnimation.fadeSlideUp,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      delay: delay,
      visibilityThreshold: 0.15, // Trigger earlier for sections
      child: child,
    );
  }
}
