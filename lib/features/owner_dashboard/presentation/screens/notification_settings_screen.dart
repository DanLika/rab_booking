import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/notification_preferences_model.dart';
import '../providers/user_profile_provider.dart';
import '../../../../shared/widgets/common_app_bar.dart';

/// Notification Settings Screen
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  NotificationPreferences? _currentPreferences;
  bool _isSaving = false;

  Future<void> _toggleMasterSwitch(bool value) async {
    if (_currentPreferences == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      final updated = _currentPreferences!.copyWith(masterEnabled: value);
      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateNotificationPreferences(updated);

      if (mounted) {
        setState(() {
          _currentPreferences = updated;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška pri ažuriranju postavki',
        );
      }
    }
  }

  Future<void> _updateCategory(
    String category,
    NotificationChannels channels,
  ) async {
    if (_currentPreferences == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      NotificationCategories updatedCategories;

      switch (category) {
        case 'bookings':
          updatedCategories =
              _currentPreferences!.categories.copyWith(bookings: channels);
          break;
        case 'payments':
          updatedCategories =
              _currentPreferences!.categories.copyWith(payments: channels);
          break;
        case 'calendar':
          updatedCategories =
              _currentPreferences!.categories.copyWith(calendar: channels);
          break;
        case 'marketing':
          updatedCategories =
              _currentPreferences!.categories.copyWith(marketing: channels);
          break;
        default:
          return;
      }

      final updated =
          _currentPreferences!.copyWith(categories: updatedCategories);

      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateNotificationPreferences(updated);

      if (mounted) {
        setState(() {
          _currentPreferences = updated;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška pri ažuriranju postavki',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final horizontalPadding = isMobile ? 12.0 : 16.0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Notification Settings',
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      body: preferencesAsync.when(
        data: (preferences) {
          // Initialize with default preferences if none exist
          _currentPreferences ??= preferences ??
              NotificationPreferences(
                userId: FirebaseAuth.instance.currentUser?.uid ?? '',
              );

          final masterEnabled = _currentPreferences!.masterEnabled;
          final categories = _currentPreferences!.categories;

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            children: [
              const SizedBox(height: 16),
              // Premium Master Switch
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: masterEnabled
                        ? [
                            AppColors.primary.withAlpha((0.1 * 255).toInt()),
                            AppColors.secondary.withAlpha((0.05 * 255).toInt()),
                          ]
                        : [
                            AppColors.textSecondary.withAlpha((0.08 * 255).toInt()),
                            AppColors.textSecondary.withAlpha((0.03 * 255).toInt()),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: masterEnabled
                        ? AppColors.primary.withAlpha((0.3 * 255).toInt())
                        : AppColors.borderLight,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: masterEnabled
                          ? AppColors.primary.withAlpha((0.1 * 255).toInt())
                          : const Color(0xFF000000).withAlpha((0.04 * 255).toInt()),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SwitchListTile(
                  value: masterEnabled,
                  onChanged: _isSaving ? null : _toggleMasterSwitch,
                  title: Text(
                    'Enable All Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Master switch for all notification types',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: masterEnabled
                            ? [
                                AppColors.primary.withAlpha((0.15 * 255).toInt()),
                                AppColors.secondary.withAlpha((0.08 * 255).toInt()),
                              ]
                            : [
                                AppColors.textSecondary.withAlpha((0.1 * 255).toInt()),
                                AppColors.textSecondary.withAlpha((0.05 * 255).toInt()),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      masterEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_rounded,
                      color: masterEnabled ? AppColors.primary : AppColors.textDisabled,
                      size: 26,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),

              // Premium warning message when disabled
              if (!masterEnabled)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warning.withAlpha((0.1 * 255).toInt()),
                        AppColors.warning.withAlpha((0.05 * 255).toInt()),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withAlpha((0.3 * 255).toInt()),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Notifications are disabled. Enable the master switch to receive notifications.',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Premium Categories Header
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.authSecondary],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Notification Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              // Bookings Category
              _buildCategoryCard(
                context: context,
                theme: theme,
                isDark: isDark,
                title: 'Bookings',
                description:
                    'New bookings, cancellations, and booking updates',
                icon: Icons.event_note,
                iconColor: AppColors.authSecondary,
                channels: categories.bookings,
                enabled: masterEnabled,
                onChanged: (channels) =>
                    _updateCategory('bookings', channels),
              ),

              // Payments Category
              _buildCategoryCard(
                context: context,
                theme: theme,
                isDark: isDark,
                title: 'Payments',
                description: 'Payment confirmations and transaction updates',
                icon: Icons.payment,
                iconColor: AppColors.success,
                channels: categories.payments,
                enabled: masterEnabled,
                onChanged: (channels) =>
                    _updateCategory('payments', channels),
              ),

              // Calendar Category
              _buildCategoryCard(
                context: context,
                theme: theme,
                isDark: isDark,
                title: 'Calendar',
                description:
                    'Availability changes, blocked dates, and price updates',
                icon: Icons.calendar_today,
                iconColor: AppColors.warning,
                channels: categories.calendar,
                enabled: masterEnabled,
                onChanged: (channels) =>
                    _updateCategory('calendar', channels),
              ),

              // Marketing Category
              _buildCategoryCard(
                context: context,
                theme: theme,
                isDark: isDark,
                title: 'Marketing',
                description: 'Promotional offers, tips, and platform news',
                icon: Icons.campaign,
                iconColor: AppColors.primary,
                channels: categories.marketing,
                enabled: masterEnabled,
                onChanged: (channels) =>
                    _updateCategory('marketing', channels),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.error.withAlpha((0.1 * 255).toInt()),
                        AppColors.error.withAlpha((0.05 * 255).toInt()),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 50,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Error loading preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required NotificationChannels channels,
    required bool enabled,
    required Function(NotificationChannels) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withAlpha((0.04 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: const Color(0x00000000)),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withAlpha((0.15 * 255).toInt()),
                  iconColor.withAlpha((0.08 * 255).toInt()),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withAlpha((0.2 * 255).toInt()),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0x00000000),
                    AppColors.borderLight,
                    const Color(0x00000000),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildChannelOption(
              context: context,
              theme: theme,
              value: enabled && channels.email,
              onChanged: enabled && !_isSaving
                  ? (value) => onChanged(channels.copyWith(email: value))
                  : null,
              title: 'Email',
              subtitle: 'Receive notifications via email',
              icon: Icons.email_outlined,
              iconColor: AppColors.primary,
              enabled: enabled,
            ),
            _buildChannelOption(
              context: context,
              theme: theme,
              value: enabled && channels.push,
              onChanged: enabled && !_isSaving
                  ? (value) => onChanged(channels.copyWith(push: value))
                  : null,
              title: 'Push Notifications',
              subtitle: 'Receive push notifications on your device',
              icon: Icons.notifications_outlined,
              iconColor: AppColors.warning,
              enabled: enabled,
            ),
            _buildChannelOption(
              context: context,
              theme: theme,
              value: enabled && channels.sms,
              onChanged: enabled && !_isSaving
                  ? (value) => onChanged(channels.copyWith(sms: value))
                  : null,
              title: 'SMS',
              subtitle: 'Receive notifications via SMS',
              icon: Icons.sms_outlined,
              iconColor: AppColors.success,
              enabled: enabled,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelOption({
    required BuildContext context,
    required ThemeData theme,
    required bool value,
    required Function(bool)? onChanged,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool enabled,
    bool isLast = false,
  }) {
    return Column(
      children: [
        SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: enabled
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: enabled
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: enabled
                  ? iconColor.withAlpha((0.1 * 255).toInt())
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: enabled ? iconColor : AppColors.textDisabled,
              size: 22,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        ),
        if (!isLast)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 72),
            height: 1,
            color: AppColors.backgroundLight,
          ),
      ],
    );
  }
}
