import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/admin_users_repository.dart';

/// Activity log screen showing admin actions and security events
class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(activityLogProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
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
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Admin actions and security events',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No activity yet',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).disabledColor,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Admin actions will appear here',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).disabledColor,
                              ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: events.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _ActivityEventCard(event: events[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error loading activity log: $err'),
                    const SizedBox(height: 16),
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
    final type = event['type'] as String? ?? 'unknown';
    final action = event['action'] as String? ?? '';
    final targetEmail = event['target_user_email'] as String? ?? '';
    final targetUserId = event['target_user_id'] as String? ?? '';
    final adminUid = event['admin_uid'] as String? ?? '';
    final previousType = event['previous_account_type'] as String? ?? '';
    final newType = event['new_account_type'] as String? ?? '';
    final timestamp = event['timestamp'];

    final eventInfo = _getEventInfo(type, action);

    String formattedTime = '-';
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      formattedTime =
          '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: eventInfo.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(eventInfo.icon, color: eventInfo.color, size: 20),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventInfo.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (targetEmail.isNotEmpty)
                  SelectableText(
                    'User: $targetEmail',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (previousType.isNotEmpty && newType.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '$previousType → $newType',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (targetUserId.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SelectableText(
                      'ID: $targetUserId',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  _EventInfo _getEventInfo(String type, String action) {
    switch (type) {
      case 'lifetime_license_change':
        if (action == 'granted') {
          return _EventInfo(
            title: 'Lifetime License Granted',
            icon: Icons.verified,
            color: Colors.purple,
          );
        }
        return _EventInfo(
          title: 'Lifetime License Revoked',
          icon: Icons.remove_circle_outline,
          color: Colors.orange,
        );
      case 'status_change':
        return _EventInfo(
          title: 'User Status Changed',
          icon: Icons.sync_alt,
          color: Colors.blue,
        );
      default:
        return _EventInfo(
          title: type.replaceAll('_', ' ').toUpperCase(),
          icon: Icons.info_outline,
          color: Colors.grey,
        );
    }
  }
}

class _EventInfo {
  final String title;
  final IconData icon;
  final Color color;

  _EventInfo({required this.title, required this.icon, required this.color});
}
