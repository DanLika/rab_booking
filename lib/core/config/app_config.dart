import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration
/// Loads environment variables from .env files
class AppConfig {
  /// Supabase URL
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? '';

  /// Supabase Anonymous Key (public)
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Stripe Publishable Key (public)
  static String get stripePublishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  /// API Base URL (if needed for custom endpoints)
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? supabaseUrl;

  /// Current environment (development, staging, production)
  static String get environment =>
      dotenv.env['ENV'] ?? 'development';

  /// Check if running in development mode
  static bool get isDevelopment => environment == 'development';

  /// Check if running in production mode
  static bool get isProduction => environment == 'production';

  /// Validate that required config values are present
  static bool validate() {
    if (supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL is not set in .env file');
    }
    if (supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY is not set in .env file');
    }
    return true;
  }
}
