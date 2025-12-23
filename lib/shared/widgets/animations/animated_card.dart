import 'package:flutter/material.dart';
import '../../../core/design_tokens/animation_tokens.dart';

/// Animated card with hover effects (scale + elevation) for desktop
///
/// Usage:
/// ```dart
/// HoverScaleCard(
///   onTap: () => handleTap(),
///   child: MyCardContent(),
/// )
/// ```
class HoverScaleCard extends StatefulWidget {
  /// Card content
  final Widget child;

  /// Tap callback
  final VoidCallback? onTap;

  /// Scale factor on hover (default: 1.02)
  final double hoverScale;

  /// Base elevation (default: 1)
  final double baseElevation;

  /// Hover elevation (default: 4)
  final double hoverElevation;

  /// Card border radius (default: 12)
  final double borderRadius;

  /// Card background color
  final Color? backgroundColor;

  /// Card border color
  final Color? borderColor;

  /// Card padding
  final EdgeInsetsGeometry? padding;

  /// Animation duration (default: fast - 200ms)
  final Duration duration;

  const HoverScaleCard({
    super.key,
    required this.child,
    this.onTap,
    this.hoverScale = 1.02,
    this.baseElevation = 1,
    this.hoverElevation = 4,
    this.borderRadius = 12,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.duration = AnimationTokens.fast,
  });

  @override
  State<HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<HoverScaleCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor =
        widget.backgroundColor ?? theme.colorScheme.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: widget.duration,
          curve: AnimationTokens.easeOut,
          transform: Matrix4.identity()
            ..setEntry(
              0,
              0,
              _isPressed
                  ? 0.98
                  : _isHovered
                  ? widget.hoverScale
                  : 1.0,
            )
            ..setEntry(
              1,
              1,
              _isPressed
                  ? 0.98
                  : _isHovered
                  ? widget.hoverScale
                  : 1.0,
            ),
          transformAlignment: Alignment.center,
          child: AnimatedContainer(
            duration: widget.duration,
            curve: AnimationTokens.easeOut,
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: widget.borderColor != null
                  ? Border.all(color: widget.borderColor!)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(
                    ((_isHovered ? 0.12 : 0.06) * 255).toInt(),
                  ),
                  blurRadius: _isHovered
                      ? widget.hoverElevation * 2
                      : widget.baseElevation * 2,
                  offset: Offset(
                    0,
                    _isHovered ? widget.hoverElevation : widget.baseElevation,
                  ),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: widget.padding != null
                  ? Padding(padding: widget.padding!, child: widget.child)
                  : widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated list tile with hover highlight effect
///
/// Usage:
/// ```dart
/// HoverListTile(
///   onTap: () => handleTap(),
///   leading: Icon(Icons.notification),
///   title: Text('New booking'),
///   subtitle: Text('Just now'),
/// )
/// ```
class HoverListTile extends StatefulWidget {
  /// Tile tap callback
  final VoidCallback? onTap;

  /// Leading widget
  final Widget? leading;

  /// Title widget
  final Widget title;

  /// Subtitle widget
  final Widget? subtitle;

  /// Trailing widget
  final Widget? trailing;

  /// Animation duration (default: fast - 200ms)
  final Duration duration;

  /// Content padding
  final EdgeInsetsGeometry? contentPadding;

  const HoverListTile({
    super.key,
    this.onTap,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.duration = AnimationTokens.fast,
    this.contentPadding,
  });

  @override
  State<HoverListTile> createState() => _HoverListTileState();
}

class _HoverListTileState extends State<HoverListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: AnimationTokens.easeOut,
        color: _isHovered
            ? theme.colorScheme.primary.withAlpha((0.08 * 255).toInt())
            : Colors.transparent,
        child: ListTile(
          onTap: widget.onTap,
          leading: widget.leading,
          title: widget.title,
          subtitle: widget.subtitle,
          trailing: widget.trailing,
          contentPadding: widget.contentPadding,
        ),
      ),
    );
  }
}

/// Entrance animation wrapper for cards/list items
///
/// Usage:
/// ```dart
/// AnimatedCardEntrance(
///   delay: Duration(milliseconds: index * 100),
///   child: MyCard(),
/// )
/// ```
class AnimatedCardEntrance extends StatefulWidget {
  /// Card content
  final Widget child;

  /// Animation delay
  final Duration delay;

  /// Animation duration (default: normal - 300ms)
  final Duration duration;

  /// Slide offset (default: 30 pixels from bottom)
  final double slideOffset;

  const AnimatedCardEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AnimationTokens.normal,
    this.slideOffset = 30,
  });

  @override
  State<AnimatedCardEntrance> createState() => _AnimatedCardEntranceState();
}

class _AnimatedCardEntranceState extends State<AnimatedCardEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AnimationTokens.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(
          begin: Offset(0, widget.slideOffset),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _controller, curve: AnimationTokens.easeOut),
        );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
