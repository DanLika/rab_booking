import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router_owner.dart';
import '../../../../core/design/responsive.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/notification_localizer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../domain/models/notification_model.dart';
import '../providers/notifications_provider.dart';
import '../widgets/owner_app_drawer.dart';

/// Notifications screen for owner dashboard
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

/// Browse-view filter for the notifications inbox. Every case maps to a real,
/// backend-backed [NotificationType] only — no review / sync / rating
/// categories are invented (audit/141 data-honesty: those have no backend).
enum _NotifFilter { all, unread, bookings, payments, system }

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  bool _isDeleting = false;
  _NotifFilter _activeFilter = _NotifFilter.all;

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

  Future<bool?> _confirm({
    required String title,
    required String content,
    required String confirmText,
    required String cancelText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => BbDialog(
        title: title,
        body: content,
        destructive: isDestructive,
        secondary: BbDialogAction(
          label: cancelText,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        primary: BbDialogAction(
          label: confirmText,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final l10n = AppLocalizations.of(context);

    final confirmed = await _confirm(
      title: l10n.notificationsDeleteSelected,
      content: l10n.notificationsDeleteSelectedDesc(_selectedIds.length),
      confirmText: l10n.delete,
      cancelText: l10n.cancel,
      isDestructive: true,
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

    final confirmed = await _confirm(
      title: l10n.notificationsDeleteAll,
      content: l10n.notificationsDeleteAllDesc,
      confirmText: l10n.notificationsDeleteAllBtn,
      cancelText: l10n.cancel,
      isDestructive: true,
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

  /// Mark every notification read in one shot (audit/141). Non-destructive →
  /// no confirm dialog; best-effort with a success / error toast.
  Future<void> _markAllRead() async {
    final ownerId = ref.read(enhancedAuthProvider).firebaseUser?.uid;
    if (ownerId == null) return;
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(notificationActionsProvider).markAllAsRead(ownerId);
      if (mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          l10n.notificationsAllMarkedRead,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(context, e);
      }
    }
  }

  bool _matchesFilter(NotificationModel n) => switch (_activeFilter) {
    _NotifFilter.all => true,
    _NotifFilter.unread => !n.isRead,
    _NotifFilter.bookings =>
      n.type == NotificationType.bookingCreated ||
          n.type == NotificationType.bookingUpdated ||
          n.type == NotificationType.bookingCancelled,
    _NotifFilter.payments => n.type == NotificationType.paymentReceived,
    _NotifFilter.system => n.type == NotificationType.system,
  };

  /// Apply the active filter to the date-grouped map, dropping now-empty day
  /// groups so the date headers stay truthful.
  Map<String, List<NotificationModel>> _applyFilter(
    Map<String, List<NotificationModel>> grouped,
  ) {
    if (_activeFilter == _NotifFilter.all) return grouped;
    final out = <String, List<NotificationModel>>{};
    for (final entry in grouped.entries) {
      final kept = entry.value.where(_matchesFilter).toList();
      if (kept.isNotEmpty) out[entry.key] = kept;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = BBColor.of(context);
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final groupedNotifications = ref.watch(groupedNotificationsProvider);
    final actions = ref.watch(notificationActionsProvider);

    // Flatten notifications for select all
    final allNotifications =
        notificationsAsync.valueOrNull ?? <NotificationModel>[];

    // Unread count — wired to the server-side stream (audit/141), falling back
    // to a local tally while that stream is still loading so the header + chip
    // never flash a stale 0.
    final unreadCount =
        ref.watch(unreadNotificationsCountProvider).valueOrNull ??
        allNotifications.where((n) => !n.isRead).length;
    final totalCount = allNotifications.length;

    final l10n = AppLocalizations.of(context);
    final bool isCompact = MediaQuery.of(context).size.width < 600;
    final bool canMarkAll = unreadCount > 0;

    return Scaffold(
      appBar: _isSelectionMode
          ? _buildSelectionAppBar(theme, allNotifications, l10n)
          : CommonAppBar(
              title: l10n.notificationsTitle,
              // Premium screens carry the title in an in-body header on wide
              // layouts (audit/126 §2A); on mobile the AppBar keeps the title
              // and owns the mark-all-read action.
              showTitle: isCompact,
              leadingIcon: Icons.menu,
              onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
              actions: isCompact && canMarkAll
                  ? <Widget>[
                      IconButton(
                        icon: const Icon(Icons.done_all),
                        onPressed: _markAllRead,
                        tooltip: l10n.notificationsMarkAllRead,
                      ),
                    ]
                  : null,
            ),
      // Shell background per handoff (`--bb-shell-bg`), matching sibling
      // screens that paint `context.gradients.pageBackground` explicitly.
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: Stack(
          alignment: Alignment.topLeft,
          children: [
            notificationsAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return _buildEmptyState(context);
                }

                // Selection mode operates on the full list; the filter chips
                // only narrow the browse view.
                final groups = _isSelectionMode
                    ? groupedNotifications
                    : _applyFilter(groupedNotifications);

                // Index 0 carries the in-body header + filter chips (so they
                // scroll with the inbox); the date groups follow.
                final bool showChrome = !_isSelectionMode;
                final int leadCount = showChrome ? 1 : 0;

                // Content clamp — center + cap width on tablet/desktop web.
                return BBContentMaxWidth(
                  maxWidth: 1100,
                  child: RefreshIndicator(
                    color: c.primary,
                    onRefresh: () async {
                      ref.invalidate(notificationsStreamProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(BBSpace.sm),
                      itemCount: groups.length + leadCount,
                      itemBuilder: (context, index) {
                        if (showChrome && index == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _buildInBodyHeader(
                                context,
                                unread: unreadCount,
                                total: totalCount,
                                isCompact: isCompact,
                                canMarkAll: canMarkAll,
                              ),
                              _buildFilterChips(
                                context,
                                allNotifications,
                                unreadCount,
                              ),
                              if (groups.isEmpty)
                                _buildFilterNoResults(context),
                            ],
                          );
                        }

                        final dateKey = groups.keys.elementAt(
                          index - leadCount,
                        );
                        final dayNotifications = groups[dateKey]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: BBSpace.sm,
                                bottom: BBSpace.xs,
                              ),
                              child: BbSectionHeader(
                                title: dateKey,
                                count: dayNotifications.length,
                                level: BbSectionHeaderLevel.h3,
                              ),
                            ),
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
                  ),
                );
              },
              loading: SkeletonLoader.notificationsList,
              error: (error, stack) {
                return _buildErrorState(context, error, ref);
              },
            ),

            // Loading overlay during delete — use textPrimary token (dark/light
            // aware) instead of raw Colors.black so OLED dark surfaces stay.
            if (_isDeleting)
              ColoredBox(
                color: c.textPrimary.withValues(
                  alpha: BBOpacity.semiTransparent,
                ),
                child: Center(
                  child: BbCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BbSpinner(size: 28, color: c.primary),
                        const SizedBox(height: BBSpace.sm),
                        Text(
                          l10n.notificationsDeleting,
                          style: BBType.body(context),
                        ),
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
              backgroundColor: c.primary,
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
      toolbarHeight: 56,
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

        if (_selectedIds.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: _deleteSelected,
            tooltip: l10n.notificationsDeleteSelectedBtn,
          ),

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
              // Raw `Colors.red` ignores the theme: on the OLED dark surface it
              // stays a saturated pure red that fails contrast. The error token
              // carries the dark-mode variant.
              child: Row(
                children: [
                  Icon(Icons.delete_forever, color: BBColor.of(ctx).error),
                  const SizedBox(width: 12),
                  Text(
                    l10n.notificationsDeleteAllBtn,
                    style: TextStyle(color: BBColor.of(ctx).error),
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
      return Padding(
        padding: const EdgeInsets.only(bottom: BBSpace.xs),
        child: _NotificationRow(
          key: ValueKey('notif_row_${notification.id}'),
          notification: notification,
          iconName: _getNotificationIconName(notification.type),
          accentTone: _getNotificationAccent(notification.type),
          selected: isSelected,
          onTap: () => _toggleSelection(notification.id),
          showCheckbox: true,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: BBSpace.xs),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BBRadius.mdAll,
          ),
          child: const BbIcon(name: 'delete', color: Colors.white, size: 28),
        ),
        confirmDismiss: (direction) async {
          final l10n = AppLocalizations.of(context);
          return await _confirm(
            title: l10n.notificationsDeleteNotification,
            content: l10n.notificationsDeleteNotificationDesc,
            confirmText: l10n.delete,
            cancelText: l10n.cancel,
            isDestructive: true,
          );
        },
        onDismissed: (direction) async {
          await actions.deleteNotification(notification.id);
        },
        child: _NotificationRow(
          key: ValueKey('notif_row_${notification.id}'),
          notification: notification,
          iconName: _getNotificationIconName(notification.type),
          accentTone: _getNotificationAccent(notification.type),
          onTap: () async {
            if (!notification.isRead) {
              await actions.markAsRead(notification.id);
            }
            if (notification.bookingId != null && context.mounted) {
              context.go(
                Uri(
                  path: OwnerRoutes.bookings,
                  queryParameters: {'bookingId': notification.bookingId},
                ).toString(),
              );
            }
          },
          // audit/114 F3 — inline approve/reject ONLY for actionable bookings.
          onApprove:
              notification.type == NotificationType.bookingCreated &&
                  notification.bookingId != null
              ? () => _runBookingAction(
                  context,
                  actions: actions,
                  notification: notification,
                  approve: true,
                )
              : null,
          onReject:
              notification.type == NotificationType.bookingCreated &&
                  notification.bookingId != null
              ? () => _runBookingAction(
                  context,
                  actions: actions,
                  notification: notification,
                  approve: false,
                )
              : null,
        ),
      ),
    );
  }

  /// Run an inline approve / reject for a `bookingCreated` notification,
  /// then mark-read and surface a snackbar — best-effort, all wrapped so a
  /// repository error never tears down the screen. audit/114 F3.
  Future<void> _runBookingAction(
    BuildContext context, {
    required NotificationActions actions,
    required NotificationModel notification,
    required bool approve,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final bookingId = notification.bookingId;
    if (bookingId == null) return;

    try {
      if (approve) {
        await actions.approveBooking(bookingId);
      } else {
        await actions.rejectBooking(bookingId);
      }
      // F-T3-Notif-01: markAsRead is best-effort. A stale / orphan notification
      // doc (test artifact, deleted upstream, rules-deny path) must NOT poison
      // the success toast — the success-critical write (approve/reject CF)
      // already committed above. Swallow + log.
      if (!notification.isRead) {
        try {
          await actions.markAsRead(notification.id);
        } catch (e) {
          debugPrint('[notifications] markAsRead best-effort failed: $e');
        }
      }
      if (!context.mounted || messenger == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? l10n.notificationApproveSuccess
                : l10n.notificationRejectSuccess,
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted || messenger == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? l10n.notificationApproveError
                : l10n.notificationRejectError,
          ),
        ),
      );
    }
  }

  /// Build empty state with entrance animation
  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(BBSpace.lg),
        child:
            BbEmptyState(
              icon: 'notifications_off',
              title: l10n.notificationsEmpty,
              body: l10n.notificationsEmptyDesc,
            ).animate().fadeIn(
              duration: BBMotionBridges.normal,
              curve: BBMotionBridges.easeOut,
            ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BBSpace.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: c.error.withValues(alpha: 0.10),
                borderRadius: BBRadius.lgAll,
              ),
              child: Center(
                child: BbIcon(name: 'error', size: 44, color: c.error),
              ),
            ),
            const SizedBox(height: BBSpace.md),
            Text(
              l10n.notificationsLoadError,
              style: BBType.h2(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BBSpace.xs),
            Text(
              error.toString(),
              style: BBType.body(context).copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: BBSpace.md),
            BbButton(
              label: l10n.notificationsTryAgain,
              iconLeft: 'refresh',
              onPressed: () => ref.invalidate(notificationsStreamProvider),
            ),
          ],
        ),
      ),
    );
  }

  /// In-body premium header (audit/141): title + "X unread · total Y" + the
  /// wired mark-all-read action. On mobile the AppBar owns the title and the
  /// action, so this collapses to just the count caption.
  Widget _buildInBodyHeader(
    BuildContext context, {
    required int unread,
    required int total,
    required bool isCompact,
    required bool canMarkAll,
  }) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);

    final Widget countLine = Text(
      l10n.notificationsUnreadOfTotal(unread, total),
      style: BBType.caption(context).copyWith(
        color: c.textTertiary,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: BBSpace.sm),
        child: Align(alignment: Alignment.centerLeft, child: countLine),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: BBSpace.xs, bottom: BBSpace.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(l10n.notificationsTitle, style: BBType.h1(context)),
                const SizedBox(height: 2),
                countLine,
              ],
            ),
          ),
          if (canMarkAll) ...<Widget>[
            const SizedBox(width: BBSpace.sm),
            BbButton(
              label: l10n.notificationsMarkAllRead,
              iconLeft: 'done_all',
              variant: BbButtonVariant.tertiary,
              size: BbButtonSize.sm,
              onPressed: _markAllRead,
            ),
          ],
        ],
      ),
    );
  }

  /// Data-honest filter chips — only the 5 real [NotificationType]s are
  /// represented. Booking* types fold into one "Rezervacije" chip.
  Widget _buildFilterChips(
    BuildContext context,
    List<NotificationModel> all,
    int unread,
  ) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);

    void select(_NotifFilter f) => setState(() => _activeFilter = f);

    return Padding(
      padding: const EdgeInsets.only(bottom: BBSpace.sm),
      child: Wrap(
        spacing: BBSpace.xs,
        runSpacing: BBSpace.xs,
        children: <Widget>[
          BbChip(
            label: l10n.notificationsFilterAll,
            selected: _activeFilter == _NotifFilter.all,
            count: all.length,
            onTap: () => select(_NotifFilter.all),
          ),
          BbChip(
            label: l10n.notificationsFilterUnread,
            selected: _activeFilter == _NotifFilter.unread,
            dotColor: _activeFilter == _NotifFilter.unread ? null : c.primary,
            count: unread,
            onTap: () => select(_NotifFilter.unread),
          ),
          BbChip(
            label: l10n.notificationsFilterBookings,
            selected: _activeFilter == _NotifFilter.bookings,
            iconLeft: 'event_available',
            onTap: () => select(_NotifFilter.bookings),
          ),
          BbChip(
            label: l10n.notificationsFilterPayments,
            selected: _activeFilter == _NotifFilter.payments,
            iconLeft: 'payments',
            onTap: () => select(_NotifFilter.payments),
          ),
          BbChip(
            label: l10n.notificationsFilterSystem,
            selected: _activeFilter == _NotifFilter.system,
            iconLeft: 'settings',
            onTap: () => select(_NotifFilter.system),
          ),
        ],
      ),
    );
  }

  /// Shown when an active filter matches nothing (but notifications exist).
  Widget _buildFilterNoResults(BuildContext context) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BBSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          BbIcon(name: 'filter_list_off', size: 40, color: c.textTertiary),
          const SizedBox(height: BBSpace.sm),
          Text(
            l10n.notificationsFilterNoResults,
            style: BBType.body(context).copyWith(color: c.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Get notification icon name (Material Symbols) based on type
  String _getNotificationIconName(NotificationType type) => switch (type) {
    NotificationType.bookingCreated => 'event_available',
    NotificationType.bookingUpdated => 'edit_calendar',
    NotificationType.bookingCancelled => 'event_busy',
    NotificationType.paymentReceived => 'payments',
    NotificationType.system => 'notifications',
  };

  /// Map notification type → BbCard accent tone (handoff tone palette)
  BbCardAccentTone _getNotificationAccent(NotificationType type) =>
      switch (type) {
        NotificationType.bookingCreated => BbCardAccentTone.tertiary,
        NotificationType.bookingUpdated => BbCardAccentTone.info,
        NotificationType.bookingCancelled => BbCardAccentTone.error,
        NotificationType.paymentReceived => BbCardAccentTone.success,
        NotificationType.system => BbCardAccentTone.primary,
      };
}

/// Notification list row built on BbCard.
///
/// Variants:
/// * default (read) — flat card
/// * unread — accent-left bar (per handoff `--bb-primary` 3px stripe)
/// * selection mode — leading checkbox + `selected` border
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    super.key,
    required this.notification,
    required this.iconName,
    required this.accentTone,
    required this.onTap,
    this.selected = false,
    this.showCheckbox = false,
    this.onApprove,
    this.onReject,
  });

  final NotificationModel notification;
  final String iconName;
  final BbCardAccentTone accentTone;
  final VoidCallback onTap;
  final bool selected;
  final bool showCheckbox;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  Color _accentColor(BBColorSet c) {
    switch (accentTone) {
      case BbCardAccentTone.primary:
        return c.primary;
      case BbCardAccentTone.tertiary:
        return c.tertiary;
      case BbCardAccentTone.success:
        return c.success;
      case BbCardAccentTone.error:
        return c.error;
      case BbCardAccentTone.info:
        return c.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final isUnread = !notification.isRead;
    final l10n = AppLocalizations.of(context);
    final localizer = NotificationLocalizer(l10n);
    final accent = _accentColor(c);

    return BbCard(
      onTap: onTap,
      hoverable: true,
      selected: selected,
      padded: false,
      padding: const EdgeInsets.fromLTRB(
        BBSpace.sm,
        BBSpace.sm,
        BBSpace.sm,
        BBSpace.sm,
      ),
      variant: isUnread ? BbCardVariant.accentLeft : BbCardVariant.defaultStyle,
      accentTone: accentTone,
      semanticLabel: localizer.getTitle(notification),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showCheckbox) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8, right: BBSpace.xs),
              child: IgnorePointer(
                child: BbCheckbox(value: selected, onChanged: (_) {}),
              ),
            ),
          ],
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BBRadius.smAll,
            ),
            child: Center(
              child: BbIcon(name: iconName, color: accent),
            ),
          ),
          const SizedBox(width: BBSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        localizer.getTitle(notification),
                        style: BBType.label(context).copyWith(
                          fontWeight: isUnread
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: c.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: BBSpace.xs),
                    Text(
                      localizer.getRelativeTime(notification),
                      style: BBType.caption(context).copyWith(
                        color: c.textTertiary,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    if (isUnread) ...<Widget>[
                      const SizedBox(width: BBSpace.xs),
                      // Decorative unread indicator — screen-reader sees
                      // the card-level semanticLabel instead.
                      ExcludeSemantics(
                        child: Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: c.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  localizer.getMessage(notification),
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textSecondary, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // audit/114 F3 — inline approve/reject row, only when both
                // callbacks supplied (parent enforces the type+bookingId gate).
                if (onApprove != null && onReject != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: BbButton(
                          key: ValueKey('notif_approve_${notification.id}'),
                          label: AppLocalizations.of(
                            context,
                          ).notificationActionApprove,
                          iconLeft: 'check',
                          variant: BbButtonVariant.success,
                          size: BbButtonSize.sm,
                          fullWidth: true,
                          onPressed: onApprove,
                          semanticLabel: AppLocalizations.of(
                            context,
                          ).notificationActionApprove,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: BbButton(
                          key: ValueKey('notif_reject_${notification.id}'),
                          label: AppLocalizations.of(
                            context,
                          ).notificationActionReject,
                          iconLeft: 'close',
                          variant: BbButtonVariant.destructiveSoft,
                          size: BbButtonSize.sm,
                          fullWidth: true,
                          onPressed: onReject,
                          semanticLabel: AppLocalizations.of(
                            context,
                          ).notificationActionReject,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Hide chevron when inline actions are present — chevron + buttons
          // double-up on affordance, so favour the explicit actions.
          if (!showCheckbox && onApprove == null) ...<Widget>[
            const SizedBox(width: BBSpace.xs),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: BbIcon(
                name: 'chevron_right',
                size: 18,
                color: c.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
