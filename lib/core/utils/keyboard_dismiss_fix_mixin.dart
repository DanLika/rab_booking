import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Conditional import for web-specific implementation
import 'keyboard_dismiss_fix_web.dart' if (dart.library.io) 'keyboard_dismiss_fix_stub.dart';

/// Mixin that fixes Android Chrome keyboard dismiss bug (Flutter #175074).
///
/// The bug: When keyboard is dismissed via Android BACK button on Chrome,
/// Flutter's CanvasKit renderer doesn't recalculate layout, leaving white space.
///
/// This mixin detects viewport changes via visualViewport API and forces
/// a full widget tree rebuild when keyboard closes.
///
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with AndroidKeyboardDismissFix {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(...);
///   }
/// }
/// ```
mixin AndroidKeyboardDismissFix<T extends StatefulWidget> on State<T> {
  /// Cleanup function for viewport listener
  void Function()? _viewportCleanup;

  /// Last known viewport height - used to detect keyboard dismiss
  double _lastViewportHeight = 0;

  /// Full viewport height (without keyboard) - baseline for comparison
  double _fullViewportHeight = 0;

  /// Rebuild key - incrementing this forces full subtree rebuild
  int _rebuildKey = 0;

  /// Whether we're on Android Web (only platform affected by this bug)
  bool get _isAndroidWeb =>
      kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();

    if (_isAndroidWeb) {
      _initializeViewportListener();
    }
  }

  @override
  void dispose() {
    _viewportCleanup?.call();
    _viewportCleanup = null;
    super.dispose();
  }

  /// Initialize the viewport listener for Android Web
  void _initializeViewportListener() {
    // Get initial viewport height
    _lastViewportHeight = getVisualViewportHeightImpl() ?? 0;
    _fullViewportHeight = _lastViewportHeight;

    // Set up listener
    _viewportCleanup = listenToVisualViewportImpl(_onViewportResize);
  }

  /// Called when visualViewport resizes (keyboard open/close)
  void _onViewportResize() {
    if (!mounted) return;

    final currentHeight = getVisualViewportHeightImpl() ?? 0;
    final heightDiff = currentHeight - _lastViewportHeight;

    // Update full height if we see a larger value
    if (currentHeight > _fullViewportHeight) {
      _fullViewportHeight = currentHeight;
    }

    // Detect keyboard dismiss: viewport height increased significantly (>100px)
    // and we're near full viewport height
    final isKeyboardDismiss = heightDiff > 100 &&
        currentHeight >= _fullViewportHeight - 50;

    if (isKeyboardDismiss) {
      _forceFullRebuild();
    }

    _lastViewportHeight = currentHeight;
  }

  /// Force a complete widget tree rebuild
  ///
  /// This is the nuclear option - we increment a key that's used in the build
  /// method, which forces Flutter to completely rebuild the subtree.
  /// Also dispatches window resize events to trick Flutter into recalculating.
  void _forceFullRebuild() {
    // First, dispatch window resize events to trigger Flutter's resize handling
    forceCanvasInvalidateImpl();

    // Schedule multiple rebuilds to catch async layout updates
    for (final delay in [0, 16, 50, 100, 150, 250, 400]) {
      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;

        // Force unfocus to ensure keyboard is fully dismissed
        FocusScope.of(context).unfocus();

        // Dispatch another resize event
        forceWindowResizeImpl();

        // Trigger rebuild
        setState(() {
          _rebuildKey++;
        });

        // Also schedule a frame callback to ensure rendering completes
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Force another layout pass
            (context as Element).markNeedsBuild();
            // Dispatch resize again after frame
            forceWindowResizeImpl();
          }
        });
      });
    }
  }

  /// Get the rebuild key - use this in your build method to force rebuilds
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   return KeyedSubtree(
  ///     key: ValueKey(keyboardFixRebuildKey),
  ///     child: Scaffold(...),
  ///   );
  /// }
  /// ```
  int get keyboardFixRebuildKey => _rebuildKey;
}
