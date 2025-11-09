import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../providers/notifications_provider.dart';
import '../../domain/models/notification_model.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/common_app_bar.dart';

/// Notifications screen for owner dashboard
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final groupedNotifications = ref.watch(groupedNotificationsProvider);
    final authState = ref.watch(enhancedAuthProvider);
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
                                  AppColors.primary.withAlpha(
                                    (0.1 * 255).toInt(),
                                  ),
                                  AppColors.secondary.withAlpha(
                                    (0.05 * 255).toInt(),
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dateKey,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
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
                                    AppColors.primary.withAlpha(
                                      (0.2 * 255).toInt(),
                                    ),
                                    const Color(0x00000000),
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
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        error: (error, stack) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

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
                          AppColors.error.withAlpha((0.1 * 255).toInt()),
                          AppColors.error.withAlpha((0.05 * 255).toInt()),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 50,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Greška pri učitavanju obavještenja',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
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
                      backgroundColor: AppColors.primary,
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
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.error, AppColors.error],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Color(0xFFFFFFFF),
          size: 28,
        ),
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
            // TODO: Navigate to booking details
            ErrorDisplayUtils.showInfoSnackBar(
              context,
              'Navigacija na rezervaciju: ${notification.bookingId}',
            );
          }
        },
        iconData: _getNotificationIcon(notification.type),
        iconColor: _getNotificationColor(notification.type),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                    AppColors.primary.withAlpha((0.1 * 255).toInt()),
                    AppColors.secondary.withAlpha((0.05 * 255).toInt()),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withAlpha((0.2 * 255).toInt()),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 70,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Nema obavještenja',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ovdje ćete vidjeti sva vaša obavještenja',
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
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
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking_created':
        return AppColors.success;
      case 'booking_updated':
        return AppColors.warning;
      case 'booking_cancelled':
        return AppColors.error;
      case 'payment_received':
        return AppColors.authPrimary;
      case 'system':
        return Colors.grey;
      default:
        return Colors.grey;
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
    final isDark = theme.brightness == Brightness.dark;
    final isUnread = !widget.notification.isRead;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? AppColors.primary.withAlpha((0.3 * 255).toInt())
                : isUnread
                ? AppColors.primary.withAlpha((0.15 * 255).toInt())
                : isDark
                ? AppColors.borderDark
                : AppColors.borderLight,
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? AppColors.primary.withAlpha((0.12 * 255).toInt())
                  : Colors.black.withAlpha((0.04 * 255).toInt()),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: Material(
          color: const Color(0x00000000),
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
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.authSecondary,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withAlpha(
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
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
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
                              color: AppColors.primary.withAlpha(
                                (0.6 * 255).toInt(),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.notification.getRelativeTime(),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary.withAlpha(
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
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDestructive
                ? AppColors.error.withAlpha((0.2 * 255).toInt())
                : AppColors.primary.withAlpha((0.2 * 255).toInt()),
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
                          AppColors.error.withAlpha((0.15 * 255).toInt()),
                          AppColors.error.withAlpha((0.08 * 255).toInt()),
                        ]
                      : [
                          AppColors.primary.withAlpha((0.15 * 255).toInt()),
                          AppColors.secondary.withAlpha((0.08 * 255).toInt()),
                        ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDestructive
                    ? Icons.warning_amber_rounded
                    : Icons.help_outline_rounded,
                color: isDestructive ? AppColors.error : AppColors.primary,
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
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Content
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
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
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
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
                          ? AppColors.error
                          : AppColors.primary,
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
