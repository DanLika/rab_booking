import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/design/bb_redesign_tokens.dart';
import '../../../../../core/design/tokens.dart';
import '../../../../../core/services/logging_service.dart';
import '../../../../../core/utils/async_utils.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../../core/utils/platform_scroll_physics.dart';
import '../../../../../core/utils/responsive_spacing_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../../../../shared/widgets/redesign.dart';
import '../../../domain/models/ical_feed.dart';
import '../../providers/ical_feeds_provider.dart';
import '../../providers/owner_calendar_provider.dart';
import '../../providers/owner_properties_provider.dart';
import '../../widgets/ical/ical_feed_delete_dialog.dart';
import '../../widgets/owner_app_drawer.dart';

const double _kDialogMaxWidth = 500.0;
const double _kDialogWidthFactor = 0.9;

/// iCal import sync — manages external calendar feeds (Booking.com, Airbnb, …).
///
/// Refactored onto the redesign Bb* foundation (PR redesign/r3-embed-ical).
/// Hero card uses the brand-primary gradient + `rd.purpleGlow`; sections use
/// [BbCard] with [BbSectionHeader]; dialog form swaps to [BbInput] +
/// [BbSwitch] + [BbButton]. Parent [Scaffold] + [CommonAppBar] +
/// [OwnerAppDrawer] are deliberately not swapped (deferred to the shell-swap
/// PR per audit/104).
///
/// FROZEN / preserved (per CLAUDE.md NIKADA NE MIJENJAJ + task guard):
///  - All iCal token logic, RFC 5545 parsing, feed subscription, Adriagate
///    re-export, token rotation lives in `functions/src/icalSync.ts` and the
///    `IcalRepository` — UNTOUCHED.
///  - `icalRepositoryProvider`, `icalFeedsStreamProvider`,
///    `icalStatisticsProvider`, `ownerUnitsProvider`,
///    `calendarBookingsProvider` — provider chain preserved verbatim.
///  - `syncIcalFeedNow` callable invocation + auto-sync ScaffoldMessenger
///    capture-before-pop pattern — preserved (otherwise snackbar disappears).
///  - [AndroidKeyboardDismissFixApproach1] mixin + `keyboardFixRebuildKey`
///    + `KeyedSubtree(ValueKey('ical_sync_settings_screen_$…'))`.
///  - `PopScope` browser-back handler routing to `/owner/integrations`.
///  - `IcalFeedDeleteDialog` (separate file) reused for destructive confirm.
///  - `_checkPlatformMismatch` URL → platform detection logic.
class IcalSyncSettingsScreen extends ConsumerStatefulWidget {
  const IcalSyncSettingsScreen({super.key});

  @override
  ConsumerState<IcalSyncSettingsScreen> createState() =>
      _IcalSyncSettingsScreenState();
}

