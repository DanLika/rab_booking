import 'package:flutter/material.dart';

/// Smart tooltip that automatically finds the best position to display
/// on small screens (360px and below) by trying different positions
/// until it finds one with enough space.
///
/// Usage:
/// ```dart
/// SmartTooltip(
///   message: 'Tooltip text',
///   child: IconButton(icon: Icon(Icons.info), onPressed: () {}),
/// )
/// ```
class SmartTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final Duration? waitDuration;
  final Duration? showDuration;
  final TextStyle? textStyle;
  final Decoration? decoration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final bool? preferBelow;
  final bool excludeFromSemantics;
  final TooltipTriggerMode? triggerMode;

  const SmartTooltip({
    super.key,
    required this.message,
    required this.child,
    this.waitDuration,
    this.showDuration,
    this.textStyle,
    this.decoration,
    this.padding,
    this.margin,
    this.height,
    this.preferBelow,
    this.excludeFromSemantics = false,
    this.triggerMode,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // On very small screens (360px and below), use custom positioning
    if (screenWidth <= 360) {
      return _SmartTooltipOverlay(
        message: message,
        waitDuration: waitDuration,
        showDuration: showDuration,
        textStyle: textStyle,
        decoration: decoration,
        padding: padding,
        margin: margin,
        height: height,
        excludeFromSemantics: excludeFromSemantics,
        triggerMode: triggerMode,
        child: child,
      );
    }

    // On larger screens, use standard Tooltip
    final minHeight = height;
    return Tooltip(
      message: message,
      waitDuration: waitDuration ?? const Duration(milliseconds: 500),
      constraints: minHeight != null
          ? BoxConstraints(minHeight: minHeight)
          : null,
      showDuration: showDuration,
      textStyle: textStyle,
      decoration: decoration,
      padding: padding,
      margin: margin,
      preferBelow: preferBelow,
      excludeFromSemantics: excludeFromSemantics,
      triggerMode: triggerMode,
      child: child,
    );
  }
}

/// Custom tooltip overlay that finds the best position on small screens
class _SmartTooltipOverlay extends StatefulWidget {
  final String message;
  final Widget child;
  final Duration? waitDuration;
  final Duration? showDuration;
  final TextStyle? textStyle;
  final Decoration? decoration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final bool excludeFromSemantics;
  final TooltipTriggerMode? triggerMode;

  const _SmartTooltipOverlay({
    required this.message,
    required this.child,
    this.waitDuration,
    this.showDuration,
    this.textStyle,
    this.decoration,
    this.padding,
    this.margin,
    this.height,
    this.excludeFromSemantics = false,
    this.triggerMode,
  });

  @override
  State<_SmartTooltipOverlay> createState() => _SmartTooltipOverlayState();
}

class _SmartTooltipOverlayState extends State<_SmartTooltipOverlay> {
  OverlayEntry? _overlayEntry;
  bool _isHovering = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    // Defensive check: ensure widget is still mounted before accessing context
    if (!mounted) return;

    try {
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) return;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;

      // Defensive check: ensure size is valid and finite
      final size = renderBox.size;
      if (!size.width.isFinite ||
          !size.height.isFinite ||
          size.width <= 0 ||
          size.height <= 0) {
        return;
      }

      final position = renderBox.localToGlobal(Offset.zero);

      // Defensive check: ensure position is valid
      if (!position.dx.isFinite || !position.dy.isFinite) {
        return;
      }

      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery == null) return;

      final screenSize = mediaQuery.size;

      // Defensive check: ensure screen size is valid
      if (!screenSize.width.isFinite ||
          !screenSize.height.isFinite ||
          screenSize.width <= 0 ||
          screenSize.height <= 0) {
        return;
      }

      _overlayEntry = OverlayEntry(
        builder: (context) => _TooltipPositioner(
          message: widget.message,
          targetPosition: position,
          targetSize: size,
          screenSize: screenSize,
          textStyle: widget.textStyle,
          decoration: widget.decoration,
          padding: widget.padding,
          margin: widget.margin,
          height: widget.height,
          onDismiss: _removeOverlay,
        ),
      );

      overlay.insert(_overlayEntry!);
    } catch (e) {
      // Ignore errors if context is no longer valid or RenderBox is disposed
      // This can happen if widget is disposed while overlay is being shown
      return;
    }
  }

  void _removeOverlay() {
    try {
      _overlayEntry?.remove();
    } catch (e) {
      // Ignore errors if overlay is already removed or context is invalid
    } finally {
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
        Future.delayed(
          widget.waitDuration ?? const Duration(milliseconds: 500),
          () {
            if (_isHovering && mounted) {
              _showOverlay();
            }
          },
        );
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        _removeOverlay();
      },
      child: GestureDetector(
        onLongPress: () {
          if (!_isHovering && mounted) {
            _showOverlay();
            Future.delayed(
              widget.showDuration ?? const Duration(seconds: 2),
              () {
                if (mounted) {
                  _removeOverlay();
                }
              },
            );
          }
        },
        child: widget.child,
      ),
    );
  }
}

/// Widget that positions the tooltip in the best available space
class _TooltipPositioner extends StatelessWidget {
  final String message;
  final Offset targetPosition;
  final Size targetSize;
  final Size screenSize;
  final TextStyle? textStyle;
  final Decoration? decoration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final VoidCallback onDismiss;

