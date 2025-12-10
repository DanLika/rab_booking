import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../services/tab_communication_service.dart';
import '../services/tab_communication_service_web.dart';

/// Web implementation of web utilities using dart:js_interop.

/// Helper to convert Dart Map to JS object via JSON.parse
@JS('JSON.parse')
external JSAny _jsonParse(JSString jsonString);

JSAny _dartMapToJs(Map<String, dynamic> map) {
  return _jsonParse(jsonEncode(map).toJS);
}

/// Replace browser URL state without navigation
void replaceUrlState(String url) {
  web.window.history.replaceState(null, '', url);
}

/// Push browser URL state without navigation
void pushUrlState(String url) {
  web.window.history.pushState(null, '', url);
}

/// Navigate to URL (redirect)
void navigateToUrl(String url) {
  web.window.location.href = url;
}

/// Check if running on web platform
bool get isWebPlatform => true;

/// Check if widget is running inside an iframe
/// Returns true if current window is not the top-level window
bool get isInIframe {
  try {
    // More reliable check: compare self to top window
    // In iframe: self != top
    // In main window: self == top
    return web.window.self != web.window.top;
  } catch (e) {
    // Cross-origin iframe throws SecurityError - assume iframe context
    return true;
  }
}

/// Create platform-appropriate TabCommunicationService
/// Returns web implementation with BroadcastChannel support
TabCommunicationService createTabCommunicationService() {
  return TabCommunicationServiceWeb();
}

/// Send iframe height to parent window via postMessage
/// Used for dynamic iframe resizing when embedded in external websites
///
/// Message format: { type: 'resize', height: 850, source: 'bookbed-widget' }
void sendIframeHeight(double height) {
  try {
    // Only send if we're in an iframe
    if (!isInIframe) {
      return; // Not in iframe, skip
    }

    // Create message object
    final message = <String, dynamic>{
      'type': 'resize',
      'height': height.ceil(),
      'source': 'bookbed-widget',
    };

    // Debug log
    web.console.log('[IFRAME_RESIZE] Sending height: ${height.ceil()}px'.toJS);

    // Send to parent window (allow any origin for iframe embedding)
    web.window.parent?.postMessage(_dartMapToJs(message), '*'.toJS);
  } catch (e) {
    web.console.log('[IFRAME_RESIZE] Error: $e'.toJS);
  }
}

/// Capture scroll events in iframe to prevent parent page scrolling
/// Call this once when widget initializes in iframe mode
void setupIframeScrollCapture() {
  if (!isInIframe) return;

  try {
    // Set overflow hidden on html/body to contain scrolling
    final htmlElement = web.document.documentElement as web.HTMLElement?;
    final bodyElement = web.document.body;

    htmlElement?.style.setProperty('overflow', 'hidden');
    htmlElement?.style.setProperty('height', '100%');
    bodyElement?.style.setProperty('overflow', 'hidden');
    bodyElement?.style.setProperty('height', '100%');

    // Add wheel event listener to prevent scroll propagation to parent
    // This is critical for desktop where wheel scrolling is common
    web.document.addEventListener(
      'wheel',
      _handleWheelEvent.toJS,
      web.AddEventListenerOptions(passive: false),
    );

    web.console.log('[IFRAME] Scroll capture configured with wheel handler'.toJS);
  } catch (e) {
    web.console.log('[IFRAME] Scroll capture error: $e'.toJS);
  }
}

/// Handle wheel events to prevent propagation to parent window
/// when scrollable elements reach their boundaries
void _handleWheelEvent(web.WheelEvent event) {
  // Find the scrollable element under the cursor
  final target = event.target;
  if (target == null) return;

  final scrollableElement = _findScrollableParent(target as web.Element);

  if (scrollableElement != null) {
    final scrollTop = scrollableElement.scrollTop;
    final scrollHeight = scrollableElement.scrollHeight;
    final clientHeight = scrollableElement.clientHeight;

    // Calculate if we're at scroll boundaries
    final atTop = scrollTop <= 0;
    final atBottom = scrollTop + clientHeight >= scrollHeight - 1; // -1 for rounding

    // Determine scroll direction (positive deltaY = scrolling down)
    final scrollingDown = event.deltaY > 0;
    final scrollingUp = event.deltaY < 0;

    // Prevent default if trying to scroll beyond boundaries
    // This stops the event from propagating to parent window
    if ((scrollingUp && atTop) || (scrollingDown && atBottom)) {
      event.preventDefault();
      event.stopPropagation();
    }
  } else {
    // No scrollable element found - prevent all scroll propagation
    // This ensures parent page never scrolls from iframe wheel events
    event.preventDefault();
    event.stopPropagation();
  }
}

