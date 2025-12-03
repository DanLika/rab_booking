import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/owner_dashboard/domain/models/notification_model.dart';

/// Service for managing owner notifications
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'notifications';

  /// Create a new notification
  Future<void> createNotification({
    required String ownerId,
    required String type,
    required String title,
    required String message,
    String? bookingId,
    Map<String, dynamic>? metadata,
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
      );

      await _firestore
          .collection(_collectionName)
          .add(notification.toFirestore());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
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
      throw Exception('Failed to mark notification as read: $e');
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
      throw Exception('Failed to mark notifications as read: $e');
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
        final end = (i + batchLimit < docs.length) ? i + batchLimit : docs.length;

        for (var j = i; j < end; j++) {
          batch.update(docs[j].reference, {'isRead': true});
        }

        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collectionName).doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
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
        final end = (i + batchLimit < docs.length) ? i + batchLimit : docs.length;

        for (var j = i; j < end; j++) {
          batch.delete(docs[j].reference);
        }

        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  /// Helper: Create booking notification
  Future<void> createBookingNotification({
    required String ownerId,
    required String bookingId,
    required String guestName,
    required String action, // 'created', 'updated', 'cancelled'
  }) async {
    final titles = {
      'created': 'Nova rezervacija',
      'updated': 'Rezervacija ažurirana',
      'cancelled': 'Rezervacija otkazana',
    };

    final messages = {
      'created': '$guestName je kreirao novu rezervaciju.',
      'updated': 'Rezervacija za $guestName je ažurirana.',
      'cancelled': 'Rezervacija za $guestName je otkazana.',
    };

    await createNotification(
      ownerId: ownerId,
      type: 'booking_$action',
      title: titles[action] ?? 'Obavještenje',
      message: messages[action] ?? 'Nova aktivnost na rezervaciji.',
      bookingId: bookingId,
      metadata: {'guestName': guestName},
    );
  }

  /// Helper: Create payment notification
  Future<void> createPaymentNotification({
    required String ownerId,
    required String bookingId,
    required String guestName,
    required double amount,
  }) async {
    await createNotification(
      ownerId: ownerId,
      type: 'payment_received',
      title: 'Plaćanje primljeno',
      message:
          'Primljeno plaćanje od $guestName u iznosu od €${amount.toStringAsFixed(2)}.',
      bookingId: bookingId,
      metadata: {'guestName': guestName, 'amount': amount},
    );
  }
}
