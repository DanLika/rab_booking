import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/notification_model.dart';

part 'notifications_repository.g.dart';

/// Repository for managing notifications
class NotificationsRepository {
  final SupabaseClient _supabase;

  NotificationsRepository(this._supabase);

  /// Get all notifications for current user
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool? onlyUnread,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      var queryBuilder = _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId);

      if (onlyUnread == true) {
        queryBuilder = queryBuilder.eq('is_read', false);
      }

      final query = queryBuilder
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await query;

      return (response as List)
          .map((json) => NotificationModel.fromSupabaseJson(json))
          .where((notification) => !notification.isExpired) // Filter expired
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Get a single notification by ID
  Future<NotificationModel?> getNotificationById(String notificationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('id', notificationId)
          .eq('user_id', userId)
          .single();

      return NotificationModel.fromSupabaseJson(response);
    } catch (e) {
      throw Exception('Failed to fetch notification: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId).eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark notification as unread
  Future<void> markAsUnread(String notificationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('notifications').update({
        'is_read': false,
        'read_at': null,
      }).eq('id', notificationId).eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to mark notification as unread: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.rpc('mark_all_notifications_as_read', params: {
        'p_user_id': userId,
      });
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Delete all read notifications
  Future<void> deleteAllRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .eq('is_read', true);
    } catch (e) {
      throw Exception('Failed to delete read notifications: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return 0;
      }

      final response = await _supabase.rpc('get_unread_notification_count', params: {
        'p_user_id': userId,
      });

      return response as int? ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  /// Subscribe to notifications changes (Realtime)
  RealtimeChannel subscribeToNotifications({
    required void Function(List<NotificationModel> notifications) onNotificationsChanged,
    required void Function(int unreadCount) onUnreadCountChanged,
  }) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final channel = _supabase
        .channel('notifications_channel_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            // Refetch notifications when changes occur
            final notifications = await getNotifications();
            onNotificationsChanged(notifications);

            // Update unread count
            final unreadCount = await getUnreadCount();
            onUnreadCountChanged(unreadCount);
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribe from notifications changes
  Future<void> unsubscribeFromNotifications(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }

  /// Create a test notification (for debugging)
  Future<void> createTestNotification({
    required NotificationType type,
    required String title,
    required String body,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': type.name,
        'title': title,
        'body': body,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create test notification: $e');
    }
  }
}

/// Provider for NotificationsRepository
@riverpod
NotificationsRepository notificationsRepository(Ref ref) {
  return NotificationsRepository(Supabase.instance.client);
}
