import 'package:flutter/foundation.dart';

import '../../../../../../core/utils/nullable.dart';
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
@immutable
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
    return {'enabled': enabled, 'deposit_percentage': depositPercentage, 'stripe_account_id': stripeAccountId};
  }

  /// Creates a copy with modified fields.
  ///
  /// For nullable String fields (stripeAccountId), use [Nullable] wrapper
  /// to explicitly set to null:
  /// ```dart
  /// config.copyWith(stripeAccountId: Nullable(null)) // Sets to null
  /// config.copyWith(stripeAccountId: Nullable('acct_xxx')) // Sets new value
  /// config.copyWith() // Keeps existing value
  /// ```
  StripePaymentConfig copyWith({
    bool? enabled,
    int? depositPercentage,
    Nullable<String>? stripeAccountId,
  }) {
    return StripePaymentConfig(
      enabled: enabled ?? this.enabled,
      depositPercentage: depositPercentage ?? this.depositPercentage,
      stripeAccountId: stripeAccountId != null ? stripeAccountId.value : this.stripeAccountId,
    );
  }
}
