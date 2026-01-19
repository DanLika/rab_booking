import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/models/user_model.dart';
import '../../data/admin_users_repository.dart';

/// Responsive breakpoint for mobile layout
const double _mobileBreakpoint = 600.0;

/// Users list screen with responsive layout
class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownersAsync = ref.watch(ownersListProvider);
    final isMobile = MediaQuery.of(context).size.width < _mobileBreakpoint;
    final padding = isMobile ? 12.0 : 24.0;

    return Scaffold(
      // No AppBar - shell provides it
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with refresh button
            Row(
              children: [
                Text(
                  'Users',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () => ref.invalidate(ownersListProvider),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            // Content
            Expanded(
              child: ownersAsync.when(
                data: (owners) => isMobile
                    ? _UsersList(owners: owners)
                    : _UsersTable(owners: owners),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error loading users: $err'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.invalidate(ownersListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mobile list view with cards
class _UsersList extends StatelessWidget {
  final List<UserModel> owners;

  const _UsersList({required this.owners});

  @override
  Widget build(BuildContext context) {
    if (owners.isEmpty) {
      return const Center(child: Text('No owners found'));
    }

    return ListView.separated(
      itemCount: owners.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = owners[index];
        return _UserCard(user: user);
      },
    );
  }
}

/// User card for mobile view
class _UserCard extends StatelessWidget {
  final UserModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/users/${user.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.deepPurple.shade100,
                    child: Text(
                      (user.displayName ?? user.fullName).isNotEmpty
                          ? (user.displayName ?? user.fullName)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? user.fullName,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _AccountTypeBadge(type: user.accountType),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Created: ${_formatDate(user.createdAt)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}.${date.month}.${date.year}';
  }
}

/// Desktop table view
class _UsersTable extends StatelessWidget {
  final List<UserModel> owners;

  const _UsersTable({required this.owners});

  @override
  Widget build(BuildContext context) {
    if (owners.isEmpty) {
      return const Center(child: Text('No owners found'));
    }

    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Account Type')),
          DataColumn(label: Text('Created')),
          DataColumn(label: Text('Actions')),
        ],
        rows: owners.map((user) {
          return DataRow(
            cells: [
              DataCell(Text(user.displayName ?? user.fullName)),
              DataCell(Text(user.email)),
              DataCell(_AccountTypeBadge(type: user.accountType)),
              DataCell(Text(_formatDate(user.createdAt))),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  onPressed: () => context.go('/users/${user.id}'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _AccountTypeBadge extends StatelessWidget {
  final AccountType type;

  const _AccountTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      AccountType.trial => Colors.orange,
      AccountType.premium => Colors.green,
      AccountType.enterprise => Colors.purple,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        type.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
