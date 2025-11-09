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

  const BankTransferConfig({
    this.enabled = false,
    this.depositPercentage = 20,
    this.bankName,
    this.accountNumber,
    this.iban,
    this.swift,
    this.accountHolder,
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
  }) {
    return BankTransferConfig(
      enabled: enabled ?? this.enabled,
      depositPercentage: depositPercentage ?? this.depositPercentage,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      iban: iban ?? this.iban,
      swift: swift ?? this.swift,
      accountHolder: accountHolder ?? this.accountHolder,
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
