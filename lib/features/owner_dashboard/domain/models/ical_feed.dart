import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ical_feed.freezed.dart';
part 'ical_feed.g.dart';

/// Platform source for iCal feeds
enum IcalPlatform {
  @JsonValue('booking_com')
  bookingCom,
  @JsonValue('airbnb')
  airbnb,
  @JsonValue('other')
  other;

  String get displayName => switch (this) {
    IcalPlatform.bookingCom => 'Booking.com',
    IcalPlatform.airbnb => 'Airbnb',
    IcalPlatform.other => 'Druga platforma',
  };

  /// Parse from Firestore string value
  static IcalPlatform fromString(String? value) => switch (value) {
    'booking_com' => IcalPlatform.bookingCom,
    'airbnb' => IcalPlatform.airbnb,
    _ => IcalPlatform.other,
  };

  /// Convert to Firestore string value
  String toFirestoreValue() => switch (this) {
    IcalPlatform.bookingCom => 'booking_com',
    IcalPlatform.airbnb => 'airbnb',
    IcalPlatform.other => 'other',
  };

  /// Detect platform from iCal URL
  ///
  /// Returns the detected platform or null if URL doesn't match any known pattern.
  /// Used for URL validation to warn users if URL doesn't match selected platform.
  static IcalPlatform? detectFromUrl(String url) {
    final lowerUrl = url.toLowerCase();

    // Booking.com patterns:
    // - https://ical.booking.com/...
    // - https://admin.booking.com/...
    if (lowerUrl.contains('booking.com')) {
      return IcalPlatform.bookingCom;
    }

    // Airbnb patterns:
    // - https://www.airbnb.com/calendar/ical/...
    // - https://airbnb.com/...
    if (lowerUrl.contains('airbnb.com') || lowerUrl.contains('airbnb.')) {
      return IcalPlatform.airbnb;
    }

    // Google Calendar patterns (informational - treated as "other"):
    // - https://calendar.google.com/...
    if (lowerUrl.contains('calendar.google.com') ||
        lowerUrl.contains('googleapis.com')) {
      return IcalPlatform.other;
    }

    // Unknown URL - could be any platform
    return null;
  }

  /// Check if URL matches this platform
  bool matchesUrl(String url) {
    final detected = detectFromUrl(url);
    // If we can't detect the platform, don't warn (could be custom URL)
    if (detected == null) return true;
    // "other" platform matches anything
    if (this == IcalPlatform.other) return true;
    return detected == this;
  }
}

/// Status for iCal feed sync
enum IcalStatus {
  @JsonValue('active')
  active,
  @JsonValue('error')
  error,
  @JsonValue('paused')
  paused;

  String get colorName => switch (this) {
    IcalStatus.active => 'green',
    IcalStatus.error => 'red',
    IcalStatus.paused => 'orange',
  };

  /// Parse from Firestore string value
  static IcalStatus fromString(String? value) => switch (value) {
    'active' => IcalStatus.active,
    'error' => IcalStatus.error,
    'paused' => IcalStatus.paused,
    _ => IcalStatus.active,
  };

  /// Convert to Firestore string value
  String toFirestoreValue() => switch (this) {
    IcalStatus.active => 'active',
    IcalStatus.error => 'error',
    IcalStatus.paused => 'paused',
  };
}

/// iCal feed configuration for syncing external calendar sources
/// Path: properties/{propertyId}/ical_feeds/{feedId}
@freezed
class IcalFeed with _$IcalFeed {
  const IcalFeed._();

