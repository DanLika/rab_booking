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
  bool get hasContactMethod =>
      _isValidContact(showPhone, phoneNumber) ||
      _isValidContact(showEmail, emailAddress) ||
      _isValidContact(showWhatsApp, whatsAppNumber);

  /// Get list of enabled contact methods.
  List<String> get enabledMethods => [
    if (_isValidContact(showPhone, phoneNumber)) 'phone',
    if (_isValidContact(showEmail, emailAddress)) 'email',
    if (_isValidContact(showWhatsApp, whatsAppNumber)) 'whatsapp',
  ];

  /// Helper to check if a contact method is enabled and has valid value.
  static bool _isValidContact(bool isEnabled, String? value) =>
      isEnabled && value != null && value.isNotEmpty;

  /// Get the count of enabled contact methods.
  int get enabledMethodCount => enabledMethods.length;

  /// Create a copy with modified fields.
  ///
  /// Auto-disables show toggles if the corresponding value is empty/null.
  /// This prevents inconsistent state where showPhone=true but phoneNumber=null.
  ContactOptions copyWith({
    bool? showPhone,
    String? phoneNumber,
    bool? showEmail,
    String? emailAddress,
    bool? showWhatsApp,
    String? whatsAppNumber,
    String? customMessage,
  }) {
    final newPhoneNumber = phoneNumber ?? this.phoneNumber;
    final newEmailAddress = emailAddress ?? this.emailAddress;
    final newWhatsAppNumber = whatsAppNumber ?? this.whatsAppNumber;

    // Auto-disable toggles if no valid value exists
    final effectiveShowPhone =
        (showPhone ?? this.showPhone) &&
        newPhoneNumber != null &&
        newPhoneNumber.isNotEmpty;
    final effectiveShowEmail =
        (showEmail ?? this.showEmail) &&
        newEmailAddress != null &&
        newEmailAddress.isNotEmpty;
    final effectiveShowWhatsApp =
        (showWhatsApp ?? this.showWhatsApp) &&
        newWhatsAppNumber != null &&
        newWhatsAppNumber.isNotEmpty;

    return ContactOptions(
      showPhone: effectiveShowPhone,
      phoneNumber: newPhoneNumber,
      showEmail: effectiveShowEmail,
      emailAddress: newEmailAddress,
      showWhatsApp: effectiveShowWhatsApp,
      whatsAppNumber: newWhatsAppNumber,
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
