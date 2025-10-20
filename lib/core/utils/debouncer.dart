import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debouncer utility for delaying function execution
///
/// Usage:
/// ```dart
/// final debouncer = Debouncer(delay: Duration(milliseconds: 500));
///
/// debouncer.run(() {
///   // This will only execute after 500ms of no new calls
///   performSearch(query);
/// });
/// ```
class Debouncer {
  Debouncer({
    required this.delay,
  });

  final Duration delay;
  Timer? _timer;

  /// Run the action after the delay
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel any pending action
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose the debouncer
  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler utility for limiting function execution frequency
///
/// Usage:
/// ```dart
/// final throttler = Throttler(duration: Duration(milliseconds: 300));
///
/// throttler.run(() {
///   // This will execute at most once per 300ms
///   updateUI();
/// });
/// ```
class Throttler {
  Throttler({
    required this.duration,
  });

  final Duration duration;
  Timer? _timer;
  bool _isReady = true;

  /// Run the action if throttle is ready
  void run(VoidCallback action) {
    if (_isReady) {
      _isReady = false;
      action();
      _timer = Timer(duration, () {
        _isReady = true;
      });
    }
  }

  /// Cancel any pending timer
  void cancel() {
    _timer?.cancel();
    _isReady = true;
  }

  /// Dispose the throttler
  void dispose() {
    _timer?.cancel();
  }
}