  const factory IcalFeed({
    required String id,
    required String unitId,
    required String propertyId,
    required IcalPlatform platform,
    required String icalUrl,

    /// Custom platform name when platform is "other" (e.g., "Adriagate", "Smoobu")
    String? customPlatformName,

    /// Whether to import events from this feed (default: true)
    /// Set to false for platforms that re-export imported data (e.g., Holiday-Home)
    /// When false, the feed is export-only: our bookings are visible to them,
    /// but we don't import their events (prevents echo loops)
    @Default(true) bool importEnabled,
    @Default(60) int syncIntervalMinutes,
    DateTime? lastSynced,
    @Default(IcalStatus.active) IcalStatus status,
    String? lastError,
    @Default(0) int syncCount,
    @Default(0) int eventCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _IcalFeed;

  factory IcalFeed.fromJson(Map<String, dynamic> json) =>
      _$IcalFeedFromJson(json);

  /// Create from Firestore document
  factory IcalFeed.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return IcalFeed(
      id: doc.id,
      unitId: data['unit_id'] as String? ?? '',
      propertyId: data['property_id'] as String? ?? '',
      platform: IcalPlatform.fromString(data['platform'] as String?),
      icalUrl: data['ical_url'] as String? ?? '',
      customPlatformName: data['custom_platform_name'] as String?,
      importEnabled: data['import_enabled'] as bool? ?? true,
      syncIntervalMinutes: data['sync_interval_minutes'] as int? ?? 60,
      lastSynced: (data['last_synced'] as Timestamp?)?.toDate(),
      status: IcalStatus.fromString(data['status'] as String?),
      lastError: data['last_error'] as String?,
      syncCount: data['sync_count'] as int? ?? 0,
      eventCount: data['event_count'] as int? ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'unit_id': unitId,
      'property_id': propertyId,
      'platform': platform.toFirestoreValue(),
      'ical_url': icalUrl,
      'custom_platform_name': customPlatformName,
      'import_enabled': importEnabled,
      'sync_interval_minutes': syncIntervalMinutes,
      'last_synced': lastSynced != null
          ? Timestamp.fromDate(lastSynced!)
          : null,
      'status': status.toFirestoreValue(),
      'last_error': lastError,
      'sync_count': syncCount,
      'event_count': eventCount,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Check if feed is active
  bool get isActive => status == IcalStatus.active;

  /// Check if feed has error
  bool get hasError => status == IcalStatus.error;

  /// Get display name for the platform
  /// Uses customPlatformName if platform is "other" and custom name is set
  String get platformDisplayName {
    if (platform == IcalPlatform.other &&
        customPlatformName != null &&
        customPlatformName!.isNotEmpty) {
      return customPlatformName!;
    }
    return platform.displayName;
  }

  /// Get time since last sync
  String getTimeSinceLastSync() {
    if (lastSynced == null) return 'Nikada';

    final now = DateTime.now();
    final difference = now.difference(lastSynced!);

    if (difference.inMinutes < 1) {
      return 'Upravo sada';
    } else if (difference.inMinutes < 60) {
      return 'Prije ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Prije ${difference.inHours} h';
    } else {
      return 'Prije ${difference.inDays} dana';
    }
  }
}

/// Echo detection status for imported iCal events
enum IcalEventStatus {
  @JsonValue('active')
  active,
  @JsonValue('needs_review')
  needsReview,
  @JsonValue('confirmed_echo')
  confirmedEcho,
  @JsonValue('confirmed_overbooking')
  confirmedOverbooking;

  /// Parse from Firestore string value
  static IcalEventStatus fromString(String? value) => switch (value) {
    'active' => IcalEventStatus.active,
    'needs_review' => IcalEventStatus.needsReview,
    'confirmed_echo' => IcalEventStatus.confirmedEcho,
    'confirmed_overbooking' => IcalEventStatus.confirmedOverbooking,
    _ => IcalEventStatus.active,
  };

  /// Convert to Firestore string value
  String toFirestoreValue() => switch (this) {
    IcalEventStatus.active => 'active',
    IcalEventStatus.needsReview => 'needs_review',
    IcalEventStatus.confirmedEcho => 'confirmed_echo',
    IcalEventStatus.confirmedOverbooking => 'confirmed_overbooking',
  };
}

/// iCal event imported from external calendar
/// Path: properties/{propertyId}/ical_events/{eventId}
@freezed
class IcalEvent with _$IcalEvent {
  const IcalEvent._();

  const factory IcalEvent({
    required String id,
    required String unitId,
    required String feedId,
    required DateTime startDate,
    required DateTime endDate,
    required String guestName,
    required String source,
    required String externalId,
    String? description,

    // Echo detection fields
    @Default(IcalEventStatus.active) IcalEventStatus status,
    double? echoConfidence,
    String? echoReason,

    /// Points to original iCal event if this is an echo
    String? parentEventId,

    /// Points to native booking if this is an echo
    String? parentBookingId,

    /// When the owner reviewed this event
    DateTime? reviewedAt,

    /// Who reviewed this event (owner UID)
    String? reviewedBy,

    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _IcalEvent;

  factory IcalEvent.fromJson(Map<String, dynamic> json) =>
      _$IcalEventFromJson(json);

  /// Create from Firestore document
  factory IcalEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return IcalEvent(
      id: doc.id,
      unitId: data['unit_id'] as String? ?? '',
      feedId: data['feed_id'] as String? ?? '',
      startDate: (data['start_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate:
          (data['end_date'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 1)),
      guestName: data['guest_name'] as String? ?? 'Gost',
      source: data['source'] as String? ?? 'other',
      externalId: data['external_id'] as String? ?? '',
      description: data['description'] as String?,
      // Echo detection fields
      status: IcalEventStatus.fromString(data['status'] as String?),
      echoConfidence: (data['echo_confidence'] as num?)?.toDouble(),
      echoReason: data['echo_reason'] as String?,
      parentEventId: data['parent_event_id'] as String?,
      parentBookingId: data['parent_booking_id'] as String?,
      reviewedAt: (data['reviewed_at'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewed_by'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'unit_id': unitId,
      'feed_id': feedId,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'guest_name': guestName,
      'source': source,
      'external_id': externalId,
      'description': description,
      // Echo detection fields
      'status': status.toFirestoreValue(),
      if (echoConfidence != null) 'echo_confidence': echoConfidence,
      if (echoReason != null) 'echo_reason': echoReason,
      if (parentEventId != null) 'parent_event_id': parentEventId,
      if (parentBookingId != null) 'parent_booking_id': parentBookingId,
      if (reviewedAt != null) 'reviewed_at': Timestamp.fromDate(reviewedAt!),
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get number of nights
  int get numberOfNights => endDate.difference(startDate).inDays;

  /// Check if this event overlaps with date range
  bool overlaps(DateTime checkIn, DateTime checkOut) {
    return startDate.isBefore(checkOut) && endDate.isAfter(checkIn);
  }

  /// Whether this event needs owner review
  bool get needsReview => status == IcalEventStatus.needsReview;

  /// Whether this event was confirmed as an echo (should not block dates)
  bool get isConfirmedEcho => status == IcalEventStatus.confirmedEcho;

  /// Whether this event blocks dates (everything except confirmed echoes)
  bool get blocksDates => status != IcalEventStatus.confirmedEcho;
}
