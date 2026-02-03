import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Feature flags for authentication providers.
///
/// These flags control which authentication methods are available in the UI.
/// Update these flags when providers are configured in Firebase Console.
abstract final class AuthFeatureFlags {
  /// Whether Google Sign-In is enabled and configured.
  ///
  /// Enabled on all platforms (Web, Android, iOS).
  ///
  /// SHA-1 certificates added to Firebase Console (rab-booking-248fc):
  /// - Debug: 28:F4:F5:3D:F1:4A:E2:5D:CD:F6:62:53:A9:52:9B:4E:12:3F:6D:28
  /// - Play Store: 85:1C:B5:E2:33:A5:32:A4:44:8A:45:B9:37:AA:45:7A:3C:F0:D4:8A
  static bool get isGoogleSignInEnabled => true;

  /// Whether Apple Sign-In is enabled and configured.
  ///
  /// Apple Sign-In is only available on iOS and Web.
  /// Android does not support Apple Sign-In natively.
  ///
  /// Configuration:
  /// 1. Apple Sign-In enabled in Firebase Console
  /// 2. Service ID: io.bookbed.app.signin (Apple Developer Portal)
  /// 3. OAuth redirect URL: https://rab-booking-248fc.firebaseapp.com/__/auth/handler
  static bool get isAppleSignInEnabled {
    if (kIsWeb) return true; // Web: Apple Sign-In works via OAuth
    if (Platform.isIOS) return true; // iOS: Native Apple Sign-In
    return false; // Android: Not supported
  }

  /// Whether email verification is required after registration/login.
  ///
  /// When false, users can access the dashboard immediately without
  /// verifying their email. Set to false during development/testing
  /// or if email verification is not critical for your use case.
  ///
  /// IMPORTANT: Set to true in production for security!
  static const bool requireEmailVerification = true;
}
