import 'package:flutter/widgets.dart';

/// Snap-to-day scroll physics for Timeline Calendar
///
/// Key behaviors:
/// - ALL swipes (weak or strong) snap to nearest day boundary
/// - No bounce-back: calendar stays where finger releases (plus snap)
/// - Critically damped spring: smooth animation without oscillation
/// - Directional intent: strong swipes (velocity > 200) snap in swipe direction
///
/// This fixes the Android weak-swipe bounce-back bug where ClampingScrollPhysics
/// returns null for low-velocity gestures, causing scroll to "settle back" to start.
class TimelineSnapScrollPhysics extends ClampingScrollPhysics {
  /// Width of a single day cell in pixels
  final double dayWidth;

  /// Velocity threshold for directional intent (pixels/second)
  /// Below this: snap to nearest day
  /// Above this: snap in direction of velocity
  static const double _velocityThreshold = 200.0;

  const TimelineSnapScrollPhysics({required this.dayWidth, super.parent});

  @override
  TimelineSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TimelineSnapScrollPhysics(
      dayWidth: dayWidth,
      parent: buildParent(ancestor),
    );
  }

  // Very low threshold to capture weak swipes on Android
  // Android has diagonal swipe velocity reduction (19-56% loss)
  @override
  double get minFlingVelocity => 10.0;

  // Lower drag start distance for more responsive feel
  @override
  double get dragStartDistanceMotionThreshold => 3.5;

  /// CRITICAL FIX: Override to ensure ALL swipes snap to day boundary
  ///
  /// Default ClampingScrollPhysics returns null for low-velocity gestures,
  /// causing the scroll to "settle back" to its starting position.
  /// This override ALWAYS returns a snap simulation, regardless of velocity.
  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Safety check for invalid day width
    if (dayWidth <= 0) {
      return super.createBallisticSimulation(position, velocity);
    }

    final double currentOffset = position.pixels;
    final double minExtent = position.minScrollExtent;
    final double maxExtent = position.maxScrollExtent;

    // Handle edge cases: already at or beyond boundaries
    if (currentOffset <= minExtent || currentOffset >= maxExtent) {
      // Let parent handle boundary behavior
      return super.createBallisticSimulation(position, velocity);
    }

    // Calculate current day position
    final int currentPage = (currentOffset / dayWidth).floor();
    final double remainder = currentOffset - (currentPage * dayWidth);
    final double fractionOfDay = remainder / dayWidth;

    // Determine snap target based on velocity
    int targetPage;

    if (velocity.abs() < _velocityThreshold) {
      // Weak swipe: snap to nearest day boundary
      // If more than 50% into next day, snap forward; otherwise snap back
      targetPage = fractionOfDay > 0.5 ? currentPage + 1 : currentPage;
    } else {
      // Strong swipe: snap in direction of velocity
      // In Flutter horizontal scroll:
      // - Dragging LEFT = position INCREASES = velocity POSITIVE = show FUTURE days
      // - Dragging RIGHT = position DECREASES = velocity NEGATIVE = show PAST days
      if (velocity > 0) {
        // User dragged LEFT: show future days (higher offset)
        targetPage = currentPage + 1;
      } else {
        // User dragged RIGHT: show past days (lower offset)
        targetPage = currentPage;
      }
    }

    // Calculate target offset and clamp to valid range
    final double targetOffset = targetPage * dayWidth;
    final double clampedTarget = targetOffset.clamp(minExtent, maxExtent);

    // If already at target (within tolerance), no animation needed
    if ((currentOffset - clampedTarget).abs() < 0.5) {
      return null;
    }

    // Return critically damped spring simulation
    // SpringDescription.withDampingRatio defaults to ratio=1.0 (critically damped)
    // This ensures no oscillation/bounce - smooth stop at target
    return ScrollSpringSimulation(
      SpringDescription.withDampingRatio(mass: 0.5, stiffness: 100.0),
      currentOffset,
      clampedTarget,
      velocity,
    );
  }
}
