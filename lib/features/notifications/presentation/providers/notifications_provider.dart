import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/notifications_repository.dart';
import '../../domain/models/notification_model.dart';

part 'notifications_provider.g.dart';

/// Provider for notifications list
@riverpod
class NotificationsNotifier extends _$NotificationsNotifier {
  RealtimeChannel? _realtimeChannel;

  @override
  Future<List<NotificationModel>> build() async {
    // Subscribe to realtime updates
    _subscribeToRealtime();

    // Cleanup realtime channel when provider is disposed
    ref.onDispose(() {
      _realtimeChannel?.unsubscribe();
    });

    // Fetch initial notifications
    return _fetchNotifications();
  }

  Future<List<NotificationModel>> _fetchNotifications() async {
    final repository = ref.read(notificationsRepositoryProvider);
    return await repository.getNotifications(limit: 100);
  }

  /// Subscribe to realtime notifications
  void _subscribeToRealtime() {
    final repository = ref.read(notificationsRepositoryProvider);

    try {
      _realtimeChannel = repository.subscribeToNotifications(
        onNotificationsChanged: (notifications) {
          state = AsyncValue.data(notifications);
        },
        onUnreadCountChanged: (count) {
          // Invalidate unread count provider
          ref.invalidate(unreadNotificationCountProvider);
        },
      );
    } catch (e) {
      // If realtime fails, still allow the app to work
      debugPrint('Failed to subscribe to notifications realtime: $e');
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchNotifications());
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final repository = ref.read(notificationsRepositoryProvider);
      await repository.markAsRead(notificationId);

      // Update local state
      state.whenData((notifications) {
        final updatedNotifications = notifications.map((notification) {
          if (notification.id == notificationId) {
            return notification.copyWith(isRead: true, readAt: DateTime.now());
          }
          return notification;
        }).toList();
        state = AsyncValue.data(updatedNotifications);
      });

      // Invalidate unread count
      ref.invalidate(unreadNotificationCountProvider);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    try {
      final repository = ref.read(notificationsRepositoryProvider);
      await repository.markAllAsRead();

      // Update local state
      state.whenData((notifications) {
        final updatedNotifications = notifications.map((notification) {
          return notification.copyWith(isRead: true, readAt: DateTime.now());
        }).toList();
        state = AsyncValue.data(updatedNotifications);
      });

      // Invalidate unread count
      ref.invalidate(unreadNotificationCountProvider);
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final repository = ref.read(notificationsRepositoryProvider);
      await repository.deleteNotification(notificationId);

      // Update local state
      state.whenData((notifications) {
        final updatedNotifications =
            notifications.where((n) => n.id != notificationId).toList();
        state = AsyncValue.data(updatedNotifications);
      });

      // Invalidate unread count
      ref.invalidate(unreadNotificationCountProvider);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Delete all read notifications
  Future<void> deleteAllRead() async {
    try {
      final repository = ref.read(notificationsRepositoryProvider);
      await repository.deleteAllRead();

      // Update local state
      state.whenData((notifications) {
        final updatedNotifications =
            notifications.where((n) => !n.isRead).toList();
        state = AsyncValue.data(updatedNotifications);
      });
    } catch (e) {
      throw Exception('Failed to delete read notifications: $e');
    }
  }

  // Riverpod notifiers don't have dispose() - use ref.onDispose() instead
  // which should be called in the build() method
}

/// Provider for unread notification count
@riverpod
class UnreadNotificationCount extends _$UnreadNotificationCount {
  @override
  Future<int> build() async {
    final repository = ref.read(notificationsRepositoryProvider);
    return await repository.getUnreadCount();
  }

  /// Refresh unread count
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(notificationsRepositoryProvider);
      return await repository.getUnreadCount();
    });
  }
}

/// Provider for filtered notifications (unread only)
@riverpod
Future<List<NotificationModel>> unreadNotifications(Ref ref) async {
  final allNotifications = await ref.watch(notificationsNotifierProvider.future);
  return allNotifications.where((n) => !n.isRead).toList();
}

/// Provider for grouped notifications by date
@riverpod
Future<Map<String, List<NotificationModel>>> groupedNotifications(
    Ref ref) async {
  final allNotifications = await ref.watch(notificationsNotifierProvider.future);

  final Map<String, List<NotificationModel>> grouped = {};

  for (final notification in allNotifications) {
    final now = DateTime.now();
    final notificationDate = notification.createdAt;

    String dateKey;

    if (notificationDate.year == now.year &&
        notificationDate.month == now.month &&
        notificationDate.day == now.day) {
      dateKey = 'Today';
    } else if (notificationDate.year == now.year &&
        notificationDate.month == now.month &&
        notificationDate.day == now.day - 1) {
      dateKey = 'Yesterday';
    } else if (now.difference(notificationDate).inDays < 7) {
      dateKey = 'This Week';
    } else if (now.difference(notificationDate).inDays < 30) {
      dateKey = 'This Month';
    } else {
      dateKey = 'Older';
    }

    if (!grouped.containsKey(dateKey)) {
      grouped[dateKey] = [];
    }
    grouped[dateKey]!.add(notification);
  }

  return grouped;
}
