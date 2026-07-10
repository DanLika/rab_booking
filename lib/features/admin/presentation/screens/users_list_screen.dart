import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/admin_users_repository.dart';
import '../../providers/admin_providers.dart';
import 'admin_shell_screen.dart';
import 'user_detail_screen.dart';

/// Content-width breakpoint at/above which the Users screen renders the desktop
/// MASTER-DETAIL split (handoff `admin-users.jsx` `AdminUsersDesktop`: owners
/// table on the left + inline `AUOwnerPanel` on the right). Below it the plain
/// table (tablet) or card list (mobile) render, unchanged. This is a
/// `LayoutBuilder` content-width value (post-sidebar), NOT a MediaQuery pivot —
/// per the breakpoint-classification rule it stays a named local const.
const double _masterDetailBreakpoint = 1000.0;

/// Fixed width of the inline detail panel (handoff desktop grid `1fr 360px`).
const double _detailPanelWidth = 360.0;

/// Responsive breakpoint for the compact per-user card layout. Below this
/// width the squeezed 5-column table is replaced by handoff-style owner cards
/// (`admin-users.jsx` `AUMobileCard`, mobile breakpoint). At or above it the
/// DataTable renders (with the #765 horizontal-scroll overflow fix).
const double _mobileBreakpoint = 600.0;

