import 'package:flutter/material.dart';

/// AppBar with fade-in background on scroll
class FadeInAppBar extends StatefulWidget implements PreferredSizeWidget {
  const FadeInAppBar({
    required this.scrollController,
    required this.title,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.fadeThreshold = 100.0,
    super.key,
  });

  final ScrollController scrollController;
  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final double fadeThreshold;

  @override
  State<FadeInAppBar> createState() => _FadeInAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _FadeInAppBarState extends State<FadeInAppBar> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final offset = widget.scrollController.offset;
    final newOpacity = (offset / widget.fadeThreshold).clamp(0.0, 1.0);

    if (_opacity != newOpacity) {
      setState(() {
        _opacity = newOpacity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? Theme.of(context).primaryColor;

    return AppBar(
      title: widget.title,
      actions: widget.actions,
      leading: widget.leading,
      backgroundColor: bgColor.withValues(alpha: _opacity),
      elevation: _opacity > 0 ? 4 : 0,
      scrolledUnderElevation: 4,
    );
  }
}

/// Parallax effect for hero section
class ParallaxEffect extends StatefulWidget {
  const ParallaxEffect({
    required this.child,
    required this.scrollController,
    this.parallaxFactor = 0.3,
    super.key,
  });

  final Widget child;
  final ScrollController scrollController;
  final double parallaxFactor;

  @override
  State<ParallaxEffect> createState() => _ParallaxEffectState();
}

class _ParallaxEffectState extends State<ParallaxEffect> {
  double _offset = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final offset = widget.scrollController.offset;
    final newOffset = offset * widget.parallaxFactor;

    if (_offset != newOffset) {
      setState(() {
        _offset = newOffset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _offset),
      child: widget.child,
    );
  }
}

/// Fade in animation as widget enters viewport
class FadeInOnScroll extends StatefulWidget {
  const FadeInOnScroll({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOut,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;

  @override
  State<FadeInOnScroll> createState() => _FadeInOnScrollState();
}

class _FadeInOnScrollState extends State<FadeInOnScroll>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    // Delay animation if specified
    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _checkVisibility();
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkVisibility();
      });
    }
  }

  void _checkVisibility() {
    // Get the RenderBox of this widget
    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;

    final renderBox = renderObject as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Get screen height
    final screenHeight = MediaQuery.of(context).size.height;

    // Check if widget is in viewport
    final isInViewport = position.dy < screenHeight &&
        position.dy + size.height > 0;

    if (isInViewport && !_isVisible) {
      setState(() {
        _isVisible = true;
      });
      _controller.forward();
    }
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
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// List of items that fade in one by one as they enter viewport
class StaggeredFadeInList extends StatelessWidget {
  const StaggeredFadeInList({
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 600),
    super.key,
  });

  final List<Widget> children;
  final Duration staggerDelay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        children.length,
        (index) => FadeInOnScroll(
          delay: staggerDelay * index,
          duration: duration,
          child: children[index],
        ),
      ),
    );
  }
}

/// Scroll-aware widget that triggers callback when visible
class VisibilityDetector extends StatefulWidget {
  const VisibilityDetector({
    required this.child,
    required this.onVisible,
    this.threshold = 0.5,
    super.key,
  });

  final Widget child;
  final VoidCallback onVisible;
  final double threshold;

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  bool _hasTriggered = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!_hasTriggered) {
          _checkVisibility();
        }
        return false;
      },
      child: widget.child,
    );
  }

  void _checkVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasTriggered) return;

      final renderObject = context.findRenderObject();
      if (renderObject == null || !renderObject.attached) return;

      final renderBox = renderObject as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      final screenHeight = MediaQuery.of(context).size.height;

      // Calculate visibility percentage
      final visibleHeight = screenHeight - position.dy;
      final visibilityRatio = (visibleHeight / size.height).clamp(0.0, 1.0);

      if (visibilityRatio >= widget.threshold) {
        setState(() {
          _hasTriggered = true;
        });
        widget.onVisible();
      }
    });
  }
}
