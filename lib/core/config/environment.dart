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

  /// Widget URL for current environment
  static String get widgetBaseUrl {
    switch (_current) {
      case Environment.development:
        return 'http://localhost:5000'; // Local dev server
      case Environment.staging:
        return 'https://staging.view.bookbed.io';
      case Environment.production:
        return 'https://view.bookbed.io';
    }
  }

  /// Dashboard URL for current environment
  static String get dashboardBaseUrl {
    switch (_current) {
      case Environment.development:
        return 'http://localhost:5001';
      case Environment.staging:
        return 'https://staging.app.bookbed.io';
      case Environment.production:
        return 'https://app.bookbed.io';
    }
  }

  /// Whether to use Firebase emulators
  static bool get useEmulators => _current == Environment.development;

  /// Sentry DSN (disable in development)
  static String? get sentryDsn {
    if (_current == Environment.development) return null;
    return 'https://2d78b151017ba853ff8b097914b92633@o4510516866908160.ingest.de.sentry.io/4510516869464144';
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
}
