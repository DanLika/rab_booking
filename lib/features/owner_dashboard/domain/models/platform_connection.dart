import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'platform_connection.freezed.dart';
part 'platform_connection.g.dart';

/// Platform type for API connections
enum PlatformType {
  @JsonValue('booking_com')
  bookingCom,
  @JsonValue('airbnb')
  airbnb;

  String get displayName => switch (this) {
    PlatformType.bookingCom => 'Booking.com',
    PlatformType.airbnb => 'Airbnb',
  };

  /// Parse from Firestore string value
  static PlatformType fromString(String? value) => switch (value) {
    'booking_com' => PlatformType.bookingCom,
    'airbnb' => PlatformType.airbnb,
    _ => PlatformType.bookingCom,
  };

  /// Convert to Firestore string value
  String toFirestoreValue() => switch (this) {
    PlatformType.bookingCom => 'booking_com',
    PlatformType.airbnb => 'airbnb',
  };
}

/// Connection status
enum ConnectionStatus {
  @JsonValue('active')
  active,
  @JsonValue('expired')
  expired,
  @JsonValue('error')
  error,
  @JsonValue('pending')
  pending;

  String get colorName => switch (this) {
    ConnectionStatus.active => 'green',
    ConnectionStatus.expired => 'orange',
    ConnectionStatus.error => 'red',
    ConnectionStatus.pending => 'blue',
  };

  /// Parse from Firestore string value
  static ConnectionStatus fromString(String? value) => switch (value) {
    'active' => ConnectionStatus.active,
    'expired' => ConnectionStatus.expired,
    'error' => ConnectionStatus.error,
    'pending' => ConnectionStatus.pending,
    _ => ConnectionStatus.pending,
  };

  /// Convert to Firestore string value
  String toFirestoreValue() => switch (this) {
    ConnectionStatus.active => 'active',
    ConnectionStatus.expired => 'expired',
    ConnectionStatus.error => 'error',
    ConnectionStatus.pending => 'pending',
  };
}

/// Platform connection model for API integrations
/// Path: platform_connections/{connectionId}
@freezed
class PlatformConnection with _$PlatformConnection {
  const PlatformConnection._();

  const factory PlatformConnection({
    required String id,
    required String ownerId,
    required PlatformType platform,
    required String unitId,
    required String externalPropertyId,
    required String externalUnitId,
    required DateTime expiresAt,
    @Default(ConnectionStatus.pending) ConnectionStatus status,
    String? lastError,
    DateTime? lastSyncedAt,
    int? lastSyncEventCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PlatformConnection;

  factory PlatformConnection.fromJson(Map<String, dynamic> json) =>
      _$PlatformConnectionFromJson(json);

  /// Create from Firestore document
  factory PlatformConnection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PlatformConnection(
      id: doc.id,
      ownerId: data['owner_id'] as String? ?? '',
      platform: PlatformType.fromString(data['platform'] as String?),
      unitId: data['unit_id'] as String? ?? '',
      externalPropertyId: data['external_property_id'] as String? ?? '',
      externalUnitId: data['external_unit_id'] as String? ?? '',
      expiresAt: (data['expires_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ConnectionStatus.fromString(data['status'] as String?),
      lastError: data['last_error'] as String?,
      lastSyncedAt: (data['last_synced_at'] as Timestamp?)?.toDate(),
      lastSyncEventCount: data['last_sync_event_count'] as int?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'owner_id': ownerId,
      'platform': platform.toFirestoreValue(),
      'unit_id': unitId,
      'external_property_id': externalPropertyId,
      'external_unit_id': externalUnitId,
      'expires_at': Timestamp.fromDate(expiresAt),
      'status': status.toFirestoreValue(),
      'last_error': lastError,
      'last_synced_at': lastSyncedAt != null
          ? Timestamp.fromDate(lastSyncedAt!)
          : null,
      'last_sync_event_count': lastSyncEventCount,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Check if connection is active
  bool get isActive => status == ConnectionStatus.active;

  /// Check if connection is expired
  bool get isExpired =>
      status == ConnectionStatus.expired ||
      expiresAt.isBefore(DateTime.now());

  /// Check if connection has error
  bool get hasError => status == ConnectionStatus.error;

  /// Get time since last sync
  String getTimeSinceLastSync() {
    if (lastSyncedAt == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastSyncedAt!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} h ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

