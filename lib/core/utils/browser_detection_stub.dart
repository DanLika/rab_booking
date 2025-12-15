/// Stub implementation for non-web platforms
class BrowserDetection {
  BrowserDetection._();

  /// Returns 'unknown' on non-web platforms
  static String getBrowserName() => 'unknown';

  /// Returns 'desktop' on non-web platforms
  static String getDeviceType() => 'desktop';
}
