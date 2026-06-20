import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/admin_users_repository.dart';
import 'admin_shell_screen.dart';

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
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
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
    final palette = _UsersListPalette.of(context, ref);

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Content-width breakpoint (audit/122, doc deleted — git history):
      // the adaptive shell reserves
      // 260/72px for sidebar/rail, so window width over-reports space.
      body: LayoutBuilder(
        builder: (context, constraints) => _buildBody(
          context,
          ownersAsync,
          notifier,
          palette,
          constraints.maxWidth < _mobileBreakpoint,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<UserModel>> ownersAsync,
    OwnersListNotifier notifier,
    _UsersListPalette palette,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(BBSpace.md),
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
                        const BbSectionHeader(title: 'Users Management'),
                        Text(
                          'Manage platform owners and licenses',
                          style: BBType.body(
                            context,
                          ).copyWith(color: palette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  BbButton(
                    label: 'Refresh',
                    iconLeft: 'refresh',
                    onPressed: notifier.loadInitial,
                  ),
                ],
              ),
              const SizedBox(height: BBSpace.sm),
              BbInput(
                controller: _searchController,
                placeholder: 'Search users by name or email...',
                iconLeft: 'search',
                trailingAction: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: BBSpace.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final type in AccountType.values)
                      Padding(
                        padding: const EdgeInsets.only(right: BBSpace.xs),
                        child: BbChip(
                          label: type.name.toUpperCase(),
                          selected: _selectedAccountTypes.contains(type),
                          size: BbChipSize.sm,
                          onTap: () {
                            setState(() {
                              if (_selectedAccountTypes.contains(type)) {
                                _selectedAccountTypes.remove(type);
                              } else {
                                _selectedAccountTypes.add(type);
                              }
                            });
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: BBSpace.xs),
                      child: BbChip(
                        label: _dateRange != null
                            ? '${_dateRange!.start.day}.${_dateRange!.start.month}.${_dateRange!.start.year} - ${_dateRange!.end.day}.${_dateRange!.end.month}.${_dateRange!.end.year}'
                            : 'Date Range',
                        iconLeft: 'date_range',
                        selected: _dateRange != null,
                        size: BbChipSize.sm,
                        onTap: _pickDateRange,
                      ),
                    ),
                    const SizedBox(width: BBSpace.xs),
                    _SortDropdown(
                      sortField: _sortField,
                      sortAscending: _sortAscending,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          if (_sortField == value) {
                            _sortAscending = !_sortAscending;
                          } else {
                            _sortField = value;
                            _sortAscending = value != _SortField.createdAt;
                          }
                        });
                      },
                    ),
                    if (_hasActiveFilters)
                      Padding(
                        padding: const EdgeInsets.only(left: BBSpace.xs),
                        child: BbChip(
                          label: 'Clear',
                          iconLeft: 'clear_all',
                          size: BbChipSize.sm,
                          onTap: _clearAllFilters,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ownersAsync.when(
            data: (owners) {
              final filtered = _filterAndSortOwners(owners);
              if (filtered.isEmpty) {
                return const _EmptyState();
              }
              final showLoadMore = notifier.hasMore && !_hasActiveFilters;
              return isMobile
                  ? _UsersList(
                      owners: filtered,
                      hasMore: showLoadMore,
                      onLoadMore: notifier.loadMore,
                      palette: palette,
                    )
                  : _UsersTable(
                      owners: filtered,
                      hasMore: showLoadMore,
                      onLoadMore: notifier.loadMore,
                      palette: palette,
                    );
            },
            loading: () => const Center(child: BbSpinner(size: 24)),
            error: (err, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error loading users: $err',
                    style: BBType.body(
                      context,
                    ).copyWith(color: palette.textSecondary),
                  ),
                  const SizedBox(height: BBSpace.sm),
                  BbButton(label: 'Retry', onPressed: notifier.loadInitial),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UsersList extends StatelessWidget {
  final List<UserModel> owners;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final _UsersListPalette palette;

  const _UsersList({
    required this.owners,
    required this.hasMore,
    required this.onLoadMore,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = owners.length + (hasMore ? 1 : 0);
    return ListView.builder(
      padding: const EdgeInsets.all(BBSpace.sm),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= owners.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: BBSpace.sm),
            child: Center(
              child: BbButton(
                label: 'Load more',
                iconLeft: 'expand_more',
                variant: BbButtonVariant.secondary,
                onPressed: onLoadMore,
              ),
            ),
          );
        }
        final user = owners[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: BBSpace.sm),
          child: _UserCard(user: user, palette: palette),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final _UsersListPalette palette;

  const _UserCard({required this.user, required this.palette});

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName ?? user.fullName;
    return BbCard(
      hoverable: true,
      onTap: () => context.go('/users/${user.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BbAvatar(name: displayName, size: BbAvatarSize.sm),
              const SizedBox(width: BBSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      displayName,
                      style: BBType.h3(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                      maxLines: 1,
                    ),
                    SelectableText(
                      user.email,
                      style: BBType.caption(
                        context,
                      ).copyWith(color: palette.textSecondary),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AccountTypeBadge(type: user.accountType),
              Text(
                _formatDate(user.createdAt),
                style: BBType.caption(
                  context,
                ).copyWith(color: palette.textTertiary),
              ),
            ],
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

class _UsersTable extends StatelessWidget {
  final List<UserModel> owners;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final _UsersListPalette palette;

  const _UsersTable({
    required this.owners,
    required this.hasMore,
    required this.onLoadMore,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final headingStyle = BBType.label(
      context,
    ).copyWith(color: palette.textSecondary, fontWeight: FontWeight.bold);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(BBSpace.md),
      child: Column(
        children: [
          BbCard(
            padded: false,
            // Horizontal scroll keeps the 5-column table usable in the
            // 800-1100px window (below the <800 card fallback). minWidth ties
            // the table to the card width so it fills on wide screens and only
            // scrolls when content overflows.
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 60,
                    columnSpacing: BBSpace.md,
                    horizontalMargin: BBSpace.md,
                    columns: [
                      DataColumn(label: Text('Name', style: headingStyle)),
                      DataColumn(label: Text('Email', style: headingStyle)),
                      DataColumn(
                        label: Text('Account Type', style: headingStyle),
                      ),
                      DataColumn(
                        label: Text('Created At', style: headingStyle),
                      ),
                      DataColumn(label: Text('Actions', style: headingStyle)),
                    ],
                    rows: owners.map((user) {
                      final displayName = user.displayName ?? user.fullName;
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                BbAvatar(
                                  name: displayName,
                                  size: BbAvatarSize.xs,
                                ),
                                const SizedBox(width: BBSpace.sm),
                                SelectableText(
                                  displayName,
                                  style: BBType.body(context).copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            SelectableText(
                              user.email,
                              style: BBType.body(
                                context,
                              ).copyWith(color: palette.textSecondary),
                            ),
                          ),
                          DataCell(_AccountTypeBadge(type: user.accountType)),
                          DataCell(
                            Text(
                              _formatDate(user.createdAt),
                              style: BBType.body(
                                context,
                              ).copyWith(color: palette.textSecondary),
                            ),
                          ),
                          DataCell(
                            BbButton(
                              asIcon: true,
                              iconLeft: 'arrow_forward_ios',
                              variant: BbButtonVariant.tertiary,
                              semanticLabel: 'View Details',
                              onPressed: () => context.go('/users/${user.id}'),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: BBSpace.sm),
              child: Center(
                child: BbButton(
                  label: 'Load more',
                  iconLeft: 'expand_more',
                  variant: BbButtonVariant.secondary,
                  onPressed: onLoadMore,
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
      AccountType.trial => AppColors.warning,
      AccountType.premium => AppColors.success,
      AccountType.enterprise => AppColors.info,
      AccountType.lifetime => AppColors.primary,
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
    return const Center(
      child: BbEmptyState(
        icon: 'people_outline',
        title: 'No users found',
        compact: true,
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final _SortField sortField;
  final bool sortAscending;
  final ValueChanged<_SortField?> onChanged;

  const _SortDropdown({
    required this.sortField,
    required this.sortAscending,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BBSpace.xs),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BBRadius.smAll,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_SortField>(
          value: sortField,
          isDense: true,
          icon: Icon(
            sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
          ),
          style: BBType.caption(
            context,
          ).copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          items: const [
            DropdownMenuItem(
              value: _SortField.createdAt,
              child: Text('Sort: Created'),
            ),
            DropdownMenuItem(value: _SortField.name, child: Text('Sort: Name')),
            DropdownMenuItem(
              value: _SortField.email,
              child: Text('Sort: Email'),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Text-tier color palette: admin-dark via [BbAdminDarkTokens] (#646 wires
/// the extension on the shell), or [ColorScheme] in admin-light/owner.
class _UsersListPalette {
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final bool isDark;

  const _UsersListPalette({
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.isDark,
  });

  static _UsersListPalette of(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(adminDarkModeProvider);
    if (isDark) {
      final t = BbAdminDarkTokens.of(context);
      return _UsersListPalette(
        textPrimary: t.textPrimary,
        textSecondary: t.textSecondary,
        textTertiary: t.textTertiary,
        isDark: true,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return _UsersListPalette(
      textPrimary: scheme.onSurface,
      textSecondary: scheme.onSurfaceVariant,
      textTertiary: scheme.onSurfaceVariant.withValues(alpha: 0.7),
      isDark: false,
    );
  }
}

/// Renders the owner `DataTable` surface (`_UsersTable`) in isolation for the
/// responsive overflow regression test, using a neutral light palette derived
/// from the ambient [Theme] (no Firebase / Riverpod). Not for production use —
/// see `test/features/admin/users_list_overflow_test.dart`.
@visibleForTesting
Widget buildUsersTableForTest({required List<UserModel> owners}) {
  return Builder(
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return _UsersTable(
        owners: owners,
        hasMore: false,
        onLoadMore: () {},
        palette: _UsersListPalette(
          textPrimary: scheme.onSurface,
          textSecondary: scheme.onSurfaceVariant,
          textTertiary: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          isDark: false,
        ),
      );
    },
  );
}
