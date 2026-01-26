import '../../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/models/user_model.dart';
import '../../data/admin_users_repository.dart';

/// Responsive breakpoint for mobile layout
const double _mobileBreakpoint = 900.0;

/// User detail screen with edit functionality and modern UI
class UserDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  // Form state
  AccountType? _selectedAccountType;
  bool? _hideSubscription;
  bool? _adminOverrideAccountType;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDetailProvider(widget.userId));
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < _mobileBreakpoint;

    return Scaffold(
      backgroundColor: Colors.transparent, // Uses shell background
      body: userAsync.when(
        data: (user) {
          if (user == null) return const _ErrorState(message: 'User not found');

          // Initialize state if needed
          _selectedAccountType ??=
              user.adminOverrideAccountType ?? user.accountType;

          _hideSubscription ??= user.hideSubscription;
          _adminOverrideAccountType ??= user.adminOverrideAccountType != null;

          return Column(
            children: [
              // Header
              _buildHeader(context, user),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: isMobile
                      ? Column(
                          children: [
                            _InfoCard(user: user),
                            const SizedBox(height: 16),
                            _StatisticsCard(user: user),
                            const SizedBox(height: 16),
                            _AdminControlsCard(
                              user: user,
                              selectedAccountType: _selectedAccountType!,
                              hideSubscription: _hideSubscription ?? false,
                              adminOverride: _adminOverrideAccountType ?? false,
                              isLoading: _isLoading,
                              onAccountTypeChanged: (val) =>
                                  setState(() => _selectedAccountType = val),
                              onHideSubscriptionChanged: (val) =>
                                  setState(() => _hideSubscription = val),
                              onAdminOverrideChanged: (val) => setState(
                                () => _adminOverrideAccountType = val,
                              ),
                              onSave: () => _saveChanges(user),
                            ),
                            const SizedBox(height: 16),
                            _LifetimeLicenseCard(
                              user: user,
                              isLoading: _isLoading,
                              onGrant: () => _grantLifetimeLicense(user),
                              onRevoke: () => _revokeLifetimeLicense(user),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (Info & Stats)
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _InfoCard(user: user),
                                  const SizedBox(height: 24),
                                  _StatisticsCard(user: user),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Right Column (Admin Controls)
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _AdminControlsCard(
                                    user: user,
                                    selectedAccountType: _selectedAccountType!,
                                    hideSubscription:
                                        _hideSubscription ?? false,
                                    adminOverride:
                                        _adminOverrideAccountType ?? false,
                                    isLoading: _isLoading,
                                    onAccountTypeChanged: (val) => setState(
                                      () => _selectedAccountType = val,
                                    ),
                                    onHideSubscriptionChanged: (val) =>
                                        setState(() => _hideSubscription = val),
                                    onAdminOverrideChanged: (val) => setState(
                                      () => _adminOverrideAccountType = val,
                                    ),
                                    onSave: () => _saveChanges(user),
                                  ),
                                  const SizedBox(height: 24),
                                  _LifetimeLicenseCard(
                                    user: user,
                                    isLoading: _isLoading,
                                    onGrant: () => _grantLifetimeLicense(user),
                                    onRevoke: () =>
                                        _revokeLifetimeLicense(user),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(message: err.toString()),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/users'),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  (user.displayName ?? user.fullName).isNotEmpty
                      ? (user.displayName ?? user.fullName)[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SelectableText(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Messages
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: AppColors.error),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.green,
                    ),
                    onPressed: () => setState(() => _successMessage = null),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveChanges(UserModel user) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final repo = ref.read(adminUsersRepositoryProvider);

      // Update account type / override
      if (_adminOverrideAccountType == true ||
          user.adminOverrideAccountType != null) {
        // If override is enabled (or was enabled), update it
        // Check if we need to clear it (if _adminOverrideAccountType is false)
        await repo.updateAdminFlags(
          user.id,
          adminOverrideAccountType: _adminOverrideAccountType!
              ? _selectedAccountType
              : null,
          clearOverride: !_adminOverrideAccountType!,
          hideSubscription: _hideSubscription,
        );
      } else {
        // Just regular settings update
        await repo.updateAdminFlags(
          user.id,
          hideSubscription: _hideSubscription,
        );
      }

      // Also update regular account type if not overridden
      if (!_adminOverrideAccountType! &&
          _selectedAccountType != user.accountType) {
        await repo.updateAccountType(user.id, _selectedAccountType!);
      }

      ref.invalidate(userDetailProvider(user.id));
      ref.invalidate(ownersListProvider);

      setState(() {
        _successMessage = 'Changes saved successfully';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _grantLifetimeLicense(UserModel user) async {
    if (!await _showConfirmation(
      context,
      'Grant Lifetime License',
      'Are you sure you want to grant a lifetime license to this user?',
    )) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(adminUsersRepositoryProvider)
          .setLifetimeLicense(userId: user.id, grant: true);
      ref.invalidate(userDetailProvider(user.id));
      setState(() {
        _successMessage = 'Lifetime license granted successfully';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _revokeLifetimeLicense(UserModel user) async {
    if (!await _showConfirmation(
      context,
      'Revoke Lifetime License',
      'Are you sure you want to revoke the lifetime license from this user?',
    )) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(adminUsersRepositoryProvider)
          .setLifetimeLicense(userId: user.id, grant: false);
      ref.invalidate(userDetailProvider(user.id));
      setState(() {
        _successMessage = 'Lifetime license revoked successfully';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<bool> _showConfirmation(
    BuildContext context,
    String title,
    String content,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _InfoCard extends StatelessWidget {
  final UserModel user;

  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'User ID',
              value: user.id,
              copyable: true,
            ),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
            ),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Role',
              value: user.role.name.toUpperCase(),
            ),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Created At',
              value:
                  '${user.createdAt.day}.${user.createdAt.month}.${user.createdAt.year}',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        value,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    if (copyable) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          // Clipboard logic
                        },
                        child: Icon(
                          Icons.copy,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsCard extends ConsumerWidget {
  final UserModel user;

  const _StatisticsCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(userPropertiesCountProvider(user.id));
    final bookingsAsync = ref.watch(userBookingsCountProvider(user.id));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'Properties',
                    value: propertiesAsync.when(
                      data: (d) => d.toString(),
                      loading: () => '...',
                      error: (_, _) => '-',
                    ),
                    icon: Icons.home_work_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatBox(
                    label: 'Bookings',
                    value: bookingsAsync.when(
                      data: (d) => d.toString(),
                      loading: () => '...',
                      error: (_, _) => '-',
                    ),
                    icon: Icons.calendar_month_outlined,
                    color: Colors.orange,
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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminControlsCard extends StatelessWidget {
  final UserModel user;
  final AccountType selectedAccountType;
  final bool hideSubscription;
  final bool adminOverride;
  final bool isLoading;
  final ValueChanged<AccountType> onAccountTypeChanged;
  final ValueChanged<bool> onHideSubscriptionChanged;
  final ValueChanged<bool> onAdminOverrideChanged;
  final VoidCallback onSave;

  const _AdminControlsCard({
    required this.user,
    required this.selectedAccountType,
    required this.hideSubscription,
    required this.adminOverride,
    required this.isLoading,
    required this.onAccountTypeChanged,
    required this.onHideSubscriptionChanged,
    required this.onAdminOverrideChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'Admin Controls',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Account Type Selector
            Text(
              'Account Type',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AccountType>(
                  value: selectedAccountType,
                  isExpanded: true,
                  items: AccountType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) onAccountTypeChanged(val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Switches
            SwitchListTile(
              title: const Text('Hide Subscription'),
              subtitle: const Text('Hide subscription UI from user dashboard'),
              value: hideSubscription,
              onChanged: onHideSubscriptionChanged,
              contentPadding: EdgeInsets.zero,
            ),

            SwitchListTile(
              title: const Text('Admin Override Account Type'),
              subtitle: const Text(
                'Force specific account type regardless of payment status',
              ),
              value: adminOverride,
              onChanged: onAdminOverrideChanged,
              contentPadding: EdgeInsets.zero,
              activeTrackColor: Colors.orange.withValues(alpha: 0.5),
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.orange;
                }
                return null;
              }),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: isLoading ? null : onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LifetimeLicenseCard extends StatelessWidget {
  final UserModel user;
  final bool isLoading;
  final VoidCallback onGrant;
  final VoidCallback onRevoke;

  const _LifetimeLicenseCard({
    required this.user,
    required this.isLoading,
    required this.onGrant,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    // Only show if user is not already lifetime (for grant) or IS lifetime (for revoke)
    // Actually typically we want to show actions available.
    final hasLifetime = user.accountType == AccountType.lifetime;

    return Card(
      elevation: 0,
      color: hasLifetime
          ? Colors.red.withValues(alpha: 0.05)
          : Colors.purple.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasLifetime
              ? Colors.red.withValues(alpha: 0.2)
              : Colors.purple.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified,
                  color: hasLifetime ? Colors.red : Colors.purple,
                ),
                const SizedBox(width: 12),
                Text(
                  hasLifetime
                      ? 'Revoke Lifetime License'
                      : 'Grant Lifetime License',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasLifetime ? Colors.red : Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hasLifetime
                  ? 'This will remove the lifetime license and revert the user to Trial status.'
                  : 'This will grant the user permanent access to all Premium features without recurring payments.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: isLoading
                    ? null
                    : (hasLifetime ? onRevoke : onGrant),
                style: OutlinedButton.styleFrom(
                  foregroundColor: hasLifetime ? Colors.red : Colors.purple,
                  side: BorderSide(
                    color: hasLifetime ? Colors.red : Colors.purple,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(hasLifetime ? 'Revoke License' : 'Grant License'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
