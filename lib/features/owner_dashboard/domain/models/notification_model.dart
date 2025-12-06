import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification model for owner app notifications
class NotificationModel {
  final String id;
  final String ownerId;
  final String type; // 'booking_created', 'booking_updated', 'booking_cancelled', 'payment_received', 'system'
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? bookingId; // Optional link to booking
  final Map<String, dynamic>? metadata; // Additional data

  // Localization keys (new fields for i18n support)
  final String? titleKey;
  final String? messageKey;

  const NotificationModel({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.bookingId,
    this.metadata,
    this.titleKey,
    this.messageKey,
  });

  /// Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      type: data['type'] ?? 'system',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      bookingId: data['bookingId'],
      metadata: data['metadata'],
      titleKey: data['titleKey'],
      messageKey: data['messageKey'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'type': type,
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

  /// Copy with modifications
  NotificationModel copyWith({
    String? id,
    String? ownerId,
    String? type,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? bookingId,
    Map<String, dynamic>? metadata,
    String? titleKey,
    String? messageKey,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      bookingId: bookingId ?? this.bookingId,
      metadata: metadata ?? this.metadata,
      titleKey: titleKey ?? this.titleKey,
      messageKey: messageKey ?? this.messageKey,
    );
  }

  /// Get icon for notification type
  String get iconName {
    switch (type) {
      case 'booking_created':
        return 'event_available';
      case 'booking_updated':
        return 'edit_calendar';
      case 'booking_cancelled':
        return 'event_busy';
      case 'payment_received':
        return 'payments';
      case 'system':
        return 'notifications';
      default:
        return 'notifications';
    }
  }
}
