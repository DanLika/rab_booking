import 'package:firebase_core/firebase_core.dart';

/// Detect the Sentry `environment` tag from the runtime Firebase project ID.
///
/// Mirrors `functions/src/sentry.ts detectEnvironment()` (fixed
/// 2026-05-21 in audit/11-sentry-env-fix.md) so dev and staging events
/// stop polluting the production Sentry dashboard on the Dart side.
///
/// Reads `Firebase.app().options.projectId` rather than
/// `EnvironmentConfig.firebaseProjectId` because the widget entry point
/// (`lib/widget_main.dart`) does not call `EnvironmentConfig.setEnvironment`,
/// so the static config would default to `development` regardless of the
/// deploy target. The runtime project ID is the authoritative source.
///
/// Must be called AFTER `Firebase.initializeApp()` has resolved.
String detectSentryEnvironment() {
  try {
    final projectId = Firebase.app().options.projectId;
    if (projectId == 'bookbed-dev') return 'development';
    if (projectId == 'bookbed-staging') return 'staging';
    if (projectId == 'rab-booking-248fc') return 'production';
    return 'unknown';
  } catch (_) {
    return 'unknown';
  }
}
