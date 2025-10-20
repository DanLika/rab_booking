/// Web-specific configuration for production deployment
///
/// These values are hardcoded for web builds since Flutter web cannot
/// read environment variables at runtime (unlike mobile builds).
///
/// For different environments (staging, production), update these values
/// or use build-time constants with --dart-define flags.
class WebConfig {
  // ===================================================================
  // SUPABASE CONFIGURATION
  // ===================================================================

  /// Supabase project URL
  /// Get this from: https://app.supabase.com/project/_/settings/api
  static const String supabaseUrl = 'https://fnfapeopfnkzkkwobhij.supabase.co';

  /// Supabase anonymous (public) key
  /// Get this from: https://app.supabase.com/project/_/settings/api
  /// This is safe to expose in client-side code (it's called "anon" key)
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZuZmFwZW9wZm5remtrd29iaGlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1NTU0NzksImV4cCI6MjA3NjEzMTQ3OX0.t9kR1UtPaZLhQFAwBDeRk7hmDqnpUNFk8Wny4FZljNo';

  // ===================================================================
  // STRIPE CONFIGURATION (PAYMENT)
  // ===================================================================

  /// Stripe publishable key (PRODUCTION)
  /// Get this from: https://dashboard.stripe.com/apikeys
  ///
  /// ⚠️ IMPORTANT: Use pk_live_xxx for production, NOT pk_test_xxx
  /// Test keys won't work with real payments!
  /// Currently using TEST mode - replace with pk_live_xxx for production!
  static const String stripePublishableKey = 'pk_test_51SIsGkBomKO7vDr0ehMwS6hKcrpH58VqXbKBNykiYoCvpKFzAzDMgBwEzdjKI6waCYOxpKTUGB3d6aBGKtj3pmvz00lxPeZTkV';

  // ===================================================================
  // OPTIONAL INTEGRATIONS
  // ===================================================================

  /// Google Maps API key (if using Google Maps)
  /// Get this from: https://console.cloud.google.com/apis/credentials
  static const String? googleMapsApiKey = null; // Optional

  /// Sentry DSN for error tracking (if using Sentry)
  /// Get this from: https://sentry.io/settings/projects/your-project/keys/
  static const String? sentryDsn = null; // Optional

  /// Google Analytics Measurement ID (if using GA4)
  /// Get this from: https://analytics.google.com/
  static const String? googleAnalyticsId = null; // Optional (e.g., 'G-XXXXXXXXXX')

  // ===================================================================
  // APP CONFIGURATION
  // ===================================================================

  /// App name
  static const String appName = 'RAB Booking';

  /// App version
  static const String appVersion = '1.0.0';

  /// Support email
  static const String supportEmail = 'support@rab-booking.com';

  /// Production base URL (your Sevalla domain)
  static const String productionUrl = 'https://rabbooking-gui6m.sevalla.page';

  // ===================================================================
  // HELPER METHODS
  // ===================================================================

  /// Check if all required keys are configured
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        stripePublishableKey.isNotEmpty &&
        !stripePublishableKey.contains('your_key_here');
  }

  /// Check if using test mode (Stripe test keys)
  static bool get isTestMode {
    return stripePublishableKey.startsWith('pk_test_');
  }

  /// Get environment name
  static String get environmentName {
    if (isTestMode) return 'TEST';
    return 'PRODUCTION';
  }
}
