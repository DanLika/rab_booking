library;

/// Stub implementation of web utilities for non-web platforms.
/// These functions are no-ops on mobile/desktop.

import '../services/tab_communication_service.dart';

/// Replace browser URL state without navigation (no-op on mobile)
void replaceUrlState(String url) {
  // No-op on non-web platforms
}

/// Push browser URL state without navigation (no-op on mobile)
void pushUrlState(String url) {
  // No-op on non-web platforms
}

/// Navigate to URL (redirect) - no-op on mobile
/// On mobile, use url_launcher instead
void navigateToUrl(String url) {
  // No-op on non-web platforms
  // Use url_launcher for mobile navigation
}

/// Check if running on web platform
bool get isWebPlatform => false;

/// Check if widget is running inside an iframe
/// Always returns false on non-web platforms
bool get isInIframe => false;

/// Create platform-appropriate TabCommunicationService
/// Returns stub implementation on non-web platforms
TabCommunicationService createTabCommunicationService() {
  return TabCommunicationServiceStub();
}

/// Send iframe height to parent window via postMessage (no-op on mobile)
/// Used for dynamic iframe resizing when embedded in external websites
void sendIframeHeight(double height) {
  // No-op on non-web platforms
}

/// Capture scroll events in iframe to prevent parent page scrolling (no-op on mobile)
void setupIframeScrollCapture() {
  // No-op on non-web platforms
}

/// Listen to visualViewport resize events - more reliable than Flutter's MediaQuery
/// on Android Chrome when keyboard is dismissed via back button.
/// Returns a function to remove the listener.
void Function() listenToVisualViewport(void Function() onResize) {
  // No-op on non-web platforms
  return () {};
}

/// Get current visual viewport height (excluding keyboard)
/// Returns null on non-web platforms
double? getVisualViewportHeight() {
  return null;
}

/// Get window.innerHeight (full window height including keyboard area)
/// Returns 0 on non-web platforms
double getWindowInnerHeight() {
  return 0;
}

/// Get physical screen width (not iframe dimensions)
/// Returns 0 on non-web platforms
double getScreenWidth() {
  return 0;
}

/// Get physical screen height (not iframe dimensions)
/// Returns 0 on non-web platforms
double getScreenHeight() {
  return 0;
}

/// Check if physical device is in landscape mode
/// Returns false on non-web platforms (mobile uses MediaQuery)
bool isDeviceLandscape() {
  return false;
}

/// Calculate keyboard height by comparing window height to visual viewport
/// Returns 0 on non-web platforms
double getKeyboardHeight() {
  return 0;
}

/// Force scroll window to top - used for Android Chrome keyboard bug
/// No-op on non-web platforms
void forceWindowScrollToTop() {
  // No-op on non-web platforms
}

/// Blur active element to dismiss keyboard on Android Chrome
/// No-op on non-web platforms
void blurActiveElement() {
  // No-op on non-web platforms
}

/// Force full layout reset - aggressive fix for Android Chrome keyboard bug
/// No-op on non-web platforms
void forceLayoutReset() {
  // No-op on non-web platforms
}

/// Setup aggressive keyboard dismiss handler for Android Chrome
/// No-op on non-web platforms, returns empty cleanup function
void Function() setupAndroidKeyboardFix() {
  // No-op on non-web platforms
  return () {};
}

/// Hide the native HTML splash screen
/// No-op on non-web platforms (no HTML splash exists)
void hideNativeSplash([void Function()? callback]) {
  // No-op on non-web platforms - just call callback
  callback?.call();
}
