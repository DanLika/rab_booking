import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../providers/notifications_provider.dart';
import '../../domain/models/notification_model.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/common_app_bar.dart';

/// Notifications screen for owner dashboard
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final groupedNotifications = ref.watch(groupedNotificationsProvider);
    final actions = ref.watch(notificationActionsProvider);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Obavještenja',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            color: theme.colorScheme.primary,
            onRefresh: () async {
              ref.invalidate(notificationsStreamProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedNotifications.length,
              itemBuilder: (context, index) {
                final dateKey = groupedNotifications.keys.elementAt(index);
                final dayNotifications = groupedNotifications[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Date header
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withAlpha(
                                    (0.1 * 255).toInt(),
                                  ),
                                  theme.colorScheme.secondary.withAlpha(
                                    (0.05 * 255).toInt(),
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dateKey,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withAlpha(
                                      (0.2 * 255).toInt(),
                                    ),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Notifications for this date
                    ...dayNotifications.map(
                      (notification) => _buildNotificationCard(
                        context,
                        notification,
                        actions,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
        error: (error, stack) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.error.withAlpha((0.1 * 255).toInt()),
                          theme.colorScheme.error.withAlpha((0.05 * 255).toInt()),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 50,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Greška pri učitavanju obavještenja',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(notificationsStreamProvider);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Pokušaj ponovno'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'notifications'),
    );
  }

  /// Build notification card
  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notification,
    NotificationActions actions,
  ) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.error, theme.colorScheme.error],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => const _PremiumAlertDialog(
            title: 'Obriši obavještenje',
            content: 'Jeste li sigurni da želite obrisati ovo obavještenje?',
            confirmText: 'Obriši',
            cancelText: 'Otkaži',
            isDestructive: true,
          ),
        );
      },
      onDismissed: (direction) async {
        await actions.deleteNotification(notification.id);
      },
      child: _PremiumNotificationCard(
        notification: notification,
        onTap: () async {
          // Mark as read if unread
          if (!notification.isRead) {
            await actions.markAsRead(notification.id);
          }

          // Navigate to booking if bookingId exists
          if (notification.bookingId != null && context.mounted) {
            context.go(
              Uri(
                path: OwnerRoutes.bookings,
                queryParameters: {'bookingId': notification.bookingId},
              ).toString(),
            );
          }
        },
        iconData: _getNotificationIcon(notification.type),
        iconColor: _getNotificationColor(context, notification.type),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Premium icon container with gradient
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                    theme.colorScheme.secondary.withAlpha((0.05 * 255).toInt()),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha((0.2 * 255).toInt()),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 70,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Nema obavještenja',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ovdje ćete vidjeti sva vaša obavještenja',
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Get notification icon based on type
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking_created':
        return Icons.event_available;
      case 'booking_updated':
        return Icons.edit_calendar;
      case 'booking_cancelled':
        return Icons.event_busy;
      case 'payment_received':
        return Icons.payments;
      case 'system':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  /// Get notification color based on type
  Color _getNotificationColor(BuildContext context, String type) {
    final theme = Theme.of(context);

    switch (type) {
      case 'booking_created':
        return theme.colorScheme.tertiary; // Green
      case 'booking_updated':
        return theme.colorScheme.error; // Red (was warning - no warning in theme)
      case 'booking_cancelled':
        return theme.colorScheme.error;
      case 'payment_received':
        return theme.colorScheme.primary;
      case 'system':
        return theme.colorScheme.onSurfaceVariant; // Grey
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}

/// Premium Notification Card with hover effect
class _PremiumNotificationCard extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final IconData iconData;
  final Color iconColor;

  const _PremiumNotificationCard({
    required this.notification,
    required this.onTap,
    required this.iconData,
    required this.iconColor,
  });

  @override
  State<_PremiumNotificationCard> createState() =>
      _PremiumNotificationCardState();
}

class _PremiumNotificationCardState extends State<_PremiumNotificationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !widget.notification.isRead;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.primary.withAlpha((0.3 * 255).toInt())
                : isUnread
                ? theme.colorScheme.primary.withAlpha((0.15 * 255).toInt())
                : theme.colorScheme.outline.withAlpha((0.3 * 255).toInt()),
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? theme.colorScheme.primary.withAlpha((0.12 * 255).toInt())
                  : Colors.black.withAlpha((0.04 * 255).toInt()),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium icon container with gradient
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.iconColor.withAlpha((0.15 * 255).toInt()),
                          widget.iconColor.withAlpha((0.08 * 255).toInt()),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: widget.iconColor.withAlpha(
                            (0.2 * 255).toInt(),
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.iconData,
                      color: widget.iconColor,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with unread indicator
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.notification.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withAlpha(
                                        (0.4 * 255).toInt(),
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Message
                        Text(
                          widget.notification.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 10),

                        // Timestamp with icon
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: theme.colorScheme.primary.withAlpha(
                                (0.6 * 255).toInt(),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.notification.getRelativeTime(),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary.withAlpha(
                                  (0.7 * 255).toInt(),
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium Alert Dialog
class _PremiumAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;

  const _PremiumAlertDialog({
    required this.title,
    required this.content,
    required this.confirmText,
    required this.cancelText,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDestructive
                ? theme.colorScheme.error.withAlpha((0.2 * 255).toInt())
                : theme.colorScheme.primary.withAlpha((0.2 * 255).toInt()),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDestructive
                      ? [
                          theme.colorScheme.error.withAlpha((0.15 * 255).toInt()),
                          theme.colorScheme.error.withAlpha((0.08 * 255).toInt()),
                        ]
                      : [
                          theme.colorScheme.primary.withAlpha((0.15 * 255).toInt()),
                          theme.colorScheme.secondary.withAlpha((0.08 * 255).toInt()),
                        ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDestructive
                    ? Icons.warning_amber_rounded
                    : Icons.help_outline_rounded,
                color: isDestructive
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                size: 32,
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Content
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withAlpha(
                          (0.5 * 255).toInt(),
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDestructive
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
