import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

/// Notification type enum for owner app notifications
enum NotificationType {
  @JsonValue('booking_created')
  bookingCreated,
  @JsonValue('booking_updated')
  bookingUpdated,
  @JsonValue('booking_cancelled')
  bookingCancelled,
  @JsonValue('payment_received')
  paymentReceived,
  @JsonValue('system')
  system;

  /// Material icon name for this notification type
  String get iconName => switch (this) {
    NotificationType.bookingCreated => 'event_available',
    NotificationType.bookingUpdated => 'edit_calendar',
    NotificationType.bookingCancelled => 'event_busy',
    NotificationType.paymentReceived => 'payments',
    NotificationType.system => 'notifications',
  };

  /// Parse from Firestore string value
  static NotificationType fromString(String? value) => switch (value) {
    'booking_created' => NotificationType.bookingCreated,
    'booking_updated' => NotificationType.bookingUpdated,
    'booking_cancelled' => NotificationType.bookingCancelled,
    'payment_received' => NotificationType.paymentReceived,
    _ => NotificationType.system,
  };

  /// Convert to Firestore string value
  String toFirestoreValue() => switch (this) {
    NotificationType.bookingCreated => 'booking_created',
    NotificationType.bookingUpdated => 'booking_updated',
    NotificationType.bookingCancelled => 'booking_cancelled',
    NotificationType.paymentReceived => 'payment_received',
    NotificationType.system => 'system',
  };
}

/// Notification model for owner app notifications
@freezed
class NotificationModel with _$NotificationModel {
  const NotificationModel._();

  const factory NotificationModel({
    required String id,
    required String ownerId,
    required NotificationType type,
    required String title,
    required String message,
    required DateTime timestamp,
    @Default(false) bool isRead,
    String? bookingId,
    Map<String, dynamic>? metadata,
    // Localization keys (for i18n support)
    String? titleKey,
    String? messageKey,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  /// Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      type: NotificationType.fromString(data['type'] as String?),
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      bookingId: data['bookingId'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      titleKey: data['titleKey'] as String?,
      messageKey: data['messageKey'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'type': type.toFirestoreValue(),
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      if (bookingId != null) 'bookingId': bookingId,
      if (metadata != null) 'metadata': metadata,
      if (titleKey != null) 'titleKey': titleKey,
      if (messageKey != null) 'messageKey': messageKey,
    };
  }
}
