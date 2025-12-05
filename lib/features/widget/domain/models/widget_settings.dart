import 'package:cloud_firestore/cloud_firestore.dart';
import 'widget_mode.dart';
import 'settings/settings.dart';
import '../../../../core/utils/date_time_parser.dart';
import '../../../../core/utils/safe_cast.dart';

// Re-export configs for backward compatibility
// (Files importing widget_settings.dart can still access these classes)
export 'settings/settings.dart'
    show
        StripePaymentConfig,
        BankTransferConfig,
        PaymentConfigBase,
        ContactOptions,
        EmailNotificationConfig,
        TaxLegalConfig;

/// Widget settings stored in Firestore for each property/unit
/// Path: properties/{propertyId}/widget_settings/{unitId}
///
/// ## Config Accessors (Phase 4 Refactoring)
/// Helper getters provide grouped access to related settings:
/// - [bookingBehavior] - Approval, cancellation, min/max nights, weekend days
/// - [icalExport] - iCal feed export settings
///
/// The flat fields remain for backward compatibility.
class WidgetSettings {
  final String id; // unitId
  final String propertyId;
  final String? ownerId; // Required for Firestore security rules

  // Display Mode
  final WidgetMode widgetMode;

  // Payment Methods Configuration
  final int
  globalDepositPercentage; // Global deposit % (applies to all payment methods)
  final StripePaymentConfig? stripeConfig;
  final BankTransferConfig? bankTransferConfig;
  final bool allowPayOnArrival;

  // Booking Behavior
  final bool requireOwnerApproval; // If true, all bookings start as 'pending'
  final bool allowGuestCancellation;
  final int? cancellationDeadlineHours; // Hours before check-in
  final int minNights; // Minimum nights required for booking (default: 1)
  final List<int> weekendDays; // Days considered as weekend (1=Mon...7=Sun). Default: [6,7] (Sat, Sun)

  // Contact Information (for calendar_only mode)
  final ContactOptions contactOptions;

  // Email Notifications
  final EmailNotificationConfig emailConfig;

  // External Calendar Integration
  final ExternalCalendarConfig? externalCalendarConfig;

  // iCal Export Configuration
  final bool icalExportEnabled; // Master toggle for iCal export feature
  final String? icalExportUrl; // Generated iCal URL (if enabled)
  final String? icalExportToken; // Security token for public feed
  final DateTime? icalExportLastGenerated; // Last time iCal was generated

  // Tax/Legal Disclaimer
  final TaxLegalConfig taxLegalConfig;