/// Find the nearest scrollable parent element
web.Element? _findScrollableParent(web.Element element) {
  web.Element? current = element;

  while (current != null) {
    // Check if element is scrollable
    final style = web.window.getComputedStyle(current);
    final overflowY = style.getPropertyValue('overflow-y');
    final overflow = style.getPropertyValue('overflow');

    final isScrollable = overflowY == 'auto' ||
        overflowY == 'scroll' ||
        overflow == 'auto' ||
        overflow == 'scroll';

    if (isScrollable) {
      // Verify it actually has scrollable content
      if (current.scrollHeight > current.clientHeight) {
        return current;
      }
    }

    // Move to parent
    current = current.parentElement;
  }

  return null;
}

/// Store callback for visualViewport listener
void Function()? _visualViewportCallback;

/// Store the JS function reference so we can remove it later
/// CRITICAL: .toJS creates a new JS function each time, so we must store the reference
JSFunction? _jsResizeHandler;

/// Listen to visualViewport resize events - more reliable than Flutter's MediaQuery
/// on Android Chrome when keyboard is dismissed via back button.
/// Returns a function to remove the listener.
void Function() listenToVisualViewport(void Function() onResize) {
  try {
    final visualViewport = web.window.visualViewport;
    if (visualViewport == null) {
      web.console.log('[VIEWPORT] visualViewport API not available'.toJS);
      return () {};
    }

    // Store callback reference
    _visualViewportCallback = onResize;

    // Create JS function ONCE and store it for later removal
    final handler = _onVisualViewportResize.toJS;
    _jsResizeHandler = handler;

    // Listen to resize events on visualViewport
    visualViewport.addEventListener('resize', handler);

    web.console.log('[VIEWPORT] visualViewport listener attached'.toJS);

    // Return cleanup function that uses the SAME JS function reference
    return () {
      if (_jsResizeHandler != null) {
        visualViewport.removeEventListener('resize', _jsResizeHandler);
        _jsResizeHandler = null;
      }
      _visualViewportCallback = null;
      web.console.log('[VIEWPORT] visualViewport listener removed'.toJS);
    };
  } catch (e) {
    web.console.log('[VIEWPORT] Error setting up listener: $e'.toJS);
    return () {};
  }
}

/// Handle visualViewport resize event
void _onVisualViewportResize(web.Event event) {
  final height = web.window.visualViewport?.height ?? 0;
  web.console.log('[VIEWPORT] resize event - height: ${height.toStringAsFixed(0)}px'.toJS);
  _visualViewportCallback?.call();
}

/// Get current visual viewport height (excluding keyboard)
double? getVisualViewportHeight() {
  try {
    final visualViewport = web.window.visualViewport;
    if (visualViewport != null) {
      return visualViewport.height.toDouble();
    }
  } catch (e) {
    // Ignore
  }
  return null;
}

/// Get window.innerHeight (full window height including keyboard area)
double getWindowInnerHeight() {
  return web.window.innerHeight.toDouble();
}

/// Calculate keyboard height by comparing window height to visual viewport
/// Returns 0 if keyboard is not visible or API not available
double getKeyboardHeight() {
  final viewportHeight = getVisualViewportHeight();
  if (viewportHeight == null) return 0;

  final windowHeight = getWindowInnerHeight();
  final keyboardHeight = windowHeight - viewportHeight;

  // Only return positive values (keyboard visible)
  return keyboardHeight > 0 ? keyboardHeight : 0;
}
