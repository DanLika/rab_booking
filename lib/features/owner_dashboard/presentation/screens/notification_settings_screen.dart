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
                              'Odaberite kako želite biti obaviješteni. Kritične '
                              'obavijesti o plaćanju uvijek šaljemo e-poštom.',
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
                              'KANALI · EMAIL + PUSH',
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
