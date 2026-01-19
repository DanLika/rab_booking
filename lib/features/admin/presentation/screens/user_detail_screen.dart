import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/models/user_model.dart';
import '../../data/admin_users_repository.dart';

/// User detail screen with edit functionality
class UserDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  AccountType? _selectedAccountType;
  bool _isSaving = false;
  String? _successMessage;

  // Admin control states
  bool? _hideSubscription;
  AccountType? _selectedOverrideType;
  bool _isSavingAdminFlags = false;
  String? _adminFlagsSuccessMessage;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDetailProvider(widget.userId));
    final isMobile = MediaQuery.of(context).size.width < 600;
    final padding = isMobile ? 12.0 : 24.0;

    return Scaffold(
      // No AppBar - shell provides it
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button and title row
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to Users',
                  onPressed: () => context.go('/users'),
                ),
                const SizedBox(width: 8),
                Text(
                  'User Details',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            // Content
            userAsync.when(
              data: (user) {
                if (user == null) {
                  return const Center(child: Text('User not found'));
                }
                return _buildUserDetails(context, user);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(child: SelectableText('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDetails(BuildContext context, UserModel user) {
    _selectedAccountType ??= user.accountType;
    _hideSubscription ??= user.hideSubscription;
    _selectedOverrideType ??= user.adminOverrideAccountType;

    final isMobile = MediaQuery.of(context).size.width < 600;
    final cardPadding = isMobile ? 16.0 : 24.0;
    final sectionSpacing = isMobile ? 12.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User info card
        Card(
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: isMobile ? 24 : 32,
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text(
                        (user.displayName ?? user.fullName).isNotEmpty
                            ? (user.displayName ?? user.fullName)[0]
                                  .toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            user.displayName ?? user.fullName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SelectableText(
                            user.email,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: isMobile ? 24 : 32),
                _buildInfoRow('User ID', user.id),
                _buildInfoRow('Role', user.role.displayName),
                _buildInfoRow(
                  'Created',
                  '${user.createdAt.day}.${user.createdAt.month}.${user.createdAt.year}',
                ),
                _buildInfoRow('Phone', user.phone ?? 'Not provided'),
              ],
            ),
          ),
        ),
        SizedBox(height: sectionSpacing),

        // User Statistics Card
        _buildStatisticsCard(context, cardPadding),
        SizedBox(height: sectionSpacing),

        // Account type editor
        Card(
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Type',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AccountType>(
                  value: _selectedAccountType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Account Type',
                  ),
                  items: AccountType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAccountType = value;
                      _successMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_successMessage != null) ...[
                  _buildSuccessMessage(_successMessage!),
                  const SizedBox(height: 16),
                ],
                FilledButton(
                  onPressed:
                      _selectedAccountType != user.accountType && !_isSaving
                      ? () => _saveAccountType(user)
                      : null,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: sectionSpacing),

        // Admin Controls Card
        Card(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.orange.shade900.withValues(alpha: 0.3)
              : Colors.orange.shade50,
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.orange.shade300
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Admin Controls',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.orange.shade300
                            : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Hide Subscription Checkbox
                CheckboxListTile(
                  value: _hideSubscription ?? false,
                  onChanged: (value) {
                    setState(() {
                      _hideSubscription = value;
                      _adminFlagsSuccessMessage = null;
                    });
                  },
                  title: const Text('Hide Subscription'),
                  subtitle: const Text('Hide subscription page from this user'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),

                // Override Account Type Dropdown
                const SizedBox(height: 8),
                const Text(
                  'Override Account Status',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Force a specific account type for this user (overrides calculated status)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AccountType?>(
                  value: _selectedOverrideType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Override Account Type',
                  ),
                  items: [
                    const DropdownMenuItem<AccountType?>(
                      value: null,
                      child: Text('No Override (use calculated)'),
                    ),
                    ...AccountType.values.map((type) {
                      return DropdownMenuItem<AccountType?>(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedOverrideType = value;
                      _adminFlagsSuccessMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                if (_adminFlagsSuccessMessage != null) ...[
                  _buildSuccessMessage(_adminFlagsSuccessMessage!),
                  const SizedBox(height: 16),
                ],

                FilledButton.tonal(
                  onPressed: _hasAdminFlagsChanged(user) && !_isSavingAdminFlags
                      ? () => _saveAdminFlags(user)
                      : null,
                  child: _isSavingAdminFlags
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Admin Controls'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessMessage(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.green.shade900.withValues(alpha: 0.3)
            : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: isDark ? Colors.green.shade300 : Colors.green.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.green.shade300 : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasAdminFlagsChanged(UserModel user) {
    return _hideSubscription != user.hideSubscription ||
        _selectedOverrideType != user.adminOverrideAccountType;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context, double cardPadding) {
    final propertiesCountAsync = ref.watch(
      userPropertiesCountProvider(widget.userId),
    );
    final bookingsCountAsync = ref.watch(
      userBookingsCountProvider(widget.userId),
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.home_work,
                    label: 'Properties',
                    value: propertiesCountAsync.when(
                      data: (count) => count.toString(),
                      loading: () => '...',
                      error: (_, __) => '-',
                    ),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Bookings',
                    value: bookingsCountAsync.when(
                      data: (count) => count.toString(),
                      loading: () => '...',
                      error: (_, __) => '-',
                    ),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAccountType(UserModel user) async {
    if (_selectedAccountType == null) return;

    setState(() {
      _isSaving = true;
      _successMessage = null;
    });

    try {
      final repo = ref.read(adminUsersRepositoryProvider);
      await repo.updateAccountType(user.id, _selectedAccountType!);

      // Refresh user data
      ref.invalidate(userDetailProvider(widget.userId));
      ref.invalidate(ownersListProvider);
      ref.invalidate(dashboardStatsProvider);

      setState(() {
        _successMessage = 'Account type updated successfully';
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _saveAdminFlags(UserModel user) async {
    setState(() {
      _isSavingAdminFlags = true;
      _adminFlagsSuccessMessage = null;
    });

    try {
      final repo = ref.read(adminUsersRepositoryProvider);
      await repo.updateAdminFlags(
        user.id,
        hideSubscription: _hideSubscription,
        adminOverrideAccountType: _selectedOverrideType,
        clearOverride:
            _selectedOverrideType == null &&
            user.adminOverrideAccountType != null,
      );

      // Refresh user data
      ref.invalidate(userDetailProvider(widget.userId));
      ref.invalidate(ownersListProvider);

      setState(() {
        _adminFlagsSuccessMessage = 'Admin controls updated successfully';
        _isSavingAdminFlags = false;
      });
    } catch (e) {
      setState(() {
        _isSavingAdminFlags = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
