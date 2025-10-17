import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debouncer utility - delays execution until a pause in events
///
/// Useful for search inputs where you want to wait until user stops typing
/// before making an API call.
///
/// Example usage:
/// ```dart
/// final debouncer = Debouncer(duration: Duration(milliseconds: 500));
///
/// TextField(
///   onChanged: (value) {
///     debouncer.run(() {
///       performSearch(value);
///     });
///   },
/// )
/// ```
class Debouncer {
  final Duration duration;
  Timer? _timer;

  Debouncer({
    this.duration = const Duration(milliseconds: 500),
  });

  /// Run the action after debounce duration
  /// Cancels previous timer if called again before duration expires
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancel any pending action
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose the debouncer and cancel any pending actions
  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler utility - limits execution frequency
///
/// Useful for scroll events, filter changes, or any high-frequency events
/// where you want to limit how often an action is executed.
///
/// Example usage:
/// ```dart
/// final throttler = Throttler(duration: Duration(milliseconds: 300));
///
/// NotificationListener<ScrollNotification>(
///   onNotification: (notification) {
///     throttler.run(() {
///       updateScrollPosition(notification.metrics.pixels);
///     });
///     return true;
///   },
/// )
/// ```
class Throttler {
  final Duration duration;
  Timer? _timer;
  bool _isThrottling = false;

  Throttler({
    this.duration = const Duration(milliseconds: 300),
  });

  /// Run the action only if not currently throttling
  /// Subsequent calls within the duration will be ignored
  void run(VoidCallback action) {
    if (_isThrottling) return;

    action();
    _isThrottling = true;

    _timer = Timer(duration, () {
      _isThrottling = false;
    });
  }

  /// Check if currently throttling
  bool get isThrottling => _isThrottling;

  /// Cancel throttling state
  void cancel() {
    _timer?.cancel();
    _isThrottling = false;
  }

  /// Dispose the throttler
  void dispose() {
    _timer?.cancel();
  }
}

/// Async Debouncer for Future operations
///
/// Similar to Debouncer but for async operations.
/// Only the last call will be executed after the debounce duration.
///
/// Example usage:
/// ```dart
/// final debouncer = AsyncDebouncer<List<Property>>(
///   duration: Duration(milliseconds: 500),
/// );
///
/// TextField(
///   onChanged: (value) async {
///     final results = await debouncer.run(() async {
///       return await searchProperties(value);
///     });
///     if (results != null) {
///       setState(() => searchResults = results);
///     }
///   },
/// )
/// ```
class AsyncDebouncer<T> {
  final Duration duration;
  Timer? _timer;
  T? _lastResult;

  AsyncDebouncer({
    this.duration = const Duration(milliseconds: 500),
  });

  /// Run the async action after debounce duration
  /// Returns a Future that completes with the result or null if cancelled
  Future<T?> run(Future<T> Function() action) async {
    _timer?.cancel();

    final completer = Completer<T?>();

    _timer = Timer(duration, () async {
      try {
        final result = await action();
        _lastResult = result;
        completer.complete(result);
      } catch (e) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  /// Get the last result without running the action
  T? get lastResult => _lastResult;

  /// Cancel any pending action
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose the debouncer
  void dispose() {
    _timer?.cancel();
  }
}

/// Debounced value notifier
///
/// A ValueNotifier that debounces changes.
/// Useful for form fields or any input that needs debouncing.
///
/// Example usage:
/// ```dart
/// final searchQuery = DebouncedValueNotifier<String>(
///   initialValue: '',
///   duration: Duration(milliseconds: 500),
/// );
///
/// // Listen to debounced changes
/// searchQuery.addListener(() {
///   performSearch(searchQuery.value);
/// });
///
/// // Update value (will be debounced)
/// searchQuery.setValue('query');
/// ```
class DebouncedValueNotifier<T> extends ValueNotifier<T> {
  final Duration duration;
  Timer? _timer;

  DebouncedValueNotifier({
    required T initialValue,
    this.duration = const Duration(milliseconds: 500),
  }) : super(initialValue);

  /// Set value with debouncing
  void setValue(T newValue) {
    _timer?.cancel();
    _timer = Timer(duration, () {
      value = newValue;
    });
  }

  /// Set value immediately without debouncing
  void setValueImmediate(T newValue) {
    _timer?.cancel();
    value = newValue;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
