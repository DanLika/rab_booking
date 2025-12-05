import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../shared/models/notification_preferences_model.dart';
import '../providers/user_profile_provider.dart';
import '../../../../shared/widgets/common_app_bar.dart';

/// Notification Settings Screen
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  NotificationPreferences? _currentPreferences;
  bool _isSaving = false;

  Future<void> _toggleMasterSwitch(bool value) async {
    if (_currentPreferences == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      final updated = _currentPreferences!.copyWith(masterEnabled: value);
      await ref.read(userProfileNotifierProvider.notifier).updateNotificationPreferences(updated);

      if (mounted) {
        // Invalidate provider to force refresh from Firestore
        ref.invalidate(notificationPreferencesProvider);

        setState(() {
          _currentPreferences = updated;
          _isSaving = false;
        });

        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? l10n.notificationSettingsEnabled : l10n.notificationSettingsDisabled),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: l10n.notificationSettingsUpdateError);
      }
    }
  }

  Future<void> _updateCategory(String category, NotificationChannels channels) async {
    if (_currentPreferences == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      NotificationCategories updatedCategories;

      switch (category) {
        case 'bookings':
          updatedCategories = _currentPreferences!.categories.copyWith(bookings: channels);
          break;
        case 'payments':
          updatedCategories = _currentPreferences!.categories.copyWith(payments: channels);
          break;
        case 'calendar':
          updatedCategories = _currentPreferences!.categories.copyWith(calendar: channels);
          break;
        case 'marketing':
          updatedCategories = _currentPreferences!.categories.copyWith(marketing: channels);
          break;
        default:
          return;
      }

      final updated = _currentPreferences!.copyWith(categories: updatedCategories);

      await ref.read(userProfileNotifierProvider.notifier).updateNotificationPreferences(updated);

      if (mounted) {
        // Invalidate provider to force refresh from Firestore
        ref.invalidate(notificationPreferencesProvider);

        setState(() {
          _currentPreferences = updated;
          _isSaving = false;
        });

        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.notificationSettingsUpdated(category)),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: l10n.notificationSettingsUpdateError);
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

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.notificationSettingsTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: preferencesAsync.when(
          data: (preferences) {
            // Initialize with default preferences if none exist
            _currentPreferences ??=
                preferences ?? NotificationPreferences(userId: FirebaseAuth.instance.currentUser?.uid ?? '');

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
                    gradient: masterEnabled ? context.gradients.brandPrimary : null,
                    color: masterEnabled ? null : context.gradients.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: masterEnabled
                          ? theme.colorScheme.primary.withAlpha((0.3 * 255).toInt())
                          : context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt()),
                      width: 1.5,
                    ),
                    boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
                  ),
                  child: Theme(
                    data: theme.copyWith(
                      switchTheme: SwitchThemeData(
                        thumbColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return isDark ? Colors.black : Colors.white;
                          }
                          return isDark ? Colors.black : Colors.white;
                        }),
                        trackColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return theme.colorScheme.primary;
                          }
                          return theme.colorScheme.outline;
                        }),
                      ),
                    ),
                    child: SwitchListTile(
                      value: masterEnabled,
                      onChanged: _isSaving ? null : _toggleMasterSwitch,
                      title: Text(
                        l10n.notificationSettingsEnableAll,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
                      ),
                      subtitle: Text(
                        l10n.notificationSettingsMasterSwitch,
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: masterEnabled
                                ? [
                                    theme.colorScheme.primary.withAlpha((0.15 * 255).toInt()),
                                    theme.colorScheme.secondary.withAlpha((0.08 * 255).toInt()),
                                  ]
                                : [
                                    theme.colorScheme.onSurface.withAlpha((0.1 * 255).toInt()),
                                    theme.colorScheme.onSurface.withAlpha((0.05 * 255).toInt()),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          masterEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                          color: masterEnabled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withAlpha((0.38 * 255).toInt()),
                          size: 26,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
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
                          theme.colorScheme.error.withAlpha((0.1 * 255).toInt()),
                          theme.colorScheme.error.withAlpha((0.05 * 255).toInt()),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.error.withAlpha((0.3 * 255).toInt())),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: theme.colorScheme.error, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.notificationSettingsDisabledWarning,
                            style: TextStyle(color: theme.colorScheme.error, fontSize: 13, fontWeight: FontWeight.w500),
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
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.notificationSettingsCategories,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),

                // Bookings Category
                _buildCategoryCard(
                  context: context,
                  theme: theme,
                  isDark: isDark,
                  title: l10n.notificationSettingsBookings,
                  description: l10n.notificationSettingsBookingsDesc,
                  icon: Icons.event_note,
                  iconColor: theme.colorScheme.secondary,
                  channels: categories.bookings,
                  enabled: masterEnabled,
                  onChanged: (channels) => _updateCategory('bookings', channels),
                ),

                // Payments Category
                _buildCategoryCard(
                  context: context,
                  theme: theme,
                  isDark: isDark,
                  title: l10n.notificationSettingsPayments,
                  description: l10n.notificationSettingsPaymentsDesc,
                  icon: Icons.payment,
                  iconColor: theme.colorScheme.primary,
                  channels: categories.payments,
                  enabled: masterEnabled,
                  onChanged: (channels) => _updateCategory('payments', channels),
                ),

                // Calendar Category
                _buildCategoryCard(
                  context: context,
                  theme: theme,
                  isDark: isDark,
                  title: l10n.notificationSettingsCalendar,
                  description: l10n.notificationSettingsCalendarDesc,
                  icon: Icons.calendar_today,
                  iconColor: theme.colorScheme.error,
                  channels: categories.calendar,
                  enabled: masterEnabled,
                  onChanged: (channels) => _updateCategory('calendar', channels),
                ),

                // Marketing Category
                _buildCategoryCard(
                  context: context,
                  theme: theme,
                  isDark: isDark,
                  title: l10n.notificationSettingsMarketing,
                  description: l10n.notificationSettingsMarketingDesc,
                  icon: Icons.campaign,
                  iconColor: theme.colorScheme.primary,
                  channels: categories.marketing,
                  enabled: masterEnabled,
                  onChanged: (channels) => _updateCategory('marketing', channels),
                ),

                const SizedBox(height: 24),
              ],
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)),
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
                          theme.colorScheme.error.withAlpha((0.1 * 255).toInt()),
                          theme.colorScheme.error.withAlpha((0.05 * 255).toInt()),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error_outline_rounded, size: 50, color: theme.colorScheme.error),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.notificationSettingsLoadError,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error.toString(),
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [iconColor.withAlpha((0.15 * 255).toInt()), iconColor.withAlpha((0.08 * 255).toInt())],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: iconColor.withAlpha((0.2 * 255).toInt()), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              description,
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    theme.colorScheme.outline.withAlpha((0.1 * 255).toInt()),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return _buildChannelOption(
                  context: context,
                  theme: theme,
                  value: enabled && channels.email,
                  onChanged: enabled && !_isSaving ? (value) => onChanged(channels.copyWith(email: value)) : null,
                  title: l10n.notificationSettingsEmailChannel,
                  subtitle: l10n.notificationSettingsEmailChannelDesc,
                  icon: Icons.email_outlined,
                  iconColor: theme.colorScheme.primary,
                  enabled: enabled,
                );
              },
            ),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return _buildChannelOption(
                  context: context,
                  theme: theme,
                  value: enabled && channels.push,
                  onChanged: enabled && !_isSaving ? (value) => onChanged(channels.copyWith(push: value)) : null,
                  title: l10n.notificationSettingsPushChannel,
                  subtitle: l10n.notificationSettingsPushChannelDesc,
                  icon: Icons.notifications_outlined,
                  iconColor: theme.colorScheme.error,
                  enabled: enabled,
                );
              },
            ),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return _buildChannelOption(
                  context: context,
                  theme: theme,
                  value: enabled && channels.sms,
                  onChanged: enabled && !_isSaving ? (value) => onChanged(channels.copyWith(sms: value)) : null,
                  title: l10n.notificationSettingsSmsChannel,
                  subtitle: l10n.notificationSettingsSmsChannelDesc,
                  icon: Icons.sms_outlined,
                  iconColor: theme.colorScheme.primary,
                  enabled: enabled,
                  isLast: true,
                );
              },
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
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Theme(
          data: theme.copyWith(
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return isDark ? Colors.black : Colors.white;
                }
                return isDark ? Colors.black : Colors.white;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return iconColor;
                }
                return theme.colorScheme.outline;
              }),
            ),
          ),
          child: SwitchListTile(
            value: value,
            onChanged: onChanged,
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: enabled ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
                color: enabled ? iconColor.withAlpha((0.1 * 255).toInt()) : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: enabled ? iconColor : theme.colorScheme.onSurface.withAlpha((0.38 * 255).toInt()),
                size: 22,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          ),
        ),
        if (!isLast)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 72),
            height: 1,
            color: theme.colorScheme.outline.withAlpha((0.1 * 255).toInt()),
          ),
      ],
    );
  }
}