class _IcalSyncSettingsScreenState extends ConsumerState<IcalSyncSettingsScreen>
    with AndroidKeyboardDismissFixApproach1<IcalSyncSettingsScreen> {
  int? _expandedPlatform;

  @override
  Widget build(BuildContext context) {
    final feedsAsync = ref.watch(icalFeedsStreamProvider);
    final statsAsync = ref.watch(icalStatisticsProvider);
    final l10n = AppLocalizations.of(context);
    final rd = BbRedesignTokens.of(context);
    final c = BBColor.of(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/owner/integrations');
          }
        }
      },
      child: KeyedSubtree(
        key: ValueKey('ical_sync_settings_screen_$keyboardFixRebuildKey'),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: CommonAppBar(
            title: l10n.icalSyncTitle,
            leadingIcon: Icons.menu,
            onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
          ),
          drawer: const OwnerAppDrawer(
            currentRoute: 'integrations/ical/import',
          ),
          body: Container(
            color: rd.shellBg,
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(icalFeedsStreamProvider);
                  ref.invalidate(icalStatisticsProvider);
                },
                color: c.primary,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 900;
                    final isTablet = constraints.maxWidth > 600;
                    final horizontalPadding = isDesktop
                        ? 48.0
                        : (isTablet ? 32.0 : BBSpace.sm);

                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: PlatformScrollPhysics.adaptive,
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 20,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isDesktop ? 1200.0 : double.infinity,
                          ),
                          child: statsAsync.when(
                            data: (stats) {
                              final totalFeeds =
                                  stats['total_feeds'] as int? ?? 0;
                              final hasFeeds = totalFeeds > 0;
                              return _layoutBody(
                                context: context,
                                isDesktop: isDesktop,
                                stats: stats,
                                hasFeeds: hasFeeds,
                                feedsAsync: feedsAsync,
                              );
                            },
                            loading: () => _layoutBody(
                              context: context,
                              isDesktop: isDesktop,
                              stats: null,
                              hasFeeds: false,
                              feedsAsync: feedsAsync,
                            ),
                            error: (_, _) => _layoutBody(
                              context: context,
                              isDesktop: isDesktop,
                              stats: null,
                              hasFeeds: false,
                              feedsAsync: feedsAsync,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _layoutBody({
    required BuildContext context,
    required bool isDesktop,
    required Map<String, dynamic>? stats,
    required bool hasFeeds,
    required AsyncValue<List<IcalFeed>> feedsAsync,
  }) {
    final hero = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 800.0 : double.infinity,
      ),
      child: _buildHeroCard(context, stats),
    );
    final benefits = _buildBenefitsSection(context);
    final platforms = _buildPlatformInstructions(context);
    final Widget? feeds = hasFeeds
        ? feedsAsync.when(
            data: (feeds) => _buildFeedsSection(context, feeds),
            loading: () => _buildFeedsLoading(context),
            error: (_, _) => _buildFeedsError(context),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        hero,
        const SizedBox(height: BBSpace.md),
        if (isDesktop) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: benefits),
                const SizedBox(width: BBSpace.md),
                Expanded(child: platforms),
              ],
            ),
          ),
          if (feeds != null) ...[const SizedBox(height: BBSpace.md), feeds],
        ] else ...[
          benefits,
          const SizedBox(height: BBSpace.md),
          if (feeds != null) ...[feeds, const SizedBox(height: BBSpace.md)],
          platforms,
        ],
        const SizedBox(height: BBSpace.lg),
      ],
    );
  }

  /// Hero — brand-primary gradient surface with status pill, description and
  /// CTA. Uses [BbRedesignTokens.brandPrimaryGradient] + `rd.purpleGlow` for
  /// the floating console feel; CTA is a `BbButton(onGradientSolid)`.
  Widget _buildHeroCard(BuildContext context, Map<String, dynamic>? stats) {
    final rd = BbRedesignTokens.of(context);
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);

    final activeFeeds = (stats?['active_feeds'] as int?) ?? 0;
    final errorFeeds = (stats?['error_feeds'] as int?) ?? 0;
    final totalFeeds = (stats?['total_feeds'] as int?) ?? 0;

    final _HeroStatus status = _resolveHeroStatus(
      totalFeeds: totalFeeds,
      errorFeeds: errorFeeds,
      activeFeeds: activeFeeds,
      l10n: l10n,
      c: c,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 700;

        final iconBackplate = Container(
          padding: const EdgeInsets.all(BBSpace.sm),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BBRadius.smAll,
          ),
          child: Icon(
            status.icon,
            size: isDesktop ? 24 : 32,
            color: Colors.white,
          ),
        );

        final statusPill = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: status.tint.withValues(alpha: 0.9),
            borderRadius: BBRadius.fullAll,
          ),
          child: Text(
            status.title,
            style: BBType.caption(
              context,
            ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        );

        final statusBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            statusPill,
            const SizedBox(height: BBSpace.xs),
            Text(
              status.description,
              style: BBType.body(
                context,
              ).copyWith(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ],
        );

        final cta = BbButton(
          key: const ValueKey('ical_add_feed_button'),
          label: l10n.icalAddFeedButton,
          iconLeft: 'add',
          variant: BbButtonVariant.onGradientSolid,
          fullWidth: !isDesktop,
          onPressed: () => _showAddFeedDialog(context),
        );

        return Container(
          decoration: BoxDecoration(
            gradient: rd.brandPrimaryGradient,
            borderRadius: BBRadius.mdAll,
            boxShadow: rd.purpleGlow,
          ),
          padding: const EdgeInsets.all(BBSpace.md),
          child: isDesktop
              ? Row(
                  children: [
                    iconBackplate,
                    const SizedBox(width: BBSpace.sm),
                    Expanded(child: statusBlock),
                    const SizedBox(width: BBSpace.sm),
                    SizedBox(width: 200, child: cta),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        iconBackplate,
                        const SizedBox(width: BBSpace.sm),
                        Expanded(child: statusBlock),
                      ],
                    ),
                    const SizedBox(height: BBSpace.sm),
                    cta,
                  ],
                ),
        );
      },
    );
  }

  _HeroStatus _resolveHeroStatus({
    required int totalFeeds,
    required int errorFeeds,
    required int activeFeeds,
    required AppLocalizations l10n,
    required BBColorSet c,
  }) {
    if (totalFeeds == 0) {
      return _HeroStatus(
        icon: Icons.sync_disabled,
        tint: c.textTertiary,
        title: l10n.icalNoFeeds,
        description: l10n.icalNoFeedsDescription,
      );
    }
    if (errorFeeds > 0) {
      return _HeroStatus(
        icon: Icons.error,
        tint: c.error,
        title: l10n.icalSyncError,
        description: l10n.icalSyncErrorCount(errorFeeds, totalFeeds),
      );
    }
    if (activeFeeds > 0) {
      return _HeroStatus(
        icon: Icons.check_circle,
        tint: c.success,
        title: l10n.icalSyncActive,
        description: l10n.icalSyncActiveCount(activeFeeds),
      );
    }
    return _HeroStatus(
      icon: Icons.pause_circle,
      tint: c.warning,
      title: l10n.icalAllFeedsPaused,
      description: l10n.icalNoActiveFeeds,
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final benefits = <_BenefitItem>[
      _BenefitItem('sync', l10n.icalAutoSync, l10n.icalAutoSyncDesc),
      _BenefitItem(
        'calendar_today',
        l10n.icalPreventDoubleBooking,
        l10n.icalPreventDoubleBookingDesc,
      ),
      _BenefitItem(
        'check_circle',
        l10n.icalCompatibility,
        l10n.icalCompatibilityDesc,
      ),
      _BenefitItem('security', l10n.icalSecure, l10n.icalSecureDesc),
    ];

    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BbSectionHeader(
            title: l10n.icalWhySync,
            level: BbSectionHeaderLevel.h3,
          ),
          ...benefits.map((b) => _buildBenefitRow(context, b)),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(BuildContext context, _BenefitItem item) {
    final c = BBColor.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: BBSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(BBSpace.xs),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.1),
              borderRadius: BBRadius.xsAll,
            ),
            child: BbIcon(name: item.icon, color: c.primary),
          ),
          const SizedBox(width: BBSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: BBType.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedsSection(BuildContext context, List<IcalFeed> feeds) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);

    return BbCard(
      padded: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BBSpace.md,
              BBSpace.md,
              BBSpace.md,
              BBSpace.sm,
            ),
            child: BbSectionHeader(
              title: l10n.icalYourFeeds,
              level: BbSectionHeaderLevel.h3,
              count: feeds.length,
            ),
          ),
          if (feeds.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BBSpace.md,
                0,
                BBSpace.md,
                BBSpace.md,
              ),
              child: BbEmptyState(
                icon: 'rss_feed',
                title: l10n.icalNoFeedsTitle,
                body: l10n.icalNoFeedsSubtitle,
                compact: true,
              ),
            )
          else ...[
            Divider(height: 1, color: c.border),
            ...feeds.map((feed) => _buildFeedRow(context, feed)),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedRow(BuildContext context, IcalFeed feed) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);
    final statusColor = _getStatusColor(feed.status, c);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: BBSpace.md,
            vertical: BBSpace.xs,
          ),
          leading: ClipRRect(
            borderRadius: BBRadius.smAll,
            child: Image.asset(
              _getPlatformIconPath(feed.platform),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BBRadius.smAll,
                  ),
                  child: Center(
                    child: Text(
                      feed.platformDisplayName[0],
                      style: BBType.h3(context).copyWith(color: statusColor),
                    ),
                  ),
                );
              },
            ),
          ),
          title: Row(
            children: [
              Text(
                feed.platformDisplayName,
                style: BBType.body(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: BBSpace.xs),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _getStatusLabel(feed.status, l10n),
                style: BBType.caption(
                  context,
                ).copyWith(color: statusColor, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                l10n.icalLastSynced(feed.getTimeSinceLastSync()),
                style: BBType.caption(context).copyWith(color: c.textSecondary),
              ),
              if (!feed.importEnabled)
                Row(
                  children: [
                    BbIcon(name: 'upload', size: 14, color: c.warning),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        l10n.icalImportDisabledWarning,
                        style: BBType.caption(context).copyWith(
                          color: c.warning,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (feed.hasError && feed.lastError != null)
                Text(
                  l10n.icalErrorPrefix(feed.lastError!),
                  style: BBType.caption(context).copyWith(color: c.error),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => _handleFeedAction(value, feed),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    const Icon(Icons.sync, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.icalSyncNow),
                  ],
                ),
              ),
              PopupMenuItem(
                value: feed.isActive ? 'pause' : 'resume',
                child: Row(
                  children: [
                    Icon(
                      feed.isActive ? Icons.pause : Icons.play_arrow,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(feed.isActive ? l10n.icalPause : l10n.icalResume),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.edit),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: c.error),
                    const SizedBox(width: 8),
                    Text(l10n.delete, style: TextStyle(color: c.error)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          indent: BBSpace.md,
          endIndent: BBSpace.md,
          color: c.border,
        ),
      ],
    );
  }

  String _getPlatformIconPath(IcalPlatform platform) => switch (platform) {
    IcalPlatform.bookingCom => 'assets/images/platforms/booking_icon.png',
    IcalPlatform.airbnb => 'assets/images/platforms/airbnb_icon.png',
    IcalPlatform.other => 'assets/images/platforms/other_sync_icon.png',
  };

  String _getStatusLabel(IcalStatus status, AppLocalizations l10n) =>
      switch (status) {
        IcalStatus.active => 'Aktivan',
        IcalStatus.paused => 'Pauziran',
        IcalStatus.error => 'Greška',
      };

  Color _getStatusColor(IcalStatus status, BBColorSet c) => switch (status) {
    IcalStatus.active => c.success,
    IcalStatus.error => c.error,
    IcalStatus.paused => c.warning,
  };

  Widget _buildFeedsLoading(BuildContext context) {
    return const BbCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: BBSpace.md),
        child: Center(child: BbSpinner()),
      ),
    );
  }

  Widget _buildFeedsError(BuildContext context) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);
    return BbCard(
      child: Center(
        child: Text(
          l10n.icalErrorLoadingFeeds,
          style: BBType.body(context).copyWith(color: c.error),
        ),
      ),
    );
  }

  Widget _buildPlatformInstructions(BuildContext context) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);

    return BbCard(
      padded: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BBSpace.md,
              BBSpace.md,
              BBSpace.md,
              BBSpace.sm,
            ),
            child: BbSectionHeader(
              title: l10n.icalGuideHeaderTitle,
              level: BbSectionHeaderLevel.h3,
            ),
          ),
          Divider(height: 1, color: c.border),
          _buildPlatformItem(
            context,
            0,
            'Booking.com',
            IcalPlatform.bookingCom,
            [
              l10n.icalGuideBookingCom1,
              l10n.icalGuideBookingCom2,
              l10n.icalGuideBookingCom3,
              l10n.icalGuideBookingCom4,
            ],
          ),
          Divider(
            height: 1,
            indent: BBSpace.md,
            endIndent: BBSpace.md,
            color: c.border,
          ),
          _buildPlatformItem(context, 1, 'Airbnb', IcalPlatform.airbnb, [
            l10n.icalGuideAirbnb1,
            l10n.icalGuideAirbnb2,
            l10n.icalGuideAirbnb3,
            l10n.icalGuideAirbnb4,
            l10n.icalGuideAirbnb5,
          ]),
        ],
      ),
    );
  }

  Widget _buildPlatformItem(
    BuildContext context,
    int index,
    String name,
    IcalPlatform platform,
    List<String> steps,
  ) {
    final c = BBColor.of(context);
    final isExpanded = _expandedPlatform == index;

    return Column(
      children: [
        InkWell(
          onTap: () =>
              setState(() => _expandedPlatform = isExpanded ? null : index),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BBSpace.md,
              vertical: BBSpace.sm,
            ),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    _getPlatformIconPath(platform),
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return BbIcon(name: 'sync', size: 24, color: c.primary);
                    },
                  ),
                ),
                const SizedBox(width: BBSpace.sm),
                Expanded(
                  child: Text(
                    name,
                    style: BBType.body(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                BbIcon(
                  name: isExpanded ? 'expand_less' : 'expand_more',
                  size: 24,
                  color: c.primary,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BBSpace.md,
              0,
              BBSpace.md,
              BBSpace.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps
                  .asMap()
                  .entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: BBSpace.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: c.primary,
                            child: Text(
                              '${e.key + 1}',
                              style: BBType.caption(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: BBSpace.xs),
                          Expanded(
                            child: Text(
                              e.value,
                              style: BBType.caption(
                                context,
                              ).copyWith(color: c.textPrimary, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  void _handleFeedAction(String action, IcalFeed feed) {
    switch (action) {
      case 'sync':
        _syncFeedNow(feed);
        break;
      case 'pause':
        _pauseFeed(feed);
        break;
      case 'resume':
        _resumeFeed(feed);
        break;
      case 'edit':
        _showEditFeedDialog(context, feed);
        break;
      case 'delete':
        _confirmDeleteFeed(context, feed);
        break;
    }
  }

  void _syncFeedNow(IcalFeed feed) async {
    final l10n = AppLocalizations.of(context);

    if (!feed.importEnabled) {
      ErrorDisplayUtils.showWarningSnackBar(
        context,
        l10n.icalImportDisabledWarning,
      );
      return;
    }

    LoggingService.log(
      'Manual sync triggered for feed: ${feed.id} (${feed.platformDisplayName})',
      tag: 'ICAL_SYNC',
    );
    ErrorDisplayUtils.showInfoSnackBar(
      context,
      l10n.icalSyncStarted(feed.platformDisplayName),
    );

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('syncIcalFeedNow');
      final result = await callable
          .call({'feedId': feed.id, 'propertyId': feed.propertyId})
          .withCloudFunctionTimeout('syncIcalFeedNow');

      if (!mounted) return;

      ref.invalidate(icalFeedsStreamProvider);
      ref.invalidate(icalStatisticsProvider);

      final data = result.data as Map<String, dynamic>?;
      final success = data?['success'] ?? false;
      final message = data?['message'] as String?;
      final bookingsCreated = data?['bookingsCreated'] as int? ?? 0;

      if (success) {
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          l10n.icalSyncSuccess(bookingsCreated),
        );
      } else {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          message ?? l10n.icalUnknownError,
          userMessage: l10n.icalSyncErrorMessage,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: AppLocalizations.of(context).icalSyncErrorMessage,
        );
      }
    }
  }

  void _pauseFeed(IcalFeed feed) async {
    final l10n = AppLocalizations.of(context);
    LoggingService.log(
      'Pausing iCal feed: ${feed.id} (${feed.platformDisplayName})',
      tag: 'ICAL_SYNC',
    );
    try {
      final repository = ref.read(icalRepositoryProvider);
      await repository.updateFeedStatus(
        feed.id,
        feed.propertyId,
        IcalStatus.paused,
      );
      if (mounted) {
        ref.invalidate(icalFeedsStreamProvider);
        ref.invalidate(icalStatisticsProvider);
        ErrorDisplayUtils.showSuccessSnackBar(context, l10n.icalFeedPaused);
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: AppLocalizations.of(context).icalFeedPauseError,
        );
      }
    }
  }

  void _resumeFeed(IcalFeed feed) async {
    final l10n = AppLocalizations.of(context);
    LoggingService.log(
      'Resuming iCal feed: ${feed.id} (${feed.platformDisplayName})',
      tag: 'ICAL_SYNC',
    );
    try {
      final repository = ref.read(icalRepositoryProvider);
      await repository.updateFeedStatus(
        feed.id,
        feed.propertyId,
        IcalStatus.active,
      );
      if (mounted) {
        ref.invalidate(icalFeedsStreamProvider);
        ref.invalidate(icalStatisticsProvider);
        ErrorDisplayUtils.showSuccessSnackBar(context, l10n.icalFeedResumed);
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: AppLocalizations.of(context).icalFeedResumeError,
        );
      }
    }
  }

  void _confirmDeleteFeed(BuildContext context, IcalFeed feed) {
    final l10n = AppLocalizations.of(context);
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => IcalFeedDeleteDialog(
        platformName: feed.platformDisplayName,
        eventCount: feed.eventCount,
      ),
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        LoggingService.log(
          'Deleting iCal feed: ${feed.id} (${feed.platformDisplayName})',
          tag: 'ICAL_SYNC',
        );
        try {
          final repository = ref.read(icalRepositoryProvider);
          await repository.deleteIcalFeed(feed.id, feed.propertyId);

          if (mounted && context.mounted) {
            ref.invalidate(icalFeedsStreamProvider);
            ref.invalidate(icalStatisticsProvider);
            ErrorDisplayUtils.showSuccessSnackBar(
              context,
              l10n.icalFeedDeleted,
            );
          }
        } catch (e) {
          if (mounted && context.mounted) {
            ErrorDisplayUtils.showErrorSnackBar(
              context,
              e,
              userMessage: l10n.icalFeedDeleteError,
            );
          }
        }
      }
    });
  }

  void _showAddFeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddIcalFeedDialog(),
    );
  }

  void _showEditFeedDialog(BuildContext context, IcalFeed feed) {
    showDialog(
      context: context,
      builder: (context) => AddIcalFeedDialog(existingFeed: feed),
    );
  }
}

