import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/owner_dashboard/domain/models/notification_model.dart';
import '../exceptions/app_exceptions.dart';

/// Service for managing owner notifications.
///
/// Handles creating, reading, updating, and deleting notifications
/// stored in Firestore. Supports batch operations with Firestore's
/// 500 operation limit.
///
/// Usage:
/// ```dart
/// final service = NotificationService();
///
/// // Create a booking notification
/// await service.createBookingNotification(
///   ownerId: 'owner123',
///   bookingId: 'booking456',
///   guestName: 'John Doe',
///   action: 'created',
/// );
///
/// // Stream notifications
/// service.getNotifications(ownerId).listen((notifications) {
///   print('Got ${notifications.length} notifications');
/// });
/// ```
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'notifications';

  /// Create a new notification with localization support
  Future<void> createNotification({
    required String ownerId,
    required NotificationType type,
    required String title,
    required String message,
    String? bookingId,
    Map<String, dynamic>? metadata,
    String? titleKey,
    String? messageKey,
  }) async {
    try {
      final notification = NotificationModel(
        id: '', // Firestore will generate ID
        ownerId: ownerId,
        type: type,
        title: title,
        message: message,
        timestamp: DateTime.now(),
        bookingId: bookingId,
        metadata: metadata,
        titleKey: titleKey,
        messageKey: messageKey,
      );

      await _firestore
          .collection(_collectionName)
          .add(notification.toFirestore());
    } catch (e) {
      throw NotificationException.creationFailed(e);
    }
  }

  /// Get all notifications for owner (stream)
  Stream<List<NotificationModel>> getNotifications(String ownerId) {
    return _firestore
        .collection(_collectionName)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('timestamp', descending: true)
        .limit(100) // Limit to last 100 notifications
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(NotificationModel.fromFirestore).toList();
        });
  }

  /// Get unread notifications count (stream)
  Stream<int> getUnreadCount(String ownerId) {
    return _firestore
        .collection(_collectionName)
        .where('ownerId', isEqualTo: ownerId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collectionName).doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw NotificationException.updateFailed(e);
    }
  }

  /// Mark multiple notifications as read
  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    try {
      final batch = _firestore.batch();

      for (final id in notificationIds) {
        batch.update(_firestore.collection(_collectionName).doc(id), {
          'isRead': true,
        });
      }

      await batch.commit();
    } catch (e) {
      throw NotificationException.updateFailed(e);
    }
  }

  /// Mark all notifications as read for owner
  /// Note: Handles Firestore batch limit of 500 operations
  Future<void> markAllAsRead(String ownerId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('ownerId', isEqualTo: ownerId)
          .where('isRead', isEqualTo: false)
          .get();

      // Firestore batch limit is 500 operations
      const batchLimit = 500;
      final docs = snapshot.docs;

      // Process in chunks to avoid batch limit
      for (var i = 0; i < docs.length; i += batchLimit) {
        final batch = _firestore.batch();
        final end = (i + batchLimit < docs.length)
            ? i + batchLimit
            : docs.length;

        for (var j = i; j < end; j++) {
          batch.update(docs[j].reference, {'isRead': true});
        }

        await batch.commit();
      }
    } catch (e) {
      throw NotificationException.updateFailed(e);
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collectionName).doc(notificationId).delete();
    } catch (e) {
      throw NotificationException(
        'Failed to delete notification',
        code: 'notification/deletion-failed',
        originalError: e,
      );
    }
  }

  /// Delete multiple notifications by IDs
  /// Note: Handles Firestore batch limit of 500 operations
  Future<void> deleteMultipleNotifications(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;

    try {
      // Firestore batch limit is 500 operations
      const batchLimit = 500;

      for (var i = 0; i < notificationIds.length; i += batchLimit) {
        final batch = _firestore.batch();
        final end = (i + batchLimit < notificationIds.length)
            ? i + batchLimit
            : notificationIds.length;

        for (var j = i; j < end; j++) {
          batch.delete(
            _firestore.collection(_collectionName).doc(notificationIds[j]),
          );
        }

        await batch.commit();
      }
    } catch (e) {
      throw NotificationException(
        'Failed to delete multiple notifications',
        code: 'notification/bulk-deletion-failed',
        originalError: e,
      );
    }
  }

  /// Delete all notifications for owner
  /// Note: Handles Firestore batch limit of 500 operations
  Future<void> deleteAllNotifications(String ownerId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('ownerId', isEqualTo: ownerId)
          .get();

      // Firestore batch limit is 500 operations
      const batchLimit = 500;
      final docs = snapshot.docs;

      // Process in chunks to avoid batch limit
      for (var i = 0; i < docs.length; i += batchLimit) {
        final batch = _firestore.batch();
        final end = (i + batchLimit < docs.length)
            ? i + batchLimit
            : docs.length;

        for (var j = i; j < end; j++) {
          batch.delete(docs[j].reference);
        }

        await batch.commit();
      }
    } catch (e) {
      throw NotificationException(
        'Failed to delete all notifications',
        code: 'notification/bulk-deletion-failed',
        originalError: e,
      );
    }
  }

  /// Helper: Create booking notification with localization keys
  Future<void> createBookingNotification({
    required String ownerId,
    required String bookingId,
    required String guestName,
    required String action, // 'created', 'updated', 'cancelled'
  }) async {
    // Map action string to NotificationType
    final notificationType = switch (action) {
      'created' => NotificationType.bookingCreated,
      'updated' => NotificationType.bookingUpdated,
      'cancelled' => NotificationType.bookingCancelled,
      _ => NotificationType.bookingCreated,
    };

    // Fallback titles (for backward compatibility)
    final fallbackTitles = {
      'created': 'New Booking',
      'updated': 'Booking Updated',
      'cancelled': 'Booking Cancelled',
    };

    // Fallback messages (for backward compatibility)
    final fallbackMessages = {
      'created': '$guestName created a new booking.',
      'updated': 'Booking for $guestName was updated.',
      'cancelled': 'Booking for $guestName was cancelled.',
    };

    // Localization keys
    final titleKeys = {
      'created': 'notificationBookingCreatedTitle',
      'updated': 'notificationBookingUpdatedTitle',
      'cancelled': 'notificationBookingCancelledTitle',
    };

    final messageKeys = {
      'created': 'notificationBookingCreatedMessage',
      'updated': 'notificationBookingUpdatedMessage',
      'cancelled': 'notificationBookingCancelledMessage',
    };

    await createNotification(
      ownerId: ownerId,
      type: notificationType,
      title: fallbackTitles[action] ?? 'Notification',
      message: fallbackMessages[action] ?? 'New booking activity.',
      bookingId: bookingId,
      metadata: {'guestName': guestName},
      titleKey: titleKeys[action],
      messageKey: messageKeys[action],
    );
  }

  /// Helper: Create payment notification with localization keys
  Future<void> createPaymentNotification({
    required String ownerId,
    required String bookingId,
    required String guestName,
    required double amount,
  }) async {
    await createNotification(
      ownerId: ownerId,
      type: NotificationType.paymentReceived,
      title: 'Payment Received',
      message:
          'Received payment from $guestName for €${amount.toStringAsFixed(2)}.',
      bookingId: bookingId,
      metadata: {'guestName': guestName, 'amount': amount},
      titleKey: 'notificationPaymentReceivedTitle',
      messageKey: 'notificationPaymentReceivedMessage',
    );
  }
}
