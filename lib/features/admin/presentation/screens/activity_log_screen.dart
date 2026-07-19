import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../data/admin_users_repository.dart';

/// Max-width of the centered event list on desktop. No-op below 1000px.
const double _kLogListMaxWidth = 1000.0;

/// Activity log screen showing admin actions and security events.
///
/// Admin is dark-only + desktop-first: surfaces resolve from canonical
/// [BbAdminDarkTokens] (shell paints [BbAdminDarkTokens.shellBg] behind this
/// transparent Scaffold), event cards use [BbCard] + [BbIcon], and the list
/// clamps to a readable centered max-width on desktop.
class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(activityLogProvider);
    final t = BbAdminDarkTokens.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.all(BBSpace.lg),
            decoration: BoxDecoration(
              color: t.panelBg,
              border: Border(bottom: BorderSide(color: t.divider, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity Log',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: t.textPrimary,
                            ),
                      ),
                      Text(
                        'Admin actions and security events',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: t.textSecondary),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(activityLogProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: logAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BbIcon(
                          name: 'history',
                          size: 64,
                          color: t.textTertiary,
                        ),
                        const SizedBox(height: BBSpace.sm),
                        Text(
                          'No activity yet',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: t.textTertiary),
                        ),
                        const SizedBox(height: BBSpace.xs),
                        Text(
                          'Admin actions will appear here',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: t.textTertiary),
                        ),
                      ],
                    ),
                  );
                }
                // Desktop-first: clamp the list to a readable centered width so
                // event rows don't stretch edge-to-edge on 1440. No-op < 1000.
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _kLogListMaxWidth,
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(BBSpace.lg),
                      itemCount: events.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: BBSpace.sm),
                      itemBuilder: (context, index) {
                        return _ActivityEventCard(event: events[index]);
                      },
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error loading activity log: $err'),
                    const SizedBox(height: BBSpace.md),
                    FilledButton(
                      onPressed: () => ref.invalidate(activityLogProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityEventCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const _ActivityEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final t = BbAdminDarkTokens.of(context);
    final type = event['type'] as String? ?? 'unknown';
    final action = event['action'] as String? ?? '';
    final targetEmail = event['target_user_email'] as String? ?? '';
    final targetUserId = event['target_user_id'] as String? ?? '';
    final adminUid = event['admin_uid'] as String? ?? '';
    final previousType = event['previous_account_type'] as String? ?? '';
    final newType = event['new_account_type'] as String? ?? '';
    final timestamp = event['timestamp'];

    final eventInfo = _getEventInfo(context, type, action);

    String formattedTime = '-';
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate().toLocal();
      formattedTime =
          '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Semantics(
      container: true,
      label: '${eventInfo.title}, $formattedTime',
      child: BbCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon tile
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: eventInfo.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: BbIcon(name: eventInfo.iconName, color: eventInfo.color),
            ),
            const SizedBox(width: BBSpace.sm),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventInfo.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (targetEmail.isNotEmpty)
                    SelectableText(
                      'User: $targetEmail',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: t.textSecondary),
                    ),
                  if (previousType.isNotEmpty && newType.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '$previousType → $newType',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: t.textSecondary,
                        ),
                      ),
                    ),
                  if (targetUserId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: SelectableText(
                        'ID: $targetUserId',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: t.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  if (adminUid.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: SelectableText(
                        'Admin: $adminUid',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: t.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Timestamp
            Text(
              formattedTime,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: t.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _EventInfo _getEventInfo(BuildContext context, String type, String action) {
    switch (type) {
      case 'lifetime_license_change':
        if (action == 'granted') {
          return _EventInfo(
            title: 'Lifetime License Granted',
            iconName: 'verified',
            color: AppColors.primary,
          );
        }
        return _EventInfo(
          title: 'Lifetime License Revoked',
          iconName: 'remove_circle',
          color: AppColors.warning,
        );
      case 'status_change':
        return _EventInfo(
          title: 'User Status Changed',
          iconName: 'sync_alt',
          color: AppColors.info,
        );
      default:
        return _EventInfo(
          title: type.replaceAll('_', ' ').toUpperCase(),
          iconName: 'info',
          color: BbAdminDarkTokens.of(context).textTertiary,
        );
    }
  }
}

class _EventInfo {
  final String title;
  final String iconName;
  final Color color;

  _EventInfo({
    required this.title,
    required this.iconName,
    required this.color,
  });
}
