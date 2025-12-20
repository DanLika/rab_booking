/// Web-specific implementation of web utilities using dart:js_interop.
///
/// This file provides the web implementation for conditional imports.
/// It is automatically selected when running on web platform via:
/// ```dart
/// export 'web_utils_stub.dart'
///     if (dart.library.js_interop) 'web_utils_web.dart';
/// ```
///
/// Available functions:
/// - URL manipulation: [replaceUrlState], [pushUrlState], [navigateToUrl]
/// - Iframe support: [isInIframe], [sendIframeHeight], [setupIframeScrollCapture]
/// - Visual viewport: [listenToVisualViewport], [getVisualViewportHeight]
/// - Keyboard handling: [setupAndroidKeyboardFix], [blurActiveElement]
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../services/tab_communication_service.dart';
import '../services/tab_communication_service_web.dart';

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

/// Redirect top-level window (breaks out of iframe)
/// CRITICAL: Use this when in iframe and need to redirect for Stripe Checkout
/// This is necessary because Stripe Checkout cannot run inside nested iframes
///
/// Strategy:
/// 1. Try to redirect window.top (works if same-origin)
/// 2. Fallback to window.open with '_top' target (opens in new tab if cross-origin)
void redirectTopLevelWindow(String url) {
  try {
    // Try to redirect parent window (works if same-origin)
    if (web.window.top != null && web.window.top != web.window.self) {
      // Cast to Window to access location property
      final topWindow = web.window.top as web.Window;
      topWindow.location.href = url; // location.href accepts String directly
      web.console.log('[REDIRECT] Redirecting top-level window (same-origin)'.toJS);
      return;
    }
  } catch (e) {
    // Cross-origin iframe - cannot access window.top.location
    web.console.log('[REDIRECT] Cross-origin iframe detected, using window.open fallback'.toJS);
  }

  // Fallback: Use window.open with '_top' target
  // This will open in new tab/window if cross-origin
  try {
    final urlJs = url.toJS;
    final targetJs = '_top'.toJS;
    final featuresJs = ''.toJS;
    // window.open with '_top' target will redirect current window if same-origin,
    // or open in new tab if cross-origin
    _windowOpen(urlJs, targetJs, featuresJs);
    web.console.log('[REDIRECT] Opened URL in new tab/window'.toJS);
  } catch (e) {
    web.console.log('[REDIRECT] Failed to redirect: $e'.toJS);
    // Last resort: redirect current window (will fail for Stripe but better than nothing)
    web.window.location.href = url; // location.href accepts String directly
  }
}

/// Open URL in new window (for Stripe Checkout when in iframe)
/// Returns the window reference for monitoring
@JS('window.open')
external web.Window? _windowOpen(JSString url, JSString target, JSString features);

/// Pre-open payment popup with placeholder (CRITICAL: call synchronously on user click)
/// Returns: 'popup', 'redirect', or 'blocked'
@JS('PaymentBridge.preOpenPaymentPopup')
external JSString _paymentBridgePreOpenPopup();

/// Update popup URL after async checkout session creation
@JS('PaymentBridge.updatePaymentPopupUrl')
external bool _paymentBridgeUpdatePopupUrl(JSString url);

/// Open Stripe Checkout using PaymentBridge (popup or redirect based on device)
/// CRITICAL: Must be called synchronously on user click to avoid popup blocking
/// Returns: 'popup', 'redirect', 'blocked', or 'error'
@JS('PaymentBridge.openPayment')
external JSString _paymentBridgeOpenPayment(JSString url);

/// Save booking state before payment redirect/popup
@JS('PaymentBridge.saveBookingState')
external void _paymentBridgeSaveBookingState(JSString bookingDataJson);

/// Register callback for payment completion
@JS('PaymentBridge.onPaymentResult')
external void _paymentBridgeOnPaymentResult(JSFunction callback);

/// Notify payment completion (called from payment success page)
@JS('PaymentBridge.notifyComplete')
external void _paymentBridgeNotifyComplete(JSString sessionId, JSString status);

/// Check if PaymentBridge is available
@JS('PaymentBridge')
external JSAny? get _paymentBridge;

