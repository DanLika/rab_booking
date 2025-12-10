import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/minimalist_colors.dart';
import 'bookbed_loader.dart';
import 'smart_progress_controller.dart';

/// Smart loading screen that shows adaptive progress animation.
///
/// Unlike [WidgetLoadingScreen] which shows indeterminate progress,
/// this screen shows a progress bar that:
/// 1. Quickly advances to ~85%
/// 2. Slows down and waits for actual loading
/// 3. Completes to 100% when [onLoadingComplete] future resolves
///
/// This provides better UX feedback regardless of actual loading duration.
///
/// Usage:
/// ```dart
/// SmartLoadingScreen(
///   isDarkMode: isDarkMode,
///   loadingFuture: _validateUnitAndProperty(),
///   onComplete: () {
///     setState(() => _isValidating = false);
///   },
/// )
/// ```
class SmartLoadingScreen extends ConsumerStatefulWidget {
  /// Whether dark mode is active
  final bool isDarkMode;

  /// The future representing the actual loading operation.
  /// When this completes, the progress bar animates to 100%.
  final Future<void>? loadingFuture;

  /// Callback when loading AND progress animation are both complete.
  /// Use this to hide the loading screen.
  final VoidCallback? onComplete;

  /// Minimum display time in milliseconds (ensures loader is visible)
  final int minimumDisplayTime;

  const SmartLoadingScreen({
    super.key,
    required this.isDarkMode,
    this.loadingFuture,
    this.onComplete,
    this.minimumDisplayTime = 500,
  });

  @override
  ConsumerState<SmartLoadingScreen> createState() => _SmartLoadingScreenState();
}

class _SmartLoadingScreenState extends ConsumerState<SmartLoadingScreen> {
  late final SmartProgressController _progressController;
  bool _loadingDone = false;
  bool _minTimePassed = false;

  @override
  void initState() {
    super.initState();
    _progressController = SmartProgressController();
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

    // Wait for actual loading to complete
    widget.loadingFuture?.then((_) {
      if (mounted) {
        _loadingDone = true;
        _finishProgress();
      }
    }).catchError((e) {
      // Even on error, complete the progress
      if (mounted) {
        _loadingDone = true;
        _finishProgress();
      }
    });
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
    await Future.delayed(const Duration(milliseconds: 150));

    _checkComplete();
  }

  void _checkComplete() {
    if (_loadingDone && _minTimePassed && _progressController.isCompleted) {
      widget.onComplete?.call();
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
    final colors = MinimalistColorSchemeAdapter(dark: widget.isDarkMode);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Center(
        child: BookBedLoader(
          isDarkMode: widget.isDarkMode,
          progress: _progressController.progress,
        ),
      ),
    );
  }
}

/// Provider-based smart loading screen for use with async providers.
///
/// This variant watches an AsyncValue and automatically completes
/// when the provider resolves (data or error).
class SmartLoadingScreenWithProvider<T> extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final AsyncValue<T> asyncValue;
  final Widget Function(T data) onData;
  final Widget Function(Object error, StackTrace stack)? onError;
  final int minimumDisplayTime;

  const SmartLoadingScreenWithProvider({
    super.key,
    required this.isDarkMode,
    required this.asyncValue,
    required this.onData,
    this.onError,
    this.minimumDisplayTime = 500,
  });

  @override
  ConsumerState<SmartLoadingScreenWithProvider<T>> createState() =>
      _SmartLoadingScreenWithProviderState<T>();
}

class _SmartLoadingScreenWithProviderState<T>
    extends ConsumerState<SmartLoadingScreenWithProvider<T>> {
  late final SmartProgressController _progressController;
  bool _minTimePassed = false;
  bool _showContent = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _progressController = SmartProgressController();
    _progressController.addListener(_onProgressChanged);
    _startTime = DateTime.now();

    // Start progress animation if currently loading
    if (widget.asyncValue.isLoading) {
      _progressController.start();
    }

    // Track minimum display time
    Future.delayed(Duration(milliseconds: widget.minimumDisplayTime), () {
      if (mounted) {
        _minTimePassed = true;
        _checkIfShouldShowContent();
      }
    });
  }

  @override
  void didUpdateWidget(SmartLoadingScreenWithProvider<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if loading just finished
    if (oldWidget.asyncValue.isLoading && !widget.asyncValue.isLoading) {
      _finishProgress();
    }
  }

  void _onProgressChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _finishProgress() async {
    // Calculate remaining time to meet minimum display
    final elapsed = DateTime.now().difference(_startTime!).inMilliseconds;
    final remaining = widget.minimumDisplayTime - elapsed;

    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (!mounted) return;

    // Animate to 100%
    await _progressController.complete();

    // Small delay to show 100% before transitioning
    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      setState(() {
        _showContent = true;
      });
    }
  }

  void _checkIfShouldShowContent() {
    if (!widget.asyncValue.isLoading && _minTimePassed) {
      _finishProgress();
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
    // If we've completed the progress animation, show actual content
    if (_showContent) {
      return widget.asyncValue.when(
        data: widget.onData,
        error: (e, st) => widget.onError?.call(e, st) ?? _buildErrorWidget(e),
        loading: _buildLoadingWidget,
      );
    }

    // Show loading with smart progress
    return _buildLoadingWidget();
  }

  Widget _buildLoadingWidget() {
    final colors = MinimalistColorSchemeAdapter(dark: widget.isDarkMode);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Center(
        child: BookBedLoader(
          isDarkMode: widget.isDarkMode,
          progress: _progressController.progress,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    final colors = MinimalistColorSchemeAdapter(dark: widget.isDarkMode);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 24),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
