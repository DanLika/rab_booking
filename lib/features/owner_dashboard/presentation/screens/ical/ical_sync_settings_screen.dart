import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../../../core/utils/async_utils.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/platform_scroll_physics.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../core/utils/responsive_spacing_helper.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../../domain/models/ical_feed.dart';
import '../../providers/ical_feeds_provider.dart';
import '../../providers/owner_calendar_provider.dart';
import '../../providers/owner_properties_provider.dart';
import '../../widgets/owner_app_drawer.dart';

/// Status indicator colors
const Color _kStatusActiveColor = Color(0xFF66BB6A);
const Color _kStatusPausedColor = Color(0xFFFFA726);
const Color _kStatusErrorColor = Color(0xFFEF5350);

/// Dialog width constraints
const double _kDialogMaxWidth = 500.0;
const double _kDialogWidthFactor = 0.9;

/// Screen for managing iCal calendar sync feeds
/// Redesigned: Premium feel with consistent theme support
class IcalSyncSettingsScreen extends ConsumerStatefulWidget {
  const IcalSyncSettingsScreen({super.key});

  @override
  ConsumerState<IcalSyncSettingsScreen> createState() =>
      _IcalSyncSettingsScreenState();
}

class _IcalSyncSettingsScreenState extends ConsumerState<IcalSyncSettingsScreen>
    with AndroidKeyboardDismissFixApproach1<IcalSyncSettingsScreen> {
  bool _showFaq = false;
  int? _expandedPlatform;

  @override
  Widget build(BuildContext context) {
    final feedsAsync = ref.watch(icalFeedsStreamProvider);
    final statsAsync = ref.watch(icalStatisticsProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Handle browser back button on Chrome Android
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
            decoration: BoxDecoration(
              gradient: context.gradients.pageBackground,
            ),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(icalFeedsStreamProvider);
                  ref.invalidate(icalStatisticsProvider);
                },
                color: theme.colorScheme.primary,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 900;
                    final isTablet = constraints.maxWidth > 600;
                    final horizontalPadding = isDesktop
                        ? 48.0
                        : (isTablet ? 32.0 : 16.0);

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

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Hero Status Card
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: isDesktop
                                          ? 800.0
                                          : double.infinity,
                                    ),
                                    child: _buildHeroCard(context, stats),
                                  ),
                                  const SizedBox(height: 24),

                                  // Desktop: Benefits + Feeds/Instructions side by side
                                  if (isDesktop) ...[
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildBenefitsSection(context),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: hasFeeds
                                              ? feedsAsync.when(
                                                  data: (feeds) =>
                                                      _buildFeedsSection(
                                                        context,
                                                        feeds,
                                                      ),
                                                  loading: () =>
                                                      _buildFeedsLoading(
                                                        context,
                                                      ),
                                                  error: (_, _) =>
                                                      _buildFeedsError(context),
                                                )
                                              : _buildPlatformInstructions(
                                                  context,
                                                ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    // Show FAQ only if has feeds, otherwise show Platform Instructions
                                    if (hasFeeds) ...[
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: _buildPlatformInstructions(
                                              context,
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          Expanded(
                                            child: _buildFaqSection(context),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ] else ...[
                                    // Mobile/Tablet: Stack vertically
                                    _buildBenefitsSection(context),
                                    const SizedBox(height: 24),
                                    if (hasFeeds) ...[
                                      feedsAsync.when(
                                        data: (feeds) =>
                                            _buildFeedsSection(context, feeds),
                                        loading: () =>
                                            _buildFeedsLoading(context),
                                        error: (_, _) =>
                                            _buildFeedsError(context),
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                    _buildPlatformInstructions(context),
                                    const SizedBox(height: 24),
                                    if (hasFeeds) _buildFaqSection(context),
                                  ],
                                  const SizedBox(height: 32),
                                ],
                              );
                            },
                            loading: () => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: isDesktop
                                        ? 800.0
                                        : double.infinity,
                                  ),
                                  child: _buildHeroCard(context, null),
                                ),
                                const SizedBox(height: 24),
                                if (isDesktop) ...[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildBenefitsSection(context),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: _buildPlatformInstructions(
                                          context,
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  _buildBenefitsSection(context),
                                  const SizedBox(height: 24),
                                  _buildPlatformInstructions(context),
                                ],
                                const SizedBox(height: 32),
                              ],
                            ),
                            error: (_, _) => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: isDesktop
                                        ? 800.0
                                        : double.infinity,
                                  ),
                                  child: _buildHeroCard(context, null),
                                ),
                                const SizedBox(height: 24),
                                if (isDesktop) ...[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildBenefitsSection(context),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: _buildPlatformInstructions(
                                          context,
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  _buildBenefitsSection(context),
                                  const SizedBox(height: 24),
                                  _buildPlatformInstructions(context),
                                ],
                                const SizedBox(height: 32),
                              ],
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

  Widget _buildHeroCard(BuildContext context, Map<String, dynamic>? stats) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final activeFeeds = (stats?['active_feeds'] as int?) ?? 0;
    final errorFeeds = (stats?['error_feeds'] as int?) ?? 0;
    final totalFeeds = (stats?['total_feeds'] as int?) ?? 0;

    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusDescription;

    if (totalFeeds == 0) {
      statusColor = theme.colorScheme.outline;
      statusIcon = Icons.sync_disabled;
      statusTitle = l10n.icalNoFeeds;
      statusDescription = l10n.icalNoFeedsDescription;
    } else if (errorFeeds > 0) {
      statusColor = _kStatusErrorColor;
      statusIcon = Icons.error;
      statusTitle = l10n.icalSyncError;
      statusDescription = l10n.icalSyncErrorCount(errorFeeds, totalFeeds);
    } else if (activeFeeds > 0) {
      statusColor = _kStatusActiveColor;
      statusIcon = Icons.check_circle;
      statusTitle = l10n.icalSyncActive;
      statusDescription = l10n.icalSyncActiveCount(activeFeeds);
    } else {
      statusColor = _kStatusPausedColor;
      statusIcon = Icons.pause_circle;
      statusTitle = l10n.icalAllFeedsPaused;
      statusDescription = l10n.icalNoActiveFeeds;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 700;

        return Container(
          decoration: BoxDecoration(
            gradient: context.gradients.brandPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? AppShadows.elevation3Dark
                : AppShadows.elevation3,
          ),
          padding: const EdgeInsets.all(24),
          child: isDesktop
              ? Row(
                  children: [
                    // Status icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(statusIcon, size: 32, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    // Status info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            statusDescription,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // CTA Button - fixed width on desktop
                    SizedBox(
                      width: 200,
                      child: FilledButton.icon(
                        onPressed: () => _showAddFeedDialog(context),
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(
                          l10n.icalAddFeedButton,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            statusIcon,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                statusDescription,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _showAddFeedDialog(context),
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(
                          l10n.icalAddFeedButton,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final benefits = [
      (Icons.sync_rounded, l10n.icalAutoSync, l10n.icalAutoSyncDesc),
      (
        Icons.calendar_today_rounded,
        l10n.icalPreventDoubleBooking,
        l10n.icalPreventDoubleBookingDesc,
      ),
      (
        Icons.check_circle_outline_rounded,
        l10n.icalCompatibility,
        l10n.icalCompatibilityDesc,
      ),
      (Icons.security_rounded, l10n.icalSecure, l10n.icalSecureDesc),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                l10n.icalWhySync,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...benefits.map((b) => _buildBenefitItem(context, b.$1, b.$2, b.$3)),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedsSection(BuildContext context, List<IcalFeed> feeds) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.rss_feed,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.icalYourFeeds,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${feeds.length}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (feeds.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.rss_feed_rounded,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.icalNoFeedsTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.icalNoFeedsSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.black.withValues(alpha: 0.55),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Divider(
              height: 1,
              color: isDark
                  ? AppColors.sectionDividerDark
                  : AppColors.sectionDividerLight,
            ),
            ...feeds.map((feed) => _buildFeedItem(context, feed)),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedItem(BuildContext context, IcalFeed feed) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final statusColor = _getStatusColor(feed.status, theme);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(feed.status),
              color: statusColor,
              size: 20,
            ),
          ),
          title: Text(
            feed.platform.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                l10n.icalLastSynced(feed.getTimeSinceLastSync()),
                style: theme.textTheme.bodySmall,
              ),
              if (feed.hasError && feed.lastError != null)
                Text(
                  l10n.icalErrorPrefix(feed.lastError!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _kStatusErrorColor,
                  ),
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
                    const Icon(Icons.delete, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      l10n.delete,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          indent: 20,
          endIndent: 20,
          color: theme.brightness == Brightness.dark
              ? AppColors.sectionDividerDark
              : AppColors.sectionDividerLight,
        ),
      ],
    );
  }

  Widget _buildFeedsLoading(BuildContext context) {
    final theme = Theme.of(context);
    // Minimalistic: Use black in light mode, white in dark mode
    final loaderColor = theme.brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: CircularProgressIndicator(color: loaderColor)),
    );
  }

  Widget _buildFeedsError(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          l10n.icalErrorLoadingFeeds,
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildPlatformInstructions(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.icalGuideHeaderTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark
                ? AppColors.sectionDividerDark
                : AppColors.sectionDividerLight,
          ),
          _buildPlatformItem(context, 0, 'Booking.com', Icons.hotel, [
            l10n.icalGuideBookingCom1,
            l10n.icalGuideBookingCom2,
            l10n.icalGuideBookingCom3,
            l10n.icalGuideBookingCom4,
          ]),
          Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: isDark
                ? AppColors.sectionDividerDark
                : AppColors.sectionDividerLight,
          ),
          _buildPlatformItem(context, 1, 'Airbnb', Icons.home, [
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
    IconData icon,
    List<String> steps,
  ) {
    final theme = Theme.of(context);
    final isExpanded = _expandedPlatform == index;

    return Column(
      children: [
        InkWell(
          onTap: () =>
              setState(() => _expandedPlatform = isExpanded ? null : index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps
                  .asMap()
                  .entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              '${e.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.value,
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.4,
                              ),
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

  Widget _buildFaqSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final faqs = [
      (l10n.icalGuideFaq1Q, l10n.icalGuideFaq1A),
      (l10n.icalGuideFaq2Q, l10n.icalGuideFaq2A),
      (l10n.icalGuideFaq3Q, l10n.icalGuideFaq3A),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showFaq = !_showFaq),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.question_answer,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.icalGuideFaqTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _showFaq ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_showFaq) ...[
            Divider(
              height: 1,
              color: isDark
                  ? AppColors.sectionDividerDark
                  : AppColors.sectionDividerLight,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: faqs
                    .map(
                      (faq) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '❓ ${faq.$1}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              faq.$2,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                height: 1.5,
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
        ],
      ),
    );
  }

  Color _getStatusColor(IcalStatus status, ThemeData theme) => switch (status) {
    IcalStatus.active => _kStatusActiveColor,
    IcalStatus.error => _kStatusErrorColor,
    IcalStatus.paused => _kStatusPausedColor,
  };

  IconData _getStatusIcon(IcalStatus status) => switch (status) {
    IcalStatus.active => Icons.check_circle,
    IcalStatus.error => Icons.error,
    IcalStatus.paused => Icons.pause_circle,
  };

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
    ErrorDisplayUtils.showInfoSnackBar(
      context,
      l10n.icalSyncStarted(feed.platform.displayName),
    );

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('syncIcalFeedNow');
      final result = await callable
          .call({'feedId': feed.id, 'propertyId': feed.propertyId})
          .withCloudFunctionTimeout('syncIcalFeedNow');

      // Invalidate providers to refresh UI after sync
      ref.invalidate(icalFeedsStreamProvider);
      ref.invalidate(icalStatisticsProvider);

      if (mounted) {
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
    try {
      final repository = ref.read(icalRepositoryProvider);
      await repository.updateFeedStatus(
        feed.id,
        feed.propertyId,
        IcalStatus.paused,
      );
      // Invalidate providers to refresh UI immediately
      ref.invalidate(icalFeedsStreamProvider);
      ref.invalidate(icalStatisticsProvider);
      if (mounted) {
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
    try {
      final repository = ref.read(icalRepositoryProvider);
      await repository.updateFeedStatus(
        feed.id,
        feed.propertyId,
        IcalStatus.active,
      );
      // Invalidate providers to refresh UI immediately
      ref.invalidate(icalFeedsStreamProvider);
      ref.invalidate(icalStatisticsProvider);
      if (mounted) {
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
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.icalDeleteFeedTitle),
        content: Text(
          l10n.icalDeleteFeedMessage(
            feed.platform.displayName,
            feed.eventCount,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              navigator.pop();
              try {
                final repository = ref.read(icalRepositoryProvider);
                // Delete feed and all associated events
                await repository.deleteIcalFeed(feed.id, feed.propertyId);
                // Invalidate providers to refresh UI immediately
                ref.invalidate(icalFeedsStreamProvider);
                ref.invalidate(icalStatisticsProvider);
                if (mounted) {
                  ErrorDisplayUtils.showSuccessSnackBar(
                    this.context,
                    l10n.icalFeedDeleted,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ErrorDisplayUtils.showErrorSnackBar(
                    this.context,
                    e,
                    userMessage: l10n.icalFeedDeleteError,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
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

/// Dialog for adding/editing iCal feed
class AddIcalFeedDialog extends ConsumerStatefulWidget {
  final IcalFeed? existingFeed;
  const AddIcalFeedDialog({super.key, this.existingFeed});

  @override
  ConsumerState<AddIcalFeedDialog> createState() => _AddIcalFeedDialogState();
}

class _AddIcalFeedDialogState extends ConsumerState<AddIcalFeedDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _icalUrlController;
  String? _selectedUnitId;
  String?
  _selectedPropertyId; // OPTIMIZED: Store property ID to avoid re-reading provider
  IcalPlatform _selectedPlatform = IcalPlatform.bookingCom;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _icalUrlController = TextEditingController(
      text: widget.existingFeed?.icalUrl ?? '',
    );
    if (widget.existingFeed != null) {
      _selectedUnitId = widget.existingFeed!.unitId;
      _selectedPropertyId = widget.existingFeed!.propertyId;
      _selectedPlatform = widget.existingFeed!.platform;
    }
  }

  @override
  void dispose() {
    _icalUrlController.dispose();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: context.gradients.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.gradients.sectionBorder),
          boxShadow: isDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
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
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sync,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.existingFeed == null
                            ? l10n.icalAddFeedTitle
                            : l10n.icalEditFeedTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark
                    ? AppColors.sectionDividerDark
                    : AppColors.sectionDividerLight,
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        unitsAsync.when(
                          data: (units) {
                            if (units.isEmpty) {
                              return Text(
                                l10n.icalNoUnitsCreated,
                                style: const TextStyle(color: AppColors.error),
                              );
                            }
                            final validUnitId =
                                units.any((u) => u.id == _selectedUnitId)
                                ? _selectedUnitId
                                : null;
                            return DropdownButtonFormField<String>(
                              initialValue: validUnitId,
                              isExpanded: true,
                              dropdownColor:
                                  InputDecorationHelper.getDropdownColor(
                                    context,
                                  ),
                              decoration: InputDecorationHelper.buildDecoration(
                                labelText: l10n.icalSelectUnit,
                                context: context,
                              ),
                              items: units
                                  .map(
                                    (unit) => DropdownMenuItem(
                                      value: unit.id,
                                      child: Text(
                                        unit.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                final unit = units.firstWhere(
                                  (u) => u.id == value,
                                  orElse: () => units
                                      .first, // Fallback (value always comes from dropdown items)
                                );
                                setState(() {
                                  _selectedUnitId = value;
                                  _selectedPropertyId = unit.propertyId;
                                });
                              },
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? l10n.icalSelectUnitRequired
                                  : null,
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (_, _) => Text(l10n.icalErrorLoadingUnits),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<IcalPlatform>(
                          initialValue: _selectedPlatform,
                          isExpanded: true,
                          dropdownColor: InputDecorationHelper.getDropdownColor(
                            context,
                          ),
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
                          onChanged: (value) =>
                              setState(() => _selectedPlatform = value!),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _icalUrlController,
                          decoration: InputDecorationHelper.buildDecoration(
                            labelText: l10n.icalUrlLabel,
                            hintText: l10n.icalUrlHint,
                            context: context,
                          ),
                          maxLines: 2,
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
                      ],
                    ),
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.dialogFooterDark
                      : AppColors.dialogFooterLight,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.sectionDividerDark
                          : AppColors.sectionDividerLight,
                    ),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(19),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.sectionDividerDark
                                : AppColors.sectionDividerLight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: AutoSizeText(
                          l10n.cancel,
                          maxLines: 1,
                          minFontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _isSaving
                              ? null
                              : context.gradients.brandPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveFeed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSaving
                                ? theme.colorScheme.surfaceContainerHighest
                                : Colors.transparent,
                            foregroundColor: _isSaving
                                ? theme.colorScheme.onSurface
                                : Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      widget.existingFeed == null
                                          ? Icons.add
                                          : Icons.save,
                                      size: 18,
                                    ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: AutoSizeText(
                                  widget.existingFeed == null
                                      ? l10n.icalAddFeedButton
                                      : l10n.save,
                                  maxLines: 1,
                                  minFontSize: 10,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

    try {
      final repository = ref.read(icalRepositoryProvider);

      // OPTIMIZED: Use stored _selectedPropertyId instead of re-reading provider
      if (_selectedPropertyId == null) {
        throw StateError('Property ID not set - unit must be selected first');
      }

      String feedIdForSync;

      if (widget.existingFeed == null) {
        final newFeed = IcalFeed(
          id: '',
          unitId: _selectedUnitId!,
          propertyId: _selectedPropertyId!,
          icalUrl: _icalUrlController.text.trim(),
          platform: _selectedPlatform,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        // FIX: Capture the created feed ID for auto-sync
        feedIdForSync = await repository.createIcalFeed(newFeed);
      } else {
        final updatedFeed = widget.existingFeed!.copyWith(
          icalUrl: _icalUrlController.text.trim(),
          platform: _selectedPlatform,
        );
        await repository.updateIcalFeed(updatedFeed);
        feedIdForSync = widget.existingFeed!.id;
      }

      ref.invalidate(icalFeedsStreamProvider);
      ref.invalidate(icalStatisticsProvider);

      if (mounted) {
        Navigator.pop(context);
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          widget.existingFeed == null
              ? l10n.icalAddFeedTitle
              : l10n.icalFeedUpdated,
        );

        // FIX: Auto-trigger sync immediately after saving new/updated feed
        // This runs in the background - user doesn't need to wait
        _triggerAutoSync(
          feedIdForSync,
          _selectedPropertyId!,
          _selectedPlatform,
        );
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

  /// Trigger automatic sync after saving a feed (fire-and-forget)
  /// Shows info snackbar when sync completes or fails
  void _triggerAutoSync(
    String feedId,
    String propertyId,
    IcalPlatform platform,
  ) async {
    final l10n = AppLocalizations.of(context);

    // Show sync started notification
    if (mounted) {
      ErrorDisplayUtils.showInfoSnackBar(
        context,
        l10n.icalSyncStarted(platform.displayName),
      );
    }

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('syncIcalFeedNow');
      final result = await callable
          .call({'feedId': feedId, 'propertyId': propertyId})
          .withCloudFunctionTimeout('syncIcalFeedNow');

      // Invalidate providers to refresh UI after sync
      ref.invalidate(icalFeedsStreamProvider);
      ref.invalidate(icalStatisticsProvider);
      // Also refresh calendar to show new bookings
      ref.invalidate(calendarBookingsProvider);

      if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.icalSyncErrorMessage,
        );
      }
    }
  }
}
