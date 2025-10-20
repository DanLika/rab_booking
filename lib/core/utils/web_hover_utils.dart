import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import 'package:flutter/services.dart';
import 'platform_utils.dart';

/// Web hover utilities for creating hover effects on web/desktop
/// Provides hover state management and cursor changes
class WebHoverUtils {
  WebHoverUtils._();

  /// Default hover scale
  static const double defaultHoverScale = 1.02;

  /// Default hover opacity
  static const double defaultHoverOpacity = 0.9;

  /// Default hover duration
  static const Duration defaultHoverDuration = Duration(milliseconds: 200);
}

/// Widget that changes mouse cursor on hover
class HoverCursor extends StatelessWidget {
  /// Child widget
  final Widget child;

  /// Cursor style
  final SystemMouseCursor cursor;

  /// Callback when hover starts
  final VoidCallback? onEnter;

  /// Callback when hover ends
  final VoidCallback? onExit;

  const HoverCursor({
    super.key,
    required this.child,
    this.cursor = SystemMouseCursors.click,
    this.onEnter,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.supportsHover) {
      return child;
    }

    return MouseRegion(
      cursor: cursor,
      onEnter: (_) => onEnter?.call(),
      onExit: (_) => onExit?.call(),
      child: child,
    );
  }
}

/// Widget that scales on hover
class HoverScale extends StatefulWidget {
  /// Child widget
  final Widget child;

  /// Scale factor when hovered
  final double scale;

  /// Animation duration
  final Duration duration;

  /// Callback when hover starts
  final VoidCallback? onEnter;

  /// Callback when hover ends
  final VoidCallback? onExit;

  /// Mouse cursor
  final SystemMouseCursor cursor;

  const HoverScale({
    super.key,
    required this.child,
    this.scale = 1.05,
    this.duration = const Duration(milliseconds: 200),
    this.onEnter,
    this.onExit,
    this.cursor = SystemMouseCursors.click,
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.supportsHover) {
      return widget.child;
    }

    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onEnter?.call();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onExit?.call();
      },
      child: AnimatedScale(
        scale: _isHovered ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Widget that changes opacity on hover
class HoverOpacity extends StatefulWidget {
  /// Child widget
  final Widget child;

  /// Opacity when hovered
  final double hoverOpacity;

  /// Normal opacity
  final double normalOpacity;

  /// Animation duration
  final Duration duration;

  /// Callback when hover starts
  final VoidCallback? onEnter;

  /// Callback when hover ends
  final VoidCallback? onExit;

  /// Mouse cursor
  final SystemMouseCursor cursor;

  const HoverOpacity({
    super.key,
    required this.child,
    this.hoverOpacity = 0.7,
    this.normalOpacity = 1.0,
    this.duration = const Duration(milliseconds: 200),
    this.onEnter,
    this.onExit,
    this.cursor = SystemMouseCursors.click,
  });

  @override
  State<HoverOpacity> createState() => _HoverOpacityState();
}

class _HoverOpacityState extends State<HoverOpacity> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.supportsHover) {
      return widget.child;
    }

    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onEnter?.call();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onExit?.call();
      },
      child: AnimatedOpacity(
        opacity: _isHovered ? widget.hoverOpacity : widget.normalOpacity,
        duration: widget.duration,
        child: widget.child,
      ),
    );
  }
}

/// Widget that changes elevation/shadow on hover
class HoverElevation extends StatefulWidget {
  /// Child widget
  final Widget child;

  /// Normal elevation
  final double normalElevation;

  /// Hover elevation
  final double hoverElevation;

  /// Border radius
  final BorderRadius? borderRadius;

  /// Animation duration
  final Duration duration;

  /// Callback when hover starts
  final VoidCallback? onEnter;

  /// Callback when hover ends
  final VoidCallback? onExit;

  /// Mouse cursor
  final SystemMouseCursor cursor;

  const HoverElevation({
    super.key,
    required this.child,
    this.normalElevation = 2.0,
    this.hoverElevation = 8.0,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 200),
    this.onEnter,
    this.onExit,
    this.cursor = SystemMouseCursors.click,
  });

  @override
  State<HoverElevation> createState() => _HoverElevationState();
}

class _HoverElevationState extends State<HoverElevation> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.supportsHover) {
      return widget.child;
    }

    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onEnter?.call();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onExit?.call();
      },
      child: AnimatedPhysicalModel(
        color: Colors.transparent,
        elevation: _isHovered ? widget.hoverElevation : widget.normalElevation,
        shadowColor: Colors.black,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius (upgraded from 8),
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Builder that provides hover state
class HoverBuilder extends StatefulWidget {
  /// Builder function with hover state
  final Widget Function(BuildContext context, bool isHovered) builder;

  /// Callback when hover starts
  final VoidCallback? onEnter;

  /// Callback when hover ends
  final VoidCallback? onExit;

  /// Mouse cursor
  final SystemMouseCursor cursor;

  const HoverBuilder({
    super.key,
    required this.builder,
    this.onEnter,
    this.onExit,
    this.cursor = SystemMouseCursors.click,
  });

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.supportsHover) {
      return widget.builder(context, false);
    }

    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onEnter?.call();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onExit?.call();
      },
      child: widget.builder(context, _isHovered),
    );
  }
}

/// Combined hover widget with multiple effects
class HoverEffect extends StatefulWidget {
  /// Child widget
  final Widget child;

  /// Enable scale effect
  final bool enableScale;

  /// Scale factor
  final double scale;

  /// Enable opacity effect
  final bool enableOpacity;

  /// Hover opacity
  final double hoverOpacity;

  /// Enable elevation effect
  final bool enableElevation;

  /// Normal elevation
  final double normalElevation;

  /// Hover elevation
  final double hoverElevation;

  /// Border radius
  final BorderRadius? borderRadius;

  /// Animation duration
  final Duration duration;

  /// Mouse cursor
  final SystemMouseCursor cursor;

  /// Callback when hover starts
  final VoidCallback? onEnter;

  /// Callback when hover ends
  final VoidCallback? onExit;

  /// Tap callback
  final VoidCallback? onTap;

  const HoverEffect({
    super.key,
    required this.child,
    this.enableScale = true,
    this.scale = 1.02,
    this.enableOpacity = false,
    this.hoverOpacity = 0.9,
    this.enableElevation = false,
    this.normalElevation = 2.0,
    this.hoverElevation = 8.0,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 200),
    this.cursor = SystemMouseCursors.click,
    this.onEnter,
    this.onExit,
    this.onTap,
  });

  @override
  State<HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<HoverEffect> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.supportsHover) {
      return GestureDetector(
        onTap: widget.onTap,
        child: widget.child,
      );
    }

    Widget child = widget.child;

    // Apply opacity effect
    if (widget.enableOpacity) {
      child = AnimatedOpacity(
        opacity: _isHovered ? widget.hoverOpacity : 1.0,
        duration: widget.duration,
        child: child,
      );
    }

    // Apply scale effect
    if (widget.enableScale) {
      child = AnimatedScale(
        scale: _isHovered ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: child,
      );
    }

    // Apply elevation effect
    if (widget.enableElevation) {
      child = AnimatedPhysicalModel(
        color: Colors.transparent,
        elevation: _isHovered ? widget.hoverElevation : widget.normalElevation,
        shadowColor: Colors.black,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius (upgraded from 8),
        duration: widget.duration,
        curve: Curves.easeOut,
        child: child,
      );
    }

    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onEnter?.call();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onExit?.call();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: child,
      ),
    );
  }
}
