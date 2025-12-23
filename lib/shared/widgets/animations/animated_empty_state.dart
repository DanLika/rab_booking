import 'package:flutter/material.dart';
import '../../../core/design_tokens/animation_tokens.dart';

/// Animated empty state widget with fade + scale entrance animation
///
/// Usage:
/// ```dart
/// AnimatedEmptyState(
///   icon: Icons.inbox_outlined,
///   title: 'No bookings yet',
///   subtitle: 'Your bookings will appear here',
/// )
/// ```
class AnimatedEmptyState extends StatefulWidget {
  /// Icon to display
  final IconData icon;

  /// Main title text
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Optional action button
  final Widget? actionButton;

  /// Icon size (default: 64)
  final double iconSize;

  /// Icon color (defaults to theme's onSurfaceVariant with 0.5 opacity)
  final Color? iconColor;

  /// Whether to show animation (set false to skip animation)
  final bool animate;

  const AnimatedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionButton,
    this.iconSize = 64,
    this.iconColor,
    this.animate = true,
  });

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationTokens.normal,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AnimationTokens.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationTokens.fastOutSlowIn,
      ),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor =
        widget.iconColor ??
        theme.colorScheme.onSurfaceVariant.withAlpha((0.5 * 255).toInt());

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: widget.iconSize, color: effectiveIconColor),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((0.8 * 255).toInt()),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (widget.actionButton != null) ...[
            const SizedBox(height: 24),
            widget.actionButton!,
          ],
        ],
      ),
    );
  }
}

/// Staggered animated empty state with delayed animations for each element
///
/// Usage:
/// ```dart
/// StaggeredEmptyState(
///   icon: Icons.notifications_none,
///   title: 'No notifications',
///   subtitle: 'You're all caught up!',
/// )
/// ```
class StaggeredEmptyState extends StatefulWidget {
  /// Icon to display
  final IconData icon;

  /// Main title text
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Optional action button
  final Widget? actionButton;

  /// Icon size (default: 64)
  final double iconSize;

  /// Icon color (defaults to theme's onSurfaceVariant with 0.5 opacity)
  final Color? iconColor;

  /// Delay between each element animation (default: 100ms)
  final Duration staggerDelay;

  const StaggeredEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionButton,
    this.iconSize = 64,
    this.iconColor,
    this.staggerDelay = const Duration(milliseconds: 100),
  });

  @override
  State<StaggeredEmptyState> createState() => _StaggeredEmptyStateState();
}

class _StaggeredEmptyStateState extends State<StaggeredEmptyState>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<double>> _slideAnimations;

  int get _elementCount =>
      2 +
      (widget.subtitle != null ? 1 : 0) +
      (widget.actionButton != null ? 1 : 0);

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      _elementCount,
      (index) =>
          AnimationController(duration: AnimationTokens.fast, vsync: this),
    );

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: AnimationTokens.easeOut),
      );
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 20.0, end: 0.0).animate(
        CurvedAnimation(parent: controller, curve: AnimationTokens.easeOut),
      );
    }).toList();

    // Start staggered animations
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildAnimatedElement(int index, Widget child) {
    return AnimatedBuilder(
      animation: _controllers[index],
      builder: (context, _) {
        return Opacity(
          opacity: _fadeAnimations[index].value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimations[index].value),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor =
        widget.iconColor ??
        theme.colorScheme.onSurfaceVariant.withAlpha((0.5 * 255).toInt());

    int elementIndex = 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAnimatedElement(
          elementIndex++,
          Icon(widget.icon, size: widget.iconSize, color: effectiveIconColor),
        ),
        const SizedBox(height: 16),
        _buildAnimatedElement(
          elementIndex++,
          Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((0.8 * 255).toInt()),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          _buildAnimatedElement(
            elementIndex++,
            Text(
              widget.subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        if (widget.actionButton != null) ...[
          const SizedBox(height: 24),
          _buildAnimatedElement(elementIndex, widget.actionButton!),
        ],
      ],
    );
  }
}
