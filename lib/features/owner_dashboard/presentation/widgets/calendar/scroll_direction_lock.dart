import 'package:flutter/material.dart';

/// Widget that locks scroll to one direction (horizontal OR vertical) per gesture.
///
/// How it works:
/// 1. Detects initial finger movement direction using Listener (BEFORE gesture arena)
/// 2. Locks to that axis for the entire gesture
/// 3. Blocks the other scroll direction until finger is lifted
class ScrollDirectionLock extends StatefulWidget {
  final Widget child;

  /// Threshold in pixels before direction is locked.
  /// Higher = more movement needed before lock, but more accurate detection.
  /// Lower = faster lock, but might misdetect diagonal as one direction.
  final double lockThreshold;

  const ScrollDirectionLock({
    super.key,
    required this.child,
    this.lockThreshold = 8.0,
  });

  @override
  State<ScrollDirectionLock> createState() => _ScrollDirectionLockState();
}

class _ScrollDirectionLockState extends State<ScrollDirectionLock> {
  /// Current locked direction (null = not locked yet)
  Axis? _lockedAxis;

  /// Starting position of current gesture
  Offset? _startPosition;

  /// Accumulated delta since gesture start (for threshold detection)
  Offset _accumulatedDelta = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Listener intercepts pointer events BEFORE they reach scroll widgets
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: _buildScrollableContent(),
    );
  }

  Widget _buildScrollableContent() {
    // If direction is locked, wrap with a widget that blocks the other direction
    if (_lockedAxis == Axis.vertical) {
      // Vertical scroll locked - block horizontal
      return _HorizontalScrollBlocker(child: widget.child);
    } else if (_lockedAxis == Axis.horizontal) {
      // Horizontal scroll locked - block vertical
      return _VerticalScrollBlocker(child: widget.child);
    }

    // No lock yet - allow both (first movement will determine direction)
    return widget.child;
  }

  void _onPointerDown(PointerDownEvent event) {
    _startPosition = event.position;
    _accumulatedDelta = Offset.zero;
    // Don't reset _lockedAxis here - it will be reset on pointer up
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_startPosition == null) return;

    // If already locked, nothing to do
    if (_lockedAxis != null) return;

    // Accumulate movement
    _accumulatedDelta += event.delta;

    final dx = _accumulatedDelta.dx.abs();
    final dy = _accumulatedDelta.dy.abs();

    // Check if we've moved enough to determine direction
    if (dx > widget.lockThreshold || dy > widget.lockThreshold) {
      // Determine dominant direction
      final newAxis = dy > dx ? Axis.vertical : Axis.horizontal;

      setState(() {
        _lockedAxis = newAxis;
      });
    }
  }

  void _onPointerUp(PointerEvent event) {
    // Reset for next gesture
    setState(() {
      _lockedAxis = null;
      _startPosition = null;
      _accumulatedDelta = Offset.zero;
    });
  }
}

/// Blocks horizontal scroll by absorbing horizontal drag gestures
class _HorizontalScrollBlocker extends StatelessWidget {
  final Widget child;

  const _HorizontalScrollBlocker({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Claim horizontal drag gestures but do nothing with them
      onHorizontalDragStart: (_) {},
      onHorizontalDragUpdate: (_) {},
      onHorizontalDragEnd: (_) {},
      // HitTestBehavior.translucent allows child to still receive events
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

/// Blocks vertical scroll by absorbing vertical drag gestures
class _VerticalScrollBlocker extends StatelessWidget {
  final Widget child;

  const _VerticalScrollBlocker({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Claim vertical drag gestures but do nothing with them
      onVerticalDragStart: (_) {},
      onVerticalDragUpdate: (_) {},
      onVerticalDragEnd: (_) {},
      // HitTestBehavior.translucent allows child to still receive events
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
