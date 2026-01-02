import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../services/logging_service.dart';

/// Performance tracker for measuring operation durations
///
/// Uses Flutter's Timeline API for DevTools integration
class PerformanceTracker {
  /// Start a named performance trace
  static void startTrace(String name) {
    developer.Timeline.startSync(name);
  }

  /// End the current performance trace
  static void endTrace() {
    developer.Timeline.finishSync();
  }

  /// Track a synchronous operation
  static T track<T>(String name, T Function() operation) {
    developer.Timeline.startSync(name);
    try {
      return operation();
    } finally {
      developer.Timeline.finishSync();
    }
  }

  /// Track an asynchronous operation
  static Future<T> trackAsync<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    developer.Timeline.startSync(name);
    try {
      final result = await operation();
      return result;
    } finally {
      developer.Timeline.finishSync();
    }
  }

  /// Measure duration of a synchronous operation
  static T measure<T>(String name, T Function() operation) {
    final stopwatch = Stopwatch()..start();
    try {
      return operation();
    } finally {
      stopwatch.stop();
      PerformanceLogger.logMetric(name, stopwatch.elapsedMilliseconds);
    }
  }

  /// Measure duration of an asynchronous operation
  static Future<T> measureAsync<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      return result;
    } finally {
      stopwatch.stop();
      PerformanceLogger.logMetric(name, stopwatch.elapsedMilliseconds);
    }
  }
}

/// Performance logger for collecting and analyzing metrics
class PerformanceLogger {
  static final Map<String, List<int>> _metrics = {};
  static final Map<String, int> _counts = {};

  /// Log a performance metric
  static void logMetric(String name, int durationMs) {
    _metrics[name] ??= [];
    _metrics[name]!.add(durationMs);

    _counts[name] = (_counts[name] ?? 0) + 1;

    // Log in debug mode
    if (kDebugMode) {
      LoggingService.logPerformance(name, Duration(milliseconds: durationMs));
    }
  }

  /// Get average duration for a metric
  static double? getAverage(String name) {
    final metrics = _metrics[name];
    if (metrics == null || metrics.isEmpty) return null;

    return metrics.reduce((a, b) => a + b) / metrics.length;
  }

  /// Get maximum duration for a metric
  static int? getMax(String name) {
    final metrics = _metrics[name];
    if (metrics == null || metrics.isEmpty) return null;

    return metrics.reduce((a, b) => a > b ? a : b);
  }

  /// Get minimum duration for a metric
  static int? getMin(String name) {
    final metrics = _metrics[name];
    if (metrics == null || metrics.isEmpty) return null;

    return metrics.reduce((a, b) => a < b ? a : b);
  }

  /// Get count of measurements for a metric
  static int getCount(String name) {
    return _counts[name] ?? 0;
  }

  /// Log summary of all metrics
  static void logSummary() {
    if (_metrics.isEmpty) {
      LoggingService.logDebug('📊 No performance metrics collected');
      return;
    }

    LoggingService.logDebug('📊 Performance Summary:');
    LoggingService.logDebug('=' * 60);

    _metrics.forEach((name, durations) {
      final avg = getAverage(name);
      final max = getMax(name);
      final min = getMin(name);
      final count = getCount(name);

      LoggingService.logDebug('[$name]');
      LoggingService.logDebug('  Calls: $count');
      LoggingService.logDebug('  Avg: ${avg?.toStringAsFixed(2)}ms');
      LoggingService.logDebug('  Min: ${min}ms');
      LoggingService.logDebug('  Max: ${max}ms');
      LoggingService.logDebug('');
    });

    LoggingService.logDebug('=' * 60);
  }

  /// Clear all metrics
  static void clear() {
    _metrics.clear();
    _counts.clear();
  }

  /// Get all metrics as a map
  static Map<String, PerformanceMetric> getAllMetrics() {
    return _metrics.map((name, durations) {
      return MapEntry(
        name,
        PerformanceMetric(
          name: name,
          count: getCount(name),
          average: getAverage(name) ?? 0,
          min: getMin(name) ?? 0,
          max: getMax(name) ?? 0,
        ),
      );
    });
  }
}

/// Performance metric data
class PerformanceMetric {
  final String name;
  final int count;
  final double average;
  final int min;
  final int max;

  PerformanceMetric({
    required this.name,
    required this.count,
    required this.average,
    required this.min,
    required this.max,
  });

  @override
  String toString() {
    return 'PerformanceMetric($name: $count calls, avg: ${average.toStringAsFixed(2)}ms, min: ${min}ms, max: ${max}ms)';
  }
}

/// Widget that tracks build time
///
/// Wraps a widget and measures how long it takes to build
///
/// Example usage:
/// ```dart
/// BuildTimeTracker(
///   label: 'PropertyListView',
///   child: ListView.builder(
///     itemCount: properties.length,
///     itemBuilder: (context, index) {
///       return PropertyCard(property: properties[index]);
///     },
///   ),
/// )
/// ```
class BuildTimeTracker extends StatefulWidget {
  final Widget child;
  final String label;

  const BuildTimeTracker({
    super.key,
    required this.child,
    required this.label,
  });

  @override
  State<BuildTimeTracker> createState() => _BuildTimeTrackerState();
}

class _BuildTimeTrackerState extends State<BuildTimeTracker> {
  @override
  Widget build(BuildContext context) {
    // Use the developer timeline to track widget build times. This is more
    // efficient than Stopwatch and integrates with Flutter DevTools.
    final task = developer.TimelineTask();
    final startTimestamp = developer.Timeline.now;
    task.start('${widget.label}.build', arguments: {'label': widget.label});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final endTimestamp = developer.Timeline.now;
      // Calculate duration in milliseconds from microseconds.
      final durationMs = (endTimestamp - startTimestamp) ~/ 1000;
      PerformanceLogger.logMetric(
        '${widget.label}.build',
        durationMs,
      );
      task.finish();
    });

    return widget.child;
  }
}

/// Performance observer for app-wide metrics
///
/// Tracks frame rate and other app-level performance metrics
///
/// Register in main.dart:
/// ```dart
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   WidgetsBinding.instance.addObserver(AppPerformanceObserver());
///   runApp(MyApp());
/// }
/// ```
class AppPerformanceObserver extends WidgetsBindingObserver {
  int _frameCount = 0;
  DateTime? _lastLog;
  final Duration logInterval;

  AppPerformanceObserver({
    this.logInterval = const Duration(seconds: 5),
  });

  @override
  void didChangeMetrics() {
    _frameCount++;

    final now = DateTime.now();
    if (_lastLog == null || now.difference(_lastLog!) > logInterval) {
      final seconds = logInterval.inSeconds;
      final fps = _frameCount / seconds;

      if (kDebugMode) {
        LoggingService.logDebug('📊 Average FPS: ${fps.toStringAsFixed(2)}');
      }

      PerformanceLogger.logMetric('app.fps', fps.round());

      _frameCount = 0;
      _lastLog = now;
    }
  }

  @override
  void didHaveMemoryPressure() {
    if (kDebugMode) {
      LoggingService.logWarning('Memory pressure detected');
    }
  }
}

/// Utility to check if app is running in profile mode
bool get isProfileMode => kProfileMode;

/// Utility to check if app is running in release mode
bool get isReleaseMode => kReleaseMode;

/// Utility to check if app is running in debug mode
bool get isDebugMode => kDebugMode;

/// Run code only in profile or release mode (for performance testing)
void runInPerformanceMode(VoidCallback callback) {
  if (kProfileMode || kReleaseMode) {
    callback();
  }
}