class _HeroStatus {
  const _HeroStatus({
    required this.icon,
    required this.tint,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final Color tint;
  final String title;
  final String description;
}

class _BenefitItem {
  const _BenefitItem(this.icon, this.title, this.description);
  final String icon;
  final String title;
  final String description;
}

/// Add / edit dialog — refactored chrome (panel surface via
/// [BbRedesignTokens] + [BbInput] / [BbSwitch] / [BbButton]) while preserving
/// the dialog flow (centered modal, capture-before-pop snackbar pattern,
/// `_checkPlatformMismatch` URL detection, repository create/update calls).
class AddIcalFeedDialog extends ConsumerStatefulWidget {
  final IcalFeed? existingFeed;
  const AddIcalFeedDialog({super.key, this.existingFeed});

  @override
  ConsumerState<AddIcalFeedDialog> createState() => _AddIcalFeedDialogState();
}

class _AddIcalFeedDialogState extends ConsumerState<AddIcalFeedDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _icalUrlController;
  late TextEditingController _customPlatformNameController;
  String? _selectedUnitId;
  String? _selectedPropertyId;
  IcalPlatform _selectedPlatform = IcalPlatform.bookingCom;
  bool _importEnabled = true;
  bool _isSaving = false;
  String? _platformMismatchWarning;

  @override
  void initState() {
    super.initState();
    _icalUrlController = TextEditingController(
      text: widget.existingFeed?.icalUrl ?? '',
    );
    _customPlatformNameController = TextEditingController(
      text: widget.existingFeed?.customPlatformName ?? '',
    );
    if (widget.existingFeed != null) {
      _selectedUnitId = widget.existingFeed!.unitId;
      _selectedPropertyId = widget.existingFeed!.propertyId;
      _selectedPlatform = widget.existingFeed!.platform;
      _importEnabled = widget.existingFeed!.importEnabled;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkPlatformMismatch();
    });
  }

