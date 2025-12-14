/// Feature flags for authentication providers.
///
/// These flags control which authentication methods are available in the UI.
/// Update these flags when providers are configured in Firebase Console.
abstract final class AuthFeatureFlags {
  /// Whether Google Sign-In is enabled and configured.
  ///
  /// Set to true when Google Sign-In is enabled in Firebase Console
  /// and all authorized domains are configured.
  static const bool isGoogleSignInEnabled = true;

  /// Whether Apple Sign-In is enabled and configured.
  ///
  /// Set to true when:
  /// 1. Apple Sign-In is enabled in Firebase Console
  /// 2. Service ID is configured in Apple Developer Portal
  /// 3. OAuth redirect URLs are configured
  static const bool isAppleSignInEnabled = false; // TODO: Enable when Apple Developer Portal is configured
}


