import 'package:flutter/material.dart';

/// Scroll direction enum for tracking user scroll behavior
enum ScrollDirection {
  up,
  down,
  idle,
}

/// Utility class for tracking scroll direction and triggering load events
///
/// Features:
/// - Detects scroll direction with debouncing
/// - Triggers load more at configurable thresholds
/// - Supports bidirectional loading (up and down)
class ScrollDirectionTracker {
  double _lastPixels = 0.0;
  ScrollDirection _currentDirection = ScrollDirection.idle;
  DateTime _lastDirectionChange = DateTime.now();
  DateTime _lastLoadTrigger = DateTime.now();

  /// Minimum pixels to detect direction change
  static const double directionThreshold = 10.0;

  /// Debounce duration for direction changes
  static const Duration debounceDuration = Duration(milliseconds: 100);

  /// Minimum time between load triggers to prevent spam
  static const Duration loadCooldown = Duration(milliseconds: 300);

  /// Current detected scroll direction
  ScrollDirection get currentDirection => _currentDirection;

  /// Update tracker with current scroll position
  void update(ScrollController controller) {
    if (!controller.hasClients) return;

    final currentPixels = controller.offset;
    final delta = currentPixels - _lastPixels;

    // Detect direction change
    if (delta.abs() > directionThreshold) {
      final newDirection = delta > 0 ? ScrollDirection.down : ScrollDirection.up;

      if (newDirection != _currentDirection) {
        final now = DateTime.now();
        if (now.difference(_lastDirectionChange) > debounceDuration) {
          _currentDirection = newDirection;
          _lastDirectionChange = now;
        }
      }
    }

    _lastPixels = currentPixels;
  }

  /// Check if we should load more items in the given direction
  ///
  /// [topThreshold] - Load more when scroll position is within this % from top (0.0 - 1.0)
  /// [bottomThreshold] - Load more when scroll position exceeds this % (0.0 - 1.0)
  bool shouldLoadMore(
    ScrollController controller,
    ScrollDirection direction, {
    double topThreshold = 0.2,
    double bottomThreshold = 0.8,
  }) {
    if (!controller.hasClients) return false;

    // Don't trigger if direction doesn't match
    if (_currentDirection != direction && _currentDirection != ScrollDirection.idle) {
      return false;
    }

    // Respect cooldown
    final now = DateTime.now();
    if (now.difference(_lastLoadTrigger) < loadCooldown) {
      return false;
    }

    final position = controller.position;

    // Handle edge case: no scrollable content
    if (position.maxScrollExtent <= 0) return false;

    final scrollPercentage = position.pixels / position.maxScrollExtent;

    bool shouldLoad = false;

    if (direction == ScrollDirection.down) {
      shouldLoad = scrollPercentage >= bottomThreshold;
    } else if (direction == ScrollDirection.up) {
      // For scrolling up, check if we're near the top
      shouldLoad = scrollPercentage <= topThreshold && position.pixels > 0;
    }

    if (shouldLoad) {
      _lastLoadTrigger = now;
    }

    return shouldLoad;
  }

  /// Get current scroll percentage (0.0 - 1.0)
  double getScrollPercentage(ScrollController controller) {
    if (!controller.hasClients) return 0.0;
    final position = controller.position;
    if (position.maxScrollExtent <= 0) return 0.0;
    return (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0);
  }

  /// Check if scroll is near the top
  bool isNearTop(ScrollController controller, {double threshold = 0.1}) {
    return getScrollPercentage(controller) <= threshold;
  }

  /// Check if scroll is near the bottom
  bool isNearBottom(ScrollController controller, {double threshold = 0.9}) {
    return getScrollPercentage(controller) >= threshold;
  }

  /// Reset tracker state
  void reset() {
    _lastPixels = 0.0;
    _currentDirection = ScrollDirection.idle;
    _lastDirectionChange = DateTime.now();
    _lastLoadTrigger = DateTime.now();
  }

  /// Get debug info
  Map<String, dynamic> getDebugInfo(ScrollController controller) {
    if (!controller.hasClients) {
      return {
        'direction': _currentDirection.name,
        'pixels': 0.0,
        'maxExtent': 0.0,
        'percentage': 0.0,
      };
    }

    final position = controller.position;
    return {
      'direction': _currentDirection.name,
      'pixels': position.pixels,
      'maxExtent': position.maxScrollExtent,
      'percentage': getScrollPercentage(controller),
    };
  }
}