/// Pre-open payment popup with placeholder (CRITICAL: call synchronously on user click)
/// Returns: 'popup', 'redirect', or 'blocked'
String preOpenPaymentPopup() {
  try {
    if (_paymentBridge == null) {
      web.console.log('[STRIPE] PaymentBridge not available'.toJS);
      return 'error';
    }

    final result = _paymentBridgePreOpenPopup();
    final resultStr = result.toDart;
    web.console.log('[STRIPE] PaymentBridge.preOpenPaymentPopup result: $resultStr'.toJS);
    return resultStr;
  } catch (e) {
    web.console.log('[STRIPE] Error pre-opening popup: $e'.toJS);
    return 'error';
  }
}

/// Update popup URL after async checkout session creation
bool updatePaymentPopupUrl(String checkoutUrl) {
  try {
    if (_paymentBridge == null) {
      web.console.log('[STRIPE] PaymentBridge not available'.toJS);
      return false;
    }

    final success = _paymentBridgeUpdatePopupUrl(checkoutUrl.toJS);
    web.console.log('[STRIPE] PaymentBridge.updatePaymentPopupUrl result: $success'.toJS);
    return success;
  } catch (e) {
    web.console.log('[STRIPE] Error updating popup URL: $e'.toJS);
    return false;
  }
}

/// Open Stripe Checkout using PaymentBridge
/// Returns: 'popup', 'redirect', 'blocked', or 'error'
String openStripeCheckoutWithBridge(String checkoutUrl) {
  try {
    // Check if PaymentBridge is available
    if (_paymentBridge == null) {
      web.console.log('[STRIPE] PaymentBridge not available, falling back to direct redirect'.toJS);
      return 'error';
    }

    final result = _paymentBridgeOpenPayment(checkoutUrl.toJS);
    final resultStr = result.toDart;
    web.console.log('[STRIPE] PaymentBridge.openPayment result: $resultStr'.toJS);
    return resultStr;
  } catch (e) {
    web.console.log('[STRIPE] Error using PaymentBridge: $e'.toJS);
    return 'error';
  }
}

/// Save booking state before payment
void saveBookingStateForPayment(String bookingDataJson) {
  try {
    if (_paymentBridge != null) {
      _paymentBridgeSaveBookingState(bookingDataJson.toJS);
      web.console.log('[STRIPE] Booking state saved'.toJS);
    }
  } catch (e) {
    web.console.log('[STRIPE] Error saving booking state: $e'.toJS);
  }
}

/// Setup payment result listener
/// Callback receives JSON string with payment result
void setupPaymentResultListener(void Function(String) callback) {
  try {
    if (_paymentBridge != null) {
      // Convert Dart function to JSFunction for JS interop
      _paymentBridgeOnPaymentResult(callback.toJS);
      web.console.log('[STRIPE] Payment result listener registered'.toJS);
    }
  } catch (e) {
    web.console.log('[STRIPE] Error setting up payment listener: $e'.toJS);
  }
}

/// Notify payment completion via PaymentBridge
/// Called from payment success page to notify original tab/iframe
void notifyPaymentComplete(String sessionId, String status) {
  try {
    if (_paymentBridge != null) {
      _paymentBridgeNotifyComplete(sessionId.toJS, status.toJS);
      web.console.log('[STRIPE] Payment completion notified via PaymentBridge'.toJS);
    }
  } catch (e) {
    web.console.log('[STRIPE] Error notifying payment completion: $e'.toJS);
  }
}

/// Open Stripe Checkout in new window when in iframe (legacy method - kept for compatibility)
/// Returns window reference or null if failed
web.Window? openStripeCheckoutInNewWindow(String checkoutUrl) {
  try {
    // Try PaymentBridge first
    final bridgeResult = openStripeCheckoutWithBridge(checkoutUrl);
    if (bridgeResult == 'popup') {
      // Bridge handled it - return a dummy window reference
      // The bridge manages the popup internally
      return web.window; // Dummy return
    } else if (bridgeResult == 'redirect') {
      // Bridge handled redirect - return null
      return null;
    }

    // Fallback to direct window.open
    final width = 600;
    final height = 700;
    final left = (web.window.screen.width.toDouble() / 2 - width / 2).round();
    final top = (web.window.screen.height.toDouble() / 2 - height / 2).round();

    final features =
        'width=$width,height=$height,left=$left,top=$top,menubar=no,toolbar=no,location=no,status=no,resizable=yes,scrollbars=yes';

    final window = _windowOpen(checkoutUrl.toJS, '_blank'.toJS, features.toJS);

    if (window != null) {
      web.console.log('[STRIPE] Opened checkout in new window'.toJS);
      return window;
    } else {
      web.console.log('[STRIPE] Failed to open new window (popup blocked?)'.toJS);
      return null;
    }
  } catch (e) {
    web.console.log('[STRIPE] Error opening new window: $e'.toJS);
    return null;
  }
}

