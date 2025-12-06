import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_color_extensions.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../../domain/models/ical_feed.dart';
import '../../providers/ical_feeds_provider.dart';
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
  ConsumerState<IcalSyncSettingsScreen> createState() => _IcalSyncSettingsScreenState();
}

class _IcalSyncSettingsScreenState extends ConsumerState<IcalSyncSettingsScreen> {
  bool _showFaq = false;
  int? _expandedPlatform;

  @override
  Widget build(BuildContext context) {
    final feedsAsync = ref.watch(icalFeedsStreamProvider);
    final statsAsync = ref.watch(icalStatisticsProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.icalSyncTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'integrations/ical'),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
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
              final horizontalPadding = isDesktop ? 48.0 : (isTablet ? 32.0 : 16.0);

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 1200.0 : double.infinity),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero Status Card
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isDesktop ? 800.0 : double.infinity),
                          child: statsAsync.when(
                            data: (stats) => _buildHeroCard(context, stats),
                            loading: () => _buildHeroCard(context, null),
                            error: (_, __) => _buildHeroCard(context, null),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Desktop: Benefits + Feeds side by side
                        if (isDesktop) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildBenefitsSection(context)),
                              const SizedBox(width: 24),
                              Expanded(
                                child: feedsAsync.when(
                                  data: (feeds) => _buildFeedsSection(context, feeds),
                                  loading: () => _buildFeedsLoading(context),
                                  error: (_, __) => _buildFeedsError(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildPlatformInstructions(context)),
                              const SizedBox(width: 24),
                              Expanded(child: _buildFaqSection(context)),
                            ],
                          ),
                        ] else ...[
                          // Mobile/Tablet: Stack vertically
                          _buildBenefitsSection(context),
                          const SizedBox(height: 24),
                          feedsAsync.when(
                            data: (feeds) => _buildFeedsSection(context, feeds),
                            loading: () => _buildFeedsLoading(context),
                            error: (_, __) => _buildFeedsError(context),
                          ),
                          const SizedBox(height: 24),
                          _buildPlatformInstructions(context),
                          const SizedBox(height: 24),
                          _buildFaqSection(context),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, Map<String, dynamic>? stats) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final activeFeeds = stats?['active_feeds'] as int? ?? 0;
    final errorFeeds = stats?['error_feeds'] as int? ?? 0;
    final totalFeeds = stats?['total_feeds'] as int? ?? 0;

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

    return Container(
      decoration: BoxDecoration(
        gradient: context.gradients.brandPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? AppShadows.elevation3Dark : AppShadows.elevation3,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha((0.9 * 255).toInt()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusTitle,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusDescription,
                      style: TextStyle(color: Colors.white.withAlpha((0.9 * 255).toInt()), fontSize: 14),
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
              label: Text(l10n.icalAddFeedButton, style: const TextStyle(fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
