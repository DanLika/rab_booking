import 'package:web/web.dart' as web;

/// Browser and device detection utilities for web platform
class BrowserDetection {
  BrowserDetection._();

  /// Detect browser name from user agent
  /// Returns: 'chrome', 'firefox', 'safari', 'edge', 'opera', 'duckduckgo', 'unknown'
  static String getBrowserName() {
    try {
      final userAgent = web.window.navigator.userAgent.toLowerCase();

      if (userAgent.contains('edg/') || userAgent.contains('edge/')) {
        return 'edge';
      } else if (userAgent.contains('opr/') || userAgent.contains('opera/')) {
        return 'opera';
      } else if (userAgent.contains('chrome') && !userAgent.contains('edg/')) {
        // Check for DuckDuckGo (uses Chrome but has specific identifier)
        if (userAgent.contains('duckduckgo')) {
          return 'duckduckgo';
        }
        return 'chrome';
      } else if (userAgent.contains('firefox')) {
        return 'firefox';
      } else if (userAgent.contains('safari') && !userAgent.contains('chrome')) {
        return 'safari';
      } else {
        return 'unknown';
      }
    } catch (e) {
      return 'unknown';
    }
  }

  /// Detect device type from screen size and user agent
  /// Returns: 'desktop', 'mobile', 'tablet'
  static String getDeviceType() {
    try {
      final userAgent = web.window.navigator.userAgent.toLowerCase();
      final screen = web.window.screen;
      final screenWidth = screen.width;

      // Check user agent for mobile/tablet indicators
      final isMobileUA = userAgent.contains('mobile') ||
                        userAgent.contains('android') ||
                        userAgent.contains('iphone') ||
                        userAgent.contains('ipod');

      final isTabletUA = userAgent.contains('ipad') ||
                        (userAgent.contains('android') && !userAgent.contains('mobile'));

      // Check screen size as fallback
      if (isMobileUA || screenWidth < 768) {
        return 'mobile';
      } else if (isTabletUA || (screenWidth >= 768 && screenWidth < 1024)) {
        return 'tablet';
      } else {
        return 'desktop';
      }
    } catch (e) {
      return 'desktop';
    }
  }
}