  // Theming
  final ThemeOptions? themeOptions;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const WidgetSettings({
    required this.id,
    required this.propertyId,
    this.ownerId,
    this.widgetMode = WidgetMode.bookingInstant,
    this.globalDepositPercentage = 20, // Default 20% deposit
    this.stripeConfig,
    this.bankTransferConfig,
    this.allowPayOnArrival = false,
    this.requireOwnerApproval = false,
    this.allowGuestCancellation = true,
    this.cancellationDeadlineHours = 48,
    this.minNights = 1,
    this.weekendDays = const [6, 7], // Default: Saturday (6) and Sunday (7)
    required this.contactOptions,
    required this.emailConfig,
    this.externalCalendarConfig,
    this.icalExportEnabled = false,
    this.icalExportUrl,
    this.icalExportToken,
    this.icalExportLastGenerated,
    required this.taxLegalConfig,
    this.themeOptions,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from Firestore document
  ///
  /// Uses safe casting to prevent runtime errors from invalid data formats.
  /// Returns defaults if data is missing or has incorrect types.
  factory WidgetSettings.fromFirestore(DocumentSnapshot doc) {
    // Safely cast document data - could be null if document doesn't exist
    final data = safeCastMap(doc.data());
    if (data == null) {
      throw ArgumentError('Document data is null or invalid format for ${doc.id}');
    }

    // Safely cast nested maps for config objects
    final stripeConfigData = safeCastMap(data['stripe_config']);
    final bankTransferConfigData = safeCastMap(data['bank_transfer_config']);
    final contactOptionsData = safeCastMap(data['contact_options']) ?? {};
    final emailConfigData = safeCastMap(data['email_config']) ?? {};
    final externalCalendarConfigData = safeCastMap(data['external_calendar_config']);
    final taxLegalConfigData = safeCastMap(data['tax_legal_config']) ?? {};
    final themeOptionsData = safeCastMap(data['theme_options']);

    // Safely cast weekendDays list
    final weekendDaysList = safeCastList<int>(data['weekend_days']) ?? const [6, 7];

    return WidgetSettings(
      id: doc.id,
      propertyId: safeCastString(data['property_id']) ?? '',
      ownerId: safeCastString(data['owner_id']),
      widgetMode: WidgetMode.fromString(
        safeCastString(data['widget_mode']) ?? 'booking_instant',
      ),
      // Migration: If global_deposit_percentage doesn't exist, use stripe deposit or 20
      globalDepositPercentage:
          safeCastInt(data['global_deposit_percentage']) ??
          (stripeConfigData != null
              ? (safeCastInt(stripeConfigData['deposit_percentage']) ?? 20)
              : 20),
      stripeConfig: stripeConfigData != null
          ? StripePaymentConfig.fromMap(stripeConfigData)
          : null,
      bankTransferConfig: bankTransferConfigData != null
          ? BankTransferConfig.fromMap(bankTransferConfigData)
          : null,
      allowPayOnArrival: safeCastBool(data['allow_pay_on_arrival']) ?? false,
      requireOwnerApproval: safeCastBool(data['require_owner_approval']) ?? false,
      allowGuestCancellation: safeCastBool(data['allow_guest_cancellation']) ?? true,
      cancellationDeadlineHours: safeCastInt(data['cancellation_deadline_hours']) ?? 48,
      minNights: safeCastInt(data['min_nights']) ?? 1,
      weekendDays: weekendDaysList,
      contactOptions: ContactOptions.fromMap(contactOptionsData),
      emailConfig: EmailNotificationConfig.fromMap(emailConfigData),
      externalCalendarConfig: externalCalendarConfigData != null
          ? ExternalCalendarConfig.fromMap(externalCalendarConfigData)
          : null,
      icalExportEnabled: safeCastBool(data['ical_export_enabled']) ?? false,
      icalExportUrl: safeCastString(data['ical_export_url']),
      icalExportToken: safeCastString(data['ical_export_token']),
      icalExportLastGenerated:
          data['ical_export_last_generated'] is Timestamp
              ? (data['ical_export_last_generated'] as Timestamp).toDate()
              : null,
      taxLegalConfig: TaxLegalConfig.fromMap(taxLegalConfigData),
      themeOptions: themeOptionsData != null
          ? ThemeOptions.fromMap(themeOptionsData)
          : null,
      createdAt: data['created_at'] is Timestamp
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updated_at'] is Timestamp
          ? (data['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'property_id': propertyId,
      'owner_id': ownerId,
      'widget_mode': widgetMode.toStringValue(),
      'global_deposit_percentage': globalDepositPercentage,
      'stripe_config': stripeConfig?.toMap(),
      'bank_transfer_config': bankTransferConfig?.toMap(),
      'allow_pay_on_arrival': allowPayOnArrival,
      'require_owner_approval': requireOwnerApproval,
      'allow_guest_cancellation': allowGuestCancellation,
      'cancellation_deadline_hours': cancellationDeadlineHours,
      'min_nights': minNights,
      'weekend_days': weekendDays,
      'contact_options': contactOptions.toMap(),
      'email_config': emailConfig.toMap(),
      'external_calendar_config': externalCalendarConfig?.toMap(),
      'ical_export_enabled': icalExportEnabled,
      'ical_export_url': icalExportUrl,
      'ical_export_token': icalExportToken,
      'ical_export_last_generated': icalExportLastGenerated != null
          ? Timestamp.fromDate(icalExportLastGenerated!)
          : null,
      'tax_legal_config': taxLegalConfig.toMap(),
      'theme_options': themeOptions?.toMap(),
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

  // ============================================================
  // CONFIG ACCESSORS (Phase 4 Refactoring)
  // ============================================================

  /// Grouped access to booking behavior settings.
  ///
  /// Returns a [BookingBehaviorConfig] constructed from flat fields.
  /// Fields not present in WidgetSettings use defaults from [WidgetConstants].
  ///
  /// ## Example
  /// ```dart
  /// final settings = await widgetSettingsRepo.getSettings(unitId);
  /// if (settings.bookingBehavior.isValidDuration(5)) {
  ///   // 5 nights is valid
  /// }
  /// if (settings.bookingBehavior.canCancelForCheckIn(checkInDate)) {
  ///   // Guest can still cancel
  /// }
  /// ```
  BookingBehaviorConfig get bookingBehavior => BookingBehaviorConfig(
        requireOwnerApproval: requireOwnerApproval,
        allowGuestCancellation: allowGuestCancellation,
        cancellationDeadlineHours: cancellationDeadlineHours,
        minNights: minNights,
        // maxNights not stored in WidgetSettings yet - use default
        weekendDays: weekendDays,
        // minDaysAdvance, maxDaysAdvance not stored - use defaults
      );

  /// Grouped access to iCal export settings.
  ///
  /// Returns an [ICalExportConfig] constructed from flat fields.
  ///
  /// ## Example
  /// ```dart
  /// final settings = await widgetSettingsRepo.getSettings(unitId);
  /// if (settings.icalExport.isConfigured) {
  ///   print('iCal URL: ${settings.icalExport.exportUrl}');
  /// }
  /// if (settings.icalExport.needsRegeneration) {
  ///   // Time to regenerate the feed
  /// }
  /// ```
  ICalExportConfig get icalExport => ICalExportConfig.fromFlatFields(
        enabled: icalExportEnabled,
        exportUrl: icalExportUrl,
        exportToken: icalExportToken,
        lastGenerated: icalExportLastGenerated,
      );

  WidgetSettings copyWith({
    String? id,
    String? propertyId,
    String? ownerId,
    WidgetMode? widgetMode,
    int? globalDepositPercentage,
    StripePaymentConfig? stripeConfig,
    BankTransferConfig? bankTransferConfig,
    bool? allowPayOnArrival,
    bool? requireOwnerApproval,
    bool? allowGuestCancellation,
    int? cancellationDeadlineHours,
    int? minNights,
    List<int>? weekendDays,
    ContactOptions? contactOptions,
    EmailNotificationConfig? emailConfig,
    ExternalCalendarConfig? externalCalendarConfig,
    bool? icalExportEnabled,
    String? icalExportUrl,
    String? icalExportToken,
    DateTime? icalExportLastGenerated,
    TaxLegalConfig? taxLegalConfig,
    ThemeOptions? themeOptions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WidgetSettings(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      ownerId: ownerId ?? this.ownerId,
      widgetMode: widgetMode ?? this.widgetMode,
      globalDepositPercentage:
          globalDepositPercentage ?? this.globalDepositPercentage,
      stripeConfig: stripeConfig ?? this.stripeConfig,
      bankTransferConfig: bankTransferConfig ?? this.bankTransferConfig,
      allowPayOnArrival: allowPayOnArrival ?? this.allowPayOnArrival,
      requireOwnerApproval: requireOwnerApproval ?? this.requireOwnerApproval,
      allowGuestCancellation:
          allowGuestCancellation ?? this.allowGuestCancellation,
      cancellationDeadlineHours:
          cancellationDeadlineHours ?? this.cancellationDeadlineHours,
      minNights: minNights ?? this.minNights,
      weekendDays: weekendDays ?? this.weekendDays,
      contactOptions: contactOptions ?? this.contactOptions,
      emailConfig: emailConfig ?? this.emailConfig,
      externalCalendarConfig:
          externalCalendarConfig ?? this.externalCalendarConfig,
      icalExportEnabled: icalExportEnabled ?? this.icalExportEnabled,
      icalExportUrl: icalExportUrl ?? this.icalExportUrl,
      icalExportToken: icalExportToken ?? this.icalExportToken,
      icalExportLastGenerated:
          icalExportLastGenerated ?? this.icalExportLastGenerated,
      taxLegalConfig: taxLegalConfig ?? this.taxLegalConfig,
      themeOptions: themeOptions ?? this.themeOptions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================
// EXTRACTED CONFIGS - See settings/ folder
// ============================================================
// The following configs have been extracted to dedicated files:
//
// Payment:
// - StripePaymentConfig → settings/payment/stripe_payment_config.dart
// - BankTransferConfig → settings/payment/bank_transfer_config.dart
//
// Contact & Communication:
// - ContactOptions → settings/contact_options.dart
// - EmailNotificationConfig → settings/email_notification_config.dart
//
// Legal & Compliance:
// - TaxLegalConfig → settings/tax_legal_config.dart
//
// All are re-exported via settings/settings.dart for backward compatibility.
// ============================================================

/// Theme customization options
class ThemeOptions {
  final String? primaryColor; // Hex color
  final String? accentColor;
  final bool showBranding; // Show "Powered by Rab Booking" badge
  final String? customTitle; // Custom title text to display above calendar
  final String? customLogoUrl;
  final String? themeMode; // 'light', 'dark', 'system' (default: 'system')

  const ThemeOptions({
    this.primaryColor,
    this.accentColor,
    this.showBranding = true,
    this.customTitle,
    this.customLogoUrl,
    this.themeMode = 'system',
  });

  factory ThemeOptions.fromMap(Map<String, dynamic> map) {
    return ThemeOptions(
      primaryColor: map['primary_color'],
      accentColor: map['accent_color'],
      showBranding: map['show_branding'] ?? true,
      customTitle: map['custom_title'],
      customLogoUrl: map['custom_logo_url'],
      themeMode: map['theme_mode'] ?? 'system',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primary_color': primaryColor,
      'accent_color': accentColor,
      'show_branding': showBranding,
      'custom_title': customTitle,
      'custom_logo_url': customLogoUrl,
      'theme_mode': themeMode,
    };
  }

  ThemeOptions copyWith({
    String? primaryColor,
    String? accentColor,
    bool? showBranding,
    String? customTitle,
    String? customLogoUrl,
    String? themeMode,
  }) {
    return ThemeOptions(
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      showBranding: showBranding ?? this.showBranding,
      customTitle: customTitle ?? this.customTitle,
      customLogoUrl: customLogoUrl ?? this.customLogoUrl,
      themeMode: themeMode ?? this.themeMode,
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
          ? DateTimeParser.tryParse(map['last_synced_at'] as String?)
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
    return enabled &&
        ((syncBookingCom && bookingComAccessToken != null) ||
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
      bookingComAccessToken:
          bookingComAccessToken ?? this.bookingComAccessToken,
      syncAirbnb: syncAirbnb ?? this.syncAirbnb,
      airbnbAccountId: airbnbAccountId ?? this.airbnbAccountId,
      airbnbAccessToken: airbnbAccessToken ?? this.airbnbAccessToken,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

