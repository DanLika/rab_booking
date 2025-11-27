import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/widget_constants.dart';

/// iCal export configuration.
///
/// Groups settings related to iCal calendar export:
/// - Export enable/disable toggle
/// - Generated iCal URL
/// - Security token for public feed access
/// - Last generation timestamp
///
/// ## Usage
/// ```dart
/// final config = ICalExportConfig(
///   enabled: true,
///   exportUrl: 'https://example.com/ical/abc123.ics',
///   exportToken: 'secure-token-here',
/// );
///
/// if (config.isConfigured) {
///   print('iCal URL: ${config.exportUrl}');
/// }
/// ```
class ICalExportConfig {
  /// Master toggle for iCal export feature.
  final bool enabled;

  /// Generated iCal URL for external calendar subscriptions.
  /// Format: https://domain.com/api/ical/{token}.ics
  final String? exportUrl;

  /// Security token for public feed access.
  /// Used to authenticate iCal feed requests without user login.
  final String? exportToken;

  /// Timestamp when the iCal feed was last generated/updated.
  final DateTime? lastGenerated;

  /// Include blocked dates in the iCal feed.
  final bool includeBlockedDates;

  /// Include pricing info in event descriptions.
  final bool includePricing;

  /// Custom feed title (appears in calendar apps).
  final String? feedTitle;

  const ICalExportConfig({
    this.enabled = false,
    this.exportUrl,
    this.exportToken,
    this.lastGenerated,
    this.includeBlockedDates = true,
    this.includePricing = false,
    this.feedTitle,
  });

  /// Create from Firestore map data.
  ///
  /// Supports both nested format (new) and flat format (legacy).
  factory ICalExportConfig.fromMap(Map<String, dynamic> map) {
    return ICalExportConfig(
      enabled: map['enabled'] ?? map['ical_export_enabled'] ?? false,
      exportUrl: map['export_url'] ?? map['ical_export_url'],
      exportToken: map['export_token'] ?? map['ical_export_token'],
      lastGenerated: _parseDateTime(
        map['last_generated'] ?? map['ical_export_last_generated'],
      ),
      includeBlockedDates: map['include_blocked_dates'] ?? true,
      includePricing: map['include_pricing'] ?? false,
      feedTitle: map['feed_title'],
    );
  }

  /// Create from flat WidgetSettings fields (legacy format).
  factory ICalExportConfig.fromFlatFields({
    required bool enabled,
    String? exportUrl,
    String? exportToken,
    DateTime? lastGenerated,
  }) {
    return ICalExportConfig(
      enabled: enabled,
      exportUrl: exportUrl,
      exportToken: exportToken,
      lastGenerated: lastGenerated,
    );
  }

  /// Convert to Firestore map (nested format).
  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'export_url': exportUrl,
      'export_token': exportToken,
      'last_generated': lastGenerated != null
          ? Timestamp.fromDate(lastGenerated!)
          : null,
      'include_blocked_dates': includeBlockedDates,
      'include_pricing': includePricing,
      'feed_title': feedTitle,
    };
  }

  /// Convert to flat fields for backward compatibility.
  Map<String, dynamic> toFlatFields() {
    return {
      'ical_export_enabled': enabled,
      'ical_export_url': exportUrl,
      'ical_export_token': exportToken,
      'ical_export_last_generated': lastGenerated != null
          ? Timestamp.fromDate(lastGenerated!)
          : null,
    };
  }

  /// Check if iCal export is fully configured and ready to use.
  bool get isConfigured {
    return enabled && exportUrl != null && exportToken != null;
  }

  /// Check if the feed needs regeneration (older than sync interval).
  bool get needsRegeneration {
    if (!enabled || lastGenerated == null) return true;
    final hoursSinceGeneration =
        DateTime.now().difference(lastGenerated!).inHours;
    return hoursSinceGeneration >= WidgetConstants.icalSyncIntervalHours;
  }

  /// Get a display-friendly title for the feed.
  String getDisplayTitle(String unitName) {
    return feedTitle ?? '$unitName - Availability Calendar';
  }

  ICalExportConfig copyWith({
    bool? enabled,
    String? exportUrl,
    String? exportToken,
    DateTime? lastGenerated,
    bool? includeBlockedDates,
    bool? includePricing,
    String? feedTitle,
  }) {
    return ICalExportConfig(
      enabled: enabled ?? this.enabled,
      exportUrl: exportUrl ?? this.exportUrl,
      exportToken: exportToken ?? this.exportToken,
      lastGenerated: lastGenerated ?? this.lastGenerated,
      includeBlockedDates: includeBlockedDates ?? this.includeBlockedDates,
      includePricing: includePricing ?? this.includePricing,
      feedTitle: feedTitle ?? this.feedTitle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ICalExportConfig) return false;
    return enabled == other.enabled &&
        exportUrl == other.exportUrl &&
        exportToken == other.exportToken &&
        lastGenerated == other.lastGenerated &&
        includeBlockedDates == other.includeBlockedDates &&
        includePricing == other.includePricing &&
        feedTitle == other.feedTitle;
  }

  @override
  int get hashCode => Object.hash(
        enabled,
        exportUrl,
        exportToken,
        lastGenerated,
        includeBlockedDates,
        includePricing,
        feedTitle,
      );

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
