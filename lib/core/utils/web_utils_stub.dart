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
