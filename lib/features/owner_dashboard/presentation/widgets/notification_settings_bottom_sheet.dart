import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../core/utils/responsive_spacing_helper.dart';
import '../../../../shared/models/notification_preferences_model.dart';
import '../providers/user_profile_provider.dart';

/// Show notification settings bottom sheet
void showNotificationSettingsBottomSheet(BuildContext context, WidgetRef ref) {
  final screenHeight = MediaQuery.of(context).size.height;
  final maxHeightPercent =
      ResponsiveSpacingHelper.getBottomSheetMaxHeightPercent(context);
  final maxSheetHeight = screenHeight * maxHeightPercent;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: maxSheetHeight),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const NotificationSettingsBottomSheet(),
  );
}

/// Notification settings bottom sheet widget
class NotificationSettingsBottomSheet extends ConsumerStatefulWidget {
  const NotificationSettingsBottomSheet({super.key});

  @override
  ConsumerState<NotificationSettingsBottomSheet> createState() =>
      _NotificationSettingsBottomSheetState();
}

class _NotificationSettingsBottomSheetState
    extends ConsumerState<NotificationSettingsBottomSheet> {
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
        // Invalidate provider to force refresh from Firestore
        ref.invalidate(notificationPreferencesProvider);

        setState(() {
          _currentPreferences = updated;
          _isSaving = false;
        });

        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          value
              ? l10n.notificationSettingsEnabled
              : l10n.notificationSettingsDisabled,
        );
      }
    } catch (e, stackTrace) {
      LoggingService.log(
        'Error toggling master switch: $e',
        tag: 'NotificationSettings',
      );
      await LoggingService.logError(
        'Failed to toggle master switch',
        e,
        stackTrace,
      );
      if (mounted) {
        setState(() => _isSaving = false);
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.notificationSettingsUpdateError,
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
      final updatedCategories = switch (category) {
        // 'bookings' removed - owner always receives booking emails
        'payments' => _currentPreferences!.categories.copyWith(
          payments: channels,
        ),
        'calendar' => _currentPreferences!.categories.copyWith(
          calendar: channels,
        ),
        'marketing' => _currentPreferences!.categories.copyWith(
          marketing: channels,
        ),
        _ => null,
      };

      if (updatedCategories == null) return;

      final updated = _currentPreferences!.copyWith(
        categories: updatedCategories,
      );

      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateNotificationPreferences(updated);

      if (mounted) {
        // Invalidate provider to force refresh from Firestore
        ref.invalidate(notificationPreferencesProvider);

        setState(() {
          _currentPreferences = updated;
          _isSaving = false;
        });

        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          l10n.notificationSettingsUpdated(category),
        );
      }
    } catch (e, stackTrace) {
      LoggingService.log(
        'Error updating category $category: $e',
        tag: 'NotificationSettings',
      );
      await LoggingService.logError(
        'Failed to update notification category',
        e,
        stackTrace,
      );
      if (mounted) {
        setState(() => _isSaving = false);
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.notificationSettingsUpdateError,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (fixed) - matches CommonAppBar height (52px)
          Container(
            height: ResponsiveDialogUtils.kHeaderHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: theme.colorScheme.onSurface,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.notificationSettingsTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content (scrollable)
          Flexible(
            child: preferencesAsync.when(
              data: (preferences) {
                // Initialize with default preferences if none exist
                _currentPreferences ??=
                    preferences ??
                    NotificationPreferences(
                      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    );

                final masterEnabled = _currentPreferences!.masterEnabled;
                final categories = _currentPreferences!.categories;

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Master Switch
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: context.gradients.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.gradients.sectionBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: masterEnabled
                                        ? theme.colorScheme.primary.withAlpha(
                                            (0.12 * 255).toInt(),
                                          )
                                        : theme
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withAlpha((0.3 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    masterEnabled
                                        ? Icons.notifications_active_rounded
                                        : Icons.notifications_off_rounded,
                                    color: masterEnabled
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface.withAlpha(
                                            (0.38 * 255).toInt(),
                                          ),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Text
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.notificationSettingsEnableAll,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.notificationSettingsMasterSwitch,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Switch
                                Switch(
                                  value: masterEnabled,
                                  onChanged: _isSaving
                                      ? null
                                      : _toggleMasterSwitch,
                                  activeThumbColor: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Warning message when disabled
                        if (!masterEnabled)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withAlpha((0.3 * 255).toInt()),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outline.withAlpha(
                                  (0.3 * 255).toInt(),
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error.withAlpha(
                                      (0.12 * 255).toInt(),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    color: theme.colorScheme.error,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.notificationSettingsDisabledWarning,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),

                        // Categories Header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            l10n.notificationSettingsCategories,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
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
                          onChanged: (channels) =>
                              _updateCategory('payments', channels),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.error.withAlpha(
                                (0.1 * 255).toInt(),
                              ),
                              theme.colorScheme.error.withAlpha(
                                (0.05 * 255).toInt(),
                              ),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.notificationSettingsLoadError,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 12,
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
          ),
        ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.gradients.sectionBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Theme.of(context).colorScheme.primary,
          collapsedIconColor: Theme.of(context).colorScheme.primary,
          tilePadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha((0.12 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
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
            ),
          ),
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outline.withAlpha((0.1 * 255).toInt()),
              indent: 16,
              endIndent: 16,
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return _buildChannelOption(
                  context: context,
                  theme: theme,
                  value: enabled && channels.email,
                  onChanged: enabled && !_isSaving
                      ? (value) => onChanged(channels.copyWith(email: value))
                      : null,
                  title: l10n.notificationSettingsEmailChannel,
                  subtitle: l10n.notificationSettingsEmailChannelDesc,
                  icon: Icons.email_outlined,
                  iconColor: theme.colorScheme.primary,
                  enabled: enabled,
                  isLast:
                      true, // Push notifications hidden until mobile app release
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: enabled
                      ? iconColor.withAlpha((0.12 * 255).toInt())
                      : theme.colorScheme.surfaceContainerHighest.withAlpha(
                          (0.3 * 255).toInt(),
                        ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? iconColor
                      : theme.colorScheme.onSurface.withAlpha(
                          (0.38 * 255).toInt(),
                        ),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: enabled
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: enabled
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.3,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              // Switch
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: iconColor,
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outline.withAlpha((0.08 * 255).toInt()),
            indent: 62,
            endIndent: 16,
          ),
        if (isLast) const SizedBox(height: 8),
      ],
    );
  }
}
