import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/notification_preferences_model.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/redesign.dart';
import '../providers/user_profile_provider.dart';

/// Notification Settings Screen (R2C — first BbSwitch consumer).
///
/// Refactored onto the Phase 1.3 `BbSwitch` primitive (PR #624). Sections
/// grouped via `BbCard(padded: true)` + `BbSectionHeader`. An info banner
/// (accent-left `BbCard`) renders when the master switch is OFF, replacing
/// the legacy ad-hoc warning container.
///
/// FCM token mgmt, notification preference Firestore writes, permission
/// request flow (iOS APNS / Android POST_NOTIFICATIONS / browser
/// Notification API), foreground/background channel setup, and the
/// `firebase-messaging-sw.js` references are intentionally UNTOUCHED.
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

  /// Persist a quiet-hours change. Uses copyWith on the nested [QuietHours]
  /// config so no field is lost (CLAUDE.md: never reconstruct nested config).
  Future<void> _updateQuietHours(QuietHours quietHours) async {
    if (_currentPreferences == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      final updated = _currentPreferences!.copyWith(quietHours: quietHours);
      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateNotificationPreferences(updated);

      if (mounted) {
        ref.invalidate(notificationPreferencesProvider);
        setState(() {
          _currentPreferences = updated;
          _isSaving = false;
        });
      }
    } catch (e, stackTrace) {
      LoggingService.log(
        'Error updating quiet hours: $e',
        tag: 'NotificationSettings',
      );
      await LoggingService.logError(
        'Failed to update quiet hours',
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

  /// Open a native TimePicker seeded from an "HH:mm" string; on confirm,
  /// persist the picked time via [onPicked] as a zero-padded "HH:mm".
  Future<void> _pickTime(
    String currentHhmm,
    ValueChanged<String> onPicked, {
    String? helpText,
  }) async {
    final parts = currentHhmm.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 22,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: helpText,
    );
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      onPicked('$hh:$mm');
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final horizontalPadding = isMobile ? BBSpace.sm : BBSpace.md;
    final BBColorSet c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.notificationSettingsTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      backgroundColor: c.bg,
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
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

                return ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: BBSpace.sm,
                  ),
                  children: <Widget>[
                    // Premium info banner — payments are critical, always sent via email.
                    // Mirrors settings.jsx §381 SInfoBanner (info tone). Static copy:
                    // no behavior implied, just sets user expectation.
                    BbCard(
                      variant: BbCardVariant.accentLeft,
                      accentTone: BbCardAccentTone.info,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          BbIcon(name: 'notifications_active', color: c.info),
                          const SizedBox(width: BBSpace.xs),
                          Expanded(
                            child: Text(
                              l10n.notificationSettingsBannerInfo,
                              style: BBType.body(
                                context,
                              ).copyWith(color: c.textSecondary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: BBSpace.sm),

                    // Master switch card
                    BbCard(
                      child: BbSwitch(
                        value: masterEnabled,
                        onChanged: _isSaving ? null : _toggleMasterSwitch,
                        label: l10n.notificationSettingsEnableAll,
                        subtitle: l10n.notificationSettingsMasterSwitch,
                      ),
                    ),

                    // Warning banner when master OFF — accent-left info card
                    if (!masterEnabled) ...<Widget>[
                      const SizedBox(height: BBSpace.sm),
                      BbCard(
                        variant: BbCardVariant.accentLeft,
                        accentTone: BbCardAccentTone.error,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            BbIcon(name: 'info', color: c.error),
                            const SizedBox(width: BBSpace.xs),
                            Expanded(
                              child: Text(
                                l10n.notificationSettingsDisabledWarning,
                                style: BBType.body(
                                  context,
                                ).copyWith(color: c.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: BBSpace.md),

                    // Categories group header
                    BbSectionHeader(
                      title: l10n.notificationSettingsCategories,
                      level: BbSectionHeaderLevel.h3,
                    ),

                    // Payments category card (only effectively-active category;
                    // bookings removed per inline comment in original; calendar +
                    // marketing intentionally hidden until backend wires them up).
                    BbCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: c.primary.withValues(alpha: 0.12),
                                  borderRadius: BBRadius.smAll,
                                ),
                                child: Icon(
                                  Icons.payment,
                                  color: c.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: BBSpace.xs),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      l10n.notificationSettingsPayments,
                                      style: BBType.label(
                                        context,
                                      ).copyWith(color: c.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.notificationSettingsPaymentsDesc,
                                      style: BBType.caption(
                                        context,
                                      ).copyWith(color: c.textTertiary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: BBSpace.xs),
                          Divider(height: 1, thickness: 1, color: c.border),
                          // Eyebrow row — column header chrome (mockup §305 NotifTable
                          // header). Single category surface, so renders as compact
                          // "KANALI · EMAIL + PUSH" label vs full table grid.
                          Padding(
                            padding: const EdgeInsets.only(top: BBSpace.xs),
                            child: Text(
                              l10n.notificationSettingsChannelsEyebrow,
                              style: BBType.eyebrow(
                                context,
                              ).copyWith(color: c.textTertiary, fontSize: 10),
                            ),
                          ),
                          const SizedBox(height: BBSpace.xxs),
                          BbSwitch(
                            value: masterEnabled && categories.payments.email,
                            onChanged: (masterEnabled && !_isSaving)
                                ? (bool value) => _updateCategory(
                                    'payments',
                                    categories.payments.copyWith(email: value),
                                  )
                                : null,
                            label: l10n.notificationSettingsEmailChannel,
                            subtitle: l10n.notificationSettingsEmailChannelDesc,
                          ),
                          BbSwitch(
                            value: masterEnabled && categories.payments.push,
                            onChanged: (masterEnabled && !_isSaving)
                                ? (bool value) => _updateCategory(
                                    'payments',
                                    categories.payments.copyWith(push: value),
                                  )
                                : null,
                            label: l10n.notificationSettingsPushChannel,
                            subtitle: l10n.notificationSettingsPushChannelDesc,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: BBSpace.md),

                    // Quiet Hours (Tihi sati) — enforced server-side in
                    // notificationPreferences.ts (push suppressed during window).
                    BbSectionHeader(
                      title: l10n.quietHoursTitle,
                      level: BbSectionHeaderLevel.h3,
                    ),
                    buildQuietHoursCard(
                      context: context,
                      quietHours: _currentPreferences!.quietHours,
                      enabled: !_isSaving,
                      onToggle: (bool v) => _updateQuietHours(
                        _currentPreferences!.quietHours.copyWith(enabled: v),
                      ),
                      onPickStart: () => _pickTime(
                        _currentPreferences!.quietHours.start,
                        (String hhmm) => _updateQuietHours(
                          _currentPreferences!.quietHours.copyWith(start: hhmm),
                        ),
                        // TODO(l10n): use l10n key when one is added for this string
                        helpText: 'Početak tihih sati',
                      ),
                      onPickEnd: () => _pickTime(
                        _currentPreferences!.quietHours.end,
                        (String hhmm) => _updateQuietHours(
                          _currentPreferences!.quietHours.copyWith(end: hhmm),
                        ),
                        // TODO(l10n): use l10n key when one is added for this string
                        helpText: 'Kraj tihih sati',
                      ),
                    ),
                    const SizedBox(height: BBSpace.md),
                  ],
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(c.primary),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(BBSpace.lg),
                  child: BbEmptyState(
                    icon: 'error_outline',
                    title: l10n.notificationSettingsLoadError,
                    body: error.toString(),
                    compact: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quiet Hours (Tihi sati) card — enable switch + start/end time pickers.
/// Time pickers only render when [quietHours.enabled] is true.
///
/// Extracted as a top-level `@visibleForTesting` builder so a seam test can
/// pump it directly without the provider-backed screen. Pure presentation:
/// all persistence flows through the callbacks.
@visibleForTesting
Widget buildQuietHoursCard({
  required BuildContext context,
  required QuietHours quietHours,
  required bool enabled,
  required ValueChanged<bool> onToggle,
  required VoidCallback onPickStart,
  required VoidCallback onPickEnd,
}) {
  final BBColorSet c = BBColor.of(context);
  final l10n = AppLocalizations.of(context);
  final startMin = _hhmmToMinutes(quietHours.start);
  final endMin = _hhmmToMinutes(quietHours.end);
  final crossesMidnight =
      startMin != null && endMin != null && startMin > endMin;

  return BbCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        BbSwitch(
          key: const ValueKey('quiet_hours_switch'),
          value: quietHours.enabled,
          onChanged: enabled ? onToggle : null,
          label: l10n.quietHoursEnable,
          subtitle: l10n.quietHoursSubtitle,
        ),
        if (quietHours.enabled) ...<Widget>[
          const SizedBox(height: BBSpace.xs),
          Divider(height: 1, thickness: 1, color: c.border),
          const SizedBox(height: BBSpace.xs),
          Row(
            children: <Widget>[
              Expanded(
                child: _QuietTimeField(
                  fieldKey: const ValueKey('quiet_hours_start'),
                  label: l10n.quietHoursStart,
                  value: quietHours.start,
                  onTap: enabled ? onPickStart : null,
                ),
              ),
              const SizedBox(width: BBSpace.sm),
              Expanded(
                child: _QuietTimeField(
                  fieldKey: const ValueKey('quiet_hours_end'),
                  label: l10n.quietHoursEnd,
                  value: quietHours.end,
                  onTap: enabled ? onPickEnd : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpace.xs),
          Text(
            crossesMidnight
                ? l10n.quietHoursCrossMidnight(quietHours.start, quietHours.end)
                : l10n.quietHoursInfo,
            style: BBType.caption(context).copyWith(color: c.textTertiary),
          ),
        ],
      ],
    ),
  );
}

int? _hhmmToMinutes(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

/// Read-only tappable time field with a 12px-radius border (CLAUDE.md input
/// standard) that opens the native TimePicker via [onTap].
class _QuietTimeField extends StatelessWidget {
  const _QuietTimeField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final Key fieldKey;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: BBType.caption(context).copyWith(color: c.textTertiary),
        ),
        const SizedBox(height: BBSpace.xxs),
        InkWell(
          key: fieldKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BBSpace.sm,
                vertical: BBSpace.xs,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    value,
                    style: BBType.body(context).copyWith(color: c.textPrimary),
                  ),
                  Icon(Icons.schedule, size: 18, color: c.textTertiary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
