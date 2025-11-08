import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/logging_service.dart';

/// Performance utilities for optimization
class PerformanceUtils {
  PerformanceUtils._();

  /// Debounce a function call by [duration]
  /// Useful for search inputs, preventing excessive API calls
  static Timer? _debounceTimer;

  static void debounce({
    required VoidCallback onExecute,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, onExecute);
  }

  /// Throttle a function call - executes at most once per [duration]
  /// Useful for scroll listeners, window resize events
  static DateTime? _lastThrottleTime;

  static void throttle({
    required VoidCallback onExecute,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    final now = DateTime.now();
    if (_lastThrottleTime == null ||
        now.difference(_lastThrottleTime!) >= duration) {
      _lastThrottleTime = now;
      onExecute();
    }
  }

  /// Memoize expensive computations
  /// Cache results based on input parameters
  static final Map<String, dynamic> _memoCache = {};

  static T memoize<T>(String key, T Function() computation) {
    if (_memoCache.containsKey(key)) {
      return _memoCache[key] as T;
    }

    final result = computation();
    _memoCache[key] = result;
    return result;
  }

  /// Clear memoization cache
  static void clearMemoCache() {
    _memoCache.clear();
  }

  /// Measure widget build time (debug mode only)
  static Future<Duration> measureBuildTime(
    WidgetBuilder builder,
    BuildContext context,
  ) async {
    if (!kDebugMode) return Duration.zero;

    final stopwatch = Stopwatch()..start();
    builder(context);
    stopwatch.stop();

    return stopwatch.elapsed;
  }

  /// Log slow frames (60 FPS = 16.67ms per frame)
  static void logSlowFrame(Duration frameDuration) {
    if (!kDebugMode) return;

    const targetFrameTime = Duration(milliseconds: 16);
    if (frameDuration > targetFrameTime) {
      LoggingService.logWarning(
        'Slow frame detected: ${frameDuration.inMilliseconds}ms (target: ${targetFrameTime.inMilliseconds}ms)',
      );
    }
  }

  /// Pre-cache images for faster loading
  static Future<void> precacheImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    for (final url in imageUrls) {
      try {
        await precacheImage(NetworkImage(url), context);
      } catch (e) {
        LoggingService.logDebug('Failed to precache image: $url - $e');
      }
    }
  }

  /// Check if device is low-end (for adaptive performance)
  static bool get isLowEndDevice {
    // This is a simplified check - in production, use device_info_plus
    // to detect specific device capabilities
    return kIsWeb ? false : Platform.isAndroid;
  }

  /// Batch updates to reduce rebuilds
  static Future<void> batchUpdate(List<VoidCallback> updates) async {
    for (final update in updates) {
      update();
    }
    await Future.delayed(Duration.zero); // Force rebuild after all updates
  }
}

/// Debounced TextEditingController
/// Automatically debounces text changes
class DebouncedTextEditingController extends TextEditingController {
  DebouncedTextEditingController({
    super.text,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  final Duration debounceDuration;
  Timer? _debounceTimer;
  final _debouncedController = StreamController<String>.broadcast();

  /// Stream of debounced text changes
  Stream<String> get debouncedStream => _debouncedController.stream;

  @override
  set text(String newText) {
    super.text = newText;
    _onTextChanged(newText);
  }

  @override
  set value(TextEditingValue newValue) {
    super.value = newValue;
    _onTextChanged(newValue.text);
  }

  void _onTextChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      if (!_debouncedController.isClosed) {
        _debouncedController.add(text);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _debouncedController.close();
    super.dispose();
  }
}

/// Optimized ListViewBuilder with viewport-based rendering
class OptimizedListView extends StatelessWidget {
  const OptimizedListView({
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    super.key,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      // Use addAutomaticKeepAlives for better performance
      addAutomaticKeepAlives: true,
      // Cache extent to pre-render items slightly off-screen
      cacheExtent: 100,
      itemBuilder: (context, index) {
        // Wrap in RepaintBoundary to prevent unnecessary repaints
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

/// Platform import shim for web compatibility
class Platform {
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isWeb => kIsWeb;
}
