import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/enums.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/admin_providers.dart';
import '../../data/repositories/admin_repository.dart';

/// Admin User Management Screen
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final filters = ref.watch(adminUserFiltersProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminUsersProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: EdgeInsets.all(
              isMobile ? AppDimensions.spaceM : AppDimensions.spaceL,
            ),
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : AppColors.surfaceLight,
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(adminUserFiltersProvider.notifier)
                                  .setSearchQuery(null);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                  ),
                  onChanged: (value) {
                    // Debounce search
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value) {
                        ref
                            .read(adminUserFiltersProvider.notifier)
                            .setSearchQuery(value.isEmpty ? null : value);
                      }
                    });
                  },
                ),
                const SizedBox(height: AppDimensions.spaceM),
                // Role filter
                Row(
                  children: [
                    Text(
                      'Role:',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _RoleChip(
                              label: 'All',
                              value: 'all',
                              selected: filters.role == 'all',
                              onTap: () => ref
                                  .read(adminUserFiltersProvider.notifier)
                                  .setRole('all'),
                            ),
                            _RoleChip(
                              label: 'Guest',
                              value: 'guest',
                              selected: filters.role == 'guest',
                              onTap: () => ref
                                  .read(adminUserFiltersProvider.notifier)
                                  .setRole('guest'),
                            ),
                            _RoleChip(
                              label: 'Owner',
                              value: 'owner',
                              selected: filters.role == 'owner',
                              onTap: () => ref
                                  .read(adminUserFiltersProvider.notifier)
                                  .setRole('owner'),
                            ),
                            _RoleChip(
                              label: 'Admin',
                              value: 'admin',
                              selected: filters.role == 'admin',
                              onTap: () => ref
                                  .read(adminUserFiltersProvider.notifier)
                                  .setRole('admin'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppColors.textSecondaryLight,
                        ),
                        const SizedBox(height: AppDimensions.spaceM),
                        Text(
                          'No users found',
                          style: AppTypography.h3,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.all(
                    isMobile ? AppDimensions.spaceM : AppDimensions.spaceL,
                  ),
                  itemCount: users.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppDimensions.spaceM),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _UserCard(user: user);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ErrorStateWidget(
                message: 'Failed to load users',
                onRetry: () => ref.invalidate(adminUsersProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.spaceS),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimaryLight,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final dynamic user; // UserModel

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = context.isMobile;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: isMobile ? 24 : 32,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.fullName.substring(0, 1).toUpperCase(),
                          style: AppTypography.h3.copyWith(
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppDimensions.spaceM),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.fullName,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _RoleBadge(role: user.role),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceXS),
                      Text(
                        user.email,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceXS),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: AppDimensions.spaceXXS),
                          Text(
                            'Joined ${_formatDate(user.createdAt)}',
                            style: AppTypography.small.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceM),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showRoleChangeDialog(context, ref, user),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Change Role'),
                ),
                const SizedBox(width: AppDimensions.spaceS),
                TextButton.icon(
                  onPressed: () => _showDeleteDialog(context, ref, user),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleChangeDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
  ) {
    showDialog(
      context: context,
      builder: (context) => _RoleChangeDialog(
        user: user,
        onRoleChanged: (newRole) async {
          try {
            await ref
                .read(adminRepositoryProvider)
                .updateUserRole(user.id, newRole.name);

            if (context.mounted) {
              Navigator.of(context).pop();
              ref.invalidate(adminUsersProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User role updated successfully'),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.fullName}? This action cannot be undone and will delete all associated data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(adminRepositoryProvider).deleteUser(user.id);

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ref.invalidate(adminUsersProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role) {
      case UserRole.admin:
        color = AppColors.error;
        break;
      case UserRole.owner:
        color = AppColors.primary;
        break;
      case UserRole.guest:
        color = AppColors.textSecondaryLight;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceS,
        vertical: AppDimensions.spaceXXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: color),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: AppTypography.small.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Dialog for changing user role using modern ListTile approach
class _RoleChangeDialog extends StatefulWidget {
  final dynamic user;
  final Future<void> Function(UserRole) onRoleChanged;

  const _RoleChangeDialog({
    required this.user,
    required this.onRoleChanged,
  });

  @override
  State<_RoleChangeDialog> createState() => _RoleChangeDialogState();
}

class _RoleChangeDialogState extends State<_RoleChangeDialog> {
  late UserRole _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change User Role'),
      content: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select new role for ${widget.user.fullName}:'),
                const SizedBox(height: AppDimensions.spaceM),
                ...UserRole.values.map((role) {
                  final isSelected = _selectedRole == role;
                  return ListTile(
                    onTap: _isLoading
                        ? null
                        : () {
                            setState(() => _selectedRole = role);
                          },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : Colors.grey,
                    ),
                    title: Text(
                      role.name.toUpperCase(),
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 20,
                          )
                        : null,
                  );
                }),
              ],
            ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading || _selectedRole == widget.user.role
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  await widget.onRoleChanged(_selectedRole);
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
