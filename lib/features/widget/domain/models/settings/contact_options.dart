/// Contact options configuration for widget settings.
///
/// Controls how guests can contact the property owner, primarily used
/// in `calendarOnly` widget mode where guests view availability but
/// must contact the owner directly to book.
///
/// ## Supported Contact Methods
/// - Phone number
/// - Email address
/// - WhatsApp
///
/// ## Usage
/// ```dart
/// final contact = ContactOptions(
///   showPhone: true,
///   phoneNumber: '+385 91 123 4567',
///   showEmail: true,
///   emailAddress: 'owner@example.com',
///   showWhatsApp: true,
///   whatsAppNumber: '+385 91 123 4567',
///   customMessage: 'Contact us for availability!',
/// );
///
/// if (contact.hasContactMethod) {
///   // At least one contact method is available
/// }
/// ```
class ContactOptions {
  /// Show phone number in widget
  final bool showPhone;

  /// Phone number to display (required if [showPhone] is true)
  final String? phoneNumber;

  /// Show email address in widget
  final bool showEmail;

  /// Email address to display (required if [showEmail] is true)
  final String? emailAddress;

  /// Show WhatsApp contact option in widget
  final bool showWhatsApp;

  /// WhatsApp number for click-to-chat (required if [showWhatsApp] is true)
  final String? whatsAppNumber;

  /// Custom message to show to guests above contact options
  final String? customMessage;

  const ContactOptions({
    this.showPhone = true,
    this.phoneNumber,
    this.showEmail = true,
    this.emailAddress,
    this.showWhatsApp = false,
    this.whatsAppNumber,
    this.customMessage,
  });

  /// Create from Firestore map data
  factory ContactOptions.fromMap(Map<String, dynamic> map) {
    return ContactOptions(
      showPhone: map['show_phone'] ?? true,
      phoneNumber: map['phone_number'],
      showEmail: map['show_email'] ?? true,
      emailAddress: map['email_address'],
      showWhatsApp: map['show_whatsapp'] ?? false,
      whatsAppNumber: map['whatsapp_number'],
      customMessage: map['custom_message'],
    );
  }

  /// Convert to Firestore map data
  Map<String, dynamic> toMap() {
    return {
      'show_phone': showPhone,
      'phone_number': phoneNumber,
      'show_email': showEmail,
      'email_address': emailAddress,
      'show_whatsapp': showWhatsApp,
      'whatsapp_number': whatsAppNumber,
      'custom_message': customMessage,
    };
  }

  /// Check if at least one contact method is available and configured.
  ///
  /// Returns true if any of the following conditions are met:
  /// - Phone is enabled AND phone number is not empty
  /// - Email is enabled AND email address is not empty
  /// - WhatsApp is enabled AND WhatsApp number is not empty
  bool get hasContactMethod {
    return (showPhone && phoneNumber != null && phoneNumber!.isNotEmpty) ||
        (showEmail && emailAddress != null && emailAddress!.isNotEmpty) ||
        (showWhatsApp && whatsAppNumber != null && whatsAppNumber!.isNotEmpty);
  }

  /// Get list of enabled contact methods.
  ///
  /// Returns a list of strings describing available contact methods.
  /// Useful for displaying in UI or generating summaries.
  List<String> get enabledMethods {
    final methods = <String>[];
    if (showPhone && phoneNumber != null && phoneNumber!.isNotEmpty) {
      methods.add('phone');
    }
    if (showEmail && emailAddress != null && emailAddress!.isNotEmpty) {
      methods.add('email');
    }
    if (showWhatsApp && whatsAppNumber != null && whatsAppNumber!.isNotEmpty) {
      methods.add('whatsapp');
    }
    return methods;
  }

  /// Get the count of enabled contact methods.
  int get enabledMethodCount => enabledMethods.length;

  /// Create a copy with modified fields
  ContactOptions copyWith({
    bool? showPhone,
    String? phoneNumber,
    bool? showEmail,
    String? emailAddress,
    bool? showWhatsApp,
    String? whatsAppNumber,
    String? customMessage,
  }) {
    return ContactOptions(
      showPhone: showPhone ?? this.showPhone,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      showEmail: showEmail ?? this.showEmail,
      emailAddress: emailAddress ?? this.emailAddress,
      showWhatsApp: showWhatsApp ?? this.showWhatsApp,
      whatsAppNumber: whatsAppNumber ?? this.whatsAppNumber,
      customMessage: customMessage ?? this.customMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactOptions &&
        other.showPhone == showPhone &&
        other.phoneNumber == phoneNumber &&
        other.showEmail == showEmail &&
        other.emailAddress == emailAddress &&
        other.showWhatsApp == showWhatsApp &&
        other.whatsAppNumber == whatsAppNumber &&
        other.customMessage == customMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      showPhone,
      phoneNumber,
      showEmail,
      emailAddress,
      showWhatsApp,
      whatsAppNumber,
      customMessage,
    );
  }

  @override
  String toString() {
    return 'ContactOptions(enabledMethods: $enabledMethods, hasContactMethod: $hasContactMethod)';
  }
}