/// Check if current window is a popup (opened via window.open)
bool get isPopupWindow {
  try {
    // If window.opener exists, we're in a popup
    return web.window.opener != null;
  } catch (e) {
    return false;
  }
}

/// Close current window (only works if opened by same script)
/// Returns true if close was attempted, false if not in popup
bool closePopupWindow() {
  try {
    if (isPopupWindow) {
      web.window.close();
      return true;
    }
    return false;
  } catch (e) {
    web.console.log('[CLOSE_POPUP] Error closing window: $e'.toJS);
    return false;
  }
}

/// Try to close current window unconditionally
/// This is used after Stripe redirect where window.opener may be lost
/// Returns true if close was attempted (doesn't guarantee success)
bool tryCloseWindow() {
  try {
    // Attempt to close - will only work if window was opened by script
    // Browsers may ignore this if the window wasn't opened programmatically
    web.window.close();
    web.console.log('[CLOSE_WINDOW] Attempted to close window'.toJS);
    return true;
  } catch (e) {
    web.console.log('[CLOSE_WINDOW] Error closing window: $e'.toJS);
    return false;
  }
}

/// Send postMessage to parent window (for iframe or popup communication)
void sendMessageToParent(Map<String, dynamic> message) {
  try {
    if (isInIframe) {
      // Send to iframe parent
      web.window.parent?.postMessage(_dartMapToJs(message), '*'.toJS);
      web.console.log('[POSTMESSAGE] Sent to iframe parent: ${message['type']}'.toJS);
    } else if (isPopupWindow && web.window.opener != null) {
      // Send to popup opener (cast to Window for postMessage)
      final opener = web.window.opener as web.Window?;
      opener?.postMessage(_dartMapToJs(message), '*'.toJS);
      web.console.log('[POSTMESSAGE] Sent to popup opener: ${message['type']}'.toJS);
    }
  } catch (e) {
    web.console.log('[POSTMESSAGE] Error sending message: $e'.toJS);
  }
}

/// JS interop for JSON.stringify
@JS('JSON.stringify')
external JSString _jsonStringify(JSAny value);

