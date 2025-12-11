import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/notification_localizer.dart';
import '../../../../core/utils/responsive_dialog_utils.dart';
import '../providers/notifications_provider.dart';
import '../../domain/models/notification_model.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/common_app_bar.dart';

/// Notifications screen for owner dashboard
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  bool _isDeleting = false;

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<NotificationModel> notifications) {
    setState(() {
      _selectedIds.addAll(notifications.map((n) => n.id));
    });
  }

  void _deselectAll() {
    setState(_selectedIds.clear);
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _PremiumAlertDialog(
        title: l10n.notificationsDeleteSelected,
        content: l10n.notificationsDeleteSelectedDesc(_selectedIds.length),
        confirmText: l10n.delete,
        cancelText: l10n.cancel,
        isDestructive: true,
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        final actions = ref.read(notificationActionsProvider);
        await actions.deleteMultiple(_selectedIds.toList());
        if (mounted) {
          setState(() {
            _selectedIds.clear();
            _isSelectionMode = false;
            _isDeleting = false;
          });
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10n.notificationsDeleted,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ErrorDisplayUtils.showErrorSnackBar(context, e);
        }
      }
    }
  }

  Future<void> _deleteAll() async {
    final authState = ref.read(enhancedAuthProvider);
    final ownerId = authState.firebaseUser?.uid;
    if (ownerId == null) return;
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _PremiumAlertDialog(
        title: l10n.notificationsDeleteAll,
        content: l10n.notificationsDeleteAllDesc,
        confirmText: l10n.notificationsDeleteAllBtn,
        cancelText: l10n.cancel,
        isDestructive: true,
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        final actions = ref.read(notificationActionsProvider);
        await actions.deleteAllNotifications(ownerId);
        if (mounted) {
          setState(() {
            _selectedIds.clear();
            _isSelectionMode = false;
            _isDeleting = false;
          });
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10n.notificationsAllDeleted,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ErrorDisplayUtils.showErrorSnackBar(context, e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final groupedNotifications = ref.watch(groupedNotificationsProvider);
    final actions = ref.watch(notificationActionsProvider);

    // Flatten notifications for select all
    final allNotifications = notificationsAsync.valueOrNull ?? [];

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: _isSelectionMode
          ? _buildSelectionAppBar(theme, allNotifications, l10n)
          : CommonAppBar(
              title: l10n.notificationsTitle,
              leadingIcon: Icons.menu,
              onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
            ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: Stack(
          children: [
            notificationsAsync.when(
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
                      final dateKey = groupedNotifications.keys.elementAt(
                        index,
                      );
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              error: (error, stack) {
                return _buildErrorState(context, error, ref);
              },
            ),

            // Loading overlay during delete
            if (_isDeleting)
              Container(
                color: Colors.black.withAlpha((0.3 * 255).toInt()),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.gradients.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.gradients.sectionBorder,
                      ),
                      boxShadow: theme.brightness == Brightness.dark
                          ? AppShadows.elevation3Dark
                          : AppShadows.elevation3,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.notificationsDeleting),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'notifications'),
      // FAB for actions when not in selection mode
      floatingActionButton: !_isSelectionMode && allNotifications.isNotEmpty
          ? FloatingActionButton(
              onPressed: _toggleSelectionMode,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              tooltip: l10n.notificationsSelect,
              child: const Icon(Icons.checklist_rounded, size: 24),
            )
          : null,
    );
  }

  /// Build selection mode app bar
  PreferredSizeWidget _buildSelectionAppBar(
    ThemeData theme,
    List<NotificationModel> allNotifications,
    AppLocalizations l10n,
  ) {
    final allSelected =
        _selectedIds.length == allNotifications.length &&
        allNotifications.isNotEmpty;

    return AppBar(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _toggleSelectionMode,
        tooltip: l10n.notificationsCancel,
      ),
      title: Text(
        l10n.notificationsSelected(_selectedIds.length),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        // Select All / Deselect All
        IconButton(
          icon: Icon(
            allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
          ),
          onPressed: () {
            if (allSelected) {
              _deselectAll();
            } else {
              _selectAll(allNotifications);
            }
          },
          tooltip: allSelected
              ? l10n.notificationsDeselectAll
              : l10n.notificationsSelectAll,
        ),

        // Delete Selected
        if (_selectedIds.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: _deleteSelected,
            tooltip: l10n.notificationsDeleteSelectedBtn,
          ),

        // More options
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'delete_all') {
              _deleteAll();
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'delete_all',
              child: Row(
                children: [
                  const Icon(Icons.delete_forever, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(
                    l10n.notificationsDeleteAllBtn,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build notification card
  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notification,
    NotificationActions actions,
  ) {
    final isSelected = _selectedIds.contains(notification.id);

    if (_isSelectionMode) {
      // Selection mode - tap to select, no swipe
      return _SelectableNotificationCard(
        notification: notification,
        isSelected: isSelected,
        onTap: () => _toggleSelection(notification.id),
        iconData: _getNotificationIcon(notification.type),
        iconColor: _getNotificationColor(context, notification.type),
      );
    }

    // Normal mode - swipe to delete
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.error,
              Theme.of(context).colorScheme.error,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        final l10n = AppLocalizations.of(context);
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => _PremiumAlertDialog(
            title: l10n.notificationsDeleteNotification,
            content: l10n.notificationsDeleteNotificationDesc,
            confirmText: l10n.delete,
            cancelText: l10n.cancel,
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
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

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
                color: context.gradients.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.gradients.sectionBorder,
                  width: 2,
                ),
                boxShadow: isDark
                    ? AppShadows.elevation2Dark
                    : AppShadows.elevation2,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 70,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.notificationsEmpty,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.notificationsEmptyDesc,
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

  /// Build error state
  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

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
                color: context.gradients.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.error.withAlpha((0.3 * 255).toInt()),
                  width: 2,
                ),
                boxShadow: isDark
                    ? AppShadows.elevation2Dark
                    : AppShadows.elevation2,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 50,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.notificationsLoadError,
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
              label: Text(l10n.notificationsTryAgain),
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
  }

  /// Get notification icon based on type
  IconData _getNotificationIcon(NotificationType type) => switch (type) {
    NotificationType.bookingCreated => Icons.event_available,
    NotificationType.bookingUpdated => Icons.edit_calendar,
    NotificationType.bookingCancelled => Icons.event_busy,
    NotificationType.paymentReceived => Icons.payments,
    NotificationType.system => Icons.notifications,
  };

  /// Get notification color based on type
  Color _getNotificationColor(BuildContext context, NotificationType type) {
    final theme = Theme.of(context);
    return switch (type) {
      NotificationType.bookingCreated => theme.colorScheme.tertiary,
      NotificationType.bookingUpdated => theme.colorScheme.error,
      NotificationType.bookingCancelled => theme.colorScheme.error,
      NotificationType.paymentReceived => theme.colorScheme.primary,
      NotificationType.system => theme.colorScheme.onSurfaceVariant,
    };
  }
}

/// Selectable notification card for selection mode
class _SelectableNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData iconData;
  final Color iconColor;

  const _SelectableNotificationCard({
    required this.notification,
    required this.isSelected,
    required this.onTap,
    required this.iconData,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUnread = !notification.isRead;
    final l10n = AppLocalizations.of(context);
    final localizer = NotificationLocalizer(l10n);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withAlpha((0.06 * 255).toInt())
            : context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary.withAlpha((0.4 * 255).toInt())
              : context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt()),
        ),
        boxShadow: isDark ? AppShadows.elevation1Dark : AppShadows.elevation1,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Checkbox - kompaktniji
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap(),
                    activeColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

                const SizedBox(width: 10),

                // Icon - jednostavnija pozadina
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(iconData, color: iconColor, size: 18),
                ),

                const SizedBox(width: 10),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              localizer.getTitle(notification),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizer.getMessage(notification),
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    final l10n = AppLocalizations.of(context);
    final localizer = NotificationLocalizer(l10n);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.gradients.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.primary.withAlpha((0.3 * 255).toInt())
                : context.gradients.sectionBorder.withAlpha(
                    (0.5 * 255).toInt(),
                  ),
          ),
          boxShadow: isDark ? AppShadows.elevation1Dark : AppShadows.elevation1,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container - jednostavniji dizajn bez gradienta
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.iconColor.withAlpha((0.12 * 255).toInt()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.iconData,
                      color: widget.iconColor,
                      size: 22,
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
                                localizer.getTitle(widget.notification),
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
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Message
                        Text(
                          localizer.getMessage(widget.notification),
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
                              localizer.getRelativeTime(widget.notification),
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
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(context),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: context.gradients.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDestructive
                ? theme.colorScheme.error.withAlpha((0.2 * 255).toInt())
                : context.gradients.sectionBorder,
            width: 1.5,
          ),
          boxShadow: isDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.gradients.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDestructive
                      ? theme.colorScheme.error.withAlpha((0.3 * 255).toInt())
                      : context.gradients.sectionBorder,
                  width: 2,
                ),
                boxShadow: isDark
                    ? AppShadows.elevation2Dark
                    : AppShadows.elevation2,
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
