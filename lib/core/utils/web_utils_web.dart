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
