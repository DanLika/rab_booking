import 'package:cloud_firestore/cloud_firestore.dart';
import 'widget_mode.dart';

/// Widget settings stored in Firestore for each property/unit
/// Path: properties/{propertyId}/widget_settings/{unitId}
class WidgetSettings {
  final String id; // unitId
  final String propertyId;

  // Display Mode
  final WidgetMode widgetMode;

  // Payment Methods Configuration
  final StripePaymentConfig? stripeConfig;
  final BankTransferConfig? bankTransferConfig;
  final bool allowPayOnArrival;

  // Booking Behavior
  final bool requireOwnerApproval; // If true, all bookings start as 'pending'
  final bool allowGuestCancellation;
  final int? cancellationDeadlineHours; // Hours before check-in

  // Contact Information (for calendar_only mode)
  final ContactOptions contactOptions;

  // Email Notifications
  final EmailNotificationConfig emailConfig;

  // External Calendar Integration
  final ExternalCalendarConfig? externalCalendarConfig;

  // Tax/Legal Disclaimer
  final TaxLegalConfig taxLegalConfig;

  // Theming
  final ThemeOptions? themeOptions;

  // Glassmorphism & Blur Effects
  final BlurConfig? blurConfig;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const WidgetSettings({
    required this.id,
    required this.propertyId,
    this.widgetMode = WidgetMode.bookingInstant,
    this.stripeConfig,
    this.bankTransferConfig,
    this.allowPayOnArrival = false,
    this.requireOwnerApproval = false,
    this.allowGuestCancellation = true,
    this.cancellationDeadlineHours = 48,
    required this.contactOptions,
    required this.emailConfig,
    this.externalCalendarConfig,
    required this.taxLegalConfig,
    this.themeOptions,
    this.blurConfig,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from Firestore document
  factory WidgetSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return WidgetSettings(
      id: doc.id,
      propertyId: data['property_id'] ?? '',
      widgetMode: WidgetMode.fromString(data['widget_mode'] ?? 'booking_instant'),
      stripeConfig: data['stripe_config'] != null
          ? StripePaymentConfig.fromMap(data['stripe_config'])
          : null,
      bankTransferConfig: data['bank_transfer_config'] != null
          ? BankTransferConfig.fromMap(data['bank_transfer_config'])
          : null,
      allowPayOnArrival: data['allow_pay_on_arrival'] ?? false,
      requireOwnerApproval: data['require_owner_approval'] ?? false,
      allowGuestCancellation: data['allow_guest_cancellation'] ?? true,
      cancellationDeadlineHours: data['cancellation_deadline_hours'] ?? 48,
      contactOptions: ContactOptions.fromMap(data['contact_options'] ?? {}),
      emailConfig: EmailNotificationConfig.fromMap(data['email_config'] ?? {}),
      externalCalendarConfig: data['external_calendar_config'] != null
          ? ExternalCalendarConfig.fromMap(data['external_calendar_config'])
          : null,
      taxLegalConfig: TaxLegalConfig.fromMap(data['tax_legal_config'] ?? {}),
      themeOptions: data['theme_options'] != null
          ? ThemeOptions.fromMap(data['theme_options'])
          : null,
      blurConfig: data['blur_config'] != null
          ? BlurConfig.fromMap(data['blur_config'])
          : null,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'property_id': propertyId,
      'widget_mode': widgetMode.toStringValue(),
      'stripe_config': stripeConfig?.toMap(),
      'bank_transfer_config': bankTransferConfig?.toMap(),
      'allow_pay_on_arrival': allowPayOnArrival,
      'require_owner_approval': requireOwnerApproval,
      'allow_guest_cancellation': allowGuestCancellation,
      'cancellation_deadline_hours': cancellationDeadlineHours,
      'contact_options': contactOptions.toMap(),
      'email_config': emailConfig.toMap(),
      'external_calendar_config': externalCalendarConfig?.toMap(),
      'tax_legal_config': taxLegalConfig.toMap(),
      'theme_options': themeOptions?.toMap(),
      'blur_config': blurConfig?.toMap(),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Check if any payment method is enabled
  bool get hasPaymentMethods {
    return (stripeConfig?.enabled ?? false) ||
           (bankTransferConfig?.enabled ?? false) ||
           allowPayOnArrival;
  }

  /// Get enabled payment method count
  int get enabledPaymentMethodCount {
    int count = 0;
    if (stripeConfig?.enabled ?? false) count++;
    if (bankTransferConfig?.enabled ?? false) count++;
    if (allowPayOnArrival) count++;
    return count;
  }

  WidgetSettings copyWith({
    String? id,
    String? propertyId,
    WidgetMode? widgetMode,
    StripePaymentConfig? stripeConfig,
    BankTransferConfig? bankTransferConfig,
    bool? allowPayOnArrival,
    bool? requireOwnerApproval,
    bool? allowGuestCancellation,
    int? cancellationDeadlineHours,
    ContactOptions? contactOptions,
    EmailNotificationConfig? emailConfig,
    ExternalCalendarConfig? externalCalendarConfig,
    TaxLegalConfig? taxLegalConfig,
    ThemeOptions? themeOptions,
    BlurConfig? blurConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WidgetSettings(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      widgetMode: widgetMode ?? this.widgetMode,
      stripeConfig: stripeConfig ?? this.stripeConfig,
      bankTransferConfig: bankTransferConfig ?? this.bankTransferConfig,
      allowPayOnArrival: allowPayOnArrival ?? this.allowPayOnArrival,
      requireOwnerApproval: requireOwnerApproval ?? this.requireOwnerApproval,
      allowGuestCancellation: allowGuestCancellation ?? this.allowGuestCancellation,
      cancellationDeadlineHours: cancellationDeadlineHours ?? this.cancellationDeadlineHours,
      contactOptions: contactOptions ?? this.contactOptions,
      emailConfig: emailConfig ?? this.emailConfig,
      externalCalendarConfig: externalCalendarConfig ?? this.externalCalendarConfig,
      taxLegalConfig: taxLegalConfig ?? this.taxLegalConfig,
      themeOptions: themeOptions ?? this.themeOptions,
      blurConfig: blurConfig ?? this.blurConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Stripe payment configuration
class StripePaymentConfig {
  final bool enabled;
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

  /// Calculate deposit amount
  double calculateDeposit(double totalAmount) {
    if (depositPercentage == 0 || depositPercentage == 100) {
      return totalAmount; // Full payment
    }
    return totalAmount * (depositPercentage / 100);
  }

  /// Calculate remaining amount
  double calculateRemaining(double totalAmount) {
    if (depositPercentage == 0 || depositPercentage == 100) {
      return 0.0; // No remaining
    }
    return totalAmount * ((100 - depositPercentage) / 100);
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

/// Bank transfer payment configuration
class BankTransferConfig {
  final bool enabled;
  final int depositPercentage; // 0-100
  final String? bankName;
  final String? accountNumber;
  final String? iban;
  final String? swift;
  final String? accountHolder;
  final int paymentDeadlineDays; // Days until payment deadline (1-14, default: 3)
  final bool enableQrCode; // Show EPC QR code for bank transfer
  final String? customNotes; // Custom notes from owner (max 500 chars)
  final bool useCustomNotes; // If true, show customNotes; if false, show default legal notes

  const BankTransferConfig({
    this.enabled = false,
    this.depositPercentage = 20,
    this.bankName,
    this.accountNumber,
    this.iban,
    this.swift,
    this.accountHolder,
    this.paymentDeadlineDays = 3,
    this.enableQrCode = true,
    this.customNotes,
    this.useCustomNotes = false,
  });

  factory BankTransferConfig.fromMap(Map<String, dynamic> map) {
    return BankTransferConfig(
      enabled: map['enabled'] ?? false,
      depositPercentage: (map['deposit_percentage'] ?? 20).clamp(0, 100),
      bankName: map['bank_name'],
      accountNumber: map['account_number'],
      iban: map['iban'],
      swift: map['swift'],
      accountHolder: map['account_holder'],
      paymentDeadlineDays: (map['payment_deadline_days'] ?? 3).clamp(1, 14),
      enableQrCode: map['enable_qr_code'] ?? true,
      customNotes: map['custom_notes'],
      useCustomNotes: map['use_custom_notes'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'deposit_percentage': depositPercentage,
      'bank_name': bankName,
      'account_number': accountNumber,
      'iban': iban,
      'swift': swift,
      'account_holder': accountHolder,
      'payment_deadline_days': paymentDeadlineDays,
      'enable_qr_code': enableQrCode,
      'custom_notes': customNotes,
      'use_custom_notes': useCustomNotes,
    };
  }

  /// Check if bank details are complete
  bool get hasCompleteDetails {
    return bankName != null &&
           accountHolder != null &&
           (iban != null || accountNumber != null);
  }

  /// Calculate deposit amount
  double calculateDeposit(double totalAmount) {
    if (depositPercentage == 0 || depositPercentage == 100) {
      return totalAmount;
    }
    return totalAmount * (depositPercentage / 100);
  }

  /// Calculate remaining amount
  double calculateRemaining(double totalAmount) {
    if (depositPercentage == 0 || depositPercentage == 100) {
      return 0.0;
    }
    return totalAmount * ((100 - depositPercentage) / 100);
  }

  BankTransferConfig copyWith({
    bool? enabled,
    int? depositPercentage,
    String? bankName,
    String? accountNumber,
    String? iban,
    String? swift,
    String? accountHolder,
    int? paymentDeadlineDays,
    bool? enableQrCode,
    String? customNotes,
    bool? useCustomNotes,
  }) {
    return BankTransferConfig(
      enabled: enabled ?? this.enabled,
      depositPercentage: depositPercentage ?? this.depositPercentage,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      iban: iban ?? this.iban,
      swift: swift ?? this.swift,
      accountHolder: accountHolder ?? this.accountHolder,
      paymentDeadlineDays: paymentDeadlineDays ?? this.paymentDeadlineDays,
      enableQrCode: enableQrCode ?? this.enableQrCode,
      customNotes: customNotes ?? this.customNotes,
      useCustomNotes: useCustomNotes ?? this.useCustomNotes,
    );
  }
}

/// Contact options for calendar_only mode
class ContactOptions {
  final bool showPhone;
  final String? phoneNumber;
  final bool showEmail;
  final String? emailAddress;
  final bool showWhatsApp;
  final String? whatsAppNumber;
  final String? customMessage; // Custom message to show to guests

  const ContactOptions({
    this.showPhone = true,
    this.phoneNumber,
    this.showEmail = true,
    this.emailAddress,
    this.showWhatsApp = false,
    this.whatsAppNumber,
    this.customMessage,
  });

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

  /// Check if at least one contact method is available
  bool get hasContactMethod {
    return (showPhone && phoneNumber != null && phoneNumber!.isNotEmpty) ||
           (showEmail && emailAddress != null && emailAddress!.isNotEmpty) ||
           (showWhatsApp && whatsAppNumber != null && whatsAppNumber!.isNotEmpty);
  }

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
}

/// Theme customization options
class ThemeOptions {
  final String? primaryColor; // Hex color
  final String? accentColor;
  final bool showBranding; // Show "Powered by Rab Booking" badge
  final String? customLogoUrl;
  final String? themeMode; // 'light', 'dark', 'system' (default: 'system')

  const ThemeOptions({
    this.primaryColor,
    this.accentColor,
    this.showBranding = true,
    this.customLogoUrl,
    this.themeMode = 'system',
  });

  factory ThemeOptions.fromMap(Map<String, dynamic> map) {
    return ThemeOptions(
      primaryColor: map['primary_color'],
      accentColor: map['accent_color'],
      showBranding: map['show_branding'] ?? true,
      customLogoUrl: map['custom_logo_url'],
      themeMode: map['theme_mode'] ?? 'system',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primary_color': primaryColor,
      'accent_color': accentColor,
      'show_branding': showBranding,
      'custom_logo_url': customLogoUrl,
      'theme_mode': themeMode,
    };
  }

  ThemeOptions copyWith({
    String? primaryColor,
    String? accentColor,
    bool? showBranding,
    String? customLogoUrl,
    String? themeMode,
  }) {
    return ThemeOptions(
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      showBranding: showBranding ?? this.showBranding,
      customLogoUrl: customLogoUrl ?? this.customLogoUrl,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Glassmorphism & Blur Effects configuration
class BlurConfig {
  final bool enabled; // Enable/disable all blur effects
  final String intensity; // 'subtle', 'light', 'medium', 'strong', 'extra_strong'
  final bool enableCardBlur; // Blur for cards
  final bool enableAppBarBlur; // Blur for app bar
  final bool enableModalBlur; // Blur for modals/dialogs
  final bool enableOverlayBlur; // Blur for overlays

  const BlurConfig({
    this.enabled = true,
    this.intensity = 'medium',
    this.enableCardBlur = true,
    this.enableAppBarBlur = true,
    this.enableModalBlur = true,
    this.enableOverlayBlur = true,
  });

  factory BlurConfig.fromMap(Map<String, dynamic> map) {
    return BlurConfig(
      enabled: map['enabled'] ?? true,
      intensity: map['intensity'] ?? 'medium',
      enableCardBlur: map['enable_card_blur'] ?? true,
      enableAppBarBlur: map['enable_app_bar_blur'] ?? true,
      enableModalBlur: map['enable_modal_blur'] ?? true,
      enableOverlayBlur: map['enable_overlay_blur'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'intensity': intensity,
      'enable_card_blur': enableCardBlur,
      'enable_app_bar_blur': enableAppBarBlur,
      'enable_modal_blur': enableModalBlur,
      'enable_overlay_blur': enableOverlayBlur,
    };
  }

  /// Get intensity as double (0.0 - 1.0)
  double get intensityValue {
    switch (intensity.toLowerCase()) {
      case 'subtle':
        return 0.2;
      case 'light':
        return 0.4;
      case 'medium':
        return 0.6;
      case 'strong':
        return 0.8;
      case 'extra_strong':
      case 'extrastrong':
        return 1.0;
      default:
        return 0.6; // Default to medium
    }
  }

  /// Check if any blur is enabled
  bool get hasAnyBlurEnabled {
    return enabled && (enableCardBlur || enableAppBarBlur || enableModalBlur || enableOverlayBlur);
  }

  BlurConfig copyWith({
    bool? enabled,
    String? intensity,
    bool? enableCardBlur,
    bool? enableAppBarBlur,
    bool? enableModalBlur,
    bool? enableOverlayBlur,
  }) {
    return BlurConfig(
      enabled: enabled ?? this.enabled,
      intensity: intensity ?? this.intensity,
      enableCardBlur: enableCardBlur ?? this.enableCardBlur,
      enableAppBarBlur: enableAppBarBlur ?? this.enableAppBarBlur,
      enableModalBlur: enableModalBlur ?? this.enableModalBlur,
      enableOverlayBlur: enableOverlayBlur ?? this.enableOverlayBlur,
    );
  }
}

/// Email notification configuration
class EmailNotificationConfig {
  final bool enabled; // Master toggle for all email notifications
  final bool sendBookingConfirmation; // Send confirmation email after booking
  final bool sendPaymentReceipt; // Send receipt email after payment
  final bool sendOwnerNotification; // Notify owner when new booking is created
  final bool requireEmailVerification; // Require email verification before booking
  final String? resendApiKey; // Resend API key for sending emails
  final String? fromEmail; // From email address (e.g., "noreply@example.com")
  final String? fromName; // From name (e.g., "Property Name")

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

  /// Check if email system is properly configured
  bool get isConfigured {
    return enabled && resendApiKey != null && fromEmail != null;
  }

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
      sendBookingConfirmation: sendBookingConfirmation ?? this.sendBookingConfirmation,
      sendPaymentReceipt: sendPaymentReceipt ?? this.sendPaymentReceipt,
      sendOwnerNotification: sendOwnerNotification ?? this.sendOwnerNotification,
      requireEmailVerification: requireEmailVerification ?? this.requireEmailVerification,
      resendApiKey: resendApiKey ?? this.resendApiKey,
      fromEmail: fromEmail ?? this.fromEmail,
      fromName: fromName ?? this.fromName,
    );
  }
}

/// External calendar integration configuration (e.g., Booking.com, Airbnb)
class ExternalCalendarConfig {
  final bool enabled; // Master toggle for external calendar sync
  final bool syncBookingCom; // Sync with Booking.com
  final String? bookingComAccountId; // Booking.com account/property ID
  final String? bookingComAccessToken; // OAuth access token
  final bool syncAirbnb; // Sync with Airbnb
  final String? airbnbAccountId; // Airbnb account/listing ID
  final String? airbnbAccessToken; // OAuth access token
  final int syncIntervalMinutes; // How often to sync (default: 60 minutes)
  final DateTime? lastSyncedAt; // Last successful sync timestamp

  const ExternalCalendarConfig({
    this.enabled = false,
    this.syncBookingCom = false,
    this.bookingComAccountId,
    this.bookingComAccessToken,
    this.syncAirbnb = false,
    this.airbnbAccountId,
    this.airbnbAccessToken,
    this.syncIntervalMinutes = 60,
    this.lastSyncedAt,
  });

  factory ExternalCalendarConfig.fromMap(Map<String, dynamic> map) {
    return ExternalCalendarConfig(
      enabled: map['enabled'] ?? false,
      syncBookingCom: map['sync_booking_com'] ?? false,
      bookingComAccountId: map['booking_com_account_id'],
      bookingComAccessToken: map['booking_com_access_token'],
      syncAirbnb: map['sync_airbnb'] ?? false,
      airbnbAccountId: map['airbnb_account_id'],
      airbnbAccessToken: map['airbnb_access_token'],
      syncIntervalMinutes: map['sync_interval_minutes'] ?? 60,
      lastSyncedAt: map['last_synced_at'] != null
          ? DateTime.parse(map['last_synced_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'sync_booking_com': syncBookingCom,
      'booking_com_account_id': bookingComAccountId,
      'booking_com_access_token': bookingComAccessToken,
      'sync_airbnb': syncAirbnb,
      'airbnb_account_id': airbnbAccountId,
      'airbnb_access_token': airbnbAccessToken,
      'sync_interval_minutes': syncIntervalMinutes,
      'last_synced_at': lastSyncedAt?.toIso8601String(),
    };
  }

  /// Check if any external calendar is connected
  bool get hasConnectedCalendar {
    return enabled && ((syncBookingCom && bookingComAccessToken != null) ||
        (syncAirbnb && airbnbAccessToken != null));
  }

  /// Check if sync is due (based on interval)
  bool get isSyncDue {
    if (lastSyncedAt == null) return true;
    final timeSinceSync = DateTime.now().difference(lastSyncedAt!);
    return timeSinceSync.inMinutes >= syncIntervalMinutes;
  }

  ExternalCalendarConfig copyWith({
    bool? enabled,
    bool? syncBookingCom,
    String? bookingComAccountId,
    String? bookingComAccessToken,
    bool? syncAirbnb,
    String? airbnbAccountId,
    String? airbnbAccessToken,
    int? syncIntervalMinutes,
    DateTime? lastSyncedAt,
  }) {
    return ExternalCalendarConfig(
      enabled: enabled ?? this.enabled,
      syncBookingCom: syncBookingCom ?? this.syncBookingCom,
      bookingComAccountId: bookingComAccountId ?? this.bookingComAccountId,
      bookingComAccessToken: bookingComAccessToken ?? this.bookingComAccessToken,
      syncAirbnb: syncAirbnb ?? this.syncAirbnb,
      airbnbAccountId: airbnbAccountId ?? this.airbnbAccountId,
      airbnbAccessToken: airbnbAccessToken ?? this.airbnbAccessToken,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

/// Tax and legal disclaimer configuration
class TaxLegalConfig {
  final bool enabled; // Master toggle - show disclaimer or not
  final bool useDefaultText; // true = use default, false = use custom
  final String? customText; // Custom text if useDefaultText = false

  const TaxLegalConfig({
    this.enabled = true, // Enabled by default for legal compliance
    this.useDefaultText = true, // Use default Croatian tax text
    this.customText,
  });

  factory TaxLegalConfig.fromMap(Map<String, dynamic> map) {
    return TaxLegalConfig(
      enabled: map['enabled'] ?? true,
      useDefaultText: map['use_default_text'] ?? true,
      customText: map['custom_text'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'use_default_text': useDefaultText,
      'custom_text': customText,
    };
  }

  /// Get the disclaimer text to display
  String get disclaimerText {
    if (!enabled) return '';

    if (useDefaultText) {
      return '''VAŽNO - Pravne i porezne informacije:

• Boravišna pristojba: Gosti su dužni platiti boravišnu pristojbu prema Zakonu o boravišnoj pristojbi (NN 52/22). Iznos pristojbe ovisi o kategoriji smještaja i dobi gosta.

• Fiskalizacija: Vlasnik smještajnog objekta je obvezan izdati fiskalizirani račun za pružene usluge prema Zakonu o fiskalizaciji (NN 115/16).

• Prijavljivanje gostiju: Gosti moraju biti prijavljeni u eVisitor sustav u roku od 24 sata od dolaska prema Zakonu o ugostiteljskoj djelatnosti (NN 85/15).

• Turistička naknada: Dodatno se naplaćuje turistička naknada prema odluci jedinice lokalne samouprave.

• Odgovornost vlasnika: Vlasnik objekta je u potpunosti odgovoran za ispunjavanje svih zakonskih obveza vezanih uz iznajmljivanje smještaja, uključujući plaćanje poreza na dohodak.

• Booking platforma: Ova platforma olakšava direktnu komunikaciju između vlasnika i gostiju. Ne preuzimamo odgovornost za porezne obveze vlasnika niti za pravnu usklađenost poslovanja.

Rezervacijom prihvaćate gore navedene uvjete i obveze.''';
    } else {
      return customText ?? '';
    }
  }

  /// Short version for emails (3-4 key points)
  String get shortDisclaimerText {
    if (!enabled) return '';

    return '''Napomena: Boravišna pristojba i turistička naknada se naplaćuju dodatno prema hrvatskim zakonima. Vlasnik objekta je odgovoran za fiskalizaciju i prijavljivanje gostiju u eVisitor sustav.''';
  }

  TaxLegalConfig copyWith({
    bool? enabled,
    bool? useDefaultText,
    String? customText,
  }) {
    return TaxLegalConfig(
      enabled: enabled ?? this.enabled,
      useDefaultText: useDefaultText ?? this.useDefaultText,
      customText: customText ?? this.customText,
    );
  }
}
