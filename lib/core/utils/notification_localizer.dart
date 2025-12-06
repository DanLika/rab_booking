import '../../l10n/app_localizations.dart';
import '../../features/owner_dashboard/domain/models/notification_model.dart';

/// Helper class for localizing notification content
class NotificationLocalizer {
  final AppLocalizations l10n;

  NotificationLocalizer(this.l10n);

  /// Get localized title for notification
  /// Falls back to stored title if no localization key exists
  String getTitle(NotificationModel notification) {
    if (notification.titleKey == null) {
      return notification.title;
    }

    return _localizeTitle(notification.titleKey!);
  }

  /// Get localized message for notification
  /// Falls back to stored message if no localization key exists
  String getMessage(NotificationModel notification) {
    if (notification.messageKey == null) {
      return notification.message;
    }

    final params = notification.metadata ?? {};
    return _localizeMessage(notification.messageKey!, params);
  }

  /// Get localized relative time string
  String getRelativeTime(NotificationModel notification) {
    final now = DateTime.now();
    final difference = now.difference(notification.timestamp);

    if (difference.inSeconds < 60) {
      return l10n.notificationTimeJustNow;
    } else if (difference.inMinutes < 60) {
      return l10n.notificationTimeMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.notificationTimeHoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.notificationTimeDaysAgo(difference.inDays);
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return l10n.notificationTimeWeeksAgo(weeks);
    } else {
      final months = (difference.inDays / 30).floor();
      return l10n.notificationTimeMonthsAgo(months);
    }
  }

  String _localizeTitle(String key) {
    switch (key) {
      case 'notificationBookingCreatedTitle':
        return l10n.notificationBookingCreatedTitle;
      case 'notificationBookingUpdatedTitle':
        return l10n.notificationBookingUpdatedTitle;
      case 'notificationBookingCancelledTitle':
        return l10n.notificationBookingCancelledTitle;
      case 'notificationPaymentReceivedTitle':
        return l10n.notificationPaymentReceivedTitle;
      default:
        return key;
    }
  }

  String _localizeMessage(String key, Map<String, dynamic> params) {
    final guestName = params['guestName'] as String? ?? '';
    final amount = params['amount'] as num? ?? 0;

    switch (key) {
      case 'notificationBookingCreatedMessage':
        return l10n.notificationBookingCreatedMessage(guestName);
      case 'notificationBookingUpdatedMessage':
        return l10n.notificationBookingUpdatedMessage(guestName);
      case 'notificationBookingCancelledMessage':
        return l10n.notificationBookingCancelledMessage(guestName);
      case 'notificationPaymentReceivedMessage':
        return l10n.notificationPaymentReceivedMessage(guestName, amount.toDouble());
      default:
        return key;
    }
  }
}
