/// Email notification configuration for widget settings.
///
/// Controls email notifications sent during the booking process:
/// - Booking confirmations to guests
/// - Payment receipts
/// - Owner notifications
/// - Email verification requirements
///
/// ## Usage
/// ```dart
/// final emailConfig = EmailNotificationConfig(
///   enabled: true,
///   sendBookingConfirmation: true,
///   sendPaymentReceipt: true,
///   sendOwnerNotification: true,
///   requireEmailVerification: false,
///   resendApiKey: 'your-api-key',
///   fromEmail: 'noreply@example.com',
///   fromName: 'Property Name',
/// );
///
/// if (emailConfig.isConfigured) {
///   // Email system is ready to send
/// }
/// ```
class EmailNotificationConfig {
  /// Master toggle for all email notifications
  final bool enabled;

  /// Send confirmation email to guest after booking is created
  final bool sendBookingConfirmation;

  /// Send receipt email to guest after payment is processed
  final bool sendPaymentReceipt;

  /// Notify owner when a new booking is created
  final bool sendOwnerNotification;

  /// Require guest to verify email before booking is confirmed
  final bool requireEmailVerification;

  /// Resend API key for sending emails
  final String? resendApiKey;

  /// From email address (e.g., "noreply@example.com")
  final String? fromEmail;

  /// From name displayed to recipients (e.g., "Property Name")
  final String? fromName;

  const EmailNotificationConfig({
    this.enabled = false,
    this.sendBookingConfirmation = true,
    this.sendPaymentReceipt = true,
    this.sendOwnerNotification = true,
    this.requireEmailVerification = false,
    this.resendApiKey,
    this.fromEmail,
    this.fromName,
  });

  /// Create from Firestore map data
  factory EmailNotificationConfig.fromMap(Map<String, dynamic> map) {
    return EmailNotificationConfig(
      enabled: map['enabled'] ?? false,
      sendBookingConfirmation: map['send_booking_confirmation'] ?? true,
      sendPaymentReceipt: map['send_payment_receipt'] ?? true,
      sendOwnerNotification: map['send_owner_notification'] ?? true,
      requireEmailVerification: map['require_email_verification'] ?? false,
      resendApiKey: map['resend_api_key'],
      fromEmail: map['from_email'],
      fromName: map['from_name'],
    );
  }

  /// Convert to Firestore map data
  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'send_booking_confirmation': sendBookingConfirmation,
      'send_payment_receipt': sendPaymentReceipt,
      'send_owner_notification': sendOwnerNotification,
      'require_email_verification': requireEmailVerification,
      'resend_api_key': resendApiKey,
      'from_email': fromEmail,
      'from_name': fromName,
    };
  }

  /// Regular expression for basic email validation.
  /// Validates format: local@domain.tld
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Check if email system is properly configured and ready to send.
  ///
  /// Returns true if:
  /// - Email notifications are enabled
  /// - Resend API key is set and not empty
  /// - From email address is set and has valid format
  bool get isConfigured {
    if (!enabled) return false;
    if (resendApiKey == null || resendApiKey!.trim().isEmpty) return false;
    if (fromEmail == null) return false;
    return _emailRegex.hasMatch(fromEmail!.trim());
  }

  /// Check if the from email address has a valid format.
  ///
  /// Returns true if fromEmail is null (not set) or matches email format.
  /// Returns false only if fromEmail is set but has invalid format.
  bool get hasValidFromEmail {
    if (fromEmail == null)
      return true; // Not set = valid (will fail isConfigured)
    return _emailRegex.hasMatch(fromEmail!.trim());
  }

  /// Create a copy with modified fields
  EmailNotificationConfig copyWith({
    bool? enabled,
    bool? sendBookingConfirmation,
    bool? sendPaymentReceipt,
    bool? sendOwnerNotification,
    bool? requireEmailVerification,
    String? resendApiKey,
    String? fromEmail,
    String? fromName,
  }) {
    return EmailNotificationConfig(
      enabled: enabled ?? this.enabled,
      sendBookingConfirmation:
          sendBookingConfirmation ?? this.sendBookingConfirmation,
      sendPaymentReceipt: sendPaymentReceipt ?? this.sendPaymentReceipt,
      sendOwnerNotification:
          sendOwnerNotification ?? this.sendOwnerNotification,
      requireEmailVerification:
          requireEmailVerification ?? this.requireEmailVerification,
      resendApiKey: resendApiKey ?? this.resendApiKey,
      fromEmail: fromEmail ?? this.fromEmail,
      fromName: fromName ?? this.fromName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailNotificationConfig &&
        other.enabled == enabled &&
        other.sendBookingConfirmation == sendBookingConfirmation &&
        other.sendPaymentReceipt == sendPaymentReceipt &&
        other.sendOwnerNotification == sendOwnerNotification &&
        other.requireEmailVerification == requireEmailVerification &&
        other.resendApiKey == resendApiKey &&
        other.fromEmail == fromEmail &&
        other.fromName == fromName;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      sendBookingConfirmation,
      sendPaymentReceipt,
      sendOwnerNotification,
      requireEmailVerification,
      resendApiKey,
      fromEmail,
      fromName,
    );
  }

  @override
  String toString() {
    return 'EmailNotificationConfig(enabled: $enabled, isConfigured: $isConfigured)';
  }
}
