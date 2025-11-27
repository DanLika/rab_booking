/// Payment configuration classes for Widget settings.
///
/// This barrel file exports all payment-related configuration classes
/// used by the Widget feature.
///
/// ## Available Configs
///
/// - [PaymentConfigBase] - Mixin with shared deposit calculation logic
/// - [StripePaymentConfig] - Stripe Connect payment configuration
/// - [BankTransferConfig] - Bank transfer payment configuration
///
/// ## Usage
/// ```dart
/// import 'package:rab_booking/features/widget/domain/models/settings/payment/payment.dart';
///
/// final stripe = StripePaymentConfig(enabled: true, depositPercentage: 20);
/// final bank = BankTransferConfig(enabled: true, ownerId: 'user_123');
///
/// // Both use shared deposit calculation from PaymentConfigBase
/// final stripeDeposit = stripe.calculateDeposit(500.0); // 100.0
/// final bankDeposit = bank.calculateDeposit(500.0); // 100.0
/// ```
library;

export 'payment_config_base.dart';
export 'stripe_payment_config.dart';
export 'bank_transfer_config.dart';
