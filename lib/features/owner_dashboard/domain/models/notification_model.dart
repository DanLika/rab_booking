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

  /// Get relative time string (e.g., "2 hours ago")
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Upravo sada';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minut' : 'minuta'} prije';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'sat' : hours < 5 ? 'sata' : 'sati'} prije';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'dan' : 'dana'} prije';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'sedmica' : weeks < 5 ? 'sedmice' : 'sedmica'} prije';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'mjesec' : months < 5 ? 'mjeseca' : 'mjeseci'} prije';
    }
  }
}
