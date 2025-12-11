import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../utils/web_utils.dart' if (dart.library.io) '../utils/web_utils_stub.dart';
import '../utils/keyboard_dismiss_fix_web.dart' if (dart.library.io) '../utils/keyboard_dismiss_fix_stub.dart';

/// A ConstrainedBox that automatically adjusts its minHeight based on keyboard state.
///
/// This widget prevents white space issues when the keyboard appears by dynamically
/// adjusting the minimum height constraint based on the current viewport size.
///
/// It works by:
/// 1. Using visualViewport API on web for accurate keyboard detection
/// 2. Falling back to [MediaQuery.viewInsets.bottom] for other platforms
/// 3. Automatically rebuilding when keyboard opens/closes
///
/// Usage:
/// ```dart
/// KeyboardAwareConstrainedBox(
///   baseHeight: constraints.maxHeight,
///   child: YourContent(),
/// )
/// ```
class KeyboardAwareConstrainedBox extends StatefulWidget {
  /// The base height to use when keyboard is closed
  /// This is typically the full screen height from LayoutBuilder
  final double baseHeight;

  /// The child widget to constrain
  final Widget child;

  /// Additional constraints to apply
  final BoxConstraints? additionalConstraints;

  const KeyboardAwareConstrainedBox({
    super.key,
    required this.baseHeight,
    required this.child,
    this.additionalConstraints,
  });

  @override
  State<KeyboardAwareConstrainedBox> createState() => _KeyboardAwareConstrainedBoxState();
}

class _KeyboardAwareConstrainedBoxState extends State<KeyboardAwareConstrainedBox> {
  void Function()? _viewportCleanup;

  @override
  void initState() {
    super.initState();
    // Listen to visualViewport changes on web to trigger rebuild when keyboard opens/closes
    if (kIsWeb) {
      _viewportCleanup = listenToVisualViewportImpl(_onViewportResize);
    }
  }

  @override
  void dispose() {
    _viewportCleanup?.call();
    _viewportCleanup = null;
    super.dispose();
  }

  void _onViewportResize() {
    if (mounted) {
      setState(() {
        // Trigger rebuild when viewport resizes (keyboard opens/closes)
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get keyboard-aware height
    // MediaQuery automatically triggers rebuild when keyboard opens/closes
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = _getAvailableHeight(mediaQuery, widget.baseHeight);

    // Use SizedBox with calculated height instead of ConstrainedBox
    // This ensures the container shrinks when keyboard appears
    final calculatedHeight = availableHeight.clamp(0.0, double.infinity);
    
    Widget result = SizedBox(
      height: calculatedHeight,
      child: widget.child,
    );

    // Apply additional constraints if provided
    if (widget.additionalConstraints != null) {
      result = ConstrainedBox(
        constraints: widget.additionalConstraints!.copyWith(
          minHeight: calculatedHeight > widget.additionalConstraints!.minHeight
              ? calculatedHeight
              : widget.additionalConstraints!.minHeight,
        ),
        child: result,
      );
    }

    return result;
  }

  /// Get available height from MediaQuery viewInsets or visualViewport
  double _getAvailableHeight(MediaQueryData mediaQuery, double baseHeight) {
    // On web, ALWAYS use visualViewport API for accurate keyboard detection
    // MediaQuery.viewInsets doesn't work reliably on web
    if (kIsWeb) {
      try {
        final viewportHeight = getVisualViewportHeight();
        if (viewportHeight != null && viewportHeight > 0) {
          // Use visualViewport height directly as it already excludes keyboard
          // Account for SafeArea padding
          final safeAreaTop = mediaQuery.padding.top;
          final safeAreaBottom = mediaQuery.padding.bottom;
          final availableViewport = viewportHeight - safeAreaTop - safeAreaBottom;
          // Return the smaller of viewport height or base height
          // This ensures we shrink when keyboard appears
          return availableViewport < baseHeight ? availableViewport : baseHeight;
        }
      } catch (e) {
        // If visualViewport fails, fall through to MediaQuery approach
      }
    }
    
    // Fallback to MediaQuery viewInsets for non-web platforms
    // viewInsets.bottom gives us the keyboard height
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    // Calculate available height (base height minus keyboard)
    final availableHeight = baseHeight - keyboardHeight;

    // Ensure we don't go below 0
    return availableHeight.clamp(0.0, double.infinity);
  }
}