/// Rows shown per page in the numbered pagination (handoff `AUPagination`).
/// Pagination windows the already-loaded + filtered owner list — it does NOT
/// fabricate a total; "of N" reflects the real loaded/filtered row count.
const int _rowsPerPage = 8;

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

  // Numbered-pagination page index (0-based) over the filtered table rows.
  int _page = 0;

  @override
  void initState() {
    super.initState();
    // Seed the local text filter from the topbar's shared owners-search query
    // (set when the admin submits the topbar search and routes here). Reuses
    // the existing filter — no separate search backend.
    final seeded = ref.read(adminOwnersSearchQueryProvider);
    if (seeded.isNotEmpty) {
      _searchQuery = seeded;
      _searchController.text = seeded;
    }
  }

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
      _page = 0;
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
      setState(() {
        _dateRange = picked;
        _page = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the local filter in sync when the topbar search is submitted while
    // this screen is already mounted (initState only runs on first mount).
    ref.listen<String>(adminOwnersSearchQueryProvider, (prev, next) {
      if (next != _searchQuery) {
        setState(() {
          _searchQuery = next;
          _searchController.text = next;
          _page = 0;
        });
      }
    });
    final ownersAsync = ref.watch(ownersListProvider);
    final notifier = ref.read(ownersListProvider.notifier);
    final palette = _UsersListPalette.of(context, ref);

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Content-width breakpoint (audit/122, doc deleted — git history):
      // the adaptive shell reserves
      // 260/72px for sidebar/rail, so window width over-reports space.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < _mobileBreakpoint;
          final isMasterDetail = width >= _masterDetailBreakpoint;
          final listColumn = _buildBody(
            context,
            ownersAsync,
            notifier,
            palette,
            isMobile,
            isMasterDetail,
          );
          if (!isMasterDetail) return listColumn;
          // Desktop master-detail split: owners list on the left, inline detail
          // panel on the right (handoff `AdminUsersDesktop` `1fr 360px`).
          final selectedId = ref.watch(adminSelectedOwnerIdProvider);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: listColumn),
              Container(
                width: _detailPanelWidth,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                ),
                child: selectedId == null
                    ? _DetailPanelPlaceholder(palette: palette)
                    : UserDetailScreen(
                        key: ValueKey('embedded_detail_$selectedId'),
                        userId: selectedId,
                        embedded: true,
                        onClose: () =>
                            ref
                                    .read(adminSelectedOwnerIdProvider.notifier)
                                    .state =
                                null,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<UserModel>> ownersAsync,
    OwnersListNotifier notifier,
    _UsersListPalette palette,
    bool isMobile,
    bool isMasterDetail,
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
                          setState(() {
                            _searchQuery = '';
                            _page = 0;
                          });
                        },
                      )
                    : null,
                onChanged: (value) => setState(() {
                  _searchQuery = value;
                  _page = 0;
                }),
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
                              _page = 0;
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
                          _page = 0;
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
              if (isMobile) {
                return _UsersList(
                  owners: filtered,
                  hasMore: showLoadMore,
                  onLoadMore: notifier.loadMore,
                  palette: palette,
                );
              }
              // Numbered pagination windows the loaded+filtered rows. Clamp the
              // page against the current row count (a filter can shrink it).
              final pageCount = (filtered.length / _rowsPerPage).ceil().clamp(
                1,
                1 << 30,
              );
              final page = _page.clamp(0, pageCount - 1);
              final start = page * _rowsPerPage;
              final end = (start + _rowsPerPage).clamp(0, filtered.length);
              final pageRows = filtered.sublist(start, end);
              // In the desktop master-detail split, selecting a row populates
              // the inline panel instead of navigating to `/users/:id`.
              final selectedId = isMasterDetail
                  ? ref.watch(adminSelectedOwnerIdProvider)
                  : null;
              return _UsersTable(
                owners: pageRows,
                totalRows: filtered.length,
                page: page,
                pageCount: pageCount,
                rangeStart: start + 1,
                rangeEnd: end,
                onPageChanged: (p) => setState(() => _page = p),
                // "Load more" pulls the next Firestore page into the loaded set,
                // extending what numbered pagination can window.
                hasMore: showLoadMore,
                onLoadMore: notifier.loadMore,
                palette: palette,
                selectedId: selectedId,
                onSelect: isMasterDetail
                    ? (id) =>
                          ref
                                  .read(adminSelectedOwnerIdProvider.notifier)
                                  .state =
                              id
                    : null,
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
            children: [
              _AccountTypeBadge(type: user.accountType),
              const SizedBox(width: BBSpace.sm),
              Expanded(
                child: Text(
                  _formatDate(user.createdAt),
                  style: BBType.caption(
                    context,
                  ).copyWith(color: palette.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: palette.textTertiary),
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

  // Numbered-pagination inputs. Defaults keep the widget usable in the
  // `buildUsersTableForTest` seam (single page, no controls) without churn.
  final int totalRows;
  final int page;
  final int pageCount;
  final int rangeStart;
  final int rangeEnd;
  final ValueChanged<int>? onPageChanged;

  /// When non-null the table is in master-detail mode: a row tap calls
  /// [onSelect] (populating the inline panel) instead of navigating to
  /// `/users/:id`, and the matching [selectedId] row is highlighted.
  final ValueChanged<String>? onSelect;
  final String? selectedId;

  _UsersTable({
    required this.owners,
    required this.hasMore,
    required this.onLoadMore,
    required this.palette,
    int? totalRows,
    this.page = 0,
    this.pageCount = 1,
    int? rangeStart,
    int? rangeEnd,
    this.onPageChanged,
    this.onSelect,
    this.selectedId,
  }) : totalRows = totalRows ?? owners.length,
       rangeStart = rangeStart ?? (owners.isEmpty ? 0 : 1),
       rangeEnd = rangeEnd ?? owners.length;

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
                      final isSelected =
                          onSelect != null && selectedId == user.id;
                      return DataRow(
                        selected: isSelected,
                        color: isSelected
                            ? WidgetStatePropertyAll(
                                AppColors.primary.withValues(alpha: 0.08),
                              )
                            : null,
                        onSelectChanged: onSelect != null
                            ? (_) => onSelect!(user.id)
                            : null,
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
                              onPressed: onSelect != null
                                  ? () => onSelect!(user.id)
                                  : () => context.go('/users/${user.id}'),
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
          if (pageCount > 1 || onPageChanged != null)
            Padding(
              padding: const EdgeInsets.only(top: BBSpace.sm),
              child: _UsersPagination(
                page: page,
                pageCount: pageCount,
                rangeStart: rangeStart,
                rangeEnd: rangeEnd,
                totalRows: totalRows,
                palette: palette,
                onPageChanged: onPageChanged ?? (_) {},
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

/// Numbered pagination bar (handoff `admin-users.jsx` `AUPagination`):
/// "Showing X–Y of N" on the left, prev / numbered page buttons (with an
/// ellipsis gap for long runs) / next on the right. Windows the loaded+filtered
/// owner rows — the "of N" total is the real loaded/filtered count, not a
/// fabricated server total.
class _UsersPagination extends StatelessWidget {
  final int page; // 0-based
  final int pageCount;
  final int rangeStart; // 1-based, inclusive
  final int rangeEnd; // 1-based, inclusive
  final int totalRows;
  final _UsersListPalette palette;
  final ValueChanged<int> onPageChanged;

  const _UsersPagination({
    required this.page,
    required this.pageCount,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalRows,
    required this.palette,
    required this.onPageChanged,
  });

  /// 1-based page numbers to show, with `null` marking an ellipsis gap.
  /// Always shows first + last + a window around the current page.
  List<int?> _pageItems() {
    if (pageCount <= 7) {
      return [for (var i = 1; i <= pageCount; i++) i];
    }
    final current = page + 1;
    final items = <int>{1};
    for (var i = current - 1; i <= current + 1; i++) {
      if (i >= 1 && i <= pageCount) items.add(i);
    }
    items.add(pageCount);
    final sorted = items.toList()..sort();
    final out = <int?>[];
    int? prev;
    for (final n in sorted) {
      if (prev != null && n - prev > 1) out.add(null);
      out.add(n);
      prev = n;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final items = _pageItems();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BBSpace.xs),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: BBSpace.xs,
        spacing: BBSpace.sm,
        children: [
          Text(
            'Showing $rangeStart–$rangeEnd of $totalRows',
            key: const ValueKey('users_pagination_range'),
            style: BBType.caption(
              context,
            ).copyWith(color: palette.textTertiary),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BbButton(
                asIcon: true,
                iconLeft: 'chevron_left',
                variant: BbButtonVariant.secondary,
                semanticLabel: 'Previous page',
                onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
              ),
              const SizedBox(width: BBSpace.xs),
              for (final n in items) ...[
                if (n == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '…',
                      style: BBType.body(
                        context,
                      ).copyWith(color: palette.textTertiary),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _PageButton(
                      number: n,
                      selected: n == page + 1,
                      palette: palette,
                      onTap: () => onPageChanged(n - 1),
                    ),
                  ),
              ],
              const SizedBox(width: BBSpace.xs),
              BbButton(
                asIcon: true,
                iconLeft: 'chevron_right',
                variant: BbButtonVariant.secondary,
                semanticLabel: 'Next page',
                onPressed: page < pageCount - 1
                    ? () => onPageChanged(page + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single numbered page button (handoff: 32×32, radius 8, primary fill when
/// selected).
class _PageButton extends StatelessWidget {
  final int number;
  final bool selected;
  final _UsersListPalette palette;
  final VoidCallback onTap;

  const _PageButton({
    required this.number,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.primary
        : Theme.of(context).dividerColor;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Page $number',
      child: InkWell(
        key: ValueKey('users_page_$number'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            '$number',
            style: BBType.label(context).copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : palette.textSecondary,
            ),
          ),
        ),
      ),
    );
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

/// Empty placeholder shown in the desktop master-detail panel before an owner
/// row is selected (handoff has an owner pre-selected; we start unselected and
/// prompt the admin to pick a row — data-honest, no fabricated default owner).
class _DetailPanelPlaceholder extends StatelessWidget {
  final _UsersListPalette palette;

  const _DetailPanelPlaceholder({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BBSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 40,
              color: palette.textTertiary,
            ),
            const SizedBox(height: BBSpace.sm),
            Text(
              'Select an owner',
              textAlign: TextAlign.center,
              style: BBType.h3(context).copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: BBSpace.xs),
            Text(
              'Choose a row to view details and admin controls.',
              textAlign: TextAlign.center,
              style: BBType.caption(
                context,
              ).copyWith(color: palette.textTertiary),
            ),
          ],
        ),
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
      return _UsersTable(
        owners: owners,
        hasMore: false,
        onLoadMore: () {},
        palette: _neutralTestPalette(context),
      );
    },
  );
}

/// Neutral light palette derived from the ambient [Theme] for test seams
/// (no Firebase / Riverpod).
_UsersListPalette _neutralTestPalette(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return _UsersListPalette(
    textPrimary: scheme.onSurface,
    textSecondary: scheme.onSurfaceVariant,
    textTertiary: scheme.onSurfaceVariant.withValues(alpha: 0.7),
    isDark: false,
  );
}

/// Renders the desktop MASTER-DETAIL split (`_UsersTable` + inline panel) in
/// isolation for the seam test. Uses local selection state (no Riverpod /
/// Firebase); [panelBuilder] receives the selected owner id (or `null` before
/// any selection) so the test can inject a fake panel in place of the real
/// provider-backed [UserDetailScreen]. Mirrors the production split: row-select
/// swaps the panel, close clears it. See
/// `test/features/admin/users_list_master_detail_test.dart`.
@visibleForTesting
Widget buildUsersMasterDetailForTest({
  required List<UserModel> owners,
  required Widget Function(String? selectedId, VoidCallback onClose)
  panelBuilder,
}) {
  return _MasterDetailTestHarness(owners: owners, panelBuilder: panelBuilder);
}

class _MasterDetailTestHarness extends StatefulWidget {
  final List<UserModel> owners;
  final Widget Function(String? selectedId, VoidCallback onClose) panelBuilder;

  const _MasterDetailTestHarness({
    required this.owners,
    required this.panelBuilder,
  });

  @override
  State<_MasterDetailTestHarness> createState() =>
      _MasterDetailTestHarnessState();
}

class _MasterDetailTestHarnessState extends State<_MasterDetailTestHarness> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final palette = _neutralTestPalette(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: _UsersTable(
              owners: widget.owners,
              hasMore: false,
              onLoadMore: () {},
              palette: palette,
              selectedId: _selectedId,
              onSelect: (id) => setState(() => _selectedId = id),
            ),
          ),
        ),
        SizedBox(
          width: _detailPanelWidth,
          child: _selectedId == null
              ? _DetailPanelPlaceholder(palette: palette)
              : widget.panelBuilder(
                  _selectedId,
                  () => setState(() => _selectedId = null),
                ),
        ),
      ],
    );
  }
}

/// The master-detail content-width breakpoint, exposed for tests.
@visibleForTesting
const double usersListMasterDetailBreakpoint = _masterDetailBreakpoint;

/// Renders the compact mobile owner-card list (`_UsersList`) in isolation for
/// the responsive layout regression test (mobile <600 branch). No Firebase /
/// Riverpod — see `test/features/admin/users_list_layout_test.dart`.
@visibleForTesting
Widget buildUsersCardListForTest({required List<UserModel> owners}) {
  return Builder(
    builder: (context) => _UsersList(
      owners: owners,
      hasMore: false,
      onLoadMore: () {},
      palette: _neutralTestPalette(context),
    ),
  );
}

/// Renders the numbered pagination bar (`_UsersPagination`) in isolation,
/// reporting page-change callbacks. See
/// `test/features/admin/users_list_layout_test.dart`.
@visibleForTesting
Widget buildUsersPaginationForTest({
  required int page,
  required int pageCount,
  required int totalRows,
  required ValueChanged<int> onPageChanged,
}) {
  return Builder(
    builder: (context) {
      final start = page * _rowsPerPage + 1;
      final end = ((page + 1) * _rowsPerPage).clamp(0, totalRows);
      return _UsersPagination(
        page: page,
        pageCount: pageCount,
        rangeStart: start,
        rangeEnd: end,
        totalRows: totalRows,
        palette: _neutralTestPalette(context),
        onPageChanged: onPageChanged,
      );
    },
  );
}

/// The compact-card breakpoint, exposed for the responsive layout test so it
/// asserts against the same value the screen uses.
@visibleForTesting
const double usersListMobileBreakpoint = _mobileBreakpoint;

/// Rows per numbered-pagination page, exposed for tests.
@visibleForTesting
const int usersListRowsPerPage = _rowsPerPage;
