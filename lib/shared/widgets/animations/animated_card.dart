import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
/// Uses flutter_animate for declarative animations with BookBed's
/// animation design tokens.
///
/// Usage:
/// ```dart
/// AnimatedCardEntrance(
///   delay: Duration(milliseconds: index * 100),
///   child: MyCard(),
/// )
/// ```
class AnimatedCardEntrance extends StatelessWidget {
  /// Card content
  final Widget child;

  /// Animation delay
  final Duration delay;

  /// Animation duration (default: fast - 200ms)
  final Duration duration;

  /// Slide offset (default: 30 pixels from bottom)
  final double slideOffset;

  /// Whether to animate (set false to skip animation)
  final bool animate;

  const AnimatedCardEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AnimationTokens.fast,
    this.slideOffset = 30,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!animate) {
      return child;
    }

    return child
        .animate(delay: delay)
        .fadeIn(
          duration: duration,
          curve: AnimationTokens.easeOut,
        )
        .slideY(
          duration: duration,
          curve: AnimationTokens.easeOut,
          begin: slideOffset,
          end: 0,
        );
  }
}
