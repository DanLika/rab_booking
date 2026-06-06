import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Centralized Firebase App Check activation.
///
/// Reads the reCAPTCHA v3 site key from `--dart-define=APP_CHECK_RECAPTCHA_KEY`
/// at build time. If absent, falls back to a placeholder string so the SDK
/// initializes without throwing on web — tokens will not validate, but every
/// callable still has `enforceAppCheck: false`, so no requests are rejected
/// (no-op gate until enforcement is flipped in a follow-up PR).
///
/// Android: Play Integrity on prod release builds, Debug provider otherwise.
/// iOS:     DeviceCheck on prod release builds, Debug provider otherwise.
class AppCheckInit {
  static const _recaptchaKey = String.fromEnvironment(
    'APP_CHECK_RECAPTCHA_KEY',
  );

  static bool _activated = false;

  /// Call AFTER `Firebase.initializeApp()` and BEFORE any callable / Firestore read.
  /// Idempotent: a second call is a no-op so it's safe for entries that delegate
  /// to `main.dart`'s background init (e.g. `main_dev.dart → app.runMainApp()`).
  static Future<void> activate({required bool isProd}) async {
    if (_activated) return;
    _activated = true;

    final webProvider = _recaptchaKey.isNotEmpty
        ? ReCaptchaV3Provider(_recaptchaKey)
        : null;

    await FirebaseAppCheck.instance.activate(
      // Web: prod uses reCAPTCHA v3 when a real key is supplied; otherwise
      // we hand the SDK a placeholder so `activate()` doesn't throw. Tokens
      // produced from the placeholder won't validate — that's fine while
      // every callable has enforceAppCheck:false.
      providerWeb: webProvider ?? ReCaptchaV3Provider('placeholder-debug-only'),
      // Android: Play Integrity on prod release, Debug elsewhere.
      providerAndroid: isProd
          ? const AndroidPlayIntegrityProvider()
          : const AndroidDebugProvider(),
      // iOS: DeviceCheck on prod release, Debug elsewhere.
      providerApple: isProd ? const AppleDeviceCheckProvider() : const AppleDebugProvider(),
    );

    if (kIsWeb && _recaptchaKey.isEmpty && isProd) {
      debugPrint(
        'App Check: APP_CHECK_RECAPTCHA_KEY not set; running with placeholder key. '
        'Register reCAPTCHA v3 in Firebase Console > App Check > Apps > Web, '
        'then pass --dart-define=APP_CHECK_RECAPTCHA_KEY=<key> on the next build.',
      );
    }
  }
}
