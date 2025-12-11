import 'dart:async';
import 'package:flutter/material.dart';
import 'owner_app_loader.dart';

/// Smart progress controller for splash screen animation.
///
/// Progress quickly advances to ~85%, then slows down and waits
/// for actual loading to complete. When [complete] is called,
/// it quickly finishes to 100%.
class _SplashProgressController extends ChangeNotifier {
  double _progress = 0.0;
  double get progress => _progress;

  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;

  bool _isRunning = false;
  Timer? _timer;
  Completer<void>? _completer;

  // Configuration constants
  static const double _targetBeforeComplete = 0.85;
  static const int _tickInterval = 50;
  static const int _completeAnimationDuration = 300;

  _SplashProgressController();

  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _isCompleted = false;
    _progress = 0.0;
    _completer = Completer<void>();

    _timer = Timer.periodic(const Duration(milliseconds: _tickInterval), (timer) {
      if (_isCompleted) {
        timer.cancel();
        return;
      }

      final remaining = _targetBeforeComplete - _progress;

      if (remaining > 0.01) {
        _progress += remaining * 0.08;
        notifyListeners();
      } else {
        if (_progress < 0.95) {
          _progress += 0.001;
          notifyListeners();
        }
      }
    });
  }

  Future<void> complete() async {
    if (_isCompleted) return;

    _isCompleted = true;
    _timer?.cancel();

    final startProgress = _progress;
    final progressToAdd = 1.0 - startProgress;
    const steps = 10;
    final stepDuration = _completeAnimationDuration ~/ steps;

    for (var i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: stepDuration));
      final t = i / steps;
      final easeOut = 1 - (1 - t) * (1 - t);
      _progress = startProgress + (progressToAdd * easeOut);
      notifyListeners();
    }

    _progress = 1.0;
    notifyListeners();

    _isRunning = false;
    _completer?.complete();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Splash screen for owner dashboard app initialization.
///
/// Shows BookBed logo with smart progress animation that:
/// 1. Quickly advances to ~85%
/// 2. Slows down and waits for actual initialization
/// 3. Completes to 100% when [initializationFuture] resolves
///
/// Usage:
/// ```dart
/// OwnerSplashScreen(
///   initializationFuture: _initializeApp(),
///   onComplete: () {
///     setState(() => _isInitialized = true);
///   },
///   child: MyApp(),
/// )
/// ```
class OwnerSplashScreen extends StatefulWidget {
  /// The future representing the actual initialization.
  /// When this completes, the progress bar animates to 100%.
  final Future<void>? initializationFuture;

  /// Callback when initialization AND progress animation are both complete.
  final VoidCallback? onComplete;

  /// Minimum display time in milliseconds (ensures loader is visible)
  final int minimumDisplayTime;

  /// The child widget to show after initialization
  final Widget? child;

  const OwnerSplashScreen({
    super.key,
    this.initializationFuture,
    this.onComplete,
    this.minimumDisplayTime = 800,
    this.child,
  });

  @override
  State<OwnerSplashScreen> createState() => _OwnerSplashScreenState();
}

class _OwnerSplashScreenState extends State<OwnerSplashScreen> {
  late final _SplashProgressController _progressController;
  bool _loadingDone = false;
  bool _minTimePassed = false;
  bool _showChild = false;

  @override
  void initState() {
    super.initState();
    _progressController = _SplashProgressController();
    _progressController.addListener(_onProgressChanged);

    // Start progress animation
    _progressController.start();

    // Track minimum display time
    Future.delayed(Duration(milliseconds: widget.minimumDisplayTime), () {
      if (mounted) {
        _minTimePassed = true;
        _checkComplete();
      }
    });

    // Wait for actual initialization to complete
    widget.initializationFuture
        ?.then((_) {
          if (mounted) {
            _loadingDone = true;
            _finishProgress();
          }
        })
        .catchError((e) {
          // Even on error, complete the progress
          if (mounted) {
            _loadingDone = true;
            _finishProgress();
          }
        });

    // If no future provided, just complete after minimum time
    if (widget.initializationFuture == null) {
      _loadingDone = true;
    }
  }

  void _onProgressChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _finishProgress() async {
    // Wait for minimum display time before completing
    if (!_minTimePassed) {
      await Future.delayed(Duration(milliseconds: widget.minimumDisplayTime));
    }

    if (!mounted) return;

    // Animate to 100%
    await _progressController.complete();

    // Small delay to show 100% before hiding
    await Future.delayed(const Duration(milliseconds: 200));

    _checkComplete();
  }