  /// Detect platform from URL and warn if it disagrees with the selection.
  void _checkPlatformMismatch() {
    final url = _icalUrlController.text.trim();
    if (url.isEmpty) {
      setState(() => _platformMismatchWarning = null);
      return;
    }

    final detectedPlatform = IcalPlatform.detectFromUrl(url);
    if (detectedPlatform == null || _selectedPlatform == IcalPlatform.other) {
      setState(() => _platformMismatchWarning = null);
      return;
    }

    if (detectedPlatform != _selectedPlatform) {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _platformMismatchWarning = l10n.icalUrlPlatformMismatch(
          detectedPlatform.displayName,
          _selectedPlatform.displayName,
        );
      });
    } else {
      setState(() => _platformMismatchWarning = null);
    }
  }

  @override
  void dispose() {
    _icalUrlController.dispose();
    _customPlatformNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(ownerUnitsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = screenWidth > _kDialogMaxWidth
        ? _kDialogMaxWidth
        : screenWidth * _kDialogWidthFactor;
    final l10n = AppLocalizations.of(context);
    final rd = BbRedesignTokens.of(context);
    final c = BBColor.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BBRadius.lgAll),
      child: Container(
        decoration: BoxDecoration(
          color: rd.panelBg,
          borderRadius: BBRadius.lgAll,
          border: Border.all(color: rd.panelBorder),
          boxShadow: rd.panelShadow,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight:
                screenHeight *
                ResponsiveSpacingHelper.getDialogMaxHeightPercent(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, l10n, c),
              Divider(height: 1, color: c.border),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(BBSpace.md),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildUnitDropdown(context, l10n, unitsAsync),
                        const SizedBox(height: BBSpace.sm),
                        _buildPlatformDropdown(context, l10n),
                        if (_selectedPlatform == IcalPlatform.other) ...[
                          const SizedBox(height: BBSpace.sm),
                          BbInput(
                            key: const ValueKey('ical_custom_platform_name'),
                            controller: _customPlatformNameController,
                            label: l10n.icalCustomPlatformName,
                            placeholder: l10n.icalCustomPlatformNameHint,
                            validator: (value) {
                              if (_selectedPlatform == IcalPlatform.other &&
                                  (value == null || value.trim().isEmpty)) {
                                return l10n.icalCustomPlatformNameRequired;
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: BBSpace.sm),
                        BbInput(
                          key: const ValueKey('ical_url'),
                          controller: _icalUrlController,
                          label: l10n.icalUrlLabel,
                          placeholder: l10n.icalUrlHint,
                          iconLeft: 'link',
                          keyboardType: TextInputType.url,
                          onChanged: (_) => _checkPlatformMismatch(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.icalUrlRequired;
                            }
                            if (!value.startsWith('http://') &&
                                !value.startsWith('https://')) {
                              return l10n.icalUrlInvalid;
                            }
                            return null;
                          },
                        ),
                        if (_platformMismatchWarning != null) ...[
                          const SizedBox(height: BBSpace.xs),
                          _buildMismatchBanner(context),
                        ],
                        const SizedBox(height: BBSpace.sm),
                        _buildImportToggle(context, l10n),
                      ],
                    ),
                  ),
                ),
              ),
              _buildFooter(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    BBColorSet c,
  ) {
    return Padding(
      padding: const EdgeInsets.all(BBSpace.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.1),
              borderRadius: BBRadius.xsAll,
            ),
            child: BbIcon(name: 'sync', color: c.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AutoSizeText(
              widget.existingFeed == null
                  ? l10n.icalAddFeedTitle
                  : l10n.icalEditFeedTitle,
              style: BBType.h3(context),
              maxLines: 1,
              minFontSize: 14,
            ),
          ),
          const SizedBox(width: BBSpace.xs),
          BbButton(
            key: const ValueKey('ical_dialog_close'),
            iconLeft: 'close',
            variant: BbButtonVariant.tertiary,
            size: BbButtonSize.sm,
            asIcon: true,
            onPressed: () => Navigator.pop(context),
            semanticLabel: l10n.cancel,
          ),
        ],
      ),
    );
  }

  Widget _buildUnitDropdown(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<dynamic>> unitsAsync,
  ) {
    final c = BBColor.of(context);
    return unitsAsync.when(
      data: (units) {
        if (units.isEmpty) {
          return Text(
            l10n.icalNoUnitsCreated,
            style: BBType.body(context).copyWith(color: c.error),
          );
        }
        final validUnitId = units.any((u) => u.id == _selectedUnitId)
            ? _selectedUnitId
            : null;
        return DropdownButtonFormField<String>(
          initialValue: validUnitId,
          isExpanded: true,
          dropdownColor: InputDecorationHelper.getDropdownColor(context),
          decoration: InputDecorationHelper.buildDecoration(
            labelText: l10n.icalSelectUnit,
            context: context,
          ),
          items: units
              .map<DropdownMenuItem<String>>(
                (unit) => DropdownMenuItem<String>(
                  value: unit.id as String,
                  child: Text(
                    unit.name as String,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            final unit = units.firstWhere(
              (u) => u.id == value,
              orElse: () => units.first,
            );
            setState(() {
              _selectedUnitId = value;
              _selectedPropertyId = unit.propertyId as String;
            });
          },
          validator: (value) => (value == null || value.isEmpty)
              ? l10n.icalSelectUnitRequired
              : null,
        );
      },
      loading: () => const Center(child: BbSpinner()),
      error: (_, _) => Text(l10n.icalErrorLoadingUnits),
    );
  }

  Widget _buildPlatformDropdown(BuildContext context, AppLocalizations l10n) {
    return DropdownButtonFormField<IcalPlatform>(
      initialValue: _selectedPlatform,
      isExpanded: true,
      dropdownColor: InputDecorationHelper.getDropdownColor(context),
      decoration: InputDecorationHelper.buildDecoration(
        labelText: l10n.icalPlatform,
        context: context,
      ),
      items: [
        DropdownMenuItem(
          value: IcalPlatform.bookingCom,
          child: Text(l10n.icalPlatformBookingCom),
        ),
        DropdownMenuItem(
          value: IcalPlatform.airbnb,
          child: Text(l10n.icalPlatformAirbnb),
        ),
        DropdownMenuItem(
          value: IcalPlatform.other,
          child: Text(l10n.icalPlatformOther),
        ),
      ],
      onChanged: (value) {
        setState(() => _selectedPlatform = value!);
        _checkPlatformMismatch();
      },
    );
  }

  Widget _buildMismatchBanner(BuildContext context) {
    final c = BBColor.of(context);
    return BbCard(
      variant: BbCardVariant.accentLeft,
      accentTone: BbCardAccentTone.error,
      padding: const EdgeInsets.all(BBSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BbIcon(name: 'warning', color: c.warning),
          const SizedBox(width: BBSpace.xs),
          Expanded(
            child: Text(
              _platformMismatchWarning!,
              style: BBType.caption(context).copyWith(color: c.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportToggle(BuildContext context, AppLocalizations l10n) {
    return BbCard(
      padding: const EdgeInsets.all(BBSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BbSwitch(
            value: _importEnabled,
            onChanged: (value) => setState(() => _importEnabled = value),
            label: l10n.icalImportEnabled,
            subtitle: l10n.icalImportEnabledDescription,
          ),
          if (!_importEnabled) ...[
            const SizedBox(height: BBSpace.xs),
            _buildImportDisabledNote(context, l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildImportDisabledNote(BuildContext context, AppLocalizations l10n) {
    final c = BBColor.of(context);
    return BbCard(
      variant: BbCardVariant.accentLeft,
      accentTone: BbCardAccentTone.info,
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BbIcon(name: 'info', size: 18, color: c.warning),
          const SizedBox(width: BBSpace.xs),
          Expanded(
            child: Text(
              l10n.icalImportDisabledNote,
              style: BBType.caption(context).copyWith(color: c.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    final c = BBColor.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpace.sm,
        vertical: BBSpace.sm,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(BBRadius.lg),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: BbButton(
              key: const ValueKey('ical_dialog_cancel'),
              label: l10n.cancel,
              variant: BbButtonVariant.secondary,
              fullWidth: true,
              onPressed: _isSaving ? null : () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: BBSpace.sm),
          Expanded(
            child: BbButton(
              key: const ValueKey('ical_dialog_save'),
              label: widget.existingFeed == null
                  ? l10n.icalAddFeedButton
                  : l10n.save,
              iconLeft: _isSaving ? null : 'save',
              fullWidth: true,
              loading: _isSaving,
              onPressed: _isSaving ? null : _saveFeed,
            ),
          ),
        ],
      ),
    );
  }

  void _saveFeed() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      ErrorDisplayUtils.showWarningSnackBar(
        context,
        l10n.widgetPleaseCheckFormErrors,
      );
      return;
    }
    setState(() => _isSaving = true);

    final isNewFeed = widget.existingFeed == null;
    LoggingService.log(
      '${isNewFeed ? "Creating" : "Updating"} iCal feed for unit: $_selectedUnitId (platform: ${_selectedPlatform.displayName})',
      tag: 'ICAL_SYNC',
    );

    try {
      final repository = ref.read(icalRepositoryProvider);

      if (_selectedPropertyId == null) {
        throw StateError('Property ID not set - unit must be selected first');
      }

      String feedIdForSync;

      final customName = _selectedPlatform == IcalPlatform.other
          ? _customPlatformNameController.text.trim()
          : null;

      if (widget.existingFeed == null) {
        final newFeed = IcalFeed(
          id: '',
          unitId: _selectedUnitId!,
          propertyId: _selectedPropertyId!,
          icalUrl: _icalUrlController.text.trim(),
          platform: _selectedPlatform,
          customPlatformName: customName,
          importEnabled: _importEnabled,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        feedIdForSync = await repository.createIcalFeed(newFeed);
      } else {
        final updatedFeed = widget.existingFeed!.copyWith(
          icalUrl: _icalUrlController.text.trim(),
          platform: _selectedPlatform,
          customPlatformName: customName,
          importEnabled: _importEnabled,
        );
        await repository.updateIcalFeed(updatedFeed);
        feedIdForSync = widget.existingFeed!.id;
      }

      if (mounted) {
        ref.invalidate(icalFeedsStreamProvider);
        ref.invalidate(icalStatisticsProvider);

        // Capture before pop — context becomes invalid after Navigator.pop(),
        // so the auto-sync snackbar would silently fail if read post-pop.
        final syncPlatform = _selectedPlatform;
        final syncPropertyId = _selectedPropertyId!;

        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          widget.existingFeed == null
              ? l10n.icalAddFeedTitle
              : l10n.icalFeedUpdated,
        );

        if (_importEnabled) {
          _triggerAutoSync(feedIdForSync, syncPropertyId, syncPlatform);
        }

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.icalFeedSaveError,
        );
      }
    }
  }

  /// Fire-and-forget auto-sync after save. ScaffoldMessenger is captured
  /// before any await + before [Navigator.pop] so snackbars still surface
  /// after this widget is disposed.
  void _triggerAutoSync(
    String feedId,
    String propertyId,
    IcalPlatform platform,
  ) async {
    LoggingService.log(
      'Starting auto-sync for feed: $feedId (platform: ${platform.displayName})',
      tag: 'ICAL_SYNC',
    );

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.icalSyncStarted(platform.displayName)),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      LoggingService.log(
        'Calling syncIcalFeedNow Cloud Function for feed: $feedId',
        tag: 'ICAL_SYNC',
      );
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('syncIcalFeedNow');
      final result = await callable
          .call({'feedId': feedId, 'propertyId': propertyId})
          .withCloudFunctionTimeout('syncIcalFeedNow');

      LoggingService.log(
        'Cloud Function syncIcalFeedNow returned successfully',
        tag: 'ICAL_SYNC',
      );

      if (mounted) {
        ref.invalidate(icalFeedsStreamProvider);
        ref.invalidate(icalStatisticsProvider);
        ref.invalidate(calendarBookingsProvider);
      }

      final data = result.data as Map<String, dynamic>?;
      final success = data?['success'] ?? false;
      final message = data?['message'] as String?;
      final bookingsCreated = data?['bookingsCreated'] as int? ?? 0;

      LoggingService.log(
        'Auto-sync completed: success=$success, bookingsCreated=$bookingsCreated',
        tag: 'ICAL_SYNC',
      );

      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.icalSyncSuccess(bookingsCreated)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(message ?? l10n.icalSyncErrorMessage),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      unawaited(
        LoggingService.logError('Auto-sync failed for feed: $feedId', e, stack),
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.icalSyncErrorMessage),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
