import '../../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/models/user_model.dart';
import '../../data/admin_users_repository.dart';

/// Responsive breakpoint for mobile layout
const double _mobileBreakpoint = 800.0;

/// Sort fields available for user list
enum _SortField { name, email, createdAt }

/// Users list screen with responsive layout and modern styling
class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Filters
  final Set<AccountType> _selectedAccountTypes = {};
  DateTimeRange? _dateRange;

  // Sort
  _SortField _sortField = _SortField.createdAt;
  bool _sortAscending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _filterAndSortOwners(List<UserModel> owners) {
    var result = owners.toList();

    // Text search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((user) {
        final name = (user.displayName ?? user.fullName).toLowerCase();
        final email = user.email.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    // Account type filter
    if (_selectedAccountTypes.isNotEmpty) {
      result = result
          .where((user) => _selectedAccountTypes.contains(user.accountType))
          .toList();
    }

    // Date range filter
    if (_dateRange != null) {
      result = result.where((user) {
        if (user.createdAt == null) return false;
        return !user.createdAt!.isBefore(_dateRange!.start) &&
            !user.createdAt!.isAfter(
              _dateRange!.end.add(const Duration(days: 1)),
            );
      }).toList();
    }

    // Sort
    result.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case _SortField.name:
          cmp = (a.displayName ?? a.fullName).toLowerCase().compareTo(
            (b.displayName ?? b.fullName).toLowerCase(),
          );
        case _SortField.email:
          cmp = a.email.toLowerCase().compareTo(b.email.toLowerCase());
        case _SortField.createdAt:
          cmp = (a.createdAt ?? DateTime(2000)).compareTo(
            b.createdAt ?? DateTime(2000),
          );
      }
      return _sortAscending ? cmp : -cmp;
    });

    return result;
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedAccountTypes.isNotEmpty ||
      _dateRange != null;

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedAccountTypes.clear();
      _dateRange = null;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) => Theme(
        data: ThemeData.light(useMaterial3: true).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownersAsync = ref.watch(ownersListProvider);
    final notifier = ref.read(ownersListProvider.notifier);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < _mobileBreakpoint;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Users Management',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Manage platform owners and licenses',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: notifier.loadInitial,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                // Filters Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Account type filter chips
                      for (final type in AccountType.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(type.name.toUpperCase()),
                            selected: _selectedAccountTypes.contains(type),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAccountTypes.add(type);
                                } else {
                                  _selectedAccountTypes.remove(type);
                                }
                              });
                            },
                            selectedColor: AppColors.primary.withValues(
                              alpha: 0.15,
                            ),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: _selectedAccountTypes.contains(type)
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _selectedAccountTypes.contains(type)
                                  ? AppColors.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      // Date range chip
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: Icon(
                            Icons.date_range,
                            size: 16,
                            color: _dateRange != null
                                ? AppColors.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          label: Text(
                            _dateRange != null
                                ? '${_dateRange!.start.day}.${_dateRange!.start.month}.${_dateRange!.start.year} - ${_dateRange!.end.day}.${_dateRange!.end.month}.${_dateRange!.end.year}'
                                : 'Date Range',
                          ),
                          onPressed: _pickDateRange,
                          backgroundColor: _dateRange != null
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : null,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: _dateRange != null
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: _dateRange != null
                                ? AppColors.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Sort dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<_SortField>(
                            value: _sortField,
                            isDense: true,
                            icon: Icon(
                              _sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 14,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: _SortField.createdAt,
                                child: Text('Sort: Created'),
                              ),
                              DropdownMenuItem(
                                value: _SortField.name,
                                child: Text('Sort: Name'),
                              ),
                              DropdownMenuItem(
                                value: _SortField.email,
                                child: Text('Sort: Email'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                if (_sortField == value) {
                                  _sortAscending = !_sortAscending;
                                } else {
                                  _sortField = value;
                                  _sortAscending =
                                      value != _SortField.createdAt;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      // Clear filters button
                      if (_hasActiveFilters)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ActionChip(
                            avatar: const Icon(
                              Icons.clear_all,
                              size: 16,
                              color: Colors.red,
                            ),
                            label: const Text('Clear'),
                            onPressed: _clearAllFilters,
                            labelStyle: const TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ownersAsync.when(
              data: (owners) {
                final filtered = _filterAndSortOwners(owners);
                if (filtered.isEmpty) {
                  return const _EmptyState();
                }
                // Hide Load More when filters are active - client-side
                // filtering on paginated data would be misleading
                final showLoadMore = notifier.hasMore && !_hasActiveFilters;
                return isMobile
                    ? _UsersList(
                        owners: filtered,
                        hasMore: showLoadMore,
                        onLoadMore: notifier.loadMore,
                      )
                    : _UsersTable(
                        owners: filtered,
                        hasMore: showLoadMore,
                        onLoadMore: notifier.loadMore,
                      );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error loading users: $err'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: notifier.loadInitial,
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

/// Mobile list view with cards
class _UsersList extends StatelessWidget {
  final List<UserModel> owners;
  final bool hasMore;
  final VoidCallback onLoadMore;

  const _UsersList({
    required this.owners,
    required this.hasMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    // +1 for load more button
    final itemCount = owners.length + (hasMore ? 1 : 0);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= owners.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more),
                label: const Text('Load more'),
              ),
            ),
          );
        }
        final user = owners[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _UserCard(user: user),
        );
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
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
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      (user.displayName ?? user.fullName).isNotEmpty
                          ? (user.displayName ?? user.fullName)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          user.displayName ?? user.fullName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                        ),
                        SelectableText(
                          user.email,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _AccountTypeBadge(type: user.accountType),
                  Text(
                    _formatDate(user.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
  final bool hasMore;
  final VoidCallback onLoadMore;

  const _UsersTable({
    required this.owners,
    required this.hasMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.surfaceContainer,
              ),
              dataRowMinHeight: 60,
              dataRowMaxHeight: 60,
              columnSpacing: 24,
              horizontalMargin: 24,
              columns: const [
                DataColumn(
                  label: Text(
                    'Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Account Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Created At',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: owners.map((user) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              (user.displayName ?? user.fullName).isNotEmpty
                                  ? (user.displayName ?? user.fullName)[0]
                                        .toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SelectableText(
                            user.displayName ?? user.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    DataCell(SelectableText(user.email)),
                    DataCell(_AccountTypeBadge(type: user.accountType)),
                    DataCell(Text(_formatDate(user.createdAt))),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        tooltip: 'View Details',
                        onPressed: () => context.go('/users/${user.id}'),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.expand_more),
                  label: const Text('Load more'),
                ),
              ),
            ),
        ],
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
      AccountType.enterprise => Colors.blue,
      AccountType.lifetime => Colors.purple,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(type), size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            type.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(AccountType type) {
    return switch (type) {
      AccountType.trial => Icons.timer,
      AccountType.premium => Icons.star,
      AccountType.enterprise => Icons.business,
      AccountType.lifetime => Icons.verified,
    };
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}