  void _checkComplete() {
    if (_loadingDone && _minTimePassed && _progressController.isCompleted) {
      if (mounted) {
        setState(() {
          _showChild = true;
        });
        widget.onComplete?.call();
      }
    }
  }

  @override
  void dispose() {
    _progressController.removeListener(_onProgressChanged);
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show child after splash is done
    if (_showChild && widget.child != null) {
      return widget.child!;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Background color based on theme
    final backgroundColor = isDark
        ? const Color(0xFF000000) // True black for dark mode
        : const Color(0xFFFAFAFA); // Warm white for light mode

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(child: OwnerAppLoader(progress: _progressController.progress)),
    );
  }
}

/// Standalone splash screen widget for use when wrapping entire app.
///
/// Can overlay a child widget (the app) while showing the splash screen.
class OwnerSplashOverlay extends StatefulWidget {
  /// The future representing the actual initialization.
  final Future<void>? initializationFuture;

  /// Callback when initialization AND progress animation are both complete.
  final VoidCallback onComplete;

  /// Minimum display time in milliseconds (0 = no minimum, show until ready)
  final int minimumDisplayTime;

  /// Optional child widget to overlay (the app)
  final Widget? child;

  const OwnerSplashOverlay({
    super.key,
    this.initializationFuture,
    required this.onComplete,
    this.minimumDisplayTime = 800,
    this.child,
  });

  @override
  State<OwnerSplashOverlay> createState() => _OwnerSplashOverlayState();
}

class _OwnerSplashOverlayState extends State<OwnerSplashOverlay> {
  late final _SplashProgressController _progressController;
  bool _loadingDone = false;
  bool _minTimePassed = false;

  @override
  void initState() {
    super.initState();
    _progressController = _SplashProgressController();
    _progressController.addListener(_onProgressChanged);

    _progressController.start();

    // Track minimum display time (skip if 0)
    if (widget.minimumDisplayTime > 0) {
      Future.delayed(Duration(milliseconds: widget.minimumDisplayTime), () {
        if (mounted) {
          _minTimePassed = true;
          _checkComplete();
        }
      });
    } else {
      // No minimum time - mark as passed immediately
      _minTimePassed = true;
    }

    // Wait for actual initialization to complete
    // NO SAFETY TIMEOUT - let initialization take as long as it needs
    // The native HTML splash has its own 15s safety timeout
    widget.initializationFuture
        ?.then((_) {
          if (mounted) {
            _loadingDone = true;
            _finishProgress();
          }
        })
        .catchError((e) {
          if (mounted) {
            _loadingDone = true;
            _finishProgress();
          }
        });

    // If no future provided, complete immediately
    if (widget.initializationFuture == null) {
      _loadingDone = true;
      _finishProgress();
    }
  }

  void _onProgressChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _finishProgress() async {
    // Wait for minimum time only if it's set and not already passed
    if (!_minTimePassed && widget.minimumDisplayTime > 0) {
      await Future.delayed(Duration(milliseconds: widget.minimumDisplayTime));
      if (!mounted) return;
      _minTimePassed = true; // Ensure flag is set after waiting
    }

    if (!mounted) return;

    // Complete progress animation
    await _progressController.complete();

    // Small delay to show 100% before hiding
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;
    _checkComplete();
  }

  void _checkComplete() {
    // Force completion - all conditions met or we'll call onComplete anyway
    if (_loadingDone && _minTimePassed && _progressController.isCompleted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _progressController.removeListener(_onProgressChanged);
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Try to get theme from context, fallback to light theme if not available
    ThemeData? theme;
    bool isDark = false;
    try {
      theme = Theme.of(context);
      isDark = theme.brightness == Brightness.dark;
    } catch (e) {
      // No theme in context yet, use light theme as default
      theme = ThemeData.light();
      isDark = false;
    }

    final backgroundColor = isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA);

    // Build the splash screen widget with theme context
    final splashScreen = Theme(
      data: theme,
      child: Material(
        color: backgroundColor,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: OwnerAppLoader(progress: _progressController.progress)),
        ),
      ),
    );

    // If we have a child (the app), overlay the splash on top
    if (widget.child != null) {
      return Stack(
        children: [
          // App in background
          widget.child!,
          // Splash overlay on top
          splashScreen,
        ],
      );
    }

    // No child - just show splash screen
    return splashScreen;
  }
}
