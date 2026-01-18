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
}
