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
  // TODO: Enable when Apple Developer Portal is configured
  static const bool isAppleSignInEnabled = false;

  /// Whether email verification is required after registration/login.
  ///
  /// When false, users can access the dashboard immediately without
  /// verifying their email. Set to false during development/testing
  /// or if email verification is not critical for your use case.
  ///
  /// IMPORTANT: Set to true in production for security!
  static const bool requireEmailVerification = false;
}























