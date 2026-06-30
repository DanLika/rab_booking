/// Environment configuration for the app
enum Environment { development, staging, production }

class EnvironmentConfig {
  static Environment _current = Environment.development;

  static Environment get current => _current;

  static void setEnvironment(Environment env) {
    _current = env;
  }

  static bool get isDevelopment => _current == Environment.development;
  static bool get isStaging => _current == Environment.staging;
  static bool get isProduction => _current == Environment.production;

  /// Firebase project ID for current environment
  static String get firebaseProjectId {
    switch (_current) {
      case Environment.development:
        return 'bookbed-dev';
      case Environment.staging:
        return 'bookbed-staging';
      case Environment.production:
        return 'rab-booking-248fc';
    }
  }

  /// Cloud Functions base URL
  static String get functionsBaseUrl {
    switch (_current) {
      case Environment.development:
        return 'https://us-central1-bookbed-dev.cloudfunctions.net';
      case Environment.staging:
        return 'https://us-central1-bookbed-staging.cloudfunctions.net';
      case Environment.production:
        return 'https://us-central1-rab-booking-248fc.cloudfunctions.net';
    }
  }

  /// Bare hostname of the widget (no scheme/path).
  /// Use for `Uri.host ==` checks and `host.endsWith()` allowlists.
  /// Prod: `view.bookbed.io` | Staging: `staging.view.bookbed.io` |
  /// Dev: `bookbed-widget-dev.web.app` (Firebase Hosting site).
  static String get widgetHost {
    switch (_current) {
      case Environment.development:
        return 'bookbed-widget-dev.web.app';
      case Environment.staging:
        return 'staging.view.bookbed.io';
      case Environment.production:
        return 'view.bookbed.io';
    }
  }

  /// Bare hostname of the owner dashboard.
  /// Prod: `app.bookbed.io` | Staging: `staging.app.bookbed.io` |
  /// Dev: `bookbed-owner-dev.web.app`.
  static String get dashboardHost {
    switch (_current) {
      case Environment.development:
        return 'bookbed-owner-dev.web.app';
      case Environment.staging:
        return 'staging.app.bookbed.io';
      case Environment.production:
        return 'app.bookbed.io';
    }
  }

  /// Bare hostname of the public marketing site.
  /// No dev/staging Firebase Hosting target exists for marketing
  /// (verified against firebase.json) — all environments share `bookbed.io`.
  static String get marketingHost => 'bookbed.io';

  /// Widget URL for current environment.
  static String get widgetBaseUrl => 'https://$widgetHost';

  /// Dashboard URL for current environment.
  static String get dashboardBaseUrl => 'https://$dashboardHost';

  /// True if [host] is the widget host itself or one of its subdomains
  /// (e.g. `jasko-rab.view.bookbed.io`).
  static bool isWidgetHost(String host) =>
      host == widgetHost || host.endsWith('.$widgetHost');

  /// True if [host] is the bare marketing domain (`bookbed.io` / `www.bookbed.io`).
  /// Used to rewrite marketing-domain landings onto the widget host.
  static bool isMarketingHost(String host) =>
      host == marketingHost || host == 'www.$marketingHost';

  /// Whether to use Firebase emulators
  static bool get useEmulators => _current == Environment.development;

  /// Sentry DSN (disable in development)
  static String? get sentryDsn {
    if (_current == Environment.development) return null;
    const dsn = String.fromEnvironment('SENTRY_DSN');
    return dsn.isEmpty ? null : dsn;
  }

  /// Log level
  static String get logLevel {
    switch (_current) {
      case Environment.development:
        return 'debug';
      case Environment.staging:
        return 'info';
      case Environment.production:
        return 'warning';
    }
  }

  /// VAPID public key for Firebase Cloud Messaging web push.
  /// Each Firebase project mints its own VAPID key pair under
  /// Firebase Console → Project Settings → Cloud Messaging → Web Push certificates.
  /// Empty string = "not configured" → FcmService.initialize() returns early on web
  /// rather than calling `getToken(vapidKey: '')` (which would fail with INVALID_ARGUMENT).
  /// Operator: paste each env's public key here. PROD value is committed; DEV/STAGING
  /// pending Firebase Console copy. Tracking: audit/33 §11.4.
  static String get vapidKey {
    switch (_current) {
      case Environment.production:
        return 'BJ34pleaflOU2jRZNOSkKt1K_-DXsepYhUlCwSrmQfX8HrlTqr5d2HTH6UODaZiwkvideADX_yTcCpLOTNwkIzM';
      case Environment.staging:
        return 'dummyStagingVapidKey0000000000000000000000000000000000000000000000000000000000000000000'; // TODO: paste bookbed-staging VAPID key from Firebase Console
      case Environment.development:
        return 'dummyDevVapidKey00000000000000000000000000000000000000000000000000000000000000000000000'; // TODO: paste bookbed-dev VAPID key from Firebase Console
    }
  }
}
