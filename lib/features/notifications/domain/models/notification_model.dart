import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

/// Notification type enum
enum NotificationType {
  @JsonValue('booking_confirmed')
  bookingConfirmed,

  @JsonValue('booking_cancelled')
  bookingCancelled,

  @JsonValue('booking_reminder')
  bookingReminder,

  @JsonValue('review_received')
  reviewReceived,

  @JsonValue('review_request')
  reviewRequest,

  @JsonValue('payment_success')
  paymentSuccess,

  @JsonValue('payment_failed')
  paymentFailed,

  @JsonValue('message_received')
  messageReceived,

  @JsonValue('property_approved')
  propertyApproved,

  @JsonValue('property_rejected')
  propertyRejected,

  @JsonValue('system_alert')
  systemAlert;

  /// Get display icon for notification type
  String get iconName {
    switch (this) {
      case NotificationType.bookingConfirmed:
        return 'check_circle';
      case NotificationType.bookingCancelled:
        return 'cancel';
      case NotificationType.bookingReminder:
        return 'notifications_active';
      case NotificationType.reviewReceived:
        return 'star';
      case NotificationType.reviewRequest:
        return 'rate_review';
      case NotificationType.paymentSuccess:
        return 'payment';
      case NotificationType.paymentFailed:
        return 'error';
      case NotificationType.messageReceived:
        return 'message';
      case NotificationType.propertyApproved:
        return 'verified';
      case NotificationType.propertyRejected:
        return 'close';
      case NotificationType.systemAlert:
        return 'info';
    }
  }

  /// Get display color for notification type (hex string)
  String get colorHex {
    switch (this) {
      case NotificationType.bookingConfirmed:
      case NotificationType.paymentSuccess:
      case NotificationType.propertyApproved:
        return '#4CAF50'; // Green
      case NotificationType.bookingCancelled:
      case NotificationType.paymentFailed:
      case NotificationType.propertyRejected:
        return '#F44336'; // Red
      case NotificationType.bookingReminder:
      case NotificationType.reviewRequest:
        return '#FF9800'; // Orange
      case NotificationType.reviewReceived:
        return '#FFC107'; // Amber
      case NotificationType.messageReceived:
        return '#2196F3'; // Blue
      case NotificationType.systemAlert:
        return '#9E9E9E'; // Grey
    }
  }
}

/// Related entity type enum
enum RelatedEntityType {
  @JsonValue('booking')
  booking,

  @JsonValue('property')
  property,

  @JsonValue('review')
  review,

  @JsonValue('message')
  message,

  @JsonValue('payment')
  payment;
}

/// Notification model
@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    RelatedEntityType? relatedEntityType,
    String? relatedEntityId,
    String? actionUrl,
    @Default({}) Map<String, dynamic> metadata,
    @Default(false) bool isRead,
    DateTime? readAt,
    required DateTime createdAt,
    DateTime? expiresAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  const NotificationModel._();

  /// Check if notification is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get time ago string (e.g., "2 hours ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    }
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'related_entity_type': relatedEntityType?.name,
      'related_entity_id': relatedEntityId,
      'action_url': actionUrl,
      'metadata': metadata,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  /// Create from Supabase JSON
  static NotificationModel fromSupabaseJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: _parseNotificationType(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      relatedEntityType: json['related_entity_type'] != null
          ? _parseRelatedEntityType(json['related_entity_type'] as String)
          : null,
      relatedEntityId: json['related_entity_id'] as String?,
      actionUrl: json['action_url'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      isRead: json['is_read'] as bool? ?? false,
      readAt:
          json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  /// Parse notification type from string
  static NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'booking_confirmed':
        return NotificationType.bookingConfirmed;
      case 'booking_cancelled':
        return NotificationType.bookingCancelled;
      case 'booking_reminder':
        return NotificationType.bookingReminder;
      case 'review_received':
        return NotificationType.reviewReceived;
      case 'review_request':
        return NotificationType.reviewRequest;
      case 'payment_success':
        return NotificationType.paymentSuccess;
      case 'payment_failed':
        return NotificationType.paymentFailed;
      case 'message_received':
        return NotificationType.messageReceived;
      case 'property_approved':
        return NotificationType.propertyApproved;
      case 'property_rejected':
        return NotificationType.propertyRejected;
      case 'system_alert':
      default:
        return NotificationType.systemAlert;
    }
  }

  /// Parse related entity type from string
  static RelatedEntityType _parseRelatedEntityType(String type) {
    switch (type) {
      case 'booking':
        return RelatedEntityType.booking;
      case 'property':
        return RelatedEntityType.property;
      case 'review':
        return RelatedEntityType.review;
      case 'message':
        return RelatedEntityType.message;
      case 'payment':
        return RelatedEntityType.payment;
      default:
        return RelatedEntityType.booking;
    }
  }
}
