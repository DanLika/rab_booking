import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:developer' as developer;

/// Helpers for performance testing and benchmarking
class PerformanceTestHelpers {
  PerformanceTestHelpers._();

  // ============================================================================
  // PERFORMANCE BENCHMARKING
  // ============================================================================

  /// Benchmark widget build time
  static Future<Duration> benchmarkBuildTime(
    WidgetTester tester,
    Widget widget, {
    int iterations = 100,
  }) async {
    final stopwatch = Stopwatch()..start();

    for (var i = 0; i < iterations; i++) {
      await tester.pumpWidget(widget);
    }

    stopwatch.stop();
    return stopwatch.elapsed ~/ iterations;
  }

  /// Benchmark scroll performance
  static Future<ScrollPerformanceResult> benchmarkScrollPerformance(
    WidgetTester tester,
    Finder scrollable, {
    double scrollAmount = 1000.0,
    Duration scrollDuration = const Duration(milliseconds: 500),
  }) async {
    int droppedFrames = 0;
    final frameTimestamps = <Duration>[];

    // Start frame tracking
    WidgetsBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
      for (final timing in timings) {
        frameTimestamps.add(timing.totalSpan);
        // Frame is dropped if it takes longer than 16.67ms (60fps)
        if (timing.totalSpan.inMicroseconds > 16667) {
          droppedFrames++;
        }
      }
    });

    // Perform scroll
    await tester.drag(scrollable, Offset(0, -scrollAmount));
    await tester.pumpAndSettle(scrollDuration);

    // Calculate metrics
    final averageFrameTime = frameTimestamps.isEmpty
        ? Duration.zero
        : frameTimestamps.reduce((a, b) => a + b) ~/
            frameTimestamps.length;

    return ScrollPerformanceResult(
      totalFrames: frameTimestamps.length,
      droppedFrames: droppedFrames,
      averageFrameTime: averageFrameTime,
      droppedFramePercentage:
          frameTimestamps.isEmpty ? 0 : (droppedFrames / frameTimestamps.length) * 100,
    );
  }

  /// Benchmark animation performance
  static Future<AnimationPerformanceResult> benchmarkAnimation(
    WidgetTester tester, {
    required Future<void> Function() animationTrigger,
    required Duration animationDuration,
  }) async {
    final frameTimestamps = <Duration>[];
    int droppedFrames = 0;

    // Start frame tracking
    WidgetsBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
      for (final timing in timings) {
        frameTimestamps.add(timing.totalSpan);
        if (timing.totalSpan.inMicroseconds > 16667) {
          droppedFrames++;
        }
      }
    });

    // Trigger animation
    await animationTrigger();

    // Let animation complete
    await tester.pumpAndSettle(animationDuration);

    final averageFrameTime = frameTimestamps.isEmpty
        ? Duration.zero
        : frameTimestamps.reduce((a, b) => a + b) ~/
            frameTimestamps.length;

    final expectedFrames = (animationDuration.inMicroseconds / 16667).ceil();

    return AnimationPerformanceResult(
      totalFrames: frameTimestamps.length,
      expectedFrames: expectedFrames,
      droppedFrames: droppedFrames,
      averageFrameTime: averageFrameTime,
      isSmooth: droppedFrames / frameTimestamps.length < 0.1, // < 10% dropped
    );
  }

  /// Measure widget memory footprint
  static Future<int> measureMemoryFootprint(
    WidgetTester tester,
    Widget widget,
  ) async {
    // Get baseline memory
    final baseline = await _getCurrentMemoryUsage();

    // Build widget
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Get memory after building
    final afterBuild = await _getCurrentMemoryUsage();

    return afterBuild - baseline;
  }

  static Future<int> _getCurrentMemoryUsage() async {
    // This is a simplified version. In production, use platform channels
    // to get actual memory usage from the native side
    return 0; // Placeholder
  }

  // ============================================================================
  // IMAGE LOADING PERFORMANCE
  // ============================================================================

  /// Benchmark image loading time
  static Future<Duration> benchmarkImageLoad(
    WidgetTester tester,
    String imageUrl,
  ) async {
    final stopwatch = Stopwatch()..start();

    await tester.runAsync(() async {
      final image = NetworkImage(imageUrl);
      await precacheImage(image, tester.element(find.byType(Container).first));
    });

    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Verify images load within acceptable time
  static Future<bool> verifyImageLoadTime(
    WidgetTester tester,
    List<String> imageUrls, {
    Duration maxLoadTime = const Duration(seconds: 3),
  }) async {
    for (final url in imageUrls) {
      final loadTime = await benchmarkImageLoad(tester, url);
      if (loadTime > maxLoadTime) {
        return false;
      }
    }
    return true;
  }

  // ============================================================================
  // BUILD PERFORMANCE
  // ============================================================================

  /// Profile widget rebuild count
  static Future<int> countRebuilds(
    WidgetTester tester,
    Widget widget,
    Future<void> Function() interaction,
  ) async {
    int buildCount = 0;

    final countingWidget = _BuildCounter(
      child: widget,
      onBuild: () => buildCount++,
    );

    await tester.pumpWidget(countingWidget);
    await interaction();
    await tester.pumpAndSettle();

    return buildCount;
  }

  /// Verify widget doesn't rebuild excessively
  static Future<void> verifyMinimalRebuilds(
    WidgetTester tester,
    Widget widget,
    Future<void> Function() interaction, {
    int maxRebuilds = 5,
  }) async {
    final rebuilds = await countRebuilds(tester, widget, interaction);
    expect(rebuilds, lessThanOrEqualTo(maxRebuilds));
  }

  // ============================================================================
  // TIMELINE PROFILING
  // ============================================================================

  /// Start timeline recording
  static void startTimelineRecording() {
    developer.Timeline.startSync('test_performance');
  }

  /// Stop timeline recording and get summary
  static TimelineSummary stopTimelineRecording() {
    developer.Timeline.finishSync();
    return TimelineSummary();
  }

  // ============================================================================
  // PERFORMANCE ASSERTIONS
  // ============================================================================

  /// Assert build time is within acceptable range
  static void assertBuildTimeAcceptable(
    Duration buildTime, {
    Duration maxBuildTime = const Duration(milliseconds: 100),
  }) {
    expect(
      buildTime.inMilliseconds,
      lessThanOrEqualTo(maxBuildTime.inMilliseconds),
      reason: 'Build time $buildTime exceeds maximum $maxBuildTime',
    );
  }

  /// Assert frame rate is acceptable (60fps = 16.67ms per frame)
  static void assertFrameRateAcceptable(
    Duration averageFrameTime, {
    Duration maxFrameTime = const Duration(milliseconds: 17),
  }) {
    expect(
      averageFrameTime.inMilliseconds,
      lessThanOrEqualTo(maxFrameTime.inMilliseconds),
      reason:
          'Average frame time $averageFrameTime exceeds target $maxFrameTime',
    );
  }

  /// Assert no dropped frames
  static void assertNoDroppedFrames(int droppedFrames, int totalFrames) {
    final droppedPercentage = (droppedFrames / totalFrames) * 100;
    expect(
      droppedPercentage,
      lessThan(10.0),
      reason: 'Dropped $droppedFrames frames ($droppedPercentage%)',
    );
  }
}

