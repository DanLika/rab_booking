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

  /// Cleanup function for window resize listener (fallback)
  void Function()? _windowResizeCleanup;

  /// Last known viewport height - used to detect keyboard dismiss
  double _lastViewportHeight = 0;

  /// Full viewport height (without keyboard) - baseline for comparison
  double _fullViewportHeight = 0;

  /// Current viewport height - updated on every resize
  double _currentViewportHeight = 0;

  /// Whether keyboard is currently open
  bool _isKeyboardOpen = false;

  /// Rebuild key - incrementing this forces full subtree rebuild
  int _rebuildKey = 0;

  /// Last known orientation - used to detect orientation changes
  Orientation? _lastOrientation;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_isAndroidWeb && mounted) {
      // Detect orientation changes and reset baseline
      try {
        final currentOrientation = MediaQuery.of(context).orientation;
        if (_lastOrientation != null && _lastOrientation != currentOrientation) {
          // Orientation changed - reset full viewport height
          // This will be updated on next viewport resize event
          _fullViewportHeight = 0;
          _isKeyboardOpen = false;
        }
        _lastOrientation = currentOrientation;
      } catch (e) {
        // Ignore errors if context is no longer valid
      }
    }
  }

  @override
  void dispose() {
    _viewportCleanup?.call();
    _viewportCleanup = null;
    _windowResizeCleanup?.call();
    _windowResizeCleanup = null;
    super.dispose();
  }

  /// Initialize the viewport listener for Android Web
  void _initializeViewportListener() {
    // Get initial viewport height
    _lastViewportHeight = getVisualViewportHeightImpl() ?? 0;
    _fullViewportHeight = _lastViewportHeight;
    _currentViewportHeight = _lastViewportHeight;
    _isKeyboardOpen = false;

    // Set up primary listener (visualViewport API)
    _viewportCleanup = listenToVisualViewportImpl(_onViewportResize);

    // Set up fallback listener (window.resize) for cases where visualViewport
    // doesn't fire events properly (e.g., some landscape mode edge cases)
    _windowResizeCleanup = listenToWindowResizeImpl(_onViewportResize);
  }

  /// Called when visualViewport resizes (keyboard open/close)
  void _onViewportResize() {
    if (!mounted) return;

    final currentHeight = getVisualViewportHeightImpl() ?? 0;
    if (currentHeight <= 0) return; // Invalid height, skip

    // Defensive: skip tiny/noise deltas to avoid spurious layout work (especially in landscape)
    if ((_fullViewportHeight == 0 && currentHeight < 80) ||
        (_fullViewportHeight > 0 && (currentHeight - _lastViewportHeight).abs() < 20)) {
      return;
    }

    final heightDiff = currentHeight - _lastViewportHeight;
    final absHeightDiff = heightDiff.abs();

    // Defensive check: ensure mounted before accessing context
    if (!mounted) return;
    
    // Get current orientation to adjust thresholds
    try {
      final orientation = MediaQuery.of(context).orientation;
      final isLandscape = orientation == Orientation.landscape;
      
      // Use orientation-specific thresholds (matching JavaScript implementation)
      // Landscape has smaller viewport, so use larger percentage threshold
      final viewportSize = MediaQuery.of(context).size;
      final viewportHeight = isLandscape ? viewportSize.width : viewportSize.height;
      final relativeThreshold = isLandscape
          ? viewportHeight * 0.15   // Landscape: 15%
          : viewportHeight * 0.12;  // Portrait: 12%
      final absoluteThreshold = isLandscape
          ? 50.0    // Landscape: 50px (match JavaScript)
          : 100.0;  // Portrait: 100px
      final threshold = relativeThreshold > absoluteThreshold ? relativeThreshold : absoluteThreshold;

      // Detect orientation change: very large height change (>40% of viewport) without keyboard
      // This happens when device rotates
      final orientationChangeThreshold = viewportHeight * 0.4;
      final isLikelyOrientationChange = absHeightDiff > orientationChangeThreshold && 
                                        absHeightDiff > 200; // Also require absolute minimum
      
      if (isLikelyOrientationChange) {
        // Reset baseline on orientation change
        _fullViewportHeight = currentHeight;
        _currentViewportHeight = currentHeight;
        _lastViewportHeight = currentHeight;
        _isKeyboardOpen = false;
        
        // Force rebuild to adjust layout
        if (mounted) {
          setState(() {
            _rebuildKey++;
          });
        }
        return;
      }

      // Update full height if we see a larger value (keyboard closed)
      // But only if the increase is reasonable (not an orientation change)
      if (currentHeight > _fullViewportHeight && absHeightDiff < orientationChangeThreshold) {
        _fullViewportHeight = currentHeight;
      }

      // Update current viewport height
      _currentViewportHeight = currentHeight;

      // Detect keyboard state: significant height decrease means keyboard opened
      // Use relative threshold based on viewport size
      final keyboardHeight = _fullViewportHeight > 0 
          ? (_fullViewportHeight - currentHeight) 
          : 0;
      final wasKeyboardOpen = _isKeyboardOpen;
      
      // Keyboard is open if height difference exceeds threshold
      // Use both absolute and relative checks
      final relativeKeyboardHeight = _fullViewportHeight > 0 
          ? (keyboardHeight / _fullViewportHeight) 
          : 0;
      _isKeyboardOpen = keyboardHeight > threshold || relativeKeyboardHeight > 0.15;

      // Detect keyboard dismiss: viewport height increased significantly
      // Use relative threshold - at least 15% increase or absolute threshold
      final heightIncreasePercent = _lastViewportHeight > 0 
          ? (heightDiff / _lastViewportHeight) 
          : 0;
      final isSignificantIncrease = heightDiff > threshold || heightIncreasePercent > 0.15;
      
      // Safety check: ensure we're near full viewport height to avoid false positives
      // Use threshold * 0.5 (matching JavaScript implementation)
      final nearFullHeightThreshold = threshold * 0.5;
      final isNearFullHeight = _fullViewportHeight > 0 &&
          currentHeight >= (_fullViewportHeight - nearFullHeightThreshold);

      // Keyboard dismiss: significant height increase AND near full height
      final isKeyboardDismiss = isSignificantIncrease && isNearFullHeight && wasKeyboardOpen;

      if (isKeyboardDismiss) {
        _forceFullRebuild();
      } else if (_isKeyboardOpen != wasKeyboardOpen) {
        // Keyboard state changed - trigger rebuild to update layout
        if (mounted) {
          setState(() {
            // Trigger rebuild to update layout
          });
        }
      }

      _lastViewportHeight = currentHeight;
    } catch (e) {
      // Ignore errors if context is no longer valid
      return;
    }
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
          if (!mounted) return;
          try {
            // Force another layout pass
            final element = context as Element?;
            if (element != null) {
              element.markNeedsBuild();
            }
            // Dispatch resize again after frame
            forceWindowResizeImpl();
          } catch (e) {
            // Ignore errors if context is no longer valid
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

  /// Get current keyboard height in pixels
  /// Returns 0 if keyboard is not open or on non-web platforms
  double get keyboardHeight {
    if (!_isAndroidWeb) {
      // On non-Android Web, use MediaQuery as fallback
      // Defensive check: ensure mounted before accessing context
      if (!mounted) return 0.0;
      try {
        return MediaQuery.of(context).viewInsets.bottom;
      } catch (e) {
        return 0.0;
      }
    }
    return _fullViewportHeight > 0
        ? (_fullViewportHeight - _currentViewportHeight).clamp(0.0, double.infinity)
        : 0.0;
  }

  /// Get whether keyboard is currently open
  bool get isKeyboardOpen => _isKeyboardOpen;

  /// Get current viewport height (excluding keyboard)
  double get currentViewportHeight {
    if (_currentViewportHeight > 0) return _currentViewportHeight;
    if (_fullViewportHeight > 0) return _fullViewportHeight;
    // Defensive check: ensure mounted before accessing context
    if (!mounted) return 0.0;
    try {
      return MediaQuery.of(context).size.height;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get full viewport height (without keyboard)
  double get fullViewportHeight {
    if (_fullViewportHeight > 0) return _fullViewportHeight;
    // Defensive check: ensure mounted before accessing context
    if (!mounted) return 0.0;
    try {
      return MediaQuery.of(context).size.height;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get dynamic min height that adjusts based on keyboard state
  /// This should be used in ConstrainedBox minHeight to prevent white space
  double getDynamicMinHeight(double baseHeight) {
    if (!_isAndroidWeb) {
      // On non-Android Web, use MediaQuery
      // Defensive check: ensure mounted before accessing context
      if (!mounted) return baseHeight;
      try {
        final viewInsets = MediaQuery.of(context).viewInsets.bottom;
        return (baseHeight - viewInsets).clamp(0.0, double.infinity);
      } catch (e) {
        return baseHeight;
      }
    }

    // On Android Web, use visualViewport height
    if (_currentViewportHeight > 0) {
      return _currentViewportHeight;
    }

    // Fallback to base height
    return baseHeight;
  }
}