  const _TooltipPositioner({
    required this.message,
    required this.targetPosition,
    required this.targetSize,
    required this.screenSize,
    this.textStyle,
    this.decoration,
    this.padding,
    this.margin,
    this.height,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate tooltip size (approximate)
    final tooltipPadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    final tooltipMargin = margin ?? const EdgeInsets.all(8);
    final maxWidth = screenSize.width * 0.7; // Max 70% of screen width
    final estimatedHeight = height ?? 32.0;

    // Try different positions in order of preference
    final positions = _calculateBestPosition(
      targetPosition: targetPosition,
      targetSize: targetSize,
      screenSize: screenSize,
      tooltipWidth: maxWidth,
      tooltipHeight: estimatedHeight,
      margin: tooltipMargin,
    );

    final bestPosition = positions.first;

    return Stack(
      children: [
        // Transparent barrier to detect taps outside
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Tooltip
        Positioned(
          left: bestPosition.alignment == _TooltipAlignment.left
              ? null
              : bestPosition.offset.dx,
          right: bestPosition.alignment == _TooltipAlignment.right
              ? null
              : screenSize.width - bestPosition.offset.dx,
          top: bestPosition.alignment == _TooltipAlignment.top
              ? null
              : bestPosition.offset.dy,
          bottom: bestPosition.alignment == _TooltipAlignment.bottom
              ? null
              : screenSize.height - bestPosition.offset.dy,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: tooltipPadding as EdgeInsets?,
                margin: tooltipMargin as EdgeInsets?,
                decoration:
                    decoration ??
                    BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2D2D3A)
                          : const Color(0xFF424242),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                child: Text(
                  message,
                  style:
                      textStyle ??
                      theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Calculate the best position for the tooltip
  List<_TooltipPosition> _calculateBestPosition({
    required Offset targetPosition,
    required Size targetSize,
    required Size screenSize,
    required double tooltipWidth,
    required double tooltipHeight,
    required EdgeInsetsGeometry margin,
  }) {
    final marginInsets = margin as EdgeInsets;
    final positions = <_TooltipPosition>[];

    // Calculate center of target
    final targetCenter = Offset(
      targetPosition.dx + targetSize.width / 2,
      targetPosition.dy + targetSize.height / 2,
    );

    // Try bottom (preferred)
    final bottomY = targetPosition.dy + targetSize.height + marginInsets.top;
    if (bottomY + tooltipHeight + marginInsets.bottom < screenSize.height) {
      positions.add(
        _TooltipPosition(
          offset: Offset(
            (targetCenter.dx - tooltipWidth / 2).clamp(
              marginInsets.left,
              screenSize.width - tooltipWidth - marginInsets.right,
            ),
            bottomY,
          ),
          alignment: _TooltipAlignment.bottom,
          score: 10, // Highest priority
        ),
      );
    }

    // Try top
    final topY = targetPosition.dy - tooltipHeight - marginInsets.bottom;
    if (topY > marginInsets.top) {
      positions.add(
        _TooltipPosition(
          offset: Offset(
            (targetCenter.dx - tooltipWidth / 2).clamp(
              marginInsets.left,
              screenSize.width - tooltipWidth - marginInsets.right,
            ),
            topY,
          ),
          alignment: _TooltipAlignment.top,
          score: 9,
        ),
      );
    }

    // Try right
    final rightX = targetPosition.dx + targetSize.width + marginInsets.left;
    if (rightX + tooltipWidth + marginInsets.right < screenSize.width) {
      positions.add(
        _TooltipPosition(
          offset: Offset(
            rightX,
            (targetCenter.dy - tooltipHeight / 2).clamp(
              marginInsets.top,
              screenSize.height - tooltipHeight - marginInsets.bottom,
            ),
          ),
          alignment: _TooltipAlignment.right,
          score: 8,
        ),
      );
    }

    // Try left
    final leftX = targetPosition.dx - tooltipWidth - marginInsets.right;
    if (leftX > marginInsets.left) {
      positions.add(
        _TooltipPosition(
          offset: Offset(
            leftX,
            (targetCenter.dy - tooltipHeight / 2).clamp(
              marginInsets.top,
              screenSize.height - tooltipHeight - marginInsets.bottom,
            ),
          ),
          alignment: _TooltipAlignment.left,
          score: 7,
        ),
      );
    }

    // If no good position found, use bottom-left corner as fallback
    if (positions.isEmpty) {
      positions.add(
        _TooltipPosition(
          offset: Offset(
            marginInsets.left,
            screenSize.height - tooltipHeight - marginInsets.bottom - 50,
          ),
          alignment: _TooltipAlignment.bottom,
          score: 1,
        ),
      );
    }

    // Sort by score (highest first)
    positions.sort((a, b) => b.score.compareTo(a.score));

    return positions;
  }
}

enum _TooltipAlignment { top, bottom, left, right }

class _TooltipPosition {
  final Offset offset;
  final _TooltipAlignment alignment;
  final int score;

  _TooltipPosition({
    required this.offset,
    required this.alignment,
    required this.score,
  });
}