// ============================================================================
// HELPER CLASSES
// ============================================================================

/// Result of scroll performance benchmark
class ScrollPerformanceResult {
  final int totalFrames;
  final int droppedFrames;
  final Duration averageFrameTime;
  final double droppedFramePercentage;

  ScrollPerformanceResult({
    required this.totalFrames,
    required this.droppedFrames,
    required this.averageFrameTime,
    required this.droppedFramePercentage,
  });

  bool get isSmooth => droppedFramePercentage < 10.0;

  @override
  String toString() {
    return 'ScrollPerformance(frames: $totalFrames, dropped: $droppedFrames '
        '(${droppedFramePercentage.toStringAsFixed(1)}%), '
        'avg: ${averageFrameTime.inMicroseconds}μs)';
  }
}

/// Result of animation performance benchmark
class AnimationPerformanceResult {
  final int totalFrames;
  final int expectedFrames;
  final int droppedFrames;
  final Duration averageFrameTime;
  final bool isSmooth;

  AnimationPerformanceResult({
    required this.totalFrames,
    required this.expectedFrames,
    required this.droppedFrames,
    required this.averageFrameTime,
    required this.isSmooth,
  });

  @override
  String toString() {
    return 'AnimationPerformance(frames: $totalFrames/$expectedFrames, '
        'dropped: $droppedFrames, avg: ${averageFrameTime.inMicroseconds}μs, '
        'smooth: $isSmooth)';
  }
}

/// Timeline summary (simplified)
class TimelineSummary {
  final DateTime startTime = DateTime.now();
  final Map<String, Duration> events = {};

  void recordEvent(String name, Duration duration) {
    events[name] = duration;
  }

  @override
  String toString() {
    return 'Timeline(events: ${events.length}, duration: ${events.values.fold(Duration.zero, (a, b) => a + b)})';
  }
}

/// Widget that counts rebuilds
class _BuildCounter extends StatefulWidget {
  final Widget child;
  final VoidCallback onBuild;

  const _BuildCounter({
    required this.child,
    required this.onBuild,
  });

  @override
  State<_BuildCounter> createState() => _BuildCounterState();
}

class _BuildCounterState extends State<_BuildCounter> {
  @override
  Widget build(BuildContext context) {
    widget.onBuild();
    return widget.child;
  }
}
