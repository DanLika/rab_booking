import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web implementation of visualViewport listener
///
/// This file contains the actual JS interop code for listening to
/// visualViewport resize events on web platforms.

/// Stored callback reference for the viewport listener
void Function()? _viewportCallback;

/// Stored JS function reference - must be stored to properly remove listener
JSFunction? _jsHandler;

/// Get current visual viewport height
/// Returns null if visualViewport API is not available
double? getVisualViewportHeightImpl() {
  try {
    final viewport = web.window.visualViewport;
    if (viewport != null) {
      return viewport.height.toDouble();
    }
  } catch (e) {
    // Silently fail - API not available
  }
  return null;
}

/// Listen to visualViewport resize events
/// Returns a cleanup function to remove the listener
void Function() listenToVisualViewportImpl(void Function() onResize) {
  try {
    final viewport = web.window.visualViewport;
    if (viewport == null) {
      return () {}; // No-op cleanup
    }

    // Store callback
    _viewportCallback = onResize;

    // Create and store JS handler
    _jsHandler = _handleResize.toJS;

    // Add listener
    viewport.addEventListener('resize', _jsHandler);

    // Return cleanup function
    return () {
      if (_jsHandler != null) {
        viewport.removeEventListener('resize', _jsHandler);
        _jsHandler = null;
      }
      _viewportCallback = null;
    };
  } catch (e) {
    return () {}; // No-op cleanup on error
  }
}

/// Internal resize handler that calls the Dart callback
void _handleResize(web.Event event) {
  _viewportCallback?.call();
}

/// Force browser to dispatch a window resize event
/// This tricks Flutter into recalculating its layout
void forceWindowResizeImpl() {
  try {
    // Create and dispatch a resize event on window
    final resizeEvent = web.Event('resize');
    web.window.dispatchEvent(resizeEvent);
  } catch (e) {
    // Silently fail
  }
}

/// Force Flutter's canvas to invalidate by temporarily changing body style
void forceCanvasInvalidateImpl() {
  try {
    final body = web.document.body;
    if (body != null) {
      // Force reflow by reading and writing layout property
      final _ = body.offsetHeight;

      // Dispatch resize event multiple times with delays
      for (final delay in [0, 50, 100, 200]) {
        web.window.setTimeout((() {
          final resizeEvent = web.Event('resize');
          web.window.dispatchEvent(resizeEvent);
        }).toJS, delay.toJS);
      }
    }
  } catch (e) {
    // Silently fail
  }
}
