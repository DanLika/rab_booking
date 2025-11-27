import 'payment_config_base.dart';

/// Stripe payment configuration
///
/// Configures Stripe Connect integration for accepting payments.
/// Uses [PaymentConfigBase] mixin for shared deposit calculation logic.
///
/// ## Example
/// ```dart
/// final stripeConfig = StripePaymentConfig(
///   enabled: true,
///   depositPercentage: 20,
///   stripeAccountId: 'acct_xxx',
/// );
///
/// final deposit = stripeConfig.calculateDeposit(500.0); // 100.0
/// final remaining = stripeConfig.calculateRemaining(500.0); // 400.0
/// ```
class StripePaymentConfig with PaymentConfigBase {
  final bool enabled;

  @override
  final int depositPercentage; // 0-100 (0 = full payment, 100 = full payment as deposit)

  final String? stripeAccountId; // Stripe Connect account ID

  const StripePaymentConfig({
    this.enabled = false,
    this.depositPercentage = 20, // Default 20% deposit
    this.stripeAccountId,
  });

  factory StripePaymentConfig.fromMap(Map<String, dynamic> map) {
    return StripePaymentConfig(
      enabled: map['enabled'] ?? false,
      depositPercentage: (map['deposit_percentage'] ?? 20).clamp(0, 100),
      stripeAccountId: map['stripe_account_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'deposit_percentage': depositPercentage,
      'stripe_account_id': stripeAccountId,
    };
  }

  StripePaymentConfig copyWith({
    bool? enabled,
    int? depositPercentage,
    String? stripeAccountId,
  }) {
    return StripePaymentConfig(
      enabled: enabled ?? this.enabled,
      depositPercentage: depositPercentage ?? this.depositPercentage,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
    );
  }
}
