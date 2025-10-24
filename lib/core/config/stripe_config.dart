import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Stripe Configuration
///
/// Manages Stripe API keys and configuration.
/// Keys are stored in .env file for security.
class StripeConfig {
  StripeConfig._();

  /// Stripe Publishable Key (frontend - safe to expose)
  ///
  /// This key is used for:
  /// - Initializing Stripe SDK in Flutter
  /// - Creating PaymentIntent client secrets
  /// - Payment Sheet UI
  ///
  /// Get from: https://dashboard.stripe.com/apikeys
  static String get publishableKey {
    final key = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'STRIPE_PUBLISHABLE_KEY not found in .env file. '
        'Please add it to your .env file.',
      );
    }
    return key;
  }

  /// Stripe Merchant Display Name
  ///
  /// This appears on the Payment Sheet and in payment confirmations.
  static const String merchantDisplayName = 'Rab Booking';

  /// Merchant Country Code (ISO 3166-1 alpha-2)
  static const String merchantCountryCode = 'HR'; // Croatia

  /// Default Currency
  static const String defaultCurrency = 'EUR';

  /// Test Mode Indicator
  ///
  /// Returns true if using test keys (starts with pk_test_)
  static bool get isTestMode {
    return publishableKey.startsWith('pk_test_');
  }

  /// Stripe API Version
  ///
  /// Should match the version used in Edge Functions
  static const String apiVersion = '2023-10-16';

  /// Apple Pay Merchant Identifier
  ///
  /// Required for Apple Pay support.
  /// Get from: https://developer.apple.com/account
  static String? get appleMerchantId {
    return dotenv.env['APPLE_MERCHANT_ID'];
  }

  /// Google Pay Merchant ID
  ///
  /// Required for Google Pay support.
  /// Get from: https://pay.google.com/business/console
  static String? get googlePayMerchantId {
    return dotenv.env['GOOGLE_PAY_MERCHANT_ID'];
  }

  /// Check if Apple Pay is configured
  static bool get isApplePayEnabled {
    return appleMerchantId != null && appleMerchantId!.isNotEmpty;
  }

  /// Check if Google Pay is configured
  static bool get isGooglePayEnabled {
    return googlePayMerchantId != null && googlePayMerchantId!.isNotEmpty;
  }

  /// Payment Methods Configuration
  ///
  /// Supported payment methods for Stripe Payment Sheet
  static const List<String> supportedPaymentMethods = [
    'card', // Credit/Debit cards
    // 'apple_pay', // Uncomment when configured
    // 'google_pay', // Uncomment when configured
  ];

  /// Allowed Card Networks
  static const List<String> allowedCardNetworks = [
    'visa',
    'mastercard',
    'amex',
    'discover',
    'diners',
    'jcb',
    'unionpay',
  ];

  /// Get configuration summary for debugging
  static Map<String, dynamic> getConfigSummary() {
    return {
      'merchantDisplayName': merchantDisplayName,
      'merchantCountryCode': merchantCountryCode,
      'defaultCurrency': defaultCurrency,
      'isTestMode': isTestMode,
      'apiVersion': apiVersion,
      'isApplePayEnabled': isApplePayEnabled,
      'isGooglePayEnabled': isGooglePayEnabled,
      'publishableKeyPrefix': publishableKey.substring(0, 10),
    };
  }
}
