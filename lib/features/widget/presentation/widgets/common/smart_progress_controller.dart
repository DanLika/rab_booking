import 'dart:async';
import 'package:flutter/foundation.dart';

/// Controller for "smart" progress animation that adapts to actual loading time.
///
/// The progress bar quickly advances to ~85%, then slows down and waits
/// for the actual loading to complete. When [complete] is called,
/// it quickly finishes to 100%.
///
/// This pattern is used by YouTube, GitHub, and many modern apps to give
/// users visual feedback without knowing the actual loading duration.
///
/// Usage:
/// ```dart
/// final controller = SmartProgressController();
/// controller.start();
///
/// // Listen to progress updates
/// controller.addListener(() {
///   setState(() {});
/// });
///
/// // When loading is actually done:
/// await controller.complete();
///
/// // Dispose when done
/// controller.dispose();
/// ```
class SmartProgressController extends ChangeNotifier {
  /// Current progress value (0.0 to 1.0)
  double _progress = 0.0;
  double get progress => _progress;

  /// Whether the controller has been completed
  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;

  /// Whether the controller is currently running
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Timer for progress animation
  Timer? _timer;

  /// Completer for waiting until animation finishes
  Completer<void>? _completer;

  /// Configuration: Target progress before waiting (default 85%)
  final double targetBeforeComplete;

  /// Configuration: How fast to reach target (milliseconds per tick)
  final int tickInterval;

  /// Configuration: How long to animate to 100% after complete (milliseconds)
  final int completeAnimationDuration;

  SmartProgressController({
    this.targetBeforeComplete = 0.85,
    this.tickInterval = 50,
    this.completeAnimationDuration = 300,
  });

  /// Start the progress animation.
  /// Progress will quickly advance to [targetBeforeComplete], then slow down.
  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _isCompleted = false;
    _progress = 0.0;
    _completer = Completer<void>();

    // Use asymptotic progress: fast at first, slows down as it approaches target
    _timer = Timer.periodic(Duration(milliseconds: tickInterval), (timer) {
      if (_isCompleted) {
        timer.cancel();
        return;
      }

      // Asymptotic formula: each tick adds a fraction of remaining distance
      // This creates natural "fast start, slow finish" effect
      final remaining = targetBeforeComplete - _progress;

      if (remaining > 0.01) {
        // Add 8% of remaining distance each tick (creates exponential decay)
        _progress += remaining * 0.08;
        notifyListeners();
      } else {
        // Very close to target - slow trickle (1% per second)
        // This keeps the bar moving slightly so user knows it's not frozen
        if (_progress < 0.95) {
          _progress += 0.001;
          notifyListeners();
        }
      }
    });
  }

  /// Signal that actual loading is complete.
  /// The progress will quickly animate to 100%.
  ///
  /// Returns a Future that completes when the animation is done.
  Future<void> complete() async {
    if (_isCompleted) return;

    _isCompleted = true;
    _timer?.cancel();

    // Animate from current progress to 100%
    final startProgress = _progress;
    final progressToAdd = 1.0 - startProgress;
    const steps = 10;
    final stepDuration = completeAnimationDuration ~/ steps;

    for (var i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: stepDuration));
      // Ease-out animation (fast start, slow end)
      final t = i / steps;
      final easeOut = 1 - (1 - t) * (1 - t); // Quadratic ease-out
      _progress = startProgress + (progressToAdd * easeOut);
      notifyListeners();
    }

    // Ensure we're exactly at 100%
    _progress = 1.0;
    notifyListeners();

    _isRunning = false;
    _completer?.complete();
  }

  /// Reset the controller to initial state.
  void reset() {
    _timer?.cancel();
    _progress = 0.0;
    _isCompleted = false;
    _isRunning = false;
    notifyListeners();
  }

  /// Wait for the completion animation to finish.
  /// Useful if you want to delay hiding the loading screen
  /// until the 100% animation is visible.
  Future<void> get onComplete => _completer?.future ?? Future.value();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
