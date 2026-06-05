import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../domain/models/notification_model.dart';

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Stream of all notifications for current owner
final notificationsStreamProvider =
    StreamProvider.autoDispose<List<NotificationModel>>((ref) {
      final authState = ref.watch(enhancedAuthProvider);
      final service = ref.watch(notificationServiceProvider);

      final ownerId = authState.firebaseUser?.uid;
      if (ownerId == null) {
        return Stream.value([]);
      }

      return service.getNotifications(ownerId);
    });

/// Stream of unread notifications count
final unreadNotificationsCountProvider = StreamProvider.autoDispose<int>((ref) {
  final authState = ref.watch(enhancedAuthProvider);
  final service = ref.watch(notificationServiceProvider);

  final ownerId = authState.firebaseUser?.uid;
  if (ownerId == null) {
    return Stream.value(0);
  }

  return service.getUnreadCount(ownerId);
});

/// Grouped notifications by date
final groupedNotificationsProvider =
    Provider.autoDispose<Map<String, List<NotificationModel>>>((ref) {
      final notificationsAsync = ref.watch(notificationsStreamProvider);

      return notificationsAsync.when(
        data: (notifications) {
          final grouped = <String, List<NotificationModel>>{};
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));

          for (final notification in notifications) {
            final notificationDate = DateTime(
              notification.timestamp.year,
              notification.timestamp.month,
              notification.timestamp.day,
            );

            String dateKey;
            if (notificationDate == today) {
              dateKey = 'Danas';
            } else if (notificationDate == yesterday) {
              dateKey = 'Jučer';
            } else if (now.difference(notificationDate).inDays < 7) {
              final weekday = _getWeekdayName(notificationDate.weekday);
              dateKey = weekday;
            } else {
              dateKey =
                  '${notificationDate.day}.${notificationDate.month}.${notificationDate.year}';
            }

            grouped.putIfAbsent(dateKey, () => []);
            grouped[dateKey]!.add(notification);
          }

          return grouped;
        },
        loading: () => {},
        error: (error, stackTrace) => {},
      );
    });

/// Notification actions provider (for mutations)
/// Uses current user's ownerId for efficient direct subcollection access
final notificationActionsProvider = Provider<NotificationActions>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final bookingsRepo = ref.watch(ownerBookingsRepositoryProvider);
  final authState = ref.watch(enhancedAuthProvider);
  final ownerId = authState.firebaseUser?.uid;
  return NotificationActions(service, bookingsRepo, ownerId);
});

/// Notification actions class
/// NEW STRUCTURE: All methods pass ownerId for direct subcollection access
/// This avoids expensive collectionGroup queries.
///
/// audit/114 F3 (Round 3) — added [approveBooking] / [rejectBooking] that
/// delegate to the existing owner bookings repository (firebase_owner_bookings
/// _repository.dart:875 / :894). No new business logic — the Cloud Function
/// hop, ownership checks, status guards and email fan-out are all handled
/// server-side. UI surfaces only the success / failure outcome.
class NotificationActions {
  final NotificationService _service;
  final FirebaseOwnerBookingsRepository _bookingsRepo;
  final String? _ownerId;

  NotificationActions(this._service, this._bookingsRepo, this._ownerId);

  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId, ownerId: _ownerId);
  }

  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    await _service.markMultipleAsRead(notificationIds, ownerId: _ownerId);
  }

  Future<void> markAllAsRead(String ownerId) async {
    await _service.markAllAsRead(ownerId);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _service.deleteNotification(notificationId, ownerId: _ownerId);
  }

  Future<void> deleteMultiple(List<String> notificationIds) async {
    await _service.deleteMultipleNotifications(
      notificationIds,
      ownerId: _ownerId,
    );
  }

  Future<void> deleteAllNotifications(String ownerId) async {
    await _service.deleteAllNotifications(ownerId);
  }

  /// Approve the pending booking referenced by an actionable notification.
  /// Thin wrapper over [FirebaseOwnerBookingsRepository.approveBooking] —
  /// surfaces the same [BookingException] on failure so callers can localize.
  Future<void> approveBooking(String bookingId) =>
      _bookingsRepo.approveBooking(bookingId);

  /// Reject the pending booking referenced by an actionable notification.
  /// Thin wrapper over [FirebaseOwnerBookingsRepository.rejectBooking].
  Future<void> rejectBooking(String bookingId, {String? reason}) =>
      _bookingsRepo.rejectBooking(bookingId, reason: reason);
}

/// Helper function to get Croatian weekday name
String _getWeekdayName(int weekday) => switch (weekday) {
  1 => 'Ponedjeljak',
  2 => 'Utorak',
  3 => 'Srijeda',
  4 => 'Četvrtak',
  5 => 'Petak',
  6 => 'Subota',
  7 => 'Nedjelja',
  _ => '',
};
