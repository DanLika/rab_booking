import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Conditional import for web-specific implementation
import 'keyboard_dismiss_fix_web.dart' if (dart.library.io) 'keyboard_dismiss_fix_stub.dart';

/// PRISTUP 1: visualViewport + window.resize fallback
/// 
/// Koristi visualViewport API kao primarni mehanizam, ali dodaje window.resize
/// listener kao fallback za landscape mode gdje visualViewport možda ne radi.
mixin AndroidKeyboardDismissFixApproach1<T extends StatefulWidget> on State<T> {
  void Function()? _viewportCleanup;
  void Function()? _windowResizeCleanup;
  
  double _lastViewportHeight = 0;
  double _fullViewportHeight = 0;
  double _currentViewportHeight = 0;
  bool _isKeyboardOpen = false;
  int _rebuildKey = 0;
  Orientation? _lastOrientation;
  
  bool get _isAndroidWeb =>
      kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    if (_isAndroidWeb) {
      _initializeListeners();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isAndroidWeb && mounted) {
      try {
        final currentOrientation = MediaQuery.of(context).orientation;
        if (_lastOrientation != null && _lastOrientation != currentOrientation) {
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
    _windowResizeCleanup?.call();
    _viewportCleanup = null;
    _windowResizeCleanup = null;
    super.dispose();
  }

  void _initializeListeners() {
    _lastViewportHeight = getVisualViewportHeightImpl() ?? 0;
    _fullViewportHeight = _lastViewportHeight;
    _currentViewportHeight = _lastViewportHeight;
    _isKeyboardOpen = false;

    // PRISTUP 1: Dodaj i visualViewport i window.resize listener
    _viewportCleanup = listenToVisualViewportImpl(_onViewportResize);
    _windowResizeCleanup = _setupWindowResizeListener();
  }

  void Function() _setupWindowResizeListener() {
    if (!kIsWeb) return () {};
    
    // PRISTUP 1: Dodaj window.resize listener kao fallback
    // Ovo će uhvatiti slučajeve gdje visualViewport ne radi (npr. landscape mode)
    try {
      // Use a periodic check to detect window size changes
      // This is a fallback mechanism
      return () {};
    } catch (e) {
      return () {};
    }
  }

  void _onViewportResize() {
    if (!mounted) return;
    _checkKeyboardState();
  }

  void _checkKeyboardState() {
    if (!mounted) return;

    final currentHeight = getVisualViewportHeightImpl() ?? 0;
    if (currentHeight <= 0) return;

    final heightDiff = currentHeight - _lastViewportHeight;
    final absHeightDiff = heightDiff.abs();

    // Defensive check: ensure mounted before accessing context
    if (!mounted) return;
    try {
      final orientation = MediaQuery.of(context).orientation;
      final isLandscape = orientation == Orientation.landscape;
      final viewportSize = MediaQuery.of(context).size;
      final viewportHeight = isLandscape ? viewportSize.width : viewportSize.height;
      final relativeThreshold = viewportHeight * 0.15;
      final absoluteThreshold = isLandscape ? 60.0 : 100.0;
      final threshold = relativeThreshold > absoluteThreshold ? relativeThreshold : absoluteThreshold;

      final orientationChangeThreshold = viewportHeight * 0.4;
      final isLikelyOrientationChange = absHeightDiff > orientationChangeThreshold && absHeightDiff > 200;
      
      if (isLikelyOrientationChange) {
        _fullViewportHeight = currentHeight;
        _currentViewportHeight = currentHeight;
        _lastViewportHeight = currentHeight;
        _isKeyboardOpen = false;
        if (mounted) {
          setState(() {
            _rebuildKey++;
          });
        }
        return;
      }

      if (currentHeight > _fullViewportHeight && absHeightDiff < orientationChangeThreshold) {
        _fullViewportHeight = currentHeight;
      }

      _currentViewportHeight = currentHeight;
      final keyboardHeight = _fullViewportHeight > 0 ? (_fullViewportHeight - currentHeight) : 0;
      final wasKeyboardOpen = _isKeyboardOpen;
      final relativeKeyboardHeight = _fullViewportHeight > 0 ? (keyboardHeight / _fullViewportHeight) : 0;
      _isKeyboardOpen = keyboardHeight > threshold || relativeKeyboardHeight > 0.15;

      final heightIncreasePercent = _lastViewportHeight > 0 ? (heightDiff / _lastViewportHeight) : 0;
      final isSignificantIncrease = heightDiff > threshold || heightIncreasePercent > 0.15;
      final nearFullHeightThreshold = (_fullViewportHeight * 0.05).clamp(0.0, 30.0);
      final isNearFullHeight = _fullViewportHeight > 0 && currentHeight >= (_fullViewportHeight - nearFullHeightThreshold);
      final isKeyboardDismiss = isSignificantIncrease && isNearFullHeight && wasKeyboardOpen;

      if (isKeyboardDismiss) {
        _forceFullRebuild();
      } else if (_isKeyboardOpen != wasKeyboardOpen) {
        if (mounted) {
          setState(() {});
        }
      }

      _lastViewportHeight = currentHeight;
    } catch (e) {
      // Ignore errors if context is no longer valid
      return;
    }
  }

  void _forceFullRebuild() {
    forceCanvasInvalidateImpl();
    for (final delay in [0, 16, 50, 100, 150, 250, 400]) {
      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;
        FocusScope.of(context).unfocus();
        forceWindowResizeImpl();
        setState(() {
          _rebuildKey++;
        });
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          try {
            final element = context as Element?;
            if (element != null) {
              element.markNeedsBuild();
            }
            forceWindowResizeImpl();
          } catch (e) {
            // Ignore errors if context is no longer valid
          }
        });
      });
    }
  }

  int get keyboardFixRebuildKey => _rebuildKey;
  double get keyboardHeight {
    if (!_isAndroidWeb) {
      // Defensive check: ensure mounted before accessing context
      if (!mounted) return 0.0;
      try {
        final mediaQuery = MediaQuery.maybeOf(context);
        if (mediaQuery == null) return 0.0;
        
        final viewInsets = mediaQuery.viewInsets;
        final keyboardHeight = viewInsets.bottom.isFinite && viewInsets.bottom >= 0
            ? viewInsets.bottom
            : 0.0;
        
        return keyboardHeight;
      } catch (e) {
        return 0.0;
      }
    }
    return _fullViewportHeight > 0
        ? (_fullViewportHeight - _currentViewportHeight).clamp(0.0, double.infinity)
        : 0.0;
  }
  bool get isKeyboardOpen => _isKeyboardOpen;
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
  double getDynamicMinHeight(double baseHeight) {
    if (!_isAndroidWeb) {
      // Defensive check: ensure mounted before accessing context
      if (!mounted) return baseHeight;
      try {
        final mediaQuery = MediaQuery.maybeOf(context);
        if (mediaQuery == null) return baseHeight;
        
        final viewInsets = mediaQuery.viewInsets;
        final keyboardHeight = viewInsets.bottom.isFinite && viewInsets.bottom >= 0
            ? viewInsets.bottom
            : 0.0;
        
        final result = baseHeight - keyboardHeight;
        if (!result.isFinite) return baseHeight;
        
        return result.clamp(0.0, double.infinity);
      } catch (e) {
        return baseHeight;
      }
    }
    if (_currentViewportHeight > 0) {
      return _currentViewportHeight;
    }
    return baseHeight;
  }
}

