import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'logging_service.dart';

/// Performance optimization service.
///
/// Provides caching, memoization, and performance monitoring.
///
/// Usage:
/// ```dart
/// final service = PerformanceOptimizationService.instance;
///
/// // Memoize expensive computation
/// final result = service.memoize('key', () => expensiveOperation());
///
/// // Track API call performance
/// await fetchData().measureTime<Data>('fetchData');
///
/// // Get performance report
/// service.logPerformanceReport();
/// ```
class PerformanceOptimizationService {
  PerformanceOptimizationService._();
  static final instance = PerformanceOptimizationService._();

  // Memoization cache
  final _memoCache = <String, _CacheEntry>{};
  final _maxCacheSize = 100;
  final _cacheDuration = const Duration(minutes: 5);

  // Performance metrics
  final _buildTimes = <String, List<int>>{};
  final _apiCallTimes = <String, List<int>>{};

  /// Memoize expensive computations
  /// Cache results for repeated calls with same parameters
  T memoize<T>(String key, T Function() computation) {
    final now = DateTime.now();

    // Check if cached and not expired
    if (_memoCache.containsKey(key)) {
      final entry = _memoCache[key]!;
      if (now.difference(entry.timestamp) < _cacheDuration) {
        return entry.value as T;
      }
    }

    // Compute and cache
    final result = computation();
    _memoCache[key] = _CacheEntry(result, now);

    // Cleanup old entries if cache is too large
    if (_memoCache.length > _maxCacheSize) {
      _cleanupCache();
    }

    return result;
  }

  /// Memoize async computations
  Future<T> memoizeAsync<T>(
    String key,
    Future<T> Function() computation,
  ) async {
    final now = DateTime.now();

    // Check if cached and not expired
    if (_memoCache.containsKey(key)) {
      final entry = _memoCache[key]!;
      if (now.difference(entry.timestamp) < _cacheDuration) {
        return entry.value as T;
      }
    }

    // Compute and cache
    final result = await computation();
    _memoCache[key] = _CacheEntry(result, now);

    // Cleanup old entries if cache is too large
    if (_memoCache.length > _maxCacheSize) {
      _cleanupCache();
    }

    return result;
  }

  /// Clear memoization cache
  void clearCache({String? key}) {
    if (key != null) {
      _memoCache.remove(key);
    } else {
      _memoCache.clear();
    }
  }

  /// Cleanup old cache entries
  void _cleanupCache() {
    final now = DateTime.now();
    final toRemove = <String>[];

    for (final entry in _memoCache.entries) {
      if (now.difference(entry.value.timestamp) > _cacheDuration) {
        toRemove.add(entry.key);
      }
    }

    toRemove.forEach(_memoCache.remove);

    // If still too large, remove oldest entries
    if (_memoCache.length > _maxCacheSize) {
      final sortedEntries = _memoCache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

      final removeCount = _memoCache.length - _maxCacheSize;
      for (var i = 0; i < removeCount; i++) {
        _memoCache.remove(sortedEntries[i].key);
      }
    }
  }

  /// Track build time for performance monitoring
  void trackBuildTime(String widgetName, int microseconds) {
    if (!_buildTimes.containsKey(widgetName)) {
      _buildTimes[widgetName] = [];
    }
    _buildTimes[widgetName]!.add(microseconds);

    // Keep only last 100 measurements
    if (_buildTimes[widgetName]!.length > 100) {
      _buildTimes[widgetName]!.removeAt(0);
    }
  }

  /// Track API call time
  void trackApiCallTime(String endpoint, int microseconds) {
    if (!_apiCallTimes.containsKey(endpoint)) {
      _apiCallTimes[endpoint] = [];
    }
    _apiCallTimes[endpoint]!.add(microseconds);

    // Keep only last 100 measurements
    if (_apiCallTimes[endpoint]!.length > 100) {
      _apiCallTimes[endpoint]!.removeAt(0);
    }
  }

