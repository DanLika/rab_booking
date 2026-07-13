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
/// ⚠ WEB: without a real key we now SKIP web activation entirely (see below).
/// `ReCaptchaV3Provider` loads `https://www.google.com/recaptcha/api.js` at
/// activation, and the deployed CSP on owner/widget/admin hosting
/// (`firebase.json` script-src) does NOT allow `www.google.com`. With the
/// placeholder key the reCAPTCHA script is CSP-blocked, its token never mints,
/// and the Firebase SDK holds `signInWithEmailAndPassword` waiting for that
/// token — so the owner/admin email-password login HANGS forever on
/// "Učitavanje…" (proven live 2026-07-13: with a debug token the login
/// completes, without it no auth request ever fires). App Check is enforced on
/// NO callable (`enforceAppCheck:false` everywhere) + Firestore/Storage App
/// Check off, so a placeholder web token protects nothing. To ENABLE web App
/// Check later: register a real reCAPTCHA v3 key, add `https://www.google.com`
/// to firebase.json script-src on all three surfaces, ship the key via
/// `--dart-define=APP_CHECK_RECAPTCHA_KEY=<key>`, THEN flip enforcement — all
/// together. Memory: `owner-login-appcheck-hang-2026-07-13.md`,
/// `csp-recaptcha-gsi-organic-refusals.md`.
///
/// Android: Play Integrity on prod release builds, Debug provider otherwise.
/// iOS:     DeviceCheck on prod release builds, Debug provider otherwise.
/// Mobile App Check is UNAFFECTED by the web skip — those providers don't use
/// reCAPTCHA and mint tokens normally.
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

    // WEB without a real reCAPTCHA key: skip activation. Activating with the
    // placeholder provider loads the CSP-blocked reCAPTCHA script whose token
    // never mints, which HANGS web email-password login (the SDK waits for the
    // App Check token before issuing the auth request). App Check is enforced
    // nowhere, so skipping it on web changes no security posture — it only
    // stops the hang. Mobile is untouched (handled below).
    if (kIsWeb && _recaptchaKey.isEmpty) {
      debugPrint(
        'App Check: skipping WEB activation — no APP_CHECK_RECAPTCHA_KEY. '
        'The placeholder reCAPTCHA is CSP-blocked and would hang web auth. '
        'Set a real key + allow www.google.com in CSP to enable web App Check.',
      );
      return;
    }

    await FirebaseAppCheck.instance.activate(
      // Web: reCAPTCHA v3 only when a real key is supplied (the no-key web case
      // returned above). On mobile this is ignored.
      providerWeb: _recaptchaKey.isNotEmpty
          ? ReCaptchaV3Provider(_recaptchaKey)
          : null,
      // Android: Play Integrity on prod release, Debug elsewhere.
      providerAndroid: isProd
          ? const AndroidPlayIntegrityProvider()
          : const AndroidDebugProvider(),
      // iOS: DeviceCheck on prod release, Debug elsewhere.
      providerApple: isProd
          ? const AppleDeviceCheckProvider()
          : const AppleDebugProvider(),
    );
  }
}
