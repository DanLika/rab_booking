import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../data/admin_users_repository.dart';
import 'admin_shell_screen.dart';

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
    return Scaffold(
      backgroundColor: Colors.transparent, // Uses shell background
      // Content-width breakpoint (audit/122, doc deleted — git history):
      // the adaptive shell reserves
      // 260/72px for sidebar/rail, so window width over-reports space.
      body: LayoutBuilder(
        builder: (context, constraints) =>
            _buildBody(context, constraints.maxWidth < _mobileBreakpoint),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isMobile) {
    final userAsync = ref.watch(userDetailProvider(widget.userId));
    return userAsync.when(
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
                                  hideSubscription: _hideSubscription ?? false,
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
                                  onRevoke: () => _revokeLifetimeLicense(user),
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
      loading: () => const Center(child: BbSpinner(size: 24)),
      error: (err, _) => _ErrorState(message: err.toString()),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    final palette = _UserDetailPalette.of(context, ref);
    final displayName = user.displayName ?? user.fullName;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpace.md,
        vertical: BBSpace.sm,
      ),
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
              BbButton(
                asIcon: true,
                iconLeft: 'arrow_back',
                variant: BbButtonVariant.tertiary,
                semanticLabel: 'Back to users',
                onPressed: () => context.go('/users'),
              ),
              const SizedBox(width: BBSpace.sm),
              BbAvatar(name: displayName),
              const SizedBox(width: BBSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      displayName,
                      style: BBType.h2(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    SelectableText(
                      user.email,
                      style: BBType.body(
                        context,
                      ).copyWith(color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: BBSpace.sm),
            _StatusMessage(
              message: _errorMessage!,
              icon: 'error',
              color: AppColors.error,
              onDismiss: () => setState(() => _errorMessage = null),
            ),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: BBSpace.sm),
            _StatusMessage(
              message: _successMessage!,
              icon: 'check_circle',
              color: AppColors.success,
              onDismiss: () => setState(() => _successMessage = null),
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
      builder: (dialogContext) => BbDialog(
        title: title,
        body: content,
        secondary: BbDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(dialogContext, false),
        ),
        primary: BbDialogAction(
          label: 'Confirm',
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
      ),
    );
    return result ?? false;
  }
}

class _StatusMessage extends StatelessWidget {
  final String message;
  final String icon;
  final Color color;
  final VoidCallback onDismiss;

  const _StatusMessage({
    required this.message,
    required this.icon,
    required this.color,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BBSpace.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BBRadius.xsAll,
      ),
      child: Row(
        children: [
          BbIcon(name: icon, color: color),
          const SizedBox(width: BBSpace.sm),
          Expanded(
            child: Text(
              message,
              style: BBType.body(context).copyWith(color: color),
            ),
          ),
          BbButton(
            asIcon: true,
            iconLeft: 'close',
            variant: BbButtonVariant.tertiary,
            size: BbButtonSize.sm,
            semanticLabel: 'Dismiss',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends ConsumerWidget {
  final UserModel user;

  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _UserDetailPalette.of(context, ref);
    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Information',
            style: BBType.h3(
              context,
            ).copyWith(fontWeight: FontWeight.bold, color: palette.textPrimary),
          ),
          const SizedBox(height: BBSpace.md),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'User ID',
            value: user.id,
            copyable: true,
            palette: palette,
          ),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
            copyable: true,
            palette: palette,
          ),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Role',
            value: user.role.name.toUpperCase(),
            palette: palette,
          ),
          _InfoRow(
            icon: Icons.calendar_today,
            label: 'Created At',
            value: user.createdAt != null
                ? '${user.createdAt!.day}.${user.createdAt!.month}.${user.createdAt!.year}'
                : '-',
            palette: palette,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
  final _UserDetailPalette palette;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BBSpace.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: palette.textSecondary),
          const SizedBox(width: BBSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: BBType.caption(
                    context,
                  ).copyWith(color: palette.textTertiary),
                ),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        value,
                        style: BBType.body(context).copyWith(
                          fontWeight: FontWeight.w500,
                          color: palette.textPrimary,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    if (copyable) ...[
                      const SizedBox(width: BBSpace.xs),
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
    final palette = _UserDetailPalette.of(context, ref);

    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: BBType.h3(
              context,
            ).copyWith(fontWeight: FontWeight.bold, color: palette.textPrimary),
          ),
          const SizedBox(height: BBSpace.md),
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
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: BBSpace.sm),
              Expanded(
                child: _StatBox(
                  label: 'Bookings',
                  value: bookingsAsync.when(
                    data: (d) => d.toString(),
                    loading: () => '...',
                    error: (_, _) => '-',
                  ),
                  icon: Icons.calendar_month_outlined,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.all(BBSpace.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BBRadius.smAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: BBSpace.xs),
          Text(
            value,
            style: BBType.h2(
              context,
            ).copyWith(fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: BBType.caption(
              context,
            ).copyWith(color: color.withValues(alpha: 0.8)),
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
    final palette = _UserDetailPalette.of(context, ref);

    final statusColor = switch (currentStatus) {
      'active' => AppColors.success,
      'suspended' => AppColors.error,
      'trial_expired' => AppColors.warning,
      _ => AppColors.info,
    };

    return BbCard(
      padding: const EdgeInsets.all(BBSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BbIcon(name: 'shield', size: 24, color: AppColors.primary),
              const SizedBox(width: BBSpace.sm),
              Text(
                'Account Status',
                style: BBType.h3(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: BBSpace.xs,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BBRadius.fullAll,
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  currentStatus.toUpperCase().replaceAll('_', ' '),
                  style: BBType.caption(
                    context,
                  ).copyWith(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpace.md),
          Wrap(
            spacing: BBSpace.xs,
            runSpacing: BBSpace.xs,
            children: [
              if (currentStatus != 'active')
                BbButton(
                  label: 'Activate',
                  iconLeft: 'check_circle',
                  variant: BbButtonVariant.secondary,
                  size: BbButtonSize.sm,
                  disabled: isLoading,
                  onPressed: () => onStatusChange('active'),
                ),
              if (currentStatus != 'suspended')
                BbButton(
                  label: 'Suspend',
                  iconLeft: 'block',
                  variant: BbButtonVariant.destructiveSoft,
                  size: BbButtonSize.sm,
                  disabled: isLoading,
                  onPressed: () => onStatusChange('suspended'),
                ),
              if (currentStatus != 'trial')
                BbButton(
                  label: 'Reset to Trial',
                  iconLeft: 'restart_alt',
                  variant: BbButtonVariant.secondary,
                  size: BbButtonSize.sm,
                  disabled: isLoading,
                  onPressed: () => onStatusChange('trial'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminControlsCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _UserDetailPalette.of(context, ref);
    return BbCard(
      padding: const EdgeInsets.all(BBSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BbIcon(
                name: 'admin_panel_settings',
                size: 24,
                color: AppColors.primary,
              ),
              const SizedBox(width: BBSpace.sm),
              Text(
                'Admin Controls',
                style: BBType.h3(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpace.md),
          BbSwitch(
            value: hideSubscription,
            onChanged: onHideSubscriptionChanged,
            label: 'Hide Subscription',
            subtitle: 'Hide subscription UI from user dashboard',
          ),
          const SizedBox(height: BBSpace.md),
          BbButton(
            label: 'Save Changes',
            fullWidth: true,
            loading: isLoading,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

class _LifetimeLicenseCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _UserDetailPalette.of(context, ref);
    final hasLifetime = user.accountType == AccountType.lifetime;
    final accentColor = hasLifetime ? AppColors.error : AppColors.primary;

    return BbCard(
      variant: BbCardVariant.accentLeft,
      accentTone: hasLifetime ? BbCardAccentTone.error : BbCardAccentTone.info,
      padding: const EdgeInsets.all(BBSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BbIcon(name: 'verified', size: 24, color: accentColor),
              const SizedBox(width: BBSpace.sm),
              Expanded(
                child: Text(
                  hasLifetime
                      ? 'Revoke Lifetime License'
                      : 'Grant Lifetime License',
                  style: BBType.h3(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold, color: accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpace.sm),
          Text(
            hasLifetime
                ? 'This will remove the lifetime license and revert the user to Trial status.'
                : 'This will grant the user permanent access to all Premium features without recurring payments.',
            style: BBType.body(context).copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: BBSpace.md),
          BbButton(
            label: hasLifetime ? 'Revoke License' : 'Grant License',
            variant: hasLifetime
                ? BbButtonVariant.destructive
                : BbButtonVariant.primary,
            fullWidth: true,
            loading: isLoading,
            onPressed: hasLifetime ? onRevoke : onGrant,
          ),
        ],
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
      child: BbEmptyState(
        icon: 'error_outline',
        title: 'Something went wrong',
        body: message,
        compact: true,
      ),
    );
  }
}

/// Text-tier color palette: admin-dark via [BbAdminDarkTokens] (#646 wires
/// the extension on the shell), or [ColorScheme] in admin-light / owner.
class _UserDetailPalette {
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final bool isDark;

  const _UserDetailPalette({
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.isDark,
  });

  static _UserDetailPalette of(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(adminDarkModeProvider);
    if (isDark) {
      final t = BbAdminDarkTokens.of(context);
      return _UserDetailPalette(
        textPrimary: t.textPrimary,
        textSecondary: t.textSecondary,
        textTertiary: t.textTertiary,
        isDark: true,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return _UserDetailPalette(
      textPrimary: scheme.onSurface,
      textSecondary: scheme.onSurfaceVariant,
      textTertiary: scheme.onSurfaceVariant.withValues(alpha: 0.7),
      isDark: false,
    );
  }
}
