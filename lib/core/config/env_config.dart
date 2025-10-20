import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/logging_service.dart';
import 'web_config.dart';

/// Environment configuration loader
///
/// Loads environment variables from .env files based on the build configuration.
///
/// Usage:
/// ```dart
/// // In main.dart
/// await EnvConfig.load();
///
/// // Access variables
/// final supabaseUrl = EnvConfig.supabaseUrl;
/// final stripeKey = EnvConfig.stripePublishableKey;
/// ```
class EnvConfig {
  // Private constructor to prevent instantiation
  EnvConfig._();

  /// Load environment configuration
  ///
  /// Loads the appropriate .env file based on the environment:
  /// - Development: .env.development
  /// - Staging: .env.staging
  /// - Production: .env.production
  ///
  /// For web builds, uses hardcoded values from WebConfig instead.
  static Future<void> load({String? environment}) async {
    // Web builds use hardcoded WebConfig values
    if (kIsWeb) {
      if (kDebugMode) {
        LoggingService.logInfo('✅ Web build detected - using WebConfig');
        LoggingService.logInfo('📦 App Name: ${WebConfig.appName}');
        LoggingService.logInfo('🌍 Environment: ${WebConfig.environmentName}');
        LoggingService.logInfo('🔧 Supabase URL: ${WebConfig.supabaseUrl}');
        LoggingService.logInfo('💳 Stripe Mode: ${WebConfig.isTestMode ? "TEST" : "PRODUCTION"}');
      }
      return;
    }

    // Mobile/Desktop builds use .env files
    final env = environment ?? _currentEnvironment;

    try {
      await dotenv.load(fileName: '.env.$env');

      if (kDebugMode) {
        LoggingService.logInfo('✅ Environment loaded: $env');
        LoggingService.logInfo('📦 App Name: $appName');
        LoggingService.logInfo('🌍 Environment: $environmentName');
        LoggingService.logInfo('🔧 API Base URL: $apiBaseUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        LoggingService.logWarning('⚠️ Failed to load .env.$env, falling back to .env.development');
      }

      // Fallback to development
      await dotenv.load(fileName: '.env.development');
    }
  }

  /// Get current environment based on build mode
  static String get _currentEnvironment {
    if (kReleaseMode) {
      return 'production';
    } else if (kProfileMode) {
      return 'staging';
    } else {
      return 'development';
    }
  }

  // ============================================================================
  // Supabase Configuration
  // ============================================================================

  /// Supabase project URL
  static String get supabaseUrl {
    // Use WebConfig for web builds
    if (kIsWeb) return WebConfig.supabaseUrl;

    // Use .env for mobile/desktop
    return dotenv.get('SUPABASE_URL', fallback: '');
  }

  /// Supabase anonymous key (public)
  static String get supabaseAnonKey {
    // Use WebConfig for web builds
    if (kIsWeb) return WebConfig.supabaseAnonKey;

    // Use .env for mobile/desktop
    return dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  }

  /// Supabase service role key (private - only for server-side)
  static String get supabaseServiceKey {
    return dotenv.get('SUPABASE_SERVICE_KEY', fallback: '');
  }

  /// Database password
  static String get databasePassword {
    return dotenv.get('DATABASE_PASSWORD', fallback: '');
  }

  // ============================================================================
  // Stripe Configuration
  // ============================================================================

  /// Stripe publishable key (safe to use in client-side code)
  static String get stripePublishableKey {
    // Use WebConfig for web builds
    if (kIsWeb) return WebConfig.stripePublishableKey;

    // Use .env for mobile/desktop
    return dotenv.get('STRIPE_PUBLISHABLE_KEY', fallback: '');
  }

  /// Stripe secret key (should only be used server-side)
  static String get stripeSecretKey {
    return dotenv.get('STRIPE_SECRET_KEY', fallback: '');
  }

  /// Check if using Stripe test mode
  static bool get isStripeTestMode {
    return stripePublishableKey.startsWith('pk_test_');
  }

  // ============================================================================
  // API Configuration
  // ============================================================================

  /// API base URL
  static String get apiBaseUrl {
    return dotenv.get('API_BASE_URL', fallback: '');
  }

  // ============================================================================
  // App Configuration
  // ============================================================================

  /// App name (can vary by environment)
  static String get appName {
    return dotenv.get('APP_NAME', fallback: 'Rab Booking');
  }

  /// Environment name (development, staging, production)
  static String get environmentName {
    return dotenv.get('ENVIRONMENT', fallback: 'development');
  }

  /// Check if development environment
  static bool get isDevelopment {
    return environmentName == 'development';
  }

  /// Check if staging environment
  static bool get isStaging {
    return environmentName == 'staging';
  }

  /// Check if production environment
  static bool get isProduction {
    return environmentName == 'production';
  }

  // ============================================================================
  // Analytics & Monitoring
  // ============================================================================

  /// Enable analytics
  static bool get enableAnalytics {
    return dotenv.get('ENABLE_ANALYTICS', fallback: 'false').toLowerCase() == 'true';
  }

  /// Enable Crashlytics
  static bool get enableCrashlytics {
    return dotenv.get('ENABLE_CRASHLYTICS', fallback: 'false').toLowerCase() == 'true';
  }

  // ============================================================================
  // Feature Flags
  // ============================================================================

  /// Enable payment testing mode
  static bool get enablePaymentTesting {
    return dotenv.get('ENABLE_PAYMENT_TESTING', fallback: 'false').toLowerCase() == 'true';
  }

  /// Enable debug tools
  static bool get enableDebugTools {
    return dotenv.get('ENABLE_DEBUG_TOOLS', fallback: 'false').toLowerCase() == 'true';
  }

  /// Enable performance overlay
  static bool get enablePerformanceOverlay {
    return dotenv.get('ENABLE_PERFORMANCE_OVERLAY', fallback: 'false').toLowerCase() == 'true';
  }

  // ============================================================================
  // Logging Configuration
  // ============================================================================

  /// Log level (debug, info, warning, error)
  static String get logLevel {
    return dotenv.get('LOG_LEVEL', fallback: 'debug');
  }

  /// Enable API logging
  static bool get enableApiLogging {
    return dotenv.get('ENABLE_API_LOGGING', fallback: 'false').toLowerCase() == 'true';
  }

  // ============================================================================
  // Validation
  // ============================================================================

  /// Validate that all required environment variables are set
  static void validate() {
    final errors = <String>[];

    if (supabaseUrl.isEmpty) {
      errors.add('SUPABASE_URL is not set');
    }

    if (supabaseAnonKey.isEmpty) {
      errors.add('SUPABASE_ANON_KEY is not set');
    }

    if (stripePublishableKey.isEmpty) {
      errors.add('STRIPE_PUBLISHABLE_KEY is not set');
    }

    if (apiBaseUrl.isEmpty) {
      errors.add('API_BASE_URL is not set');
    }

    if (errors.isNotEmpty) {
      final errorMessage = 'Environment validation failed:\n${errors.join('\n')}';

      if (kDebugMode) {
        LoggingService.logError('❌ $errorMessage');
      }

      throw Exception(errorMessage);
    }

    if (kDebugMode) {
      LoggingService.logInfo('✅ Environment validation passed');
    }
  }

  /// Get all environment variables as a map (for debugging)
  /// ⚠️ Use with caution - may contain sensitive data
  static Map<String, String> toMap() {
    return {
      'supabaseUrl': supabaseUrl,
      'apiBaseUrl': apiBaseUrl,
      'appName': appName,
      'environment': environmentName,
      'enableAnalytics': enableAnalytics.toString(),
      'enableCrashlytics': enableCrashlytics.toString(),
      'enablePaymentTesting': enablePaymentTesting.toString(),
      'enableDebugTools': enableDebugTools.toString(),
      'logLevel': logLevel,
      'isStripeTestMode': isStripeTestMode.toString(),
      // Don't include sensitive keys
      'supabaseAnonKeySet': supabaseAnonKey.isNotEmpty.toString(),
      'stripePublishableKeySet': stripePublishableKey.isNotEmpty.toString(),
    };
  }

  /// Print environment configuration (safe for debugging)
  static void printConfig() {
    if (!kDebugMode) return;

    LoggingService.logDebug('');
    LoggingService.logDebug('=' * 60);
    LoggingService.logDebug('Environment Configuration');
    LoggingService.logDebug('=' * 60);

    toMap().forEach((key, value) {
      LoggingService.logDebug('$key: $value');
    });

    LoggingService.logDebug('=' * 60);
    LoggingService.logDebug('');
  }
}
