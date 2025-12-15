import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/owner_dashboard/domain/models/notification_model.dart';
import '../exceptions/app_exceptions.dart';

/// Service for managing owner notifications.
///
/// Handles creating, reading, updating, and deleting notifications
/// stored in Firestore. Supports batch operations with Firestore's
/// 500 operation limit.
///
/// NEW STRUCTURE: notifications are stored as subcollection under users
/// Path: users/{userId}/notifications/{notificationId}
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

  /// Get notifications collection reference for a user
  /// NEW STRUCTURE: users/{userId}/notifications
  CollectionReference<Map<String, dynamic>> _notificationsCollection(
      String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

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

      // NEW STRUCTURE: Write to user's notifications subcollection
      await _notificationsCollection(ownerId).add(notification.toFirestore());
    } catch (e) {
      throw NotificationException.creationFailed(e);
    }
  }

  /// Get all notifications for owner (stream)
  Stream<List<NotificationModel>> getNotifications(String ownerId) {
    // NEW STRUCTURE: Query from user's notifications subcollection
    // No longer need 'ownerId' filter since it's scoped to the user
    return _notificationsCollection(ownerId)
        .orderBy('timestamp', descending: true)
        .limit(100) // Limit to last 100 notifications
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(NotificationModel.fromFirestore).toList();
    });
  }

  /// Get unread notifications count (stream)
  Stream<int> getUnreadCount(String ownerId) {
    // NEW STRUCTURE: Query from user's notifications subcollection
    return _notificationsCollection(ownerId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId, {String? ownerId}) async {
    try {
      if (ownerId != null) {
        // NEW STRUCTURE: Use subcollection path
        await _notificationsCollection(ownerId).doc(notificationId).update({
          'isRead': true,
        });
      } else {
        // Fallback: Use collection group query to find notification
        final query = await _firestore
            .collectionGroup('notifications')
            .where(FieldPath.documentId, isEqualTo: notificationId)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.update({'isRead': true});
        }
      }
    } catch (e) {
      throw NotificationException.updateFailed(e);
    }
  }

  /// Mark multiple notifications as read
  Future<void> markMultipleAsRead(List<String> notificationIds,
      {String? ownerId}) async {
    if (notificationIds.isEmpty) return;

    try {
      final batch = _firestore.batch();

      if (ownerId != null) {
        // NEW STRUCTURE: Use subcollection path directly
        for (final id in notificationIds) {
          batch.update(_notificationsCollection(ownerId).doc(id), {
            'isRead': true,
          });
        }
      } else {
        // Fallback: Find each notification via collection group
        for (final id in notificationIds) {
          final query = await _firestore
              .collectionGroup('notifications')
              .where(FieldPath.documentId, isEqualTo: id)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            batch.update(query.docs.first.reference, {'isRead': true});
          }
        }
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
      // NEW STRUCTURE: Query from user's notifications subcollection
      final snapshot = await _notificationsCollection(ownerId)
          .where('isRead', isEqualTo: false)
          .get();

      // Firestore batch limit is 500 operations
      const batchLimit = 500;
      final docs = snapshot.docs;

      // Process in chunks to avoid batch limit
      for (var i = 0; i < docs.length; i += batchLimit) {
        final batch = _firestore.batch();
        final end =
            (i + batchLimit < docs.length) ? i + batchLimit : docs.length;

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
  Future<void> deleteNotification(String notificationId,
      {String? ownerId}) async {
    try {
      if (ownerId != null) {
        // NEW STRUCTURE: Use subcollection path
        await _notificationsCollection(ownerId).doc(notificationId).delete();
      } else {
        // Fallback: Use collection group query to find notification
        final query = await _firestore
            .collectionGroup('notifications')
            .where(FieldPath.documentId, isEqualTo: notificationId)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.delete();
        }
      }
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
  Future<void> deleteMultipleNotifications(List<String> notificationIds,
      {String? ownerId}) async {
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
          if (ownerId != null) {
            // NEW STRUCTURE: Use subcollection path
            batch.delete(_notificationsCollection(ownerId).doc(notificationIds[j]));
          } else {
            // Fallback: Find via collection group
            final query = await _firestore
                .collectionGroup('notifications')
                .where(FieldPath.documentId, isEqualTo: notificationIds[j])
                .limit(1)
                .get();

            if (query.docs.isNotEmpty) {
              batch.delete(query.docs.first.reference);
            }
          }
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
      // NEW STRUCTURE: Query from user's notifications subcollection
      final snapshot = await _notificationsCollection(ownerId).get();

      // Firestore batch limit is 500 operations
      const batchLimit = 500;
      final docs = snapshot.docs;

      // Process in chunks to avoid batch limit
      for (var i = 0; i < docs.length; i += batchLimit) {
        final batch = _firestore.batch();
        final end =
            (i + batchLimit < docs.length) ? i + batchLimit : docs.length;

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