/// Listen for postMessage from parent/opener window
/// Returns cleanup function
void Function() listenToParentMessages(void Function(Map<String, dynamic>) onMessage) {
  void handler(web.MessageEvent event) {
    try {
      // Verify origin (allow all for iframe embedding flexibility)
      // In production, you might want to restrict this

      final data = event.data;
      if (data == null) return;

      // Convert JS object to Dart Map
      // event.data is JSAny, so we can stringify it directly
      final jsonString = _jsonStringify(data).toDart;
      final map = jsonDecode(jsonString) as Map<String, dynamic>;

      onMessage(map);
    } catch (e) {
      web.console.log('[POSTMESSAGE] Error handling message: $e'.toJS);
    }
  }

  final jsHandler = handler.toJS;
  web.window.addEventListener('message', jsHandler);

  web.console.log('[POSTMESSAGE] Listening for parent messages'.toJS);

  return () {
    web.window.removeEventListener('message', jsHandler);
    web.console.log('[POSTMESSAGE] Stopped listening for parent messages'.toJS);
  };
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
    final message = <String, dynamic>{'type': 'resize', 'height': height.ceil(), 'source': 'bookbed-widget'};

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
    web.document.addEventListener('wheel', _handleWheelEvent.toJS, web.AddEventListenerOptions(passive: false));

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

  // FIX #16: Safe cast with try-catch - target can be Document, Window, etc.
  web.Element? scrollableElement;
  try {
    scrollableElement = _findScrollableParent(target as web.Element);
  } catch (e) {
    // Cast failed - target is not an Element, ignore this event
    return;
  }

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

    final isScrollable = overflowY == 'auto' || overflowY == 'scroll' || overflow == 'auto' || overflow == 'scroll';

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

/// Get physical screen width (not iframe dimensions)
/// Uses window.screen API which returns actual device screen dimensions
double getScreenWidth() {
  return web.window.screen.width.toDouble();
}

/// Get physical screen height (not iframe dimensions)
/// Uses window.screen API which returns actual device screen dimensions
double getScreenHeight() {
  return web.window.screen.height.toDouble();
}

/// Check if physical device is in landscape mode
/// Uses multiple strategies for reliable cross-browser detection:
/// 1. Screen Orientation API (most reliable, not supported on older iOS Safari)
/// 2. matchMedia orientation query (works on most browsers including Safari)
/// 3. Fallback to screen dimensions comparison
bool isDeviceLandscape() {
  try {
    // Strategy 1: Use Screen Orientation API (Chrome, Firefox, modern browsers)
    // Returns 'landscape-primary', 'landscape-secondary', 'portrait-primary', 'portrait-secondary'
    final orientation = web.window.screen.orientation;
    final orientationType = orientation.type;
    if (orientationType.contains('landscape')) {
      return true;
    }
    if (orientationType.contains('portrait')) {
      return false;
    }
  } catch (e) {
    // Screen Orientation API not available or failed
  }

  try {
    // Strategy 2: Use matchMedia orientation query (works on Safari iOS)
    // This is more reliable than screen.width/height on iOS
    final landscapeQuery = web.window.matchMedia('(orientation: landscape)');
    if (landscapeQuery.matches) {
      return true;
    }
    final portraitQuery = web.window.matchMedia('(orientation: portrait)');
    if (portraitQuery.matches) {
      return false;
    }
  } catch (e) {
    // matchMedia not available
  }

  // Strategy 3: Fallback to window dimensions (more reliable than screen dimensions in iframe)
  // On iOS Safari, screen.width/height are FIXED and don't reflect rotation
  // window.innerWidth/innerHeight DO change with rotation
  final windowWidth = web.window.innerWidth;
  final windowHeight = web.window.innerHeight;
  return windowWidth > windowHeight;
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

/// Force scroll window to top - used for Android Chrome keyboard bug
/// This uses native browser scroll, not Flutter's scroll controller
void forceWindowScrollToTop() {
  try {
    // Scroll document body and html element
    web.document.body?.scrollTop = 0;
    final htmlElement = web.document.documentElement;
    if (htmlElement != null) {
      htmlElement.scrollTop = 0;
    }

    // Also try window.scrollTo
    _windowScrollTo(0, 0);

    web.console.log('[SCROLL_FIX] Forced window scroll to top'.toJS);
  } catch (e) {
    web.console.log('[SCROLL_FIX] Error: $e'.toJS);
  }
}

/// JS interop for window.scrollTo
@JS('window.scrollTo')
external void _windowScrollTo(int x, int y);

/// Force full layout reset - aggressive fix for Android Chrome keyboard bug
/// This forces browser to recalculate layout after keyboard dismisses
void forceLayoutReset() {
  try {
    final body = web.document.body;
    if (body == null) return;

    // Force reflow by toggling display
    final originalDisplay = body.style.getPropertyValue('display');
    body.style.setProperty('display', 'none');

    // Force browser to acknowledge the change
    // ignore: unnecessary_statements
    body.offsetHeight; // Trigger reflow

    // Restore display
    body.style.setProperty('display', originalDisplay.isEmpty ? '' : originalDisplay);

    // Reset scroll positions
    body.scrollTop = 0;
    web.document.documentElement?.scrollTop = 0;
    _windowScrollTo(0, 0);

    web.console.log('[LAYOUT_RESET] Forced layout reset'.toJS);
  } catch (e) {
    web.console.log('[LAYOUT_RESET] Error: $e'.toJS);
  }
}

/// Setup aggressive keyboard dismiss handler for Android Chrome
/// This listens to visualViewport and forces layout reset when keyboard closes
/// Note: Works in both iframe and non-iframe contexts
void Function() setupAndroidKeyboardFix() {
  double lastHeight = web.window.visualViewport?.height.toDouble() ?? 0;
  double fullHeight = lastHeight;

  void onResize(web.Event event) {
    final currentHeight = web.window.visualViewport?.height.toDouble() ?? 0;

    // Update full height if we see a larger value
    if (currentHeight > fullHeight) {
      fullHeight = currentHeight;
    }

    // Detect keyboard dismiss: height increased significantly
    final heightIncrease = currentHeight - lastHeight;
    final isNearFullHeight = currentHeight >= fullHeight - 50;

    if (heightIncrease > 100 && isNearFullHeight) {
      web.console.log('[KEYBOARD_FIX] Keyboard dismissed, forcing layout reset'.toJS);

      // Multiple delayed resets to catch async layout updates
      for (final delay in [0, 50, 100, 200, 300]) {
        Future.delayed(Duration(milliseconds: delay), () {
          forceLayoutReset();
          blurActiveElement();
        });
      }
    }

    lastHeight = currentHeight;
  }

  final handler = onResize.toJS;
  web.window.visualViewport?.addEventListener('resize', handler);

  web.console.log('[KEYBOARD_FIX] Android keyboard fix installed'.toJS);

  return () {
    web.window.visualViewport?.removeEventListener('resize', handler);
    web.console.log('[KEYBOARD_FIX] Android keyboard fix removed'.toJS);
  };
}

/// Blur active element to dismiss keyboard on Android Chrome
void blurActiveElement() {
  try {
    final activeElement = web.document.activeElement;
    if (activeElement != null) {
      // Call blur on the active element
      (activeElement as dynamic).blur();
      web.console.log('[BLUR] Blurred active element'.toJS);
    }
  } catch (e) {
    web.console.log('[BLUR] Error: $e'.toJS);
  }
}

/// JS interop for window.hideNativeSplash
@JS('window.hideNativeSplash')
external void _jsHideNativeSplash([JSFunction? callback]);

/// Hide the native HTML splash screen (defined in index.html)
/// This calls window.hideNativeSplash() which fades out and removes the splash
void hideNativeSplash([void Function()? callback]) {
  try {
    if (callback != null) {
      _jsHideNativeSplash(callback.toJS);
    } else {
      _jsHideNativeSplash();
    }
    web.console.log('[SPLASH] Native splash hide requested'.toJS);
  } catch (e) {
    web.console.log('[SPLASH] Error hiding native splash: $e'.toJS);
    // Call callback anyway so app continues
    callback?.call();
  }
}

// ============================================
// PWA INSTALL PROMPT
// ============================================

/// JS interop for PWA install prompt functions
@JS('window.pwaCanInstall')
external bool? get _pwaCanInstall;

@JS('window.pwaPromptInstall')
external JSPromise<JSBoolean>? _pwaPromptInstall();

@JS('window.pwaIsInstalled')
external bool? get _pwaIsInstalled;

/// Check if PWA can be installed (install prompt is available)
bool canInstallPwa() {
  try {
    return _pwaCanInstall ?? false;
  } catch (e) {
    return false;
  }
}

/// Check if PWA is already installed
bool isPwaInstalled() {
  try {
    // Check display-mode media query (works for installed PWAs)
    final mediaQuery = web.window.matchMedia('(display-mode: standalone)');
    if (mediaQuery.matches) return true;

    // Also check iOS standalone mode
    final navigator = web.window.navigator;
    // Safari iOS uses navigator.standalone property
    try {
      final standalone = (navigator as dynamic).standalone;
      if (standalone == true) return true;
    } catch (_) {
      // Property doesn't exist on this browser
    }

    return _pwaIsInstalled ?? false;
  } catch (e) {
    return false;
  }
}

/// Prompt user to install PWA
/// Returns true if user accepted, false if dismissed
Future<bool> promptPwaInstall() async {
  try {
    final result = _pwaPromptInstall();
    if (result == null) {
      web.console.log('[PWA] Install prompt not available'.toJS);
      return false;
    }

    final jsResult = await result.toDart;
    final accepted = jsResult.toDart;
    web.console.log('[PWA] Install prompt result: $accepted'.toJS);
    return accepted;
  } catch (e) {
    web.console.log('[PWA] Error prompting install: $e'.toJS);
    return false;
  }
}

/// Listen for PWA installability changes
/// Callback is called when install prompt becomes available
void Function() listenToPwaInstallability(void Function(bool canInstall) callback) {
  try {
    // Check initial state
    callback(canInstallPwa());

    // Listen for custom event from index.html
    void handler(web.Event event) {
      callback(canInstallPwa());
    }

    final jsHandler = handler.toJS;
    web.window.addEventListener('pwa-installable', jsHandler);

    return () {
      web.window.removeEventListener('pwa-installable', jsHandler);
    };
  } catch (e) {
    web.console.log('[PWA] Error setting up installability listener: $e'.toJS);
    return () {};
  }
}
