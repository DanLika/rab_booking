/// Widget settings sub-configurations.
///
/// This barrel file exports all settings-related configuration classes
/// used by the Widget feature.
///
/// ## Available Configs
///
/// ### Payment Configs
/// - [PaymentConfigBase] - Mixin with shared deposit calculation logic
/// - [StripePaymentConfig] - Stripe Connect payment configuration
/// - [BankTransferConfig] - Bank transfer payment configuration
///
/// ### Booking Behavior
/// - [BookingBehaviorConfig] - Approval, cancellation, min/max nights
///
/// ### Calendar Export
/// - [ICalExportConfig] - iCal feed export settings
///
/// ### Contact & Communication
/// - [ContactOptions] - Phone, email, WhatsApp contact settings
/// - [EmailNotificationConfig] - Email notification settings
///
/// ### Legal & Compliance
/// - [TaxLegalConfig] - Tax and legal disclaimer settings
///
/// ## Usage
/// ```dart
/// import 'package:bookbed/features/widget/domain/models/settings/settings.dart';
///
/// final stripe = StripePaymentConfig(enabled: true, depositPercentage: 20);
/// final bank = BankTransferConfig(enabled: true, ownerId: 'user_123');
/// final booking = BookingBehaviorConfig(minNights: 2);
/// final ical = ICalExportConfig(enabled: true);
/// final contact = ContactOptions(showPhone: true, phoneNumber: '+385...');
/// final email = EmailNotificationConfig(enabled: true);
/// final tax = TaxLegalConfig(enabled: true);
/// ```
library;

export 'payment/payment.dart';
export 'booking_behavior_config.dart';
export 'ical_export_config.dart';
export 'contact_options.dart';
export 'email_notification_config.dart';
export 'tax_legal_config.dart';
