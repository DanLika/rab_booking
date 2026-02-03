import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
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
  bool? _hideSubscription;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  Timer? _successDismissTimer;

  @override
  void didUpdateWidget(covariant UserDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _hideSubscription = null;
      _errorMessage = null;
      _successMessage = null;
      _successDismissTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _successDismissTimer?.cancel();
    super.dispose();
  }

  void _showSuccess(String message) {
    _successDismissTimer?.cancel();
    setState(() {
      _successMessage = message;
      _errorMessage = null;
    });
    _successDismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _successMessage = null);
      }
    });
  }

  String _sanitizeError(Object error) {
    String message = error.toString();
    // Handle Cloud Functions exceptions - extract human-readable message
    final cfMatch = RegExp(
      r'\[cloud_functions/[^\]]+\]\s*(.*)',
    ).firstMatch(message);
    if (cfMatch != null && cfMatch.group(1)!.isNotEmpty) {
      return cfMatch.group(1)!;
    }
    // Strip common prefixes
    message = message
        .replaceAll('Exception: ', '')
        .replaceAll(RegExp(r'^\[.*?\]\s*'), '')
        .trim();
    if (message.isEmpty || message.length > 200) {
      return 'An error occurred. Please try again.';
    }
    return message;
  }

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
          _hideSubscription ??= user.hideSubscription;

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
                            _UserStatusCard(
                              user: user,
                              isLoading: _isLoading,
                              onStatusChange: (status) =>
                                  _updateUserStatus(user, status),
                            ),
                            const SizedBox(height: 16),
                            _AdminControlsCard(
                              hideSubscription: _hideSubscription ?? false,
                              isLoading: _isLoading,
                              onHideSubscriptionChanged: (val) =>
                                  setState(() => _hideSubscription = val),
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
                                  _UserStatusCard(
                                    user: user,
                                    isLoading: _isLoading,
                                    onStatusChange: (status) =>
                                        _updateUserStatus(user, status),
                                  ),
                                  const SizedBox(height: 24),
                                  _AdminControlsCard(
                                    hideSubscription:
                                        _hideSubscription ?? false,
                                    isLoading: _isLoading,
                                    onHideSubscriptionChanged: (val) =>
                                        setState(() => _hideSubscription = val),
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
                  const Icon(Icons.error, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.error,
                    ),
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

      await repo.updateAdminFlags(user.id, hideSubscription: _hideSubscription);

      ref.invalidate(userDetailProvider(user.id));
      ref.invalidate(ownersListProvider);

      // Clear form state so it re-initializes from fresh provider data
      _hideSubscription = null;

      _isLoading = false;
      _showSuccess('Changes saved successfully');
    } catch (e) {
      setState(() {
        _errorMessage = _sanitizeError(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserStatus(UserModel user, String newStatus) async {
    final label = switch (newStatus) {
      'active' => 'Activate',
      'suspended' => 'Suspend',
      'trial' => 'Reset to Trial',
      'trial_expired' => 'Expire Trial',
      _ => 'Update',
    };

    if (!await _showConfirmation(
      context,
      '$label User',
      'Are you sure you want to set this user\'s status to "$newStatus"?',
    )) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(adminUsersRepositoryProvider)
          .updateUserStatus(userId: user.id, newStatus: newStatus);
      ref.invalidate(userDetailProvider(user.id));
      ref.invalidate(userAccountStatusProvider(user.id));
      ref.invalidate(ownersListProvider);

      _hideSubscription = null;

      _isLoading = false;
      _showSuccess('User status changed to $newStatus');
    } catch (e) {
      setState(() {
        _errorMessage = _sanitizeError(e);
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

      // Clear form state so it re-initializes from fresh provider data
      _hideSubscription = null;

      _isLoading = false;
      _showSuccess('Lifetime license granted successfully');
    } catch (e) {
      setState(() {
        _errorMessage = _sanitizeError(e);
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

      // Clear form state so it re-initializes from fresh provider data
      _hideSubscription = null;

      _isLoading = false;
      _showSuccess('Lifetime license revoked successfully');
    } catch (e) {
      setState(() {
        _errorMessage = _sanitizeError(e);
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
              copyable: true,
            ),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Role',
              value: user.role.name.toUpperCase(),
            ),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Created At',
              value: user.createdAt != null
                  ? '${user.createdAt!.day}.${user.createdAt!.month}.${user.createdAt!.year}'
                  : '-',
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
                        onTap: () async {
                          try {
                            await Clipboard.setData(ClipboardData(text: value));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (_) {
                            // Clipboard API can fail on some browsers
                          }
                        },
                        child: const Icon(
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

class _UserStatusCard extends ConsumerWidget {
  final UserModel user;
  final bool isLoading;
  final ValueChanged<String> onStatusChange;

  const _UserStatusCard({
    required this.user,
    required this.isLoading,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(userAccountStatusProvider(user.id));
    final currentStatus = statusAsync.valueOrNull ?? 'trial';

    final statusColor = switch (currentStatus) {
      'active' => Colors.green,
      'suspended' => Colors.red,
      'trial_expired' => Colors.orange,
      _ => Colors.blue, // trial
    };

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
                const Icon(Icons.shield_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'Account Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    currentStatus.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (currentStatus != 'active')
                  _StatusButton(
                    label: 'Activate',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    isLoading: isLoading,
                    onPressed: () => onStatusChange('active'),
                  ),
                if (currentStatus != 'suspended')
                  _StatusButton(
                    label: 'Suspend',
                    icon: Icons.block,
                    color: Colors.red,
                    isLoading: isLoading,
                    onPressed: () => onStatusChange('suspended'),
                  ),
                if (currentStatus != 'trial')
                  _StatusButton(
                    label: 'Reset to Trial',
                    icon: Icons.restart_alt,
                    color: Colors.blue,
                    isLoading: isLoading,
                    onPressed: () => onStatusChange('trial'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}

class _AdminControlsCard extends StatelessWidget {
  final bool hideSubscription;
  final bool isLoading;
  final ValueChanged<bool> onHideSubscriptionChanged;
  final VoidCallback onSave;

  const _AdminControlsCard({
    required this.hideSubscription,
    required this.isLoading,
    required this.onHideSubscriptionChanged,
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
                const Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.primary,
                ),
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

            SwitchListTile(
              title: const Text('Hide Subscription'),
              subtitle: const Text('Hide subscription UI from user dashboard'),
              value: hideSubscription,
              onChanged: onHideSubscriptionChanged,
              contentPadding: EdgeInsets.zero,
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