  /// Get average build time for a widget
  double? getAverageBuildTime(String widgetName) {
    if (!_buildTimes.containsKey(widgetName)) return null;
    final times = _buildTimes[widgetName]!;
    if (times.isEmpty) return null;
    return times.reduce((a, b) => a + b) / times.length / 1000; // Convert to ms
  }

  /// Get average API call time
  double? getAverageApiCallTime(String endpoint) {
    if (!_apiCallTimes.containsKey(endpoint)) return null;
    final times = _apiCallTimes[endpoint]!;
    if (times.isEmpty) return null;
    return times.reduce((a, b) => a + b) / times.length / 1000; // Convert to ms
  }

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    return {
      'cache_size': _memoCache.length,
      'widgets_tracked': _buildTimes.length,
      'api_endpoints_tracked': _apiCallTimes.length,
      'average_build_times': _buildTimes.map((key, value) {
        final avg = value.reduce((a, b) => a + b) / value.length / 1000;
        return MapEntry(key, '${avg.toStringAsFixed(2)}ms');
      }),
      'average_api_times': _apiCallTimes.map((key, value) {
        final avg = value.reduce((a, b) => a + b) / value.length / 1000;
        return MapEntry(key, '${avg.toStringAsFixed(2)}ms');
      }),
    };
  }

  /// Log performance report (debug mode only)
  void logPerformanceReport() {
    if (kDebugMode) {
      final report = getPerformanceReport();
      LoggingService.logDebug('=== Performance Report ===');
      LoggingService.logDebug('Cache size: ${report['cache_size']}');
      LoggingService.logDebug('Widgets tracked: ${report['widgets_tracked']}');
      LoggingService.logDebug('API endpoints tracked: ${report['api_endpoints_tracked']}');

      LoggingService.logDebug('\nAverage Build Times:');
      final buildTimes = report['average_build_times'] as Map;
      buildTimes.forEach((key, value) {
        LoggingService.logDebug('  $key: $value');
      });

      LoggingService.logDebug('\nAverage API Call Times:');
      final apiTimes = report['average_api_times'] as Map;
      apiTimes.forEach((key, value) {
        LoggingService.logDebug('  $key: $value');
      });

      LoggingService.logDebug('=========================');
    }
  }

  /// Debounce function execution
  Timer? _debounceTimer;
  void debounce(Duration duration, VoidCallback action) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, action);
  }

  /// Throttle function execution
  DateTime? _lastThrottleTime;
  void throttle(Duration duration, VoidCallback action) {
    final now = DateTime.now();
    if (_lastThrottleTime == null ||
        now.difference(_lastThrottleTime!) > duration) {
      _lastThrottleTime = now;
      action();
    }
  }

  /// Dispose resources
  void dispose() {
    _memoCache.clear();
    _buildTimes.clear();
    _apiCallTimes.clear();
    _debounceTimer?.cancel();
  }
}

/// Cache entry with timestamp
class _CacheEntry {
  final dynamic value;
  final DateTime timestamp;

  _CacheEntry(this.value, this.timestamp);
}

/// Extension for widget build time tracking
extension WidgetPerformanceTracking on Widget {
  /// Measure build time
  T measureBuildTime<T>(String widgetName, T Function() builder) {
    final stopwatch = Stopwatch()..start();
    final result = builder();
    stopwatch.stop();

    PerformanceOptimizationService.instance.trackBuildTime(
      widgetName,
      stopwatch.elapsedMicroseconds,
    );

    return result;
  }
}

/// Extension for async performance tracking
extension AsyncPerformanceTracking on Future {
  /// Measure async operation time
  Future<T> measureTime<T>(String operationName) async {
    final stopwatch = Stopwatch()..start();
    final result = await this;
    stopwatch.stop();

    PerformanceOptimizationService.instance.trackApiCallTime(
      operationName,
      stopwatch.elapsedMicroseconds,
    );

    return result as T;
  }
}
