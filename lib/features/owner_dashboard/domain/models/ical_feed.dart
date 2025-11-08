import 'package:cloud_firestore/cloud_firestore.dart';

/// iCal feed configuration for syncing external calendar sources
/// Path: ical_feeds/{feedId}
class IcalFeed {
  final String id;
  final String unitId;
  final String propertyId;
  final String platform; // 'booking_com', 'airbnb', 'expedia', 'other'
  final String icalUrl;
  final int syncIntervalMinutes; // How often to sync (default: 60 min)
  final DateTime? lastSynced;
  final String status; // 'active', 'error', 'paused'
  final String? lastError;
  final int syncCount; // Total number of syncs performed
  final int eventCount; // Current number of events from this feed
  final DateTime createdAt;
  final DateTime updatedAt;

  const IcalFeed({
    required this.id,
    required this.unitId,
    required this.propertyId,
    required this.platform,
    required this.icalUrl,
    this.syncIntervalMinutes = 60,
    this.lastSynced,
    this.status = 'active',
    this.lastError,
    this.syncCount = 0,
    this.eventCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IcalFeed.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return IcalFeed(
      id: doc.id,
      unitId: data['unit_id'] ?? '',
      propertyId: data['property_id'] ?? '',
      platform: data['platform'] ?? 'other',
      icalUrl: data['ical_url'] ?? '',
      syncIntervalMinutes: data['sync_interval_minutes'] ?? 60,
      lastSynced: (data['last_synced'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'active',
      lastError: data['last_error'],
      syncCount: data['sync_count'] ?? 0,
      eventCount: data['event_count'] ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'unit_id': unitId,
      'property_id': propertyId,
      'platform': platform,
      'ical_url': icalUrl,
      'sync_interval_minutes': syncIntervalMinutes,
      'last_synced': lastSynced != null ? Timestamp.fromDate(lastSynced!) : null,
      'status': status,
      'last_error': lastError,
      'sync_count': syncCount,
      'event_count': eventCount,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get platform display name
  String get platformDisplayName {
    switch (platform.toLowerCase()) {
      case 'booking_com':
        return 'Booking.com';
      case 'airbnb':
        return 'Airbnb';
      case 'expedia':
        return 'Expedia';
      case 'vrbo':
        return 'VRBO';
      case 'homeaway':
        return 'HomeAway';
      default:
        return 'Drugi';
    }
  }

  /// Get status display color
  String get statusColor {
    switch (status) {
      case 'active':
        return 'green';
      case 'error':
        return 'red';
      case 'paused':
        return 'orange';
      default:
        return 'grey';
    }
  }

  /// Check if feed is active
  bool get isActive => status == 'active';

  /// Check if feed has error
  bool get hasError => status == 'error';

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

  IcalFeed copyWith({
    String? id,
    String? unitId,
    String? propertyId,
    String? platform,
    String? icalUrl,
    int? syncIntervalMinutes,
    DateTime? lastSynced,
    String? status,
    String? lastError,
    int? syncCount,
    int? eventCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IcalFeed(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      propertyId: propertyId ?? this.propertyId,
      platform: platform ?? this.platform,
      icalUrl: icalUrl ?? this.icalUrl,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      lastSynced: lastSynced ?? this.lastSynced,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      syncCount: syncCount ?? this.syncCount,
      eventCount: eventCount ?? this.eventCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// iCal event imported from external calendar
/// Path: ical_events/{eventId}
class IcalEvent {
  final String id;
  final String unitId;
  final String feedId; // Reference to ical_feeds
  final DateTime startDate;
  final DateTime endDate;
  final String guestName;
  final String source; // 'booking_com', 'airbnb', etc.
  final String externalId; // UID from iCal file
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IcalEvent({
    required this.id,
    required this.unitId,
    required this.feedId,
    required this.startDate,
    required this.endDate,
    required this.guestName,
    required this.source,
    required this.externalId,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IcalEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return IcalEvent(
      id: doc.id,
      unitId: data['unit_id'] ?? '',
      feedId: data['feed_id'] ?? '',
      startDate: (data['start_date'] as Timestamp).toDate(),
      endDate: (data['end_date'] as Timestamp).toDate(),
      guestName: data['guest_name'] ?? 'Gost',
      source: data['source'] ?? 'other',
      externalId: data['external_id'] ?? '',
      description: data['description'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

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

  IcalEvent copyWith({
    String? id,
    String? unitId,
    String? feedId,
    DateTime? startDate,
    DateTime? endDate,
    String? guestName,
    String? source,
    String? externalId,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IcalEvent(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      feedId: feedId ?? this.feedId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      guestName: guestName ?? this.guestName,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
