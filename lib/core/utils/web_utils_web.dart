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
    // Only send if we're in an iframe (parent != self)
    if (web.window.parent == web.window) {
      return; // Not in iframe, skip
    }

    // Create message object
    final message = <String, dynamic>{
      'type': 'resize',
      'height': height.ceil(),
      'source': 'bookbed-widget',
    };

    // Send to parent window (allow any origin for iframe embedding)
    web.window.parent?.postMessage(_dartMapToJs(message), '*'.toJS);
  } catch (e) {
    // Silently fail - not critical functionality
  }
}
